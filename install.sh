#!/usr/bin/env bash
#
# dotfiles installer — symlinks packages into $HOME via GNU Stow.
#
# Usage:
#   ./install.sh              # install all packages
#   ./install.sh zsh ghostty  # install only the named packages
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Packages to install by default (raycast is manual — see README).
DEFAULT_PACKAGES=(zsh ghostty claude git karabiner)

# --- Ensure Homebrew is available ---
if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew not found. Install it first: https://brew.sh" >&2
  exit 1
fi

# --- Install packages from Brewfile (taps, CLI tools, GUI apps) ---
# This also installs stow itself, so it must run before stowing.
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
  echo "Installing packages from Brewfile..."
  brew bundle --file="$DOTFILES_DIR/Brewfile"
fi

# --- Install Oh My Zsh + prompt theme + plugins (idempotent) ---
# .zshrc expects oh-my-zsh, the powerlevel10k theme, and two custom plugins.
# Install whatever is missing so a fresh machine needs no manual steps.
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [ ! -d "$ZSH_DIR" ]; then
  echo "Installing Oh My Zsh..."
  # Unattended: don't run zsh, don't touch ~/.zshrc (we stow ours), don't chsh
  # (macOS already defaults to zsh).
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Clone a git repo into $2 only if it isn't already there.
clone_if_missing() {
  if [ ! -d "$2" ]; then
    echo "  cloning: $(basename "$2")"
    git clone --depth=1 "$1" "$2"
  fi
}

echo "Installing zsh theme & plugins..."
clone_if_missing https://github.com/romkatv/powerlevel10k.git             "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git     "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

# --- Determine packages ---
if [ "$#" -gt 0 ]; then
  PACKAGES=("$@")
else
  PACKAGES=("${DEFAULT_PACKAGES[@]}")
fi

# --- Back up any pre-existing real files that would collide ---
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
echo "Stowing packages: ${PACKAGES[*]}"

for pkg in "${PACKAGES[@]}"; do
  if [ ! -d "$pkg" ]; then
    echo "  skip: '$pkg' is not a package directory"
    continue
  fi
  # Adopt-free approach: stow will refuse on conflicts. Pre-move real files.
  while IFS= read -r -d '' file; do
    rel="${file#"$pkg"/}"
    target="$HOME/$rel"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$backup_dir/$(dirname "$rel")"
      echo "  backup: $target -> $backup_dir/$rel"
      mv "$target" "$backup_dir/$rel"
    fi
  done < <(find "$pkg" -type f -print0)

  stow --restow --target="$HOME" "$pkg"
  echo "  linked: $pkg"
done

if [ -d "$backup_dir" ]; then
  echo "Backed up pre-existing files to: $backup_dir"
fi

echo "Done. Restart your shell (exec zsh) to pick up zsh changes."
echo "First launch runs the Powerlevel10k wizard if ~/.p10k.zsh is absent"
echo "(or run 'p10k configure' anytime)."
