#!/bin/bash
echo "==========================================="
echo "    BACKEND STATUS CHECK IN VM"
echo "==========================================="
echo

echo "1. Checking if backend process is running..."
if pgrep -f "Study-Mate" > /dev/null; then
    echo "✅ Backend process is running"
    pgrep -f "Study-Mate" | head -5
else
    echo "❌ Backend process not found"
    echo "💡 Start backend with: make run/api"
fi
echo

echo "2. Testing backend locally in VM..."
curl -w "\nHTTP Status: %{http_code}\n" --connect-timeout 3 "http://localhost:4000/v1/healthcheck" 2>/dev/null
echo

echo "3. Checking what's listening on port 4000..."
if command -v netstat > /dev/null; then
    netstat -tlnp | grep :4000 || echo "Nothing listening on port 4000"
elif command -v ss > /dev/null; then
    ss -tlnp | grep :4000 || echo "Nothing listening on port 4000"
fi
echo

echo "4. Getting VM's external IP address..."
echo "Network interfaces:"
ip route get 1 | awk '{print $NF;exit}' 2>/dev/null || echo "Could not determine external IP"
echo

echo "All IPs on this machine:"
hostname -I 2>/dev/null || ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1

echo
echo "==========================================="
echo "If backend is not running, start it with:"
echo "cd /home/kelsey/cmps4191/Study-Mate"
echo "make run/api"
echo "==========================================="
