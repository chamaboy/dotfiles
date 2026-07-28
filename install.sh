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

# Non-fatal problems are collected here and reported together at the end, so a
# single failure (e.g. a cask that needs an interactive sudo password) never
# stops the independent steps that follow it.
WARNINGS=()
warn() {
  echo "  warning: $1" >&2
  WARNINGS+=("$1")
}

# --- Ensure Homebrew is available ---
if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew not found. Install it first: https://brew.sh" >&2
  exit 1
fi

# --- Install packages from Brewfile (taps, CLI tools, GUI apps) ---
# This also installs stow itself, so it must run before stowing.
#
# A partial Brewfile failure is not fatal: the steps below don't depend on any
# individual formula, so we record what failed and carry on. `brew bundle` is
# itself idempotent — already-installed entries are reported as "Using ...".
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
  echo "Installing packages from Brewfile..."
  if ! brew bundle --file="$DOTFILES_DIR/Brewfile"; then
    warn "brew bundle: some entries failed to install (see output above);
           re-run 'brew bundle --file=Brewfile' in an interactive shell if a
           cask needed a sudo password"
  fi
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
  if ! RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
       sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
    warn "Oh My Zsh install failed; .zshrc will not load until it is present"
  fi
fi

# Clone a git repo into $2 only if it isn't already there.
#
# A failed clone can leave a partial directory behind, which would make the
# -d test below succeed on the next run and silently skip the repair. Roll the
# directory back on failure so re-running the script always retries cleanly.
clone_if_missing() {
  [ -d "$2" ] && return 0
  echo "  cloning: $(basename "$2")"
  if ! git clone --depth=1 "$1" "$2"; then
    rm -rf "$2"
    warn "clone failed: $1 (re-run to retry)"
  fi
}

echo "Installing zsh theme & plugins..."
clone_if_missing https://github.com/romkatv/powerlevel10k.git             "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git     "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

# --- Install Claude Code (idempotent) ---
# Self-updating tool; we only bootstrap the binary on a fresh machine.
if ! command -v claude >/dev/null 2>&1; then
  echo "Installing Claude Code..."
  if ! curl -fsSL https://claude.ai/install.sh | bash; then
    warn "Claude Code install failed (re-run to retry)"
  fi
fi

# --- Determine packages ---
if [ "$#" -gt 0 ]; then
  PACKAGES=("$@")
else
  PACKAGES=("${DEFAULT_PACKAGES[@]}")
fi

# Stow ships via the Brewfile, so a failed bundle can leave it missing. Without
# it nothing below can run, which makes this the one hard dependency worth
# stopping for.
if ! command -v stow >/dev/null 2>&1; then
  echo "Error: stow not found — 'brew install stow', then re-run." >&2
  exit 1
fi

# --- Back up any pre-existing real files that would collide ---
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
echo "Stowing packages: ${PACKAGES[*]}"

# True if $1 or any of its parent directories (up to $HOME) is a symlink.
#
# `[ -L "$path" ]` only tests the final component, but stow folds a directory
# whose entire contents it owns into a single link — so ~/.config/ghostty can
# be a link while ~/.config/ghostty/config tests as a plain file. Backing that
# "file" up would follow the link and move the real file *out of this repo*.
# Walk the parents so an already-stowed path is never mistaken for a conflict.
under_symlink() {
  local path="$1"
  while [ "$path" != "$HOME" ] && [ "$path" != "/" ]; do
    [ -L "$path" ] && return 0
    path="$(dirname "$path")"
  done
  return 1
}

for pkg in "${PACKAGES[@]}"; do
  # Strip any trailing slash so tab-completed names ("zsh/") still match.
  pkg="${pkg%/}"
  if [ ! -d "$pkg" ]; then
    warn "'$pkg' is not a package directory — skipped"
    continue
  fi
  # Adopt-free approach: stow will refuse on conflicts. Pre-move real files.
  while IFS= read -r -d '' file; do
    rel="${file#"$pkg"/}"
    target="$HOME/$rel"
    if [ -e "$target" ] && ! under_symlink "$target"; then
      mkdir -p "$backup_dir/$(dirname "$rel")"
      echo "  backup: $target -> $backup_dir/$rel"
      mv "$target" "$backup_dir/$rel"
    fi
  done < <(find "$pkg" -type f -print0)

  # --restow is idempotent: it unlinks then relinks, so re-running repairs a
  # package whose symlink was replaced by a real file. One package failing
  # must not prevent the rest from being linked.
  if stow --restow --target="$HOME" "$pkg"; then
    echo "  linked: $pkg"
  else
    warn "stow failed for '$pkg' (see output above)"
  fi
done

if [ -d "$backup_dir" ]; then
  echo "Backed up pre-existing files to: $backup_dir"
fi

# --- Report anything that was skipped or failed ---
# Exit non-zero so callers and CI can tell a partial run from a clean one,
# while the work that *could* be done has still been done.
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  echo
  echo "Completed with ${#WARNINGS[@]} warning(s):" >&2
  for w in "${WARNINGS[@]}"; do
    echo "  - $w" >&2
  done
  echo
  echo "Everything else was installed and linked. Re-run to retry the above." >&2
  exit 1
fi

echo "Done. Restart your shell (exec zsh) to pick up zsh changes."
echo "Prompt style comes from the stowed ~/.p10k.zsh; 'p10k configure' restyles"
echo "it (writes through the symlink into this repo — commit afterwards)."
