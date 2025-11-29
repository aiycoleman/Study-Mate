@echo off
echo ====================================
echo    STUDY MATE API CONFIG SWITCHER
echo ====================================
echo.
echo Choose your backend location:
echo [1] VM Backend (10.0.73.12:4000)
echo [2] Windows Localhost (localhost:4000)
echo [3] Android Emulator (10.0.2.2:4000)
echo.
set /p choice="Enter choice (1/2/3): "

if "%choice%"=="1" (
    echo Switching to VM backend...
    echo const String apiBaseUrl = 'http://10.0.73.12:4000'; > lib\config\api_config.dart
    echo ✅ API config updated to VM backend
) else if "%choice%"=="2" (
    echo Switching to localhost backend...
    echo const String apiBaseUrl = 'http://localhost:4000'; > lib\config\api_config.dart
    echo ✅ API config updated to localhost backend
) else if "%choice%"=="3" (
    echo Switching to Android emulator backend...
    echo const String apiBaseUrl = 'http://10.0.2.2:4000'; > lib\config\api_config.dart
    echo ✅ API config updated to Android emulator backend
) else (
    echo Invalid choice. No changes made.
)

echo.
echo Current API configuration:
type lib\config\api_config.dart
echo.
echo Remember to hot restart your Flutter app after changing configuration!
pause
