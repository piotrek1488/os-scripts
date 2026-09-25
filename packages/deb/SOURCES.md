# Źródła pakietów DEB

Stan: 2026-09-25, Ubuntu 26.04 / amd64. Bezpośrednie adresy do pobrania znajdują
się w [essentials.txt](essentials.txt), [dev.txt](dev.txt) i
[entertainment.txt](entertainment.txt), po jednym linku w wierszu.
`bash install.sh --source deb` pobiera wybrane pliki,
sprawdza je i instaluje przez APT wraz z zależnościami.

Dla wszystkich ośmiu URL-i odczytano nagłówki rzeczywistych plików DEB (HTTP Range),
w tym pola `Package`, `Architecture` i `Version`. Nie pobierano pełnych dużych aplikacji
ani nie instalowano ich. Kontrola archiwum DEB i zależności następuje przy uruchomieniu
instalatora; nie wykonano testów uruchomienia aplikacji.

| Kategoria | Pakiet / wersja sprawdzonego DEB | Źródło |
| --- | --- | --- |
| essentials | `caprine` 2.61.25 | [bankjaneo/caprine](https://github.com/bankjaneo/caprine/releases/tag/v2.61.25), `Caprine-2.61.25-amd64.deb`. Zachowano wskazany fork. Snap i Gemfury dotyczą upstreamu sindresorhus. |
| essentials | `chatgpt` 26.917.71314 | [Oficjalna instrukcja OpenAI dla Linux](https://learn.chatgpt.com/docs/linux/linux-app), bezpośredni DEB amd64 z `persistent.oaistatic.com`. Adres `latest` zwraca aktualne wydanie. |
| essentials | `openlogi` 0.8.8 | [AprilNEA/OpenLogi](https://github.com/AprilNEA/OpenLogi/releases/tag/v0.8.8), `openlogi-v0.8.8-linux-amd64.deb`. Nowsze wydanie niż 0.8.7 z audytu 24 września. |
| essentials | `synaptics-repository-keyring` 2022.01 (`all`) | [Pakiet inicjujący repozytorium Synaptics](https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb). Dodaje klucz i własny `synaptics.list`. Nie jest samym sterownikiem DisplayLink. |
| dev | `kiro` 1.1.70-1790200420 | [Kiro Downloads](https://kiro.dev/downloads/), oficjalny DEB x64 dla Debian/Ubuntu 24+. Link wskazuje wersję 1.1.70. Nie użyto repozytorium podmiotu trzeciego `kiro-repo.aws.nz`. |
| dev | `docker-desktop` 4.92.0-240144 | [Instrukcja Docker Desktop dla Ubuntu](https://docs.docker.com/desktop/setup/install/linux/ubuntu/), `docker-desktop-amd64.deb`. Adres zwraca aktualne wydanie. Zależność `docker-ce-cli` wymaga repozytorium Docker. |
| entertainment | `nuvio` 1.1.25-1 | [NuvioMedia/NuvioDesktop](https://github.com/NuvioMedia/NuvioDesktop/releases/tag/0.1.25-alpha), `Nuvio-Linux-x86_64-0.1.25-alpha.deb`. Tag wydania alpha różni się od wersji zapisanej wewnątrz DEB. |
| entertainment | `heroic` 2.22.3 | [Heroic Games Launcher](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/tag/v2.22.3), `Heroic-2.22.3-linux-amd64.deb`. |

Wszystkie pakiety mają architekturę `amd64`, poza keyringiem Synaptics (`all`).

## Wyjątki poza instalacją DEB

Po doprecyzowaniu nazw przez użytkownika:

- `copyclip`: [CopyClip](https://fiplab.com/apps/copyclip-for-mac) jest aplikacją macOS; brak wersji Linux.
- `google-drive`: oficjalny [Google Drive for desktop](https://support.google.com/drive/answer/2375082?hl=en)
  nie jest dostępny na Linuksie. Można używać wersji web; nie wpisano fikcyjnego `google-drive.deb`.
- `adguard`: [AdGuard for Linux](https://adguard.com/kb/adguard-for-linux/installation/)
  (`adguard-cli`) instaluje [scripts/install-adguard.sh](../../scripts/install-adguard.sh)
  przez wskazany instalator kanału `release`, z argumentem `-v`.
  Uruchomienie: `bash scripts/install-adguard.sh --apply`.
- `adobe-acrobat-reader`: aktualny [Adobe Reader](https://www.adobe.com/acrobat/pdf-reader.html)
  jest oferowany na Windows/macOS; brak potwierdzonego aktualnego natywnego DEB.
- `surfshark`: dodany do `apt/essentials.txt`. Repozytorium
  `https://ocean.surfshark.com/debian stretch main` i publiczny klucz z
  [oficjalnego instalatora](https://downloads.surfshark.com/linux/debian-install.sh)
  są w [repositories.sources](../apt/repositories.sources). Po przywróceniu dostępu
  2026-09-25 APT zweryfikował podpis repozytorium; symulacja instalacji
  `surfshark` w wersji `3.13.0-7797` dla Ubuntu 26.04 / amd64 przeszła.

WhatsApp przeniesiono do Snap jako [Whatsie](https://snapcraft.io/whatsie):
nieoficjalny klient WhatsApp Web autora `keshavbhatt`, wydawca `keshavnrj`.
API sklepu potwierdziło wersję `6.1.1`, `latest/stable`, amd64, `strict`.
