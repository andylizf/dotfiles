#!/usr/bin/env python3
"""Make Claude Code accept cross-session messages on every local config home."""

from __future__ import annotations

import json
import os
import stat
from pathlib import Path


def config_paths(home: Path) -> list[Path]:
    paths = [home / ".claude" / "settings.json"]
    paths.extend(sorted(home.glob(".claude-*/settings.json")))
    return [path for path in paths if path.is_file()]


def update(path: Path) -> bool:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SystemExit(f"could not read Claude settings {path}: {error}") from error
    if not isinstance(data, dict):
        raise SystemExit(f"Claude settings must be a JSON object: {path}")
    if data.get("crossSessionInbound") == "accept":
        return False

    data["crossSessionInbound"] = "accept"
    mode = stat.S_IMODE(path.stat().st_mode)
    temporary = path.with_name(f".{path.name}.tmp-{os.getpid()}")
    try:
        temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)
    return True


def main() -> int:
    home = Path(os.environ.get("HOME", str(Path.home())))
    changed = [path for path in config_paths(home) if update(path)]
    for path in changed:
        print(f"[dotfiles] set crossSessionInbound=accept in {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
