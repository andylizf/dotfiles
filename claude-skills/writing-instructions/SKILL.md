---
name: writing-instructions
description: Load before writing or editing anything that will later be read back as a rule — a skill, a global or per-repository CLAUDE.md or a machine-notes file. The trigger is the durability of the text, not who asked or how small the edit looks: adding one bullet, tightening a description, recording a correction just given, or turning a lesson from the current session into something permanent all land here. Load it also when deciding *which* file a new rule belongs in, since putting it in the wrong one is the most expensive way to get it wrong. Covers the layer split and precedence, the failure modes that keep recurring in these files, and a checker to run before saving.
---

# Writing instructions

Rules are read months later by a reader with none of this context — sometimes a person, usually a model, and the model follows literally what a person would charitably reinterpret. Everything here follows from that.

## Which layer

| Layer | Holds | Editing |
|---|---|---|
| Global `CLAUDE.md` | Principles true across every project and session | **Never on your own initiative.** Propose the wording and wait. It takes effect silently in every later session, and that is the only moment it gets reviewed |
| Machine notes | One machine's facts: safety rules needed *before* acting, and things costly to rediscover | Present tense, self-contained, lean. Rewrite a changed line as though it had always read that way |
| A skill | Procedures loaded on demand for one kind of work | Freely. A rule that must always hold, but is not universal enough for the global file, belongs here |
| A repository's `CLAUDE.md` | Facts about that codebase | Freely |
| A stored memory | **Evidence** — what happened, what was said, what a system actually does | Freely |

**A rule that must always hold goes in a skill or the global file, never only in a memory.** Memory gives a rule the worst combination there is: present only sometimes, and authoritative whenever it is. When a memory contradicts an instruction the instruction wins, and the memory is what to fix — in the same turn.

Memory appears here only as somewhere a rule must be routed away from; **writing one is outside this file.** Several checks below invert for it: a memory needs the date a fact was true, the history of how it changed, and the reasoning that produced it, and it quotes verbatim in whatever language was spoken. Run the checker on a memory and it will flag precisely what makes the memory good.

## What keeps going wrong

They share a root: writing down your own path to the rule instead of the rule.

**Explaining how you got there.** The most common one by far. A paragraph justifying why the rule is scoped this way, why an earlier framing was wrong, what the alternative would have cost — none of it changes what the reader does. <!-- check: ignore --> **Test: delete the sentence. Does anything change about what gets done?** If not, it was thinking out loud in a file meant for instructions.

**Edit history.** Phrasing that only parses against a previous draft. The reader never saw that draft. State what is true now, in present tense, as though it had always read that way.

**Pointers.** Words that fill the subject slot so a grammar check passes them and resolve to nothing for someone reading only this file. **If a rule needs a pointer, it is in the wrong place** — carry the exception inline in the clause that states the rule, rather than writing a better pointer to it.

**Accretion.** One paragraph added per new instance, until a single item carries five sub-headings. Each addition felt necessary; the cause is that patterns were being collected instead of the shape underneath them being found. **Before adding the Nth pattern, look for what makes them one thing.** A rule that takes five costumes to recognise will miss the sixth.

**Scoping to a category.** Naming the important-looking half invites the reading that the other half is exempt, and the next instance lands there. An unqualified rule is already universal; a qualifier is a hole.

**Forced parallelism.** Constructing a symmetry the facts do not have, producing a clause that is neat and meaningless. If the parallel needs a wrong word to close, drop the parallel.

**Over-abstracted examples.** Stripping an incident to its mechanism is right for a rule and wrong for an answer. Past a point the abstraction names nothing recognisable and reads as a riddle. Keep an example concrete enough to picture and generic enough to leak no identity; cut it if it cannot be both.

**Unenforceable instructions.** A skill body cannot order its own invocation — by the time it loads, it has been invoked. Check that whoever reads the line is positioned to act on it.

**Language.** English throughout. Quote verbatim only where the phrase itself is the artifact — something that has to be recognised word for word. Otherwise paraphrase; a file thick with quotes is an incident log wearing a rulebook's cover.

## Before saving

Run the checker on every file touched:

```
python3 <skill dir>/scripts/check.py FILE [FILE...]
```

It flags pointers, edit-history phrasing, embedded dates, sentences that explain the route to the rule, accreted structure, and non-English text — exiting non-zero when anything is caught, so it can gate a commit. It decides only what a regex can decide. Text quoted as an example is masked automatically; add `<!-- check: ignore -->` on a line to suppress the rest.

Then read the whole thing back cold, imagining two readers: a person who saw none of the conversation, and a model that will do exactly what the words say.

- Every sentence: does it survive with no conversation context behind it?
- Every sentence: delete it — does the reader do anything differently? If not, it goes.
- Can any line be read as permission for the opposite of what you meant?
- Does it contradict something in a higher layer, or a memory that will surface later?

Then say which layer it went in and why, so the choice is visible rather than assumed.
