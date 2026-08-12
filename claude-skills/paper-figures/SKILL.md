---
name: paper-figures
description: >-
  Use when producing or fixing a figure that will be printed in a paper — plotting with matplotlib
  for a LaTeX/NeurIPS/ICML/ACL/IEEE/ACM submission, or dealing with any of the symptoms: the figure
  is too tall, text is too small, labels collide, two side-by-side panels are different heights,
  something overflows the column, the font came out wrong, or a reviewer/venue rejected the PDF.
  Trigger it as soon as the destination is a paper, even when the request sounds like ordinary
  plotting ("plot the ablation", "make a figure for the results") — the difference between a figure
  that survives print and one that gets redone at 3am is entirely in defaults set before the first
  plt.subplots. Also use before submission to audit figures that already exist, including ones you
  did not draw.
---

# Figures that survive printing

A screen figure and a printed figure are different artifacts. On screen it is 1000px wide and you
are looking at it alone; in the paper it is a 215pt column, a reader's eye is 40cm away, and it sits
next to body text set in 10pt. Almost every late-night figure emergency traces back to a default that
was fine for the first situation and wrong for the second.

## The one model to hold: size is decided twice

This explains most of the confusing behaviour, so build it before touching anything else.

```
Python:  figsize=(6.0, 3.0)  →  a PDF file some number of points wide
LaTeX:   \includegraphics[width=...]  →  scaled again to fit the column
```

Two consequences follow, and they surprise people every time:

- **`fontsize` is not the printed size.** The printed size is `fontsize × scale`, where
  `scale = printed width ÷ PDF width`. Two figures with identical `rcParams` print at different
  text sizes whenever they are scaled differently — so "I set all the scripts to 14" does not
  make the figures consistent, and can quietly make them *less* consistent.
- **Shrinking `figsize` makes the contents look bigger.** Smaller canvas → bigger scale factor →
  larger printed text. This reads as backwards until you see that the *figure* is always column
  width; what changes is how big everything inside it is relative to the frame.

**So the highest-leverage decision is to make `scale = 1`:** compute `figsize` from the actual
column width in the document, and include the file with no `width=`/`height=` at all. Then
`fontsize` means points on paper, panels keep the proportions you gave them, and a whole class of
problems stops existing. `scripts/figstyle.py` does this arithmetic for you.

When you cannot avoid scaling (a figure you inherited, a template that demands `width=\linewidth`),
everything still works — you just have to carry the scale factor in your head and check the printed
size rather than assume it.

## Start from a venue bundle, then harden it

**Do not hand-derive figure sizes for a known venue — [`tueplots`](https://github.com/pnkraemer/tueplots)
already has them.** It ships `rcParams` bundles for NeurIPS, ICML, ICLR, AISTATS, AAAI and JMLR, with
the column widths and font sizes taken from each template, so `scale = 1` comes for free:

```python
from tueplots import bundles
plt.rcParams.update(bundles.neurips2024())   # figsize (5.5, 3.399), font 9pt, ticks 7pt
plt.rcParams.update(bundles.icml2024(column="half"))   # (3.25, 2.009), font 8pt
```

It also sets `text.usetex=True`, so figure text is typeset by LaTeX in the document's own font —
the "figures match the body text" policy, executed properly. (`mpl_sizes` is a lighter alternative
covering ICLR/ICML/NeurIPS.)

**What no venue bundle sets:**

```python
import figstyle                    # <skill>/scripts
figstyle.harden(font="Inter")      # apply AFTER the venue bundle
```

- **A font that is actually installed.** `font.sans-serif = ["Inter", "Arial", ...]` is a preference
  list that silently falls back, so two people rendering the same repo get different fonts and nobody
  notices — this is the one that really costs you, because it produces a paper whose figures don't
  match each other and gives no signal at all. `harden` raises instead of substituting.
- **`bbox_inches`.** With `"tight"` the output size is no longer `figsize × 72` — it depends on how
  long your tick labels happen to be, which invalidates every size calculation downstream. Leave it
  off and control margins explicitly, or measure the exported file rather than assuming.
- **`pdf.fonttype = 42`.** Matplotlib defaults to Type 3 and no venue bundle overrides it. Set it
  always — it is one line with no downside — but know which deadline it belongs to:
  **systems camera-ready forbids Type 3** (USENIX OSDI/NSDI/ATC/FAST/Security and ACM SOSP/SIGCOMM
  all require embedded scalable fonts, and name imported figures as the usual culprit), while
  **ML venues do not check it at all** (ICML says so explicitly; NeurIPS/ICLR/OpenReview document no
  check). matplotlib's Type 3 output still extracts and searches correctly, so this is a
  publication-pipeline requirement, never a reader-facing defect. See `references/fonts.md`.

If the venue is not covered, or you need an exact width (a subfigure, a fixed-height row),
`figstyle` computes it from the column width you measure out of the document:

```python
figstyle.apply(font="Inter")                          # standalone: harden + sane defaults
fig, ax = figstyle.figure(width_pt=215, ratio=0.62)   # figsize from the real column width
la, rb, wl, wr = figstyle.equal_height_pair(398.1, split=(0.54, 0.44), height_pt=105)
figstyle.save(fig, "ablation.pdf")
```

## When something is wrong

Match the symptom, then read `references/sizing.md` for the derivations.

| Symptom | The move |
|---|---|
| Two side-by-side panels are different heights | Give both `figsize` the **same height**, and make their **widths proportional to the column splits**. Include with `width=\linewidth`. |
| A panel overflows its column | You used `height=` on unequal columns. Either switch to `width=`, or check `H ÷ aspect ≤ column width` for *each* panel. |
| Text is too small | Do not just raise `fontsize` — compute the printed size first (`fontsize × scale`), target ~7pt against 10pt body text, then find the space by cutting decoration, not by shrinking the data. |
| No room for the bigger text | The canvas is fixed, so text and decoration are zero-sum: rotate a horizontal annotation to vertical, tighten `labelspacing`, replace whitespace with a faint grid, wrap the y-axis title. |
| The figure eats too much page | Flatten it (reduce the height in `figsize`) and add a grid so values stay readable without the whitespace. |
| Labels collide | `references/checking.md` — detection first, then `adjustText` or an explicit offset table. |
| Font came out wrong | `references/fonts.md` — variable-font files and stale caches are the two usual causes. |

## Before it goes in the paper

Never ship on a visual skim. At column size, a collision that will be obvious to a reviewer is a few
pixels on your screen. Run the audit:

```bash
python <skill>/scripts/check_figure.py fig.pdf --printed-width 215
python <skill>/scripts/check_figure.py paper.pdf --page 9 --column 107.5 505.7
```

It reports Type 3 fonts, text-on-text collisions, ink outside the column, and the printed font size —
the four things that are invisible at a glance and expensive after submission. It works on any PDF,
including figures you did not produce.

Then get a second pair of eyes that is not yours. A fresh reviewer — a subagent with the rendered
crop, or a collaborator — catches composition problems that no script can express ("the legend hides
a data point", "panel b's message doesn't match its caption"). `references/checking.md` has the
review prompt and the zoom levels that make defects visible.

## Reference files

- `references/sizing.md` — the size arithmetic in full: scale factors, equal-height panels, the
  `height=` vs `width=` tradeoff, why `tight_layout` and `bbox_inches` interact badly with both.
- `references/fonts.md` — choosing a font, download links, static vs variable files, Type 42, cache
  invalidation, and how to verify what actually got embedded.
- `references/checking.md` — programmatic overlap detection at draw time and on finished PDFs, the
  independent-review loop, and what to ask a reviewing agent to look at.
