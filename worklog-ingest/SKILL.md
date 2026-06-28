---
name: worklog-ingest
description: worklog 自主 ingest agent。用户睡前说「记录今天 / 记录昨天 / 记录 5 月 X 日 / 补充今天 / 更新日记」+ 附带当天信息时触发,把一天工作素材(本机 git log + yuenan-mbp 工作机桌面所有项目远程扫 + memory + wiki 改动 + 触发消息附带信息)编译成结构化日记 + 更新 wiki + TODO 盘点 + commit + push。全程无人值守、永不阻塞提问: 触发消息即全部输入、没提到的走默认值、用户发完即可去睡。
---

# worklog-ingest

> **写日记不是记录，是为未来复盘 5 分钟内能还原决策上下文。**
> 你是 Maxwell 的 worklog 自主 ingest agent，职责是把一天的工作素材编译成可复盘的日记 + 落档到 wiki + commit。
> 默认绑定 worklog（Maxwell 个人知识库）形态、Maxwell 写作偏好、Maxwell 工作流默契。不抽象给陌生人，以 Maxwell 为主。

---

## 触发与启动

**触发语**（用户说这些之一即触发）：

- 「记录今天 / 记录昨天 / 记录 5 月 X 日」 = **新增 ingest**（日记不存在 → 走完整 5 步）
- 「补充今天」 = **追加模式**（日记已存在 → 增量）
- 「更新日记」 = **交互改模式**（定向覆盖）

**模式由「触发语 + 文件实测」共同决定**（防覆盖历史日记；ARCHITECTURE「日记 append 不覆盖」契约的实现）：

- 触发语「记录今天」+ `diaries/$D.md` **已存在** → **auto-fallback 到补充模式**（走「追加」分支，不整篇 Write）
- 触发语「补充今天」+ `diaries/$D.md` **不存在** → **auto-fallback 到新增模式**（走「整篇 Write」分支）
- 触发语「更新日记」 → 始终交互改（无 fallback）

**三模式分支**：

| 模式 | Step A 自扫 | Step B 解析（不提问） | D.1 写日记 | D.2 更 wiki | D.3 TODO 盘点 | D.4 commit message |
|---|---|---|---|---|---|---|
| **新增** | 完整跑 | 解析触发消息附带信息 + 默认值填空 | 整篇 Write（**前置：文件不存在**） | 全跑（index 头部 / 项目表 / 日记表 + log + 各活跃项目页决策日志） | 全跑（4 态盘点） | `ingest: M/D 日记(<主线>)` |
| **补充** | 只扫增量（上次 ingest 后的新 commit） | 解析触发消息的增量信息 + 默认 | append 到现有日记尾部 | **有实质增量工作才跑增量**：刷 index 头部当日摘要 + 触及项目页决策日志 + log 追加补记说明；trivial 补充（如补 1 个 docs commit）可只动 diary + 该项目页计数 | 有 TODO 状态变化才跑，否则塌指针（见 E2） | `ingest-补: M/D <增量主题>` |
| **更新** | Skip A | 解析触发消息里要改什么（信息不全则按字面理解 + 标 ⚠️，不提问） | 定向 Edit 已有日记 | 默认 **diary-only 不动 wiki**；除非订正的是已镜像到 wiki 的事实（计数 / 项目页摘要 / 日期归属），则同步那一处保持一致 | 默认不跑；除非订正本身涉及 TODO 状态 | `ingest-改: M/D <修改点>` |

> **补充模式的 wiki 永久漂移注意**：次日 ingest 只记次日、不会回捕今天补充时漏更的 wiki 增量 → 补充模式当下该更的 index 摘要 / 项目页决策日志若跳过，就**永久漏记**（不像 diary 还能再补充）。所以补充模式的 D.2「有实质工作才跑」要从严判断：宁可多刷一句 index 摘要，别留 wiki 与 diary 不一致。trivial 跳过的也要在 commit message 里说清跳了什么。

**触发后立刻进入 5 步流程，全程无人值守、永不阻塞提问**：

```
Step A: 后台自扫数据源
   │
Step B: 解析触发消息附带的信息 = brain-dump,没提到的项用默认值填空(不向用户提问)
   │
Step C: 一行回执「收到、按这些信息开跑」(回显解析到的 + 默认假设,立即进 Step D)
   │
Step D: 自主跑 (生成日记 / 更新 wiki / TODO 盘点 / commit + push)
   │
Step E: 终端打印完成清单 / 错误状态(用户晨起读)
```

### 核心交互模型：睡前无人值守、触发消息即全部输入（2026-06-27 用户定）

**使用场景**： Maxwell 在**睡前**触发本 skill，触发消息里**附带当天信息**（「有什么工作 / 哪台机器没工作 / 发生什么事」），**敲回车发送后即去睡觉、不在线**。由此：

- **铁律：永不以提问结尾、永不阻塞等用户回话** —— 一律一口气跑到 commit + push。问一句 = 挂一整晚、什么都不会跑 = 失败。
- **触发消息 = 完整 brain-dump**： 用户说的就是全部输入，直接解析、不回问；纯「记录今天」无任何附带信息时也照默认跑、不挂起（Step E 标一句「未附带信息、按默认跑、请核对」）。
- **没提到的项一律走默认值**（见下表），不追问、不臆造。
- **遇到任何歧义**： 用规则 / 默认自己拍 + 日记标 ⚠️ + 必要时写 `.ingest-status.md`，**绝不停下提问**。
- **Step C 一行回执不是提问**，是「边确认边开跑」，用户在不在都不影响。

### 默认值表（触发消息没提到时按此处理，全部不追问；2026-06-27 用户逐项确认）

| 项 | 默认 |
|---|---|
| **日期归属** | 永远 **7:00 为分割线**（00:00-06:59 归前一天，否则当天）；连续跨日工作归主推进日。**从不询问**，有歧义自己拍 + 日记标一句 |
| **本机各项目** | 始终扫 git log（窗口内 commit）|
| **Yuan-MBP / cfr** | **默认无工作、不 SSH**（cfr 维护模式收尾中、将归档）；日记记「cfr 今日无工作」。**仅当用户明说「yuan-mbp 有工作」才** SSH §3 抓 |
| **yuenan-mbp（工作机）** | **默认有工作**；§3.5 跑 `yuenan-scan.sh` 扫**整个桌面所有工作项目**（auto-discover、含新建项目）。仅当用户明说「yuenan-mbp 没工作」才跳过 |
| **求职动态** | 无新事件，不单列求职段 |
| **对外动作 / 发布** | 无（除非扫描有明显发布类 commit）|
| **生活类事务** | 无，生活段写「无」 |
| **特殊强调 / 校准** | 无，主线由我按 judgment 提炼 |
| **前几天缺口日记** | **默认不补、不追问**（用户不在、不替他决定补哪天）；§2.1 检测到只在报告里被动标一句 |
| **commit + push** | 始终做（无人值守闭环）|

> 上表 = 「用户没说时」的默认。**用户在触发消息里明说的一律覆盖默认**（如「今天 petslog 发版了」→ 对外段记；「yuenan 今天没干活」→ 跳过 §3.5；「yuan-mbp 有工作」→ 反转抓 cfr）。

---

## Step A: 自扫数据源

**目标**：拿到本机 / 远程能扫到的客观素材，与触发消息附带信息对账。

**与 Step B 关系**： Step A 扫描 + Step B 解析触发消息**同回合内连着做**（不向用户提问、不等待）：后台跑扫描，同时解析用户触发消息里附带的信息，扫完即对账，直接进 Step C/D。客观数据以扫描为准、用户独有信息（求职 / 生活等）以触发消息为准、没说的走默认值表。

### A.0: 主动 Read 关键 memory（skill 触发时必读）

分两类读，**① 静态质量基线（与具体项目无关，一上来就读）+ ② 动态项目 memory（随活跃项目自动适配，新增项目无需改本清单）**。

**① 静态 essential subset**（直接决定 ingest 怎么跑：日期 / 归属 / 标点 / TODO / 远程 / locale，稳定且与具体项目无关，一上来先全 Read）：

```
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/feedback_stash_date_alignment.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/feedback_yuan_mbp_remote_collab.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/feedback_diary_timestamps.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/feedback_todo_review_via_memory_gitlog.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/feedback_wiki_symbol_consistency.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/feedback_job_scope_record_not_coach.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/<remote-project-git-log-memory>.md
~/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory/reference_macos_grep_locale.md
```

> 这 8 个是「上来必读全文」的**下限不是上限**。完整 feedback / reference 索引在每会话已注入的 `MEMORY.md` 里，新增的 workflow feedback 自动进 MEMORY.md，按需补读。

**② 动态项目 memory**（解决「常新增项目，固定清单必漏」）：

A.1 扫描拿到「本窗口有 commit 的活跃项目」后，对每个活跃 slug，**在已注入的 `MEMORY.md` 索引里找到对应的 `project_*.md`（Project 段链接 / 标题含该 slug）并 Read**：

- 映射**不是机械的**，别拼 `project_<slug>.md` 字面（会漏）：`ai-knowledge → project_ai_knowledge_kb`、`petslog → project_petslog_v3`、`maxwell-homepage → project_personal_static_page + project_maxwellii_site`。一律走 MEMORY.md 索引匹配。
- 读到的项目约束（定位 / 敏感数据红线 / 下一步）在 D.1 写该项目章节时遵守。
- 这样新立项项目（如 `<client-proj-b>`）一有活动，其约束**自动载入**，无需回来改这张清单。

### A.1: 自扫清单（全部默认执行）

**时间窗口公式**：目标归属日 `D` + 扫描窗口 `[D 07:00, D+1 07:00)`，涵盖一整天 + 凌晨延续。**所有自扫脚本统一用 `$D` / `$SINCE` / `$UNTIL` 变量，不出现 `YYYY-MM-DD` 占位字面**。

```bash
# ---- 0. 设定 WORKLOG 锚点(不依赖 cwd,Bash 工具长会话 cwd 可能漂移)----
WORKLOG="$HOME/Desktop/Claude-Project/worklog"

# ---- 0.1 计算目标归属日 D 与扫描窗口（macOS / GNU 兼容）----
HOUR=$(date +%H)
if [ "$HOUR" -lt 7 ]; then
  D=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d 'yesterday' +%Y-%m-%d)
else
  D=$(date +%Y-%m-%d)
fi
D_END=$(date -v+1d -j -f '%Y-%m-%d' "$D" +%Y-%m-%d 2>/dev/null \
        || date -d "$D + 1 day" +%Y-%m-%d)
SINCE="$D 07:00"
UNTIL="$D_END 06:59:59"   # git --until 闭区间(<=), 用 06:59:59 收口使窗口=半开 [D 07:00, 次日 07:00), 防正好 07:00:00 的 commit 跨两天双算
echo "目标归属日 D=$D, 扫描窗口 [$SINCE, $UNTIL]"

# ---- 0.2 模式实测(触发语 + 文件实测共定模式;防覆盖历史日记)----
if [ -f "$WORKLOG/diaries/$D.md" ]; then
  MODE="补"
  echo "⚠️  diaries/$D.md 已存在 → 模式 = 补充(追加,不整篇 Write)"
else
  MODE="新增"
  echo "✓ diaries/$D.md 不存在 → 模式 = 新增"
fi
# 若用户触发语与实测冲突(如「补充今天」但文件不存在),按上方 fallback 规则修正 MODE

# ---- 1. 真实日期对齐（防 compact summary 跨天压成一天）----
git -C "$WORKLOG" log --date=short --pretty=format:'%h %cd %s' -20

# ---- 2. 各项目今日 commit / 改动（按归属日期窗口）----
# SCAN_PROJECTS = canonical 列表, 须与 worklog/CLAUDE.md「需要扫描的项目」段一致;循环末尾 drift lint 自动比对告警。
# personal-skills = worklog 发布镜像子线: 扫到归 [[worklog]] 章节记, 不单列 ## 章 / 不建 wiki/projects 页。
# 关键: ① --branches --tags 不含 refs/stash(避免 WIP on main / index on main 伪 commit 当真实工作, Maxwell 高频 stash)
#       ② 显示用 %cd(commit-date, 与 --since/--until 过滤口径一致;rebase/squash 旧 author-date 不错位, 呼应 §4)
#       ③ 无 .git 项目(如 banks-data)走 mtime 兜底, 否则零 commit 新项目对扫描完全隐形
SCAN_PROJECTS="ai-knowledge astock-board banks-data bbq10-keyboard eastern-wisdom maxwell-homepage maxwell-rag-sources \
  multiplayer-xiaoshuo newapi-proxy jobs-hunt <client-proj-a> petslog \
  short-story <client-proj-b> xiaohongshu-tool personal-skills worklog"
for p in $SCAN_PROJECTS; do
  d="$HOME/Desktop/Claude-Project/$p"
  [ -d "$d" ] || continue
  if [ -d "$d/.git" ]; then
    log=$(git -C "$d" log --branches --tags --since="$SINCE" --until="$UNTIL" \
          --date=format-local:'%m-%d %H:%M' --pretty=format:'  %cd %h %s' 2>/dev/null)
    [ -n "$log" ] && printf '=== %s ===\n%s\n\n' "$p" "$log"
  else
    # 无 git: 文件 mtime 兜底列当日改动 + 抓项目 CLAUDE.md 进度段(BSD find 兼容, 无 -printf)
    files=$(find "$d" -type f -newermt "$SINCE" ! -newermt "$UNTIL" \
            ! -path '*/.git/*' ! -path '*/.venv/*' ! -path '*/node_modules/*' 2>/dev/null \
            | sed "s#$d/##" | sort | head -25)
    if [ -n "$files" ]; then
      printf '=== %s (无 git, 文件 mtime) ===\n%s\n' "$p" "$files"
      [ -f "$d/CLAUDE.md" ] && { echo '--- CLAUDE.md 进度段(节选) ---'; \
        grep -n -iE '进度|status' "$d/CLAUDE.md" | head -3; }
      echo ""
    fi
  fi
done
# drift lint: CLAUDE.md 扫描段的本地 slug 若不在 SCAN_PROJECTS 则告警(防双写漂移, banks-data 即此漏网)
cl=$(sed -n '/需要扫描的项目/,/^>/p' "$WORKLOG/CLAUDE.md" | grep -oE '`[a-z0-9-]+`' | tr -d '`' | sort -u)
for s in $cl; do
  [ -d "$HOME/Desktop/Claude-Project/$s/.git" ] || [ -f "$HOME/Desktop/Claude-Project/$s/CLAUDE.md" ] || continue
  printf '%s\n' $SCAN_PROJECTS | grep -qxF "$s" || echo "⚠️ drift: CLAUDE.md 扫描段有本地项目 $s 但 SCAN_PROJECTS 数组无 → 补进数组"
done

# ---- 2.5 AIREADME 漂移雷达（对今日活跃项目，算其 AIREADME 落后 HEAD 多少 commit）----
# 复用 aireadme skill 的 drift 算法(check.sh --drift, 单一真相源, 不在此重写); 只对「今日窗口内有 commit + 有真 AIREADME(以 INDEX.md 为准)」的项目跑。
# 漂移 = 你今天动过、AIREADME 没跟上 → Step E 列出, 你决定要不要 /aireadme update。本 skill 只暴露漂移、绝不自动改 AIREADME(update 有确认门)。
# scope 边界: 只抓「今日活跃」的漂移; 今天没动但陈年滞后的项目不在此列(定期手动 /aireadme check 全量)。雷达全清 ≠ 全库同步。
# 远程项目(cfr / CarysCloud)无本地 AIREADME, 不在雷达范围。
DRIFT_TOOL="$HOME/.claude/skills/aireadme/check.sh"
if [ -f "$DRIFT_TOOL" ]; then
  echo "--- AIREADME 漂移雷达(今日活跃项目)---"
  for p in $SCAN_PROJECTS; do
    d="$HOME/Desktop/Claude-Project/$p"
    # 门用 INDEX.md(不是 -d AIREADME): macOS 大小写不敏感 FS 下 -d "$d/AIREADME" 会假匹配到小写 aireadme/ 等 skill 目录; 真项目 AIREADME 必有 INDEX.md
    [ -d "$d/.git" ] && [ -f "$d/AIREADME/INDEX.md" ] || continue
    git -C "$d" log --branches --tags --since="$SINCE" --until="$UNTIL" --oneline 2>/dev/null | grep -q . || continue
    # E1 内容新鲜度门(2026-06-27): 该项目 AIREADME/ 今日窗口内有 commit = 项目自己(自有 session, 如 petslog 等)在维护 AIREADME
    #   → 抑制「落后」噪音。根因: worklog 侧 last-synced 锚点不由 worklog bump、对自有 session 项目恒报「落后 N」+ 建议「/aireadme update」(那是项目 session 职责、对 ingest 操作者不可执行)。
    #   用「AIREADME 真实新鲜度」替代「按所有权手维护 skip 名单」: 自动覆盖未来任意自有 session 项目, 且不误伤 worklog 自身这类真该 ingest 维护的(它今日 AIREADME 没 commit → 不抑制)。wc -l 恒 exit 0 防截断。
    aireadme_fresh=$(git -C "$d" log --branches --tags --since="$SINCE" --until="$UNTIL" --oneline -- AIREADME/ 2>/dev/null | wc -l | tr -d ' ')
    out=$( cd "$d" && bash "$DRIFT_TOOL" --drift AIREADME 2>/dev/null )
    # case 必须有 catch-all: check.sh 的 🔴 无 INDEX / 🟡 不是 HEAD 祖先 / 🟡 不在本仓历史 都是真漂移信号, 漏掉等于废掉上游防漏报。
    # 静默只给 ✅ 已同步 + pre-code(用 emoji/关键词前缀判, 别用 *同步* 因「不是祖先」消息里含「已同步」字样)。
    case "$out" in
      ✅*|*pre-code*) : ;;
      *落后*) [ "${aireadme_fresh:-0}" -gt 0 ] || printf '  ⚠️ %s: %s\n' "$p" "$(printf '%s' "$out" | head -1)" ;;
      *无可解析*) printf '  ⚠️ %s: AIREADME 锚点退化(无 SHA), 先 /aireadme 修锚点\n' "$p" ;;
      *) printf '  ⚠️ %s: AIREADME 漂移信号需核对: %s\n' "$p" "$(printf '%s' "$out" | head -1)" ;;
    esac
  done
else
  echo "(aireadme check.sh 不在, 跳过漂移雷达)"
fi

# ---- 2.1 漏记前几天缺口检测（非阻塞；逻辑属 D 计算后，置此因依赖 SCAN_PROJECTS 作用域）----
# 6/17 拖到 6/18 才补、靠用户提醒的教训。最近 7 天内逐日查: 无日记但各项目当天有 commit → Step B 主动问。
# 逐日查日记存在性(非「最后一篇之后」), 尾部缺口 + 中间空洞(6/15、6/17 有但 6/16 无)都能抓。
# ⚠️ B2 局限(2026-06-27 标注): gtot 只数本地 .git commit, 对「只做了远程主线(CarysCloud / cfr)、本地 0 commit」的缺口日恒判 gtot=0、原本静默 = 假 all-clear(漏记最高价值工作流)。
#   故对每个无日记缺口日: gtot>0 → 报本地 commit 数; gtot==0 → 仍打一行常驻提示(本地无 commit 不等于没干活、远程未计入), 让用户自行回忆远程是否漏记。无 git 项目同理只能靠这行兜。
gstart=$(date -v-7d -j -f '%Y-%m-%d' "$D" +%Y-%m-%d 2>/dev/null || date -d "$D -7 day" +%Y-%m-%d)
g="$gstart"
while [[ "$g" < "$D" ]]; do
  gend=$(date -v+1d -j -f '%Y-%m-%d' "$g" +%Y-%m-%d 2>/dev/null || date -d "$g +1 day" +%Y-%m-%d)
  if [ ! -f "$WORKLOG/diaries/$g.md" ]; then
    gtot=0
    for gp in $SCAN_PROJECTS; do
      gd="$HOME/Desktop/Claude-Project/$gp"
      [ -d "$gd/.git" ] && gtot=$((gtot + $(git -C "$gd" log --branches --tags \
        --since="$g 07:00" --until="$gend 06:59:59" --oneline 2>/dev/null | wc -l | tr -d ' ')))
    done
    # 默认不补、不追问(用户睡前不在、不替他决定补哪天, 2026-06-27 定): 只在 Step E 报告被动标一行供晨起参考
    if [ "$gtot" -gt 0 ]; then
      echo "ℹ️ 缺口: $g 无日记但各项目当天本地共 $gtot 个 commit → Step E 被动标一句(默认不补、不追问、晨起自行决定)"
    else
      echo "ℹ️ 缺口: $g 无日记、本地 0 commit → 仅基于本地 git、远程未计入(默认不补、不追问)"
    fi
  fi
  g="$gend"
done

# ---- 3. Yuan-MBP cfr 远程（默认无工作、不 SSH；2026-06-27 用户定：cfr 维护模式收尾、将归档）----
# 默认: 直接记「cfr 今日无工作」、跳过本块 SSH。仅当触发消息明说「yuan-mbp 有工作」, agent 把 CFR_SCAN=1 才跑下面的块抓 cfr git log。
# 哨兵 CFR_REACHABLE 剥「可达 0 commit vs 不可达」; ConnectTimeout=8 防休眠挂; cfr 路径见 memory <remote-project-git-log-memory>。
CFR_SCAN=""   # 仅当用户明说 yuan-mbp 有工作时由 agent 置 1（默认空 = 不 SSH）
if [ -n "$CFR_SCAN" ]; then
  cfr=$(ssh -o ConnectTimeout=8 yuan-mbp "P='<远程投研项目路径>'; \
    echo CFR_REACHABLE; [ -d \"\$P/.git\" ] || echo CFR_PATH_MISSING; \
    git -C \"\$P\" log --branches --tags --since='$SINCE' --until='$UNTIL' \
    --date=format-local:'%m-%d %H:%M' --pretty=format:'  %cd %h %s'" 2>/dev/null)
  case "$cfr" in
    *CFR_PATH_MISSING*) echo "=== cfr ⚠️ Yuan-MBP 可达但 cfr 路径失效(疑似改名/迁移) → 引言块标、勿当可达 0 commit ===" ;;
    CFR_REACHABLE*) printf '=== cfr (Yuan-MBP 可达) ===%s\n' "${cfr#CFR_REACHABLE}" ;;
    *) echo "=== cfr ⚠️ Yuan-MBP 不可达(休眠/网络) → 日记引言块标 ⚠️ 远程待 D+1 补抓 ===" ;;
  esac
else
  echo "=== cfr 默认无工作(维护模式收尾)、未 SSH; 用户未提 yuan-mbp 有工作 → 日记记『cfr 今日无工作』 ==="
fi

# ---- 3.5 yuenan-mbp 工作机（默认有工作，自动发现桌面所有工作项目）----
# 调 yuenan-mbp 上的 yuenan-scan.sh（glob ~/Desktop/* 自动发现所有工作项目）。yuenan-mbp = 工作机, 桌面所有项目都是雇主团队工作项目。
# 2026-06-27 起根治：取代原 §3.5/§3.5b/§3.5c「每新增 CarysCloud 工作区粘一块 §3.5x」的跑步机 + 桌面新目录/新项目首日盲（6/12 AllinOne、6/27 DAG 两次首日漏扫）。
# 脚本结构: 每个项目 = 多 git 子仓容器(若干后端/前端子仓, 不写死、*/.git glob 自动发现)。
# 口径分流: 有 daily-digest.sh 的工作区(旧 CarysCloud)跑 digest 4 信号; 其余枚举子仓跑 yuenan 分支 git-log:
#   --branches='*yuenan*' glob 抓所有名字含 yuenan 的分支(只我的分支、排除同事/基线/dev、跨多分支单次 walk 去重) + 越南/yuenan 署名过滤(团队共享仓必须过滤排除同事) + AIREADME/CHANGELOG 头部。LC_ALL=C 防漏 CJK 署名。
# 默认有工作 = 始终跑; 仅当触发消息明说「yuenan-mbp 没工作」, agent 把 YUENAN_SKIP=1 才跳过。
# 哨兵 YUENAN_REACHABLE 剥「可达 0 改动 vs 不可达」; 脚本尾 YUENAN_SCAN_WORKSPACES=N 确认真跑到 + 发现 N 个工作区; YUENAN_SCAN_MISSING = 可达但脚本没部署/坏。
# ⚠️ 2026-06-08 起雇主项目私仓内与其他项目同等详记（日记 + caryscloud.md/对应项目页）；保留：① 项目页 RAG 排除(挡公开主页) ② 团队成员真名抽象
#    ③ 公开镜像 personal-skills 同步时脱敏雇主名/主机/脚本（见 memory feedback_ingest_caryscloud_via_yuenan_mbp）。
# 脚本本体只活在 yuenan-mbp（含雇主目录/仓名/分支模式/署名），不进 worklog 仓、不进公开镜像（同 daily-digest.sh 先例）；改扫描逻辑改远端脚本、新项目零改 skill（auto-discover）。
YUENAN_SKIP=""   # 仅当用户明说 yuenan-mbp 没工作时由 agent 置 1（默认空 = 始终扫）
if [ -z "$YUENAN_SKIP" ]; then
  yc=$(ssh -o ConnectTimeout=8 yuenan-mbp "echo YUENAN_REACHABLE; \
    [ -x ~/Desktop/yuenan-scan.sh ] && ~/Desktop/yuenan-scan.sh '$D' || echo YUENAN_SCAN_MISSING" 2>/dev/null)
  case "$yc" in
    *YUENAN_SCAN_MISSING*) echo "=== yuenan-mbp ⚠️ 可达但 yuenan-scan.sh 缺失/不可执行 → 引言块标、勿当 0 改动 ===" ;;
    YUENAN_REACHABLE*) printf '=== yuenan-mbp 工作机 (可达) ===%s\n' "${yc#YUENAN_REACHABLE}" ;;
    *) echo "=== yuenan-mbp ⚠️ 不可达(合盖/休眠/网络) → 日记引言块标 ⚠️ 待 D+1 补抓 ===" ;;
  esac
else
  echo "=== yuenan-mbp 用户明说今日无工作 → 跳过扫描、日记记无 ==="
fi

# ---- 4. 今日改动 worklog memory + wiki / diaries（按归属窗口 [SINCE, UNTIL]，与 §2 口径一致）----
find "$HOME/.claude/projects/-Users-maxwell-Desktop-Claude-Project-worklog/memory" \
     -name '*.md' -newermt "$SINCE" ! -newermt "$UNTIL" 2>/dev/null
find "$WORKLOG/wiki" "$WORKLOG/diaries" \
     -name '*.md' -newermt "$SINCE" ! -newermt "$UNTIL" 2>/dev/null

# ---- 5. todos.md 现状 ----
cat "$HOME/Desktop/Claude-Project/worklog/wiki/todos.md"
```

### 扫描扩展

- **跨日延续**：凌晨提交 (00:00-06:59) 归前一天，扫描窗口要覆盖。
- **本机扫不到的盲区**： Yuan-MBP cfr（**默认无、维护收尾**，仅用户提才抓）+ yuenan-mbp 工作机（**默认有**，yuenan-scan.sh 自动发现桌面所有工作项目扫，私仓详记）+ 其他全靠触发消息附带信息。
- **yuenan-mbp scan = 输入**： §3.5 调远端 `yuenan-scan.sh $D` 返回的各工作项目段（有 digest 的工作区跑 digest 4 信号 / 其余跑 yuenan 分支 git-log + CHANGELOG）作当天理解输入；**2026-06-08 起与其他项目同等详记（私仓）**，保留对应项目页 RAG 排除 + 团队成员真名抽象 + 公开镜像脱敏（见 memory `feedback_ingest_caryscloud_via_yuenan_mbp`）。
- **yuenan-mbp 桌面 auto-discover（2026-06-27 起根治）**： yuenan-mbp = 工作机，桌面工作项目会持续增多（现 3 个 CarysCloud 工作区，每个含多 git 子仓；未来会建新项目）。**不再每新增一个工作区粘一块 §3.5x**（6/12 AllinOne、6/27 DAG 两次首日漏扫的教训）：远端 `yuenan-scan.sh` glob `~/Desktop/*` 自动发现所有工作项目 + 按口径分流（digest / yuenan 分支 git-log）+ `*/.git` glob 自动发现子仓，**新项目 / 新仓零改 skill 自动纳入**；非工作区目录（如 feishu 文档缓存）自动跳过。CarysCloud 系归 [[caryscloud]] 项目页分子线记；新发现的非 CarysCloud 项目按内容判断归属（caryscloud 子线 vs 新建项目页），拿不准 Step E 标一句让用户晨起定，默认按工作机私有处理。**脚本本体只活在 yuenan-mbp**（雇主目录 / 仓名 / 分支模式 / 署名都在远端），故 SKILL.md 内无逐项目雇主坐标，公开镜像 personal-skills 只需脱敏 §3.5 一块的主机名 + 脚本名（见 memory `reference_personal_skills_monorepo` / `feedback_ingest_caryscloud_via_yuenan_mbp`）。
- **SSH 不可达**： Yuan-MBP / yuenan-mbp 合盖休眠等情况，日记引言块标 ⚠️「<机器> SSH 不可达，远程工作待 X+1 补抓」（参考 5/26 / 6/4 日记）。不阻塞，Step E 不报错。
- **AIREADME 漂移雷达（§2.5）**： 对今日活跃 + 本地有 `AIREADME/` 的项目，复用 `aireadme/check.sh --drift` 算 AIREADME 落后 HEAD 多少 commit，漂移项转述进 Step E 报告。**只暴露不自动改**（`/aireadme update` 有确认门）。解决 AIREADME「init 做到位、update 没人记得跑」导致的无声漂移。远程项目（cfr / CarysCloud）无本地 AIREADME，不在范围。**内容新鲜度门（2026-06-27 加）**： 报「落后」前先查该项目 `AIREADME/` 今日窗口内有无 commit，有则抑制（= 自有 session 项目如 [[petslog]] / [[<client-proj-a>]] 自己在维护 AIREADME、worklog 侧锚点不 bump 致恒报「落后」是噪音；建议的 `/aireadme update` 也是项目 session 职责、非 ingest 操作者能跑）。用真实新鲜度替代按所有权手维护 skip 名单，自动覆盖未来项目，且不误伤 worklog 自身（今日 AIREADME 没 commit → 照常报）。

---

## Step B: 解析触发消息（不提问、不等待）

**目标**：把用户触发消息里附带的信息解析成 brain-dump，没提到的项用上方[默认值表](#默认值表触发消息没提到时按此处理全部不追问2026-06-27-用户逐项确认)填空。**绝不向用户提问、绝不等待回话**（用户睡前发完即离线，见「核心交互模型」）。

### 解析触发消息

触发消息形如「记录今天 + <附带信息>」，附带信息自由格式（「有什么工作 / 哪台机器没工作 / 发生什么事」）。逐句识别对应项：

- **机器工作状态**：「yuan-mbp 有工作」→ agent 置 `CFR_SCAN=1`（默认空 = 不抓）；「yuenan-mbp 没工作」→ 置 `YUENAN_SKIP=1`（默认空 = 扫）；没提 = 按默认（cfr 不抓 / yuenan 扫）。
- **当天主线 / 项目提示**：「今天主要在 X 项目 / 新建了 Y」→ 作主线识别 + 归属判断输入（auto-discover 已兜底发现，用户点一句更准）。
- **求职 / 对外 / 生活 / 特殊强调**：用户提到的归对应段；没提到的按默认（无）。
- **日期 / 模式**：「记录昨天 / 5 月 X 日」→ 对应归属日；「补充 / 更新」→ 对应模式。日期边界永远 7:00、从不问。

### 解析规则

- **客观数据以扫描为准、用户独有信息以触发消息为准**：扫描扫到的项目工作照常记（不依赖用户提）；用户独有、扫不到的信息（求职 / 生活 / 对外 / 强调）只认触发消息说的。
- **用户明说的覆盖默认**（「petslog 今天发版」→ 对外段记；「yuan-mbp 有工作」→ 反转抓 cfr）。
- **用户没提到的项一律走默认值表**，不脑补、不追问；日记对应段写「无」/「均无」。
- **纯「记录今天」无任何附带信息** → 全部走默认（cfr 无 / yuenan 扫 / 求职·对外·生活无），照跑，Step E 标一句「未附带信息、按默认跑、请核对」。
- **重要沟通 / 跨 session 同步**：不主动找，但用户在触发消息里提到的必接（归对应段）。
- **遇到任何歧义**：用规则 / 默认自己拍 + 日记标 ⚠️，**绝不停下提问**。
- **§2.1 报缺口**（前几天有 commit 无日记）：默认不补、不追问，Step E 被动标一句供晨起参考（[[feedback-stash-date-alignment]] 不照抄、按真实日期对齐）。

---

## Step C: 一行回执，开跑（不阻塞，不等响应）

解析完触发消息后，**立即一行回执**（回显解析到的 + 默认假设，**不是提问**），直接进入 Step D。用户睡了也不影响。**按触发模式分化措辞**：

**新增模式**（默认）：
```
收到、开跑。解析到: <从触发消息解析到的几条, 如 yuenan-mbp 主线 X / yuan-mbp 无工作>;
默认: cfr 无工作 / 求职·对外·生活无(你没提)。扫到: 本机 X commits + yuenan-mbp N。
跑完终端打印完成清单 + 已 commit + 已 push; 有错日记标 ⚠️ + .ingest-status.md 写卡点。
```

**补充模式**：
```
增量收到(自上次 ingest 多 N commits + 触发消息 K 项)。
追加到 diaries/$D.md 尾部, commit `ingest-补: M/D <增量主题>`。
```

**更新模式**：
```
收到改动请求, 定向 Edit diaries/$D.md, commit `ingest-改: M/D <修改点>`。
```

**关键约束**：

- **永不以提问结尾、永不等待**：一行回执后**立即开跑** Step D（assistant 同回合继续 tool call loop，不向用户提问、不结束回合等回话）。
- **Step D 全程不向用户提问**：遇模糊 → 标 ⚠️ 写日记 / 写 `.ingest-status.md`，**不打断**。
- 回执让用户（若未离开）瞄一眼**确认解析正确**，但不阻塞（用户已睡也照跑完）。

---

## Step D: 自主跑

**执行顺序**： **D.3 TODO 盘点 → D.1 写日记 → D.2 更 wiki → D.4 commit + push**。

> **硬约束（贯穿 Step D）**：所有 git / 文件操作走 `WORKLOG="$HOME/Desktop/Claude-Project/worklog"` 绝对锚点（`git -C "$WORKLOG"` / `"$WORKLOG/..."`），**不依赖 cwd、不用裸 `cd`**。长会话 Bash 工具 cwd 会漂移（stash 时漂到子目录致路径推导出错是真实案例），shell 变量也不跨 Bash 调用持久，每个新 Bash 调用若用到 `$WORKLOG` / `$D` 先重设。

- **D.3 先做**：盘点结果（完成 N / 失效 M / 顺延 K + 关键变化一句）进 D.1 的「事务·TODO 盘点」段。
- **todos.md 主存储由 D.3 全权拥有**： D.2 不重复操作 todos.md（避免与 D.3 双重操作不一致）。
- **D.1 概览灵魂句一旦写定**(`> **主线 = ...**`)、Step E 终端打印的「主线」回顾**直接 quote 这一句**，不要二次造句产生 drift。

### D.1 生成日记 `diaries/YYYY-MM-DD.md`

按下面「核心 judgment」+「输出契约」编译。一气呵成，**写盘前必跑校验**（见输出契约段）。

**ingest 当下衍生的 worklog 自维护必入 `## worklog` 章节**（2026-06-13 与用户立，堵历史盲区）：worklog 自己的改动按来源分四类，记录待遇不同：

- **(A) ingest 之前已 commit 的 worklog 实质工作**（改 schema / skill / 求职材料 / 全仓 review 等）：Step A 的 git log 扫得到，照常进 `## worklog` 章节。
- **(B) ingest 当下为修盲点 / 改进顺手做的 worklog 自维护**（改 skill / 更新 memory / stash / wiki 治理）：发生在写日记的同一动作里、写时还没 commit，**Step A 扫不到** → **必须主动作为 `## worklog` 章节的独立工作块记录（四元素），不能只在「事务」段一笔带过**。← 本约定要堵的盲区（2026-06-12 §3.5b 双工作区扫描扩展、2026-06-27 远程扫描根治成 yuenan-scan.sh 都是触发案例）。**「产出」写法（F3，2026-06-27 校正）**： (B) 工作与本篇日记同处一个 ingest commit、commit 在 D.4 之后才发生、写日记当下拿不到真 hash → **不写具体 hash（写了也是占位、回填需 amend 已 push 撞 no-rebase 红线）**，改写「本次 ingest commit / 见 D.4」。**且 D.4 必须 status 驱动 add 把这些 (B) 文件纳入暂存（见 D.4 F1 闸门），否则记录有「见 D.4」、diff 里却没该文件 = 名实不符。**
- **(C) 纯 ingest 动作本身**（写当天日记 + 更新 index / log / todos）：递归终止，不进 `## worklog` 章节，`log.md` 的 ingest 段留痕即可。
- **(D) 纯 chore**（obsidian graph 同步等）：噪音，不记。

> 自检：commit + push 前回看，本次 ingest 里我对 worklog 自己（skill / memory / wiki）动过手吗？动过 = (B) 类，确认：① 它在 `## worklog` 章节有独立工作块、不是只躺在事务段；② **D.4 用 `git status --short` 通览整树、把这些 (B) 文件(skill / AIREADME / concepts 等)确实 add 进暂存区(F1 闸门)，别漏 commit**。

### D.2 更新 wiki

参照 worklog AIREADME/CONVENTIONS.md 的日记 schema + wiki 维护约定：

- `wiki/index.md`:
  - 头部「最后更新」段加 5/X 摘要（把现有最后更新降为「之前」）；**封顶规则（2026-06-08 加）：只保留最近 3 天 ingest 摘要，更早的删掉、改为一句「更早见下方〔日记〕表」指针**（日记表是每日 canonical 记录；头部单行累积会膨胀到 20KB+，2026-06-08 review 已踩并瘦身）
  - 项目表对应项目行刷新「最后更新」+ 描述追加 5/X 内容
  - 日记表新增 [[YYYY-MM-DD]] 行（放最顶部）
- `wiki/log.md`: 顶部追加 `## [YYYY-MM-DD] ingest` 段
- `wiki/projects/<slug>.md`: 各今日活跃项目页：
  - frontmatter `last_updated` 改 / `source_count` +1 / `diaries` 数组加 `[[YYYY-MM-DD]]`
  - 决策日志加 `### YYYY-MM-DD: 主题` 段（在最新段之前插入）
  - **例外 `personal-skills`**（公开 skill 镜像）不单建项目页，其改动并入 `wiki/projects/worklog.md`（worklog 的发布子线）

> **注**： `wiki/todos.md` 不在 D.2 处理范围，由 **D.3 全权操作**（避免 D.2/D.3 双重写不一致）。

### D.3 TODO 盘点

**对每个项目的 TODO 必先读项目 memory + git log 实际进度**，再判断 4 状态：

| 状态 | 处理 |
|---|---|
| ✅ 完成 | 原位标 `✅ <YYYY-MM-DD>` + 列证据（commit hash / 文件 / 链接） |
| 失效 | 划掉 `~~...~~` + 注「❌ 失效 <date>（理由）」 |
| 可拆 | 拆成子 TODO + 顺延 |
| 顺延 | 更 `📅` 截止日期，跟进类默认顺延 1 周不主动 fade out |

**输出三处都更**：
1. **进日记**：「## 事务」段下加「TODO 盘点」简表 / 或在 log.md ingest 段记
2. **更 todos.md**：主存储改动（meta / life / idea 三段）
3. **更项目页 `## 下一步`**: 项目专属 TODO 处理

新 TODO: 按用户 brain-dump + ingest 中发现的需要 follow-up 的事项，按 type 写到主存储。

### D.4 commit + push

**分两步 commit**（语义分离）：

```bash
# 全程 git -C "$WORKLOG"(不依赖 cwd; 长会话 Bash cwd 会漂移、裸 git add 会落到错目录或静默失败)
WORKLOG="$HOME/Desktop/Claude-Project/worklog"

# 1. 求职 / me 材料 commit: 仅当 ingest 过程中改过 wiki/job 或 wiki/me
#    (如 D.3 把 #todo/job-hunt 写进 面试备战.md、或 brain-dump 衍生的招呼语微调;
#     ⚠️ D.3 改的备战 / activity 文件必须在这步 add, 否则漏 commit 留工作树被下次裹进无关 commit)。
#    用户在 ingest 触发前已自己 commit 的不重复处理。用 status 列实际改动逐个 add(不要字面 <...>)。
git -C "$WORKLOG" status --short wiki/job wiki/me      # 看有无 ingest 相关改动, 有才走本步
git -C "$WORKLOG" add wiki/job/<D.3/brain-dump 实改文件...> wiki/me/<...>
git -C "$WORKLOG" commit -m "docs(job): <摘要>" \
  -m "Co-Authored-By: Claude <当前运行模型,如 Opus 4.8 (1M context)> <noreply@anthropic.com>"

# 2. ingest 产出 commit (新增模式)。wiki/projects 下逐个列 D.2 实改的 slug(避免 *.md add 全部)。
# ⚠️ F1(2026-06-27): add 列表不止 diary/wiki。**(B) 类 ingest 当下自维护改动(改 skill / .claude/skills/、AIREADME/、wiki/concepts、wiki/infrastructure 等)也必须进本 commit**,
#    否则照旧写死列表跑会漏 commit 留工作树(被下次 ingest 裹进无关 commit)、且 (B) 工作块回填的 hash 名实不符(记录有 hash、diff 里却没该文件)。做法 = add 已知产出 + 逐个 add (B) 实改文件 + status 通览整树补漏。
git -C "$WORKLOG" add "diaries/$D.md" wiki/index.md wiki/log.md wiki/todos.md
git -C "$WORKLOG" add wiki/projects/<D.2 实改 slug1>.md wiki/projects/<D.2 实改 slug2>.md
# (B) 类自维护: 本次 ingest 若改过 skill 本体 / AIREADME / concepts / infrastructure, 在此逐个 add(按实际改动, 没改的删掉对应行、不要字面 <...>)
git -C "$WORKLOG" add .claude/skills/worklog-ingest/SKILL.md   # 例: 改过 skill 才 add(本行示例, 没改删掉)
# 整树自检(F1 闸门): 确认无 ingest 触及却漏 add 的文件(wiki/job、wiki/me 归 step 1, 不在此)。意外的 ?? / M 要么 add 要么排查清楚再 commit
git -C "$WORKLOG" status --short
# ⚠️ commit 不可改(不 rebase 是红线) → 标题先过 --commit 门(只 gate 破折号; type:冒号 / 日记()括号是 commit 惯例不拦)
T="ingest: M/D 日记(<主线一句话>)"
printf '%s\n' "$T" > /tmp/wl_msg.txt
python3 "$WORKLOG/.claude/skills/worklog-ingest/scripts/punctuation_check.py" --commit /tmp/wl_msg.txt \
  || echo "⚠️ 标题含破折号(em-dash), 改后再 commit"
git -C "$WORKLOG" commit -m "$T" \
  -m "<正文: 各项目要点摘要, 不用破折号>" \
  -m "Co-Authored-By: Claude <当前运行模型,如 Opus 4.8 (1M context)> <noreply@anthropic.com>"

# 3. push 私有仓
git -C "$WORKLOG" push
```

**三模式 commit 分支**：

- **新增模式**：上述命令块(`ingest: M/D 日记(<主线>)`)。
- **补充模式**：
  - `git add "diaries/$D.md"` 主要（其余 wiki 可能没改，按工作树实际调整）
  - `git commit -m "ingest-补: M/D <增量主题>"`
- **更新模式**：
  - 按用户指定的改动范围 `git add <files>`
  - `git commit -m "ingest-改: M/D <修改点>"`

**commit message 规范**：
- 标题前缀： `ingest:` / `ingest-补:` / `ingest-改:`（三模式之一）
- 正文：各项目要点摘要，1-3 段，**不用破折号**
- 结尾必含 Co-Authored-By 行，署名用**当前运行模型标识**（harness 注入，如 `Claude Opus 4.8 (1M context)`），**不写死版本号**（模型升级会 drift，4.7→4.8 已踩）

---

## Step E: 完成通知 / 错误兜底

### 成功路径

终端打印类似：

```
✅ 5/X 日记 ingest 完成

日记: diaries/YYYY-MM-DD.md (XXX 行)
Wiki 更新: index / log / todos / projects/{slugs}
TODO 盘点: ✅ 完成 N / 失效 M / 顺延 K
Commit: <hash1> 内容微调 / <hash2> ingest 产出
Push: ✅ pushed to origin/main
AIREADME 漂移: ⚠️ newapi-proxy 落后 17 / petslog 落后 28（今日动过但 AIREADME 未跟上 → 考虑 /aireadme update）｜ 无则「均同步」

主线: ...(一句话回顾)
```

> **AIREADME 漂移行 = §2.5 雷达输出直接转述**（哪些今日活跃项目的 AIREADME 落后 + commit 数 / 锚点退化 / 失锚）。**只提示、不自动跑 update**（update 有确认门、要判断，属另一动作）；雷达全清则写「均同步（仅今日活跃项目）」。**scope 边界**：雷达只覆盖今日动过的项目，陈年滞后（今天没动但早已漂移）的项目不在此列，需定期手动 `/aireadme check` 全量，雷达全清 ≠ 全库同步。

### 错误路径

**Never 烂尾**。原则：已完成的部分先 commit，卡点写到状态文件。

- **某步报错**（SSH 不可达 / git push 网络失败 / 标点检查发现问题修不了）
- → 已完成的 wiki + 日记 + memory 改动先 commit（避免丢失）
- → 错误状态 + 卡点 + 复现命令写到 `worklog/` **根目录** `.ingest-status.md`（已加 .gitignore,**不入 commit，仅本地，Maxwell 醒来读这一个文件即可接着跑**）
- → 终端打印 `⚠️ ingest 部分完成,卡点写入 .ingest-status.md,醒来读这个文件接着跑`

**例子**：

```markdown
# .ingest-status.md (Maxwell 醒来读)

## 卡点
git push 失败: 网络不可达(2026-05-27 04:12)

## 已完成
- diaries/2026-05-27.md (已 commit `dd323bf`)
- wiki/index.md / wiki/log.md / 3 项目页 / todos.md (已 commit `0e8e294`)

## 待做
- git push origin main (一行命令)
- (没了)

## 复现 / 接着跑
git -C "$HOME/Desktop/Claude-Project/worklog" push
```

---

## 写日记的核心 judgment

> 进入 Step D.1（生成日记）时遵守。默认全部生效，除非 Maxwell 在 brain-dump 中明确放宽。

### 1. 主线提炼：概览先讲主线，不流水账

多块工作时，识别主线（花时间最多 / 影响最大 / 连续推进的）vs 支线（零散补丁 / chore / 常规）。**概览段 2-3 行只讲主线**，支线进对应章节。

实战：
- ✓ 概览：「主线 = 求职对外呈现全面升级」
- ✗ 概览：「今天做了简历改造 + xhs 开源 + projects 重构 + obsidian 图谱 + ...」

### 2. 跨项目主题识别（高价值 judgment）

跨项目工作有共同主题时**单独提炼**，概览点出来，不要只按项目分章。

案例：
- 5/12: maxwell-homepage / multiplayer-xiaoshuo / cfr 同日切模型 → 「跨项目模型切换日」
- 5/27: 简历 + self-intro + homepage 同步 + worklog 私有仓 → 「求职对外呈现升级」

### 3. 时间线纪律：跨来源按分钟级合并

「今日时间线」表合并所有有时间的事（git commit / 部署 / 关键决策 / 外部沟通）：
- 时间戳精确到分钟(`21:01` 而非「晚上」)
- 跨项目合并到一张表，不按项目分表
- 没有精确时间的归入对应章节，不强塞时间线

### 4. 跨日归属：连续工作归主推进日

一段工作从今天晚上做到明天凌晨，统一归「主推进日」（开始日），不拆。

**两条规则，按时段分别用**：

- **凌晨 00:00 至 06:59 工作**（还在边界窗口内）： **自动归前一天**，不需问用户。
- **07:00 后开始的工作** = 新一天独立工作，**默认归当天**。**除外**： Maxwell 在 brain-dump 中明确说「早上这段是接续昨晚 X 项目的」，才归昨天。

**判断锚点**：开始时间 + 工作连续性，**不看 commit 时间**。

**实战反例 1（凌晨边界）**： 2026-05-28 凌晨 02:00,Maxwell 说「记录今天」，按 5/28 算错 → 实际归 5/27（凌晨延续 5/27 晚的简历重构，在 06:59 窗口内）。

**实战反例 2（07:00+ 边界）**：假设 Maxwell 早上 09:30 醒来继续 5/27 晚未完的 X 工作 → 默认归 5/28（已过 06:59），除非他在 brain-dump 中明说「09:30 这段是 5/27 的延续」才归 5/27。

### 5. 四元素章节：每块工作按四元素抽象

每个章节按这四元素组织，不只是「做了什么」：
- **做了什么**：具体动作 + 量化结果
- **关键决策**：背后判断（为什么这么定，不是别的）。**日记最有价值的部分**。
- **产出**：可指向的物（commit hash / 文件路径 / URL / 截图）
- **下一步**：接下来做什么 / 顺延 / 已完成关闭

反例：「改名 AIPM-FDE(`cd899d1`)」（只复述 commit）
正例：「改名 AIPM-FDE: 加 FDE 定位需要，旧名 AIProductManager 已偏窄；同步 maxwell-homepage 跨仓 RESUME_PATH(`b2a6e77`)+ 修 chunk-filter 误杀简历主源；reindex 验证化身答 FDE。下一步 = 项目话术段口播化（已记 todos）。」

### 6. 不臆造：只写有据的，盲区主动标

没拿到的信息绝不脑补（数字 / 时间 / 决策细节 / 量化效果）。
- 素材有 → 写
- 素材缺关键信息 → Step B 已经问过了；还是缺就标 ⚠️
- Maxwell 说「大概 / 应该」→ 不写绝对量化，改「初步看 / 待验证」

### 7. 写决策的「为什么」，不复述 git log

commit message 是「做了什么」的简写。日记要补「为什么这么做」（背后判断 / 技术取舍 / 用户反馈 / 踩坑）。

### 8. 砍冗余：每句改变复盘价值

每句话问一次：「未来读这句，会改变我的复盘判断吗？」
- 改变 → 留
- 不改变（套话 / 寒暄 / 不必要限定词） → 砍

---

## 默认偏好（Maxwell 风格）

> 写作 / 标点 / 时间 / commit hash / wikilink / emoji / 标题格式的 **canonical 规则见下方 [写作规范](#写作规范) 表**，本处不再重复（防两份拷贝漂移，曾出现一处半角冒号 vs 表内全角的不一致）。
> 另两条不在表内的: **跨日边界** 00:00-06:59 归前一天（见核心 judgment §4）；**标点门**由 `scripts/punctuation_check.py` 强制（见[写盘前必做的校验](#写盘前必做的校验标点门p0)）。

---

## 输出契约：日记结构

> Step D.1 产出 = `diaries/YYYY-MM-DD.md`，完整 markdown，自上而下：
>
> **每段的写法细则（主线提炼 / 时间线 / 四元素 / 不臆造 / 跨日归属）统一遵守上方[核心 judgment](#写日记的核心-judgment) 8 条**，本段只定结构与模板。

```
1. frontmatter (yaml)
2. 标题 (H1)
3. 引言块 (可选: 跨日延续 / 扫描盲区 / 特殊说明)
4. 目录
5. 概览
6. 今日时间线
7. 项目章节 (每项目一段)
8. 求职 (可选: 有具体事件才写;材料打磨在项目章节带一句即可)
9. 事务 (必含)
10. 生活 (必含)
```

### frontmatter 模板

```yaml
---
date: 2026-05-27         # YYYY-MM-DD,用真实归属日
day: 周三                 # 中文星期
projects:                # 当天有实质工作的项目 slug,主线项目在前
  - worklog
  - maxwell-homepage
  - xiaohongshu-tool
tags:
  - 工作日记
  - Claude_Code
git_commits: 14          # 数字,跨项目 commit 总数
---
```

### 标题

```markdown
# 工作日记：2026年5月27日（周三）
```

### 引言块（可选）

```markdown
> 单次会话跨日产出: 5/27 白天起,一路工作到 5/28 凌晨 01:50。
> 按日期边界规则,凌晨段全部归 5/27。
> cfr(Yuan-MBP)5/27 无新投研。
```

### 概览

```markdown
## 概览

> **主线 = ...**(一句话灵魂句)

| 项目 | 进展摘要 |
|------|---------|
| [[项目1]] 🔥🔥🔥 | 主线相关,3 行内 |
| [[项目2]] 🔥 | 支线相关 |
```

🔥 程度： 🔥🔥🔥 = 主线 / 🔥🔥 = 重要支线 / 🔥 = 一般推进 / 不带 = 零散补丁。

### 今日时间线

```markdown
## 今日时间线

> 时间为本地时间(CST, UTC+8)。00:00-06:59 按边界归前一天。

| 时间 | 项目 | 操作 |
|:--:|------|------|
| 10:14 | worklog | commit `a816594` cfr 5/26 补抓 |
| 21:01 | worklog | commit `cd899d1` 简历重构 加 FDE + 改名 AIPM-FDE |
```

### 项目章节

```markdown
## <slug> · <本日主题摘要>

> 项目目录：`~/Desktop/Claude-Project/<slug>/`
> 工作时段：HH:MM → HH:MM（跨日延续说明）
> （可选）session 说明（如「另一 session」）

### 今日进展

**① 工作块标题(`hash1`)⭐**

按四元素描述(做了什么 / 关键决策 / 产出 / 下一步)。

**② 工作块标题(`hash2`)**

...

### Git 提交(N 个)

- `hash1` HH:MM 描述
- `hash2` HH:MM 描述

### 下一步

- TODO 项(或顺延理由)
```

### 事务段（实证格式，基于 5/14-5/27 历史日记归纳）

**有就写，无就不列**；全无 → 一行「均无」。**类目仅作 trigger 提示，不强行展开 4 行「无」**。标题统一用裸 `## 事务`（6/13 起实际产物已全裸标题，「（已确认）」后缀约定 2026-06-18 废弃）；若想标确认度，段首加一行 `> 本段均经 brain-dump 确认`。

```markdown
## 事务

(用户 brain-dump 提到 + Step A 扫到的非项目动作,逐条 bullet 写;全无 → 均无)

- **部署 / 基础设施**: 服务器、SSH、Docker、Caddy 操作(如有)
- **对外动作 / 发布**: 版本发布、开源、社区宣传、客户对接(如有)
- **跨 session / 跨设备**: doubleL-* 系列 / 另一 session 状况、SSH 远程其他机器(如有)
- **特殊状况**: 扫描盲区说明、跨项目同步处理、cron 漏跑、SSH 不可达等异常(如有)
- **TODO 盘点结果**: 由 D.3 写入(完成 N / 失效 M / 顺延 K + 关键变化一句)
```

**写法参考**：

- 5/26 日记： 4 行 bullet（远程 + git 外工作 + 求职 + 生活无）
- 5/27 日记： 3 行 bullet（求职 + xhs 开源 + 「部署 / Web / 沟通均无」一行汇总）

四类完全无 → 直接 `## 事务\n\n均无\n`。

### 生活段（必含）

```markdown
## 生活

无 / 人物 + 简述(不脑补,只记用户告知的)
```

---

## 写作规范

| 项 | 规则 |
|---|---|
| 标点 | 中文全角(`:` `(` `)` `;`)，不用半角 |
| 破折号 `—` / `——` | **绝对禁止**。标题分隔用 `:`，插入语用 `(...)`，转折用 `,` |
| commit hash | 反引号包裹 \`abc1234\` |
| 项目 / 文件名 | wikilink `[[slug]]` 或反引号 \`path\` |
| 时间 | 24h `HH:MM`，不用「下午 2 点」 |
| 量化 | 具体数字，**没有就不写**（不用「大概 / 应该」） |
| 列表 | `-`，不用 `*` |
| emoji | 🔥 / ⭐ / ✅⏳⚠️ 节制使用，不堆砌 |
| H2 章节标题 | `## <主体> · <主题>`(中点 `·` 分隔) |
| H1 日记标题 | `# 工作日记：YYYY年MM月DD日（周X）` |

### 写盘前必做的校验（标点门，P0）

写完日记、**写盘后 commit 前**，用专用脚本查中文标点残余。脚本按真 unicode 字符匹配（天然区分全 / 半角、不踩 macOS locale），覆盖全部半角标点（不只 `**bold**:` + 破折号），是磁盘文件、不会被上下文渲染吞符号。

```bash
WORKLOG="$HOME/Desktop/Claude-Project/worklog"          # 锚点自带重设, 防 cwd 漂移 / 变量未设
F="$WORKLOG/diaries/$D.md"; [ -f "$F" ] || echo "⚠️ 目标日记不存在: $F"
python3 "$WORKLOG/.claude/skills/worklog-ingest/scripts/punctuation_check.py" "$F"
# exit 0 = 干净直接进 commit; exit 1 = 逐行打印 路径:行号:[类型] 上下文
```

**有残余（exit 1）→ 一棵决策树（按命中数走，不再散在多处）**：

1. **命中 1 至 5 处（常态）→ 直接 Edit / Python 单点改，不跑 perl**。逐行对脚本打印的行号改: 半角 → 全角（`，：（）；！？`），破折号 `—` / `——` 按语义换 `，` / `：` / `（…）`。Edit 输全角被规范化成半角时（见 [[feedback-wiki-symbol-consistency]] 第四次升级）改用 Python `\uXXXX` escape 写。改完**重跑脚本**验证。
2. **大量机械残余（罕见）→ 才考虑 perl，但 ⚠️ 必须从磁盘真文件取命令**（`grep -n 's/' "$WORKLOG/.claude/skills/worklog-ingest/SKILL.md"`），**绝不照抄本 SKILL.md 渲染进上下文的版本**（`$1` / `$1$2` 会被插值吞掉、把 `**加粗段**:` 删成单个 `：`，每次 ingest 复发，见 [[feedback-wiki-symbol-consistency]] 6/15；perl 块见文末「附录: perl 批量修」）。跑 perl **一次后立即重跑脚本** + 抽验加粗标签存活（`grep -c '\*\*做了什么\*\*' "$F"`）；被吞 → **立即 `git checkout -- "$F"` 回滚、切第 1 条 Python 单点修，绝不重试同一 perl**。
3. **两轮修不干净 → 写 `.ingest-status.md` 卡点（贴脚本输出原样）+ 终端告警 + 仍 commit + push**（不阻塞，醒来人工处理）。**绝不无限循环。**

> 误报说明: 脚本对代码 / 路径 / 比例 / 时间 / wikilink / 链接已做保护，正常 0 误报；若 brain-dump quote 规范文本产生破折号字面，引言块说明并放过该行。

**commit message 也过门**（commit 不可改 = 破折号污染不可逆，历史标题 `490908b` 已踩 em-dash）：commit 标题用 **`--commit` 模式只 gate 破折号**（标题里 `ingest:` 的 ASCII 冒号、`日记(主线)` 的括号是 commit 惯例、不套日记正文的全角规则）。实际命令在 D.4 commit 块（拼好 `$T` → 写临时文件 → `punctuation_check.py --commit` → 命中则改后再 commit）。

**附录: perl 批量修（最后手段，仅大量机械残余时用；首选仍是上面决策树第 1 条 Python / Edit 单点改）**

⚠️ **此块的 `$1` / `$1$2` 反向引用，照抄本 SKILL.md 渲染进上下文的版本会被插值吞掉**（replacement 只剩 `：`、把整个 `**加粗段**:` 删成单个 `：`，每次 ingest 复发）。**必须 `grep -n 's/' "$WORKLOG/.claude/skills/worklog-ingest/SKILL.md"` 从磁盘真文件取**、确认含 `$1` 再跑；跑后立即重跑标点脚本 + 抽验加粗标签存活，被吞即 `git checkout -- "$F"` 回滚切 Python。纯字节模式不加 `-CSD`；替换符是全角中文冒号 `：`（U+FF1A）：

```bash
perl -i -pe '
  s/(\*\*[^*\n]+\*\*):/$1：/g;                  # **加粗段** 半角: → 全角：
  s/(^|\n)(#+[^\n]*?) — /$1$2：/g;              # 标题里的 ` — ` → 全角：
  s/ —— /：/g; s/ — /：/g; s/——/：/g;            # 内容间破折号 → 全角：
' "$F"
```

`.ingest-status.md` 卡点格式见 Step E 错误路径例子（贴标点脚本输出原样 + 待人工 review 行号 + 复现命令 `python3 .../scripts/punctuation_check.py "$F"`）。

---

## TODO 盘点 know-how

### 盘点流程

1. 读 `wiki/todos.md` 列出所有 open TODO
2. 对每条 TODO **按其 `[[<slug>]]` 关联项目，读项目 `~/.claude/projects/...` memory + 该项目今日 git log，获取实际进度**（不照 todos.md 表面进度）
3. 判断 4 状态：
   - ✅ 完成：原位标 `✅ <YYYY-MM-DD>` + 列证据
   - 失效： `~~划掉~~` + 注「❌ 失效 <date>（理由）」
   - 可拆：拆成子 TODO + 顺延
   - 顺延：更 `📅`（跟进类默认顺延 1 周不主动 fade out）
4. 标完成必列证据（commit hash / 文件路径 / 决策日志位置）

### 输出三处

| 位置 | 内容 |
|---|---|
| 日记 `## 事务` 段 | TODO 盘点简表（完成 N / 失效 M / 顺延 K 数字 + 关键变化一句） |
| `wiki/todos.md` | 主存储（meta / life / idea）逐条改动；`last_updated` 改 |
| 项目页 `## 下一步` | 该项目专属 TODO 处理(在 `wiki/projects/<slug>.md`) |

**E2 无变化塌指针（2026-06-27 加，防盘点走过场）**： 若当日盘点 = 完成 0 / 失效 0 / 新增 0 **且顺延集与上次完全相同**（同一批 meta TODO 又躺一天），日记 `## 事务` 段**只写一行指针**「TODO 盘点：无变化，N 条 meta 跟进项原状顺延，详见 [[todos]]」，**不逐条重列**（与 index.md 头部封顶同源）。有任一变化才展开。根因：6/01-6/27 连续 20+ 天逐字重列同 4 条 = 噪音淹真信号。配套 todos.md 把跟进类 TODO 按**所有权**而非统一「顺延 1 周」管理：① 归他项目 session 的（chemai RAG / homepage embeddings 归 maxwell-homepage session）标「归 X session、worklog 不每日重列」；② 有明确退出条件的当 watch item（cfr 维护 = 客户方招到人触发）；③ 真个人待办可 snooze（📅 推后、到期再问，如自介口播化 6/28 snooze 到 7/28）。

### 新增 TODO

按 `type` 写到主存储：
- `#todo/meta` → `wiki/todos.md`
- `#todo/life` → `wiki/todos.md`
- `#todo/idea` → `wiki/todos.md`
- `#todo/project` → 对应项目页 `## 下一步`
- `#todo/job-hunt` → **跨公司策略 / 共性 TODO** 进 `wiki/job/activity.md`;**公司专属备战 / 跟进** 进 `wiki/job/company/active/<公司>/面试备战.md`（5/26 二轮重构后职责分流）

格式： `- [ ] <描述> #todo/<type> [[<slug>]] ⏫/🔼/🔽 📅 YYYY-MM-DD ➕ <today>`

---

## 边界 / 不干啥

- **永不向用户提问 / 永不阻塞**： 触发后整个流程（解析 → 跑 → commit → push）一口气走完，遇到模糊用规则 / 默认自己拍 + 标 ⚠️ 写日记 / 写 `.ingest-status.md`，**绝不停下等用户**（用户睡前发完即离线，问一句 = 挂一整晚）
- **不主动读项目 AIREADME**：项目 AIREADME 是项目自己的真相源，不为日记上下文主动读（除非项目今日有 commit 改动 AIREADME 文件需要在日记里 reference）
- **不动跨仓库文件**： maxwell-homepage / xiaohongshu-tool / cfr 等项目内的文件不动（只读 git log + memory，改动是这些项目自己 session 的责任）
- **不发外部消息**：不主动给客户 / 朋友 / HR 发任何消息；commit + push 仅限 worklog 自己的私有仓
- **不做不可逆操作**：不删 / 不移 / 不 rebase / 不 force-push;commit + push 是可逆的（revert / force-push 改），其他卡住等用户醒来
- **跨项目同步消息不主动接**：用户从其他 session 转过来的同步消息（像 maxwell-homepage 的 P0 修复反馈）是即时处理，不主动找；但用户在触发消息里提到的必接（归对应段）
- **求职细节不追问**： Maxwell 给求职数据 / 口径是让我落档，不是做谈薪 / 面试教练；不追问面试言行，不推行动清单，风险提醒一句点到为止(见 memory `feedback_job_scope_record_not_coach`)
- **客户 / 私有项目敏感数据不进 worklog**： 扫到的客户项目（如 `<client-proj-b>`）git log 摘要写进 diary / `wiki/projects/` 时，**报价 / 真实姓名 / 未成年人数据等敏感细节留在项目本地 PRD，不进 worklog**（`wiki/projects/` 可能被 maxwell-homepage build 读 = 半公开）。该项目约束由 A.0 ② 动态载入，按其红线办

---

## 关联（skill 触发时主动 Read 这些 memory，不等遇坑才查）

- **契约层**： `worklog/AIREADME/ARCHITECTURE.md` 6 步契约定义（本 skill 是实现）
- **日记 schema**： `worklog/AIREADME/CONVENTIONS.md` 日记格式契约
- **触发语接口**： `worklog/AIREADME/SPEC.md`
- **关联 memory**（完整 superset。**Step A.0 ① 的 8 个 memory 是 essential subset 必读**，**② 活跃项目的 `project_*.md` 走 MEMORY.md 索引动态读**；此处其余几个为「触发联想」遇坑再查）：

  Step A.0 必读 8 个（essential subset）：
  - 日期对齐 → `feedback_stash_date_alignment`
  - 远程归属默认 Maxwell → `feedback_yuan_mbp_remote_collab`
  - 时间戳 + 工作时段 → `feedback_diary_timestamps`
  - TODO 盘点先读 memory + git log → `feedback_todo_review_via_memory_gitlog`
  - 标点校验 perl 批量修 → `feedback_wiki_symbol_consistency`
  - 求职只记不导 → `feedback_job_scope_record_not_coach`
  - cfr SSH 路径 → `<remote-project-git-log-memory>`
  - macOS grep locale → `reference_macos_grep_locale`

  其余触发联想（遇坑再查）：
  - 不用破折号 → 全局 `~/.claude/CLAUDE.md`「中文写作规范」
  - 面试录音归档 / 复盘 / 对外猎头反馈 → `feedback_interview_recording_archival`
  - 项目主动归档 → `feedback_project_archive_workflow`
  - 老面试归档规则 + fade out → `feedback_old_interview_close_rule`
  - 知识库 git 严禁 SSH 私钥 → `feedback_no_secrets_in_worklog_git`
  - 生活段记日常事务 → `feedback_diary_include_daily_life`
  - 远程 / 对外 / 沟通主动询问 → `feedback_ingest_check_offline_work`
  - 项目命名规范 → `feedback_project_naming_convention`
  - 求职决策规则（三档薪资 + Web3 框架等）→ `feedback_job_decision_rules`
