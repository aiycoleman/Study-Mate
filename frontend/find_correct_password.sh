#!/bin/bash
echo "==========================================="
echo "  PASSWORD VERIFICATION TEST"
echo "==========================================="
echo

echo "This script will test different password variations"
echo "for user: aiyeshacole@example.com"
echo

# Get the password hash from database to see if it exists
echo "Checking if user has a password hash in DB:"
psql study_mate -c "SELECT id, email, LENGTH(password_hash) as hash_length FROM users WHERE email='aiyeshacole@example.com';"
echo

# List of common passwords to try
PASSWORDS=(
    "password123"
    "Password123"
    "password"
    "Password"
    "test123"
    "Test123"
    "aiyeshacole"
    "Aiyeshacole"
    "aiyeshacole123"
    "pa55word"
)

echo "Testing ${#PASSWORDS[@]} common passwords..."
echo

for PASSWORD in "${PASSWORDS[@]}"; do
    echo -n "Testing password: '$PASSWORD' ... "

    RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:4000/v1/tokens/authentication \
      -H 'Content-Type: application/json' \
      -d "{\"email\":\"aiyeshacole@example.com\",\"password\":\"$PASSWORD\"}")

    HTTP_CODE="${RESPONSE: -3}"
    BODY="${RESPONSE:0:${#RESPONSE}-3}"

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo "✅✅✅ SUCCESS! ✅✅✅"
        echo
        echo "================================================"
        echo "  FOUND THE CORRECT PASSWORD: '$PASSWORD'"
        echo "================================================"
        echo
        echo "Response: $BODY"
        echo
        exit 0
    elif [ "$HTTP_CODE" = "401" ]; then
        echo "❌ (401 Unauthorized)"
    else
        echo "⚠️  (HTTP $HTTP_CODE)"
    fi
done

echo
echo "==========================================="
echo "  NO COMMON PASSWORD WORKED"
echo "==========================================="
echo
echo "None of the common passwords matched."
echo
echo "OPTIONS:"
echo
echo "1. Check what password you used when creating this account"
echo
echo "2. Reset the password in database:"
echo "   psql study_mate"
echo "   UPDATE users SET password_hash = crypt('yournewpassword', gen_salt('bf'))"
echo "   WHERE email='aiyeshacole@example.com';"
echo
echo "3. Create a fresh test account:"
echo "   - Use Sign Up in Flutter app"
echo "   - Email: test@example.com"
echo "   - Password: test123"
echo "   - Activate it: UPDATE users SET activated = true WHERE email='test@example.com';"
echo
echo "4. Check backend logs to see the exact error"
echo
echo "==========================================="

