@echo off
echo ========================================
echo  Backend Server Connectivity Test
echo ========================================
echo.
echo Testing connection to your VM backend...
echo VM IP: 10.0.73.12
echo Port: 4000
echo.

echo 1. Testing VM connectivity...
ping -n 2 10.0.73.12
if %errorlevel% neq 0 (
    echo ❌ VM is not reachable
    echo SOLUTION: Check if your VM is powered on
    goto :end
)

echo.
echo 2. Testing backend server health...
curl -s --connect-timeout 5 http://10.0.73.12:4000/v1/healthcheck
if %errorlevel% equ 0 (
    echo.
    echo ✅ Backend server is running!
) else (
    echo ❌ Backend server is not responding
    echo.
    echo SOLUTION: Start your backend server in VM:
    echo   cd /cmps4191/Study-Mate
    echo   HOST=0.0.0.0 PORT=4000 make run/api
)

echo.
echo 3. Testing study sessions endpoint...
curl -s --connect-timeout 5 -X GET http://10.0.73.12:4000/v1/study-sessions
if %errorlevel% equ 0 (
    echo.
    echo ✅ Study sessions endpoint is accessible!
) else (
    echo ❌ Study sessions endpoint not accessible
    echo This is why you can't add study sessions
)

:end
echo.
echo ========================================
echo If backend is not running:
echo 1. Connect to your VM terminal
echo 2. cd /cmps4191/Study-Mate
echo 3. HOST=0.0.0.0 PORT=4000 make run/api
echo ========================================
pause
