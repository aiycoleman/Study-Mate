@echo off
echo ========================================
echo  Testing New VM IP Address
echo ========================================
echo.
echo Your VM IP changed to: 10.0.73.12
echo Flutter config has been updated!
echo.

echo 1. Testing new VM connectivity...
ping -n 2 10.0.73.12
if %errorlevel% equ 0 (
    echo ✅ VM is now reachable!
) else (
    echo ❌ VM still not reachable - check VM power status
    goto :end
)

echo.
echo 2. Testing backend server...
curl -s --connect-timeout 5 http://10.0.73.12:4000/v1/healthcheck
if %errorlevel% equ 0 (
    echo ✅ Backend server is responding!
    echo.
    echo ========================================
    echo  SUCCESS! Problem Fixed! ✅
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Hot restart your Flutter app (press 'R')
    echo 2. Click "Test Backend Connection" button
    echo 3. Try login - should work now!
) else (
    echo ❌ Backend server not responding
    echo.
    echo Action needed: Start backend server in VM
    echo   cd /cmps4191/Study-Mate
    echo   HOST=0.0.0.0 PORT=4000 make run/api
)

:end
echo.
pause
