---
name: external-send
description: Load before any write that leaves this machine — committing, pushing, opening an issue or PR, merging, commenting, reviewing, posting, emailing, messaging, or running code that hits a send endpoint. Load it to decide whether Zhifei's approval is needed, not after deciding: concluding "this one is fine" without opening it is the failure this file exists to catch, and the cases that need nothing are in here too. Covers the three repository cases — two of which need no approval at all — the send test and what it deliberately does not reach, why approval for a neighbouring action never covers the prose beside it, what "I showed him" actually requires, and what stays free.
---

# External sends under Zhifei's identity

The one-line rule lives in the Code of Conduct: anything with a person on the other end — received, notified, addressed — needs his per-item approval of the **exact final text**. This file is why that rule exists, how it actually gets broken, and where it deliberately does not reach.

## Why this is not pedantry — the cost lands on him, not you

Sending is not progress. The work was already done before the message; the message only reports it, so the upside of sending it yourself is roughly zero. The downside is unbounded and his to carry.

Every line under his name is a social act with his collaborators: it takes positions he may not hold, concedes things he would have fought, promises work he now owes ("I'll run it tonight" is a commitment *he* has to honor), and sets a tone that becomes how people read him. Being factually correct doesn't protect against any of that — a right answer delivered in the wrong stance still spends his credibility. And he can't take it back: he'd have to walk it back publicly, which costs more than the message was ever worth.

So the accounting is not "helpful vs. cautious." It's "no gain for the task vs. real damage to his standing." When you send without asking, you are not finishing the job faster; you are making a decision that was his to make, with his name on it.

## The send test — run it before every write

One mechanical question: **is there a person on the other end?** Someone who receives this, gets notified of it, or is being addressed by it.

If yes, it needs his per-item approval of the exact text — however small, however factual, however mid-task you are. Run it on every write action, not only on the ones that trigger doubt.

Public is not the same as addressed. A commit landing in a world-readable repository of his has nobody on the other end — no inbox, no notification, nobody being spoken to — and the repository cases below govern it, not this test. Read the question as "could anyone ever see this" and every commit becomes a checkpoint, which is how a rule stops being usable at the moment it matters.

**The failure mode is never "posted without permission". It's never noticing a check was due.**

## Adjacent approval is the trap

It looks like this: he approved editing a document, so replying to comments inside that document felt like the same job. Or he approved merging, so the comment alongside felt included.

Being mid-task with approval for a neighbouring action is the moment of **highest** risk, not lowest — that is exactly when to re-run the send test.

Approval to merge a PR does not authorize the comment posted alongside it, if that comment carries stance, positioning, or commitments ("PRs welcome", "we'll publish the numbers either way" — those create obligations he has to honor).

## "I showed him" means it was in your reply text. Nothing else counts.

He reads the messages you write. He does not see your terminal. A command's stdout, a `cat`, a file you opened, a tool result — none of those reached him, however plainly they were printed on your screen.

So the check before any send is **not** "did I show him this" — that judgement is exactly what fails. It is:

> **Did this exact text, in its final form, as one block, appear in a message I wrote to him?**

Only that. If it lived in a `show` command's output, the honest answer is no.

This subsumes the splice problem rather than sitting beside it: text you assembled from separately-approved pieces was, by construction, never in a message you wrote — so the same check catches it, and there is nothing extra to remember.

## Sends are unsendable

The notification fires the instant the write lands; the recipient has the full text in their inbox before your call returns. Deleting afterwards clears the thread but not their mail, and reads as covering tracks. There is no post-hoc fix, so don't offer one — the only control point is before the call.

If you did send something unapproved: say so immediately, quote verbatim what went out, stop, and don't delete unless he asks.

## Writing code that posts is posting

A script hitting `/comments`, `/replies`, `/messages`, `/issues`, or any send endpoint is the same act as clicking Send. The engineering framing makes it feel like tooling; it isn't. **No automation exemption.**

## What stays free

Editing files and documents he asked you to edit, inline annotations addressed to him (【andy：…】), local drafts. And the first two repository cases below — committing, pushing, opening PRs and merging in his own repositories, private or public — which need no approval and no draft shown.

The line is **document ≠ message**: changing a shared doc's body is editing; writing in its comment threads is messaging people.

## Repository writes: three cases

Identify the case before staging anything. Two repositories can be indistinguishable from inside the working tree and land in different cases, so check who owns it, whether it is public, and whether this particular write lands in front of a person — write access, collaborator status and organization membership are none of them ownership.

**Only the third case waits on him.** The first two are yours to finish: no approval, no draft shown, no pause to check. Stopping to ask inside them is its own failure — it hands him work he already delegated, and a rule that fires everywhere is one he can't rely on anywhere.

**His own, private — or team-internal.** Commit, push, open issues and PRs, merge. Freely, no asking, titles and descriptions included. Merging still needs green checks, or a documented and verified reason a red one is environmental.

**His own, public.** The same freedom to act, and the same no-asking — world-readable is not the same as addressed to someone, and it does not turn the repository into an approval surface. What changes is content, not permission: every addition gets a privacy audit first, every time, judged against everything already published rather than line by line. **That audit is yours to run, not his to sign off** — needing it is never a reason to stop and ask. Such a repository states its own audit standard in its `CLAUDE.md`, and every commit is made under that standard, so that file has to be in context at the moment you commit. Auto-loaded, nothing more to do. Not there, go read it before staging.

**Anyone else's, or anything another person will read.** Third-party, upstream, organization-owned, shared with collaborators — and, wherever it lives, any comment, review, reply or issue aimed at a human. Stop before staging and ask. The test is who is on the other end, not who owns the remote: a reply to a collaborator in his own public repository is this case, and a commit to a repository he shares with nobody is not.

**A free repository does not make everything inside it free.** Approval attaches to a person receiving text, so a reply to someone's comment needs it in a repository where committing, pushing and merging need nothing. Same repository, same page, opposite answer, and the second one is easy to miss precisely because everything around it was free.

## Two worked examples, so this isn't abstract

**Failure 1 — "EXACT final text" read as "the content is what he saw".**
He approved rewriting one numbered section of a long reply, and the assembled comment went out. Reconstructing afterwards, he had read exactly one of its four parts — the rewritten section, which had been typed into a message. The other three existed only in the output of a local tool's `show` command, which he never saw. The assistant believed it had shown him the draft and said so; it had run a command that printed the draft to itself.

Note which rules did *not* fire: the send test passed (it knew a human would receive this, and did ask), and adjacent-approval didn't apply (one action throughout). "EXACT final text" was the only rule in play, and it was misread.

**Failure 2 — enumerated surfaces read as a boundary.**
He approved editing a shared document via an API and adding inline annotations addressed to him. Fourteen comment replies then went out under his name to two senior people he works with — technically accurate, but four of them took positions in an unresolved disagreement inside the group, and one promised overnight work in his name. Nothing was recoverable: the platform emails the full text on write.

The chain: enumerated surfaces read as a boundary → document-editing approval felt adjacent enough to cover replies → writing a script to POST felt like engineering rather than messaging → "the content is correct" felt like sufficient justification. Each link is covered by a rule above; none fired, because no rule was bound to the moment of the write.

## Momentum creep

A session of batch approvals ("批次1可以", "send all of those") builds a habit of executing external actions without per-item sign-off; by the time something genuinely sensitive comes up, the slide feels normal and you post it without asking.

Scoped approval never extends by similarity, momentum, or "the session's rhythm." **The more consecutive approvals he has given, the MORE carefully you should check whether the next action is actually covered.**

## Never hedge his own work

When the subject is **him, or work he had a hand in** — CV, bio, application, cover note, project blurb, README, talk abstract — do not add qualifiers that shrink his contribution. He has stated this as a standing rule for outward-facing writing about himself: no defensive framing.

A shared-credit verb already carries the caveat. `co-developed` / `co-authored` / `led` tells the reader it was collaborative. Appending a ceiling on top of that is a second, unforced concession — it reads as apologising for the work, and nobody on the receiving end was going to assume sole authorship anyway.

Two shapes, both from one editing pass where the assistant hedged twice and was corrected each time:

- A line stating the scale of a collaborative artifact, then volunteering how small a fraction of it he personally built. The verb was already `co-developed`; the fraction was pure giveaway. Fix: say what he built, drop the fraction.
- `led one case study` where `led the case study` was equally true. `one` quietly implies "only one of many"; the definite article concedes nothing and costs nothing.

Scan every self-referential draft for `one of`, `part of`, `for N of them`, `helped with`, `assisted`, `some of`, `a portion of`, `just`, `only`. Cut each unless removing it would make the sentence false. **Accuracy is the constraint; modesty is not.**

This cuts *against* the instinct the rest of this file trains, so hold both: caution about **whether to send** protects him, caution about **how much credit to claim** costs him. Different axes — do not let the first bleed into the second.

## Before showing him any draft

Run it through the `avoid-ai-writing` skill. A draft that reads as obviously AI-written damages his credibility even if the content is right. The skill's hard constraint also applies: scrubbing AI味 ≠ making prose 散/口语/水 — narrow surgery only.

What decides this is the case, not the genre. Everything in the third case gets scrubbed, because a person is going to read it. Nothing in the first two does — a README, a release note, a commit message and a PR description in his own repositories all get the same answer, and it is no. Do not reintroduce a second judgement about which of them counts as prose; the case is the whole test.

The two skills divide cleanly, and keeping them divided is what makes either one usable. **This file decides whether a write needs anything at all. `avoid-ai-writing` only says how to repair the prose once that answer is yes.** It holds no view about cases and must not be read as asserting one — if its wording ever seems to widen the gate, this file governs. The same goes the other way: nothing here overrides how it says to scrub.
