@echo off
title Fix Godot Path
echo ========================================
echo        Fix Godot Path
echo ========================================
echo.

echo [INFO] This script will help fix Godot PATH issues
echo.

echo [STEP 1] Checking current Godot installation...
if exist "C:\Godot\Godot_v4.5-stable_win64.exe" (
    echo [OK] Found Godot at C:\Godot\Godot_v4.5-stable_win64.exe
    set GODOT_PATH=C:\Godot\Godot_v4.5-stable_win64.exe
) else if exist "C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe" (
    echo [OK] Found Godot at Desktop location
    set GODOT_PATH=C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe
) else (
    echo [ERROR] Godot not found!
    echo Please make sure Godot is properly installed.
    pause
    exit /b 1
)

echo.
echo [STEP 2] Testing Godot execution...
"%GODOT_PATH%" --version
if %errorlevel% neq 0 (
    echo [ERROR] Godot execution failed!
    pause
    exit /b 1
)

echo.
echo [STEP 3] Creating a working client launcher...
echo @echo off > start_client_working.bat
echo title holoDelta Client >> start_client_working.bat
echo cd /d "%%~dp0" >> start_client_working.bat
echo echo Starting holoDelta Client... >> start_client_working.bat
echo echo. >> start_client_working.bat
echo "%GODOT_PATH%" --path "%%~dp0" --headless=false >> start_client_working.bat
echo pause >> start_client_working.bat

echo [OK] Created start_client_working.bat
echo.

echo [STEP 4] Testing the new launcher...
echo [INFO] You can now use start_client_working.bat to launch the client
echo.

echo [STEP 5] PATH troubleshooting...
echo [INFO] If you want to use 'godot' command directly:
echo 1. Make sure C:\Godot\ is in your system PATH
echo 2. Restart your command prompt/terminal
echo 3. Or create a symlink: mklink "C:\Godot\godot.exe" "C:\Godot\Godot_v4.5-stable_win64.exe"
echo.

echo ========================================
echo Fix complete! Use start_client_working.bat
echo ========================================
echo.
echo Press any key to exit...
pause >nul


