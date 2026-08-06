# Numbers, evidence, and complete mechanisms

Read before writing anything with numbers, comparisons, or claims that need backing. The unifying
idea: a number without its derivation has to be taken on faith, and faith isn't understanding.

- [Worked examples must be re-runnable](#worked-examples-must-be-re-runnable)
- [Numbers come with their arithmetic](#numbers-come-with-their-arithmetic)
- [Name a set, then list it](#name-a-set-then-list-it)
- [Enumerate to resolve, not to be complete](#enumerate-to-resolve-not-to-be-complete)
- [Qualitative comparisons need both numbers](#qualitative-comparisons-need-both-numbers)
- [Every comparison needs its baseline first](#every-comparison-needs-its-baseline-first)
- [Your own coinages are terms too](#your-own-coinages-are-terms-too)
- [Complete the mechanism: counterfactual and contradiction](#complete-the-mechanism-counterfactual-and-contradiction)

## Worked examples must be re-runnable

Every quantity the arithmetic touches needs a value, including the ones that feel like background.
They read examples by *following the computation*, so a missing input stops them cold.

Failure shape: an example gives the transfer time but never the compute time it's being weighed
against. The first thing they ask is what the missing side costs — a round-trip you paid for nothing.

If a number is genuinely unknown, say it's unknown and say what it would take to get it. Don't quietly
leave the slot empty.

## Numbers come with their arithmetic

By default — not only when challenged.

The rule is easy to under-read as "be ready to justify a constant if pushed." They do push: a bare
`2048` draws "why 2048", and what's wanted is the decomposition (4 × 16 × 32) *and* the design
tradeoff behind it, not the number restated. But by then it has already cost a round-trip.

Write the derivation the first time, inline: `8 × (1 − (7/8)^8) = 5.25`, not a bare `5.25`.

**Provenance is not derivation.** Tagging a number 〔measured〕 or 〔from the paper〕 establishes that
it's *trustworthy* — a different property from being *understandable*. Don't let the tag stand in for
the arithmetic.

Any count you assert must be exact and match the diagram. Ban vague collectives like "那几块" — say how
many.

## Name a set, then list it

Saying how many is the floor, not the fix. **If you will later point at one member, list the members.**

"12 组数据" satisfies "say how many" and still leaves them stuck the moment anything refers back to it:
"the group whose traffic dropped most" has nothing to resolve against, because they never learned what
the twelve were. Cardinality tells them a set exists; only the roster lets them locate an element in it.

So: enumerate at first mention (a bracketed list is enough), or, if the roster genuinely doesn't
matter, phrase later references so they never single one out.

## Enumerate to resolve, not to be complete

The failure mode on the rebound is dumping every identifier.

Asked what "12 组" meant, one reply listed all twelve machine-readable dataset codes and drew "why this
much detail — does it help me understand?" That objection was right. What was needed was how the twelve
were *composed* (4 languages × two modalities, plus 4 topics) and enough to locate the one later singled
out.

Machine identifiers serve reproducibility, not comprehension. Describe the member in words they can
picture ("the Arabic transcripts") and park the codes in an appendix.

## Qualitative comparisons need both numbers

"超出任何场景", "远小于", "够不着" read as conclusions but carry no evidence.

Put the two quantities next to each other and let the gap speak: *the turning point needs about 800
words per unit; a realistic batch of 209 words across 8 units gives 26 each*. Now "out of reach" is
something they can verify rather than take on trust.

## Every comparison needs its baseline first

"555 µs → 270 µs, and communication +213 µs" is unreadable without knowing what the two configurations
were and why each number is what it is. That's exactly the question it draws: why did both sides move,
what was the original setup, what is it now?

Before any "dropped to / rose by / N× faster", spend the line or two on what the starting configuration
looked like and where its number came from. Deltas are meaningless against an unstated baseline, and a
table of them reads as data while conveying nothing.

## Your own coinages are terms too

And they're the most dangerous kind. Real jargon at least *looks* unfamiliar, so you remember to define
it. A plain-sounding compound you invented on the spot — "容量上限", "打满", "重叠" — slips past your own
filter precisely because it reads like ordinary language, while to the reader it's an undefined
quantity: capacity of *what*, measured in *what*?

Any noun phrase you assembled yourself gets one sentence saying exactly what it measures and in what
unit, at first use.

## Complete the mechanism: counterfactual and contradiction

**They test a claim by probing its negation**, so a mechanism explanation isn't finished until it also
says **why the opposite case breaks**. "The fuller it is, the better it hides latency" is only half —
the immediate follow-up is why the less-full case *fails* to hide it. Build both halves in up front:
why it works *and* why the alternative doesn't.

**Pre-empt apparent contradictions.** When you put two facts or constants side by side that *look* like
they conflict — a 32-byte minimum transfer unit next to a 128-byte cache line — they will fixate on the
conflict until it's resolved. Name the seeming contradiction and reconcile it explicitly, rather than
stating both and moving on.
