---
name: stash
description: 回顾当前对话，把值得跨会话持久化的信息（用户偏好/反馈、项目决策与约束、踩过的坑、外部资源指针）存进本项目 memory 目录、更新 MEMORY.md 索引，并按需更新 CLAUDE.md。用户说「stash / 保存记忆 / 记一下 / 沉淀一下 / 记住这个」时触发。显式触发，不在会话结束时自动运行。
---

# stash：项目记忆持久化

回顾本次对话，把跨会话有用的信息落进 memory，让未来的会话能召回。

> **记忆写法规范以同目录 [`MEMORY_SPEC.md`](MEMORY_SPEC.md) 为唯一真相源**，本文件只定流程，不复述 schema 细节（复述会随规范演化而漂移，这正是 stash 从 command 升级为 skill 的初衷）。执行前先读 `MEMORY_SPEC.md`。

## 触发

显式触发：`/stash`、「stash / 保存记忆 / 记一下 / 沉淀一下 / 记住这个」。**不自动触发**，持久化是写文件的副作用动作，只在用户明确要求时跑。

## 主流程（7 步）

### 1. 定位 memory 目录

```bash
# 锚到项目根（git toplevel），不用裸 pwd：从子目录触发时 pwd 会偏移、写进错 keyspace 致召回静默丢失
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MEM="$HOME/.claude/projects/-$(printf '%s' "$ROOT" | sed 's:^/::; s:[^a-zA-Z0-9]:-:g')/memory"
[ -d "$MEM" ] || mkdir -p "$MEM"   # 新项目首次 stash 自动建
# MEMORY.md 不存在则建四段骨架（recall 总目录；按 type 分段）
[ -f "$MEM/MEMORY.md" ] || printf '# Memory\n\n## User\n\n## Feedback\n\n## Project\n\n## Reference\n' > "$MEM/MEMORY.md"
echo "$MEM"
```

**路径由项目根（git toplevel，回退 pwd）动态推导，绝不硬编码**（通用工具跨项目零修改；硬编码曾把记忆写错机器，裸 pwd 则在子目录触发时写偏）。若 harness 直接给了 memory 目录绝对路径，优先用它。**`MEM` 是 shell 变量、不跨 Bash 调用持久**，下面每个用到它的 bash 块都重新派生一次（别依赖上一块的 `MEM` 还在）。

### 2. 盘点候选

读 `MEMORY_SPEC.md` 拿规范，再扫本次对话，列出值得持久化的候选：新知识、做出的决策、发现的坑、配置/基础设施变更、用户反馈与偏好。按 `MEMORY_SPEC` 判断标准先粗筛（只留跨会话有用的）。

**加法 + 减法双扫**：除了「值得记什么」（加法），同时扫「本次对话作废了什么」（减法）：删除 / 退役 / 下线 / 停用 / 离职 / 决策反转这类破坏性事件，拿去撞现有 memory 的主题：对每个被作废实体名跑全文撞库 `LC_ALL=C grep -ril -- '<实体名>' "$MEM"`（`$MEM` 重派生见 Step 1；撞全文、不止 name / description，旧值常只散落在他题 memory 的正文里）。命中的进 Step 3 走 supersession / 墓碑，别当没发生。减法事件天生不触发「记一下」，是过时记忆的高发源。

### 3. 查重（先查后写，防碎片化）

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd); MEM="$HOME/.claude/projects/-$(printf '%s' "$ROOT" | sed 's:^/::; s:[^a-zA-Z0-9]:-:g')/memory"  # 每块各自重派生（变量不跨调用）
awk 'FNR==1{c=0} /^---[[:space:]]*$/{c++; next} c==1 && /^(name|description):/' "$MEM"/*.md 2>/dev/null   # 只取 frontmatter 区，防正文顶格示例行混入
```

对每个候选，比对现有 memory 的 name + description，判断**三种关系**（不只是去重）：

- **重复**（同一事实又记一遍）→ 不新建。
- **演进 / supersession**（新观察让某条旧状态变了：改了 / 转移了 / 删了）→ 更新那条，按 `MEMORY_SPEC` 的「记状态：时效与变更」节的「变更 ≠ 纠错」+「墓碑」写；绝不新建平行条（并存两条矛盾记忆正是「并存冲突」的根）。
- **无覆盖** → 新建。

候选与旧值冲突、拿不准怎么并的，按下判，且**无人值守下任何分支都不许停下来问用户**：

- **互斥**（不可能同时为真，如姓名 / 部署位置）且已确认是时效变更（旧值当时对、现在变了）→ supersede，新值上位、旧值留痕。
- 互斥但**排除不了 newer 是笔误 / 纠错** → 归「拿不准」。
- **兼容**（可能同时为真，如「负责 X 板块」‖「兼任评审委员」）→ 归「拿不准」。
- **「拿不准」一律保守**：两条都留、各带 as-of、正文标一句「待 memory-maintain（Phase 2）复核消解」；不问用户、不擅自选新、不合并。交互式追问留给 Phase 2 审计。

### 4. 判断记什么

套 `MEMORY_SPEC` 的「记什么 / 不记什么」：**不记**能从 git log / 代码 / CLAUDE.md 直接获取的，**不记**只对本次会话有用的临时上下文。**留下的若含「坑」，按 `MEMORY_SPEC` 的「记坑：诚实捕获」记**（根因没复现就标「疑似 / 未验证」、不冒充确定、带条件戳）。**留下的若含「状态」（角色 / 归属 / 现状 / 实体存废），按 `MEMORY_SPEC` 的「记状态：时效与变更」记**（带 as-of、变更走 supersession、删除立墓碑）。

留下的候选为空就直接到 Step 7 报告「本次无需持久化（理由）」收尾，**不为凑产物硬造低价值记忆**。

### 5. 写盘

**按 `MEMORY_SPEC.md` 的 frontmatter schema + 正文规范写 / 改**（文件名、name 前缀、description、type 枚举、Why/How、坑的诚实捕获等细节都在那，本步不复述、防漂移）。本步只强调流程动作：

- **每新建 / 更新一条，同步在 `MEMORY.md` 加 / 改一行索引**（按 type 分段），索引与文件一一对应。
- **状态型候选写入盖 as-of 戳**（按 `MEMORY_SPEC`「记状态：时效与变更」§2，本机真实时区）；混含条的状态部分进 description 也带戳。
- 发现存量失效的，**按类型分开处理**，都不干净覆盖（禁丢历史），且三类 description 处理方向不同、别用一个模板统括（措辞模板一律以 `MEMORY_SPEC`「记状态：时效与变更」§3 表 / §4 为准，本步只记方向、不复述格式）：
  - **写错**（错值 / 误建，当时就错）→ 留纠错痕迹（SPEC §3 纠错行）。
  - **过时·状态变更**（当时对、现实变了，实体还在）→ description 换当前真相 + 新 as-of 戳，旧值 X **出 description**、降为正文历史行（SPEC §3 时效变更行）。
  - **过时·实体消失**（删除 / 退役）→ 立墓碑，旧值 X **留在 description** 打死标、正文原样保留（前缀格式见 SPEC §4）。

### 6. 校验

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd); MEM="$HOME/.claude/projects/-$(printf '%s' "$ROOT" | sed 's:^/::; s:[^a-zA-Z0-9]:-:g')/memory"  # 每块各自重派生
bash ~/.claude/skills/stash/check.sh "$MEM"
```

🔴 must-fix 必须修到过；🟡 advisory 逐条 review（多数应修，少数可接受，如指向其它项目 keyspace memory 的带前缀链接：本 keyspace 查不到、属跨库引用）。

### 7. 更新 CLAUDE.md（条件）+ 报告

- **仅当**本次有项目配置 / 常用命令 / 基础设施 / 关键信息变更，才更新当前项目 `CLAUDE.md`（无变更跳过）。
- 报告：新建 N 条 / 更新 M 条 / 跳过哪些（及原因）/ check.sh 结果。

## 红线

1. **规范以 `MEMORY_SPEC.md` 为唯一真相源**，不在本文件或对话里复述 schema 细节（防漂移）。
2. **路径动态推导**（git toplevel，回退 pwd），绝不硬编码项目路径。
3. **先查重后写**，有覆盖去更新，绝不新建重复。
4. **写后必跑 `check.sh`**，🔴 必修。但 `check.sh` **只验 schema 合规、不验内容正确**：过线 ≠ 记对了，正确性靠诚实捕获 + 下游验证。
5. **MEMORY.md 索引与 memory 文件一一对应**，新增 / 改名必同步。
6. **只记跨会话有用的**（判断标准见 `MEMORY_SPEC`），不记 git / code / CLAUDE.md 可直接获取的。
7. **不自动触发**，只在用户明确要求时运行。
8. **状态变更走 supersession / 墓碑**，绝不新建平行矛盾条；状态型带 as-of 戳；冲突拿不准时保守并存、无人值守不问用户（时效与措辞规范见 `MEMORY_SPEC` 的「记状态：时效与变更」节）。
