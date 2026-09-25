# Odtwarzanie języka i ustawień

Konfiguracja Ubuntu 26.04 / GNOME 50.1: aplikacje z 2026-09-24, pulpit ponownie
sprawdzony 2026-09-25. Skrypty są w Bash i domyślnie pokazują tylko plan.
Do odczytu JSON potrzebny jest `jq`. Etap Ulaunchera używa także systemowego
Pythona do scalenia jego binarnych baz preferencji; pozostałe ustawienia go nie wymagają.

## Pulpit: system → Dostrajanie → rozszerzenia

[DESKTOP.md](DESKTOP.md) zawiera porównanie z efektywnymi wartościami domyślnymi
zainstalowanego systemu, uwzględniające nadpisania Ubuntu i firmowe.
W `desktop.json` zapisano 98 różnic (46 + 7 + 45), stan 25 rozszerzeń,
preferencje języka, monitory, profil zasilania, strefę czasową i skojarzenia aplikacji.
Skrypt odtwarza zapisane różnice; nie zeruje pozostałych preferencji.

```bash
bash scripts/restore-desktop.sh --dry-run
bash scripts/restore-desktop.sh --apply
# Etapy można uruchamiać oddzielnie:
bash scripts/restore-desktop.sh --section system --apply
bash scripts/restore-desktop.sh --section tweaks --apply
bash scripts/restore-desktop.sh --section extensions --apply
```

Uruchamiaj jako zalogowany użytkownik GNOME, bez sudo. Etap systemowy sam używa
sudo dla locale, układu X11, strefy czasowej i NTP. Wymaga narzędzi standardowego
Ubuntu Desktop: dconf/gsettings, GNOME Shell, locales, systemd, AccountsService,
xdg-utils i glib-compile-schemas. Brak powerprofilesctl jest zgłaszany i pomijany.
Nie wykonano odtwarzania ustawień w bieżącej sesji podczas przygotowania repo.

- Zasoby Fluent-Dark, Win11, kursory MacTahoe, tło, ikona ArcMenu i motyw Ulaunchera
  są w `assets/desktop.tar.gz`. Każdy etap odtwarza zasoby przed ich użyciem.
- `assets/extensions.tar.gz` zawiera kod 17 rozszerzeń użytkownika. Skrypt instaluje
  brakujące katalogi, zachowuje istniejące wersje i scala stan znanych rozszerzeń
  z listą na docelowym komputerze. Pakiety rozszerzeń systemowych są wskazane
  w `desktop.json`: `gnome-shell-ubuntu-extensions` i `himmelblau-qr-greeter`.
  Jeśli ich brakuje, skrypt informuje o pominięciu zamiast instalować je samodzielnie.
- Quick Settings Tweaks 29 jest zaznaczone jako włączone, ale niezgodne z GNOME 50.
  Tak samo będzie po odtworzeniu; skrypt zachowuje kontrolę zgodności.
- `files/monitors.xml` zawiera trzy profile dla obecnego sprzętu. Zostanie odczytany
  przy kolejnym logowaniu; skrypt nie przełącza monitorów w trakcie pracy.
- Dash to Panel ma ten sam układ na trzech ekranach; zapisano indeksy 0/1/2.
- Ulauncher otrzymuje autostart i Ctrl+Spacja. Istniejący inny skrót pod `custom0`
  jest zachowywany — wtedy Ulauncher dostaje osobną ścieżkę konfiguracji.
- Run or Raise zachowuje obecne skróty, także przykładowe do gnome-terminal,
  Pidgin i Chromium oraz własny `Super+.` dla ChatGPT. Brakujące aplikacje
  nie są z tego powodu instalowane.

Po odtworzeniu wyloguj się i zaloguj ponownie, aby wczytać nowe rozszerzenia,
monitory i język konta. Ustawienia urządzeń i polityki administratora mogą wpływać
na wynik na innym komputerze.

## Polski język

```bash
bash scripts/setup-polish.sh --dry-run
bash scripts/setup-polish.sh --apply
```

Ten skrypt instaluje polskie tłumaczenia, słowniki i locale, ustawia język konta,
formaty oraz polską klawiaturę programisty. Domyślnie ustawia również systemowe
LANG na polskie. `--english-ui` wybiera angielski interfejs z polskimi formatami.

Aby odtworzyć dokładnie obecny podział, wykonaj **potem** `restore-desktop.sh`:
konto i formaty `pl_PL.UTF-8`, systemowe `LANG=en_US.UTF-8`, klawiatura sesji `pl`,
a systemowy układ X11 `us`/`pc105`. Narzędziowe `LC_ALL=C.UTF-8` nie jest preferencją
pulpitu. Skrypt nie wymusza języka wszystkich aplikacji; np. Ferdium ma `en-US`.

## Preferencje aplikacji

```bash
# Pulpit i aplikacje razem:
bash scripts/restore-settings.sh --dry-run
bash scripts/restore-settings.sh --apply
# Tylko aplikacje:
bash scripts/restore-settings.sh --section apps --apply
```

`restore-settings.sh` deleguje pulpit do `restore-desktop.sh`, więc oba korzystają
z tego samego aktualnego snapshotu. Zachowano też wybory `--section desktop`,
`--section extensions` i `--section assets`.

`snapshot.json` zawiera 43 klucze aplikacji/GTK, 13 plików preferencji,
42 preferencje/aliasy Git i ustawienia GitHub CLI bez kont i tokenów.
[APPLICATIONS.md](APPLICATIONS.md) opisuje aplikacje, znalezione konfiguracje i pominięcia.
Stary pełny eksport `../dconf.ini` nie jest importowany.

Etap aplikacji wywołuje również `setup-ulauncher.sh`: instaluje dodatki, oba motywy
i ich zależności APT. Szczegóły: [raport Ulaunchera](../ulauncher/README.md).

Zamknij aplikacje przed etapem `apps`; skrypt wykrywa działające procesy.
Edge, Firefox i Snapy muszą wcześniej utworzyć profil przy pierwszym uruchomieniu;
brakujące profile są zgłaszane i pomijane. JSON/INI są scalane z istniejącymi danymi.
Przy zapisie JSONC komentarze znikają; oryginał jest w kopii zapasowej.
Firefox otrzymuje pojedynczy zarządzany blok `user.js`; powtórzenie nie duplikuje bloku.
Ten plik stosuje preferencje przy każdym starcie, zgodnie z
[dokumentacją Mozilla](https://www-archive.mozilla.org/support/firefox/edit).

## Usługi i Python

```bash
bash scripts/restore-system-settings.sh --dry-run
bash scripts/restore-system-settings.sh --apply
bash scripts/setup-python.sh --dry-run
bash scripts/setup-python.sh --apply
```

Usługi mają osobny plik `system.json`: `live-restore=true` Dockera i harmonogramy/
retencja Timeshift (harmonogramy są obecnie wyłączone). Nie przenosimy UUID dysków,
wykluczeń backupu ani ustawień sieci Dockera. Skrypt nie restartuje usług.

`setup-python.sh` tworzy `~/.venv` i instaluje 11 bibliotek z
`../../packages/python/requirements.txt` przez pip tego środowiska. Nie wymaga jq.
Pakiety APT `python3` i `python3-venv` są już na listach. Skrypt wykorzystuje ponownie
poprawne istniejące venv, sprawdza zależności przez `pip check` i nie nadpisuje
katalogu, który nie jest venv. Inny cel wybiera `--venv ŚCIEŻKA`.

## Kopie zapasowe i zakres

Pulpit: `~/.local/state/os-scripts/backups/desktop-<czas>/`.
`dconf.json` zawiera poprzednie wartości użytkownika; `null` oznacza brak wpisu,
który cofa się przez `dconf reset`. Pliki w `files/` mają ścieżki względem `/`.
Tekstowe pliki obok zapisują poprzednią strefę/NTP, klawiaturę, język konta i zasilanie.

Aplikacje i zasoby: `~/.local/state/os-scripts/backups/<czas>/`, ścieżki w `files/`
są względem HOME. Etapy mają osobne kopie i wypisują ich lokalizacje.
Język: `~/.local/state/os-scripts/language-*`. Usługi: `.os-scripts-<czas>.bak`
obok oryginałów. Nowe pliki nie mają poprzedniej kopii; przy cofaniu usuń je ręcznie.

Pominięto hasła, konta, klucze SSH/GPG, OAuth, historię schowka/przeglądarek,
zakładki, profile VPN/O365 oraz tożsamość i firmowe adresy Git.
W archiwum Win11 poprawiono wcześniej jedno uszkodzone dowiązanie `preferences/22`
na względne `32`.

## Walidacja

`bash tests/check.sh`: testy offline, bez zmiany ustawień bieżącej sesji.
Obejmują scalanie JSONC/INI/skrótów/list rozszerzeń, archiwa, tryby podglądu,
instalatory i obsługę błędów. Sprawdzono również ShellCheck oraz parsowanie
wartości snapshotu przez GLib. Pełna instalacja 11 bibliotek Pythona, ich importy
i `pip check` przeszły w tymczasowym venv na Pythonie 3.14.4.
Nie wykonano testu wizualnego po odtworzeniu ani instalacji bibliotek w HOME.
