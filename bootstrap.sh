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
  brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile" || \
    warn "Some Homebrew packages failed to install — continuing"
}

install_packages_debian() {
  info "Updating apt..."
  sudo apt update -qq

  local pkgs=(
    zsh tmux git git-lfs neovim stow
    fzf bat ripgrep tree curl wget unzip
    python3 python3-pip ruby
    task cargo
  )
  info "Installing packages..."
  for pkg in "${pkgs[@]}"; do
    sudo apt install -y "$pkg" || warn "apt: failed to install $pkg — skipping"
  done

  install_cargo_packages
}

install_packages_fedora() {
  local pkgs=(
    zsh tmux git git-lfs neovim stow
    fzf bat ripgrep tree curl wget unzip
    python3 python3-pip ruby
    task cargo lazygit
  )
  info "Installing packages..."
  for pkg in "${pkgs[@]}"; do
    sudo dnf install -y "$pkg" || warn "dnf: failed to install $pkg — skipping"
  done

  install_cargo_packages
}

install_packages_arch() {
  local pkgs=(
    zsh tmux git git-lfs neovim stow
    fzf bat ripgrep tree curl wget unzip
    python python-pip ruby
    task cargo lazygit
  )
  info "Installing packages..."
  for pkg in "${pkgs[@]}"; do
    sudo pacman -Sy --noconfirm "$pkg" || warn "pacman: failed to install $pkg — skipping"
  done

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
      cargo install "$pkg" || warn "cargo: failed to install $pkg — skipping"
    else
      success "$pkg already installed"
    fi
  done

  # lazygit (if not installed via package manager)
  if ! command -v lazygit &>/dev/null; then
    info "Installing lazygit..."
    local LAZYGIT_VERSION
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [[ -n "$LAZYGIT_VERSION" ]]; then
      curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
        && tar xf /tmp/lazygit.tar.gz -C /tmp lazygit \
        && sudo install /tmp/lazygit /usr/local/bin \
        && rm -f /tmp/lazygit /tmp/lazygit.tar.gz \
        || warn "Failed to install lazygit — skipping"
    else
      warn "Could not resolve lazygit version — skipping"
    fi
  fi

  # qo (Go-based, install from binary)
  if ! command -v qo &>/dev/null; then
    info "Installing qo..."
    local QO_VERSION
    QO_VERSION=$(curl -s "https://api.github.com/repos/cube2222/qo/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [[ -n "$QO_VERSION" ]]; then
      curl -Lo /tmp/qo.tar.gz "https://github.com/cube2222/qo/releases/latest/download/qo_${QO_VERSION}_linux_amd64.tar.gz" \
        && tar xf /tmp/qo.tar.gz -C /tmp qo \
        && sudo install /tmp/qo /usr/local/bin \
        && rm -f /tmp/qo /tmp/qo.tar.gz \
        || warn "Failed to install qo — skipping"
    else
      warn "Could not resolve qo version — skipping"
    fi
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

# ── Build steps ───────────────────────────────────────────────────────────────

build_scripts() {
  local aerospace_scripts="$DOTFILES_DIR/aerospace/.config/aerospace/scripts"

  if [[ -f "$aerospace_scripts/almost-maximize.swift" ]]; then
    info "Compiling almost-maximize..."
    swiftc "$aerospace_scripts/almost-maximize.swift" -o "$aerospace_scripts/almost-maximize" \
      && success "almost-maximize compiled" \
      || warn "Failed to compile almost-maximize — skipping"
  fi
}

# ── Alfred workflows ──────────────────────────────────────────────────────────

install_alfred_workflows() {
  [[ "$(detect_os)" != "macos" ]] && return 0

  local alfred_dir="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows"
  local dotfiles_workflows="$DOTFILES_DIR/alfred/workflows"

  if [[ ! -d "$alfred_dir" ]]; then
    warn "Alfred workflows directory not found — is Alfred installed?"
    return 0
  fi

  if [[ ! -d "$dotfiles_workflows" ]]; then
    return 0
  fi

  for workflow in "$dotfiles_workflows"/*/; do
    local name
    name="$(basename "$workflow")"
    local target="$alfred_dir/user.workflow.$name"

    if [[ -L "$target" ]]; then
      success "Alfred workflow '$name' already linked"
    elif [[ -d "$target" ]]; then
      warn "Alfred workflow '$name' exists but is not a symlink — skipping (remove it manually to link from dotfiles)"
    else
      info "Linking Alfred workflow '$name'..."
      ln -sf "$workflow" "$target"
      success "Alfred workflow '$name' linked"
    fi
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

  build_scripts
  install_alfred_workflows
  set_zsh_default

  echo ""
  success "Bootstrap complete!"
  echo ""
  echo "  Next steps:"
  echo "  - Stow packages manually:  cd ~/dotfiles && stow <package>"
  echo "  - Reload your shell:       exec zsh"
  echo "  - Local overrides:         create ~/dotfiles/zsh/local.zsh  (gitignored)"
  echo "  - Machine-specific env:    create ~/.zshrc.local             (gitignored)"
  echo ""
}

main "$@"
