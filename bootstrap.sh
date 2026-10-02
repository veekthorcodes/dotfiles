#!/bin/bash
# Fresh-Mac entry point. Run with:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/veekthorcodes/dotfiles/main/bootstrap.sh)"
# Work machine:
#   DOTFILES_PROFILE=work bash -c "$(curl -fsSL https://raw.githubusercontent.com/veekthorcodes/dotfiles/main/bootstrap.sh)"
set -euo pipefail

REPO="https://github.com/veekthorcodes/dotfiles.git"
DIR="$HOME/dotfiles"

# 1. Xcode Command Line Tools (git, make, a C compiler)
if ! xcode-select -p >/dev/null 2>&1; then
	echo "==> Installing Xcode Command Line Tools. Click Install in the dialog."
	xcode-select --install || true
	until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

# 2. Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
	BREW=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
	BREW=/usr/local/bin/brew
else
	echo "==> Installing Homebrew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	BREW=$([ -x /opt/homebrew/bin/brew ] && echo /opt/homebrew/bin/brew || echo /usr/local/bin/brew)
fi
eval "$("$BREW" shellenv)"

# 3. Clone (HTTPS, no key needed yet) or update the dotfiles
if [ -d "$DIR/.git" ]; then
	git -C "$DIR" pull --ff-only || echo "warning: could not update $DIR; using it as is"
else
	git clone "$REPO" "$DIR"
fi

exec "$DIR/install.sh" "$@"
