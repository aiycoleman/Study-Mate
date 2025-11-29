@echo off
echo ========================================
echo  Login Credentials Debug Test
echo ========================================
echo.
echo Testing login with your backend server...
echo.

set /p email="Enter email (kelsedom204@gmail.com): "
if "%email%"=="" set email=kelsedom204@gmail.com

set /p password="Enter password: "
if "%password%"=="" (
    echo Password cannot be empty!
    pause
    exit /b
)

echo.
echo 1. Testing backend health...
curl -s http://192.168.18.109:4000/v1/healthcheck
echo.

echo 2. Testing login with EMAIL field...
echo Payload: {"email":"%email%","password":"***"}
curl -s -X POST http://192.168.18.109:4000/v1/tokens/authentication ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%email%\",\"password\":\"%password%\"}"
echo.

echo 3. Testing login with USERNAME field...
echo Payload: {"username":"%email%","password":"***"}
curl -s -X POST http://192.168.18.109:4000/v1/tokens/authentication ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"%email%\",\"password\":\"%password%\"}"
echo.

echo ========================================
echo  RESULTS ANALYSIS:
echo ========================================
echo.
echo If you see "invalid credentials":
echo   → User exists but wrong password OR not activated
echo.
echo If you see "user not found":
echo   → User doesn't exist in database
echo.
echo If you see activation error:
echo   → User exists but needs activation via email token
echo.
echo If you see a token response:
echo   → Login works! Issue is in Flutter app
echo.
echo SOLUTION: Try signup + activation flow in Flutter app
echo.
pause
