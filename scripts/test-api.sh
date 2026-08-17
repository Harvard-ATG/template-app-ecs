#!/bin/bash
# Automated API Testing Script
# Tests all endpoints and generates a report

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE="http://localhost:8000"
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="securepassword123"
RESULTS=()

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}Testing:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    RESULTS+=("PASS: $1")
}

print_failure() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    RESULTS+=("FAIL: $1")
}

test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local description=$5
    
    print_test "$description"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    # Split response and status code
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$status_code" -eq "$expected_status" ]; then
        print_success "$description (Status: $status_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_failure "$description (Expected: $expected_status, Got: $status_code)"
        echo "$body"
    fi
    
    echo ""
}

# Start testing
clear
print_header "API Automated Testing Suite"
echo "API Base: $API_BASE"
echo "Test Email: $TEST_EMAIL"
echo "Timestamp: $(date)"

# Check if services are running
print_header "1. Service Health Check"
if ! curl -s "$API_BASE/api/v1/health" > /dev/null 2>&1; then
    print_failure "API is not responding. Is docker-compose running?"
    echo "Run: docker-compose up -d"
    exit 1
fi

# Test 1: Health Endpoint
test_endpoint "GET" "/api/v1/health" "" 200 "Health endpoint"

# Test 2: Register User
print_header "2. User Registration"
REGISTER_DATA="{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"full_name\": \"Test User\"
}"
test_endpoint "POST" "/api/v1/auth/register" "$REGISTER_DATA" 201 "Register new user"

# Test 3: Duplicate Registration (should fail)
test_endpoint "POST" "/api/v1/auth/register" "$REGISTER_DATA" 400 "Duplicate registration (should fail)"

# Test 4: Login
print_header "3. User Authentication"
LOGIN_DATA="{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
}"
print_test "Login with correct credentials"
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA")

if echo "$LOGIN_RESPONSE" | jq -e '.session_id' > /dev/null 2>&1; then
    SESSION_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.session_id')
    print_success "Login successful (Session ID: ${SESSION_ID:0:20}...)"
    echo "$LOGIN_RESPONSE" | jq '.'
else
    print_failure "Login failed - no session ID returned"
    echo "$LOGIN_RESPONSE"
fi
echo ""

# Test 5: Invalid Login
INVALID_LOGIN_DATA="{
    \"email\": \"wrong@example.com\",
    \"password\": \"wrongpassword\"
}"
test_endpoint "POST" "/api/v1/auth/login" "$INVALID_LOGIN_DATA" 401 "Login with invalid credentials (should fail)"

# Test 6: LLM Completion (will be 503 without API key)
print_header "4. LLM Integration"
LLM_DATA="{
    \"prompt\": \"What is 2+2?\",
    \"stream\": false
}"
print_test "LLM completion endpoint"
LLM_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/api/v1/llm/complete" \
    -H "Content-Type: application/json" \
    -d "$LLM_DATA")

llm_status=$(echo "$LLM_RESPONSE" | tail -n1)
llm_body=$(echo "$LLM_RESPONSE" | head -n-1)

if [ "$llm_status" -eq 503 ]; then
    print_success "LLM returns 503 (not configured - expected without API key)"
    echo "$llm_body" | jq '.' 2>/dev/null || echo "$llm_body"
elif [ "$llm_status" -eq 200 ]; then
    print_success "LLM completion successful (API key configured)"
    echo "$llm_body" | jq '.' 2>/dev/null || echo "$llm_body"
else
    print_failure "LLM endpoint returned unexpected status: $llm_status"
    echo "$llm_body"
fi
echo ""

# Test 7: Logout
print_header "5. Logout"
if [ -n "$SESSION_ID" ]; then
    LOGOUT_DATA="{
        \"session_id\": \"$SESSION_ID\"
    }"
    test_endpoint "POST" "/api/v1/auth/logout" "$LOGOUT_DATA" 200 "Logout with valid session"
else
    print_failure "Skipping logout test (no session ID from login)"
fi

# Database Verification
print_header "6. Database Verification"
print_test "Checking if user exists in database"
DB_CHECK=$(docker-compose exec -T postgres psql -U app_user -d app_db -t -c \
    "SELECT email FROM users WHERE email='$TEST_EMAIL';" 2>/dev/null || echo "")

if echo "$DB_CHECK" | grep -q "$TEST_EMAIL"; then
    print_success "User found in database"
else
    print_failure "User not found in database"
fi
echo ""

# Frontend Check
print_header "7. Frontend Verification"
print_test "Checking frontend availability"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)

if [ "$FRONTEND_STATUS" -eq 200 ]; then
    print_success "Frontend is accessible (Status: $FRONTEND_STATUS)"
else
    print_failure "Frontend returned status: $FRONTEND_STATUS"
fi
echo ""

# Generate Report
print_header "Test Summary"
PASS_COUNT=0
FAIL_COUNT=0

for result in "${RESULTS[@]}"; do
    if [[ $result == PASS:* ]]; then
        ((PASS_COUNT++))
        echo -e "${GREEN}$result${NC}"
    else
        ((FAIL_COUNT++))
        echo -e "${RED}$result${NC}"
    fi
done

echo ""
echo "========================================="
echo -e "Total Tests: $((PASS_COUNT + FAIL_COUNT))"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo "========================================="

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! 🎉${NC}\n"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Check logs above for details.${NC}\n"
    exit 1
fi
