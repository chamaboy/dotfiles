# Homebrew Bundle — declarative list of taps, CLI tools, and GUI apps.
#
# Restore everything on a new machine with:
#   brew bundle --file=Brewfile
# (install.sh runs this automatically before stowing.)
#
# VS Code extensions are intentionally NOT tracked here — they sync via
# VS Code Settings Sync. Global npm/uv tools are likewise left out.

# --- Taps ---
tap "supabase/tap"

# --- CLI tools ---
# CLI tool to build, test, debug, and deploy Serverless applications using AWS SAM
brew "aws-sam-cli"
# Official Amazon AWS command-line interface
brew "awscli"
# GitHub command-line tool
brew "gh"
# Organize software neatly under a single directory tree (e.g. /usr/local)
brew "stow"
# Terminal multiplexer
brew "tmux"
# Extremely fast Python package installer and resolver, written in Rust
brew "uv"
# Supabase CLI
brew "supabase/tap/supabase", trusted: true

# --- GUI apps (casks) ---
# Terminal emulator that uses platform-native UI and GPU acceleration
cask "ghostty"
# Plugin for AWS CLI to start and end sessions that connect to managed instances
cask "session-manager-plugin"
