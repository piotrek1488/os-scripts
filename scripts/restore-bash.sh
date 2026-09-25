#!/usr/bin/env bash
# Kopiuje definicje Bash, ale ich nie wykonuje. Domyślnie tylko podgląd.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
apply=false
mode=
settings_home=$HOME
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        --home-dir)
            (($# >= 2)) && [[ -n $2 ]] || die 'Brak katalogu po --home-dir.'
            settings_home=$2; shift ;;
        -h|--help)
            echo 'Użycie: bash scripts/restore-bash.sh [--dry-run|--apply] [--home-dir KATALOG]'
            echo 'Domyślnie katalog bieżącego użytkownika. Kopie zapasowe poza repozytorium.'
            exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
if $apply && ((EUID == 0)); then die 'Uruchom jako zwykły użytkownik, bez sudo.'; fi
need realpath
settings_home=$(realpath -m -- "$settings_home")
[[ ! -e $settings_home || -d $settings_home ]] || die 'Katalog docelowy nie jest katalogiem.'
repo=$(realpath -- "$ROOT")
outside_repository() {
    local path
    path=$(realpath -m -- "$1")
    [[ $path != "$repo" && $path != "$repo/"* ]] || die 'Konfiguracja i prywatne kopie Bash muszą pozostać poza repozytorium.'
}
outside_repository "$settings_home"
umask 077
# Istniejący .bashrc może zawierać prywatne dane. Nie używaj TMPDIR wskazującego na repo.
work=$(mktemp -d /tmp/os-scripts-bash-XXXXXXXX)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
backup=$(inside_home "$settings_home/.local/state/os-scripts/backups/bash-$(date +%Y%m%d-%H%M%S-%N)")
outside_repository "$backup"
names=(.bashrc.user .bash_aliases .bash_functions .bashrc)
targets=()
declare -A seen=()
for name in "${names[@]}"; do
    target=$(inside_home "$settings_home/$name")
    outside_repository "$target"
    [[ ! -e $target || -f $target ]] || die "Cel nie jest plikiem: $target"
    [[ ! ${seen[$target]+yes} ]] || die 'Pliki konfiguracji wskazują ten sam cel.'
    seen[$target]=1
    targets+=("$target")
    if [[ $name != .bashrc ]]; then
        cp -- "$ROOT/config/bash/$name" "$work/$name"
    else
        old=/dev/null
        [[ ! -f $target ]] || old=$target
        # Zachowaj pozostałą konfigurację .bashrc i zastąp wyłącznie nasz blok.
        awk '
            $0 == "# BEGIN os-scripts bash" { if(block) exit 2; block=1; next }
            $0 == "# END os-scripts bash" { if(!block) exit 2; block=0; next }
            !block { print }
            END { if(block) exit 2 }
        ' "$old" > "$work/$name" || die 'Niepoprawny zarządzany blok w .bashrc.'
        cat -- "$ROOT/config/bash/bashrc-loader.sh" >> "$work/$name"
    fi
    # Bez source i bez wypisywania fragmentów błędnego, potencjalnie prywatnego pliku.
    env -u BASH_ENV bash --noprofile --norc -n "$work/$name" >/dev/null 2>&1 || die "Niepoprawna składnia Bash: $name"
done
for i in "${!names[@]}"; do
    name=${names[i]}
    target=${targets[i]}
    if [[ -f $target ]] && cmp -s -- "$work/$name" "$target"; then
        echo "# Bez zmian: $target"
        continue
    fi
    echo "# Odtwórz: $target"
    if $apply; then
        if [[ -f $target ]]; then
            mkdir -p -- "$backup"
            chmod 700 -- "$backup"
            cp -a -- "$target" "$backup/$name"
        fi
        mkdir -p -- "$(dirname -- "$target")"
        install -m 0600 -- "$work/$name" "$target"
    fi
done
if $apply; then
    echo "Kopie zmienionych plików (jeśli istniały): $backup"
    echo 'Otwórz nowy terminal Bash, aby wczytać aliasy, funkcje i prompt.'
else
    echo 'Podgląd zakończony. Zapis wymaga --apply; definicje Bash nie zostały uruchomione.'
fi
