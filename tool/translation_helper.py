#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HoloDelta 翻譯助手
用於批量處理和添加翻譯內容
"""

import os
import re
from pathlib import Path

class TranslationHelper:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.card_localization_dir = self.project_root / "cardLocalization"
        self.zh_tw_file = self.card_localization_dir / "zh_TW.po"
        
        # 角色名稱對照表
        self.character_names = {
            "Tokino Sora": "時乃空",
            "AZKi": "AZKi",
            "Roboco-san": "機器子",
            "Sakura Miko": "櫻巫女",
            "Hoshimachi Suisei": "星街彗星",
            "Aki Rosenthal": "亞綺·羅森塔爾",
            "Shirakami Fubuki": "白上吹雪",
            "Natsuiro Matsuri": "夏色祭",
            "Akai Haato": "赤井心",
            "Hitomi Chris": "人見克里斯",
            "Minato Aqua": "湊阿庫婭",
            "Murasaki Shion": "紫咲詩音",
            "Nakiri Ayame": "百鬼綾目",
            "Yuzuki Choco": "癒月巧可",
            "Oozora Subaru": "大空昴",
            "Usada Pekora": "兔田佩克拉",
            "Shiranui Flare": "不知火芙蕾雅",
            "Shirogane Noel": "白銀諾艾爾",
            "Houshou Marine": "寶鐘瑪琳",
            "Uruha Rushia": "潤羽露西婭",
            "Amane Kanata": "天音彼方",
            "Kiryu Coco": "桐生可可",
            "Tsunomaki Watame": "角卷綿芽",
            "Tokoyami Towa": "常闇永遠",
            "Himemori Luna": "姬森露娜",
            "Yukihana Lamy": "雪花菈米",
            "Momosuzu Nene": "桃鈴音音",
            "Shishiro Botan": "獅白牡丹",
            "Omaru Polka": "尾丸波爾卡",
            "Ookami Mio": "大神澪",
            "Nekomata Okayu": "貓又小粥",
            "Inugami Korone": "戌神沁音",
            "Mori Calliope": "森美聲",
            "Takanashi Kiara": "小鳥遊琪亞拉",
            "Ninomae Ina'nis": "一伊那爾栖",
            "Gawr Gura": "噶嗚·古拉",
            "Watson Amelia": "華生·阿米莉亞",
            "Tsukumo Sana": "九十九佐命",
            "Ceres Fauna": "塞雷斯·法烏娜",
            "Ouro Kronii": "歐羅·克羅尼",
            "Hakos Baelz": "哈克斯·貝爾茲",
            "Nanashi Mumei": "七詩無名",
            "IRyS": "IRyS",
            "Regis Altare": "里吉斯·阿爾特亞",
            "Magni Dezmond": "馬格尼·德茲蒙德",
            "Axel Syrios": "阿克塞爾·西里奧斯",
            "Noir Vesper": "諾瓦爾·維斯帕",
            "Gavis Bettel": "加維斯·貝特爾",
            "Machina X Flayon": "馬基納·X·弗萊永",
            "Banzoin Hakka": "萬象院哈卡",
            "Josuiji Shinri": "定水寺真理",
            "Shiori Novella": "希奧里·諾維拉",
            "Koseki Bijou": "古石碧珠",
            "Nerissa Ravencroft": "內莉莎·雷文克羅夫特",
            "Fuwawa Abyssgard": "軟軟·阿比斯加德",
            "Mococo Abyssgard": "茸茸·阿比斯加德",
            "Hiodoshi Ao": "火威青",
            "Todoroki Hajime": "轟始",
            "Ririka": "一條莉莉華",
            "Raden": "儒烏風亭鏍佃",
            "Airani Iofifteen": "艾拉妮·伊歐菲夫蒂恩",
            "Moona Hoshinova": "穆娜·星諾瓦",
            "Ayunda Risu": "阿雲達·里蘇",
            "Kureiji Ollie": "克雷吉·奧利",
            "Anya Melfissa": "阿尼亞·梅爾菲莎",
            "Pavolia Reine": "帕沃利亞·雷內",
            "Vestia Zeta": "貝斯蒂亞·澤塔",
            "Kaela Kovalskia": "卡埃拉·科瓦爾斯基亞",
            "Kobo Kanaeru": "科博·卡納埃爾",
            "La+ Darknesss": "拉普拉斯·達克內斯",
            "Takane Lui": "鷹嶺路易",
            "Hakui Koyori": "博衣小夜璃",
            "Sakamata Chloe": "沙花叉克蘿伊",
            "Rikka": "律可",
            "Arurandeisu": "阿爾蘭迪斯",
            "Astel Leda": "阿斯特爾·雷達",
            "Kishido Temma": "岸堂天真",
            "Yukoku Roberu": "夕刻羅貝爾",
            "Kageyama Shien": "影山詩恩",
            "Aragami Oga": "荒咬歐加",
            "Hanasaki Miyabi": "花咲雅",
            "Kanade Izuru": "奏手伊鶴",
            "Ririmu": "莉莉姆"
        }
        
        # 遊戲術語對照表
        self.game_terms = {
            "Turn": "回合",
            "Game": "遊戲",
            "Match": "對戰",
            "Life": "生命值",
            "HP": "體力",
            "Damage": "傷害",
            "Special Damage": "特殊傷害",
            "Arts": "技能",
            "Skill": "技能",
            "SP Skill": "SP技能",
            "Oshi Skill": "推し技能",
            "Holopower": "ホロパワー",
            "Cheer": "應援",
            "Support": "支援",
            "Bloom": "綻放",
            "Baton Pass": "接力",
            "Hand": "手牌",
            "Deck": "牌組",
            "Cheer Deck": "應援牌組",
            "Archive": "歸檔區",
            "Center": "中央",
            "Back": "後台",
            "Collab": "合作區",
            "Stage": "舞台",
            "Draw": "抽牌",
            "Mill": "棄牌",
            "Reveal": "展示",
            "Search": "搜尋",
            "Shuffle": "洗牌",
            "Attach": "附加",
            "Switch": "切換",
            "Move": "移動",
            "Play": "打出",
            "Once per turn": "每回合一次",
            "Once per game": "每場遊戲一次",
            "Usable when": "可使用時",
            "During this turn": "本回合內",
            "Until end of turn": "直到回合結束",
            "If": "如果",
            "Then": "然後",
            "However": "但是",
            "Instead": "代替",
            "Ignore": "無視",
            "Reroll": "重擲",
            "Roll a die": "擲骰",
            "Declare": "宣言",
            "Red": "紅色",
            "Blue": "藍色",
            "Green": "綠色",
            "Purple": "紫色",
            "White": "白色",
            "Yellow": "黃色",
            "Colorless": "無色",
            "Buzz": "BUZZ",
            "Limited": "限制",
            "Unlimited": "無限制",
            "Downed": "倒下",
            "Attached": "附加",
            "Revealed": "已展示",
            "Hidden": "隱藏",
            "Rested": "休息",
            "Face Down": "背面",
            "Face Up": "正面",
            "Start of turn": "回合開始時",
            "End of turn": "回合結束時",
            "Before": "之前",
            "After": "之後",
            "When": "時",
            "While": "期間",
            "Until": "直到",
            "As long as": "只要",
            "In addition": "此外",
            "Also": "也",
            "Debut": "出道",
            "Spot": "現身",
            "1st Bloom": "第一次綻放",
            "2nd Bloom": "第二次綻放",
            "Holomem": "ホロメン",
            "Oshi": "推し",
            "Staff": "工作人員",
            "Item": "道具",
            "Event": "活動",
            "Tool": "工具",
            "Mascot": "吉祥物",
            "Fan": "粉絲",
            "Lobby": "大廳",
            "Public": "公開",
            "Private": "私人",
            "Spectate": "觀戰",
            "Forfeit": "投降",
            "Mulligan": "重抽",
            "RPS": "猜拳"
        }
        
    def read_english_file(self):
        """讀取英文翻譯檔案"""
        en_file = self.card_localization_dir / "en.po"
        if not en_file.exists():
            print(f"找不到英文檔案: {en_file}")
            return None
            
        with open(en_file, 'r', encoding='utf-8') as f:
            return f.read()
            
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
        
    def translate_entry(self, msgid, msgstr):
        """翻譯單個條目"""
        # 如果是角色名稱
        if msgid in self.character_names:
            return self.character_names[msgid]
            
        # 如果是遊戲術語
        if msgid in self.game_terms:
            return self.game_terms[msgid]
            
        # 如果是卡片名稱 (包含_NAME)
        if "_NAME" in msgid:
            # 提取角色名稱並翻譯
            for eng_name, zh_name in self.character_names.items():
                if eng_name in msgstr:
                    return msgstr.replace(eng_name, zh_name)
                    
        # 如果是技能效果 (包含_EFFECT)
        if "_EFFECT" in msgid:
            return self.translate_effect(msgstr)
            
        # 如果是技能名稱 (包含_SKILL_NAME)
        if "_SKILL_NAME" in msgid:
            return self.translate_skill_name(msgstr)
            
        # 如果是藝術名稱 (包含_ART_)
        if "_ART_" in msgid and "_NAME" in msgid:
            return self.translate_art_name(msgstr)
            
        # 預設返回原文
        return msgstr
        
    def translate_effect(self, effect):
        """翻譯技能效果"""
        # 替換常見的遊戲術語
        for eng_term, zh_term in self.game_terms.items():
            effect = effect.replace(eng_term, zh_term)
            
        # 替換角色名稱
        for eng_name, zh_name in self.character_names.items():
            effect = effect.replace(f"<{eng_name}>", f"<{zh_name}>")
            
        return effect
        
    def translate_skill_name(self, skill_name):
        """翻譯技能名稱"""
        # 替換常見的遊戲術語
        for eng_term, zh_term in self.game_terms.items():
            skill_name = skill_name.replace(eng_term, zh_term)
            
        return skill_name
        
    def translate_art_name(self, art_name):
        """翻譯藝術名稱"""
        # 替換角色名稱
        for eng_name, zh_name in self.character_names.items():
            art_name = art_name.replace(eng_name, zh_name)
            
        return art_name
        
    def generate_translation(self):
        """生成翻譯檔案"""
        print("正在讀取英文翻譯檔案...")
        en_content = self.read_english_file()
        if not en_content:
            return
            
        print("正在解析PO檔案...")
        entries = self.parse_po_file(en_content)
        
        print(f"找到 {len(entries)} 個翻譯條目")
        
        # 讀取現有的繁體中文檔案
        existing_entries = {}
        if self.zh_tw_file.exists():
            with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
                existing_content = f.read()
                existing_entries = self.parse_po_file(existing_content)
                
        # 生成新的翻譯內容
        new_entries = []
        translated_count = 0
        
        for msgid, msgstr in entries.items():
            if msgid in existing_entries:
                # 使用現有翻譯
                new_entries.append(f'msgid "{msgid}"')
                new_entries.append(f'msgstr "{existing_entries[msgid]}"')
            else:
                # 生成新翻譯
                translation = self.translate_entry(msgid, msgstr)
                new_entries.append(f'msgid "{msgid}"')
                new_entries.append(f'msgstr "{translation}"')
                if translation != msgstr:
                    translated_count += 1
                    
        print(f"新增翻譯了 {translated_count} 個條目")
        
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
            
        print(f"翻譯檔案已更新: {self.zh_tw_file}")
        
    def add_missing_translations(self):
        """添加缺失的翻譯"""
        print("正在檢查缺失的翻譯...")
        
        # 讀取英文檔案
        en_content = self.read_english_file()
        if not en_content:
            return
            
        en_entries = self.parse_po_file(en_content)
        
        # 讀取現有繁體中文檔案
        if not self.zh_tw_file.exists():
            print("繁體中文檔案不存在，請先運行 generate_translation()")
            return
            
        with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
            zh_content = f.read()
            
        zh_entries = self.parse_po_file(zh_content)
        
        # 找出缺失的翻譯
        missing_entries = []
        for msgid, msgstr in en_entries.items():
            if msgid not in zh_entries:
                translation = self.translate_entry(msgid, msgstr)
                missing_entries.append((msgid, translation))
                
        if missing_entries:
            print(f"找到 {len(missing_entries)} 個缺失的翻譯")
            
            # 添加到檔案末尾
            with open(self.zh_tw_file, 'a', encoding='utf-8') as f:
                f.write('\n')
                for msgid, translation in missing_entries:
                    f.write(f'msgid "{msgid}"\n')
                    f.write(f'msgstr "{translation}"\n\n')
                    
            print("缺失的翻譯已添加")
        else:
            print("沒有缺失的翻譯")

def main():
    helper = TranslationHelper()
    
    print("HoloDelta 翻譯助手")
    print("=" * 30)
    print("1. 生成完整翻譯檔案")
    print("2. 添加缺失的翻譯")
    print("3. 退出")
    
    choice = input("請選擇操作 (1-3): ").strip()
    
    if choice == "1":
        helper.generate_translation()
    elif choice == "2":
        helper.add_missing_translations()
    elif choice == "3":
        print("再見！")
    else:
        print("無效選擇")

if __name__ == "__main__":
    main()
