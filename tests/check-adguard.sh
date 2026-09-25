#!/usr/bin/env bash
# Offline: zamiast instalatora producenta uruchamiany jest mały skrypt testowy.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/bin"
export OS_SCRIPTS_ADGUARD_TEST_LOG="$work/log"
export OS_SCRIPTS_ADGUARD_TEST_PATH="$work/download-path"
cat > "$work/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf 'download\n' >> "$OS_SCRIPTS_ADGUARD_TEST_LOG"
while (($#)); do
    if [[ $1 == --output ]]; then output=$2; shift; fi
    shift
done
printf '%s\n' "$output" > "$OS_SCRIPTS_ADGUARD_TEST_PATH"
cat > "$output" <<'PAYLOAD'
#!/bin/sh
printf 'executed:%s\n' "$*" >> "$OS_SCRIPTS_ADGUARD_TEST_LOG"
PAYLOAD
case ${OS_SCRIPTS_ADGUARD_TEST_MODE:-success} in
    failure) exit 22;;
    invalid) printf 'if\n' > "$output";;
    empty) : > "$output";;
esac
MOCK
chmod +x "$work/bin/curl"
run_installer() { PATH="$work/bin:$PATH" bash "$ROOT/scripts/install-adguard.sh" "$@"; }
assert_cleanup() {
    downloaded=$(cat "$OS_SCRIPTS_ADGUARD_TEST_PATH")
    [[ ! -e $downloaded && ! -d ${downloaded%/*} ]]
}
run_installer > "$work/dry-run"
[[ ! -e $OS_SCRIPTS_ADGUARD_TEST_LOG ]]
run_installer --apply
[[ $(cat "$OS_SCRIPTS_ADGUARD_TEST_LOG") == $'download\nexecuted:-v' ]]
assert_cleanup
for mode in failure invalid empty; do
    : > "$OS_SCRIPTS_ADGUARD_TEST_LOG"
    export OS_SCRIPTS_ADGUARD_TEST_MODE=$mode
    if run_installer --apply > "$work/error" 2>&1; then
        echo "Nieoczekiwany sukces: $mode" >&2; exit 1
    fi
    [[ $(cat "$OS_SCRIPTS_ADGUARD_TEST_LOG") == download ]]
    assert_cleanup
done
echo 'OK: AdGuard dry-run, argument -v, błędy pobierania/składni i sprzątanie.'
