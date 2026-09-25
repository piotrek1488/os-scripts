#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dry_run=false
source_filter=all
categories=()
usage() {
    echo "Użycie: $0 [--dry-run] [--source apt|snap|deb|all] [essentials dev entertainment]"
    echo 'Alias optional oznacza entertainment. Bez kategorii: wszystkie.'
    echo 'DEB: po jednym URL w wierszu packages/deb/<kategoria>.txt.'
}
die() { echo "BŁĄD: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "Brak $1 — zainstaluj wymagane narzędzie."; }
while (($#)); do
    case "$1" in
        --dry-run) dry_run=true ;;
        --source)
            (($# >= 2)) || { usage >&2; exit 2; }
            source_filter=$2; shift
            case "$source_filter" in apt|snap|deb|all) ;; *) usage >&2; exit 2;; esac ;;
        essentials|dev|entertainment) categories+=("$1") ;;
        optional) categories+=(entertainment) ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done
((${#categories[@]})) || categories=(essentials dev entertainment)
apt_packages=() snap_packages=() deb_urls=() deb_files=()
declare -A seen=()
for source in apt snap deb; do
    [[ $source_filter == all || $source_filter == "$source" ]] || continue
    for category in "${categories[@]}"; do
        file="$BASE_DIR/packages/$source/$category.txt"
        while IFS= read -r line || [[ -n $line ]]; do
            line=${line%$'\r'}
            line=${line%%#*}
            read -r entry flag extra <<< "$line"
            [[ -n $entry ]] || continue
            if [[ $source == deb ]]; then
                [[ $entry =~ ^https://[^/?#[:space:]]+/[^[:space:]]+$ && -z $flag && -z $extra ]] || die "Oczekiwano jednego URL HTTPS w wierszu: $file: $line"
            else
                [[ $entry =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die "Niepoprawna nazwa: $file: $entry"
                [[ -z $extra && ( -z $flag || ( $source == snap && $flag == --classic ) ) ]] || die "Niepoprawne opcje: $file: $line"
            fi
            [[ ! ${seen[$source:$entry]+exists} ]] || continue
            seen[$source:$entry]=1
            case $source in
                apt) apt_packages+=("$entry") ;;
                snap) snap_packages+=("$entry${flag:+ $flag}") ;;
                deb) deb_urls+=("$entry") ;;
            esac
        done < "$file"
    done
done
run() {
    printf '%q ' "$@"; printf '\n'
    if ! $dry_run; then "$@"; fi
}
work=
trap 'if [[ -n $work ]]; then rm -rf -- "$work"; fi' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Sprawdź wymagane narzędzia przed pobieraniem i instalacją.
if ! $dry_run; then
    if ((${#apt_packages[@]} + ${#deb_urls[@]} + ${#snap_packages[@]})); then need sudo; fi
    if ((${#apt_packages[@]} + ${#deb_urls[@]})); then need apt-get; fi
    if ((${#apt_packages[@]})); then need apt-cache; fi
    if ((${#snap_packages[@]})); then need snap; fi
    if ((${#deb_urls[@]})); then
        for command in curl dpkg-deb dpkg; do need "$command"; done
        host_arch=$(dpkg --print-architecture)
        work=$(mktemp -d "${TMPDIR:-/tmp}/os-scripts-deb-XXXXXXXX")
    fi
fi
# Najpierw pobierz wszystkie DEB. Sudo jest używane dopiero po ich sprawdzeniu.
for i in "${!deb_urls[@]}"; do
    file="${work:-${TMPDIR:-/tmp}/os-scripts-deb-XXXXXXXX}/$((i + 1)).deb"
    run curl --fail --location --show-error --proto '=https' --proto-redir '=https' \
        --connect-timeout 30 --max-time 1800 --retry 3 --retry-delay 2 \
        --output "$file" -- "${deb_urls[i]}"
    if ! $dry_run; then
        package=$(dpkg-deb -f "$file" Package) || die "Niepoprawny plik DEB: ${deb_urls[i]}"
        arch=$(dpkg-deb -f "$file" Architecture) || die "Brak architektury DEB: $package"
        [[ $arch == "$host_arch" || $arch == all ]] || die "Niezgodna architektura $arch: $package (system: $host_arch)"
        dpkg-deb --fsys-tarfile "$file" >/dev/null || die "Uszkodzone dane pakietu: $package"
        echo "# Pobrano: $package ($arch)"
    fi
    deb_files+=("$file")
done
if ((${#apt_packages[@]} + ${#deb_files[@]})); then
    run sudo apt-get update
    if ! $dry_run; then
        for package in "${apt_packages[@]}"; do
            candidate=$(LC_ALL=C apt-cache policy "$package" | awk '/Candidate:/ {print $2}')
            [[ -n $candidate && $candidate != '(none)' ]] || die "Brak kandydata APT: $package — sprawdź nazwę/repozytorium."
        done
    fi
    # Jedna transakcja APT + DEB, ze sprawdzeniem zależności przed zapisem.
    run apt-get --simulate install -- "${apt_packages[@]}" "${deb_files[@]}"
    run sudo apt-get install -y -- "${apt_packages[@]}" "${deb_files[@]}"
fi
for entry in "${snap_packages[@]}"; do
    read -r name flag <<< "$entry"
    if ! $dry_run && snap list "$name" >/dev/null 2>&1; then
        echo "Snap już zainstalowany: $name"
        continue
    fi
    args=(sudo snap install "$name")
    [[ -z $flag ]] || args+=("$flag")
    run "${args[@]}"
done
