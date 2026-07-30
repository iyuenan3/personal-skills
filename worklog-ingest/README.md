# worklog-ingest（已迁移）

> canonical 维护地已迁至 [worklog-kit](https://github.com/iyuenan3/worklog-kit)。本目录只保留指针，不再包含可发现的 `SKILL.md`。

worklog-kit 中的实现已去除个人路径和工作流 hardcode，改为 `worklog.config.yaml` 驱动，并同时支持 Codex 与 Claude Code。

## 使用

推荐直接从 worklog-kit 模板创建私有 vault，再在 Codex 或 Claude Code 中调用 `worklog-init`。单独查看源码：

[`worklog-kit/.agents/skills/worklog-ingest/`](https://github.com/iyuenan3/worklog-kit/tree/main/.agents/skills/worklog-ingest)

迁移前的 Maxwell 个人参考实现冻结在本仓 [`legacy/claude-era/worklog-ingest/`](../legacy/claude-era/worklog-ingest/)，只供考古，不建议安装。
