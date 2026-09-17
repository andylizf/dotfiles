#!/usr/bin/env python3
"""Stop hook: catch a turn that ends by handing work back to Zhifei.

Two stages, so the common turn costs nothing: a string filter that only
lets through a message that looks like it is putting something to him,
then a DeepSeek call that judges whether that is one of the two stops
CLAUDE.md allows. Blocking costs one extra model round and never an
action, so this fails open everywhere — no key, no network, bad JSON,
slow reply all let the turn end.
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

ENV_FILE = Path.home() / "Projects" / "MyClaw" / ".env"
LOG_DIR = Path.home() / "Projects" / "MyClaw" / "logs"
LOG_FALLBACK = Path.home() / ".claude"
API_URL = "https://api.deepseek.com/chat/completions"
MODEL = "deepseek-chat"
API_TIMEOUT = 6.0
TAIL = 4000  # judge the end of the message, where the handback lives

# Stage 1. A turn that puts nothing to him matches none of these and costs
# no call. Written wide on purpose: a false match only buys a 1s judgement.
MARKERS = re.compile(
    r"要不要|要我|需要你|你想怎|你来定|你决定|你说一声|你回一句|你点头|等你|"
    r"你看要|你觉得呢|行不行|可以吗|好不好|我不自己动|请你|麻烦你|"
    r"want me to|should i\b|do you want|shall i\b|let me know|"
    r"which (one )?(do|would) you|your call|up to you|waiting (on|for) you",
    re.IGNORECASE,
)

JUDGE = """判断一个 agent 这一轮最后说的话，是不是把本该自己做的活退回给了用户 Zhifei。

先问：它在等的那样东西，是不是非 Zhifei 不可？
- 要花他的钱、要删不可恢复的东西、要对外发出去或提交、要他本人的密码或他本人点一下、只有他知道的事实 → 非他不可 → OK
- 一个走下去就不好回头的方向选择（不可逆，或者改回来代价很大）→ 非他不可 → OK
- 它只是在汇报做完的事，没有在等什么 → OK
- 它在回答 Zhifei 刚问的问题，末尾的问句不挡它继续干活 → OK
- Zhifei 自己的规矩要求这件事先问过他：改他的全局 CLAUDE.md 或他的 skill、发出去之前要他的确认令牌 → OK
- 它提的那件事不是这一轮被派来做的事：顺带想到的、留着下次的、或者干活时撞见的别处的毛病（别的系统、别的机器、后台自己的报错）→ OK。判据是「这一轮的任务是什么」，不是它听起来急不急、也不是它用了「要不要我」这种问法——哪怕它问的正是「要不要我去做」，只要那件事不是这一轮被派来做的，也放走：不问就跑去做，才是越界

其余都是 HANDBACK：
- 实现层面的选择（用哪个库、放哪个目录、先做哪件、怎么写）
- 它自己查得到、试得出来的事实
- 「要不要我继续」「要不要我装 X」「你想怎么处理」
- 一个先做了、他事后纠正也不会有任何损失的方案，却停下来等一句「行」
- 它把主线任务的下一步具体说出来了（该做什么、怎么做），然后这一轮就结束了、没有去做

例：
「脚本放 scripts/ 还是 tools/？你决定」→ HANDBACK
「缺个依赖，要不要我装？」→ HANDBACK
「一次判断约 0.001 美元，用哪把钥匙付，你说一声」→ OK
「A 方案会覆盖掉没有副本的旧配置，不可逆，要不要走 A？」→ OK
「这是对你全局 CLAUDE.md 的第三处改动，措辞如上，你回一个改我就落」→ OK
「（主线是评测结论）结论是要把并发从 500 提到 3500——要不要现在重跑一遍，这个我自己定：不跑」→ HANDBACK（主线的下一步说了没做）
「活干完了，报告如上。顺带一提那个旧备份目录要不要哪天清一清，跟这次没关系」→ OK（支线）
「（主线在改代码）报告如上。另外干活的时候一直在冒一个和这次无关的后台报错，要不要我去看看？」→ OK

只回一个词：HANDBACK 或 OK。

最后一段话：
---
%s
---"""

REASON = """Ending the turn here hands work back. Two stops are allowed: the step is not yours to take (only he can do or supply it — his approval alone is not that), or a direction only he can set. If it is one of those, or a confirmation he or a skill of his requires, say which in a clause and end again — this fires once. Otherwise do it yourself and carry on. An approval you are already waiting on still stands; this is not permission to proceed without it."""


MAX_LOG_BYTES = 5_000_000


def log(record):
    directory = LOG_DIR if LOG_DIR.is_dir() else LOG_FALLBACK
    path = directory / "stop-gate.jsonl"
    record["at"] = datetime.now().astimezone().isoformat(timespec="seconds")
    try:
        if path.exists() and path.stat().st_size > MAX_LOG_BYTES:
            path.replace(path.with_suffix(".jsonl.1"))
        with open(path, "a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, ensure_ascii=False) + "\n")
        os.chmod(path, 0o600)
    except OSError:
        pass


def api_key():
    key = os.environ.get("DPSK_KEY")
    if key:
        return key
    try:
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            if line.startswith("DPSK_KEY="):
                return line.split("=", 1)[1].strip().strip("'\"")
    except OSError:
        return None
    return None


def judge(message, key):
    body = json.dumps(
        {
            "model": MODEL,
            "max_tokens": 4,
            "temperature": 0,
            "messages": [{"role": "user", "content": JUDGE % message[-TAIL:]}],
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        API_URL,
        data=body,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=API_TIMEOUT) as response:
        payload = json.load(response)
    return payload["choices"][0]["message"]["content"].strip().upper()


def main():
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    if event.get("stop_hook_active"):
        return 0

    message = event.get("last_assistant_message") or ""
    hit = MARKERS.search(message[-TAIL:])
    if not hit:
        log({"verdict": "pass", "session": event.get("session_id"), "cwd": event.get("cwd")})
        return 0

    key = api_key()
    if not key:
        log({"verdict": "skipped", "why": "no DPSK_KEY", "marker": hit.group(0)})
        return 0

    started = time.monotonic()
    try:
        verdict = judge(message, key)
    except (urllib.error.URLError, OSError, KeyError, ValueError, TimeoutError) as error:
        log({"verdict": "skipped", "why": type(error).__name__, "marker": hit.group(0)})
        return 0
    took = round(time.monotonic() - started, 2)

    log(
        {
            "verdict": verdict,
            "took_s": took,
            "marker": hit.group(0),
            "session": event.get("session_id"),
            "cwd": event.get("cwd"),
            "tail": message[-300:],
        }
    )

    if verdict.startswith("HANDBACK"):
        # The JSON form blocks without the harness labelling it an error in his
        # terminal; the reason reaches the model either way, and the log below
        # is where a fire is read back from.
        print(json.dumps({"decision": "block", "reason": REASON, "suppressOutput": True}))
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
