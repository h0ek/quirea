package main

import (
	"context"
	"log/slog"
	"os/signal"
	"syscall"
	"time"

	"github.com/h0ek/quirea/internal/config"
	"github.com/h0ek/quirea/internal/runtimeinfo"
)

func main() {
	cfg := config.Load()
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	slog.Info("quirea worker started", "version", runtimeinfo.Version, "interval", cfg.WorkerInterval)
	ticker := time.NewTicker(cfg.WorkerInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			slog.Info("quirea worker stopped")
			return
		case <-ticker.C:
			slog.Info("worker heartbeat")
		}
	}
}
