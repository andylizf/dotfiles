# Sizing: the arithmetic behind every layout complaint

Read when a figure is the wrong height, overflows, has text at the wrong size, or when two panels
refuse to line up. All of it follows from one chain, so it is worth deriving once rather than
memorising the cases.

- [The chain](#the-chain)
- [Getting the column width](#getting-the-column-width)
- [Printed font size](#printed-font-size)
- [Two panels, equal height](#two-panels-equal-height)
- [height= versus width=](#height-versus-width)
- [tight_layout and bbox_inches](#tight_layout-and-bbox_inches)
- [Making room](#making-room)

## The chain

```
figsize (inches) ──×72──► PDF size (pt) ──× scale──► printed size (pt)

scale = printed width ÷ PDF width          (when included with width=)
scale = printed height ÷ PDF height        (when included with height=)
scale = 1                                  (when included with neither)
```

Everything downstream is this chain read in a different direction:

- printed height = printed width × (PDF height ÷ PDF width)
- printed font size = `fontsize` × scale
- the *aspect ratio* survives scaling untouched; only absolute sizes change

The reason `scale = 1` is worth engineering for: it collapses three quantities into one. Your
`figsize` is the printed size, your `fontsize` is the printed font size, and equal height between
panels becomes "write the same number twice".

## Getting the column width

You need the real number, not an estimate, and the document will tell you:

```latex
\the\textwidth     % full column width
\the\linewidth     % width of the current environment — inside a subfigure this is the subfigure
\the\columnwidth   % in twocolumn documents, one column
```

Put `\the\linewidth` inside the exact environment the figure will live in and compile once. This
matters because inside `subfigure`/`minipage`, **`\textwidth` is redefined to that environment's
width**, so `width=\textwidth` and `width=\linewidth` behave identically there — a distinction that
often gets mistaken for a meaningful difference between two approaches.

If you only have the compiled PDF, measure it: the left and right edges of a full body-text line.

## Printed font size

```
printed = fontsize × scale
```

Two calibration points make this concrete: body text in most templates is 10pt, and figure text
below about 5pt is where readers start to squint. A comfortable target is 6.5–7.5pt — deliberately
smaller than body text, because figure labels are meant to recede.

The trap is that identical `rcParams` across scripts do **not** give identical printed text, because
each figure has its own scale. A figure at `scale = 0.48` and one at `scale = 0.64` differ by a third
even with the same `fontsize`. Worse, this can invert the ordering: a script written with
`fontsize=12` can print *larger* than one written with `fontsize=14`. If you must scale, compare the
products, never the settings.

## Two panels, equal height

Equal printed height means:

```
column_a × aspect_a = column_b × aspect_b        where aspect = PDF height ÷ PDF width
⟺  aspect_a ÷ aspect_b = column_b ÷ column_a
```

So the narrower column needs the *taller-proportioned* figure. Two ways to satisfy it:

**With `scale = 1`** — no scaling in LaTeX. Set both `figsize` heights to the same number of inches
and the widths to the column widths. Equal height then holds by construction, with no ratio
arithmetic at all. This is what `figstyle.equal_height_pair` returns.

**With `width=\linewidth`** — the widths are forced to the columns, so you tune the aspects to
satisfy the ratio above. Give both `figsize` the same height and make the widths proportional to the
columns: `figsize_width_a ÷ figsize_width_b = column_a ÷ column_b`.

One caveat with the second route: if you export with `bbox_inches="tight"`, the aspect you get is
**not** `figsize_h ÷ figsize_w`, because the crop removes different amounts on different sides
depending on how long the tick labels are. Measure the exported PDF and iterate, or turn tight off.

## height= versus width=

They are duals. Each hands you one guarantee and makes the other your problem:

| | free | you must check |
|---|---|---|
| `height=H` | panels are equal height | that each printed width `H ÷ aspect` fits its column |
| `width=\linewidth` | fills the column exactly, cannot overflow | that the heights match (tune aspects) |

`height=` is **not** wrong in general — it is the better choice when two panels have very different
natural aspects (a square map beside a wide time series), where forcing both to column width would
make their heights wildly different. The cost is that the narrower panel will not fill its column,
leaving side whitespace, which is usually fine.

`height=` fails specifically when the columns differ in width but the figures have *similar* aspects:
then one height produces one printed width for both, and the narrower column cannot hold it. Check
before shipping:

```
for each panel:  H ÷ aspect  ≤  its column width
```

An overflow is not a crash. LaTeX emits `Overfull \hbox` and draws the figure past the margin, which
is easy to miss on screen and conspicuous in print.

## tight_layout and bbox_inches

Two different things, often confused, each removing a guarantee you need:

- **`fig.tight_layout()`** does *not* change `figsize`. It changes what fraction of the canvas the
  axes occupy, so that labels fit. The consequence that bites: **raising the font size shrinks the
  data area**, because the labels claim more of a fixed canvas. This is why "just make the text
  bigger" quietly compresses the plot.
- **`savefig(bbox_inches="tight")`** *does* change the output file size — it crops to the drawn
  content plus `pad_inches`. After this the output is no longer `figsize × 72`, and the aspect ratio
  is no longer `figsize_h ÷ figsize_w`, because the crop is asymmetric.

Together they make `figsize` and `fontsize` both non-authoritative, which is exactly the state where
layout can only be found by trial and error. Prefer explicit margins (`fig.subplots_adjust`) and
`bbox_inches=None`; if you keep `tight`, treat the exported file as the source of truth and measure
it.

## Making room

When the text has to grow and the canvas cannot, text and decoration are zero-sum. In rough order of
how much they give back for how little they cost:

1. **Rotate a horizontal annotation to vertical** (`rotation=90`) — a multi-word label pinned to the
   side of a plot costs a lot of width horizontally and almost none vertically.
2. **Tighten the legend** — `labelspacing`, `borderpad`, `handlelength`, `columnspacing`, and a
   thinner frame. Legends are usually padded far beyond what they need.
3. **Wrap long axis titles** (`"QA\nAccuracy (%)"`) — trades a line of height for a chunk of width.
4. **Replace whitespace with a faint grid** — when you flatten a figure, the whitespace that used to
   help the eye track values disappears; a light grid (`set_axisbelow(True)` so it sits under the
   data) does that job in zero space.
5. **Shorten tick labels** — thousands separators, fewer ticks, or a `×10³` exponent on the axis.
6. **Cut the decoration you stopped needing** — a title that duplicates the caption, a legend entry
   for something obvious, top/right spines.

Do this in the order "fix font size first, then find the room". If you shrink the font to make things
fit, you have solved the wrong problem — the figure will be unreadable in print and you will not
notice on screen.
