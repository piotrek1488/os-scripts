#!/usr/bin/env bash
# Kontrola wartości poświadczeń; wypisuje tylko nazwy plików, nigdy trafienia.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
source "$ROOT/scripts/lib/ulauncher.sh"
need rg
need jq
need tar
pattern='(^|[^A-Za-z0-9])(sk-(proj-|svcacct-)?[A-Za-z0-9_-]{24,}|AIza[0-9A-Za-z_-]{30,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{16,}|AKIA[A-Z0-9]{16})|-----BEGIN ((RSA|EC|DSA|OPENSSH|PGP) )?PRIVATE KEY( BLOCK)?-----|https?://[^[:space:]/<>:@]+:[^[:space:]/<>@]{3,}@'
# Poświadczenia CLI również w komentarzach (np. stare aliasy).
pattern+='|curl.*[[:space:]](--user|-u)[[:space:]]+[A-Za-z0-9_.@-]+:[A-Za-z0-9+/_=-]{6,}|mysql.*[[:space:]](-p|--password=)[A-Za-z0-9+/_=-]{6,}'
scan_stream() {
    local status=0
    # Bez -q: odbierz cały strumień archiwum, bez SIGPIPE i bez ujawniania treści.
    grep -aE -- "$pattern" >/dev/null || status=$?
    case $status in
        0) echo "BŁĄD: możliwy sekret w $1" >&2; return 1 ;;
        1) return 0 ;;
        *) die 'Błąd sprawdzania sekretów.' ;;
    esac
}
cd -- "$ROOT"
while IFS= read -r -d '' file; do
    [[ ! -L $file ]] || continue
    # Funkcja czyta stdin i wypisuje jedynie nazwę błędnego pliku; nic do niego nie zapisuje.
    # shellcheck disable=SC2094
    scan_stream "$file" < "$file"
    case $file in
        *.tar.gz|*.tgz) tar -xOzf "$file" | scan_stream "$file (zawartość archiwum)" ;;
    esac
done < <(rg --files --hidden --no-ignore -0 -g '!.git/**')
for file in config/settings/*.json config/ulauncher/*.json; do
    jq -e '
        all(.. | objects | to_entries[];
            if (.key | test("^(api[_-]?key|access[_-]?token|refresh[_-]?token|id[_-]?token|token|client[_-]?secret|secret[_-]?key|password|passwd|authorization|cookie|openai_api_key|gemini_api_key|github_token)$"; "i"))
            then (.value == null or .value == "") else true end)
    ' "$file" >/dev/null 2>&1 || die "Niepusta wartość poświadczenia lub błędny JSON: $file"
done
validate_ulauncher_snapshot config/ulauncher/snapshot.json
echo 'OK: brak wykrytych sekretów w plikach i archiwach; snapshoty bez wartości poświadczeń.'
