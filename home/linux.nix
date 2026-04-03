{ lib, ... }:
{
  # Linux-specific tweaks can go here.

  # ── Server audit & observability ──────────────────────────────────
  # Deploys auditd rules for tracking kills, deletions, docker, su/sudo,
  # and all command execution. auditd itself is installed by setup.sh.
  home.activation.ensureAudit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run_privileged() {
      if [ "$(id -u)" -eq 0 ]; then
        "$@"
      elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
      else
        echo "[dotfiles] no sudo; skipping audit setup" >&2
        return 1
      fi
    }

    # Skip on systems without systemd (containers, WSL1, etc.)
    if [ ! -d /run/systemd/system ]; then
      echo "[dotfiles] no systemd; skipping audit setup" >&2
    elif ! command -v auditctl >/dev/null 2>&1; then
      echo "[dotfiles] auditd not installed; skipping rules (run setup.sh first)" >&2
    else
      tmpRules="$(mktemp)"
      cat > "$tmpRules" <<'RULES'
## dotfiles-managed audit rules — do not edit manually

# Track all command execution (the real audit trail — shell-independent,
# survives history -c). Filter out system services (auid unset) to
# reduce log volume by ~60%.
-a always,exit -F arch=b64 -S execve -F auid!=4294967295 -k cmd_exec

# Track process kills (who killed what)
-a always,exit -F arch=b64 -S kill -S tkill -S tgkill -F auid!=4294967295 -k process_kill

# Track file/directory deletion
-a always,exit -F arch=b64 -S unlinkat -S renameat -F auid!=4294967295 -k file_delete

# Track Docker socket access (who ran docker commands)
-w /var/run/docker.sock -p rwxa -k docker_access

# Track privilege escalation
-w /usr/bin/sudo -p x -k priv_escalation
-w /usr/bin/su -p x -k priv_escalation

# Track user/group modifications
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k identity
-w /etc/sudoers.d -p wa -k identity
RULES
      run_privileged install -Dm644 "$tmpRules" /etc/audit/rules.d/90-dotfiles.rules
      rm -f "$tmpRules"

      run_privileged augenrules --load 2>/dev/null || true
      run_privileged systemctl enable --now auditd 2>/dev/null || true
      echo "[dotfiles] auditd rules deployed"
    fi
  '';

  home.activation.ensureInotify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SYSCTL_BIN=""
    if command -v sysctl >/dev/null 2>&1; then
      SYSCTL_BIN="$(command -v sysctl)"
    elif [ -x /usr/sbin/sysctl ]; then
      SYSCTL_BIN="/usr/sbin/sysctl"
    elif [ -x /sbin/sysctl ]; then
      SYSCTL_BIN="/sbin/sysctl"
    elif [ -x /bin/sysctl ]; then
      SYSCTL_BIN="/bin/sysctl"
    fi

    if [ -z "$SYSCTL_BIN" ]; then
      echo "[dotfiles] sysctl not available; skipping inotify tuning" >&2
    else
      tmpFile="$(mktemp)"
      cat > "$tmpFile" <<'EOF'
fs.inotify.max_user_watches = 524288
EOF

      if [ "$(id -u)" -eq 0 ]; then
        install -Dm644 "$tmpFile" /etc/sysctl.d/99-inotify.conf
        rm -f "$tmpFile"
        "$SYSCTL_BIN" -p /etc/sysctl.d/99-inotify.conf || true
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
          "$SUDO_BIN" "$SYSCTL_BIN" -p /etc/sysctl.d/99-inotify.conf || true
        elif command -v doas >/dev/null 2>&1; then
          doas install -Dm644 "$tmpFile" /etc/sysctl.d/99-inotify.conf
          rm -f "$tmpFile"
          doas "$SYSCTL_BIN" -p /etc/sysctl.d/99-inotify.conf || true
        else
          rm -f "$tmpFile"
          echo "[dotfiles] no sudo/doas; skipping inotify sysctl" >&2
        fi
      fi
    fi
  '';
}
