[![macOS compatibility](https://github.com/piotrek1488/os-scripts/actions/workflows/macos-ci.yml/badge.svg?branch=macos&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/macos-ci.yml)
[![Secrets and Actions lint](https://github.com/piotrek1488/os-scripts/actions/workflows/security.yml/badge.svg?branch=macos&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/security.yml)
[![Shell CI](https://github.com/piotrek1488/os-scripts/actions/workflows/shell-ci.yml/badge.svg?branch=macos&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/shell-ci.yml)
[![Zsh config validation](https://github.com/piotrek1488/os-scripts/actions/workflows/zsh-ci.yml/badge.svg?branch=macos&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/zsh-ci.yml)
[![Homebrew catalog validation](https://github.com/piotrek1488/os-scripts/actions/workflows/homebrew-validator.yml/badge.svg?branch=macos&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/homebrew-validator.yml)
[![Python generator smoke test](https://github.com/piotrek1488/os-scripts/actions/workflows/python-smoke.yml/badge.svg?branch=macos&event=push)](https://github.com/piotrek1488/os-scripts/actions/workflows/python-smoke.yml)

# os-scripts — macOS

Zestaw skryptów do przygotowania środowiska pracy na **macOS**: instalacji aplikacji i narzędzi, konfiguracji powłoki Zsh oraz tworzenia szkieletu projektu Python.

> **Gałęzie:** `macos` (ta gałąź) zawiera narzędzia dla macOS. Skrypty przeznaczone dla Ubuntu/Linux znajdują się na [gałęzi `linux`](https://github.com/piotrek1488/os-scripts/tree/linux).
>
> Skrypty odzwierciedlają indywidualną konfigurację komputera — przed uruchomieniem przejrzyj listy pakietów, adresy pobierania i operacje zmieniające system.

## Zawartość repozytorium

| Ścieżka | Przeznaczenie |
| --- | --- |
| `new_mac_setup.sh` | Konfiguracja nowego Maca i instalacja wybranych aplikacji oraz narzędzi. |
| `new_python_proj_setup.sh` | Tworzenie struktury startowej projektu Python. |
| `zsh_config_files/` | Pliki i ustawienia powłoki Zsh. |
| `.github/workflows/` | Automatyczne testy i kontrole jakości, jeżeli zostały dodane do gałęzi. |

## Wymagania

- Mac z systemem macOS i dostępem do Internetu.
- Terminal i powłoka Bash; do konfiguracji terminala także Zsh.
- Narzędzia wiersza poleceń Xcode (Command Line Tools), jeżeli są potrzebne do instalacji.
- Uprawnienia administratora do operacji wymagających `sudo`.
- [Homebrew](https://brew.sh/) dla instalacji pakietów i aplikacji zarządzanych przez Brew. Część instalacji może korzystać także z Mac App Store (`mas`) i pobieranych plików DMG.

Nie wszystkie aplikacje są dostępne na każdej wersji macOS i na obu architekturach procesora. Zaloguj się do Mac App Store przed instalowaniem aplikacji stamtąd.

## Szybki start

Sklonuj **właściwą gałąź**:

```bash
git clone --branch macos --single-branch https://github.com/piotrek1488/os-scripts.git
cd os-scripts
```

Przed instalacją sprawdź skrypt i jego składnię:

```bash
bash -n new_mac_setup.sh
less new_mac_setup.sh
```

Jeżeli akceptujesz działania skryptu, uruchom:

```bash
bash new_mac_setup.sh
```

> **Uwaga:** nie traktuj `new_mac_setup.sh` jako trybu podglądu. Skrypt może instalować oprogramowanie, pobierać pliki i zmieniać konfigurację. README nie zakłada obsługi `--dry-run` ani `--help`, jeśli te opcje nie są zaimplementowane.

## Generator projektu Python

`new_python_proj_setup.sh` służy do szybkiego utworzenia szkieletu nowego projektu. Przed użyciem zapoznaj się z argumentami i ścieżkami zapisu w skrypcie:

```bash
bash -n new_python_proj_setup.sh
less new_python_proj_setup.sh
```

Po wygenerowaniu projektu sprawdź utworzone pliki, importy i testy. Jeśli generator tworzy `src/main.py`, upewnij się, że plik startowy importuje właściwy moduł. Dobrym testem jest uruchomienie wygenerowanego programu i `pytest` z katalogu projektu.

## Konfiguracja Zsh

Pliki w `zsh_config_files/` możesz wykorzystać jako podstawę własnej konfiguracji. Najpierw porównaj je z aktualnymi ustawieniami, zamiast nadpisywać działający `.zshrc` bez kopii:

```bash
cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d-%H%M%S)
find zsh_config_files -maxdepth 2 -type f -print
```

Po wybraniu odpowiedniego pliku sprawdź składnię w Zsh i ręcznie dostosuj ścieżki, aliasy oraz odwołania do narzędzi zewnętrznych. Niektóre wpisy mogą wymagać doinstalowania pluginów, np. `zsh-syntax-highlighting` lub `thefuck`.

## Kontrola jakości i GitHub Actions

Jeżeli na gałęzi znajdują się workflowy CI, ich zadaniem powinno być weryfikowanie skryptów **bez uruchamiania całej instalacji macOS**. Przydatne kontrole:

| Kontrola | Zakres |
| --- | --- |
| Bash Syntax | `bash -n` dla skryptów `.sh`. |
| ShellCheck | Statyczna analiza skryptów powłoki. |
| Python Smoke Test | Sprawdzenie struktury projektu wygenerowanego przez skrypt. |
| Homebrew Validator | Weryfikacja nazw pakietów, duplikatów i dostępności formuł/casków. |
| macOS Compatibility | Bezpieczne kontrole na runnerze macOS, bez pełnej instalacji aplikacji. |
| Gitleaks / Actionlint | Wykrywanie sekretów i walidacja workflowów. |
| Zsh Validation | Kontrola składni i konfiguracji plików Zsh. |

Lokalna podstawowa weryfikacja:

```bash
bash -n new_mac_setup.sh
bash -n new_python_proj_setup.sh

# Jeśli ShellCheck jest zainstalowany:
shellcheck new_mac_setup.sh new_python_proj_setup.sh
```

Wyniki testów znajdziesz w zakładce [Actions](https://github.com/piotrek1488/os-scripts/actions). Workflowy specyficzne dla macOS powinny być przypisane do gałęzi `macos`.

## Bezpieczeństwo i rozwiązywanie problemów

- **Homebrew / `mas` nie działa:** sprawdź instalację, `PATH`, logowanie do App Store i dostępność pakietu.
- **Pobieranie DMG kończy się błędem:** zweryfikuj adres źródłowy, podpis aplikacji i zgodność z macOS przed instalacją.
- **Zsh zgłasza brak komendy lub pluginu:** doinstaluj brakujące narzędzie albo warunkowo ładuj jego konfigurację.
- **Skrypt zatrzyma się w połowie:** przeczytaj ostatnie komunikaty błędu. Przed ponownym uruchomieniem sprawdź, które kroki zostały już wykonane — nie zakładaj, że instalator jest idempotentny.
- **Sekrety i dane prywatne:** nie commituj haseł, tokenów, kluczy SSH ani lokalnych plików zawierających poświadczenia.

## Rozwój projektu

Zmiany specyficzne dla systemu macOS wprowadzaj na gałęzi `macos`, a zmiany dotyczące Ubuntu/Linux — na `linux`. Przed wysłaniem Pull Requesta uruchom lokalne kontrole składni i sprawdź wyniki GitHub Actions.

## Licencja

Warunki używania kodu sprawdź w pliku `LICENSE` repozytorium, jeśli jest dostępny. Sam ten dokument nie nadaje kodowi odrębnej licencji.
