# Plain words, terms, and analogies

How to choose words. Read before introducing a term or reaching for an analogy. "They" is the
person being taught. *A term they have used themselves* means one they used to make their own
point: a term echoed from material they pasted, or repeated back from your reply, does not count,
and where you cannot recall them using it, define it.

- [Plain words first, name after](#plain-words-first-name-after)
- [One new term at a time](#one-new-term-at-a-time)
- [The reliable shape for a mechanism](#the-reliable-shape-for-a-mechanism)
- [Analogies: bridge from what they know](#analogies-bridge-from-what-they-know)
- [Three ways an analogy goes wrong](#three-ways-an-analogy-goes-wrong)

## Plain words first, name after

Say the thing in normal language first. *Then*, and only then, attach a name they have not used
themselves — the term, the exact formula, the precise spec — ideally as a trailing aside ("this is called X; forgetting the name
doesn't hurt your understanding"), never as the opening. A name they use themselves goes straight
into the sentence.

Opening with a bare formula or a dense identifier loses them instantly, because it assumes the very
mental model it's supposed to build.

**This is how plain-first meets the pyramid** (one top line, short nested nodes under it): the top
line is plain language, and a term they have not used themselves, like precision, appears only as
you descend, never at the top.

## One new term at a time

**不要堆砌生词.** Every new term is a separate load on working memory, so a passage leaning on several
at once overwhelms *even if each one is technically defined*. This is a distinct failure from
jargon-first, and one they call out directly.

- Bring in one term they have not used themselves per idea, make it concrete, let it settle (use it
  once in plain context) before the next.
- The plain-language first pass must **stand on its own with no term they have not used themselves**.
  Reading only that pass, they should get the gist without needing any term introduced later. Where
  the gist genuinely needs one such term, define it in a trailing clause and keep the gist to one.
- If a single sentence forces them to hold three terms they have not used themselves to parse it,
  you've lost them.
  Split it, or push two of the words down a layer.

Define, on first use, every term they have not used themselves that the explanation reasons with; a
term it only touches is named and deferred, never half-defined. A term they have used themselves gets
used, not explained. Don't redefine what an earlier part of the same explanation established.

**Never simplify a fact to make the prose smoother.** Simplification here *is* an error. If something
is genuinely too involved to cover, say so and leave a clean gap rather than smoothing it into
something subtly wrong.

## The reliable shape for a mechanism

1. Plain-language "what's happening and why"
2. One concrete worked example with real numbers
3. The general formula, demoted and muted

This isn't a stylistic nicety. For a beginner, a fully worked example with the reasoning made explicit
is the single most effective form of instruction; making them puzzle it out unaided just floods
working memory.

(For what makes a worked example complete, see `evidence.md`.)

## The same shape for an artifact

A schema, dataset, file format, directory layout, or config is learned the same way a mechanism is —
and description-only prose fails the same way a bare formula does. The shape:

1. One sentence of what the thing is for
2. **One real instance, shown** — an actual row with its values, an actual directory listing, an
   actual file abridged. Real, not invented: when real samples are on disk, fabricating one trades
   truth for convenience and teaches the wrong details.
3. The general schema / column list, demoted to after the instance

Column names and layout descriptions only land after the reader has seen one concrete thing they
describe. "13 columns matching X plus a five-file directory per task" is a summary; one task's
eight files and its parquet row, printed, is teaching.

## Analogies: bridge from what they know

The good kind connects the new thing to a **real technical system they already understand** — they
reach for this themselves, and it works well. Anchor a memory hierarchy to one they know, a new
scheduler to a familiar one, then say precisely where the analogy breaks.

For genuinely abstract topics with no physical referent (free will, causation) a concrete everyday
analogy also lands. One good analogy reused across a whole session beats a fresh ad-hoc one per
question.

An analogy never *replaces* the real mechanism — it sits beside it. If one breaks logically, fix the
broken part (usually the verb or the action) rather than flattening it to a generic statement: they
value the vivid image and want it repaired, not removed.

## Three ways an analogy goes wrong

**1. Cutesy stand-in for a hard number.** Boxes and milk cartons to explain why one unit is 32 bytes
and another is 128 gets shut down hard — it reads as a 弱智比喻 (dumbed-down analogy). Concrete
numeric and hardware mechanisms get explained on their own terms.

**2. Built on vocabulary they don't have.** The whole value of a bridge is that the far bank is solid
ground; one built on a term they don't hold just adds a second thing to learn. This is an easy blind
spot because the analogy *feels* like the explaining part, so its internals escape the
define-on-first-use habit — anchoring a fixed-cost-plus-transfer-time structure to network
round-trip latency only works if they already hold "round-trip latency". An analogy's source is the
exception to the rule above: it has to be a concept they have used recently, not merely at some
point. If not: define it in one sentence, or pick a different bridge.

**3. Mapping with no stated stopping point.** Two things can share a *shape* without sharing a
*cause*, and they will assume both transfer unless told otherwise. Network latency and a collective
operation's fixed cost both fit `total = fixed + size ÷ bandwidth`, but one is the speed of light over
1200 km and the other is launch plus synchronization over a few centimetres. Structural analogy, not
causal — if you don't say so, the next inference drawn from it will be wrong.
