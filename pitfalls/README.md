# pitfalls（已迁移）

> canonical 维护地已迁至 [worklog-kit](https://github.com/iyuenan3/worklog-kit)。本目录只保留指针，不再包含可发现的 `SKILL.md`。

当前实现同时支持 Codex 与 Claude Code，工程坑库位于 `references/LIBRARY.md`，并区分当前行为与 Claude 历史案例。

## 安装

```bash
git clone https://github.com/iyuenan3/worklog-kit.git
mkdir -p ~/.agents/skills ~/.claude/skills
cp -R worklog-kit/.agents/skills/pitfalls ~/.agents/skills/
ln -s ../../.agents/skills/pitfalls ~/.claude/skills/pitfalls
```

源码：[`worklog-kit/.agents/skills/pitfalls/`](https://github.com/iyuenan3/worklog-kit/tree/main/.agents/skills/pitfalls)

迁移前版本冻结在本仓 [`legacy/claude-era/pitfalls/`](../legacy/claude-era/pitfalls/)。
