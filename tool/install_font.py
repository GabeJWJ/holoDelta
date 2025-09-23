#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字體安裝工具
用於安裝 NotoSansJP-Black.ttf 字體到系統中
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

def install_font():
    """安裝字體到系統"""
    try:
        # 字體文件路徑
        font_path = Path(__file__).parent.parent / "CyberAssets" / "Main Menu Assets" / "NotoSansJP-Black.ttf"
        
        if not font_path.exists():
            print("❌ 找不到 NotoSansJP-Black.ttf 字體文件")
            return False
            
        # Windows 字體目錄
        if sys.platform == "win32":
            fonts_dir = Path(os.environ['WINDIR']) / 'Fonts'
            target_path = fonts_dir / "NotoSansJP-Black.ttf"
            
            print(f"📁 字體目錄: {fonts_dir}")
            print(f"📄 字體文件: {font_path}")
            
            # 複製字體文件
            if not target_path.exists():
                shutil.copy2(font_path, target_path)
                print("✅ 字體文件已複製到系統字體目錄")
            else:
                print("ℹ️ 字體文件已存在於系統中")
                
            # 嘗試註冊字體
            try:
                subprocess.run([
                    "reg", "add", 
                    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts",
                    "/v", "Noto Sans JP Black (TrueType)",
                    "/t", "REG_SZ",
                    "/d", "NotoSansJP-Black.ttf",
                    "/f"
                ], check=True, capture_output=True)
                print("✅ 字體已註冊到系統")
            except subprocess.CalledProcessError:
                print("⚠️ 字體註冊失敗，但文件已複製")
                
        else:
            print("❌ 此腳本僅支援 Windows 系統")
            return False
            
        print("🎉 字體安裝完成！")
        print("💡 請重新啟動啟動器以使用新字體")
        return True
        
    except Exception as e:
        print(f"❌ 字體安裝失敗: {e}")
        return False

def check_font():
    """檢查字體是否已安裝"""
    try:
        import tkinter as tk
        from tkinter import font
        
        # 獲取系統字體列表
        root = tk.Tk()
        fonts = font.families()
        root.destroy()
        
        # 檢查 Noto Sans JP 字體
        noto_fonts = [f for f in fonts if 'noto' in f.lower() and 'sans' in f.lower()]
        
        if noto_fonts:
            print("✅ 找到 Noto Sans 字體:")
            for f in noto_fonts:
                print(f"   - {f}")
            return True
        else:
            print("❌ 未找到 Noto Sans 字體")
            return False
            
    except Exception as e:
        print(f"❌ 字體檢查失敗: {e}")
        return False

def main():
    print("🔤 HoloDelta 字體安裝工具")
    print("=" * 40)
    
    # 檢查字體
    print("\n📋 檢查字體狀態...")
    if check_font():
        print("✅ 字體已安裝，無需重複安裝")
        return
    
    # 安裝字體
    print("\n📦 開始安裝字體...")
    if install_font():
        print("\n🎉 字體安裝成功！")
        print("💡 建議重新啟動啟動器以確保字體正常顯示")
    else:
        print("\n❌ 字體安裝失敗")
        print("💡 請手動將 NotoSansJP-Black.ttf 複製到 C:\\Windows\\Fonts\\ 目錄")

if __name__ == "__main__":
    main()
    input("\n按 Enter 鍵退出...")
