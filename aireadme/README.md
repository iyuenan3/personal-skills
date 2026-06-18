# AIREADME

为每个项目维护一份 `AIREADME/`，该项目的 **AI 真相源**（AI-native 跨项目文档体系）。一个 [Claude Code](https://claude.com/claude-code) skill。

## 是什么 / 为什么

项目变多、互相调用变密后，AI agent（和人）需要快速搞懂「项目 A 的架构 / 部署 / 对外契约」，而不必啃它整个 repo。AIREADME 把这些散落的真相收进每个项目根的 **12 个固定文件**，双用途：

1. **跨项目了解**：别的项目读 `../<proj>/AIREADME/` 就懂你（架构 / 部署 / 契约）。
2. **防偏差**：项目自己的 agent 读 `CORE` / `DECISIONS` / `ARCHITECTURE`，不跑偏。

核心约束：**一条信息只进一个文件**（边界规则防腐烂）；**一项目一份 AIREADME**，不抽独立子节点；**key / secret / PII 绝不进**任何 AIREADME 文件。

## 12 文件模型

| 文件 | 作用 |
|---|---|
| INDEX | 导航 + 状态表 + 同步锚点 |
| CORE | 身份 / non-goals /「绝不」硬约束 |
| RELATIONS | 依赖图 + 共享资产 |
| SPEC | 对外契约（API/端点/schema/CLI）|
| ARCHITECTURE | 结构 + 禁改项 |
| DEPLOYMENT | 跑哪 / 共享服务 / 运维约束 |
| PRD | 产品意图（产品类）|
| ROADMAP | Now / Next / Later |
| CONVENTIONS | 项目特有约定 |
| DECISIONS | ADR（append-only）|
| MEMORY | 踩坑 / 事故（append-only）|
| CHANGELOG | 版本史（append-only）|

逐文件「写什么 / 不写什么 / 何时更新 / 哪些 N/A」+ 边界规则 + 项目类型适用矩阵，见 [`STANDARD.md`](STANDARD.md)。

## 安装

```bash
git clone https://github.com/iyuenan3/aireadme-skill.git ~/.claude/skills/aireadme
```

即把本仓库放到 `~/.claude/skills/aireadme/`，Claude Code 会自动识别该 skill。

## 用法

在**目标项目仓库**里，对 Claude Code 说 `/aireadme`（或「给这个项目建 / 更新 / 检查 AIREADME」）。三模式自动判定：

| 现状 | 模式 |
|---|---|
| 项目还没 `AIREADME/` | **init**，首次生成 |
| 已有 `AIREADME/` | **update**，按 git delta 增量更新 |
| 「检查 / lint」 | **check**，跑 `check.sh` |

init 后的项目结构：

```
<project>/
├── CLAUDE.md          # 瘦成 router（需你确认才动）
├── README.md
└── AIREADME/
    ├── INDEX.md   CORE.md   RELATIONS.md   SPEC.md
    ├── ARCHITECTURE.md   DEPLOYMENT.md   PRD.md   ROADMAP.md
    └── CONVENTIONS.md   DECISIONS.md   MEMORY.md   CHANGELOG.md
```

> 立项 / pre-code 项目只必填 INDEX + CORE + RELATIONS，其余留语义占位，按维护触发逐步填。

## Lint

```bash
bash ~/.claude/skills/aireadme/check.sh [AIREADME_DIR]   # 默认 ./AIREADME
```

退出码：🔴 = exit 1（必修）/ 🟡 = advisory（exit 0）。脚本会校验 12 文件齐全、INDEX 状态表 + 同步锚点、未填占位、明文密钥泄漏、边界粗查。需 UTF-8 locale（脚本已自设 `LC_ALL=C.UTF-8`）。

## 设计原则（节选）

- 一条信息只进一个文件；旧文档**按内容拆迁、不按文件名**（一个旧 `SPEC.md`/`INFRA.md` 常跨多个 AIREADME 文件）。
- 一项目一份 AIREADME，不抽独立子节点；被多项目共享的底座写进**属主项目**根 AIREADME。
- `CLAUDE.md` 瘦身、删根 doc 等破坏性动作：先把内容迁妥，再**合一确认门**等用户确认才落。
- AIREADME 要**可携带**：导入即去链（不照抄 `[[wikilink]]` 等内部链接）。

## Credits / Prior art

- 12 文件方案最初改造自一段 GPT 提示词，再按真实多项目实践迭代。
- 三层「真相源」思路受 Andrej Karpathy 提出的 "LLM Wiki"（Schema / Wiki / Diary 三层）启发。

## License

[Apache-2.0](LICENSE)。
