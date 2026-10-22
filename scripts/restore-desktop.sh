#!/usr/bin/env bash
# Ustawienia ogólne → Dostrajanie → rozszerzenia, na podstawie lokalnego audytu.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
DATA="$ROOT/config/settings"
snapshot="$DATA/desktop.json"
apply=false
mode=
section=all
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        --section)
            (($# >= 2)) || die 'Brak sekcji po --section.'
            section=$2; shift
            case $section in all|system|tweaks|extensions) ;; *) die "Nieznana sekcja: $section";; esac ;;
        -h|--help)
            echo 'Użycie: bash scripts/restore-desktop.sh [--dry-run|--apply] [--section all|system|tweaks|extensions]'
            echo 'Snapshot Ubuntu 26.04 / GNOME 50. Kopie zapasowe: ~/.local/state/os-scripts/backups/.'
            exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
if $apply && ((EUID == 0)); then die 'Uruchom jako zalogowany użytkownik GNOME, bez sudo.'; fi
need jq
need realpath
jq -e '.dconf and .extensions and .mime and .custom_shortcuts and .system_keyboard' "$snapshot" >/dev/null
settings_home=$(realpath -- "$HOME")
unset GSETTINGS_SCHEMA_DIR
export XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop
umask 077
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
backup=$(inside_home "$settings_home/.local/state/os-scripts/backups/desktop-$(date +%Y%m%d-%H%M%S-%N)")
selected() { [[ $section == all || $section == "$1" ]]; }
run() { show_command "$@"; if $apply; then "$@"; fi; }
ensure_backup() { mkdir -p -- "$backup"; chmod 700 -- "$backup"; }
save_file() {
    local path=$1 dest
    [[ -e $path || -L $path ]] || return 0
    ensure_backup
    dest="$backup/files/${path#/}"
    mkdir -p -- "$(dirname -- "$dest")"
    cp -a -- "$path" "$dest"
}
copy_file() {
    local source=$1 dest
    dest=$(inside_home "$settings_home/$2")
    show_command install -D -m 600 -- "$source" "$dest"
    if $apply; then save_file "$dest"; install -D -m 600 -- "$source" "$dest"; fi
}
write_dconf() {
    local path=$1 value=$2 previous escaped_home
    escaped_home=${settings_home//\\/\\\\}; escaped_home=${escaped_home//\'/\\\'}
    value=${value//@HOME@/"$escaped_home"}
    if $apply; then
        previous=$(dconf read "$path")
        ensure_backup
        [[ -f $backup/dconf.json ]] || printf '{}\n' > "$backup/dconf.json"
        jq --arg path "$path" --arg value "$previous" \
            'if has($path) then . else .[$path] = (if $value == "" then null else $value end) end' \
            "$backup/dconf.json" > "$work/dconf.json"
        cp -- "$work/dconf.json" "$backup/dconf.json"
    fi
    run dconf write "$path" "$value"
}
apply_preferences() {
    local part=$1 setting path
    while IFS= read -r setting; do
        path=$(jq -r '.path' <<< "$setting")
        if [[ $part == system && $path == "$original_shortcut"* ]]; then
            path="$shortcut${path#"$original_shortcut"}"
        fi
        write_dconf "$path" "$(jq -r '.current' <<< "$setting")"
    done < <(jq -c --arg section "$part" '.dconf[] | select(.section == $section)' "$snapshot")
}
if $apply; then
    for command in dconf gsettings gnome-shell glib-compile-schemas; do need "$command"; done
    [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || die 'Wymagana aktywna sesja użytkownika GNOME.'
    gsettings get org.gnome.shell enabled-extensions >/dev/null
    if selected system; then
        for command in sudo locale-gen update-locale timedatectl localectl gdbus xdg-mime; do need "$command"; done
    fi
fi

original_shortcut=$(jq -r '.custom_shortcuts[0]' "$snapshot")
shortcut=$original_shortcut
custom_key=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
if selected system && command -v dconf >/dev/null; then
    command_now=$(dconf read "${shortcut}command")
    if [[ -n $command_now && $command_now != "'ulauncher-toggle'" ]]; then
        shortcut='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/os_scripts_ulauncher/'
        command_now=$(dconf read "${shortcut}command")
        [[ -z $command_now || $command_now == "'ulauncher-toggle'" ]] || die "Konflikt skrótu: $shortcut"
    fi
fi
# Schematowe wartości domyślne też mogą zawierać istniejące skróty.
merged_shortcuts="['$shortcut']"
if selected system && command -v gsettings >/dev/null 2>&1; then
    if current_shortcuts=$(gsettings get \
        org.gnome.settings-daemon.plugins.media-keys \
        custom-keybindings 2>/dev/null); then
        merged_shortcuts=$(merge_shortcut_paths \
            "$current_shortcuts" "$shortcut")
    fi
fi


# Zasoby muszą istnieć przed ustawieniem tapety, motywów i ikony ArcMenu.
run bash "$ROOT/scripts/restore-settings.sh" --section assets "${mode:---dry-run}"

if selected system; then
    echo '# 1. Ustawienia ogólne systemu'
    if $apply; then
        ensure_backup
        save_file /etc/default/locale
        save_file /etc/default/keyboard
        timedatectl show > "$backup/time.txt"
        localectl status > "$backup/keyboard.txt"
        for property in Language FormatsLocale; do
            gdbus call --system --dest org.freedesktop.Accounts \
                --object-path "/org/freedesktop/Accounts/User$(id -u)" \
                --method org.freedesktop.DBus.Properties.Get org.freedesktop.Accounts.User "$property" > "$backup/account-$property.txt"
        done
    fi
    run sudo locale-gen en_US.UTF-8 pl_PL.UTF-8
    run sudo update-locale --reset "LANG=$(jq -r '.system_language' "$snapshot")"
    run sudo localectl set-x11-keymap "$(jq -r '.system_keyboard.layout' "$snapshot")" "$(jq -r '.system_keyboard.model' "$snapshot")"
    run sudo timedatectl set-timezone "$(jq -r '.timezone' "$snapshot")"
    run sudo timedatectl set-ntp "$(jq -r '.ntp' "$snapshot")"
    account="/org/freedesktop/Accounts/User$(id -u)"
    run gdbus call --system --dest org.freedesktop.Accounts --object-path "$account" \
        --method org.freedesktop.Accounts.User.SetLanguage "$(jq -r '.account_language' "$snapshot")"
    run gdbus call --system --dest org.freedesktop.Accounts --object-path "$account" \
        --method org.freedesktop.Accounts.User.SetFormatsLocale "$(jq -r '.account_formats' "$snapshot")"
    write_dconf /org/gnome/system/locale/region "$(gvariant_string "$(jq -r '.account_formats' "$snapshot")")"
    if command -v powerprofilesctl >/dev/null; then
        if $apply; then powerprofilesctl get > "$backup/power-profile.txt"; fi
        run powerprofilesctl set "$(jq -r '.power_profile' "$snapshot")"
    else echo '# POMINIĘTO profil zasilania: brak powerprofilesctl.'; fi
    apply_preferences system
    write_dconf "$custom_key" "$merged_shortcuts"
    copy_file "$DATA/files/monitors.xml" .config/monitors.xml
    echo '# Układ monitorów zostanie odczytany przy kolejnym logowaniu na tym sprzęcie.'
    if $apply; then
        for rel in .config/mimeapps.list .config/gnome-mimeapps.list .local/share/applications/mimeapps.list; do
            save_file "$(inside_home "$settings_home/$rel")"
        done
    fi
    while IFS=$'\t' read -r type desktop; do
        found=false
        for base in "$settings_home/.local/share" /usr/local/share /usr/share /var/lib/snapd/desktop; do
            if [[ -f $base/applications/$desktop ]]; then found=true; break; fi
        done
        if $found || ! $apply; then run xdg-mime default "$desktop" "$type"
        else echo "# POMINIĘTO skojarzenie $type: brak $desktop"; fi
    done < <(jq -r '.mime[] | [.type,.desktop] | @tsv' "$snapshot")
fi
if selected tweaks; then
    echo '# 2. Dostrajanie'
    apply_preferences tweaks
    copy_file "$DATA/files/ulauncher.desktop" .config/autostart/ulauncher.desktop
fi
if selected extensions; then
    echo '# 3. Rozszerzenia'
    archive="$DATA/assets/extensions.tar.gz"
    if $apply; then
        mkdir -- "$work/extensions"
        tar -tzf "$archive" > "$work/extension-paths"
        while IFS= read -r entry; do
            [[ $entry != /* && /$entry/ != */../* ]] || die "Niepoprawna ścieżka archiwum: $entry"
        done < "$work/extension-paths"
        tar -xzf "$archive" -C "$work/extensions" --no-same-owner --no-same-permissions
        find "$work/extensions" -type l -print0 | xargs -0 -r realpath -m -- > "$work/extension-links"
        while IFS= read -r link; do
            [[ $link == "$work/extensions/"* ]] || die 'Dowiązanie rozszerzenia poza archiwum.'
        done < "$work/extension-links"
    fi
    available='[]'
    major=50
    if command -v gnome-shell >/dev/null; then major=$(gnome-shell --version | sed -nE 's/.* ([0-9]+)\..*/\1/p'); fi
    while IFS= read -r extension; do
        uuid=$(jq -r '.uuid' <<< "$extension")
        [[ $uuid =~ ^[a-zA-Z0-9@._+-]+$ ]] || die 'Niepoprawny UUID rozszerzenia.'
        dest=$(inside_home "$settings_home/.local/share/gnome-shell/extensions/$uuid")
        metadata=
        for base in "$settings_home/.local/share" /usr/local/share /usr/share; do
            if [[ -f $base/gnome-shell/extensions/$uuid/metadata.json ]]; then
                metadata="$base/gnome-shell/extensions/$uuid/metadata.json"; break
            fi
        done
        if [[ -z $metadata && $(jq -r '.bundled' <<< "$extension") == true ]]; then
            echo "# Instalacja brakującego rozszerzenia: $uuid"
            if $apply; then
                [[ ! -e $dest ]] || die "Niekompletny katalog rozszerzenia: $dest"
                jq -e --arg uuid "$uuid" '.uuid == $uuid' "$work/extensions/$uuid/metadata.json" >/dev/null
                mkdir -p -- "$(dirname -- "$dest")"
                cp -a -- "$work/extensions/$uuid" "$dest"
                if [[ -d $dest/schemas ]]; then glib-compile-schemas "$dest/schemas"; fi
                metadata="$dest/metadata.json"
            fi
        elif [[ -z $metadata ]]; then
            echo "# POMINIĘTO brak rozszerzenia systemowego: $uuid; pakiet: $(jq -r '.package // "sprawdź DESKTOP.md"' <<< "$extension")"
            continue
        fi
        supported=$(jq -c '."shell-version"' <<< "$extension")
        [[ -z $metadata ]] || supported=$(jq -c '."shell-version" // []' "$metadata")
        if [[ $(jq -r '.enabled' <<< "$extension") == true ]] && ! jq -e --arg major "$major" 'index($major) != null' <<< "$supported" >/dev/null; then
            echo "# UWAGA: $uuid nie obsługuje GNOME $major. Zachowuję wybór włączenia; GNOME zablokuje niezgodną wersję."
        fi
        available=$(jq --argjson item "$extension" '. + [$item]' <<< "$available")
        echo "# $uuid: enabled=$(jq -r '.enabled' <<< "$extension")"
    done < <(jq -c '.extensions[]' "$snapshot")
    apply_preferences extensions
    copy_file "$DATA/files/run-or-raise.conf" .config/run-or-raise/shortcuts.conf
    # Włącz kontrolę zgodności przed listami, aby nie załadować niezgodnej wersji.
    write_dconf /org/gnome/shell/disable-extension-version-validation false
    # Zapis list działa także dla rozszerzeń wykrywanych dopiero przy kolejnym logowaniu.
    for key in enabled-extensions disabled-extensions; do
        current="@as []"
        if command -v gsettings >/dev/null 2>&1; then
            if current_value=$(gsettings get org.gnome.shell "$key" 2>/dev/null); then
                current="$current_value"
            fi
        fi
        value=$(merge_extension_states "$current" "$available" "$key")
        write_dconf "/org/gnome/shell/$key" "$value"
    done
    write_dconf /org/gnome/shell/disable-user-extensions false
fi
if $apply; then
    echo "Kopie zapasowe: $backup"
    echo 'Wyloguj się i zaloguj ponownie, aby GNOME wykryło rozszerzenia i układ monitorów.'
else
    echo 'Podgląd zakończony. Zapis: dodaj --apply. Szczegóły różnic: config/settings/DESKTOP.md.'
fi
