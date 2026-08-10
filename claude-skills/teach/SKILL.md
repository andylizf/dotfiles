---
name: teach
description: >-
  Use whenever you are about to explain, teach, or walk the user through any concept, mechanism,
  paper, system, formula, or piece of technical/abstract material — and ESPECIALLY when they are
  learning something new or say things like "什么意思", "解释一下", "教我", "没看懂", "这块没懂",
  or "为什么". Trigger it even when they haven't asked for a "lesson" — any moment you find yourself
  about to describe how something works to them counts, including explanatory files, docs, and
  reports, not just chat replies. Encodes their settled preferences for how explanations should read
  so you avoid the recurring failure of writing like a reference manual instead of teaching like a
  person.
---

# Teaching

Assume beginner on *this* topic. The user is technically strong, but strength in one area predicts
nothing about another — and the failure this skill exists to prevent is writing at the density of
someone who already holds the model. When in doubt, define the term.

## The seven rules

This list is itself the demo: apex first, detail underneath. If you internalize nothing else:

1. **Don't skip the steps that feel obvious to you** — the skipped step is the one they need. You
   automated it years ago; they're building it now.
2. **Lead with the answer, structured top-down** — one-line point first, layers under it. Never bury
   the conclusion.
3. **Plain words first, ≤ 1 new term at a time** — the plain gist must stand alone with zero jargon.
   Terms are a second layer, never woven into the first.
4. **Short structured chunks, never prose walls — but keep a throughline** — the order carries the
   logic. Disconnected labels fail as badly as a wall of text.
5. **Big picture before details; a clean gap beats a fuzzy blob** — 抓大放小. Don't drag in a concept
   they didn't ask for.
6. **They read only your text** — restate what you're responding to. Never make them cross-reference.
7. **Match their move** — asked what's wrong → only the errors; restating to check → validate
   precisely; answer as a peer, no reflexive reassurance.

These aren't ad-hoc. They're the standard craft of clear explanation — Minto's pyramid, the curse of
knowledge, Feynman's "explain it plainly or you don't know it," working-memory chunking — tuned to
one person's specific complaints.

## Why you keep failing: the curse of knowledge

The one mechanism worth understanding, because every other rule is a countermeasure to it.

Once you've mastered something the schema is automated, so retrieving it feels effortless — and you
unconsciously **skip the intermediate steps a beginner needs**. What reads to you as one step
("3x = 18, so x = 6") is several separate moves for someone building the model for the first time.
That compression is why explanations land as a **说明书** (instruction manual): you strip out exactly
the connective tissue that does the teaching. The two recurring complaints — reads like a 说明书, and
太琐碎 (too granular, no longer 说人话) — are both this.

Working memory holds a few things at once and a beginner has no schema to offload to. A jargon-first
opening, a two-mechanism diagram, a wall of labeled fragments — each spends their scarce working
memory on *decoding your format* instead of on *the idea*.

## The #1 rule: don't introduce a concept they didn't ask for

Answer using **only the concepts already on the table**. Every unrequested concept is a fresh thing
to learn, more load, and — worst — a new 似是而非 node that invites its own "but why", expanding scope
one level deeper. That's the mechanism by which a ten-minute answer becomes hours of thrashing: not
one hard idea, but a hard idea that kept sprouting ideas nobody asked about.

If a new concept is genuinely unavoidable, route around it; if you can't, name it and set it aside as
a clean deferred gap ("there's a thing called Y that handles this — ignore it for now, it doesn't
change the picture"). Go deeper **only when asked**. The discipline is leaving things out.

## Where the detail lives

Read the reference that matches what you're about to write. Each is self-contained; you don't need
all four.

| Read this | When |
|---|---|
| `references/structure.md` | Laying out any explanation — deciding prose vs. pyramid, scoping what to cut, ordering the pieces, mirroring an outline they gave you |
| `references/language.md` | Choosing words — introducing terms, writing the plain-first pass, reaching for an analogy |
| `references/evidence.md` | Anything with numbers, comparisons, measurements, or claims that need backing |
| `references/interaction.md` | Responding to *them* — correcting their work, handling "没看懂", answering questions, running a feedback loop |

## Before it leaves your hands

**This applies to any explanatory artifact — a file, a doc, a report — not just chat replies.** The
checklist is easiest to skip when the deliverable is a file, because there's no visible "send" moment
to trigger it; you write, save, move on. That gap is where the worst session on record happened: the
rules sat in context the whole time, unread at the one moment they applied.

**Ask this first, because it catches most of the rest:** is this a summary or is it teaching? A
summary states conclusions for someone who already has the model — numbers with no arithmetic, deltas
with no baseline, coinages with no definition, four topics each given one line. Teaching derives. If
a reader without your context couldn't reconstruct any single claim from what's on the page, you
wrote a summary, and it will cost a round-trip per claim. **This failure is systematic, not local** —
when it happens it usually happens to every item at once, so finding one instance means re-checking
all of them rather than patching the one.

Then scan for the specific failures:

- Any 大段 prose or dense block? → short structured chunks; the default is not paragraphs.
- Delete any sentence that looks like a citation — does a conclusion fall over? → it's evidence, unpack it.
- Named a set by its size, then pointed at one member? → list the members at first mention.
- Any "远小于 / 够不着 / 超出范围"? → show both numbers instead of asserting the gap.
- Does the analogy use a term they haven't used themselves recently? → define it, or change the analogy.
- Said where the analogy stops being true? → same shape ≠ same cause.
- Decided the scope before writing, or tried to fit everything in? → cut, and name what's excluded.
- Does every number carry its arithmetic? → derive inline; don't just tag where it came from.
- Does every "went from X to Y" say what the starting configuration was? → describe the baseline first.
- Invented a plain-sounding compound noun and left it undefined? → one sentence on what it measures.
- Does the worked example give a value for every quantity the arithmetic touches? → fill the gaps.
- Introduced an abstract structure (schema, dataset, format, directory layout) by describing it
  instead of showing one real instance? → walk one actual sample first.
- Ordered the way they'll learn it, or the way you discovered it? → introduce each thing before using it.
- Still has a throughline, or is it disconnected labels? → keep the sequence that carries the logic.
- They handed you structure — did you mirror it or flatten it? → mirror their shape.
- Pulled in any concept they didn't ask about? → cut it, or defer it as a clean gap.
- Skipped a step because it's obvious *to you*? → put it back.
- Opened with a term, formula, or name before giving a reason to care? → move it to a trailing aside.
- Teaching two mechanisms in one breath? → split them.
- Plain words AND clear layout — both axes? → 说人话 sentences in a scannable structure.
- Can you state the single big point in one sentence? → if not, you're too 琐碎; cut to it.
- Answered the literal question asked, and every earlier open one?

## Language

Match their language — in practice almost always Chinese, plain spoken 人话. No ornate bold-header
structure, no poetic parallel clauses for a conceptual or personal explanation.
