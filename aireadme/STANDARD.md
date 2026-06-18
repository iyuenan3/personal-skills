# AIREADME 标准 v0.2

> 每个项目根 `AIREADME/` = 该项目的 **AI 真相源**。本文件是逐文件编写规范，`aireadme` skill 执行时读它。
> 双用途：**跨项目了解**（别人读你）+ **防偏差**（你读自己）。

## 文件清单（12）

| 文件 | 组 | 来访读 | 一句话 |
|---|---|:--:|---|
| INDEX | 导航 | ✓ | 路由 + 状态表 |
| CORE | 身份&契约 | ✓ | 身份 / non-goals / 硬约束 |
| RELATIONS | 身份&契约 | ✓ | 依赖图 + 共享资产 |
| SPEC | 身份&契约 | ✓ | 对外契约 |
| ARCHITECTURE | 设计&护栏 | ✓ | 结构 + 禁改 |
| DEPLOYMENT | 身份&契约 | ✓ | 跑哪 / 共享底座 |
| PRD | 规划&记忆 | — | 产品意图（产品类）|
| ROADMAP | 规划&记忆 | — | Now/Next/Later |
| CONVENTIONS | 设计&护栏 | — | 编码约定 |
| DECISIONS | 设计&护栏 | — | ADR（append-only）|
| MEMORY | 规划&记忆 | — | 踩坑（append-only）|
| CHANGELOG | 规划&记忆 | — | 版本史（append-only）|

✓ = 跨项目来访默认读这 6 个（INDEX 路由）。其余内部 + 自己防偏差用。

## 边界规则（防腐烂：一条信息只进一个文件）

| 信息 | 写 | 不写 |
|---|---|---|
| 对外 API/端点/schema | SPEC | ARCHITECTURE |
| 实现细节/内部结构 | ARCHITECTURE | SPEC |
| 决策理由 + 否决项 | DECISIONS | ARCHITECTURE（只放结论+链接）|
| 运行时事故/踩坑 | MEMORY | DECISIONS |
| 什么版本变了什么 | CHANGELOG | DECISIONS（CHANGELOG 链过去拿理由）|
| 可执行 TODO 颗粒 | 项目 TODO 系统 | ROADMAP（只放方向）|
| infra 项目"为什么存在" | CORE | PRD（产品类才写）|
| key/secret 本身 | **哪都不写** | — |

## 旧文档迁入（按内容拆，不按文件名）

旧 repo 常有名字不对应 12 文件的 doc（`SPEC.md`/`INFRA.md`/`OPS.md`/`DESIGN.md`…）。**文件名是历史包袱——按内容归位、不按名字**；一个旧 doc 常跨多个 AIREADME 文件，照上方边界规则逐段拆。

| 旧 doc | 内容 → 落点 | 处置 |
|---|---|---|
| INFRA / OPS / RUNBOOK | 部署·运维→DEPLOYMENT；结构→ARCHITECTURE；共享依赖→RELATIONS；事故→MEMORY | 迁入 + 删根 |
| DESIGN / ARCH | 结构→ARCHITECTURE；理由→DECISIONS | 迁入 + 删根 |
| PRD / ROADMAP / CHANGELOG | → 同名文件 | 迁入 + 删根 |
| SPEC | 先分 4 类（见下）| 见下 |
| README | —（人看入口）| 保留 |
| TESTING / TEST_REPORT | —（生成物）| 保留，CONVENTIONS 指向 |
| ARCHIVE | durable→CHANGELOG/DECISIONS/MEMORY | 不整搬，留 + 指向 |

**SPEC 同名最易误判，先分 4 类**：① 对外契约（API/端点/schema/CLI）→ SPEC，迁入+删根 ② 项目级 SSOT（"是什么+架构+部署+路线"打包）→ 拆进 CORE/ARCHITECTURE/DEPLOYMENT/ROADMAP/SPEC，迁入+删根、**走确认门**（动文档治理）③ 字段级穷举大参考 → SPEC 放摘要 + 原文件留作附录、指向 ④ monorepo 子模块 SPEC（`apps/<app>/SPEC.md`）→ 保留，根 AIREADME 指向。

**通则**：重叠 12 文件 → 蒸馏迁入 + `git rm` 删根（不留平行件）；**指向**只给「不同受众（README/安装/发布）/ 生成物 / 超大附录 / 子模块详规」。删根前内容先迁妥（破坏性动作走确认门）。

## 项目类型 → 文件适用矩阵

> N/A 的文件**也 ship**（写一行占位指向替代），不删。

| 文件 | code | infra | docs·meta | product |
|---|:--:|:--:|:--:|:--:|
| INDEX / CORE / RELATIONS / ROADMAP / CONVENTIONS / DECISIONS / MEMORY / CHANGELOG | ✅ | ✅ | ✅ | ✅ |
| SPEC | ✅ | ✅ | —（无对外 API 时占位）| ✅ |
| ARCHITECTURE | ✅ | ✅ | ✅（知识/目录结构）| ✅ |
| DEPLOYMENT | ✅ | ✅ | —（本地/无服务占位）| ✅ |
| PRD | ✅ | —（→CORE）| —（→CORE）| ✅ |

> docs·meta 例 = 纯文档 / 知识库项目（无 API/服务器 → SPEC/DEPLOYMENT 占位或改述；ARCHITECTURE = 知识体系结构；CONVENTIONS = 文档约定）。

## 逐文件规范

### INDEX `导航/跨`
必填：① 一句话定位 + 生命周期 ② 文件状态表（文件｜✅/⚑/—｜摘要）③ 按任务读路由。触发：任何文件增减/状态变。

### CORE `身份&契约/跨` — 来访首读 + 防偏差总纲
必填：身份 / 使命 / Non-Goals（做·不做）/ **绝不（硬约束红线）** / 生命周期。
不写：产品细节→PRD、架构→ARCHITECTURE、接口→SPEC。触发：定位/边界/红线变。

### RELATIONS `身份&契约/跨`
必填：① 出向依赖（谁·用途·`../<proj>/AIREADME/`）② 入向（谁用我）③ 共享底座。
共享底座（被 ≥2 项目依赖的 Caddy/域名/库）：写进**属主项目根 AIREADME** 的 DEPLOYMENT，这里只指向属主 `../<owner>/AIREADME/`（不抽独立节点）。触发：接入/解耦/归档。

### SPEC `身份&契约/跨` — 别人集成你的契约
必填：端点（base+协议）/ 鉴权 / 能力·模型清单 / 配额·分组 / 版本兼容（docs·meta 无对外 API 时 N/A 占位）。
不写：实现→ARCHITECTURE、为何→DECISIONS。触发：对外接口变。

### ARCHITECTURE `设计&护栏/跨+防偏差`
必填：组件+数据流 / 关键选型（→DECISIONS）/ **禁改项**。
不写：决策理由→DECISIONS、契约→SPEC。触发：结构/选型变。

### DEPLOYMENT `身份&契约/跨`
必填：主机+环境 / 怎么起 / 域名入口 / 共享底座引用 / 备份·升级·回滚 / 运维约束（docs·meta 本地/无服务时 N/A 占位）。
不写：key→哪都不写。（共享底座属本项目→配置写这；消费别人的→RELATIONS 指属主、不复制其配置。）触发：部署/环境变。

### PRD `规划&记忆/内`（产品类）
必填：目标 / 用户问题 / 成功指标 / UX 哲学。infra / docs·meta 类 = N/A 占位指向 CORE。触发：产品方向变。

### ROADMAP `规划&记忆/内`
必填：**Now** / Next / Later / 搁置(+原因)。不写：可执行 TODO 颗粒。触发：优先级变。

### CONVENTIONS `设计&护栏/内`
必填：命名 / 偏好模式 / 禁用模式（只写项目特有，共享基线链过去）。触发：约定变。

### DECISIONS `设计&护栏/内 · append-only`
必填：每条 = 编号+日期 + `Problem / Constraint / Decision / Alternatives(否决) / Tradeoff`。
不写：运行时事故→MEMORY。触发：重大技术/产品决策。

### MEMORY `规划&记忆/内 · append-only`
必填：每条 = 现象 + 根因 + 结论/避免。不写：决策→DECISIONS。触发：事故/失败/复盘。

### CHANGELOG `规划&记忆/内 · append-only`
必填：倒序版本块，每块 = 版本+日期 + `Added/Changed/Fixed/Removed/Deprecated`；理由链 DECISIONS。
不写：为什么→DECISIONS、未来→ROADMAP、commit 流水→git、踩坑→MEMORY。触发：release / 里程碑。

## INDEX 格式

```markdown
# <项目> · AIREADME
> 一句话定位 ｜ 生命周期: active
> last-synced: <commit SHA> · <date>
<!-- 同步锚点格式见下；注释另起一行，不和锚点值同行。INDEX 不列自己。 -->

## 状态
| 文件 | 状态 | 摘要 |
|---|:--:|---|
| CORE | ✅ | … |
| SPEC | ⚑ | 占位—接口未定 |
| DEPLOYMENT | — | N/A 未部署 |

## 按任务读
- 跨项目了解 → CORE + RELATIONS (+ SPEC 若集成)
- 改架构 → ARCHITECTURE + DECISIONS
- 部署/运维 → DEPLOYMENT
- 加功能 → PRD + ROADMAP + CONVENTIONS
```
状态符号：`✅ 已填 / ⚑ 占位(将填) / — N/A`

### 同步锚点格式（机器可读契约）

`last-synced` 是 update / drift 算 delta 的命根子，**必须机器可解析**，否则文档会无声烂掉：

- 单行 `last-synced: <SHA> · <date>`：`<SHA>` = 7-40 位 commit hex（立项未出 commit 用 `pre-code` 哨兵）；`<date>` = `YYYY-MM-DD`；中间分隔用 `·`。
- **SHA 必填**：没有 SHA，`git log <SHA>..HEAD` 这套增量机制直接失效（锚点一旦退化成「日期 + 一段 changelog」就无法算 delta）。
- **别塞 changelog / 备注 / 「待提交」字样**（那些进 CHANGELOG）；注释 `<!-- -->` 另起一行（同行注释虽会被剥除，但若注释里重复出现 `last-synced:` 字面词，会被 greedy 取值吞掉、解析出错的 SHA，故另起一行最稳）。
- `check.sh` 校验此格式（不合规 🟡）；`check.sh --drift`（在项目 git 仓内跑）据此算 AIREADME 落后 HEAD 多少 commit + delta 是否触及结构 / 部署文件。

## 占位规范

占位答两件：**将放什么** + **为何空/现状猜测**。不留裸 TODO。
例：`DEPLOYMENT ⚑ 未部署。计划：静态产物→Caddy。部署后填环境+域名。`

## CLAUDE.md = router（80–150 行）

只放：① 当前状态 ② 加载路由（任务→AIREADME）③ 红线指针→CORE「绝不」④ 维护责任（什么变更新哪个）⑤ 常用命令 ⑥ 元信息。
不放：设计/架构/部署/历史实体（在 AIREADME）。

## 写作风格

显式块：`Problem: / Constraint: / Decision: / Tradeoff: / Avoid: / Preferred: / Known Issue:`。高信号密度、少叙述、无营销语、显式约束。

## 立项 vs 演进（成熟度分档）

| 阶段 | 必填 | 其余 |
|---|---|---|
| 立项 pre-code | INDEX + CORE + RELATIONS | 其余文件仍 ship（语义占位），不删不并 |
| 有架构 | + ARCHITECTURE | |
| 部署后 | + DEPLOYMENT | |
| 暴露接口 | + SPEC | |
| 首个 release | + CHANGELOG | |

不破"立项最小骨架"原则，靠维护触发逐步填。

## 共享底座（一项目一份 AIREADME，不抽子节点）

**每个项目只有一份 AIREADME（项目根），不为子目录 / 共享底座单独建 AIREADME。** 被 ≥2 项目依赖的共享底座（共享 Caddy / 域名路由 / 公共库 / 平台服务，即便已是 `proj/edge/` 子目录）→ 写进**属主项目根 AIREADME** 的 DEPLOYMENT/RELATIONS；消费方 RELATIONS 指向属主项目 `../<owner>/AIREADME/`。
> 理由：节点抽象有维护成本，小底座不值得单独成套文档。例：一个被 ≥2 项目共享的 Caddy 配置，即便放在 `proj-a/edge/` 子目录，也只写进 `proj-a` 根 AIREADME。

---
v0.2，版本史见 CHANGELOG.md。
