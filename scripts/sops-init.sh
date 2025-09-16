#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

AGE_DIR="$HOME/.config/sops/age"
AGE_KEY="$AGE_DIR/keys.txt"
SOPS_YAML="$ROOT_DIR/.sops.yaml"
PLAIN_EXAMPLE="$ROOT_DIR/secrets/secrets.example.yaml"
ENC_FILE="$ROOT_DIR/secrets/secrets.yaml"

export PATH="$HOME/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
require age-keygen
require sops

mkdir -p "$AGE_DIR" "$ROOT_DIR/secrets"

if [ ! -f "$AGE_KEY" ]; then
  echo "Generating age private key: $AGE_KEY"
  age-keygen -o "$AGE_KEY"
fi

PUB=$(grep '^# public key:' "$AGE_KEY" | awk '{print $4}')
if [ -z "$PUB" ]; then
  echo "Unable to read age public key, please check $AGE_KEY" >&2
  exit 1
fi

if [ ! -f "$SOPS_YAML" ]; then
  cat > "$SOPS_YAML" <<EOF
creation_rules:
  - path_regex: secrets/secrets\\.yaml$
    age: $PUB
EOF
  echo "Generated $SOPS_YAML (recipient=$PUB)"
else
  echo "Completed: $SOPS_YAML already exists. Edit with: sops $SOPS_YAML"
fi

if [ ! -f "$ENC_FILE" ]; then
  if [ ! -f "$PLAIN_EXAMPLE" ]; then
    echo "Missing $PLAIN_EXAMPLE, please create an example or provide plaintext." >&2
    exit 1
  fi
  echo "Encrypting $PLAIN_EXAMPLE -> $ENC_FILE"
  cp "$PLAIN_EXAMPLE" "$ENC_FILE"
  sops --encrypt --in-place "$ENC_FILE"
  echo "Completed: $ENC_FILE created (encrypted). Edit with: sops $ENC_FILE"
else
  echo "Completed: $ENC_FILE already exists. Edit with: sops $ENC_FILE"
fi
