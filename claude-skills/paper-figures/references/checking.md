# Checking: finding what a visual skim misses

Read before declaring a figure done, and when auditing figures for a submission. The premise:
**at the size you inspect a figure, the defects that matter are a few pixels.** A label collision
that a reviewer will see immediately is, on your 27" monitor at 100% zoom, two glyphs that look
adjacent. So the checks here are the ones that do not rely on your eyes.

- [Detect overlap while drawing](#detect-overlap-while-drawing)
- [Audit the finished PDF](#audit-the-finished-pdf)
- [Fixing overlaps once found](#fixing-overlaps-once-found)
- [Independent review](#independent-review)
- [A pre-submission pass](#a-pre-submission-pass)

## Detect overlap while drawing

Matplotlib exposes exactly what you need; the pieces are just not obviously connected.

```python
fig.canvas.draw()                          # a renderer must exist before extents are known
r = fig.canvas.get_renderer()
boxes = [t.get_window_extent(r) for t in texts]

for i, j in itertools.combinations(range(len(boxes)), 2):
    if boxes[i].overlaps(boxes[j]):
        print("collision:", texts[i].get_text(), texts[j].get_text())
```

- `get_window_extent(renderer)` → the artist's `Bbox` in display pixels. Any artist has it, so the
  same loop covers legends, annotations, titles and tick labels.
- `Bbox.overlaps(other)` → the intersection test, built in.
- `fig.canvas.draw()` (or `fig.draw_without_rendering()`) must run first — extents are unknown until
  something has been laid out.
- `ax.get_tightbbox(r)` when you need the axes *including* its decorations, e.g. to check whether a
  panel's labels spill outside its allotted area.

Worth wiring into the plotting script itself as an assertion, so a figure cannot be regenerated into
a broken state without someone hearing about it.

## Audit the finished PDF

Drawing-time checks only cover figures you generate. `scripts/check_figure.py` works on any PDF —
including a co-author's figure, a TikZ drawing, or a whole compiled paper:

```bash
python <skill>/scripts/check_figure.py fig.pdf --printed-width 215
python <skill>/scripts/check_figure.py paper.pdf --page 9 --column 107.5 505.7
```

It reports four things, chosen because none of them is visible at a glance:

1. **Type 3 fonts** — a hard rejection at several venues, and completely invisible.
2. **Text-on-text collisions** — every pair of text spans whose ink boxes intersect past a threshold.
3. **Ink outside the column** — pass `--column LEFT RIGHT` and it catches a figure bleeding into the
   margin, which is the visible symptom of a `height=` overflow.
4. **Printed font size** — pass `--printed-width` and it applies the scale, so you see paper points
   rather than what the script asked for.

Two details in how it tests overlap, worth knowing if you adapt it. A text span's bounding box runs
from ascender to descender, so tightly-spaced legend rows appear to intersect even when nothing
visibly touches — it shrinks each box to the middle band before testing. And rotated text (axis
titles at 90°) needs that squeeze applied on the *horizontal* axis instead, which it decides from the
line's `dir` field; without that, every y-axis title reads as colliding with its own tick labels.

## Fixing overlaps once found

In increasing order of effort:

- **`adjustText`** ([pypi](https://pypi.org/project/adjustText/)) — iteratively pushes labels apart
  and draws leader lines back to their points. Right answer for a scatter plot with many labels.
  It uses the same `get_window_extent` / overlap machinery internally.
- **An explicit offset table** — a dict of `(series, point) → (dx, dy)` in points, applied via
  `ax.annotate(..., xytext=offset, textcoords="offset points")`. More work, but deterministic and
  reviewable, which matters for a figure that will be regenerated many times. Budget for the
  maintenance cost: adding one data point means re-tuning its neighbours' offsets too.
- **Label fewer things** — often the real fix. If twenty points need labels, the figure is asking the
  reader to do lookup work that a table does better.
- **Give the labels room** — a wider aspect, or moving the legend outside the axes.

## Independent review

Scripts cannot see composition. A second reviewer — a subagent, or a co-author — catches the class of
problem that has no programmatic expression: the legend covering a data point, a panel whose visual
message contradicts its caption, an inconsistent color meaning between panels, a trend that reads
backwards because of the axis direction.

Make it possible for them to actually see the defects:

- Render the figure **at its printed size** first, then again at 3–6× that size. The first shows
  what the reviewer of the paper will see; the second shows what is actually there. A defect that
  only appears in the second is still a defect — it means the figure is over-packed for its size.
- Hand over the caption and the claim the figure supports, not just the image. Most composition
  errors are mismatches between what the figure shows and what the text says it shows.
- Ask for specifics, because open-ended "review this" produces "looks good": *is any text clipped
  or overlapping; does anything cross the panel border; can you read every tick label; does the
  legend hide data; do the panels use color consistently; does what you see match the caption?*
- Review each panel separately as well as the whole. Panel-level problems hide in a composite.

Keep the reviewer independent — a fresh context that did not write the figure. The author's eye
stops seeing a defect after the third look, which is precisely the failure this step exists to
counter.

## A pre-submission pass

Once, over every figure in the paper, ideally scripted:

```bash
for f in figures/*.pdf; do python <skill>/scripts/check_figure.py "$f"; done
python <skill>/scripts/check_figure.py paper.pdf --column 107.5 505.7
```

Then check the things that span figures rather than living inside one:

- **One font family across every figure** — `pdffonts` on each, compare. Different names mean
  someone's machine substituted silently.
- **Consistent printed text size** — compute `fontsize × scale` per figure, not the settings.
- **Consistent color semantics** — if blue means "ours" in one figure, it must not mean "baseline"
  in another.
- **Every figure referenced in the text**, and every reference pointing at the right one.
