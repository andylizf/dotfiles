---
name: teach
description: >-
  Use whenever your reply will explain how something works — any concept, mechanism, paper, system,
  formula, or piece of technical/abstract material. **The trigger is a property of the answer you
  are about to write, never of the words they asked with.** Check it against your own outgoing
  reply; a question phrased in no particular way still qualifies the moment the answer would
  describe how something works. It applies whether or not they asked for a "lesson", and whether
  the answer lands in chat, in an explanatory file, doc, or report, or in a status report on
  changes you made — that last is the disguise that gets missed, because it still qualifies the
  moment it says how anything works. Encodes their settled preferences so explanations read as
  teaching rather than as a reference manual.
---

# Teaching

**Material he pastes is not material he understands.** A log, an error, a paper, a diff, a message
someone else sent him: he may be handing it over precisely because it means nothing to him yet.
Reading it back in its own vocabulary answers a question he did not ask. Say what it says before
saying anything about it, and define every term inside it that he has not used himself.

Assume beginner on *this* topic. The user is technically strong, but strength in one area predicts
nothing about another — and the failure this skill exists to prevent is writing at the density of
someone who already holds the model. When in doubt, define the term.

**Load `writing-for-people` too, and apply both to the same draft.** The two work on different axes:
that skill decides how the sentences sound, this one decides whether the explanation lands. Neither
substitutes for the other.

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

## The shape of one explanation

The seven rules are properties: plain words, small chunks, no buried conclusion. None of them fixes
an order, and an explanation can satisfy all seven and still leave the reader holding nothing. This
is the order.

**1. Open by naming what is about to be explained, and how much of it.** One line, before anything
else, so they know whether a paragraph or a page is coming. This is not rule 2 restated: rule 2 puts
the substantive answer up front, this declares the scope. Both belong at the top and they are two
different sentences.

**2. Derive from zero, assuming they remember nothing.** Not "assume they are new to the topic" —
assume the context of the conversation itself is gone. Whatever the explanation rests on gets
rebuilt where it is used, never pointed back at.

**3. Never drop the subject.** Every sentence says who or what is doing the thing. A quoted
fragment, a pronoun carried over from an earlier paragraph, a referent that moved while the reader
was following something else — each one stops them to reconstruct who is acting. The pull is
strongest in languages where a sentence still parses with the subject missing. A subject that
is *present but empty* fails the same way and is far harder to see — see *Hand over the thing,
not a pointer to it*.

**4. Close on what it changes.** The last line says what they now do differently, or what the whole
thing was worth reading for. A mechanism described and then abandoned leaves a description with no
use attached. This is not a summary of what was just said; it is its consequence, and it is the one
part that cannot be inferred from the rest.

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

## Define the load-bearing noun before explaining the logic that stands on it

An explanation of a mechanism rests on primitives — the nouns it manipulates ("dead", "a turn",
"the signal it waits for"). If you explain how the system *detects* / *handles* / *decides about* X
without ever saying what X **is**, the explanation floats: every sentence is logic operating on a
term the reader was never handed. They can follow each step and still hold nothing, because the thing
all the steps refer to was never placed on the table.

The diagnostic that makes this unmistakable: **the reader rejects your "too abstract" version and
then your "too detailed" version in turn.** The instinct is to hear that as an altitude complaint and
slide along the abstraction axis — swap the metaphor for code, or code for a metaphor. That is
thrashing on the wrong axis. A metaphor and a code-dump fail *identically* when both skip the
definition; altitude was never the problem, a missing primitive was. When you catch yourself sliding
up and down hunting for the right level, stop — the fix is orthogonal. Name the noun the whole
explanation depends on and define it, concretely, in one or two sentences, *before* any mechanism
that uses it.

Concretely means what it **is**, not what happens to it. "Dead" is not "we stop hearing from it"
(that is a symptom the logic reads); "dead" is "the process that was going to send the completion
signal no longer exists, so that signal will never arrive." Define the state, and its detection is
finally explicable.

This is the curse of knowledge in its purest form: the noun is so automated for you that it never
registers as a thing needing definition. It is the single most common way a "just explain it
concretely" request keeps failing across several tries — and the tell is that you were sliding on
altitude while the reader kept pointing at a word you never defined.

## Hand over the thing, not a pointer to it

Two failures, one shape. Both leave the reader holding an address instead of the content, and both
feel finished as you write them, because you resolve the address instantly and they cannot.

**Failure one: a word that only resolves outside this message.** "That line", "those two", "the one
mentioned above", "the earlier point" — grammatically these are complete subjects, so the
never-drop-the-subject rule waves them through, and they feel like restating because you are naming
the thing you were just discussing. They restate nothing; they point. A reader holding only this
message cannot follow the pointer, and a reader who can follow it still pays for the trip.

**The topic is where this leaks, and the reason is worth knowing.** You rebuild everything the
explanation *rests on*, because that material is obviously new to them. You leave the thing the
explanation is *about* as a pointer, because it is the one item that feels too established to
restate. So an answer can open with "the exception in that rule", derive the exception faultlessly,
and still leave a reader who never learns which rule was meant.

The fix is not a longer pointer. Name the thing: quote the line, state the rule, give the file and
what it says. If naming it costs two sentences, spend the two sentences.

**An address is the hardest pointer to catch, because precision reads as content.** A line
number, a file path with a range, a commit hash, a ticket id, a URL: each is maximally exact,
and exactness feels like the opposite of vagueness, so it never trips the check above. To a
reader who cannot open the thing it points at, an address carries nothing at all, and its
exactness makes it worse than a vague pointer rather than better, because you will build a
whole argument on top of it and they cannot evaluate, agree with, or correct a single step.
A plan whose steps are addresses is not a plan they have been shown. Quote the text that
lives at the address and let the address ride in parentheses for whoever can open it.

**Failure two: a class where an instance was asked for.** Asked to be concrete or specific, they
want the real material — an actual example, the literal text, the exact values, the file with its
real contents. Answering with a sharper description of the category repeats the pointer move, since
a category is an address for its instances. Keep two requests apart here: writing a *rule* for
general reuse means stripping an incident down to its mechanism, while answering a *question* means
producing the incident itself. The first is abstraction doing its job; the second is abstraction
dodging the question.

**One test catches both.** Cut this message loose from everything around it and hand it to someone
who saw none of the conversation. Can they name every noun in it, and point at every concrete thing
it claims? A word that resolves only by looking elsewhere is a defect, and so is a claim that
resolves only into another abstraction.

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

**Pick by what the finished piece will contain, never by whether you feel you already know the
rule.** You will almost always feel that you do — that feeling is the curse of knowledge pointed at
this skill instead of at the subject, and it is how these rules get broken while sitting unread in
context. The trigger is a property of the artifact, not a judgement about yourself: **if the piece
will contain even one number, `evidence.md` is mandatory.**

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
- Every number, one at a time: can the reader compute it from what is already on the page? → each one
  is either an input (say what was measured and how) or a derivation (write the arithmetic inline).
  "I measured it" is provenance, not derivation. **Hardest to catch: a measured number that
  contradicts what the reader would compute from the formula you just gave them** — that one needs
  the arithmetic *and* a sentence on why the expected route fails.
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
- Any word that points outside this message — "that line", "those two", "the one above"? → name the
  thing instead; a pointer is not a restatement, and the topic is where it leaks.
- Asked to be concrete, and answered with a better description of the category? → give the instance:
  the real text, the real values, a real example.
- Explaining logic that acts on a noun ("detect if it's dead") without defining the noun first? → define the primitive (what it *is*) before the mechanism.
- Been rejected as "too abstract" then "too detailed"? → stop sliding on altitude; you skipped a definition — name and define the load-bearing term.
- Opened with a term, formula, or name before giving a reason to care? → move it to a trailing aside.
- Teaching two mechanisms in one breath? → split them.
- Plain words AND clear layout — both axes? → 说人话 sentences in a scannable structure.
- Can you state the single big point in one sentence? → if not, you're too 琐碎; cut to it.
- Answered the literal question asked, and every earlier open one?

## Language

Match their language — in practice almost always Chinese, plain spoken 人话. No ornate bold-header
structure, no poetic parallel clauses for a conceptual or personal explanation.
