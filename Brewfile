# Baseline packages and apps for every Mac.
# install.sh sets DOTFILES_PROFILE to "personal" or "work".
# Never add node, maven, gradle or openjdk here: fnm and SDKMAN own those.
work = ENV["DOTFILES_PROFILE"] == "work"

tap "hashicorp/tap"

# CLI
brew "git"
brew "gh"
brew "neovim"
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

# Personal only
cask "spotify" unless work
cask "telegram" unless work
