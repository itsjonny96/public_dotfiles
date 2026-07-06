# dotfiles

Personal dotfiles for macOS and Linux. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/itsjonny96/dotfiles/main/bootstrap.sh)
```

Installs Homebrew (macOS) or the native package manager (Linux), symlinks all configs via Stow, and sets zsh as the default shell. Then reload:

```bash
exec zsh
```

---

## Structure

```
dotfiles/
├── bootstrap.sh        # cross-platform setup script
├── homebrew/
│   └── Brewfile        # core packages (macOS)
├── zsh/
│   ├── .zshrc          # main shell config (starship, fzf, completions)
│   ├── .zshenv         # env vars loaded before .zshrc
│   └── aliases.zsh     # shell aliases
├── nvim/               # neovim config (lazy.nvim)
├── tmux/               # tmux config (tpm)
├── starship/           # starship prompt config
└── taskwarrior/        # taskwarrior config and catppuccin theme
```

---

## Local overrides

Two files are gitignored for machine-specific config:

| File | Purpose |
|---|---|
| `~/dotfiles/zsh/local.zsh` | Machine-specific aliases, PATH additions, project shortcuts |
| `~/.zshrc.local` | Anything that can't live in the dotfiles dir (e.g. work toolchain paths) |

Both are sourced automatically if they exist.

---

## Obsidian (nvim)

The Obsidian plugin reads vault paths from environment variables. Set these in `~/dotfiles/zsh/local.zsh` or `~/.zshrc.local`:

```zsh
export OBSIDIAN_VAULT="$HOME/Documents/Obsidian"
export OBSIDIAN_TEMPLATES="Templates"
export OBSIDIAN_WEEKLY_DIR="$HOME/Documents/Obsidian/Weekly/$(date +%Y)"
export OBSIDIAN_WEEKLY_TEMPLATE="$HOME/Documents/Obsidian/Templates/Weekly Note.md"
```

---

## Taskwarrior sync

Sync config is machine-specific and never tracked. Create `~/.task/sync.taskrc` locally and uncomment the include in `taskwarrior/.taskrc`.

---

## Troubleshooting

**Stow conflict on bootstrap** — a file already exists at the symlink target. Back it up then re-run:
```bash
stow -v --restow <package>
```

**Wrong default shell after bootstrap**:
```bash
chsh -s $(which zsh)
```
