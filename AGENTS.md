# AGENTS.md · personal-skills

本仓是公开 Skill 合集，Codex 与 Claude Code 并列支持。

## 当前维护边界

- `story-writer/` 是本仓唯一继续维护的完整 Skill。
- `aireadme/`、`stash/`、`pitfalls/`、`worklog-ingest/` 已迁到 [worklog-kit](https://github.com/iyuenan3/worklog-kit)，本仓同名目录只保留安装指针。
- 迁移前的旧实现冻结在 `legacy/claude-era/`，仅供考古和回滚，不再修复、不用于安装。
- `.agents/skills/` 是仓库内 Codex 发现入口；`.claude/skills` 指向同一目录，Claude Code 不维护第二份实现。

## 修改规则

- 修改 `story-writer` 时同步更新 `story-writer/SKILL.md`、README 与 `agents/openai.yaml`，并运行其脚本自检。
- 已迁移 Skill 的功能、文档与修复只改 worklog-kit，不在本仓恢复双份实现。
- 本仓公开，提交前检查 diff，不写入个人路径、凭证、客户或雇主信息。
- 中文内容使用中文标点，不使用破折号。
