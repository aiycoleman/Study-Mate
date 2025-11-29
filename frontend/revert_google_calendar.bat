@echo off
echo ========================================
echo  Reverting Google Calendar Integration
echo ========================================
echo.
echo This will restore your services to clean state
echo before Google Calendar popup implementation.
echo.

set /p confirm="Continue with revert? (y/n): "
if /i not "%confirm%"=="y" goto :end

echo.
echo 1. Backing up current Google Calendar service...
copy "lib\services\google_calendar_service.dart" "lib\services\google_calendar_service_POPUP_VERSION.dart" >nul

echo 2. Restoring clean Google Calendar service...
copy "lib\services\google_calendar_service_CLEAN.dart" "lib\services\google_calendar_service.dart" >nul

echo 3. Services have been restored to clean state.
echo.
echo ========================================
echo  Revert Complete! ✅
echo ========================================
echo.
echo Changes made:
echo ✅ Auth service - clean backend connection only
echo ✅ API service - removed Google Calendar integration methods
echo ✅ API config - simple configuration restored
echo ✅ Google Calendar service - clean placeholder state
echo.
echo Your app will now work with:
echo ✅ Normal login/signup flow
echo ✅ Backend integration for goals, quotes, study sessions
echo ❌ No Google Calendar popup (placeholder state)
echo.
echo To re-enable Google Calendar later:
echo   1. Run 'flutter pub get' to install dependencies
echo   2. Configure OAuth credentials
echo   3. Replace service with working version
echo.

:end
pause
