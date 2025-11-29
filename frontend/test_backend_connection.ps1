# Backend Connection Quick Test
Write-Host "========================================" -ForegroundColor Yellow
Write-Host " Backend Connection Quick Diagnostic" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Testing VM connectivity..." -ForegroundColor Cyan
$pingResult = Test-Connection -ComputerName "10.0.73.12" -Count 1 -Quiet
if ($pingResult) {
    Write-Host "✅ VM IP 10.0.73.12 is reachable" -ForegroundColor Green
} else {
    Write-Host "❌ VM IP 10.0.73.12 is NOT reachable" -ForegroundColor Red
    Write-Host "   → Check if VM is powered on" -ForegroundColor Yellow
    Write-Host "   → Check VM network settings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SOLUTION: Power on your VM and check network adapter" -ForegroundColor Magenta
    exit
}

Write-Host ""
Write-Host "2. Testing port 4000 connectivity..." -ForegroundColor Cyan
$portTest = Test-NetConnection -ComputerName "10.0.73.12" -Port 4000 -InformationLevel Quiet
if ($portTest) {
    Write-Host "✅ Port 4000 is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ Port 4000 is not accessible" -ForegroundColor Red
    Write-Host "   → Backend server is not running" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SOLUTION: Start backend server in VM:" -ForegroundColor Magenta
    Write-Host "   cd /cmps4191/Study-Mate" -ForegroundColor White
    Write-Host "   HOST=0.0.0.0 PORT=4000 make run/api" -ForegroundColor White
    exit
}

Write-Host ""
Write-Host "3. Testing backend health endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://10.0.73.12:4000/v1/healthcheck" -TimeoutSec 5
    Write-Host "✅ Backend health endpoint responded!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host " BACKEND IS WORKING!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Backend server is working correctly." -ForegroundColor Green
    Write-Host "Issue might be in your Flutter app." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Try:" -ForegroundColor Magenta
    Write-Host "1. Restart Flutter app (hot restart)" -ForegroundColor White
    Write-Host "2. Clear app cache/data" -ForegroundColor White
    Write-Host "3. Check Flutter console for errors" -ForegroundColor White
} catch {
    Write-Host "❌ Backend health endpoint failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "SOLUTION: Backend server is down, restart it in VM" -ForegroundColor Magenta
}

Write-Host ""
Read-Host "Press Enter to continue..."
