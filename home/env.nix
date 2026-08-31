# Environment variables, defined once and emitted for every shell.
#
# These used to live only in `programs.fish.shellInit`, which meant they existed
# only where fish is the login shell. A machine whose login shell is zsh never
# got any of them, and neither did anything started by launchd or over SSH —
# precisely the contexts automation runs in. The symptom is never "the variable
# is missing"; it is a tool falling back to some other credential path and
# failing much later, somewhere unrelated.
#
# So the values are declared here as data, and rendered into both fish and POSIX
# sh. Adding a variable in one place gets it everywhere; there is no second copy
# to forget.
{ config, pkgs, lib, ... }:

let
  inherit (lib) concatStringsSep mapAttrsToList;
  cfg = config.dotfilesEnv;

  # Plain values, no condition.
  staticVars = {
    CLAUDE_CODE_USE_VERTEX = "0";
    ANTHROPIC_VERTEX_PROJECT_ID = "llm-retrieval-403823";
    ANTHROPIC_MODEL = "opus[1m]";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-sonnet-4-6";

    # gws encrypts its token cache with a key from either the OS keyring or a
    # local file. The keyring cannot be unlocked without a GUI session, so over
    # SSH or under launchd gws fails to read what it wrote -- and for the
    # credential file it does not report that, it DELETES it. Pinning the file
    # backend everywhere keeps one behaviour on every host and in every context.
    GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND = "file";

    # Claude Code's Bash tool runs only bash or zsh. A login shell it does not
    # recognise (fish here) is silently replaced by zsh, while the model is still
    # told the login shell's name -- so it writes commands for a shell that is not
    # the one executing them. Pinning the tool's shell does not change what the
    # model is told, but it removes the expensive half of that mismatch: zsh
    # aborts the whole command when an unquoted glob matches nothing, so
    # `grep --include=*.py ...` never runs at all, while bash passes the pattern
    # through to the program that was meant to expand it.
    CLAUDE_CODE_SHELL = "${pkgs.bash}/bin/bash";
  };

  # VAR -> path under ~/.config; the file's trimmed contents become the value.
  # Absent file means the variable is simply not set.
  tokenFiles = {
    HF_TOKEN = "huggingface/token";
    OPENAI_API_KEY = "openai/token";
    CF_ACCESS_CLIENT_ID = "cloudflare/client-id";
    CF_ACCESS_CLIENT_SECRET = "cloudflare/client-secret";
    CLOUDFLARE_API_TOKEN = "cloudflare/api-token";
    VERCEL_TOKEN = "vercel/token";
    WANDB_API_KEY = "wandb/token";
  };

  # VAR -> path under ~/.config; the PATH itself is the value, not the contents.
  pathVars = {
    # Point gws at the sops-deployed credential rather than the copy it writes
    # for itself, so every host shares one rotation instead of each drifting on
    # its own schedule.
    #
    # A host that has not redeployed since the secret was last rotated still
    # carries the old snapshot, and pointing gws at a stale one swaps a working
    # credential for a dead one -- seen on 2026-08-29, where one machine held a
    # valid refresh token and another a revoked one, and forcing the override
    # there broke a calendar sync that had been fine. That is a stale-deploy
    # symptom, not a reason to avoid the shared credential: redeploying restored
    # it, after which the secret refreshed successfully and the calendar sync
    # ran clean. Rotate the secret and every host needs a deploy, as with any
    # other secret here.
    GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE = "gws/credentials.json";
  };

  # ---- renderers ------------------------------------------------------------
  fishStatic = concatStringsSep "\n"
    (mapAttrsToList (k: v: ''set -gx ${k} "${v}"'') staticVars);
  shStatic = concatStringsSep "\n"
    (mapAttrsToList (k: v: ''export ${k}="${v}"'') staticVars);

  fishTokens = concatStringsSep "\n" (mapAttrsToList (k: p: ''
    if test -f ~/.config/${p}
      set -gx ${k} (string trim (cat ~/.config/${p}))
    end'') tokenFiles);
  # `tr -d` rather than parameter-expansion trimming: these files hold
  # single-line secrets with no internal whitespace, so this is both correct and
  # readable, and it survives being embedded in a Nix string without a stack of
  # escapes that are easy to get subtly wrong.
  shTokens = concatStringsSep "\n" (mapAttrsToList (k: p: ''
    [ -f "$HOME/.config/${p}" ] && export ${k}="$(tr -d "[:space:]" < "$HOME/.config/${p}")"'') tokenFiles);

  fishPaths = concatStringsSep "\n" (mapAttrsToList (k: p: ''
    if test -f ~/.config/${p}
      set -gx ${k} ~/.config/${p}
    end'') pathVars);
  shPaths = concatStringsSep "\n" (mapAttrsToList (k: p: ''
    [ -f "$HOME/.config/${p}" ] && export ${k}="$HOME/.config/${p}"'') pathVars);

  # ---- cases that are not a simple mapping ----------------------------------
  # Claude Code OAuth token: ONLY on machines that are not the user's own Macs.
  #
  # This is gated on the machine's ROLE, not on its platform. The CLI prefers an
  # env token unconditionally over locally stored credentials, so on a machine
  # that authenticates by real login the env token shadows the good credential,
  # which is then never refreshed and gets cleared when it expires. That failure
  # is silent and only shows up as an agent that stopped working weeks ago.
  # Reading `uname` would give the right answer today purely by coincidence, and
  # the wrong one the first time a personal Linux box appears.
  fishClaudeToken = lib.optionalString (!cfg.myMachine) ''
    if test -f ~/.config/anthropic/claude-oauth-token
      set -gx CLAUDE_CODE_OAUTH_TOKEN (string trim (cat ~/.config/anthropic/claude-oauth-token))
    end'';
  shClaudeToken = lib.optionalString (!cfg.myMachine) ''
    [ -f "$HOME/.config/anthropic/claude-oauth-token" ] && \
      export CLAUDE_CODE_OAUTH_TOKEN="$(tr -d "[:space:]" < "$HOME/.config/anthropic/claude-oauth-token")"'';

  # Gemini: one file, two variables; the fallback must not clobber an existing one.
  fishGemini = ''
    if test -f ~/.config/gemini/token
      set -l _gemini (string trim (cat ~/.config/gemini/token))
      if test -n "$_gemini"
        set -gx GOOGLE_API_KEY "$_gemini"
        if not set -q GEMINI_API_KEY
          set -gx GEMINI_API_KEY "$_gemini"
        end
      end
    end'';
  shGemini = ''
    if [ -f "$HOME/.config/gemini/token" ]; then
      _gemini="$(tr -d "[:space:]" < "$HOME/.config/gemini/token")"
      if [ -n "$_gemini" ]; then
        export GOOGLE_API_KEY="$_gemini"
        [ -n "''${GEMINI_API_KEY:-}" ] || export GEMINI_API_KEY="$_gemini"
      fi
      unset _gemini
    fi'';

  # Lambda Labs: 'default' -> LAMBDA_API_KEY, any other profile -> LAMBDA_API_KEY_<NAME>.
  fishLambda = ''
    for f in ~/.config/lambda/*
      if test -f $f
        set -l profile_name (basename $f)
        set -l token_value (string trim (cat $f))
        if test -n "$token_value"
          if test "$profile_name" = "default"
            set -gx LAMBDA_API_KEY "$token_value"
          else
            set -gx "LAMBDA_API_KEY_"(string upper $profile_name) "$token_value"
          end
        end
      end
    end'';
  shLambda = ''
    for f in "$HOME"/.config/lambda/*; do
      [ -f "$f" ] || continue
      _p="$(basename "$f")"
      _v="$(tr -d "[:space:]" < "$f")"
      [ -n "$_v" ] || continue
      if [ "$_p" = "default" ]; then
        export LAMBDA_API_KEY="$_v"
      else
        export "LAMBDA_API_KEY_$(printf '%s' "$_p" | tr '[:lower:]' '[:upper:]')=$_v"
      fi
    done
    unset f _p _v'';

  # Nix: a GitHub token lifts the API rate limit from 60/h to 5000/h. Without it
  # a deploy behind a shared exit IP hits 403 and looks like a broken network.
  fishNixConfig = ''
    if command -q gh
      set -l _gh (gh auth token 2>/dev/null)
      if test -n "$_gh"
        set -gx NIX_CONFIG "access-tokens = github.com=$_gh"
      end
    end'';
  shNixConfig = ''
    if command -v gh >/dev/null 2>&1; then
      _gh="$(gh auth token 2>/dev/null)"
      [ -n "$_gh" ] && export NIX_CONFIG="access-tokens = github.com=$_gh"
      unset _gh
    fi'';

  fishBody = concatStringsSep "\n\n" [
    fishStatic fishTokens fishPaths fishClaudeToken fishGemini fishLambda fishNixConfig
  ];
  shBody = concatStringsSep "\n\n" [
    shStatic shTokens shPaths shClaudeToken shGemini shLambda shNixConfig
  ];

in {
  options.dotfilesEnv = {
    fishInit = lib.mkOption {
      type = lib.types.lines;
      internal = true;
      default = "";
      description = "Rendered fish form of the shared environment, spliced into programs.fish.";
    };

    myMachine = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isDarwin;
      description = ''
        Whether this host is one of the user's own machines (laptop, always-on
        mini) rather than a server. Governs credential shape, not packages: a
        personal machine authenticates by real login and must NOT receive an
        env-var token that would shadow it, while a server has no login session
        and needs one. Defaults to isDarwin, which happens to be the current
        split; set it explicitly from the site flake when that stops holding.
      '';
    };
  };

  config = {
    # Rendered for POSIX shells. zsh reads it via ~/.zshenv (below), and any
    # launchd job can `. ~/.config/dotfiles/env.sh` to get the same set --
    # launchd is not a shell and inherits nothing on its own.
    home.file.".config/dotfiles/env.sh".text = ''
      # Generated by home/env.nix -- do not edit.
      # Sourced by ~/.zshenv, and available for launchd jobs to source explicitly.
      ${shBody}
    '';

    # Taking over ~/.zshenv means anything a machine had put there by hand is
    # gone at the next deploy. Two things guard against that: the toolchain
    # sources known to live here are re-sourced explicitly, and ~/.zshenv.local
    # is read at the end so a host can keep something of its own without having
    # to fight the generated file.
    home.file.".zshenv".text = ''
      # Generated by home/env.nix -- do not edit.
      # Machine-specific additions belong in ~/.zshenv.local (sourced below).
      export PATH="$HOME/.local/bin:$PATH"

      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      [ -f "$HOME/.config/dotfiles/env.sh" ] && . "$HOME/.config/dotfiles/env.sh"

      [ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"
    '';

    # Exposed so common.nix can splice the same data into fish.
    dotfilesEnv.fishInit = fishBody;
  };
}
