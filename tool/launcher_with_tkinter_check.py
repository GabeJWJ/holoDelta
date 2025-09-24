#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HoloDelta Enhanced Visual Launcher with tkinter detection
"""

import subprocess
import sys
import os
from pathlib import Path

def check_tkinter():
    """Check if tkinter is available"""
    try:
        import tkinter as tk
        return True, None
    except ImportError as e:
        return False, str(e)

def show_tkinter_installation_guide():
    """Show tkinter installation guide when tkinter is not available"""
    print("=" * 60)
    print("          HoloDelta Enhanced Launcher")
    print("=" * 60)
    print()
    print("❌ 錯誤：tkinter 模組不可用")
    print()
    print("tkinter 是 Python 的標準 GUI 庫，但可能未正確安裝。")
    print("請根據您的系統選擇以下解決方案：")
    print()
    print("🖥️  Windows 系統：")
    print("   1. 重新安裝 Python 並確保勾選 'tcl/tk and IDLE' 選項")
    print("   2. 或使用以下命令安裝：")
    print("      pip install tk")
    print()
    print("🐧 Linux 系統：")
    print("   Ubuntu/Debian: sudo apt-get install python3-tk")
    print("   CentOS/RHEL:   sudo yum install tkinter")
    print("   Arch Linux:    sudo pacman -S tk")
    print()
    print("🍎 macOS 系統：")
    print("   1. 使用 Homebrew: brew install python-tk")
    print("   2. 或重新安裝 Python: brew reinstall python")
    print()
    print("🔧 自動安裝嘗試：")
    print("   正在嘗試自動安裝 tkinter...")
    
    # Try to install tkinter automatically
    try:
        result = subprocess.run([sys.executable, "-m", "pip", "install", "tk"], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            print("✅ tkinter 安裝成功！")
            print("   請重新運行啟動器。")
            return True
        else:
            print("❌ 自動安裝失敗，請手動安裝。")
            print(f"   錯誤信息: {result.stderr}")
    except Exception as e:
        print(f"❌ 自動安裝過程出錯: {e}")
    
    print()
    print("🚀 備用方案：")
    print("   如果無法安裝 tkinter，請使用簡易啟動器：")
    print("   simple_launcher.bat")
    print()
    print("=" * 60)
    input("按 Enter 鍵退出...")
    return False

def launch_simple_launcher():
    """Launch the simple launcher as fallback"""
    simple_launcher_path = Path(__file__).parent / "simple_launcher.bat"
    if simple_launcher_path.exists():
        print("🚀 正在啟動簡易啟動器...")
        try:
            os.system(f'"{simple_launcher_path}"')
        except Exception as e:
            print(f"啟動簡易啟動器失敗: {e}")
    else:
        print("❌ 簡易啟動器檔案不存在")

def main():
    """Main function with tkinter detection"""
    print("🔍 正在檢查 tkinter 環境...")
    
    # Check tkinter availability
    tkinter_available, error = check_tkinter()
    
    if not tkinter_available:
        print(f"❌ tkinter 不可用: {error}")
        
        # Try to install tkinter
        if show_tkinter_installation_guide():
            # If installation was successful, try again
            print("🔄 重新檢查 tkinter...")
            tkinter_available, _ = check_tkinter()
        
        if not tkinter_available:
            # Offer to launch simple launcher
            print()
            choice = input("是否要啟動簡易啟動器？(y/n): ").lower().strip()
            if choice in ['y', 'yes', '是']:
                launch_simple_launcher()
            return
    
    # If tkinter is available, launch the enhanced launcher
    print("✅ tkinter 環境正常，正在啟動增強版啟動器...")
    try:
        # Import and run the enhanced launcher
        from holoDelta_launcher_enhanced import main as enhanced_main
        enhanced_main()
    except Exception as e:
        print(f"❌ 增強版啟動器運行失敗: {e}")
        print("🚀 正在啟動簡易啟動器作為備用方案...")
        launch_simple_launcher()

if __name__ == "__main__":
    main()
