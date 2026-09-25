# Przegląd konfiguracji aplikacji — 2026-09-24

Sprawdzono bieżące pliki użytkownika i ustawienia sesji Ubuntu 26.04 / GNOME 50.1, nie archiwum ze starego systemu.
Brak znalezionego pliku oznacza brak danych do odtworzenia w sprawdzonych lokalizacjach, a nie gwarancję, że aplikacja nie ma innego magazynu ustawień.

| Aplikacja | Sprawdzone miejsce | Wynik |
| --- | --- | --- |
| `ansible` | `.ansible.cfg`, `.config/ansible/ansible.cfg`, `/etc/ansible/ansible.cfg` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `cmake` | `.config/CMake` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `gcc` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `git-email` | `.gitconfig` | SMTP, tożsamość i podpisy pominięte; wspólne preferencje Git odtwarza skrypt. |
| `imagemagick` | `.config/ImageMagick`, `.magick` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `kdiff3` | `.config/kdiff3rc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `make` | `.make.rc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `moreutils` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `notepadqq` | `.config/notepadqq` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `python3` | `.pythonrc.py` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `python3-venv` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `xmlstarlet` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `docker-ce` | `/etc/docker/daemon.json`, `.docker/config.json` | Osobny skrypt: live-restore=true. Pominięto bip/fixed-cidr/mtu/iptables zależne od sieci hosta. |
| `docker-compose-plugin` | `.docker/config.json` | Brak przenośnych preferencji; poświadczenia i konfiguracja projektowa nie są kopiowane. |
| `pyenv` | `.pyenv/version` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `sqlitebrowser` | `.config/DB Browser for SQLite` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `jq` | `.jq` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `sqlite3` | `.sqliterc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `docker-ce-cli` | `.docker/config.json` | Plik zawiera dane logowania do rejestrów; nie kopiowano. |
| `containerd.io` | `/etc/containerd/config.toml` | Konfiguracja usługi pozostaje zarządzana przez pakiet Docker; brak własnej przenośnej części. |
| `docker-buildx-plugin` | `.docker/buildx` | Stan builderów/cache/rejestrów nie jest przenoszony. |
| `gamemode` | `.config/gamemode.ini`, `/etc/gamemode.ini` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `vlc` | `.config/vlc`, `.vlcrc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `qbittorrent` | `.config/qBittorrent` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `ffmpeg` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `dconf-editor` | `dconf` | Odtwarzane wybrane klucze GNOME; nie jest importowany pełny dconf.ini. |
| `filezilla` | `.config/filezilla`, `.filezilla` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `gcolor3` | `dconf` | Brak własnych zmienionych kluczy w bieżącym eksporcie dconf. |
| `gnome-shell-extension-manager` | `dconf` | Audyt 25 rozszerzeń, ich preferencje i archiwum kodu 17 rozszerzeń użytkownika: DESKTOP.md. |
| `gnome-tweaks` | `dconf` | Ustawienia GNOME: Fluent-Dark, Win11, MacTahoe, panel, klawiatura, zegar, zasilanie i kolory. |
| `micro` | `.config/micro` | Scalane 2 skróty komentarza; settings.json jest pusty. |
| `nedit` | `.nedit`, `.neditrc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `microsoft-edge-stable` | `.config/microsoft-edge/Default/Preferences` | Scalane wybrane preferencje wyglądu/języka/słowników z profilem Default. Bez zakładek, historii, haseł, rozszerzeń i kont. |
| `network-manager-openvpn-gnome` | `/etc/NetworkManager/system-connections` | Profile VPN/certyfikaty/poświadczenia pominięte; brak uniwersalnych preferencji GUI. |
| `network-manager-pptp-gnome` | `/etc/NetworkManager/system-connections` | Profile VPN i poświadczenia pominięte. |
| `o365` | `.config/o365-profiles` | Profile firmowe i dane kont pominięte. |
| `pluma` | `dconf` | Wybrane skuteczne wartości schematu GSettings; brak osobnego pliku użytkownika. |
| `putty` | `.putty` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `seahorse` | `dconf` | Wygląd listy/panelu z GSettings; klucze i pęk kluczy nie są kopiowane. |
| `teams-for-linux` | `.config/teams-for-linux/Preferences` | Odtwarzany polski słownik Electron; bez danych sesji. |
| `timeshift` | `/etc/timeshift/timeshift.json` | Osobny skrypt: harmonogramy i retencja. Wszystkie harmonogramy są obecnie wyłączone; UUID dysku i wykluczenia pominięte. |
| `ulauncher` | `.config/ulauncher` | Preferencje, wyszukiwarki, autostart i Ctrl+Spacja; oba motywy libadwaita oraz dodatki opisane w [raporcie Ulaunchera](../ulauncher/README.md). |
| `unzip` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `wget` | `.wgetrc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `wmctrl` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `yad` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `zip` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `grep` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `code` | `.config/Code/User/settings.json`, `.config/Code/User/keybindings.json` | Scalane 3 ustawienia: potwierdzenia usuwania/przeciągania i polskie locale rozszerzenia ChatGPT. |
| `signal-desktop` | `.config/Signal` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `onedrive` | `.config/onedrive` | Katalog istnieje, brak zwykłego pliku config; stan synchronizacji i dane kont pominięte. |
| `tree` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `gh` | `.config/gh/config.yml`, `.config/gh/hosts.yml` | Protokół https, prompt enabled, alias co=pr checkout; hosts.yml z tokenami pominięty. |
| `git` | `.gitconfig` | 42 wybrane preferencje/aliasy, w tym nedit, kdiff3, push.default=nothing. Bez tożsamości, kluczy podpisów, SMTP i firmowych przekierowań URL. |
| `curl` | `.curlrc` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `google-chrome-stable` | `.config/google-chrome/Default/Preferences` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `drawio` | `.config/drawio`, `snap/drawio/current/.config/draw.io` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `glab` | `.config/glab-cli/config.yml`, `snap/glab/current/.config/glab-cli/config.yml` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `openjdk` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `sublime-text` | `.config/sublime-text/Packages/User/Preferences.sublime-settings` | Odtwarzany rozmiar fontu 13. |
| `yq` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |
| `powershell` | `.config/powershell` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `audacity` | `.config/audacity`, `snap/audacity/current/.audacity-data` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `opencomic` | `.config/OpenComic`, `snap/opencomic/current/.config/OpenComic` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `jdownloader2` | `.jd`, `snap/jdownloader2/current` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `firefox` | `snap/firefox/common/.mozilla/firefox/profiles.ini` | Wygląd toolbar-theme=0 do zarządzanego bloku user.js profilu domyślnego; flagi migracji pominięto. |
| `ferdium` | `snap/ferdium/current/.config/Ferdium/config/settings.json` | Preferencje interfejsu i skróty; zachowano obecne locale en-US. Bez usług/kont/hasła blokady/proxy. |
| `gemini-desktop` | `snap/gemini-desktop/current/.config/gemini-desktop/Preferences` | Odtwarzany polski słownik; pominięte flagi migracji i sesja. |
| `gtk-theme-fluent` | Parametry poleceń / konfiguracja projektowa | Snap zasobów nie ma osobnych preferencji. Wygląd GNOME odtwarza archiwum lokalnych motywów. |
| `thunderbird` | `.thunderbird`, `snap/thunderbird/common/.thunderbird` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `telegram-desktop` | `.local/share/TelegramDesktop`, `snap/telegram-desktop/current` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `whatsie` | `.config/whatsie`, `snap/whatsie/current` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `docker-desktop` | `.docker/desktop/settings-store.json`, `.docker/desktop/settings.json` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `kiro` | `.config/Kiro/User/settings.json` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `nuvio` | `.config/nuvio`, `.local/share/nuvio` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `heroic` | `.config/heroic` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `caprine` | `.config/Caprine`, `.config/caprine` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `chatgpt` | `.config/Codex` | Istnieje profil Codex/Electron z sesją; brak znalezionego samodzielnego, przenośnego settings.json. Nie kopiowano profilu ani danych rozmów. |
| `openlogi` | `.config/OpenLogi`, `.local/share/OpenLogi` | Nie znaleziono konfiguracji w sprawdzonych lokalizacjach. |
| `synaptics-repository-keyring` | Parametry poleceń / konfiguracja projektowa | Narzędzie/biblioteka bez osobnej konfiguracji do odtworzenia. |

## Rozszerzenia GNOME

Aktualny audyt 25 rozszerzeń i różnice ich preferencji są w [DESKTOP.md](DESKTOP.md).
Kod 17 rozszerzeń użytkownika jest w `assets/extensions.tar.gz`; skrypt
`restore-desktop.sh` instaluje brakujące katalogi i zachowuje istniejące wersje.
Rozszerzenia systemowe wymagają pakietów wskazanych w `desktop.json`.
Quick Settings Tweaks 29 zachowuje wybór włączenia, ale GNOME 50 blokuje jego
uruchomienie jako niezgodne. Skrypt nie wyłącza kontroli zgodności.
