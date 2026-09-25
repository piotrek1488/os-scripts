# Weryfikacja list pakietów — 2026-09-24

Aktualizacja 2026-09-25: wszystkie osiem DEB ma teraz bezpośrednie linki w
listach kategorii `deb/*.txt` (jeden URL w wierszu) i automatyczne pobieranie przez instalator.
W tym dniu potwierdzono też oficjalny URL ChatGPT i OpenLogi 0.8.8;
[aktualne metadane DEB](deb/SOURCES.md) uzupełniają historyczne ustalenia poniżej.

Aktualizacja Surfshark/AdGuard 2026-09-25: po przywróceniu dostępu sieciowego
zweryfikowano podpis repozytorium Surfsharka i symulację instalacji `3.13.0-7797`.
Wspólna symulacja całej aktualnej listy 57 pakietów APT również przeszła; nie instalowano aplikacji.
Pakiet jest teraz w `apt/essentials.txt`, a repozytorium i klucz w `repositories.sources`.
AdGuard ma osobny [instalator Bash](../scripts/install-adguard.sh) używający oficjalnego
skryptu kanału `release` z `-v`; jego obsługę przetestowano offline.

Ponowna weryfikacja Signala 2026-09-25: `signal-desktop` pozostaje na liście
`apt/essentials.txt`. Parametry repozytorium porównano z oficjalnym
[signal-desktop.sources](https://updates.signal.org/static/desktop/apt/signal-desktop.sources),
a osadzony klucz jest identyczny z [keys.asc](https://updates.signal.org/desktop/apt/keys.asc).
APT poprawnie zweryfikował podpis; symulacja instalacji `8.28.0` przeszła.

**Cel:** Ubuntu 26.04 (resolute), amd64. Nie jest to deklaracja zgodności z Ubuntu 24.04 ani ARM.

Sprawdzono wszystkie dziewięć aktywnych list oraz historyczne pliki z `packages/del/`.
Historyczne pliki zachowano bez zmian w `archive/packages-original/`; dawny wrapper `install.sh` i pusty `external_repos.txt` nie są aktywną konfiguracją.
Nie przywracano Chromium obecnego wyłącznie w archiwum (Snap `chromium` istnieje, ale użytkownik usunął go z aktywnych list).

## Metoda i wynik

- Pobrano świeże, podpisane indeksy Ubuntu i repozytoriów producentów do odizolowanego katalogu `/tmp/package-audit`.
- Użyto pustego stanu dpkg oraz własnych plików sources/config/cache. Nie użyto firmowego repozytorium ani repozytoriów Debiana skonfigurowanych na hoście.
- Wszystkie 56 końcowych pakietów APT przeszło osobne symulacje instalacji; cały zestaw przeszedł również wspólną symulację zależności.
- Dla 16 Snapów potwierdzono `latest/stable`, architekturę amd64, wydawcę i tryb confinement bezpośrednio w API Snap Store.
- Sprawdzono składnię Bash, wszystkie źródła w `--dry-run`, alias `optional`, brak duplikatów i zgodność `--classic` z metadanymi sklepu.
- Nie instalowano aplikacji, nie testowano ich uruchomienia i nie zmieniano `/etc/apt`. Dostępny pakiet i rozwiązywalne zależności nie gwarantują działania GUI, sterowników czy logowania.
- Wersje poniżej są dowodem z dnia audytu, nie są przypięte w listach instalacyjnych.

## Każdy wpis z aktywnych list wejściowych

| Wpis wejściowy | Końcowa lista / nazwa | Wynik i źródło |
| --- | --- | --- |
| `apt/essentials.txt`: `chatgpt` | `deb/essentials.txt`: `chatgpt` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). Potwierdzony lokalnym dpkg; brak ustalonego publicznego adresu pobierania. |
| `apt/essentials.txt`: `dconf-editor` | `apt/essentials.txt`: `dconf-editor` | APT: `49.0-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/dconf-editor). |
| `apt/essentials.txt`: `filezilla` | `apt/essentials.txt`: `filezilla` | APT: `3.69.6-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/filezilla). |
| `apt/essentials.txt`: `gcolor3` | `apt/essentials.txt`: `gcolor3` | APT: `2.4.0-2build3`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/gcolor3). |
| `apt/essentials.txt`: `gnome-shell-extension-manager` | `apt/essentials.txt`: `gnome-shell-extension-manager` | APT: `0.6.5-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/gnome-shell-extension-manager). |
| `apt/essentials.txt`: `gnome-tweaks` | `apt/essentials.txt`: `gnome-tweaks` | APT: `49.0-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/gnome-tweaks). |
| `apt/essentials.txt`: `micro` | `apt/essentials.txt`: `micro` | APT: `2.0.15-2`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/micro). |
| `apt/essentials.txt`: `nedit` | `apt/essentials.txt`: `nedit` | APT: `1:5.7-7`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/nedit). |
| `apt/essentials.txt`: `microsoft-edge-stable` | `apt/essentials.txt`: `microsoft-edge-stable` | APT: `154.0.4258.37-1`; symulacja OK. [edge](https://packages.microsoft.com/repos/edge-stable/). |
| `apt/essentials.txt`: `network-manager-openvpn-gnome` | `apt/essentials.txt`: `network-manager-openvpn-gnome` | APT: `1.12.5-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/network-manager-openvpn-gnome). |
| `apt/essentials.txt`: `network-manager-pptp-gnome` | `apt/essentials.txt`: `network-manager-pptp-gnome` | APT: `1.2.12-6`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/network-manager-pptp-gnome). |
| `apt/essentials.txt`: `o365` | `apt/essentials.txt`: `o365` | APT: `4.0.4-ubuntu26.04`; symulacja OK. [himmelblau](https://himmelblau-idm.org/docs/installation/). |
| `apt/essentials.txt`: `pluma` | `apt/essentials.txt`: `pluma` | APT: `1.28.0-3build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/pluma). |
| `apt/essentials.txt`: `putty` | `apt/essentials.txt`: `putty` | APT: `0.83-3build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/putty). |
| `apt/essentials.txt`: `seahorse` | `apt/essentials.txt`: `seahorse` | APT: `47.0.1-3build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/seahorse). |
| `apt/essentials.txt`: `teams-for-linux` | `apt/essentials.txt`: `teams-for-linux` | APT: `2.22.0`; symulacja OK. [teams-for-linux](https://ismaelmartinez.github.io/teams-for-linux/installation/). |
| `apt/essentials.txt`: `timeshift` | `apt/essentials.txt`: `timeshift` | APT: `25.12.4-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/timeshift). |
| `apt/essentials.txt`: `ulauncher` | `apt/essentials.txt`: `ulauncher` | APT: `5.16.2-0ubuntu1ppa1~resolute`; symulacja OK. [ulauncher](https://ulauncher.io/). |
| `apt/essentials.txt`: `unzip` | `apt/essentials.txt`: `unzip` | APT: `6.0-29ubuntu1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/unzip). |
| `apt/essentials.txt`: `wget` | `apt/essentials.txt`: `wget` | APT: `1.25.0-2ubuntu4.4`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/wget). |
| `apt/essentials.txt`: `wmctrl` | `apt/essentials.txt`: `wmctrl` | APT: `1.07+git20240228.1105759-1build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/wmctrl). |
| `apt/essentials.txt`: `yad` | `apt/essentials.txt`: `yad` | APT: `7.2-1build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/yad). |
| `apt/essentials.txt`: `zip` | `apt/essentials.txt`: `zip` | APT: `3.0-15ubuntu3`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/zip). |
| `apt/essentials.txt`: `grep` | `apt/essentials.txt`: `grep` | APT: `3.12-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/grep). |
| `apt/essentials.txt`: `openlogi` | `deb/essentials.txt`: `openlogi` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). |
| `apt/essentials.txt`: `vscode` | `apt/essentials.txt`: `code` | APT: `1.139.0-1790100840`; symulacja OK. [vscode](https://code.visualstudio.com/docs/setup/linux). Poprawiono nazwę pakietu. |
| `apt/essentials.txt`: `telegram` | `snap/essentials.txt`: `telegram-desktop` | [Snap Store](https://snapcraft.io/telegram-desktop): `7.2.9`, `telegram-desktop`, `strict`. |
| `apt/essentials.txt`: `signal` | `apt/essentials.txt`: `signal-desktop` | APT: `8.28.0`; symulacja OK. [signal](https://signal.org/download/linux/). Poprawiono nazwę pakietu. |
| `apt/essentials.txt`: `surfshark` | `apt/essentials.txt`: `surfshark` | Aktualizacja 2026-09-25: podpisane repozytorium `ocean.surfshark.com/debian`, suite `stretch`, wersja `3.13.0-7797`; symulacja APT OK. Klucz z oficjalnego instalatora osadzono w `repositories.sources`. |
| `apt/essentials.txt`: `whatsapp` | `snap/essentials.txt`: `whatsie` | [Snap Store](https://snapcraft.io/whatsie): `6.1.1`, amd64, latest/stable, strict, wydawca `keshavnrj`. Nieoficjalny klient WhatsApp Web, wybrany po doprecyzowaniu zastosowania. |
| `apt/essentials.txt`: `onedrive` | `apt/essentials.txt`: `onedrive` | APT: `2.5.10-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/onedrive). |
| `apt/essentials.txt`: `adguard` | `scripts/install-adguard.sh` | [AdGuard for Linux](https://adguard.com/kb/adguard-for-linux/installation/) (`adguard-cli`): instalator producenta `AdguardTeam/AdGuardCLI/release/install.sh`, wywołanie przez `sh -s -- -v`. |
| `apt/essentials.txt`: `synaptics-repository-keyring` | `deb/essentials.txt`: `synaptics-repository-keyring` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). Brak pakietu w publicznym indeksie APT; producent publikuje osobny DEB inicjujący repo. |
| `apt/essentials.txt`: `adobe-acrobat-reader` | `deb/essentials.txt` — komentarz UNSUPPORTED | Brak potwierdzonego współczesnego natywnego DEB; [Adobe](https://www.adobe.com/acrobat/pdf-reader.html) oferuje aktualny Reader na Windows/macOS. |
| `apt/essentials.txt`: `tree` | `apt/essentials.txt`: `tree` | APT: `2.3.1-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/tree). |
| `apt/essentials.txt`: `gh` | `apt/essentials.txt`: `gh` | APT: `2.46.0-4`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/gh). |
| `apt/essentials.txt`: `git` | `apt/essentials.txt`: `git` | APT: `1:2.53.0-1ubuntu1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/git). |
| `apt/essentials.txt`: `curl` | `apt/essentials.txt`: `curl` | APT: `8.18.0-1ubuntu2.7`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/curl). |
| `apt/dev.txt`: `ansible` | `apt/dev.txt`: `ansible` | APT: `13.1.0+dfsg-1ubuntu1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/ansible). |
| `apt/dev.txt`: `cmake` | `apt/dev.txt`: `cmake` | APT: `4.2.3-2ubuntu2`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/cmake). |
| `apt/dev.txt`: `gcc` | `apt/dev.txt`: `gcc` | APT: `4:15.2.0-5ubuntu1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/gcc). |
| `apt/dev.txt`: `git-email` | `apt/dev.txt`: `git-email` | APT: `1:2.53.0-1ubuntu1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/git-email). |
| `apt/dev.txt`: `imagemagick` | `apt/dev.txt`: `imagemagick` | APT: `8:7.1.2.18+dfsg1-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/imagemagick). |
| `apt/dev.txt`: `kdiff3` | `apt/dev.txt`: `kdiff3` | APT: `1.12.4-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/kdiff3). |
| `apt/dev.txt`: `kiro` | `deb/dev.txt`: `kiro` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). |
| `apt/dev.txt`: `make` | `apt/dev.txt`: `make` | APT: `4.4.1-3`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/make). |
| `apt/dev.txt`: `moreutils` | `apt/dev.txt`: `moreutils` | APT: `0.69-1build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/moreutils). |
| `apt/dev.txt`: `notepadqq` | `apt/dev.txt`: `notepadqq` | APT: `2.0.0~beta1-4.1build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/notepadqq). |
| `apt/dev.txt`: `powershell` | `snap/dev.txt`: `powershell --classic` | [Snap Store](https://snapcraft.io/powershell): `7.6.5`, `canonical`, `classic`. Repozytorium Microsoft dla 26.04 istnieje i ma poprawny podpis, ale nie zawiera pakietu `powershell`; dlatego wybrano Snap. |
| `apt/dev.txt`: `python3` | `apt/dev.txt`: `python3` | APT: `3.14.3-0ubuntu2`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/python3). |
| `apt/dev.txt`: `python3-venv` | `apt/dev.txt`: `python3-venv` | APT: `3.14.3-0ubuntu2`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/python3-venv). |
| `apt/dev.txt`: `xmlstarlet` | `apt/dev.txt`: `xmlstarlet` | APT: `1.6.1-5build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/xmlstarlet). |
| `apt/dev.txt`: `docker` | `apt/dev.txt`: `docker-ce` | APT: `5:29.8.1-1~ubuntu.26.04~resolute`; symulacja OK. [docker](https://docs.docker.com/engine/install/ubuntu/). Poprawiono nazwę pakietu. |
| `apt/dev.txt`: `docker-compose` | `apt/dev.txt`: `docker-compose-plugin` | APT: `5.5.1-1~ubuntu.26.04~resolute`; symulacja OK. [docker](https://docs.docker.com/engine/install/ubuntu/). Poprawiono nazwę pakietu. |
| `apt/dev.txt`: `pyenv` | `apt/dev.txt`: `pyenv` | APT: `2.6.8-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/pyenv). |
| `apt/dev.txt`: `db-browser-for-sqlite` | `apt/dev.txt`: `sqlitebrowser` | APT: `3.13.1-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/sqlitebrowser). Poprawiono nazwę pakietu. |
| `apt/dev.txt`: `jq` | `apt/dev.txt`: `jq` | APT: `1.8.1-4ubuntu2`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/jq). |
| `apt/dev.txt`: `sqlite` | `apt/dev.txt`: `sqlite3` | APT: `3.46.1-9ubuntu0.3`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/sqlite3). Poprawiono nazwę pakietu. |
| `apt/entertainment.txt`: `gamemode` | `apt/entertainment.txt`: `gamemode` | APT: `1.8.2-2build1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/gamemode). |
| `apt/entertainment.txt`: `nuvio` | `deb/entertainment.txt`: `nuvio` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). |
| `apt/entertainment.txt`: `vlc` | `apt/entertainment.txt`: `vlc` | APT: `3.0.23-1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/vlc). |
| `apt/entertainment.txt`: `qbittorrent` | `apt/entertainment.txt`: `qbittorrent` | APT: `5.1.4-dmo1`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/qbittorrent). |
| `apt/entertainment.txt`: `heroic` | `deb/entertainment.txt`: `heroic` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). |
| `apt/entertainment.txt`: `ffmpeg-full` | `apt/entertainment.txt`: `ffmpeg` | APT: `7:8.0.1-3ubuntu2`; symulacja OK. [Ubuntu](https://packages.ubuntu.com/resolute/ffmpeg). Poprawiono nazwę pakietu. |
| `snap/essentials.txt`: `firefox` | `snap/essentials.txt`: `firefox` | [Snap Store](https://snapcraft.io/firefox): `156.0.1-1`, `mozilla`, `strict`. |
| `snap/essentials.txt`: `ferdium` | `snap/essentials.txt`: `ferdium` | [Snap Store](https://snapcraft.io/ferdium): `7.2.3`, `ferdium`, `strict`. |
| `snap/essentials.txt`: `gemini-desktop` | `snap/essentials.txt`: `gemini-desktop` | [Snap Store](https://snapcraft.io/gemini-desktop): `0.6.0-1-g69bbec4ce7`, `ken-vandine`, `strict`. |
| `snap/essentials.txt`: `gtk-theme-fluent` | `snap/essentials.txt`: `gtk-theme-fluent` | [Snap Store](https://snapcraft.io/gtk-theme-fluent): `2026-01-25`, `kyuyrii`, `strict`. |
| `snap/essentials.txt`: `thunderbird` | `snap/essentials.txt`: `thunderbird` | [Snap Store](https://snapcraft.io/thunderbird): `156.0.1-1`, `canonical`, `strict`. |
| `snap/dev.txt`: `drawio` | `snap/dev.txt`: `drawio` | [Snap Store](https://snapcraft.io/drawio): `31.3.2`, `jgraph`, `strict`. |
| `snap/dev.txt`: `glab` | `snap/dev.txt`: `glab` | [Snap Store](https://snapcraft.io/glab): `1.119.0`, `gitlab-cli`, `strict`. |
| `snap/dev.txt`: `openjdk` | `snap/dev.txt`: `openjdk` | [Snap Store](https://snapcraft.io/openjdk): `27+35`, `jgneff`, `strict`. |
| `snap/dev.txt`: `sublime-text --classic` | `snap/dev.txt`: `sublime-text --classic` | [Snap Store](https://snapcraft.io/sublime-text): `4213`, `snapcrafters`, `classic`. |
| `snap/dev.txt`: `yq` | `snap/dev.txt`: `yq` | [Snap Store](https://snapcraft.io/yq): `v4.49.2`, `mikefarah`, `strict`. |
| `snap/entertainment.txt`: `audacity` | `snap/entertainment.txt`: `audacity` | [Snap Store](https://snapcraft.io/audacity): `3.7.9`, `snapcrafters`, `strict`. |
| `snap/entertainment.txt`: `opencomic` | `snap/entertainment.txt`: `opencomic` | [Snap Store](https://snapcraft.io/opencomic): `1.6.4`, `ollm`, `strict`. |
| `deb/essentials.txt`: `caprine` | `deb/essentials.txt`: `caprine` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). Zachowano fork bankjaneo; dostępny Snap dotyczy upstreamu. |
| `deb/essentials.txt`: `google-chrome` | `apt/essentials.txt`: `google-chrome-stable` | APT: `154.0.8037.57-1`; symulacja OK. [google-chrome](https://www.google.com/linuxrepositories/). Poprawiono nazwę pakietu. |
| `deb/essentials.txt`: `google-drive` | `deb/essentials.txt` — komentarz UNSUPPORTED | [Google](https://support.google.com/drive/answer/2375082?hl=en): oficjalny Drive for desktop nie jest dostępny na Linuksie. Pozostaje wersja web; nie utworzono fikcyjnego DEB. |
| `deb/essentials.txt`: `copyclip` | `deb/essentials.txt` — komentarz UNSUPPORTED | [CopyClip](https://fiplab.com/apps/copyclip-for-mac): aplikacja macOS, zgodnie z doprecyzowaniem użytkownika. Brak wersji Linux. |
| `deb/dev.txt`: `docker-desktop` | `deb/dev.txt`: `docker-desktop` | Ręczny DEB; [konkretny projekt i źródło](deb/SOURCES.md). |
| `deb/entertainment.txt`: `jdownloader` | `snap/entertainment.txt`: `jdownloader2` | [Snap Store](https://snapcraft.io/jdownloader2): `0+git.6b03563`, `fnkr`, `strict`. |

Docker wymaga ponadto `docker-ce-cli`, `containerd.io` i `docker-buildx-plugin`; dodano je do `apt/dev.txt` zgodnie z [instrukcją producenta](https://docs.docker.com/engine/install/ubuntu/). Każdy z nich przeszedł osobną i wspólną symulację.

## Repozytoria i klucze

Pełne adresy repozytoriów, źródła kluczy, odciski (także podkluczy) i publiczne klucze są w [repositories.sources](apt/repositories.sources). Pierwotny audyt potwierdził podpisy 10 repozytoriów; 2026-09-25 dodano zweryfikowane repozytorium Surfshark. Końcowy plik aktywuje 9 z 11 wpisów.

| Repozytorium | Stan w pliku | Pakiety / uwaga |
| --- | --- | --- |
| [vscode](https://code.visualstudio.com/docs/setup/linux) | Aktywne | `code` |
| [edge](https://packages.microsoft.com/repos/edge-stable/) | Aktywne | `microsoft-edge-stable` |
| [powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu) | Wyłączone (`Enabled: no`) | `powershell` — brak pakietu w indeksie dla 26.04; użyto Snap. |
| [google-chrome](https://www.google.com/linuxrepositories/) | Aktywne | `google-chrome-stable` |
| [signal](https://signal.org/download/linux/) | Aktywne | `signal-desktop` |
| [teams-for-linux](https://ismaelmartinez.github.io/teams-for-linux/installation/) | Aktywne | `teams-for-linux` |
| [ulauncher](https://ulauncher.io/) | Aktywne | `ulauncher` |
| [docker](https://docs.docker.com/engine/install/ubuntu/) | Aktywne | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` |
| [himmelblau](https://himmelblau-idm.org/docs/installation/) | Aktywne | `o365` — publiczny podpisany indeks istnieje; dokumentacja opisuje też płatny kanał stable, więc przyszła dostępność wymaga ponownego sprawdzenia. |
| [synaptics](https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu) | Wyłączone (`Enabled: no`) | `synaptics-repository-keyring` — osobny DEB dodaje własny plik źródeł. |
| [surfshark](https://support.surfshark.com/hc/en-us/articles/5067279648146-How-to-set-up-Surfshark-VPN-on-Linux) | Aktywne | `surfshark`; repozytorium i klucz potwierdzone 2026-09-25. |
