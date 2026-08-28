# `slack` — every workspace you are signed into, from the command line

One command that reads and writes every Slack workspace the desktop app is
signed into, so an agent can reach Slack over a shell instead of running a
per-workspace MCP server. Pure Python 3 stdlib: no dependencies, no daemon, no
token store to keep fresh. Deployed to `~/.local/bin/slack`.

```
slack ls                                   workspaces
slack inbox [-w <ws>] [-m N]               unread everywhere, mentions and DMs first
slack channels <ws> [--all]                channels (--all includes ones you're not in)
slack dms <ws>                             direct messages
slack users <ws> [query]                   find people
slack read <ws> <#chan|@person|ID> [-n N]  recent messages
slack thread <ws> <target> <ts>            a thread's replies
slack search <ws|--all> <query...>         search, one workspace or all of them
slack send <ws> <target> <text> [--yes]    post — dry run unless --yes
slack whoami [<ws>]                        identity check
slack setup / slack refresh                credentials
```

`<ws>` is a substring of the domain or the team name. `--json` on any read
command gives machine-readable output.

## Sending is gated

`slack send` without `--yes` resolves the target, prints the exact text, and
posts nothing. **An agent runs `--yes` only after the user has seen that exact
text and approved it** — the standing rule for anything sent under their
identity, which Slack does not exempt. Draft, show, wait.

## How the credentials work

The desktop app holds one session cookie, `d` (`xoxd-…`), shared across every
workspace and valid for about a year. Everything else is derived from it at call
time:

- `https://app.slack.com/auth?app=client` with that cookie lists every workspace
  the session is signed into.
- `https://<domain>.slack.com/customize` with that cookie returns a page carrying
  a working `api_token` (`xoxc-…`) for that workspace.

So the only stored secret is the cookie, in `~/.config/slack-cli/cookie` (mode
600). Minted tokens are cached in `~/.config/slack-cli/cache.json` (also 600) and
re-minted automatically whenever Slack rejects one, so there is no expiry to
track and nothing to schedule.

`slack setup` decrypts the cookie out of the desktop app's Cookies DB using the
`Slack Safe Storage` key in the login Keychain (macOS prompts once; choose Always
Allow). On a machine without the desktop app — any Linux box included — pass the
value directly:

```
slack setup --cookie xoxd-...
```

That is all another machine needs, which is also the reason not to scatter it
around: the cookie alone is full read and write access to every workspace.

### The tool and the cookie are separate requirements

The tool is pure stdlib and reads no application data, so it installs on any host
regardless of whether Slack was ever there. What needs a signed-in Slack session
is producing the cookie once: `slack setup` reads the macOS desktop app, and a
browser session's `d` cookie works too when passed with `--cookie`. Once produced,
the cookie is a string — a host that has never had Slack is a full read-and-write
client the moment it receives one. So a machine can run the tool without Slack; it
cannot mint the first cookie without a Slack session somewhere.

## Why not the first-party integrations

Both are gated on being a workspace administrator, which a plain member is not:
Slack's own hosted MCP server (`mcp.slack.com/mcp`) is off by default and enters
a workspace only on explicit admin sign-off, and the Claude Slack app has to be
installed from the Marketplace by an admin. Both are also per-workspace. This
tool needs no admin anywhere and covers every workspace at once.

Session-token access is a personal-use technique, not a supported integration
path: it acts as your own account, on your own messages, and Slack can invalidate
the session at any time — the cost of that is re-running `slack setup`.

## Notes and limits

- Acts as your own account, so it sees exactly what you see: every channel you
  are in, every DM, and private channels.
- Reading does not mark anything read. `slack inbox` reports unread state without
  consuming it.
- Requests identify as the desktop app that minted the cookie — `setup` sniffs
  the installed app's own User-Agent from its logs, overridable with
  `SLACK_CLI_UA`. A browser-shaped agent on a desktop-app cookie reads as a new
  device and invites sign-in alerts.
- A workspace drops out of `slack ls` when its session is invalidated (a password
  change, or signing out on the desktop). Sign back in there and run
  `slack refresh`.
