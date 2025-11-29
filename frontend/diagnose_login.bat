@echo off
echo ==========================================
echo    LOGIN DIAGNOSTIC TOOL
echo ==========================================
echo.

echo Testing login with your credentials...
echo Email: aiyeshacole@example.com
echo.

echo [1] Testing if backend is accessible...
curl -s http://localhost:4000/v1/healthcheck
if %errorlevel%==0 (
    echo ✅ Backend is accessible
) else (
    echo ❌ Backend is NOT accessible
    echo PROBLEM: Backend server is not running on localhost:4000
    echo SOLUTION: Start backend with 'make run/api' in VM
    pause
    exit /b 1
)
echo.

echo [2] Testing login with EMAIL field...
curl -i -X POST http://localhost:4000/v1/tokens/authentication ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"aiyeshacole@example.com\",\"password\":\"password123\"}"
echo.

echo [3] Testing login with USERNAME field (if user has username)...
curl -i -X POST http://localhost:4000/v1/tokens/authentication ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"aiyeshacole\",\"password\":\"password123\"}"
echo.

echo ==========================================
echo             DIAGNOSIS RESULTS
echo ==========================================
echo.
echo If you see "401" or "Unauthorized":
echo   → Credentials are wrong OR account is not activated
echo   → Check database for user's actual email/password
echo   → Check if account is activated (activated = true)
echo.
echo If you see "200" or "Created":
echo   → Login works! Check Flutter app configuration
echo.
echo If you see "Connection refused" or timeout:
echo   → Backend is not running
echo   → Start backend in VM: make run/api
echo.

echo ==========================================
echo          QUICK FIXES TO TRY
echo ==========================================
echo.
echo 1. Check if account is activated:
echo    In VM: psql study_mate -c "SELECT email, activated FROM users WHERE email='aiyeshacole@example.com';"
echo.
echo 2. Manually activate account if needed:
echo    In VM: psql study_mate -c "UPDATE users SET activated = true WHERE email='aiyeshacole@example.com';"
echo.
echo 3. Reset password if needed:
echo    Create new user with signup screen
echo.

pause
