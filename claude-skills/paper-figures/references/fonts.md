# Fonts: choosing one, installing it, proving it took

Read when picking a font for a paper's figures, when the font "didn't apply", or before submission to
verify what actually got embedded. Font problems are unusually nasty because **the failure mode is
silence** — matplotlib substitutes something and renders happily.

- [Pick one policy for the whole paper](#pick-one-policy-for-the-whole-paper)
- [Which font](#which-font)
- [Downloading: static, not variable](#downloading-static-not-variable)
- [Installing so matplotlib sees it](#installing-so-matplotlib-sees-it)
- [Type 42, not Type 3](#type-42-not-type-3)
- [Verify what was embedded](#verify-what-was-embedded)

## Pick one policy for the whole paper

There are two coherent choices, and the only bad option is the mixture:

- **Figures match the body text** — serif figures in a serif paper. Maximum integration; the figure
  reads as part of the page. Costs you the legibility advantage sans-serif has at small sizes.
- **Figures are their own system** — one sans-serif everywhere in the figures, serif body text. The
  figures read as a consistent family of objects. This is the more common modern choice and is more
  forgiving at 7pt.

What ruins either is inconsistency *between figures*, which is the default outcome when each script
sets its own font and each collaborator has different fonts installed. Centralise it: one style
module every plotting script imports (`scripts/figstyle.py`), never per-script `rcParams`.

## Which font

Free, redistributable, and good at small print sizes:

| Font | Get it | Notes |
|---|---|---|
| **Inter** | [github.com/rsms/inter/releases](https://github.com/rsms/inter/releases) | Designed for small-size legibility; tabular figures available. Excellent default. |
| **Source Sans 3** | [github.com/adobe-fonts/source-sans/releases](https://github.com/adobe-fonts/source-sans/releases) | Adobe, OFL. Pairs well with Source Serif for body text. |
| **Roboto** | [github.com/googlefonts/roboto](https://github.com/googlefonts/roboto/releases) | Ubiquitous, safe, slightly narrow. |
| **TeX Gyre Heros** | [gust.org.pl/projects/e-foundry/tex-gyre/heros](https://www.gust.org.pl/projects/e-foundry/tex-gyre/heros) | A free Helvetica clone — the right pick when a venue's template expects Helvetica. |
| **Libertinus Sans** | [github.com/alerque/libertinus/releases](https://github.com/alerque/libertinus/releases) | Matches Libertine/Libertinus body text if the paper uses it. |

Avoid shipping figures set in **Helvetica** or **Arial** unless you have them legitimately — they are
not redistributable, so a collaborator without them silently gets a substitute. Same trap for
corporate fonts (Google Sans, SF Pro): fine on the machine that has them, a different font everywhere
else, and the paper ends up with two fonts across its figures without anyone seeing it happen.

For numbers, prefer a font with **tabular figures** (fixed-width digits) so tick labels and value
annotations line up in columns. Inter exposes this as a feature; some families ship it as a separate
file.

## Downloading: static, not variable

This is the single most common "I installed it and it didn't work" cause.

Modern fonts ship as **variable fonts** — one file encoding a continuous range of weights along an
axis (`InterVariable.ttf`, `Inter.ttc`). **Matplotlib does not support variable fonts.** It needs
**static instances**: one file per weight, `Inter-Regular.ttf`, `Inter-SemiBold.ttf`, and so on.

In a release archive, look for a `static/` directory and take the `.ttf` files from there. Prefer
`.ttf` over `.otf` — matplotlib's FreeType binding handles TrueType most reliably.

```
Inter-4.x.zip
├── InterVariable.ttf          ← do NOT use
├── Inter.ttc                  ← do NOT use (TrueType Collection)
└── static/
    ├── Inter-Regular.ttf      ← use these
    ├── Inter-Italic.ttf
    └── Inter-Bold.ttf
```

The failure this produces is not an error — the family name still resolves, and you get a fallback
font that looks close enough to pass a glance.

## Installing so matplotlib sees it

Two routes. The second is better for a paper repo.

**System install** — put the files where the OS keeps fonts (`~/Library/Fonts` on macOS,
`~/.local/share/fonts` on Linux), then **clear matplotlib's font cache**, which is the step everyone
forgets:

```bash
rm -rf "$(python -c 'import matplotlib; print(matplotlib.get_cachedir())')"
```

matplotlib caches the name→file map and will not notice a newly installed font until that cache is
rebuilt. "I installed it and it still falls back" is almost always this.

**Vendor it with the paper** — commit the `.ttf` files next to the source and register them at
runtime. Now the repo renders identically on every machine and in CI, with no install step:

```python
import matplotlib.font_manager as fm
fm.fontManager.addfont("fonts/Inter-Regular.ttf")
plt.rcParams["font.family"] = "Inter"
```

`figstyle.apply(font_dir="fonts")` does this and then **raises if the font still isn't resolvable**,
which converts a silent substitution into a loud failure. Guard it yourself if you're not using the
helper — `fm.findfont` returns the fallback path rather than failing, so check the returned path
rather than trusting that the call succeeded.

## Type 42, not Type 3

Matplotlib's default for PDF export is **Type 3**, where each glyph is a small PostScript drawing
program rather than an entry in a proper font program. Set it to 42 (TrueType):

```python
mpl.rcParams["pdf.fonttype"] = 42
mpl.rcParams["ps.fonttype"]  = 42
mpl.rcParams["svg.fonttype"] = "none"   # keep SVG text as text, not outlines
```

**Calibrate how much this matters, because the folklore around it is mostly wrong.** Measured on
matplotlib output, Type 3 and Type 42 are indistinguishable where people claim they differ:

| Claim | Reality for matplotlib output |
|---|---|
| "Type 3 is a low-res bitmap" | False. Type 3 glyphs are arbitrary PostScript, in practice vector. The bitmap association is a 1986 `dvips` artifact — it used Type 3 to carry PK bitmap fonts. |
| "Type 3 breaks search and copy" | False here. That's `dvips`-style Type 3, whose `/Encoding` is meaningless. matplotlib writes a correct ToUnicode map; text extracts and searches identically under both. |
| "Type 42 makes bigger files" | Not necessarily — matplotlib subsets either way. A small test figure came out *smaller* as Type 42. |

**Whether it actually blocks you depends entirely on the venue family**, and the split is sharp:

| Venue family | Position on Type 3 |
|---|---|
| **Systems** — USENIX (OSDI, NSDI, ATC, FAST, Security), ACM (SOSP, SIGCOMM) | **Camera-ready instructions forbid it.** USENIX asks for scalable fonts, all embedded, and names *imported vector figures* as the usual source. A shepherd reviews the final PDF. |
| **ACM/IEEE production pipelines** — TAPS, PDF eXpress | Automated check at camera-ready; bounces on Type 3. |
| **ML** — NeurIPS, ICML, ICLR (OpenReview) | Not checked. ICML's instructions say outright there is no Type 3 check. |
| **Accessibility** — PDF/UA, Acrobat checker | Fails regardless of venue. |

So the honest framing: **submission is never blocked by this; camera-ready at a systems venue is.**
Since it costs one line, set it always and stop thinking about it — but don't tear apart a working
pipeline mid-deadline over a Type 3 warning at a venue that doesn't check.

One wrinkle if a shepherd is strict: USENIX's wording asks for **Type 1**, while `fonttype=42`
produces **TrueType**, which is not literally Type 1. TrueType is accepted in practice, being a
standard scalable PDF font. If challenged, convert with
`gs -dEmbedAllFonts=true -dSubsetFonts=true -sDEVICE=pdfwrite`.

Note also that the official wording at several venues describes Type 3 as "bit-mapped", which is the
same misconception as above — the requirement is real even though the justification given for it
isn't. Comply; don't argue.

## Verify what was embedded

Never assume — the whole point is that these failures are invisible. Check the finished file:

```bash
python <skill>/scripts/check_figure.py fig.pdf      # reports Type 3 and much else
pdffonts fig.pdf                                    # poppler; shows type and embedded flag
```

What you want to see: your font's name, `emb` yes, and a type of TrueType/CID/Type1 — never `Type3`.
A subset prefix like `ABCDEF+Inter-Regular` is normal and good; it means only the glyphs used were
embedded.

Two failures this catches that nothing else will: a font you never chose appearing in the list (a
silent fallback on someone else's machine), and the same logical font appearing under two names
across different figures (two people rendered with different installs).
