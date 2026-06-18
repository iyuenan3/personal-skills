#!/usr/bin/env python3
"""worklog 日记 / wiki 中文标点残余检查（CJK 上下文感知，按真字符匹配、不踩 locale）。

用法:
  python3 punctuation_check.py <file.md> [<file2.md> ...]   # 日记 / wiki: 查全部半角 + em-dash
  python3 punctuation_check.py --commit <file>               # commit message: 只 gate em-dash(红线)
退出码: 0 = 干净; 1 = 有残余(逐行打印 路径:行号:[类型] 上下文); 2 = 用法错误; 3 = 有文件不存在(其余已检测)。

为什么用 Python 不用 rg/grep:
- 按真 unicode 字符匹配，天然区分全角（：（）U+FF1A/08/09）与半角（: ( ) U+003A/28/29），不踩 LC_ALL（macOS 默认 locale 静默漏 CJK）。
- 是磁盘脚本，不会像 SKILL.md 内联 perl 的 $1 那样被上下文渲染吞掉。
- 覆盖「全部半角标点」，不只 **bold**: + em-dash（落实 feedback_wiki_symbol_consistency 5/31 规则）。

检测类别（仅 prose，保护区已剥离）:
1. em-dash: — / ——（中文写作绝不用破折号，全局红线；commit 模式只查这条）
2. CJK 相邻半角 , ; ! ?（含 CJK 后跟空格再半角）
3. CJK 相邻半角冒号 :（时间 21:01 因两侧是数字非 CJK，天然不命中）
4. 半角括号 ( ) 前邻 CJK 或括号内含 CJK（func(x) 纯 ASCII 括号不误报）
5. 加粗段 **X** 后跟半角 , : ; ! ?
保护区（不检测）: frontmatter（开头第一对 ---，未闭合则不当 frontmatter）/ 代码围栏 ```（未闭合则告警并当 prose）/
行内代码 `...` / [[wikilink]] / [文本](链接) / 裸 URL（URL 在 CJK / 中文标点边界停，不吞 prose）。
"""
import re
import sys

# CJK + 中文常见非汉字符号（〇々 + Ext-A + 基本区 + 兼容区 + 圈号①-⑳ + 括号号㈠-㈩）, 供「相邻」判定
CJK = r'々〇㐀-䶿一-鿿豈-﫿①-⑳㈠-㈩'

_RE_INLINE_CODE = re.compile(r'`[^`]*`')
_RE_WIKILINK = re.compile(r'\[\[[^\]]*\]\]')
_RE_MDLINK = re.compile(r'\[[^\]]*\]\([^)]*\)')
# URL 结尾在空白 / 中文 / 中文标点 / 半角逗号分号处停，避免吞掉紧邻的中文 prose（如 "见 https://x.com,已部署"）
_RE_URL = re.compile(r'https?://[^\s' + CJK + r'，。、；：！？（）「」,;]+')

_RE_EMDASH = re.compile(r'—')
# CJK 紧邻(可含一个空格)半角逗号/分号/叹号/问号
_RE_HALF_PUNCT = re.compile(r'[' + CJK + r'] ?[,;!?]|[,;!?] ?[' + CJK + r']')
_RE_HALF_COLON = re.compile(r'[' + CJK + r'] ?:|: ?[' + CJK + r']')
_RE_HALF_PAREN = re.compile(r'[' + CJK + r']\(|\([^()]*[' + CJK + r'][^()]*\)')
_RE_BOLD_HALF = re.compile(r'\*\*[^*\n]+\*\*[,:;!?]')


def _strip_protected(line):
    line = _RE_INLINE_CODE.sub(' ', line)
    line = _RE_WIKILINK.sub(' ', line)
    line = _RE_MDLINK.sub(' ', line)
    line = _RE_URL.sub(' ', line)
    return line


def _classify(p, commit_mode):
    if _RE_EMDASH.search(p):
        return 'em-dash'
    if commit_mode:
        return None
    # 先判加粗后半角(优先于裸半角冒号, 标签更准)
    if _RE_BOLD_HALF.search(p):
        return '加粗后半角'
    if _RE_HALF_PUNCT.search(p):
        return '半角,;!?'
    if _RE_HALF_COLON.search(p):
        return '半角冒号'
    if _RE_HALF_PAREN.search(p):
        return '半角括号'
    return None


def _frontmatter_end(lines):
    """开头第一对 --- 的闭合行号(0-based, 含)；未闭合 / 非 --- 开头 → -1(不当 frontmatter)。"""
    if not lines or lines[0].strip() != '---':
        return -1
    for i in range(1, min(len(lines), 60)):
        if lines[i].strip() == '---':
            return i
    return -1  # 未闭合: 不吞后文


def check_file(path, commit_mode=False):
    with open(path, encoding='utf-8') as f:
        lines = f.read().split('\n')
    fm_end = _frontmatter_end(lines)
    # 预扫围栏: 配对 ``` 行号; 未闭合则告警 + 不跳过(当 prose), 防整篇被吞
    fence_lines = [i for i, l in enumerate(lines) if l.lstrip().startswith('```')]
    fenced = set()
    if len(fence_lines) % 2 != 0:
        sys.stderr.write(f'⚠️ {path}: 代码围栏 ``` 不闭合（{len(fence_lines)} 个），围栏内不豁免、全当 prose 检测\n')
    else:
        for a, b in zip(fence_lines[0::2], fence_lines[1::2]):
            for k in range(a, b + 1):
                fenced.add(k)
    hits = []
    for i, raw in enumerate(lines):
        if i <= fm_end:
            continue
        if i in fenced:
            continue
        kind = _classify(_strip_protected(raw.rstrip()), commit_mode)
        if kind:
            hits.append((i + 1, kind, raw.strip()[:90]))
    return hits


def main(argv):
    args = argv[1:]
    commit_mode = False
    if args and args[0] in ('--commit', '--mode=commit'):
        commit_mode = True
        args = args[1:]
    if not args:
        sys.stderr.write('用法: punctuation_check.py [--commit] <file.md> [...]\n')
        return 2
    all_hits = []
    missing = False
    for path in args:
        try:
            for ln, kind, ctx in check_file(path, commit_mode):
                all_hits.append((path, ln, kind, ctx))
        except FileNotFoundError:
            sys.stderr.write(f'⚠️ 文件不存在(跳过): {path}\n')
            missing = True
    if all_hits:
        for path, ln, kind, ctx in all_hits:
            print(f'{path}:{ln}: [{kind}] {ctx}')
        sys.stderr.write(f'\n✗ {len(all_hits)} 处{"破折号" if commit_mode else "中文标点残余"}（改后重跑）\n')
        return 1
    if missing:
        return 3
    print('✓ 标点干净（无残余）')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
