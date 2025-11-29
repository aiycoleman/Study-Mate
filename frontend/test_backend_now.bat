@echo off
echo Testing backend at 10.0.73.12:4000...
curl -s http://10.0.73.12:4000/v1/healthcheck
echo.
echo.
if %errorlevel%==0 (
    echo ✅ Backend is online! Your Flutter app should work now.
    echo.
    echo Press 'R' in Flutter terminal to hot restart
) else (
    echo ❌ Backend is NOT responding!
    echo.
    echo 1. Make sure VM is running
    echo 2. Start backend in VM: make run/api
    echo 3. Check VM IP: ip addr show
)
pause

