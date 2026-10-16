package config

import (
	"os"
	"strings"
	"time"
)

type Config struct {
	ListenAddress  string
	InstanceName   string
	BaseURL        string
	DatabaseURL    string
	StaticDir      string
	WorkerInterval time.Duration
}

func Load() Config {
	return Config{
		ListenAddress:  getenv("QUIREA_LISTEN_ADDR", "127.0.0.1:8174"),
		InstanceName:   getenv("QUIREA_INSTANCE_NAME", "Quirea"),
		BaseURL:        strings.TrimRight(os.Getenv("QUIREA_BASE_URL"), "/"),
		DatabaseURL:    os.Getenv("QUIREA_DATABASE_URL"),
		StaticDir:      getenv("QUIREA_STATIC_DIR", "/usr/local/share/quirea"),
		WorkerInterval: duration("QUIREA_WORKER_INTERVAL", time.Minute),
	}
}

func getenv(key, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func duration(key string, fallback time.Duration) time.Duration {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := time.ParseDuration(value)
	if err != nil || parsed <= 0 {
		return fallback
	}
	return parsed
}
