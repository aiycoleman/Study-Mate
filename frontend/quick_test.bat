@echo off
echo Testing backend connections...
echo.

echo [1] Testing localhost:4000
echo curl http://localhost:4000/v1/healthcheck
curl -w "Response Code: %%{http_code}\n" --connect-timeout 5 http://localhost:4000/v1/healthcheck 2>nul
echo.

echo [2] Testing VM at 10.0.73.12:4000
echo curl http://10.0.73.12:4000/v1/healthcheck
curl -w "Response Code: %%{http_code}\n" --connect-timeout 5 http://10.0.73.12:4000/v1/healthcheck 2>nul
echo.

echo [3] Ping test to VM
ping -n 1 10.0.73.12
echo.

echo [4] Port test to VM
powershell -Command "Test-NetConnection -ComputerName 10.0.73.12 -Port 4000 -InformationLevel Detailed"
echo.

pause
