// ──────────────────────────────────────────────────────────────────────────────
// LeadDesk Mini — Backend (all in one file)
//
// This single file contains EVERYTHING the server needs:
//   1. Database connection  (connectDB)
//   2. Lead data model      (Lead struct + SQL queries)
//   3. HTTP handlers        (createLead, listLeads, updateStatus, healthCheck)
//   4. CORS setup           (allowCrossDomain)
//   5. Main server          (main)
//
// Run it:
//   set DATABASE_URL=postgres://postgres:yourpassword@localhost:5432/leaddesk?sslmode=disable
//   go run main.go
// ──────────────────────────────────────────────────────────────────────────────

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/cors"
)

// ════════════════════════════════════════════════════════════════════════════
// SECTION 1 — DATABASE CONNECTION
// ════════════════════════════════════════════════════════════════════════════

// pool is the shared PostgreSQL connection pool used by all query functions.
var pool *pgxpool.Pool

// connectDB opens a connection to PostgreSQL.
// It reads the DATABASE_URL environment variable (recommended) or builds
// the connection string from individual DB_* variables.
func connectDB(ctx context.Context) error {
	dsn := os.Getenv("DATABASE_URL")

	if dsn == "" {
		// Build DSN from individual env vars (useful for local development)
		host := envOr("DB_HOST", "localhost")
		port := envOr("DB_PORT", "5432")
		user := envOr("DB_USER", "postgres")
		pass := envOr("DB_PASSWORD", "abhi15401")
		name := envOr("DB_NAME", "leaddesk")
		ssl  := envOr("DB_SSLMODE", "disable")
		dsn = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
			user, pass, host, port, name, ssl)
	}

	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return fmt.Errorf("bad DATABASE_URL: %w", err)
	}

	pool, err = pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return fmt.Errorf("cannot create pool: %w", err)
	}

	// Ping to verify the connection is actually working
	if err = pool.Ping(ctx); err != nil {
		return fmt.Errorf("cannot reach database: %w", err)
	}

	// Auto-create the leads table if it doesn't exist
	_, err = pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS leads (
			id SERIAL PRIMARY KEY,
			name VARCHAR(100) NOT NULL,
			email VARCHAR(255) NOT NULL,
			budget_range VARCHAR(50) NOT NULL,
			message TEXT NOT NULL,
			status VARCHAR(20) DEFAULT 'New',
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW()
		);
	`)
	if err != nil {
		return fmt.Errorf("failed to auto-create table: %w", err)
	}

	log.Println("✅  Database connected")
	return nil
}

// envOr returns the env var value, or a fallback if it's not set.
func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION 2 — DATA MODEL
// ════════════════════════════════════════════════════════════════════════════

// Lead maps to one row in the PostgreSQL `leads` table.
// json tags define the field names in API responses.
type Lead struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Email       string    `json:"email"`
	BudgetRange string    `json:"budget_range"`
	Message     string    `json:"message"`
	Status      string    `json:"status"`      // "New" | "Contacted" | "Closed"
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// validBudgets is the set of accepted budget range strings.
var validBudgets = map[string]bool{
	"< $1,000":         true,
	"$1,000 – $5,000":  true,
	"$5,000 – $20,000": true,
	"$20,000+":         true,
}

// validStatuses is the set of accepted status strings.
var validStatuses = map[string]bool{
	"New": true, "Contacted": true, "Closed": true,
}

// insertLead saves a new lead and returns the saved record (with id, created_at, etc.).
func insertLead(ctx context.Context, name, email, budget, message string) (*Lead, error) {
	// RETURNING makes PostgreSQL send back the full row after the insert.
	q := `INSERT INTO leads (name, email, budget_range, message)
	      VALUES ($1, $2, $3, $4)
	      RETURNING id, name, email, budget_range, message, status, created_at, updated_at`

	var l Lead
	err := pool.QueryRow(ctx, q, name, email, budget, message).Scan(
		&l.ID, &l.Name, &l.Email, &l.BudgetRange,
		&l.Message, &l.Status, &l.CreatedAt, &l.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("insertLead: %w", err)
	}
	return &l, nil
}

// listLeads returns all leads, newest first.
// If search is not empty, only rows where name or email contain that text are returned.
func listLeads(ctx context.Context, search string) ([]*Lead, error) {
	var (
		q    string
		args []any
	)

	if strings.TrimSpace(search) == "" {
		q = `SELECT id, name, email, budget_range, message, status, created_at, updated_at
		     FROM leads ORDER BY created_at DESC`
	} else {
		// ILIKE = case-insensitive LIKE; % is the wildcard character
		q = `SELECT id, name, email, budget_range, message, status, created_at, updated_at
		     FROM leads
		     WHERE name ILIKE $1 OR email ILIKE $1
		     ORDER BY created_at DESC`
		args = []any{"%" + strings.TrimSpace(search) + "%"}
	}

	rows, err := pool.Query(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("listLeads query: %w", err)
	}
	defer rows.Close()

	var leads []*Lead
	for rows.Next() {
		var l Lead
		if err := rows.Scan(
			&l.ID, &l.Name, &l.Email, &l.BudgetRange,
			&l.Message, &l.Status, &l.CreatedAt, &l.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("listLeads scan: %w", err)
		}
		leads = append(leads, &l)
	}
	return leads, rows.Err()
}

// updateLeadStatus changes the status of a lead by ID.
func updateLeadStatus(ctx context.Context, id int, status string) (*Lead, error) {
	q := `UPDATE leads SET status = $1, updated_at = NOW()
	      WHERE id = $2
	      RETURNING id, name, email, budget_range, message, status, created_at, updated_at`

	var l Lead
	err := pool.QueryRow(ctx, q, status, id).Scan(
		&l.ID, &l.Name, &l.Email, &l.BudgetRange,
		&l.Message, &l.Status, &l.CreatedAt, &l.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("updateLeadStatus: %w", err)
	}
	return &l, nil
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION 3 — HTTP HANDLERS
// ════════════════════════════════════════════════════════════════════════════

// sendJSON writes a success JSON response: { "data": <value> }
func sendJSON(w http.ResponseWriter, code int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]any{"data": data})
}

// sendError writes an error JSON response: { "error": "<message>" }
func sendError(w http.ResponseWriter, code int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]any{"error": msg})
}

// emailRe validates email format
var emailRe = regexp.MustCompile(`(?i)^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$`)

// ── JWT SETUP ────────────────────────────────────────────────────────────────
func getJWTSecret() []byte {
	return []byte(envOr("JWT_SECRET", "super-secret-key-for-dev"))
}

func getAdminPassword() string {
	return envOr("ADMIN_PASSWORD", "admin1234") // the required admin password
}

// authMiddleware wraps an http.HandlerFunc and checks for a valid JWT
func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			sendError(w, http.StatusUnauthorized, "Missing or invalid token")
			return
		}
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		
		token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method")
			}
			return getJWTSecret(), nil
		})

		if err != nil || !token.Valid {
			sendError(w, http.StatusUnauthorized, "Invalid token")
			return
		}

		next(w, r)
	}
}

// ── POST /api/login ──────────────────────────────────────────────────────────
func handleLogin(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid JSON body")
		return
	}

	if body.Password != getAdminPassword() {
		sendError(w, http.StatusUnauthorized, "Incorrect password")
		return
	}

	// Create JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"admin": true,
		"exp":   time.Now().Add(24 * time.Hour).Unix(),
	})

	tokenString, err := token.SignedString(getJWTSecret())
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Could not generate token")
		return
	}

	sendJSON(w, http.StatusOK, map[string]string{"token": tokenString})
}

// ── GET /health ──────────────────────────────────────────────────────────────
// Returns {"server":"ok","database":"ok"} so you can quickly verify the API is up.
func healthCheck(w http.ResponseWriter, r *http.Request) {
	dbStatus := "ok"
	code := http.StatusOK
	if err := pool.Ping(r.Context()); err != nil {
		dbStatus = "unavailable"
		code = http.StatusServiceUnavailable
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"server": "ok", "database": dbStatus})
}

// ── POST /api/leads ──────────────────────────────────────────────────────────
// Receives the lead form data, validates it, and saves it to the database.
func createLead(w http.ResponseWriter, r *http.Request) {
	// Step 1 — decode JSON body
	var body struct {
		Name        string `json:"name"`
		Email       string `json:"email"`
		BudgetRange string `json:"budget_range"`
		Message     string `json:"message"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid JSON body")
		return
	}

	// Step 2 — clean up whitespace
	name    := strings.TrimSpace(body.Name)
	email   := strings.ToLower(strings.TrimSpace(body.Email))
	budget  := body.BudgetRange
	message := strings.TrimSpace(body.Message)

	// Step 3 — server-side validation (never trust the client alone)
	switch {
	case name == "":
		sendError(w, http.StatusUnprocessableEntity, "Name is required"); return
	case len(name) < 2 || len(name) > 100:
		sendError(w, http.StatusUnprocessableEntity, "Name must be 2–100 characters"); return
	case !emailRe.MatchString(email):
		sendError(w, http.StatusUnprocessableEntity, "Enter a valid email address"); return
	case !validBudgets[budget]:
		sendError(w, http.StatusUnprocessableEntity, "Select a valid budget range"); return
	case len(message) < 10 || len(message) > 2000:
		sendError(w, http.StatusUnprocessableEntity, "Message must be 10–2000 characters"); return
	}

	// Step 4 — save to database
	lead, err := insertLead(r.Context(), name, email, budget, message)
	if err != nil {
		log.Printf("createLead error: %v", err)
		sendError(w, http.StatusInternalServerError, "Could not save your inquiry. Please try again.")
		return
	}

	// Step 5 — return the saved lead (HTTP 201 = Created)
	sendJSON(w, http.StatusCreated, lead)
}

// ── GET /api/leads ───────────────────────────────────────────────────────────
// Returns all leads. Add ?search=text to filter by name or email.
func handleListLeads(w http.ResponseWriter, r *http.Request) {
	search := r.URL.Query().Get("search")

	leads, err := listLeads(r.Context(), search)
	if err != nil {
		log.Printf("listLeads error: %v", err)
		sendError(w, http.StatusInternalServerError, "Could not fetch leads")
		return
	}

	// Always return an array (never null) even when empty
	if leads == nil {
		leads = []*Lead{}
	}
	sendJSON(w, http.StatusOK, leads)
}

// ── PATCH /api/leads/{id}/status ─────────────────────────────────────────────
// Changes the status of one lead. Body: { "status": "Contacted" }
func handleUpdateStatus(w http.ResponseWriter, r *http.Request) {
	// Parse {id} from URL: /api/leads/42/status → parts[2] = "42"
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 4 {
		sendError(w, http.StatusBadRequest, "Missing lead ID in URL"); return
	}
	id, err := strconv.Atoi(parts[2])
	if err != nil || id <= 0 {
		sendError(w, http.StatusBadRequest, "Lead ID must be a positive number"); return
	}

	var body struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid JSON body"); return
	}
	if !validStatuses[body.Status] {
		sendError(w, http.StatusUnprocessableEntity,
			"Status must be one of: New, Contacted, Closed"); return
	}

	lead, err := updateLeadStatus(r.Context(), id, body.Status)
	if err != nil {
		log.Printf("updateStatus error: %v", err)
		sendError(w, http.StatusInternalServerError, "Could not update status"); return
	}
	sendJSON(w, http.StatusOK, lead)
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION 4 — MAIN (server setup + start)
// ════════════════════════════════════════════════════════════════════════════

func main() {
	ctx := context.Background()

	// Connect to PostgreSQL
	if err := connectDB(ctx); err != nil {
		log.Fatalf("Database error: %v", err)
	}
	defer pool.Close()

	// Register routes
	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthCheck)
	mux.HandleFunc("/api/login", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			handleLogin(w, r)
			return
		}
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	})

	// /api/leads  → GET or POST
	mux.HandleFunc("/api/leads", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			authMiddleware(handleListLeads)(w, r)
		case http.MethodPost:
			createLead(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	// /api/leads/{id}/status  → PATCH only
	mux.HandleFunc("/api/leads/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPatch && strings.HasSuffix(r.URL.Path, "/status") {
			authMiddleware(handleUpdateStatus)(w, r)
			return
		}
		http.NotFound(w, r)
	})

	// Serve the Flutter frontend (Single Page Application)
	frontendPath := envOr("FRONTEND_PATH", "../build/web")
	fs := http.FileServer(http.Dir(frontendPath))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// If it's an API route that wasn't matched, return 404, don't serve HTML
		if strings.HasPrefix(r.URL.Path, "/api/") {
			http.NotFound(w, r)
			return
		}
		
		path := frontendPath + r.URL.Path
		info, err := os.Stat(path)
		if os.IsNotExist(err) || (err == nil && info.IsDir()) {
			// Route to index.html for Flutter's internal navigation (/admin)
			http.ServeFile(w, r, frontendPath+"/index.html")
			return
		}
		
		// Serve static assets (js, css, png, canvaskit)
		fs.ServeHTTP(w, r)
	})

	// Serve the Flutter frontend (Single Page Application)
	frontendPath := envOr("FRONTEND_PATH", "../build/web")
	fs := http.FileServer(http.Dir(frontendPath))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// If it's an API route that wasn't matched, return 404, don't serve HTML
		if strings.HasPrefix(r.URL.Path, "/api/") {
			http.NotFound(w, r)
			return
		}
		
		path := frontendPath + r.URL.Path
		info, err := os.Stat(path)
		if os.IsNotExist(err) || (err == nil && info.IsDir()) {
			// Route to index.html for Flutter's internal navigation (/admin)
			http.ServeFile(w, r, frontendPath+"/index.html")
			return
		}
		
		// Serve static assets (js, css, png, canvaskit)
		fs.ServeHTTP(w, r)
	})

	// CORS: allows Flutter Web (running on a different port) to call this API
	// In production set ALLOWED_ORIGIN=https://your-flutter-app.netlify.app
	allowedOrigin := envOr("ALLOWED_ORIGIN", "*")
	handler := cors.New(cors.Options{
		AllowedOrigins: []string{allowedOrigin},
		AllowedMethods: []string{"GET", "POST", "PATCH", "OPTIONS"},
		AllowedHeaders: []string{"Content-Type", "Accept", "Authorization"},
	}).Handler(mux)

	// Start server
	port := envOr("PORT", "8080")
	server := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	go func() {
		log.Printf("🚀  LeadDesk API running at http://localhost:%s", port)
		log.Printf("    Health check → http://localhost:%s/health", port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Wait for Ctrl+C then shut down cleanly
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down...")
	shutCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	server.Shutdown(shutCtx)
	log.Println("Done.")
}
