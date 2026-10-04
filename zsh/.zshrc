# Completions
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # case-insensitive
zstyle ':completion:*' menu select                     # arrow-key menu

# Plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(fzf --zsh)          # Ctrl+R history search, Ctrl+T file search
eval "$(zoxide init zsh)"    # `z proj` jumps to folders
eval "$(starship init zsh)"  # prompt with git branch, node/java versions
eval "$(fnm env --use-on-cd --shell zsh)"  # Node versions, auto-switch on .nvmrc

# Aliases
alias ls="eza --icons"
alias cat="bat"
alias vim="nvim"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Machine-only settings (work env vars, tokens): never committed
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Must be last
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
