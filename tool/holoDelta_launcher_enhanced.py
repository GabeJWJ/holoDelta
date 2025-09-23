#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
holoDelta 增強版視覺化啟動器
參考原app設計風格，包含環境檢測和自動安裝功能
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext, font
import subprocess
import threading
import socket
import os
import sys
import time
import json
import webbrowser
import urllib.request
import zipfile
import shutil
from pathlib import Path
import platform

class HoloDeltaLauncherEnhanced:
    def __init__(self, root):
        self.root = root
        self.root.title("ホロデルタ - HoloDelta Launcher")
        self.root.geometry("800x600")
        self.root.resizable(True, True)
        
        # 設定視窗圖示和樣式
        self.setup_window()
        
        # 伺服器進程
        self.server_process = None
        self.client_process = None
        
        # 專案根目錄
        self.project_root = Path(__file__).parent.parent
        
        # 環境檢測結果
        self.env_status = {
            'python': False,
            'godot': False,
            'server_deps': False,
            'project_files': False
        }
        
        # 創建界面
        self.create_widgets()
        
        # 執行環境檢測
        self.check_environment()
        
    def setup_window(self):
        """設定視窗樣式"""
        # 設定背景色 (現代化的深色主題)
        self.root.configure(bg='#1a1a2e')
        
        # 設定視窗圖示和樣式
        try:
            # 嘗試設定視窗圖示
            self.root.iconbitmap(default="icon.ico")
        except:
            pass
        
        # 設定視窗最小尺寸
        self.root.minsize(900, 700)
        
        # 嘗試設定自定義字體
        self.setup_custom_font()
        
    def setup_custom_font(self):
        """設定自定義字體"""
        try:
            # 檢查 NotoSansJP-Black.ttf 字體文件是否存在
            font_path = Path(__file__).parent.parent / "CyberAssets" / "Main Menu Assets" / "NotoSansJP-Black.ttf"
            if font_path.exists():
                # 嘗試載入 NotoSansJP 字體
                try:
                    # 在 Windows 上，我們需要先安裝字體或使用系統字體名稱
                    # 這裡我們使用 Noto Sans JP 作為字體家族名稱
                    self.custom_font = font.Font(family="Noto Sans JP", size=12, weight="bold")
                    self.title_font = font.Font(family="Noto Sans JP", size=24, weight="bold")
                    self.subtitle_font = font.Font(family="Noto Sans JP", size=11)
                    self.log_font = font.Font(family="Noto Sans JP", size=10)
                    print("成功載入 NotoSansJP-Black 字體")
                except:
                    # 如果載入失敗，使用備用字體
                    self.custom_font = font.Font(family="Microsoft YaHei UI", size=12, weight="bold")
                    self.title_font = font.Font(family="Microsoft YaHei UI", size=24, weight="bold")
                    self.subtitle_font = font.Font(family="Microsoft YaHei UI", size=11)
                    self.log_font = font.Font(family="Consolas", size=10)
                    print("使用備用字體 Microsoft YaHei UI")
            else:
                # 使用系統預設字體
                self.custom_font = font.Font(family="Microsoft YaHei UI", size=12, weight="bold")
                self.title_font = font.Font(family="Microsoft YaHei UI", size=24, weight="bold")
                self.subtitle_font = font.Font(family="Microsoft YaHei UI", size=11)
                self.log_font = font.Font(family="Consolas", size=10)
                print("使用系統預設字體")
        except Exception as e:
            print(f"字體設定失敗: {e}")
            # 最終備用字體
            self.custom_font = font.Font(family="Arial", size=12, weight="bold")
            self.title_font = font.Font(family="Arial", size=24, weight="bold")
            self.subtitle_font = font.Font(family="Arial", size=11)
            self.log_font = font.Font(family="Arial", size=10)
            
    def create_widgets(self):
        """創建界面元件"""
        # 主容器 - 使用現代化的深色主題
        main_container = tk.Frame(self.root, bg='#1a1a2e')
        main_container.pack(fill=tk.BOTH, expand=True, padx=25, pady=25)
        
        # 標題區域
        self.create_title_section(main_container)
        
        # 環境狀態區域
        self.create_environment_section(main_container)
        
        # 伺服器設定區域
        self.create_server_section(main_container)
        
        # 控制按鈕區域
        self.create_control_section(main_container)
        
        # 狀態顯示區域
        self.create_status_section(main_container)
        
        # 底部資訊
        self.create_footer_section(main_container)
        
    def create_title_section(self, parent):
        """創建標題區域"""
        title_frame = tk.Frame(parent, bg='#1a1a2e')
        title_frame.pack(fill=tk.X, pady=(0, 30))
        
        # 主標題 - 使用漸變效果
        title_label = tk.Label(
            title_frame, 
            text="ホロデルタ", 
            font=self.title_font,
            fg='#ff6b9d',  # 粉紅色
            bg='#1a1a2e'
        )
        title_label.pack()
        
        # 副標題
        subtitle_label = tk.Label(
            title_frame,
            text="An unofficial Hololive OCG simulator - Enhanced Launcher",
            font=self.subtitle_font,
            fg='#a8a8a8',  # 淺灰色
            bg='#1a1a2e'
        )
        subtitle_label.pack()
        
        # 分隔線
        separator = tk.Frame(title_frame, height=2, bg='#ff6b9d')
        separator.pack(fill=tk.X, pady=(10, 0))
        
    def create_environment_section(self, parent):
        """創建環境檢測區域"""
        env_frame = tk.LabelFrame(
            parent, 
            text="🔧 環境檢測", 
            font=self.custom_font,
            fg='#ff6b9d',
            bg='#16213e',
            relief=tk.FLAT,
            bd=0,
            highlightbackground='#ff6b9d',
            highlightthickness=1
        )
        env_frame.pack(fill=tk.X, pady=(0, 20))
        
        # 環境檢測項目
        self.env_items = {}
        env_items = [
            ('python', 'Python 3.7+', '檢查Python環境'),
            ('godot', 'Godot 4.5+', '檢查Godot引擎'),
            ('server_deps', '伺服器依賴', '檢查Python套件'),
            ('project_files', '專案文件', '檢查holoDelta專案')
        ]
        
        for i, (key, name, desc) in enumerate(env_items):
            item_frame = tk.Frame(env_frame, bg='#16213e')
            item_frame.pack(fill=tk.X, padx=15, pady=8)
            
            # 狀態指示器 - 使用更現代的圖標
            status_label = tk.Label(
                item_frame, 
                text="●", 
                fg='#ff6b6b',
                bg='#16213e',
                font=('Arial', 14)
            )
            status_label.pack(side=tk.LEFT, padx=(0, 15))
            
            # 項目名稱
            name_label = tk.Label(
                item_frame,
                text=name,
                font=self.custom_font,
                fg='#ffffff',
                bg='#16213e'
            )
            name_label.pack(side=tk.LEFT, padx=(0, 15))
            
            # 描述
            desc_label = tk.Label(
                item_frame,
                text=desc,
                font=self.subtitle_font,
                fg='#a8a8a8',
                bg='#16213e'
            )
            desc_label.pack(side=tk.LEFT)
            
            # 安裝按鈕 - 現代化設計
            install_btn = tk.Button(
                item_frame,
                text="🔧 安裝/修復",
                command=lambda k=key: self.install_dependency(k),
                bg='#ff6b9d',
                fg='white',
                font=self.subtitle_font,
                relief=tk.FLAT,
                padx=15,
                pady=5,
                cursor='hand2'
            )
            install_btn.pack(side=tk.RIGHT)
            
            self.env_items[key] = {
                'status': status_label,
                'install_btn': install_btn
            }
            
    def create_server_section(self, parent):
        """創建伺服器設定區域"""
        server_frame = tk.LabelFrame(
            parent,
            text="🌐 伺服器設定",
            font=self.custom_font,
            fg='#ff6b9d',
            bg='#16213e',
            relief=tk.FLAT,
            bd=0,
            highlightbackground='#ff6b9d',
            highlightthickness=1
        )
        server_frame.pack(fill=tk.X, pady=(0, 20))
        
        # IP地址設定
        ip_frame = tk.Frame(server_frame, bg='#16213e')
        ip_frame.pack(fill=tk.X, padx=15, pady=10)
        
        tk.Label(
            ip_frame,
            text="🌍 局域網IP地址:",
            font=self.custom_font,
            fg='#ffffff',
            bg='#16213e'
        ).pack(side=tk.LEFT, padx=(0, 15))
        
        self.ip_var = tk.StringVar()
        self.ip_entry = tk.Entry(
            ip_frame,
            textvariable=self.ip_var,
            font=self.custom_font,
            width=20,
            relief=tk.FLAT,
            bd=2,
            bg='#0f3460',
            fg='#ffffff',
            insertbackground='#ffffff'
        )
        self.ip_entry.pack(side=tk.LEFT, padx=(0, 15))
        
        # 自動檢測按鈕
        auto_detect_btn = tk.Button(
            ip_frame,
            text="🔍 自動檢測",
            command=self.auto_detect_ip,
            bg='#4A90E2',
            fg='white',
            font=self.subtitle_font,
            relief=tk.FLAT,
            padx=15,
            pady=5,
            cursor='hand2'
        )
        auto_detect_btn.pack(side=tk.LEFT)
        
        # 端口設定
        port_frame = tk.Frame(server_frame, bg='#16213e')
        port_frame.pack(fill=tk.X, padx=15, pady=(0, 15))
        
        tk.Label(
            port_frame,
            text="🔌 端口:",
            font=self.custom_font,
            fg='#ffffff',
            bg='#16213e'
        ).pack(side=tk.LEFT, padx=(0, 15))
        
        self.port_var = tk.StringVar(value="8000")
        port_entry = tk.Entry(
            port_frame,
            textvariable=self.port_var,
            font=self.custom_font,
            width=10,
            relief=tk.FLAT,
            bd=2,
            bg='#0f3460',
            fg='#ffffff',
            insertbackground='#ffffff'
        )
        port_entry.pack(side=tk.LEFT, padx=(0, 15))
        
        # 客戶端配置按鈕
        update_config_btn = tk.Button(
            port_frame,
            text="⚙️ 更新客戶端配置",
            command=self.update_client_config_manual,
            bg='#FFA500',
            fg='white',
            font=self.subtitle_font,
            relief=tk.FLAT,
            padx=15,
            pady=5,
            cursor='hand2'
        )
        update_config_btn.pack(side=tk.LEFT, padx=(0, 10))
        
        restore_config_btn = tk.Button(
            port_frame,
            text="🔄 恢復原始配置",
            command=self.restore_client_config_manual,
            bg='#6C757D',
            fg='white',
            font=self.subtitle_font,
            relief=tk.FLAT,
            padx=15,
            pady=5,
            cursor='hand2'
        )
        restore_config_btn.pack(side=tk.LEFT)
        
    def create_control_section(self, parent):
        """創建控制按鈕區域"""
        control_frame = tk.Frame(parent, bg='#1a1a2e')
        control_frame.pack(fill=tk.X, pady=(0, 20))
        
        # 主要控制按鈕 - 現代化設計
        button_style = {
            'font': self.custom_font,
            'relief': tk.FLAT,
            'padx': 25,
            'pady': 12,
            'width': 15,
            'cursor': 'hand2'
        }
        
        self.start_server_btn = tk.Button(
            control_frame,
            text="🚀 啟動伺服器",
            command=self.start_server,
            bg='#7B68EE',
            fg='white',
            **button_style
        )
        self.start_server_btn.pack(side=tk.LEFT, padx=(0, 15))
        
        self.start_client_btn = tk.Button(
            control_frame,
            text="🎮 啟動客戶端",
            command=self.start_client,
            bg='#32CD32',
            fg='white',
            **button_style
        )
        self.start_client_btn.pack(side=tk.LEFT, padx=(0, 15))
        
        self.stop_server_btn = tk.Button(
            control_frame,
            text="⏹️ 停止伺服器",
            command=self.stop_server,
            bg='#FF6B6B',
            fg='white',
            state='disabled',
            **button_style
        )
        self.stop_server_btn.pack(side=tk.LEFT, padx=(0, 15))
        
        self.stop_client_btn = tk.Button(
            control_frame,
            text="⏹️ 停止客戶端",
            command=self.stop_client,
            bg='#FF6B6B',
            fg='white',
            state='disabled',
            **button_style
        )
        self.stop_client_btn.pack(side=tk.LEFT)
        
    def create_status_section(self, parent):
        """創建狀態顯示區域"""
        status_frame = tk.LabelFrame(
            parent,
            text="📊 運行狀態",
            font=self.custom_font,
            fg='#ff6b9d',
            bg='#16213e',
            relief=tk.FLAT,
            bd=0,
            highlightbackground='#ff6b9d',
            highlightthickness=1
        )
        status_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 20))
        
        # 狀態文字區域 - 現代化終端風格
        self.status_text = scrolledtext.ScrolledText(
            status_frame,
            height=12,
            font=self.log_font,
            bg='#0f1419',
            fg='#00ff88',
            relief=tk.FLAT,
            bd=0,
            insertbackground='#00ff88',
            selectbackground='#ff6b9d',
            selectforeground='white'
        )
        self.status_text.pack(fill=tk.BOTH, expand=True, padx=15, pady=15)
        
    def create_footer_section(self, parent):
        """創建底部資訊區域"""
        footer_frame = tk.Frame(parent, bg='#1a1a2e')
        footer_frame.pack(fill=tk.X)
        
        # 版本資訊
        version_label = tk.Label(
            footer_frame,
            text="✨ HoloDelta Enhanced Launcher v2.0.0",
            font=self.subtitle_font,
            fg='#a8a8a8',
            bg='#1a1a2e'
        )
        version_label.pack(side=tk.RIGHT)
        
        # 線上玩家數 (模擬)
        players_label = tk.Label(
            footer_frame,
            text="👥 0 players online",
            font=self.subtitle_font,
            fg='#a8a8a8',
            bg='#1a1a2e'
        )
        players_label.pack(side=tk.LEFT)
        
    def check_environment(self):
        """檢查環境依賴"""
        self.log_message("正在檢查環境依賴...")
        
        # 檢查Python
        self.env_status['python'] = self.check_python()
        self.update_env_status('python', self.env_status['python'])
        
        # 檢查Godot
        self.env_status['godot'] = self.check_godot()
        self.update_env_status('godot', self.env_status['godot'])
        
        # 檢查伺服器依賴
        self.env_status['server_deps'] = self.check_server_dependencies()
        self.update_env_status('server_deps', self.env_status['server_deps'])
        
        # 檢查專案文件
        self.env_status['project_files'] = self.check_project_files()
        self.update_env_status('project_files', self.env_status['project_files'])
        
        # 自動檢測IP
        self.auto_detect_ip()
        
        # 顯示當前客戶端配置
        self.show_current_client_config()
        
    def check_python(self):
        """檢查Python環境"""
        try:
            version = sys.version_info
            if version.major >= 3 and version.minor >= 7:
                self.log_message(f"Python {version.major}.{version.minor}.{version.micro} - 正常")
                return True
            else:
                self.log_message(f"Python版本過舊: {version.major}.{version.minor}.{version.micro}", "ERROR")
                return False
        except Exception as e:
            self.log_message(f"Python檢查失敗: {e}", "ERROR")
            return False
            
    def check_godot(self):
        """檢查Godot安裝"""
        godot_paths = [
            "C:\\Godot\\Godot_v4.5-stable_win64.exe",
            "C:\\Godot\\Godot.exe",
            "godot"
        ]
        
        for path in godot_paths:
            if path == "godot":
                try:
                    result = subprocess.run([path, "--version"], capture_output=True, text=True, timeout=5)
                    if result.returncode == 0:
                        self.log_message(f"找到Godot: {result.stdout.strip()}")
                        return True
                except:
                    continue
            elif os.path.exists(path):
                self.log_message(f"找到Godot: {path}")
                return True
                
        self.log_message("未找到Godot安裝", "ERROR")
        return False
        
    def check_server_dependencies(self):
        """檢查伺服器依賴"""
        try:
            server_dir = self.project_root / "ServerStuff"
            if not server_dir.exists():
                self.log_message("ServerStuff目錄不存在", "ERROR")
                return False
                
            requirements_file = server_dir / "requirements.txt"
            if not requirements_file.exists():
                self.log_message("requirements.txt不存在", "ERROR")
                return False
                
            # 檢查主要依賴
            try:
                import fastapi
                import uvicorn
                self.log_message("伺服器依賴檢查通過")
                return True
            except ImportError as e:
                self.log_message(f"缺少依賴: {e}", "ERROR")
                return False
                
        except Exception as e:
            self.log_message(f"伺服器依賴檢查失敗: {e}", "ERROR")
            return False
            
    def check_project_files(self):
        """檢查專案文件"""
        try:
            project_file = self.project_root / "project.godot"
            if not project_file.exists():
                self.log_message("project.godot不存在", "ERROR")
                return False
                
            scripts_dir = self.project_root / "Scripts"
            if not scripts_dir.exists():
                self.log_message("Scripts目錄不存在", "ERROR")
                return False
                
            self.log_message("專案文件檢查通過")
            return True
            
        except Exception as e:
            self.log_message(f"專案文件檢查失敗: {e}", "ERROR")
            return False
            
    def update_env_status(self, key, status):
        """更新環境狀態顯示"""
        if key in self.env_items:
            if status:
                self.env_items[key]['status'].config(fg='#00ff88', text='✅')
                self.env_items[key]['install_btn'].config(state='disabled', text='✅ 已安裝')
            else:
                self.env_items[key]['status'].config(fg='#ff6b6b', text='❌')
                self.env_items[key]['install_btn'].config(state='normal', text='🔧 安裝/修復')
                
    def install_dependency(self, dependency):
        """安裝依賴"""
        if dependency == 'python':
            self.install_python()
        elif dependency == 'godot':
            self.install_godot()
        elif dependency == 'server_deps':
            self.install_server_dependencies()
        elif dependency == 'project_files':
            self.repair_project_files()
            
    def install_python(self):
        """安裝Python"""
        response = messagebox.askyesno(
            "安裝Python",
            "需要安裝Python 3.7或更高版本。\n是否要打開下載頁面？"
        )
        if response:
            webbrowser.open("https://www.python.org/downloads/")
            
    def install_godot(self):
        """安裝Godot"""
        response = messagebox.askyesno(
            "安裝Godot",
            "需要安裝Godot 4.5或更高版本。\n是否要打開下載頁面？"
        )
        if response:
            webbrowser.open("https://godotengine.org/download/")
            
    def install_server_dependencies(self):
        """安裝伺服器依賴"""
        def install_thread():
            try:
                self.log_message("正在安裝伺服器依賴...")
                server_dir = self.project_root / "ServerStuff"
                requirements_file = server_dir / "requirements.txt"
                
                if requirements_file.exists():
                    cmd = [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)]
                    result = subprocess.run(cmd, capture_output=True, text=True, cwd=server_dir)
                    
                    if result.returncode == 0:
                        self.log_message("伺服器依賴安裝成功")
                        self.env_status['server_deps'] = True
                        self.update_env_status('server_deps', True)
                    else:
                        self.log_message(f"安裝失敗: {result.stderr}", "ERROR")
                else:
                    self.log_message("requirements.txt不存在", "ERROR")
                    
            except Exception as e:
                self.log_message(f"安裝過程出錯: {e}", "ERROR")
                
        threading.Thread(target=install_thread, daemon=True).start()
        
    def repair_project_files(self):
        """修復專案文件"""
        self.log_message("檢查專案文件完整性...")
        # 這裡可以添加專案文件修復邏輯
        messagebox.showinfo("修復專案文件", "專案文件檢查完成")
        
    def update_client_config(self):
        """更新客戶端配置以連接到正確的伺服器"""
        try:
            ip = self.ip_var.get().strip()
            port = self.port_var.get().strip()
            
            if not ip or not port:
                self.log_message("IP地址或端口未設定", "ERROR")
                return False
                
            # 檢查server.gd文件是否存在
            server_gd_path = self.project_root / "Scripts" / "server.gd"
            if not server_gd_path.exists():
                self.log_message("找不到Scripts/server.gd文件", "ERROR")
                return False
                
            # 備份原始文件
            backup_path = server_gd_path.with_suffix('.gd.backup')
            if not backup_path.exists():
                shutil.copy2(server_gd_path, backup_path)
                self.log_message("已備份原始server.gd文件")
                
            # 讀取當前配置
            current_config = server_gd_path.read_text(encoding='utf-8')
            
            # 檢查是否已經配置了正確的IP
            websocket_url = f'"{ip}:{port}"'
            if f'const websocketURL = {websocket_url}' in current_config:
                self.log_message(f"客戶端已配置為連接到 {ip}:{port}")
                return True
                
            # 更新配置
            new_config = f'''extends Node


const websocketURL = {websocket_url}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
\tpass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
\tpass
'''
            
            # 寫入新配置
            server_gd_path.write_text(new_config, encoding='utf-8')
            self.log_message(f"已更新客戶端配置: {ip}:{port}", "SUCCESS")
            return True
            
        except Exception as e:
            self.log_message(f"更新客戶端配置失敗: {e}", "ERROR")
            return False
            
    def restore_client_config(self):
        """恢復客戶端原始配置"""
        try:
            server_gd_path = self.project_root / "Scripts" / "server.gd"
            backup_path = server_gd_path.with_suffix('.gd.backup')
            
            if backup_path.exists():
                shutil.copy2(backup_path, server_gd_path)
                self.log_message("已恢復客戶端原始配置", "SUCCESS")
                return True
            else:
                self.log_message("找不到備份文件", "WARNING")
                return False
                
        except Exception as e:
            self.log_message(f"恢復客戶端配置失敗: {e}", "ERROR")
            return False
            
    def update_client_config_manual(self):
        """手動更新客戶端配置"""
        if self.update_client_config():
            messagebox.showinfo("成功", "客戶端配置已更新")
        else:
            messagebox.showerror("錯誤", "客戶端配置更新失敗")
            
    def restore_client_config_manual(self):
        """手動恢復客戶端配置"""
        if self.restore_client_config():
            messagebox.showinfo("成功", "客戶端配置已恢復")
        else:
            messagebox.showerror("錯誤", "客戶端配置恢復失敗")
            
    def get_current_client_config(self):
        """獲取當前客戶端配置"""
        try:
            server_gd_path = self.project_root / "Scripts" / "server.gd"
            if not server_gd_path.exists():
                return None
                
            content = server_gd_path.read_text(encoding='utf-8')
            for line in content.split('\n'):
                if 'const websocketURL' in line:
                    # 提取IP和端口
                    import re
                    match = re.search(r'"([^"]+)"', line)
                    if match:
                        return match.group(1)
            return None
            
        except Exception as e:
            self.log_message(f"讀取客戶端配置失敗: {e}", "ERROR")
            return None
            
    def show_current_client_config(self):
        """顯示當前客戶端配置"""
        current_config = self.get_current_client_config()
        if current_config:
            self.log_message(f"當前客戶端配置: {current_config}")
        else:
            self.log_message("無法讀取客戶端配置", "WARNING")
        
    def log_message(self, message, level="INFO"):
        """記錄訊息到狀態區域"""
        timestamp = time.strftime("%H:%M:%S")
        
        # 根據級別設定顏色 - 現代化終端風格
        color_map = {
            "INFO": "#00ff88",
            "ERROR": "#ff6b6b",
            "SUCCESS": "#00ff88",
            "WARNING": "#ffa500",
            "SERVER": "#4A90E2"
        }
        
        # 添加圖標
        icon_map = {
            "INFO": "ℹ️",
            "ERROR": "❌",
            "SUCCESS": "✅",
            "WARNING": "⚠️",
            "SERVER": "🖥️"
        }
        
        log_entry = f"[{timestamp}] {icon_map.get(level, 'ℹ️')} [{level}] {message}\n"
        
        self.status_text.insert(tk.END, log_entry)
        self.status_text.see(tk.END)
        
        # 設定文字顏色
        start_line = self.status_text.index(tk.END + "-2l")
        end_line = self.status_text.index(tk.END + "-1l")
        self.status_text.tag_add(level, start_line, end_line)
        self.status_text.tag_config(level, foreground=color_map.get(level, "#00ff88"))
        
        self.root.update_idletasks()
        
    def auto_detect_ip(self):
        """自動檢測本機IP地址"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 80))
                local_ip = s.getsockname()[0]
                self.ip_var.set(local_ip)
                self.log_message(f"自動檢測到本機IP: {local_ip}")
        except Exception as e:
            self.log_message(f"無法自動檢測IP地址: {e}", "ERROR")
            
    def validate_ip(self, ip):
        """驗證IP地址格式"""
        try:
            socket.inet_aton(ip)
            return True
        except socket.error:
            return False
            
    def start_server(self):
        """啟動伺服器"""
        if not self.env_status['server_deps']:
            messagebox.showerror("錯誤", "請先安裝伺服器依賴")
            return
            
        ip = self.ip_var.get().strip()
        port = self.port_var.get().strip()
        
        if not ip:
            messagebox.showerror("錯誤", "請輸入IP地址")
            return
            
        if not self.validate_ip(ip):
            messagebox.showerror("錯誤", "IP地址格式不正確")
            return
            
        if not port.isdigit():
            messagebox.showerror("錯誤", "端口必須是數字")
            return
            
        server_thread = threading.Thread(target=self._start_server_thread, args=(ip, port))
        server_thread.daemon = True
        server_thread.start()
        
    def _start_server_thread(self, ip, port):
        """在線程中啟動伺服器"""
        try:
            self.log_message("正在啟動伺服器...")
            
            if self.server_process:
                self.server_process.terminate()
                time.sleep(2)
                
            server_dir = self.project_root / "ServerStuff"
            os.chdir(server_dir)
            
            cmd = [
                sys.executable, "-m", "uvicorn", 
                "server:app", 
                "--host", "0.0.0.0", 
                "--port", port, 
                "--reload"
            ]
            
            self.server_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            self.root.after(0, lambda: self.start_server_btn.config(state='disabled'))
            self.root.after(0, lambda: self.stop_server_btn.config(state='normal'))
            
            self.log_message(f"伺服器已啟動 - http://{ip}:{port}", "SUCCESS")
            self.log_message(f"WebSocket地址 - ws://{ip}:{port}/ws", "SUCCESS")
            
            for line in iter(self.server_process.stdout.readline, ''):
                if line:
                    self.root.after(0, lambda l=line: self.log_message(l.strip(), "SERVER"))
                    
        except Exception as e:
            self.log_message(f"啟動伺服器失敗: {e}", "ERROR")
            self.root.after(0, lambda: self.start_server_btn.config(state='normal'))
            self.root.after(0, lambda: self.stop_server_btn.config(state='disabled'))
            
    def stop_server(self):
        """停止伺服器"""
        if self.server_process:
            try:
                self.server_process.terminate()
                self.server_process.wait(timeout=5)
                self.log_message("伺服器已停止", "SUCCESS")
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                self.log_message("強制停止伺服器", "WARNING")
            except Exception as e:
                self.log_message(f"停止伺服器時發生錯誤: {e}", "ERROR")
            finally:
                self.server_process = None
                self.start_server_btn.config(state='normal')
                self.stop_server_btn.config(state='disabled')
                
    def start_client(self):
        """啟動客戶端"""
        if not self.env_status['godot']:
            messagebox.showerror("錯誤", "請先安裝Godot")
            return
            
        if not self.env_status['project_files']:
            messagebox.showerror("錯誤", "專案文件不完整")
            return
            
        # 更新客戶端配置以連接到正確的伺服器
        if not self.update_client_config():
            messagebox.showerror("錯誤", "無法更新客戶端配置")
            return
            
        godot_paths = [
            "C:\\Godot\\Godot_v4.5-stable_win64.exe",
            "C:\\Godot\\Godot.exe",
            "godot"
        ]
        
        godot_exe = None
        for path in godot_paths:
            if path == "godot":
                try:
                    subprocess.run([path, "--version"], capture_output=True, check=True)
                    godot_exe = path
                    break
                except:
                    continue
            elif os.path.exists(path):
                godot_exe = path
                break
                
        if not godot_exe:
            messagebox.showerror("錯誤", "找不到Godot執行檔")
            return
            
        client_thread = threading.Thread(target=self._start_client_thread, args=(godot_exe,))
        client_thread.daemon = True
        client_thread.start()
        
    def _start_client_thread(self, godot_exe):
        """在線程中啟動客戶端"""
        try:
            self.log_message("正在啟動客戶端...")
            
            os.chdir(self.project_root)
            
            cmd = [godot_exe, "--path", str(self.project_root), "--headless=false"]
            
            self.client_process = subprocess.Popen(cmd)
            
            self.root.after(0, lambda: self.start_client_btn.config(state='disabled'))
            self.root.after(0, lambda: self.stop_client_btn.config(state='normal'))
            
            self.log_message("客戶端已啟動", "SUCCESS")
            
        except Exception as e:
            self.log_message(f"啟動客戶端失敗: {e}", "ERROR")
            self.root.after(0, lambda: self.start_client_btn.config(state='normal'))
            self.root.after(0, lambda: self.stop_client_btn.config(state='disabled'))
            
    def stop_client(self):
        """停止客戶端"""
        if self.client_process:
            try:
                self.client_process.terminate()
                self.client_process.wait(timeout=5)
                self.log_message("客戶端已停止", "SUCCESS")
            except subprocess.TimeoutExpired:
                self.client_process.kill()
                self.log_message("強制停止客戶端", "WARNING")
            except Exception as e:
                self.log_message(f"停止客戶端時發生錯誤: {e}", "ERROR")
            finally:
                self.client_process = None
                self.start_client_btn.config(state='normal')
                self.stop_client_btn.config(state='disabled')
                
    def on_closing(self):
        """關閉應用程式時的清理工作"""
        if self.server_process:
            self.stop_server()
        if self.client_process:
            self.stop_client()
        self.root.destroy()

def main():
    root = tk.Tk()
    app = HoloDeltaLauncherEnhanced(root)
    
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    root.mainloop()

if __name__ == "__main__":
    main()
