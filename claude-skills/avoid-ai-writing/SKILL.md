---
name: avoid-ai-writing
description: 写或改任何给人看的文字时用——GitHub issue/PR 评论、code review、release notes、HN/社交评论、帖子、文档、邮件、文章、个人陈述、发言稿、commit/PR 说明。凡是公开协作场景下以用户名义发出的文字,发出前必须先过一遍本 skill。扫掉 AI 写作痕迹(AI-isms),让内容自己说话。中英文都适用。Use when writing or editing prose a human will read, especially anything posted publicly under the user identity (GitHub comments, reviews, social posts).
---

# 去除 AI 写作痕迹

目标:写得像一个真人在认真说话,而不是一台被调教得过度光滑的机器。让事实和判断自己承重,不靠辞藻和结构撑场面。

## 最高优先:不要过度纠偏(硬约束)

去 AI 味**不等于**把文字改散、改口语、改水。这是最常见的反向翻车。

- **保留**:好的正式语感、经过思考的判断、排比、诗意、克制的修辞。
- **只动**:确认的句式痕迹和堆砌,做窄范围手术。**不要从头重写已经认可的内容**——做行级精修。
- 触发全文重写的阈值见末尾;没到阈值就只改命中点。
- 改完问一句:语气是不是被降级了?如果原来是"考究的书面体",改完变成"随口聊天",那是改坏了。
- **功能性格式不是 AI 味,别扫掉**:论文/仓库/文档的超链接、行内代码、必要的章节引用是信息,真人恰恰会加。要扫的是装饰性格式(加粗轰炸、emoji 标题、PPT 式小节),不是让文字裸奔成纯文本。

判断"不是X而是Y"这类句式时**不要一刀切删**:
- **留**:真有反差/反直觉张力的(承重的"钉子",一篇留 1–2 个)。
- **删/改平**:X 是没人信的稻草人的(改成普通正面陈述)。

## 英文 tell(写 HN 评论、英文内容时重点查)

**词(出现即换成普通词):**

| AI 词 | 换成 |
|---|---|
| leverage / utilize | use |
| robust | reliable / solid |
| seamless / streamline | smooth / simplify |
| delve / dive into | look at / get into |
| foster / empower | build / help / let |
| boast / feature / serve as | has / is |
| showcase / highlight / underscore | show |
| pivotal / crucial / vital | important(或直接说为什么) |
| tapestry / landscape / ecosystem / realm | (具体名词) |
| meticulous / intricate / nuanced | careful / detailed |
| testament to / nestled | (删,直接说事实) |

**短语 / 套路(删或重写):**
- 开场客套:"Great question", "Certainly", "You're absolutely right", "Let me break this down"
- 收尾客套:"Hope this helps", "Feel free to reach out", "At the end of the day", "Only time will tell", "The future looks bright", "a game-changer"
- 软化垫话:"It's worth noting", "That said", "Interestingly", "It's important to remember"
- 假权威:"Experts say", "Studies show", "It's widely believed"
- 自我标注:"Here's the interesting part", "The kicker?", "The catch?", "Here's the thing"

补充词/短语:moreover / furthermore / albeit / indeed / certainly;"a symphony of" / "a tapestry of" / "delicate balance";装腔状语 "with practiced efficiency" / "with measured steps" / "mastered precision"。

**句式:**
- **否定排比**:"It's not X, it's Y" / "Not only X but also Y" / "not just X — Y"。这是头号 tell,英文同样要管;留 1–2 个真有张力的,其余改平。
- **提问紧接自答**:"And that question? It's the answer." / "The result? Total chaos." → 删掉这种自问自答的小机灵。
- **戏剧性断句**:"Short sentences. Pauses. For effect." 一串名词/碎句堆戏剧感 → 合回正常句子。
- **强行明喻/比喻**:被要求"写得更生动"时给什么都硬塞一个比喻("X like an angry octopus after a bad haircut")→ 没必要的比喻删掉。
- **三连**(rule of three):"fast, reliable, and scalable" 这种凑数三元组——砍成一个具体的。ChatGPT 改不掉这个,要专门盯。
- **系动词回避**:别用 serves as / boasts / features 代替 is / has。
- **拖尾 -ing 拔高**:"..., highlighting its significance" / "..., reflecting a broader shift" → 删掉这条尾巴,或拆成有事实的句子。
- **拔高夸张**:"You're not just onto something — you've changed the entire game" 这种顺势升级捧场 → 删。
- **节奏均匀**:所有句子 15–25 词、所有段落一样长 = 机器感。故意让长短不齐。

**标点 / 格式:**
- 破折号(— / --)滥用:能用逗号句号就别用。
- 弯引号 " " 混进直引号(技术痕迹)。
- 每个关键词都 **加粗**;每行都是 **粗体标签:** 开头的列表;标题 Title Case 每个词大写;emoji 当小标题(🚀💡✅);随手撒 emoji(🤖🌀)。正文该是段落就写段落,别什么都列表化。
- 整篇切成 PPT/大纲式的小节(没内容也要凑标题)。

**内容造假 / 虚饰:**
- **编造化名假人当案例**:没数据/没真例子时,AI 爱凭空造个人(经典名字 "Sarah Chen")+ 一段轶事。要么用真例子,要么不编。
- **只说"代表/象征/反映"不说事实**:"this represents/symbolizes/reflects…" → 直接给可核查的事实。
- **过度周全**:面面俱到、每点都平衡、每段都收个漂亮尾巴 = 没立场没灵魂。真人会有偏好、会跑题、会留开口。

## 中文 tell(写中文内容、发言稿、文章时重点查)

- **"不是X,而是Y"**:你最反感、每篇都冒出来的句式。留 1–2 个承重的,其余改成普通正面陈述。
- **加粗强调**满天飞:正文里零散加粗,删。
- **段尾总结/升华句**:"这些都是…的一部分"、"这让我明白了…"、"真正的意义在于…"——删掉评语,只留发生了什么,让读者自己感受。
- **空评价/空过渡**:"很重要"、"对我影响很大"、"更重要的是"、"我逐渐意识到"、"这是一次宝贵的经历"——说了等于没说。换成那个让人自己得出结论的**具体场景/事实**。
- **概念词加引号**成癖:"一体化""集市""抓手"——引号密度本身是 tell,只留必要的(英文术语注释、专名)。
- **口号化**:正文里的标语腔,改成平实陈述。
- **小标题模板**:对仗四字("诉讼先行,规则未定")、"从X到Y"、"双X与Y"、"…的X维度"、"本质:…"、"宏观启示:…"。改成具体、略不对称、真人会起的标题。
- **凑整的排比/对仗**:为整齐而堆的删;真有力量的留。

## 字频扫描(肉眼漏掉的痕迹,用计数抓)

定稿前数一遍,超量就砍,但保留正当用法:
- 破折号(— / 破折号)条数
- 圆括号 ( ) 条数
- "本质""核心""关键"出现次数
- 引号成对数(中文概念加引号)
- "不是…而是" / "it's not...it's" 出现次数

正当保留:英文术语注释 (transformative use)、法条号、案件年份/法院标注、脚注编号。其余的削到个位数。

## 两个判断测试(写完自检)

1. **段落互换测试**:随便交换两个正文段,通不通?如果照样通顺,说明每段没有真正往前推进——它在原地踏步。
2. **跑步机测试**:逐段问"这段到底新增了什么?"。如果什么都没推进,删掉。

## 重写 vs 精修 阈值

命中 **5+ 个词 tell + 3+ 类句式/结构 tell + 节奏均匀** → 整段重写,别逐点打补丁。
否则只精修命中点,**保住已认可的内容和语气**(见最高优先那条)。
