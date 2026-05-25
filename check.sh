#!/usr/bin/env bash
# AIREADME lint — 在项目根运行：bash ~/.claude/skills/aireadme/check.sh [AIREADME_DIR]
# 退出码：🔴 问题 → exit 1；🟡 advisory → exit 0。
set -uo pipefail
export LC_ALL="${LC_ALL:-C.UTF-8}"   # 中文关键词匹配需 UTF-8 locale，否则边界/结构检查会静默失效
DIR="${1:-AIREADME}"
files=(INDEX CORE RELATIONS SPEC ARCHITECTURE DEPLOYMENT PRD ROADMAP CONVENTIONS DECISIONS MEMORY CHANGELOG)
fail=0

[ -d "$DIR" ] || { echo "🔴 无 $DIR/ 目录（先 init）"; exit 1; }

echo "== 12 文件齐全 =="
for f in "${files[@]}"; do
  if [ -f "$DIR/$f.md" ]; then echo "  ✅ $f.md"; else echo "  🔴 缺 $f.md"; fail=1; fi
done

echo "== INDEX 状态表 =="
if grep -qE '^\|[[:space:]]*文件[[:space:]]*\|' "$DIR/INDEX.md" 2>/dev/null; then echo "  ✅ 有状态表"; else echo "  🟡 INDEX 缺状态表（应有 | 文件 | 状态 | 摘要 | 表头）"; fi

echo "== 同步锚点 =="
if grep -qiE 'last-synced|上次同步' "$DIR/INDEX.md" 2>/dev/null; then echo "  ✅ INDEX 有 last-synced 锚点"; else echo "  🟡 INDEX 缺 last-synced 锚点（update 靠它算 delta）"; fi

echo "== 未填占位（⚑ 标记 / 裸 TODO·TBD 行，advisory）=="
# 排除 <!--注释--> 行（图例/指引里的 ⚑ 不算）；TODO/TBD 只匹配独占一行的裸标记（不匹配句中"TODO 系统"等）
ph=$(for f in "$DIR"/*.md; do grep -vE '<!--' "$f" 2>/dev/null | grep -qE '⚑|^[[:space:]]*[-*]?[[:space:]]*(TODO|TBD):?[[:space:]]*$' && echo "$f"; done)
if [ -n "$ph" ]; then
  echo "  🟡 仍含未填占位（语义占位可接受，应逐步填实）："
  echo "$ph" | sed 's#.*/#    - #'
else echo "  ✅ 无未填占位"; fi

echo "== key/secret 泄漏粗扫（红线 1）=="
if grep -rniE "(sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{12,}|Bearer[[:space:]]+[A-Za-z0-9._-]{16,}|(api[_-]?key|secret|token|password)[[:space:]]*[:=][[:space:]]*['\"]?[A-Za-z0-9._-]{16,})" "$DIR" 2>/dev/null; then
  echo "  🔴 疑似明文 key/secret/token，立即移除（committed 后可跨项目读）"; fail=1
else echo "  ✅ 未见明文密钥"; fi

echo "== 边界粗查（排除 <!--注释--> 与指针行，advisory）=="
arch=$(grep -vE '<!--|→|详见|另见' "$DIR/ARCHITECTURE.md" 2>/dev/null || true)
dec=$(grep -vE '<!--|→|详见|另见' "$DIR/DECISIONS.md" 2>/dev/null || true)
echo "$arch" | grep -qE '(GET|POST|PUT|DELETE) /|base[_ ]?url' && echo "  🟡 ARCHITECTURE 疑似混入对外接口 → 该进 SPEC"
echo "$dec" | grep -qE '事故|踩坑|根因' && echo "  🟡 DECISIONS 疑似混入运行时事故 → 该进 MEMORY"

echo "----"
[ "$fail" = 0 ] && echo "✅ 结构通过（🟡 为 advisory，不阻断）" || echo "🔴 有 must-fix 问题"
exit "$fail"
