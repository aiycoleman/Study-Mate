#!/bin/bash
echo "==========================================="
echo "  CHECKING BACKEND ACTIVATION LOGIC"
echo "==========================================="
echo

# Find the backend authentication handler file
echo "[1] Searching for authentication handler..."
echo

if [ -f "../cmd/api/tokens.go" ]; then
    echo "Found: ../cmd/api/tokens.go"
    echo
    echo "Checking activation requirements:"
    echo
    grep -A 10 -B 5 "activated\|Activated" ../cmd/api/tokens.go
    echo
elif [ -f "../cmd/api/authentication.go" ]; then
    echo "Found: ../cmd/api/authentication.go"
    echo
    echo "Checking activation requirements:"
    echo
    grep -A 10 -B 5 "activated\|Activated" ../cmd/api/authentication.go
    echo
fi

echo
echo "[2] Checking user authentication in database model..."
echo

if [ -f "../internal/data/users.go" ]; then
    echo "Found: ../internal/data/users.go"
    echo
    echo "Authentication method:"
    grep -A 30 "func.*Authenticate\|func.*GetByEmail\|func.*Matches" ../internal/data/users.go | head -50
    echo
fi

echo
echo "[3] Checking middleware for activation requirements..."
echo

if [ -f "../cmd/api/middleware.go" ]; then
    echo "Found: ../cmd/api/middleware.go"
    echo
    grep -A 10 -B 5 "requireActivated\|activated" ../cmd/api/middleware.go
    echo
fi

echo
echo "==========================================="
echo "  TESTING ACTUAL LOGIN"
echo "==========================================="
echo

echo "Database user status:"
psql study_mate -c "SELECT id, email, username, activated FROM users WHERE email='aiyeshacole@example.com';"
echo

echo "Testing login with email..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:4000/v1/tokens/authentication \
  -H 'Content-Type: application/json' \
  -d '{"email":"aiyeshacole@example.com","password":"password123"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "HTTP Status: $HTTP_CODE"
echo "Response Body: $BODY"
echo

if [ "$HTTP_CODE" = "401" ]; then
    echo "❌ 401 UNAUTHORIZED"
    echo
    echo "Possible reasons:"
    echo "  1. Wrong password (most likely)"
    echo "  2. Email not found"
    echo "  3. Account not activated (but DB shows it is)"
    echo
    echo "Check backend logs for exact error!"
elif [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✅ LOGIN SUCCESSFUL!"
    echo
    echo "The password 'password123' works!"
    echo "Problem is in Flutter app, not backend."
else
    echo "⚠️  Unexpected status: $HTTP_CODE"
fi

echo
echo "==========================================="
echo "  BACKEND LOGS"
echo "==========================================="
echo
echo "Check your terminal where 'make run/api' is running."
echo "It should show the exact error when login fails."
echo
echo "Common errors:"
echo "  - 'invalid authentication credentials'"
echo "  - 'account is not activated'"
echo "  - 'user does not exist'"
echo
echo "==========================================="

