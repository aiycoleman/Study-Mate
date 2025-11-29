@echo off
echo ========================================
echo  Study Mate - Restore Original Backend
echo ========================================
echo.
echo This will restore your original backend services
echo and disable mock mode.
echo.

set /p confirm="Continue? (y/n): "
if /i not "%confirm%"=="y" goto :end

echo.
echo Restoring original files...

if exist "lib\services\auth_service_BACKUP.dart" (
    copy "lib\services\auth_service_BACKUP.dart" "lib\services\auth_service.dart" >nul
    echo ✅ Restored auth_service.dart
    del "lib\services\auth_service_BACKUP.dart" >nul
) else (
    echo ❌ Backup auth_service.dart not found
)

if exist "lib\services\api_service_BACKUP.dart" (
    copy "lib\services\api_service_BACKUP.dart" "lib\services\api_service.dart" >nul
    echo ✅ Restored api_service.dart
    del "lib\services\api_service_BACKUP.dart" >nul
) else (
    echo ❌ Backup api_service.dart not found
)

echo.
echo ========================================
echo  Original Backend Services Restored! 🔄
echo ========================================
echo.
echo Your app will now connect to the real backend.
echo Make sure your backend server is running at:
echo   192.168.18.109:4000
echo.

:end
pause
