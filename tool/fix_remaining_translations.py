#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修復剩餘翻譯問題的腳本
處理更複雜的翻譯問題
"""

import os
import re
from pathlib import Path

class RemainingTranslationFixer:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.card_localization_dir = self.project_root / "cardLocalization"
        self.zh_tw_file = self.card_localization_dir / "zh_TW.po"
        
    def fix_remaining_issues(self):
        """修復剩餘的翻譯問題"""
        print("正在讀取繁體中文翻譯檔案...")
        
        if not self.zh_tw_file.exists():
            print(f"找不到檔案: {self.zh_tw_file}")
            return
            
        with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        print("正在修復剩餘的翻譯問題...")
        
        # 統計修復數量
        fixed_count = 0
        
        # 1. 修復混合中英文的翻譯
        print("\\n=== 修復混合中英文翻譯 ===")
        
        # 修復 "查看 the 上方 7 張卡" -> "查看牌組上方7張卡"
        pattern1 = r'msgstr "\[1/遊戲\]查看 the 上方 (\d+) 張卡\. 展示 (\d+) \[<([^>]+)> 並且 staff\] 從中, 並且加入手牌\. 然後, 將剩下的牌丟棄至歸檔區\."'
        replacement1 = r'msgstr "[1/遊戲]查看牌組上方\1張卡，從中展示\2張 [<\3> and 工作人員] 並且加入手牌，然後將剩下的牌丟棄至歸檔區。"'
        
        if re.search(pattern1, content):
            content = re.sub(pattern1, replacement1, content)
            fixed_count += 1
            print("修復混合中英文翻譯")
            
        # 2. 修復其他常見的混合翻譯問題
        mixed_fixes = [
            # 修復 "the" 在中文中的問題
            (r'查看 the 上方', '查看牌組上方'),
            (r'查看 the 下方', '查看牌組下方'),
            (r'查看 the top', '查看牌組上方'),
            (r'查看 the bottom', '查看牌組下方'),
            
            # 修復 "並且" 和 "and" 的混合
            (r'並且 staff', 'and 工作人員'),
            (r'並且 fan', 'and 粉絲'),
            (r'並且 mascot', 'and 吉祥物'),
            (r'並且 item', 'and 道具'),
            (r'並且 event', 'and 活動'),
            (r'並且 tool', 'and 工具'),
            
            # 修復數字和單位的問題
            (r'(\d+) 張卡', r'\\1張卡'),
            (r'(\d+) 張', r'\\1張'),
            (r'(\d+) 個', r'\\1個'),
            (r'(\d+) 點', r'\\1點'),
            
            # 修復標點符號
            (r'\. 然後,', '，然後'),
            (r'\. 然後', '，然後'),
            (r'\. 並且', '，並且'),
            (r'\. 如果', '，如果'),
            (r'\. 當', '，當'),
            (r'\. 期間', '，期間'),
            (r'\. 直到', '，直到'),
            (r'\. 之前', '，之前'),
            (r'\. 之後', '，之後'),
            (r'\. 代替', '，代替'),
            (r'\. 但是', '，但是'),
            (r'\. 也', '，也'),
            (r'\. 此外', '，此外'),
            
            # 修復空格問題
            (r' 並且 ', ' 並且 '),
            (r' 然後 ', ' 然後 '),
            (r' 如果 ', ' 如果 '),
            (r' 當 ', ' 當 '),
            (r' 期間 ', ' 期間 '),
            (r' 直到 ', ' 直到 '),
            (r' 之前 ', ' 之前 '),
            (r' 之後 ', ' 之後 '),
            (r' 代替 ', ' 代替 '),
            (r' 但是 ', ' 但是 '),
            (r' 也 ', ' 也 '),
            (r' 此外 ', ' 此外 '),
        ]
        
        for pattern, replacement in mixed_fixes:
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                fixed_count += 1
                print(f"修復混合翻譯: {pattern[:30]}...")
                
        # 3. 修復角色名稱在效果中的引用格式
        print("\\n=== 修復角色引用格式 ===")
        
        # 修復 <角色名稱> and 工作人員 格式
        character_fixes = [
            (r'<尾丸波爾卡> 並且 staff', '<尾丸波爾卡> and 工作人員'),
            (r'<白上吹雪> 並且 staff', '<白上吹雪> and 工作人員'),
            (r'<櫻巫女> 並且 staff', '<櫻巫女> and 工作人員'),
            (r'<星街彗星> 並且 staff', '<星街彗星> and 工作人員'),
            (r'<亞綺·羅森塔爾> 並且 staff', '<亞綺·羅森塔爾> and 工作人員'),
            (r'<夏色祭> 並且 staff', '<夏色祭> and 工作人員'),
            (r'<赤井心> 並且 staff', '<赤井心> and 工作人員'),
            (r'<人見克里斯> 並且 staff', '<人見克里斯> and 工作人員'),
            (r'<湊阿庫婭> 並且 staff', '<湊阿庫婭> and 工作人員'),
            (r'<紫咲詩音> 並且 staff', '<紫咲詩音> and 工作人員'),
            (r'<百鬼綾目> 並且 staff', '<百鬼綾目> and 工作人員'),
            (r'<癒月巧可> 並且 staff', '<癒月巧可> and 工作人員'),
            (r'<大空昴> 並且 staff', '<大空昴> and 工作人員'),
            (r'<兔田佩克拉> 並且 staff', '<兔田佩克拉> and 工作人員'),
            (r'<不知火芙蕾雅> 並且 staff', '<不知火芙蕾雅> and 工作人員'),
            (r'<白銀諾艾爾> 並且 staff', '<白銀諾艾爾> and 工作人員'),
            (r'<寶鐘瑪琳> 並且 staff', '<寶鐘瑪琳> and 工作人員'),
            (r'<潤羽露西婭> 並且 staff', '<潤羽露西婭> and 工作人員'),
            (r'<天音彼方> 並且 staff', '<天音彼方> and 工作人員'),
            (r'<桐生可可> 並且 staff', '<桐生可可> and 工作人員'),
            (r'<角卷綿芽> 並且 staff', '<角卷綿芽> and 工作人員'),
            (r'<常闇永遠> 並且 staff', '<常闇永遠> and 工作人員'),
            (r'<姬森露娜> 並且 staff', '<姬森露娜> and 工作人員'),
            (r'<雪花菈米> 並且 staff', '<雪花菈米> and 工作人員'),
            (r'<桃鈴音音> 並且 staff', '<桃鈴音音> and 工作人員'),
            (r'<獅白牡丹> 並且 staff', '<獅白牡丹> and 工作人員'),
            (r'<尾丸波爾卡> 並且 staff', '<尾丸波爾卡> and 工作人員'),
            (r'<大神澪> 並且 staff', '<大神澪> and 工作人員'),
            (r'<貓又小粥> 並且 staff', '<貓又小粥> and 工作人員'),
            (r'<戌神沁音> 並且 staff', '<戌神沁音> and 工作人員'),
        ]
        
        for pattern, replacement in character_fixes:
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                fixed_count += 1
                print(f"修復角色引用格式: {pattern[:20]}...")
                
        # 4. 修復其他常見的翻譯問題
        print("\\n=== 修復其他翻譯問題 ===")
        
        other_fixes = [
            # 修復 "staff" 的翻譯
            (r'staff', '工作人員'),
            (r'Staff', '工作人員'),
            (r'STAFF', '工作人員'),
            
            # 修復 "fan" 的翻譯
            (r'fan', '粉絲'),
            (r'Fan', '粉絲'),
            (r'FAN', '粉絲'),
            
            # 修復 "mascot" 的翻譯
            (r'mascot', '吉祥物'),
            (r'Mascot', '吉祥物'),
            (r'MASCOT', '吉祥物'),
            
            # 修復 "item" 的翻譯
            (r'item', '道具'),
            (r'Item', '道具'),
            (r'ITEM', '道具'),
            
            # 修復 "event" 的翻譯
            (r'event', '活動'),
            (r'Event', '活動'),
            (r'EVENT', '活動'),
            
            # 修復 "tool" 的翻譯
            (r'tool', '工具'),
            (r'Tool', '工具'),
            (r'TOOL', '工具'),
        ]
        
        for pattern, replacement in other_fixes:
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                fixed_count += 1
                print(f"修復其他翻譯: {pattern} -> {replacement}")
                
        # 寫入修復後的檔案
        with open(self.zh_tw_file, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"\\n修復完成！總共修復了 {fixed_count} 個翻譯條目")
        print(f"檔案已更新: {self.zh_tw_file}")

def main():
    fixer = RemainingTranslationFixer()
    fixer.fix_remaining_issues()

if __name__ == "__main__":
    main()
