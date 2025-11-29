#!/bin/bash
echo "==========================================="
echo "    TESTING LOGIN WITH YOUR CREDENTIALS"
echo "==========================================="
echo

echo "Testing login for: aiyeshacole@example.com"
echo "User ID from DB: 2"
echo "Activated: true"
echo

echo "[1] Testing login with EMAIL field:"
echo "Payload: {\"email\":\"aiyeshacole@example.com\",\"password\":\"[your-password]\"}"
echo

# Test with email
curl -v -X POST http://localhost:4000/v1/tokens/authentication \
  -H "Content-Type: application/json" \
  -d '{"email":"aiyeshacole@example.com","password":"password123"}' \
  2>&1 | grep -E "< HTTP|< Content|{|}"

echo
echo

echo "[2] Testing login with USERNAME field:"
echo "Payload: {\"username\":\"aiyeshacole\",\"password\":\"[your-password]\"}"
echo

# Test with username
curl -v -X POST http://localhost:4000/v1/tokens/authentication \
  -H "Content-Type: application/json" \
  -d '{"username":"aiyeshacole","password":"password123"}' \
  2>&1 | grep -E "< HTTP|< Content|{|}"

echo
echo

echo "==========================================="
echo "           WHAT TO CHECK:"
echo "==========================================="
echo
echo "1. What HTTP status code did you get?"
echo "   - 200/201 = Login works, problem is in Flutter"
echo "   - 401 = Wrong password or backend expects different format"
echo "   - 500 = Backend error"
echo
echo "2. Does the password match what you're entering in the app?"
echo "   - Password is case-sensitive"
echo "   - Check for extra spaces"
echo
echo "3. Check backend logs in the terminal where you ran 'make run/api'"
echo "   - Look for authentication errors"
echo "   - See what fields backend is expecting"
echo
echo "==========================================="
