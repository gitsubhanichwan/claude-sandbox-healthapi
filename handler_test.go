package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthGET(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	newMux().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	if ct := rec.Header().Get("Content-Type"); ct != "application/json" {
		t.Errorf("Content-Type = %q, want application/json", ct)
	}

	var got healthResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	if got.Status != "ok" {
		t.Errorf("status field = %q, want %q", got.Status, "ok")
	}
}

func TestHealthMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/health", nil)
	rec := httptest.NewRecorder()

	newMux().ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func getVersion(t *testing.T) versionResponse {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	rec := httptest.NewRecorder()

	newMux().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	var got versionResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	return got
}

func TestVersionDefault(t *testing.T) {
	t.Setenv("APP_VERSION", "")
	if got := getVersion(t); got.Version != "dev" {
		t.Errorf("version = %q, want %q", got.Version, "dev")
	}
}

func TestVersionFromEnv(t *testing.T) {
	t.Setenv("APP_VERSION", "1.2.3")
	if got := getVersion(t); got.Version != "1.2.3" {
		t.Errorf("version = %q, want %q", got.Version, "1.2.3")
	}
}
