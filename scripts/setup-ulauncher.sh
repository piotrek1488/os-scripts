#!/usr/bin/env bash
# Brakujące rozszerzenia/motywy oraz bieżące preferencje. Domyślnie podgląd.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/settings.sh"
source "$ROOT/scripts/lib/ulauncher.sh"
DATA="$ROOT/config/ulauncher/snapshot.json"
apply=false
mode=
while (($#)); do
    case $1 in
        --apply|--dry-run)
            [[ -z $mode || $mode == "$1" ]] || die 'Wybierz --apply albo --dry-run.'
            mode=$1; [[ $1 != --apply ]] || apply=true ;;
        -h|--help)
            echo 'Użycie: bash scripts/setup-ulauncher.sh [--dry-run|--apply]'
            echo 'Ulauncher 5/API 2: APT, rozszerzenia, oba motywy libadwaita i preferencje.'
            echo 'Zamknij Ulaunchera przed --apply; istniejące klucze API pozostają w jego bazach.'
            exit 0 ;;
        *) die "Nieznana opcja: $1" ;;
    esac
    shift
done
if $apply && ((EUID == 0)); then die 'Uruchom jako zwykły użytkownik, bez sudo.'; fi
for command in jq realpath python3; do need "$command"; done
jq -e '(.settings|type == "object") and (.extensions|type == "array") and (.themes|type == "array")' "$DATA" >/dev/null
validate_ulauncher_snapshot "$DATA"
settings_home=$(realpath -- "$HOME")
config=$(inside_home "${XDG_CONFIG_HOME:-$settings_home/.config}/ulauncher")
data=$(inside_home "${XDG_DATA_HOME:-$settings_home/.local/share}/ulauncher")
umask 077
work=$(mktemp -d /tmp/os-scripts-ulauncher-XXXXXXXX)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
backup=$(inside_home "$settings_home/.local/state/os-scripts/backups/ulauncher-$(date +%Y%m%d-%H%M%S-%N)")
for private_path in "$config" "$data" "$backup" "$work"; do
    ulauncher_outside_repository "$private_path"
done
run() { show_command "$@"; if $apply; then "$@"; fi; }
save() {
    local path=$1 dest
    [[ -e $path || -L $path ]] || return 0
    dest="$backup/files/${path#"$settings_home/"}"
    mkdir -p -- "$(dirname -- "$dest")"
    cp -a -- "$path" "$dest"
}
install_file() {
    local source=$1 dest=$2 temp
    save "$dest"
    mkdir -p -- "$(dirname -- "$dest")"
    temp=$(mktemp -- "$dest.os-scripts-XXXXXXXX")
    cat -- "$source" > "$temp"
    chmod 600 -- "$temp"
    mv -f -- "$temp" "$dest"
}
if $apply; then
    for command in curl tar sha256sum sudo dpkg-query; do need "$command"; done
    if pgrep -u "$(id -u)" -x 'ulauncher|ulauncher-.+' >/dev/null; then
        die 'Zamknij Ulaunchera przed odtwarzaniem preferencji.'
    fi
    installed=$(dpkg-query -W -f='${Version}' ulauncher 2>/dev/null || true)
    [[ -z $installed || $installed == 5.* ]] || die "Obsługiwany Ulauncher 5; zainstalowano $installed. Format wersji 6 wymaga odrębnej migracji."
fi
# Zweryfikuj dane i przygotuj scalenia przed instalacją APT lub zmianą ustawień.
packages=()
while IFS= read -r package || [[ -n $package ]]; do
    [[ -n $package && $package != \#* ]] || continue
    [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die 'Niepoprawna nazwa zależności APT.'
    packages+=("$package")
done < "$ROOT/packages/ulauncher/apt.txt"
[[ ${#packages[@]} -gt 0 ]] || die 'Pusta lista zależności.'
settings_target=$(inside_home "$config/settings.json")
ulauncher_outside_repository "$settings_target"
old=/dev/null; [[ ! -f $settings_target ]] || old=$settings_target
merge_jsonc "$old" "$(jq -c '.settings' "$DATA")" > "$work/settings.json"
registry_target=$(inside_home "$config/extensions.json")
ulauncher_outside_repository "$registry_target"
if [[ -f $registry_target ]]; then
    jq -e 'if type == "object" then . else error("Niepoprawny rejestr rozszerzeń") end' "$registry_target" > "$work/registry.json"
else printf '{}\n' > "$work/registry.json"; fi
new_sources=() new_targets=() prefs_targets=() prefs_outputs=()
patch_items=() patch_targets=() patch_sources=()
while IFS= read -r item; do
    id=$(jq -r '.id' <<< "$item")
    kind=$(jq -r '.kind' <<< "$item")
    url=$(jq -r '.download_url' <<< "$item")
    checksum=$(jq -r '.sha256' <<< "$item")
    [[ $id =~ ^[a-zA-Z0-9._-]+$ && $checksum =~ ^[a-f0-9]{64}$ ]] || die 'Niepoprawny identyfikator lub suma SHA256.'
    [[ $url =~ ^https://codeload\.github\.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+/tar\.gz/[a-f0-9]{40}$ ]] || die 'Niepoprawny URL wersji dodatku.'
    if [[ $kind == extension ]]; then dest=$(inside_home "$data/extensions/$id")
    else dest=$(inside_home "$config/user-themes/$id"); fi
    if [[ -e $dest ]]; then
        [[ -f $dest/manifest.json ]] || die "Niekompletny istniejący katalog: $dest"
        echo "# Zachowaj zainstalowany kod: $id"
        manifest="$dest/manifest.json"
    else
        echo "# Zainstaluj $kind: $id (wersja $(jq -r '.ref' <<< "$item"))"
        run curl --fail --location --proto '=https' --proto-redir '=https' --retry 2 --output "$work/$id.tar.gz" -- "$url"
        echo "# Sprawdź SHA256: $checksum; rozpakuj do $dest"
        manifest=
        if $apply; then
            printf '%s  %s\n' "$checksum" "$work/$id.tar.gz" | sha256sum -c - >/dev/null
            extract_ulauncher_archive "$work/$id.tar.gz" "$work/$id"
            manifest="$work/$id/manifest.json"
            jq -e 'type == "object" and (.name|type == "string")' "$manifest" >/dev/null
            new_sources+=("$work/$id"); new_targets+=("$dest")
        fi
        if [[ $kind == extension ]]; then
            jq --argjson item "$item" --arg now "$(date -Iseconds)" '.[$item.id] = {
                id:$item.id,url:$item.url,last_commit:$item.ref,
                last_commit_time:$item.last_commit_time,updated_at:$now
            }' "$work/registry.json" > "$work/registry.next"
            mv -- "$work/registry.next" "$work/registry.json"
        fi
    fi
    if [[ $kind == extension ]]; then
        if [[ -n $manifest ]]; then
            api=$(jq -r '.required_api_version // ""' "$manifest")
            [[ $api == 2 || $api == '^2.0.0' ]] || die "Nieobsługiwane API $api w $id"
            jq -e --argjson prefs "$(jq -c '.preferences' <<< "$item")" \
                '([.preferences[].id]) as $keys | all($prefs|keys[]; . as $key | $keys | index($key) != null)' "$manifest" >/dev/null || die "Preferencje nie pasują do zainstalowanego manifestu: $id"
        fi
        if jq -e '.patch' <<< "$item" >/dev/null; then
            echo "# Popraw adresy paneli GNOME 50: $id"
            if [[ -n $manifest ]]; then
                source_file="${manifest%/*}/main.py"
                hash=$(sha256sum -- "$source_file"); hash=${hash%% *}
                expected=$(jq -r '.patch.source_sha256' <<< "$item")
                patched=$(jq -r '.patch.result_sha256' <<< "$item")
                [[ $hash == "$expected" || $hash == "$patched" ]] || die "Nieznana wersja main.py dodatku GNOME Settings; nie można zastosować poprawki."
                if [[ $hash == "$expected" ]]; then
                    patch_items+=("$item")
                    patch_targets+=("$(inside_home "$dest/main.py")")
                    patch_sources+=("$source_file")
                fi
            fi
        fi
        # Istniejący katalog bez wpisu także powinien być widoczny w menedżerze.
        if ! jq -e --arg id "$id" 'has($id)' "$work/registry.json" >/dev/null; then
            jq --argjson item "$item" '.[$item.id] = {id:$item.id,url:$item.url,
                last_commit:"",last_commit_time:"",updated_at:""}' "$work/registry.json" > "$work/registry.next"
            mv -- "$work/registry.next" "$work/registry.json"
        fi
        target=$(inside_home "$config/ext_preferences/$id.db")
        ulauncher_outside_repository "$target"
        output="$work/$id.db"
        jq '.preferences' <<< "$item" > "$work/preferences.json"
        merge_ulauncher_preferences "$target" "$work/preferences.json" "$output"
        prefs_targets+=("$target"); prefs_outputs+=("$output")
        echo "# Scal preferencje: $id; zachowaj istniejące klucze prywatne."
    elif [[ -n $manifest ]]; then
        jq -e --arg name "$id" '.name == $name' "$manifest" >/dev/null || die "Niezgodny identyfikator motywu: $id"
    fi
done < <(jq -c '(.extensions[] + {kind:"extension"}), (.themes[] + {kind:"theme"})' "$DATA")

run sudo apt-get update
# Symulacja i sprawdzenie wersji przed rzeczywistą instalacją — tylko API 2.
if $apply; then
    candidate=$(LC_ALL=C apt-cache policy ulauncher | awk '/Candidate:/ {print $2; exit}')
    [[ $candidate == 5.* ]] || die "Kandydat APT to Ulauncher $candidate, wymagany 5.x."
fi
run sudo apt-get --simulate install -- "${packages[@]}"
run sudo apt-get install -y -- "${packages[@]}"
echo '# Zapis ustawień i obu motywów; aktywny: libadwaita-dark.'
if $apply; then
    # Instalacja pakietu na nowym systemie może uruchomić aplikację.
    if pgrep -u "$(id -u)" -x 'ulauncher|ulauncher-.+' >/dev/null; then die 'Zamknij Ulaunchera uruchomionego po instalacji i powtórz skrypt.'; fi
    for i in "${!new_sources[@]}"; do
        dest=${new_targets[i]}
        [[ ! -e $dest ]] || die "Katalog powstał podczas instalacji: $dest"
        mkdir -p -- "$(dirname -- "$dest")"
        cp -a -- "${new_sources[i]}" "$dest"
    done
    for i in "${!patch_targets[@]}"; do
        # Patch tylko sprawdzonej wersji; kod dodatku nie jest uruchamiany.
        output="$work/patched-$i.py"
        cp -- "${patch_sources[i]}" "$output"
        patch --batch --forward "$output" "$ROOT/config/ulauncher/patches/gnome-settings-50.patch" >/dev/null
        expected=$(jq -r '.patch.result_sha256' <<< "${patch_items[i]}")
        printf '%s  %s\n' "$expected" "$output" | sha256sum -c - >/dev/null
        install_file "$output" "${patch_targets[i]}"
    done
    install_file "$work/settings.json" "$settings_target"
    install_file "$work/registry.json" "$registry_target"
    for i in "${!prefs_targets[@]}"; do install_file "${prefs_outputs[i]}" "${prefs_targets[i]}"; done
    echo "Kopie zapasowe: $backup"
    echo 'Gotowe. Uruchom Ulaunchera ponownie.'
else
    echo 'Podgląd zakończony. Zamknij Ulaunchera i dodaj --apply, aby zainstalować oraz skonfigurować dodatki.'
fi
