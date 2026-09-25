#!/usr/bin/env bash
# Pełna instalacja; bez --apply wyświetla wyłącznie kolejność i polecenia.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/scripts/lib/settings.sh"
apply=false
mode=
first=apps
stages=(apps ulauncher language desktop settings services python)
usage() {
    echo 'Użycie: bash setup.sh [--dry-run|--apply] [--from ETAP]'
    echo 'Etapy: apps → ulauncher → language → desktop → settings → services → python.'
    echo 'Domyślnie podgląd. --from wykonuje wskazany etap i wszystkie kolejne.'
}
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        --from)
            (($# >= 2)) || die 'Brak etapu po --from.'
            first=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
start=-1
for i in "${!stages[@]}"; do
    if [[ ${stages[i]} == "$first" ]]; then start=$i; break; fi
done
((start >= 0)) || die "Nieznany etap: $first"
if $apply; then
    ((EUID != 0)) || die 'Uruchom jako zalogowany użytkownik, bez sudo.'
    if ((start <= 4)); then
        [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || die 'Uruchom instalator w sesji użytkownika GNOME.'
    fi
else
    echo '# PODGLĄD: poniższe polecenia nie zostaną wykonane. Zapis wymaga --apply.'
fi
stage=$first
on_error() {
    local status=$?
    trap - ERR
    printf '\nBŁĄD: przerwano etap %s (kod %s). Dalszych etapów nie uruchomiono.\n' "$stage" "$status" >&2
    echo 'Po usunięciu przyczyny wznów poleceniem:' >&2
    show_command bash "$ROOT/setup.sh" --apply --from "$stage" >&2
    exit "$status"
}
trap on_error ERR
trap 'exit 130' INT
trap 'exit 143' TERM
run() { show_command "$@"; if $apply; then "$@"; fi; }

for ((i=start; i<${#stages[@]}; i++)); do
    stage=${stages[i]}
    printf '\n# Etap %s/%s: %s\n' "$((i + 1))" "${#stages[@]}" "$stage"
    case $stage in
        apps)
            run bash "$ROOT/scripts/setup-repositories.sh" --apply
            run sudo apt-get update
            # Narzędzia potrzebne przed wywołaniem instalatorów aplikacji i ustawień.
            run sudo apt-get install -y -- ca-certificates curl jq snapd dconf-cli python3 python3-venv
            run bash "$ROOT/install.sh"
            # Pakiety producentów mogą dodać własne źródła; usuń ich duplikaty z naszego pliku.
            run bash "$ROOT/scripts/setup-repositories.sh" --apply
            run bash "$ROOT/scripts/install-adguard.sh" --apply ;;
        ulauncher) run bash "$ROOT/scripts/setup-ulauncher.sh" --apply ;;
        language) run bash "$ROOT/scripts/setup-polish.sh" --apply ;;
        # Pulpit po tłumaczeniach przywraca zapisany podział: system EN, konto PL.
        desktop) run bash "$ROOT/scripts/restore-desktop.sh" --apply ;;
        settings) run bash "$ROOT/scripts/restore-settings.sh" --section apps --skip-ulauncher --apply ;;
        services) run bash "$ROOT/scripts/restore-system-settings.sh" --apply ;;
        python) run bash "$ROOT/scripts/setup-python.sh" --apply ;;
    esac
done
if $apply; then
    echo 'Wszystkie etapy zakończone. Sprawdź komunikaty POMINIĘTO powyżej.'
    echo 'Po utworzeniu brakujących profili aplikacji zamknij je i wykonaj: bash setup.sh --apply --from settings'
    echo 'Po zmianach pulpitu wyloguj się i zaloguj ponownie.'
else
    echo 'Podgląd zakończony. Pełna instalacja: bash setup.sh --apply'
fi
