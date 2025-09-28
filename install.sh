#!/bin/bash

# Welcome message
echo "===================================================="
echo "  Setting up your development environment"
echo "  This script will install all dependencies and set up symlinks"
echo "===================================================="

# Define variables
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

# Create necessary directories
mkdir -p "$CONFIG_DIR"

# Detect OS
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
  echo "Detected macOS system"
elif grep -q 'Ubuntu\|Debian' /etc/os-release 2>/dev/null; then
  OS_TYPE="ubuntu"
  echo "Detected Ubuntu/Debian system"
else
  echo "Error: This script only supports macOS and Ubuntu/Debian systems."
  exit 1
fi

# Clone dotfiles repository if not already present
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Cloning dotfiles repository..."
  git clone https://github.com/ghvinerias/.dotfiles.git "$DOTFILES_DIR"
else
  echo "Dotfiles repository already exists. Pulling latest changes..."
  cd "$DOTFILES_DIR" && git pull
fi

# Function to create symlinks
create_symlink() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ]; then
    if [ ! -L "$dest" ]; then
      echo "Backing up existing file: $dest -> $dest.backup"
      mv "$dest" "$dest.backup"
    else
      echo "Removing existing symlink: $dest"
      rm "$dest"
    fi
  fi

  echo "Creating symlink: $src -> $dest"
  ln -sf "$src" "$dest"
}

#===========================================
# macOS specific setup
#===========================================
if [ "$OS_TYPE" == "macos" ]; then
  # Install Homebrew if not already installed
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if [[ $(uname -m) == "arm64" ]]; then
      # For Apple Silicon
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      # For Intel
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >>"$HOME/.zprofile"
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo "Homebrew is already installed. Updating..."
    brew update
  fi

  # Install Homebrew packages from Brewfile
  echo "Installing packages from Brewfile..."
  brew bundle --file="$DOTFILES_DIR/Brewfile"

  # Install Neovim plugin dependencies
  brew install ripgrep fd
  
  # macOS specific symlinks
  create_symlink "$DOTFILES_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
  create_symlink "$DOTFILES_DIR/sketchybar" "$CONFIG_DIR/sketchybar"
  create_symlink "$DOTFILES_DIR/ghostty" "$CONFIG_DIR/ghostty"
  
  # Make scripts executable
  find "$DOTFILES_DIR/sketchybar/plugins" -type f -exec chmod +x {} \;
fi

#===========================================
# Ubuntu/Debian specific setup
#===========================================
if [ "$OS_TYPE" == "ubuntu" ]; then
  # Update package lists
  echo "Updating package lists..."
  sudo apt-get update

  # Install essential packages
  echo "Installing essential packages..."
  sudo apt-get install -y \
    curl \
    git \
    tmux \
    zsh \
    ripgrep \
    fd-find \
    python3 \
    python3-pip \
    unzip \
    wget

  # Install Neovim from source (to get the latest version)
  echo "Installing Neovim..."
  if ! command -v nvim &>/dev/null; then
    sudo apt-get install -y ninja-build gettext cmake unzip curl
    git clone https://github.com/neovim/neovim
    cd neovim && git checkout stable && make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd .. && rm -rf neovim
  fi

  # Create symlink for fd-find (different name in Ubuntu)
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf $(which fdfind) /usr/local/bin/fd
  fi
fi

#===========================================
# Common setup for both OS types
#===========================================

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh is already installed."
fi

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  echo "tmux plugin manager is already installed."
fi

# Create symlinks for dotfiles
echo "Creating symlinks..."

# Core config files
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/catppuccin_mocha-zsh-syntax-highlighting.zsh" "$HOME/.catppuccin_mocha-zsh-syntax-highlighting.zsh"
create_symlink "$DOTFILES_DIR/.gitignore" "$HOME/.gitignore"

# Config directories
create_symlink "$DOTFILES_DIR/nvim" "$CONFIG_DIR/nvim"
create_symlink "$DOTFILES_DIR/yazi" "$CONFIG_DIR/yazi"

# Git config
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# GitHub CLI config
create_symlink "$DOTFILES_DIR/gh" "$CONFIG_DIR/gh"

# SSH config
mkdir -p "$HOME/.ssh"
create_symlink "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# Create bin directory for scripts
mkdir -p "$HOME/.local/bin"
chmod +x "$DOTFILES_DIR/bash_scripts/compress_video.sh"
create_symlink "$DOTFILES_DIR/bash_scripts/compress_video.sh" "$HOME/.local/bin/compress_video"
chmod +x "$DOTFILES_DIR/bash_scripts/tmux-auto-launch.sh"
create_symlink "$DOTFILES_DIR/bash_scripts/tmux-auto-launch.sh" "$HOME/.local/bin/tmux-auto-launch"

# Add local bin to PATH if not already there
if ! grep -q "$HOME/.local/bin" "$HOME/.zshrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.zshrc"
fi

# Setup LazyVim (Neovim config)
echo "Setting up Neovim..."

# Make sure Neovim plugins are installed
if command -v nvim &>/dev/null; then
  echo "Installing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa
else
  echo "Warning: Neovim not found in PATH. Plugins will be installed on first launch."
fi

# Install starship prompt if not already done
if ! command -v starship &>/dev/null; then
  echo "Installing starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install and setup Zoxide
if ! command -v zoxide &>/dev/null; then
  echo "Installing zoxide..."
  if [ "$OS_TYPE" == "macos" ]; then
    brew install zoxide
  else
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  fi
fi

# Setup Zoxide
if command -v zoxide &>/dev/null; then
  echo "Setting up zoxide..."
  zoxide init zsh >/dev/null
fi

# Install tmux plugins
echo "Installing tmux plugins..."
$HOME/.tmux/plugins/tpm/bin/install_plugins

# Set Zsh as default shell if it's not already
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  chsh -s $(which zsh)
fi

# Handle shell restart
echo ""
echo "===================================================="
echo "  Setup complete!"
echo "  Please restart your terminal or run 'source ~/.zshrc'"
echo "===================================================="
echo ""
echo "You may want to run the following to finish setup:"
echo "  - tmux source ~/.tmux.conf (to reload tmux config)"

# OS-specific final instructions
if [ "$OS_TYPE" == "macos" ]; then
  echo "  - If AeroSpace is not running, start it from Applications folder"
fi

echo "===================================================="
