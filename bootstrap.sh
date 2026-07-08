#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="git@github.com:itsjonny96/dotfiles.git"

# ── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }
die()     { echo "[error] $*" >&2; exit 1; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if command -v apt &>/dev/null;      then echo "debian"
      elif command -v dnf &>/dev/null;    then echo "fedora"
      elif command -v pacman &>/dev/null; then echo "arch"
      else die "Unsupported Linux distribution"
      fi ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac
}

# ── Package installation ──────────────────────────────────────────────────────

install_packages_macos() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    success "Homebrew already installed"
  fi

  info "Installing packages from Brewfile..."
  brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile"
}

install_packages_debian() {
  info "Updating apt..."
  sudo apt update -qq

  info "Installing packages..."
  sudo apt install -y \
    zsh tmux git git-lfs neovim stow \
    fzf bat ripgrep tree curl wget unzip \
    python3 python3-pip ruby \
    task cargo

  install_cargo_packages
}

install_packages_fedora() {
  info "Installing packages..."
  sudo dnf install -y \
    zsh tmux git git-lfs neovim stow \
    fzf bat ripgrep tree curl wget unzip \
    python3 python3-pip ruby \
    task cargo lazygit

  install_cargo_packages
}

install_packages_arch() {
  info "Installing packages..."
  sudo pacman -Sy --noconfirm \
    zsh tmux git git-lfs neovim stow \
    fzf bat ripgrep tree curl wget unzip \
    python python-pip ruby \
    task cargo lazygit

  install_cargo_packages
}

install_cargo_packages() {
  if ! command -v cargo &>/dev/null; then
    info "Installing Rust/Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
  fi

  local cargo_pkgs=(csvlens diffnav)
  for pkg in "${cargo_pkgs[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
      info "Installing $pkg via cargo..."
      cargo install "$pkg"
    else
      success "$pkg already installed"
    fi
  done

  # lazygit (if not installed via package manager)
  if ! command -v lazygit &>/dev/null; then
    info "Installing lazygit..."
    local LAZYGIT_VERSION
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm /tmp/lazygit /tmp/lazygit.tar.gz
  fi

  # qo (Go-based, install from binary)
  if ! command -v qo &>/dev/null; then
    info "Installing qo..."
    local QO_VERSION
    QO_VERSION=$(curl -s "https://api.github.com/repos/cube2222/qo/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/qo.tar.gz "https://github.com/cube2222/qo/releases/latest/download/qo_${QO_VERSION}_linux_amd64.tar.gz"
    tar xf /tmp/qo.tar.gz -C /tmp qo
    sudo install /tmp/qo /usr/local/bin
    rm /tmp/qo /tmp/qo.tar.gz
  fi
}

# ── Dotfiles ──────────────────────────────────────────────────────────────────

clone_dotfiles() {
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    info "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    success "Dotfiles already present"
  fi
}

stow_dotfiles() {
  cd "$DOTFILES_DIR"

  local packages=()
  for dir in nvim tmux zsh taskwarrior; do
    [[ -d "$dir" ]] && packages+=("$dir")
  done

  for pkg in "${packages[@]}"; do
    info "Stowing $pkg..."
    stow -v --restow "$pkg"
  done
}

# ── ZSH default shell ─────────────────────────────────────────────────────────

set_zsh_default() {
  if [[ "$SHELL" != */zsh ]]; then
    local zsh_path
    zsh_path="$(command -v zsh)"
    info "Setting zsh as default shell..."
    if ! grep -qF "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    chsh -s "$zsh_path"
  else
    success "zsh already default shell"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  local os
  os="$(detect_os)"
  info "Detected OS: $os"

  clone_dotfiles

  case "$os" in
    macos)  install_packages_macos  ;;
    debian) install_packages_debian ;;
    fedora) install_packages_fedora ;;
    arch)   install_packages_arch   ;;
  esac

  if ! command -v stow &>/dev/null; then
    die "stow not found after package install — check your package list"
  fi

  stow_dotfiles
  set_zsh_default

  echo ""
  success "Bootstrap complete!"
  echo ""
  echo "  Next steps:"
  echo "  - Reload your shell:    exec zsh"
  echo "  - Local overrides:      create ~/dotfiles/zsh/local.zsh  (gitignored)"
  echo "  - Machine-specific env: create ~/.zshrc.local             (gitignored)"
  echo ""
}

main "$@"
