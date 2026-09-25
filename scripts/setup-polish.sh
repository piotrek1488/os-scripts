#!/usr/bin/env bash
set -euo pipefail
apply=false
ui=pl
while (($#)); do
    case "$1" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        --english-ui) ui=en ;;
        -h|--help)
            echo 'Użycie: bash scripts/setup-polish.sh [--dry-run|--apply] [--english-ui]'
            echo 'Polskie tłumaczenia, słowniki, formaty i klawiatura. Domyślnie polski interfejs.'
            exit 0 ;;
        *) echo "Nieznana opcja: $1" >&2; exit 2 ;;
    esac
    shift
done
if $apply && ((EUID == 0)); then
    echo 'Uruchom jako użytkownik GNOME bez sudo; skrypt sam użyje sudo do instalacji.' >&2
    exit 1
fi
run() {
    printf '%q ' "$@"; printf '\n'
    if $apply; then "$@"; fi
}
# Nie korzystaj ze schematów GTK dostarczanych przez terminal Snapa Code.
unset GSETTINGS_SCHEMA_DIR
export XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop
if [[ $ui == pl ]]; then
    lang=pl_PL.UTF-8
    languages=pl:en
else
    lang=en_US.UTF-8
    languages=en:pl
fi
if $apply; then
    [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || { echo 'Uruchom z aktywnej sesji użytkownika GNOME.' >&2; exit 1; }
    command -v gsettings >/dev/null
    command -v gdbus >/dev/null
fi
run sudo apt-get update
run sudo apt-get install -y -- locales language-selector-common language-pack-pl language-pack-gnome-pl hunspell-pl hyphen-pl mythes-pl wpolish
run sudo locale-gen pl_PL.UTF-8 en_US.UTF-8
# Dopasuj dodatkowe tłumaczenia do aplikacji faktycznie zainstalowanych na nowym systemie.
if $apply; then
    missing=$(check-language-support -l pl)
    if [[ -n $missing ]]; then
        read -r -a language_packages <<< "$missing"
        for package in "${language_packages[@]}"; do
            [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || { echo 'Niepoprawna nazwa pakietu językowego' >&2; exit 1; }
        done
        run sudo apt-get install -y -- "${language_packages[@]}"
    fi
else
    echo '# check-language-support -l pl: zainstaluj zgłoszone brakujące tłumaczenia.'
fi
if $apply; then
    backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/os-scripts"
    mkdir -p "$backup_root"
    locale_backup=$(mktemp -d "$backup_root/language-XXXXXXXX")
    cp /etc/default/locale "$locale_backup/system-locale"
    [[ ! -f "$HOME/.pam_environment" ]] || cp "$HOME/.pam_environment" "$locale_backup/pam-environment"
    gsettings get org.gnome.system.locale region > "$locale_backup/region"
    gsettings get org.gnome.desktop.input-sources sources > "$locale_backup/input-sources"
    echo "Kopia ustawień języka: $locale_backup"
fi
run sudo update-locale "LANG=$lang" "LANGUAGE=$languages" LC_ALL LC_MESSAGES \
    LC_NUMERIC=pl_PL.UTF-8 LC_TIME=pl_PL.UTF-8 LC_MONETARY=pl_PL.UTF-8 \
    LC_PAPER=pl_PL.UTF-8 LC_NAME=pl_PL.UTF-8 LC_ADDRESS=pl_PL.UTF-8 \
    LC_TELEPHONE=pl_PL.UTF-8 LC_MEASUREMENT=pl_PL.UTF-8 LC_IDENTIFICATION=pl_PL.UTF-8
account="/org/freedesktop/Accounts/User$(id -u)"
run gdbus call --system --dest org.freedesktop.Accounts --object-path "$account" \
    --method org.freedesktop.Accounts.User.SetLanguage "$lang"
run gdbus call --system --dest org.freedesktop.Accounts --object-path "$account" \
    --method org.freedesktop.Accounts.User.SetFormatsLocale pl_PL.UTF-8
run gsettings set org.gnome.system.locale region pl_PL.UTF-8
run gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'pl')]"
echo 'Po zastosowaniu wyloguj się i zaloguj ponownie. Preferencje językowe poszczególnych aplikacji odtwarza restore-settings.sh.'
