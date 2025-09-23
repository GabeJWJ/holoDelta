#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成完整繁體中文翻譯的腳本
確保所有英文用語都被翻譯成中文
"""

import os
import re
from pathlib import Path

class CompleteTranslationGenerator:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.card_localization_dir = self.project_root / "cardLocalization"
        self.zh_tw_file = self.card_localization_dir / "zh_TW.po"
        self.en_file = self.card_localization_dir / "en.po"
        
        # 角色名稱對照表
        self.character_names = {
            # Gen 0
            "Tokino Sora": "時乃空",
            "AZKi": "AZKi",
            "Roboco-san": "機器子",
            "Sakura Miko": "櫻巫女",
            "Hoshimachi Suisei": "星街彗星",
            
            # Gen 1
            "Aki Rosenthal": "亞綺·羅森塔爾",
            "Shirakami Fubuki": "白上吹雪",
            "Natsuiro Matsuri": "夏色祭",
            "Akai Haato": "赤井心",
            "Hitomi Chris": "人見克里斯",
            
            # Gen 2
            "Minato Aqua": "湊阿庫婭",
            "Murasaki Shion": "紫咲詩音",
            "Nakiri Ayame": "百鬼綾目",
            "Yuzuki Choco": "癒月巧可",
            "Oozora Subaru": "大空昴",
            
            # Gen 3
            "Usada Pekora": "兔田佩克拉",
            "Shiranui Flare": "不知火芙蕾雅",
            "Shirogane Noel": "白銀諾艾爾",
            "Houshou Marine": "寶鐘瑪琳",
            "Uruha Rushia": "潤羽露西婭",
            
            # Gen 4
            "Amane Kanata": "天音彼方",
            "Kiryu Coco": "桐生可可",
            "Tsunomaki Watame": "角卷綿芽",
            "Tokoyami Towa": "常闇永遠",
            "Himemori Luna": "姬森露娜",
            
            # Gen 5
            "Yukihana Lamy": "雪花菈米",
            "Momosuzu Nene": "桃鈴音音",
            "Shishiro Botan": "獅白牡丹",
            "Omaru Polka": "尾丸波爾卡",
            
            # Gamers
            "Ookami Mio": "大神澪",
            "Nekomata Okayu": "貓又小粥",
            "Inugami Korone": "戌神沁音",
            
            # Myth
            "Mori Calliope": "森美聲",
            "Takanashi Kiara": "小鳥遊琪亞拉",
            "Ninomae Ina'nis": "一伊那爾栖",
            "Gawr Gura": "噶嗚·古拉",
            "Watson Amelia": "華生·阿米莉亞",
            
            # Council
            "Tsukumo Sana": "九十九佐命",
            "Ceres Fauna": "塞雷斯·法烏娜",
            "Ouro Kronii": "歐羅·克羅尼",
            "Hakos Baelz": "哈克斯·貝爾茲",
            "Nanashi Mumei": "七詩無名",
            "IRyS": "IRyS",
            
            # Promise
            "Regis Altare": "里吉斯·阿爾特亞",
            "Magni Dezmond": "馬格尼·德茲蒙德",
            "Axel Syrios": "阿克塞爾·西里奧斯",
            "Noir Vesper": "諾瓦爾·維斯帕",
            "Gavis Bettel": "加維斯·貝特爾",
            "Machina X Flayon": "馬基納·X·弗萊永",
            "Banzoin Hakka": "萬象院哈卡",
            "Josuiji Shinri": "定水寺真理",
            
            # Advent
            "Shiori Novella": "希奧里·諾維拉",
            "Koseki Bijou": "古石碧珠",
            "Nerissa Ravencroft": "內莉莎·雷文克羅夫特",
            "Fuwawa Abyssgard": "軟軟·阿比斯加德",
            "Mococo Abyssgard": "茸茸·阿比斯加德",
            
            # ReGloss
            "Hiodoshi Ao": "火威青",
            "Todoroki Hajime": "轟始",
            "Ichijou Ririka": "一條莉莉華",
            "Juufuutei Raden": "儒烏風亭鏍佃",
            
            # ID Gen 1
            "Airani Iofifteen": "艾拉妮·伊歐菲夫蒂恩",
            "Moona Hoshinova": "穆娜·星諾瓦",
            "Ayunda Risu": "阿雲達·里蘇",
            "Kureiji Ollie": "克雷吉·奧利",
            "Anya Melfissa": "阿尼亞·梅爾菲莎",
            "Pavolia Reine": "帕沃利亞·雷內",
            
            # ID Gen 2
            "Vestia Zeta": "貝斯蒂亞·澤塔",
            "Kaela Kovalskia": "卡埃拉·科瓦爾斯基亞",
            "Kobo Kanaeru": "科博·卡納埃爾",
            
            # ID Gen 3
            "La+ Darknesss": "拉普拉斯·達克內斯",
            "Takane Lui": "鷹嶺路易",
            "Hakui Koyori": "博衣小夜璃",
            "Sakamata Chloe": "沙花叉克蘿伊",
            
            # holoX
            "Rikka": "律可",
            "Arurandeisu": "阿爾蘭迪斯",
            "Astel Leda": "阿斯特爾·雷達",
            "Kishido Temma": "岸堂天真",
            "Yukoku Roberu": "夕刻羅貝爾",
            "Kageyama Shien": "影山詩恩",
            "Aragami Oga": "荒咬歐加",
            "Hanasaki Miyabi": "花咲雅",
            "Kanade Izuru": "奏手伊鶴",
            "Ririmu": "莉莉姆",
            
            # 其他重要角色
            "Jurard T Rexford": "朱拉德·T·雷克斯福德",
            "Kagami Kira": "鏡見吉良",
            "Kazama Iroha": "風真伊呂波",
            "Mano Aloe": "魔乃阿蘿耶",
            "Minase Rio": "水無世燐央",
            "Amelia Watson": "華生·阿米莉亞",
            
            # 特殊角色
            "YAGOO": "YAGOO",
            "A-chan": "A醬",
            "Nodoka": "野田",
            "M-chan": "M醬"
        }
        
        # 遊戲術語對照表
        self.game_terms = {
            # 基本遊戲術語
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
            
            # 遊戲操作術語
            "Draw": "抽牌",
            "Mill": "棄牌",
            "Reveal": "展示",
            "Search": "搜尋",
            "Shuffle": "洗牌",
            "Attach": "附加",
            "Switch": "切換",
            "Move": "移動",
            "Play": "打出",
            "Look at": "查看",
            "Look at the top": "查看牌組上方",
            "from among them": "從中",
            "and add them to hand": "並且加入手牌",
            "add to hand": "加入手牌",
            "archive the remaining cards": "將剩下的牌丟棄至歸檔區",
            "archive": "丟棄至歸檔區",
            "remaining cards": "剩下的牌",
            "cards of your deck": "張卡",
            "top": "上方",
            "bottom": "下方",
            
            # 時間和條件術語
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
            
            # 顏色術語
            "Red": "紅色",
            "Blue": "藍色",
            "Green": "綠色",
            "Purple": "紫色",
            "White": "白色",
            "Yellow": "黃色",
            "Colorless": "無色",
            
            # 狀態術語
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
            
            # 時間術語
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
            
            # 特殊術語
            "Debut": "出道",
            "Spot": "現身",
            "1st Bloom": "第一次綻放",
            "2nd Bloom": "第二次綻放",
            "Holomem": "ホロメン",
            "Oshi": "推し",
            "Staff": "工作人員",
            "staff": "工作人員",
            "Item": "道具",
            "item": "道具",
            "Event": "活動",
            "event": "活動",
            "Tool": "工具",
            "tool": "工具",
            "Mascot": "吉祥物",
            "mascot": "吉祥物",
            "Fan": "粉絲",
            "fan": "粉絲",
            
            # 遊戲模式術語
            "Lobby": "大廳",
            "Public": "公開",
            "Private": "私人",
            "Spectate": "觀戰",
            "Forfeit": "投降",
            "Mulligan": "重抽",
            "RPS": "猜拳",
            
            # 額外術語
            "EXTRA_BUZZ": "額外BUZZ",
            "EXTRA_UNLIM": "額外無限制",
            "EXTRA_EXTRANAME": "額外名稱",
            "EXTRA_SPOT": "額外現身",
            "This": "這個",
            "this": "這個",
            "holomem": "ホロメン",
            "is downed": "倒下時",
            "you get": "你獲得",
            "you may": "你可以",
            "you can": "你可以",
            "you must": "你必須",
            "you cannot": "你不能",
            "include": "包含",
            "any number of": "任意數量的",
            "in the deck": "在牌組中",
            "is also regarded as": "也被視為",
            "cardType": "卡片類型",
            "extraName": "額外名稱",
            "cannot bloom": "無法綻放",
            "this holomem": "這個ホロメン",
            "your opponent": "你的對手",
            "your opponent's": "你對手的",
            "this card": "這張卡",
            "that card": "那張卡",
            "all cards": "所有卡",
            "each card": "每張卡",
            "up to": "最多",
            "at least": "至少",
            "exactly": "正好",
            "more than": "超過",
            "less than": "少於",
            "equal to": "等於",
            "greater than": "大於",
            "smaller than": "小於",
            "then": "然後",
            "and": "並且",
            "or": "或",
            "when": "當",
            "while": "期間",
            "until": "直到",
            "after": "之後",
            "during": "在...期間",
            "instead": "代替",
            "also": "也",
            "in addition": "此外",
            "You may": "你可以",
            "You can": "你可以",
            "You must": "你必須",
            "You cannot": "你不能",
            "include": "包含",
            "any number of": "任意數量的",
            "in the deck": "在牌組中",
            "is also regarded as": "也被視為",
            "cardType": "卡片類型",
            "extraName": "額外名稱",
            "cannot bloom": "無法綻放",
            "this holomem": "這個ホロメン",
            "your opponent": "你的對手",
            "your opponent's": "你對手的",
            "this card": "這張卡",
            "that card": "那張卡",
            "all cards": "所有卡",
            "each card": "每張卡",
            "up to": "最多",
            "at least": "至少",
            "exactly": "正好",
            "more than": "超過",
            "less than": "少於",
            "equal to": "等於",
            "greater than": "大於",
            "smaller than": "小於"
        }
        
    def parse_po_file(self, content):
        """解析PO檔案內容"""
        entries = {}
        lines = content.split('\n')
        current_msgid = None
        current_msgstr = None
        
        for line in lines:
            line = line.strip()
            if line.startswith('msgid '):
                if current_msgid and current_msgstr is not None:
                    entries[current_msgid] = current_msgstr
                current_msgid = line[7:-1]  # 移除 'msgid "' 和結尾的 '"'
                current_msgstr = None
            elif line.startswith('msgstr '):
                current_msgstr = line[8:-1]  # 移除 'msgstr "' 和結尾的 '"'
                
        if current_msgid and current_msgstr is not None:
            entries[current_msgid] = current_msgstr
            
        return entries
        
    def translate_text(self, text):
        """翻譯文本，確保所有英文用語都被翻譯"""
        if not text:
            return text
            
        # 先替換角色名稱
        for eng_name, zh_name in self.character_names.items():
            text = text.replace(eng_name, zh_name)
            
        # 再替換遊戲術語（按長度排序，先替換長的）
        sorted_terms = sorted(self.game_terms.items(), key=lambda x: len(x[0]), reverse=True)
        for eng_term, zh_term in sorted_terms:
            text = text.replace(eng_term, zh_term)
            
        return text
        
    def generate_complete_translations(self):
        """生成完整的繁體中文翻譯"""
        print("正在讀取英文翻譯檔案...")
        
        if not self.en_file.exists():
            print(f"找不到英文檔案: {self.en_file}")
            return
            
        with open(self.en_file, 'r', encoding='utf-8') as f:
            en_content = f.read()
            
        print("正在解析英文檔案...")
        en_entries = self.parse_po_file(en_content)
        
        print(f"找到 {len(en_entries)} 個英文條目")
        
        # 生成新的翻譯內容
        new_entries = []
        translated_count = 0
        
        for msgid, msgstr in en_entries.items():
            # 翻譯文本
            translation = self.translate_text(msgstr)
            
            new_entries.append(f'msgid "{msgid}"')
            new_entries.append(f'msgstr "{translation}"')
            
            if translation != msgstr:
                translated_count += 1
                
        print(f"翻譯了 {translated_count} 個條目")
        
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
            for i in range(0, len(new_entries), 2):
                f.write(new_entries[i] + '\n')
                f.write(new_entries[i+1] + '\n\n')
            
        print(f"完整翻譯檔案已生成: {self.zh_tw_file}")

def main():
    generator = CompleteTranslationGenerator()
    generator.generate_complete_translations()

if __name__ == "__main__":
    main()
