# =========================
# BETTER DEFAULTS
# =========================
export EDITOR=micro

# =========================
# HISTORY (zsh version)
# =========================
HISTSIZE=2000
SAVEHIST=4000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# =========================
# LS COLORS (macOS safe)
# =========================
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# =========================
# GREP COLORS
# =========================
export GREP_OPTIONS='--color=auto' 2>/dev/null


# =========================
# NVM (Node Version Manager)
# =========================
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
fi

# =========================
# HOME BREW COMPLETION
# =========================
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX=$(brew --prefix)
  if [ -f "$BREW_PREFIX/etc/bash_completion" ]; then
    . "$BREW_PREFIX/etc/bash_completion"
  fi
fi

# =========================
# GIT PROMPT (FIXED FOR ZSH)
# =========================
if [ -f /opt/homebrew/etc/bash_completion.d/git-prompt.sh ]; then
  source /opt/homebrew/etc/bash_completion.d/git-prompt.sh
elif [ -f /usr/local/etc/bash_completion.d/git-prompt.sh ]; then
  source /usr/local/etc/bash_completion.d/git-prompt.sh
fi

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto"

# =========================
# PROMPT (ZSH VERSION + GIT)
# =========================
setopt PROMPT_SUBST
PROMPT='%F{green}%n@mac%f:%F{blue}%~%f%F{yellow}$(__git_ps1 " %s")%f$ '

# =========================
# OPTIONAL FILES
# =========================
if [ -f "$HOME/.zshrc.user" ]; then
    source "$HOME/.zshrc.user"
fi

# =========================
# ZSH COMPLETION SYSTEM
# =========================
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  autoload -Uz compinit
  compinit -u
fi
# You may also need to force rebuild `zcompdump`:
#   rm -f ~/.zcompdump; compinit
# Additionally, if you receive "zsh compinit: insecure directories" warnings when attempting
# to load these completions, you may need to run these commands:
#   chmod go-w '/opt/homebrew/share'
#   chmod -R go-w '/opt/homebrew/share/zsh'
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval $(thefuck --alias)
