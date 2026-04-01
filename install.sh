#!/bin/bash
# Install core tools
sudo apt install zsh bat eza zoxide fzf -y

# Oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Starship
curl -sS https://starship.rs/install.sh | sh

# Atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Zellij
cargo install zellij

# Yazi
cargo install yazi-fm

# Kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# Bun
curl -fsSL https://bun.sh/install | bash

# pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -

echo "✅ Done! Run: source ~/.zshrc"
