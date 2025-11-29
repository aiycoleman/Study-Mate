#!/bin/bash
echo "==========================================="
echo "    LOGIN DIAGNOSTIC - VM SIDE"
echo "==========================================="
echo

echo "Checking for user: aiyeshacole@example.com"
echo

echo "[1] Does user exist?"
psql study_mate -c "SELECT id, email, username, activated, created_at FROM users WHERE email='aiyeshacole@example.com' OR username='aiyeshacole';" 2>/dev/null || echo "Error connecting to database"
echo

echo "[2] All users in database:"
psql study_mate -c "SELECT email, username, activated FROM users LIMIT 10;" 2>/dev/null || echo "Error connecting to database"
echo

echo "[3] Testing backend health:"
curl -w "\nStatus: %{http_code}\n" http://localhost:4000/v1/healthcheck 2>/dev/null
echo

echo "[4] Testing login with email (common passwords):"
for pass in password123 password Password123 test123; do
    echo "Trying password: $pass"
    curl -s -X POST http://localhost:4000/v1/tokens/authentication \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"aiyeshacole@example.com\",\"password\":\"$pass\"}" | head -c 200
    echo
done
echo

echo "==========================================="
echo "           QUICK FIXES"
echo "==========================================="
echo
echo "To activate account:"
echo "  psql study_mate -c \"UPDATE users SET activated = true WHERE email='aiyeshacole@example.com';\""
echo
echo "To see all users and their status:"
echo "  psql study_mate -c \"SELECT * FROM users;\""
echo
echo "To create test user:"
echo "  Use signup screen in Flutter app"
echo
echo "==========================================="
