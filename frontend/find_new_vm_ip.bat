@echo off
echo ==========================================
echo    VM IP FINDER AND CONFIG UPDATER
echo ==========================================
echo.
echo After switching to Bridged mode, your VM has a new IP address.
echo Let's find it and update your Flutter app configuration.
echo.

echo [1] Scanning your network for possible VM IPs...
echo.

REM Get your Windows IP range
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| find "IPv4"') do (
    set WINDOWS_IP=%%i
    goto :found_ip
)

:found_ip
echo Your Windows IP range: %WINDOWS_IP%
echo.

echo [2] Common VM IP ranges to check:
echo    - 192.168.1.x (most common)
echo    - 192.168.0.x
echo    - 10.0.0.x
echo    - 172.16.x.x
echo.

echo [3] Testing common VM IPs on port 4000...
echo.

REM Test common IP ranges
for %%i in (192.168.1.100 192.168.1.101 192.168.1.102 192.168.1.103 192.168.1.104 192.168.1.105) do (
    echo Testing %%i:4000...
    curl -s --connect-timeout 2 http://%%i:4000/v1/healthcheck > nul 2>&1
    if !errorlevel!==0 (
        echo ✅ FOUND VM BACKEND AT: %%i:4000
        set NEW_VM_IP=%%i
        goto :update_config
    )
)

for %%i in (192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104 192.168.0.105) do (
    echo Testing %%i:4000...
    curl -s --connect-timeout 2 http://%%i:4000/v1/healthcheck > nul 2>&1
    if !errorlevel!==0 (
        echo ✅ FOUND VM BACKEND AT: %%i:4000
        set NEW_VM_IP=%%i
        goto :update_config
    )
)

echo ❌ VM backend not found on common IPs
echo.
echo MANUAL STEPS:
echo 1. In your VM terminal, run: ip addr show
echo 2. Look for the IP address (usually 192.168.x.x)
echo 3. Run this script again or manually update api_config.dart
echo.
goto :manual_input

:update_config
echo.
echo ==========================================
echo          UPDATING CONFIGURATION
echo ==========================================
echo.
echo Found VM at: %NEW_VM_IP%:4000
echo.
set /p confirm="Update api_config.dart with this IP? (y/n): "

if /i "%confirm%"=="y" (
    echo const String apiBaseUrl = 'http://%NEW_VM_IP%:4000'; > lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // Alternative configurations: >> lib\config\api_config.dart
    echo // For localhost ^(if backend on Windows^): 'http://localhost:4000' >> lib\config\api_config.dart
    echo // For Android emulator: 'http://10.0.2.2:4000' >> lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // API endpoints >> lib\config\api_config.dart
    echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
    echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
    echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
    echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart

    echo.
    echo ✅ Configuration updated to: http://%NEW_VM_IP%:4000
    echo.
    echo Current config:
    type lib\config\api_config.dart
    echo.
    echo 🔥 NEXT STEP: Hot restart your Flutter app!
    echo    Stop the app ^(Ctrl+C^) then run: flutter run
) else (
    echo No changes made.
)
goto :end

:manual_input
echo.
echo MANUAL IP ENTRY:
set /p manual_ip="Enter the VM IP address (from 'ip addr show' in VM): "

if not "%manual_ip%"=="" (
    echo Testing %manual_ip%:4000...
    curl -s --connect-timeout 3 http://%manual_ip%:4000/v1/healthcheck > nul 2>&1
    if !errorlevel!==0 (
        echo ✅ Backend confirmed at: %manual_ip%:4000
        set NEW_VM_IP=%manual_ip%
        goto :update_config
    ) else (
        echo ❌ No backend found at %manual_ip%:4000
        echo Make sure your backend is running in the VM
    )
)

:end
echo.
pause
