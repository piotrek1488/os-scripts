#!/usr/bin/env bash
# Publiczne klucze są już osadzone w Deb822; nie potrzeba curl, jq ani apt-key.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
apply=false
mode=
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        -h|--help)
            echo 'Użycie: bash scripts/setup-repositories.sh [--dry-run|--apply]'
            echo 'Dodaje brakujące repozytoria dla Ubuntu 26.04/amd64 z publicznymi kluczami.'
            exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
if $apply; then
    ((EUID != 0)) || die 'Uruchom jako zwykły użytkownik, bez sudo.'
    # shellcheck source=/dev/null
    source /etc/os-release
    [[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 26.04 && $(dpkg --print-architecture) == amd64 ]] ||
        die 'Repozytoria przygotowano dla Ubuntu 26.04 (resolute), amd64.'
    need sudo
fi
catalog="$ROOT/packages/apt/repositories.sources"
target=/etc/apt/sources.list.d/os-scripts.sources
existing=()
[[ ! -f /etc/apt/sources.list ]] || existing+=(/etc/apt/sources.list)
shopt -s nullglob
for file in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    # Plik zarządzany odtwarzamy z katalogu, uwzględniając źródła dodane przez aplikacje.
    [[ $file == "$target" ]] || existing+=("$file")
done
shopt -u nullglob
umask 077
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
awk -v catalog="$catalog" -f "$ROOT/scripts/lib/missing-repositories.awk" \
    "${existing[@]}" "$catalog" > "$work/repos.sources"
echo '# Repozytoria zarządzane przez os-scripts (pozostałe aktywne adresy już istnieją):'
awk '/^URIs:/ { print }' "$work/repos.sources"
if [[ ! -s $work/repos.sources && ! -e $target ]]; then
    echo '# Wszystkie wymagane adresy mają już aktywne wpisy. Nie dodano pliku.'
    exit 0
fi
if [[ -f $target ]] && cmp -s -- "$work/repos.sources" "$target"; then
    echo '# Repozytoria os-scripts są aktualne.'
    exit 0
fi
if [[ -e $target || -L $target ]]; then
    backup="$target.os-scripts-$(date +%Y%m%d-%H%M%S-%N).bak"
    show_command sudo cp -a -- "$target" "$backup"
    if $apply; then sudo cp -a -- "$target" "$backup"; fi
fi
show_command sudo install -m 0644 -- "$work/repos.sources" "$target"
if $apply; then sudo install -m 0644 -- "$work/repos.sources" "$target"; fi
echo '# Wymagane są również standardowe źródła Ubuntu main i universe.'
echo '# Indeksy odświeża następny etap: sudo apt-get update.'
