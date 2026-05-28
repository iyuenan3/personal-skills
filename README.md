# personal-skills

Maxwell 的 [Claude Code](https://claude.com/claude-code) skill 合集。

## skill 列表

| skill | 定位 | 受众 |
|---|---|---|
| [`aireadme/`](aireadme/) | AI-native 跨项目文档体系（12 文件 + 三模式 + lint） | 通用 |
| [`worklog-ingest/`](worklog-ingest/) | 个人 worklog 知识库自主 ingest agent | Maxwell 专属（参考性公开） |

## 安装

每个 skill 独立安装到 `~/.claude/skills/<name>/`，Claude Code 自动识别。

### aireadme（通用）

```bash
git clone https://github.com/iyuenan3/personal-skills.git
cp -r personal-skills/aireadme ~/.claude/skills/
```

详细用法见 [`aireadme/README.md`](aireadme/README.md)。

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
└── worklog-ingest/     # 个人 worklog ingest agent skill
```

各 skill 内部有独立 README + CHANGELOG（如 [`aireadme/CHANGELOG.md`](aireadme/CHANGELOG.md)）。

## 历史

本仓从 `aireadme-skill` rename 而来（2026-05-25 首发 aireadme v0.1，2026-05-28 monorepo 化）。老 URL `github.com/iyuenan3/aireadme-skill` 仍自动 redirect 到本仓，clone 不会失败。

## License

[Apache-2.0](LICENSE)。各 skill 公开内容均适用根 LICENSE。
