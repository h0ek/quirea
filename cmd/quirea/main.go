package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/h0ek/quirea/internal/config"
	"github.com/h0ek/quirea/internal/httpserver"
	"github.com/h0ek/quirea/internal/runtimeinfo"
)

func main() {
	command := "serve"
	if len(os.Args) > 1 {
		command = os.Args[1]
	}

	switch command {
	case "serve":
		serve()
	case "doctor":
		doctor()
	case "version", "--version", "-v":
		fmt.Println(runtimeinfo.Version)
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", command)
		os.Exit(2)
	}
}

func serve() {
	cfg := config.Load()
	server := httpserver.New(cfg)
	errCh := make(chan error, 1)
	go func() {
		errCh <- server.ListenAndServe()
	}()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-sigCh:
		slog.Info("shutdown requested", "signal", sig.String())
	case err := <-errCh:
		if !errors.Is(err, http.ErrServerClosed) {
			slog.Error("web server failed", "error", err)
			os.Exit(1)
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.HTTPServer().Shutdown(ctx); err != nil {
		slog.Error("shutdown failed", "error", err)
		os.Exit(1)
	}
}

func doctor() {
	cfg := config.Load()
	status := "OK"
	if cfg.BaseURL == "" {
		fmt.Println("[WARN] QUIREA_BASE_URL is not configured")
		status = "WARN"
	} else {
		fmt.Printf("[OK] Base URL: %s\n", cfg.BaseURL)
	}
	if cfg.DatabaseURL == "" {
		fmt.Println("[WARN] QUIREA_DATABASE_URL is not configured")
		status = "WARN"
	} else {
		fmt.Println("[OK] Database URL configured")
	}
	if _, err := os.Stat(cfg.StaticDir); err != nil {
		fmt.Printf("[WARN] Static directory unavailable: %s\n", cfg.StaticDir)
		status = "WARN"
	} else {
		fmt.Printf("[OK] Static directory: %s\n", cfg.StaticDir)
	}
	fmt.Printf("Result: %s\n", status)
}
