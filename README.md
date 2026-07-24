# LeadDesk Mini 🚀

> A full-stack lead-capture product built for the **Digital Heroes Training Task**.  
> **Frontend**: Flutter Web · **Backend**: Go · **Database**: PostgreSQL

---

## Features

| Feature | Status |
|---------|--------|
| Public landing page with lead form | ✅ |
| Client-side validation | ✅ |
| Server-side validation | ✅ |
| PostgreSQL storage | ✅ |
| Admin view at `/admin` | ✅ |
| Search leads by name/email | ✅ |
| Status toggle (New → Contacted → Closed) | ✅ |
| Password-protected admin | ✅ |
| CORS configured | ✅ |
| Graceful shutdown | ✅ |

---

## Tech Stack

- **Frontend**: Flutter 3.x (Web)
- **Backend**: Go 1.22 (stdlib `net/http`)
- **Database**: PostgreSQL 15+
- **Packages**: pgx/v5, rs/cors, go_router, google_fonts, http, url_launcher

---

## Local Development

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.12
- [Go](https://go.dev/dl/) ≥ 1.22
- [PostgreSQL](https://www.postgresql.org/download/) ≥ 14

### 1. Database Setup

```bash
# Create database
psql -U postgres -c "CREATE DATABASE leaddesk;"

# Run schema
psql -U postgres -d leaddesk -f backend/db/schema.sql
```

### 2. Backend

```bash
cd backend

# Copy env file and fill in your DB password
cp .env.example .env

# Download dependencies
go mod download

# Run the server (reads from .env if you use a tool like godotenv, or export vars)
export DATABASE_URL="postgres://postgres:yourpassword@localhost:5432/leaddesk?sslmode=disable"
go run main.go
# → Listening on :8080
```

### 3. Flutter Frontend

```bash
# From project root
flutter pub get

# Run in Chrome (development)
flutter run -d chrome

# Or build for production
flutter build web --dart-define=API_URL=https://your-backend.com
```

---

## API Reference

### POST `/api/leads`
Submit a new lead.

```json
// Request body
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "budget_range": "$1,000 – $5,000",
  "message": "I need a website for my business..."
}

// 201 Created
{ "data": { "id": 1, "name": "Jane Smith", ... "status": "New" } }

// 422 Unprocessable Entity
{ "error": "invalid email address" }
```

### GET `/api/leads?search=jane`
List all leads (admin). Optional `search` filters by name or email.

```json
{ "data": [ { "id": 1, ... }, { "id": 2, ... } ] }
```

### PATCH `/api/leads/:id/status`
Update a lead's status.

```json
// Request body
{ "status": "Contacted" }

// 200 OK
{ "data": { "id": 1, ..., "status": "Contacted" } }
```

### GET `/health`
```json
{ "status": "ok", "service": "leaddesk-api", "version": "1.0.0" }
```

---

## Admin Access & Authentication

Navigate to `/admin` on the deployed frontend.
Default password: `admin1234` (or whatever is set in `ADMIN_PASSWORD` env var).

**Authentication Approach:**
- **No Hardcoded Passwords:** The frontend no longer checks a hardcoded string. It sends a `POST /api/login` request.
- **Environment Variable Security:** The backend compares the password against the `ADMIN_PASSWORD` environment variable (which is secure on the server).
- **JWT (JSON Web Tokens):** If correct, the backend issues a signed JWT (using `JWT_SECRET`).
- **Client Storage:** The frontend stores the JWT in `SharedPreferences` (Local Storage on Web) and attaches it as `Authorization: Bearer <token>` on all protected requests.

> ⚠️ Change the `ADMIN_PASSWORD` environment variable on your backend host before deploying.

---

## Data Model

The application uses PostgreSQL with a single table:
```sql
CREATE TABLE leads (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  budget_range VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'New',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```
- **Statuses:** `New`, `Contacted`, `Closed`
- **Budget Ranges:** `< $1,000`, `$1,000 – $5,000`, `$5,000 – $20,000`, `$20,000+`

---

## Deployment Guide

See [DEPLOYMENT.md](./DEPLOYMENT.md) for step-by-step instructions on deploying to:
- **Backend** → Railway or Render (free tier, config `render.yaml` provided)
- **Frontend** → Netlify (free tier, config `netlify.toml` provided)
- **Database** → Supabase or Railway Postgres

---

## Loom Walkthrough 📹

> **[TODO: Add your Loom video link here]**

*In the Loom video, demonstrate:*
1. *Submitting a lead on the public landing page.*
2. *Logging in to the `/admin` area using the real password.*
3. *Viewing the submitted lead and changing its status.*

---

## Credit

Built for **[Digital Heroes Training Task](https://digitalheroesco.com)**
