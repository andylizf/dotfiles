#!/usr/bin/env python3
"""Run: python3 test_cjk_punct.py  (from any directory). Exercises --fix on a fixture."""
import pathlib
import subprocess
import sys
import tempfile

SCRIPT = pathlib.Path(__file__).with_name("cjk-punct.py")

CASES = [
    # (input line, expected line after --fix)
    # English quoted inside Chinese prose keeps its own marks.
    ("目标：约 1,000 词，开头一句「load the browser skill, attach a lane, then:」。",
     "目标：约 1,000 词，开头一句「load the browser skill, attach a lane, then:」。"),
    ("它问的是「can you say which answer you expect?」这个测试。",
     "它问的是「can you say which answer you expect?」这个测试。"),
    ("文档里写着“Bottom Line: never.”这一句。",
     "文档里写着“Bottom Line: never.”这一句。"),
    # A quotation with Chinese inside is Chinese prose and still gets fixed.
    ("他说「用 uv, 别用 pip」。", "他说「用 uv， 别用 pip」。"),
    # Plain Chinese prose outside any quotation is fixed as before.
    ("先定读者, 再去痕迹: 两步都要做?", "先定读者， 再去痕迹： 两步都要做？"),
    # Inline code and ASCII-quoted English were already protected and stay so.
    ("参数写成 `--wait-for domcontentloaded`, 不是别的。", "参数写成 `--wait-for domcontentloaded`， 不是别的。"),
    ('英文引文 "it counts, always" 保持原样。', '英文引文 "it counts, always" 保持原样。'),
    # A mark after a closing quote is judged by the Chinese on its other side.
    ("他说「ok」, 然后继续。", "他说「ok」， 然后继续。"),
    ("他说：「用这个」: 因为快。", "他说：「用这个」： 因为快。"),
    # A Chinese quotation's own mark is still Chinese.
    ("她问“真的吗?”然后走了。", "她问“真的吗？”然后走了。"),
]


def main():
    text = "\n".join(src for src, _ in CASES) + "\n"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
        f.write(text)
        path = f.name
    subprocess.run([sys.executable, str(SCRIPT), "--fix", path], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    got = pathlib.Path(path).read_text(encoding="utf-8").split("\n")
    failures = 0
    for (src, want), out in zip(CASES, got):
        status = "ok  " if out == want else "FAIL"
        if out != want:
            failures += 1
        print(f"{status} {src!r}\n     -> {out!r}" + ("" if out == want else f"\n     want {want!r}"))
    print(f"\n{len(CASES) - failures}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
