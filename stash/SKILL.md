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
# 锚到项目根（git toplevel），不用裸 pwd：从子目录触发时 pwd 会偏移、写进错 keyspace 致召回静默丢失
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MEM="$HOME/.claude/projects/-$(printf '%s' "$ROOT" | sed 's:^/::; s:/:-:g')/memory"
[ -d "$MEM" ] || mkdir -p "$MEM"   # 新项目首次 stash 自动建
# MEMORY.md 不存在则建四段骨架（recall 总目录；按 type 分段）
[ -f "$MEM/MEMORY.md" ] || printf '# Memory\n\n## User\n\n## Feedback\n\n## Project\n\n## Reference\n' > "$MEM/MEMORY.md"
echo "$MEM"
```

**路径由项目根（git toplevel，回退 pwd）动态推导，绝不硬编码**（通用工具跨项目零修改；硬编码曾把记忆写错机器，裸 pwd 则在子目录触发时写偏）。若 harness 直接给了 memory 目录绝对路径，优先用它。**`MEM` 是 shell 变量、不跨 Bash 调用持久**，下面每个用到它的 bash 块都重新派生一次（别依赖上一块的 `MEM` 还在）。

### 2. 盘点候选

读 `MEMORY_SPEC.md` 拿规范，再扫本次对话，列出值得持久化的候选：新知识、做出的决策、发现的坑、配置/基础设施变更、用户反馈与偏好。按 `MEMORY_SPEC` 判断标准先粗筛（只留跨会话有用的）。

### 3. 查重（先查后写，防碎片化）

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd); MEM="$HOME/.claude/projects/-$(printf '%s' "$ROOT" | sed 's:^/::; s:/:-:g')/memory"  # 每块各自重派生（变量不跨调用）
grep -rh -E '^(name|description):' "$MEM"/*.md 2>/dev/null
```

对每个候选，比对现有 memory 的 name + description，判断：**已有覆盖 → 更新那条**；**无 → 新建**。绝不新建与现有重复的文件。

### 4. 判断记什么

套 `MEMORY_SPEC` 的「记什么 / 不记什么」：**不记**能从 git log / 代码 / CLAUDE.md 直接获取的，**不记**只对本次会话有用的临时上下文。**留下的若含「坑」，按 `MEMORY_SPEC` 的「记坑：诚实捕获」记**（根因没复现就标「疑似 / 未验证」、不冒充确定、带条件戳）。

留下的候选为空就直接到 Step 7 报告「本次无需持久化（理由）」收尾，**不为凑产物硬造低价值记忆**。

### 5. 写盘

**按 `MEMORY_SPEC.md` 的 frontmatter schema + 正文规范写 / 改**（文件名、name 前缀、description、type 枚举、Why/How、坑的诚实捕获等细节都在那，本步不复述、防漂移）。本步只强调流程动作：

- **每新建 / 更新一条，同步在 `MEMORY.md` 加 / 改一行索引**（按 type 分段），索引与文件一一对应。
- 发现存量写错的（错值 / 过时 / 误建）→ 改 / 删，但**旧根因被证伪时保留一句纠错痕迹**（「原记为 X，后修正为 Y」），别干净覆盖（呼应全局红线「禁丢历史」，也给未来会话留审计线索、免得又推回同一错根因）。

### 6. 校验

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd); MEM="$HOME/.claude/projects/-$(printf '%s' "$ROOT" | sed 's:^/::; s:/:-:g')/memory"  # 每块各自重派生
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
4. **写后必跑 `check.sh`**，🔴 必修。但 `check.sh` **只验 schema 合规、不验内容正确**：过线 ≠ 记对了，正确性靠诚实捕获 + 下游验证。
5. **MEMORY.md 索引与 memory 文件一一对应**，新增 / 改名必同步。
6. **只记跨会话有用的**（判断标准见 `MEMORY_SPEC`），不记 git / code / CLAUDE.md 可直接获取的。
7. **不自动触发**，只在用户明确要求时运行。
