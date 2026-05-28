#!/usr/bin/env python3
"""字数统计脚本 - 统计故事的字数"""
import sys
import re

def count_chinese_chars(text):
    """统计中文字符数（不含标点）"""
    # 匹配中文字符
    chinese_chars = re.findall(r'[\u4e00-\u9fff]', text)
    return len(chinese_chars)

def count_words(text):
    """统计总字数（中文+英文单词）"""
    # 中文字符
    chinese = len(re.findall(r'[\u4e00-\u9fff]', text))
    # 英文单词
    english = len(re.findall(r'[a-zA-Z]+', text))
    # 数字
    numbers = len(re.findall(r'\d+', text))
    return chinese + english + numbers

def main():
    if len(sys.argv) < 2:
        print("用法: python word_count.py <文件路径>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 提取正文（去除分割线之间的标题和结尾）
    parts = content.split('─' * 20)
    if len(parts) >= 2:
        body = parts[1] if len(parts) > 1 else content
    else:
        body = content
    
    chinese = count_chinese_chars(body)
    total = count_words(body)
    
    print(f"中文字符: {chinese}")
    print(f"总字数（含英文数字）: {total}")
    print(f"目标字数: 7000-10000")
    
    if chinese < 7000:
        print(f"⚠️ 字数不足，还差 {7000 - chinese} 字")
    elif chinese > 10000:
        print(f"⚠️ 字数超出 {chinese - 10000} 字")
    else:
        print("✅ 字数达标")

if __name__ == "__main__":
    main()