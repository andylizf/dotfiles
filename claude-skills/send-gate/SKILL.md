---
name: send-gate
description: >-
  Load before any repository write and before any text reaches someone other than him — committing, pushing, opening an issue or PR, merging, commenting, reviewing, posting, emailing, messaging, editing or sharing a document other people can open, submitting a form, registering, booking or scheduling, RSVPing, answering an invitation, or code that hits a send endpoint. A click can be a send: if the page records something under his name once you press it, that is a send. Load it to decide whether Zhifei's approval is needed, not after deciding: concluding "this one is fine" without opening it is the failure this file catches, and the cases that need nothing are in here too. **Text addressed to him and to nobody else is not a send — a reply, a direct message or an email to him alone.** A group channel or a shared document is not that, however clearly you wrote it for him: who can read it is looked up here, never assumed. Load even when the task explicitly asks you to send.
---

# The send gate

Anything with a person other than Zhifei on the other end — received, notified, addressed — needs his per-item approval of the **exact final text**, as a confirmation token he types back. Text addressed to him and to nobody else is not that, on any channel whose recipients you can see. A write into a repository he can push to, or onto a page in a team space his account administers, that addresses nobody in particular — no comment, review or reply, no text that pings anyone but him — is not that either, however many people can read it; the three repository cases below govern repository writes, and the document rule below governs pages. A line under his name takes positions he may not hold, promises work he then owes, and sets how people read him; being factually correct protects against none of it. Several checks below leave a named line in your reply — absent from the reply, the check did not happen.

## The send test — run it before every write

One mechanical question: **is there a person other than him on the other end?** Someone who receives this, gets notified of it, or is being addressed by it. **He is not that person**: text addressed to him **and to nobody else** is not a send — a reply, a message or an email to him alone, where you can see who receives it. A group channel, a shared document or anything whose recipient list you cannot see is decided by the lookups below, not by who you had in mind. Notified means the platform pings them — an @-mention, an assignment, a requested review; a name that merely appears in the prose pings nobody. What decides it is whether someone is notified or addressed, not whether the text is risky: the blandest acknowledgement is not exempt.

Run it on every write, however small or factual, however mid-task you are. **Where you cannot tell whether something counts, it counts** — except push access and visibility, which are never settled by doubt: look them up.

A document on a sharing platform — a Drive or Notion page, a wiki — exists to be read, so it is addressed by default; its readers are whoever holds access, which is **a fact to look up, not to infer**. Read the sharing setting and the collaborator list before the first edit and before sharing one you wrote, and quote the returned access value in your reply, literally. Two results make a document free. One is sole access by his own account. The other is a page in a team's shared space — a team wiki or team drive, never a file of his shared with particular people — where the space's member list shows his own account, not merely the account the tool acts as, in its admin or manager role, and the write addresses nobody in particular: no @-mention, no comment, no share with a named person, no link posted to a person or a chat. A notification the platform sends a page's followers on every edit does not count, as a repository's watchers do not; widening who can open it within the team is part of such a write and is audited against the new reach, while opening it to anyone outside the team is a send. Quote the role his account holds in the space beside the access value. The second result is his choice, so that team pages need no round-trip. A failed call, a missing endpoint or a platform with no such setting leaves it addressed.

## What stays free

**No approval and no draft shown:** anything addressed to him and to nobody else on a channel whose recipients you can see — a reply, a direct message to him, an email to him alone; files nobody else can open; local drafts; text he wrote himself and handed over to send verbatim, a line he dictates inside the instruction included — what needs a token is wording you chose; and, in a repository he can push to directly, committing, pushing, opening issues and PRs, merging, titles and descriptions included. A commit message, issue body or PR body that pings nobody but him is free; a comment, review or reply *to* a person other than him is not, in any repository. A document joins the list on either of the two results above; comment threads on a document are messaging people whatever its access. Free of approval is not free of the privacy audit, which runs whenever anyone but him can read the result; whether `writing-for-people` runs is its description's call, and his never seeing the text is not what decides.

## Repository writes: three cases

Before staging anything, **write into your reply** the case number and the three facts that settle it — whether he can push to this repository directly, whether it is public, and whether anyone but him is notified by or addressed in this write (not whether anyone can read it: a public repository he can push to is still case 2). **Push access and visibility are looked up, never inferred**: `gh api repos/<owner>/<name> --jq '.permissions.push, .private'` answers both for GitHub, for the account `gh` is signed in as — check `gh auth status` where that may not be his. The answer settles the case whoever owns the repository: his own, an organization's, a collaborator's are the same case once he can push there. With no lookup possible — no remote, or a host without such an API — a repository nobody but him can open is case 1, and anything else is case 3.

**Only the third case waits on him.** In the first two, **asking whether to commit or push is itself the failure**, and citing this rule while asking shows it was read and set aside. **Push what you committed in those two cases; unpushed is not done.** Commits already in the tree when you started are not yours to push.

**Case 1 — private, he can push directly, nothing in this write addressed to anyone.** Commit, push, open an issue or a PR, merge. **Any text you write there that pings anyone but him — a commit message, an issue, a PR, a release note — is case 3 in full**: the ping travels with the artifact, so the whole text takes a token before the artifact exists. Where the repository requires review before a merge, push access does not bypass it.

**Case 2 — public, he can push directly, nothing in this write addressed to anyone.** The same freedom and the same no-asking; what changes is content. Every addition gets a privacy audit first, judged against everything already published rather than line by line: **does anything here identify a third party, expose work not yet public, carry a credential or an internal identifier, quote him verbatim, or touch his health or personal life?** Read that repository's `CLAUDE.md` before staging and commit under its standard where it is stricter; where it has none, this is the standard. The audit is yours to run, never a reason to stop and ask.

**Case 3 — a repository he cannot push to directly, or a write addressed to someone other than him.** An upstream he contributes to through a fork and a PR — and, wherever it lives, any comment, review or reply aimed at a human other than him. Stop before it goes anywhere and ask. Text that reaches a person takes the token below, an upstream PR's title and description included; the push itself has no wording to approve — what he approves is writing there at all, said in the conversation before you stage.

**The audit turns on reach, not on the case number.** A repository only he can open is outside it; one shared with anyone else is inside it, case 1 included, under the case-2 criterion — `gh api repos/<owner>/<name>/collaborators --jq length` says how many can open a private one, and more than one means the audit runs. A case-3 write is audited wherever it lives, before he sees the draft, because a reply's reach is wherever the recipient forwards it. Outside a repository — a team-space page included, judged against everyone who can open the page — the question is **does this reader have business with each thing in the draft?** The audit leaves **one line in your reply naming who can read this and what you judged the addition against.**

## Approval is a token he types

For sends that require approval under this skill, a task request authorises preparation; only the matching SEND token he types after the exact final text is shown establishes authorisation to send. Existing authorisation for these sends means this approval. Only Zhifei's explicit instruction to change or waive this approval rule changes the requirement; never infer a waiver from an instruction to perform the task.

One reply carries the exact final text as its own block — in a message you wrote to him, since stdout, a `cat`, a file you opened and a tool result never reached him — and the token alone on a line inside a fenced code block, so copying it carries nothing else. Shape it `SEND <item>-<recipient>`, and append `-2`, `-3` when that string would repeat one used earlier this session.

**The send happens once he types that token back, and at no other moment.** A match is that exact string in his reply — not a different capitalisation, not a shortened or modified form; when what arrives is not a match, say what you are still waiting for instead of deciding what he meant. Anything he says after seeing the block is his next instruction, whether it arrives with the token or in a message before it: if it changes what should be sent, the token is void — redraft and propose a new one; if it does not, the token holds and you send. None of these is approval:

- `可以`, `ok`, `go`, `发吧`, a thumbs-up
- the instruction that preceded the draft — "reply to him", "回复一下", "send them an invite" — which says which reply to draft and never authorises sending it
- anything he does to clear a path: granting a permission, supplying an address, fixing a file
- a question, a change of subject, silence

**A token covers one item and one exact draft, and nothing transfers it.** Not to a neighbouring action he approved — editing a document does not cover replying to comments in it, merging does not cover the comment posted alongside. Not to the next item after a run of approvals, and not to a batch he waved through. Not to a whole you assembled from separately approved parts, which was never itself in a message you wrote. Not to the same draft with a word changed. Five sends need five tokens. After a run of approvals, check the next send against this paragraph before it goes, not after.

**Nothing he has not approved is ever in a document anyone but him can open, except a page in a team space his account administers, written without addressing anyone in particular.** What he approves is the resulting text of every passage you changed, as one block, never a description of the change; the changes he asks for accumulate locally and reach the document once, after the token. The same for anything you iterate on with him that needs approval — an upstream PR description, an email.

Never propose a token and send in the same reply. Once you have asked, you do not proceed until he answers.

## Sends are unsendable

There is no post-hoc fix, so don't offer one — the only control point is before the call. If you did send something unapproved: say so immediately, quote verbatim what went out, stop, and don't delete unless he asks.

## Writing code that posts is posting

A script hitting `/comments`, `/replies`, `/messages` or any send endpoint is the same act as doing it by hand, and the same rules decide it. **No automation exemption.**
