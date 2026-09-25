#!/usr/bin/env bash
# Osobne środowisko Pythona; domyślnie podgląd bez pobierania i zapisu.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
apply=false
mode=
venv="$HOME/.venv"
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        --venv)
            (($# >= 2)) && [[ -n $2 ]] || die 'Brak ścieżki po --venv.'
            venv=$2; shift ;;
        -h|--help)
            echo 'Użycie: bash scripts/setup-python.sh [--dry-run|--apply] [--venv ŚCIEŻKA]'
            echo 'Domyślnie: ~/.venv; biblioteki: packages/python/requirements.txt.'
            exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
if $apply && ((EUID == 0)); then die 'Uruchom jako zwykły użytkownik, bez sudo.'; fi
need python3
venv=$(realpath -m -- "$venv")
requirements="$ROOT/packages/python/requirements.txt"
[[ -f $requirements ]] || die 'Brak listy bibliotek Pythona.'
if [[ -e $venv || -L $venv ]]; then
    [[ -f $venv/pyvenv.cfg && -x $venv/bin/python ]] || die "Istniejący katalog nie jest środowiskiem venv: $venv"
    # Sam plik pyvenv.cfg nie wystarcza: sprawdź interpreter i jego prefix.
    "$venv/bin/python" -c 'import sys; from pathlib import Path; assert sys.prefix != sys.base_prefix and Path(sys.prefix).resolve() == Path(sys.argv[1]).resolve(), "Niepoprawny interpreter venv"' "$venv"
else
    show_command python3 -m venv "$venv"
    if $apply; then
        python3 -m venv "$venv" || die 'Nie udało się utworzyć venv. Sprawdź pakiet python3-venv (lista apt/dev.txt).'
    fi
fi
show_command "$venv/bin/python" -m pip install -r "$requirements"
show_command "$venv/bin/python" -m pip check
if $apply; then
    "$venv/bin/python" -m pip install -r "$requirements"
    "$venv/bin/python" -m pip check
    echo "Gotowe. Interpreter: $venv/bin/python"
else
    echo 'Podgląd zakończony. Aby utworzyć środowisko i zainstalować biblioteki, dodaj --apply.'
fi
