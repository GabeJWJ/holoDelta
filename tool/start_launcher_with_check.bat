@echo off
echo ========================================
echo    HoloDelta - Enhanced Launcher
echo    (with tkinter detection)
echo ========================================
echo.
echo [INFO] Starting launcher with tkinter detection...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

REM Check if the launcher file exists
if not exist "launcher_with_tkinter_check.py" (
    echo [ERROR] launcher_with_tkinter_check.py not found
    echo Please make sure you are running this script from the correct directory
    echo.
    pause
    exit /b 1
)

REM Start the launcher with tkinter check
echo [INFO] Launching HoloDelta Launcher with tkinter detection...
python launcher_with_tkinter_check.py

REM Check if the launcher exited with an error
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Launcher execution failed
    echo Please check Python environment and dependencies
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo [INFO] Launcher closed successfully
pause
