# Troubleshooting

A log of real problems hit while bootstrapping these dotfiles, the root cause
of each, and the fix. Most of these only show up on restricted / China-based
networks (e.g. internal GPU boxes) where access to overseas hosts like
`cache.nixos.org`, `proxy.golang.org`, and `github.com` is slow or blocked.

The bootstrap has three independent network-sensitive phases, and each can fail
for a different reason:

1. Fetching prebuilt artifacts from the Nix binary cache (`nix-daemon`).
2. Building packages that download their own deps at build time (e.g. Go
   modules for `sops-install-secrets`).
3. Activating `system-manager`, which fetches its own flake inputs from GitHub.

---

## 1. Bootstrap hangs at "copying path ... from cache.nixos.org"

### Symptom

`Home Manager` activation prints something like:

```
copying path '/nix/store/...-source' from 'https://cache.nixos.org'...
```

and then hangs for many minutes with no progress. `nix-daemon` sits idle
(~0% CPU) blocked in `poll()`, with an ESTABLISHED but stalled TCP connection
to the Fastly CDN behind `cache.nixos.org`.

Confusingly, basic connectivity checks all pass:

```bash
curl -I https://cache.nixos.org           # HTTP 200, fast
curl -I https://github.com                 # HTTP 200, fast
```

### Root cause

It is **not** "the network is unstable." Small requests (TLS handshake, HEAD,
tiny files like `nix-cache-info`) complete instantly, which makes the network
look healthy. But **bulk downloads of large NARs stall**. Measured directly:

```bash
# A ~34 MB NAR from cache.nixos.org:
curl -o /dev/null -w '%{speed_download}\n' --max-time 25 \
  https://cache.nixos.org/nar/<hash>.nar.xz
# => ~42 KB/s, then effectively stalls (exit 28, timeout)
```

So `nix-daemon` opens the connection fine, then waits forever for bytes that
trickle in at ~42 KB/s. Total download is hundreds of MB, so it never finishes.

### Fix: use domestic binary-cache mirrors

Point Nix at a fast mirror. Benchmark of the same 34 MB NAR:

| Source                          | Result                         |
| ------------------------------- | ------------------------------ |
| `cache.nixos.org` (Fastly, intl) | ~42 KB/s, stalls               |
| `mirror.sjtu.edu.cn`            | ~1.1 MB/s                      |
| `mirrors.ustc.edu.cn`           | **~23 MB/s (full file in ~1.5s)** |

Add to `/etc/nix/nix.conf` (system-level; the daemon reads this, and a
non-trusted user's `--option substituters` is ignored), then
`sudo systemctl restart nix-daemon`:

```ini
substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
connect-timeout = 5
stalled-download-timeout = 20
fallback = true
```

Notes:

- Mirrors serve the exact same store paths and signatures as the official
  cache, so the `cache.nixos.org-1` public key still verifies them.
- Listing multiple mirrors + the official cache gives automatic failover. The
  USTC mirror occasionally returns HTTP 403 on `nix-cache-info` (transient
  rate-limiting); when it does, Nix briefly disables it and falls through to
  SJTU, then to the official cache.
- The short `connect-timeout` / `stalled-download-timeout` make Nix give up on
  a slow source quickly instead of hanging for the 300s default.

---

## 2. `sops-install-secrets` build fails: `proxy.golang.org` timeout

### Symptom

```
building '/nix/store/...-sops-install-secrets-0.0.1-go-modules.drv'...
go: downloading github.com/Mic92/ssh-to-age ...
Get "https://proxy.golang.org/...": dial tcp [2607:f8b0:400a:80c::2011]:443: connect: connection timed out
```

### Root cause

This package has no prebuilt artifact in the mirror, so it is **built locally**.
Its `go-modules` fixed-output derivation runs `go mod download`, which reaches
out to `proxy.golang.org` (Google-hosted, here resolved over IPv6) — that route
times out.

### Fix: domestic Go module proxy via `nix-daemon`

`buildGoModule`'s module-fetch derivation honors `GOPROXY` (it is in
`impureEnvVars`). But `nix-daemon` is a systemd service and does **not** inherit
your shell's environment, so exporting `GOPROXY` in a shell is not enough.

Set it on the daemon via a systemd drop-in
`/etc/systemd/system/nix-daemon.service.d/override.conf`:

```ini
[Service]
Environment="GOPROXY=https://goproxy.cn,direct"
# Optional: a corporate/HTTP proxy as a fallback for other overseas fetches.
# Keep domestic mirrors direct via no_proxy so large NARs are not proxied.
Environment="http_proxy=http://YOUR_PROXY:PORT"
Environment="https_proxy=http://YOUR_PROXY:PORT"
Environment="no_proxy=localhost,127.0.0.1,::1,mirrors.ustc.edu.cn,mirror.sjtu.edu.cn,goproxy.cn"
```

Then:

```bash
sudo systemctl daemon-reload && sudo systemctl restart nix-daemon
```

`goproxy.cn` serves byte-identical module zips, so the fixed-output hash still
matches. This alone fixes the build without needing any VPN.

---

## 3. `system-manager` aborts: "This OS is not currently supported"

### Symptom

`system-manager` downloads and builds its whole profile successfully, then
fails right at activation:

```
This OS is not currently supported.
Supported OSs are: nixos, ubuntu
Pre-activation assertion osVersion failed.
```

### Root cause

`system-manager` officially supports only NixOS and Ubuntu. On Debian (which
some target hosts run), the `osVersion` pre-activation assertion refuses to
proceed.

### Fix: `allowAnyDistro`

Already applied in this repo (`system/default.nix`):

```nix
config = {
  system-manager.allowAnyDistro = true;
};
```

This is the officially documented escape hatch. Debian is Ubuntu's upstream and
the modules used here (`/etc` files, systemd units, auditd rules) are
distro-agnostic, so it works in practice. Upstream still labels it
"unsupported / use at your own risk."

---

## 4. `system-manager` flake inputs time out fetching from GitHub

### Symptom

```
unable to download 'https://github.com/jfroche/userborn/archive/<rev>.tar.gz':
  Timeout was reached ... Operation too slow. Less than 1 bytes/sec ...
```

### Root cause

`setup.sh` activates system-manager with:

```bash
sudo env PATH="$PATH" nix run 'github:numtide/system-manager' -- switch --flake "."
```

`sudo env PATH="$PATH"` preserves only `PATH`, **not** proxy variables. Flake
*inputs* (`github:numtide/system-manager`, `github:jfroche/userborn`, ...) are
fetched by the root `nix` evaluator process, which then has no proxy and times
out on slow GitHub routes. (Binary-cache substitution is unaffected — that runs
in the already-configured `nix-daemon`.)

### Fix

Run that one step with proxy env preserved for the root evaluator, e.g.:

```bash
cd <dotfiles> && sudo env PATH="/nix/var/nix/profiles/default/bin:$PATH" \
  http_proxy=http://YOUR_PROXY:PORT https_proxy=http://YOUR_PROXY:PORT \
  no_proxy=localhost,127.0.0.1,::1,mirrors.ustc.edu.cn,mirror.sjtu.edu.cn,goproxy.cn \
  GOPROXY=https://goproxy.cn,direct \
  nix run 'github:numtide/system-manager' -- switch --flake "."
```

Once the inputs are fetched, they are cached in the Nix store and later runs no
longer need network for them. `setup.sh` is intentionally left unchanged here;
this is documented as a manual, environment-specific step.

---

## Quick reference: machine-level changes (not in this repo)

These live on the host, not in the flake, so they are not version-controlled:

- `/etc/nix/nix.conf` — domestic substituter mirrors (problem 1).
- `/etc/systemd/system/nix-daemon.service.d/override.conf` — `GOPROXY` and
  optional HTTP proxy for the daemon (problem 2).

Apply them once per machine, then `sudo systemctl daemon-reload && sudo
systemctl restart nix-daemon`.
