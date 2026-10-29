package main

import (
	"encoding/json"
	"net/http"
	"os"
)

type healthResponse struct {
	Status string `json:"status"`
}

type versionResponse struct {
	Version string `json:"version"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(healthResponse{Status: "ok"})
}

func versionHandler(w http.ResponseWriter, r *http.Request) {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "dev"
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(versionResponse{Version: version})
}

func newMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", healthHandler)
	mux.HandleFunc("GET /version", versionHandler)
	return mux
}
