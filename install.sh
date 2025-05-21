#!/bin/bash

# Welcome message
echo "===================================================="
echo "  Setting up your macOS environment"
echo "  This script will install all dependencies and set up symlinks"
echo "===================================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Error: This script is intended for macOS only."
  exit 1
fi

# Define variables
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

# Create necessary directories
mkdir -p "$CONFIG_DIR"

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

# Clone dotfiles repository if not already present
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Cloning dotfiles repository..."
  git clone https://github.com/ghvinerias/.dotfiles.git "$DOTFILES_DIR"
else
  echo "Dotfiles repository already exists. Pulling latest changes..."
  cd "$DOTFILES_DIR" && git pull
fi

# Install Homebrew packages from Brewfile
echo "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

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

# Create symlinks for dotfiles
echo "Creating symlinks..."

# Core config files
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
create_symlink "$DOTFILES_DIR/catppuccin_mocha-zsh-syntax-highlighting.zsh" "$HOME/.catppuccin_mocha-zsh-syntax-highlighting.zsh"
create_symlink "$DOTFILES_DIR/.gitignore" "$HOME/.gitignore"

# Config directories
create_symlink "$DOTFILES_DIR/nvim" "$CONFIG_DIR/nvim"
create_symlink "$DOTFILES_DIR/yazi" "$CONFIG_DIR/yazi"
create_symlink "$DOTFILES_DIR/sketchybar" "$CONFIG_DIR/sketchybar"
create_symlink "$DOTFILES_DIR/ghostty" "$CONFIG_DIR/ghostty"

# Git config
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# GitHub CLI config
create_symlink "$DOTFILES_DIR/gh" "$CONFIG_DIR/gh"

# Create bin directory for scripts
mkdir -p "$HOME/.local/bin"
chmod +x "$DOTFILES_DIR/bash_scripts/compress_video.sh"
create_symlink "$DOTFILES_DIR/bash_scripts/compress_video.sh" "$HOME/.local/bin/compress_video"

# Add local bin to PATH if not already there
if ! grep -q "$HOME/.local/bin" "$HOME/.zshrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.zshrc"
fi

# Setup LazyVim (Neovim config)
echo "Setting up Neovim..."

# Install Neovim plugin dependencies
brew install ripgrep fd

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

# Setup Zoxide
if command -v zoxide &>/dev/null; then
  echo "Setting up zoxide..."
  zoxide init zsh >/dev/null
fi

# Install tmux plugins
echo "Installing tmux plugins..."
$HOME/.tmux/plugins/tpm/bin/install_plugins

# Make scripts executable
find "$DOTFILES_DIR/sketchybar/plugins" -type f -exec chmod +x {} \;
brew services start sketchybar
source~/.zshrc
# Handle shell restart
echo ""
echo "===================================================="
echo "  Setup complete!"
echo "  Please restart your terminal or run 'source ~/.zshrc'"
echo "===================================================="
echo ""
echo "You may want to run the following to finish setup:"
echo "  - tmux source ~/.tmux.conf (to reload tmux config)"
echo "  - If AeroSpace is not running, start it from Applications folder"
echo "===================================================="
