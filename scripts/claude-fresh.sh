#!/bin/sh
# Launch Claude Code with a clean environment.
#
# A `claude` started from inside another Claude Code session — the Bash tool, a
# subagent, a hook, a launchd job spawned from one — inherits the parent's
# harness variables. Two of them do real damage:
#
#   CLAUDE_CODE_CHILD_SESSION=1   The new session does not save a transcript.
#                                 It prints a one-line warning that scrolls away
#                                 immediately, and the conversation is gone when
#                                 the process exits.
#
#   ANTHROPIC_API_KEY (non-empty) Claude Code prefers the key over the Max
#                                 subscription, so the session is billed
#                                 pay-as-you-go, and Remote Control refuses to
#                                 start: `claude remote-control` errors out and
#                                 the `--remote-control` flag fails SILENTLY —
#                                 the session runs, RC never registers, nothing
#                                 reaches the phone, nothing lands in the logs.
#                                 (An empty value is fine; only a real key hurts.)
#
# The remaining CLAUDE_CODE_* variables pin the parent's session id, entrypoint
# and binary path onto the child. Strip the lot and exec the real binary.
#
# Deliberately NOT stripped: ANTHROPIC_MODEL, ANTHROPIC_DEFAULT_HAIKU_MODEL,
# CLAUDE_CODE_USE_VERTEX, ANTHROPIC_VERTEX_PROJECT_ID — those are real
# preferences set by this dotfiles repo, not harness leakage.
#
# Usage:
#   claude-fresh                                   # plain session
#   claude-fresh --resume <uuid> --remote-control 'name'
#
# Override the target binary with CLAUDE_REAL_BIN if it lives elsewhere.

CLAUDE="${CLAUDE_REAL_BIN:-$HOME/.local/bin/claude}"

if [ ! -x "$CLAUDE" ]; then
    # Fall back to PATH, but refuse to re-exec ourselves.
    resolved=$(command -v claude 2>/dev/null)
    case "$resolved" in
        ''|*claude-fresh)
            echo "claude-fresh: cannot find the real claude binary (tried $CLAUDE)" >&2
            exit 1
            ;;
        *)
            CLAUDE="$resolved"
            ;;
    esac
fi

exec env \
    -u CLAUDECODE \
    -u CLAUDE_CODE_CHILD_SESSION \
    -u CLAUDE_CODE_BRIDGE_SESSION_ID \
    -u CLAUDE_CODE_ENTRYPOINT \
    -u CLAUDE_CODE_ENVIRONMENT_KIND \
    -u CLAUDE_CODE_EXECPATH \
    -u CLAUDE_CODE_SESSION_ACCESS_TOKEN \
    -u CLAUDE_CODE_SESSION_ID \
    -u CLAUDE_CODE_WORKER_EPOCH \
    -u CLAUDE_EFFORT \
    -u CLAUDE_PID \
    -u ANTHROPIC_API_KEY \
    "$CLAUDE" "$@"
