package config

import "testing"

func TestLoadDefaults(t *testing.T) {
	t.Setenv("QUIREA_LISTEN_ADDR", "")
	t.Setenv("QUIREA_INSTANCE_NAME", "")
	t.Setenv("QUIREA_STATIC_DIR", "")
	cfg := Load()
	if cfg.ListenAddress != "127.0.0.1:8174" {
		t.Fatalf("unexpected listen address: %s", cfg.ListenAddress)
	}
	if cfg.InstanceName != "Quirea" {
		t.Fatalf("unexpected instance name: %s", cfg.InstanceName)
	}
}
