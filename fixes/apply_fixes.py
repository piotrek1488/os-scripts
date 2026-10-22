#!/usr/bin/env python3
"""Apply minimal guarded changes to scripts checked out from the macos branch."""
from pathlib import Path


def edit(path, old, new):
    p = Path(path)
    contents = p.read_text()
    count = contents.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one occurrence, found {count}: {old!r}')
    p.write_text(contents.replace(old, new, 1))
    print(f'Updated {path}')


edit('new_python_proj_setup.sh', 'if [ -z "$1" ]; then', 'if [ "$#" -ne 1 ] || [ -z "$1" ]; then')
edit('new_python_proj_setup.sh', 'PROJECT_NAME=$1', '''PROJECT_NAME=$1
# Keep generated Python string literals and project paths predictable.
if [[ ! "$PROJECT_NAME" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
  echo "Invalid project name. Use letters, digits, _ or - (starting with a letter)." >&2
  exit 1
fi''')
edit('new_python_proj_setup.sh', 'mkdir "$PROJECT_NAME"\ncd "$PROJECT_NAME"', 'mkdir -- "$PROJECT_NAME"\ncd -- "$PROJECT_NAME"')
edit('new_python_proj_setup.sh', 'Creating src/main.py...', 'Creating src/main_module.py...')
edit('new_python_proj_setup.sh', '> src/main.py', '> src/main_module.py')
edit('new_python_proj_setup.sh', 'Creating src/\\$file...', 'Creating src/$file...')
edit('new_python_proj_setup.sh', '> src/\\$file', '> src/$file')
edit('new_python_proj_setup.sh', '# \\$file: Add your implementation details here.', '# $file: Add your implementation details here.')

# Remove one duplicate in each list, leaving the first instance and its comment intact.
p = Path('new_mac_setup.sh')
s = p.read_text()
needle = '    "keyclu"\n'
assert s.count(needle) == 2, 'Unexpected keyclu list contents'
s = s.replace(needle, '', 1)
needle = '    "545519333"   # Amazon Prime Video\n'
assert s.count(needle) == 1, 'Unexpected Prime Video list contents'
s = s.replace(needle, '')
# A local logging variable avoids leaking state across installation functions.
s = s.replace('    formatted_date=$(date ', '    local formatted_date\n    formatted_date=$(date ', 1)
# Avoid treating a failed install as success due to testing $? after assignments.
s = s.replace('''    install_brew
    new_install="true"
    if [[ $? -ne 0 ]]; then''', '''    if ! install_brew; then''', 1)
s = s.replace('''        exit 1
    fi
    setup_path
    if [[ $? -ne 0 ]]; then''', '''        exit 1
    fi
    new_install="true"
    if ! setup_path; then''', 1)
# Prefer in-repository files rather than a different repository's main branch.
s = s.replace('https://raw.githubusercontent.com/piotrek1488/macos-scripts/refs/heads/main/zsh_config_files/', 'https://raw.githubusercontent.com/piotrek1488/os-scripts/refs/heads/macos/zsh_config_files/')
s = s.replace('.zshrc.userand .zsh_aliases', '.zshrc.user and .zsh_aliases')
p.write_text(s)
print('Updated new_mac_setup.sh')

p = Path('zsh_config_files/.zshrc')
s = p.read_text()
s = s.replace('source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh', '''if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi''')
s = s.replace('eval $(thefuck --alias)', '''if (( $+commands[thefuck] )); then
  eval "$(thefuck --alias)"
fi''')
s = s.replace('PROMPT=\'%F{green}%n@mac%f:%F{blue}%~%f%F{yellow}$(__git_ps1 " %s")%f$ \'', '''if (( $+functions[__git_ps1] )) || (( $+commands[__git_ps1] )); then
  PROMPT='%F{green}%n@mac%f:%F{blue}%~%f%F{yellow}$(__git_ps1 " %s")%f$ '
else
  PROMPT='%F{green}%n@mac%f:%F{blue}%~%f$ '
fi''')
p.write_text(s)
print('Updated zsh_config_files/.zshrc')
