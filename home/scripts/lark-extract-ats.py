#!/usr/bin/env -S uv run --with cryptography --script
"""Writer helper: decrypt every lark-cli user-token .enc and print "<app_id> <access_token>"
per line. Used to publish access-token strings to Bitwarden (readers inject them via
LARKSUITE_CLI_USER_ACCESS_TOKEN — no keychain/.enc/master.key needed on readers).
Usage: lark-extract-ats.py <master.key.file> <lark-cli-support-dir>
"""
import sys, json, re
from pathlib import Path
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

key = open(sys.argv[1], "rb").read()
supp = Path(sys.argv[2])
for enc in sorted(supp.glob("cli_*_ou_*.enc")):
    m = re.match(r"^(cli_[a-z0-9]+)_ou_", enc.name)
    if not m:
        continue
    app_id = m.group(1)
    try:
        blob = enc.read_bytes()
        d = json.loads(AESGCM(key).decrypt(blob[:12], blob[12:], None))
        at = d.get("accessToken", "")
        if at:
            print(f"{app_id} {at}")
    except Exception:
        pass
