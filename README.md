# dotfiles

Personal macOS dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Package     | Manages                          | Target                          |
| ----------- | -------------------------------- | ------------------------------- |
| `Brewfile`  | Homebrew taps, CLI tools, apps   | (installed, not symlinked)      |
| `zsh`       | `.zshrc`, `.zshenv`, `.zprofile` | `~/`                            |
| `ghostty`   | Ghostty terminal config          | `~/.config/ghostty/config`      |
| `claude`    | Claude Code `settings.json`      | `~/.claude/settings.json`       |
| `git`       | Global git config + ignore       | `~/.config/git/`                |
| `karabiner` | Karabiner-Elements key mappings  | `~/.config/karabiner/`          |
| `raycast`   | Raycast (manual — see below)     | —                               |

## Install

```sh
git clone https://github.com/chamaboy/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./install.sh
```

`install.sh` runs, in order:

1. **`brew bundle`** — installs everything in the `Brewfile` (taps, CLI tools,
   GUI apps — including Stow itself).
2. **Oh My Zsh + prompt + plugins** — installs Oh My Zsh if missing, then clones
   the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme and the
   `zsh-autosuggestions` / `zsh-syntax-highlighting` plugins that `.zshrc`
   expects. Each step is idempotent (skipped if already present).
3. **Stow** — backs up any conflicting real files to
   `~/.dotfiles-backup/<timestamp>/`, then symlinks each package into `$HOME`.

The only prerequisite is Homebrew (https://brew.sh); everything the shell needs
is installed for you. On first launch, Powerlevel10k runs its configuration
wizard if `~/.p10k.zsh` doesn't exist yet (or run `p10k configure` anytime).

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

## Homebrew (Brewfile)

The `Brewfile` is a declarative list of Homebrew taps, CLI tools (`brew`), and
GUI apps (`cask`). `install.sh` applies it automatically, or run it directly:

```sh
brew bundle --file=Brewfile          # install everything listed
brew bundle check --file=Brewfile    # check what's missing / outdated
```

After installing or removing packages, refresh the list:

```sh
brew bundle dump --file=Brewfile --force
```

VS Code extensions are **not** tracked here — they sync via VS Code Settings
Sync. Global `npm`/`uv` tools are likewise left out.

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
- GitHub CLI (`gh`) config is **not** tracked — it's just defaults. Run
  `gh auth login` on each new machine to authenticate.
- The `.gitignore` blocks `*.local`, `.env*`, `*token*`, `*secret*`, `*.key`,
  karabiner auto-backups, and everything under `claude/.claude/` except
  `settings.json`.

## Raycast

Raycast stores its config in an **encrypted SQLite database**, so it can't be
tracked as plain files. Sync it one of two ways:

1. **Raycast Cloud Sync** (Raycast Pro) — Settings → Cloud Sync. Recommended.
2. **Manual export/import** — Settings → Advanced → *Export / Import*. Save the
   exported `.rayconfig` outside this repo (it may contain secrets).

## Claude Code

Only `~/.claude/settings.json` is tracked. History, sessions, caches, plugins,
and the SuperClaude framework files are intentionally **not** managed here.
