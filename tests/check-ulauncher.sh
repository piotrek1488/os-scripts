#!/usr/bin/env bash
# Testy danych i instalatora na atrapach — bez sieci, APT i uruchamiania dodatków.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
source "$ROOT/scripts/lib/ulauncher.sh"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
python3 - "$work" <<'PY'
import pickle, sys
from pathlib import Path
root=Path(sys.argv[1])
(root/'old.db').write_bytes(pickle.dumps({'keyword':'old','api_key':'test-only-secret','unknown':'keep'},protocol=2))
(root/'invalid.db').write_bytes(pickle.dumps({'object':set()},protocol=2))
PY
printf '{"keyword":"new"}\n' > "$work/prefs.json"
merge_ulauncher_preferences "$work/old.db" "$work/prefs.json" "$work/new.db"
merge_ulauncher_preferences "$work/new.db" "$work/prefs.json" "$work/twice.db"
cmp "$work/new.db" "$work/twice.db"
python3 - "$work/new.db" <<'PY'
import pickle,sys
with open(sys.argv[1],'rb') as f: d=pickle.load(f)
assert d == {'keyword':'new','api_key':'test-only-secret','unknown':'keep'}
PY
if merge_ulauncher_preferences "$work/invalid.db" "$work/prefs.json" "$work/rejected.db" > "$work/error" 2>&1; then fail 'Obiekt wykonywalny został zaakceptowany'; fi
[[ ! -e $work/rejected.db ]] || fail 'Zapis po błędzie pickle'
if grep -q 'test-only-secret' "$work/error"; then fail 'Ujawnienie wartości sekretu'; fi

# Snapshot z poświadczeniem jest odrzucany, także przy brakującej deklaracji private_keys.
printf '{"extensions":[{"preferences":{"api_key":"test-only-value"}}]}\n' > "$work/rejected.json"
if (validate_ulauncher_snapshot "$work/rejected.json") > "$work/rejected-log" 2>&1; then fail 'Sekret w snapshotcie zaakceptowany'; fi
if grep -q 'test-only-value' "$work/rejected-log"; then fail 'Sekret ujawniony w błędzie walidacji'; fi
printf '{"extensions":[{"preferences":{"customCredential":"test-only-value"},"private_keys":["customCredential"]}]}\n' > "$work/rejected.json"
if (validate_ulauncher_snapshot "$work/rejected.json") >/dev/null 2>&1; then fail 'Zignorowano private_keys'; fi
if (ulauncher_outside_repository "$ROOT/config/private.db") >/dev/null 2>&1; then fail 'Baza dopuszczona wewnątrz repo'; fi
ln -s "$ROOT" "$work/link-to-repo"
if (ulauncher_outside_repository "$work/link-to-repo/private.db") >/dev/null 2>&1; then fail 'Dowiązanie do repo dopuszczone'; fi
ulauncher_outside_repository "$work/outside.db"

# Kopia repo i atrapowe repozytoria GitHub zawierają wyłącznie sztuczne dane.
fixture="$work/repo"
mkdir -p "$fixture/scripts/lib" "$fixture/config/ulauncher" "$fixture/packages/ulauncher" "$work/bin" "$work/home"
cp "$ROOT/scripts/setup-ulauncher.sh" "$fixture/scripts/"
cp "$ROOT/scripts/lib/"{settings.sh,ulauncher.sh,merge-jsonc.jq} "$fixture/scripts/lib/"
cp "$ROOT/packages/ulauncher/apt.txt" "$fixture/packages/ulauncher/"
python3 - "$work" <<'PY'
from pathlib import Path
import json,tarfile,hashlib,sys
w=Path(sys.argv[1]); ref='a'*40; items=[]
for name,kind in [('com.github.test.extension','extension'),('libadwaita','theme'),('libadwaita-dark','theme')]:
    source=w/'sources'/name/'root'; source.mkdir(parents=True)
    manifest={'name':name,'required_api_version':'^2.0.0','preferences':[{'id':'keyword'}]}
    (source/'manifest.json').write_text(json.dumps(manifest))
    (source/'main.py').write_text('raise RuntimeError("Fixture code must never run")\n')
    archive=w/(name+'.tar.gz')
    with tarfile.open(archive,'w:gz') as t: t.add(source,arcname='root')
    item={'id':name,'name':name,'url':'https://github.com/test/'+name,'ref':ref,
          'download_url':f'https://codeload.github.com/test/{name}/tar.gz/{ref}',
          'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),
          'last_commit_time':'2026-09-25T00:00:00','preferences':{'keyword':'restore'}}
    items.append(item)
d={'settings':{'theme-name':'libadwaita-dark'},'extensions':items[:1],'themes':items[1:]}
(w/'repo/config/ulauncher/snapshot.json').write_text(json.dumps(d))
PY
export OS_SCRIPTS_ULAUNCHER_TEST_WORK="$work"
export OS_SCRIPTS_ULAUNCHER_REALPATH
OS_SCRIPTS_ULAUNCHER_REALPATH=$(command -v realpath)
cat > "$work/bin/realpath" <<'MOCK'
#!/usr/bin/env bash
if [[ $# == 2 && $1 == -- && $2 == "$HOME" ]]; then printf '%s/home\n' "$OS_SCRIPTS_ULAUNCHER_TEST_WORK"
else exec "$OS_SCRIPTS_ULAUNCHER_REALPATH" "$@"; fi
MOCK
cat > "$work/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
out= url=
while (($#)); do
    case $1 in --output) out=$2; shift;; --) url=$2; break;; esac
    shift
done
name=${url#https://codeload.github.com/test/}; name=${name%%/tar.gz/*}
printf 'download %s\n' "$name" >> "$OS_SCRIPTS_ULAUNCHER_TEST_WORK/commands"
if [[ ${OS_SCRIPTS_ULAUNCHER_BAD_DOWNLOAD:-} == 1 ]]; then printf 'bad archive' > "$out"
else cp "$OS_SCRIPTS_ULAUNCHER_TEST_WORK/$name.tar.gz" "$out"; fi
MOCK
cat > "$work/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$OS_SCRIPTS_ULAUNCHER_TEST_WORK/commands"
if [[ $* == *--simulate* && ${OS_SCRIPTS_ULAUNCHER_APT_FAIL:-} == 1 ]]; then exit 100; fi
MOCK
cat > "$work/bin/apt-cache" <<'MOCK'
#!/usr/bin/env bash
printf '  Candidate: 5.16.2\n'
MOCK
cat > "$work/bin/dpkg-query" <<'MOCK'
#!/usr/bin/env bash
printf '5.16.2\n'
MOCK
cat > "$work/bin/pgrep" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$work/bin/"*
run_setup() {
    PATH="$work/bin:$PATH" XDG_CONFIG_HOME="$work/home/.config" XDG_DATA_HOME="$work/home/.local/share" \
        bash "$fixture/scripts/setup-ulauncher.sh" "$@"
}
: > "$work/commands"
run_setup --dry-run > "$work/plan"
[[ ! -s $work/commands ]] || fail 'Podgląd wywołał sieć lub sudo'
[[ ! -e $work/home/.config ]] || fail 'Podgląd zapisał konfigurację'
if ((EUID != 0)); then
    export OS_SCRIPTS_ULAUNCHER_BAD_DOWNLOAD=1
    if run_setup --apply > "$work/error" 2>&1; then fail 'Błędna suma archiwum zaakceptowana'; fi
    unset OS_SCRIPTS_ULAUNCHER_BAD_DOWNLOAD
    if grep -q '^sudo ' "$work/commands"; then fail 'APT przed sprawdzeniem archiwów'; fi
    : > "$work/commands"
    export OS_SCRIPTS_ULAUNCHER_APT_FAIL=1
    if run_setup --apply > "$work/error" 2>&1; then fail 'Zignorowany błąd symulacji APT'; fi
    unset OS_SCRIPTS_ULAUNCHER_APT_FAIL
    [[ ! -e $work/home/.config ]] || fail 'Konfiguracja zapisana mimo błędu APT'
    run_setup --apply > "$work/applied"
    config="$work/home/.config/ulauncher"
    [[ -f $config/user-themes/libadwaita/manifest.json && -f $config/user-themes/libadwaita-dark/manifest.json ]] || fail 'Brak motywu'
    jq -e '."theme-name" == "libadwaita-dark"' "$config/settings.json" >/dev/null
    jq -e 'has("com.github.test.extension")' "$config/extensions.json" >/dev/null
    cp "$work/old.db" "$config/ext_preferences/com.github.test.extension.db"
    cp "$config/extensions.json" "$work/registry-before"
    run_setup --apply > "$work/reapplied"
    cmp "$work/registry-before" "$config/extensions.json"
    python3 - "$config/ext_preferences/com.github.test.extension.db" <<'PY'
import pickle,sys
with open(sys.argv[1],'rb') as f: d=pickle.load(f)
assert d['keyword']=='restore' and d['api_key']=='test-only-secret' and d['unknown']=='keep'
PY
    if grep -q 'test-only-secret' "$work/applied" "$work/reapplied"; then fail 'Sekret w logu instalatora'; fi
    [[ $(find "$work/home/.local/state/os-scripts/backups" -name '*.db' | wc -l) -ge 1 ]] || fail 'Brak kopii preferencji'
fi
# Snapshot publiczny nie może zawierać wartości pól prywatnych.
jq -e 'all(.extensions[]; (.private_keys // []) as $private |
    all(.preferences|keys[]; . as $key | $private | index($key) == null))' "$ROOT/config/ulauncher/snapshot.json" >/dev/null
if bash "$ROOT/scripts/setup-ulauncher.sh" --apply --dry-run >/dev/null 2>&1; then fail 'Sprzeczne tryby'; fi
echo 'OK: Ulauncher — scalanie pickle, zachowanie sekretów, pobieranie/SHA256, motywy, rejestr, błędy APT i podgląd.'
