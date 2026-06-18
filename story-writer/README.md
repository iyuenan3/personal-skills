# story-writer

短篇小说创作 [Claude Code](https://claude.com/claude-code) skill（目标平台：番茄小说，字数 7000-10000 字）。

## 触发词

「写小说」「写短故事」「写故事」「创作小说」「创作故事」「番茄小说」「短篇小说」

## 工作流

1. **确认题材**：用户提供 / 自动搜热门
2. **参考指南**：阅读 [`references/`](references/) 创作技巧（写作风格 / 热门题材 / 标题公式）
3. **制定大纲**：100 字导语 + 5-8 章 + 每章字数 1000-2000
4. **撰写正文**：7000 字以上一次性完成
5. **保存文件**：`workspace/story/YYYY-MM-DD-HH-MM-<小说名>.txt`

详细 prompt 见 [`SKILL.md`](SKILL.md)。

## 资源

| 目录 / 文件 | 作用 |
|---|---|
| [`references/writing-guide.md`](references/writing-guide.md) | 写作风格指南 |
| [`references/genres.md`](references/genres.md) | 热门题材清单（重生复仇 / 真假千金 / 追妻火葬场 / 家庭伦理 / 豪门总裁等） |
| [`references/title-formula.md`](references/title-formula.md) | 标题公式 |
| [`scripts/check_duplicates.py`](scripts/check_duplicates.py) | 查重（避免与已写故事重复） |
| [`scripts/word_count.py`](scripts/word_count.py) | 字数统计 |
| [`assets/story-template.txt`](assets/story-template.txt) | 故事模板 |

## 安装

```bash
git clone https://github.com/iyuenan3/personal-skills.git
cp -r personal-skills/story-writer ~/.claude/skills/
```

## License

[Apache-2.0](../LICENSE)。

## 历史

2026-03-28 创建于 `iyuenan3/OpenClaw-Customize-Skills`（OpenClaw 时代的 skill 集合仓），2026-05-28 迁入本 monorepo（老仓已删除）。SKILL.md 早期已被改造为 Claude Code skill 格式（`name:` / `description:` frontmatter），迁移时无需 port。
