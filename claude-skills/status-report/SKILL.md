---
name: status-report
description: >-
  Use when telling him (the user) where work stands. The test: the turn left something changed
  outside the conversation — a file edited, a job now running, a message sent, a form submitted —
  or reports on work of yours that did; if the only product is text in the reply and it is not
  reporting on such work of yours, it is a discussion, not a report. Writing down what was said
  does not count, wherever it lands (a memory, a note, a scratch file, a summary committed to a
  repo). Reports: the recap closing such a turn; the message when something you did is blocked
  on him; a one-line update while something long runs; the first reply after he returns or asks
  what is going on with the work; the rewrite after he answers a report with 什么意思, 没懂 or
  人话. A question about the subject matter, some research, an answer, a chat is answered as an
  answer, however much it found: no stamp, no orientation line, no 要你做什么 line. A question
  about work you did, or about a report you sent, is a report. Two misses account for most
  failures: the closing recap feels like the end of the work rather than a report on it, so it
  goes out as a list of what you did; and running commentary while you work ("checking X now",
  "that rules out Y, trying Z") reads to you as keeping him informed and to him as a wall of names
  he never used. He reads every report cold, so it orients him first and succeeds only if he can
  act on it without asking a question. A report that leaves the conversation (Feishu, Slack) takes
  its shape from here, its surface from `writing-for-people` and its gate from `send-gate`. A
  passage explaining how something works follows `teach`; this file caps a mechanism you
  volunteer, one he asked about is `teach`'s at full depth, and the rest of a report is state,
  never teaching.
---

# Reporting to him

He reads a report the way an on-call engineer reads a handover: he was somewhere else, does not
remember where this thread was, and needs to decide something or confirm nothing needs him. His
name for the standard is zero context: someone holding nothing but this message can follow it.
**The test of a finished report: can he act on it without asking a question?** A noun that would
make him ask "what is that" or an item that would make him ask "so what do I do" means it is not
finished.

## The shape, in the order he needs it

1. **Where we are.** One line holding the project and task in his name for them, one of three
   states — done, blocked on him, still running — and, where this report is the answer to a
   question of his about the work, which question, in his vocabulary — either in that line, or as one sentence of your own
   words ahead of it saying what you understood him to ask, in which case the stamp opens the next
   line, as after 没懂: he does not remember what he asked by the time the answer comes. Where the
   task name and his question are the same words, the in-line form is enough.
2. **Seen, then why, then done.** For a fix: the phenomenon (what a user saw, what a command
   printed, what failed), in terms that need no code to picture; then the cause; then the change.
   For other work: what he would have met before and what he meets now — never the file before
   and the file after. Cause before phenomenon hands him an explanation of something he was never
   shown.
3. **What changed since the baseline.** Numbered, results only, each marked verified or not and by
   what (「复现脚本从 403 变成 200」 is verified; 「应该好了」 is not). An item is named by what broke
   or what he now meets, never by an identifier. The unit of the report is never the unit you kept
   your own books in while working — whatever you were counting or ticking off: tickets, word
   counts, sections moved, which feel like content rather than books when the work is editing
   text. Where nothing he does behaves differently, the item is what the rule or the code now
   requires that it did not. File, ticket and count ride in parentheses; only where he asked in
   that unit (「哪几个文件动了」) is the unit his. Where rounds have accumulated, give the whole
   state — the table, the counts — with the one cell that still needs him marked, not this round's
   delta; every count says which total it is out of.
4. **What he has to decide or do**, with your leaning and its reason in the same sentence, or
   不需要你做什么. A decision that is his — direction or design — gets the options and what each
   costs; an implementation choice is yours, and asking it hands back delegated work. A plan of
   yours that branches is collapsed: what you will do, and the one condition that would change it.
   Where several things need him, the blocker comes first and alone.
5. **What comes next.** One line; anything still running gets a place he can watch it — a log
   path, a command. With more than one thing in flight: what is live, what is next, the single
   blocker, and whether anything else is running at all.

## Where he can point

The first line starts with `[MM-DD HH:MM]` in the local time of the machine the session runs on,
read from `date` now — never from a timestamp seen earlier in the context, which is usually UTC and
cannot be told apart by looking. A rewrite after 没懂 opens with the sentence naming what was wrong
and the stamp opens the next line. Items are numbered wherever there is more than one, so he can
say 「18:40 的第 2 条没说清楚」. A report following an earlier one names it as the baseline (「自
17:50 以来」); the baseline is a stamp from this same machine.

## Every word he must act on is decodable where it appears

- **The noun check.** Every proper noun in the report, whoever wrote it first — you, a subagent, a
  tool, a log, a teammate — is one he used himself or one defined in the line that uses it. The
  words he cannot decode are mostly names you coined during the work (a pool, a gate, a phase
  letter), then repo and paper terms he never used. Define each as what it is, why it exists and
  what it does for him, in terms of something he already uses, then say the sentence again in his
  terms; or replace it with what it does (「登录后本该跳回原页面，现在跳到首页」). His own terms are
  used unchanged, never explained back to him.
- **A subagent's passage gets the noun check before it is compressed.** It arrives organised by
  its author's unit (ticket numbers as item names) in an engineer's vocabulary; compressing it is
  composing it. Its account of how it got there — what it tried, in what order — is cut before any
  renaming.
- **Names he made you replace stay replaced as the item's name**, whether he asked with 什么意思,
  没懂 or 人话 or you caught it yourself, in every later report; the identifier still rides in
  parentheses. Write those names down once in a memory or a file a later turn can read, not only
  into the message that introduced them; where they are no longer visible, re-derive each from
  what the thing does rather than falling back to the identifier.
- **An identifier rides along, never load-bearing.** A ticket number in parentheses after an item he
  understands lets him open it; the same number as the item's name or as the object of the next
  action (「先合 #412」) is noise where the meaning has to be.
- **No word that points outside the message**: 「那行」, 「上面说的」, 「之前那版」, a line number, a
  diff against a draft he never saw. Put the content at the address into the message; a pointer
  swapped for another pointer is a failed repair.
- **Every sentence says who or what is doing the thing.** Subjects go missing in Chinese without
  the sentence breaking.
- **An abstraction arrives with one real instance beside it** (the row, the warning text, the
  value), and the instance says what it is an instance of, in a word he has used or the same line
  defines; a bare example is as unusable as a bare category. Neither half is what the length
  section below cuts.
- In a report written in Chinese, a quotation not in Chinese carries a Chinese translation right
  after it — a line from a file, an error message, a reviewer's sentence, a rule you are proposing —
  in full; the quotation keeps its own words, and identifiers, commands and paths are not
  quotations.

## Organised around his question, never around your work

No headings that are the stages you went through, no numbering only you can read. Where several
objects are in play, name and place every one before any sentence acts on one; where a noun he
used could mean two things, say which you took. A thing with no counterpart he uses is mapped onto
one he does (a mailbox for a queue), with where the mapping stops; an analogy that carries the very
decision he is questioning is not an analogy.

## The report holds the state, never the route to it

A sentence asserting something now true that he has to work with is state; a sequence of actions —
yours or a source's — is route: what was tried, which approach failed, which git operation was
chosen, 「改之前 / 改之后」 of your own text, narration of the report's structure. The one sentence
about the writing a report carries is a rewrite's opening line naming what was wrong. State that is
easy to mistake for route, and stays, stated as the constraint rather than as the story of meeting
it: a limit you are now under, a thing that will break next time, a decision a failure forces, a
tool looked for and found missing, a package installed, where a backup landed, why a retry or a
check was put in or left out, the file and line that made you stop. **Anything another instruction
file requires a report to carry is state**, in item 3 or 4, one clause each unless that file sets
its own depth, and the length section below does not cut it.

## Details stay out unless they change his decision

Length follows what changed, never how long you worked: **a three-hour task that changed one line
gets a three-line report** — stamp and item 1 stay, items 2, 3 and 5 collapse or disappear, item 4
never goes. Mark what was cut with "(details omitted)". The cut falls on evidence, not reasons: the
reason for a leaning stays, a second measurement propping up a conclusion already given goes, a
fact he needs to act on or to reach the conclusion himself stays. A result that overturns something
you told him earlier restates what was measured and how before the new number — what is tested,
how, what you said before, what is true, what it means for him — and one sentence retracts the old
claim; explaining what you meant by it is not a retraction.

## Mechanism: as deep as he asked, or as deep as the decision needs

A mechanism he asked about — a question of his naming the thing, answered in that turn; not a
request for a report, not a topic raised turns ago — is `teach`'s at full depth, whether or not a
decision rests on it. One you volunteer follows `teach` where his decision depends on it and goes
only as deep as the decision needs; `teach`'s checklist runs on that passage, not on the report.
Everywhere else a mechanism is one clause, and "why" is his to ask.

## The moments

- **Turn done.** Full shape, at the length the change earns.
- **Blocked on him.** Full shape; item 4 is the point — one sentence he can answer with one word
  where the options allow it, the options and their costs where they do not.
- **Still running.** Stamp, what is being checked and for which symptom, how long, when the next
  update comes as a duration rather than a clock time. One or two lines. A suspicion in one clause
  is fine; an unconfirmed hypothesis about the thing you are chasing, delivered as mechanism, stays
  in your head until the result is in. That is not silence about anything else: something
  discovered mid-run that changes what he should do, or alters behaviour he would not notice, goes
  to him the moment you see it.
- **He returns, or asks what is going on.** Full shape as of now, even if nothing changed since the
  last stamp — say so and name it.
- **He answers 什么意思, 没懂, 人话, or asks what was actually done.** Below.

## When he did not understand

Rewrite from the top; never extend. The first line says the restart out loud — 「我上一条堆了太多
细节，从头说」, 「那个词是我造的，没解释就用了」, 「我那句话说错了」 — and how long the rewrite runs.
Then from the phenomenon: definitions before mechanism, his questions in his order and numbered,
the text he could not see quoted where he asked, an instance where the first version gave a
category. Repeated 没懂 on one subject usually means one unstated premise the whole thing stands on:
name it, state it, rebuild on it. More structure is the wrong reflex — bold terms, the source
quoted, formatting over unchanged sentences fail again, and one concrete retelling of something he
actually did lands; the one table that lands is one that pins a term, with its columns set to the
questions he is asking, never to the fields the code has. The rewrite carries nothing else — an
appended finding becomes the next 什么意思; send it later, on its own. Run the noun check on the
rewrite itself. The repairs that fail take three shapes: **re-pointing instead of handing over the
thing** (a pointer for a pointer, the rejected term kept, a concession with no definition, "see the
X skill"); **changing the presentation instead of the content** (the same voice with more words,
the same abstraction shorter, more formatting, a glossary above what he holds); **answering
something he did not ask** (a misread question answered more clearly, another experiment instead
of an answer, three options with no leaning).

## Where the detail lives

| Read this | When |
|---|---|
| `references/checklist.md` | Every report, after it is written and before it is sent: the pass runs on the finished text, a rewrite included |
| `references/examples.md` | Before your first report in a session, and again when he has answered one with 什么意思 or 没懂: four reports as sent and as they should have read |
