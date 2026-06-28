# 通用工程踩坑库

> 跨项目复用的「通用工程坑」精选。每条 = 一个会反复踩、且与具体业务无关的坑。
> 用法见 `SKILL.md`。加坑用 SKILL.md「加」节的统一格式。
> 只写通用知识，不含任何项目／客户／雇主的具体标识（全抽象成占位符）。

---

## Claude Code 工具

### 截断的 Read 不满足 Edit 的「先读后改」前置
- **症状**：对大文件先 `Read`（返回 `[Truncated: PARTIAL view ...]`），再 `Edit` 文件内某处（即便编辑目标行就在已显示范围内），报 `File has not been read yet. Read it first before writing to it.`
- **根因**：Edit 的「本会话已 Read 过」前置，**不被截断／partial 的 Read 满足**。只有一次非截断的 Read（整文件，或带 `offset`／`limit` 的某行段）才把目标标记为「已读」。
- **正确做法**：编辑大文件前，用 `Read(file, offset=N, limit=M)` 精确读「覆盖编辑目标的那段」（小到不触发截断），再 Edit。本会话已 `Write`／`Edit` 过的文件即「已读」，可直接再 Edit。**注意**：用 `cat` 等 Bash 命令读文件**不算**满足 Edit 前置，必须用 Read 工具。
- **触发场景**：改千行级的大文档／长配置／长脚本时高频。

### grep 等命令非零退出会截断工具的后续输出
- **症状**：一段 shell 里某条 `grep`／`rg` **无匹配返回 exit 1**，该命令**之后**的 stdout 被工具整段截掉（连尾部 `echo` 都不显示），误以为脚本没跑完。
- **根因**：这是 **Claude Code Bash 工具的观测行为**（非 shell 本身特性，可能随 harness 版本变化）：工具按整段命令的退出码处理，任一命令非零退出即触发后续输出截断；`set +e`／`|| true`／`|| echo` 实测都拦不稳。下面的防御写法在任何版本都安全。
- **正确做法**：① 「查残余应为空」检查：单跑一条 grep／rg，把「输出空 + Exit 1」直接读作「0 匹配 = 干净」；② 一次看多处：一条 `rg 'A|B|C'` 且预期会命中，则 exit 0、输出完整；③ 布尔判断**别用 `grep -q`**，改 bash 原生 `case "$x" in *sub*) ;; esac` 或 `[[ $x == *sub* ]]`，完全不调 grep；④ 想看完整输出又怕某条 grep 失败截断，给该段接 `| cat`（管道整体 exit 0）或结尾 `; true`。

---

## Bash / Shell

### heredoc 定界符不带引号，Bash 命令替换破坏脚本体
- **症状**：`python3 <<EOF ... EOF` 里若含反引号 / `$` / `\`，Bash 在喂给 python 前先做命令替换 + 变量展开：反引号内容被当命令执行（报 `xxx: command not found`）、`$x` 被展开，python 收到的是被改坏的残体。
- **根因**：**不带引号**的 heredoc 定界符，Bash 会对 heredoc 体做替换。
- **正确做法**：定界符**加单引号** `python3 <<'EOF' ... EOF`，Bash 原样传递。只有确实需要把外部变量展开进 heredoc 时，才用不带引号的 `<<EOF`（且确保体内无意外反引号／`$`）。
- **触发场景**：heredoc 里嵌 commit hash、路径示例、正则、代码片段时。

### lsof 多个选项默认是 OR 不是 AND
- **症状**：`lsof -p 12345 -i` 想看「PID 12345 的网络连接」，结果输出一大堆别的进程（sshd / 代理 / node 等），误以为都是目标 PID 的连接。
- **根因**：lsof 设计上**多个选项之间默认 OR**（满足任一即列出）。
- **正确做法**：要 AND 必须加 `-a`：`lsof -a -p $pid -i -P`。识别被坑：输出的 `COMMAND PID` 列与 `-p` 给的 PID 不一致，就是中招了。多 AND 同理：`lsof -a -c nginx -iTCP -sTCP:LISTEN -P`。

---

## macOS 特有（字节 / locale / 文件系统）

### 默认 locale + regex 元字符处理多字节会拆字符（字面量扫描则稳）
- **症状**：在 C／POSIX locale（非交互 / harness / cron 的常见默认环境）下，用 `grep`／`sed` 的 regex 元字符（`.` 只配单字节、`[...]` 字符类按单字节拆）处理中文，**静默给错结果**：漏匹配、或匹配半个字符。
- **根因**：**字面量按字节逐串比对在任何 locale 都稳**（所以 `LC_ALL=C grep '中文关键词'` 做泄漏扫描可靠）；出问题的是 **regex 元字符遇多字节**，C/POSIX locale 下把多字节字符按单字节拆。别误以为「`LC_ALL=C grep` 配中文永不出错」而把它用到 regex 场景。
- **正确做法**：扫描／核查类（如发布前查泄漏、查残留关键词）用 `LC_ALL=C grep`（**仅对字面量可靠**）；脚本里要对中文跑 regex，顶部 `export LC_ALL="${LC_ALL:-C.UTF-8}"`，别在 C locale 下对多字节用 `.`／`[...]`（见下「字节模式字符类」条）。
- **触发场景**：发布 / 开源前查私货泄漏、批量核查中文关键词。

### 词边界 `\b` / `[[:<:]]` 跨 grep 实现不一致；中文批量替换别用 perl
- **症状**：想用词边界精确匹配，换一个 grep 实现就**静默失配**（不报错、也不命中）。
- **根因**：常见三种 grep 对词边界语法支持不一：`\b` 在现行 macOS BSD grep（`/usr/bin/grep`，2.6.0-FreeBSD）、GNU grep、ugrep 上**都支持**；但 BSD 专有的 `[[:<:]]` / `[[:>:]]` 在 GNU grep 和 ugrep 上**不支持、静默失配**。注意 macOS 交互式 shell 的 `grep` 可能被装成 ugrep，跟 `/usr/bin/grep` 行为不同。
- **正确做法**：词边界优先用 `\b`（可移植性最好，三种实现都通）；只有必须兼容很老的 BSD grep 时才退回 `[[:<:]]`，且要知道它在 GNU/ugrep 上会静默失败。空白用 POSIX 的 `[[:space:]]`（全平台通用）。中文**批量替换文件**别用 `perl -CSD -i -pe 's/中文/.../'`（`-e` 里的中文字面有字节/字符层不一致、静默不匹配），改用 **Python**（`open(p, encoding='utf-8')` + `str.replace`，按真字符）；少量精确改用 Edit（先 Read 精确 copy-paste）。

### 字节模式下字符类 `[：:]` 会拆开全角标点
- **症状**：`LC_ALL=C` 字节模式下，把全角标点（如全角冒号 `：`，U+FF1A，3 字节）放进 sed/grep 的 `[...]` 字符类，会被当 3 个单字节成员，只吃半个字符、留游离字节、污染后续取值（如 SHA 解析丢失）。
- **根因**：字节模式下字符类按单字节展开，多字节字符被拆。
- **正确做法**：先 `s/：/:/g` 把全角归一成半角，再用半角字符类。注意：字面量匹配 `s/：/:/g` 没事（按字节串匹配），**只有字符类 `[...]` 才拆**。

### bash 3.2 裸 `$var` 紧贴全角标点会吃字节
- **症状**：`echo "$sha）"` 里全角 `）` 的首字节被 bash 当成变量名一部分，报 `sha\xef: unbound variable`。
- **根因**：macOS 自带 bash 3.2 + 字节模式，变量名边界识别把多字节标点首字节并入。
- **正确做法**：所有紧贴 CJK / 全角标点的展开**加花括号** `${sha}`。

### 大小写不敏感文件系统下 `[ -d X/AIREADME ]` 假匹配小写目录
- **症状**：`[ -d "$x/AIREADME" ]` 在默认 APFS/HFS+ 上会命中同目录的小写 `aireadme/`，把非目标当目标。
- **根因**：macOS 默认 APFS/HFS+ **大小写不敏感**。
- **正确做法**：别用「目录存在」判真伪，改 gate 一个「只有真目标才有的唯一标志文件」，如 `[ -f "$x/AIREADME/INDEX.md" ]`。
- **触发场景**：写跨平台 / 可移植 shell 脚本时，Linux（多为大小写敏感 FS）不复现、只在 macOS 翻车。

### Homebrew Python 装包被 PEP 668 拦 + user site 路径无版本号
- **症状**：`/opt/homebrew/bin/pip3.X install pkg` 被 PEP 668 拦（externally-managed）；加 `PYTHONUSERBASE=~/.local` 想换路径，结果包装上了但 import 不到。
- **根因**：Homebrew Python 是 externally-managed；且 macOS user site 路径是 `~/Library/Python/3.X/lib/python/site-packages`（**`python` 不带版本号**，与 Linux 的 `~/.local/lib/python3.X/...` 不同），换路径后解释器搜不到。
- **正确做法**：`pip install --user --break-system-packages pkg`（加 `--user` 后装到 `~/Library/Python/3.X/`，独立于 brew site-packages，**不破坏任何 brew 包**）。别强行改 `PYTHONUSERBASE`，直接用 macOS 默认 user site。

---

## Git

### `git rm` 后再 `git add` 同一已删路径，整条 add 失败、静默漏暂存
- **症状**：`git rm a.md` 后 `git add a.md b.md`（想顺手暂存 b.md），报 `fatal: pathspec 'a.md' did not match any files`，**整条 add 失败、b.md 也没暂存上**；若 add 与 commit 分行写（非 `&&`），commit 照跑、只提交了删除，**静默漏掉 b.md**。
- **根因**：`git rm` 已把删除暂存好；再对已删路径 `git add` 因工作树无此文件而 fatal，且 `git add` 多路径遇一个坏 pathspec 会整条失败、不暂存任何路径。
- **正确做法**：提交「删除 + 修改」混合时，别再把已 `git rm` 的路径传给 add；只 add 还在工作树的文件，或直接 `git add -A` / `git add -u`（自动处理删 + 改）。commit 前 `git status --short` 确认 staged 集合，commit 后核对 `N files changed` 数对不对。

---

## 部署 / 基础设施

### Cloudflare 新子域默认「已代理」，Caddy/Certbot 签不下证书
- **症状**：新建 CF 托管的子域（A/CNAME），部署的 Caddy/Nginx+Certbot 拿不到 Let's Encrypt 证书；Caddy 日志显示 ACME challenge 超时/失败，浏览器看到的是 CF 自签的 Universal SSL 而非站点自己的 LE。
- **根因**：CF 给新子域**默认开启「已代理」（橙色云）**，代理层在 :443 终止 TLS 并自代理 :80/:443，使 Caddy 的 ACME 验证（默认 TLS-ALPN-01，及 HTTP-01）都拿不到 LE 证书。
- **正确做法**：CF 后台 DNS，对应记录点橙色云切成**灰色云 DNS only**（`proxied: false`），**先于部署**做。切换后 Caddy 重启或等几分钟自动重试即出证书。只有「不需要站点自己的证书、只用 CF 的 SSL+DDoS」时才保留橙色云（此时站点侧别跑 automatic_https）。

### 阿里云专属 Docker 加速器不缓存小众镜像
- **症状**：阿里云账号专属加速器（`https://<your_id>.mirror.aliyuncs.com`）pull 主流镜像（nginx/redis 等）秒级，pull 小众镜像（自建 / GHCR / 冷门 Docker Hub 项目）卡在 0-1% 几分钟甚至超时。
- **根因**：专属加速器只缓存主流镜像，没缓存的回源直连 docker.io，境内外都慢。
- **正确做法**：`/etc/docker/daemon.json` 配多级 fallback，专属优先 + 公共加速器兜底：
  ```json
  { "registry-mirrors": [
      "https://<your_id>.mirror.aliyuncs.com",
      "https://docker.m.daocloud.io",
      "https://docker.1ms.run" ] }
  ```
  `sudo systemctl restart docker` 后 `docker info | grep -A5 "Registry Mirrors"` 验证。主流走专属（最快）/ 小众走 daocloud / GHCR 等特殊源走 1ms。

---

## 文件同步

### 开发项目放进 iCloud/网盘同步区，dataless 冲突 + 改名翻车
- **症状**：`node_modules` 等几万小文件进 iCloud 桌面，多设备 dataless 占位 + 冲突副本（`xxx 2`）+ 拖累同步进程；对**已上云**的目录追溯 `mv node_modules node_modules.nosync` 会被当类型冲突，造一堆 `node_modules 2`；`rsync`/`rm` 访问 dataless 占位触发 `Resource deadlock avoided (11)`。
- **根因**：开发项目本该靠 git remote 同步，不该靠文件级云同步；`.nosync` 改名必须在「未上云 / 已停同步」时做。
- **正确做法**：① 开发项目尽量移出同步区，靠 git remote；② 要排除大目录用 `.nosync`，**在目录全新建时就改、别对已上云的追溯改名**（否则停同步再改）；③ 清云端一坨（含抠不掉的隐藏副本 `.git/index 2`）最利落是 `mv ~/Desktop/X ~/X` 移出同步区，云端整个 X 自动删；④ 单设备 + 关「优化 Mac 储存空间」时，dataless evict 与多设备冲突都不发生，`.nosync` 从必须降为可选。
