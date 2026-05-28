#!/usr/bin/env python3
"""重复内容检测脚本 - 检测故事中的重复段落"""
import sys
import re
from collections import Counter

def extract_sentences(text):
    """提取句子（以句号、问号、感叹号结尾）"""
    sentences = re.split(r'[。！？]', text)
    return [s.strip() for s in sentences if len(s.strip()) > 10]

def find_duplicates(text, min_length=20):
    """查找重复内容"""
    duplicates = []
    
    # 提取句子
    sentences = extract_sentences(text)
    
    # 统计重复
    counter = Counter(sentences)
    
    for sentence, count in counter.items():
        if count > 1 and len(sentence) >= min_length:
            duplicates.append({
                'text': sentence[:50] + '...' if len(sentence) > 50 else sentence,
                'count': count,
                'length': len(sentence)
            })
    
    return duplicates

def main():
    if len(sys.argv) < 2:
        print("用法: python check_duplicates.py <文件路径>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 提取正文
    parts = content.split('─' * 20)
    if len(parts) >= 2:
        body = parts[1] if len(parts) > 1 else content
    else:
        body = content
    
    duplicates = find_duplicates(body)
    
    if duplicates:
        print("⚠️ 发现重复内容：\n")
        for dup in duplicates:
            print(f"[重复{dup['count']}次] {dup['text']}")
            print()
        print(f"共发现 {len(duplicates)} 处重复")
    else:
        print("✅ 未发现重复内容")

if __name__ == "__main__":
    main()