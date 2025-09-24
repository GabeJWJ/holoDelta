@echo off
echo ========================================
echo    HoloDelta - Enhanced Launcher
echo ========================================
echo.
echo [INFO] Starting enhanced visual launcher...
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
if not exist "holoDelta_launcher_enhanced.py" (
    echo [ERROR] holoDelta_launcher_enhanced.py not found
    echo Please make sure you are running this script from the correct directory
    echo.
    pause
    exit /b 1
)

REM Start the launcher
echo [INFO] Launching HoloDelta Enhanced Launcher...
python holoDelta_launcher_enhanced.py

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
