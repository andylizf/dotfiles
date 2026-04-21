#!/usr/bin/env bash
set -euo pipefail
# Clones dotfiles to /tmp, runs setup, cleans up.
# curl -fsSL https://gist.githubusercontent.com/andylizf/b0f7e7af109ee49236292e6f453d9348/raw/bootstrap.sh | bash

REPO="https://github.com/andylizf/dotfiles.git"
DIR="/tmp/dotfiles-bootstrap"

rm -rf "$DIR"
git clone --depth 1 "$REPO" "$DIR"
bash "$DIR/scripts/setup.sh"
rm -rf "$DIR"
