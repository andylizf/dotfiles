{ pkgs, ... }:
{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";

    # ── Auditd: server observability ──────────────────────────────────
    # Tracks command execution, process kills, file deletion, Docker
    # access, privilege escalation, and identity file changes.
    # Query with: ausearch -k <key> -ts today
    environment.etc."audit/rules.d/90-dotfiles.rules" = {
      text = ''
        ## dotfiles-managed audit rules — do not edit manually

        # Track all command execution (shell-independent, survives history -c).
        # Filter out system services (auid unset) to reduce log volume by ~60%.
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
      '';
    };
  };
}
