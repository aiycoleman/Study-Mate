@echo off
echo ========================================
echo  VM CONNECTIVITY QUICK FIX
echo ========================================
echo.
echo Ping to 192.168.18.109 failed!
echo This means your VM is not reachable.
echo.
echo IMMEDIATE ACTIONS:
echo.
echo 1. CHECK VM POWER STATUS:
echo    - Open VMware Workstation or VirtualBox
echo    - Check if Study-Mate VM is powered on
echo    - If off, click "Power On" or "Start"
echo.
echo 2. CHECK VM NETWORK SETTINGS:
echo    - Right-click VM ^> Settings
echo    - Go to Network Adapter
echo    - Change to "Bridged" mode (not NAT)
echo    - Click OK and restart VM
echo.
echo 3. GET VM'S CURRENT IP:
echo    - Open VM terminal/console
echo    - Run: ip addr show
echo    - Look for new IP address
echo.
echo 4. TEST AGAIN:
echo    - ping NEW_VM_IP
echo.
echo ========================================
echo  ALTERNATIVE: USE DIFFERENT IP
echo ========================================
echo.
echo If VM has different IP address:
echo 1. Find VM's actual IP in VM terminal
echo 2. Update Flutter config file:
echo    lib/config/api_config.dart
echo 3. Change apiBaseUrl to new IP
echo.
pause
echo.
echo Testing some common VM IPs...
echo.

echo Testing 192.168.1.x range...
for /L %%i in (100,1,110) do (
    ping -n 1 -w 1000 192.168.1.%%i > nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ Found VM at 192.168.1.%%i
        curl -s --connect-timeout 2 http://192.168.1.%%i:4000/v1/healthcheck > nul 2>&1
        if !errorlevel! equ 0 (
            echo ✅ Backend running at 192.168.1.%%i:4000
            echo UPDATE Flutter config to use: http://192.168.1.%%i:4000
        )
    )
)

echo.
echo Testing 192.168.56.x range (VirtualBox Host-Only)...
for /L %%i in (100,1,110) do (
    ping -n 1 -w 1000 192.168.56.%%i > nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ Found VM at 192.168.56.%%i
        curl -s --connect-timeout 2 http://192.168.56.%%i:4000/v1/healthcheck > nul 2>&1
        if !errorlevel! equ 0 (
            echo ✅ Backend running at 192.168.56.%%i:4000
            echo UPDATE Flutter config to use: http://192.168.56.%%i:4000
        )
    )
)

echo.
echo If no VMs found:
echo 1. VM is powered off - start your VM
echo 2. VM network mode needs changing to Bridged
echo 3. Check VM settings in VMware/VirtualBox
echo.
pause
