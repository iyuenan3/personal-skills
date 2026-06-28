# stash

回顾当前对话、把跨会话有用的信息持久化进项目 memory 目录的 [Claude Code](https://claude.com/claude-code) skill。

## 是什么 / 为什么

Claude Code 有 per-project 文件记忆（`~/.claude/projects/-<dashed-cwd>/memory/`）。stash 把「这次对话学到、值得下次记住」的编译进去：用户偏好与反馈、项目决策与约束、踩过的坑、外部资源指针。

**显式触发**（`/stash`），不自动跑，持久化是写文件的副作用动作，只在用户明确要求时执行。

## 三件套

| 文件 | 作用 |
|---|---|
| [`SKILL.md`](SKILL.md) | 主流程 7 步（定位 → 盘点 → 查重 → 判断 → 写盘 → 校验 → 更新 CLAUDE.md（按需）+ 报告） |
| [`MEMORY_SPEC.md`](MEMORY_SPEC.md) | 记忆规范**单一真相源**（frontmatter schema / 四类 type / 命名 / 互链 / 判断标准），SKILL 和 check.sh 都引用它、不复述 |
| [`check.sh`](check.sh) | 校验脚本（🔴 block / 🟡 warn），可手动跑、可被 skill 调 |

## 安装

```bash
git clone https://github.com/iyuenan3/personal-skills.git
mkdir -p ~/.claude/skills && cp -r personal-skills/stash ~/.claude/skills/
```

> `mkdir -p` 不能省：`~/.claude/skills/` 不存在（首次装 skill）时直接 cp 会把内容平铺、skill 注册不上。

## 用法

显式触发：`/stash` 或「保存记忆 / 记一下 / 沉淀一下 / 记住这个」。skill 会盘点本次对话、查重、按 `MEMORY_SPEC` 写入 memory + 更新 `MEMORY.md` 索引、跑 `check.sh` 校验。

手动校验任意 memory 目录：

```bash
bash ~/.claude/skills/stash/check.sh [MEMORY_DIR]   # 无参数从 pwd 推导
```

## 通用性说明

记忆规范**贴合 Claude Code harness 注入的 `# Memory` 段**（name kebab-slug + `[[name]]` 互链 + metadata.type 四类枚举 + feedback/project 的 Why/How + MEMORY.md 一行索引）。

`MEMORY_SPEC.md` 末尾列了**两处本地特化**（name 带 type 前缀消歧 / 索引分隔符用全角冒号），那是为「memory 与某 Obsidian wiki 共享 `[[ ]]` 命名空间」「中文不用破折号」两个本地约束做的。换到别的项目，按自己情况照搬或调整即可。

## License

[Apache-2.0](../LICENSE)。
