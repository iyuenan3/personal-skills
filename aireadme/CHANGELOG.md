# Changelog

本 skill 的版本史。格式参考 [Keep a Changelog](https://keepachangelog.com/)。

## v0.4

聚焦「v0.3 收尾 + 既有加固」：v0.3 的 pm 蒸馏只接了声明侧、且带出一批一致性缺陷（多 agent 对抗式 review 抓出），本版补齐落地链，并修两个直击「防腐」使命的既有缺口。

### Added
- **check.sh 密钥扫描补私钥与多家 token**：新增 PEM 私钥头 `-----BEGIN … PRIVATE KEY-----`（红线 1 此前静默放行的最高危类）+ Slack `xox*-` / Google `AIza` / GitLab `glpat-`；泛型 `key=value` 分支加**值内**占位词豁免（仅当 `[:=]` 后的值本身含 `placeholder`/`your_`/`占位`/`替换`/`<…>` 等才豁免，行内注释里的词不算）免误杀 DEPLOYMENT 占位值、又不漏报真密钥。
- **update pre-code 分支**：`last-synced = pre-code` 时不再跑 `git log pre-code..HEAD`（fatal），改把全历史当 delta 逐文件填实、收尾把锚点 rebaseline 成 HEAD 真 SHA。
- **drift 对 pre-code 陈旧态自动兜底**：锚点=pre-code 但仓里已有真实 commit 时，`--drift` 改吐 🟡「该 update 翻真 SHA」而非静默跳过（补上漂移雷达对 pre-code 的盲点，不靠人脑）。
- **PRD 模板加「关键假设 / 风险」节** + STANDARD 边界表加「产品赌注/假设/pre-mortem 风险 → PRD（前瞻）」行并对 DECISIONS/MEMORY 消歧、再补 pm 产物分流消歧注（红线→CORE、风险→PRD）；PRD 必填清单补该项（跑过 pm 工作流条件必填）。
- **SKILL 流程接通 pm 蒸馏**：init Step 3 把 pm-skills 产出列为可选素材源，并明确「蒸馏后弃稿、不走迁入 xor 指向」；update 流程点一句。
- **check.sh self-test**：默认 lint 顺带校验硬编码 12 文件名数组与 `template/AIREADME/` 一致（改 STANDARD 文件清单忘同步 check.sh 时 🟡 报警）。
- **README 补 `check.sh --drift` 用法**与前置条件（此前新用户从 README 发现不了这个核心防腐能力）。

### Changed
- **init Step 8 裁决 pre-code vs 真 SHA**：已有 commit（含 Step 7 立项 baseline）→ 用真 SHA；唯确无 commit 才 `pre-code`；并加纪律「pre-code 项目出首个真实 commit 后须翻成真 SHA」（否则 drift 雷达永久跳过、无声漂移）。
- **红线 6 加限定**：格式示例类占位（`[[YYYY-MM-DD]]` 之类）不在「`[[wikilink]]` 不照抄」之列，与 init Step 5 分类③对齐。
- **模板约 20 处裸 `⚑ 待填。` 升级为语义占位**（答「将放什么」），与占位规范及同套模板已有的好占位看齐。
- drift 结构判定 `.env` 加边界 `\.env(rc)?([./]|$)` 免 `client.envelope.ts` 误判、且覆盖 `.envrc`（direnv）；`schema`/`.config` 保持不动（收紧会漏 `schema.sql`/`webpack.config.js` 真命中，advisory 场景假阴性更糟）。
- **Bearer 密钥检测单列并要求 token 含数字**：滤掉散文 `Bearer authentication_header_value` 类误报（真 token 几乎必含数字），高危前缀密钥（PEM/sk-/ghp_/AKIA/xox/AIza/glpat）不受影响。

### Fixed
- **`identify-assumptions` → `identify-assumptions-new`**（STANDARD + CHANGELOG 共 4 处）：v0.3 引用了不存在的 skill 名，pm-skills 实际按 new/existing 分叉、立项用 -new。
- **v0.3 发布时误删 CHANGELOG `## v0.2` 标题**：致 v0.2（drift 特性）内容被并进 v0.3、README「详见 CHANGELOG v0.2」跨引用悬空；已恢复标题、归位内容（此事本身违反红线 3 append-only，引以为戒）。
- drift 侧 `pre-code` 比对前小写归一（`tr A-Z a-z`），免大小写变体 `Pre-Code` 在 drift 与 lint 两模式判定分裂。

## v0.3

聚焦「立项思考的蒸馏落点」：立项工作流会借 pm-skills（`phuryn/pm-skills` marketplace）做前期产品思考（愿景 / 价值主张 / 精益画布 / PRD / 假设 / pre-mortem），但那些是**展开的推理过程**，aireadme 只该存**压缩的结论**。本版定死「怎么把 pm 产物蒸馏进 AIREADME、蒸馏后原稿即弃」，且**不为此加任何新文件**。

### Added
- **CORE 蒸馏指引**：身份·使命 ← product-vision + value-proposition；Non-Goals ← lean-canvas out-of-scope + 战略取舍；绝不 ← identify-assumptions-new 致命约束 / pre-mortem 红线。结论体，只留拍板结果不留推演。
- **PRD 蒸馏指引**：目标·成功指标 ← create-prd 的 Objective + Key Results（SMART）；用户问题 ← Market Segment + Value Proposition；**关键假设/风险各 1 行 ← identify-assumptions-new + pre-mortem**（弃原稿后赌注唯一存续处）。

### Changed
- 明确「读法 1 = 蒸馏即弃原稿」：pm-skills 的完整长稿是立项当下的临时草稿，蒸馏进 CORE + PRD 后不留 docs、不落盘（守 aireadme 轻量初心）。
- 明确「不加文件」原则：pm 产物只进 CORE + PRD 两个已有槽位，不为产品思考单开文件（避免 schema 膨胀 + N/A 项目里的僵尸占位）。12 文件模型不变。

## v0.2

聚焦「保鲜」：init 把出生做到位，但 update 纯被动、没人记得跑，导致 AIREADME 在现场无声漂移（实测多项目锚点滞后 2 至 4 周、退化成日期加 changelog）。本版把漂移从隐形变可见。

### Added
- **`check.sh --drift` 漂移模式**：在项目 git 仓内读锚点 SHA，算 `git rev-list <SHA>..HEAD` 落后多少 commit，并粗判 delta 是否触及结构、部署文件（docker / compose / Caddyfile / package.json / .env / migrations / schema 等）后提示 DEPLOYMENT、ARCHITECTURE、SPEC 可能要更（排除 AIREADME 自身路径，免改 `AIREADME/DEPLOYMENT.md` 被 deploy 子串自指误判）。
- **同步锚点格式契约**（STANDARD「同步锚点格式」）：单行 `<7-40 位 SHA 或 pre-code> · YYYY-MM-DD`，SHA 必填，不塞 changelog、备注，注释另起一行。
- **锚点格式校验**：`check.sh` 不再只查锚点「存在」，改查「可机器解析」（有 SHA 加合法日期）；退化成日期、prose 的锚点 🟡 报警，且按 SHA 有无分支文案（有 SHA 缺日期时 drift 仍可凭 SHA 算）。

### Changed
- INDEX 模板锚点注释从「值同行」改为「另起一行」（避免注释里重复 `last-synced:` 字面词被 greedy 取值污染）。
- `check.sh` locale 从 `C.UTF-8`（macOS 不存在，静默回落且漏 CJK）改 `LC_ALL=C` 字节模式；所有紧贴全角标点的变量加 `${...}` 花括号（bash 3.2 字节模式下裸变量会把全角字节吃进变量名）。

### Fixed
- drift 模式 `$sha）` 裸变量紧贴全角括号在 macOS bash 3.2 报 `unbound variable` 的崩溃。
- 锚点用全角冒号 `：` 时（中文写作高频），`LC_ALL=C` 字节模式下字符类 `[：:]` 按单字节拆、吃半个字符留游离字节，致 SHA 丢失加 drift／lint 双重误报；改为先 `s/：/:/g` 整体归一。
- 锚点英文标签写成 Title-case、全大写时，检测用 `grep -i`、剥前缀用 `sed` 大小写口径不一致致 SHA 解析失败；剥除子句加 `//I` 标志对齐。
- drift 误把「锚点不是 HEAD 祖先」（分支分叉 / rebase / 锚点超前）静默吞成「✅ 已同步」（漏报）；rev-list 前加 `git merge-base --is-ancestor` 门。
- 锚点解析被 INDEX 正文里提及 "last-synced" 字面词的句子撞 `grep -m1`；改为行首锚定 `^[[:space:]>]*(last-synced|上次同步)`。

## v0.1

首个公开版本。

### Added
- **12 文件 AIREADME 模型**（INDEX / CORE / RELATIONS / SPEC / ARCHITECTURE / DEPLOYMENT / PRD / ROADMAP / CONVENTIONS / DECISIONS / MEMORY / CHANGELOG）+ 边界规则表 + 项目类型 N/A 适用矩阵。
- **三模式**：`init` / `update` / `check`，`/aireadme` 触发。
- **一项目一份 AIREADME** 原则：不抽独立子节点；被 ≥2 项目共享的底座写进属主项目根 AIREADME。
- **旧文档迁入** 规范：按内容拆、不按文件名（一个旧 doc 常跨多个 AIREADME 文件）。
- **破坏性动作合一确认门**：删根 doc / CLAUDE.md 瘦身先迁妥再确认；立项 / 无 commit 项目删根前先首 commit。
- **vendored / 上游目录** 处理：不吸收其 doc，敏感来源 scrub。
- `check.sh` lint：12 文件齐全 / INDEX 状态表 + 同步锚点 / 未填占位 / 明文密钥泄漏 / 边界粗查；退出码 🔴=1 / 🟡=0。
- `template/AIREADME/` 12 文件骨架。
