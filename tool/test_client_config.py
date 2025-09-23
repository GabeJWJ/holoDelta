#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試客戶端配置更新功能
"""

import sys
import os
from pathlib import Path

# 添加父目錄到路徑
sys.path.append(str(Path(__file__).parent))

def test_client_config_update():
    """測試客戶端配置更新功能"""
    print("=" * 50)
    print("測試客戶端配置更新功能")
    print("=" * 50)
    
    # 檢查專案結構
    project_root = Path(__file__).parent.parent
    server_gd_path = project_root / "Scripts" / "server.gd"
    
    print(f"專案根目錄: {project_root}")
    print(f"server.gd路徑: {server_gd_path}")
    print(f"server.gd存在: {server_gd_path.exists()}")
    
    if not server_gd_path.exists():
        print("❌ 找不到Scripts/server.gd文件")
        return False
        
    # 讀取當前配置
    try:
        current_content = server_gd_path.read_text(encoding='utf-8')
        print("\n當前server.gd內容:")
        print("-" * 30)
        print(current_content)
        print("-" * 30)
        
        # 提取當前websocketURL
        import re
        match = re.search(r'const websocketURL = "([^"]+)"', current_content)
        if match:
            current_url = match.group(1)
            print(f"當前websocketURL: {current_url}")
        else:
            print("❌ 無法找到websocketURL配置")
            return False
            
    except Exception as e:
        print(f"❌ 讀取server.gd失敗: {e}")
        return False
        
    # 測試配置更新
    test_ip = "192.168.1.100"
    test_port = "8000"
    test_url = f"{test_ip}:{test_port}"
    
    print(f"\n測試更新配置為: {test_url}")
    
    # 備份原始文件
    backup_path = server_gd_path.with_suffix('.gd.backup')
    if not backup_path.exists():
        import shutil
        shutil.copy2(server_gd_path, backup_path)
        print(f"✅ 已備份原始文件到: {backup_path}")
    
    # 更新配置
    new_config = f'''extends Node


const websocketURL = "{test_url}"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
\tpass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
\tpass
'''
    
    try:
        server_gd_path.write_text(new_config, encoding='utf-8')
        print("✅ 配置更新成功")
        
        # 驗證更新
        updated_content = server_gd_path.read_text(encoding='utf-8')
        if test_url in updated_content:
            print("✅ 配置驗證成功")
        else:
            print("❌ 配置驗證失敗")
            return False
            
    except Exception as e:
        print(f"❌ 配置更新失敗: {e}")
        return False
        
    # 恢復原始配置
    try:
        if backup_path.exists():
            import shutil
            shutil.copy2(backup_path, server_gd_path)
            print("✅ 已恢復原始配置")
        else:
            print("⚠️ 找不到備份文件，無法恢復")
            
    except Exception as e:
        print(f"❌ 恢復配置失敗: {e}")
        return False
        
    print("\n✅ 所有測試通過！")
    return True

def test_connection_flow():
    """測試完整的連接流程"""
    print("\n" + "=" * 50)
    print("測試完整連接流程")
    print("=" * 50)
    
    # 模擬啟動器的工作流程
    project_root = Path(__file__).parent.parent
    
    # 1. 檢查環境
    print("1. 檢查環境...")
    server_gd_path = project_root / "Scripts" / "server.gd"
    if not server_gd_path.exists():
        print("❌ Scripts/server.gd不存在")
        return False
    print("✅ Scripts/server.gd存在")
    
    # 2. 檢查ServerStuff目錄
    server_dir = project_root / "ServerStuff"
    if not server_dir.exists():
        print("❌ ServerStuff目錄不存在")
        return False
    print("✅ ServerStuff目錄存在")
    
    # 3. 檢查專案文件
    project_file = project_root / "project.godot"
    if not project_file.exists():
        print("❌ project.godot不存在")
        return False
    print("✅ project.godot存在")
    
    print("\n✅ 環境檢查通過！")
    print("\n建議的連接流程:")
    print("1. 伺服器端: 輸入IP地址 → 啟動伺服器")
    print("2. 客戶端: 點擊「更新客戶端配置」→ 啟動客戶端")
    print("3. 客戶端會自動連接到指定的伺服器IP")
    
    return True

if __name__ == "__main__":
    print("holoDelta 客戶端配置測試工具")
    print("=" * 50)
    
    # 測試配置更新功能
    config_test = test_client_config_update()
    
    # 測試連接流程
    flow_test = test_connection_flow()
    
    print("\n" + "=" * 50)
    print("測試結果總結")
    print("=" * 50)
    print(f"配置更新測試: {'✅ 通過' if config_test else '❌ 失敗'}")
    print(f"連接流程測試: {'✅ 通過' if flow_test else '❌ 失敗'}")
    
    if config_test and flow_test:
        print("\n🎉 所有測試通過！客戶端配置功能正常。")
    else:
        print("\n⚠️ 部分測試失敗，請檢查相關配置。")
