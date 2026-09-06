---
name: send-gate
description: Load before any repository write, and before any text that reaches a person — committing, pushing, opening an issue or PR, merging, commenting, reviewing, posting, emailing, messaging, editing or sharing a document other people can open, submitting a form, registering, booking or scheduling, RSVPing, accepting or declining an invitation, or running code that hits a send endpoint. A click can be a send: if the page records something under his name once you press it, that is a send. Load it to decide whether Zhifei's approval is needed, not after deciding: concluding "this one is fine" without opening it is the failure this file exists to catch, and the cases that need nothing are in here too. Covers the three repository cases, the send test, the confirmation token that is the only form his approval takes, why approval for a neighbouring action never covers the prose beside it, what "I showed him" actually requires, and what stays free. This is the gate alone — whether a send may happen, whose approval it needs, and whether the content may be public. What the draft actually says is decided by `writing-for-people`, and clearing this gate settles nothing about that.
---

# The send gate

Anything with a person on the other end — received, notified, addressed — needs his per-item approval of the **exact final text**, given as the confirmation token he types back.

## The cost lands on him, not you

Sending it yourself gains the task nothing that asking first would not: the draft is written either way. The downside is unbounded and his to carry.

Every line under his name is a social act with his collaborators: it takes positions he may not hold, concedes things he would have fought, promises work he now owes ("I'll run it tonight" is a commitment *he* has to honor), and sets a tone that becomes how people read him. Being factually correct doesn't protect against any of that — a right answer delivered in the wrong stance still spends his credibility. And he can't take it back: he'd have to walk it back publicly, which costs more than the message was ever worth.

## The send test — run it before every write

One mechanical question: **is there a person on the other end?** Someone who receives this, gets notified of it, or is being addressed by it.

If yes, it needs his per-item approval of the exact text — however small, however factual, however mid-task you are. Run it on every write action, not only on the ones that trigger doubt. **Where you cannot tell whether something counts, it counts.**

Public is not the same as addressed. A write landing in a world-readable repository he can push to — a commit, a tag, a release note, a PR title — has nobody on the other end: no inbox, no notification, nobody being spoken to. The repository cases below govern it, not this test. Read the question as "could anyone ever see this" and every commit becomes a checkpoint.

A document is the opposite case, on the same reasoning: it exists in order to be read, so it is addressed by default, and its readers are whoever holds access — named collaborators, everyone in his organization, a link already forwarded. **Who holds access is a fact to look up, not to infer.** Read the sharing setting and the collaborator list before the first edit, and before sharing one you wrote; quote the returned access value in your reply, literally rather than as a summary, because absent from the reply the check did not happen. Sole access by his own account is the only result that moves a document to the free list — a failed call, an endpoint that does not exist, or a platform with no such setting leaves it addressed.

## Approval is a token he types

Approval you inferred is not approval. It has one form: a string he types back.

**This governs sends to a person.** Committing, pushing, opening PRs and merging in a repository he can push to directly, where the write itself is not addressed to anyone, are repository cases 1 and 2 below; they take no token and no pause.

One reply carries the exact final text as its own block, and the token alone on a line inside a fenced code block, so copying it carries nothing else. Shape it `SEND <item>-<recipient>`, and append `-2`, `-3` when that string would repeat one used earlier this session. Redrafting the same request to the same person is exactly where the collision falls, and a reused string makes a spent approval look live.

**The send happens once he types that token back, and at no other moment.** A match is that string and nothing else: not a different capitalisation, not the token with punctuation or other words around it, not a shortened form. When what arrives is not a match, say what you are still waiting for instead of deciding what he meant.

A token names one draft. Change a word of that draft and the token is void; issue a different one. None of these is approval:

- `可以`, `ok`, `go`, `发吧`, a thumbs-up
- the instruction that preceded the draft ("reply to him", "send them an invite")
- anything he does to clear a path: granting a permission, supplying an address, fixing a file
- a question, a change of subject, silence

One token per item: five sends need five tokens. "Reply to this thread" and "回复一下" mean that one reply drafted and waiting, not every message in the session, and never authorisation to send.

**Nothing he has not approved is ever in the document**, because every write puts its text in front of whoever holds access. The unit and the timing both fall out of that. What he approves is the resulting text of every passage you changed, shown as one block, never a description of what changed. The changes he asks for accumulate in a local draft until then — every one of them carried out, reaching the document once, after the token, rather than one write per message he sends. Views arriving after he has seen the block void its token, like any other change to a draft. This holds for anything you iterate on with him that needs approval at all: a PR description in a repository he cannot push to, or an email, as much as a document.

Text he wrote himself and handed over to send verbatim is already his — send it. The token is for text you drafted.

Never propose a token and send in the same reply. Once you have asked, the answer is required.

## Adjacent approval is the trap

It looks like this: he approved editing a document, so replying to comments inside that document felt like the same job. Or he approved merging, so the comment alongside felt included.

Being mid-task with approval for a neighbouring action is the moment of **highest** risk, not lowest — that is exactly when to re-run the send test.

Approval to merge a PR does not authorize the comment posted alongside it. The blandest acknowledgement you can write is not exempt: what needs approval is the notification it fires, not the stance it carries. And a throwaway courtesy can promise work he then owes, which is worse than a position, because he cannot decline it without looking like he is going back on something.

## "I showed him" means it was in your reply text. Nothing else counts.

He reads the messages you write. He does not see your terminal. A command's stdout, a `cat`, a file you opened, a tool result — none of those reached him, however plainly they were printed on your screen.

So the check before any send is **not** "did I show him this" — that judgement is exactly what fails. It is:

> **Did this exact text, in its final form, as one block, appear in a message I wrote to him?**

Only that. If it lived in a `show` command's output, the honest answer is no.

The same check catches text you assembled from separately-approved pieces: that assembled whole was never itself in a message you wrote.

## Sends are unsendable

The notification fires the instant the write lands; the recipient has the full text in their inbox before your call returns. Deleting afterwards clears the thread but not their mail, and reads as covering tracks. There is no post-hoc fix, so don't offer one — the only control point is before the call.

If you did send something unapproved: say so immediately, quote verbatim what went out, stop, and don't delete unless he asks.

## Writing code that posts is posting

A script hitting `/comments`, `/replies`, `/messages`, `/issues`, or any send endpoint is the same act as clicking Send. The engineering framing makes it feel like tooling; it isn't. **No automation exemption.**

## What stays free

Editing files nobody else can open, and local drafts. And the first two repository cases below — committing, pushing, opening PRs and merging in any repository he can push to directly, private or public, where the write itself is not addressed to anyone — which need no approval and no draft shown. Free of approval is not free of the privacy audit: anything readable beyond his collaborators is audited, and that audit is yours to run.

A document joins that list only once the lookup in the send test shows his account is the only one holding access. Comment threads on a document are messaging people whatever the document's access.

## Repository writes: three cases

Identify the case before staging anything, and **write the answer into your reply**: the case number, plus the two facts that settled it — whether he can push to this repository directly, and whether this particular write lands in front of a person. Absent from the reply, the step did not happen. **Push access and visibility are facts to look up, not to infer**: `gh api repos/<owner>/<name> --jq '.permissions.push, .private'` answers both for GitHub, and the answer settles the case whoever owns the repository — his own, an organization's, a collaborator's are all the same case once he can push there. The call reports the access of whatever account `gh` is authenticated as, so where that may not be his, confirm with `gh auth status` before trusting it. **Where no lookup is possible** — no remote at all, or a host with no such API — a repository nobody but him can open is case 1, and anything else takes his say-so in the conversation before you stage. Two repositories can be indistinguishable from inside the working tree and land in different cases, so run the lookup rather than reading the working tree.

**Only the third case waits on him.** The first two are yours to finish: no approval, no draft shown, no pause to check. Stopping to ask inside them is its own failure — it hands him work he already delegated. **Asking whether to commit or push is itself that failure**, and citing this rule while asking does not soften it: it shows the rule was read and set aside. **Always push what you committed in those two cases — an unpushed change is not done.** Commits already in the tree that you did not make are not yours to push.

**Case 1 — a private repository he can push to directly, and this write not addressed to anyone.** His own, his team's, a collaborator's: who owns it changes nothing once the lookup says he can push. Commit, push, open an issue or a PR, merge. Freely, no asking, titles and descriptions included. **An issue or PR that asks a named person for something is case 3**: the artifact is free, the request inside it is not. And push access is not permission to bypass what his collaborators put in place — where the repository requires review before a merge, that requirement stands.

**Case 2 — a public repository he can push to directly, and this write not addressed to anyone.** The same freedom to act, and the same no-asking — world-readable is not the same as addressed to someone, and it does not turn the repository into an approval surface. What changes is content, not permission: every addition gets a privacy audit first, every time, judged against everything already published rather than line by line. **That audit is yours to run, not his to sign off** — needing it is never a reason to stop and ask. Where the repository states its own audit standard in its `CLAUDE.md`, every commit is made under that standard, so that file has to be in context at the moment you commit: auto-loaded, nothing more to do; not in context, go read it before staging. Where it states none, the standard is what the audit paragraph below sets for reach beyond his collaborators.

**Case 3 — a repository he cannot push to directly, or a write addressed to someone.** An upstream he contributes to through a fork and a PR — and, wherever it lives, any comment, review, reply or issue aimed at a human. Stop before it goes anywhere and ask. The test is who is on the other end, not who owns the remote: a reply to a collaborator in a repository he pushes to freely is this case, and a commit to a repository he shares with nobody is not.

The two limbs take different approvals. Text addressed to a person takes the token below, because there is exact wording to approve. A write into a repository he cannot push to has no wording to approve — what he approves is writing there at all, said in the conversation, before you stage.

The privacy audit applies here too, and the reach is someone else's to control once it lands. Run it on the draft *before* he sees it, so what he is approving is already clean. His approval is for the message; it is not a second pass that catches what you left in.

Outside a repository there is no `CLAUDE.md` stating the standard, and a publication standard is the wrong one to borrow: a letter to a clinic is supposed to carry his health, and words he wrote himself are supposed to go out as he wrote them. The question here is narrower — **does this recipient have business with each thing in the draft?** What leaks is the detail that came from somewhere else and rode along: a third party named in passing, unpublished work offered as context, an identifier that was in your buffer. Cut those. What he is actually writing about stays.

**Audit and approval are different questions with different triggers, and they turn on different facts.** Approval turns on push access and on who is on the other end; **the audit turns on reach — who can open this repository, which is a separate lookup and never follows from the case number.** A commit to a public repository he can push to is audited and needs no approval; a reply to a collaborator needs both. A repository only he can open is outside the audit; **one shared with anyone else is inside it, case 1 included**, because a private repository with outside collaborators reaches exactly the readers the audit exists for. A case-3 write is audited wherever it lives: a reply's reach is not the repository's reach — it is wherever the recipient forwards it.

The audit leaves a product or it did not happen: **one line in your reply naming who can open this repository and what you judged the addition against.** Where the repository states no standard of its own, the standard is that every part of the addition is the business of the people who can read it — a third party named in passing, unpublished work from elsewhere, an identifier that was in your buffer are cut whether or not they are on topic.

**A free repository does not make everything inside it free.** Approval attaches to a person receiving text, so a reply to someone's comment needs it in a repository where committing, pushing and merging need nothing. Same repository, same page, opposite answer, and the second one is easy to miss precisely because everything around it was free.

## A worked failure

**Passing some of these checks is not passing the gate.** Enumerated surfaces read as a boundary:
He approved a set of changes to a shared document, made via an API, along with the inline annotations addressed to him that came with them. A batch of comment replies then went out under his name to people he works with — technically accurate, but several took positions in an unresolved disagreement, and one promised overnight work in his name. Nothing was recoverable: the platform emails the full text on write.

The chain: enumerated surfaces read as a boundary → document-editing approval felt adjacent enough to cover replies → writing a script to POST felt like engineering rather than messaging → "the content is correct" felt like sufficient justification. Each link is covered by a rule above; none fired, because no rule was bound to the moment of the write.

## Momentum creep

A run of quick releases — a token typed back for item after item, or a "send all of those" you let stand for a batch — builds a habit of executing external actions without per-item sign-off; by the time something genuinely sensitive comes up, the slide feels normal and you post it without asking.

Scoped approval never extends by similarity, momentum, or "the session's rhythm." **The more consecutive approvals he has given, the MORE carefully you should check whether the next action is actually covered.**

## Every draft goes through `writing-for-people`, shown to him or not

Run it through the `writing-for-people` skill. Its opening asks you to write one line naming the reader, the medium the text lands in, and the register. **Write that line into your reply before drafting.** It is the product of this step: absent from the reply, the step did not happen, whatever you read. What stays in the draft is settled by that line, not by the checklists further down — a draft can be clean of every AI tic and still be the wrong draft, so clearing this gate is no evidence the content is right.

The case decides whose approval the send needs. It does not decide whether that skill runs: every draft you wrote goes through it, a README, a release note, a commit message and a PR description in a repository he can push to included — including case-1 and case-2 writes, which he never sees. Text he wrote himself is exempt, as above: it goes out in his words. Whether the `writing-reviewer` subagent also runs is that skill's question, not this gate's.
