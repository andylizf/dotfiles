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
  answer, however much it found: no stamp, no anchor lines, no 要你做什么 line. A question
  about work you did, or about a report you sent, is a report. Two misses account for most
  failures: the closing recap feels like the end of the work rather than a report on it, so it
  goes out as a list of what you did; and running commentary while you work ("checking X now",
  "that rules out Y, trying Z") reads to you as keeping him informed and never reaches him.
  He reads every report cold, so it orients him first and succeeds only if he can
  act on it without asking a question. A report to him on another channel — a message to
  him on Feishu or Slack — takes its shape from here. Posted anywhere anyone else can read it, it
  is a send: `writing-for-people` and `send-gate` each decide their own reach over it. A
  report accounts for the work: results, verification, outstanding work and decisions. `teach`
  helps him understand that account, including what a change means or why a problem remains.
  Both can apply to the same sentences; his request sets how much explanation is needed.
---

# Reporting to him

He reads a report the way an on-call engineer reads a handover: he was somewhere else, does not
remember where this thread was, and needs to decide something or confirm nothing needs him. His
name for the standard is zero context: someone holding nothing but this message can follow it.
**Write every report as though it is the only one he will read.** What he reads is a turn's last
message — his next message ends a turn, while a check of your own that rejects the ending and puts
you back to work leaves the same turn running — plus anything you send him on another channel. The
narration between tool calls never reaches him, and neither does a report you superseded, meaning
one you followed with another message of the same turn before he had spoken: displayed though it
was, it reached no one. So everything he must act on, know or quote back stands after the stamp in
the message you are sending or was never said; where an earlier message of this turn carried it,
state it here again as current fact, never as a correction of a message of this turn.
**The test of a finished report: can he act on it without asking a question?** A noun that would
make him ask "what is that" or an item that would make him ask "so what do I do" means it is not
finished.

## The shape, in the order he needs it

1. **What this session is for, opening with a labelled 目标 line.** The stamp, then these two
   lines, before anything you did:

   ```
   [MM-DD HH:MM]
   目标：<the problem this session exists to solve, in words he uses — his own where he framed it>
   <what the session is working on right now, and which of three states the work is in — done,
   blocked on him, still running — in a sentence or two of ordinary prose>
   ```

   **Only 目标 carries a label; the rest is prose.** 目标 is what the whole session is for, not
   the project's name and not what you did this turn — he arrives holding nothing, and without it
   every line under it answers a question he cannot reconstruct. **It does not move while the
   session runs.** Work that spins off along the way — a tool you had to fix to get on with the
   job, a correction he made to how you report, a detour he sent you on — goes in the line under
   目标, which is why that line says what the session is working on now rather than the shortest
   path to 目标. 目标 is rewritten only where he sets that problem aside and the session stops
   working toward it at all; work he adds while it is still open goes underneath, however unrelated
   it looks and however long it takes. It is the delta in item 2, not 目标, that follows his
   questions. Where this report answers a question of his about the work, that question goes under
   the anchor, in his vocabulary, never a replacement for either of the two — or one sentence of
   your own words ahead of the stamp, as after 没懂: he does not remember what he asked by the time
   the answer comes. Anything still running names a place he
   can watch it — a log path, a command — and where more than one thing is in flight, which is
   live, which is next, the single blocker, and whether anything else is running at all.
2. **What has happened since his last question that opened a subject.** A message of his opens a
   subject when it introduces scope the delta does not already cover; one that only reacts to what
   you just said — a 什么意思, a 不对, a 这个先放着 — does not, however sharply it lands, so the
   delta still runs from the question before it. The baseline is never your own last report.
   Results only, numbered, each marked verified or not and by something that tells him how far to
   trust it or how he would check it again (「复现脚本从 403 变成 200」 is verified;
   「应该好了」 is not; 「部署后逐字节与源码相同」 is neither — it says you did your own
   job, and the deploy either landed or it did not).
   **He does not want the process** — what you tried first, which approach you abandoned, what you
   read, the order you did it in, and least of all the narration of your own wrong turns, which
   reads to you as candour and to him as noise he has to filter.
   Cutting the process is not summarising it either. What a wrong turn leaves behind is not
   process and still reaches him: a constraint he is now under, a claim of yours he is still
   holding that has to be retracted, something you changed and undid that he would want to know
   happened. For a fix the item is what he would have seen going wrong and what happens now, the cause
   only where he needs it to judge; for other work, what he would have met before and what he
   meets now, never the file before and
   the file after. An item is named by what broke or what he now meets, never by an identifier,
   and never in the unit you kept your own books in while working — tickets, word counts, sections
   moved, which feel like content rather than books when the work is editing text. Where nothing
   he does behaves differently, the item is what the rule or the code now requires that it did
   not. A file, a ticket or a count rides in parentheses only where he would open it, or where he
   asked in that unit (「哪几个文件动了」) and the unit is his. **Every result says what he does
   with it**, and where the same fact can be told from his side, that is the version that goes in:
   「我确认了什么」 is yours, 「现在是什么样」 is his.
   Where rounds have accumulated, give the whole state — the table, the counts — with the one cell
   that still needs him marked, not this round's delta, and every count says which total it is
   out of.
3. **What judgment is needed from him**, written as an agenda rather than a paragraph: one
   numbered line per thing that needs him, each carrying its options, what each costs, and your
   leaning with its reason in the same sentence — or 不需要你做什么 and nothing else. A decision
   that is his is direction or design; an implementation choice is yours, and asking it hands back
   delegated work. A plan of yours that branches is collapsed: what you will do, and the one
   condition that would change it. Where several things need him, the blocker is item 1 and alone.

**The stamp opens the report, and the report runs to the end of the message.** He scans the turn's
last message for that stamp and reads from it down; whatever stands before it costs him nothing,
which is where process, thinking aloud and mid-flight commentary belong. That is what makes the
no-process rule executable, and it cuts both ways: two things may precede the stamp and still be
read — a rewrite's opening sentence naming what was wrong, which exists to send him back into the
report rather than away from it, and one sentence of your own words saying what you understood him
to ask.

## The ledger a task keeps when he will hear about it more than once

`notes/open.md`, under the project's own directory and kept out of `logs/` because it is edited
rather than appended to: what was agreed and not done, and the deeper questions he asked that are
still unanswered. An item leaves when it is done or answered, never when it is mentioned. It
outlives any one report, so something still running belongs both there and in the report.

## Where he can point

The first line starts with `[MM-DD HH:MM]` in the local time of the machine the session runs on,
read from `date` now — never from a timestamp seen earlier in the context, which is usually UTC and
cannot be told apart by looking. A rewrite after 没懂 opens with the sentence naming what was wrong
and the stamp opens the next line. Items are numbered wherever there is more than one, so he can
say 「18:40 的第 2 条没说清楚」. A report following an earlier one says where its delta starts by
naming the question it runs from in his own words (「自你问登录为什么跳错页以来」), never by a stamp
alone: a stamp tells him which message, not which subject.

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
  composing it. Unless he asked for the investigation history, cut its account of what it tried
  and in what order before any renaming.
- **Names he made you replace stay replaced as the item's name**, whether he asked with 什么意思,
  没懂 or 人话 or you caught it yourself, in every later report; the identifier still rides where
  he would open it. Write those names down once in a memory or a file a later turn can read, not
  only into the message that introduced them; where they are no longer visible, re-derive each from
  what the thing does rather than falling back to the identifier.
- **An identifier never names an item and never carries the meaning** — a ticket, a file name, a
  count, a commit hash, a branch. It rides in parentheses only where he would open it, or where he
  asked in that unit and the unit is his; the same number as the item's name or as the object of
  the next action (「先合 #412」) is noise where the meaning has to be.
- **No word that points outside the message**: 「那行」, 「上面说的」, 「之前那版」, a line number, a
  diff against a draft he never saw — and equally a noun phrase full of real content words that
  still resolves only outside it, 「你定的那三段」, 「你贴的那段」, which reads as specific and names
  nothing he can reach from here. Put the content at the address into the message; a pointer
  swapped for another pointer is a failed repair.
- **Every sentence says who or what is doing the thing.** Subjects go missing in Chinese without
  the sentence breaking.
- **An abstraction arrives with one real instance beside it** (the row, the warning text, the
  value), and the instance says what it is an instance of, in a word he has used or the same line
  defines; a bare example is as unusable as a bare category.
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

## What earns a place in the report

**Every result says what he does with it**, and where the same fact can be told from his side, that
is the version that goes in. 「我跑了什么」, 「我确认了什么」, 「我装了 X」,
「自审提了几条、接受了几条」, 「部署后逐字节与源码相同」 are yours;
「现在是什么样」, 「下次开工会遇到什么」, 「这台机器上现在有 X」, 「已部署」 are the same
facts as he meets them. Only a fact with no his-side version at all is dropped outright, with no
「(details omitted)」 and no file to point at, because it was never his detail. What another rule
required you to *do* is your side too — writing the memory, filing the backup, making the commit
are done, and he hears about one only where he meets something because of it.

A sentence asserting something now true that he has to work with is state; a sequence of actions —
yours or a source's — is route: what was tried, which approach failed, which git operation was
chosen, 「改之前 / 改之后」 of your own text, narration of the report's structure. Cut that chronology
unless he asks what was tried or how the result was reached; then answer the requested history.
In an ordinary report, the only sentence about the writing itself is a rewrite's opening line
naming what was wrong. State that is
easy to mistake for route stays where he acts on it or where another rule requires it, stated as
what he will meet rather than as the story of meeting it: a limit he is now under, a thing that
will break next time, a decision a failure forces, where a backup landed, why a retry or a check
was put in or left out, the file and line that made you stop. **Anything another rule — in this
file or in another instruction file — requires a report to carry stays**: it rides in item 2 or 3,
one clause each unless that file sets its own depth or he asks for explanation, and the
rules against process, against chronology and on length do not remove it, and neither does any
other rule here; what it requires is told from his side like anything else — the finding and what
you did with it, never how many there were.

## Length follows his request and the work

Default to a brief report sized to what changed, never how long you worked. For a small change,
stamp and item 1 stay, item 2 can collapse, and item 3 never goes. When he asks for a
detailed account, examples or explanation, expand to answer that request; details needed to
understand the work stay even when no decision depends on them. Detail he might later want back is
moved rather than dropped: write it to a file under the project's own directories before the report
goes, and say where it landed, so the marker hands him a path and not only a notice. Evidence that
adds nothing, the process, and a chronology he did not ask for are dropped outright and have no
address, and the same goes for a second measurement propping up a conclusion already established;
keep the reason for a leaning and the facts he needs to understand the conclusion or act on it. A result that overturns something
you told him earlier restates what was measured and how before the new number — what is tested,
how, what you said before, what is true, what it means for him — and one sentence retracts the old
claim; explaining what you meant by it is not a retraction. That covers a claim he read — a
message that ended an earlier turn, or another channel you sent it on, report and answer alike; one that stood only in
this turn's narration or in a message of this turn you superseded never reached him — repair the
file, memory or note it was written into, leave the retraction out, and carry the corrected fact as
current state in item 2 or 3.

## Using teach in a report

This skill keeps the requested work accounted for; `teach` makes that account understandable.
Apply it wherever the reader needs background, an example or reasoning to understand a result,
a changed rule, an outstanding problem or a mechanism. A request for a detailed report can need
all of these without naming a mechanism. Explain each requested item far enough to answer his
question, keeping the other items in view. A brief completion check can stay brief; a request to
understand the whole task needs more than action labels, but does not invite a lesson on every
part of the system. Run `teach`'s checklist on the passages doing that explanatory work.

## The moments

- **Turn done.** Full shape, at the length his request and the change call for.
- **Blocked on him.** Full shape; item 3 is the point — one sentence he can answer with one word
  where the options allow it, the options and their costs where they do not.
- **Unsolicited update while still running.** The anchor, then what is being checked and for which
  symptom, how long, and when the next update comes as a duration rather than a clock time. One or
  two lines under the anchor. A suspicion in one clause
  is fine; an unconfirmed hypothesis about the thing you are chasing, delivered as mechanism, stays
  in your head until the result is in. That is not silence about anything else: something
  you find or do mid-run that changes what he should do, or changes how something behaves in a way
  he would not notice, goes to him the moment you see it — on another channel if one is open — and
  is stated again as current fact in every later message of this turn, the closing report included,
  since a message you superseded reached him as nothing.
- **He returns, or asks what is going on.** Full shape as of now, even if nothing changed since the
  last stamp — say so and name it.
- **He answers 什么意思, 没懂, 人话, or asks what was actually done.** Below.

## When he did not understand

Rewrite the full report requested, even when he names one passage as an example of its failure;
answer only that passage when his question is confined to it. Asking for `teach` keeps the report's
scope: explain the concrete changes and what remains, with the background, examples and reasoning
needed to understand those answers.
For a full rewrite he asked for, after his 什么意思 / 没懂 / 人话 on a report he read, the first
line says the restart out loud — 「我上一条堆了太多细节，从头说」, 「那个词是我造的，没解释就用了」,
「我那句话说错了」 — and what the rewrite covers.
Then from the phenomenon: definitions before mechanism, his questions in his order and numbered,
the text he could not see quoted where he asked, an instance where the first version gave a
category. Repeated 没懂 on one subject usually means one unstated premise the whole thing stands on:
name it, state it, rebuild on it. More structure is the wrong reflex — bold terms, the source
quoted, formatting over unchanged sentences fail again, and one concrete retelling of something he
actually did lands; the one table that lands is one that pins a term, with its columns set to the
questions he is asking, never to the fields the code has. The rewrite carries the whole requested
answer without unrelated appended findings; send those later, on their own. Run the noun check on the
rewrite itself. The repairs that fail take three shapes: **re-pointing instead of handing over the
thing** (a pointer for a pointer, the rejected term kept, a concession with no definition, "see the
X skill"); **changing the presentation instead of the content** (the same voice with more words,
the same abstraction shorter, more formatting, a glossary above what he holds); **answering
something he did not ask** (a misread question answered more clearly, another experiment instead
of an answer, three options with no leaning).

## Where the detail lives

| Read this | When |
|---|---|
| `teach` skill, `references/interaction.md`, "Review the answer against the request" | Before requesting or performing a review of a draft report: establish what the user requested and whether the draft answers it before checking its wording |
| `references/checklist.md` | Every report, after it is written and before it is sent: the pass runs on the finished text, a rewrite included |
| `references/examples.md` | Before your first report in a session, and again when he has answered one with 什么意思 or 没懂: four reports as sent and as they should have read |
