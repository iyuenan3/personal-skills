# Changelog

本 skill 的版本史。格式参考 [Keep a Changelog](https://keepachangelog.com/)。

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
