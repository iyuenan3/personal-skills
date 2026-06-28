# Changelog

本仓库（monorepo）的演进史。各 skill 内部 changelog 见各子目录的 `CHANGELOG.md`。

格式参考 [Keep a Changelog](https://keepachangelog.com/)。

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
