#!/usr/bin/env bash
# Testy orkiestracji i wyboru repozytoriów, bez instalacji i zapisu do /etc lub HOME.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
fixture="$work/repo with spaces"
mkdir -p "$fixture/scripts/lib" "$fixture/config/settings" "$work/bin"
cp "$ROOT/setup.sh" "$fixture/"
cp "$ROOT/scripts/lib/settings.sh" "$fixture/scripts/lib/"
export OS_SCRIPTS_SETUP_LOG="$work/calls"
: > "$OS_SCRIPTS_SETUP_LOG"
for file in install.sh scripts/{setup-repositories,install-adguard,setup-ulauncher,setup-polish,restore-desktop,restore-settings,restore-bash,restore-system-settings,setup-python}.sh; do
    cat > "$fixture/$file" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
name=${0##*/}
if (( $# > 0 )); then
    printf '%s %s\n' "$name" "$*" >> "$OS_SCRIPTS_SETUP_LOG"
else
    printf '%s\n' "$name" >> "$OS_SCRIPTS_SETUP_LOG"
fi
if [[ $name == "${OS_SCRIPTS_SETUP_FAIL:-}" ]]; then exit 23; fi
# Wykrywa błędne flagi przekazane przez nadrzędny skrypt.
case $name in
    install.sh) (($# == 0)) ;;
    restore-settings.sh) [[ $* == '--section apps --skip-ulauncher --apply' ]] ;;
    *) [[ $* == --apply ]] ;;
esac
MOCK
done
cat > "$work/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$OS_SCRIPTS_SETUP_LOG"
case "$*" in
    'apt-get update' | \
    'apt-get install -y -- ca-certificates curl jq snapd dconf-cli python3 python3-venv' | \
    'btmgmt ssp on' | \
    'apt-get install kdeconnect -y' | \
    'firewall-cmd --add-service=kdeconnect --permanent' | \
    'firewall-cmd --reload')
        exit 0
        ;;
    *)
        echo "Nieoczekiwane sudo: $*" >&2
        exit 1
        ;;
esac
MOCK
# Podgląd nie może wymagać ani używać jq.
printf '#!/usr/bin/env bash\nexit 99\n' > "$work/bin/jq"
chmod +x "$work/bin/"*
run_setup() { PATH="$work/bin:$PATH" DBUS_SESSION_BUS_ADDRESS=fixture bash "$fixture/setup.sh" "$@"; }
run_setup > "$work/preview"
run_setup --dry-run > "$work/explicit-preview"
cmp "$work/preview" "$work/explicit-preview"
[[ ! -s $OS_SCRIPTS_SETUP_LOG ]] || fail 'Podgląd uruchomił etap lub sudo'
for args in '--apply --dry-run' '--dry-run --apply' '--from' '--from unknown' '--unknown'; do
    read -r -a argv <<< "$args"
    if run_setup "${argv[@]}" >/dev/null 2>&1; then fail "Zaakceptowano błędne opcje: $args"; fi
done
[[ ! -s $OS_SCRIPTS_SETUP_LOG ]] || fail 'Błędne opcje uruchomiły etap'

if ((EUID != 0)); then
    run_setup --apply > "$work/applied"
    cat > "$work/expected" <<'EXPECTED'
setup-repositories.sh --apply
sudo apt-get update
sudo btmgmt ssp on
sudo apt-get install -y -- ca-certificates curl jq snapd dconf-cli python3 python3-venv
sudo apt-get install kdeconnect -y
sudo firewall-cmd --add-service=kdeconnect --permanent
sudo firewall-cmd --reload
install.sh
setup-repositories.sh --apply
install-adguard.sh --apply
setup-ulauncher.sh --apply
setup-polish.sh --apply
restore-desktop.sh --apply
restore-settings.sh --section apps --skip-ulauncher --apply
restore-bash.sh --apply
restore-system-settings.sh --apply
setup-python.sh --apply
EXPECTED
    diff -u "$work/expected" "$OS_SCRIPTS_SETUP_LOG" || fail 'Kolejność lub argumenty etapów'
    # Każda awaria zatrzymuje dalsze etapy i wskazuje właściwe wznowienie.
    while read -r stage child; do
        : > "$OS_SCRIPTS_SETUP_LOG"
        status=0
        OS_SCRIPTS_SETUP_FAIL="$child" run_setup --apply > "$work/error" 2>&1 || status=$?
        [[ $status == 23 ]] || fail "Nie zachowano kodu błędu: $child"
        last_call=$(tail -n 1 "$OS_SCRIPTS_SETUP_LOG")
        [[ $last_call == "$child" || $last_call == "$child "* ]] \
            || fail "Kontynuowano po błędzie: $child"
        grep -Fq -- "--apply --from $stage" "$work/error" || fail "Brak wznowienia: $stage"
    done <<'STAGES'
apps install.sh
ulauncher setup-ulauncher.sh
language setup-polish.sh
desktop restore-desktop.sh
settings restore-settings.sh
settings restore-bash.sh
services restore-system-settings.sh
python setup-python.sh
STAGES
    : > "$OS_SCRIPTS_SETUP_LOG"
    run_setup --apply --from settings > /dev/null
    tail -4 "$work/expected" > "$work/resumed"
    cmp "$work/resumed" "$OS_SCRIPTS_SETUP_LOG" || fail 'Wznowienie powtórzyło wcześniejsze etapy'
    : > "$OS_SCRIPTS_SETUP_LOG"
    if PATH="$work/bin:$PATH" DBUS_SESSION_BUS_ADDRESS='' bash "$fixture/setup.sh" --apply >/dev/null 2>&1; then fail 'Brak sesji GNOME zaakceptowany'; fi
    [[ ! -s $OS_SCRIPTS_SETUP_LOG ]] || fail 'Brak sesji wykryto dopiero po zmianach'
else
    if run_setup --apply >/dev/null 2>&1; then fail 'Zezwolono na instalację jako root'; fi
fi

# Prawdziwy delegator ustawień ma zachować samodzielną instalację Ulaunchera,
# ale nie może jej powtarzać po dodaniu --skip-ulauncher.
cp "$ROOT/scripts/restore-settings.sh" "$fixture/scripts/"
printf '{"files":[],"dconf":[],"git":[],"gh":[]}' > "$fixture/config/settings/snapshot.json"
cat > "$fixture/scripts/setup-ulauncher.sh" <<'MOCK'
#!/usr/bin/env bash
printf 'ulauncher %s\n' "$*" >> "$OS_SCRIPTS_SETUP_LOG"
MOCK
: > "$OS_SCRIPTS_SETUP_LOG"
bash "$fixture/scripts/restore-settings.sh" --section apps --dry-run > /dev/null
grep -Fxq 'ulauncher --dry-run' "$OS_SCRIPTS_SETUP_LOG" || fail 'Zniknęła domyślna delegacja Ulaunchera'
: > "$OS_SCRIPTS_SETUP_LOG"
bash "$fixture/scripts/restore-settings.sh" --section apps --skip-ulauncher --dry-run > /dev/null
[[ ! -s $OS_SCRIPTS_SETUP_LOG ]] || fail 'Powtórna instalacja Ulaunchera mimo --skip-ulauncher'

catalog="$ROOT/packages/apt/repositories.sources"
filter="$ROOT/scripts/lib/missing-repositories.awk"
awk -v catalog="$catalog" -f "$filter" "$catalog" > "$work/all.sources"
[[ $(grep -c '^URIs:' "$work/all.sources") == 9 ]] || fail 'Nie wybrano dziewięciu aktywnych repozytoriów'
if grep -q '^Enabled: no' "$work/all.sources"; then fail 'Włączono wyłączone repozytorium'; fi
# Klucze muszą pozostać dokładnie takie jak w katalogu.
awk 'BEGIN {RS=""; ORS="\n\n"} !/^#?$/ && !/Enabled: no/' "$catalog" > "$work/active-with-header"
# Porównanie pojedynczych bloków kluczy nie zależy od komentarza nagłówkowego.
awk '/^Signed-By:/,/^ -----END PGP PUBLIC KEY BLOCK-----/' "$work/active-with-header" > "$work/keys-before"
awk '/^Signed-By:/,/^ -----END PGP PUBLIC KEY BLOCK-----/' "$work/all.sources" > "$work/keys-after"
cmp "$work/keys-before" "$work/keys-after" || fail 'Zmieniono publiczny klucz'
cat > "$work/existing.list" <<'LIST'
# deb https://packages.microsoft.com/repos/edge-stable stable main
 deb [arch=amd64 signed-by=/usr/share/keyrings/local.gpg] http://packages.microsoft.com/repos/code/ stable main
 deb http://ppa.launchpad.net/agornostal/ulauncher/ubuntu resolute main
 deb-src https://ocean.surfshark.com/debian stretch main
LIST
cat > "$work/existing.sources" <<'SOURCES'
Types: deb-src deb
URIs:
 https://dl.google.com/linux/chrome/deb
 https://updates.signal.org/desktop/apt/
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/existing.gpg

Enabled: no
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: resolute
Components: stable
SOURCES
awk -v catalog="$catalog" -f "$filter" "$work/existing.list" "$work/existing.sources" "$catalog" > "$work/missing.sources"
[[ $(grep -c '^URIs:' "$work/missing.sources") == 5 ]] || fail 'Duplikaty lub pominięte aktywne repozytoria'
for uri in repos/edge-stable repo.teamsforlinux.de download.docker.com packages.himmelblau-idm.org ocean.surfshark.com; do
    grep -Fq "$uri" "$work/missing.sources" || fail "Brak źródła: $uri"
done
# Ponowny przebieg z dołączonym wynikiem nie generuje kolejnego duplikatu.
awk -v catalog="$catalog" -f "$filter" "$work/existing.list" "$work/existing.sources" "$work/missing.sources" "$catalog" > "$work/again.sources"
[[ ! -s $work/again.sources ]] || fail 'Nie zachowano idempotencji repozytoriów'
# Podgląd na bieżącej konfiguracji nie wywołuje sudo.
: > "$OS_SCRIPTS_SETUP_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/scripts/setup-repositories.sh" --dry-run > "$work/repositories-preview"
[[ ! -s $OS_SCRIPTS_SETUP_LOG ]] || fail 'Podgląd repozytoriów wywołał sudo'
echo 'OK: kolejność i błędy etapów, wznowienie, brak podwójnej instalacji Ulaunchera, repozytoria i podgląd bez zmian.'
