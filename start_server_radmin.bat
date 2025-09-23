@echo off
title holoDelta Server (RadminVPN)
cd /d "%~dp0ServerStuff"
echo ========================================
echo        holoDelta Server (RadminVPN)
echo ========================================
echo.
echo [INFO] Starting server for RadminVPN network
echo [INFO] Server will be accessible at: http://26.46.176.133:8000
echo [INFO] WebSocket will be available at: ws://26.46.176.133:8000/ws
echo.
echo [INFO] Make sure RadminVPN is running and connected!
echo [INFO] Share this IP with your friends: 26.46.176.133
echo.
echo Press CTRL+C to stop the server
echo.
python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
pause

