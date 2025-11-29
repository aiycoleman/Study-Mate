@echo off
echo ========================================
echo  Backend Connection Diagnostic Tool
echo ========================================
echo.

echo 1. Testing if backend server is reachable...
ping -n 1 192.168.18.109 > nul
if %errorlevel% equ 0 (
    echo ✅ VM IP 192.168.18.109 is reachable
) else (
    echo ❌ VM IP 192.168.18.109 is not reachable
    echo    Check if your VM is running and network is configured
)
echo.

echo 2. Testing backend health endpoint...
curl -s --connect-timeout 5 http://192.168.18.109:4000/v1/healthcheck > temp_response.txt 2>nul
if %errorlevel% equ 0 (
    echo ✅ Backend server responded!
    echo Response:
    type temp_response.txt
    del temp_response.txt
) else (
    echo ❌ Backend server is not responding on port 4000
    echo    Possible issues:
    echo    - Backend server is not running
    echo    - Firewall blocking port 4000
    echo    - Backend listening on wrong interface
    del temp_response.txt 2>nul
)
echo.

echo 3. Testing if port 4000 is open...
powershell -Command "Test-NetConnection -ComputerName 192.168.18.109 -Port 4000 -InformationLevel Quiet" > nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Port 4000 is open and accessible
) else (
    echo ❌ Port 4000 is not accessible
)
echo.

echo 4. Quick network diagnostics...
echo Current network configuration:
ipconfig | findstr /i "IPv4"
echo.

echo ========================================
echo  Next Steps:
echo ========================================
echo 1. Make sure your VM is running
echo 2. Start your backend server in the VM
echo 3. Check VM firewall allows port 4000
echo 4. Try the Flutter app login again
echo.
pause
