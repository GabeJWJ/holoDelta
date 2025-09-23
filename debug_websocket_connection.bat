@echo off
title WebSocket Connection Debug
echo ========================================
echo        WebSocket Connection Debug
echo ========================================
echo.

echo [INFO] Testing WebSocket connection to: ws://26.46.176.133:8000/ws
echo.

echo [TEST 1] Testing HTTP connection first
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://26.46.176.133:8000' -UseBasicParsing -TimeoutSec 10; Write-Host '[SUCCESS] HTTP Status:' $response.StatusCode } catch { Write-Host '[ERROR] HTTP failed:' $_.Exception.Message }"
echo.

echo [TEST 2] Testing WebSocket endpoint
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://26.46.176.133:8000/ws' -UseBasicParsing -TimeoutSec 10; Write-Host '[SUCCESS] WebSocket endpoint accessible' } catch { Write-Host '[ERROR] WebSocket endpoint failed:' $_.Exception.Message }"
echo.

echo [TEST 3] Testing server check endpoint
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://26.46.176.133:8000/check' -UseBasicParsing -TimeoutSec 10; Write-Host '[SUCCESS] Check endpoint:' $response.Content } catch { Write-Host '[ERROR] Check endpoint failed:' $_.Exception.Message }"
echo.

echo [INFO] Possible issues:
echo 1. WebSocket protocol mismatch (ws vs wss)
echo 2. Firewall blocking WebSocket connections
echo 3. RadminVPN connection issues
echo 4. Server not properly handling WebSocket upgrade
echo.

echo [INFO] From server logs, we see:
echo - HTTP requests are working (200 OK)
echo - But WebSocket connection might be failing
echo - "Invalid HTTP request received" suggests WebSocket handshake issues
echo.

echo ========================================
echo Debug complete!
echo ========================================
echo.
echo Press any key to exit...
pause >nul

