# Changelog

本仓库（monorepo）的演进史。各 skill 内部 changelog 见各子目录的 `CHANGELOG.md`。

格式参考 [Keep a Changelog](https://keepachangelog.com/)。

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
