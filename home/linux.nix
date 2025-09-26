{ lib, ... }:
{
  # Linux-specific tweaks can go here.

  home.activation.ensureInotify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v sudo >/dev/null 2>&1; then
      tmpFile="$(mktemp)"
      cat > "$tmpFile" <<'EOF'
fs.inotify.max_user_watches = 524288
EOF
      sudo install -Dm644 "$tmpFile" /etc/sysctl.d/99-inotify.conf
      rm -f "$tmpFile"
      sudo sysctl -p /etc/sysctl.d/99-inotify.conf || true
    else
      echo "[dotfiles] sudo not found; skipping inotify sysctl" >&2
    fi
  '';
}
