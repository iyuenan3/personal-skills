# personal-skills

Maxwell 的 [Claude Code](https://claude.com/claude-code) skill 合集。

## skill 列表

| skill | 定位 | 受众 |
|---|---|---|
| [`aireadme/`](aireadme/) | AI-native 跨项目文档体系（12 文件 + 三模式 + lint） | 通用 |
| [`story-writer/`](story-writer/) | 短篇小说创作 skill（番茄小说平台，7000-10000 字） | 通用 |
| [`stash/`](stash/) | 对话记忆持久化到项目 memory + 校验（贴合 harness `# Memory` 规范） | 通用 |
| [`worklog-ingest/`](worklog-ingest/) | 个人 worklog 知识库自主 ingest agent | Maxwell 专属（参考性公开） |

## 安装

每个 skill 独立安装到 `~/.claude/skills/<name>/`，Claude Code 自动识别。

### aireadme（通用）

```bash
git clone https://github.com/iyuenan3/personal-skills.git
cp -r personal-skills/aireadme ~/.claude/skills/
```

详细用法见 [`aireadme/README.md`](aireadme/README.md)。

### story-writer（通用）

```bash
cp -r personal-skills/story-writer ~/.claude/skills/
```

触发词：「写小说」「写短故事」「写故事」「创作小说」「创作故事」「番茄小说」「短篇小说」。详细用法见 [`story-writer/README.md`](story-writer/README.md)。

### stash（通用）

```bash
cp -r personal-skills/stash ~/.claude/skills/
```

显式触发：`/stash` 或「保存记忆 / 沉淀一下 / 记住这个」。详见 [`stash/README.md`](stash/README.md)。

### worklog-ingest（个人 skill）

```bash
cp -r personal-skills/worklog-ingest ~/.claude/skills/
```

⚠️ worklog-ingest 包含 Maxwell 个人偏好（memory 路径 / 求职决策 / 工作流默契等 hardcode），公开仅作版本管理 + 参考。**不建议直接使用**，详见 [`worklog-ingest/README.md`](worklog-ingest/README.md)。

## 仓库结构

```
personal-skills/
├── README.md           # 本文件
├── LICENSE             # Apache-2.0（全仓共用）
├── CHANGELOG.md        # monorepo 顶层 changelog（仓改名 + skill 增减里程碑）
├── aireadme/           # AI-native 跨项目文档体系 skill
├── story-writer/       # 短篇小说创作 skill（番茄小说平台）
├── stash/              # 对话记忆持久化 + 校验 skill
└── worklog-ingest/     # 个人 worklog ingest agent skill
```

各 skill 内部有独立 README + CHANGELOG（如 [`aireadme/CHANGELOG.md`](aireadme/CHANGELOG.md)）。

## 历史

- **2026-05-25** 仓首发，仓名 `aireadme-skill`，首个 skill = aireadme v0.1
- **2026-05-28** monorepo 化 + rename 为 `personal-skills`，加入 `worklog-ingest`（老 URL `aireadme-skill` GitHub 永久 redirect）
- **2026-05-28** 加入 `story-writer`（从已删除的 `iyuenan3/OpenClaw-Customize-Skills` 仓迁入）
- **2026-05-29** 加入 `stash`（对话记忆持久化 skill，从全局单文件 command 升级为 skill + 两轮 subagent review）

## License

[Apache-2.0](LICENSE)。各 skill 公开内容均适用根 LICENSE。
