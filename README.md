# dotfiles

Personal macOS dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Package     | Manages                          | Target                          |
| ----------- | -------------------------------- | ------------------------------- |
| `zsh`       | `.zshrc`, `.zshenv`, `.zprofile` | `~/`                            |
| `ghostty`   | Ghostty terminal config          | `~/.config/ghostty/config`      |
| `claude`    | Claude Code `settings.json`      | `~/.claude/settings.json`       |
| `git`       | Global git config + ignore       | `~/.config/git/`                |
| `gh`        | GitHub CLI config (no token)     | `~/.config/gh/config.yml`       |
| `karabiner` | Karabiner-Elements key mappings  | `~/.config/karabiner/`          |
| `raycast`   | Raycast (manual — see below)     | —                               |

## Install

```sh
git clone https://github.com/chamaboy/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./install.sh
```

`install.sh` installs GNU Stow if missing, backs up any conflicting real files
to `~/.dotfiles-backup/<timestamp>/`, then symlinks each package into `$HOME`.

Install specific packages only:

```sh
./install.sh zsh ghostty
```

## How it works

Each top-level directory is a Stow *package*. Its inner layout mirrors `$HOME`,
so `zsh/.zshrc` links to `~/.zshrc` and `ghostty/.config/ghostty/config` links
to `~/.config/ghostty/config`.

To add a new dotfile: move it under the right package (preserving its path
relative to `$HOME`), then re-run `./install.sh <package>`.

To remove links for a package:

```sh
stow --delete --target="$HOME" zsh
```

## Secrets

This repo is **public**. Never commit tokens, keys, or credentials.

- Machine-local, secret shell config goes in `~/.zshrc.local` (git-ignored,
  sourced automatically by `.zshrc` if present).
- Git identity (name/email) goes in `~/.gitconfig.local`, included by the
  tracked `git/config` via `[include]`. Create it on a new machine:
  ```sh
  cat > ~/.gitconfig.local <<'EOF'
  [user]
  	name  = Your Name
  	email = you@example.com
  EOF
  ```
- `gh/hosts.yml` (GitHub auth token) is **not** tracked — run `gh auth login`
  on each new machine instead.
- The `.gitignore` blocks `*.local`, `.env*`, `*token*`, `*secret*`, `*.key`,
  `gh/hosts.yml`, karabiner auto-backups, and everything under
  `claude/.claude/` except `settings.json`.

## Raycast

Raycast stores its config in an **encrypted SQLite database**, so it can't be
tracked as plain files. Sync it one of two ways:

1. **Raycast Cloud Sync** (Raycast Pro) — Settings → Cloud Sync. Recommended.
2. **Manual export/import** — Settings → Advanced → *Export / Import*. Save the
   exported `.rayconfig` outside this repo (it may contain secrets).

## Claude Code

Only `~/.claude/settings.json` is tracked. History, sessions, caches, plugins,
and the SuperClaude framework files are intentionally **not** managed here.
