{ pkgs, lib, config, resilient, ... }:
{
  # Run one activation step in isolation. home-manager concatenates every
  # `home.activation.*` fragment into a single `set -eu` bash script, so the
  # first step that exits non-zero silently skips every step ordered after it
  # — and the deploy can still look like it succeeded. Wrapping a step means a
  # failure is reported loudly and recorded, and the rest still runs.
  #
  # The `set +e` dance is not decorative. bash disables `set -e` INSIDE a
  # subshell when that subshell sits in an `if !` or `|| ...` context, so the
  # obvious spellings would let a step keep executing after its first error,
  # which is worse than aborting. Running the subshell in a plain context and
  # reading `$?` afterwards is what actually preserves the step's own `set -e`.
  _module.args.resilient = name: script: ''
    set +e
    ( set -e
    ${script}
    )
    _dotfilesRc=$?
    set -e
    if [ "''${_dotfilesRc}" -ne 0 ]; then
      echo "[dotfiles] ---------------------------------------------" >&2
      echo "[dotfiles] ACTIVATION STEP FAILED: ${name} (rc=''${_dotfilesRc})" >&2
      echo "[dotfiles] The remaining steps still run; this one did not." >&2
      echo "[dotfiles] ---------------------------------------------" >&2
      dotfilesFailedSteps="''${dotfilesFailedSteps:-}${name} "
      mkdir -p "$HOME/.local/state/dotfiles" || true
      echo "$(date -Iseconds) ${name} rc=''${_dotfilesRc}" \
        >> "$HOME/.local/state/dotfiles/activation-failures.log" || true
    fi
  '';

  # Runs last: activation steps at the same depth are ordered alphabetically, so the
  # zz prefix places this after every wrapped step. It is what keeps the wrapper from
  # being a downgrade — without it a failed step prints a banner and the deploy still
  # exits 0, i.e. a failure nobody notices, which is worse than the abort-on-first-
  # failure behaviour it replaced. home-manager already owns an EXIT trap, so this
  # cannot be done with a trap.
  home.activation.zzReportActivationFailures = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -n "''${dotfilesFailedSteps:-}" ]; then
      echo "[dotfiles] =============================================" >&2
      echo "[dotfiles] ACTIVATION FINISHED WITH FAILED STEPS:" >&2
      echo "[dotfiles]   ''${dotfilesFailedSteps}" >&2
      echo "[dotfiles] Every other step was applied. Details:" >&2
      echo "[dotfiles]   $HOME/.local/state/dotfiles/activation-failures.log" >&2
      echo "[dotfiles] =============================================" >&2
      exit 1
    fi
  '';

  # Set once and bump intentionally when adopting changed defaults.
  home.stateVersion = "24.05";

  # Core packages common to Linux and macOS
  home.packages = with pkgs; [
    awscli2
    google-cloud-sdk
    fish
    git
    unzip
    zip
    gzip
    coreutils
    less
    tree
    rsync
    gh
    uv
    python313
    nodejs_24
    direnv
    ripgrep
    # Disk-usage browsers, for answering "what is eating this disk" without a
    # hand-rolled `du | sort` every time. `dua` scans in parallel and is the one
    # to reach for on a large tree; `dua i` and `ncdu` both give an interactive
    # browser to descend through.
    #
    # Both size a file by its allocated blocks, exactly as `du` does, so both
    # count each APFS clone in full even though the blocks are shared. On a
    # machine running web-plane -- which clones Chrome, and which macOS clones
    # again per launch -- that inflates the total several times over: measured
    # 2026-08-29, a 500 MB file plus its clone reads as 1.0 GB in all three
    # tools while occupying 500 MB. Use them to find candidates; price the
    # cleanup with `df` before and after.
    dua
    ncdu
    # Toolchains for building and testing the projects checked out on these
    # machines, so a suite that needs one is not blocked on a machine that
    # happens to lack it.
    go
    python312Packages.huggingface-hub
  ];

  # Ensure ~/.local/bin is in PATH for user-managed tools if needed
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.fish = {
    enable = true;
    shellInit = ''
      # Anthropic API key (for Claude CLI, etc.)
      #
      # Disabled 2026-07-27. Exporting this globally has two costs:
      #  * Claude Code prefers the key over the Max subscription, so interactive
      #    use is billed pay-as-you-go (and dies with "Credit balance too low").
      #  * Remote Control requires claude.ai subscription auth and refuses to
      #    start when the key is set — for `claude remote-control` it errors out,
      #    for `claude --remote-control` it fails SILENTLY (session runs, RC never
      #    registers, nothing on the phone, nothing in the logs).
      # Upstream has no opt-out flag yet (anthropics/claude-code#9880, #12861).
      #
      # The sops-managed token file stays in place. Export it per-command when
      # API billing is actually wanted:
      #   env ANTHROPIC_API_KEY=(string trim (cat ~/.config/anthropic/token)) <cmd>
      #
      # if test -f ~/.config/anthropic/token
      #   set -gx ANTHROPIC_API_KEY (string trim (cat ~/.config/anthropic/token))
      # end

      # Shared environment, rendered from home/env.nix so that zsh, bash and
      # launchd get exactly the same set. Do not add variables here -- add them
      # to env.nix, or they will exist only where fish is the login shell.
      ${config.dotfilesEnv.fishInit}

      # fish-only convenience: switch Lambda profile with `lambda-use <profile>`.
      function lambda-use
        if test (count $argv) -eq 0
          echo "Usage: lambda-use <profile>"
          echo "Available profiles:"
          for f in ~/.config/lambda/*
            test -f $f; and echo "  "(basename $f)
          end
          return 1
        end
        set -l profile $argv[1]
        if test -f ~/.config/lambda/$profile
          set -gx LAMBDA_API_KEY (string trim (cat ~/.config/lambda/$profile))
          echo "Switched to Lambda profile: $profile"
        else
          echo "Profile not found: $profile"
          return 1
        end
      end

      # Direnv integration for fish
      if command -v direnv >/dev/null 2>&1
        direnv hook fish | source
      end

      # Ensure npm global bin (~/.local/bin) is in PATH for fish.
      # fish_add_path exists since fish 3.2 and is idempotent; it
      # stores ~/.local/bin in the universal fish_user_paths.
      fish_add_path ~/.local/bin

      # Ensure Nix profile binaries are available
      if test -f ~/.nix-profile/etc/profile.d/nix.fish
        . ~/.nix-profile/etc/profile.d/nix.fish
      end
      fish_add_path ~/.nix-profile/bin
      fish_add_path ~/.local/state/nix/profile/bin
      fish_add_path /etc/profiles/per-user/$USER/bin
      fish_add_path /run/current-system/sw/bin

      # Sync Hugging Face token into default cache for CLI detection

      # First-time plugin download. Check installed_plugins.json (not just the
      # cache dir) so orphaned/incomplete installs get retried.
      if command -q claude; and not grep -q 'document-skills@anthropic-agent-skills' ~/.claude/plugins/installed_plugins.json 2>/dev/null
        claude plugin marketplace add anthropics/skills &>/dev/null
        claude plugin install document-skills@anthropic-agent-skills &>/dev/null
      end

      function dotfiles-update
        curl -fsSL https://gist.githubusercontent.com/andylizf/b0f7e7af109ee49236292e6f453d9348/raw/bootstrap.sh | bash
      end

      function codex --wraps codex
        set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)
        command codex -c "projects.\"$root\".trust_level=\"trusted\"" $argv
      end
      alias codex-resume 'codex --ask-for-approval never --sandbox danger-full-access resume'
    '';
  };

  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    mouse = true;
    historyLimit = 50000;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
      {
        plugin = logging;
        extraConfig = ''
          set -g @logging-path '~/.tmux/logs'
          set -g @logging-auto-start 'on'
          set -g @logging-filename '#{session_name}-#{window_index}-#{pane_index}.log'
        '';
      }
    ];
    extraConfig = ''
      set -g set-titles on
      set -g set-titles-string "#S"
      set -g remain-on-exit on
    '';
  };

  programs.git = {
    enable = true;
    userName = "Zhifei Li";
    userEmail = "andylizf@outlook.com";
    extraConfig = {
      push.autoSetupRemote = true;
      push.default = "current";
      branch.autoSetupMerge = false;
      init.defaultBranch = "main";
      credential.helper = "!gh auth git-credential";
      credential."https://huggingface.co".helper = "store";
      credential."https://git.overleaf.com".helper =
        "store --file ${config.home.homeDirectory}/.config/overleaf/git-credentials";
      credential."https://git.overleaf.com".username = "git";
      core.editor = "cursor --wait";
      pull.rebase = true;
      rebase.autoStash = true;
      color.ui = "auto";
      core.sshCommand = "ssh -i ~/.ssh/id_ed25519 -F ~/.ssh/config";
    };
  };


  home.activation.fixSshPerms = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "fixSshPerms" ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh" || true
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys" || true
    PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp3Vontmq0bBIlnQIeUFqk/UhwGSFm3f96MRdR2T6AQ andylizf@outlook.com'
    if ! grep -Fxq "$PUBKEY" "$HOME/.ssh/authorized_keys"; then
      printf '%s\n' "$PUBKEY" >> "$HOME/.ssh/authorized_keys"
    fi
  '');

  home.activation.ensureSshConfig = lib.hm.dag.entryAfter [ "fixSshPerms" ] (resilient "ensureSshConfig" ''
    if [ ! -f "$HOME/.ssh/config" ]; then
      touch "$HOME/.ssh/config"
      chmod 600 "$HOME/.ssh/config" || true
    fi
  '');

  # Optional: set npm global prefix to ~/.local (safer PATH)
  home.activation.npmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "npmPrefix" ''
    if command -v npm >/dev/null 2>&1; then
      npm config set prefix "$HOME/.local" --global || true
      mkdir -p "$HOME/.local/bin"
    fi
  '');

  home.activation.ensureGcloudDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureGcloudDir" ''
    mkdir -p "$HOME/.config/gcloud"
    chmod 700 "$HOME/.config/gcloud" || true
  '');

  home.activation.ensureAwsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureAwsDir" ''
    mkdir -p "$HOME/.aws"
    chmod 700 "$HOME/.aws" || true
  '');

  home.activation.ensureDockerConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureDockerConfigDir" ''
    mkdir -p "$HOME/.docker"
    chmod 700 "$HOME/.docker" || true
  '');

  # Ensure GNU readlink is used during activation (macOS BSD readlink lacks -e).
  home.activation.fixReadlink = lib.hm.dag.entryBefore [ "linkGeneration" ] (resilient "fixReadlink" ''
    readlink() {
      "${pkgs.coreutils}/bin/readlink" "$@"
    }
  '');

  # Sync Docker config from sops-nix secrets to ~/.docker/config.json
  # Docker Desktop cannot handle symlinks (cross-device link errors).
  # sops-nix stores secrets at ~/.config/sops-nix/secrets/<name>, not at custom paths.
  home.activation.syncDockerConfig = lib.hm.dag.entryAfter [ "ensureDockerConfigDir" ] (resilient "syncDockerConfig" ''
    src="$HOME/.config/sops-nix/secrets/docker/config.json"
    dst="$HOME/.docker/config.json"
    if [ -f "$src" ] || [ -L "$src" ]; then
      # Remove any existing symlink first (sops-nix may have created one)
      if [ -L "$dst" ]; then
        rm "$dst"
      fi
      # Only update if content differs (preserve Docker Desktop modifications)
      if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
        install -m 600 "$src" "$dst"
      fi
    fi
  '');

  home.activation.ensureAnthropicDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureAnthropicDir" ''
    mkdir -p "$HOME/.config/anthropic"
    chmod 700 "$HOME/.config/anthropic" || true
  '');

  home.activation.ensureLambdaDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureLambdaDir" ''
    mkdir -p "$HOME/.config/lambda"
    chmod 700 "$HOME/.config/lambda" || true
  '');

  home.activation.ensureWandbDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureWandbDir" ''
    mkdir -p "$HOME/.config/wandb"
    chmod 700 "$HOME/.config/wandb" || true
  '');

  home.activation.syncPypirc = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "syncPypirc" ''
    token_file="$HOME/.config/pypi/token"
    dst="$HOME/.pypirc"
    if [ -f "$token_file" ]; then
      token="$(tr -d '\n\r' < "$token_file")"
      if [ -n "$token" ]; then
        tmp="$dst.tmp"
        cat > "$tmp" <<PYPIRC
[pypi]
username = __token__
password = $token
PYPIRC
        chmod 600 "$tmp"
        mv "$tmp" "$dst"
      fi
    fi
  '');

  home.activation.syncHuggingFaceToken = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "syncHuggingFaceToken" ''
    if [ -f "$HOME/.config/huggingface/token" ]; then
      mkdir -p "$HOME/.cache/huggingface"
      install -m 600 "$HOME/.config/huggingface/token" "$HOME/.cache/huggingface/token"
    fi
  '');

  home.activation.ensureOverleafConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "ensureOverleafConfigDir" ''
    mkdir -p "$HOME/.config/overleaf"
    chmod 700 "$HOME/.config/overleaf" || true
  '');

  home.activation.syncOverleafGitCredentials = lib.hm.dag.entryAfter [ "ensureOverleafConfigDir" ] (resilient "syncOverleafGitCredentials" ''
    token_file="$HOME/.config/overleaf/git-token"
    cred_file="$HOME/.config/overleaf/git-credentials"
    if [ -f "$token_file" ]; then
      token="$(tr -d '\n\r' < "$token_file")"
      if [ -n "$token" ]; then
        tmp_file="$cred_file.tmp"
        printf 'https://git:%s@git.overleaf.com\n' "$token" > "$tmp_file"
        chmod 600 "$tmp_file"
        mv "$tmp_file" "$cred_file"
      fi
    fi
  '');

  home.file.".claude/CLAUDE.md".source = ../claude-instruction.md;
  home.file.".codex/AGENTS.md".source = ../claude-instruction.md;
  home.file.".local/bin/notion-mcp-wrapper" = {
    source = ./scripts/notion-mcp-wrapper.sh;
    executable = true;
  };
  # Reads and writes every Slack workspace the desktop app is signed into, from
  # one session cookie. Pure stdlib, so it deploys everywhere; on a host without
  # the desktop app, `slack setup --cookie xoxd-...` is the whole install.
  # Usage and credential model: docs/slack-cli.md.
  home.file.".local/bin/slack" = {
    source = ./scripts/slack;
    executable = true;
  };
  # `gws` bound to the university Workspace profile. The wrapper exists because
  # the config-dir variable alone does not switch accounts — see the script.
  home.file.".local/bin/gws-princeton" = {
    source = ./scripts/gws-princeton;
    executable = true;
  };
  # Shared user-level skills for Claude Code and Codex. Codex discovers user
  # skills under ~/.agents/skills and supports symlinked skill directories, so
  # both agents read the same tracked sources instead of maintaining copies.
  # writing-for-people is canonical here; the copy in the daily-agent repo stays
  # for its unattended runs.
  home.file.".claude/skills/writing-for-people/SKILL.md".source =
    ../claude-skills/writing-for-people/SKILL.md;
  home.file.".claude/skills/writing-for-people/scripts/cjk-punct.py" = {
    source = ../claude-skills/writing-for-people/scripts/cjk-punct.py;
    executable = true;
  };
  home.file.".agents/skills/writing-for-people".source =
    ../claude-skills/writing-for-people;
  # teach: how explanations should read. Linked as a whole directory so new
  # files under references/ need no change here. The tracked copy is
  # de-identified — this repo is public, so keep names, personal details, and
  # verbatim user quotes out of it when editing.
  home.file.".claude/skills/teach".source = ../claude-skills/teach;
  home.file.".agents/skills/teach".source = ../claude-skills/teach;
  # send-gate: the full approval rules for anything that reaches another
  # human. Same de-identification rule as above. (personal-matters is
  # deliberately NOT here — it lives in a private repo, since health and
  # personal-life material does not belong in a public one.)
  home.file.".claude/skills/send-gate".source =
    ../claude-skills/send-gate;
  home.file.".agents/skills/send-gate".source =
    ../claude-skills/send-gate;
  # writing-instructions: which file a durable rule belongs in, the failures
  # that keep recurring in these files, and the subagent review to run before
  # saving one.
  home.file.".claude/skills/writing-instructions".source =
    ../claude-skills/writing-instructions;
  home.file.".agents/skills/writing-instructions".source =
    ../claude-skills/writing-instructions;
  # instruction-reviewer: the subagent that review calls. Kept beside the skill
  # because the two change together — the skill's failure-mode list is what the
  # agent reviews against — but deployed to .claude/agents, the only place
  # Claude Code looks for agent definitions. Its frontmatter preloads the skill
  # and sets load-claude-md false, so it reads a rule the way a later session
  # will: with nothing but the file.
  home.file.".claude/agents/instruction-reviewer.md".source =
    ../claude-skills/writing-instructions/instruction-reviewer.agent.md;

  # writing-reviewer: the same arrangement for drafts that go to a person. The
  # exhaustive half of the tell-scrub — the word table, the pattern list, the
  # frequency ceilings — lives in this agent rather than in the skill, because
  # those only apply to finished text while the skill has to be in context
  # before the first sentence is written.
  home.file.".claude/agents/writing-reviewer.md".source =
    ../claude-skills/writing-for-people/writing-reviewer.agent.md;

  # Claude Code settings.json must be a writable real file (not a nix-store
  # symlink), because `claude plugin install` rewrites it when enabling plugins.
  # We seed it from the nix-derived template on first setup, and also migrate
  # away from any old read-only symlink left by previous generations.
  home.activation.installClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "installClaudeSettings" ''
    mkdir -p "$HOME/.claude"
    dst="$HOME/.claude/settings.json"
    src="${pkgs.writeText "claude-settings.json" ''
      {
        "$schema": "https://json.schemastore.org/claude-code-settings.json",
        "attribution": {
          "commit": "",
          "pr": ""
        },
        "permissions": {
          "defaultMode": "bypassPermissions"
        },
        "enabledPlugins": {
          "document-skills@anthropic-agent-skills": true
        },
        "alwaysThinkingEnabled": true,
        "skipDangerousModePermissionPrompt": true,
        "cleanupPeriodDays": 365,
        "hooks": {
          "Stop": [
            {
              "matcher": "",
              "hooks": [
                {
                  "type": "command",
                  "command": "printf '\\a' > /dev/tty; if command -v afplay >/dev/null 2>&1; then afplay /System/Library/Sounds/Hero.aiff & elif command -v paplay >/dev/null 2>&1; then paplay /usr/share/sounds/freedesktop/stereo/complete.oga & fi"
                }
              ]
            }
          ],
          "Notification": [
            {
              "matcher": "",
              "hooks": [
                {
                  "type": "command",
                  "command": "printf '\\a' > /dev/tty; if command -v osascript >/dev/null 2>&1; then osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'; elif command -v notify-send >/dev/null 2>&1; then notify-send 'Claude Code' 'Claude Code needs your attention'; fi"
                }
              ]
            }
          ]
        }
      }
    ''}"
    # Replace any stale read-only symlink from a previous nix generation.
    if [ -L "$dst" ]; then
      rm "$dst"
    fi
    # Seed from the nix template only if missing — preserve any in-place
    # modifications written by `claude plugin install` or the user.
    if [ ! -f "$dst" ]; then
      install -m 644 "$src" "$dst"
    fi
  '');

  # Global MCP servers for Claude Code (user scope → auto-trusted, no approval prompt)

  # Install user-scoped development CLIs only when missing. Claude Code's native
  # installation updates itself; repeatedly downloading every CLI made an otherwise
  # idempotent Home Manager switch slow and fragile. Set DOTFILES_FORCE_CLI_UPDATE=1
  # for an explicit refresh.
  home.activation.installDevCLIs = lib.hm.dag.entryAfter [ "npmPrefix" ] (resilient "installDevCLIs" ''
    set -e
    force_update="''${DOTFILES_FORCE_CLI_UPDATE:-0}"
    export npm_config_prefix="$HOME/.local"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/lib/node_modules"
    export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.nodejs_24}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$HOME/.local/bin:$PATH:/usr/bin"
    export TAR="${pkgs.gnutar}/bin/tar"
    NPM="${pkgs.nodejs_24}/bin/npm"
    if [ "$force_update" = 1 ] || [ ! -x "$HOME/.local/bin/claude" ]; then
      echo "[dotfiles] installing Claude Code (this may take a minute)..."
      claude_installed=0
      for _attempt in 1 2 3; do
        if curl -fsSL https://claude.ai/install.sh | bash -s --; then
          claude_installed=1
          break
        fi
        sleep 2
      done
      if [ "$claude_installed" -ne 1 ]; then
        echo "[dotfiles] claude install failed (network/region issue); skipping" >&2
      fi
    else
      echo "[dotfiles] Claude Code already present; skipping install"
    fi

    if [ "$force_update" = 1 ] || [ ! -x "$HOME/.local/bin/codex" ]; then
      "$NPM" i -g @openai/codex@latest --prefix "$HOME/.local" 2>&1 || true
    else
      echo "[dotfiles] Codex already present; skipping install"
    fi
    if [ "$force_update" = 1 ] || [ ! -x "$HOME/.local/bin/gemini" ]; then
      "$NPM" i -g --force @google/gemini-cli --prefix "$HOME/.local" 2>&1 || true
    else
      echo "[dotfiles] Gemini already present; skipping install"
    fi
    if [ "$force_update" = 1 ] || [ ! -x "$HOME/.local/bin/gws" ]; then
      "$NPM" i -g @googleworkspace/cli@latest --prefix "$HOME/.local" 2>&1 || true
    else
      echo "[dotfiles] Google Workspace CLI already present; skipping install"
    fi
  '');

  # Claude user-scoped MCP setup. Notion is launched through a wrapper that
  # reads the sops-managed token file itself, so zsh, fish, GUI, and tmux
  # sessions all get identical behavior without storing the secret in config.
  home.activation.configureClaudeMcp =
    lib.hm.dag.entryAfter [ "installDevCLIs" "linkGeneration" ] (resilient "configureClaudeMcp" ''
      marker="$HOME/.claude/.mcp-registered-v3"
      claude_bin="$HOME/.local/bin/claude"
      if [ -x "$claude_bin" ] && [ ! -f "$marker" ]; then
        mkdir -p "$HOME/.claude"
        if ! "$claude_bin" mcp get context7 >/dev/null 2>&1; then
          "$claude_bin" mcp add --scope user -t stdio context7 -- npx -y @upstash/context7-mcp
        fi

        "$claude_bin" mcp remove --scope user notion >/dev/null 2>&1 || true
        if "$claude_bin" mcp add --scope user -t stdio notion -- "$HOME/.local/bin/notion-mcp-wrapper"; then
          touch "$marker"
          echo "[dotfiles] configured Notion MCP through notion-mcp-wrapper"
        else
          echo "[dotfiles] failed to configure Notion MCP; will retry next switch" >&2
        fi
      fi
    '');

  home.file.".codex/notify_bell.sh".source = ../scripts/notify_bell.sh;

  # Codex config.toml MUST stay writable: codex persists runtime state
  # into it (for example per-project `trust_level`). A `home.file`
  # symlink points into the read-only /nix/store, so those writes fail with
  # "failed to persist config.toml". Instead we ship the declarative template
  # to a side path and, on activation, seed a real writable copy that codex
  # then owns. To re-seed after editing the template below, delete
  # ~/.codex/config.toml and re-run the switch.
  home.file.".codex/config.toml.hm-template".text = ''
    # Seeded from Home Manager template; codex owns this file at runtime.
    # model: gpt-5.6 family — sol (frontier) / terra (balanced) / luna (efficient); gpt-5.6 aliases to sol.
    model = "gpt-5.6-sol"
    # model_reasoning_effort: none | low | medium | high | xhigh | max (+ ultra for parallel subagents).
    model_reasoning_effort = "xhigh"
    # Run trusted local sessions without approval prompts or Codex's inner sandbox.
    approval_policy = "never"
    sandbox_mode = "danger-full-access"
    # web_search: cached (default, pre-indexed, safer) | live (fetches live pages).
    web_search = "live"
    notify = ["/usr/bin/env", "bash", "${config.home.homeDirectory}/.codex/notify_bell.sh"]

    [tui]
    # Ring after every completed agent turn, including while the terminal is focused.
    notifications = ["agent-turn-complete"]
    notification_method = "bel"
    notification_condition = "always"
    terminal_title = ["spinner", "thread-title"]

    [features]
    hooks = true
    plugins = true
    plugin_hooks = true

    [marketplaces.omem-local]
    source_type = "local"
    source = "${config.home.homeDirectory}/Projects/omem"

    [plugins."omem@omem-local"]
    enabled = true

    [plugins."omem@omem-local".mcp_servers.omem.tools.search_memory]
    approval_mode = "approve"

    [projects."${config.home.homeDirectory}/Projects/omem"]
    trust_level = "trusted"

    [mcp_servers.context7]
    command = "npx"
    args = ["-y", "@upstash/context7-mcp"]

  '';

  # Seed a writable ~/.codex/config.toml from the template above, but only when
  # it is absent or is a stale Home-Manager symlink into /nix/store. Once codex
  # owns a real file, leave it alone so runtime trust/hook writes persist.
  home.activation.seedCodexConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] (resilient "seedCodexConfig" ''
      cfg="${config.home.homeDirectory}/.codex/config.toml"
      tpl="${config.home.homeDirectory}/.codex/config.toml.hm-template"
      if [ ! -e "$cfg" ] || [ -L "$cfg" ]; then
        $DRY_RUN_CMD rm -f "$cfg"
        $DRY_RUN_CMD cp -f "$tpl" "$cfg"
        $DRY_RUN_CMD chmod 0644 "$cfg"
        echo "[dotfiles] seeded writable ~/.codex/config.toml from template"
      fi
    '');

  # The writable runtime config is intentionally not replaced after its first
  # seed, because Codex persists trust and hook state there. Keep just the TUI
  # notification keys in sync with the declarative template instead.
  home.activation.configureCodexTuiNotifications =
    lib.hm.dag.entryAfter [ "seedCodexConfig" ] (resilient "configureCodexTuiNotifications" ''
      cfg="${config.home.homeDirectory}/.codex/config.toml"
      if [ -f "$cfg" ]; then
        cfg_tmp="$cfg.tui-notifications"
        "${pkgs.gawk}/bin/awk" '
          function emit_missing_tui_settings() {
            if (!seen_notifications)
              print "notifications = [\"agent-turn-complete\"]"
            if (!seen_notification_method)
              print "notification_method = \"bel\""
            if (!seen_notification_condition)
              print "notification_condition = \"always\""
          }

          BEGIN {
            in_tui = 0
            saw_tui = 0
          }

          /^\[tui\]$/ {
            saw_tui = 1
            in_tui = 1
            seen_notifications = 0
            seen_notification_method = 0
            seen_notification_condition = 0
            print
            next
          }

          /^\[/ {
            if (in_tui) {
              emit_missing_tui_settings()
              in_tui = 0
            }
            if (!saw_tui && /^\[tui\./) {
              print "[tui]"
              print "notifications = [\"agent-turn-complete\"]"
              print "notification_method = \"bel\""
              print "notification_condition = \"always\""
              print ""
              saw_tui = 1
            }
            print
            next
          }

          in_tui && /^[[:space:]]*notifications[[:space:]]*=/ {
            print "notifications = [\"agent-turn-complete\"]"
            seen_notifications = 1
            next
          }
          in_tui && /^[[:space:]]*notification_method[[:space:]]*=/ {
            print "notification_method = \"bel\""
            seen_notification_method = 1
            next
          }
          in_tui && /^[[:space:]]*notification_condition[[:space:]]*=/ {
            print "notification_condition = \"always\""
            seen_notification_condition = 1
            next
          }

          { print }

          END {
            if (in_tui) {
              emit_missing_tui_settings()
            } else if (!saw_tui) {
              print ""
              print "[tui]"
              print "notifications = [\"agent-turn-complete\"]"
              print "notification_method = \"bel\""
              print "notification_condition = \"always\""
            }
          }
        ' "$cfg" > "$cfg_tmp"
        chmod 0644 "$cfg_tmp"
        mv "$cfg_tmp" "$cfg"
      fi
    '');

  # Keep the real omem CLI and Codex plugin installed from the local omem
  # repository. Reinstall only when the repository revision changes, the binary/plugin
  # is missing, or DOTFILES_FORCE_CLI_UPDATE=1. Lifecycle hooks are machine-managed in
  # system/darwin.nix, so the plugin itself remains the MCP delivery bundle.
  home.activation.configureCodexOmem =
    lib.hm.dag.entryAfter [ "installDevCLIs" "seedCodexConfig" ] (resilient "configureCodexOmem" ''
      omem_repo="$HOME/Projects/omem"
      codex_bin="$HOME/.local/bin/codex"
      cfg="$HOME/.codex/config.toml"
      marker="$HOME/.local/state/dotfiles/omem-installed-rev"
      force_update="''${DOTFILES_FORCE_CLI_UPDATE:-0}"

      if [ -d "$omem_repo" ] && [ -x "$codex_bin" ]; then
        # The retired reproduction checkout is no longer a valid marketplace root and
        # makes every `codex plugin list` fail. Remove only that obsolete source.
        "$codex_bin" plugin marketplace remove codex-memory-repro >/dev/null 2>&1 || true

        revision="$("${pkgs.git}/bin/git" -C "$omem_repo" rev-parse HEAD 2>/dev/null || printf unknown)"
        installed_revision="$(cat "$marker" 2>/dev/null || true)"
        plugin_manifest="$("${pkgs.findutils}/bin/find" "$HOME/.codex/plugins/cache/omem-local/omem" \
          -mindepth 3 -maxdepth 3 -path '*/.codex-plugin/plugin.json' -print -quit 2>/dev/null || true)"
        needs_install=0
        if [ "$force_update" = 1 ] || [ ! -x "$HOME/.local/bin/omem" ] \
          || [ "$installed_revision" != "$revision" ] || [ -z "$plugin_manifest" ]; then
          needs_install=1
        fi

        if [ "$needs_install" -eq 1 ]; then
          echo "[dotfiles] installing real omem and Codex integration at $revision"
          if "${pkgs.uv}/bin/uv" tool install --reinstall "$omem_repo"; then
            "$codex_bin" plugin marketplace add "$omem_repo" >/dev/null 2>&1 || true
            if "$codex_bin" plugin add omem@omem-local; then
              mkdir -p "$(dirname "$marker")"
              printf '%s\n' "$revision" > "$marker"
            else
              echo "[dotfiles] failed to install omem Codex plugin; will retry next switch" >&2
            fi
          else
            echo "[dotfiles] failed to install omem CLI; will retry next switch" >&2
          fi
        else
          echo "[dotfiles] omem $revision already installed; skipping reinstall"
        fi

        if [ -f "$cfg" ]; then
          cfg_tmp="$cfg.omem-migration"
          "${pkgs.gawk}/bin/awk" '
            BEGIN { old_plugin = 0 }
            /^\[plugins\."codex-memory-reproduction@codex-memory-repro"\]$/ {
              old_plugin = 1
              print
              next
            }
            /^\[/ { old_plugin = 0 }
            old_plugin && /^enabled[[:space:]]*=[[:space:]]*true$/ {
              print "enabled = false"
              next
            }
            { print }
          ' "$cfg" > "$cfg_tmp"
          chmod 0644 "$cfg_tmp"
          mv "$cfg_tmp" "$cfg"

          if ! grep -Fqx '[plugins."omem@omem-local".mcp_servers.omem.tools.search_memory]' "$cfg"; then
            cat >> "$cfg" <<'TOML'

[plugins."omem@omem-local".mcp_servers.omem.tools.search_memory]
approval_mode = "approve"
TOML
          fi

        fi
      else
        echo "[dotfiles] $omem_repo or codex missing; skipping omem integration" >&2
      fi
    '');

  # Ensure Cursor remote terminals default to Nix-provided fish shell.
  home.file.".cursor-server/data/Machine/settings.json".text =
    builtins.toJSON {
      "terminal.integrated.profiles.linux" = {
        "fish-nix" = {
          path = "${config.home.homeDirectory}/.nix-profile/bin/fish";
          args = [ "--login" ];
        };
      };
      "terminal.integrated.defaultProfile.linux" = "fish-nix";
    } + "\n";

  # Mirror the same logic for VS Code Remote Server.
  home.file.".vscode-server/data/Machine/settings.json".text =
    builtins.toJSON {
      "terminal.integrated.profiles.linux" = {
        "fish-nix" = {
          path = "${config.home.homeDirectory}/.nix-profile/bin/fish";
          args = [ "--login" ];
        };
      };
      "terminal.integrated.defaultProfile.linux" = "fish-nix";
    } + "\n";

}
