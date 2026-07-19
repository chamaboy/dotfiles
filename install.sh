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
