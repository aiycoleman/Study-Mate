@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo    COMPREHENSIVE LOGIN TEST
echo ==========================================
echo.

echo Your Database Info:
echo   Username: aiyeshacole
echo   Email: aiyeshacole@example.com
echo   User ID: 2
echo   Activated: true
echo.

echo Testing different login scenarios...
echo.

echo ==========================================
echo  TEST 1: Backend Health Check
echo ==========================================
curl -s http://localhost:4000/v1/healthcheck
if %errorlevel%==0 (
    echo ✅ Backend is responding
) else (
    echo ❌ Backend is NOT responding
    echo Please start backend: make run/api in VM
    pause
    exit /b 1
)
echo.
echo.

echo ==========================================
echo  TEST 2: Login with EMAIL + common passwords
echo ==========================================
echo.

set "found=0"

for %%p in (password123 Password123 password test123 Test123 aiyeshacole Aiyeshacole) do (
    echo Testing password: %%p
    echo Payload: {"email":"aiyeshacole@example.com","password":"%%p"}

    curl -s -w "\nHTTP_CODE:%%{http_code}\n" -X POST http://localhost:4000/v1/tokens/authentication ^
      -H "Content-Type: application/json" ^
      -d "{\"email\":\"aiyeshacole@example.com\",\"password\":\"%%p\"}" > temp_response.txt

    findstr /C:"HTTP_CODE:20" temp_response.txt >nul 2>&1
    if !errorlevel!==0 (
        echo ✅✅✅ SUCCESS! Password is: %%p
        echo Response:
        type temp_response.txt
        set "found=1"
        goto :found_password
    )

    findstr /C:"HTTP_CODE:401" temp_response.txt >nul 2>&1
    if !errorlevel!==0 (
        echo ❌ 401 Unauthorized - wrong password
    ) else (
        echo Response:
        type temp_response.txt
    )
    echo.
)

:found_password
if "%found%"=="0" (
    echo.
    echo ==========================================
    echo  TEST 3: Login with USERNAME + common passwords
    echo ==========================================
    echo.

    for %%p in (password123 Password123 password test123 Test123 aiyeshacole Aiyeshacole) do (
        echo Testing password: %%p
        echo Payload: {"username":"aiyeshacole","password":"%%p"}

        curl -s -w "\nHTTP_CODE:%%{http_code}\n" -X POST http://localhost:4000/v1/tokens/authentication ^
          -H "Content-Type: application/json" ^
          -d "{\"username\":\"aiyeshacole\",\"password\":\"%%p\"}" > temp_response.txt

        findstr /C:"HTTP_CODE:20" temp_response.txt >nul 2>&1
        if !errorlevel!==0 (
            echo ✅✅✅ SUCCESS! Password is: %%p
            echo Response:
            type temp_response.txt
            set "found=1"
            goto :done
        )

        findstr /C:"HTTP_CODE:401" temp_response.txt >nul 2>&1
        if !errorlevel!==0 (
            echo ❌ 401 Unauthorized - wrong password
        ) else (
            echo Response:
            type temp_response.txt
        )
        echo.
    )
)

:done
del temp_response.txt 2>nul

echo.
echo ==========================================
echo             RESULTS
echo ==========================================
echo.

if "%found%"=="1" (
    echo ✅ Found working password!
    echo    The login works from command line.
    echo.
    echo 🔍 If Flutter app still fails:
    echo    1. Check Flutter console for detailed logs
    echo    2. Make sure you're using the exact same password
    echo    3. Check for extra spaces in password field
    echo    4. Verify API URL in api_config.dart is correct
) else (
    echo ❌ None of the common passwords worked
    echo.
    echo 🎯 SOLUTIONS:
    echo.
    echo    1. Reset password in database:
    echo       In VM: psql study_mate
    echo       UPDATE users SET password_hash = crypt('newpassword', gen_salt('bf'))
    echo       WHERE email='aiyeshacole@example.com';
    echo.
    echo    2. Create new test user:
    echo       Use signup screen in Flutter app
    echo       Email: test@example.com
    echo       Password: test123
    echo.
    echo    3. Check backend logs:
    echo       Look at VM terminal where backend is running
    echo       See what error backend is returning
)

echo.
pause
