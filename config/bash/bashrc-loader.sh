# BEGIN os-scripts bash
# shellcheck shell=bash
if [[ $- == *i* && ${OS_SCRIPTS_BASH_LOADED:-} != 1 && -r $HOME/.bashrc.user ]]; then
    source "$HOME/.bashrc.user"
fi
# END os-scripts bash
