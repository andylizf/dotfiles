{ pkgs, lib, config, ... }:
{
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
    nodejs_22
    direnv
    ripgrep
    python312Packages.huggingface-hub
  ];

  # Ensure ~/.local/bin is in PATH for user-managed tools if needed
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.fish = {
    enable = true;
    shellInit = ''
      # Anthropic API key (for Claude CLI, etc.)
      if test -f ~/.config/anthropic/token
        set -gx ANTHROPIC_API_KEY (string trim (cat ~/.config/anthropic/token))
      end

      # Claude Code OAuth token (for Linux headless — macOS uses Keychain which auto-refreshes)
      if test (uname) != Darwin; and test -f ~/.config/anthropic/claude-oauth-token
        set -gx CLAUDE_CODE_OAUTH_TOKEN (string trim (cat ~/.config/anthropic/claude-oauth-token))
      end

      # Claude Code env flags
      set -gx CLAUDE_CODE_USE_VERTEX 0
      set -gx ANTHROPIC_VERTEX_PROJECT_ID llm-retrieval-403823
      set -gx ANTHROPIC_MODEL "opus[1m]"
      set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL claude-sonnet-4-6
      # set -gx ANTHROPIC_DEFAULT_SONNET_MODEL claude-opus-4-6
      if test -f ~/.config/huggingface/token
        set -gx HF_TOKEN (string trim (cat ~/.config/huggingface/token))
      end

      # OpenAI: export OPENAI_API_KEY if present
      if test -f ~/.config/openai/token
        set -gx OPENAI_API_KEY (string trim (cat ~/.config/openai/token))
      end

      # Cloudflare Access service token (CF-Access-Client-Id / Secret)
      if test -f ~/.config/cloudflare/client-id
        set -gx CF_ACCESS_CLIENT_ID (string trim (cat ~/.config/cloudflare/client-id))
      end
      if test -f ~/.config/cloudflare/client-secret
        set -gx CF_ACCESS_CLIENT_SECRET (string trim (cat ~/.config/cloudflare/client-secret))
      end

      # Cloudflare API token (scoped, for wrangler/terraform/CLI)
      if test -f ~/.config/cloudflare/api-token
        set -gx CLOUDFLARE_API_TOKEN (string trim (cat ~/.config/cloudflare/api-token))
      end

      # Vercel: export VERCEL_TOKEN if present
      if test -f ~/.config/vercel/token
        set -gx VERCEL_TOKEN (string trim (cat ~/.config/vercel/token))
      end

      # Notion: export NOTION_TOKEN (consumed by the Notion MCP server via ''${NOTION_TOKEN})
      if test -f ~/.config/notion/token
        set -gx NOTION_TOKEN (string trim (cat ~/.config/notion/token))
      end

      # Google Workspace CLI (gws): point at sops-managed credentials
      if test -f ~/.config/gws/credentials.json
        set -gx GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE ~/.config/gws/credentials.json
      end

      # Codex auth.json: seed from sops on Linux if not already present
      if test (uname) != Darwin; and test -f ~/.config/sops-nix/codex-auth.json; and not test -f ~/.codex/auth.json
        mkdir -p ~/.codex
        cp ~/.config/sops-nix/codex-auth.json ~/.codex/auth.json
        chmod 600 ~/.codex/auth.json
      end

      # Weights & Biases: export WANDB_API_KEY if present
      if test -f ~/.config/wandb/token
        set -gx WANDB_API_KEY (string trim (cat ~/.config/wandb/token))
      end

      # Gemini: export GOOGLE_API_KEY (and GEMINI_API_KEY fallback) if present
      if test -f ~/.config/gemini/token
        set -l _GEMINI_TOKEN (string trim (cat ~/.config/gemini/token))
        if test -n "$_GEMINI_TOKEN"
          set -gx GOOGLE_API_KEY "$_GEMINI_TOKEN"
          if not set -q GEMINI_API_KEY
            set -gx GEMINI_API_KEY "$_GEMINI_TOKEN"
          end
        end
      end

      # Lambda Labs Cloud API (multiple profiles)
      # 'default' → LAMBDA_API_KEY, others → LAMBDA_API_KEY_<NAME>
      for f in ~/.config/lambda/*
        if test -f $f
          set -l profile_name (basename $f)
          set -l token_value (string trim (cat $f))
          if test -n "$token_value"
            if test "$profile_name" = "default"
              set -gx LAMBDA_API_KEY "$token_value"
            else
              set -l var_name "LAMBDA_API_KEY_"(string upper $profile_name)
              set -gx $var_name "$token_value"
            end
          end
        end
      end

      # Switch Lambda profile: lambda-use <profile>
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

      # Nix: use GitHub token for higher API rate limits (60/h → 5000/h)
      if command -q gh
        set -l _gh_token (gh auth token 2>/dev/null)
        if test -n "$_gh_token"
          set -gx NIX_CONFIG "access-tokens = github.com=$_gh_token"
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

      # Register Claude Code MCP servers at user scope (auto-trusted, no approval prompt).
      # Sentinel is versioned: bump the suffix when adding a server so machines that
      # already ran an earlier version re-run and pick up the new server(s).
      if command -q claude; and not test -f ~/.claude/.mcp-registered-v2
        claude mcp add --scope user -t stdio context7 -- npx -y @upstash/context7-mcp 2>/dev/null
        # Notion: token is expanded at launch from the NOTION_TOKEN env var (sops-managed),
        # so the literal ''${NOTION_TOKEN} is stored in config, never the secret itself.
        claude mcp add --scope user -t stdio notion -e NOTION_TOKEN=''\'''${NOTION_TOKEN}' -- npx -y @notionhq/notion-mcp-server 2>/dev/null
        touch ~/.claude/.mcp-registered-v2
      end

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


  home.activation.fixSshPerms = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh" || true
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys" || true
    PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOp3Vontmq0bBIlnQIeUFqk/UhwGSFm3f96MRdR2T6AQ andylizf@outlook.com'
    if ! grep -Fxq "$PUBKEY" "$HOME/.ssh/authorized_keys"; then
      printf '%s\n' "$PUBKEY" >> "$HOME/.ssh/authorized_keys"
    fi
  '';

  home.activation.ensureSshConfig = lib.hm.dag.entryAfter [ "fixSshPerms" ] ''
    if [ ! -f "$HOME/.ssh/config" ]; then
      touch "$HOME/.ssh/config"
      chmod 600 "$HOME/.ssh/config" || true
    fi
  '';

  # Optional: set npm global prefix to ~/.local (safer PATH)
  home.activation.npmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v npm >/dev/null 2>&1; then
      npm config set prefix "$HOME/.local" --global || true
      mkdir -p "$HOME/.local/bin"
    fi
  '';

  home.activation.ensureGcloudDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/gcloud"
    chmod 700 "$HOME/.config/gcloud" || true
  '';

  home.activation.ensureAwsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.aws"
    chmod 700 "$HOME/.aws" || true
  '';

  home.activation.ensureDockerConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.docker"
    chmod 700 "$HOME/.docker" || true
  '';

  # Ensure GNU readlink is used during activation (macOS BSD readlink lacks -e).
  home.activation.fixReadlink = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    readlink() {
      "${pkgs.coreutils}/bin/readlink" "$@"
    }
  '';

  # Sync Docker config from sops-nix secrets to ~/.docker/config.json
  # Docker Desktop cannot handle symlinks (cross-device link errors).
  # sops-nix stores secrets at ~/.config/sops-nix/secrets/<name>, not at custom paths.
  home.activation.syncDockerConfig = lib.hm.dag.entryAfter [ "ensureDockerConfigDir" ] ''
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
  '';

  home.activation.ensureAnthropicDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/anthropic"
    chmod 700 "$HOME/.config/anthropic" || true
  '';

  home.activation.ensureLambdaDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/lambda"
    chmod 700 "$HOME/.config/lambda" || true
  '';

  home.activation.ensureWandbDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/wandb"
    chmod 700 "$HOME/.config/wandb" || true
  '';

  home.activation.syncPypirc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
  '';

  home.activation.syncHuggingFaceToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.config/huggingface/token" ]; then
      mkdir -p "$HOME/.cache/huggingface"
      install -m 600 "$HOME/.config/huggingface/token" "$HOME/.cache/huggingface/token"
    fi
  '';

  home.activation.ensureOverleafConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/overleaf"
    chmod 700 "$HOME/.config/overleaf" || true
  '';

  home.activation.syncOverleafGitCredentials = lib.hm.dag.entryAfter [ "ensureOverleafConfigDir" ] ''
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
  '';

  home.file.".claude/CLAUDE.md".source = ../claude-instruction.md;

  # Claude Code settings.json must be a writable real file (not a nix-store
  # symlink), because `claude plugin install` rewrites it when enabling plugins.
  # We seed it from the nix-derived template on first setup, and also migrate
  # away from any old read-only symlink left by previous generations.
  home.activation.installClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
  '';

  # Global MCP servers for Claude Code (user scope → auto-trusted, no approval prompt)

  # Install/update CLI tools from npm to ~/.local on each switch.
  # Keep tracking npm latest while remaining user-scoped.
  home.activation.installDevCLIs = lib.hm.dag.entryAfter [ "npmPrefix" ] ''
    set -e
    export npm_config_prefix="$HOME/.local"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/lib/node_modules"
    export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.nodejs_22}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$HOME/.local/bin:$PATH:/usr/bin"
    export TAR="${pkgs.gnutar}/bin/tar"
    NPM="${pkgs.nodejs_22}/bin/npm"
    # Claude Code: install via official script (downloads ~60MB binary, may take a minute)
    echo "[dotfiles] installing Claude Code (this may take a minute)..."
    for _attempt in 1 2 3; do
      if curl -fsSL https://claude.ai/install.sh | bash -s --; then
        break
      fi
      sleep 2
    done || echo "[dotfiles] claude install failed (network/region issue); skipping"
    "$NPM" i -g @openai/codex@latest --prefix ~/.local 2>&1 || true
    "$NPM" i -g --force @google/gemini-cli --prefix ~/.local 2>&1 || true
    "$NPM" i -g @googleworkspace/cli@latest --prefix ~/.local 2>&1 || true
  '';

  home.file.".codex/notify_bell.sh".source = ../scripts/notify_bell.sh;

  home.file.".codex/config.toml".text = ''
    # Managed by Home Manager — local changes will be overwritten.
    model = "gpt-5.5"
    reasoning_effort = "extra_high"
    web_search = "live"
    check_for_update_on_startup = false
    notify = ["/usr/bin/env", "bash", "${config.home.homeDirectory}/.codex/notify_bell.sh"]

    [features]
    hooks = true
    plugins = true
    plugin_hooks = true

    [marketplaces.codex-memory-repro]
    source_type = "local"
    source = "${config.home.homeDirectory}/Projects/codex-memory-reproduce"

    [plugins."codex-memory-reproduction@codex-memory-repro"]
    enabled = true

    [projects."/Users/andyl/Projects/codex-memory-reproduce"]
    trust_level = "trusted"

    [hooks.state."codex-memory-reproduction@codex-memory-repro:hooks/hooks.json:pre_tool_use:0:0"]
    trusted_hash = "sha256:9d8b745dc3d71b2ca62a865e51cbca24c5ff57c824c713201866a85626e9b111"

    [hooks.state."codex-memory-reproduction@codex-memory-repro:hooks/hooks.json:post_tool_use:0:0"]
    trusted_hash = "sha256:202aca64974ccdd59e36c6eaba5c21001aa54a8799134f34773207cc5cd20b0d"

    [hooks.state."codex-memory-reproduction@codex-memory-repro:hooks/hooks.json:post_compact:0:0"]
    trusted_hash = "sha256:84b3a9c9cd1aff87de8d2ed3e111d69e8fd0770266a4fef6a6af74f179cb91a1"

    [hooks.state."codex-memory-reproduction@codex-memory-repro:hooks/hooks.json:user_prompt_submit:0:0"]
    trusted_hash = "sha256:a7d5c001fcbf7c9a85c3ebab31894bd559e28e2802f7cb854c74d5c5aeaf2668"

    [hooks.state."codex-memory-reproduction@codex-memory-repro:hooks/hooks.json:subagent_start:0:0"]
    trusted_hash = "sha256:0bcd1d7351843dfdfd41339bdd366953a0a71767256d893a5df83b7392d898ed"

    [hooks.state."codex-memory-reproduction@codex-memory-repro:hooks/hooks.json:subagent_stop:0:0"]
    trusted_hash = "sha256:72943dde20be870dd6b1e654b100a6fdbf4ea2b2337e99804bd6c7e6eaa089d7"

    [mcp_servers.context7]
    command = "npx"
    args = ["-y", "@upstash/context7-mcp"]

  '';

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
