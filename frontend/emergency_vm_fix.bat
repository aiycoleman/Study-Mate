@echo off
echo ===========================================
echo    EMERGENCY VM IP FIX FOR PRESENTATION
echo ===========================================
echo.

echo Your VM is in bridged mode but app still can't connect.
echo Let's try multiple solutions quickly.
echo.

echo [1] Testing if backend is accessible from Windows...
echo.

REM Test common bridged IPs
set "FOUND_IP="
for %%i in (192.168.1.100 192.168.1.101 192.168.1.102 192.168.1.105 192.168.1.110 192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.105 10.0.0.100 10.0.0.101) do (
    echo Testing %%i...
    ping -n 1 -w 1000 %%i >nul 2>&1
    if !errorlevel!==0 (
        echo Found VM at %%i, testing backend...
        curl -s --connect-timeout 3 "http://%%i:4000/v1/healthcheck" >nul 2>&1
        if !errorlevel!==0 (
            echo ✅ BACKEND FOUND AT %%i:4000
            set "FOUND_IP=%%i"
            goto :found
        )
    )
)

echo ❌ Could not find VM backend automatically
echo.
echo QUICK SOLUTIONS:
echo.

:manual_solutions
echo [A] Switch to localhost (backend on Windows)
echo [B] Get VM IP manually
echo [C] Use Android emulator config
echo.
set /p solution="Choose quick fix (A/B/C): "

if /i "%solution%"=="A" goto :localhost
if /i "%solution%"=="B" goto :manual_ip
if /i "%solution%"=="C" goto :emulator
goto :manual_solutions

:localhost
echo.
echo Switching to localhost backend...
echo const String apiBaseUrl = 'http://localhost:4000'; > lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // Localhost configuration for Windows backend >> lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // API endpoints >> lib\config\api_config.dart
echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart

echo ✅ Switched to localhost:4000
echo 🔥 Hot restart Flutter app and try login
goto :show_config

:manual_ip
echo.
set /p vm_ip="Enter VM IP (from 'ip addr show' - look for 192.168.x.x): "
if "%vm_ip%"=="" goto :manual_ip

echo Testing %vm_ip%:4000...
curl -s --connect-timeout 5 "http://%vm_ip%:4000/v1/healthcheck" >nul 2>&1
if !errorlevel!==0 (
    echo ✅ Backend confirmed at %vm_ip%:4000
    echo const String apiBaseUrl = 'http://%vm_ip%:4000'; > lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // VM backend configuration >> lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // API endpoints >> lib\config\api_config.dart
    echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
    echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
    echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
    echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart
    echo ✅ Updated to %vm_ip%:4000
) else (
    echo ❌ Backend not responding at %vm_ip%:4000
    echo Make sure backend is running in VM: make run/api
)
goto :show_config

:emulator
echo.
echo Switching to Android emulator config...
echo const String apiBaseUrl = 'http://10.0.2.2:4000'; > lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // Android emulator configuration >> lib\config\api_config.dart
echo // 10.0.2.2 maps to host machine's localhost >> lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // API endpoints >> lib\config\api_config.dart
echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart

echo ✅ Switched to Android emulator config (10.0.2.2:4000)
goto :show_config

:found
echo.
echo Updating configuration to %FOUND_IP%...
echo const String apiBaseUrl = 'http://%FOUND_IP%:4000'; > lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // VM backend found automatically >> lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // API endpoints >> lib\config\api_config.dart
echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart

echo ✅ Configuration updated to %FOUND_IP%:4000

:show_config
echo.
echo ==========================================
echo           CURRENT CONFIGURATION
echo ==========================================
type lib\config\api_config.dart
echo ==========================================
echo.
echo 🎯 NEXT STEPS:
echo 1. Hot restart your Flutter app (Ctrl+C then flutter run)
echo 2. Try login - should work now
echo 3. If still fails, check that backend is running
echo.
pause
