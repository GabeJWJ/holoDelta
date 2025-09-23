#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
清理重複翻譯條目的腳本
"""

import os
import re
from pathlib import Path

class DuplicateCleaner:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.card_localization_dir = self.project_root / "cardLocalization"
        self.zh_tw_file = self.card_localization_dir / "zh_TW.po"
        self.en_file = self.card_localization_dir / "en.po"
        
    def clean_duplicates(self):
        """清理重複的翻譯條目"""
        print("正在讀取英文翻譯檔案...")
        
        if not self.en_file.exists():
            print(f"找不到英文檔案: {self.en_file}")
            return
            
        with open(self.en_file, 'r', encoding='utf-8') as f:
            en_content = f.read()
            
        print("正在讀取繁體中文翻譯檔案...")
        
        if not self.zh_tw_file.exists():
            print(f"找不到繁體中文檔案: {self.zh_tw_file}")
            return
            
        with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
            zh_content = f.read()
            
        print("正在解析英文檔案...")
        en_entries = self.parse_po_file(en_content)
        
        print("正在解析繁體中文檔案...")
        zh_entries = self.parse_po_file(zh_content)
        
        print(f"英文條目數: {len(en_entries)}")
        print(f"中文條目數: {len(zh_entries)}")
        
        # 找出英文檔案中存在的條目
        valid_entries = {}
        for msgid, msgstr in zh_entries.items():
            if msgid in en_entries:
                valid_entries[msgid] = msgstr
            else:
                print(f"移除不在英文檔案中的條目: {msgid}")
                
        print(f"清理後的中文條目數: {len(valid_entries)}")
        
        # 生成新的翻譯內容
        new_entries = []
        for msgid, msgstr in en_entries.items():
            if msgid in valid_entries:
                new_entries.append(f'msgid "{msgid}"')
                new_entries.append(f'msgstr "{valid_entries[msgid]}"')
            else:
                # 如果中文檔案中沒有這個條目，使用英文原文
                new_entries.append(f'msgid "{msgid}"')
                new_entries.append(f'msgstr "{msgstr}"')
                
        # 寫入檔案
        header = '''msgid ""
msgstr ""
"Plural-Forms: nplurals=1; plural=0;\\n"
"X-Crowdin-Project: holodelta\\n"
"X-Crowdin-Project-ID: 724315\\n"
"X-Crowdin-File: /cards/template.pot\\n"
"X-Crowdin-File-ID: 14\\n"
"Project-Id-Version: holodelta\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Language-Team: Traditional Chinese\\n"
"Language: zh_TW\\n"
"PO-Revision-Date: 2024-12-19 00:00\\n"

'''
        
        with open(self.zh_tw_file, 'w', encoding='utf-8') as f:
            f.write(header)
            f.write('\n'.join(new_entries))
            
        print(f"清理完成！檔案已更新: {self.zh_tw_file}")
        
    def parse_po_file(self, content):
        """解析PO檔案內容"""
        entries = {}
        lines = content.split('\n')
        current_msgid = None
        current_msgstr = None
        
        for line in lines:
            line = line.strip()
            if line.startswith('msgid '):
                if current_msgid and current_msgstr:
                    entries[current_msgid] = current_msgstr
                current_msgid = line[7:-1]  # 移除 'msgid "' 和結尾的 '"'
                current_msgstr = None
            elif line.startswith('msgstr '):
                current_msgstr = line[8:-1]  # 移除 'msgstr "' 和結尾的 '"'
                
        if current_msgid and current_msgstr:
            entries[current_msgid] = current_msgstr
            
        return entries

def main():
    cleaner = DuplicateCleaner()
    cleaner.clean_duplicates()

if __name__ == "__main__":
    main()
