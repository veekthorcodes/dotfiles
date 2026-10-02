# dotfiles

My Mac setup. One command takes a fresh Mac to my baseline.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/veekthorcodes/dotfiles/main/bootstrap.sh)"
```

Work machine:

```bash
DOTFILES_PROFILE=work bash -c "$(curl -fsSL https://raw.githubusercontent.com/veekthorcodes/dotfiles/main/bootstrap.sh)"
```

`bootstrap.sh` installs the Xcode Command Line Tools and Homebrew, clones this repo to `~/dotfiles`, then runs `install.sh`.
`install.sh` can be re-run at any time; it skips whatever is already done. It:

- installs everything in the `Brewfile`
- installs Java, Maven and Gradle with SDKMAN, and Node with fnm
- symlinks the config files below into place (existing files are moved to `~/.dotfiles-backup/`)
- creates an SSH key, logs in to GitHub and uploads the key
- clones [veekthorcodes/nvim](https://github.com/veekthorcodes/nvim) into `~/.config/nvim`
- applies macOS settings (Dock auto-hide, Stage Manager)
- prints a checklist of the steps that need clicks

| File | Linked to |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `git/.gitconfig`, `git/.gitignore_global` | `~/.gitconfig`, `~/.gitignore_global` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `ssh/config` | `~/.ssh/config` |
| `claude/settings.json`, `claude/statusline.sh` | `~/.claude/` |

Because these are symlinks, editing `~/.zshrc` edits the repo; commit and push to share the change with other machines.

## Profiles

| | Personal (default) | Work |
|---|---|---|
| Spotify, Telegram | yes | removed |
| Forge CLI | no | yes |
| Git email | personal | asks for a work email, saved to `~/.gitconfig.local` |

## Rules

- This repo is public. Never commit secrets: `.env` files, tokens, private keys. A pre-commit hook in `.githooks/` blocks the common ones.
- Never install `node`, `maven`, `gradle` or `openjdk` with Homebrew. fnm and SDKMAN own those.
- Machine-specific settings go in `~/.gitconfig.local` (not committed).
