#!/usr/bin/env bash
# Ulauncher 5 zapisuje preferencje dodatków jako pickle, nie JSON.
# Python jest używany wyłącznie jako czytnik/zapis danych w natywnym formacie.
merge_ulauncher_preferences() {
    local old=$1 patch=$2 output=$3
    python3 - "$old" "$patch" "$output" <<'PY'
import io, json, pickle, sys
from pathlib import Path
class DataOnly(pickle.Unpickler):
    def find_class(self, module, name):
        raise ValueError('Preferencje muszą być danymi, bez obiektów wykonywalnych')
try:
    old, patch, output = map(Path, sys.argv[1:])
    current = DataOnly(io.BytesIO(old.read_bytes())).load() if old.is_file() else {}
    wanted = json.loads(patch.read_text())
    for data in (current, wanted):
        if not isinstance(data, dict) or not all(isinstance(k, str) and isinstance(v, (str, int, float, bool, type(None))) for k, v in data.items()):
            raise ValueError('Niepoprawny format preferencji')
    current.update(wanted)
    output.write_bytes(pickle.dumps(current, protocol=2))
except Exception:
    # Bez wypisywania wartości z bazy, która może zawierać klucze API.
    sys.exit('BŁĄD: nie można scalić preferencji Ulaunchera; żaden plik docelowy nie został zmieniony.')
PY
}

extract_ulauncher_archive() {
    local archive=$1 dest=$2 entry target
    mkdir -p -- "$dest"
    tar -tzf "$archive" > "$dest.paths"
    while IFS= read -r entry; do
        [[ $entry != /* && /$entry/ != */../* ]] || die 'Niepoprawna ścieżka archiwum Ulaunchera.'
    done < "$dest.paths"
    # Archiwa GitHub mają jeden katalog nadrzędny.
    [[ $(cut -d/ -f1 "$dest.paths" | sort -u | wc -l) == 1 ]] || die 'Archiwum musi mieć jeden katalog nadrzędny.'
    tar -xzf "$archive" -C "$dest" --strip-components=1 --no-same-owner --no-same-permissions
    find "$dest" -type l -print0 | xargs -0 -r realpath -m -- > "$dest.links"
    while IFS= read -r target; do
        [[ $target == "$dest/"* ]] || die 'Dowiązanie w archiwum wskazuje poza rozszerzenie.'
    done < "$dest.links"
}

validate_ulauncher_snapshot() {
    # Same nazwy pól w private_keys są dozwolone; wartości sekretów nie są.
    jq -e '
        def credential: test("^(api[_-]?key|access[_-]?token|refresh[_-]?token|id[_-]?token|token|client[_-]?secret|secret[_-]?key|password|passwd|authorization|cookie|openai_api_key|gemini_api_key|github_token)$"; "i");
        all(.. | objects | to_entries[];
            if (.key | credential) then (.value == null or .value == "") else true end)
        and all(.extensions[]; . as $ext |
            all((.private_keys // [])[]; $ext.preferences[.] == null or $ext.preferences[.] == ""))
    ' "$1" >/dev/null 2>&1 || die 'Snapshot Ulaunchera zawiera niedozwolone wartości prywatne albo ma niepoprawny format. Usuń sekrety z repozytorium.'
}

ulauncher_outside_repository() {
    local path repository
    path=$(realpath -m -- "$1")
    repository=$(realpath -- "$ROOT")
    [[ $path != "$repository" && $path != "$repository/"* ]] || die 'Bazy, kopie i dane robocze Ulaunchera muszą znajdować się poza repozytorium.'
}
