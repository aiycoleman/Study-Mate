@echo off
echo ========================================
echo  Backend Connection Quick Diagnostic
echo ========================================
echo.
echo This will check what changed since this morning...
echo.

echo 1. Testing if VM IP is reachable...
ping -n 1 192.168.18.109 > nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ VM IP 192.168.18.109 is reachable
) else (
    echo ❌ VM IP 192.168.18.109 is NOT reachable
    echo    → VM might be powered off
    echo    → Network configuration changed
    goto :vm_issue
)
echo.

echo 2. Testing backend health endpoint...
curl -s --connect-timeout 5 http://192.168.18.109:4000/v1/healthcheck > temp_health_check.txt 2>nul
if %errorlevel% equ 0 (
    echo ✅ Backend health endpoint responded!
    echo Response:
    type temp_health_check.txt
    del temp_health_check.txt
    goto :backend_ok
) else (
    echo ❌ Backend server is not responding on port 4000
    del temp_health_check.txt 2>nul
    goto :server_issue
)

:vm_issue
echo.
echo ========================================
echo  VM CONNECTION ISSUE
echo ========================================
echo.
echo The VM is not reachable. Check:
echo 1. Is your VM powered on?
echo 2. Did the VM get a new IP address?
echo 3. Is your network connection working?
echo.
echo SOLUTION: Start your VM and check IP address
echo.
goto :end

:server_issue
echo.
echo ========================================
echo  BACKEND SERVER ISSUE
echo ========================================
echo.
echo VM is reachable but backend server is down.
echo.
echo SOLUTION: Start your backend server in the VM:
echo   1. SSH/connect to your VM
echo   2. cd /cmps4191/Study-Mate
echo   3. HOST=0.0.0.0 PORT=4000 make run/api
echo.
goto :end

:backend_ok
echo.
echo ========================================
echo  BACKEND IS WORKING
echo ========================================
echo.
echo Backend server is responding correctly!
echo The issue might be in your Flutter app.
echo.
echo Try:
echo 1. Restart your Flutter app
echo 2. Clear app data/cache
echo 3. Check Flutter console for errors
echo.

:end
echo.
pause
