#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os

# 添加 ServerStuff 到路徑
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ServerStuff'))

# 重新導入模組
from globals.data import initialize, get_data
from utils.card_utils import card_info

def test_card_info():
    print("=== 測試 card_info 函數 ===")
    
    try:
        # 初始化數據
        initialize()
        print("✅ 數據初始化成功")
        
        # 檢查數據狀態
        card_data = get_data('card_data')
        print(f"✅ 卡片數據載入: {len(card_data)} 張卡片")
        
        # 測試特定卡片
        test_cards = ['hSD01-001', 'hSD01-002', 'hY01-001', 'hBP01-021']
        
        for card_id in test_cards:
            print(f"\n測試卡片: {card_id}")
            
            # 直接檢查
            if card_id in card_data:
                direct_result = card_data[card_id]
                print(f"  直接訪問: ✅ {direct_result.get('cardType', '未知')}")
            else:
                print(f"  直接訪問: ❌ 不存在")
            
            # 通過 card_info 函數
            card_info_result = card_info(card_id)
            if 'cardType' in card_info_result:
                print(f"  card_info: ✅ {card_info_result['cardType']}")
            else:
                print(f"  card_info: ❌ 無效")
        
        # 測試牌組驗證
        print("\n=== 測試牌組驗證 ===")
        from utils.deck_validator import check_legal
        import json
        
        with open('Decks/start01_azki.json', 'r', encoding='utf-8') as f:
            deck = json.load(f)
        
        real_deck, result = check_legal(deck)
        
        if result['legal']:
            print("✅ 牌組驗證成功！")
        else:
            print("❌ 牌組驗證失敗:")
            for reason in result['reasons']:
                print(f"  - {reason[0]}: {reason[1]}")
        
    except Exception as e:
        print(f"❌ 測試失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_card_info()

