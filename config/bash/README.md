# Konfiguracja Bash

Pliki pochodzą z konfiguracji użytkownika odczytanej 2026-09-25:

- `.bashrc.user`: kolory i układ promptu, Git w prompcie, LESS, LANG, TMOUT,
  ładowanie aliasów i funkcji oraz opcjonalne środowisko firmowe.
- `.bash_aliases`: wszystkie 46 aktywnych aliasów oraz wyłączenie aliasów cp/mv/rm.
- `.bash_functions`: wszystkie 13 funkcji, m.in. Kerberos, Flexlab, moduły Java,
  Citrix i `git_reset`. Są definicjami do ręcznego wywołania.
- `bashrc-loader.sh`: blok dopisywany do istniejącego `.bashrc`.

Usunięto dawne zakomentowane polecenia; część zawierała hasła lub poświadczenia CLI.
Nie skopiowano kluczy, keytabów ani danych konta Git. EMAIL i USER_NAME są odczytywane
z lokalnego Git podczas otwierania terminala. Dawne ścieżki `/home/epiolud` wskazują
teraz `${HOME}`. Pozostałe definicje aliasów i funkcji zachowują dotychczasowe działanie
oraz zależności, także od firmowych katalogów, poleceń `module` i starszego Pythona.
Funkcja `set_venv` dotyczy starego Flexlab; nie zastępuje etapu tworzenia `~/.venv`.

W `.bashrc.user` usunięto powtórne ładowanie aliasów oraz automatyczne odpytywanie
sieciowego `/proj/flexlab` przez `df`. Ścieżki startowe są używane tylko wtedy, gdy
istnieją. Prompt korzysta z osobistych plików Git lub ich systemowych odpowiedników.
Loader unika ponownego ładowania, jeśli istniejący `.bashrc` już wczytał `.bashrc.user`.
Ręczne `source ~/.bashrc.user` nadal pozwala ponownie wczytać preferencje.

```bash
bash scripts/restore-bash.sh --dry-run
bash scripts/restore-bash.sh --apply
```

Skrypt jest także częścią etapu `settings` w `setup.sh`. Wymaga Bash i standardowych
narzędzi systemowych, działa bez sudo i bez jq. Opcja `--home-dir KATALOG` pozwala
przygotować pliki w innym katalogu, np. tymczasowym podczas testów.

Przed zapisem sprawdza składnię wszystkich czterech wynikowych plików bez ich wykonania.
Istniejący `.bashrc` zachowuje poza własnym blokiem; trzy pozostałe pliki zastępuje
kopiami z repozytorium. Zmieniane pliki otrzymują kopie w
`~/.local/state/os-scripts/backups/bash-*`; kopie mogą zawierać lokalne dane prywatne.
Cel i kopie są chronione przed zapisem do repozytorium, także przez dowiązania.
Kolejne uruchomienie z tą samą konfiguracją nie dopisuje loadera ani nowych kopii.
Otwórz nowy terminal Bash po zastosowaniu ustawień.
