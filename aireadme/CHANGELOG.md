# Changelog

本 skill 的版本史。格式参考 [Keep a Changelog](https://keepachangelog.com/)。

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
