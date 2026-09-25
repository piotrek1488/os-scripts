# Bieżące ustawienia a wartości domyślne — 2026-09-25

Ubuntu 26.04.1, GNOME Shell 50.1. Porównano **efektywne wartości domyślne zainstalowanego systemu**, z nadpisaniami Ubuntu i firmowymi, przez `Gio.Settings.get_default_value()`. To nie jest porównanie z czystym upstream GNOME. Wiersze poniżej zawierają różnice; jawne zapisy identyczne z domyślną wartością nie są liczone jako zmiany.

Polecenie odtwarzania: `bash scripts/restore-desktop.sh --apply`. Domyślnie skrypt tylko pokazuje plan. Pełne wartości są w `desktop.json`, a skrypt wykonuje polecenia dconf/gsettings i narzędzi systemowych.

## 1. Ustawienia ogólne systemu

- Konto: polski język i formaty (`pl_PL.UTF-8`), systemowe `LANG=en_US.UTF-8`. Klawiatura sesji: polska; systemowy układ X11: `us`, model `pc105`. Skrypt zachowuje ten obecny podział.
- Strefa: Europe/Warsaw, NTP aktywne, profil zasilania balanced. Nie da się określić jednego domyślnego języka, strefy ani profilu ekranu: zależą od instalacji i sprzętu.
- Bezczynność: brak wygaszania (`idle-delay=0`), przygaszanie wyłączone; zasilanie sieciowe nie usypia systemu. Night Light: ręczny harmonogram, 4700 K.
- Przeglądarka domyślna: Microsoft Edge. Powiązania MIME są scalane przez `xdg-mime`; brakująca aplikacja jest pomijana.
- Dodatkowe skojarzenia wybrane dla instalatora: Sublime Text (`sublime-text_subl.desktop`) dla `text/plain`, `application/json`, `application/xml`, `text/x-python` i `text/x-shellscript`. Ustawia je etap `desktop` pełnego instalatora, po instalacji aplikacji.

### Monitory (obecna sesja)

| Wyjście | Rozdzielczość / Hz | Pozycja | Skala | Główny |
| --- | --- | --- | --- | --- |
| DP-4 | 2560×1440 / 59.95 | 2560, 0 | 100% | nie |
| eDP-1 | 2560×1600 / 120.00 | 1572, 1440 | 125% | nie |
| DP-6 | 2560×1440 / 59.95 | 0, 0 | 100% | tak |

`files/monitors.xml` zachowuje także dwa wcześniejsze profile połączeń i identyfikatory monitorów potrzebne GNOME. Jest przeznaczony dla tego sprzętu; będzie odczytany przy kolejnym logowaniu. Skrypt nie przełącza monitorów w trakcie pracy.

### Różnice GNOME

Liczba przenoszonych różnic: **46**.

| Klucz | Domyślnie | Obecnie / wartość przenośna |
| --- | --- | --- |
| `/org/gnome/desktop/a11y/magnifier/cross-hairs-length` | `4096` | `58` |
| `/org/gnome/desktop/app-folders/folder-children` | `@as []` | `['System', 'Utilities', 'YaST', 'Pardus']` |
| `/org/gnome/desktop/background/picture-uri` | `'(firmowa tapeta systemowa)'` | `'file://@HOME@/.local/share/backgrounds/os-scripts-current.jpg'` |
| `/org/gnome/desktop/background/picture-uri-dark` | `'(firmowa ciemna tapeta systemowa)'` | `'file://@HOME@/.local/share/backgrounds/os-scripts-current.jpg'` |
| `/org/gnome/desktop/background/primary-color` | `'#023c88'` | `'#000000000000'` |
| `/org/gnome/desktop/background/secondary-color` | `'#5789ca'` | `'#000000000000'` |
| `/org/gnome/desktop/calendar/show-weekdate` | `false` | `true` |
| `/org/gnome/desktop/calendar/week-start-day` | `'default'` | `'monday'` |
| `/org/gnome/desktop/input-sources/sources` | `@a(ss) []` | `[('xkb', 'pl')]` |
| `/org/gnome/desktop/interface/accent-color` | `'orange'` | `'blue'` |
| `/org/gnome/desktop/interface/clock-show-seconds` | `false` | `true` |
| `/org/gnome/desktop/interface/clock-show-weekday` | `false` | `true` |
| `/org/gnome/desktop/interface/color-scheme` | `'default'` | `'prefer-dark'` |
| `/org/gnome/desktop/interface/show-battery-percentage` | `false` | `true` |
| `/org/gnome/desktop/peripherals/keyboard/numlock-state` | `false` | `true` |
| `/org/gnome/desktop/peripherals/mouse/speed` | `0.0` | `0.79746835443037978` |
| `/org/gnome/desktop/peripherals/touchpad/speed` | `0.0` | `0.38461538461538458` |
| `/org/gnome/desktop/screensaver/picture-uri` | `'file:///usr/share/backgrounds/warty-final-ubuntu.png'` | `'file://@HOME@/.local/share/backgrounds/os-scripts-current.jpg'` |
| `/org/gnome/desktop/screensaver/primary-color` | `'#023c88'` | `'#000000000000'` |
| `/org/gnome/desktop/screensaver/secondary-color` | `'#5789ca'` | `'#000000000000'` |
| `/org/gnome/desktop/session/idle-delay` | `uint32 300` | `uint32 0` |
| `/org/gnome/mutter/workspaces-only-on-primary` | `true` | `false` |
| `/org/gnome/settings-daemon/plugins/color/night-light-enabled` | `false` | `true` |
| `/org/gnome/settings-daemon/plugins/color/night-light-schedule-automatic` | `true` | `false` |
| `/org/gnome/settings-daemon/plugins/color/night-light-temperature` | `uint32 2700` | `uint32 4700` |
| `/org/gnome/settings-daemon/plugins/power/ambient-enabled` | `true` | `false` |
| `/org/gnome/settings-daemon/plugins/power/idle-dim` | `true` | `false` |
| `/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout` | `0` | `3600` |
| `/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type` | `'suspend'` | `'nothing'` |
| `/org/gnome/shell/app-picker-layout` | `[{'org.gnome.Geary.desktop': <{'position': <0>}>, 'org.gnome.Contacts.desktop': <{'position': <1>}>, 'org.gnome.Weather.desktop': <{'position': <2>}>, 'org.gnome.clocks.desktop': <{'position': <3>}>, 'org.gnome.Maps.desktop': <{'position… (pełna wartość w desktop.json)` | `[{'org.gnome.Calculator.desktop': <{'position': <0>}>, 'firmware-updater_firmware-updater.desktop': <{'position': <1>}>, 'yad-icon-browser.desktop': <{'position': <2>}>, 'org.gnome.clocks.desktop': <{'position': <3>}>, 'gnome-language-se… (pełna wartość w desktop.json)` |
| `/org/gnome/shell/favorite-apps` | `['ubuntu-desktop-bootstrap_ubuntu-desktop-bootstrap.desktop', 'firefox_firefox.desktop', 'thunderbird_thunderbird.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Rhythmbox3.desktop', 'libreoffice-writer.desktop', 'snap-store_snap-stor… (pełna wartość w desktop.json)` | `['org.gnome.Nautilus.desktop', 'microsoft-edge.desktop', 'org.gnome.Ptyxis.desktop', 'o365-outlook.desktop', 'o365-teams.desktop']` |
| `/org/gnome/desktop/app-folders/folders/Pardus/translate` | `false` | `true` |
| `/org/gnome/desktop/app-folders/folders/Pardus/categories` | `@as []` | `['X-Pardus-Apps']` |
| `/org/gnome/desktop/app-folders/folders/Pardus/name` | `''` | `'X-Pardus-Apps.directory'` |
| `/org/gnome/desktop/app-folders/folders/System/translate` | `false` | `true` |
| `/org/gnome/desktop/app-folders/folders/System/name` | `''` | `'X-GNOME-Shell-System.directory'` |
| `/org/gnome/desktop/app-folders/folders/System/apps` | `@as []` | `['nm-connection-editor.desktop', 'org.gnome.baobab.desktop', 'org.gnome.DiskUtility.desktop', 'im-config.desktop', 'org.gnome.Logs.desktop', 'org.gnome.Sysprof.desktop']` |
| `/org/gnome/desktop/app-folders/folders/Utilities/translate` | `false` | `true` |
| `/org/gnome/desktop/app-folders/folders/Utilities/name` | `''` | `'X-GNOME-Shell-Utilities.directory'` |
| `/org/gnome/desktop/app-folders/folders/Utilities/apps` | `@as []` | `['org.gnome.Papers.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Loupe.desktop', 'org.gnome.seahorse.Application.desktop']` |
| `/org/gnome/desktop/app-folders/folders/YaST/translate` | `false` | `true` |
| `/org/gnome/desktop/app-folders/folders/YaST/categories` | `@as []` | `['X-SuSE-YaST']` |
| `/org/gnome/desktop/app-folders/folders/YaST/name` | `''` | `'suse-yast.directory'` |
| `/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command` | `''` | `'ulauncher-toggle'` |
| `/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name` | `''` | `'ulauncher'` |
| `/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding` | `''` | `'<Control>space'` |

## 2. Dostrajanie (GNOME Tweaks)

Wygląd: Fluent-Dark (GTK i Shell), ikony Win11, kursor MacTahoe, dźwięki freedesktop. Czcionki nie mają zmian użytkownika względem obecnych domyślnych wartości. Autostart Ulaunchera odtwarza dołączony plik `.desktop`.

Liczba przenoszonych różnic: **7**.

| Klucz | Domyślnie | Obecnie / wartość przenośna |
| --- | --- | --- |
| `/org/gnome/desktop/interface/cursor-theme` | `'Yaru'` | `'MacTahoe'` |
| `/org/gnome/desktop/interface/gtk-enable-primary-paste` | `false` | `true` |
| `/org/gnome/desktop/interface/gtk-theme` | `'Yaru'` | `'Fluent-Dark'` |
| `/org/gnome/desktop/interface/icon-theme` | `'Yaru'` | `'Win11'` |
| `/org/gnome/desktop/sound/theme-name` | `'Yaru'` | `'freedesktop'` |
| `/org/gnome/desktop/wm/preferences/action-middle-click-titlebar` | `'lower'` | `'none'` |
| `/org/gnome/mutter/overlay-key` | `'Super'` | `'Super_L'` |

## 3. Menedżer rozszerzeń

Kod 17 rozszerzeń użytkownika dołączono w `assets/extensions.tar.gz`. Skrypt instaluje brakujące katalogi; istniejących wersji nie nadpisuje. Rozszerzenia systemowe pochodzą z pakietów Ubuntu/Himmelblau. Stan „włączone” i stan działania są rozdzielone.

| Rozszerzenie | Wersja | Włączone | Stan w tej sesji | Pochodzenie |
| --- | --- | --- | --- | --- |
| Coverflow Alt-Tab (`CoverflowAltTab@palatis.blogspot.com`) | 88 | nie | INITIALIZED | archiwum użytkownika |
| Vitals (`Vitals@CoreCoding.com`) | 85 | tak | ACTIVE | archiwum użytkownika |
| Add to Desktop (`add-to-desktop@tommimon.github.com`) | 16 | tak | ACTIVE | archiwum użytkownika |
| ArcMenu (`arcmenu@arcmenu.com`) | 73 | tak | ACTIVE | archiwum użytkownika |
| Blur my Shell (`blur-my-shell@aunetx`) | 72 | nie | INITIALIZED | archiwum użytkownika |
| Clipboard Indicator (`clipboard-indicator@tudmotu.com`) | 71 | tak | ACTIVE | archiwum użytkownika |
| Compiz alike magic lamp effect (`compiz-alike-magic-lamp-effect@hermes83.github.com`) | 25 | nie | INITIALIZED | archiwum użytkownika |
| Compiz windows effect (`compiz-windows-effect@hermes83.github.com`) | 31 | nie | INITIALIZED | archiwum użytkownika |
| Dash to Panel (`dash-to-panel@jderose9.github.com`) | 74 | tak | ACTIVE | archiwum użytkownika |
| Dash2Dock Animated (`dash2dock-lite@icedman.github.com`) | 92 | nie | INITIALIZED | archiwum użytkownika |
| Date Menu Formatter (`date-menu-formatter@marcinjakubowski.github.com`) | 19 | tak | ACTIVE | archiwum użytkownika |
| Just Perfection (`just-perfection-desktop@just-perfection`) | 37 | tak | ACTIVE | archiwum użytkownika |
| Quick Settings Tweaks (`quick-settings-tweaks@qwreey`) | 29 | tak | OUT OF DATE | archiwum użytkownika |
| Run or raise (`run-or-raise@edvard.cz`) | 44 | tak | ACTIVE | archiwum użytkownika |
| Space Bar (`space-bar@luchrioh`) | 39 | nie | INITIALIZED | archiwum użytkownika |
| User Themes (`user-theme@gnome-shell-extensions.gcampax.github.com`) | 79 | tak | ACTIVE | archiwum użytkownika |
| Lockscreen Studio (`lockscreen-studio@pedro.projects`) | 7 | tak | INACTIVE | archiwum użytkownika |
| Desktop Icons NG (DING) (`ding@rastersoft.com`) | pakiet systemowy | tak | ACTIVE | gnome-shell-ubuntu-extensions |
| SNAPD Permission Prompting (`snapd-prompting@canonical.com`) | pakiet systemowy | tak | ACTIVE | gnome-shell-ubuntu-extensions |
| Snapd Search Provider (`snapd-search-provider@canonical.com`) | pakiet systemowy | tak | ACTIVE | gnome-shell-ubuntu-extensions |
| Ubuntu Tiling Assistant (`tiling-assistant@ubuntu.com`) | 54 | tak | ACTIVE | gnome-shell-ubuntu-extensions |
| Ubuntu AppIndicators (`ubuntu-appindicators@ubuntu.com`) | pakiet systemowy | tak | ACTIVE | gnome-shell-ubuntu-extensions |
| Ubuntu Dock (`ubuntu-dock@ubuntu.com`) | 105 | nie | INITIALIZED | gnome-shell-ubuntu-extensions |
| Web Search Provider (`web-search-provider@ubuntu.com`) | pakiet systemowy | tak | ACTIVE | gnome-shell-ubuntu-extensions |
| Himmelblau QR Greeter (`qr-greeter@himmelblau-idm.org`) | 1 | tak | INACTIVE | himmelblau-qr-greeter |

**Quick Settings Tweaks 29** jest włączone, ale ma stan `OUT OF DATE`: deklaruje GNOME 46–48. Skrypt zachowuje żądany stan włączenia i pozostawia walidację wersji aktywną; GNOME 50 nie załaduje tej wersji. Lockscreen Studio i QR Greeter są `INACTIVE`, co samo w sobie nie dowodzi błędu — działają w odpowiednich trybach sesji.

### Preferencje rozszerzeń różne od domyślnych

Liczba przenoszonych różnic: **45**.

| Klucz | Domyślnie | Obecnie / wartość przenośna |
| --- | --- | --- |
| `/org/gnome/shell/extensions/vitals/hot-sensors` | `['_memory_usage_', '_system_load_1m_', '__network-rx_max__']` | `['_processor_usage_', '_memory_usage_', '_system_load_1m_']` |
| `/org/gnome/shell/extensions/arcmenu/context-menu-items` | `[{'id': 'org.gnome.Extensions.desktop'}, {'id': 'ArcMenu_Settings', 'name': 'ArcMenu Settings', 'icon': 'ArcMenu_ArcMenuIcon'}, {'id': 'ArcMenu_PanelExtensionSettings', 'name': 'Panel Extension Settings', 'icon': 'application-x-addon-sym… (pełna wartość w desktop.json)` | `[{'id': 'ArcMenu_Settings', 'name': 'ArcMenu Settings', 'icon': 'ArcMenu_ArcMenuIcon'}, {'id': 'ArcMenu_PanelExtensionSettings', 'name': 'Panel Extension Settings', 'icon': 'application-x-addon-symbolic'}, {'id': 'ArcMenu_Separator', 'na… (pełna wartość w desktop.json)` |
| `/org/gnome/shell/extensions/arcmenu/eleven-layout-extra-shortcuts` | `[{'id': 'org.gnome.Nautilus.desktop'}, {'id': 'org.gnome.Terminal.desktop'}, {'id': 'org.gnome.Settings.desktop'}]` | `[{'id': 'org.gnome.Nautilus.desktop'}, {'id': 'org.gnome.Settings.desktop'}]` |
| `/org/gnome/shell/extensions/arcmenu/hide-overview-on-startup` | `false` | `true` |
| `/org/gnome/shell/extensions/arcmenu/menu-button-icon` | `'resource:///org/gnome/shell/extensions/arcmenu/icons/scalable/actions/icon-arcmenu-logo-symbolic.svg'` | `'@HOME@/.local/share/icons/os-scripts-menu.webp'` |
| `/org/gnome/shell/extensions/arcmenu/menu-button-icon-size` | `20` | `32` |
| `/org/gnome/shell/extensions/arcmenu/menu-button-middle-click-action` | `'ArcMenu'` | `'None'` |
| `/org/gnome/shell/extensions/arcmenu/menu-height` | `550` | `650` |
| `/org/gnome/shell/extensions/arcmenu/menu-layout` | `'arcmenu'` | `'11'` |
| `/org/gnome/shell/extensions/arcmenu/multi-monitor` | `false` | `true` |
| `/org/gnome/shell/extensions/arcmenu/pinned-apps` | `[{'id': 'firefox.desktop'}, {'id': 'org.gnome.Nautilus.desktop'}, {'id': 'org.gnome.Terminal.desktop'}, {'id': 'gnome-extensions prefs arcmenu@arcmenu.com', 'name': 'ArcMenu Settings', 'icon': 'ArcMenu_ArcMenuIcon'}]` | `[{'id': 'org.gnome.Nautilus.desktop'}, {'id': 'gnome-extensions prefs arcmenu@arcmenu.com', 'name': 'ArcMenu Settings', 'icon': 'ArcMenu_ArcMenuIcon'}]` |
| `/org/gnome/shell/extensions/arcmenu/power-options` | `[(0, true), (1, true), (2, true), (3, true), (4, false), (5, false), (6, false), (7, false)]` | `[(0, true), (1, true), (4, true), (2, true), (3, true), (5, false), (6, false), (7, false)]` |
| `/org/gnome/shell/extensions/dash-to-panel/animate-appicon-hover-animation-extent` | `{'RIPPLE': 4, 'PLANK': 4}` | `{'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}` |
| `/org/gnome/shell/extensions/dash-to-panel/panel-anchors` | `'{}'` | `'{"0":"MIDDLE","1":"MIDDLE","2":"MIDDLE"}'` |
| `/org/gnome/shell/extensions/dash-to-panel/panel-element-positions` | `'{}'` | `'{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":t… (pełna wartość w desktop.json)` |
| `/org/gnome/shell/extensions/date-menu-formatter/apply-all-panels` | `false` | `true` |
| `/org/gnome/shell/extensions/date-menu-formatter/custom-locale` | `''` | `'pl-PL'` |
| `/org/gnome/shell/extensions/date-menu-formatter/font-weight` | `'initial'` | `'bold'` |
| `/org/gnome/shell/extensions/date-menu-formatter/formatter` | `'01_luxon'` | `'02_original'` |
| `/org/gnome/shell/extensions/date-menu-formatter/pattern` | `'EEE, MMM d  H : mm'` | `'H:mm:ss\\ndd/MM/yyyy'` |
| `/org/gnome/shell/extensions/date-menu-formatter/use-default-locale` | `true` | `false` |
| `/org/gnome/shell/extensions/just-perfection/animation` | `1` | `4` |
| `/org/gnome/shell/extensions/just-perfection/clock-menu-position` | `0` | `1` |
| `/org/gnome/shell/extensions/just-perfection/keyboard-layout` | `true` | `false` |
| `/org/gnome/shell/extensions/just-perfection/notification-banner-position` | `1` | `5` |
| `/org/gnome/shell/extensions/just-perfection/panel-in-overview` | `false` | `true` |
| `/org/gnome/shell/extensions/just-perfection/support-notifier-type` | `1` | `0` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/dnd-quick-toggle-indicator-position` | `'system-tray'` | `'date-menu'` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/system-items-layout-enabled` | `false` | `true` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/system-items-layout-hide-lock` | `false` | `true` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/system-items-layout-hide-screenshot` | `false` | `true` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/system-items-layout-hide-shutdown` | `false` | `true` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/system-items-layout-order` | `['battery', 'laptopSpacer', 'screenshot', 'settings', 'desktopSpacer', 'lock', 'shutdown']` | `['shutdown', 'lock', 'settings', 'desktopSpacer', 'screenshot', 'laptopSpacer', 'battery']` |
| `/org/gnome/shell/extensions/quick-settings-tweaks/volume-mixer-enabled` | `true` | `false` |
| `/org/gnome/shell/extensions/run-or-raise/move-window-to-active-workspace` | `false` | `true` |
| `/org/gnome/shell/extensions/user-theme/name` | `''` | `'Fluent-Dark'` |
| `/org/gnome/shell/extensions/lockscreen-studio/clock-font-size` | `80` | `200` |
| `/org/gnome/shell/extensions/lockscreen-studio/date-font-size` | `24` | `50` |
| `/org/gnome/shell/extensions/ding/icon-size` | `'standard'` | `'small'` |
| `/org/gnome/shell/extensions/ding/start-corner` | `'bottom-right'` | `'top-left'` |
| `/org/gnome/shell/extensions/tiling-assistant/focus-hint-color` | `''` | `'rgb(0,115,229)'` |
| `/org/gnome/shell/extensions/tiling-assistant/tiling-popup-all-workspace` | `false` | `true` |
| `/org/gnome/shell/extensions/dash-to-dock/multi-monitor` | `false` | `true` |
| `/org/gnome/shell/extensions/dash-to-dock/dock-position` | `'LEFT'` | `'BOTTOM'` |
| `/org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size` | `48` | `36` |

## Dane pominięte świadomie

- Historia schowka, ostatnio instalowane aplikacje, liczniki wersji i powiadomień, lista ostatnich klawiatur i zapamiętany rozmiar okna Extension Manager nie opisują docelowych preferencji.
- Tiling Assistant sam nadpisuje `edge-tiling` i skróty kafelkowania GNOME. Nie odtwarzamy jego wewnętrznego `overridden-settings` ani kopii poprzednich ustawień.
- Nie przenosimy kont, haseł, sieci Wi-Fi/VPN, certyfikatów ani profili firmowych. Bieżąca głośność, jasność i urządzenia audio to stan sprzętu/sesji, a nie zapisana konfiguracja porównywana tutaj.
- Ustawienia panelu zapisano pod indeksami monitorów 0/1/2; bieżący układ elementów jest taki sam na wszystkich monitorach. Plik monitorów zachowuje dokładne fizyczne profile połączeń.
- Dla 11 zapisów GNOME wartość użytkownika była równa domyślnej; nie przenoszono ich jako zmian. Wersje rozszerzeń i nadpisania dostawcy mogą zmienić wartości domyślne w przyszłości.

## Źródła metody

[GSettings: domyślna wartość](https://docs.gtk.org/gio/method.Settings.get_default_value.html), [wartość użytkownika](https://docs.gtk.org/gio/method.Settings.get_user_value.html), [GNOME dconf](https://help.gnome.org/system-admin-guide/dconf.html).
