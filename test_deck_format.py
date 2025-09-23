#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import sys
import os

# 添加 ServerStuff 到路徑
sys.path.append(os.path.join(os.path.dirname(__file__), 'ServerStuff'))

from utils.deck_validator import check_legal

def test_deck_file(deck_path):
    """測試牌組文件格式"""
    print(f"測試牌組文件: {deck_path}")
    print("=" * 50)
    
    try:
        # 讀取牌組文件
        with open(deck_path, 'r', encoding='utf-8') as f:
            deck_data = json.load(f)
        
        print("牌組數據結構:")
        print(f"  deckName: {deck_data.get('deckName', 'N/A')}")
        print(f"  oshi: {deck_data.get('oshi', 'N/A')}")
        print(f"  deck 項目數: {len(deck_data.get('deck', []))}")
        print(f"  cheerDeck 項目數: {len(deck_data.get('cheerDeck', []))}")
        
        # 檢查 oshi 格式
        oshi = deck_data.get('oshi', [])
        if isinstance(oshi, list) and len(oshi) == 2:
            print(f"  oshi[0] 類型: {type(oshi[0])} = {oshi[0]}")
            print(f"  oshi[1] 類型: {type(oshi[1])} = {oshi[1]}")
        else:
            print(f"  ❌ oshi 格式錯誤: {oshi}")
        
        # 檢查 deck 格式
        deck = deck_data.get('deck', [])
        if isinstance(deck, list):
            print(f"  deck 前3項:")
            for i, item in enumerate(deck[:3]):
                if isinstance(item, list) and len(item) == 3:
                    print(f"    [{i}] {item} - 類型: {[type(x) for x in item]}")
                else:
                    print(f"    [{i}] ❌ 格式錯誤: {item}")
        
        # 檢查 cheerDeck 格式
        cheer_deck = deck_data.get('cheerDeck', [])
        if isinstance(cheer_deck, list):
            print(f"  cheerDeck 項目:")
            for i, item in enumerate(cheer_deck):
                if isinstance(item, list) and len(item) == 3:
                    print(f"    [{i}] {item} - 類型: {[type(x) for x in item]}")
                else:
                    print(f"    [{i}] ❌ 格式錯誤: {item}")
        
        # 測試伺服器端驗證
        print("\n伺服器端驗證結果:")
        try:
            real_deck, result = check_legal(deck_data)
            if result["legal"]:
                print("  ✅ 牌組合法")
            else:
                print("  ❌ 牌組不合法")
                for reason in result["reasons"]:
                    print(f"    - {reason[0]}: {reason[1]}")
        except Exception as e:
            print(f"  ❌ 驗證過程出錯: {e}")
        
    except Exception as e:
        print(f"❌ 讀取文件失敗: {e}")
    
    print("\n" + "=" * 50)

def main():
    """主函數"""
    print("holoDelta 牌組格式測試工具")
    print("=" * 50)
    
    # 測試所有牌組文件
    decks_dir = "Decks"
    if os.path.exists(decks_dir):
        for filename in os.listdir(decks_dir):
            if filename.endswith('.json'):
                deck_path = os.path.join(decks_dir, filename)
                test_deck_file(deck_path)
                print()
    else:
        print(f"❌ 找不到 {decks_dir} 目錄")

if __name__ == "__main__":
    main()

