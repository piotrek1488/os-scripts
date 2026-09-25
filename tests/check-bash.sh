#!/usr/bin/env bash
# Tylko pliki tymczasowe; test nie wczytuje osobistej konfiguracji Bash.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
fixture="$work/repo with spaces"
target="$work/home with spaces"
mkdir -p "$fixture/scripts/lib" "$fixture/config/bash" "$target"
cp "$ROOT/scripts/restore-bash.sh" "$fixture/scripts/"
cp "$ROOT/scripts/lib/settings.sh" "$fixture/scripts/lib/"
cp "$ROOT/config/bash/"{.bashrc.user,.bash_aliases,.bash_functions,bashrc-loader.sh} "$fixture/config/bash/"
# Marker udowadnia, że nawet kod najwyższego poziomu nie zostaje uruchomiony.
export OS_SCRIPTS_BASH_TEST_MARKER="$work/should-not-run"
cat >> "$fixture/config/bash/.bash_functions" <<'FIXTURE'
printf invoked > "$OS_SCRIPTS_BASH_TEST_MARKER"
FIXTURE
cat > "$target/.bashrc" <<'FIXTURE'
# Existing Bash configuration
printf invoked > "$OS_SCRIPTS_BASH_TEST_MARKER"
FIXTURE
printf 'alias local_only=true\n' > "$target/.bash_aliases"
cp "$target/.bashrc" "$work/original-bashrc"
cp "$target/.bash_aliases" "$work/original-aliases"
run_restore() { bash "$fixture/scripts/restore-bash.sh" --home-dir "$target" "$@"; }
run_restore --dry-run > "$work/preview"
[[ ! -e $target/.bashrc.user && ! -e $target/.local && ! -e $OS_SCRIPTS_BASH_TEST_MARKER ]] || fail 'Skutki uboczne podglądu'
cmp "$target/.bashrc" "$work/original-bashrc"
cmp "$target/.bash_aliases" "$work/original-aliases"
for args in '--apply --dry-run' '--dry-run --apply' '--unknown' '--home-dir'; do
    read -r -a argv <<< "$args"
    if run_restore "${argv[@]}" >/dev/null 2>&1; then fail 'Przyjęto błędne argumenty'; fi
done
if ((EUID != 0)); then
    run_restore --apply > "$work/applied"
    [[ ! -e $OS_SCRIPTS_BASH_TEST_MARKER ]] || fail 'Wykonano odtwarzaną konfigurację'
    for name in .bashrc.user .bash_aliases .bash_functions; do
        cmp "$fixture/config/bash/$name" "$target/$name"
        [[ $(stat -c %a "$target/$name") == 600 ]] || fail 'Nieprywatny plik wynikowy'
    done
    grep -Fxq '# Existing Bash configuration' "$target/.bashrc"
    [[ $(grep -c '^# BEGIN os-scripts bash$' "$target/.bashrc") == 1 ]] || fail 'Brak loadera'
    backups=("$target/.local/state/os-scripts/backups/"*)
    [[ ${#backups[@]} == 1 && -d ${backups[0]} ]] || fail 'Brak kopii zapasowej'
    [[ $(stat -c %a "${backups[0]}") == 700 ]] || fail 'Nieprywatny katalog kopii'
    cmp "${backups[0]}/.bashrc" "$work/original-bashrc"
    cmp "${backups[0]}/.bash_aliases" "$work/original-aliases"
    cp "$target/.bashrc" "$work/once"
    run_restore --apply > "$work/twice"
    cmp "$target/.bashrc" "$work/once"
    backups=("$target/.local/state/os-scripts/backups/"*)
    [[ ${#backups[@]} == 1 ]] || fail 'Ponowne uruchomienie utworzyło zbędną kopię'
    [[ ! -e $OS_SCRIPTS_BASH_TEST_MARKER ]] || fail 'Powtórzenie wykonało konfigurację'
else
    if run_restore --apply >/dev/null 2>&1; then fail 'Zaakceptowano root'; fi
fi
# Niepoprawny plik źródłowy musi zatrzymać całość przed zapisem i nie ujawnić treści.
failure_mode=--dry-run
if ((EUID != 0)); then failure_mode=--apply; fi
cp "$fixture/config/bash/.bash_functions" "$work/functions"
printf 'if fixture-private-value\n' >> "$fixture/config/bash/.bash_functions"
cp "$target/.bashrc" "$work/before-error"
if run_restore "$failure_mode" > "$work/error" 2>&1; then fail 'Niepoprawna składnia została zaakceptowana'; fi
if grep -q fixture-private-value "$work/error"; then fail 'Ujawniono treść błędnego pliku'; fi
cmp "$target/.bashrc" "$work/before-error"
cp "$work/functions" "$fixture/config/bash/.bash_functions"
printf '\n# BEGIN os-scripts bash\n' >> "$target/.bashrc"
if run_restore "$failure_mode" >/dev/null 2>&1; then fail 'Niekompletny blok loadera'; fi
cp "$work/before-error" "$target/.bashrc"
# Nie zapisuj konfiguracji ani prywatnych kopii do repozytorium, również przez linki.
if bash "$fixture/scripts/restore-bash.sh" --home-dir "$fixture/private" --dry-run >/dev/null 2>&1; then fail 'Cel w repozytorium'; fi
mkdir "$work/linked"
ln -s "$fixture/config/bash/.bash_aliases" "$work/linked/.bash_aliases"
if bash "$fixture/scripts/restore-bash.sh" --home-dir "$work/linked" --dry-run >/dev/null 2>&1; then fail 'Dowiązanie pliku do repo'; fi
mkdir "$work/linked-backup"
ln -s "$fixture" "$work/linked-backup/.local"
if bash "$fixture/scripts/restore-bash.sh" --home-dir "$work/linked-backup" --dry-run >/dev/null 2>&1; then fail 'Dowiązanie kopii do repo'; fi
# Składnia prawdziwych definicji jest sprawdzana bez source i bez wywoływania funkcji.
for file in "$ROOT/config/bash/"{.bashrc.user,.bash_aliases,.bash_functions,bashrc-loader.sh}; do
    env -u BASH_ENV bash --noprofile --norc -n "$file"
done
echo 'OK: Bash — podgląd, kopie, zachowanie .bashrc, idempotencja, błędy składni i ochrona ścieżek; definicje niewykonywane.'
