@echo off
cls
echo ==========================================
echo    STUDY MATE - URGENT BACKEND FIX
echo ==========================================
echo.

echo [TEST 1] Checking if VM is reachable...
ping -n 2 10.0.73.12 > nul 2>&1
if %errorlevel%==0 (
    echo ✅ VM is reachable at 10.0.73.12
    set VM_REACHABLE=1
) else (
    echo ❌ VM is NOT reachable
    echo SOLUTION: Check VM network settings - needs Bridged mode
    set VM_REACHABLE=0
)
echo.

echo [TEST 2] Testing localhost backend...
curl -s http://localhost:4000/v1/healthcheck > nul 2>&1
if %errorlevel%==0 (
    echo ✅ Backend found on localhost:4000
    echo SOLUTION: Switch to localhost config
    set LOCALHOST_BACKEND=1
) else (
    echo ❌ No backend on localhost
    set LOCALHOST_BACKEND=0
)
echo.

echo [TEST 3] Testing VM backend (if reachable)...
if %VM_REACHABLE%==1 (
    curl -s --connect-timeout 5 http://10.0.73.12:4000/v1/healthcheck > nul 2>&1
    if %errorlevel%==0 (
        echo ✅ VM backend is working
        set VM_BACKEND=1
    ) else (
        echo ❌ VM backend not responding
        echo LIKELY CAUSE: VM firewall blocking port 4000
        set VM_BACKEND=0
    )
) else (
    echo Skipping VM backend test (VM not reachable)
    set VM_BACKEND=0
)
echo.

echo ==========================================
echo              SOLUTIONS:
echo ==========================================

if %LOCALHOST_BACKEND%==1 (
    echo 🎯 QUICKEST FIX: Backend is running on localhost
    echo.
    echo 1. Run: switch_api_config.bat
    echo 2. Choose option 2 (localhost)
    echo 3. Hot restart Flutter app
    echo.
    set /p quickfix="Apply localhost fix now? (y/n): "
    if /i "!quickfix!"=="y" (
        echo const String apiBaseUrl = 'http://localhost:4000'; > lib\config\api_config.dart
        echo ✅ FIXED! API config switched to localhost
        echo ✅ Now hot restart your Flutter app
        goto :end
    )
)

if %VM_BACKEND%==1 (
    echo ✅ VM backend is working - no changes needed
    goto :end
)

if %VM_REACHABLE%==1 (
    echo 🔧 VM FIREWALL FIX NEEDED:
    echo.
    echo In your VM terminal, run these commands:
    echo   sudo ufw allow 4000
    echo   make run/api
    echo.
    echo Then hot restart your Flutter app
) else (
    echo 🔧 VM NETWORK FIX NEEDED:
    echo.
    echo 1. Open VM settings
    echo 2. Change network from NAT to BRIDGED
    echo 3. Restart VM
    echo 4. Get new IP with: ip addr show
    echo 5. Update api_config.dart with new IP
)

:end
echo.
echo Current API config:
echo ==========================================
type lib\config\api_config.dart 2>nul || echo Error: Could not read api_config.dart
echo ==========================================
echo.
echo REMEMBER: Hot restart Flutter app after any changes!
pause
