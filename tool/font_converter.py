#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字體轉換工具
將woff字體轉換為tkinter可用的格式
"""

import os
import sys
from pathlib import Path

def convert_woff_to_ttf():
    """將woff字體轉換為ttf格式"""
    try:
        # 檢查是否有fonttools
        try:
            from fontTools.ttLib import TTFont
        except ImportError:
            print("需要安裝fonttools來轉換字體")
            print("請運行: pip install fonttools")
            return False
            
        woff_path = Path(__file__).parent / "NotoSans-Black.woff"
        ttf_path = Path(__file__).parent / "NotoSans-Black.ttf"
        
        if not woff_path.exists():
            print(f"找不到字體文件: {woff_path}")
            return False
            
        print(f"正在轉換字體: {woff_path}")
        
        # 讀取woff字體
        font = TTFont(woff_path)
        
        # 保存為ttf格式
        font.save(ttf_path)
        
        print(f"字體轉換完成: {ttf_path}")
        return True
        
    except Exception as e:
        print(f"字體轉換失敗: {e}")
        return False

def install_fonttools():
    """安裝fonttools"""
    try:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "fonttools"])
        print("fonttools安裝成功")
        return True
    except Exception as e:
        print(f"安裝fonttools失敗: {e}")
        return False

if __name__ == "__main__":
    print("字體轉換工具")
    print("=" * 30)
    
    # 嘗試轉換字體
    if convert_woff_to_ttf():
        print("字體轉換成功！")
    else:
        print("字體轉換失敗，嘗試安裝依賴...")
        if install_fonttools():
            print("依賴安裝成功，請重新運行此腳本")
        else:
            print("依賴安裝失敗")
