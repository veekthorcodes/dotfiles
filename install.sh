#!/bin/bash
# Set up this Mac from the dotfiles. Safe to re-run: every step skips what's already done.
# Usage: ~/dotfiles/install.sh [--personal | --work]
set -o pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_USER="veekthorcodes"
NODE_MAJOR=24
# Temurin builds of OpenJDK (the -open builds stop getting fixes at the next release).
# Pin only versions SDKMAN can download: java 21.0.12+1.1-tem and gradle 9.8.0 are listed but 404 (2026-10-04).
SDKMAN_CANDIDATES="java:21.0.7-tem java:25.0.4-tem maven:3.10.0 gradle:9.5.1"
JAVA_DEFAULT="25.0.4-tem"
PROFILE_FILE="$HOME/.dotfiles-profile"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
TODO=()

bold=$'\033[1m' green=$'\033[32m' yellow=$'\033[33m' reset=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$bold" "$1" "$reset"; }
ok() { printf '  %s✓%s %s\n' "$green" "$reset" "$1"; }
warn() { printf '  %s!%s %s\n' "$yellow" "$reset" "$1"; }
todo() { TODO+=("$1"); }

# Profile: flag, then $DOTFILES_PROFILE, then the last run's choice, then personal
profile="${DOTFILES_PROFILE:-}"
for arg in "$@"; do
	case "$arg" in
	--work) profile=work ;;
	--personal) profile=personal ;;
	esac
done
[ -z "$profile" ] && [ -f "$PROFILE_FILE" ] && profile=$(cat "$PROFILE_FILE")
profile="${profile:-personal}"
echo "$profile" >"$PROFILE_FILE"
export DOTFILES_PROFILE="$profile"
printf '%sProfile: %s%s\n' "$bold" "$profile" "$reset"

# ---------------------------------------------------------------------------
step "Homebrew"
if [ "$(uname -m)" != arm64 ]; then
	echo "These dotfiles are for Apple Silicon Macs only." && exit 1
fi
BREW=/opt/homebrew/bin/brew
[ -x "$BREW" ] || { echo "Homebrew is not installed. Run bootstrap.sh first." && exit 1; }
eval "$("$BREW" shellenv)"
if [ -f /etc/paths.d/homebrew ] || grep -qs 'brew shellenv' "$HOME/.zprofile"; then
	ok "brew is on PATH for new shells"
else
	echo "eval \"\$($BREW shellenv)\"" >>"$HOME/.zprofile"
	ok "added brew shellenv to ~/.zprofile"
fi

if /usr/bin/pgrep -q oahd || arch -x86_64 /usr/bin/true 2>/dev/null; then
	ok "Rosetta"
else
	sudo softwareupdate --install-rosetta --agree-to-license && ok "Rosetta installed"
fi

# ---------------------------------------------------------------------------
step "Brewfile ($profile)"
if brew bundle check --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
	ok "all packages and apps installed"
else
	brew bundle install --no-upgrade --file="$DOTFILES/Brewfile" ||
		warn "some entries failed (see above). An app installed by hand can be handed to Homebrew with: brew install --cask --adopt <name> (quit the app first). 'Operation not permitted' means your terminal needs System Settings -> Privacy & Security -> App Management; allow it, then Cmd+Q and reopen the terminal"
fi
if [ "$profile" = work ]; then
	for cask in spotify telegram; do
		brew list --cask "$cask" >/dev/null 2>&1 && brew uninstall --cask "$cask" && ok "removed $cask (work profile)"
	done
fi

# ---------------------------------------------------------------------------
step "Config files"
link() {
	local src="$DOTFILES/$1" dest="$2"
	if [ "$(readlink "$dest")" = "$src" ]; then
		ok "$dest"
		return
	fi
	mkdir -p "$(dirname "$dest")"
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		local backup="$BACKUP_DIR/${dest#"$HOME"/}"
		mkdir -p "$(dirname "$backup")"
		mv "$dest" "$backup"
		warn "moved existing $dest to $backup"
	fi
	ln -s "$src" "$dest"
	ok "$dest -> dotfiles/$1"
}
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
link zsh/.zshrc "$HOME/.zshrc"
link zsh/.zprofile "$HOME/.zprofile"
link git/.gitconfig "$HOME/.gitconfig"
link git/.gitignore_global "$HOME/.gitignore_global"
link ghostty/config "$HOME/.config/ghostty/config"
link ssh/config "$HOME/.ssh/config"
link claude/settings.json "$HOME/.claude/settings.json"
link claude/statusline.sh "$HOME/.claude/statusline.sh"

[ -d "$BACKUP_DIR" ] && todo "Old configs were moved to $BACKUP_DIR. Copy machine-only lines from them: env vars and aliases into ~/.zshrc.local, Host blocks into ~/.ssh/config.local, git settings into ~/.gitconfig.local"

if [ "$profile" = work ] && ! git config --file "$HOME/.gitconfig.local" user.email >/dev/null; then
	read -r -p "  Work git email (blank to keep the personal one): " work_email
	[ -n "$work_email" ] && git config --file "$HOME/.gitconfig.local" user.email "$work_email" && ok "work email saved to ~/.gitconfig.local"
fi

# ---------------------------------------------------------------------------
step "Java, Maven, Gradle (SDKMAN)"
BREW_BASH="$(brew --prefix)/bin/bash" # SDKMAN needs Bash 4+; macOS ships 3.2
if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
	curl -s "https://get.sdkman.io?rcupdate=false" | "$BREW_BASH" # .zshrc already loads SDKMAN
fi
for entry in $SDKMAN_CANDIDATES; do
	cand=${entry%%:*} ver=${entry#*:}
	if [ -d "$HOME/.sdkman/candidates/$cand/$ver" ]; then
		ok "$cand $ver"
	else
		"$BREW_BASH" -c "source \"\$HOME/.sdkman/bin/sdkman-init.sh\" && sdkman_auto_answer=true sdk install $cand $ver" &&
			ok "$cand $ver installed" || warn "could not install $cand $ver; pick another with: sdk list $cand"
	fi
done
if [ "$(readlink "$HOME/.sdkman/candidates/java/current")" = "$HOME/.sdkman/candidates/java/$JAVA_DEFAULT" ]; then
	ok "default java $JAVA_DEFAULT"
else
	"$BREW_BASH" -c "source \"\$HOME/.sdkman/bin/sdkman-init.sh\" && sdk default java $JAVA_DEFAULT" >/dev/null && ok "default java $JAVA_DEFAULT"
fi

# ---------------------------------------------------------------------------
step "Node (fnm)"
eval "$(fnm env --shell bash)"
if fnm list | grep -q "v$NODE_MAJOR\."; then
	ok "Node $NODE_MAJOR"
else
	fnm install "$NODE_MAJOR" && ok "Node $NODE_MAJOR installed"
fi
fnm default "$NODE_MAJOR" && ok "default: $(fnm exec --using=default node -v)"

if [ "$profile" = work ]; then
	if command -v forge >/dev/null; then
		ok "Forge CLI"
	else
		# Forge's native deps (keytar, cloudflared) need their install scripts
		npm install -g @forge/cli --allow-scripts=@forge/cli,cloudflared,keytar && ok "Forge CLI installed"
	fi
	todo "forge login"
	todo "Bitbucket: pbcopy < ~/.ssh/id_ed25519.pub, add it under Personal settings -> SSH keys, then ssh -T git@bitbucket.org"
fi

# ---------------------------------------------------------------------------
step "SSH key and GitHub"
KEY="$HOME/.ssh/id_ed25519"
if [ -f "$KEY" ]; then
	ok "$KEY exists"
else
	ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$KEY"
fi
if ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$KEY" | awk '{print $2}')"; then
	ok "key loaded in the agent"
else
	ssh-add --apple-use-keychain "$KEY" && ok "key added to the Keychain" || warn "could not add the key to the agent"
fi

if gh auth status -h github.com >/dev/null 2>&1; then
	ok "gh logged in"
else
	gh auth login -h github.com -p ssh -w
fi
if gh ssh-key list 2>/dev/null | grep -q "$(awk '{print $2}' "$KEY.pub")"; then
	ok "key is on GitHub"
else
	gh ssh-key add "$KEY.pub" --title "$(scutil --get ComputerName)" && ok "key added to GitHub"
fi
# ssh -T exits 1 even on success, so check its output, not its status
ssh_out=$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)
case "$ssh_out" in
*"successfully authenticated"*) ok "ssh to github.com works" ;;
*) warn "ssh -T git@github.com failed: $ssh_out" ;;
esac

# Push access for the dotfiles themselves, plus the secret-blocking hook
if git -C "$DOTFILES" remote get-url origin 2>/dev/null | grep -q '^https://'; then
	git -C "$DOTFILES" remote set-url origin "git@github.com:$GITHUB_USER/dotfiles.git" && ok "dotfiles remote switched to SSH"
fi
git -C "$DOTFILES" config core.hooksPath .githooks

# ---------------------------------------------------------------------------
step "Neovim"
if [ -d "$HOME/.config/nvim/.git" ]; then
	ok "~/.config/nvim"
else
	git clone "git@github.com:$GITHUB_USER/nvim.git" "$HOME/.config/nvim" && ok "cloned $GITHUB_USER/nvim"
	todo "Open nvim once so Lazy and Mason install everything, then run :checkhealth"
fi

# ---------------------------------------------------------------------------
step "macOS settings"
dock_changed=0
setting() { # domain key type value expected-read-value
	if [ "$(defaults read "$1" "$2" 2>/dev/null)" = "$5" ]; then
		ok "$1 $2"
	else
		defaults write "$1" "$2" "-$3" "$4" && ok "$1 $2 = $4"
		[ "$1" = com.apple.dock ] && dock_changed=1
	fi
}
setting com.apple.dock autohide bool true 1
setting com.apple.dock tilesize int 45 45
setting com.apple.WindowManager GloballyEnabled bool true 1 # Stage Manager
[ "$dock_changed" = 1 ] && killall Dock

# ---------------------------------------------------------------------------
fdesetup isactive >/dev/null 2>&1 || todo "Turn on FileVault: System Settings -> Privacy & Security (save the recovery key)"
command -v docker >/dev/null || todo "Open OrbStack once to finish setup (installs the docker CLI)"
az account show >/dev/null 2>&1 || todo "When you need Azure: az login"

step "Done"
if [ ${#TODO[@]} -eq 0 ]; then
	ok "nothing left to do by hand"
else
	echo "  Still to do by hand:"
	for t in "${TODO[@]}"; do echo "  - $t"; done
fi
echo "  Open a new terminal tab to load the shell config."
