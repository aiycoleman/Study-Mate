#!/bin/bash
echo "==========================================="
echo "  TESTING LOGIN FOR: aiyeshacole"
echo "==========================================="
echo

echo "Database shows:"
echo "  ID: 2"
echo "  Username: aiyeshacole"
echo "  Email: aiyeshacole@example.com"
echo "  Activated: t (true)"
echo

echo "Let's verify in database right now:"
psql study_mate -c "SELECT id, email, username, activated, created_at FROM users WHERE id=2;"
echo

echo "Now testing login from command line..."
echo

# Test 1: With email
echo "[TEST 1] Login with EMAIL field:"
echo "curl -X POST http://localhost:4000/v1/tokens/authentication \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"aiyeshacole@example.com\",\"password\":\"YOUR_PASSWORD\"}'"
echo

# Since we don't know the actual password, let's try to see what the backend expects
echo "Testing with common password (password123):"
curl -i -X POST http://localhost:4000/v1/tokens/authentication \
  -H 'Content-Type: application/json' \
  -d '{"email":"aiyeshacole@example.com","password":"password123"}' 2>&1 | head -20
echo
echo

# Test 2: With username
echo "[TEST 2] Login with USERNAME field:"
curl -i -X POST http://localhost:4000/v1/tokens/authentication \
  -H 'Content-Type: application/json' \
  -d '{"username":"aiyeshacole","password":"password123"}' 2>&1 | head -20
echo
echo

echo "==========================================="
echo "           ANALYSIS"
echo "==========================================="
echo
echo "1. Check the HTTP status code above:"
echo "   - 200/201 = Success! Password is correct"
echo "   - 401 = Wrong password OR account issue"
echo "   - 500 = Backend error"
echo
echo "2. If you see 401, the password 'password123' is wrong"
echo "   What password did you use when creating this account?"
echo
echo "3. Check backend logs (where you ran 'make run/api')"
echo "   Look for the exact error message"
echo
echo "==========================================="
echo "        BACKEND LOG CHECK"
echo "==========================================="
echo
echo "Look at your terminal where backend is running."
echo "When you try to login, you should see:"
echo "  - Request received"
echo "  - Authentication attempt"
echo "  - Success or failure message"
echo
echo "Common backend errors:"
echo "  'invalid authentication credentials' = Wrong password"
echo "  'account is not activated' = Activation issue"
echo "  'user does not exist' = Email/username not found"
echo
echo "==========================================="
