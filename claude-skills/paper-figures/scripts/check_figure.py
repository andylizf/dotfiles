#!/usr/bin/env python3
"""Audit a figure PDF (or a page of one) for the defects a visual skim misses.

Checks, in order of how often they bite:
  1. Colliding text     — labels close enough to read as one blob at print size
  2. Ink outside a stated box — a figure bleeding past the text column
  3. Printed font size    — what the reader actually sees, after LaTeX scaling
  4. Missing /ToUnicode  — draws fine, but cannot be selected, copied or searched
  5. Type 3 fonts        — a font-type question; matters at ACM/IEEE, not at ML venues

Usage:
  python check_figure.py fig.pdf                       # figure file, no scaling assumed
  python check_figure.py paper.pdf --page 9            # one page of a compiled paper
  python check_figure.py fig.pdf --printed-width 215   # apply the scale it gets in LaTeX
  python check_figure.py paper.pdf --page 9 --column 107.5 505.7
"""
from __future__ import annotations

import argparse
import itertools
import re
import sys

import pymupdf

OVERLAP_FRACTION = 0.18   # report a pair only when the smaller box loses this much area
MIN_PRINTED_PT = 5.0      # below this, body-text readers will squint

# A span's bbox spans the full line box — ascender to descender — while the ink
# occupies roughly the middle. Comparing raw bboxes therefore flags every pair of
# tightly-spaced legend rows as colliding when nothing visibly touches. Shrink
# vertically to the ink band before testing.
#
# 0.62 is calibrated against measured output: rendering real labels at 12x and
# taking their non-white pixel bounds puts the ink at 57–85% of the line box,
# depending on whether the string has ascenders and descenders. A hit therefore
# means "these two are close enough to read as one blob at print size", which at
# 7pt is just as damaging as literal glyph-on-glyph overlap and much more common.
INK_BAND = 0.62


def spans(page):
    """All non-blank text spans, each carrying its line's writing direction.

    `dir` lives on the line, not the span, so it has to be copied down — rotated
    axis titles are only distinguishable from horizontal text by this field.
    """
    out = []
    for block in page.get_text("dict")["blocks"]:
        if block["type"] != 0:
            continue
        for line in block["lines"]:
            for s in line["spans"]:
                if s["text"].strip():
                    out.append({**s, "dir": line.get("dir", (1.0, 0.0))})
    return out


def area(b):
    return max(0.0, b[2] - b[0]) * max(0.0, b[3] - b[1])


def intersect(a, b):
    return (max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3]))


FONT_FILE_KEYS = ("/FontFile2", "/FontFile3", "/FontFile")


def _has_font_file(doc, obj):
    """Follow /FontDescriptor from a font dict and report whether a file hangs off it."""
    m = re.search(r"/FontDescriptor\s+(\d+)\s+\d+\s+R", obj)
    if not m:
        return None                                    # no descriptor at this level
    fd = doc.xref_object(int(m.group(1)), compressed=False) or ""
    return any(k in fd for k in FONT_FILE_KEYS)


def embed_state(doc, xref):
    """Classify a font as embedded / self-contained / missing.

    Three traps, each of which produces a confident wrong answer:

    - `extract_font` returns an empty buffer for Type 3, which is *not* a missing
      font: Type 3 glyphs are CharProcs inside the PDF, so there is no font file to
      extract and never can be.
    - Embedding is decided by the FontDescriptor carrying a FontFile* key, not by
      anything in the font dictionary itself.
    - **A Type 0 (CID) font has no FontDescriptor at the top level** — it sits on the
      descendant CIDFont. Since `pdf.fonttype=42` produces exactly this, checking only
      the top level marks every correctly-embedded figure as missing.
    """
    obj = doc.xref_object(xref, compressed=False) or ""
    if "/Type3" in obj:
        return "type3"

    found = _has_font_file(doc, obj)
    if found is None:
        m = re.search(r"/DescendantFonts\s*\[?\s*(\d+)\s+\d+\s+R", obj)
        if m:
            desc = doc.xref_object(int(m.group(1)), compressed=False) or ""
            found = _has_font_file(doc, desc)
    return "embedded" if found else "missing"


def check_fonts(doc, pages):
    """Returns (unembedded, no_tounicode, type3) — three problems, in weight order.

    A font without a /ToUnicode map draws correctly but has no mapping back to
    characters, so selection, copy, search and screen readers all fail on it. This is
    invisible in every visual check and is what venues asking for a "searchable PDF"
    are actually asking for — a far more consequential defect than the font's type,
    and independent of it.
    """
    unembedded, no_tounicode, type3 = {}, {}, {}
    for p in pages:
        for f in doc[p].get_fonts(full=True):
            xref, base = f[0], f[3]
            state = embed_state(doc, xref)
            if state == "missing":
                unembedded.setdefault(base, set()).add(p + 1)
            elif state == "type3":
                type3.setdefault(base, set()).add(p + 1)
            obj = doc.xref_object(xref, compressed=False) or ""
            if "/ToUnicode" not in obj:
                no_tounicode.setdefault(base, set()).add(p + 1)
    return unembedded, no_tounicode, type3


def ink_box(span):
    """Shrink a span's bbox to the band its glyphs actually occupy.

    The line box runs ascender-to-descender across the writing direction, so the
    slack is on the axis perpendicular to the text. Rotated labels (axis titles at
    90°) therefore need the *horizontal* squeeze, not the vertical one — without
    this every y-axis title reads as colliding with its own tick labels.
    """
    x0, y0, x1, y1 = span["bbox"]
    dx, dy = span.get("dir", (1.0, 0.0))
    if abs(dy) > abs(dx):                      # rotated (vertical) text
        cx, half = (x0 + x1) / 2, (x1 - x0) * INK_BAND / 2
        return (cx - half, y0, cx + half, y1)
    cy, half = (y0 + y1) / 2, (y1 - y0) * INK_BAND / 2
    return (x0, cy - half, x1, cy + half)


def check_overlaps(page, scale):
    found = []
    ss = spans(page)
    for a, b in itertools.combinations(ss, 2):
        if a["bbox"] == b["bbox"]:
            continue
        ba, bb = ink_box(a), ink_box(b)
        ia = area(intersect(ba, bb))
        if ia <= 0:
            continue
        smaller = min(area(ba), area(bb))
        if smaller <= 0:
            continue
        frac = ia / smaller
        if frac >= OVERLAP_FRACTION:
            found.append((frac, a["text"].strip()[:28], b["text"].strip()[:28],
                          round(a["bbox"][0] * scale, 1), round(a["bbox"][1] * scale, 1)))
    return sorted(found, reverse=True)


def check_bleed(page, column):
    if not column:
        return None
    left, right = column
    ink_l, ink_r = None, None
    for s in spans(page):
        x0, x1 = s["bbox"][0], s["bbox"][2]
        ink_l = x0 if ink_l is None else min(ink_l, x0)
        ink_r = x1 if ink_r is None else max(ink_r, x1)
    for d in page.get_drawings():
        r = d["rect"]
        ink_l = r.x0 if ink_l is None else min(ink_l, r.x0)
        ink_r = r.x1 if ink_r is None else max(ink_r, r.x1)
    return ink_l, ink_r, left, right


def check_sizes(page, scale):
    sizes = {}
    for s in spans(page):
        printed = round(s["size"] * scale, 2)
        sizes.setdefault(printed, 0)
        sizes[printed] += len(s["text"].strip())
    return sizes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf")
    ap.add_argument("--page", type=int, default=None, help="1-indexed page; default all")
    ap.add_argument("--printed-width", type=float, default=None,
                    help="width in pt this figure occupies in the document; sets the scale")
    ap.add_argument("--column", nargs=2, type=float, default=None,
                    metavar=("LEFT", "RIGHT"), help="text column bounds in pt, to check bleed")
    args = ap.parse_args()

    doc = pymupdf.open(args.pdf)
    pages = [args.page - 1] if args.page else list(range(len(doc)))
    failures = 0

    print(f"── {args.pdf}" + (f"  page {args.page}" if args.page else ""))

    unembedded, no_tounicode, t3 = check_fonts(doc, pages)
    if unembedded:
        failures += 1
        print(f"\n  [FAIL] {len(unembedded)} font(s) not embedded — every venue rejects this")
        for base, pp in sorted(unembedded.items()):
            print(f"         {base}  (pages {sorted(pp)[:5]})")
        print("         usually comes from an imported figure whose own fonts weren't embedded")
    else:
        print("\n  [ok]   every font is embedded")

    if no_tounicode:
        failures += 1
        print(f"  [FAIL] {len(no_tounicode)} font(s) have no /ToUnicode map")
        for base, pp in sorted(no_tounicode.items()):
            print(f"         {base}  (pages {sorted(pp)[:5]})")
        print("         text draws correctly but cannot be selected, copied, searched or read")
        print("         aloud — this is what 'searchable PDF' requirements are about, and it is")
        print("         invisible to any visual check. Verify with: pdftotext <file> -")
    else:
        print("  [ok]   every font maps back to characters (/ToUnicode present)")

    if t3:
        print(f"  [note] {len(t3)} Type 3 font(s): {', '.join(sorted(t3))}")
        print("         a font-type question, independent of the two checks above; Type 3 with a")
        print("         ToUnicode map searches fine. Relevant to ACM TAPS / IEEE PDF eXpress and")
        print("         PDF/UA; NeurIPS / ICML / ICLR do not check it.")
        print("         fix: mpl.rcParams['pdf.fonttype'] = 42  (and ps.fonttype)")

    for p in pages:
        page = doc[p]
        scale = 1.0
        if args.printed_width:
            scale = args.printed_width / page.rect.width
            print(f"\n  page {p+1}: PDF {page.rect.width:.1f}pt wide → printed "
                  f"{args.printed_width:.1f}pt, scale {scale:.3f}×")

        ov = check_overlaps(page, scale)
        if ov:
            failures += 1
            print(f"\n  [FAIL] {len(ov)} colliding text pair(s) on page {p+1}")
            for frac, ta, tb, x, y in ov[:12]:
                print(f'         {frac:5.0%} too close: "{ta}" ×= "{tb}"   at ({x}, {y})')
        else:
            print(f"  [ok]   no text overlaps on page {p+1}")

        bl = check_bleed(page, args.column)
        if bl:
            il, ir, left, right = bl
            over_r, over_l = ir - right, left - il
            if over_r > 0.5 or over_l > 0.5:
                failures += 1
                print(f"\n  [FAIL] ink outside the text column on page {p+1}")
                print(f"         ink {il:.1f}..{ir:.1f}  column {left}..{right}"
                      f"  (right +{over_r:.1f}, left +{over_l:.1f})")
            else:
                print(f"  [ok]   ink stays inside the column on page {p+1}")

        if args.printed_width:
            sizes = check_sizes(page, scale)
            tiny = {s: n for s, n in sizes.items() if s < MIN_PRINTED_PT}
            line = "  ".join(f"{s}pt×{n}" for s, n in sorted(sizes.items()))
            print(f"  printed font sizes (pt × chars): {line}")
            if tiny:
                failures += 1
                print(f"  [FAIL] text below {MIN_PRINTED_PT}pt once printed: {sorted(tiny)}")

    print(f"\n── {'PASS' if failures == 0 else str(failures) + ' issue group(s)'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
