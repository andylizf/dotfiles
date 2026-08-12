#!/usr/bin/env python3
"""Baseline matplotlib setup for figures that get printed in a paper.

Import it instead of hand-rolling rcParams, so every figure in the paper shares one
configuration and the settings that fail silently are handled once:

    import figstyle
    figstyle.apply(font="Inter")
    fig, ax = figstyle.figure(width_pt=215, ratio=0.62)
    ...
    figstyle.save(fig, "out.pdf")

The design goal is scale == 1: figsize is computed from the column width the figure
will actually occupy, and the file is included in LaTeX with no width=/height=. Then
`fontsize` is points on paper and nothing downstream has to correct for scaling.
"""
from __future__ import annotations

import warnings
from pathlib import Path

import matplotlib as mpl
import matplotlib.font_manager as fm
import matplotlib.pyplot as plt

PT_PER_INCH = 72.0

# Font stacks that survive print and are freely redistributable. See references/fonts.md
# for download links and the static-vs-variable trap.
KNOWN_FONTS = ("Inter", "Source Sans 3", "Roboto", "TeX Gyre Heros", "Helvetica", "Arial")


class FontMissing(RuntimeError):
    pass


def available(name: str) -> bool:
    """True if matplotlib can actually resolve this family to a real file.

    findfont() falls back to DejaVu Sans rather than failing, so asking it for a name
    always "succeeds" — the resolved path is what tells you whether it really found it.
    """
    try:
        path = fm.findfont(fm.FontProperties(family=name), fallback_to_default=False)
        return Path(path).exists()
    except Exception:
        return False


def register_dir(font_dir: str | Path) -> list[str]:
    """Register every font file in a directory without installing it system-wide.

    Useful for vendoring the font next to the paper source so collaborators and CI
    render identically instead of each silently falling back to whatever they have.
    """
    added = []
    for f in sorted(Path(font_dir).glob("**/*")):
        if f.suffix.lower() in {".ttf", ".otf"}:
            fm.fontManager.addfont(str(f))
            added.append(f.name)
    return added


def harden(font: str | None = None, font_dir: str | Path | None = None):
    """Add the submission-safety settings that venue style packages leave out.

    Call this *after* a venue bundle (tueplots, mpl_sizes, SciencePlots, a lab style
    file). Those packages get sizes and font sizes right, which is the hard part, but
    none of them sets pdf.fonttype — so a perfectly sized figure still exports Type 3
    and gets rejected by ACM/USENIX/IEEE/AAAI. This only touches the safety settings
    and deliberately leaves figsize and font sizes alone.

        from tueplots import bundles
        plt.rcParams.update(bundles.neurips2024())
        figstyle.harden(font="Inter")
    """
    if font_dir:
        register_dir(font_dir)

    family = None
    if font:
        if not available(font):
            raise FontMissing(
                f"{font!r} is not resolvable by matplotlib.\n"
                f"  - if you just installed it: rm -rf {mpl.get_cachedir()} and retry\n"
                f"  - if it is a variable font (e.g. InterVariable.ttf): use the static/ files\n"
                f"  - or pass font_dir=... to register the files directly"
            )
        family = font

    rc = {
        # Type 3 is matplotlib's default; systems venues forbid it at camera-ready.
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "svg.fonttype": "none",
    }
    if family:
        rc["font.family"] = "sans-serif"
        rc["font.sans-serif"] = [family] + list(KNOWN_FONTS) + ["DejaVu Sans"]
        # Math text defaults to DejaVu regardless of the text font, so a single
        # `$\times$` in a label silently mixes a second typeface into the figure.
        # Point mathtext at the same family. Symbols the font lacks (≤, ×, ∈) still
        # fall back — for those, writing the Unicode character directly instead of
        # `$\leq$` keeps everything in one face.
        #
        # A "findfont: Failed to find font weight/style" warning here is real
        # information, not noise: it means only some weights of the family are
        # installed. Install the missing static files rather than silencing it.
        rc.update({
            "mathtext.fontset": "custom",
            "mathtext.rm": family,
            "mathtext.it": f"{family}:italic",
            "mathtext.bf": f"{family}:bold",
        })
    mpl.rcParams.update(rc)
    return family


def apply(font: str | None = None, base_size: float = 9.0, font_dir: str | Path | None = None):
    """Full standalone baseline: hardening plus readable defaults and no bbox surprise.

    Use when there is no venue bundle to build on. If there is one, prefer
    `bundles.<venue>()` followed by `harden()` — those numbers come from the template
    and are more trustworthy than anything derived by hand.
    """
    family = harden(font=font, font_dir=font_dir)

    mpl.rcParams.update({
        # Type 3 is matplotlib's default and is rejected by ACM/USENIX/IEEE/AAAI.
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "svg.fonttype": "none",

        "font.family": "sans-serif",
        "font.sans-serif": ([family] if family else []) + list(KNOWN_FONTS) + ["DejaVu Sans"],
        "font.size": base_size,
        "axes.labelsize": base_size,
        "axes.titlesize": base_size,
        "xtick.labelsize": base_size,
        "ytick.labelsize": base_size,
        "legend.fontsize": base_size - 1,

        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.linewidth": 0.8,
        "lines.linewidth": 1.5,
        "lines.markersize": 4,
        "legend.frameon": False,
        "legend.handlelength": 1.6,
        "legend.labelspacing": 0.3,
        "grid.color": "#d9d9d9",
        "grid.linewidth": 0.6,

        "figure.dpi": 300,
        "savefig.dpi": 300,
        # NOT "tight": it makes output size depend on label lengths, which breaks
        # every size calculation that follows. Control margins explicitly instead.
        "savefig.bbox": None,
        "savefig.pad_inches": 0.0,
        "savefig.transparent": False,
    })
    return family


def size_from_pt(width_pt: float, ratio: float = 0.62, height_pt: float | None = None):
    """Convert a column width in points to a matplotlib figsize in inches.

    ratio is height/width; 0.62 is close to the golden ratio and reads well for a
    single wide panel. Pass height_pt when two panels must print at equal height.
    """
    w = width_pt / PT_PER_INCH
    h = (height_pt / PT_PER_INCH) if height_pt else w * ratio
    return (w, h)


def figure(width_pt: float, ratio: float = 0.62, height_pt: float | None = None, **kwargs):
    """plt.subplots with figsize derived from the printed width."""
    return plt.subplots(figsize=size_from_pt(width_pt, ratio, height_pt), **kwargs)


def equal_height_pair(total_pt: float, split=(0.54, 0.44), height_pt: float = 105.0, gap=0.02):
    """figsize for two side-by-side panels that print at the same height.

    Equal printed height means `printed_width × aspect` matches for both panels. Since
    each panel is scaled to its own column, giving both figsizes the *same height in
    inches* and widths proportional to the splits satisfies that by construction —
    no trial and error, provided you keep scale == 1 (no width=/height= in LaTeX).

    Returns (figsize_left, figsize_right, width_pt_left, width_pt_right).
    """
    a, b = split
    wl, wr = total_pt * a, total_pt * b
    h = height_pt / PT_PER_INCH
    return (wl / PT_PER_INCH, h), (wr / PT_PER_INCH, h), wl, wr


def save(fig, path, **kwargs):
    """Save without letting bbox='tight' silently resize the output.

    Pass tight=True only if you accept that the output size will no longer equal
    figsize×72 — in that case measure the result rather than assuming it.
    """
    tight = kwargs.pop("tight", False)
    if tight:
        kwargs.setdefault("bbox_inches", "tight")
        kwargs.setdefault("pad_inches", 0.02)
    fig.savefig(path, **kwargs)

    got = fig.get_size_inches()
    if not tight:
        warnings.filterwarnings("ignore")
        print(f"saved {path}  {got[0]*PT_PER_INCH:.1f} × {got[1]*PT_PER_INCH:.1f} pt "
              f"(include with no width=/height= to keep scale 1.0)")
    return path


def printed_font_size(fontsize: float, printed_width_pt: float, pdf_width_pt: float) -> float:
    """What `fontsize` becomes on paper once LaTeX scales the figure.

    Use this whenever you cannot avoid scaling. Body text in most templates is 10pt;
    figure text below ~5pt is unreadable, ~7pt is a comfortable target.
    """
    return fontsize * (printed_width_pt / pdf_width_pt)
