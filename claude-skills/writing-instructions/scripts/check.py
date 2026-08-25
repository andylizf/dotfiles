#!/usr/bin/env python3
"""Flag the mechanical failures in an instruction file.

    python3 check.py path/to/SKILL.md [more files...]

Reports only what a regex can decide. Judgement calls -- whether a sentence
earns its place, whether an example is recognisable -- stay with the reader;
this handles the ones that are cheap to miss and cheap to check.
Exit status is 1 when anything is flagged, so it can gate a commit.
"""
import re, sys, os

POINTER = re.compile(
    r"\b(?:the (?:bullet|section|rule|paragraph|line|list|table|point) (?:above|below)"
    r"|(?:see|per) (?:the )?\w+(?: \w+)? (?:above|below)"
    r"|earlier in this file|further down|as (?:stated|noted|described) above"
    r"|that (?:line|point|rule)\b|those two\b"
    r"|,? below\.|,? above\.)", re.I)

HISTORY = re.compile(
    r"\b(?:not the principle|no longer|used to (?:be|say|read)|previously|formerly"
    r"|this (?:replaces|supersedes|corrects)|superseded|the earlier (?:rule|version|draft|framing)"
    r"|renamed from|has been (?:changed|moved|rewritten)|now reads|as of \d{4}"
    r"|he added(?: himself)?|added on \d{4}|in the session that)\b", re.I)

DATE = re.compile(r"\b(?:19|20)\d{2}[-/](?:0?[1-9]|1[0-2])[-/](?:0?[1-9]|[12]\d|3[01])\b")

HEDGE = re.compile(
    r"\b(?:the reason (?:this|it|the rule)|the reasoning behind|which is why (?:this|the rule)"
    r"|it is worth (?:explaining|noting) why|this is scoped|the alternative would"
    r"|the thinking here)\b", re.I)

CJK = re.compile(r"[一-鿿]")

QUOTED = re.compile(r"\*\*[^*\n]{1,120}\*\*|\*[^*\n]{1,120}\*|`[^`\n]{1,120}`")
SUPPRESS = re.compile(r"<!--\s*check:\s*ignore\s*-->")


def mask(line):
    """Blank out phrases the file is quoting as examples, so a rule against a
    phrasing is not flagged for naming the phrasing it bans."""
    if SUPPRESS.search(line):
        return ""
    return QUOTED.sub(lambda m: " " * len(m.group(0)), line)


def check(path):
    text = open(path, encoding="utf-8").read()
    lines = [mask(l) for l in text.split("\n")]
    flags = []

    for i, line in enumerate(lines, 1):
        for name, rx in (("pointer", POINTER), ("edit-history", HISTORY),
                         ("date", DATE), ("explains-the-route", HEDGE)):
            for m in rx.finditer(line):
                a = max(0, m.start() - 45)
                flags.append((i, name, m.group(0), line[a:m.end() + 45].strip()))

    # accretion: a top-level bullet trailed by indented paragraphs
    run = start = 0
    for i, line in enumerate(lines, 1):
        if line.startswith("- "):
            pass
        elif line.startswith("## ") or line.startswith("#"):
            run, start = 0, i
            continue
        if line.startswith("- "):
            if run >= 3:
                flags.append((start, "accretion", f"{run} indented blocks under one item",
                              "consider merging into one paragraph"))
            run, start = 0, i
        elif line.startswith("  ") and line.strip():
            run += 1
    if run >= 3:
        flags.append((start, "accretion", f"{run} indented blocks under one item",
                      "consider merging into one paragraph"))

    cjk = len(CJK.findall(text))
    if cjk:
        flags.append((0, "non-english", f"{cjk} CJK characters",
                      "instruction layer is English; quote only a phrase that must be recognised verbatim"))

    return flags

if __name__ == "__main__":
    paths = sys.argv[1:]
    if not paths:
        sys.exit(__doc__)
    total = 0
    for p in paths:
        fl = check(p)
        total += len(fl)
        print(f"\n=== {os.path.basename(p)} — {len(fl) or 'no'} flag(s)")
        for line, kind, hit, ctx in sorted(fl):
            print(f"  L{line:<4} {kind:<20} {hit!r}")
            if ctx and ctx != hit:
                print(f"        …{ctx[:150]}")
    sys.exit(1 if total else 0)
