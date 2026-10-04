# Baseline packages and apps for every Mac.
# install.sh saves the profile ("personal" or "work") to ~/.dotfiles-profile.
# Read it from there: Homebrew strips most env vars, so ENV["DOTFILES_PROFILE"] is always nil here.
# Never add node, maven, gradle or openjdk here: fnm and SDKMAN own those.
profile_file = File.expand_path("~/.dotfiles-profile")
work = File.exist?(profile_file) && File.read(profile_file).strip == "work"

tap "hashicorp/tap"

# CLI
brew "git"
brew "gh"
brew "neovim"
brew "lazygit"                   # terminal UI for git
brew "ripgrep"
brew "fd"
brew "jq"
brew "bat"
brew "eza"
brew "fzf"
brew "zoxide"
brew "starship"
brew "bash"                      # Bash 4+ for the SDKMAN installer
brew "pnpm"
brew "python"                    # pip installs are blocked; CLI tools come as formulas
brew "fnm"                       # Node version manager (instead of nvm)
brew "azure-cli"
brew "hashicorp/tap/terraform"   # not in homebrew-core since the license change
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-syntax-highlighting"

# Apps and font
cask "ghostty"
cask "brave-browser"
cask "google-chrome"
cask "orbstack"
cask "claude-code"
cask "font-jetbrains-mono-nerd-font"

# Work only
brew "ansible" if work

# Personal only
cask "spotify" unless work
cask "telegram" unless work
