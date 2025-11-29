@echo off
echo ==========================================
echo    QUICK FIX: SWITCH TO LOCALHOST
echo ==========================================
echo.
echo This will switch your backend to localhost:4000
echo (Use this if your backend is running on Windows)
echo.
set /p confirm="Continue? (y/n): "

if /i "%confirm%"=="y" (
    echo.
    echo Updating API configuration...
    echo const String apiBaseUrl = 'http://localhost:4000'; > lib\config\api_config.dart
    echo.
    echo ✅ API config updated to localhost:4000
    echo.
    echo Current configuration:
    type lib\config\api_config.dart
    echo.
    echo 🔥 IMPORTANT: Hot restart your Flutter app now!
    echo    Stop the app (Ctrl+C) then run: flutter run
) else (
    echo No changes made.
)
echo.
pause
