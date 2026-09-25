#!/usr/bin/env bash
# Funkcje używane przez skrypty Bash; JSON przetwarza jq, INI/Firefox — awk.
SETTINGS_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

die() { printf 'BŁĄD: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "Brak $1. Zainstaluj wymagane narzędzie."; }
show_command() { printf '%q ' "$@"; printf '\n'; }

merge_jsonc() {
    local input=$1 patch=$2
    jq -eRs --argjson patch "$patch" -f "$SETTINGS_LIB_DIR/merge-jsonc.jq" "$input"
}

# Ta funkcja jest przeznaczona dla prostych, jednoliniowych ustawień GTK.
merge_ini() {
    local input=$1 patch=$2 output=$3 section key value row
    cp -- "$input" "$output"
    while IFS= read -r row; do
        section=$(jq -r '.[0]' <<< "$row")
        key=$(jq -r '.[1]' <<< "$row")
        value=$(jq -r '.[2]' <<< "$row")
        [[ $section != *$'\n'* && $key != *$'\n'* && $value != *$'\n'* ]] || die 'Wieloliniowy wpis INI.'
        awk -v wanted="$section" -v key="$key" -v value="$value" '
            function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
            /^[ \t]*\[/ {
                if (section == wanted && !done) { print key "=" value; done=1 }
                section=trim($0); sub(/^\[/, "", section); sub(/\]$/, "", section)
                if (section == wanted) found=1
            }
            {
                line=trim($0); at=index(line, "=")
                if (section == wanted && at && trim(substr(line,1,at-1)) == key) {
                    if (!done) print key "=" value
                    done=1; next
                }
                print
            }
            END {
                if (!found) print "\n[" wanted "]"
                if (!done) print key "=" value
            }
        ' "$output" > "$output.next"
        mv -- "$output.next" "$output"
    done < <(jq -c 'to_entries[] | .key as $section | .value | to_entries[] | [$section,.key,.value]' <<< "$patch")
}

firefox_profile() {
    local base=$1 profile
    [[ -f $base/profiles.ini ]] || return 0
    profile=$(awk '
        function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
        /^[ \t]*\[/ { section=trim($0); sub(/^\[/,"",section); sub(/\]$/,"",section)
            if (section ~ /^Profile/) order[++count]=section; next }
        /^[ \t]*[;#]/ { next }
        /=/ { p=index($0,"="); key=trim(substr($0,1,p-1)); val=trim(substr($0,p+1))
            values[section,key]=val
            if (section ~ /^Install/ && key == "Default" && install == "") install=val }
        END {
            if (install != "") { print install; exit }
            for (i=1;i<=count;i++) if (values[order[i],"Default"] == "1") {
                selected=order[i]; break
            }
            if (selected == "" && count == 1) selected=order[1]
            if (selected != "") print values[selected,"Path"]
        }
    ' "$base/profiles.ini") || return
    [[ -n $profile ]] || return 0
    if [[ $profile == /* ]]; then printf '%s\n' "$profile"; else printf '%s/%s\n' "$base" "$profile"; fi
}

render_firefox() {
    local input=$1 patch=$2 output=$3
    # Nie usuwaj pozostałych preferencji; niepoprawny blok zatrzymuje zapis.
    awk '
        $0 == "// BEGIN os-scripts preferences" { if (block) exit 2; block=1; next }
        $0 == "// END os-scripts preferences" { if (!block) exit 2; block=0; next }
        !block { print }
        END { if (block) exit 2 }
    ' "$input" > "$output" || die 'Niepoprawny zarządzany blok Firefox user.js.'
    {
        printf '// BEGIN os-scripts preferences\n'
        jq -r 'to_entries[] | "user_pref(\(.key|tojson), \(.value|tojson));"' <<< "$patch"
        printf '// END os-scripts preferences\n'
    } >> "$output"
}

# Rozwiązuj także dowiązania snap/current, lecz nie zapisuj poza katalogiem użytkownika.
inside_home() {
    local path base=${settings_home:?Brak katalogu docelowego}
    path=$(realpath -m -- "$1") || return
    [[ $path == "$base/"* ]] || die "Cel poza katalogiem użytkownika: $1"
    printf '%s\n' "$path"
}

gvariant_string() {
    local value=$1
    value=${value//\\/\\\\}; value=${value//\'/\\\'}
    printf "'%s'" "$value"
}

merge_shortcut_paths() {
    local current=$1 new=$2 part result='' found=false
    current=${current#@as }; current=${current//[$' \t\r\n']/}
    [[ -n $current ]] || current='[]'
    [[ $current == \[*\] ]] || die 'Niepoprawna lista custom-keybindings.'
    current=${current:1:${#current}-2}
    local -a parts=()
    IFS=, read -r -a parts <<< "$current"
    for part in "${parts[@]}"; do
        [[ $part =~ ^\'/[a-zA-Z0-9_/-]+/\'$ ]] || die 'Niepoprawna ścieżka custom-keybindings.'
        [[ $part != "'$new'" ]] || found=true
        result+="${result:+, }$part"
    done
    if ! $found; then result+="${result:+, }'$new'"; fi
    printf '[%s]\n' "$result"
}

# UUID rozszerzeń mają ograniczony alfabet; parser nie wykonuje tekstu GVariant.
merge_extension_states() {
    local current=$1 desired=$2 key=$3 part json='[]'
    current=${current#@as }; current=${current//[$' \t\r\n']/}
    [[ $current == \[*\] ]] || die 'Niepoprawna lista rozszerzeń.'
    current=${current:1:${#current}-2}
    local -a parts=()
    IFS=, read -r -a parts <<< "$current"
    for part in "${parts[@]}"; do
        [[ $part =~ ^\'[a-zA-Z0-9@._+-]+\'$ ]] || die 'Niepoprawny UUID na liście rozszerzeń.'
        part=${part:1:${#part}-2}
        json=$(jq --arg uuid "$part" '. + [$uuid]' <<< "$json")
    done
    [[ $key == enabled-extensions || $key == disabled-extensions ]] || die 'Niepoprawny klucz rozszerzeń.'
    jq -r --argjson desired "$desired" --arg key "$key" '
        ($desired | map(.uuid)) as $known |
        ([.[] | select(. as $uuid | $known | index($uuid) | not)] +
         [$desired[] | select(.enabled == ($key == "enabled-extensions")) | .uuid]) |
        reduce .[] as $uuid ([]; if index($uuid) == null then . + [$uuid] else . end) | "[" + (map("\u0027" + . + "\u0027") | join(", ")) + "]"
    ' <<< "$json"
}
