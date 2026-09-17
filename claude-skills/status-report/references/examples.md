# Reports, as sent and as they should have read

Specimen reports, four pairs. "He" is the user; project names, ticket numbers and file names are
placeholders, and the rule files named inside the fourth pair are stand-ins, not the real ones.

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
[08-12 18:40]

这个 session：你问今天到底做了什么。
在改的东西：后端，五个修复。

都已提交，等 CI 绿了我合。一句话：都是同一个毛病，系统出了事不告诉人。

1. 点一下「全部已读」，会把全项目所有人的未读都标掉。通知接口不认收件人，不指定就当成所有人的。改完按登录身份认，读别人的直接 403。已验证：接口测试 31 条全绿。（#413）
2. 后台任务干到一半被杀掉，界面一直显示「进行中」。容器重建、内存不够都会杀掉它，死了状态不变，实测三个任务这样躺了八小时没人发现。上周修了一半，今天补上剩下三个口子。（#417）
3. 审批卡在自检环节就永远出不来。自检任务死了，条目停在「检查中」，通过、驳回、撤销都按不动。现在超时自动判死，另加了人工作废按钮。（#412）
不需要你做什么。CI 绿了我先合审批那条，它是别的几条的地基。
另外两个修复和逐条测试结果在 logs/backend-fixes-0812.md。(details omitted)
```

The stamp is what he scans a turn for; everything before it he never reads, which is what makes
writing the process elsewhere free rather than merely discouraged. The two lines under it are the
anchor, the same two lines every report of this subject opens with: he reads each one cold and should not have to remember the last. What was cut names
where it now is, so 「(details omitted)」 hands him a door rather than only telling him a room
exists.

**A mid-task update, as it went out.** He said he felt helpless reading it and could not tell what
it was about.

```
在等回收探针的三轮结果（每轮约 1 分钟）。期间把架构事理清了，肇事者的范围已经很窄：测试夹具用的是不复用连接的池，测试客户端把服务跑在自己的事件循环上，退出前只等主流程收尾，它不等派生出去的后台任务，也不等代码里那七八处延迟触发的 create_task。这类任务如果正拿着会话上下文时事件循环关掉，收尾分支永远不跑，会话不关，连接就留着事务挂在数据库上……
```

Names he never used, no line saying what problem is being investigated, a hypothesis delivered as
mechanism before the probe has confirmed it, and nothing that tells him the state.

**The same moment, rewritten.**

```
[09-05 18:37]

这个 session：后端测试跑完之后，数据库连接不释放。
在改的东西：查是哪一处没释放。

还在查，探针要跑三轮，约 3 分钟。目前的怀疑是测试退出时没等后台任务跑完，任务手里的数据库事务就一直挂着；探针跑完能点名是哪一处。

你不用做什么，3 分钟后我再报。探针输出实时写在 logs/conn-probe-0905.log。
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
[07-10 15:20]

这个 session：638 条条目要分清哪些是对方的、该删，哪些是我们的、该留。
在改的东西：逐批判定每条归谁。

还在跑，第三批判完了。当前全局快照：

|              | 你亲定的 | 我猜的 | 合计 |
|---|---:|---:|---:|
| 对方的 → 删  | 71      | 25 ⚠️  | 96  |
| 我们的 → 留  | 22      | 520    | 542 |

四个格子的意思：行是这条归谁、因此删还是留；列是这个判断你亲自定过，还是我猜的。
要你做的，一件：

1. 过一遍右上角那 25 条——判成「对方的、要删」，而判断是我猜的。逐条列在
   review/uncertain-25.md。你确认或推翻，第四批我照你的判法走；不过的话我按自己的判法
   继续，代价是这 25 条错了没人拦。我倾向你过一遍：这一格是整张表里唯一没人核过的。
```

**A change to rules, as it went out.** He said he still could not read it.

```
（时间戳和锚点两行略）
1. explain.md（a1b2c3d + b2c3d4e）：根文件 3,798 → 1,600 词，描述 1,117 → 746 字符。路由表挪到七条规则下面；「一次讲解的形状」并入 references/structure.md；三十项发送前清单搬进新建的 references/checklist.md，四件「递把手不递东西」的马甲合成一项。三处冲突各在规则自己那句里收口：只定义他没用过的词、机制操作的原语从不算可推迟的空缺、重写是重组不是加长。已验证：部署后逐字节与源码相同。
2. writing.md（c3d4e5f）：952 → 613 词……
```

The stamp and the anchor were there; the body is the work's own books — one item per file,
word counts before and after, which section moved where — in a subagent's vocabulary (马甲、原语、
收口), and nothing says what he will meet next time.

**The same change, rewritten.** He read it and moved on.

```
我上一条报的是文件里搬了什么、字数变了多少，没说你以后会看到什么不一样。从头说，三条。

[09-06 11:07]

这个 session：三份规则文件互相矛盾，你读不动，也不知道该信哪份。
在改的东西：那三份规则。

改完、已部署、装出来的和仓库一致。

1. 讲东西：你用过的词直接用，只定义你没用过的；你说「没懂」，我重组，不加长。（explain.md）
2. 对外写作：「我看行」要不要改成「我觉得可以」，两处规则原来答案相反，现在只剩一个答案：改。替别人写之前，回复里先一行「读者是谁、拿去做什么、落在哪、多正式」；你问「邮件怎么回」，草稿进文件，整段也贴回复。（writing.md）
3. 要不要问你：能直接 push 的仓库，commit、push、开 PR、合并都不问；写给某个人的字才要令牌。令牌后面带的话（「SEND x，另外把第二段口气放软」）就是你的下一条指令，改了稿就作废重发——原来的规则没说这种情况怎么办。（gate.md）
不需要你做什么，没有在跑的东西。
三份文件的完整改动逐条在 logs/rules-rewrite-0906.md。(details omitted)
```

An item whose object is a rule file is named by what the rule now makes happen, in words he uses;
the file name is demoted to the parenthesis exactly as a ticket number would be.
