# aireadme（已迁移）

> ⚠️ **canonical 维护地已迁至 [worklog-kit](https://github.com/iyuenan3/worklog-kit)。** aireadme skill 不再在本仓维护，本目录仅留指针。

## 安装（从 worklog-kit）

```bash
git clone https://github.com/iyuenan3/worklog-kit.git
mkdir -p ~/.agents/skills ~/.claude/skills
cp -R worklog-kit/.agents/skills/aireadme ~/.agents/skills/
ln -s ../../.agents/skills/aireadme ~/.claude/skills/aireadme
```

Skill 路径：`worklog-kit` 的 `.agents/skills/aireadme/`。用 worklog-kit 的 `worklog-init` 初始化 vault 时会自动完成双客户端安装。

## 是什么

aireadme = 为每个项目维护一份 `AIREADME/`（该项目的 **AI 真相源**，12 文件 + 三模式 init/update/check + lint）。详细规范见 worklog-kit 仓内 [`references/STANDARD.md`](https://github.com/iyuenan3/worklog-kit/blob/main/.agents/skills/aireadme/references/STANDARD.md)。

## 历史

- **2026-05-25** aireadme 首发于本仓（当时仓名 `aireadme-skill`，v0.1）。
- **2026-07** canonical 迁至 `worklog-kit`（与其 project-lifecycle 工作流同源），本仓自此留指针。
