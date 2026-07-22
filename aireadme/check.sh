#!/usr/bin/env bash
# AIREADME lint，在项目根运行：bash ~/.claude/skills/aireadme/check.sh [AIREADME_DIR]
#   漂移检查：bash ~/.claude/skills/aireadme/check.sh --drift [AIREADME_DIR]   # 在项目 git 仓内跑，算 AIREADME 落后 HEAD 多少 commit
# 退出码：🔴 问题 → exit 1；🟡 advisory / drift 信息 → exit 0。
set -uo pipefail
export LC_ALL=C   # 字节模式：macOS BSD grep 匹配中文字面量靠它（C.UTF-8 在 macOS 不存在 / 默认 locale 静默漏 CJK，见 reference_macos_grep_locale）。注意：bash 3.2 裸 $var 吃全角首字节的触发条件是 UTF-8 locale 不是字节模式（LC_ALL=C 反而是旁路）；下方仍全程 ${...} 花括号作防御性双保险（防有人去掉 LC_ALL=C）

# 从 INDEX.md 提同步锚点的「值」（剥 last-synced: 前缀 / 同行 <!--注释--> / ⚑ / 引导 > 空白）
_anchor_val() {
  local idx="$1" line
  # 只认行首(可带 blockquote >)的锚点行，不被正文里提及 "last-synced" 的句子撞 -m1
  line=$(grep -m1 -iE '^[[:space:]>]*(last-synced|上次同步)' "$idx" 2>/dev/null) || return 1
  # 全角冒号 ：(3 字节)在 LC_ALL=C 字节模式下不能进 [：:] 字符类(会被按单字节拆、吃半个字符留游离字节、SHA 丢失)，先整体归一成半角
  # 剥标签子句带 //I(BSD/GNU sed 都支持的大小写不敏感)，与上面行首检测 grep -i 口径对齐，免得 Last-Synced/LAST-SYNCED 被检测到却剥不掉前缀
  printf '%s' "$line" \
    | sed -E 's/：/:/g; s/<!--.*-->//; s/.*(last-synced|上次同步):?//I; s/⚑//g; s/^[[:space:]>]*//; s/[[:space:]]*$//'
}
# 锚点里的 SHA token（行首首个 7-40 位 hex 或 pre-code 哨兵）；取不到回空
_anchor_sha() {
  printf '%s' "$1" | grep -oiE '^[0-9a-f]{7,40}|^pre-code' | head -1
}

# ---- drift 模式：算 AIREADME 落后项目 HEAD 多少 commit（A 漂移雷达与本模式同源）----
if [ "${1:-}" = "--drift" ]; then
  shift
  DIR="${1:-AIREADME}"
  [ -f "$DIR/INDEX.md" ] || { echo "🔴 无 $DIR/INDEX.md（先 init）"; exit 1; }
  val=$(_anchor_val "$DIR/INDEX.md" || true)
  sha=$(_anchor_sha "$val")
  if [ -z "$sha" ]; then echo "🟡 锚点无可解析 SHA（[$val]）→ 无法算 drift，先把锚点修成 \`<SHA> · YYYY-MM-DD\`"; exit 0; fi
  if [ "$(printf '%s' "${sha}" | tr 'A-Z' 'a-z')" = "pre-code" ]; then
    # pre-code 但仓里已有真实 commit = 该翻 SHA 却没翻的陈旧态，别静默跳过（否则漂移雷达永远看不见它）
    if git rev-parse --git-dir >/dev/null 2>&1 && [ -n "$(git rev-list -n1 HEAD 2>/dev/null)" ]; then
      echo "🟡 锚点仍是 pre-code，但项目已有真实 commit → 该 update 把锚点翻成真 SHA（否则 drift 永久跳过、AIREADME 无声漂移）"
    else
      echo "ℹ️ 锚点 = pre-code（立项未出 commit），跳过 drift"
    fi
    exit 0
  fi
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "🔴 当前不在 git 仓内，drift 需在项目仓里跑"; exit 1; }
  git cat-file -e "${sha}^{commit}" 2>/dev/null || { echo "🟡 锚点 SHA ${sha} 不在本仓历史（rebase / 换仓？）→ 重新对锚点"; exit 0; }
  # 必须验「锚点是 HEAD 祖先」：否则锚点旁逸 / 超前于 HEAD 时 rev-list SHA..HEAD 返回 0，会把「不可比」静默吞成「✅ 已同步」（漏报，正中漂移雷达反面）
  git merge-base --is-ancestor "${sha}" HEAD 2>/dev/null || { echo "🟡 锚点 SHA ${sha} 不是 HEAD 祖先（分支分叉 / rebase / 锚点超前）→ 重新对锚点，别误判已同步"; exit 0; }
  n=$(git rev-list --count "${sha}"..HEAD 2>/dev/null || echo 0)
  if [ "${n:-0}" -eq 0 ]; then echo "✅ AIREADME 同步（HEAD = 锚点 ${sha}，0 commits behind）"; exit 0; fi
  echo "🟡 AIREADME 落后 ${n} commits（since ${sha}）："
  git log --oneline -15 "${sha}"..HEAD | sed 's/^/    /'
  # 先排除 AIREADME 自身路径：否则改 AIREADME/DEPLOYMENT.md 会被 deploy 子串自指误判成「触及部署文件」
  struct=$(git -c core.quotepath=false diff --name-only "${sha}"..HEAD 2>/dev/null \
    | grep -vE "^${DIR}/" \
    | grep -iE '(docker|compose|caddyfile|package\.json|cargo\.toml|pyproject|requirements|\.env(rc)?([./]|$)|deploy|/migrations/|schema|\.config)' | head)
  if [ -n "$struct" ]; then
    echo "  ⚠️ delta 触及结构 / 部署文件，DEPLOYMENT / ARCHITECTURE / SPEC 可能要更："
    printf '%s\n' "$struct" | sed 's/^/      /'
  fi
  exit 0
fi

# ---- 结构 lint 模式（默认）----
DIR="${1:-AIREADME}"
files=(INDEX CORE RELATIONS SPEC ARCHITECTURE DEPLOYMENT PRD ROADMAP CONVENTIONS DECISIONS MEMORY CHANGELOG)
fail=0

# self-test：硬编码文件名数组 ↔ 本 skill template 一致性（防将来改 STANDARD 文件清单忘同步此数组）
_selfdir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)
if [ -n "${_selfdir}" ] && [ -d "${_selfdir}/template/AIREADME" ]; then
  _tpl=$(cd "${_selfdir}/template/AIREADME" && for m in *.md; do printf '%s\n' "${m%.md}"; done | sort | tr '\n' ' ')
  _arr=$(printf '%s\n' "${files[@]}" | sort | tr '\n' ' ')
  [ "${_tpl}" = "${_arr}" ] || echo "🟡 self-test：check.sh files 数组与 template/AIREADME/ 不一致（改了文件清单？同步 files 数组 + STANDARD 文件清单）"
fi

# 大小写精确门：默认 APFS/HFS+ 大小写不敏感，[ -d AIREADME ] 会假命中小写 aireadme/（见 pitfalls 库）；用 find 按 dirent 串比对
if [ "$DIR" = "$(basename "$DIR")" ]; then
  [ -n "$(find . -maxdepth 1 -type d -name "$DIR" 2>/dev/null)" ] || { echo "🔴 无 $DIR/ 目录（大小写须精确，先 init）"; exit 1; }
else
  [ -d "$DIR" ] || { echo "🔴 无 $DIR/ 目录（先 init）"; exit 1; }
fi

echo "== 12 文件齐全 =="
for f in "${files[@]}"; do
  if [ -f "$DIR/$f.md" ]; then echo "  ✅ $f.md"; else echo "  🔴 缺 $f.md"; fail=1; fi
done

echo "== INDEX 状态表 =="
if grep -qE '^\|[[:space:]]*文件[[:space:]]*\|' "$DIR/INDEX.md" 2>/dev/null; then echo "  ✅ 有状态表"; else echo "  🟡 INDEX 缺状态表（应有 | 文件 | 状态 | 摘要 | 表头）"; fi

echo "== 同步锚点（格式 = \`<SHA 或 pre-code> · YYYY-MM-DD\`）=="
aval=$(_anchor_val "$DIR/INDEX.md" || true)
if [ -z "$aval" ]; then
  echo "  🟡 INDEX 缺 last-synced 锚点（update / drift 靠它算 delta）"
elif printf '%s' "$aval" | grep -qiE '^([0-9a-f]{7,40}|pre-code)[[:space:]]*·[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  echo "  ✅ 锚点合规：$aval"
elif [ -n "$(_anchor_sha "$aval")" ]; then
  echo "  🟡 锚点有 SHA 但缺规范 \`· YYYY-MM-DD\`（当前 = [$aval]）→ drift 可凭 SHA 算，但读不出同步时点，建议补全"
else
  echo "  🟡 锚点无可解析 SHA → update / drift 算不了 delta（当前 = [$aval]，应为 \`<7-40 位 SHA 或 pre-code> · YYYY-MM-DD\`，别塞 changelog / 备注）"
fi

echo "== 未填占位（⚑ 标记 / 裸 TODO·TBD 行，advisory）=="
# 排除 <!--注释--> 行（图例/指引里的 ⚑ 不算）；TODO/TBD 只匹配独占一行的裸标记（不匹配句中"TODO 系统"等）
ph=$(for f in "$DIR"/*.md; do grep -vE '<!--' "$f" 2>/dev/null | grep -qE '⚑|^[[:space:]]*[-*]?[[:space:]]*(TODO|TBD):?[[:space:]]*$' && echo "$f"; done)
if [ -n "$ph" ]; then
  echo "  🟡 仍含未填占位（语义占位可接受，应逐步填实）："
  echo "$ph" | sed 's#.*/#    - #'
else echo "  ✅ 无未填占位"; fi

echo "== key/secret 泄漏粗扫（红线 1）=="
# ① 高置信具体前缀（含 PEM 私钥头 + 各家 token）：命中即 🔴，不做占位豁免（近零误报）
hard=$(grep -rniE "(-----BEGIN[[:space:]]+[A-Z ]*PRIVATE KEY-----|sk-ant-[A-Za-z0-9_-]{16,}|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{12,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{20,}|glpat-[A-Za-z0-9_-]{20,})" "$DIR" 2>/dev/null || true)
# Bearer 单列：要求 token 含数字，滤掉散文如 "Bearer authentication_header_value"（真 token 几乎必含数字）；仍不豁免占位词
bearer=$(grep -rniE "Bearer[[:space:]]+[A-Za-z0-9._-]{16,}" "$DIR" 2>/dev/null | grep -E "Bearer[[:space:]]+[A-Za-z0-9._-]*[0-9]" || true)
# ② 泛型 key=value：易误伤占位（NEWAPI_TOKEN=your_token_placeholder…），滤掉明显占位词再判
soft=$(grep -rniE "(api[_-]?key|secret|token|password)[[:space:]]*[:=][[:space:]]*['\"]?[A-Za-z0-9._-]{16,}" "$DIR" 2>/dev/null \
  | grep -viE "[:=][[:space:]]*['\"]?([A-Za-z0-9._-]*(placeholder|your[_-]|xxxx|changeme|占位|替换)|<[^>]*>)" || true)
hits=$(printf '%s\n%s\n%s\n' "${hard}" "${bearer}" "${soft}" | grep -vE '^[[:space:]]*$' | awk '!seen[$0]++' || true)
if [ -n "${hits}" ]; then
  echo "  🔴 疑似明文 key/secret/token，立即移除（committed 后可跨项目读）："
  printf '%s\n' "${hits}" | head | sed 's/^/    /'; fail=1
else echo "  ✅ 未见明文密钥"; fi

echo "== 边界粗查（排除 <!--注释--> 与指针行，advisory）=="
arch=$(grep -vE '<!--|→|详见|另见' "$DIR/ARCHITECTURE.md" 2>/dev/null || true)
dec=$(grep -vE '<!--|→|详见|另见' "$DIR/DECISIONS.md" 2>/dev/null || true)
echo "$arch" | grep -qE '(GET|POST|PUT|DELETE) /|base[_ ]?url' && echo "  🟡 ARCHITECTURE 疑似混入对外接口 → 该进 SPEC"
echo "$dec" | grep -qE '事故|踩坑|根因' && echo "  🟡 DECISIONS 疑似混入运行时事故 → 该进 MEMORY"

echo "----"
[ "$fail" = 0 ] && echo "✅ 结构通过（🟡 为 advisory，不阻断）" || echo "🔴 有 must-fix 问题"
exit "$fail"
