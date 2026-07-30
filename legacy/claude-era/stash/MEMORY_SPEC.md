# MEMORY_SPEC：Claude Code 项目记忆规范

> memory 写法的**单一真相源**。stash skill（同目录 `SKILL.md`）引用本文件、不复述，校验脚本 `check.sh` 按本文件检查。
> 本规范**贴合 Claude Code harness 注入的 `# Memory` 段**，做两处本地特化（name 命名 + 索引分隔符，见末尾「贴合 harness」）。

---

## memory 是什么

- **位置**：`~/.claude/projects/-<dashed-cwd>/memory/`。`<dashed-cwd>` = 当前项目绝对路径去开头 `/`、其余**非字母数字字符逐个换 `-`**（不只 `/`；例：`/Users/you/projects/my-app` → `-Users-you-projects-my-app`，`/Users/you/.claude` → `-Users-you--claude`）。
- **结构**：一事一文件 `<type>_<topic>.md` + 一个 `MEMORY.md` 索引。
- **唯一消费者** = recall 时读 memory 的 LLM。harness 靠 **description 语义匹配**决定注入哪些 memory。
- memory **不在任何 Obsidian vault 里** → 正文里的 `[[link]]` 没有工具渲染/跳转，纯粹是给 recall LLM 的关联指针。

## frontmatter schema

```yaml
---
name: <type>-<topic-kebab>          # 带 type 前缀的 kebab-slug，= 文件名 stem 把 _ 换成 -
description: <一句话：这条记什么 + 何时该被想起>   # recall 命中的唯一依据，最重要
metadata:
  type: user | feedback | project | reference   # 四类枚举
---
```

- **name**：全小写 kebab-case，**带 type 前缀**（`feedback-` / `project-` / `reference-` / `user-`）。恒等于「文件名 stem 把 `_` 换 `-`」。
- **description**：recall 相关性的唯一依据，全篇最重要的一行。写清「记的是什么 + 何时该被想起」，**单行 inline**（不用 `>` / `|` 块标量）、**一两句话 ≤200 字**（check.sh `DESC_MAX`），**忌把正文塞进来**（过长会稀释 recall 信号）。
- **metadata.type**：四类之一，统一放 `metadata` 下（**不要用顶层 `type:`**）。
- **可选遗留字段**（`metadata.originSessionId` / `metadata.node_type`）：新建不必加，存量保留无妨。
- **可选 `metadata.asOf`**（`YYYY-MM-DD`）：状态型记忆的有效期戳，供下游时效审计机读筛选（见「记状态：时效与变更」节）。新建状态型记忆建议带，check.sh 本轮不强制。

## 文件命名

- 文件名 `<type>_<topic>.md`，**纯下划线分隔**（topic 内部也只用 `_`，不混 `-`），否则破坏与 name 的双向映射。
- `name` = 文件名 stem 把 `_` 换 `-`，双向无损。
- 例：`feedback_stash_skill_upgrade.md` ↔ name `feedback-stash-skill-upgrade`。

## 四类 type

| type | 记什么 | 正文要求 |
|---|---|---|
| **user** | 用户是谁：角色 / 专长 / 稳定偏好 | 直述 |
| **feedback** | 用户给的工作指导（纠正或确认的做法） | 必含 **Why:** + **How to apply:** |
| **project** | 进行中的工作 / 目标 / 约束（代码·git 推不出来的） | 必含 **Why:** + **How to apply:** |
| **reference** | 外部资源指针（URL / dashboard / ticket）或可复用技术参考 | 直述 |

## 正文规范

- **feedback / project**：事实陈述之后跟 **Why:**（为什么这样）+ **How to apply:**（下次怎么用）两行。
- **互链**：相关 memory 用 `[[name]]`（锚带前缀 kebab name，如 `[[feedback-stash-skill-upgrade]]`）。多链相关项，断链不慌（recall 辅助，非硬键）。
- **命名空间区分**（决定 `[[ ]]` 指谁）：
  - `[[feedback-… / project-… / reference-… / user-…]]`（带 type 前缀）→ 指 **memory**，check.sh 校验其存在。
  - 其它如 `[[some-homepage]]` / `[[some-project]]`（无 type 前缀）→ 指 **你的 wiki 页 / 项目名**，跨库引用，校验跳过。

## MEMORY.md 索引

- 每条 memory 在 `MEMORY.md` 占**一行**：`- [标题](文件名.md)：一句钩子`。
- 按 type 分段（`## Feedback` / `## Project` / `## Reference` / `## User`）。
- **新增 memory 必同步加索引行**；`MEMORY.md` 是 recall 时加载的总目录，漏加 = 这条 memory 在索引层隐身。

## 判断标准：记什么 / 不记什么

**记**：
- 用户偏好 / 反馈 / 工作模式（→ feedback）
- 项目目标 / 约束 / 非显然的决策与理由（→ project）
- 踩过的坑：观察 + 根因（标把握度）+ 条件戳 + 复现方式（→ reference / feedback；写法见下「记坑：诚实捕获」）
- 外部资源指针（→ reference）

**不记**：
- 能从 git log / 代码 / CLAUDE.md **直接获取**的（代码结构、过往修复、提交历史）。
- 只对**本次会话**有用的临时上下文。
- 已有 memory 覆盖的（去**更新**那条，不新建重复）。
- 高频轮换、且另有专门主场的易变状态（凭证 / token / 动态端点位置等）：值本身别落 memory，落了也是维护负担；至多留一个指向主场的指针。

**反例**：「修了 `login.ts` 的空指针」= 不记（git 有）；「用户要求所有 commit message 用中文且不用破折号」= 记（feedback）。**边界例**：「修 X 这件事」不记（git 有）；但「修 X 时撞到的、换个项目还会踩的坑」要记（→ 坑，跨会话有用），这条边界正是脑补高发区，按下面「记坑：诚实捕获」记。

## 记坑：诚实捕获（写入只保证诚实，正确性靠下游验证）

踩坑当下「改了 X 就好」常是相关、不是因果；事后总结又容易把不确定抹成一个干净的因果故事（脑补）。写入时**保证不了「正确」**，能保证的是**「诚实」**。记一条坑要做到：

- **根因标把握度，写「因为」前先验尺**：抽掉疑似根因看症状是否消失、加回是否重现，复现过才写「因为 Y」；没复现就写「疑似 / 相关」「暂定假设·未验证」，不冒充确定。
- **观察与推断分开**：一行写**观察**（症状、跑的命令 + 输出 = 事实），一行写**推断**（我以为的根因 = 猜）。读的人一眼能分清哪些是事实、哪些是猜。
- **带条件戳**：工具 + 版本、OS、locale、shell。没范围的坑是颗雷（写「macOS BSD grep 2.6」而非光「grep」；版本一换结论可能就反了）。
- **不确定就老实写不确定**：根因不明时记「现象 + 绕法，因未知」是真实有用的；一个假装确定的干净因果，比「不知道为啥」更危险，因为别人会信、不再复检。
- **可选** `metadata.status: verified | unverified`（或正文一行「把握度：已复现 / 仅推测」），给下游晋级一个机读钩子。

> 这是**捕获层**纪律。正确性的最终保证不在写入时，在**下游验证**（换个时间 / 项目再次相遇时检验）+ 这条坑晋级进 pitfalls 共享库时的「已复现」门。check.sh 只验格式、不验真伪（见下）。

## 记状态：时效与变更（诚实捕获的时间维）

「记坑」防认知脑补（把不确定抹成确定）；本节防**时间脑补**（把会过期的状态写成永恒事实）。三类翻车都从这来：孤条状态没人回头改（**静默漂移**）、新旧两版并存打架（**并存冲突**）、实体已删记忆还活着（**幽灵实体**）。

### 1. 先分：状态型 vs 耐久型（正交于四类 type）

第二个维度，不跟 type 对齐：

- **耐久型**：世界不在它脚下变，只会被证伪。偏好、坑、方法论、稳定身份。越老越可信，harness 的「N 天前」提醒对它是噪音。
- **状态型**：现实会在它脚下悄悄变、无需谁回头观察就已成假。角色 / 职责范围 / 归属 / 项目现状 / 谁负责什么 / 部署拓扑 / 一切「进行中」。有有效期、会衰减。

两把判定尺（下结论前先过）：

- **「一年不碰，它还成立吗？」** 成立 = 耐久；可能已悄悄变假 = 状态。
- **「它的反面是被证伪、还是被更新？」** 证伪（当时就错）= 耐久失效；更新（曾对、现在变了）= 状态。

映射四类：project 几乎全状态型；feedback 偏耐久；user、reference 混合（user 的稳定偏好耐久、当前职责状态；reference 的坑 / 方法论耐久、URL / 部署 / 端点状态）。

⚠️ **混含条**（一条里既有耐久又有状态，如「是 PM + 工作偏好」耐久 ‖「负责 X 板块」状态）：状态部分在 description 里**单独成句并带戳**、与耐久部分分开表述；「污染」指不带戳地糅进整条、让全条冒充耐久，不是不许进 description（状态进 description 必须带戳，见 §2）。

### 2. 状态型必带 as-of 戳

- 凡状态型事实（或混含条的状态部分），就近带 as-of 戳（「截至 2026-06」/「2026-06 起」）。
- 🔴 **戳必须进 description**（不只进正文）：description 是 recall 唯一钩子，不带戳的状态冒充永恒事实、每次 recall 先喂过期值。正文改了 description 没改 = 没修。
- **粒度**：月级通常够；有已知硬变更日（上任 / 退役 / 迁移）才到日。
- **写入按本机真实时区盖戳**（部分沙箱注入错误时区会把日期算错，先校准再取当前日期）。
- **给存量旧条回补 as-of**（如冲突保守并存要求两条各带戳）：用可考的最好证据（正文内日期 / git log）；不可考就标「as-of 不详（原写入日不可考）」，**绝不拿当天日期冒充**（伪造观察时点，误导后续消解）。
- 可选 `metadata.asOf: YYYY-MM-DD`，给下游时效审计一个机读筛选钩子（对标「记坑」的 `metadata.status`）。

### 3. 变更 ≠ 纠错：两种 update 分开写

旧值失效有两种，措辞和语义完全不同，别混：

| | 触发 | 措辞 | description 处理 | 语义 |
|---|---|---|---|---|
| **纠错** | 旧值当时就错（被证伪） | 「原记为 X，后修正为 Y」 | 换成 Y、留纠错痕迹 | X 是 bug |
| **时效变更** | 旧值当时对、现实变了 | 「YYYY-MM 起 Y；此前 X」 | 换成当前真相 Y + 新 as-of；X 降级为正文带日期历史行 | X、Y 都真，各有其时 |

两条红线：

1. 🔴 **别把变更写成纠错**。把「3 月起转岗 B、此前做 A」写成「原记为做 A、后修正为 B」，会误导未来 Claude 以为 A 是错误记录，抹掉「他确实做过 A」这段真实历史（违反禁丢历史）。
2. 🔴 **变更必须改 description**。只改正文 = 没修。

> 判定「人变了还是记错了」：事实本身变了（旧值当时真）= 时效变更；用户说「你一直记错了」= 纠错。

### 4. 实体消失：立墓碑，不删除

删除 / 退役 / 下线是「supersession 到不存在」，是状态型最易漏的一类：创建会被 stash、删除不会，**减法事件天生不触发「记一下」**。

- 🔴 **别删那条记忆**（禁丢历史），立墓碑：description 开头写「【已作废 YYYY-MM-DD】原：X；<消失原因>」。注意与 §3 时效变更**方向相反**：变更是「旧值 X 出 description」，墓碑是「旧值 X 留在 description、只在前面打死标」，好让 recall 一眼看到「死掉的是什么」、立刻降权。墓碑前缀会加长 description：叠加后超 200 字时把 X 压缩成要点（完整原值在正文保留），或接受该条超长 🟡。
- 正文保留原内容 + 一句作废说明与日期。
- **复活 / 回退**（已作废实体又启用，或 A→B→A 反复）：更新那条墓碑记录本身（去掉【已作废】前缀、补一句复活日期 + 现状），绝不新建平行条；拿不准的并入 Phase 2 老状态复核。
- 思路同「知识库给废弃项目立归档标记」，照搬到 memory 侧。

> 本节整体是**判断层**纪律，check.sh 只验 schema、这轮不加门。下游落地：stash 写时（Step 2 减法扫描 + Step 3 supersession 视角 + 冲突保守并存 + Step 5 as-of / 墓碑）+ 未来 memory-maintain skill 的三模式审计（真相源对账 / 冲突消解 / 老状态复核）。
> recall 期「多条在场按 recency 读」的推理指引**不放本 SPEC**：recall LLM 不读本文件，放这里送不到执行者手里。Phase 1 靠 as-of 戳让 recall 自行判断新旧，显式指引留 Phase 2。

## 校验（check.sh 对应项）

- 🔴 **block**（check.sh 输出称 must-fix）：缺 `name` / `description` / `metadata.type` · type 非枚举 · 文件名含非法字符（非 `a-z0-9_`）· `MEMORY.md` 缺索引行。
- 🟡 **warn**（输出称 advisory）：`name` ≠ stem 连字符版 · `name` 缺 type 前缀 · 文件名前缀 ≠ type · feedback/project 缺 **Why:** / **How to apply:** · `[[带前缀 link]]` 断链 · description 过长（>200 字）或用块标量 · 老式顶层 `type:` 未迁 metadata · 顶层 type 与 metadata.type 冲突 · `MEMORY.md` 索引孤儿行（指向已删 / 改名文件）。

> 分级说明：`name`≠stem / 缺 Why·How 暂列 warn（不阻断），因存量普遍未满足；待存量批量修净后可考虑升 block。
>
> **能力边界**：check.sh 只保证 **schema 合规**，不保证内容**正确**、也不查内部自相矛盾。过线 ≠ 记对了，正确性靠「记坑·诚实捕获」纪律 + 下游验证 + 晋级「已复现」门。
>
> **实现对账**：check.sh 的 Why: / How to apply: 检查接受中文等价（**为什么** / **如何应用** / **怎么用**，冒号可选），这条放宽是 load-bearing（勿在 check.sh 收紧）；索引「按 type 分段」check.sh 不校验，只校验「每条有索引行 + 无孤儿行」。
>
> **时效不入门**：「记状态：时效与变更」节属判断层，check.sh 本轮不验时效 / as-of（过时是真伪问题、非格式问题）。已核实：新增 `metadata.asOf` 不触发现有 check.sh（只查必填键存在性、不 allowlist metadata 子键，未知键忽略）；墓碑 description 前缀本身单行 inline 且极短、不触发格式项；与原 description 叠加可能超 200 字，按「记状态」§4 把 X 压成要点或接受 🟡。未来机读钩子 = `metadata.asOf` 存在性 + `--stale-candidates` 预筛，留给 memory-maintain skill。

## 贴合 harness

本规范贴合 harness 注入的 `# Memory` 段：`name` 是 kebab-slug、`[[name]]` 互链、`metadata.type` 四类枚举、feedback/project 的 **Why:** / **How to apply:**、MEMORY.md 一行索引。

**两处本地特化**：

1. **`name` 带 type 前缀**（`feedback-` 等）。原因：本机 memory 与你的 wiki **共享 `[[ ]]` 命名空间**，不带前缀的 `[[name]]` 会和 wiki 页名相撞（如 `[[some-project]]` 既可能是 memory 又是 wiki 项目）；type 前缀消歧。harness 的 kebab-case-slug 要求并未禁止 slug 带语义前缀，故合规。
2. **MEMORY.md 索引分隔符用全角冒号 `：`**，不沿用 harness 原格式的破折号分隔符（用户「中文绝不用破折号」红线优先于 harness 格式）。
