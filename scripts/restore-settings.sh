#!/usr/bin/env bash
# Odtwarzanie wybranych preferencji; domyślnie tylko podgląd.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
DATA="$ROOT/config/settings"
apply=false
section=all
skip_ulauncher=false
mode=
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        --section)
            (($# >= 2)) || die 'Brak sekcji po --section.'
            section=$2; shift
            case $section in all|desktop|apps|assets|extensions) ;; *) die "Nieznana sekcja: $section";; esac ;;
        --skip-ulauncher) skip_ulauncher=true ;;
        -h|--help)
            echo 'Użycie: bash scripts/restore-settings.sh [--dry-run|--apply] [--section all|desktop|apps|assets|extensions] [--skip-ulauncher]'
            echo '--skip-ulauncher: pomija instalator dodatków i motywów, jeżeli wykonano go wcześniej.'
            exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
if $apply && ((EUID == 0)); then die 'Uruchom jako zalogowany użytkownik GNOME, bez sudo.'; fi
need jq
need realpath
jq -e '.files and .dconf and .git and .gh' "$DATA/snapshot.json" >/dev/null
settings_home=$(realpath -- "$HOME")
unset GSETTINGS_SCHEMA_DIR
export XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop
umask 077
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
backup=$(inside_home "$settings_home/.local/state/os-scripts/backups/$(date +%Y%m%d-%H%M%S-%N)")
declare -A backed=()
selected() { [[ $section == all || $section == "$1" ]]; }
run() { show_command "$@"; if $apply; then "$@"; fi; }
ensure_backup() { mkdir -p -- "$backup"; chmod 700 -- "$backup"; }
save() {
    local path=$1 target
    [[ ! ${backed[$path]+yes} ]] || return 0
    backed[$path]=1
    [[ -e $path || -L $path ]] || return 0
    ensure_backup
    target="$backup/files/${path#"$settings_home/"}"
    mkdir -p -- "$(dirname -- "$target")"
    cp -a -- "$path" "$target"
}

# Przygotuj i zweryfikuj wszystkie scalenia przed pierwszym zapisem konfiguracji.
targets=() rendered=()
declare -A processes=()
if selected apps; then
    while IFS= read -r item; do
        target=$(inside_home "$settings_home/$(jq -r '.target' <<< "$item")")
        kind=$(jq -r '.kind' <<< "$item")
        if [[ $kind == firefox ]]; then
            profile=$(firefox_profile "$target")
            if [[ -z $profile || ! -d $profile ]]; then
                echo '# POMINIĘTO Firefox: uruchom raz aplikację i wybierz profil domyślny.'
                continue
            fi
            target=$(inside_home "$profile/user.js")
        elif [[ $(jq -r '.existing' <<< "$item") == true && ! -f $target ]]; then
            echo "# POMINIĘTO brak profilu: $(jq -r '.app' <<< "$item") — uruchom aplikację raz."
            continue
        fi
        old=/dev/null
        [[ ! -e $target ]] || old=$target
        output="$work/file-${#targets[@]}"
        patch=$(jq -c '.data' <<< "$item")
        case $kind in
            json) merge_jsonc "$old" "$patch" > "$output" ;;
            ini) merge_ini "$old" "$patch" "$output" ;;
            firefox) render_firefox "$old" "$patch" "$output" ;;
            text) jq -j '.data' <<< "$item" > "$output" ;;
            *) die "Nieobsługiwany rodzaj preferencji: $kind" ;;
        esac
        targets+=("$target"); rendered+=("$output")
        while IFS= read -r process; do processes[$process]=1; done < <(jq -r '.processes[]' <<< "$item")
    done < <(jq -c '.files[]' "$DATA/snapshot.json")
    busy=()
    live=$(ps -u "$(id -u)" -o comm=)
    while IFS= read -r process; do
        [[ ! ${processes[$process]+yes} ]] || busy+=("$process")
    done <<< "$live"
    if ((${#busy[@]})); then
        if $apply; then die "Zamknij przed zapisem: ${busy[*]}"; fi
        echo "# Zamknij przed zapisem: ${busy[*]}"
    fi
    # Sprawdź ścieżki konfiguracji CLI także przed zmianami pulpitu.
    git_home_config=$(inside_home "${GIT_CONFIG_GLOBAL:-$settings_home/.gitconfig}")
    git_xdg_config=$(inside_home "${XDG_CONFIG_HOME:-$settings_home/.config}/git/config")
    gh_config=$(inside_home "${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$settings_home/.config}/gh}/config.yml")
fi

if $apply && selected apps; then
    need dconf
    [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || die 'Wymagane dconf i aktywna sesja użytkownika GNOME.'
fi
if selected apps && ! $skip_ulauncher; then
    bash "$ROOT/scripts/setup-ulauncher.sh" "${mode:---dry-run}"
fi
if selected desktop; then
    bash "$ROOT/scripts/restore-desktop.sh" "${mode:---dry-run}"
elif selected extensions; then
    bash "$ROOT/scripts/restore-desktop.sh" --section extensions "${mode:---dry-run}"
fi

if [[ $section == assets ]]; then
    archive="$DATA/assets/desktop.tar.gz"
    asset_roots=(.local/share/themes/Fluent-Dark .local/share/icons/Win11
        .local/share/icons/MacTahoe .local/share/icons/os-scripts-menu.webp
        .local/share/backgrounds/os-scripts-current.jpg .config/ulauncher/user-themes/libadwaita-dark)
    echo "# Odtwórz zasoby z $archive (z kopią obecnych motywów)."
    if $apply; then
        mkdir -- "$work/assets"
        # GNU tar odrzuca .. i nie przechodzi przez dowiązania katalogów.
        # Najpierw rozpakuj do pustego katalogu, nie wprost do HOME.
        tar -tzf "$archive" > "$work/archive-paths"
        while IFS= read -r entry; do
            [[ $entry != /* && /$entry/ != */../* ]] || die "Niepoprawna ścieżka w archiwum: $entry"
        done < "$work/archive-paths"
        tar -xzf "$archive" -C "$work/assets" --no-same-owner --no-same-permissions
        # Sprawdź wszystkie linki naraz; nie mogą wskazywać poza rozpakowane zasoby.
        find "$work/assets" -type l -print0 | xargs -0 -r realpath -m -- > "$work/asset-links"
        while IFS= read -r link; do
            [[ $link == "$work/assets/"* ]] || die 'Dowiązanie zasobu poza archiwum.'
        done < "$work/asset-links"
        asset_targets=()
        for rel in "${asset_roots[@]}"; do
            [[ -e $work/assets/$rel ]] || die "Brak zasobu: $rel"
            asset_targets+=("$(inside_home "$settings_home/$rel")")
        done
        for i in "${!asset_roots[@]}"; do
            dest=${asset_targets[i]}
            save "$dest"
            mkdir -p -- "$(dirname -- "$dest")"
            if [[ -e $dest || -L $dest ]]; then mv -- "$dest" "$work/replaced-$i"; fi
            cp -a -- "$work/assets/${asset_roots[i]}" "$dest"
        done
    fi
fi

write_dconf() {
    local path=$1 value=$2 previous escaped_home
    escaped_home=${settings_home//\\/\\\\}; escaped_home=${escaped_home//\'/\\\'}
    value=${value//@HOME@/"$escaped_home"}
    if $apply; then
        previous=$(dconf read "$path")
        ensure_backup
        [[ -f $backup/dconf.json ]] || printf '{}\n' > "$backup/dconf.json"
        jq --arg path "$path" --arg value "$previous" \
            '.[$path] = (if $value == "" then null else $value end)' "$backup/dconf.json" > "$work/dconf.json"
        cp -- "$work/dconf.json" "$backup/dconf.json"
    fi
    run dconf write "$path" "$value"
}
if selected apps; then
    while IFS= read -r setting; do
        write_dconf "$(jq -r '.path' <<< "$setting")" "$(jq -r '.value' <<< "$setting")"
    done < <(jq -c '.dconf[]' "$DATA/snapshot.json")
    for i in "${!targets[@]}"; do
        target=${targets[i]}
        echo "# Zapis scalonych preferencji: $target"
        if $apply; then
            save "$target"
            mkdir -p -- "$(dirname -- "$target")"
            temp=$(mktemp -- "$target.os-scripts-XXXXXXXX")
            cat -- "${rendered[i]}" > "$temp"
            if [[ -f $target ]]; then chmod --reference="$target" -- "$temp"; else chmod 600 -- "$temp"; fi
            mv -f -- "$temp" "$target"
        fi
    done
    if command -v git >/dev/null; then
        if $apply; then save "$git_home_config"; save "$git_xdg_config"; fi
        while IFS= read -r pair; do
            run git config --global "$(jq -r '.[0]' <<< "$pair")" "$(jq -r '.[1]' <<< "$pair")"
        done < <(jq -c '.git[]' "$DATA/snapshot.json")
    else echo '# POMINIĘTO Git: brak programu.'; fi
    if command -v gh >/dev/null; then
        if $apply; then save "$gh_config"; fi
        while IFS= read -r pair; do
            run gh config set "$(jq -r '.[0]' <<< "$pair")" "$(jq -r '.[1]' <<< "$pair")"
        done < <(jq -c '.gh[]' "$DATA/snapshot.json")
        run gh alias set co 'pr checkout'
    else echo '# POMINIĘTO GitHub CLI: brak programu.'; fi
fi

if $apply; then
    echo "Kopie zapasowe (jeśli zmieniono istniejące dane): $backup"
    echo 'Uruchom ponownie aplikacje. Motyw GNOME może wymagać wylogowania.'
else
    echo 'Podgląd zakończony. Zapis: dodaj --apply. Usługi i instalacja tłumaczeń mają osobne skrypty.'
fi
