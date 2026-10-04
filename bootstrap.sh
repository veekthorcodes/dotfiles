#!/bin/bash
# Fresh-Mac entry point. Run with:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/veekthorcodes/dotfiles/main/bootstrap.sh)"
# Work machine:
#   DOTFILES_PROFILE=work bash -c "$(curl -fsSL https://raw.githubusercontent.com/veekthorcodes/dotfiles/main/bootstrap.sh)"
set -euo pipefail

REPO="https://github.com/veekthorcodes/dotfiles.git"
DIR="$HOME/dotfiles"
BREW=/opt/homebrew/bin/brew

if [ "$(uname -m)" != arm64 ]; then
	echo "These dotfiles are for Apple Silicon Macs only." && exit 1
fi

# 1. Xcode Command Line Tools (git, make, a C compiler)
if ! xcode-select -p >/dev/null 2>&1; then
	echo "==> Installing Xcode Command Line Tools. Click Install in the dialog."
	xcode-select --install || true
	until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

# 2. Homebrew
if [ ! -x "$BREW" ]; then
	echo "==> Installing Homebrew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$BREW" shellenv)"

# 3. Clone (HTTPS, no key needed yet) or update the dotfiles
if [ -d "$DIR/.git" ]; then
	git -C "$DIR" pull --ff-only || echo "warning: could not update $DIR; using it as is"
else
	git clone "$REPO" "$DIR"
fi

exec "$DIR/install.sh" "$@"
