package httpserver

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/h0ek/quirea/internal/config"
)

func TestHealth(t *testing.T) {
	server := New(config.Config{ListenAddress: "127.0.0.1:0", InstanceName: "Quirea"})
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()
	server.HTTPServer().Handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", rr.Code)
	}
	if rr.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatal("security headers missing")
	}
}

func TestLocalization(t *testing.T) {
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, "locales"), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "locales", "en.json"), []byte(`{"name":"English","messages":{"tagline":"Follow what matters."}}`), 0644); err != nil {
		t.Fatal(err)
	}
	server := New(config.Config{StaticDir: dir})
	for _, tc := range []struct {
		path   string
		status int
		needle string
	}{
		{"/locales", http.StatusOK, `"code":"en"`},
		{"/locales/en.json", http.StatusOK, `"tagline"`},
		{"/locales/..json", http.StatusNotFound, ""},
		{"/locales/missing.json", http.StatusNotFound, ""},
	} {
		request := httptest.NewRequest(http.MethodGet, tc.path, nil)
		recorder := httptest.NewRecorder()
		server.HTTPServer().Handler.ServeHTTP(recorder, request)
		if recorder.Code != tc.status || !strings.Contains(recorder.Body.String(), tc.needle) {
			t.Errorf("%s: status %d, body %q", tc.path, recorder.Code, recorder.Body.String())
		}
	}
}

func TestBrandAssets(t *testing.T) {
	dir := t.TempDir()
	cases := []struct {
		name        string
		contentType string
	}{
		{"logo.svg", "image/svg+xml"},
		{"favicon.ico", "image/x-icon"},
		{"apple-touch-icon.png", "image/png"},
		{"icon-192.png", "image/png"},
		{"icon-512.png", "image/png"},
	}
	for _, tc := range cases {
		if err := os.WriteFile(filepath.Join(dir, tc.name), []byte("asset"), 0644); err != nil {
			t.Fatal(err)
		}
	}
	server := New(config.Config{StaticDir: dir})
	for _, tc := range cases {
		rr := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/"+tc.name, nil)
		server.HTTPServer().Handler.ServeHTTP(rr, req)
		if rr.Code != http.StatusOK {
			t.Errorf("%s status=%d", tc.name, rr.Code)
		}
		if got := rr.Header().Get("Content-Type"); got != tc.contentType {
			t.Errorf("%s content-type=%q", tc.name, got)
		}
	}
}
