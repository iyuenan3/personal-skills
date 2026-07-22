# Changelog

本仓库（monorepo）的演进史。各 skill 内部 changelog 见各子目录的 `CHANGELOG.md`。

格式参考 [Keep a Changelog](https://keepachangelog.com/)。

## 2026-07-22: v0.7 stash 记状态（时效与变更）+ 整体 review 修复

### Added

- **stash ·「记状态：时效与变更」节（MEMORY_SPEC）**：记忆过时是记忆系统的最大留白，状态型记忆过期后 recall 持续喂旧值。新增写时纪律：状态型 vs 耐久型两把判定尺 / as-of 戳必进 description / 变更 ≠ 纠错（supersession 保历史）/ 实体消失立墓碑（含复活回退）/ 不记高频轮换状态 / 可选 `metadata.asOf` 机读钩子 / 存量回补 as-of 取证规则。
- **stash · SKILL 写时接线**：Step 2 加法 + 减法双扫（含全文撞库命令）；Step 3 查重升级为三种关系（重复 / 演进 / 无覆盖）+ 冲突保守并存（无人值守任何分支不问用户）；Step 5 三向 description 处理路由（写错 / 状态变更 / 实体消失方向各异）；红线第 8 条。

### Fixed

- **stash · 8 视角对抗 review 修复 15 项**（39 条发现证伪剩 31、去重 15）：memory 目录推导对齐 harness 真实 keyspace 命名（非字母数字全换 `-`，原推导对含 `.`/`_` 的路径会写进死目录）；check.sh 索引孤儿行校验补连字符形文件名（fixture 复现修复）；红线 2 路径机制注对齐 git-toplevel 锚定；Step 5 去模板化防复述漂移；混含条措辞消歧；示例全部占位化；标点全角统一。

## 2026-07-09: v0.6 worklog-ingest 同步到最新（方法论骨架定位）

worklog-ingest 公开镜像定位明确：**「个人工作日志 ingest 方法论骨架」**，不追求与私有工作副本逐字复刻。通用改进全量 port；雇主专属扩展（IM 协调层的具体坐标）收敛为泛化骨架，永不进公开仓。

### Added

- **worklog-ingest · IM 协调层（§3.6）**：任组长后 git 扫不到的协调 / 汇报 / 开会工作层。默认拉 + 触发消息可跳 + token 过期不阻塞兜底；输出契约新增「IM 协调段模板」（组长节奏 / 全组工作线 / 组内分工 / 跨群协调 / 会议纪要五子层）+ 四条纪律。群坐标 / 作用域 defer 到私有 memory，公开版只保留泛化骨架（不列群名 / 人名 / 命令细节）。
- **worklog-ingest · 时区铁律（§0）**：Claude Code Bash 沙箱注入 `TZ=America/Los_Angeles` 会把日期算错；所有算日期的 Bash 调用先 `export TZ=Asia/Shanghai`（env 不跨调用持久）。默认值表 / Step D 硬约束 / 时间线模板同步 UTC+8 口径。
- **pitfalls**：2026-07-08 已先行同步 Bash 沙箱 TZ 注入坑条（`771c31a`），与本条同源。

### Changed

- **worklog-ingest · 扫描扩展去重**：6 个与代码注释约 80% 重复的胖段压成导航索引（防双写漂移）。
- **worklog-ingest · 一致性修正**：multi-agent review 9 缺陷修复的可 port 部分（judgment §4 消歧、Step C 回执补 IM 层、A.0 memory 机制扩至 9 项等）；README 素材来源 / 参考价值 / hardcode 清单同步。

## 2026-06-28: v0.5.1 第二轮 review 修正

第二轮逐条坑本机对抗式复现 + 修复验证 + 采用者/作品集视角，修掉一批准确性与可用性问题。

### Fixed

- **LIBRARY.md 准确性**：逐条实测后修正 7 条 imprecise。裸变量吃字节的根因纠正（触发是 UTF-8 locale 而非字节模式，`LC_ALL=C` 反而不犯，已实测）；词边界区分 `[[:<:]]` 在 ugrep 静默失配 vs GNU grep 报错；阿里云加速器限定到 docker.io（`registry-mirrors` 不管 GHCR/自建，删误述）；iCloud 条 `rm` 不死锁只慢爬 + 补回 `.nosync` 的 symlink 步骤；Cloudflare 的 HTTP-01 视 SSL 模式而定 + 补 DNS-01 备选；两条 Claude Code 工具行为坑标注版本前提（当前 harness 不复现）。
- **安装命令静默坑**：pitfalls/README 与根 README 5 个 skill 的 `cp` 命令补 `mkdir -p ~/.claude/skills`（修首次安装时内容平铺、skill 注册不上的坑）；加安装自检 + 全局纪律文件新建兜底 + 澄清「是 Claude 动高危活时来查、不是你手动翻」。
- **SKILL.md 一致性**：消除「description 自动浮现 vs 只能 /pitfalls」的自相矛盾；加坑模板与 frontmatter 标点全角化。
- **project-lifecycle.md 作品集打磨**：软化「解法只有一个」；三尺度讲成两条正交轴（跨项目 vs 本地、策展 vs 原始）+ 晋级方向；免疫隐喻补「主动接种」缝；「每晚」加「有进展才聚」限定；加最小上手 + 澄清 story-writer 不在本工作流。

## 2026-06-28: v0.5 加入 pitfalls + 项目生命周期方法论

### Added

- 新增 `pitfalls/` skill（跨项目复用的通用工程踩坑库）
  - 解决「记忆项目隔离」导致的痛点：A 项目踩明白的工程坑，B 项目看不见、又踩一遍
  - 三件套 SKILL（pull 模型 + 触发纪律 + 加坑格式）+ LIBRARY（按域组织的种子坑库）+ README
  - 种子坑从既有跨项目工程经验抽象 + 脱敏而来（macOS locale/字节陷阱、git 删改混合、heredoc 引号、Cloudflare 新子域证书、阿里云 Docker 加速器、iCloud 同步等）
  - 定位「三层提纯阶梯」中间层：项目本地坑（stash）→ 通用工程坑（pitfalls）→ 全局铁律
- 新增根级 `project-lifecycle.md`：把 aireadme / stash / pitfalls / worklog-ingest 串成「以父项目为中枢的项目生命周期工作流」的方法论文档

## 2026-05-29: v0.4 加入 stash

### Added

- 新增 `stash/` skill（对话记忆持久化到项目 memory 目录 + MEMORY.md 索引 + check.sh 校验）
  - 从全局单文件 command（`~/.claude/commands/stash.md`）升级为 skill（三件套 SKILL + MEMORY_SPEC + check.sh），老 command 已删
  - 收益：记忆规范抽成 `MEMORY_SPEC.md` 单一真相源（告别 command prompt 复述漂移）+ check.sh 机械校验
  - 经两轮 subagent review（一轮静态审 bash + 二轮实战 dry-run / 对抗，共 17 findings 修 16）
  - 规范贴合 Claude Code harness 注入的 `# Memory` 段 + 两处本地特化（name 带 type 前缀 / 索引分隔符全角冒号）
- 新增 `stash/README.md`

## 2026-05-28: v0.3 加入 story-writer

### Added

- 新增 `story-writer/` skill（短篇小说创作，番茄小说平台 7000-10000 字）
  - 从已废弃的 `iyuenan3/OpenClaw-Customize-Skills` 仓迁入（该仓 2026-03-28 创建，2026-04-07 后未再活动，已 GitHub 删除）
  - SKILL.md 早期已被改造成 Claude Code skill 格式（`name:` / `description:` frontmatter），迁移时无需 port
  - 同仓另两个 OpenClaw 时代 skill（moltbook-daily / wordpress-blog-writer）因 Maxwell 不再使用且代码不保留而未迁入
- 新增 `story-writer/README.md`（简介 + 触发词 + 工作流 + 资源说明 + 迁入历史）

## 2026-05-28: v0.2 monorepo 化

### Changed

- 仓库从 `aireadme-skill` rename 为 `personal-skills`（GitHub 自动永久 redirect 老 URL）
- 老 `aireadme-skill` 内容全部迁入 `aireadme/` 子目录（git 历史 + rename detection 完整保留）

### Added

- 新增 `worklog-ingest/` skill（个人 worklog 自主 ingest agent，参考性公开）
- 根级 `README.md` / `CHANGELOG.md`（monorepo 层文档）
- 根级 `LICENSE`（Apache-2.0 全仓共用，从原 aireadme-skill 沿用）

## 2026-05-25: v0.1 aireadme 首发

- aireadme skill 首个公开版本（详见 [`aireadme/CHANGELOG.md`](aireadme/CHANGELOG.md)）
- 当时仓名 `aireadme-skill`，monorepo 化后迁入子目录。
