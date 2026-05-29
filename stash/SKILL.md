---
name: stash
description: 回顾当前对话，把值得跨会话持久化的信息（用户偏好/反馈、项目决策与约束、踩过的坑、外部资源指针）存进本项目 memory 目录、更新 MEMORY.md 索引，并按需更新 CLAUDE.md。用户说「stash / 保存记忆 / 记一下 / 沉淀一下 / 记住这个」时触发。显式触发，不在会话结束时自动运行。
---

# stash：项目记忆持久化

回顾本次对话，把跨会话有用的信息落进 memory，让未来的会话能召回。

> **记忆写法规范以同目录 [`MEMORY_SPEC.md`](MEMORY_SPEC.md) 为唯一真相源** ,本文件只定流程，不复述 schema 细节（复述会随规范演化而漂移，这正是 stash 从 command 升级为 skill 的初衷）。执行前先读 `MEMORY_SPEC.md`。

## 触发

显式触发：`/stash`、「stash / 保存记忆 / 记一下 / 沉淀一下 / 记住这个」。**不自动触发** ,持久化是写文件的副作用动作，只在用户明确要求时跑。

## 主流程（7 步）

### 1. 定位 memory 目录

```bash
DASHED=$(pwd | sed 's:^/::; s:/:-:g')
MEM="$HOME/.claude/projects/-$DASHED/memory"
[ -d "$MEM" ] || mkdir -p "$MEM"   # 新项目首次 stash 自动建
# MEMORY.md 不存在则建四段骨架（recall 总目录；按 type 分段）
[ -f "$MEM/MEMORY.md" ] || printf '# Memory\n\n## User\n\n## Feedback\n\n## Project\n\n## Reference\n' > "$MEM/MEMORY.md"
echo "$MEM"
```

**路径一律由 pwd 动态推导，绝不硬编码项目路径**（通用工具跨项目零修改；硬编码曾导致记忆写错机器）。

### 2. 盘点候选

读 `MEMORY_SPEC.md` 拿规范，再扫本次对话，列出值得持久化的候选：新知识、做出的决策、发现的坑、配置/基础设施变更、用户反馈与偏好。按 `MEMORY_SPEC` 判断标准先粗筛（只留跨会话有用的）。

### 3. 查重（先查后写，防碎片化）

```bash
grep -rh -E '^(name|description):' "$MEM"/*.md 2>/dev/null
```

对每个候选，比对现有 memory 的 name + description，判断：**已有覆盖 → 更新那条**；**无 → 新建**。绝不新建与现有重复的文件。

### 4. 判断记什么

套 `MEMORY_SPEC` 的「记什么 / 不记什么」：**不记**能从 git log / 代码 / CLAUDE.md 直接获取的，**不记**只对本次会话有用的临时上下文。留下的才进下一步。

### 5. 写盘

按 `MEMORY_SPEC` 的 schema 写 / 改 memory 文件：

- 文件名 `<type>_<topic>.md`（纯下划线）；frontmatter `name`（带 type 前缀 kebab）/ `description`（一两句话 recall 钩子，单行 inline、≤200 字）/ `metadata.type`（四类枚举）。
- feedback / project 正文跟 **Why:** + **How to apply:** 两行。
- 互链相关 memory 用 `[[name]]`（锚带前缀 kebab name）。
- **每新建 / 更新一条，同步在 `MEMORY.md` 加 / 改一行索引**（`- [标题](文件名.md)：钩子`，按 type 分段）。
- 发现存量里写错的（错值 / 过时 / 误建）→ 顺手改 / 删（纠错不违背记忆保护）。

### 6. 校验

```bash
bash ~/.claude/skills/stash/check.sh "$MEM"
```

🔴 must-fix 必须修到过；🟡 advisory 逐条 review（多数应修，少数如跨库 `[[wiki]]` 引用可接受）。

### 7. 更新 CLAUDE.md（条件）+ 报告

- **仅当**本次有项目配置 / 常用命令 / 基础设施 / 关键信息变更，才更新当前项目 `CLAUDE.md`（无变更跳过）。
- 报告：新建 N 条 / 更新 M 条 / 跳过哪些（及原因）/ check.sh 结果。

## 红线

1. **规范以 `MEMORY_SPEC.md` 为唯一真相源** ,不在本文件或对话里复述 schema 细节（防漂移）。
2. **路径动态推导**（pwd），绝不硬编码项目路径。
3. **先查重后写**，有覆盖去更新，绝不新建重复。
4. **写后必跑 `check.sh`**，🔴 必修。
5. **MEMORY.md 索引与 memory 文件一一对应**，新增 / 改名必同步。
6. **只记跨会话有用的**（判断标准见 `MEMORY_SPEC`），不记 git / code / CLAUDE.md 可直接获取的。
7. **不自动触发**，只在用户明确要求时运行。
