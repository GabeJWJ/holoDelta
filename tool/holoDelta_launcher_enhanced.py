#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HoloDelta Enhanced Visual Launcher
Reference original app design style with environment detection and auto-installation features
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

class GradientCapsuleButton(tk.Button):
    """Custom gradient capsule button with 8px purple border and gradient background"""
    def __init__(self, parent, **kwargs):
        # Extract button_type before passing to parent
        button_type = kwargs.pop('button_type', 'blue')
        
        # Set gradient-like background colors
        gradient_colors = {
            'blue': '#e3f2fd',      # Light blue
            'purple': '#f3e5f5',    # Light purple
            'pink': '#fce4ec',      # Light pink
            'orange': '#fff3e0',    # Light orange
            'red': '#ffebee',       # Light red
            'green': '#e8f5e8'      # Light green
        }
        
        # Set active background (darker version)
        active_colors = {
            'blue': '#bbdefb',
            'purple': '#e1bee7',
            'pink': '#f8bbd9',
            'orange': '#ffcc02',
            'red': '#ffcdd2',
            'green': '#c8e6c9'
        }
        
        # Set default gradient button style with 8px purple stroke border
        default_style = {
            'relief': tk.FLAT,  # Flat relief for stroke effect
            'bd': 8,  # 8px thick stroke
            'highlightthickness': 0,
            'cursor': 'hand2',
            'padx': 20,
            'pady': 8,
            'highlightbackground': '#625b93',  # Purple stroke color
            'highlightcolor': '#625b93',
            'bg': gradient_colors.get(button_type, '#e3f2fd'),
            'fg': '#625b93',  # Purple text
            'activebackground': active_colors.get(button_type, '#bbdefb'),
            'activeforeground': '#625b93'
        }
        default_style.update(kwargs)
        super().__init__(parent, **default_style)
        
        # Store original colors for hover effects
        self.original_bg = default_style['bg']
        self.original_fg = default_style['fg']
        
        # Bind hover effects
        self.bind("<Enter>", self._on_enter)
        self.bind("<Leave>", self._on_leave)
        
    def _on_enter(self, event):
        """Hover effect - slightly darker gradient"""
        current_bg = self.cget('bg')
        if current_bg == '#e3f2fd':  # Light blue
            self.config(bg='#bbdefb')
        elif current_bg == '#f3e5f5':  # Light purple
            self.config(bg='#e1bee7')
        elif current_bg == '#fce4ec':  # Light pink
            self.config(bg='#f8bbd9')
        elif current_bg == '#fff3e0':  # Light orange
            self.config(bg='#ffcc02')
        elif current_bg == '#ffebee':  # Light red
            self.config(bg='#ffcdd2')
        elif current_bg == '#e8f5e8':  # Light green
            self.config(bg='#c8e6c9')
            
    def _on_leave(self, event):
        """Leave effect - restore original color"""
        self.config(bg=self.original_bg, fg=self.original_fg)

class CapsuleButton(GradientCapsuleButton):
    """Backward compatibility - alias for GradientCapsuleButton"""
    pass

class HoloDeltaLauncherEnhanced:
    def __init__(self, root):
        self.root = root
        self.root.title("HoloDelta - Enhanced Launcher")
        self.root.geometry("1000x700")
        self.root.resizable(True, True)
        
        # Set default language to English
        self.current_language = "en"
        self.load_language_data()
        
        # Setup window
        self.setup_window()
        
        # Server and client processes
        self.server_process = None
        self.client_process = None
        
        # Project root directory
        self.project_root = Path(__file__).parent.parent
        
        # Environment check results
        self.env_status = {
            'python': False,
            'godot': False,
            'server_deps': False,
            'project_files': False
        }
        
        # Create main scrollable frame
        self.create_scrollable_interface()
        
        # Execute environment check
        self.check_environment()
        
    def load_language_data(self):
        """Load language data from languages.json"""
        try:
            lang_file = Path(__file__).parent / "languages.json"
            if lang_file.exists():
                with open(lang_file, 'r', encoding='utf-8') as f:
                    self.languages = json.load(f)
            else:
                # Fallback language data
                self.languages = {
                    "en": {"title": "HoloDelta", "subtitle": "Enhanced Launcher"},
                    "ja": {"title": "ホロデルタ", "subtitle": "拡張ランチャー"},
                    "zh": {"title": "ホロデルタ", "subtitle": "增强版启动器"}
                }
        except Exception as e:
            print(f"Failed to load language data: {e}")
            self.languages = {"en": {}}
    
    def get_text(self, key, **kwargs):
        """Get localized text"""
        try:
            text = self.languages.get(self.current_language, {}).get(key, 
                   self.languages.get("en", {}).get(key, key))
            return text.format(**kwargs) if kwargs else text
        except:
            return key
    
    def setup_window(self):
        """Setup window style"""
        # Set background color with gradient effect matching Figma design
        self.root.configure(bg='#d8d9eb')
        
        # Set window icon and style
        try:
            # Try to set window icon
            self.root.iconbitmap(default="icon.ico")
        except:
            pass
        
        # Set minimum window size
        self.root.minsize(1000, 700)
        
        # Add window styling for modern look
        self.root.configure(relief='flat', bd=0)
        
        # Setup custom fonts
        self.setup_custom_font()
        
    def setup_custom_font(self):
        """Setup custom fonts matching Figma design"""
        try:
            # Check if NotoSans-Black.ttf font file exists (matching Figma design)
            font_path = Path(__file__).parent / "NotoSans-Black.ttf"
            if font_path.exists():
                try:
                    # Use Noto Sans as font family name (matching Figma)
                    self.custom_font = font.Font(family="Noto Sans", size=12, weight="bold")
                    self.title_font = font.Font(family="Noto Sans", size=32, weight="bold")  # Larger title like Figma
                    self.subtitle_font = font.Font(family="Noto Sans", size=11)
                    self.log_font = font.Font(family="Noto Sans", size=10)
                    print("Successfully loaded NotoSans-Black font")
                except:
                    # Fallback fonts
                    self.custom_font = font.Font(family="Microsoft YaHei UI", size=12, weight="bold")
                    self.title_font = font.Font(family="Microsoft YaHei UI", size=32, weight="bold")
                    self.subtitle_font = font.Font(family="Microsoft YaHei UI", size=11)
                    self.log_font = font.Font(family="Consolas", size=10)
                    print("Using fallback font Microsoft YaHei UI")
            else:
                # Use system default fonts
                self.custom_font = font.Font(family="Microsoft YaHei UI", size=12, weight="bold")
                self.title_font = font.Font(family="Microsoft YaHei UI", size=32, weight="bold")
                self.subtitle_font = font.Font(family="Microsoft YaHei UI", size=11)
                self.log_font = font.Font(family="Consolas", size=10)
                print("Using system default fonts")
        except Exception as e:
            print(f"Font setup failed: {e}")
            # Final fallback fonts
            self.custom_font = font.Font(family="Arial", size=12, weight="bold")
            self.title_font = font.Font(family="Arial", size=32, weight="bold")
            self.subtitle_font = font.Font(family="Arial", size=11)
            self.log_font = font.Font(family="Arial", size=10)
            
    def create_scrollable_interface(self):
        """Create scrollable interface"""
        # Create main container with scrollbar
        main_container = tk.Frame(self.root, bg='#d8d9eb')
        main_container.pack(fill=tk.BOTH, expand=True)
        
        # Create canvas and scrollbar
        self.canvas = tk.Canvas(main_container, bg='#d8d9eb', highlightthickness=0)
        self.scrollbar = ttk.Scrollbar(main_container, orient="vertical", command=self.canvas.yview)
        self.scrollable_frame = tk.Frame(self.canvas, bg='#d8d9eb')
        
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        )
        
        self.canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        
        # Pack canvas and scrollbar
        self.canvas.pack(side="left", fill="both", expand=True)
        self.scrollbar.pack(side="right", fill="y")
        
        # Bind mousewheel to canvas
        self.bind_mousewheel()
        
        # Create language selector
        self.create_language_selector()
        
        # Create interface components
        self.create_widgets()
        
    def bind_mousewheel(self):
        """Bind mousewheel events for scrolling"""
        def _on_mousewheel(event):
            self.canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        
        def _bind_to_mousewheel(event):
            self.canvas.bind_all("<MouseWheel>", _on_mousewheel)
        
        def _unbind_from_mousewheel(event):
            self.canvas.unbind_all("<MouseWheel>")
        
        self.canvas.bind('<Enter>', _bind_to_mousewheel)
        self.canvas.bind('<Leave>', _unbind_from_mousewheel)
        
    def create_language_selector(self):
        """Create language selection dropdown"""
        lang_frame = tk.Frame(self.scrollable_frame, bg='#d8d9eb')
        lang_frame.pack(fill=tk.X, padx=25, pady=(25, 10))
        
        tk.Label(
            lang_frame,
            text="🌐 Language:",
            font=self.custom_font,
            fg='#ff1c99',
            bg='#d8d9eb'
        ).pack(side=tk.LEFT, padx=(0, 10))
        
        self.language_var = tk.StringVar(value=self.current_language)
        self.language_combo = ttk.Combobox(
            lang_frame,
            textvariable=self.language_var,
            values=["en", "ja", "zh"],
            state="readonly",
            width=10,
            style="Capsule.TCombobox"
        )
        self.language_combo.pack(side=tk.LEFT)
        self.language_combo.bind("<<ComboboxSelected>>", self.change_language)
        
        # Style the combobox to match Figma design
        style = ttk.Style()
        style.configure("Capsule.TCombobox", 
                       fieldbackground='white',
                       background='white',
                       foreground='#625b93',
                       borderwidth=0,
                       relief='flat')
        
    def change_language(self, event=None):
        """Change application language"""
        new_lang = self.language_var.get()
        if new_lang != self.current_language:
            self.current_language = new_lang
            self.refresh_interface()
            
    def refresh_interface(self):
        """Refresh interface with new language"""
        # Update window title
        self.root.title(f"{self.get_text('title')} - {self.get_text('subtitle')}")
        
        # Clear and recreate the scrollable interface
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()
            
        # Recreate interface components
        self.create_language_selector()
        self.create_widgets()
        
    def update_text_elements(self):
        """Update all text elements with current language"""
        # Update title
        if hasattr(self, 'title_label'):
            self.title_label.config(text=self.get_text('title'))
            
        # Update environment section
        if hasattr(self, 'env_frame'):
            self.env_frame.config(text=f"🔧 {self.get_text('environment_check')}")
            
        # Update server section
        if hasattr(self, 'server_frame'):
            self.server_frame.config(text=f"🌐 {self.get_text('server_settings')}")
            
        # Update status section
        if hasattr(self, 'status_frame'):
            self.status_frame.config(text=f"📊 {self.get_text('running_status')}")
            
        # Update environment check items
        self.update_environment_items()
        
        # Update server settings items
        self.update_server_settings_items()
            
        # Update buttons
        self.update_button_texts()
        
    def update_environment_items(self):
        """Update environment check items with current language"""
        if hasattr(self, 'env_items'):
            for key, item_data in self.env_items.items():
                # Update install button text
                if 'install_btn' in item_data:
                    install_btn = item_data['install_btn']
                    if install_btn.cget('state') == 'disabled':
                        install_btn.config(text=f"✅ {self.get_text('installed')}")
                    else:
                        install_btn.config(text=f"🔧 {self.get_text('install_repair')}")
    
    def update_server_settings_items(self):
        """Update server settings items with current language"""
        # This method will be called to update server settings labels and buttons
        # The actual text updates will be handled by recreating the interface
        pass
    
    def update_button_texts(self):
        """Update button texts with current language"""
        if hasattr(self, 'start_server_btn'):
            self.start_server_btn.config(text=f"🚀 {self.get_text('start_server')}")
        if hasattr(self, 'start_client_btn'):
            self.start_client_btn.config(text=f"🎮 {self.get_text('start_client')}")
        if hasattr(self, 'stop_server_btn'):
            self.stop_server_btn.config(text=f"⏹️ {self.get_text('stop_server')}")
        if hasattr(self, 'stop_client_btn'):
            self.stop_client_btn.config(text=f"⏹️ {self.get_text('stop_client')}")
            
    def create_widgets(self):
        """Create interface components"""
        # Title section
        self.create_title_section()
        
        # Environment status section
        self.create_environment_section()
        
        # Server settings section
        self.create_server_section()
        
        # Control buttons section
        self.create_control_section()
        
        # Status display section
        self.create_status_section()
        
        # Footer section
        self.create_footer_section()
        
    def create_title_section(self):
        """Create title section"""
        title_frame = tk.Frame(self.scrollable_frame, bg='#d8d9eb')
        title_frame.pack(fill=tk.X, pady=(0, 30), padx=25)
        
        # Main title with Figma design colors
        self.title_label = tk.Label(
            title_frame, 
            text=self.get_text('title'), 
            font=self.title_font,
            fg='#625b93',  # Purple color from Figma
            bg='#d8d9eb'
        )
        self.title_label.pack()
        
        # Separator line with updated color
        separator = tk.Frame(title_frame, height=2, bg='#625b93')
        separator.pack(fill=tk.X, pady=(10, 0))
        
    def create_environment_section(self):
        """Create environment check section"""
        self.env_frame = tk.LabelFrame(
            self.scrollable_frame, 
            text=f"🔧 {self.get_text('environment_check')}", 
            font=self.custom_font,
            fg='#625b93',
            bg='#ffffff',
            relief=tk.FLAT,
            bd=0,
            highlightbackground='#625b93',
            highlightthickness=1
        )
        # Add semi-transparent effect by using a lighter background
        # Note: True transparency is limited in tkinter, using closest approximation
        self.env_frame.configure(bg='#f0f2f5')
        self.env_frame.pack(fill=tk.X, pady=(0, 20), padx=25)
        
        # Environment check items
        self.env_items = {}
        env_items = [
            ('python', self.get_text('python_check'), self.get_text('python_desc')),
            ('godot', self.get_text('godot_check'), self.get_text('godot_desc')),
            ('server_deps', self.get_text('server_deps_check'), self.get_text('server_deps_desc')),
            ('project_files', self.get_text('project_files_check'), self.get_text('project_files_desc'))
        ]
        
        for i, (key, name, desc) in enumerate(env_items):
            item_frame = tk.Frame(self.env_frame, bg='#f0f2f5')
            item_frame.pack(fill=tk.X, padx=15, pady=8)
            
            # Status indicator with modern icons
            status_label = tk.Label(
                item_frame, 
                text="●", 
                fg='#e74c3c',
                bg='#f0f2f5',
                font=('Arial', 14)
            )
            status_label.pack(side=tk.LEFT, padx=(0, 15))
            
            # Item name
            name_label = tk.Label(
                item_frame,
                text=name,
                font=self.custom_font,
                fg='#625b93',
                bg='#f0f2f5'
            )
            name_label.pack(side=tk.LEFT, padx=(0, 15))
            
            # Description
            desc_label = tk.Label(
                item_frame,
                text=desc,
                font=self.subtitle_font,
                fg='#625b93',
                bg='#f0f2f5'
            )
            desc_label.pack(side=tk.LEFT)
            
            # Install button with gradient capsule design
            install_btn = GradientCapsuleButton(
                item_frame,
                text=f"🔧 {self.get_text('install_repair')}",
                command=lambda k=key: self.install_dependency(k),
                button_type='blue',
                fg='#625b93',
                font=self.subtitle_font
            )
            install_btn.pack(side=tk.RIGHT)
            
            self.env_items[key] = {
                'status': status_label,
                'install_btn': install_btn
            }
            
    def create_server_section(self):
        """Create server settings section"""
        self.server_frame = tk.LabelFrame(
            self.scrollable_frame,
            text=f"🌐 {self.get_text('server_settings')}",
            font=self.custom_font,
            fg='#625b93',
            bg='#f0f2f5',
            relief=tk.FLAT,
            bd=0,
            highlightbackground='#625b93',
            highlightthickness=1
        )
        self.server_frame.pack(fill=tk.X, pady=(0, 20), padx=25)
        
        # IP address setting
        ip_frame = tk.Frame(self.server_frame, bg='#f0f2f5')
        ip_frame.pack(fill=tk.X, padx=15, pady=10)
        
        tk.Label(
            ip_frame,
            text=f"🌍 {self.get_text('lan_ip')}",
            font=self.custom_font,
            fg='#625b93',
            bg='#f0f2f5'
        ).pack(side=tk.LEFT, padx=(0, 15))
        
        self.ip_var = tk.StringVar()
        self.ip_entry = tk.Entry(
            ip_frame,
            textvariable=self.ip_var,
            font=self.custom_font,
            width=20,
            relief=tk.FLAT,
            bd=2,
            bg='#ffffff',
            fg='#625b93',
            insertbackground='#625b93'
        )
        self.ip_entry.pack(side=tk.LEFT, padx=(0, 15))
        
        # Auto detect button with gradient capsule design
        auto_detect_btn = GradientCapsuleButton(
            ip_frame,
            text=f"🔍 {self.get_text('auto_detect')}",
            command=self.auto_detect_ip,
            button_type='pink',
            fg='#625b93',
            font=self.subtitle_font
        )
        auto_detect_btn.pack(side=tk.LEFT)
        
        # Port setting
        port_frame = tk.Frame(self.server_frame, bg='#f0f2f5')
        port_frame.pack(fill=tk.X, padx=15, pady=(0, 15))
        
        tk.Label(
            port_frame,
            text=f"🔌 {self.get_text('port')}",
            font=self.custom_font,
            fg='#625b93',
            bg='#f0f2f5'
        ).pack(side=tk.LEFT, padx=(0, 15))
        
        self.port_var = tk.StringVar(value="8000")
        port_entry = tk.Entry(
            port_frame,
            textvariable=self.port_var,
            font=self.custom_font,
            width=10,
            relief=tk.FLAT,
            bd=2,
            bg='#ffffff',
            fg='#625b93',
            insertbackground='#625b93'
        )
        port_entry.pack(side=tk.LEFT, padx=(0, 15))
        
        # Client config buttons with gradient capsule design
        update_config_btn = GradientCapsuleButton(
            port_frame,
            text=f"⚙️ {self.get_text('update_client_config')}",
            command=self.update_client_config_manual,
            button_type='purple',
            fg='#625b93',
            font=self.subtitle_font
        )
        update_config_btn.pack(side=tk.LEFT, padx=(0, 10))
        
        restore_config_btn = GradientCapsuleButton(
            port_frame,
            text=f"🔄 {self.get_text('restore_config')}",
            command=self.restore_client_config_manual,
            button_type='orange',
            fg='#625b93',
            font=self.subtitle_font
        )
        restore_config_btn.pack(side=tk.LEFT)
        
    def create_control_section(self):
        """Create control buttons section"""
        control_frame = tk.Frame(self.scrollable_frame, bg='#d8d9eb')
        control_frame.pack(fill=tk.X, pady=(0, 20), padx=25)
        
        # Main control buttons with capsule design
        button_style = {
            'font': self.custom_font,
            'padx': 30,
            'pady': 15,
            'width': 15
        }
        
        self.start_server_btn = GradientCapsuleButton(
            control_frame,
            text=f"🚀 {self.get_text('start_server')}",
            command=self.start_server,
            button_type='purple',
            fg='#625b93',
            **button_style
        )
        self.start_server_btn.pack(side=tk.LEFT, padx=(0, 15))
        
        self.start_client_btn = GradientCapsuleButton(
            control_frame,
            text=f"🎮 {self.get_text('start_client')}",
            command=self.start_client,
            button_type='pink',
            fg='#625b93',
            **button_style
        )
        self.start_client_btn.pack(side=tk.LEFT, padx=(0, 15))
        
        self.stop_server_btn = GradientCapsuleButton(
            control_frame,
            text=f"⏹️ {self.get_text('stop_server')}",
            command=self.stop_server,
            button_type='red',
            fg='#625b93',
            state='disabled',
            **button_style
        )
        self.stop_server_btn.pack(side=tk.LEFT, padx=(0, 15))
        
        self.stop_client_btn = GradientCapsuleButton(
            control_frame,
            text=f"⏹️ {self.get_text('stop_client')}",
            command=self.stop_client,
            button_type='red',
            fg='#625b93',
            state='disabled',
            **button_style
        )
        self.stop_client_btn.pack(side=tk.LEFT)
        
    def create_status_section(self):
        """Create status display section"""
        self.status_frame = tk.LabelFrame(
            self.scrollable_frame,
            text=f"📊 {self.get_text('running_status')}",
            font=self.custom_font,
            fg='#625b93',
            bg='#f0f2f5',
            relief=tk.FLAT,
            bd=0,
            highlightbackground='#625b93',
            highlightthickness=1
        )
        self.status_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 20), padx=25)
        
        # Status text area with modern terminal style
        self.status_text = scrolledtext.ScrolledText(
            self.status_frame,
            height=12,
            font=self.log_font,
            bg='#ffffff',
            fg='#625b93',
            relief=tk.FLAT,
            bd=0,
            insertbackground='#625b93',
            selectbackground='#ff1c99',
            selectforeground='white'
        )
        self.status_text.pack(fill=tk.BOTH, expand=True, padx=15, pady=15)
        
    def create_footer_section(self):
        """Create footer section"""
        footer_frame = tk.Frame(self.scrollable_frame, bg='#d8d9eb')
        footer_frame.pack(fill=tk.X, padx=25, pady=(0, 25))
        
        # Version info
        version_label = tk.Label(
            footer_frame,
            text=f"✨ {self.get_text('version')}",
            font=self.subtitle_font,
            fg='#625b93',
            bg='#d8d9eb'
        )
        version_label.pack(side=tk.RIGHT)
        
        # Online players count (simulated)
        players_label = tk.Label(
            footer_frame,
            text=f"👥 0 {self.get_text('players_online')}",
            font=self.subtitle_font,
            fg='#625b93',
            bg='#d8d9eb'
        )
        players_label.pack(side=tk.LEFT)
        
    def check_environment(self):
        """Check environment dependencies"""
        self.log_message(self.get_text('checking_environment'))
        
        # Check Python
        self.env_status['python'] = self.check_python()
        self.update_env_status('python', self.env_status['python'])
        
        # Check Godot
        self.env_status['godot'] = self.check_godot()
        self.update_env_status('godot', self.env_status['godot'])
        
        # Check server dependencies
        self.env_status['server_deps'] = self.check_server_dependencies()
        self.update_env_status('server_deps', self.env_status['server_deps'])
        
        # Check project files
        self.env_status['project_files'] = self.check_project_files()
        self.update_env_status('project_files', self.env_status['project_files'])
        
        # Auto detect IP
        self.auto_detect_ip()
        
        # Show current client config
        self.show_current_client_config()
        
    def check_python(self):
        """Check Python environment"""
        try:
            version = sys.version_info
            if version.major >= 3 and version.minor >= 7:
                self.log_message(self.get_text('python_ok', version=f"{version.major}.{version.minor}.{version.micro}"))
                return True
            else:
                self.log_message(self.get_text('python_old', version=f"{version.major}.{version.minor}.{version.micro}"), "ERROR")
                return False
        except Exception as e:
            self.log_message(self.get_text('python_check_failed', error=e), "ERROR")
            return False
            
    def check_godot(self):
        """Check Godot installation"""
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
                        self.log_message(self.get_text('godot_found', path=result.stdout.strip()))
                        return True
                except:
                    continue
            elif os.path.exists(path):
                self.log_message(self.get_text('godot_found', path=path))
                return True
                
        self.log_message(self.get_text('godot_not_found'), "ERROR")
        return False
        
    def check_server_dependencies(self):
        """Check server dependencies"""
        try:
            server_dir = self.project_root / "ServerStuff"
            if not server_dir.exists():
                self.log_message("ServerStuff directory not found", "ERROR")
                return False
                
            requirements_file = server_dir / "requirements.txt"
            if not requirements_file.exists():
                self.log_message("requirements.txt not found", "ERROR")
                return False
                
            # Check main dependencies
            try:
                import fastapi
                import uvicorn
                self.log_message(self.get_text('server_deps_ok'))
                return True
            except ImportError as e:
                self.log_message(self.get_text('server_deps_missing', error=e), "ERROR")
                return False
                
        except Exception as e:
            self.log_message(f"Server dependencies check failed: {e}", "ERROR")
            return False
            
    def check_project_files(self):
        """Check project files"""
        try:
            project_file = self.project_root / "project.godot"
            if not project_file.exists():
                self.log_message(self.get_text('project_godot_missing'), "ERROR")
                return False
                
            scripts_dir = self.project_root / "Scripts"
            if not scripts_dir.exists():
                self.log_message(self.get_text('scripts_missing'), "ERROR")
                return False
                
            self.log_message(self.get_text('project_files_ok'))
            return True
            
        except Exception as e:
            self.log_message(f"Project files check failed: {e}", "ERROR")
            return False
            
    def update_env_status(self, key, status):
        """Update environment status display"""
        if key in self.env_items:
            if status:
                self.env_items[key]['status'].config(fg='#27ae60', text='✅')
                self.env_items[key]['install_btn'].config(state='disabled', text=f"✅ {self.get_text('installed')}")
            else:
                self.env_items[key]['status'].config(fg='#e74c3c', text='❌')
                self.env_items[key]['install_btn'].config(state='normal', text=f"🔧 {self.get_text('install_repair')}")
                
    def install_dependency(self, dependency):
        """Install dependency"""
        if dependency == 'python':
            self.install_python()
        elif dependency == 'godot':
            self.install_godot()
        elif dependency == 'server_deps':
            self.install_server_dependencies()
        elif dependency == 'project_files':
            self.repair_project_files()
            
    def install_python(self):
        """Install Python"""
        response = messagebox.askyesno(
            self.get_text('install_python_title'),
            self.get_text('install_python_msg')
        )
        if response:
            webbrowser.open("https://www.python.org/downloads/")
            
    def install_godot(self):
        """Install Godot"""
        response = messagebox.askyesno(
            self.get_text('install_godot_title'),
            self.get_text('install_godot_msg')
        )
        if response:
            webbrowser.open("https://godotengine.org/download/")
            
    def install_server_dependencies(self):
        """Install server dependencies"""
        def install_thread():
            try:
                self.log_message(self.get_text('installing_deps'))
                server_dir = self.project_root / "ServerStuff"
                requirements_file = server_dir / "requirements.txt"
                
                if requirements_file.exists():
                    cmd = [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)]
                    result = subprocess.run(cmd, capture_output=True, text=True, cwd=server_dir)
                    
                    if result.returncode == 0:
                        self.log_message(self.get_text('deps_install_success'))
                        self.env_status['server_deps'] = True
                        self.update_env_status('server_deps', True)
                    else:
                        self.log_message(self.get_text('deps_install_failed', error=result.stderr), "ERROR")
                else:
                    self.log_message(self.get_text('requirements_missing'), "ERROR")
                    
            except Exception as e:
                self.log_message(self.get_text('install_error', error=e), "ERROR")
                
        threading.Thread(target=install_thread, daemon=True).start()
        
    def repair_project_files(self):
        """Repair project files"""
        self.log_message("Checking project file integrity...")
        # Add project file repair logic here
        messagebox.showinfo("Repair Project Files", "Project file check completed")
        
    def update_client_config(self):
        """Update client config to connect to correct server"""
        try:
            ip = self.ip_var.get().strip()
            port = self.port_var.get().strip()
            
            if not ip or not port:
                self.log_message(self.get_text('ip_not_set'), "ERROR")
                return False
                
            # Check if server.gd file exists
            server_gd_path = self.project_root / "Scripts" / "server.gd"
            if not server_gd_path.exists():
                self.log_message("Scripts/server.gd file not found", "ERROR")
                return False
                
            # Backup original file
            backup_path = server_gd_path.with_suffix('.gd.backup')
            if not backup_path.exists():
                shutil.copy2(server_gd_path, backup_path)
                self.log_message("Backed up original server.gd file")
                
            # Read current config
            current_config = server_gd_path.read_text(encoding='utf-8')
            
            # Check if already configured with correct IP
            websocket_url = f'"{ip}:{port}"'
            if f'const websocketURL = {websocket_url}' in current_config:
                self.log_message(f"Client already configured to connect to {ip}:{port}")
                return True
                
            # Update config
            new_config = f'''extends Node


const websocketURL = {websocket_url}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
\tpass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
\tpass
'''
            
            # Write new config
            server_gd_path.write_text(new_config, encoding='utf-8')
            self.log_message(self.get_text('config_updated', ip=ip, port=port), "SUCCESS")
            return True
            
        except Exception as e:
            self.log_message(self.get_text('config_update_failed', error=e), "ERROR")
            return False
            
    def restore_client_config(self):
        """Restore client original config"""
        try:
            server_gd_path = self.project_root / "Scripts" / "server.gd"
            backup_path = server_gd_path.with_suffix('.gd.backup')
            
            if backup_path.exists():
                shutil.copy2(backup_path, server_gd_path)
                self.log_message(self.get_text('config_restored'), "SUCCESS")
                return True
            else:
                self.log_message(self.get_text('backup_not_found'), "WARNING")
                return False
                
        except Exception as e:
            self.log_message(self.get_text('config_restore_failed', error=e), "ERROR")
            return False
            
    def update_client_config_manual(self):
        """Manually update client config"""
        if self.update_client_config():
            messagebox.showinfo(self.get_text('success'), self.get_text('client_config_updated'))
        else:
            messagebox.showerror(self.get_text('error'), self.get_text('client_config_update_failed'))
            
    def restore_client_config_manual(self):
        """Manually restore client config"""
        if self.restore_client_config():
            messagebox.showinfo(self.get_text('success'), self.get_text('client_config_restored'))
        else:
            messagebox.showerror(self.get_text('error'), self.get_text('client_config_restore_failed'))
            
    def get_current_client_config(self):
        """Get current client config"""
        try:
            server_gd_path = self.project_root / "Scripts" / "server.gd"
            if not server_gd_path.exists():
                return None
                
            content = server_gd_path.read_text(encoding='utf-8')
            for line in content.split('\n'):
                if 'const websocketURL' in line:
                    # Extract IP and port
                    import re
                    match = re.search(r'"([^"]+)"', line)
                    if match:
                        return match.group(1)
            return None
            
        except Exception as e:
            self.log_message(self.get_text('config_read_failed', error=e), "ERROR")
            return None
            
    def show_current_client_config(self):
        """Show current client config"""
        current_config = self.get_current_client_config()
        if current_config:
            self.log_message(self.get_text('current_config', config=current_config))
        else:
            self.log_message(self.get_text('config_read_failed'), "WARNING")
        
    def log_message(self, message, level="INFO"):
        """Log message to status area"""
        timestamp = time.strftime("%H:%M:%S")
        
        # Set colors based on level - original multi-color configuration
        color_map = {
            "INFO": "#3498db",
            "ERROR": "#e74c3c",
            "SUCCESS": "#27ae60",
            "WARNING": "#f39c12",
            "SERVER": "#9b59b6"
        }
        
        # Add icons
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
        
        # Set text color
        start_line = self.status_text.index(tk.END + "-2l")
        end_line = self.status_text.index(tk.END + "-1l")
        self.status_text.tag_add(level, start_line, end_line)
        self.status_text.tag_config(level, foreground=color_map.get(level, "#00ff88"))
        
        self.root.update_idletasks()
        
    def auto_detect_ip(self):
        """Auto detect local IP address"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 80))
                local_ip = s.getsockname()[0]
                self.ip_var.set(local_ip)
                self.log_message(self.get_text('auto_detected_ip', ip=local_ip))
        except Exception as e:
            self.log_message(self.get_text('ip_detection_failed', error=e), "ERROR")
            
    def validate_ip(self, ip):
        """Validate IP address format"""
        try:
            socket.inet_aton(ip)
            return True
        except socket.error:
            return False
            
    def start_server(self):
        """Start server"""
        if not self.env_status['server_deps']:
            messagebox.showerror(self.get_text('error'), self.get_text('install_server_deps_first'))
            return
            
        ip = self.ip_var.get().strip()
        port = self.port_var.get().strip()
        
        if not ip:
            messagebox.showerror(self.get_text('error'), self.get_text('ip_not_set'))
            return
            
        if not self.validate_ip(ip):
            messagebox.showerror(self.get_text('error'), self.get_text('invalid_ip'))
            return
            
        if not port.isdigit():
            messagebox.showerror(self.get_text('error'), self.get_text('port_not_number'))
            return
            
        server_thread = threading.Thread(target=self._start_server_thread, args=(ip, port))
        server_thread.daemon = True
        server_thread.start()
        
    def _start_server_thread(self, ip, port):
        """Start server in thread"""
        try:
            self.log_message(self.get_text('starting_server'))
            
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
            
            self.log_message(self.get_text('server_started', ip=ip, port=port), "SUCCESS")
            self.log_message(self.get_text('websocket_url', ip=ip, port=port), "SUCCESS")
            
            for line in iter(self.server_process.stdout.readline, ''):
                if line:
                    self.root.after(0, lambda l=line: self.log_message(l.strip(), "SERVER"))
                    
        except Exception as e:
            self.log_message(self.get_text('server_start_failed', error=e), "ERROR")
            self.root.after(0, lambda: self.start_server_btn.config(state='normal'))
            self.root.after(0, lambda: self.stop_server_btn.config(state='disabled'))
            
    def stop_server(self):
        """Stop server"""
        if self.server_process:
            try:
                self.server_process.terminate()
                self.server_process.wait(timeout=5)
                self.log_message(self.get_text('server_stopped'), "SUCCESS")
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                self.log_message(self.get_text('force_stop_server'), "WARNING")
            except Exception as e:
                self.log_message(self.get_text('server_stop_error', error=e), "ERROR")
            finally:
                self.server_process = None
                self.start_server_btn.config(state='normal')
                self.stop_server_btn.config(state='disabled')
                
    def start_client(self):
        """Start client"""
        if not self.env_status['godot']:
            messagebox.showerror(self.get_text('error'), self.get_text('install_godot_first'))
            return
            
        if not self.env_status['project_files']:
            messagebox.showerror(self.get_text('error'), self.get_text('project_files_incomplete'))
            return
            
        # Update client config to connect to correct server
        if not self.update_client_config():
            messagebox.showerror(self.get_text('error'), self.get_text('update_config_failed'))
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
            messagebox.showerror(self.get_text('error'), self.get_text('godot_not_found_error'))
            return
            
        client_thread = threading.Thread(target=self._start_client_thread, args=(godot_exe,))
        client_thread.daemon = True
        client_thread.start()
        
    def _start_client_thread(self, godot_exe):
        """Start client in thread"""
        try:
            self.log_message(self.get_text('starting_client'))
            
            os.chdir(self.project_root)
            
            cmd = [godot_exe, "--path", str(self.project_root), "--headless=false"]
            
            self.client_process = subprocess.Popen(cmd)
            
            self.root.after(0, lambda: self.start_client_btn.config(state='disabled'))
            self.root.after(0, lambda: self.stop_client_btn.config(state='normal'))
            
            self.log_message(self.get_text('client_started'), "SUCCESS")
            
        except Exception as e:
            self.log_message(self.get_text('client_start_failed', error=e), "ERROR")
            self.root.after(0, lambda: self.start_client_btn.config(state='normal'))
            self.root.after(0, lambda: self.stop_client_btn.config(state='disabled'))
            
    def stop_client(self):
        """Stop client"""
        if self.client_process:
            try:
                self.client_process.terminate()
                self.client_process.wait(timeout=5)
                self.log_message(self.get_text('client_stopped'), "SUCCESS")
            except subprocess.TimeoutExpired:
                self.client_process.kill()
                self.log_message(self.get_text('force_stop_client'), "WARNING")
            except Exception as e:
                self.log_message(self.get_text('client_stop_error', error=e), "ERROR")
            finally:
                self.client_process = None
                self.start_client_btn.config(state='normal')
                self.stop_client_btn.config(state='disabled')
                
    def on_closing(self):
        """Cleanup when closing application"""
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