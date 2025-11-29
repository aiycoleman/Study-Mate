@echo off
echo ==========================================
echo    PRESENTATION EMERGENCY FIX
echo ==========================================
echo.
echo Quick fixes for your presentation:
echo.

echo [OPTION 1] Switch to localhost (if backend is on Windows)
echo [OPTION 2] Find new VM IP after bridged mode
echo [OPTION 3] Use Android emulator config
echo.

set /p choice="Choose option (1/2/3): "

if "%choice%"=="1" (
    echo.
    echo Switching to localhost configuration...
    echo const String apiBaseUrl = 'http://localhost:4000'; > lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // Backend running on Windows localhost >> lib\config\api_config.dart
    echo // Alternative: Switch back to VM IP when found >> lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // API endpoints >> lib\config\api_config.dart
    echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
    echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
    echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
    echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart

    echo ✅ Switched to localhost:4000
    echo 🔥 Hot restart Flutter app and try login

) else if "%choice%"=="2" (
    echo.
    echo Running VM IP finder...
    call find_new_vm_ip.bat

) else if "%choice%"=="3" (
    echo.
    echo Switching to Android emulator configuration...
    echo const String apiBaseUrl = 'http://10.0.2.2:4000'; > lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // Android emulator configuration >> lib\config\api_config.dart
    echo // Points to host machine's localhost >> lib\config\api_config.dart
    echo. >> lib\config\api_config.dart
    echo // API endpoints >> lib\config\api_config.dart
    echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
    echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
    echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
    echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart

    echo ✅ Switched to Android emulator config (10.0.2.2:4000)
    echo 🔥 Hot restart Flutter app and try login

) else (
    echo Invalid choice.
)

echo.
echo Current configuration:
echo ==========================================
type lib\config\api_config.dart
echo ==========================================
echo.
pause
