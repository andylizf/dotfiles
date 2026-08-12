#!/usr/bin/env python3
"""Audit a figure PDF (or a page of one) for the defects a visual skim misses.

Checks, in order of how often they bite:
  1. Text-on-text overlap — labels colliding, the classic "looks fine at 100%" bug
  2. Ink outside a stated box — a figure bleeding past the text column
  3. Printed font size    — what the reader actually sees, after LaTeX scaling
  4. Type 3 fonts        — only matters for ACM/IEEE camera-ready and accessibility

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
# tightly-spaced legend rows as "overlapping" when nothing visibly touches. Shrink
# vertically to the ink band before testing.
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


def embed_state(doc, xref):
    """Classify a font as embedded / self-contained / missing.

    Two traps here. `extract_font` returns an empty buffer for Type 3 and that is
    *not* a missing font — Type 3 glyphs are CharProcs living inside the PDF, so they
    are always self-contained and there is no font file to extract. And embedding for
    every other type is decided by the FontDescriptor carrying a FontFile* key, not by
    anything in the font dictionary itself.
    """
    obj = doc.xref_object(xref, compressed=False) or ""
    if "/Type3" in obj:
        return "type3"
    m = re.search(r"/FontDescriptor\s+(\d+)\s+\d+\s+R", obj)
    if not m:
        return "missing"
    fd = doc.xref_object(int(m.group(1)), compressed=False) or ""
    return "embedded" if any(k in fd for k in ("/FontFile2", "/FontFile3", "/FontFile")) else "missing"


def check_fonts(doc, pages):
    """Returns (unembedded, type3) — two different problems of very different weight."""
    unembedded, type3 = {}, {}
    for p in pages:
        for f in doc[p].get_fonts(full=True):
            xref, base = f[0], f[3]
            state = embed_state(doc, xref)
            if state == "missing":
                unembedded.setdefault(base, set()).add(p + 1)
            elif state == "type3":
                type3.setdefault(base, set()).add(p + 1)
    return unembedded, type3


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

    unembedded, t3 = check_fonts(doc, pages)
    if unembedded:
        failures += 1
        print(f"\n  [FAIL] {len(unembedded)} font(s) not embedded — every venue rejects this")
        for base, pp in sorted(unembedded.items()):
            print(f"         {base}  (pages {sorted(pp)[:5]})")
        print("         usually comes from an imported figure whose own fonts weren't embedded")
    else:
        print("\n  [ok]   every font is embedded")

    if t3:
        print(f"  [note] {len(t3)} Type 3 font(s): {', '.join(sorted(t3))}")
        print("         self-contained and searchable, so this is a venue-policy issue, not a defect")
        print("         matters at: systems camera-ready (USENIX, ACM SOSP/SIGCOMM), ACM TAPS,")
        print("                     PDF/UA accessibility   |   ignored by NeurIPS / ICML / ICLR")
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
            print(f"\n  [FAIL] {len(ov)} overlapping text pair(s) on page {p+1}")
            for frac, ta, tb, x, y in ov[:12]:
                print(f'         {frac:5.0%} overlap: "{ta}" ×= "{tb}"   at ({x}, {y})')
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
