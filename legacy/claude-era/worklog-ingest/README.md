# worklog-ingest

**Maxwell 的 worklog 自主 ingest agent**（[Claude Code](https://claude.com/claude-code) skill）。

> ⚠️ **本 skill 不适合一般用户。**
> 公开发布仅作 Maxwell 个人版本管理 + 设计参考。

## 是什么

worklog（Maxwell 的个人知识库 + 工作日记系统）的 ingest 工作流抽象为一个**睡前无人值守**的自主 agent。

当 Maxwell 睡前说「记录今天 / 记录昨天 / 记录 5 月 X 日 / 补充今天 / 更新日记」并**在同一条消息里附带当天信息**（有什么工作 / 哪台机器没工作 / 发生什么事）时触发，把一天散乱的工作素材编译成：

1. 结构化日记 `diaries/YYYY-MM-DD.md`
2. 更新 wiki（index / log / 各项目页 / todos）
3. TODO 盘点
4. commit + push

**素材来源**：本机各项目 git log（无 git 的走文件 mtime 兜底）+ 远程工作机（SSH 上去跑一个自动发现桌面所有工作项目的扫描脚本）+ 远程投研机（默认无工作，触发消息说有才抓）+ IM 协调层（任组长后 git 扫不到的协调 / 汇报 / 开会工作，经工作机上已认证的 IM CLI 拉，作用域细节在私有 memory）+ Claude 项目记忆 + wiki/diaries 当日改动 + 触发消息本身附带的信息。

## 核心交互模型：睡前无人值守、永不阻塞

这是本 skill 最特别的设计，也是参考价值所在：

- **触发消息 = 完整输入**：用户发完消息就去睡了、不在线。所以 agent **永不以提问结尾、永不阻塞等回话**，一律一口气跑到 commit + push。
- **没提到的项一律走默认值**（远程投研机默认无工作、求职 / 生活默认无事件、日期 7 点为界不问等），不追问、不臆造。
- **遇到任何歧义**：用规则 / 默认自己拍 + 日记里标 ⚠️ + 必要时写 `.ingest-status.md`，绝不停下提问。

## 为什么不通用

包含以下 Maxwell 专属 hardcode：

- **个人 memory 路径**：`~/.claude/projects/-Users-maxwell-...-worklog/memory/`
- **远程机**：远程机的 SSH 别名、特定项目路径（含客户机器）
- **个人项目清单**：`~/Desktop/Claude-Project/` 下约 17 个项目的 slug
- **求职决策规则**：三档薪资 / 个人偏好城市 / Web3 灰色框架
- **个人写作规范**：不用破折号、中文全角标点、不脑补、不臆造
- **个人工作流默契**：凌晨段归前一天、远程工作机默认有工作、求职只记不导等
- **IM 协调层坐标**：群作用域 / 成员归属映射 / 认证通路全在私有 memory（公开版已收敛为泛化骨架，不列群名 / 人名 / 命令细节）

## 参考价值

如果你想做类似的 ingest agent，本 skill 的结构可参考：

- **5 步流程（A–E）**：A 后台自扫数据源 → B 解析触发消息（不提问、不等待）→ C 一行回执（不阻塞）→ D 自主跑（写日记 / 更新 wiki / TODO 盘点 / commit + push）→ E 终端打印完成清单 / 错误状态
- **三模式**：新增 `ingest:` / 补充 `ingest-补:` / 更新 `ingest-改:`
- **触发语 + 文件实测共定模式**：防覆盖历史日记（「记录今天」但当天日记已存在 → 自动转补充，不整篇覆盖）
- **写盘前校验**：独立的 Python 标点门 `scripts/punctuation_check.py`（CJK 上下文感知、commit 模式只 gate 破折号）
- **错误兜底**：`.ingest-status.md` 状态文件 + commit 已完成部分 + push（永不烂尾原则）
- **远程盲区**：本机扫不到的远程工作，靠 SSH 哨兵探活 + 远端自动发现脚本，不可达则日记标 ⚠️、不阻塞
- **git 扫不到的协调层**：任组长后大量工作发生在 IM（协调 / 汇报 / 对齐 / 开会），git-scan 天然盲区 → §3.6 默认拉 + 触发消息可跳 + token 过期不阻塞兜底；输出契约配「IM 协调段模板」（组长节奏 / 全组工作线 / 组内分工 / 跨群协调 / 会议纪要五子层）+ 四条纪律；群坐标 defer 到私有 memory、skill 本体不写死
- **时区铁律**：Claude Code Bash 沙箱注入 `TZ=America/Los_Angeles`，裸跑 `date` 会把跨时区次日工作错记成前一天 → 每个算日期的 Bash 调用先 `export TZ=Asia/Shanghai`（env 不跨调用持久，每次都带）

## 想做自己的版本？

参考 [`SKILL.md`](SKILL.md) 结构，替换所有 hardcode。需要换的关键词：

- `~/.claude/projects/` / `~/Desktop/Claude-Project/` / `WORKLOG=` 等本机路径
- 远程机 SSH 别名 / 远端扫描脚本 / 项目路径
- `worklog` / 知识库结构相关
- `frontmatter` / `wikilink` 等 Obsidian vault 相关
- 求职 / 项目命名 / 写作规范等个人偏好

## 安装（仅当你确认要用）

```bash
mkdir -p ~/.claude/skills && cp -r personal-skills/worklog-ingest ~/.claude/skills/
```

> `mkdir -p` 不能省：`~/.claude/skills/` 不存在时直接 cp 会把内容平铺、skill 注册不上。

或对应到 `<your-project>/.claude/skills/worklog-ingest/`（项目本地 skill）。

## License

[Apache-2.0](../LICENSE)。
