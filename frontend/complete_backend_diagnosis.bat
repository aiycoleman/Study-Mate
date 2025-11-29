@echo off
echo ====================================
echo    STUDY MATE BACKEND DIAGNOSIS
echo ====================================
echo.

echo [1/6] Testing Windows to VM Network Connection...
echo.
ping -n 3 10.0.73.12
if %errorlevel%==0 (
    echo ✅ VM is reachable from Windows
) else (
    echo ❌ VM is NOT reachable from Windows
    echo Check VM network settings - ensure bridged network mode
)
echo.

echo [2/6] Testing Port 4000 Connectivity...
echo.
powershell -Command "try { $result = Test-NetConnection -ComputerName '10.0.73.12' -Port 4000 -InformationLevel Quiet -WarningAction SilentlyContinue; if($result) { Write-Host '✅ Port 4000 is accessible' -ForegroundColor Green } else { Write-Host '❌ Port 4000 is blocked or backend not running' -ForegroundColor Red } } catch { Write-Host '❌ Cannot test port connectivity' -ForegroundColor Red }"
echo.

echo [3/6] Testing Backend Health Check...
echo.
powershell -Command "try { $response = Invoke-RestMethod -Uri 'http://10.0.73.12:4000/v1/healthcheck' -TimeoutSec 5; Write-Host '✅ Backend is responding!' -ForegroundColor Green; Write-Host 'Response:' $response } catch { Write-Host '❌ Backend health check failed:' $_.Exception.Message -ForegroundColor Red }"
echo.

echo [4/6] Checking for localhost backend (if you're running backend on Windows)...
echo.
powershell -Command "try { $response = Invoke-RestMethod -Uri 'http://localhost:4000/v1/healthcheck' -TimeoutSec 3; Write-Host '✅ Localhost backend found!' -ForegroundColor Green; Write-Host 'Response:' $response } catch { Write-Host '❌ No localhost backend running' -ForegroundColor Yellow }"
echo.

echo [5/6] Testing VM SSH/Connection (alternative test)...
echo.
powershell -Command "try { $result = Test-NetConnection -ComputerName '10.0.73.12' -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue; if($result) { Write-Host '✅ VM SSH port accessible (VM is definitely running)' -ForegroundColor Green } else { Write-Host '❌ VM SSH not accessible - VM might be down' -ForegroundColor Red } } catch { Write-Host 'SSH test inconclusive' -ForegroundColor Yellow }"
echo.

echo [6/6] Summary and Next Steps:
echo.
echo If VM is reachable but port 4000 fails:
echo   → VM firewall is blocking the port
echo   → Backend server is not running
echo.
echo If VM is not reachable at all:
echo   → VM network needs to be in bridged mode
echo   → VM might be down/suspended
echo.
echo VM Commands to run if VM is accessible:
echo   sudo ufw status          # Check firewall
echo   sudo ufw allow 4000      # Allow port 4000
echo   make run/api             # Start backend server
echo   curl localhost:4000/v1/healthcheck  # Test locally in VM
echo.

pause
