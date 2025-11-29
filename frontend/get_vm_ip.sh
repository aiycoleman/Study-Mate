#!/bin/bash
echo "==================================="
echo "    VM IP ADDRESS FINDER"
echo "==================================="
echo
echo "Finding your VM's external IP address..."
echo

# Get all network interfaces and their IPs
echo "All network interfaces:"
ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | grep -v "::1"
echo

# Get the main external IP (usually the first non-localhost IP)
EXTERNAL_IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' 2>/dev/null)

if [ ! -z "$EXTERNAL_IP" ]; then
    echo "🎯 VM External IP: $EXTERNAL_IP"
    echo
    echo "Testing backend on this IP..."
    curl -w "\nResponse Code: %{http_code}\n" --connect-timeout 5 "http://$EXTERNAL_IP:4000/v1/healthcheck" 2>/dev/null
    echo
    echo "✅ Use this IP in your Flutter app: $EXTERNAL_IP:4000"
    echo
    echo "Update your api_config.dart with:"
    echo "const String apiBaseUrl = 'http://$EXTERNAL_IP:4000';"
else
    echo "❌ Could not determine external IP automatically"
    echo
    echo "Manual check - your network interfaces:"
    ip addr show
    echo
    echo "Look for an IP like 192.168.x.x or 10.x.x.x (not 127.0.0.1)"
fi

echo
echo "==================================="
