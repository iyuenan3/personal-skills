# MEMORY_SPEC：Claude Code 项目记忆规范

> memory 写法的**单一真相源**。stash skill（同目录 `SKILL.md`）引用本文件、不复述，校验脚本 `check.sh` 按本文件检查。
> 本规范**贴合 Claude Code harness 注入的 `# Memory` 段**，做两处本地特化（name 命名 + 索引分隔符，见末尾「贴合 harness」）。

---

## memory 是什么

- **位置**：`~/.claude/projects/-<dashed-cwd>/memory/`。`<dashed-cwd>` = 当前项目绝对路径去开头 `/`、其余 `/` 换 `-`（例：`/Users/maxwell/Desktop/Claude-Project/worklog` → `-Users-maxwell-Desktop-Claude-Project-worklog`）。
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
- **互链**：相关 memory 用 `[[name]]`（锚带前缀 kebab name，如 `[[feedback-stash-date-alignment]]`）。多链相关项，断链不慌（recall 辅助，非硬键）。
- **命名空间区分**（决定 `[[ ]]` 指谁）：
  - `[[feedback-… / project-… / reference-… / user-…]]`（带 type 前缀）→ 指 **memory**，check.sh 校验其存在。
  - 其它如 `[[maxwell-homepage]]` / `[[车脉科技]]`（无 type 前缀）→ 指 **worklog wiki 页 / 项目名**，跨库引用，校验跳过。

## MEMORY.md 索引

- 每条 memory 在 `MEMORY.md` 占**一行**：`- [标题](文件名.md)：一句钩子`。
- 按 type 分段（`## Feedback` / `## Project` / `## Reference` / `## User`）。
- **新增 memory 必同步加索引行**；`MEMORY.md` 是 recall 时加载的总目录，漏加 = 这条 memory 在索引层隐身。

## 判断标准：记什么 / 不记什么

**记**：
- 用户偏好 / 反馈 / 工作模式（→ feedback）
- 项目目标 / 约束 / 非显然的决策与理由（→ project）
- 踩过的坑 + 根因 + 复现方式（→ reference / feedback）
- 外部资源指针（→ reference）

**不记**：
- 能从 git log / 代码 / CLAUDE.md **直接获取**的（代码结构、过往修复、提交历史）。
- 只对**本次会话**有用的临时上下文。
- 已有 memory 覆盖的（去**更新**那条，不新建重复）。

**反例**：「修了 `login.ts` 的空指针」= 不记（git 有）；「用户要求所有 commit message 用中文且不用破折号」= 记（feedback，跨会话有用）。

## 校验（check.sh 对应项）

- 🔴 **block**：缺 `name` / `description` / `metadata.type` · type 非枚举 · 文件名含非法字符（非 `a-z0-9_`）· `MEMORY.md` 缺索引行。
- 🟡 **warn**：`name` ≠ stem 连字符版 · `name` 缺 type 前缀 · 文件名前缀 ≠ type · feedback/project 缺 **Why:** / **How to apply:** · `[[带前缀 link]]` 断链 · description 过长（>200 字）或用块标量 · 老式顶层 `type:` 未迁 metadata · 顶层 type 与 metadata.type 冲突。

> 分级说明：`name`≠stem / 缺 Why·How 暂列 warn（不阻断），因存量普遍未满足；待存量批量修净后可考虑升 block。

## 贴合 harness

本规范贴合 harness 注入的 `# Memory` 段：`name` 是 kebab-slug、`[[name]]` 互链、`metadata.type` 四类枚举、feedback/project 的 **Why:** / **How to apply:**、MEMORY.md 一行索引。

**两处本地特化**：

1. **`name` 带 type 前缀**（`feedback-` 等）。原因：本机 memory 与 worklog wiki **共享 `[[ ]]` 命名空间**，不带前缀的 `[[name]]` 会和 wiki 页名相撞（如 `[[claude-financial-research]]` 既是 memory 又是 wiki 项目）；type 前缀消歧。harness 的 kebab-case-slug 要求并未禁止 slug 带语义前缀，故合规。
2. **MEMORY.md 索引分隔符用全角冒号 `：`**，不沿用 harness 原格式的破折号分隔符（用户「中文绝不用破折号」红线优先于 harness 格式）。
