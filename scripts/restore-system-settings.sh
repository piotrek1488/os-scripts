#!/usr/bin/env bash
# Preferencje Timeshift i Dockera, bez ustawień sieci/dysków i restartów usług.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
apply=false
mode=
for arg in "$@"; do
    case $arg in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$arg" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$arg; [[ $arg != --apply ]] || apply=true ;;
        -h|--help) echo 'Użycie: bash scripts/restore-system-settings.sh [--dry-run|--apply]'; exit 0 ;;
        *) die "Nieznana opcja: $arg" ;;
    esac
done
need jq
jq -e 'type == "object" and all(.[]; type == "object")' "$ROOT/config/settings/system.json" >/dev/null
umask 077
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
paths=() rendered=()
# Najpierw przygotuj wszystkie pliki, dopiero potem zapisz zmiany.
while IFS= read -r entry; do
    path=$(jq -r '.key' <<< "$entry")
    case $path in /etc/timeshift/timeshift.json|/etc/docker/daemon.json) ;; *) die "Nieobsługiwany cel: $path";; esac
    if [[ ! -f $path ]]; then
        echo "# POMINIĘTO $path — zainstaluj i skonfiguruj aplikację pierwszy raz."
        continue
    fi
    patch=$(jq -c '.value' <<< "$entry")
    echo "# Scal z $path: $patch"
    if $apply; then
        temp="$work/${#paths[@]}.json"
        sudo cat -- "$path" | jq -e --argjson patch "$patch" \
            'if type == "object" then . * $patch else error("Oczekiwano obiektu JSON") end' > "$temp"
        paths+=("$path"); rendered+=("$temp")
    fi
done < <(jq -c 'to_entries[]' "$ROOT/config/settings/system.json")
for i in "${!paths[@]}"; do
    path=${paths[i]}
    backup="$path.os-scripts-$(date +%Y%m%d-%H%M%S-%N).bak"
    sudo cp --preserve=mode,ownership -- "$path" "$backup"
    # Zapis do istniejącego pliku zachowuje właściciela i uprawnienia.
    # Źródło jest prywatnym plikiem tymczasowym bieżącego użytkownika.
    # shellcheck disable=SC2024
    sudo tee -- "$path" < "${rendered[i]}" >/dev/null
    echo "Kopia: $backup"
done
echo 'Docker: skrypt nie restartuje usługi. Zmiana live-restore zacznie działać po kontrolowanym restarcie Dockera.'
if ! $apply; then echo 'Podgląd zakończony. Zapis: dodaj --apply.'; fi
