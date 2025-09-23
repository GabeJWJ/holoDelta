#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import sys
import os

# 添加 ServerStuff 到路徑
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ServerStuff'))

from globals.data import initialize
from utils.deck_validator import check_legal

def test_client_deck_format():
    print("=== 測試客戶端牌組格式 ===")
    
    try:
        # 初始化數據
        initialize()
        print("✅ 數據初始化成功")
        
        # 載入原始牌組文件
        with open('Decks/start01_azki.json', 'r', encoding='utf-8') as f:
            original_deck = json.load(f)
        
        print(f"原始牌組: {original_deck['deckName']}")
        print(f"原始牌組結構: {list(original_deck.keys())}")
        
        # 模擬客戶端 _set_selected 函數的處理
        client_deck = {}
        if "deck" in original_deck:
            client_deck["deck"] = original_deck["deck"]
        if "cheerDeck" in original_deck:
            client_deck["cheerDeck"] = original_deck["cheerDeck"]
        if "oshi" in original_deck:
            client_deck["oshi"] = original_deck["oshi"]
        if "deckName" in original_deck:
            client_deck["deckName"] = original_deck["deckName"]
        
        print(f"客戶端牌組結構: {list(client_deck.keys())}")
        
        # 測試原始牌組驗證
        print("\n=== 測試原始牌組驗證 ===")
        real_deck, result = check_legal(original_deck)
        if result['legal']:
            print("✅ 原始牌組驗證成功")
        else:
            print("❌ 原始牌組驗證失敗:")
            for reason in result['reasons']:
                print(f"  - {reason[0]}: {reason[1]}")
        
        # 測試客戶端牌組驗證
        print("\n=== 測試客戶端牌組驗證 ===")
        real_deck, result = check_legal(client_deck)
        if result['legal']:
            print("✅ 客戶端牌組驗證成功")
        else:
            print("❌ 客戶端牌組驗證失敗:")
            for reason in result['reasons']:
                print(f"  - {reason[0]}: {reason[1]}")
        
        # 比較兩個牌組的差異
        print("\n=== 比較牌組差異 ===")
        print(f"原始牌組字段: {set(original_deck.keys())}")
        print(f"客戶端牌組字段: {set(client_deck.keys())}")
        print(f"缺失字段: {set(original_deck.keys()) - set(client_deck.keys())}")
        print(f"額外字段: {set(client_deck.keys()) - set(original_deck.keys())}")
        
        # 檢查具體數據差異
        for key in ['oshi', 'deck', 'cheerDeck']:
            if key in original_deck and key in client_deck:
                if original_deck[key] == client_deck[key]:
                    print(f"✅ {key}: 數據一致")
                else:
                    print(f"❌ {key}: 數據不一致")
                    print(f"  原始: {original_deck[key]}")
                    print(f"  客戶端: {client_deck[key]}")
            elif key in original_deck:
                print(f"❌ {key}: 客戶端缺失")
            elif key in client_deck:
                print(f"❌ {key}: 客戶端額外")
        
    except Exception as e:
        print(f"❌ 測試失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_client_deck_format()

