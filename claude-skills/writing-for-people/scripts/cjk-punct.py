#!/usr/bin/env python3
"""Flag (and optionally fix) half-width punctuation sitting inside Chinese prose.

Why this exists: models emit ASCII `,` `:` `"` `(` in Chinese text because
full-width punctuation is poorly placed in the tokenizer vocabulary, not
because anyone chose that style. A human typing Chinese gets full-width by
default -- producing half-width takes an extra IME switch. So the artifact is
below the level of intent and eyeballing does not catch it reliably; count it.

Protected spans are never touched or reported: fenced code blocks, inline
code, URLs, markdown link targets, and HTML/XML tags. A mark is judged by the
text on its two sides: only a Chinese neighbour makes it Chinese punctuation.
A quotation mark next to it says nothing about the language, so the colon in
`「attach a lane, then:」` stays half-width -- it closes an English clause.

Usage:
    cjk-punct.py FILE...            # report only
    cjk-punct.py --fix FILE...      # rewrite the unambiguous cases in place
"""

import argparse
import re
import sys

# CJK ideographs + CJK punctuation (、。《》「」…) + full-width forms (，：？！（）).
CJK = r"㐀-䶿一-鿿　-〿＀-￯‘’“”"
CJK_RE = re.compile(f"[{CJK}]")

# Unambiguous swaps: same meaning, only the width is wrong.
SIMPLE = {",": "，", ";": "；", ":": "：", "?": "？", "!": "！"}

# Paired marks depend on what they wrap: `(transformative use)` around English is
# correct, `(见上一节)` around Chinese is not. So pair them up and look inside,
# rather than flagging every bracket and drowning the report in false positives.
PAIRS = [
    (re.compile(r'"([^"\n]{0,200})"'), "“", "”"),
    (re.compile(r"\(([^()\n]{0,200})\)"), "（", "）"),
]

PROTECT_PATTERNS = [
    re.compile(r"```.*?```", re.S),          # fenced code
    re.compile(r"`[^`\n]*`"),                # inline code
    re.compile(r"https?://\S+"),             # bare URLs
    re.compile(r"\]\([^)\n]*\)"),            # markdown link targets
    re.compile(r"<[^<>\n]{1,80}>"),          # html/xml tags
    # YAML/frontmatter keys: `description: 中文…` must keep its ASCII colon or the
    # file stops parsing.
    re.compile(r"^[A-Za-z_][A-Za-z0-9_.-]*:", re.M),
    # 4-space indent is code only when there is no Chinese on the line -- inside a
    # markdown list the same indent is just a continuation of the prose.
    re.compile(rf"^ {{4,}}(?![^\n]*[{CJK}])\S[^\n]*$", re.M),
]

# Markup that sits between a mark and the Chinese it belongs to: `**粗体**：中文`
# still needs a full-width colon.
TRANSPARENT = "*_ "

# Quotation marks are in the CJK range but carry no language of their own. A
# mark next to one is judged as if that side were empty: `then:」` closes an
# English clause and keeps its colon; `用这个」: 因为` still gets a full-width one
# from the Chinese on its other side.
QUOTE_MARKS = "「」『』“”‘’"


def protected_mask(text):
    """Per-char mask: True where the position must not be inspected."""
    mask = [False] * len(text)
    for pat in PROTECT_PATTERNS:
        for m in pat.finditer(text):
            for i in range(m.start(), m.end()):
                mask[i] = True
    return mask


def near_cjk(text, i):
    """A half-width mark counts as an artifact only if it sits against Chinese."""
    for step in (-1, 1):
        j = i + step
        while 0 <= j < len(text) and text[j] in TRANSPARENT:
            j += step
        if 0 <= j < len(text) and text[j] not in QUOTE_MARKS and CJK_RE.match(text[j]):
            return True
    return False


def convert_pairs(text, do_fix):
    """Rewrite half-width pairs that wrap Chinese; leave the English ones alone.

    Pair-aware on purpose: swapping quote characters one at a time is how you
    end up with two opening quotes.
    """
    findings = []
    for pat, open_ch, close_ch in PAIRS:
        mask = protected_mask(text)
        # Only the brackets themselves must be unprotected -- `（含 `12:30`）` wraps an
        # inline code span and is still a Chinese paren pair.
        hits = [m for m in pat.finditer(text)
                if not mask[m.start()] and not mask[m.end() - 1]
                and CJK_RE.search(m.group(1))]
        if not hits:
            continue
        out, last = [], 0
        for m in hits:
            ln, col = line_col(text, m.start())
            findings.append((ln, col, m.group(0)[0] + "…" + m.group(0)[-1],
                             open_ch + "…" + close_ch, "fixed" if do_fix else "half-width"))
            if do_fix:
                out.append(text[last:m.start()])
                out.append(open_ch + m.group(1) + close_ch)
                last = m.end()
        if do_fix:
            out.append(text[last:])
            text = "".join(out)
    return text, findings


def line_col(text, idx):
    line = text.count("\n", 0, idx) + 1
    col = idx - (text.rfind("\n", 0, idx) + 1) + 1
    return line, col


def scan(path, do_fix):
    text = open(path, encoding="utf-8").read()
    original = text

    text, findings = convert_pairs(text, do_fix)

    mask = protected_mask(text)
    chars = list(text)
    for i, ch in enumerate(chars):
        if mask[i] or ch not in SIMPLE or not near_cjk(text, i):
            continue
        ln, col = line_col(text, i)
        if do_fix:
            chars[i] = SIMPLE[ch]
        findings.append((ln, col, ch, SIMPLE[ch], "fixed" if do_fix else "half-width"))

    if do_fix:
        text = "".join(chars)
        if text != original:
            open(path, "w", encoding="utf-8").write(text)

    findings.sort()
    for ln, col, got, want, note in findings:
        print(f"{path}:{ln}:{col}: {got} -> {want}  [{note}]")
    return findings


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="+")
    ap.add_argument("--fix", action="store_true",
                    help="rewrite the unambiguous cases in place (the , ; : ? ! marks and "
                         "bracket/quote pairs; full stops and ellipses are never touched)")
    args = ap.parse_args()

    total = 0
    for path in args.files:
        total += len(scan(path, args.fix))
    if total:
        verb = "rewrote/flagged" if args.fix else "found"
        print(f"\n{verb} {total} half-width mark(s) in Chinese text", file=sys.stderr)
    return 1 if total and not args.fix else 0


if __name__ == "__main__":
    sys.exit(main())
