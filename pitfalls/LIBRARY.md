# 通用工程踩坑库

> 跨项目复用的「通用工程坑」精选。每条 = 一个会反复踩、且与具体业务无关的坑。
> 用法见 `SKILL.md`。加坑用 SKILL.md「加」节的统一格式。
> 只写通用知识，不含任何项目／客户／雇主的具体标识（全抽象成占位符）。
> 工具行为类的坑（Claude Code harness 行为）会随版本变，每条标了前提，用前自测。

---

## Claude Code 工具

### 未成功完成的 Read 不满足 Edit 的「先读后改」前置
- **症状**：对大文件做一次**未能完整成功的 Read**，之后 `Edit` 报 `File has not been read yet. Read it first before writing to it.`。当前 harness：`Read` 一个 >256KB 的文件直接报错 `File content (...) exceeds maximum allowed size (256KB)`、不显示任何内容（旧版本可能返回 `[Truncated: PARTIAL view ...]`）。
- **根因**：只有一次**成功完成**的 Read（整文件，或带 `offset`／`limit` 的某行段）才把文件标记为本会话已读；任何未成功完成的 Read（报错或截断）都不满足前置。
- **正确做法**：编辑大文件前，用 `Read(file, offset=N, limit=M)` 精确读「覆盖编辑目标的那段」（小到不超限）再 Edit；单次 Read 上限约 256KB，超限必须分段。本会话已 `Write`／`Edit` 过的文件即「已读」，可直接再 Edit。**注意**：用 `cat` 等 Bash 命令读文件**不算**满足 Edit 前置，必须用 Read 工具。
- **触发场景**：改千行级的大文档／长配置／长脚本时高频。

### （历史 / 版本相关）某些 harness 上命令非零退出会截断后续输出
- **症状**：在**某些** Claude Code Bash 工具版本上，一段 shell 里某条命令（最常见 `grep`／`rg` 无匹配 exit 1）非零退出后，其后的 stdout 被整段截掉（连尾部 `echo` 都不显示）。**2026-06-28 实测当前 harness 不复现**（`false; echo X` 的 X 照常显示，失败 grep 后的 echo 也显示）。
- **根因**：这是**曾观察到的 harness 行为**（机制不明、非 shell 本身特性、随版本变）。用前自测一条 `false; echo PROBE`，看 PROBE 是否显示，即可判定本会话是否受影响。
- **正确做法**（防御习惯，在不受影响的 harness 上属低成本冗余，仍推荐）：① 布尔判断用 bash 原生 `[[ $x == *sub* ]]` / `case "$x" in *sub*) ;; esac`，不用 `grep -q`（可读性也更好）；② 想稳妥让某段输出完整，给它接 `| cat` 或结尾 `; true`（使该段 exit 0）；③ 「查残余应为空」可单跑一条 grep，无匹配 exit 1 即读作「0 命中 = 干净」。

### Claude Code Bash 工具注入 `TZ=America/Los_Angeles`，`date` / git 时间戳给的是太平洋时间
- **症状**：Bash 工具里裸跑 `date` 给太平洋时间，与机器真实系统时区（`/etc/localtime`）不符；靠 `date +%H` 之类算「今天」会把跨时区的次日工作错算成前一天；`git log --date=format-local` 时间戳也变太平洋。
- **根因**：Claude Code 的 Bash 工具环境注入了 `TZ=America/Los_Angeles`（覆盖系统真实时区，env 变量优先于 `/etc/localtime`）；用户机器本身没问题。
- **正确做法**：任何算日期 / 读时间戳的操作先显式定住目标时区 `export TZ=<目标时区>`（如 UTC+8 用 `Asia/Shanghai`），别裸信 `date`。用 `export` 指定而非 `unset TZ`（unset 会回退系统 `/etc/localtime`、系统时区被改就又偏；显式 export 才锁死）。env 不跨 Bash 调用持久 → 每个相关调用都要带。判定：`echo "$TZ"` 看注入值、`readlink /etc/localtime` 看系统真值、`TZ=<目标> date` 三方对比。
- **触发场景**：在 Claude Code Bash 里算「今天 / 昨天」、按日期窗口过滤 git log、给用户产出带时间戳内容（尤其用户 / 工作在非美西时区时）。

---

## Bash / Shell

### heredoc 定界符不带引号，Bash 命令替换破坏脚本体
- **症状**：`python3 <<EOF ... EOF` 里若含反引号 / `$` / `\`，Bash 在喂给 python 前先做命令替换 + 变量展开：反引号内容被当命令执行（报 `xxx: command not found`）、`$x` 被展开，python 收到的是被改坏的残体。
- **根因**：**不带引号**的 heredoc 定界符，Bash 会对 heredoc 体做替换（POSIX 标准行为，跨 bash/sh/zsh 一致）。
- **正确做法**：定界符**加单引号** `python3 <<'EOF' ... EOF`，Bash 原样传递。只有确实需要把外部变量展开进 heredoc 时，才用不带引号的 `<<EOF`（且确保体内无意外反引号／`$`）。
- **触发场景**：heredoc 里嵌 commit hash、路径示例、正则、代码片段时。

### lsof 多个选项默认是 OR 不是 AND
- **症状**：`lsof -p 12345 -i` 想看「PID 12345 的网络连接」，结果输出一大堆别的进程（sshd / 代理 / node 等），误以为都是目标 PID 的连接。
- **根因**：lsof 设计上**多个 list-selection 选项之间默认 OR**（满足任一即列出），man page 原文如此，跨 Linux/macOS 一致。
- **正确做法**：要 AND 必须加 `-a`：`lsof -a -p $pid -i -P`。识别被坑：输出的 `COMMAND PID` 列与 `-p` 给的 PID 不一致，就是中招了。多 AND 同理：`lsof -a -c nginx -iTCP -sTCP:LISTEN -P`。

---

## macOS 特有（字节 / locale / 文件系统）

### 默认 locale + regex 元字符处理多字节会拆字符（字面量扫描则稳）
- **症状**：在 C／POSIX locale（非交互 / harness / cron 的常见默认环境）下，用 `grep`／`sed` 的 regex 元字符（`.` 只配单字节、`[...]` 字符类按单字节拆）处理中文，**静默给错结果**：漏匹配、误配（假阳性）、或匹配半个字符。
- **根因**：**字面量按字节逐串比对在任何 locale 都稳**（所以 `LC_ALL=C grep '中文关键词'` 做泄漏扫描可靠）；出问题的是 **regex 元字符遇多字节**，C/POSIX locale 下把多字节字符按单字节拆。别误以为「`LC_ALL=C grep` 配中文永不出错」而把它用到 regex 场景。
- **正确做法**：扫描／核查类（如发布前查泄漏、查残留关键词）用 `LC_ALL=C grep`（**仅对字面量可靠**）；脚本里要对中文跑 regex，顶部 `export LC_ALL="${LC_ALL:-C.UTF-8}"`（注意：很老的 macOS 可能不带 C.UTF-8，setlocale 失败会静默退回 C），别在 C locale 下对多字节用 `.`／`[...]`（见下「字节模式字符类」条）。
- **触发场景**：发布 / 开源前查私货泄漏、批量核查中文关键词。

### 词边界 `\b` / `[[:<:]]` 跨 grep 实现不一致；中文批量替换别用 perl
- **症状**：想用词边界精确匹配，换一个 grep 实现就**静默失配**（不命中、也可能不报错）。
- **根因**：常见三种 grep 对词边界语法支持不一：`\b` 在现行 macOS BSD grep（`/usr/bin/grep` 2.6.0-FreeBSD）、GNU grep、ugrep 上**都支持**；但 BSD 专有的 `[[:<:]]` / `[[:>:]]` 在 GNU grep 和 ugrep 上都**不支持，且失败方式不同**：ugrep 是**静默不命中**（exit 1、无报错，最危险），GNU grep 是**大声报错** `grep: Invalid character class`（exit 2）。注意 macOS 交互 shell 的 `grep` 可能被装成 ugrep，跟 `/usr/bin/grep` 行为不同。
- **正确做法**：词边界优先用 `\b`（可移植性最好，三种实现都通）；只有必须兼容很老的 BSD grep 时才退回 `[[:<:]]`，且要知道它在 ugrep 上静默失败、在 GNU grep 上直接报错。空白用 POSIX 的 `[[:space:]]`（全平台通用）。中文**批量替换文件**别用 `perl -CSD -i -pe 's/中文/.../'`（`-e` 里的中文字面无 `use utf8` 仍是字节串、静默不匹配），改用 **Python**（`open(p, encoding='utf-8')` + `str.replace`，按真字符）；少量精确改用 Edit（先 Read 精确 copy-paste）。

### 字节模式下字符类 `[：:]` 会拆开全角标点
- **症状**：`LC_ALL=C` 字节模式下，把全角标点（如全角冒号 `：`，U+FF1A，3 字节）放进 sed/grep 的 `[...]` 字符类，会被当 3 个单字节成员，只消费其中一个字节、留下游离字节、污染后续取值（如取冒号后字段时 SHA 解析丢失）。
- **根因**：字节模式下字符类按单字节展开，多字节字符被拆。
- **正确做法**：先 `s/：/:/g` 把全角归一成半角，再用半角字符类。注意：字面量匹配 `s/：/:/g` 没事（按字节串匹配），**只有字符类 `[...]` 才拆**。

### bash 3.2 裸 `$var` 紧贴全角标点会吃字节（触发条件是 UTF-8 locale，不是字节模式）
- **症状**：UTF-8 locale 下 `echo "$sha）"`：在 `set -u` 下报 `sha\xef: unbound variable`（`）` = EF BC 89，EF 被并入变量名）；无 `set -u` 时**静默**把首字节吞进变量名、变量值连同丢失。
- **根因**：macOS 自带 bash 3.2 在 **UTF-8（多字节）locale** 下解析裸 `$name` 时，把紧随的多字节字符首字节误并入变量名，引用到不存在的 `sha\xef`。**注意触发条件是多字节 locale，不是字节模式**：`LC_ALL=C` 下反而不复现（可作旁路）。
- **正确做法**：所有紧贴 CJK / 全角标点的展开**加花括号** `${sha}`（跨 locale 稳定，首选）；或 `LC_ALL=C` 旁路（但花括号更可移植）。

### 大小写不敏感文件系统下 `[ -d X/AIREADME ]` 假匹配小写目录
- **症状**：`[ -d "$x/AIREADME" ]` 在默认 APFS/HFS+ 上会命中同目录的小写 `aireadme/`，把非目标当目标。
- **根因**：macOS 默认 APFS/HFS+ **大小写不敏感**。
- **正确做法**：① 若小写 decoy 不含碰撞文件，可 gate「只有真目标才有的唯一标志文件」如 `[ -f "$x/AIREADME/INDEX.md" ]`（但标志文件名本身也走大小写不敏感解析，decoy 里有同名异 case 的文件就失效）；② **要真正区分盘上大小写，用 `find`**（按 dirent 串比对、不走 FS lookup）：`[ -n "$(find "$x" -maxdepth 1 -type d -name AIREADME)" ]`，只有盘上真有大写 `AIREADME/` 才非空。
- **触发场景**：写跨平台 / 可移植 shell 脚本时，Linux（多为大小写敏感 FS）不复现、只在 macOS 翻车。

### Homebrew Python 装包被 PEP 668 拦 + user site 路径无版本号
- **症状**：`/opt/homebrew/bin/pip3.X install pkg` 被 PEP 668 拦（externally-managed）；加 `PYTHONUSERBASE=~/.local` 想换路径，结果包装上了但 import 不到。
- **根因**：Homebrew Python 是 externally-managed（有 `EXTERNALLY-MANAGED` marker）；且 macOS framework build 的 user site 路径是 `~/Library/Python/3.X/lib/python/site-packages`（**`python` 不带版本号**，与 Linux 的 `~/.local/lib/python3.X/...` 不同），换路径后解释器搜不到。
- **正确做法**：`pip install --user --break-system-packages pkg`（两个 flag 缺一不可：`--break-system-packages` 绕 PEP668、`--user` 把包落到默认 user site `~/Library/Python/3.X/`，独立于 brew site-packages，**不破坏任何 brew 包**）。别强行改 `PYTHONUSERBASE`，直接用 macOS 默认 user site。

---

## Git

### `git rm` 后再 `git add` 同一已删路径，整条 add 失败、静默漏暂存
- **症状**：`git rm a.md` 后 `git add a.md b.md`（想顺手暂存 b.md），报 `fatal: pathspec 'a.md' did not match any files`，**整条 add 失败、b.md 也没暂存上**；若 add 与 commit 分行写（非 `&&`），commit 照跑、只提交了删除，**静默漏掉 b.md**。
- **根因**：`git rm` 已把删除暂存好；再对已删路径 `git add` 因工作树无此文件而 fatal，且 `git add` 多路径先做整体 pathspec 解析、遇一个坏的就整条失败、不暂存任何路径（与坏 pathspec 的位置无关）。
- **正确做法**：提交「删除 + 修改」混合时，别再把已 `git rm` 的路径传给 add；只 add 还在工作树的文件，或直接 `git add -A` / `git add -u`（自动处理删 + 改）。commit 前 `git status --short` 确认 staged 集合，commit 后核对 `N files changed` 数对不对。

---

## 部署 / 基础设施

### Cloudflare 新子域默认「已代理」，Caddy 默认 TLS-ALPN-01 签不下证书
- **症状**：新建 CF 托管的子域（A/CNAME），部署的 Caddy 拿不到 Let's Encrypt 证书；Caddy 日志显示 ACME challenge 超时/失败，浏览器看到的是 CF 自动签发的 Universal SSL（公开受信、但不是站点自己的 LE）而非站点期望的 LE。
- **根因**：CF 给新子域**默认开启「已代理」（橙色云）**，边缘在 :443 终止 TLS。Caddy 默认首选的 **TLS-ALPN-01 在橙云下必失败**（CF 不把 `acme-tls/1` 握手透传到 origin）；HTTP-01 是否失败**取决于 CF 的 SSL/TLS 模式**：Flexible（回源 :80）下 HTTP-01 可成功，Full/Full(strict) 且 origin 尚无证书时才连带失败。
- **正确做法**：① 最简：CF 后台把该记录从橙色云切**灰色云 DNS only**（`proxied: false`），**先于部署**做，之后 ACME 直连 origin 即出证书；② **或**保留橙云（要 CF 的代理/DDoS）+ 改用 **DNS-01 挑战**（Caddy 的 cloudflare DNS 插件 / certbot-dns-cloudflare + 受限 API Token），origin 照样拿到自己的 LE 证书，与代理不互斥。（注：dashboard 建可代理记录默认橙云；经 API/Terraform 建则默认灰云。）

### 阿里云专属 Docker 加速器不缓存小众镜像（且 registry-mirrors 只对 Docker Hub 生效）
- **症状**：阿里云账号专属加速器（`https://<your_id>.mirror.aliyuncs.com`）pull 主流 Docker Hub 镜像（nginx/redis 等）秒级，pull **冷门 Docker Hub 镜像**（如 `calciumion/new-api`）卡在 0-1% 几分钟甚至超时。
- **根因**：`registry-mirrors`（本条全部修复手段）**只对 Docker Hub（docker.io）生效**，是它的 pull-through 兜底；非 docker.io 的 registry（ghcr.io / quay.io / gcr.io / 自建）pull 时**直连各自源、完全绕过 mirror 列表**。专属加速器对没缓存的冷门 docker.io 镜像回源直连、境内外都慢。
- **正确做法**：`/etc/docker/daemon.json` 配多级 fallback，**只加速 docker.io 镜像**（专属优先 + 公共加速器兜底）：
  ```json
  { "registry-mirrors": [
      "https://<your_id>.mirror.aliyuncs.com",
      "https://docker.m.daocloud.io",
      "https://docker.1ms.run" ] }
  ```
  `sudo systemctl restart docker` 后 `docker info | grep -A5 "Registry Mirrors"` 验证。**GHCR/quay/自建要走代理须改写镜像引用前缀**（如 `ghcr.m.daocloud.io/owner/img`），而非靠 registry-mirrors。公共加速器（daocloud/1ms 等）可用性随政策波动，用前实测。

---

## 文件同步

### 开发项目放进 iCloud/网盘同步区，dataless 冲突 + 改名翻车
- **症状**：`node_modules` 等几万小文件进 iCloud 桌面，多设备 dataless 占位 + 冲突副本（`xxx 2`）+ 拖累同步进程；`rsync` 访问 dataless 占位读内容触发 `Resource deadlock avoided (11)`（errno 11 / EDEADLK）并跳过（exit 23）；`rm` **不死锁**、只是 readdir 极慢爬（最终能爬完）。
- **根因**：开发项目本该靠 git remote 同步，不该靠文件级云同步；`.nosync` 排除必须在「未上云 / 已停同步」时做。
- **正确做法**：① 开发项目尽量移出同步区，靠 git remote；② 排除大目录用 `.nosync` 的**标准姿势是 `mv node_modules node_modules.nosync && ln -s node_modules.nosync node_modules`**（iCloud 只同步那个小 symlink、不碰 `.nosync` 真身；**别只 mv 不补 symlink，否则构建工具找不到 node_modules**），且**必须在目录全新建时 / 已停同步时做**：对**已上云**的目录建同名 symlink 替换它，会触发「symlink vs 目录」类型冲突、造一堆 `node_modules 2`；③ 清云端一坨（含抠不掉的隐藏副本 `.git/index 2`）最利落是 `mv ~/Desktop/X ~/X` 移出同步区，云端整个 X 自动删；④ 单设备 + 关「优化 Mac 储存空间」时，dataless evict 与多设备冲突都不发生，`.nosync` 从必须降为可选。
