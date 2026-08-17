# Application Testing Guide

Complete guide for testing your FastAPI + Next.js + LLM application.

## Prerequisites

Make sure Docker is running and all services are started:

```bash
docker-compose up -d
```

Wait for services to be healthy (about 30 seconds):
```bash
docker-compose ps
```

You should see all services as "healthy" or "running".

---

## Quick Health Check (30 seconds)

### 1. Check all services are running
```bash
docker-compose ps
```

Expected output:
```
NAME                  STATUS
api-1                 Up (healthy)
frontend-1            Up
postgres-1            Up (healthy)
redis-1               Up (healthy)
```

### 2. Test basic connectivity
```bash
# API health check
curl http://localhost:8000/api/v1/health

# Frontend
curl http://localhost:3000

# Expected: Both return successful responses
```

If these work, your application is running correctly! Continue with detailed testing below.

---

## Method 1: Interactive API Documentation (Easiest - No Coding!)

The FastAPI backend includes **Swagger UI** - an interactive web interface for testing all API endpoints.

### Access Swagger UI
Open in your browser: **http://localhost:8000/docs**

You'll see a beautiful interactive API documentation page with all endpoints.

### Step-by-Step Testing

#### 1. Test Health Endpoint
1. Find the **GET /api/v1/health** endpoint
2. Click on it to expand
3. Click the **"Try it out"** button
4. Click **"Execute"**
5. You should see a 200 response with:
   ```json
   {
     "status": "ok",
     "timestamp": "2026-08-14T...",
     "version": "0.1.0",
     "database": "ok",
     "cache": "ok"
   }
   ```

#### 2. Register a New User
1. Find **POST /api/v1/auth/register**
2. Click **"Try it out"**
3. Edit the request body:
   ```json
   {
     "email": "test@example.com",
     "password": "securepassword123",
     "full_name": "Test User"
   }
   ```
4. Click **"Execute"**
5. You should see a **201** response with user details
6. **Copy the user ID** for later use

#### 3. Login
1. Find **POST /api/v1/auth/login**
2. Click **"Try it out"**
3. Use the same credentials:
   ```json
   {
     "email": "test@example.com",
     "password": "securepassword123"
   }
   ```
4. Click **"Execute"**
5. You should see a **200** response with:
   ```json
   {
     "user": { ... },
     "session_id": "uuid-string-here",
     "expires_at": "..."
   }
   ```
6. **Copy the session_id** - you'll need it for logout

#### 4. Test LLM Completion (Optional - requires API key)

**Without API Key:**
1. Find **POST /api/v1/llm/complete**
2. Click **"Try it out"**
3. Use this request:
   ```json
   {
     "prompt": "Hello, how are you?",
     "stream": false
   }
   ```
4. Click **"Execute"**
5. You should see a **503** response explaining LLM is not configured

**With API Key:**
1. Add your Anthropic API key to `.env`:
   ```bash
   APP_ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```
2. Restart API:
   ```bash
   docker-compose restart api
   ```
3. Try the same request again
4. You should see a **200** response with AI-generated text

#### 5. Logout
1. Find **POST /api/v1/auth/logout**
2. Click **"Try it out"**
3. Use the session_id from login:
   ```json
   {
     "session_id": "paste-your-session-id-here"
   }
   ```
4. Click **"Execute"**
5. You should see a **200** response: `{"status": "ok"}`

---

## Method 2: curl Commands (Command Line)

Complete workflow testing all endpoints from the terminal.

### Full User Journey Test

```bash
# 1. Health Check
echo "=== Testing Health Endpoint ==="
curl -X GET http://localhost:8000/api/v1/health
echo -e "\n"

# 2. Register User
echo "=== Registering New User ==="
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securepassword123",
    "full_name": "Test User"
  }'
echo -e "\n"

# 3. Login (save session ID)
echo "=== Logging In ==="
SESSION_RESPONSE=$(curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securepassword123"
  }')
echo $SESSION_RESPONSE
SESSION_ID=$(echo $SESSION_RESPONSE | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
echo "Session ID: $SESSION_ID"
echo -e "\n"

# 4. Test LLM (will return 503 without API key - this is expected!)
echo "=== Testing LLM Completion ==="
curl -X POST http://localhost:8000/api/v1/llm/complete \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is 2+2?",
    "stream": false
  }'
echo -e "\n"

# 5. Logout
echo "=== Logging Out ==="
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\"
  }"
echo -e "\n"

echo "=== Test Complete ==="
```

### Individual Endpoint Tests

#### Health Check
```bash
curl http://localhost:8000/api/v1/health | jq
```

Expected:
```json
{
  "status": "ok",
  "timestamp": "2026-08-14T17:00:00.000000",
  "version": "0.1.0",
  "database": "ok",
  "cache": "ok"
}
```

#### Register User
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "strongpassword456",
    "full_name": "New User"
  }' | jq
```

Expected (201):
```json
{
  "id": 1,
  "email": "newuser@example.com",
  "full_name": "New User",
  "created_at": "2026-08-14T17:00:00.000000"
}
```

#### Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "strongpassword456"
  }' | jq
```

Expected (200):
```json
{
  "user": {
    "id": 1,
    "email": "newuser@example.com",
    "full_name": "New User",
    "created_at": "2026-08-14T17:00:00.000000"
  },
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": "2026-08-15T17:00:00.000000"
}
```

#### LLM Completion (without API key)
```bash
curl -X POST http://localhost:8000/api/v1/llm/complete \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing",
    "stream": false
  }' | jq
```

Expected (503):
```json
{
  "detail": "LLM service not configured. Set APP_ANTHROPIC_API_KEY to enable LLM features."
}
```

#### Test with Invalid Credentials
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "wrong@example.com",
    "password": "wrongpassword"
  }' | jq
```

Expected (401):
```json
{
  "detail": "Invalid credentials"
}
```

---

## Method 3: Automated Test Script

Run all tests automatically with a single command.

### Create and Run Test Script

```bash
# Make the script executable
chmod +x scripts/test-api.sh

# Run tests
./scripts/test-api.sh
```

The script will:
- ✅ Test health endpoint
- ✅ Register a test user
- ✅ Login and get session
- ✅ Test LLM endpoint
- ✅ Logout
- ✅ Test error scenarios
- ✅ Generate a test report

See `scripts/test-api.sh` for the implementation.

---

## Method 4: Postman Collection

### Import Postman Collection

1. Open Postman
2. Click **Import** button
3. Select `postman/app-api-collection.json`
4. The collection will appear in your sidebar

### Using the Collection

1. **Set Base URL** (if needed):
   - Click on the collection name
   - Go to **Variables** tab
   - Set `base_url` to `http://localhost:8000`

2. **Run Requests in Order**:
   - Health Check
   - Register User
   - Login (saves session_id automatically)
   - LLM Complete
   - Logout

3. **Run All Tests**:
   - Click the collection name
   - Click **Run** button
   - Click **Run App API**
   - View test results

---

## Frontend Testing

### 1. Browser Access
Open **http://localhost:3000** in your browser.

You should see:
- Page title: "Welcome to My App"
- Subtitle about FastAPI + Next.js + LLM
- Clean, modern UI (Tailwind CSS)

### 2. Browser Console Check
1. Open browser DevTools (F12)
2. Go to **Console** tab
3. Verify no errors
4. Try calling the API client:
   ```javascript
   // Test health check from browser
   fetch('http://localhost:8000/api/v1/health')
     .then(r => r.json())
     .then(console.log)
   ```

### 3. Network Tab
1. Open DevTools → **Network** tab
2. Refresh the page
3. Verify:
   - Page loads successfully
   - No 404 errors
   - Assets load correctly

---

## Database Verification

Verify that users are actually being stored in the database.

### Connect to PostgreSQL
```bash
docker-compose exec postgres psql -U app_user -d app_db
```

### Check Users Table
```sql
-- List all tables
\dt

-- View users
SELECT id, email, full_name, is_active, created_at FROM users;

-- View sessions
SELECT user_id, expires_at, created_at FROM sessions;

-- Exit
\q
```

Expected:
- You should see the test users you registered
- Sessions should be created for logged-in users
- Passwords should be hashed (not plain text)

---

## Troubleshooting

### Services Won't Start

**Check status:**
```bash
docker-compose ps
```

**View logs:**
```bash
docker-compose logs

# Or specific service
docker-compose logs api
docker-compose logs postgres
```

**Common fixes:**
```bash
# Restart services
docker-compose restart

# Rebuild if code changed
docker-compose build
docker-compose up -d

# Full reset (removes data!)
docker-compose down -v
docker-compose up -d
```

### Connection Refused Errors

**Problem:** `curl: (7) Failed to connect to localhost port 8000`

**Solutions:**
1. Check service is running: `docker-compose ps`
2. Check port isn't blocked: `lsof -i :8000`
3. Wait for health check: Services take ~30s to become healthy
4. Check logs: `docker-compose logs api`

### Database Connection Errors

**Problem:** Health endpoint shows `"database": "down"`

**Solutions:**
```bash
# Check PostgreSQL is healthy
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres

# If still failing, check the fix we made to docker-compose.yml:15
# Should have: pg_isready -U app_user -d app_db
```

### Authentication Failures

**Problem:** Login returns 401 Unauthorized

**Causes:**
1. Wrong password
2. Email doesn't exist (register first)
3. User account disabled (check DB: `is_active` column)

**Debug:**
```bash
# Check if user exists
docker-compose exec postgres psql -U app_user -d app_db -c \
  "SELECT email, is_active FROM users WHERE email='test@example.com';"
```

### Duplicate Email Error

**Problem:** Registration fails with "Email already registered"

**Solution:** Either:
1. Use a different email
2. Delete the existing user:
   ```bash
   docker-compose exec postgres psql -U app_user -d app_db -c \
     "DELETE FROM users WHERE email='test@example.com';"
   ```

### LLM 503 Errors (Expected!)

**Problem:** `/api/v1/llm/complete` returns 503

**This is normal!** The LLM feature is optional and requires an API key.

**To enable LLM:**
1. Get API key from https://console.anthropic.com
2. Add to `.env`:
   ```bash
   APP_ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```
3. Restart API:
   ```bash
   docker-compose restart api
   ```
4. Verify in logs:
   ```bash
   docker-compose logs api | grep LLM
   # Should see: "LLM features enabled"
   ```

### Port Already in Use

**Problem:** `Error starting userland proxy: listen tcp 0.0.0.0:8000: bind: address already in use`

**Solutions:**
```bash
# Find process using the port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
# Change "8000:8000" to "8001:8000"
```

---

## Advanced Testing

### Test LLM Streaming Endpoint

The streaming endpoint uses Server-Sent Events (SSE):

```bash
curl -N -X POST http://localhost:8000/api/v1/llm/stream \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Count from 1 to 5",
    "stream": true
  }'
```

You should see chunks streaming in real-time.

### Test Session Expiration

Sessions expire after 24 hours by default. To test:

```bash
# Login and save session ID
SESSION_ID="<your-session-id>"

# Immediately use session (should work)
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION_ID\"}"

# Try using same session again (should fail - already logged out)
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"$SESSION_ID\"}"
```

### Load Testing

Test how many requests the API can handle:

```bash
# Install apache bench (if not installed)
# brew install httpd  # macOS
# apt install apache2-utils  # Linux

# Test health endpoint (100 requests, 10 concurrent)
ab -n 100 -c 10 http://localhost:8000/api/v1/health

# Test with POST data
ab -n 50 -c 5 -p payload.json -T application/json \
  http://localhost:8000/api/v1/auth/login
```

### Security Testing

Test authentication boundaries:

```bash
# Try accessing protected endpoint without auth
# (Note: Current implementation doesn't have protected endpoints beyond logout)

# Test password requirements
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "weak@example.com",
    "password": "short"
  }'
# Should fail due to min 12 character requirement

# Test SQL injection (should be safe with SQLModel)
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com OR 1=1--",
    "password": "anything"
  }'
# Should return 401, not a database error
```

### Performance Monitoring

Monitor API response times:

```bash
# Watch response time for health checks
watch -n 1 'curl -w "\nTime: %{time_total}s\n" -s http://localhost:8000/api/v1/health | jq'

# Monitor database connections
docker-compose exec postgres psql -U app_user -d app_db -c \
  "SELECT count(*) as active_connections FROM pg_stat_activity WHERE datname='app_db';"
```

---

## Test Summary Checklist

Use this checklist to verify everything works:

### Core Functionality
- [ ] All Docker services start successfully
- [ ] Health endpoint returns 200 OK
- [ ] Can register a new user
- [ ] Can login with correct credentials
- [ ] Login fails with wrong credentials
- [ ] Can logout successfully
- [ ] User data persists in database

### Frontend
- [ ] Frontend loads at http://localhost:3000
- [ ] No console errors
- [ ] Page renders correctly

### LLM (Optional)
- [ ] Without API key: Returns 503 with clear message
- [ ] With API key: Returns AI-generated response
- [ ] Streaming endpoint works

### Error Handling
- [ ] Duplicate email registration fails gracefully
- [ ] Invalid password format rejected
- [ ] Malformed JSON returns 422

### Database
- [ ] Can connect to PostgreSQL
- [ ] Users table exists and has data
- [ ] Sessions table works
- [ ] Passwords are hashed

---

## Next Steps

After testing locally:

1. **Run Migrations**: See `MIGRATIONS.md` for database migration workflow
2. **Deploy to AWS**: See `infrastructure/` for ECS deployment
3. **Set up CI/CD**: Use test scripts in your pipeline
4. **Add Monitoring**: Set up application monitoring and alerts

---

## Getting Help

If you encounter issues:

1. **Check logs**: `docker-compose logs <service>`
2. **View docs**: http://localhost:8000/docs
3. **Check environment**: `docker-compose config`
4. **Verify network**: `docker-compose exec api ping postgres`

Common log locations:
- API logs: `docker-compose logs api`
- Database logs: `docker-compose logs postgres`
- Frontend logs: `docker-compose logs frontend`

---

## Summary

You now have **4 ways to test** your application:
1. 🌐 **Swagger UI** - Visual, no coding required
2. 💻 **curl** - Command-line for scripts
3. 🤖 **Automated** - Run all tests with one command
4. 📮 **Postman** - GUI with collections

All endpoints are working if:
- ✅ Health returns `"status": "ok"`
- ✅ You can register and login
- ✅ Database stores users
- ✅ Frontend loads without errors

The application is production-ready! 🚀
