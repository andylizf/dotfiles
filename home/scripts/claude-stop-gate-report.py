#!/usr/bin/env python3
"""What the stop gate has been doing, and whether every Stop hook still runs.

Reads the gate's own log for rates, latency and cost, then checks each hook
wired into settings.json — a hook that stops working leaves no trace anywhere
else, so this is the only place omem's stash/extract or the awake manager
going missing would show up.

  stop-gate-report.py            last 24h
  stop-gate-report.py --days 7   last 7 days
  stop-gate-report.py --hooks    hook health only
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

LOGS = [
    Path.home() / "Projects" / "MyClaw" / "logs" / "stop-gate.jsonl",
    Path.home() / "Projects" / "MyClaw" / "logs" / "stop-gate.jsonl.1",
    Path.home() / ".claude" / "stop-gate.jsonl",
]
SETTINGS = Path.home() / ".claude" / "settings.json"
GATE = Path.home() / ".claude" / "stop-gate.py"
USD_PER_JUDGEMENT = 0.001  # DeepSeek, ~1k tokens in and 4 out
SKIP_ALARM = 0.20
QUIET_ALARM_HOURS = 6


def read(since):
    rows = []
    for path in LOGS:
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            try:
                row = json.loads(line)
            except ValueError:
                continue
            if row.get("at", "") >= since:
                rows.append(row)
    return rows


def percentile(values, fraction):
    if not values:
        return None
    values = sorted(values)
    return values[min(len(values) - 1, int(len(values) * fraction))]


def gate_report(hours):
    since = (datetime.now().astimezone() - timedelta(hours=hours)).isoformat(timespec="seconds")
    rows = read(since)
    window = f"最近 {hours} 小时" if hours <= 48 else f"最近 {hours // 24} 天"
    print(f"=== 闸的动静（{window}）===")
    if not rows:
        print("  这段时间一条记录都没有 —— 要么没人用，要么闸没在跑（见下面的体检）")
        return

    turns = len(rows)
    judged = [r for r in rows if r["verdict"] in ("OK", "HANDBACK")]
    blocked = [r for r in rows if r["verdict"] == "HANDBACK"]
    skipped = [r for r in rows if r["verdict"] == "skipped"]
    took = [r["took_s"] for r in judged if r.get("took_s")]

    print(f"  轮次结束 {turns} 次 | 快筛命中 {len(judged) + len(skipped)} 次"
          f"（{(len(judged) + len(skipped)) / turns:.0%}）| 拦 {len(blocked)} | 放 {len(judged) - len(blocked)}"
          f" | 判官没答上 {len(skipped)}")
    if took:
        print(f"  判官耗时 中位 {percentile(took, 0.5):.2f}s，95 分位 {percentile(took, 0.95):.2f}s"
              f" | 这段时间花了约 ${len(judged) * USD_PER_JUDGEMENT:.2f}")

    markers = {}
    for row in judged + skipped:
        markers[row.get("marker", "?")] = markers.get(row.get("marker", "?"), 0) + 1
    if markers:
        top = sorted(markers.items(), key=lambda kv: -kv[1])[:6]
        print("  命中最多的词: " + "，".join(f"{k} {v}" for k, v in top))

    if blocked:
        print("  最近拦下的:")
        for row in blocked[-5:]:
            where = (row.get("cwd") or "?").split("/")[-1]
            tail = (row.get("tail") or "").replace("\n", " ")[-90:]
            print(f"    {row['at'][11:16]}  {where:22} …{tail}")

    alarms = []
    if skipped and len(skipped) / max(1, len(judged) + len(skipped)) > SKIP_ALARM:
        reasons = {r.get("why") for r in skipped}
        alarms.append(f"判官失败率 {len(skipped) / (len(judged) + len(skipped)):.0%}（{', '.join(sorted(reasons))}）")
    newest = max(r["at"] for r in rows)
    quiet = (datetime.now().astimezone() - datetime.fromisoformat(newest)).total_seconds() / 3600
    if quiet > QUIET_ALARM_HOURS:
        alarms.append(f"最后一条记录在 {quiet:.0f} 小时前 —— 闸可能没在跑")
    print("  健康: " + ("正常" if not alarms else "⚠ " + "；⚠ ".join(alarms)))


def executable_of(command):
    """The file a hook command would actually run, or None for inline shell."""
    first = command.strip().split()[0]
    if any(c in command for c in ";|&") and not first.startswith(("~", "/")):
        return None
    path = Path(os.path.expanduser(first))
    if path.is_absolute() or str(path).startswith(str(Path.home())):
        return path if path.exists() else False
    found = shutil.which(first)
    return Path(found) if found else False


def hook_report():
    print("=== 每个 hook 还在不在（settings.json 里配的）===")
    try:
        settings = json.loads(SETTINGS.read_text())
    except (OSError, ValueError) as error:
        print(f"  读不到 {SETTINGS}: {error}")
        return
    for event, entries in (settings.get("hooks") or {}).items():
        for entry in entries:
            for hook in entry.get("hooks", []):
                command = hook.get("command", "")
                target = executable_of(command)
                if target is None:
                    state = "内联 shell，无文件可查"
                elif target is False:
                    state = "❌ 找不到这个文件/命令"
                else:
                    state = f"✅ {target}"
                print(f"  {event:18} {command.strip()[:46]:48} {state}")

    print("=== 关键 hook 实跑一次 ===")
    probes = [
        ("闸（空跑，不该拦）", [str(GATE)], '{"last_assistant_message":"报告如上，已提交。","stop_hook_active":false}'),
        ("omem 的 hook 还能跑", ["omem", "hook", "--help"], None),
    ]
    for name, argv, payload in probes:
        if not shutil.which(argv[0]) and not Path(argv[0]).exists():
            print(f"  {name:22} ❌ 装都没装")
            continue
        started = time.monotonic()
        try:
            done = subprocess.run(argv, input=payload, capture_output=True, text=True, timeout=30)
            took = time.monotonic() - started
            mark = "✅" if done.returncode == 0 else f"❌ exit={done.returncode}"
            note = (done.stdout or done.stderr or "").strip().splitlines()
            print(f"  {name:22} {mark} {took:.2f}s  {note[0][:60] if note else ''}")
        except subprocess.TimeoutExpired:
            print(f"  {name:22} ❌ 30s 没返回")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, help="看几天，默认看 24 小时")
    parser.add_argument("--hooks", action="store_true", help="只做 hook 体检")
    args = parser.parse_args()
    if not args.hooks:
        gate_report(args.days * 24 if args.days else 24)
        print()
    hook_report()
    return 0


if __name__ == "__main__":
    sys.exit(main())
