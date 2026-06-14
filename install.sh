#!/bin/bash

set -e  # exit on error

# ─────────────────────────────────────────
# 🎨 Colors
# ─────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
error()   { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ─────────────────────────────────────────
# 🔍 Detect Distro
# ─────────────────────────────────────────
if command -v pacman &>/dev/null; then
  DISTRO="arch"
  info "Detected: Arch / EndeavourOS"
elif command -v apt &>/dev/null; then
  DISTRO="ubuntu"
  info "Detected: Ubuntu / Debian"
else
  error "Unsupported distro. Only Arch and Ubuntu/Debian are supported."
fi

# ─────────────────────────────────────────
# 📁 Setup ~/.local/bin
# ─────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# ─────────────────────────────────────────
# 📦 Package Installation
# ─────────────────────────────────────────
install_packages_arch() {
  info "Installing core packages via pacman..."
  sudo pacman -S --needed --noconfirm \
    zsh git curl unzip base-devel \
    bat eza zoxide fzf \
    starship zellij yazi \
    nodejs npm pnpm thefuck

  # yay (AUR helper)
  if ! command -v yay &>/dev/null; then
    info "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd ~
    rm -rf /tmp/yay
  fi

  # Atuin (AUR)
  if ! command -v atuin &>/dev/null; then
    info "Installing Atuin via yay..."
    yay -S --noconfirm atuin
  fi
}

install_packages_ubuntu() {
  info "Updating apt..."
  sudo apt update -y

  info "Installing core packages via apt..."
  sudo apt install -y \
    zsh git curl unzip build-essential \
    bat zoxide fzf thefuck

  # eza (needs custom repo)
  if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update && sudo apt install -y eza
  fi

  # bat is batcat on Ubuntu — symlink it
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    info "Symlinking batcat → bat..."
    ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  fi

  # Starship
  if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # Zellij (prebuilt binary)
  if ! command -v zellij &>/dev/null; then
    info "Installing Zellij (prebuilt)..."
    curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
      | tar -xz -C "$HOME/.local/bin"
    chmod +x "$HOME/.local/bin/zellij"
  fi

  # Yazi (prebuilt binary)
  if ! command -v yazi &>/dev/null; then
    info "Installing Yazi (prebuilt)..."
    YAZI_TMP=$(mktemp -d)
    curl -L https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip \
      -o "$YAZI_TMP/yazi.zip"
    unzip -q "$YAZI_TMP/yazi.zip" -d "$YAZI_TMP"
    cp "$YAZI_TMP"/yazi-*/yazi "$HOME/.local/bin/yazi"
    chmod +x "$HOME/.local/bin/yazi"
    rm -rf "$YAZI_TMP"
  fi

  # Atuin
  if ! command -v atuin &>/dev/null; then
    info "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  fi

  # pnpm
  if ! command -v pnpm &>/dev/null; then
    info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi
}

# ─────────────────────────────────────────
# 🔧 Common Tools (both distros)
# ─────────────────────────────────────────
install_common() {
  # Oh My Zsh
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    warn "Oh My Zsh already installed, skipping."
  fi

  # zsh-snap (Znap)
  if [ ! -d "$HOME/Git/zsh-snap" ]; then
    info "Installing Znap (zsh plugin manager)..."
    mkdir -p "$HOME/Git"
    git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git "$HOME/Git/zsh-snap"
  else
    warn "Znap already installed, skipping."
  fi

  # NVM
  if [ ! -d "$HOME/.nvm" ]; then
    info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  else
    warn "NVM already installed, skipping."
  fi

  # Bun
  if ! command -v bun &>/dev/null; then
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
  else
    warn "Bun already installed, skipping."
  fi
}

# ─────────────────────────────────────────
# 🔗 Dotfiles
# ─────────────────────────────────────────
link_dotfiles() {
  DOTFILES_DIR="$HOME/dotfiles"

  if [ ! -d "$DOTFILES_DIR" ]; then
    warn "No dotfiles directory found at $DOTFILES_DIR"
    warn "Clone your dotfiles repo first:"
    warn "  git clone https://github.com/yourname/dotfiles.git ~/dotfiles"
    return
  fi

  info "Linking dotfiles..."
  [ -f "$DOTFILES_DIR/.zshrc" ]     && ln -sf "$DOTFILES_DIR/.zshrc"     "$HOME/.zshrc"
  [ -f "$DOTFILES_DIR/.bashrc" ]    && ln -sf "$DOTFILES_DIR/.bashrc"    "$HOME/.bashrc"
  [ -f "$DOTFILES_DIR/.gitconfig" ] && ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  success "Dotfiles linked!"
}

# ─────────────────────────────────────────
# 🐚 Set Zsh as Default Shell
# ─────────────────────────────────────────
set_default_shell() {
  if [ "$(basename "$SHELL")" != "zsh" ]; then
    info "Setting Zsh as default shell..."
    chsh -s /bin/zsh
  else
    warn "Zsh is already the default shell."
  fi
}

# ─────────────────────────────────────────
# 🚀 Run
# ─────────────────────────────────────────
if [ "$DISTRO" = "arch" ]; then
  install_packages_arch
else
  install_packages_ubuntu
fi

install_common
link_dotfiles
set_default_shell

success "All done! Restart your terminal or run: source ~/.zshrc"
