[![Linux - Actionlint](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-actionlint.yml/badge.svg?branch=linux&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-actionlint.yml) 
[![Linux - GNOME and configuration](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-config.yml/badge.svg?branch=linux&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-config.yml)
[![Linux - Secrets](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-secrets.yml/badge.svg?branch=linux&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-secrets.yml)
[![Linux - Package manifests](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-packages.yml/badge.svg?branch=linux&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-packages.yml)
[![Linux - Shell quality](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-shell.yml/badge.svg?branch=linux&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-shell.yml)
[![Linux - Offline integration tests](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-tests.yml/badge.svg?branch=linux&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/linux-tests.yml)

# os-scripts

Listy aplikacji i instalator Bash po reinstalacji **Ubuntu 26.04 (resolute), amd64**.
Audyt APT/Snap: 2026-09-24; bezpośrednie URL-e DEB: 2026-09-25.
Szczegółowe wyniki: [packages/VERIFICATION.md](packages/VERIFICATION.md).

## Pełna instalacja

Uruchom [setup.sh](setup.sh) jako zwykły użytkownik w sesji GNOME. Zamknij Ulaunchera
oraz aplikacje, których ustawienia będą odtwarzane. Skrypt używa sudo tylko tam,
gdzie jest to potrzebne; nie uruchamiaj całego instalatora przez sudo.

```bash
bash setup.sh             # podgląd kolejności i poleceń, bez pobierania i zmian
bash setup.sh --apply     # wykonanie wszystkich etapów
```

Kolejność:

1. `apps`: brakujące repozytoria i publiczne klucze APT, narzędzia pomocnicze,
   wszystkie kategorie APT/Snap/DEB oraz AdGuard.
2. `ulauncher`: zależności, 12 rozszerzeń, oba motywy i konfiguracja.
3. `language`: polskie tłumaczenia i pakiety językowe.
4. `desktop`: ustawienia ogólne, Dostrajanie, rozszerzenia GNOME i zasoby pulpitu.
5. `settings`: preferencje aplikacji oraz Bash (prompt, aliasy i funkcje),
   bez ponownej instalacji dodatków Ulaunchera.
6. `services`: preferencje Docker i Timeshift, bez restartowania usług.
7. `python`: utworzenie `~/.venv` i instalacja bibliotek z listy wymagań.

Język jest instalowany przed odtworzeniem pulpitu, aby zachować zapisany układ:
system EN, konto i formaty PL. Podgląd głównego instalatora wyświetla polecenia,
które wykona `--apply`; nie wywołuje skryptów etapów i nie wymaga jeszcze jq.
Szczegółowe podglądy udostępniają poszczególne skrypty.

Błąd zatrzymuje dalsze etapy i wyświetla polecenie wznowienia. Na przykład:

```bash
bash setup.sh --apply --from ulauncher
bash setup.sh --apply --from settings
```

`--from` ponawia wskazany etap i wszystkie następne; nie zapisuje automatycznych
punktów kontrolnych. Pominięcie wcześniejszych etapów zakłada, że już je wykonano.
Nowe profile części aplikacji trzeba najpierw utworzyć, uruchamiając aplikacje.
Takie pominięcia są zgłaszane przez skrypty; następnie zamknij aplikacje i ponów
etap `settings`. Docker i Timeshift również wymagają istniejącej konfiguracji.
Po odtworzeniu pulpitu wyloguj się i zaloguj ponownie.

## Sama instalacja aplikacji

```bash
bash install.sh --dry-run essentials dev
bash install.sh --source snap entertainment
bash install.sh --source apt dev
bash install.sh --source deb essentials dev entertainment
```

Kategorie: `essentials`, `dev`, `entertainment`; `optional` jest aliasem ostatniej.
Bez kategorii wybierane są wszystkie. `--source apt|snap|deb|all` ogranicza źródło.
`--dry-run` wyświetla plan bez instalacji, sudo, pobierania i tworzenia plików.
Bez `--dry-run` instalator wykonuje plan. Ustawienia odtwarzają osobne skrypty
z domyślnym podglądem i wymaganym `--apply` do zapisu.

## Repozytoria APT

[packages/apt/repositories.sources](packages/apt/repositories.sources) zawiera adresy
repozytoriów, publiczne klucze osadzone w `Signed-By`, odciski kluczy i źródła instrukcji.
Dziewięć repozytoriów jest aktywnych: VS Code, Edge, Google Chrome, Signal,
Teams for Linux, Ulauncher, Docker, Himmelblau (`o365`) i Surfshark. Konfiguracje Microsoft
Ubuntu 26.04 i Synaptics są zachowane jako `Enabled: no` z wyjaśnieniem w pliku.

Pełny instalator konfiguruje brakujące adresy automatycznie. Osobno:

```bash
bash scripts/setup-repositories.sh --dry-run
bash scripts/setup-repositories.sh --apply
sudo apt-get update
sudo apt-get install -y curl ca-certificates
bash install.sh --source apt essentials dev
```

Wymagane są standardowe repozytoria Ubuntu z komponentami `main` i `universe`.
`setup-repositories.sh` sprawdza wersję systemu i architekturę przed zapisem.
Czyta aktywne źródła `.list` i `.sources`, pomija już skonfigurowane adresy
(również warianty HTTP/HTTPS i stare adresy PPA) i zapisuje pozostałe wraz z publicznymi
kluczami w `/etc/apt/sources.list.d/os-scripts.sources`. Innych plików nie zmienia.
Przed zastąpieniem swojego pliku tworzy kopię `.bak`. Istniejące obce źródła zachowuje;
jeżeli mają nieprawidłowe klucze lub wydanie, błąd APT wymaga poprawienia tych źródeł.
Po instalacji aplikacji pełny instalator ponownie uzgadnia swój plik z repozytoriami
dodanymi przez pakiety, aby kolejne etapy nie napotkały duplikatów `Signed-By`.
Sam `install.sh` nadal obsługuje wyłącznie pakiety.
Konfiguracja zawiera wpisy `resolute` i `ubuntu26.04`; inne wydania wymagają odrębnej weryfikacji.
Publiczne repozytorium Himmelblau udostępniło podpisane pakiety podczas audytu;
aktualna dokumentacja opisuje także płatne repozytoria stable. Dostępność publicznego
adresu i przyszłych aktualizacji trzeba ponownie sprawdzić przy kolejnym reinstalu.

Surfshark jest na liście `apt/essentials.txt`. Jego wpis w `repositories.sources`
korzysta z `https://ocean.surfshark.com/debian`, suite `stretch`, komponentu `main`
i osadzonego klucza z oficjalnego instalatora. `stretch` to nazwa repozytorium
producenta; nie zmieniaj jej na `resolute`.

Signal jest na liście `apt/essentials.txt` jako `signal-desktop`. Wpis repozytorium
i klucz w `repositories.sources` odpowiadają [oficjalnej instrukcji](https://signal.org/download/linux/):
`https://updates.signal.org/desktop/apt`, suite `xenial`, komponent `main`, architektura `amd64`.
Klucz jest osadzony w polu `Signed-By`. Ponowna weryfikacja podpisu i symulacja
instalacji wersji `8.28.0` przeszły 2026-09-25.

## Listy i pobieranie DEB

Aktywne listy kategorii: `packages/{apt,snap,deb}/{essentials,dev,entertainment}.txt`.
Puste wiersze i komentarze `#` są pomijane. Snap obsługuje `--classic`.
Duplikaty w wybranych kategoriach są deduplikowane.

Linki DEB są bezpośrednio w plikach [essentials.txt](packages/deb/essentials.txt),
[dev.txt](packages/deb/dev.txt) i [entertainment.txt](packages/deb/entertainment.txt).
Każdy aktywny wiersz zawiera **tylko jeden bezpośredni URL HTTPS**, np.:

```text
https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb
https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb
```

Dodanie aplikacji wymaga dopisania jednego linku do wybranej kategorii.
Źródła i wersje opisano w [SOURCES.md](packages/deb/SOURCES.md).

```bash
# Podgląd pobierania i instalacji wszystkich DEB:
bash install.sh --dry-run --source deb
# Pobierz i zainstaluj DEB kategorii dev:
bash install.sh --source deb dev
```

Instalator DEB to Bash z `curl`, certyfikatami CA i standardowymi narzędziami Ubuntu
(`sudo`, `apt-get`, `dpkg`, `dpkg-deb`). **Nie wymaga `jq` ani Pythona.**
Pobiera wszystkie wybrane pliki do katalogu tymczasowego, sprawdza format DEB,
architekturę i integralność archiwum. Następnie odświeża indeksy APT, sprawdza
zależności przez symulację i instaluje wybrane APT oraz DEB w jednej transakcji
`apt-get install`, razem z zależnościami. Pliki tymczasowe usuwa po zakończeniu,
także przy błędzie. Przy kolejnym uruchomieniu pobiera je ponownie.

Błędny URL, nieudane pobranie lub niepoprawny DEB przerywają wykonanie przed sudo.
Docker Desktop wymaga wcześniej skonfigurowanego repozytorium Docker dla `docker-ce-cli`.

Komentarze `TODO`, `MANUAL` i `UNSUPPORTED` opisują wyjątki i nie są instalowane.
WhatsApp jest dostępny przez Snap `whatsie` — nieoficjalnego klienta WhatsApp Web.
Poprzednie pliki z `packages/del/` zachowano w `archive/packages-original/`.
Instalator ich nie odczytuje.

## AdGuard for Linux

AdGuardCLI instaluje osobny skrypt [scripts/install-adguard.sh](scripts/install-adguard.sh).
Pobiera [instalator producenta](https://raw.githubusercontent.com/AdguardTeam/AdGuardCLI/release/install.sh)
i uruchamia go przez `sh -s -- -v`, zgodnie z podanym poleceniem. Opcja `-v`
włącza szczegółowy log. Pełny plik jest pobierany i sprawdzany składniowo przed
uruchomieniem, a pliki tymczasowe są usuwane po zakończeniu.

```bash
bash scripts/install-adguard.sh --dry-run
bash scripts/install-adguard.sh --apply
```

Uruchom jako zwykły użytkownik; instalator producenta sam wywołuje sudo, gdy go potrzebuje.
Pełny `setup.sh` wywołuje go po APT/Snap/DEB; sam `install.sh` nie instaluje AdGuarda.
Skrypt nie wymaga jq ani Pythona.

## Ustawienia systemu, Dostrajanie i rozszerzenia

[Raport porównania z ustawieniami domyślnymi](config/settings/DESKTOP.md) obejmuje
98 różnic: 46 ustawień ogólnych, 7 z Dostrajania i 45 preferencji rozszerzeń.
Zapisano też stan 25 rozszerzeń, monitory, język, strefę czasową i domyślne aplikacje.
Kod 17 rozszerzeń użytkownika jest dołączony; brakujące katalogi zostaną odtworzone.

```bash
# Podgląd, potem odtworzenie bieżącego pulpitu:
bash scripts/restore-desktop.sh --dry-run
bash scripts/restore-desktop.sh --apply
# Oddzielne etapy: --section system|tweaks|extensions
```

Skrypt tworzy kopie zapasowe. Uruchamiaj go jako użytkownik GNOME, bez sudo;
podnosi uprawnienia tylko dla ustawień systemowych. Potem wyloguj się i zaloguj ponownie.
Quick Settings Tweaks 29 nie obsługuje GNOME 50; kontrola zgodności pozostaje włączona.
Profile monitorów dotyczą obecnego sprzętu.

[Pełna instrukcja](config/settings/README.md) opisuje też aplikacje i język:

```bash
bash scripts/setup-polish.sh --dry-run            # instalacja polskich tłumaczeń
bash scripts/restore-settings.sh --dry-run        # pulpit oraz preferencje aplikacji
bash scripts/restore-settings.sh --section apps --dry-run
bash scripts/restore-system-settings.sh --dry-run # osobno: Docker i Timeshift
```

Wszystkie skrypty są w Bash. Ustawienia JSON przetwarza `jq`.
Skrypty te zapisują zmiany dopiero z `--apply`; `install.sh` nie uruchamia ich automatycznie.

## Rozszerzenia i motywy Ulaunchera

[Raport Ulaunchera](config/ulauncher/README.md) opisuje wszystkie 12 wskazanych
projektów, ustawienia i brakujące zależności. Instalator obejmuje wszystkie 12 dodatków,
w tym GPT skonfigurowane bez klucza API. Dodaje oba motywy libadwaita, zachowując ciemny
jako aktywny, oraz poprawia adresy przeniesionych paneli GNOME 50.

```bash
bash scripts/setup-ulauncher.sh --dry-run
# Zamknij Ulaunchera przed zapisem:
bash scripts/setup-ulauncher.sh --apply
```

Ten etap jest też częścią `restore-settings.sh --section apps` i pełnego odtwarzania.
Główny `setup.sh` wykonuje go wcześniej, a do ustawień przekazuje `--skip-ulauncher`.
Pobiera brakujący kod ze sprawdzonych commitów z kontrolą SHA256 i instaluje zależności
APT dla systemowego Pythona. Istniejące klucze API zachowuje w lokalnych bazach;
repozytorium ich nie zawiera. Na świeżej instalacji tokeny i urządzenia Bluetooth
wymagają uzupełnienia. Szczegóły i wyniki sprawdzenia są w raporcie.

## Bash: prompt, aliasy i funkcje

W [config/bash](config/bash/README.md) są `.bashrc.user`, 46 aktywnych aliasów
w `.bash_aliases` i 13 funkcji w `.bash_functions`. Usunięto stare zakomentowane
polecenia, w tym zawierające poświadczenia. Ustawienia ładuje etap `settings`
pełnego instalatora. Osobno, bez wymagania sesji GNOME:

```bash
bash scripts/restore-bash.sh --dry-run
bash scripts/restore-bash.sh --apply
```

Skrypt zachowuje obecną zawartość `.bashrc`, dodając jeden blok wczytujący
`.bashrc.user`. Pozostałe trzy pliki zastępuje wersjami z repozytorium, tworząc
kopie istniejących plików w `~/.local/state/os-scripts/backups/bash-*`.
Nie wykonuje przenoszonych definicji. Po odtworzeniu otwórz nowy terminal Bash.
Funkcje firmowe wymagają właściwych narzędzi i ścieżek; nie są uruchamiane automatycznie.

## Środowisko Pythona

[packages/python/requirements.txt](packages/python/requirements.txt) zawiera wszystkie
11 bibliotek z podanymi minimalnymi wersjami. Skrypt tworzy `~/.venv` poleceniem
`python3 -m venv`, instaluje biblioteki przez interpreter tego środowiska i sprawdza zależności.
Istniejące poprawne środowisko wykorzystuje ponownie; innego katalogu nie nadpisuje.
Wymagane APT: `python3` i `python3-venv` (są na listach pakietów).

```bash
bash scripts/setup-python.sh --dry-run
bash scripts/setup-python.sh --apply
# Opcjonalnie aktywuj środowisko w swoim terminalu:
source ~/.venv/bin/activate
```

Inny katalog: `--venv /ścieżka/do/venv`. Instalacja nie używa sudo ani globalnego pip.
Pełna instalacja i importy zostały sprawdzone w tymczasowym venv na Pythonie 3.14.4;
nie utworzono środowiska w katalogu domowym podczas przygotowania skryptów.

## Sprawdzenie zmian

```bash
bash tests/check.sh
```

Testy używają tymczasowych plików oraz atrap curl/sudo/APT. Sprawdzają scalanie
ustawień, archiwa motywów i rozszerzeń, podgląd konfiguracji/Pythona, obsługę DEB,
kolejność i wznawianie etapów oraz wybór brakujących repozytoriów — bez sieci i zmiany bieżącej konfiguracji.

## Sekrety

Repozytorium zawiera wyłącznie niesekretną konfigurację. Klucze API i tokeny
uzupełnia się lokalnie w aplikacjach; nie są generowane ani eksportowane przez
te skrypty. Publiczne klucze GPG w repozytoriach APT służą weryfikacji pakietów.

Instalator Ulaunchera odrzuca snapshot z wartościami poświadczeń oraz ścieżki baz
i kopii prowadzące do repozytorium, również przez dowiązania. Lokalne bazy z kluczami
pozostają poza repozytorium. `.gitignore` wyklucza pliki środowiskowe, prywatne klucze,
bazy i kopie; kontrolę zawartości wykonuje `bash tests/check-no-secrets.sh` (wymaga
również `rg`). Test obejmuje pliki i archiwa oraz niepuste pola poświadczeń w JSON.
Nie zastępuje przeglądu nowych formatów i niestandardowych rodzajów sekretów.
