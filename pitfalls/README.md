# pitfalls

跨项目复用的**通用工程踩坑库**。一个 [Claude Code](https://claude.com/claude-code) skill。

## 解决什么

单人同时跑很多项目时，最浪费的不是写代码，是**在 B 项目重踩 A 项目早就踩明白的坑**。Claude Code 的项目记忆是**项目隔离**的：A 项目 memory 里的工程教训，B 项目的 session 默认看不见。结果同一个 macOS locale 坑 / git 坑 / 部署坑，被不同项目轮流踩一遍。

`pitfalls` 就是那条跨项目的共享记忆：把「与具体业务无关、换个项目还会踩」的坑抽象出来，集中存一处，任何项目动同类活之前查一眼就绕开。

## 怎么用

正常模式下，**是 Claude 在动高危活之前自动来查这条库**（写 bash/shell 脚本、改 git 历史、做 macOS 文件/locale 操作、写正则、配 DNS/Docker/反代、用 Read/Edit 改大文件之前），你只需在它建议时放行；你当然也可以自己 `/pitfalls` 翻 [`LIBRARY.md`](LIBRARY.md)。

- **查**：按要干的活定位 [`LIBRARY.md`](LIBRARY.md) 对应域，照「正确做法」改写即将执行的命令。
- **加**：踩到新坑时，先判断「单项目 vs 通用工程」。通用的按 [`SKILL.md`](SKILL.md) 的统一格式追加进 `LIBRARY.md`；单项目的留给项目自己的记忆（用 [`stash`](../stash/)）。

它是 **pull 模型**：不会自动弹出来，全部价值在于「该查的时候真去查」，所以下面的全局纪律那一步很关键。

## 安装

```bash
git clone https://github.com/iyuenan3/personal-skills.git
mkdir -p ~/.claude/skills && cp -r personal-skills/pitfalls ~/.claude/skills/
```

> `mkdir -p` 不能省：若 `~/.claude/skills/` 还不存在（第一次装 skill），直接 `cp -r ... ~/.claude/skills/` 会把内容平铺成 `~/.claude/skills/SKILL.md`、skill 注册不上（这本身就是「照 README 抄就翻车」的坑）。

**确认装好**：重开一个 Claude Code 会话，skill 列表里应出现 `pitfalls`，或直接试 `/pitfalls`。看不到 = 上一步 cp 落错了位置。

**装完务必再做一步**（让 pull 模型在对的时刻真被触发）：在全局 `~/.claude/CLAUDE.md` 里加一句 always-on 纪律：

```
- 写 bash / 改 git 历史 / macOS 文件·locale 操作 / 配 DNS·Docker·反代 / Read·Edit 改大文件前，先查 pitfalls 的 LIBRARY.md。
```

若 `~/.claude/CLAUDE.md` 不存在就新建它（普通 Markdown，手动编辑或让 Claude 帮你加都行）。没有这一步，`description` 只给 harness 一个**偶尔主动想起**本 skill 的机会，对「正要写 heredoc」这种当下时刻并不可靠，你就只能靠显式 `/pitfalls` 了。

随库自带一批种子坑（macOS locale/字节陷阱、git 删改混合、heredoc 引号、Cloudflare 新子域证书、iCloud 同步等），装好即可用，边用边长。

## 三层提纯阶梯

坑按局部性分三层，本库是中间层：

```
单项目坑     → 项目自己的 memory（stash 写，项目内自动加载）
通用工程坑   → 本库 LIBRARY.md（高危活前主动查）        ← pitfalls
全局铁律     → ~/.claude/CLAUDE.md（每个 session 自动加载）
```

越往上越贵、越要克制：全局只放极少数「每次都该记得」的，本库放长尾。

## 关联

- [`stash`](../stash/)：记**单项目**记忆。与 pitfalls 分工：stash 管「这个项目的事」，pitfalls 管「所有项目都该知道的工程坑」。
- 本仓 [`project-lifecycle.md`](https://github.com/iyuenan3/personal-skills/blob/main/project-lifecycle.md)：pitfalls 在整套项目生命周期工作流里扮演「集体记忆 / 舰队免疫」那一环。
