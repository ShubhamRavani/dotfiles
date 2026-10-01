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

# Dotfiles live wherever this script lives
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────
# 🔍 Detect Distro
# ─────────────────────────────────────────
if command -v pacman &>/dev/null; then
  DISTRO="arch"
  info "Detected: Arch / EndeavourOS"
elif command -v apt-get &>/dev/null; then
  DISTRO="ubuntu"
  info "Detected: Ubuntu / Debian"
else
  error "Unsupported distro. Only Arch and Ubuntu/Debian are supported."
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|aarch64) ;;
  *) error "Unsupported CPU architecture: $ARCH" ;;
esac

# ─────────────────────────────────────────
# 📁 Setup ~/.local/bin
# ─────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# install_nerd_font <release zip name> <font family name>
install_nerd_font() {
  if fc-list | grep -qi "$2"; then
    return
  fi
  info "Installing $2..."
  local font_dir="$HOME/.local/share/fonts/$1" font_tmp
  font_tmp=$(mktemp -d)
  mkdir -p "$font_dir"
  curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$1.zip" \
    -o "$font_tmp/$1.zip"
  unzip -qo "$font_tmp/$1.zip" -d "$font_dir"
  rm -rf "$font_tmp"
  fc-cache -f "$font_dir"
}

# ─────────────────────────────────────────
# 📦 Package Installation
# ─────────────────────────────────────────
install_packages_arch() {
  info "Installing core packages via pacman..."
  sudo pacman -S --needed --noconfirm \
    zsh git curl wget unzip base-devel \
    bat eza zoxide fzf \
    starship zellij yazi atuin \
    ttf-firamono-nerd ttf-cascadia-code-nerd \
    nodejs npm pnpm thefuck

  # yay (AUR helper)
  if ! command -v yay &>/dev/null; then
    info "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
  fi
}

install_packages_ubuntu() {
  info "Updating apt..."
  sudo apt-get update -y

  info "Installing core packages via apt..."
  sudo apt-get install -y \
    zsh git curl wget gpg ca-certificates unzip fontconfig build-essential \
    bat fzf

  # thefuck is broken on Python 3.12+ (Ubuntu 24.04+), so don't let it abort the run
  sudo apt-get install -y thefuck || warn "thefuck failed to install, skipping."

  # eza (needs custom repo)
  if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update && sudo apt-get install -y eza
  fi

  # bat is batcat on Ubuntu — symlink it
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    info "Symlinking batcat → bat..."
    ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  fi

  # zoxide (apt version on 22.04 is very old)
  if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi

  # Starship (into ~/.local/bin so it doesn't need sudo)
  if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
  fi

  # Zellij (prebuilt, static musl binary)
  if ! command -v zellij &>/dev/null; then
    info "Installing Zellij (prebuilt)..."
    curl -fL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ARCH}-unknown-linux-musl.tar.gz" \
      | tar -xz -C "$HOME/.local/bin"
    chmod +x "$HOME/.local/bin/zellij"
  fi

  # Yazi (prebuilt, static musl binary — the gnu build can need a newer glibc than 22.04 has)
  if ! command -v yazi &>/dev/null; then
    info "Installing Yazi (prebuilt)..."
    YAZI_TMP=$(mktemp -d)
    curl -fL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${ARCH}-unknown-linux-musl.zip" \
      -o "$YAZI_TMP/yazi.zip"
    unzip -q "$YAZI_TMP/yazi.zip" -d "$YAZI_TMP"
    cp "$YAZI_TMP"/yazi-*/yazi "$YAZI_TMP"/yazi-*/ya "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya"
    rm -rf "$YAZI_TMP"
  fi

  # Atuin (installs to ~/.atuin/bin)
  if ! command -v atuin &>/dev/null && [ ! -x "$HOME/.atuin/bin/atuin" ]; then
    info "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  fi

  # pnpm
  if ! command -v pnpm &>/dev/null && [ ! -d "$HOME/.local/share/pnpm" ]; then
    info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi

  # Nerd Fonts used by the terminal configs (kitty: FiraMono, ghostty: CaskaydiaCove)
  install_nerd_font FiraMono "FiraMono Nerd Font"
  install_nerd_font CascadiaCode "CaskaydiaCove Nerd Font"
}

# ─────────────────────────────────────────
# 🔧 Common Tools (both distros)
# ─────────────────────────────────────────
install_common() {
  # Oh My Zsh
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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

  # NVM (PROFILE=/dev/null: our .zshrc/.bashrc already load it)
  if [ ! -d "$HOME/.nvm" ]; then
    info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
  else
    warn "NVM already installed, skipping."
  fi

  # Bun
  if ! command -v bun &>/dev/null && [ ! -x "$HOME/.bun/bin/bun" ]; then
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
  else
    warn "Bun already installed, skipping."
  fi
}

# ─────────────────────────────────────────
# 🔗 Dotfiles
# ─────────────────────────────────────────
# link <path relative to repo> — symlinks into $HOME, backing up any real file in the way
link() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$1"
  [ -e "$src" ] || return 0
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
    warn "Backed up existing $dest"
  fi
  ln -sfn "$src" "$dest"
}

link_dotfiles() {
  info "Linking dotfiles from $DOTFILES_DIR..."
  link .zshrc
  link .bashrc
  link .gitconfig
  link .config/starship.toml
  link .config/atuin/config.toml
  link .config/zellij/config.kdl
  link .config/kitty/kitty.conf
  link .config/kitty/current-theme.conf
  link .config/ghostty/config.ghostty
  success "Dotfiles linked!"
}

# ─────────────────────────────────────────
# 🐚 Set Zsh as Default Shell
# ─────────────────────────────────────────
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]; then
    info "Setting Zsh as default shell..."
    chsh -s "$zsh_path"
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

success "All done! Log out and back in (for the shell change), or run: exec zsh"
