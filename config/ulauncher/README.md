# Ulauncher: rozszerzenia, motywy i preferencje

Audyt: 2026-09-25, Ulauncher 5.16.2 (API 2), Ubuntu 26.04, GNOME 50.
Sprawdzono manifesty, lokalne bazy preferencji, wymagania projektów i źródła
przypiętych wersji. Wszystkie 12 wskazanych rozszerzeń jest obecnie zainstalowanych.

```bash
bash scripts/setup-ulauncher.sh --dry-run
# Zamknij Ulaunchera przed zapisem:
bash scripts/setup-ulauncher.sh --apply
```

Ten etap jest także wywoływany przez `restore-settings.sh --section apps --apply`
i pełne `restore-settings.sh --apply`. Podgląd nie pobiera plików ani nie zapisuje
ustawień. `--apply` pobiera brakujące dodatki/motywy, sprawdza SHA256, instaluje
zależności APT, scala rejestr i preferencje, a potem pozostawia uruchomienie aplikacji
użytkownikowi. Wymaga wcześniej dostępnych `jq`, `curl`, `python3` i narzędzi Ubuntu;
repozytorium APT Ulaunchera jest w `packages/apt/repositories.sources`.

Instalator obejmuje wszystkie **12 rozszerzeń**. GPT odtwarza tylko niesekretne
preferencje. Klucz podaje się lokalnie w ustawieniach dodatku; skrypt go nie tworzy,
nie pobiera ani nie zapisuje w repozytorium.

## Ustawienia każdego dodatku

Pełne niesekretne wartości: [snapshot.json](snapshot.json). Zapisano także wartości
równe domyślnym, aby odtworzenie nie zależało od przyszłych zmian manifestów.

| Projekt | Odtwarzana konfiguracja | Wynik sprawdzenia / ograniczenia |
| --- | --- | --- |
| [Calculate Anything](https://github.com/tchar/ulauncher-albert-calculate-anything) | `=`, `time`, `dec`, `hex`, `oct`, `bin`; cache 1 dzień; USD/EUR/GBP/CAD; miasta z obecnej konfiguracji; tryb normal | Brakowało Pint, simpleeval i parsedatetime. Dodano zależności APT. Zachowano wybór `fixerio` + źródła wewnętrzne; klucz fixer.io jest pusty. |
| [System](https://github.com/iboyperson/ulauncher-system) | Skrót `system` zamiast domyślnego `sys` | Projekt przekierowuje do `tjquillan/ulauncher-system`; zachowano dotychczasowy identyfikator, żeby nie zdublować rozszerzenia. Nie wykonano poleceń wyłączania/restartu. |
| [GitHub — brpaz](https://github.com/brpaz/ulauncher-github) | `gh` i wszystkie obecne skróty `gh:*` | Brakowało PyGithub. Token jest pusty; funkcje konta wymagają tokena skonfigurowanego w preferencjach. |
| [Kill](https://github.com/Ulauncher/ulauncher-kill) | `kill` | Zweryfikowano zależność GI Notify. Nie wykonywano operacji na procesach. |
| [Docker](https://github.com/brpaz/ulauncher-docker) | `dk`, `dk:info`, `dk:prune`, `dk:docs`; terminal `gnome-terminal` | Biblioteka docker jest dostępna. Dodano GNOME Terminal, bo obecny wpis wskazywał nieobecny program. Wymaga działającego Dockera i dostępu użytkownika do jego gniazda. |
| [Bluetooth Quick Connect](https://github.com/Eckhoff42/Ulauncher-Bluetooth-quick-connect) | `bt`; obecna pusta lista urządzeń | BlueZ dostarcza `bluetoothctl`. Urządzenia trzeba dopisać w formacie `nazwa AA:BB:CC:DD:EE:FF`, oddzielając kolejne przecinkami. Nie wybierano urządzeń za użytkownika. |
| [GPT](https://github.com/SeoFernando25/ulauncher-gpt) | `gpt` i pozostałe bieżące preferencje modelu, odpowiedzi i wyglądu | Instalacja bez klucza API. Na nowym komputerze klucz należy podać lokalnie w preferencjach; nie jest częścią snapshotu. Nie wykonywano wywołań API. |
| [GNOME Settings](https://github.com/friday/ulauncher-gnome-settings) | Wszystkie obecne nazwy skrótów, np. Display Settings, Keyboard Settings | Dołączono poprawkę sześciu adresów paneli dla GNOME 50, opisaną poniżej. |
| [Gemini Direct](https://github.com/kalligator/ulauncher-gemini-direct) | `gm` / `γμ`; model `gemini-flash-latest`; temperatura 1; zawijanie 43; logowanie i debug wyłączone | Lokalny klucz jest zapisany: scalenie go zachowuje. Snapshot repozytorium nie zawiera klucza. Nowa instalacja wymaga ponownego podania klucza lub dostępnej dla Ulaunchera zmiennej GEMINI_API_KEY. Nie wysyłano zapytań do API. |
| [YouTube Search](https://github.com/NastuzziSamy/ulauncher-youtube-search) | `yt`, miniatury włączone, obecny szablon opisu | Korzysta z requests i parsuje stronę YouTube. Zmiany strony, zgody lub ograniczenia dostępu mogą wpływać na wyniki; nie wykonano testu wyszukiwania online. |
| [Git Code Launch](https://github.com/alchemistake/git_code_launch) | `code`, polecenie `code`, katalog `~/git` | Kod szuka katalogów `.git`. Nie obejmuje plików `.git` worktree; repozytoria zagnieżdżone i argumenty ze znakami specjalnymi mają ograniczenia w kodzie autora. |
| [GitHub Search — Glovecc](https://github.com/Glovecc/ulauncher-github-search) | `ghs` zamiast domyślnego `gb` | Pobrano i zweryfikowano wskazany commit bezpośrednio z GitHub; osobny dodatek, bez tokena GitHub. |

## Motywy

Instalator udostępnia oba motywy:

- [libadwaita-dark](https://github.com/kareemkasem/ulauncher-theme-libadwaita-dark), obecnie aktywny;
- [libadwaita](https://github.com/leodr/ulauncher-theme-libadwaita), jasny, dotąd nieobecny.

Katalogi: `~/.config/ulauncher/user-themes/`. Istniejące motywy są zachowywane.
Wybrany pozostaje `libadwaita-dark`. Zachowano też Ctrl+Spacja, otwieranie na ekranie
kursora, czyszczenie poprzedniego zapytania, ikonę wskaźnika i brak ostatnich aplikacji.
Autostart i globalny skrót GNOME nadal odtwarza `restore-desktop.sh`.

## Zależności i zgodność

Lista [packages/ulauncher/apt.txt](../../packages/ulauncher/apt.txt) jest instalowana
przez ten skrypt. Ulauncher uruchamia rozszerzenia przez `sys.executable`, czyli
w obecnej instalacji systemowy Python. Biblioteki w `~/.venv` nie są dla niego
widoczne; nie rozwiązują zależności tych dodatków.

Piny w historycznych plikach requirements autorów (np. Docker 5, PyGithub 1.55,
Pint do 0.23) są starsze od pakietów Ubuntu 26.04. Skrypt korzysta z pakietów APT
zamiast wymuszać stare biblioteki przez globalny pip. Symulacja APT przeszła;
pełna zgodność funkcjonalna dodatków z nowymi bibliotekami wymaga testu działania.

Wersje rozszerzeń odpowiadają obecnie zainstalowanym commitom; motywy przypięto do
zweryfikowanych commitów. URL-e i SHA256 są w snapshotcie. Istniejący kod rozszerzeń
jest zachowywany, a preferencje sprawdzane względem ich manifestów. Ulauncher 6
nie jest obsługiwany przez ten snapshot: ma inny format danych i API.

## Poprawka GNOME 50

[gnome-settings-50.patch](patches/gnome-settings-50.patch) zmienia tylko adresy
paneli otwieranych przez istniejące skróty:

| Stary panel | Nowe argumenty gnome-control-center |
| --- | --- |
| datetime | `system datetime` |
| info-overview | `system about` |
| region | `system region` |
| user-accounts | `system users` |
| default-apps | `applications` |
| removable-media | `applications` |

Dwie ostatnie pozycje otwierają wspólny panel Aplikacje; podstronę wybiera się
w jego interfejsie. Mapowanie sprawdzono w [kodzie GNOME 50 System](https://github.com/GNOME/gnome-control-center/blob/50.1/panels/system/cc-system-panel.c),
[obsłudze parametrów](https://github.com/GNOME/gnome-control-center/blob/50.1/shell/cc-panel.c)
i [panelu Aplikacje](https://github.com/GNOME/gnome-control-center/blob/50.1/panels/applications/cc-applications-panel.c).
Poprawka jest stosowana tylko do znanego pliku main.py, sprawdzanego przez SHA256;
powtórne uruchomienie jej nie dubluje. Aktualizacja dodatku w Ulauncherze może
nadpisać tę lokalną poprawkę.

## Dane prywatne i kopie

`api_key` i `access_token` nie trafiają do snapshotu. Scalenie zachowuje wartości
już zapisane w docelowym komputerze, także klucz Gemini i inne ustawienia spoza
snapshotu. Samo sklonowanie repozytorium na nowym komputerze nie przenosi sekretów.
Walidacja odrzuca niepuste pola poświadczeń w snapshotcie, a instalator nie pozwala
na zapis baz i kopii wewnątrz repozytorium, także przez dowiązania. Prywatne pliki
robocze tworzy bezpośrednio w `/tmp` i usuwa po zakończeniu. Nie korzysta tu z TMPDIR,
który mógłby wskazywać na repozytorium.

Bash obsługuje instalację i konfigurację. W Ulauncherze 5 pliki `.db` są binarnym
formatem pickle; tylko ich odczyt/scalenie/zapis korzysta z krótkiego fragmentu
systemowego Pythona w `scripts/lib/ulauncher.sh`. Czytnik odrzuca obiekty wykonywalne.
Nie kopiuje się historii zapytań, cache, logów ani danych kont.

Przed zastąpieniem plików powstaje kopia w
`~/.local/state/os-scripts/backups/ulauncher-<czas>/files/`, ze ścieżkami względem HOME.
Kopie baz mogą zawierać lokalne klucze API; katalog ma prywatne uprawnienia.
Przy cofnięciu przywróć kopie przy zamkniętym Ulauncherze i usuń nowo dodane katalogi,
które wcześniej nie istniały.

## Sprawdzenie

```bash
bash tests/check-ulauncher.sh
bash tests/check.sh
```

Testy używają sztucznych archiwów i atrap curl/APT. Sprawdzają SHA256, odtwarzanie
motywów i rejestru, scalenie baz z zachowaniem sekretów, powtórne wykonanie,
kopie zapasowe, błędy pobierania/APT oraz podgląd bez zapisu.
Sprawdzono także składnię kodu dodatków bez wykonania i statycznie poprawkę GNOME.
Automatyczna kontrola uprawnień odrzuciła testowy import pobranego kodu; nie wykonano
uruchomienia rozszerzeń, testów API ani zmian w bieżącej konfiguracji Ulaunchera.
