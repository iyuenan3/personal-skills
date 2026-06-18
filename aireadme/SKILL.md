---
name: aireadme
description: 在某个项目仓库里生成或维护它的 AIREADME/（AI 原生跨项目文档体系）。当用户说"给这个项目写/更新 AIREADME""按 AIREADME 标准建文档""scaffold AIREADME""检查 AIREADME"时使用；新项目立项铺骨架也用它。会读同目录 STANDARD.md 的逐文件规范，扫描本项目（含其 Claude Code 项目记忆，若有）后产出/更新 AIREADME/，并"提议"把 CLAUDE.md 瘦成 router（不自动改）。不用于日常 commit / 日记记录类工作流。
---

# AIREADME：AI 原生跨项目文档体系

为每个项目维护一个 `AIREADME/` 文件夹 = 该项目的 **AI 真相源**。双用途：
1. **跨项目了解**：别的项目读 `../<proj>/AIREADME/` 搞懂本项目（架构 / 部署 / 契约）。
2. **防偏差**：本项目自己的 agent 读 CORE / DECISIONS / ARCHITECTURE，不跑偏。

逐文件"写什么 / 不写什么 / 何时更新 / 哪些 N/A"的完整规范在**同目录 `STANDARD.md`**；执行任何模式前**必读它**。

## 模式

| 现状 / 触发 | 模式 |
|---|---|
| 项目无 `AIREADME/` | **init** |
| 已有 `AIREADME/` | **update** |
| "检查 / lint" | **check** |

## init 流程

1. **读 `STANDARD.md`** 拿 12 文件规范 + 边界表 + 项目类型 N/A 矩阵 + 占位规范。
2. **判项目类型**（code / infra / docs·meta / product）→ 按 STANDARD 矩阵定哪些文件实写、哪些 N/A 占位。**monorepo（多 app/包）仍只建一份根 AIREADME**，子 app/包是组件、在 ARCHITECTURE 描述，不各自建 AIREADME。
3. **摸清本项目**（素材来源）：
   - repo 结构（`find -maxdepth 2`，排除 `node_modules/` `vendor/` `upstream/` 等 vendored 目录）、`README.md`、`docs/`、已有 `PRD/SPEC/INFRA/ROADMAP/OPS/USAGE/ARCHIVE`
   - 配置：`package.json` / `Cargo.toml` / `docker-compose.yml` / `.env.example` / `CLAUDE.md`
   - `git log --oneline -20` + `git tag`（→ CHANGELOG）+ 最新 commit SHA（→ INDEX 同步锚点）。**无任何 commit**（立项/pre-code）→ 锚点暂占位，且首 commit 必须在删根前（见 Step 7）。
   - **（可选）本项目的 Claude Code 项目记忆**：若该项目在 Claude Code 用过、积累了项目记忆（路径 = 项目绝对路径每个 `/` 换 `-` → `~/.claude/projects/<dashed-path>/memory/`），读 `MEMORY.md` + 相关文件当耐久知识源。**目录不存在 → 跳过此源**（多数项目没有，正常）。
4. **已有文档定归属**（成熟 repo 关键，**这步只决定、不删**）：repo 已有 PRD/SPEC/INFRA/OPS/USAGE/ARCHIVE 等 → **按内容拆、不按文件名**（一个旧 doc 常跨多个 AIREADME 文件，映射见 STANDARD「旧文档迁入」）：重叠的标记**蒸馏迁入**、例外标记**指向/保留**，**绝不复制**（红线 4）。**vendored / 上游目录**（`upstream/` `vendor/` 等）：不吸收其 README/CLAUDE/LICENSE，ARCHITECTURE 记「vendored 依赖 + 指向该目录」；**上游身份若敏感 → scrub 禁词**，别写进任何 AIREADME 文件。
5. **拷 `template/AIREADME/` 到项目根 `AIREADME/`**，逐文件按 STANDARD 填（**先把 Step 4 标「迁入」的内容迁进来；删根延到 Step 7**）：
   - 无内容的留**语义占位**（写"将放什么 + 为何空 + 现状猜测"，不留裸 TODO）。
   - **导入即去链**（源文档若含 `[[wikilink]]`〔Obsidian 等〕或其它内部链接，不照抄，AIREADME 要可携带）：按链接目标分三类：① 本仓库 / 本地知识库内部页 / **项目记忆文件** → 内容**迁入**对应 AIREADME 文件或转**纯文本**（**绝不**编造成 `../x/AIREADME/` 死链）；② 真·别的项目仓库 → `../<proj>/AIREADME/`；③ 格式示例（`[[YYYY-MM-DD]]`、`[[slug]]` 之类占位）→ **原样保留**。
6. **跨项目 / 共享底座**：
   - RELATIONS 出向用 `../<proj>/AIREADME/`。
   - **每个项目只有一份 AIREADME（项目根），不抽独立子节点。** 共享底座（共享 Caddy / 域名路由 / 公共库，即便已在 `proj/edge/` 之类子目录里）→ 写进**属主项目根 AIREADME** 的 DEPLOYMENT/RELATIONS；消费方 RELATIONS 指向属主项目 `../<owner>/AIREADME/`。在报告里点名共享关系。
7. **破坏性动作合一确认门**（内容已按 Step 5 迁妥后，把下面**一次列出、等用户确认才执行**）：
   - **待 `git rm` 的根 doc 清单**（Step 4 标「迁入」且内容已迁妥的；删根不丢历史 = 内容已迁 + git rename）。
   - **CLAUDE.md**：若已是 router（薄、只有状态/路由/红线/命令/元信息）→ 不动、仅补「维护责任」段指向 AIREADME；若臃肿 → 给瘦成 router（80–150 行）的 **diff 预览**。
   - **立项 / 无 commit 项目**：`git rm` 必须在**首 commit 立项 baseline 之后**（无 commit 就删 = 真丢失、无 git 兜底）；**首 commit 也一并提请确认、不自动执行**（遵全局「commit 仅在用户要求时」）。
   确认后才 `git rm` + 落 CLAUDE 瘦身。
8. **写 INDEX 同步锚点**（机器可读契约，见 STANDARD「同步锚点格式」）：`last-synced: <commit SHA> · <date>` 独占一行，**SHA 必填**（立项无 commit 用 `pre-code` 哨兵），别塞 changelog / 备注，注释另起一行。update / drift 靠它算 delta。
9. **跑 `check.sh`**（🔴 exit 1 必修、🟡 exit 0 advisory）→ 报告：建了/实填/占位哪些、各旧 doc 迁入/指向/删根/保留、vendored 怎么处理、共享底座写进了谁、flagged 项。

## update 流程

1. 读 `STANDARD.md` + 现有 `AIREADME/`，取 INDEX 的 `last-synced` SHA。
2. `git log <SHA>..HEAD` + 看改动的 docs/code → 定哪些文件要更新（**新增 `upstream/`/`vendor/` 目录或上游身份变敏感 → 套 init Step 4 的「不吸收 vendored doc + scrub 禁词」守卫**）。
3. 按**更新触发**改对应文件（部署变→DEPLOYMENT / 重大决策→DECISIONS / 出事→MEMORY / release→CHANGELOG / 接口变→SPEC …）。
4. **append-only 文件**（CHANGELOG / DECISIONS / MEMORY）**只追加，不重写历史**。
5. 刷新 `INDEX.md` 状态表 + 把 `last-synced` 更到本次 HEAD 的 SHA（格式 `<SHA> · <date>`，见 STANDARD「同步锚点格式」；别塞 changelog 进锚点）。
6. 跑 `check.sh`（🔴 必修）+ 报告 diff。

## check 流程

跑 `check.sh`（12 文件齐 + INDEX 状态表 + 同步锚点**格式校验** + 未填占位清单 + key 泄漏 + 边界**仅机检 2 项**：ARCH 混对外 API / DECISIONS 混事故）+ **人工边界复核**（check.sh green ≠ 边界干净）：SPEC 没混实现细节 / ARCHITECTURE 没复述决策理由 / DECISIONS 没混事故 / ROADMAP 没塞 TODO 颗粒。

**漂移检查**（项目演进后判断 AIREADME 是否过期）：在项目 git 仓内跑 `check.sh --drift`，读锚点 SHA 算 `git rev-list <SHA>..HEAD`，报落后多少 commit + delta 是否触及结构 / 部署文件（DEPLOYMENT / ARCHITECTURE / SPEC 可能要更）。worklog-ingest 每日扫描会对当天活跃项目自动跑这一步、把漂移项列进完成报告（漂移雷达），据此决定要不要 `/aireadme update`。
> 退出码：🔴 = exit 1（必修）；🟡 = advisory / drift 信息（exit 0）。

## 红线（任一触发即停 + 校正）

1. **key / secret / PII 不进任何 AIREADME 文件**（committed + 可跨项目读）。
2. **CLAUDE.md 瘦身必须人确认**，不自动重写。
3. **append-only 文件不改历史**。
4. **一条信息只进一个文件**（按 STANDARD 边界表）；已有文档**迁入 xor 指向，绝不复制**；**删根 doc 前内容必须先迁妥 + 走确认门**（init Step 7）。
5. **占位语义化**（说明将写什么 + 为何空），不留裸 TODO。
6. **导入即去链**：`[[wikilink]]` 不照抄进 AIREADME（破坏可携带性）。
7. 只动当前 CWD 项目，不替别的项目写它的 AIREADME。
