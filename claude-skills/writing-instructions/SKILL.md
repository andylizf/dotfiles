---
name: writing-instructions
description: Load before writing or editing anything that will later be read back as a rule — a skill, a global or per-repository CLAUDE.md, a machine-notes file, a stored memory. The trigger is the durability of the text, not who asked or how small the edit looks: adding one bullet, tightening a description, recording a correction just given, or turning a lesson from the current session into something permanent all land here. Load it also when deciding *which* file a new rule belongs in, since putting it in the wrong one is the most expensive way to get it wrong. Covers the layer split and precedence, the failure modes that keep recurring in these files, and the review to run before saving.
---

# Writing instructions

Rules are read months later by a reader with none of this context — sometimes a person, usually a model, and the model follows literally what a person would charitably reinterpret. Everything here follows from that.

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

**Explaining how you got there.** A paragraph justifying why the rule is scoped this way, why an earlier framing was wrong, what the alternative would have cost — none of it changes what the reader does. <!-- check: ignore --> **Test: delete the sentence. Does anything change about what gets done?** If not, it was thinking out loud in a file meant for instructions. **The evidence a rule rests on is part of that path, and it is the hardest instance to catch because it reads as rigour rather than as justification** — a dataset name, a paper, a measured count all feel like the thing that makes the rule legitimate, and none of them change what the reader does. Of a mechanism, keep only the part that changes the method: that a failure arrives disguised as the obvious next step tells the reader to hunt for it in finished-looking work rather than in hesitation, and that stays; the study it came from goes. **Why a rule exists is not the same as how you reached it** — the first lets a reader judge the case the rule never anticipated and belongs in the file; the second is your route and does not.

**Carve-outs and disclaimers.** A scope carve-out, a note on what this file does not cover, a clarification that some reading would be wrong — each ends with the reader holding no action, and each occupies the space where the positive rule would have gone. Where a wrong reading is genuinely likely, state the right one more precisely instead. Where a concrete hazard exists, attach the warning to the line where that action happens, not to a paragraph about scope.

**Edit history.** Phrasing that only parses against a previous draft. The reader never saw that draft. State what is true now, in present tense, as though it had always read that way.

**Pointers.** Words that fill the subject slot so a grammar check passes them and resolve to nothing for someone reading only this file. **If a rule needs a pointer, it is in the wrong place** — carry the exception inline in the clause that states the rule, rather than writing a better pointer to it.

**Accretion.** One paragraph added per new instance, until a single item carries five sub-headings. The cause is that patterns were being collected instead of the shape underneath them being found. **Before adding the Nth pattern, look for what makes them one thing.** A rule that takes five costumes to recognise will miss the sixth.

**Scoping to a category.** Naming the important-looking half invites the reading that the other half is exempt, and the next instance lands there. An unqualified rule is already universal; a qualifier is a hole.

**Forced parallelism.** Constructing a symmetry the facts do not have, producing a clause that is neat and meaningless. If the parallel needs a wrong word to close, drop the parallel.

**Examples at the wrong grain.** An example earns its place by letting the reader recognise the *next* instance, so it keeps the structure that makes the failure identifiable and drops everything replaceable. **Test: swap every proper noun and every number in it.** Reads the same → those were filler, so write the category instead. Breaks → that detail is load-bearing, so it stays. An example naming a person, a project, a date, or a source is describing one incident and will not be recognised the next time it happens in different clothes; an abstraction that survives every swap because it names nothing has the opposite fault and reads as a riddle.

**A requirement where a boundary belongs.** A capable reader already knows how to do the work, so a directive telling it *how* competes with the task for attention, while a boundary sits inert until the moment it is about to be crossed. "Do not refactor unrelated code" earns its place; "follow code style" and "handle edge cases" cost more than they return. **Test: is this a boundary, or a requirement you thought of yourself?** Keep boundaries and what this particular person values; drop the rest.

**A required step with no guard on it.** A step gets reasoned around at the moment it applies: this case does not need the check, it looks done already, a "must" reread as "consider". Write the step so that skipping it is visible — name what it produces, so its absence is a missing artifact rather than a judgement call.

**Contradiction, which is resolved by proximity rather than by reasoning.** Meeting two rules that conflict, a reader follows whichever it saw first or whichever sits nearest the task in hand, and reports having honoured both. Find the collision before saving and cut one side.

**Unenforceable instructions.** A skill body cannot order its own invocation — by the time it loads, it has been invoked. Check that whoever reads the line is positioned to act on it.

**Language.** English throughout. Quote verbatim only where the phrase itself is the artifact — something that has to be recognised word for word. Otherwise paraphrase; a file thick with quotes is an incident log wearing a rulebook's cover.

## Before saving

**Anything that loads without being asked for gets a subagent review; everything else gets your own read.** That covers the global `CLAUDE.md`, any skill deployed to every machine, and the machine-notes file imported into the global one — each takes effect silently in every later session, and the moment you save is the only moment anyone looks at it. A repository's `CLAUDE.md`, a skill scoped to one directory, and memories are read back inside the work that produced them, by someone positioned to notice when they are wrong: read those yourself, fix what you find, move on.

**He asked for this review, so a standing "don't spawn subagents unless the user asked" rule is already satisfied — the asking happened, in advance, and covers every such file.** Spawn one per file, in parallel, without pausing to request permission that exists. Only a live instruction in *this* conversation — "do it yourself", "no subagents" — withdraws it. The reason he wants an outside reader: re-reading your own draft returns your intent, and every sentence you just wrote looks necessary to you, which is how accretion and route-explaining survive a self-review.

Send it this, filling in the path:

> Review `<path>` as an instruction file: text a person or a model will read back months from now as a rule, with none of the context that produced it.
>
> First read `~/.claude/skills/writing-instructions/SKILL.md` for the failure modes and the layer table. Then go through the target line by line and report every sentence you believe violates one, quoting the sentence, naming the failure, and saying what a reader would wrongly do because of it.
>
> Apply every test named in that file's failure-mode list to every sentence, plus these two: can it be read as permission for the opposite of what it means, and does it survive with no conversation context behind it?
>
> You must return your three most suspect sentences even when you judge the file sound, ranked, with your reasoning. Never reply that it looks fine.

Its report is evidence, not a verdict: act on what you agree with, and say what you rejected.

Then read the whole thing back cold yourself, imagining two readers: a person who saw none of the conversation, and a model that will do exactly what the words say. Name the higher-layer rule and the memory you checked it against, so a skipped check is a missing sentence rather than a private judgement.

Then say which layer it went in and why, so the choice is visible rather than assumed.
