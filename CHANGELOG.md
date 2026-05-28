# Changelog

本仓库（monorepo）的演进史。各 skill 内部 changelog 见各子目录的 `CHANGELOG.md`。

格式参考 [Keep a Changelog](https://keepachangelog.com/)。

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
