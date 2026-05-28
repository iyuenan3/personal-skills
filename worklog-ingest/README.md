# worklog-ingest

**Maxwell 的 worklog 自主 ingest agent**（[Claude Code](https://claude.com/claude-code) skill）。

> ⚠️ **本 skill 不适合一般用户。**
> 公开发布仅作 Maxwell 个人版本管理 + 设计参考。

## 是什么

worklog（Maxwell 的个人知识库系统，基于 Karpathy LLM Wiki 三层架构）的 ingest 工作流抽象为自主 agent。

当 Maxwell 说「记录今天 / 记录昨天 / 记录 5 月 X 日 / 补充今天 / 更新日记」时触发，把一天散乱的工作素材（本地 git log + 远程协作机 SSH + Claude 记忆 + 用户 brain-dump）编译成：

1. 结构化日记 `diaries/YYYY-MM-DD.md`
2. 更新 wiki（index / log / 各项目页 / todos）
3. TODO 盘点
4. commit + push

全程自主无需人盯，只在启动时向用户一次性收集本机扫不到的补充信息。

## 为什么不通用

包含以下 Maxwell 专属 hardcode：

- **个人 memory 路径**：`~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/`
- **远程协作机**：Yuan-MBP 的 SSH 别名、特定项目路径（金融投研客户机器）
- **个人项目清单**：Maxwell 的 `~/Desktop/Claude-Project/` 下 10 个项目
- **求职决策规则**：三档薪资 / 个人偏好城市 / Web3 灰色框架
- **个人写作规范**：不用破折号、中文全角标点、不脑补、不臆造
- **个人工作流默契**：凌晨段归前一天、远程机默认有工作、求职只记不导等

## 参考价值

如果你想做类似的 ingest agent，本 skill 的结构可参考：

- **5 步流程**：自扫 → brain-dump 收集 → 一行回应不再追问 → 自主跑 → 完成通知 / 错误兜底
- **三模式**：新增 `ingest:` / 补充 `ingest-补:` / 更新 `ingest-改:`
- **触发语 + 文件实测共定模式**：防覆盖历史日记
- **写盘前校验**：rg + alternation 一条命令查残余，N=2 兜底防死循环
- **错误兜底**：`.ingest-status.md` 状态文件 + commit 已完成部分 + push（Never 烂尾原则）

## 想做自己的版本？

参考 [`SKILL.md`](SKILL.md) 结构，替换所有 hardcode。搜索以下关键词全部需要换：

- `~/.claude/projects/` / `~/Desktop/Claude-Project/` / `WORKLOG=` 等本机路径
- `Yuan-MBP` / `cfr` / 远程机相关
- `worklog` / `karpathy` / 知识库结构相关
- `frontmatter` / `wikilink` 等 Obsidian vault 相关
- 求职 / 项目命名 / 写作规范等个人偏好

## 安装（仅当你确认要用）

放到 `~/.claude/skills/worklog-ingest/`：

```bash
cp -r personal-skills/worklog-ingest ~/.claude/skills/
```

或对应到 `<your-project>/.claude/skills/worklog-ingest/`（项目本地 skill）。

## License

[Apache-2.0](../LICENSE)。
