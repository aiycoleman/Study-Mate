@echo off
echo ==========================================
echo    TESTING VM BACKEND CONNECTION
echo ==========================================
echo.

echo Testing health check at 10.0.73.12:4000...
curl -s http://10.0.73.12:4000/v1/healthcheck
if %errorlevel%==0 (
    echo.
    echo ✅ Backend is responding!
    echo.
    echo Testing signup endpoint...
    echo.
    curl -i -X POST http://10.0.73.12:4000/v1/users ^
      -H "Content-Type: application/json" ^
      -d "{\"username\":\"quicktest\",\"email\":\"quicktest@example.com\",\"password\":\"test123\"}"
    echo.
    echo.
    echo ==========================================
    echo If you see HTTP 201 Created above, signup works!
    echo ==========================================
    echo.
    echo NOW:
    echo 1. Hot restart your Flutter app (press 'R' in terminal)
    echo 2. Try signing up with: day / day@gmail.com / test123
    echo 3. You should be redirected to activation screen
    echo.
) else (
    echo.
    echo ❌ Backend is NOT responding at 10.0.73.12:4000
    echo.
    echo Please:
    echo 1. Make sure VM is running
    echo 2. Start backend: make run/api
    echo 3. Check VM IP with: ip addr show
    echo.
)
pause

