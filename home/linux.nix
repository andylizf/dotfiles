{ lib, ... }:
{
  # Linux-specific tweaks can go here.

  home.activation.ensureInotify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! command -v sysctl >/dev/null 2>&1; then
      echo "[dotfiles] sysctl not available; skipping inotify tuning" >&2
    else
      tmpFile="$(mktemp)"
      cat > "$tmpFile" <<'EOF'
fs.inotify.max_user_watches = 524288
EOF

      if [ "$(id -u)" -eq 0 ]; then
        install -Dm644 "$tmpFile" /etc/sysctl.d/99-inotify.conf
        rm -f "$tmpFile"
        sysctl -p /etc/sysctl.d/99-inotify.conf || true
      else
        SUDO_BIN=""
        if command -v sudo >/dev/null 2>&1; then
          SUDO_BIN="$(command -v sudo)"
        elif [ -x /usr/bin/sudo ]; then
          SUDO_BIN="/usr/bin/sudo"
        elif [ -x /bin/sudo ]; then
          SUDO_BIN="/bin/sudo"
        fi

        if [ -n "$SUDO_BIN" ]; then
          "$SUDO_BIN" install -Dm644 "$tmpFile" /etc/sysctl.d/99-inotify.conf
          rm -f "$tmpFile"
          "$SUDO_BIN" sysctl -p /etc/sysctl.d/99-inotify.conf || true
        elif command -v doas >/dev/null 2>&1; then
          doas install -Dm644 "$tmpFile" /etc/sysctl.d/99-inotify.conf
          rm -f "$tmpFile"
          doas sysctl -p /etc/sysctl.d/99-inotify.conf || true
        else
          rm -f "$tmpFile"
          echo "[dotfiles] no sudo/doas; skipping inotify sysctl" >&2
        fi
      fi
    fi
  '';
}
