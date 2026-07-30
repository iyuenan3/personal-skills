# personal-skills

Maxwell 的 Codex / Claude Code Skill 合集。

## skill 列表

| Skill | 定位 | 状态 |
|---|---|---|
| [`story-writer/`](story-writer/) | 短篇小说创作 Skill（番茄小说平台，7000-10000 字） | 本仓维护，Codex / Claude Code 双兼容 |
| [`aireadme/`](aireadme/) | AI 原生跨项目文档体系 | 已迁至 [worklog-kit](https://github.com/iyuenan3/worklog-kit)，本仓留指针 |
| [`stash/`](stash/) | 项目记忆持久化与校验 | 已迁至 worklog-kit，本仓留指针 |
| [`pitfalls/`](pitfalls/) | 跨项目通用工程踩坑库 | 已迁至 worklog-kit，本仓留指针 |
| [`worklog-ingest/`](worklog-ingest/) | worklog 无人值守 ingest | 已迁至 worklog-kit，本仓留指针 |

## 这些 skill 怎么组合：项目生命周期工作流

它们不是孤立工具。一个人同时跑很多项目时，可以用一个「父项目」当大脑，把 `aireadme` / `stash` / `pitfalls` / `worklog-ingest` 串成一条覆盖项目「从想法到退役」的工作流。该方法论与四个 Skill 的 canonical 现已统一迁入 worklog-kit。

完整方法论见 [worklog-kit 的 `docs/methodology.md`](https://github.com/iyuenan3/worklog-kit/blob/main/docs/methodology.md)。本仓 [`project-lifecycle.md`](project-lifecycle.md) 只保留迁移指针。

## 安装

当前完整 Skill 统一安装到 `~/.agents/skills/<name>/`，Codex 直接识别；Claude Code 在 `~/.claude/skills/<name>` 建软链接，复用同一实现。

### story-writer

```bash
git clone https://github.com/iyuenan3/personal-skills.git
mkdir -p ~/.agents/skills ~/.claude/skills
cp -R personal-skills/story-writer ~/.agents/skills/
ln -s ../../.agents/skills/story-writer ~/.claude/skills/story-writer
```

触发词：「写小说」「写短故事」「写故事」「创作小说」「创作故事」「番茄小说」「短篇小说」。详细用法见 [`story-writer/README.md`](story-writer/README.md)。

### 已迁移的四个 Skill

从 [worklog-kit](https://github.com/iyuenan3/worklog-kit) 安装。每个同名指针目录都给出了单独安装命令；完整 worklog 用户直接使用模板并调用 `worklog-init`。

迁移前源码完整冻结在 [`legacy/claude-era/`](legacy/claude-era/)，不再作为当前 Skill 安装。

## 仓库结构

```
personal-skills/
├── README.md           # 本文件
├── AGENTS.md           # Codex / Claude Code 共用项目规则
├── CLAUDE.md           # 指向 AGENTS.md 的 Claude 兼容入口
├── LICENSE             # Apache-2.0（全仓共用）
├── CHANGELOG.md        # monorepo 顶层 changelog（仓改名 + skill 增减里程碑）
├── .agents/skills/     # story-writer 的 Codex 项目级发现入口
├── .claude/skills      # 指向 .agents/skills 的 Claude 兼容入口
├── aireadme/           # 指针：canonical 已迁至 worklog-kit
├── story-writer/       # 短篇小说创作 skill（番茄小说平台）
├── stash/              # 指针：canonical 已迁至 worklog-kit
├── pitfalls/           # 指针：canonical 已迁至 worklog-kit
├── worklog-ingest/     # 指针：canonical 已迁至 worklog-kit
├── legacy/claude-era/  # 迁移前实现，只供考古
└── project-lifecycle.md # 方法论迁移指针
```

当前完整 Skill 与各迁移指针都有独立 README。

## 历史

- **2026-05-25** 仓首发，仓名 `aireadme-skill`，首个 skill = aireadme v0.1
- **2026-05-28** monorepo 化 + rename 为 `personal-skills`，加入 `worklog-ingest`（老 URL `aireadme-skill` GitHub 永久 redirect）
- **2026-05-28** 加入 `story-writer`（从已删除的 `iyuenan3/OpenClaw-Customize-Skills` 仓迁入）
- **2026-05-29** 加入 `stash`（对话记忆持久化 skill，从全局单文件 command 升级为 skill + 两轮 subagent review）
- **2026-06-28** 加入 `pitfalls`（跨项目通用工程踩坑库 skill）+ `project-lifecycle.md`（把四个 skill 串成项目生命周期工作流的方法论）
- **2026-07-22** `aireadme` canonical 迁至 [`worklog-kit`](https://github.com/iyuenan3/worklog-kit)（与其 project-lifecycle 工作流同源），本仓 `aireadme/` 降为指针
- **2026-07-30** `stash` / `pitfalls` / `worklog-ingest` 与 project-lifecycle canonical 全部收敛到 worklog-kit；旧实现冻结到 `legacy/claude-era/`，`story-writer` 完成 Codex / Claude Code 双适配

## License

[Apache-2.0](LICENSE)。各 skill 公开内容均适用根 LICENSE。
