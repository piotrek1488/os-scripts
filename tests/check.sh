#!/usr/bin/env bash
# Testy bez sieci, sudo, instalacji pakietów i zapisu do bieżących ustawień.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
for command in jq dpkg-deb tar; do need "$command"; done
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

cat > "$work/input.jsonc" <<'JSON'
{
    // Zachowaj URL, ukośniki i cudzysłowy w literałach.
    "url": "https://example.com/a//b/*c*/",
    "escaped": "quote: \" and slash: \\",
    "nested": {"private": "keep", "changed": 1},
    "array": [1, 2,], /* komentarz */
}
JSON
merge_jsonc "$work/input.jsonc" '{"nested":{"changed":2},"array":[3]}' > "$work/merged.json"
jq -e '.url == "https://example.com/a//b/*c*/" and .nested == {private:"keep",changed:2} and .array == [3] and .escaped == "quote: \" and slash: \\"' "$work/merged.json" >/dev/null
for bad in '[]' '{"broken":}' 'null'; do
    printf '%s' "$bad" > "$work/invalid"
    if merge_jsonc "$work/invalid" '{}' >/dev/null 2>&1; then fail 'Niepoprawny JSON zaakceptowany'; fi
done
printf '; keep comment\n[Other]\nunknown=yes\n[Settings]\nkeep=42\ngtk-application-prefer-dark-theme=1\n' > "$work/input.ini"
merge_ini "$work/input.ini" '{"Settings":{"gtk-application-prefer-dark-theme":"0","new":"hello"}}' "$work/output.ini"
grep -Fxq '; keep comment' "$work/output.ini"
grep -Fxq 'keep=42' "$work/output.ini"
grep -Fxq 'unknown=yes' "$work/output.ini"
grep -Fxq 'gtk-application-prefer-dark-theme=0' "$work/output.ini"
merge_ini "$work/output.ini" '{"Settings":{"gtk-application-prefer-dark-theme":"0","new":"hello"}}' "$work/twice.ini"
cmp "$work/output.ini" "$work/twice.ini"

printf 'user_pref("other", true);\n' > "$work/user.js"
render_firefox "$work/user.js" '{"browser.theme.toolbar-theme":0}' "$work/user.once.js"
render_firefox "$work/user.once.js" '{"browser.theme.toolbar-theme":0}' "$work/user.twice.js"
cmp "$work/user.once.js" "$work/user.twice.js"
grep -Fxq 'user_pref("other", true);' "$work/user.twice.js"
mkdir "$work/firefox"
printf '[Profile0]\nPath=profile one\nIsRelative=1\nDefault=1\n[InstallABC]\nDefault=profile two\n' > "$work/firefox/profiles.ini"
[[ $(firefox_profile "$work/firefox") == "$work/firefox/profile two" ]] || fail 'Domyślny profil instalacji'
printf '[Profile0]\nPath=/tmp/profile space\nIsRelative=0\nDefault=1\n' > "$work/firefox/profiles.ini"
[[ $(firefox_profile "$work/firefox") == '/tmp/profile space' ]] || fail 'Bezwzględny profil'
printf '[Profile0]\nPath=one\n[Profile1]\nPath=two\n' > "$work/firefox/profiles.ini"
[[ -z $(firefox_profile "$work/firefox") ]] || fail 'Niejednoznaczny profil'
shortcuts=$(merge_shortcut_paths "@as ['/existing/']" /new/)
[[ $shortcuts == "['/existing/', '/new/']" ]] || fail 'Scalanie skrótów'
[[ $(merge_shortcut_paths "$shortcuts" /new/) == "$shortcuts" ]] || fail 'Duplikat skrótu'
[[ $(merge_shortcut_paths '@as []' /new/) == "['/new/']" ]] || fail 'Pusta lista skrótów'
settings_home="$work/home"
mkdir "$settings_home"
ln -s /etc "$settings_home/outside"
if (inside_home "$settings_home/outside/settings") >/dev/null 2>&1; then fail 'Zapis poza HOME'; fi

# Rzeczywista ekstrakcja zasobów i sprawdzenie linków, wyłącznie w /tmp.
mkdir "$work/assets"
tar -xzf "$ROOT/config/settings/assets/desktop.tar.gz" -C "$work/assets" --no-same-owner --no-same-permissions
find "$work/assets" -type l -print0 | xargs -0 -r realpath -m -- > "$work/asset-links"
while IFS= read -r target; do
    [[ $target == "$work/assets/"* ]] || fail "Link poza zasobami: $target"
done < "$work/asset-links"
[[ -f $work/assets/.local/share/backgrounds/os-scripts-current.jpg ]] || fail 'Brak tapety'
echo 'OK: scalanie JSONC/INI, Firefox, skróty, ścieżki i archiwum.'

# Instalator pracuje w kopii repo. curl kopiuje lokalny DEB, sudo i APT tylko logują.
fixture="$work/repo with spaces"
mkdir -p "$fixture/packages/deb" "$work/bin" "$work/pkg/DEBIAN"
cp "$ROOT/install.sh" "$fixture/"
cp "$ROOT/packages/deb/"*.txt "$fixture/packages/deb/"
printf 'Package: fixture-app\nVersion: 1.0\nArchitecture: amd64\nMaintainer: Test <test@example.invalid>\nDescription: Synthetic package for offline installer tests\n' > "$work/pkg/DEBIAN/control"
dpkg-deb --build --root-owner-group "$work/pkg" "$work/fixture.deb" >/dev/null
export OS_SCRIPTS_TEST_DEB="$work/fixture.deb" OS_SCRIPTS_TEST_LOG="$work/commands.log"
export OS_SCRIPTS_TEST_DOWNLOADS="$work/downloads.log"
: > "$OS_SCRIPTS_TEST_LOG"
: > "$OS_SCRIPTS_TEST_DOWNLOADS"
cat > "$work/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
output= url=
while (($#)); do
    case $1 in --output) output=$2; shift;; --) url=$2; break;; esac
    shift
done
printf 'curl %s\n' "$url" >> "$OS_SCRIPTS_TEST_LOG"
printf '%s\n' "$output" >> "$OS_SCRIPTS_TEST_DOWNLOADS"
[[ $url != *fail.deb ]] || exit 22
cp -- "$OS_SCRIPTS_TEST_DEB" "$output"
MOCK
cat > "$work/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf 'sudo %s\n' "$*" >> "$OS_SCRIPTS_TEST_LOG"
for arg in "$@"; do
    if [[ $arg == *.deb ]]; then
        [[ -f $arg ]] || exit 1
        cmp -- "$OS_SCRIPTS_TEST_DEB" "$arg" || exit 1
    fi
done
MOCK
cat > "$work/bin/apt-get" <<'MOCK'
#!/usr/bin/env bash
printf 'apt-get %s\n' "$*" >> "$OS_SCRIPTS_TEST_LOG"
exit "${OS_SCRIPTS_TEST_APT_FAIL:-0}"
MOCK
cat > "$work/bin/dpkg" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "${OS_SCRIPTS_TEST_ARCH:-amd64}"
MOCK
cat > "$work/bin/jq" <<'MOCK'
#!/usr/bin/env bash
# Pobieranie i instalacja DEB nie mogą używać jq.
exit 99
MOCK
chmod +x "$work/bin/"*
run_installer() { PATH="$work/bin:$PATH" bash "$fixture/install.sh" --source deb essentials "$@"; }
assert_cleanup() {
    while IFS= read -r file; do
        [[ ! -e $file && ! -d ${file%/*} ]] || fail 'Pozostawiony katalog pobierania'
    done < "$OS_SCRIPTS_TEST_DOWNLOADS"
}
expect_failure() {
    : > "$OS_SCRIPTS_TEST_LOG"
    if run_installer > "$work/failure.log" 2>&1; then fail 'Instalator powinien odmówić'; fi
    if grep -q '^sudo .*install' "$OS_SCRIPTS_TEST_LOG"; then fail 'Instalacja po błędzie'; fi
    assert_cleanup
}
# Same URL-e, komentarz, CRLF i ostatni wiersz bez końcowego znaku nowej linii.
url='https://example.invalid/app.deb?build=1&arch=amd64'
printf '# apps\r\n\r\n%s\r\n%s # duplicate' "$url" "$url" > "$fixture/packages/deb/essentials.txt"
run_installer --dry-run > "$work/dry-run.log"
[[ ! -s $OS_SCRIPTS_TEST_LOG && ! -s $OS_SCRIPTS_TEST_DOWNLOADS ]] || fail 'Skutki uboczne dry-run'
run_installer > "$work/install.log"
[[ $(grep -c '^curl ' "$OS_SCRIPTS_TEST_LOG") == 1 ]] || fail 'Deduplikacja DEB'
grep -Fxq "curl $url" "$OS_SCRIPTS_TEST_LOG"
grep -q '^apt-get --simulate install' "$OS_SCRIPTS_TEST_LOG"
grep -q '^sudo apt-get install -y' "$OS_SCRIPTS_TEST_LOG"
assert_cleanup
# Kolejne uruchomienie pobiera plik ponownie, a różne URL-e nie nadpisują się.
printf '%s\nhttps://other.invalid/app.deb\n' "$url" > "$fixture/packages/deb/essentials.txt"
: > "$OS_SCRIPTS_TEST_LOG"
: > "$OS_SCRIPTS_TEST_DOWNLOADS"
run_installer > /dev/null
[[ $(grep -c '^curl ' "$OS_SCRIPTS_TEST_LOG") == 2 ]] || fail 'Nie pobrano obu URL-i'
[[ $(sort -u "$OS_SCRIPTS_TEST_DOWNLOADS" | wc -l) == 2 ]] || fail 'Kolizja nazw plików'
[[ $(head -n 2 "$OS_SCRIPTS_TEST_LOG" | grep -c '^curl ') == 2 ]] || fail 'Instalacja przed końcem pobierania'
assert_cleanup
printf '%s\nhttps://example.invalid/fail.deb\n' "$url" > "$fixture/packages/deb/essentials.txt"
expect_failure
if grep -q '^sudo ' "$OS_SCRIPTS_TEST_LOG"; then fail 'Sudo mimo błędu pobrania'; fi
printf '%s\n' "$url" > "$fixture/packages/deb/essentials.txt"
export OS_SCRIPTS_TEST_APT_FAIL=100
expect_failure
unset OS_SCRIPTS_TEST_APT_FAIL
for invalid in 'http://example.invalid/app.deb' 'fixture-app https://example.invalid/app.deb' 'https://example.invalid/app.deb extra'; do
    printf '%s\n' "$invalid" > "$fixture/packages/deb/essentials.txt"
    expect_failure
    [[ ! -s $OS_SCRIPTS_TEST_LOG ]] || fail 'Niepoprawny wiersz nie zatrzymał operacji'
done
printf '%s\n' "$url" > "$fixture/packages/deb/essentials.txt"
export OS_SCRIPTS_TEST_ARCH=arm64
expect_failure
grep -q 'Niezgodna architektura' "$work/failure.log"
unset OS_SCRIPTS_TEST_ARCH
# Pakiety niezależne od architektury również powinny się instalować.
sed -i 's/Architecture: amd64/Architecture: all/' "$work/pkg/DEBIAN/control"
dpkg-deb --build --root-owner-group "$work/pkg" "$work/fixture.deb" >/dev/null
run_installer > /dev/null
assert_cleanup
printf '<html>not a deb</html>' > "$work/fixture.deb"
expect_failure
if grep -q '^sudo ' "$OS_SCRIPTS_TEST_LOG"; then fail 'Sudo mimo niepoprawnego DEB'; fi
: > "$fixture/packages/deb/essentials.txt"
: > "$OS_SCRIPTS_TEST_LOG"
run_installer > /dev/null
[[ ! -s $OS_SCRIPTS_TEST_LOG ]] || fail 'Pusta lista wywołała instalację'
# Prawdziwe listy: podgląd wszystkich kategorii, także aliasu optional.
bash "$ROOT/install.sh" --dry-run > "$work/all-plan"
bash "$ROOT/install.sh" --dry-run --source snap optional > "$work/optional-plan"
bash "$ROOT/install.sh" --dry-run --source deb dev > "$work/dev-plan"
[[ $(grep -c '^curl ' "$work/dev-plan") == 2 ]] || fail 'Wybór kategorii DEB'
if grep -q 'caprine\|heroic' "$work/dev-plan"; then fail 'DEB z niewybranej kategorii'; fi
echo 'OK: listy URL bez jq, pobieranie, architektura, błędy curl/APT, sprzątanie i dry-run.'

bash "$ROOT/tests/check-adguard.sh"

bash "$ROOT/tests/check-desktop.sh"

bash "$ROOT/tests/check-ulauncher.sh"

bash "$ROOT/tests/check-no-secrets.sh"

bash "$ROOT/tests/check-setup.sh"

bash "$ROOT/tests/check-bash.sh"
