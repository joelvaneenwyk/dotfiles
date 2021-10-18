#!/usr/bin/env bash
#
# Use the following to update the short URL:
#   - curl -i https://git.io -F "url=https://gist.githubusercontent.com/joelvaneenwyk/dfe24a255f77b2e14e67965391a3a8fe/raw" -F "code=mycelio.sh"
#

echo "[mycelio] Cloning 'dotfiles' repository..."
git -C "$HOME" -c core.symlinks=true clone --recursive https://github.com/joelvaneenwyk/dotfiles.git

# shellcheck source=setup.sh
source "$HOME/setup.sh"
