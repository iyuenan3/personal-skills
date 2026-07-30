# stash（已迁移）

> canonical 维护地已迁至 [worklog-kit](https://github.com/iyuenan3/worklog-kit)。本目录只保留指针，不再包含可发现的 `SKILL.md`。

当前实现同时支持 Codex 与 Claude Code，使用中立项目 memory，并能把旧 Claude memory 可恢复地迁移为兼容软链接。

## 安装

```bash
git clone https://github.com/iyuenan3/worklog-kit.git
mkdir -p ~/.agents/skills ~/.claude/skills
cp -R worklog-kit/.agents/skills/stash ~/.agents/skills/
ln -s ../../.agents/skills/stash ~/.claude/skills/stash
```

源码：[`worklog-kit/.agents/skills/stash/`](https://github.com/iyuenan3/worklog-kit/tree/main/.agents/skills/stash)

迁移前版本冻结在本仓 [`legacy/claude-era/stash/`](../legacy/claude-era/stash/)。
