#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import sys
import os

# 添加 ServerStuff 到路徑
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ServerStuff'))

from globals.data import initialize, get_data
from utils.deck_validator import check_legal

def test_websocket_deck_validation():
    print("=== 測試 WebSocket 牌組驗證 ===")
    
    try:
        # 初始化數據
        initialize()
        print("✅ 數據初始化成功")
        
        # 載入測試牌組
        with open('Decks/start01_azki.json', 'r', encoding='utf-8') as f:
            deck_data = json.load(f)
        
        print(f"測試牌組: {deck_data['deckName']}")
        
        # 模擬 WebSocket 接收到的數據格式
        websocket_message = {
            "supertype": "Lobby",
            "command": "Ready",
            "data": {
                "deck": deck_data
            }
        }
        
        print(f"WebSocket 消息: {json.dumps(websocket_message, indent=2)}")
        
        # 提取牌組數據
        received_deck = websocket_message["data"]["deck"]
        print(f"接收到的牌組: {received_deck['deckName']}")
        
        # 模擬伺服器端驗證邏輯
        banlist = get_data("current_banlist")
        only_en = False
        
        print(f"使用禁卡列表: {len(banlist)} 項")
        print(f"僅英文模式: {only_en}")
        
        # 執行驗證
        real_deck, deck_legality = check_legal(received_deck, banlist, only_en)
        
        print(f"\n驗證結果:")
        print(f"合法: {deck_legality['legal']}")
        print(f"原因數量: {len(deck_legality['reasons'])}")
        
        if deck_legality['legal']:
            print("✅ 牌組驗證成功！")
            print(f"主牌組: {len(real_deck['deck'])} 張")
            print(f"應援牌組: {len(real_deck['cheerDeck'])} 張")
        else:
            print("❌ 牌組驗證失敗:")
            for reason in deck_legality['reasons']:
                print(f"  - {reason[0]}: {reason[1]}")
        
        # 檢查特定卡片
        print(f"\n=== 檢查特定卡片 ===")
        test_cards = ['hSD01-002', 'hSD01-003', 'hY01-001']
        card_data = get_data('card_data')
        
        for card_id in test_cards:
            if card_id in card_data:
                card_info = card_data[card_id]
                print(f"✅ {card_id}: {card_info.get('cardType', '未知')}")
            else:
                print(f"❌ {card_id}: 不存在")
        
    except Exception as e:
        print(f"❌ 測試失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_websocket_deck_validation()

