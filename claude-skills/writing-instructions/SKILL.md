---
name: writing-instructions
description: Load before writing or editing text that a later session will read back as a rule — a skill, a global or per-repository CLAUDE.md, a machine-notes file. The trigger is the durability of the text, not who asked or how small the edit looks: adding one bullet, tightening a description, or turning a lesson from the current session into something permanent all land here. Load it also when deciding *which* file a new rule belongs in, since putting it in the wrong one is the most expensive way to get it wrong. Covers the layer split and precedence, the failure modes that keep recurring in these files, and the review to run before saving.
---

# Writing instructions

Rules are read months later by a reader with none of this context — sometimes a person, usually a model, and the model follows literally what a person would charitably reinterpret.

## Which layer

| Layer | Holds | Editing |
|---|---|---|
| Global `CLAUDE.md` | Principles true across every project and session | **Never on your own initiative.** Propose the wording and wait. |
| Machine notes | One machine's facts: safety rules needed *before* acting, and things costly to rediscover | Present tense, self-contained, lean. Rewrite a changed line as though it had always read that way |
| A skill | Procedures loaded on demand for one kind of work | Freely. A rule that must always hold, but is not universal enough for the global file, belongs here |
| A repository's `CLAUDE.md` | Facts about that codebase | Freely |
| A stored memory | **Evidence** — what happened, what was said, what a system actually does | Freely |

**A rule that must always hold goes in a skill or the global file, never only in a memory.** Memory gives a rule the worst combination there is: present only sometimes, and authoritative whenever it is. When a memory contradicts an instruction the instruction wins, and the memory is what to fix — in the same turn.

## What keeps going wrong

**Explaining how you got there.** A paragraph defending the boundary you chose over the one you rejected, or saying what an earlier draft got wrong, or pricing the alternative — none of it changes what the reader does. **Test: delete the sentence. Does anything change about what gets done?** If not, it was thinking out loud in a file meant for instructions. **The evidence a rule rests on is part of that path, and it is the hardest instance to catch because it reads as rigour rather than as justification** — a dataset name, a paper, a measured count all feel like the thing that makes the rule legitimate, and none of them change what the reader does. Of a mechanism, keep only the part that changes the method: that a failure arrives disguised as the obvious next step tells the reader to hunt for it in finished-looking work rather than in hesitation, and that stays; the study it came from goes. **What a rule prevents is not the same as why you settled on this version of it** — the first lets a reader judge a case the rule never anticipated, so it belongs in the file; the second is a defence of your own choice and does not.

**A sentence that only says what does not apply.** A paragraph about what this file does not cover, or that some reading of it would be wrong, ends with the reader holding no action while occupying the space a rule would have. What separates this from a useful exclusion is placement: an exclusion attached to the line where the action happens stops a specific wrong move and earns its keep — "an instruction is executed, never rewritten" sitting on the rule that rewrites things. The same words in their own paragraph about scope stop nothing.

**Edit history.** Phrasing that only parses against a previous draft. The reader never saw that draft. State what is true now, in present tense, as though it had always read that way.

**Pointers.** Words that fill the subject slot so a grammar check passes them and resolve to nothing for someone reading only this file. **If a rule needs a pointer, it is in the wrong place** — carry the exception inline in the clause that states the rule, rather than writing a better pointer to it.

**Accretion.** One paragraph added per new instance, until a single item carries five sub-headings. The cause is that patterns were being collected instead of the shape underneath them being found. **Before adding the Nth pattern, look for what makes them one thing.** A rule that takes five costumes to recognise will miss the sixth.

**Scoping to a category.** Naming the important-looking half invites the reading that the other half is exempt, and the next instance lands there. An unqualified rule is already universal; a qualifier is a hole.

**Forced parallelism.** Constructing a symmetry the facts do not have, producing a clause that is neat and meaningless. If the parallel needs a wrong word to close, drop the parallel.

**Examples at the wrong grain.** An example earns its place by letting the reader recognise the *next* instance, so it keeps the structure that makes the failure identifiable and drops everything replaceable. **Test: swap every proper noun and every number in it.** Reads the same → those were filler, so write the category instead. Breaks → that detail is load-bearing, so it stays. An example naming a person, a project, a date, or a source is describing one incident and will not be recognised the next time it happens in different clothes; an abstraction that survives every swap because it names nothing has the opposite fault and reads as a riddle.

**A requirement where a boundary belongs.** A capable reader already knows how to do the work, so a directive telling it *how* competes with the task for attention, while a boundary sits inert until the moment it is about to be crossed. "Do not refactor unrelated code" earns its place; "handle edge cases" costs more than it returns. **Test: would a capable reader do this anyway?** If yes it is a requirement and goes, however true it is. Keep boundaries and what this particular person values.

**A step that leaves no trace when skipped.** A step gets reasoned around at the moment it applies: this case does not need the check, it looks done already, a "must" reread as "consider". Nothing in the output shows it happened, so nothing shows it did not. Name what the step produces — a sentence, a file, a named reader — so skipping it leaves a hole rather than a private judgement.

**Contradiction, which is resolved by proximity rather than by reasoning.** Meeting two rules that conflict, a reader follows whichever it saw first or whichever sits nearest the task in hand, and reports having honoured both. Find the collision before saving and cut one side.

**Unenforceable instructions.** A skill body cannot order its own invocation — by the time it loads, it has been invoked. Check that whoever reads the line is positioned to act on it.

**Language.** English throughout. Quote verbatim only where the phrase itself is the artifact — something that has to be recognised word for word. Otherwise paraphrase; a file thick with quotes is an incident log wearing a rulebook's cover.

## Before saving

**A file that will take effect in later sessions, where the moment you save it is the only moment anyone looks at it, gets a subagent review.** That is the global `CLAUDE.md`, the machine-notes file imported into it, and every skill that applies across projects rather than to one directory. A repository's `CLAUDE.md` and a directory-scoped skill are read back inside the work that produced them, by someone positioned to notice when they are wrong.

**The user asked for this review in advance, so a standing "don't spawn subagents unless the user asked" rule is already satisfied for a global file, a machine-notes file, and a cross-project skill.** Spawn one per file without pausing to request permission that exists; only an instruction in the current conversation declining the review withdraws it. Where no subagent is available, any reader who did not write the draft will serve, and your own second pass will not — name that reader in the report, so an unreviewed file is a missing name rather than a private judgement.

Dispatch the `instruction-reviewer` subagent, giving it the path and what you just changed and what it replaced.

Its report is evidence, not a verdict: act on what you agree with, and say what you rejected.

A subagent starts without this conversation, but not without your vocabulary: a word is jargon only relative to a reader, and one common in the text both of you were trained on reads as plain to both of you and as jargon to someone outside the field. Asked to audit their own writing, experts flag about a quarter of the terms that actually stop a newcomer, and a reviewer sharing the vocabulary flags no more. So route what survives to the person the file is for, and treat what they stumble on as the measurement. Every file gets a cold read-back of your own, reviewed or not. Name the higher-layer rule you checked it against, and the memory if one is relevant or "none" if none is, so a skipped check is a missing sentence rather than a private judgement.

Then say which layer it went in and why, so the choice is visible rather than assumed.
