---
name: status-report
description: >-
  Use when telling him where work stands: the recap closing any turn that changed a file, ran a
  job, or reached a finding; the message when work is blocked on him; a one-line update while
  something long runs; the first reply after he returns to a session or asks what is going on; and
  the rewrite after he answers a report with 什么意思, 没懂 or 人话. A turn that only answered a
  question is not a report and does not load this. Two misses account for most failures. The
  closing recap feels like the natural end of the work rather than a report on it, so it goes out
  as a list of what you did. And running commentary while you work ("checking X now", "that rules
  out Y, trying Z") reads to you as keeping him informed and to him as a wall of names he never
  used. He switches between many projects and reads every report cold, so the report orients him
  before it says anything else, and it succeeds only if he can act on it (decide, approve, move
  on) without asking a question. A report that leaves the conversation — a Feishu or Slack message
  telling him where things stand — takes its shape from here and its surface from
  `writing-for-people`. The passage of a report that explains how something works follows `teach`,
  and this file caps how deep a mechanism you volunteer goes — one he asked about is `teach`'s at
  full depth; the rest of a report is state, never teaching.
---

# Reporting to him

He reads a report the way an on-call engineer reads a handover: he was somewhere else, he does not
remember where this thread was, and he needs to decide something or confirm that nothing needs him.
His own name for the standard is zero context: write it so that someone holding nothing but this
message can follow it. Every rule below serves that reader. The test of a finished report: **can he
act on it without asking a question?** If any noun in it would make him ask "what is that", or any
item would make him ask "so what do I do", it is not finished.

**Every sentence says who or what is doing the thing.** Subjects go missing in Chinese without the
sentence breaking, so the fault survives a re-read.

**An abstraction arrives with one real instance beside it**: the actual row, the actual warning
text, the actual value. A category names where its instances live; he cannot act on that, so hand
him one. And the instance says what it is an instance of, in a word he has used or one the same
line defines — the row, the warning text, the value, each named by what it shows; a bare example is
as unusable as a bare category, because he cannot map it. Neither half is what the length rules cut.

## Where he can point

The first line starts with a stamp, `[MM-DD HH:MM]`, in the local time of the machine the session
runs on, read from `date` at the moment of writing — never from a timestamp seen earlier in the
context: those are usually UTC, and you cannot tell by looking. Items are numbered wherever there is
more than one. He refers back by stamp and number (「18:40 的第 2 条没说清楚」), so a report
without them cannot be pointed at. A report following an earlier one in the same thread names it as
the baseline (「自 17:50 以来」), so what changed is measured against something he can find; the
baseline is a stamp you wrote from this same machine, since a stamp from another one is a different
clock.

## The shape, in the order he needs it

1. **Where we are.** Project and task, using his name for it wherever he named it, then one of
   three states: done, blocked on him, still running. One line. After a long detour this line also
   restates which of his questions is being answered: he asks 「我们之前的问题是什么」 when it is
   missing.
2. **What was seen, then why, then what was done.** For a fix: the phenomenon first (what a user
   saw, what a command printed, what failed), in terms that need no code to picture; then the cause;
   then the change. For any other work: what he would have met before and what he meets now — never the file
   before and the file after. Cause before
   phenomenon is how a report becomes unreadable — he is handed an explanation of something he was
   never shown.
3. **What changed since the baseline.** Numbered, results only, each marked verified or not and by
   what (「复现脚本从 403 变成 200」 is verified; 「应该好了」 is not). **Each item is named by what
   broke or what a user now sees, never by an identifier** — a PR number is the usual one. The unit
   of the report is never the unit you kept your own books in while working, whatever you were
   counting or ticking off — and when the work is editing text, word counts and sections moved
   feel like content rather than books. An item is what now happens differently, said in the situation he would
   meet it; where nothing he does behaves differently, it is what the rule or the code now requires
   that it did not. The file, the ticket and the count ride in parentheses. Only where he asked in
   that unit (「哪几个文件动了」) is the unit his.

   **Where rounds have accumulated, give the state, not this round's change.** A net-change log
   reads to you as the news and to him as arithmetic against a total he never held; he answers it
   with 「到底现在是什么情况」. Draw the whole current picture — the counts, the table, whatever the
   buckets are this time — mark the one cell that still needs him, and let the delta live inside it.
   Where you give counts out of a total, every count says which total: three numbers over three
   different denominators in one line is the shape that fails.
4. **What he has to decide or do**, with your leaning and the reason for it in the same sentence.
   Or 不需要你做什么. The question is about direction or design, asked plainly, with the options and
   what each costs; an implementation choice is yours to make, and asking it hands him work he
   delegated. Where several things need him, the one that blocks comes first and alone. **A plan
   that branches three ways is not something he can decide** — collapse it: say what you will do,
   and name the one condition that would change it.
5. **What comes next.** One line. Anything still running gets a place he can watch it: a log path,
   a command. Where more than one thing is in flight: what is live, what is next, the single
   blocker, and whether anything else is running at all (「除此之外没有别的在飞了」).

## Every noun he must act on is defined where it appears

The words he cannot decode are, overwhelmingly, names you coined during the work for things you
built: a pool, a gate, a handle, a mode, a marker, a phase letter. To you each is the thing; to him
it is noise, and he cannot approve or reject noise. Repo and paper terms he never used are the next
group. Define each as what it is, why it exists and what it does for him, in terms of something he
already uses, and then say the sentence again in those terms; or replace it with what it does
(「登录后本该跳回原页面，现在跳到首页」). The judge: every proper noun in the report — yours, a
subagent's, a tool's — is one he used himself, or one defined in the line that uses it. Where a term is his own — he named the project,
the machine, the script — use it unchanged and do not explain it back to him. Call this the noun
check; it is referred to below.

**An identifier is fine riding along and never fine load-bearing.** A ticket or PR number in
parentheses at the end of an item he can already understand costs him nothing and lets him open it.
The same number as the name of the item, or as the object of the next action (「先合 #412」), is a
word he cannot decode standing where the meaning has to be.

A word that points outside the message fails the same way: 「那行」, 「上面说的」, 「之前那版」, a line
number, a diff against a draft he never saw. Put the content at the address into the message; a
pointer is not a restatement, and replacing one pointer with another is a failed repair.

**A noun you did not coin fails the same test as one you did**: a function name in a subagent's
report, a ticket number in a tool result, a branch in a log, a term in a teammate's message.
Compressing such a passage into your report is composing it, and a passage a subagent wrote for
you is the one most likely to carry its unit — ticket numbers as item names — into the report;
check its nouns before its sentences. A source's account of how it got there is route and is cut
before any renaming: renamed route is still route.

**Names he made you replace stay replaced as the name of the item** — whether he asked with
什么意思, 没懂 or 人话, or you caught the fault yourself — in every later report, whatever form the
next material arrives in; the identifier still rides in parentheses. Write those names down once
where a later turn can read them, not only into the message that introduced them; where you can no
longer see them, re-derive each name from what the thing does rather than falling back to the
identifier.

**The report is organised around his question, never around your work.** Headings that are the
stages you went through, a numbering scheme that only means something to you: each makes him reconstruct your route before he can find his answer. Where
several objects are in play, name and place every one of them before any sentence acts on one, and
where a noun he used could mean two things, say which one you took it as rather than picking
silently.

Where a thing has no counterpart he already uses, map it onto one he does — a mailbox for a queue,
a duvet cover for a flat sheet, a laptop's sleep for a suspended machine — then say where the
mapping stops. An analogy that carries the very design decision he is questioning is not an
analogy; it is a way of not answering.

## The report holds the state, never the route to it

This covers the work and the writing alike, and a source you relay as much as yourself: no account
of what you or it tried, which approach failed, which git operation was chosen, no 「改之前 / 改之后」 of your own text, no narration of the report's
own structure. A rewrite after he says he did not understand opens by naming what was wrong with
the previous message; that line is required, and it is the only sentence about the writing a report
carries.

The test for what is route and what is not: a sentence asserting something now true that he has to
work with is state; a sequence of your actions is route. A limit you are now under, a thing that
will break next time, a decision a failure forces, a tool you looked for and found missing, a
package you installed, where a backup landed, why a retry or a check was put in or left out, the
file and line that made you stop — each is state, stated as the constraint rather than as the story
of meeting it. **Anything another instruction file requires a report to carry is in this class and
stays**, in item 3 or item 4, at one clause each unless the file requiring it sets its own depth, and
the length rules below do not cut it.

## Details stay out unless they change his decision

Length follows what changed, never how long you worked. **A three-hour task that changed one line
gets a three-line report**: the stamp and item 1 stay, items 2, 3 and 5 collapse to one line each or
disappear where they have nothing to say, and item 4 never goes — 不需要你做什么 is itself the
answer he needs. Mark what was cut with "(details omitted)" so he knows there is more and can ask.

The cut falls on evidence, not on reasons. The reason for a leaning is what he judges it by and it
stays; a second measurement propping up a conclusion he has already been given is what goes. A fact
he needs in order to act, or one that lets him reach the conclusion himself, is content and stays.

**A result that overturns something you told him earlier restates what was being measured and how
before it gives the new number.** A table he cannot place is the usual form: the numbers are right
and he has no idea what they are numbers of. Inside item 2, the order that lands is what is being
tested, how, what you said before, what is actually true, what it means for him. Where the earlier
claim was wrong, one sentence retracts it, then the corrected mechanism; explaining what you meant
by it is not a retraction.

## Mechanism: as deep as he asked, or as deep as the decision needs

**A mechanism he asked about is `teach`'s at full depth, whether or not a decision rests on it.**
Asked about means a question of his that names the thing, answered in the turn that answers it —
not a request for a report, which asks for state, and not a topic he raised some turns ago.
Everything else is a mechanism you are volunteering. Where what he decides depends on it, that
passage is teaching and follows `teach` — define the noun, derive from what he already holds, one
mechanism at a time — and goes only as deep as the decision needs; `teach`'s checklist runs on that
passage and not on the report around it. Where nothing he decides depends on it, a mechanism is one
clause (「因为会话里没有组织信息」), and "why" is his to ask.

## The moments

- **Turn done.** Full shape, at the length the change earns.
- **Blocked on him.** Full shape; item 4 is the whole point. Put the question in one sentence he
  can answer with one word where the options allow it.
- **Still running, mid-task.** Stamp, what is being checked and for which symptom, how long, when
  you will report next as a duration rather than a clock time. One or two lines. An unconfirmed hypothesis about the thing you are chasing
  stays in your head until the result is in: a dozen undefined names and a guess are not information
  he can use. This is not silence about anything else — something you discover mid-run that changes
  what he should do, or that alters behaviour he would not notice, goes to him the moment you see
  it.
- **He returns, or asks what is going on.** Full shape as of now, even if nothing changed since the
  last stamp: say so, and name that stamp.
- **He answers 什么意思, 没懂, 人话, or asks what was actually done.** Below.

## When he did not understand

Rewrite from the top; do not extend. **Say the restart out loud in the first line** — 「我上一条堆了
太多细节，从头说」, 「那个词是我造的，没解释就用了」, 「我那句话说错了，你的理解是对的」 — and say how
long the rewrite runs. Then restart from the phenomenon: definitions before mechanism, his questions
in his order and numbered, the text he could not see quoted in the part he asked about, a concrete
instance where the first version gave a category.

**Look for the premise you never stated.** Repeated 没懂 on the same subject usually means one
unstated thing the whole explanation stands on, not that the words were too hard — say which premise
was missing, state it, then rebuild on it. Where a term needs pinning down, a small table lands it,
with the columns set to the questions he is asking, never to the fields the code happens to have.

**More structure is the wrong reflex.** Told 没懂, the pull is to add a table, bold the key terms,
quote the source. It fails, and it fails again on the next try, because presentation was never what
was missing. What lands is one concrete retelling: walk through something he actually did, with the
real values, and let the rule fall out of it.

**A rewrite carries nothing but the rewrite.** Appending an unrelated item — a second finding, a new
question, something you happened to fix — undoes the repair: he is back to two threads at once, and
the appended one becomes the next 什么意思. Send it later, on its own.

Then run the noun check on the rewrite itself, because a good rewrite usually leaves the next
undefined name standing and draws the next 什么意思.

Three shapes account for the repairs that fail, and each feels like progress while you write it.
**You re-pointed instead of handing over the thing**: a pointer swapped for another pointer, the
term he just rejected kept, a concession with no definition behind it, "see the X skill". **You
changed the presentation instead of the content**: the same voice with more words, the same
abstraction stated shorter, more formatting over unchanged sentences, a glossary pitched above what
he holds. **You answered something he did not ask**: a misread question answered more clearly,
another experiment run instead of an answer, three options handed back with no leaning.

## Before sending

Each line here is the short form of a rule above; where they differ, the rule above governs.

- Stamp matches `date` run now on the machine this session is on; items numbered wherever there is
  more than one.
- First line names the task and one of the three states.
- Phenomenon before cause; cause before fix.
- Every item named by what broke, what he sees, or what now holds that did not; files, tickets and
  counts ride in parentheses and carry nothing.
- Every result marked verified or not, and by what.
- Every sentence has a subject that names something.
- No word that points outside the message — including 「那行」, which is a subject and passes the
  line above.
- Every abstraction has one real instance beside it, and every instance a word he can map it to.
- Where rounds have accumulated: the whole state, and every count says which total.
- Organised around his question, not around the work.
- Anything needing him is one collapsed decision with a leaning and its reason; the blocker first
  and alone.
- Anything still running names where he can watch it.
- Length matches what changed, not how long it took; what was cut is marked "(details omitted)".
- No route: no sequence of your actions, no history of your text. What another instruction file
  requires a report to carry is state and stays; so does a rewrite's opening line naming what was
  wrong.
- A mechanism he asked about at full depth; one you volunteer only as deep as his decision needs.
- Run the noun check on the finished text, a rewrite and anything compressed from a subagent, a
  tool or a log included.
- Names he made you replace stay replaced as the item's name; the identifier still rides in
  parentheses.
- Chinese punctuation full-width: `，。：；？！、` and `……`, 「」 for quotes. Half-width stays inside
  code, paths, parameter names and numbers, the `[08-12 18:40]` stamp included. For anything that
  lands in a file, `~/.claude/skills/writing-for-people/scripts/cjk-punct.py --fix` does it
  mechanically.

## Reports, as sent and as they should have read

**A batch of fixes, as it went out.** He asked for it again in plain words: what was actually done.

```
推进到这里了：
**#412 解冻了**：把 main 合进那条分支（不强推，不改写历史），冲突是两边各加一个周期清理任务，都保留。31 条测试全绿，现在 MERGEABLE，CI 在跑。
**#415 关了**，替代方案在 feat/scoped-token 上重做中，作用域按项目、长期有效、不建表。
现在开着 5 个 PR，全部 MERGEABLE：#418 缓存键规矩 / #417 任务猝死后还在谎报活着 / #414 列表排序时间戳 / #413 通知越权 / #412 状态机死锁
```

The unit of the report is a ticket number plus an internal label; the git operations are narrated;
no item says what a user would have seen go wrong; nothing says whether he has to do anything.

**The same work, rewritten.** He engaged with item 2 and asked a follow-up about its mechanism.

```
[08-12 18:40] 后端，今天的五个修复：都已提交，等 CI 绿了我合，不需要你做什么。
一句话：都是同一个毛病，系统出了事不告诉人。
1. 点一下「全部已读」，会把全项目所有人的未读都标掉。通知接口不认收件人，不指定就当成所有人的。改完按登录身份认，读别人的直接 403。已验证：接口测试 31 条全绿。（#413）
2. 后台任务干到一半被杀掉，界面一直显示「进行中」。容器重建、内存不够都会杀掉它，死了状态不变，实测三个任务这样躺了八小时没人发现。上周修了一半，今天补上剩下三个口子。（#417）
3. 审批卡在自检环节就永远出不来。自检任务死了，条目停在「检查中」，通过、驳回、撤销都按不动。现在超时自动判死，另加了人工作废按钮。（#412）
接下来：CI 绿了先合审批那条，它是别的几条的地基。(details omitted)
```

**A mid-task update, as it went out.** He said he felt helpless reading it and could not tell what
it was about.

```
在等回收探针的三轮结果（每轮约 1 分钟）。期间把架构事理清了，肇事者的范围已经很窄：测试夹具用的是不复用连接的池，测试客户端把服务跑在自己的事件循环上，退出前只等主流程收尾，它不等派生出去的后台任务，也不等代码里那七八处延迟触发的 create_task。这类任务如果正拿着会话上下文时事件循环关掉，收尾分支永远不跑，会话不关，连接就留着事务挂在数据库上……
```

Names he never used, no line saying what problem is being investigated, a hypothesis delivered as
mechanism before the probe has confirmed it, and nothing that tells him the state.

**The same moment, rewritten.**

```
[09-05 18:37] 后端测试为什么会把数据库连接挂住：还在查，探针要跑三轮，约 3 分钟。
目前的怀疑是测试退出时没等后台任务跑完，任务手里的数据库事务就一直挂着。探针跑完能点名是哪一处。你不用做什么，跑完我再报。
```

**A round of an accumulating task, as it went out.** He answered by asking what the state of the
whole set now was.

```
## 这轮净变更
- 第二批课程类：判成对方的 8 条（你定的）；我之前误判的两门课 7 条 → 翻回我们的。
- 第三批工具类：4 条 → 我们的。
现状：对方的 96 条 · 你定 93 条 · 将删 157 / 936。
```

The items are this round's arithmetic against a total he never held, and the last line puts three
counts over three different denominators side by side.

**The same round, rewritten.** He answered with the next step's constraint, not another question.

```
[07-10 15:20] 条目归属，当前全局快照——638 条现在的状态：

|              | 你亲定的 | 我猜的 | 合计 |
| 对方的 → 删  | 71      | 25 ⚠️  | 96  |
| 我们的 → 留  | 22      | 520    | 542 |

四个格子的意思：行是这条归谁、因此删还是留；列是这个判断你亲自定过，还是我猜的。
只有右上角那 25 条要你上心：判成「对方的、要删」，而判断是我猜的。
所以你现在只剩一件事：过一遍那 25 条。
```

**A change to rules, as it went out.** He said he still could not read it.

```
（时间戳和定位行略）
1. explain.md（a1b2c3d + b2c3d4e）：根文件 3,798 → 1,600 词，描述 1,117 → 746 字符。路由表挪到七条规则下面；「一次讲解的形状」并入 references/structure.md；三十项发送前清单搬进新建的 references/checklist.md，四件「递把手不递东西」的马甲合成一项。三处冲突各在规则自己那句里收口：只定义他没用过的词、机制操作的原语从不算可推迟的空缺、重写是重组不是加长。已验证：部署后逐字节与源码相同。
2. writing.md（c3d4e5f）：952 → 613 词……
```

The stamp and orientation line were there; the body is the work's own books — one item per file,
word counts before and after, which section moved where — in a subagent's vocabulary (马甲、原语、
收口), and nothing says what he will meet next time.

**The same change, rewritten.** He read it and moved on.

```
我上一条报的是文件内部搬了什么、字数变了多少，通篇是我自己造的词，没说你以后会看到什么不一样，从头说，三条。

[09-06 11:07] 三份规则文件的整改：改完、已部署，装出来的文件和仓库逐字节相同，不需要你做什么。
1. 讲东西的规则。以后我给你讲一个机制时，你自己用过的词我直接用，不再解释；只有你没用过的词才定义，你贴给我的报错、论文里的词不算「你用过」。你说「没懂」让我重讲时，我重新组织，不会越写越长。（explain.md，a1b2c3d）
2. 对外写作的规则。「我看行」这类说法要不要改成「我觉得可以」，以前两处规则给的答案相反，现在只有一个。你以后会看到：我替别人写东西之前，回复里先有一行「读者是谁、他拿去做什么、落在哪、多正式」；你问「这封邮件怎么回」，草稿进文件供你改，整段也贴在回复里。（writing.md，c3d4e5f）
3. 要不要问你的规则。你能直接 push 的仓库里，commit、push、开 issue、开 PR、合并都不问；对着某个人的评论、回复，或 at 了人的文字，才要令牌。你回「SEND x，另外把第二段口气放软」这种带话的令牌，以前没有出口；现在旁边的话就是你的下一条指令，改了稿就作废重发。（gate.md，d4e5f6a）
接下来没有在跑的东西。(details omitted)
```

An item whose object is a rule file is named by what the rule now makes happen, in words he uses;
the file name is demoted to the parenthesis exactly as a ticket number would be.
