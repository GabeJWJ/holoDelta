#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HoloDelta 繁體中文翻譯測試腳本
用於驗證翻譯檔案的完整性和正確性
"""

import os
import re
from pathlib import Path

class TranslationTester:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.card_localization_dir = self.project_root / "cardLocalization"
        self.zh_tw_file = self.card_localization_dir / "zh_TW.po"
        self.en_file = self.card_localization_dir / "en.po"
        
    def test_file_exists(self):
        """測試翻譯檔案是否存在"""
        print("🔍 檢查翻譯檔案...")
        
        if not self.zh_tw_file.exists():
            print("❌ 繁體中文翻譯檔案不存在")
            return False
            
        if not self.en_file.exists():
            print("❌ 英文翻譯檔案不存在")
            return False
            
        print("✅ 翻譯檔案存在")
        return True
        
    def test_file_format(self):
        """測試翻譯檔案格式"""
        print("\n🔍 檢查檔案格式...")
        
        try:
            with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # 檢查基本格式
            if 'msgid ""' not in content:
                print("❌ 缺少檔案標頭")
                return False
                
            if 'msgstr ""' not in content:
                print("❌ 缺少檔案標頭")
                return False
                
            # 檢查語言設定
            if 'Language: zh_TW' not in content:
                print("❌ 語言設定不正確")
                return False
                
            print("✅ 檔案格式正確")
            return True
            
        except Exception as e:
            print(f"❌ 讀取檔案時發生錯誤: {e}")
            return False
            
    def test_translation_completeness(self):
        """測試翻譯完整性"""
        print("\n🔍 檢查翻譯完整性...")
        
        try:
            # 讀取英文檔案
            with open(self.en_file, 'r', encoding='utf-8') as f:
                en_content = f.read()
                
            # 讀取繁體中文檔案
            with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
                zh_content = f.read()
                
            # 統計英文條目
            en_entries = len(re.findall(r'msgid "', en_content))
            zh_entries = len(re.findall(r'msgid "', zh_content))
            
            print(f"📊 英文條目數: {en_entries}")
            print(f"📊 中文條目數: {zh_entries}")
            
            if zh_entries < en_entries:
                print(f"⚠️  中文翻譯不完整，缺少 {en_entries - zh_entries} 個條目")
                return False
            elif zh_entries > en_entries:
                print(f"⚠️  中文翻譯條目過多，多出 {zh_entries - en_entries} 個條目")
                return False
            else:
                print("✅ 翻譯條目數量正確")
                return True
                
        except Exception as e:
            print(f"❌ 檢查翻譯完整性時發生錯誤: {e}")
            return False
            
    def test_character_names(self):
        """測試角色名稱翻譯"""
        print("\n🔍 檢查角色名稱翻譯...")
        
        test_names = [
            ("Tokino Sora", "時乃空"),
            ("Shirakami Fubuki", "白上吹雪"),
            ("Usada Pekora", "兔田佩克拉"),
            ("Houshou Marine", "寶鐘瑪琳"),
            ("AZKi", "AZKi")
        ]
        
        try:
            with open(self.zh_tw_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            all_correct = True
            for eng_name, expected_zh in test_names:
                # 搜尋角色名稱翻譯
                pattern = f'msgid "{eng_name}"\\nmsgstr "([^"]*)"'
                match = re.search(pattern, content)
                
                if match:
                    actual_zh = match.group(1)
                    if actual_zh == expected_zh:
                        print(f"✅ {eng_name} -> {actual_zh}")
                    else:
                        print(f"❌ {eng_name} -> {actual_zh} (期望: {expected_zh})")
                        all_correct = False
                else:
                    print(f"❌ 找不到 {eng_name} 的翻譯")
                    all_correct = False
                    
            return all_correct
            
        except Exception as e:
            print(f"❌ 檢查角色名稱時發生錯誤: {e}")
            return False
            
    def test_game_terms(self):
        """測試遊戲術語翻譯"""
        print("\n🔍 檢查遊戲術語翻譯...")
        
        # 檢查主要的本地化檔案
        main_zh_file = self.project_root / "Localization" / "zh_TW.po"
        
        test_terms = [
            ("STEP79", "回合"),
            ("STEP82", "生命值"),
            ("STEP84", "傷害"),
            ("STEP86", "技能"),
            ("STEP3", "應援"),
            ("STEP64", "支援"),
            ("STEP90", "綻放"),
            ("STEP34", "每回合一次"),
            ("STEP37", "本回合內")
        ]
        
        try:
            if not main_zh_file.exists():
                print("❌ 主要繁體中文本地化檔案不存在")
                return False
                
            with open(main_zh_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            all_correct = True
            for term_id, expected_zh in test_terms:
                # 搜尋術語翻譯
                pattern = f'msgid "{term_id}"\\nmsgstr "([^"]*)"'
                match = re.search(pattern, content)
                
                if match:
                    actual_zh = match.group(1)
                    if actual_zh == expected_zh:
                        print(f"✅ {term_id} -> {actual_zh}")
                    else:
                        print(f"❌ {term_id} -> {actual_zh} (期望: {expected_zh})")
                        all_correct = False
                else:
                    print(f"❌ 找不到 {term_id} 的翻譯")
                    all_correct = False
                    
            return all_correct
            
        except Exception as e:
            print(f"❌ 檢查遊戲術語時發生錯誤: {e}")
            return False
            
    def test_settings_integration(self):
        """測試設定檔案整合"""
        print("\n🔍 檢查設定檔案整合...")
        
        settings_file = self.project_root / "Scripts" / "settings.gd"
        multiplayer_file = self.project_root / "Scripts" / "Multiplayer.gd"
        
        try:
            # 檢查 settings.gd
            with open(settings_file, 'r', encoding='utf-8') as f:
                settings_content = f.read()
                
            if '["zh_TW","繁體中文"]' in settings_content:
                print("✅ settings.gd 包含繁體中文設定")
            else:
                print("❌ settings.gd 缺少繁體中文設定")
                return False
                
            # 檢查 Multiplayer.gd
            with open(multiplayer_file, 'r', encoding='utf-8') as f:
                multiplayer_content = f.read()
                
            if '"zh_TW"' in multiplayer_content:
                print("✅ Multiplayer.gd 包含繁體中文支援")
            else:
                print("❌ Multiplayer.gd 缺少繁體中文支援")
                return False
                
            return True
            
        except Exception as e:
            print(f"❌ 檢查設定檔案時發生錯誤: {e}")
            return False
            
    def run_all_tests(self):
        """執行所有測試"""
        print("🚀 開始測試 HoloDelta 繁體中文翻譯")
        print("=" * 50)
        
        tests = [
            ("檔案存在性", self.test_file_exists),
            ("檔案格式", self.test_file_format),
            ("翻譯完整性", self.test_translation_completeness),
            ("角色名稱", self.test_character_names),
            ("遊戲術語", self.test_game_terms),
            ("設定整合", self.test_settings_integration)
        ]
        
        results = []
        for test_name, test_func in tests:
            try:
                result = test_func()
                results.append((test_name, result))
            except Exception as e:
                print(f"❌ {test_name} 測試失敗: {e}")
                results.append((test_name, False))
                
        # 顯示測試結果
        print("\n" + "=" * 50)
        print("📊 測試結果摘要")
        print("=" * 50)
        
        passed = 0
        total = len(results)
        
        for test_name, result in results:
            status = "✅ 通過" if result else "❌ 失敗"
            print(f"{test_name}: {status}")
            if result:
                passed += 1
                
        print(f"\n總計: {passed}/{total} 測試通過")
        
        if passed == total:
            print("🎉 所有測試通過！繁體中文翻譯設定完成！")
        else:
            print("⚠️  部分測試失敗，請檢查上述錯誤訊息")
            
        return passed == total

def main():
    tester = TranslationTester()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎮 現在您可以在遊戲中選擇繁體中文語言了！")
        print("📖 詳細使用說明請參考: tool/TRADITIONAL_CHINESE_SETUP.md")
    else:
        print("\n🔧 請修復上述問題後重新測試")

if __name__ == "__main__":
    main()
