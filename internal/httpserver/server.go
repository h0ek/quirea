package httpserver

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/h0ek/quirea/internal/config"
	"github.com/h0ek/quirea/internal/runtimeinfo"
)

var localeCode = regexp.MustCompile(`^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$`)

type Server struct {
	cfg  config.Config
	http *http.Server
}

func New(cfg config.Config) *Server {
	mux := http.NewServeMux()
	s := &Server{cfg: cfg}
	mux.HandleFunc("GET /", s.index)
	mux.HandleFunc("GET /app.css", s.asset)
	mux.HandleFunc("GET /app.js", s.asset)
	mux.HandleFunc("GET /logo.svg", s.asset)
	mux.HandleFunc("GET /favicon.ico", s.asset)
	mux.HandleFunc("GET /apple-touch-icon.png", s.asset)
	mux.HandleFunc("GET /icon-192.png", s.asset)
	mux.HandleFunc("GET /icon-512.png", s.asset)
	mux.HandleFunc("GET /locales", s.locales)
	mux.HandleFunc("GET /locales/{file}", s.locale)
	mux.HandleFunc("GET /healthz", s.health)
	mux.HandleFunc("GET /readyz", s.ready)
	mux.HandleFunc("GET /status", s.status)
	s.http = &http.Server{
		Addr:              cfg.ListenAddress,
		Handler:           securityHeaders(mux),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    1 << 20,
	}
	return s
}

func (s *Server) HTTPServer() *http.Server {
	return s.http
}

func (s *Server) ListenAndServe() error {
	slog.Info("quirea web started", "listen", s.cfg.ListenAddress, "version", runtimeinfo.Version)
	return s.http.ListenAndServe()
}

func (s *Server) index(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	path := filepath.Join(s.cfg.StaticDir, "index.html")
	body, err := os.ReadFile(path)
	if err != nil {
		http.Error(w, "Quirea static files are not available", http.StatusServiceUnavailable)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(body)
}

func (s *Server) asset(w http.ResponseWriter, r *http.Request) {
	var contentType string
	switch r.URL.Path {
	case "/app.css":
		contentType = "text/css; charset=utf-8"
	case "/app.js":
		contentType = "text/javascript; charset=utf-8"
	case "/logo.svg":
		contentType = "image/svg+xml"
	case "/favicon.ico":
		contentType = "image/x-icon"
	case "/apple-touch-icon.png", "/icon-192.png", "/icon-512.png":
		contentType = "image/png"
	default:
		http.NotFound(w, r)
		return
	}
	path := filepath.Join(s.cfg.StaticDir, strings.TrimPrefix(r.URL.Path, "/"))
	body, err := os.ReadFile(path)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", contentType)
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(body)
}

func (s *Server) locales(w http.ResponseWriter, _ *http.Request) {
	dir := filepath.Join(s.cfg.StaticDir, "locales")
	entries, err := os.ReadDir(dir)
	if err != nil {
		http.Error(w, "Language files are not available", http.StatusServiceUnavailable)
		return
	}
	languages := make([]map[string]string, 0, len(entries))
	for _, entry := range entries {
		if !entry.Type().IsRegular() || !strings.HasSuffix(entry.Name(), ".json") {
			continue
		}
		code := strings.TrimSuffix(entry.Name(), ".json")
		if !localeCode.MatchString(code) {
			continue
		}
		body, err := os.ReadFile(filepath.Join(dir, entry.Name()))
		if err != nil || len(body) > 65536 {
			continue
		}
		var data struct {
			Name string `json:"name"`
		}
		if json.Unmarshal(body, &data) != nil || strings.TrimSpace(data.Name) == "" {
			continue
		}
		languages = append(languages, map[string]string{"code": code, "name": data.Name})
	}
	writeJSON(w, http.StatusOK, languages)
}

func (s *Server) locale(w http.ResponseWriter, r *http.Request) {
	file := r.PathValue("file")
	if !strings.HasSuffix(file, ".json") || !localeCode.MatchString(strings.TrimSuffix(file, ".json")) {
		http.NotFound(w, r)
		return
	}
	body, err := os.ReadFile(filepath.Join(s.cfg.StaticDir, "locales", file))
	if err != nil || len(body) > 65536 || !json.Valid(body) {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	_, _ = w.Write(body)
}

func (s *Server) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"status": "ok"})
}

func (s *Server) ready(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"status": "ready"})
}

func (s *Server) status(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"application": "operational",
		"version":     runtimeinfo.Version,
		"instance":    s.cfg.InstanceName,
	})
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Security-Policy", "default-src 'self'; img-src 'self' data:; style-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	body, err := json.Marshal(value)
	if err != nil {
		http.Error(w, fmt.Sprintf("encoding error: %v", err), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(body)
}
