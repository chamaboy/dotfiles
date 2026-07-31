# dotfiles

Personal macOS dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Package     | Manages                          | Target                          |
| ----------- | -------------------------------- | ------------------------------- |
| `Brewfile`  | Homebrew taps, CLI tools, apps   | (installed, not symlinked)      |
| `zsh`       | `.zshrc`, `.zshenv`, `.zprofile`, `.p10k.zsh` | `~/`               |
| `ghostty`   | Ghostty terminal config          | `~/.config/ghostty/config`      |
| `claude`    | Claude Code `settings.json`      | `~/.claude/settings.json`       |
| `git`       | Global git config + ignore       | `~/.config/git/`                |
| `karabiner` | Karabiner-Elements key mappings  | `~/.config/karabiner/`          |
| `macos.sh`  | macOS system preferences (Dock, trackpad, shortcuts) | (applied via `defaults`, not symlinked) |
| `raycast`   | Raycast settings export (imported via GUI — see below) | (not symlinked) |

## Install

**Homebrew is the only prerequisite.** It pulls in the Xcode Command Line Tools
(and with them `git`), and `install.sh` installs Stow and everything else from
the `Brewfile`. `zsh` and `curl` already ship with macOS.

```sh
# 1. Homebrew — interactive, asks for your password
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Put brew on PATH for this shell. Only needed once: after step 3 the
#    stowed .zprofile does it for every new shell.
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Dotfiles
git clone https://github.com/chamaboy/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./install.sh
```

Skipping step 2 makes `install.sh` stop with `Homebrew not found` — the install
succeeded, `brew` just isn't on `PATH` in the shell you started it from.

`install.sh` runs, in order:

1. **`brew bundle`** — installs everything in the `Brewfile` (taps, CLI tools,
   GUI apps — including Stow itself).
2. **Oh My Zsh + prompt + plugins** — installs Oh My Zsh if missing, then clones
   the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme and the
   `zsh-autosuggestions` / `zsh-syntax-highlighting` plugins that `.zshrc`
   expects. Each step is idempotent (skipped if already present).
3. **Claude Code** — bootstraps the `claude` binary via the official installer
   if it isn't on `PATH`. It self-updates afterwards, so this only matters on a
   fresh machine.
4. **Stow** — backs up any conflicting real files to
   `~/.dotfiles-backup/<timestamp>/`, then symlinks each package into `$HOME`.
5. **macOS defaults** — applies the System Settings preferences in `macos.sh`
   (Dock auto-hide/position, trackpad speed, cmd+` window switching).

The Powerlevel10k config is tracked (`zsh/.p10k.zsh`), so the prompt looks the
same on every machine with no wizard on first launch. To restyle it, run
`p10k configure` — it writes through the `~/.p10k.zsh` symlink straight into
the repo, so commit the result afterwards.

Install specific packages only:

```sh
./install.sh zsh ghostty
```

Re-running is always safe — every step is idempotent, so nothing is duplicated
and a package whose symlink was replaced by a real file gets repaired.

### Reading the result

The script separates failures that make the rest pointless from ones that
don't, so a single broken cask can't stop your configs from being linked.

| Output | What happened | What to do |
| ---------------------------- | ------------------------------------------ | ------------------------ |
| `Done.`                      | Everything succeeded (exit 0)              | Nothing |
| `Completed with N warning(s)`| **Configs are linked**; some installs failed (exit 1) | Read the list, fix, re-run |
| `Error: ...` and stops       | Nothing ran — Homebrew or Stow is missing  | Install it, re-run |

A non-zero exit means "something didn't install", **not** "nothing happened" —
the warning summary is printed after the stow step has already finished.

Known warning: `karabiner-elements` and `session-manager-plugin` are casks
whose installers need a `sudo` password. Run interactively (a normal terminal),
you just get a password prompt; under a non-interactive run they fail with a
warning. Re-running fixes it:

```sh
brew bundle --file=~/Dotfiles/Brewfile
```

Karabiner also needs two one-time GUI approvals on each machine that no script
can automate: allow its system extension, and enable it under *Privacy &
Security → Input Monitoring*. Its first-launch wizard walks you through both.

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

## Daily workflow

Every tracked config in `$HOME` is a **symlink into this repo**, so editing
`~/.zshrc` (or letting a tool write through the link, like `p10k configure`)
edits the repo directly. Day to day that means: keep reality (this machine) and
the repo (the declaration) in sync.

| You did | Then do |
| ------------------------------------------ | ------------------------------------------------- |
| Edited a tracked config (`~/.zshrc`, ghostty, …) | `git commit && git push` — no stow needed |
| Created a **new** config file | Move it into its package (path mirrors `$HOME`), `./install.sh <pkg>`, commit |
| `brew install`-ed a keeper | Add a line to `Brewfile` by hand, commit |
| Changed a System Settings preference worth keeping | Add its `defaults write` line to `macos.sh`, commit |
| Changed Raycast settings | Re-export over `raycast/Raycast.rayconfig` (GUI), commit |
| Added a tool that needs install steps (zsh plugin, …) | Also add the step to `install.sh` (e.g. `clone_if_missing …`) — config alone won't set up the next machine |

On the other machine, after `git pull`:

- Config-only change → nothing to do, the symlinks already point at the repo.
- `Brewfile` changed → `brew bundle --file=Brewfile`.
- New package or `install.sh` step → `./install.sh` (safe to re-run).

Machine-local settings that should *not* sync (secrets, per-machine overrides
like this machine's nodenv-instead-of-Volta) go in `~/.zshrc.local` /
`~/.gitconfig.local` — git-ignored, see [Secrets](#secrets).

## Homebrew (Brewfile)

The `Brewfile` is a declarative list of Homebrew taps, CLI tools (`brew`), and
GUI apps (`cask`). `install.sh` applies it automatically, or run it directly:

```sh
brew bundle --file=Brewfile          # install everything listed
brew bundle check --file=Brewfile    # check what's missing / outdated
```

After `brew install`-ing something worth keeping, **add it to the Brewfile by
hand** (with a comment), then commit. Don't use `brew bundle dump --force`: it
overwrites the curated comments in this file and records *everything* installed
on the machine — including one-off experiments and deliberately untracked tools.

To spot drift (installed but not listed), dry-run cleanup:

```sh
brew bundle cleanup --file=Brewfile  # lists extras; add --force to uninstall them
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

## macOS defaults (macos.sh)

System Settings choices live in plists that the `defaults` command can read and
write, so the ones worth syncing are scripted in `macos.sh` (run by
`install.sh`, or directly). Currently: Dock auto-hide + right position,
trackpad tracking speed, and "move focus to next window" on cmd+`.

Every line sets an absolute value, so re-running never toggles anything. Most
changes apply immediately; trackpad/keyboard-shortcut ones may need a re-login.

To capture a new setting: change it in System Settings, find the key by diffing
`defaults read` output before/after, and add the `defaults write` line here.

## Raycast

Raycast stores its config in an **encrypted SQLite database**, so it can't be
stowed as plain files. Instead the repo tracks a **password-encrypted export
snapshot**: `raycast/Raycast.rayconfig` (Settings → Advanced → *Export*).

- **New machine**: after `./install.sh`, run Raycast's *Import Settings & Data*,
  pick `raycast/Raycast.rayconfig`, enter the export password (it's in the
  password manager). This is a one-time GUI step, like Karabiner's approvals.
- **Changed Raycast settings**: re-export over the same file, commit. Like the
  Brewfile, the export only updates when you do it by hand — the file is a
  snapshot, not a live sync.

Why committing this to a public repo is OK *today*: no Store extensions are
installed, so the export holds hotkeys/aliases/preferences — nothing secret —
and the file itself is encrypted with the export password. **If an extension
that takes an API key ever gets installed, revisit this** (move the export to
private storage, or at least rotate to a strong unique password).

## Claude Code

`install.sh` bootstraps the `claude` binary itself (official installer, skipped
if already present; it self-updates from then on). Of its config, only
`~/.claude/settings.json` is tracked. History, sessions, caches, plugins, and
the SuperClaude framework files are intentionally **not** managed here — note
that plugins enabled in `settings.json` still need a one-time
`claude plugin install` on each machine.
