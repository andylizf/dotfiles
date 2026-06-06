#!/usr/bin/env -S uv run --with cryptography --script
"""Strip refreshToken from a lark-cli user-token .enc so readers can't refresh
(and thus can't break the writer's single-use refresh chain).
Usage: lark-strip-refresh.py <master.key.file> <in.enc> <out.enc>
"""
import sys, json, os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

key = open(sys.argv[1], "rb").read()
blob = open(sys.argv[2], "rb").read()
d = json.loads(AESGCM(key).decrypt(blob[:12], blob[12:], None))
d["refreshToken"] = ""
d["refreshExpiresAt"] = 0
pt = json.dumps(d, ensure_ascii=False).encode()
iv = os.urandom(12)
out = iv + AESGCM(key).encrypt(iv, pt, None)
open(sys.argv[3], "wb").write(out)
