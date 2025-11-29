#!/bin/bash
# Fix for Go backend server binding issue
# Run this script in your VM to make the server accessible from Windows

echo "🔧 Fixing Go Backend Server Network Binding"
echo "=========================================="
echo ""

cd /cmps4191/Study-Mate

echo "1. Stopping any existing server on port 4000..."
sudo pkill -f ":4000" 2>/dev/null
sudo fuser -k 4000/tcp 2>/dev/null
sleep 2

echo "2. Checking current network configuration..."
ip addr show | grep inet | grep -v "127.0.0.1"

echo ""
echo "3. Starting server with correct binding to all interfaces..."

# Method 1: Use environment variable to bind to all interfaces
echo "Trying: HOST=0.0.0.0 PORT=4000 make run/api"
HOST=0.0.0.0 PORT=4000 make run/api &

sleep 3

echo ""
echo "4. Testing server accessibility..."
echo "Local test:"
curl -s http://localhost:4000/v1/healthcheck | head -3

echo ""
echo "External IP test:"
curl -s http://192.168.18.109:4000/v1/healthcheck | head -3

echo ""
echo "5. Checking server binding:"
netstat -tuln | grep :4000

echo ""
echo "✅ If you see 0.0.0.0:4000, the server is now accessible from Windows!"
echo "❌ If you see 127.0.0.1:4000, try the alternative method below"
echo ""
echo "Alternative method if above doesn't work:"
echo "1. Stop server: sudo pkill -f ':4000'"
echo "2. Edit server code to bind to '0.0.0.0:4000' instead of ':4000'"
echo "3. Restart with: make run/api"
