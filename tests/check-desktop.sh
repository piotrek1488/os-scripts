#!/usr/bin/env bash
# Offline: bez zapisu do ustawień sesji i bez tworzenia venv w HOME.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

desired='[{"uuid":"z@on","enabled":true},{"uuid":"a@on","enabled":true},{"uuid":"b@off","enabled":false}]'
enabled=$(merge_extension_states "['extra@keep', 'b@off', 'extra@keep']" "$desired" enabled-extensions)
[[ $enabled == "['extra@keep', 'z@on', 'a@on']" ]] || fail 'Scalenie/kolejność włączonych rozszerzeń'
[[ $(merge_extension_states "$enabled" "$desired" enabled-extensions) == "$enabled" ]] || fail 'Idempotencja rozszerzeń'
[[ $(merge_extension_states "['z@on', 'external@off']" "$desired" disabled-extensions) == "['external@off', 'b@off']" ]] || fail 'Lista wyłączonych rozszerzeń'
[[ $(merge_extension_states '@as []' '[]' enabled-extensions) == '[]' ]] || fail 'Pusta lista rozszerzeń'
if (merge_extension_states "['bad;uuid']" "$desired" enabled-extensions) >/dev/null 2>&1; then fail 'Niepoprawny UUID zaakceptowany'; fi

# Każdy przenoszony wpis ma jednoznaczną ścieżkę i sekcję; stare dane nie nadpisują pulpitu.
jq -e '([.dconf[].path] | length == (unique | length)) and
    all(.dconf[]; .different and (.section == "system" or .section == "tweaks" or .section == "extensions"))' "$ROOT/config/settings/desktop.json" >/dev/null
jq -e 'all(.dconf[]; .path | test("^/org/(gtk/|mate/pluma/|gnome/seahorse/)")) and
    (has("extensions") | not)' "$ROOT/config/settings/snapshot.json" >/dev/null
mkdir "$work/extensions"
tar -xzf "$ROOT/config/settings/assets/extensions.tar.gz" -C "$work/extensions" --no-same-owner --no-same-permissions
while IFS= read -r uuid; do
    jq -e --arg uuid "$uuid" '.uuid == $uuid' "$work/extensions/$uuid/metadata.json" >/dev/null
    if [[ -d $work/extensions/$uuid/schemas ]]; then glib-compile-schemas --strict "$work/extensions/$uuid/schemas"; fi
done < <(jq -r '.extensions[] | select(.bundled) | .uuid' "$ROOT/config/settings/desktop.json")
find "$work/extensions" -type l -print0 | xargs -0 -r realpath -m -- > "$work/links"
while IFS= read -r target; do [[ $target == "$work/extensions/"* ]] || fail 'Link rozszerzenia poza archiwum'; done < "$work/links"

# Pułapki na skutki uboczne w trybie podglądu. Symuluj zajęty skrót custom0.
mkdir "$work/bin"
cat > "$work/bin/dconf" <<'MOCK'
#!/usr/bin/env bash
[[ $1 == read ]] || exit 91
if [[ $2 == */custom0/command ]]; then printf "'other-launcher'\n"; fi
MOCK
cat > "$work/bin/gsettings" <<'MOCK'
#!/usr/bin/env bash
[[ $1 == get ]] || exit 92
case $3 in
    enabled-extensions) printf "['external@keep']\n" ;;
    disabled-extensions) printf '@as []\n' ;;
    custom-keybindings) printf "['/existing/']\n" ;;
    *) exit 93 ;;
esac
MOCK
for command in sudo xdg-mime gdbus; do
    printf '#!/usr/bin/env bash\nexit 94\n' > "$work/bin/$command"
done
chmod +x "$work/bin/"*
PATH="$work/bin:$PATH" bash "$ROOT/scripts/restore-desktop.sh" --dry-run > "$work/all"
grep -q '/os_scripts_ulauncher/command' "$work/all"
grep -q 'external@keep' "$work/all"
if grep -q '/custom0/command ' "$work/all"; then fail 'Nadpisanie obcego skrótu'; fi
for section in system tweaks extensions; do
    PATH="$work/bin:$PATH" bash "$ROOT/scripts/restore-desktop.sh" --section "$section" --dry-run > "$work/plan-$section"
done
if grep -q 'dconf write /org/gnome/shell/extensions/' "$work/plan-system"; then fail 'Rozszerzenia w etapie systemowym'; fi
if grep -q '^sudo ' "$work/plan-tweaks" "$work/plan-extensions"; then fail 'sudo poza etapem systemowym'; fi
if bash "$ROOT/scripts/restore-desktop.sh" --apply --dry-run > /dev/null 2>&1; then fail 'Sprzeczne tryby'; fi
bash "$ROOT/scripts/restore-settings.sh" --section desktop --dry-run > "$work/delegated"
grep -q '# 3. Rozszerzenia' "$work/delegated"

# Python: pusty cel w podglądzie pozostaje nieutworzony; istniejące dane są chronione.
bash "$ROOT/scripts/setup-python.sh" --dry-run --venv "$work/venv with spaces" > "$work/python-plan"
[[ ! -e "$work/venv with spaces" ]] || fail 'Podgląd utworzył venv'
grep -q 'python3 -m venv ' "$work/python-plan"
grep -q 'pip install -r ' "$work/python-plan"
mkdir "$work/not-venv"
printf 'keep\n' > "$work/not-venv/user-file"
if bash "$ROOT/scripts/setup-python.sh" --dry-run --venv "$work/not-venv" > /dev/null 2>&1; then fail 'Akceptacja katalogu innego niż venv'; fi
grep -Fxq keep "$work/not-venv/user-file"
if bash "$ROOT/scripts/setup-python.sh" --apply --dry-run > /dev/null 2>&1; then fail 'Sprzeczne tryby Pythona'; fi
echo 'OK: stany rozszerzeń, archiwum i schematy, podział etapów, skróty, podgląd bez zapisu i ochrona katalogu venv.'
