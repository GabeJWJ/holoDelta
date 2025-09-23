#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
holoDelta 視覺化啟動器
讓玩家可以方便地輸入IP地址並啟動伺服器和客戶端
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import subprocess
import threading
import socket
import os
import sys
import time
import json
from pathlib import Path

class HoloDeltaLauncher:
    def __init__(self, root):
        self.root = root
        self.root.title("holoDelta 遊戲啟動器")
        self.root.geometry("600x500")
        self.root.resizable(True, True)
        
        # 設定樣式
        self.setup_styles()
        
        # 伺服器進程
        self.server_process = None
        self.client_process = None
        
        # 專案根目錄
        self.project_root = Path(__file__).parent.parent
        
        # 創建界面
        self.create_widgets()
        
        # 自動獲取本機IP
        self.auto_detect_ip()
        
    def setup_styles(self):
        """設定界面樣式"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # 設定顏色
        style.configure('Title.TLabel', font=('Arial', 16, 'bold'), foreground='#2E86AB')
        style.configure('Info.TLabel', font=('Arial', 10), foreground='#666666')
        style.configure('Success.TLabel', font=('Arial', 10), foreground='#28A745')
        style.configure('Error.TLabel', font=('Arial', 10), foreground='#DC3545')
        
    def create_widgets(self):
        """創建界面元件"""
        # 主框架
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 標題
        title_label = ttk.Label(main_frame, text="holoDelta 遊戲啟動器", style='Title.TLabel')
        title_label.grid(row=0, column=0, columnspan=2, pady=(0, 20))
        
        # IP地址輸入區域
        ip_frame = ttk.LabelFrame(main_frame, text="伺服器設定", padding="10")
        ip_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Label(ip_frame, text="局域網IP地址:").grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        self.ip_var = tk.StringVar()
        self.ip_entry = ttk.Entry(ip_frame, textvariable=self.ip_var, width=20)
        self.ip_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 10))
        
        ttk.Button(ip_frame, text="自動檢測", command=self.auto_detect_ip).grid(row=0, column=2)
        
        # 端口設定
        ttk.Label(ip_frame, text="端口:").grid(row=1, column=0, sticky=tk.W, padx=(0, 10), pady=(10, 0))
        self.port_var = tk.StringVar(value="8000")
        ttk.Entry(ip_frame, textvariable=self.port_var, width=10).grid(row=1, column=1, sticky=tk.W, pady=(10, 0))
        
        # 控制按鈕區域
        control_frame = ttk.Frame(main_frame)
        control_frame.grid(row=2, column=0, columnspan=2, pady=10)
        
        self.start_server_btn = ttk.Button(control_frame, text="啟動伺服器", command=self.start_server)
        self.start_server_btn.grid(row=0, column=0, padx=(0, 10))
        
        self.start_client_btn = ttk.Button(control_frame, text="啟動客戶端", command=self.start_client)
        self.start_client_btn.grid(row=0, column=1, padx=(0, 10))
        
        self.stop_server_btn = ttk.Button(control_frame, text="停止伺服器", command=self.stop_server, state='disabled')
        self.stop_server_btn.grid(row=0, column=2, padx=(0, 10))
        
        self.stop_client_btn = ttk.Button(control_frame, text="停止客戶端", command=self.stop_client, state='disabled')
        self.stop_client_btn.grid(row=0, column=3)
        
        # 狀態顯示區域
        status_frame = ttk.LabelFrame(main_frame, text="狀態資訊", padding="10")
        status_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(10, 0))
        
        self.status_text = scrolledtext.ScrolledText(status_frame, height=15, width=70)
        self.status_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 配置網格權重
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(3, weight=1)
        ip_frame.columnconfigure(1, weight=1)
        status_frame.columnconfigure(0, weight=1)
        status_frame.rowconfigure(0, weight=1)
        
    def log_message(self, message, level="INFO"):
        """記錄訊息到狀態區域"""
        timestamp = time.strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}\n"
        
        self.status_text.insert(tk.END, log_entry)
        self.status_text.see(tk.END)
        self.root.update_idletasks()
        
    def auto_detect_ip(self):
        """自動檢測本機IP地址"""
        try:
            # 連接到外部地址來獲取本機IP
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
            
        # 檢查伺服器目錄是否存在
        server_dir = self.project_root / "ServerStuff"
        if not server_dir.exists():
            messagebox.showerror("錯誤", f"找不到伺服器目錄: {server_dir}")
            return
            
        # 在新線程中啟動伺服器
        server_thread = threading.Thread(target=self._start_server_thread, args=(ip, port))
        server_thread.daemon = True
        server_thread.start()
        
    def _start_server_thread(self, ip, port):
        """在線程中啟動伺服器"""
        try:
            self.log_message("正在啟動伺服器...")
            
            # 停止現有的伺服器進程
            if self.server_process:
                self.server_process.terminate()
                time.sleep(2)
                
            # 切換到伺服器目錄
            server_dir = self.project_root / "ServerStuff"
            os.chdir(server_dir)
            
            # 啟動伺服器
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
            
            # 更新按鈕狀態
            self.root.after(0, lambda: self.start_server_btn.config(state='disabled'))
            self.root.after(0, lambda: self.stop_server_btn.config(state='normal'))
            
            self.log_message(f"伺服器已啟動 - http://{ip}:{port}")
            self.log_message(f"WebSocket地址 - ws://{ip}:{port}/ws")
            
            # 讀取伺服器輸出
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
                self.log_message("伺服器已停止")
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                self.log_message("強制停止伺服器")
            except Exception as e:
                self.log_message(f"停止伺服器時發生錯誤: {e}", "ERROR")
            finally:
                self.server_process = None
                self.start_server_btn.config(state='normal')
                self.stop_server_btn.config(state='disabled')
                
    def start_client(self):
        """啟動客戶端"""
        # 檢查Godot是否安裝
        godot_paths = [
            "C:\\Godot\\Godot_v4.5-stable_win64.exe",
            "godot",
            "C:\\Godot\\Godot.exe"
        ]
        
        godot_exe = None
        for path in godot_paths:
            if path == "godot":
                # 檢查是否在PATH中
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
            messagebox.showerror("錯誤", "找不到Godot執行檔，請確保Godot已正確安裝")
            return
            
        # 檢查專案文件
        project_file = self.project_root / "project.godot"
        if not project_file.exists():
            messagebox.showerror("錯誤", f"找不到專案文件: {project_file}")
            return
            
        # 在新線程中啟動客戶端
        client_thread = threading.Thread(target=self._start_client_thread, args=(godot_exe,))
        client_thread.daemon = True
        client_thread.start()
        
    def _start_client_thread(self, godot_exe):
        """在線程中啟動客戶端"""
        try:
            self.log_message("正在啟動客戶端...")
            
            # 切換到專案根目錄
            os.chdir(self.project_root)
            
            # 啟動Godot客戶端
            cmd = [godot_exe, "--path", str(self.project_root), "--headless=false"]
            
            self.client_process = subprocess.Popen(cmd)
            
            # 更新按鈕狀態
            self.root.after(0, lambda: self.start_client_btn.config(state='disabled'))
            self.root.after(0, lambda: self.stop_client_btn.config(state='normal'))
            
            self.log_message("客戶端已啟動")
            
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
                self.log_message("客戶端已停止")
            except subprocess.TimeoutExpired:
                self.client_process.kill()
                self.log_message("強制停止客戶端")
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
    app = HoloDeltaLauncher(root)
    
    # 設定關閉事件
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    
    # 啟動應用程式
    root.mainloop()

if __name__ == "__main__":
    main()
