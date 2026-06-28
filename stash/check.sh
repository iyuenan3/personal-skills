#!/usr/bin/env bash
# stash memory lint: 校验 memory 目录是否合 MEMORY_SPEC.md
# 用法：bash ~/.claude/skills/stash/check.sh [MEMORY_DIR]
#   无参数时从 pwd 推导：~/.claude/projects/-<dashed-cwd>/memory
# 退出码：🔴 有 must-fix → exit 1；🟡 advisory 不影响退出码。
set -uo pipefail
export LC_ALL="${LC_ALL:-C.UTF-8}"   # 中文匹配需 UTF-8 locale，否则静默失效
shopt -s nullglob                     # 空目录时 glob 不留字面

# ---- 定位 memory 目录 ----
if [ $# -ge 1 ]; then
  DIR="$1"
else
  dashed=$(pwd | sed 's:^/::; s:/:-:g')
  DIR="$HOME/.claude/projects/-$dashed/memory"
fi
[ -d "$DIR" ] || { echo "🔴 无 memory 目录：$DIR"; exit 1; }

DESC_MAX=200
fail=0; warn=0; nfiles=0
index=$(cat "$DIR/MEMORY.md" 2>/dev/null || true)
[ -n "$index" ] || echo "🟡 无 MEMORY.md 索引（索引校验跳过）"

# 所有 memory stem（[[link]] 存在性校验用）
stems=""
for f in "$DIR"/*.md; do
  b=$(basename "$f" .md); [ "$b" = "MEMORY" ] && continue
  stems="$stems $b"
done

for f in "$DIR"/*.md; do
  b=$(basename "$f" .md); [ "$b" = "MEMORY" ] && continue
  nfiles=$((nfiles+1))
  # frontmatter / body（^---$ 放宽含 \r 兼容 CRLF；body 去行尾 \r）
  fm=$(awk '/^---[[:space:]]*$/{c++; next} c==1' "$f")
  body=$(awk '/^---[[:space:]]*$/{c++; next} c>=2{gsub(/\r$/,""); print}' "$f")

  # 值提取：统一去尾 \r（CRLF 文件防误判），再去引号
  name=$(printf '%s\n' "$fm" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//; s/\r$//; s/["'"'"']//g')
  desc=$(printf '%s\n' "$fm" | grep -E '^description:' | head -1 | sed 's/^description:[[:space:]]*//; s/\r$//; s/^["'"'"']//; s/["'"'"']$//')
  mtype=$(printf '%s\n' "$fm" | grep -E '^[[:space:]]+type:' | head -1 | sed 's/.*type:[[:space:]]*//; s/\r$//; s/["'"'"']//g')
  toptype=$(printf '%s\n' "$fm" | grep -E '^type:' | head -1 | sed 's/^type:[[:space:]]*//; s/\r$//; s/["'"'"']//g')

  errs=""; warns=""

  # 文件名格式（block）：只允许 a-z0-9_（保护 name 反向映射唯一性）
  case "$b" in *[!a-z0-9_]*) errs="$errs 文件名含非法字符(只允许a-z0-9_)" ;; esac

  # name（缺失=block；≠stem连字符版 / 缺前缀=warn）
  if [ -z "$name" ]; then errs="$errs 缺name"
  else
    expect=$(printf '%s' "$b" | tr 'A-Z' 'a-z' | sed 's/_/-/g')
    [ "$name" = "$expect" ] || warns="$warns name≠stem连字符版(=$name 期望$expect)"
    case "$name" in user-*|feedback-*|project-*|reference-*) ;; *) warns="$warns name缺type前缀" ;; esac
  fi

  # description（缺失=block；块标量〔含同行内容形〕/ 过长=warn）
  if [ -z "$desc" ]; then errs="$errs 缺description"
  else
    case "$desc" in '>'*|'|'*) warns="$warns description用块标量(应单行inline)" ;; esac
    dlen=$(printf '%s' "$desc" | wc -m | tr -d ' ')
    [ "$dlen" -gt "$DESC_MAX" ] && warns="$warns description过长(${dlen}字)"
  fi

  # type（缺失/非枚举=block；老式顶层=warn；顶层与metadata冲突=warn）
  the_type="$mtype"
  if [ -z "$mtype" ] && [ -n "$toptype" ]; then the_type="$toptype"; warns="$warns 老式顶层type未迁metadata"; fi
  [ -n "$mtype" ] && [ -n "$toptype" ] && [ "$mtype" != "$toptype" ] && warns="$warns 顶层type($toptype)与metadata.type($mtype)冲突"
  if [ -z "$the_type" ]; then errs="$errs 缺type"
  else case "$the_type" in user|feedback|project|reference) ;; *) errs="$errs type非枚举($the_type)" ;; esac
  fi

  # 文件名前缀 vs type（warn）
  fileprefix=$(printf '%s' "$b" | sed 's/_.*//')
  [ -n "$the_type" ] && [ "$fileprefix" != "$the_type" ] && warns="$warns 文件名前缀($fileprefix)≠type($the_type)"

  # MEMORY.md 索引行（block）：须出现在 markdown 链接括号 (xxx.md) 里
  [ -n "$index" ] && { printf '%s' "$index" | grep -qE "\($b\.md\)" || errs="$errs MEMORY.md缺索引行"; }

  # feedback/project 必含 Why + How to apply（中文兜底要带加粗/冒号标记，防裸子串假阳）
  if [ "$the_type" = "feedback" ] || [ "$the_type" = "project" ]; then
    printf '%s' "$body" | grep -qiE '\*\*Why' || printf '%s' "$body" | grep -qE '\*\*为什么|为什么：|为什么:' || warns="$warns 缺Why"
    printf '%s' "$body" | grep -qiE 'How to apply' || printf '%s' "$body" | grep -qE '\*\*如何应用|如何应用：|如何应用:|\*\*怎么用|怎么用：|怎么用:' || warns="$warns 缺HowToApply"
  fi

  # [[link]]：带 type 前缀的须在 memory 存在（warn）
  for lk in $(printf '%s' "$body" | grep -oE '\[\[[^]]+\]\]' | sed 's/\[\[//; s/\]\]//; s/|.*//; s/#.*//'); do
    case "$lk" in
      user-*|feedback-*|project-*|reference-*)
        lk_stem=$(printf '%s' "$lk" | sed 's/-/_/g')
        printf '%s' "$stems" | grep -qFw "$lk_stem" || warns="$warns 断链[[$lk]]" ;;
    esac
  done

  [ -n "$errs" ]  && { echo "🔴 $b.md:$errs"; fail=1; }
  [ -n "$warns" ] && { echo "🟡 $b.md:$warns"; warn=1; }
done

# 反向索引校验：MEMORY.md 里指向不存在文件的孤儿行（改名 / 删除后漏清 → recall 加载悬空指针，红线5「一一对应」的反向半边）
if [ -n "$index" ]; then
  for link in $(printf '%s' "$index" | grep -oE '\([a-z0-9_]+\.md\)' | tr -d '()' | sed 's/\.md$//'); do
    [ "$link" = "MEMORY" ] && continue
    printf '%s' "$stems" | grep -qFw "$link" || { echo "🟡 MEMORY.md 索引孤儿行 → $link.md（文件不存在，改名 / 删除后漏清）"; warn=1; }
  done
fi

echo "----"
echo "扫描 $nfiles 个 memory"
[ "$fail" = 0 ] && echo "✅ 无 must-fix（🔴）" || echo "🔴 有 must-fix"
[ "$warn" = 1 ] && echo "🟡 有 advisory（不阻断）"
exit "$fail"
