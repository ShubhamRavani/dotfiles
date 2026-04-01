unset KITTY_SHELL_INTEGRATION

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="alanpeabody"

COMPLETION_WAITING_DOTS="true"

BASE16_SHELL_PATH="$HOME/.config/base16-shell"
[ -n "$PS1" ] && \
  [ -s "$BASE16_SHELL_PATH/profile_helper.sh" ] && \
    source "$BASE16_SHELL_PATH/profile_helper.sh"

plugins=(git aliases colorize command-not-found copypath emoji emoji-clock)

source $ZSH/oh-my-zsh.sh

# Download Znap, if it's not there yet.
[[ -f ~/Git/zsh-snap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/Git/zsh-snap

source ~/Git/zsh-snap/znap.zsh  # Start Znap

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# `znap source` automatically downloads and starts your plugins.
znap source zsh-users/zsh-syntax-highlighting
znap source zsh-users/zsh-autosuggestions
znap source marlonrichert/zsh-autocomplete

# Aliases
alias apt-up="sudo apt-get update && stuod apt-get upgrade"
alias rm-db="sudo rm -rf db-data"
alias mv-db="mv ./unnati-db/db-data ."
alias dev="npm run dev"
alias start="npm run start:dev"
alias up="sudo docker compose up"
alias cat=bat
alias zshconfig="vi ~/.zshrc"
alias ls="eza --color=always --long --git --icons=always --no-time --no-user"
alias ssh="kitty +kitten ssh"
alias src="source ~/.zshrc"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# 🌸 Initialize prompt
eval "$(starship init zsh)"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

JAVA_HOME="/usr/java/jre1.8.0_371"

# pnpm
export PNPM_HOME="/home/shubham/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# sst
export PATH=/home/shubham/.sst/bin:$PATH

# fly.io
export FLYCTL_INSTALL="/home/shubham/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

# atuin
. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
eval "$(atuin init zsh)"

export PATH="$HOME/.cargo/bin:$PATH"
export PATH=$PATH:~/.local/bin

# bun completions
[ -s "/home/shubham/.bun/_bun" ] && source "/home/shubham/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Bat theme
export BAT_THEME="Solarized (dark)"
export PATH=$PATH:$HOME/bin

# The F*ck
eval $(thefuck --alias)

# 📂 Yazi
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# zellij setup
eval "$(zellij setup --generate-auto-start zsh)"

# zoxide
eval "$(zoxide init zsh)"
export PATH=$PATH:/usr/local/go/bin
