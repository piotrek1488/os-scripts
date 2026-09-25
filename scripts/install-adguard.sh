#!/usr/bin/env bash
# AdGuard for Linux (AdGuardCLI), oficjalny instalator kanału release.
set -euo pipefail
url=https://raw.githubusercontent.com/AdguardTeam/AdGuardCLI/release/install.sh
usage() { echo 'Użycie: bash scripts/install-adguard.sh [--dry-run|--apply]'; }
(($# <= 1)) || { usage >&2; exit 2; }
case ${1:---dry-run} in
    --dry-run)
        printf 'curl -fsSL %q | sh -s -- -v\n' "$url"
        echo '# Przy wykonaniu skrypt najpierw pobiera cały instalator do pliku tymczasowego.'
        exit 0 ;;
    --apply) ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
command -v curl >/dev/null || { echo 'Brak curl. Zainstaluj: sudo apt-get install curl ca-certificates' >&2; exit 1; }
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 30 --max-time 120 --output "$work/install.sh" -- "$url"
[[ -s $work/install.sh ]] || { echo 'Pobrano pusty instalator AdGuarda.' >&2; exit 1; }
sh -n "$work/install.sh"
# Te same argumenty i interpreter co w poleceniu producenta.
sh -s -- -v < "$work/install.sh"
