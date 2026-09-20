#
# ~/.bashrc
#

# If not running interactively, don't do anything

[[ $- == *i* ]]


PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'disown -a -h'

### Aliases

alias du='du --human-readable --threshold'
alias dotfiles='/usr/bin/git --git-dir=/home/glebespalov/mymaybedotfiles --work-tree=/home/glebespalov'

# Reloads

alias bashreload='source ~/.bashrc'
alias tmuxreload='tmux source-file ~/.tmux.conf'

# Pacman

alias pacin='sudo pacman -S --needed'
alias pacrem='sudo pacman -R '
alias pacupg='sudo pacman -Syu --needed'
alias pacremall='sudo pacman -Rsn'

#configs

alias swayconf='emacs ~/.config/sway/config'
alias ghosttyconf='emacs ~/.config/ghostty/config.ghostty'
alias tmuxconf='emacs ~/.tmux.conf'

#rus to eng
alias сп='cd'

#else
alias pkill='pkill -e'

#emacs 
alias emacs='emacs -nw'
alias fzf='fzf -e'
alias femacs='emacs $(fzf -e)'


# color auto

alias grep='grep --color=auto'
alias lsd='ls --color=auto -d */'
alias ls='ls -rt --color=auto'


#exports

export DISPLAY=:0
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export EDITOR='emacs -nw'
export VISUAL='emacs -nw'
export PATH=$PATH:~/.spicetify
export PATH="$HOME/.local/bin:$PATH"

set -o histexpand

#$

PS1='\[\033[01;34m\] \@ \[\033[033m\]\W \[\033[32m\]\$ \[\033[00m\]'

# pnpm
export PNPM_HOME='/home/glebespalov/.local/share/pnpm'
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.cargo/env"
