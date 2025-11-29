@echo off
echo ==========================================
echo    URGENT: WHERE IS YOUR BACKEND RUNNING?
echo ==========================================
echo.

echo Checking localhost (Windows)...
curl -s -m 5 http://localhost:4000/v1/healthcheck >nul 2>&1
if %errorlevel%==0 (
    echo ✅ Backend is running on Windows localhost
    echo.
    curl -s http://localhost:4000/v1/healthcheck
    echo.
    goto :test_login
) else (
    echo ❌ Backend is NOT running on Windows localhost
)

echo.
echo Checking common VM IPs...
for %%i in (192.168.1.100 192.168.1.101 192.168.0.100 10.0.73.12 192.168.18.109) do (
    echo Testing %%i...
    curl -s -m 2 http://%%i:4000/v1/healthcheck >nul 2>&1
    if !errorlevel!==0 (
        echo ✅ Backend found at %%i:4000
        set BACKEND_IP=%%i
        goto :found_backend
    )
)

echo.
echo ❌ Cannot find backend anywhere!
echo.
echo Please:
echo 1. Start backend in VM: make run/api
echo 2. Or tell me where it's running
pause
exit /b 1

:found_backend
echo.
echo ==========================================
echo    UPDATING FLUTTER CONFIG TO USE VM
echo ==========================================
echo Backend is at: %BACKEND_IP%:4000
echo.
echo Updating api_config.dart...
echo const String apiBaseUrl = 'http://%BACKEND_IP%:4000'; > lib\config\api_config.dart
echo. >> lib\config\api_config.dart
echo // Updated to VM backend at %BACKEND_IP% >> lib\config\api_config.dart
echo // API endpoints >> lib\config\api_config.dart
echo const String healthCheckEndpoint = '/v1/healthcheck'; >> lib\config\api_config.dart
echo const String loginEndpoint = '/v1/tokens/authentication'; >> lib\config\api_config.dart
echo const String registerEndpoint = '/v1/users'; >> lib\config\api_config.dart
echo const String activateEndpoint = '/v1/users/activated'; >> lib\config\api_config.dart
echo.
echo ✅ Updated! Hot restart your Flutter app
goto :test_login_vm

:test_login
echo ==========================================
echo    TESTING LOGIN ON LOCALHOST
echo ==========================================
echo.
echo Testing with: aiyeshacole@example.com
echo.
curl -i -X POST http://localhost:4000/v1/tokens/authentication ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"aiyeshacole@example.com\",\"password\":\"password123\"}"
echo.
goto :done

:test_login_vm
echo ==========================================
echo    TESTING LOGIN ON VM
echo ==========================================
echo.
echo Testing with: aiyeshacole@example.com on %BACKEND_IP%
echo.
curl -i -X POST http://%BACKEND_IP%:4000/v1/tokens/authentication ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"aiyeshacole@example.com\",\"password\":\"password123\"}"
echo.

:done
echo.
echo ==========================================
echo Look at the response above:
echo - If you see "401 Unauthorized" = Wrong password
echo - If you see "200 OK" = Login works! Problem is in Flutter
echo - If you see "token" in response = Backend is working perfectly
echo ==========================================
echo.
pause
