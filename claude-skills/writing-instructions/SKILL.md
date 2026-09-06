---
name: writing-instructions
description: Load before writing, editing, or committing text that a later session will read back as a rule — a skill, a global or per-repository CLAUDE.md, a machine-notes file. **The trigger is the durability of the text, not where the wording came from**: adding one bullet, tightening a description, or turning a lesson from the current session into something permanent all land here. So does writing out wording the user dictated, and that is the disguise that gets missed — words arriving finished read as already reviewed, but the sign-off is on the content, never on whether it works as an instruction. Load it also when deciding *which* layer a new rule belongs in, when auditing existing instruction files, and when the user says the model behind the sessions has changed.
---

# Writing instructions

Rules are read months later by a reader with none of this context — sometimes a person, usually a model, and the model follows literally what a person would charitably reinterpret; each generation reads them more literally and more completely than the one they were written for.

## Which layer

| Layer | Holds | Editing |
|---|---|---|
| Global `CLAUDE.md` | Principles true across every project and session | **Never on your own initiative.** Propose the wording and wait. |
| Machine notes | Safety rules you need *before* acting here, and what is costly to rediscover on this box. Beyond those, only what another machine would have no use for | Present tense, self-contained, lean. Rewrite a changed line as though it had always read that way |
| A skill | Procedures loaded on demand for one kind of work | Freely. A rule that must always hold, but is not universal enough for the global file, belongs here |
| A repository's `CLAUDE.md` | Facts about that codebase | Freely |
| A stored memory | **Evidence** — what happened, what was said, what a system actually does. Never the only home of a rule that must always hold | Freely |

**Inside a skill, the description and the body are two layers.** The description is the only text
read before the skill loads, so it carries everything that decides *whether* to load: the trigger,
and every sentence that closes an exemption — that a one-line reply still counts, that being asked
first changes nothing, that the commonest miss is the shape which does not feel like the work at
all. The body is read after that decision and holds what to do once you are here. A trigger rule
written into the body cannot fire: whoever needed it never got that far. **Descriptions reach a
session two ways — a listing of all of them, and a per-turn push of the ones that look relevant to
the task in hand — and they are the only place triggering is governed from.** A rule that must always hold lives in a skill only if the skill's description names the trigger in
words that will be in front of the reader at the moment the rule applies; where no such description
can be written, it is proposed for the global file. A stop is the exception: a stop written into a
skill halts work only while that skill's procedure is running, so a halt wanted everywhere is proposed
for the global file too. Where two skills you own would fire on the same moment, each description
says which one's rules win there and names the other; a skill you cannot edit is named from yours
alone.

**A tool installed on every machine by the same provisioning step is not a machine fact**, however local it looks: how to drive it travels with the work, so it goes to the skill that work belongs to. Where one fact carries both, split it rather than filing the whole where its most obvious half points.

## Auditing a file written for an older model

**A rule written to make an older model comply carries, in its own sentence, the reading it is guarding against**, so that the pass you run when the user says the model has changed can delete it where that misreading has not recurred. That pass's report says which rules it deleted, or that none had; in the global file it proposes the deletion and waits. Emphasis that marks which clause carries the rule is formatting and stays; emphasis that raises the volume of a whole rule — repetition, capitals, "IMPORTANT" — was there to make an older reader comply and comes out, and the rule under it stays or goes on its own merits.

**A sentence that makes the reader stop and ask is a stop, whatever it is called** — "check with me", "confirm before", "wait for a reply". Where continuing wrongly would be cheaper than stopping, say so on the line. A stop written for politeness turns a capable reader into one that asks.

## What keeps going wrong

**Explaining how you got there.** A paragraph defending the boundary you chose over the one you rejected, or saying what an earlier draft got wrong, or pricing the alternative — none of it changes what the reader does. **Test: delete the sentence. Does anything change about what gets done?** If not, it was thinking out loud in a file meant for instructions. **The evidence a rule rests on is part of that path, and it is the hardest instance to catch because it reads as rigour rather than as justification** — a dataset name, a paper, a measured count all feel like the thing that makes the rule legitimate, and none of them change what the reader does. Of a mechanism, keep only the part that changes the method: that a failure arrives disguised as the obvious next step tells the reader to hunt for it in finished-looking work rather than in hesitation, and that stays; the study it came from goes. **What a rule prevents is not the same as why you settled on this version of it** — the first lets a reader judge a case the rule never anticipated, so it belongs in the file; the second is a defence of your own choice and does not.

**A sentence that only says what does not apply.** A paragraph about what this file does not cover, or that some reading of it would be wrong, ends with the reader holding no action while occupying the space a rule would have. What separates this from a useful exclusion is placement: an exclusion attached to the line where the action happens stops a specific wrong move and earns its keep — "an instruction is executed, never rewritten" sitting on the rule that rewrites things. The same words in their own paragraph about scope stop nothing.

**Edit history.** Phrasing that only parses against a previous draft. The reader never saw that draft. State what is true now, in present tense, as though it had always read that way.

**A moved fact.** A fact you move — into another file or another section — is re-asserted as current by the move: check it against whatever can answer (the machine for a path on the deployed layout, an alias in the ssh config, a host a status command reports; the repository or the tool for the rest) before it lands, or mark it unchecked on the line.

**A deliberate lenient ruling reads to a literal reader as a hole**, and a reviewer will propose closing it. Mark it on the line as chosen, in one clause: whose choice, and what it buys.

**Pointers.** Words that fill the subject slot so a grammar check passes them and resolve to nothing for someone reading only this file. **If a rule needs a pointer, it is in the wrong place** — carry the exception inline in the clause that states the rule, rather than writing a better pointer to it.

**Accretion.** One paragraph added per new instance, until a single item carries five sub-headings. The cause is that patterns were being collected instead of the shape underneath them being found. **Before adding the Nth pattern, look for what makes them one thing.** A rule that takes five costumes to recognise will miss the sixth.

**Scoping a rule to the vivid half.** Naming the important-looking half invites the reading that the other half is exempt, and the next instance lands there. **Test: does the failure this rule prevents also happen outside the named set?** If it does, the naming is a hole — cut it and let the rule stand universal, which it already was. If it genuinely does not, that is the rule's scope: keep it, inside the sentence that states the rule.

**Forced parallelism.** Constructing a symmetry the facts do not have, producing a clause that is neat and meaningless. If the parallel needs a wrong word to close, drop the parallel.

**Examples at the wrong grain.** An example earns its place by letting the reader recognise the *next* instance, so it keeps the structure that makes the failure identifiable and drops everything replaceable. **Test: swap every proper noun and every number in it.** Reads the same → those were filler, so write the category instead. Breaks → that detail is load-bearing, so it stays. An example naming a person, a project, a date, or a source is describing one incident and will not be recognised the next time it happens in different clothes; an abstraction that survives every swap because it names nothing has the opposite fault and reads as a riddle.

**A requirement where a boundary belongs.** A capable reader already knows how to do the work, so a directive telling it *how* competes with the task for attention, while a boundary sits inert until the moment it is about to be crossed. "Do not refactor unrelated code" earns its place; "handle edge cases" costs more than it returns. **Test: would a capable reader do this anyway?** If yes it is a requirement and goes, however true it is. Keep boundaries and what this particular person values.

**A step that leaves no trace when skipped.** A step gets reasoned around at the moment it applies: this case does not need the check, it looks done already, a "must" reread as "consider". Nothing in the output shows it happened, so nothing shows it did not. Name what the step produces — a sentence that lands where that step's reader looks, a file, a named reader — so skipping it leaves a hole rather than a private judgement. The named product has to depend on the step having run: one that appears whether or not it did is not a trace but a reassurance, and it is read as evidence the rule held while the rule is being broken.

**Contradiction, resolved by proximity or by blending rather than by reasoning.** Meeting two rules that conflict, a reader follows whichever it saw first or sits nearest the task in hand, and reports having honoured both. A capable one does something worse: it spends effort trying to satisfy both and produces something neither rule asked for. Neither outcome is visible in the result, so the conflict has to be found in the text. **The commonest shape is not a flat contradiction but a rule whose scope lives in a different sentence**, so it reads as unconditional where it sits — the fix is to write that scope into the rule's own sentence rather than leaving it to position. Find the collision before saving and cut one side, or scope it.

**Unenforceable instructions.** A skill body cannot order its own invocation — by the time it loads, it has been invoked. Check that whoever reads the line is positioned to act on it.

**Language.** Write an instruction file in the language it is already in, description included; a new one is English. Quote verbatim only where the phrase itself is the artifact — something that has to be recognised word for word. Otherwise paraphrase; a file thick with quotes is an incident log wearing a rulebook's cover.

## Before saving

**A file that will take effect in later sessions, where the moment you save it is the only moment anyone looks at it, gets a subagent review.** That is the global `CLAUDE.md`, the machine-notes file imported into it, and every skill that applies across projects rather than to one directory; a repository's `CLAUDE.md` and a directory-scoped skill do not get it, because they are read back inside the work that produced them, by someone positioned to notice when they are wrong.

**Dispatching this reviewer is part of this skill: spawn one without asking.** Only an instruction in the current conversation declining the review withdraws it — not the wording having arrived finished, and not the text still being under correction. Each of those three kinds of file gets one review per commit, never none, and one reviewer per file. The version you commit differs from the reviewed one by no more than the fixes you accepted, and where those touched more than a few sentences, only after one more pass; while corrections are still arriving, hold it and run it on that version. Where no subagent is available, any reader who did not write the draft will serve, and your own second pass does not substitute for one — name that reader.

Dispatch the `instruction-reviewer` subagent, giving it the path, everything that changed since the last review, and what it replaced.

Its report is evidence, not a verdict: act on what you agree with, and say what you rejected; passes end when one returns nothing you accept. A reviewer is a literal reader and will lengthen every rule toward covering its edge cases: where a fix grows a rule past a sentence, prefer the short rule.

You cannot find your own jargon by asking which words look hard: a term common in the text you were trained on reads as plain to you and to a subagent alike. Restating every term in plain words finds it instead — the reviewer's restatement pass does this, and on a file with no reviewer you run it yourself: a term that can only be restated by reusing it, or whose plain substitute changes the meaning, is defined where it is used or cut.

**Every instruction file, reviewed or not, gets your own read and three checks.** Read the whole file once, top to bottom and not as a diff, the way a stranger would, and say what stopped you or that nothing did. Check it against the higher-layer rule and say what that changed, or that the file is itself the top layer. Search memory for what bears on it, say what you found or that nothing did, and fix in the same turn a memory that contradicts it. Say which layer the text went in and why.

**The trace has to live where someone who was not in the session can find it.** A note in the report reaches only whoever is already in the room, and goes when the conversation does. For a tracked file that place is the commit, and it carries, said in the report as well: the review's findings, what you rejected and who did it, or that no review ran and why; and what the read and the three checks above produced. A commit changing an instruction file and saying none of this is the hole: a review that leaves no record is one the next editor cannot tell from no review. A file in no repository has no such place: back it up, move it into a repository and load it from there — a symlink at the old path is enough — and then edit.
