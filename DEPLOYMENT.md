# LeadDesk Mini — Deployment Guide

This guide walks you through deploying LeadDesk Mini for free using:
- **PostgreSQL** → Supabase (free tier)
- **Backend (Go)** → Railway or Render (free tier)
- **Frontend (Flutter Web)** → Netlify (free tier)

---

## Step 1 — PostgreSQL on Supabase

1. Go to [supabase.com](https://supabase.com) → **New project**
2. Choose a project name, region, and database password
3. Once ready, go to **Settings → Database → Connection string (URI)**
4. Copy the connection string — it looks like:
   ```
   postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres
   ```
5. Open the **SQL Editor** and paste + run the contents of `backend/db/schema.sql`

---

## Step 2 — Backend on Railway

### Option A: Railway (recommended)

1. Go to [railway.app](https://railway.app) → **New Project → Deploy from GitHub repo**
2. Select your repo → Railway auto-detects Go
3. Set the **Root Directory** to `backend/`
4. Add environment variables:
   ```
   DATABASE_URL  = <your Supabase connection string>
   PORT          = 8080
   ALLOWED_ORIGIN = https://your-netlify-site.netlify.app
   ```
5. Deploy → copy the generated URL (e.g. `https://leaddesk-backend.up.railway.app`)

### Option B: Render

1. Go to [render.com](https://render.com) → **New Web Service**
2. Connect your GitHub repo → set **Root Directory** to `backend/`
3. Build command: `go build -o server .`
4. Start command: `./server`
5. Add the same environment variables as above

---

## Step 3 — Frontend on Netlify

1. Build the Flutter web app with your backend URL:
   ```bash
   flutter build web --dart-define=API_URL=https://leaddesk-backend.up.railway.app
   ```
2. The output is in `build/web/`

3. Go to [netlify.com](https://netlify.com) → **Add new site → Deploy manually**
4. Drag and drop the `build/web/` folder
5. Your site is live at e.g. `https://leaddesk-mini.netlify.app`

6. **Important**: Add a `_redirects` file inside `build/web/`:
   ```
   /*    /index.html   200
   ```
   This makes Flutter's client-side routing (`/admin`) work correctly.

---

## Step 4 — Update CORS

Once you have your Netlify URL, go back to Railway/Render and update:
```
ALLOWED_ORIGIN = https://leaddesk-mini.netlify.app
```

Redeploy the backend.

---

## Step 5 — Verify

1. Open your Netlify URL → fill out the lead form → submit
2. Navigate to `https://your-netlify-url.netlify.app/admin`
3. Password: `admin1234` (change in `lib/screens/admin_page.dart` before production)
4. You should see your test lead listed

---

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `PORT` | ❌ | Server port (default: `8080`) |
| `ALLOWED_ORIGIN` | ❌ | CORS origin (default: `*`) |

---

## Netlify `_redirects` note

After `flutter build web`, create `build/web/_redirects` with:
```
/*    /index.html   200
```

This is needed for SPA routing to work (so `/admin` doesn't 404 on refresh).

---

*Built for [Digital Heroes Training Task](https://digitalheroesco.com)*
