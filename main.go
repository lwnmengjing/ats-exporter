package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var logger *slog.Logger

func initLogger(logLevel string) {
	var level slog.Level
	switch logLevel {
	case "debug":
		level = slog.LevelDebug
	case "info":
		level = slog.LevelInfo
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	default:
		level = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{Level: level}
	handler := slog.NewTextHandler(os.Stdout, opts)
	logger = slog.New(handler)
	slog.SetDefault(logger)
}

func main() {
	var (
		listenAddress = flag.String("web.listen-address", ":9090", "Address to listen on for web interface and telemetry.")
		metricsPath   = flag.String("web.telemetry-path", "/metrics", "Path under which to expose metrics.")
		atsURL        = flag.String("ats.url", "http://localhost:80/_stats", "URL to Apache Traffic Server stats endpoint.")
		atsTimeout    = flag.Duration("ats.timeout", 10*time.Second, "Timeout for scraping ATS.")
		logLevel      = flag.String("log.level", "info", "Log level (debug, info, warn, error).")
		showVersion   = flag.Bool("version", false, "Print version information and exit.")
	)
	flag.Parse()

	initLogger(*logLevel)

	if *showVersion {
		fmt.Printf("ats-exporter\nVersion: %s\nRevision: %s\nBranch: %s\nBuildDate: %s\nGoVersion: %s\n",
			Version, Revision, Branch, BuildDate, GoVersion)
		os.Exit(0)
	}

	logger.Info("Starting ATS exporter",
		"ats_url", *atsURL,
		"listen", *listenAddress,
		"metrics_path", *metricsPath,
		"version", Version,
		"revision", Revision,
		"branch", Branch,
		"buildDate", BuildDate,
	)

	config := &Config{
		ATSURL:   *atsURL,
		Timeout:  *atsTimeout,
		LogLevel: *logLevel,
	}

	client, err := NewATSClient(config)
	if err != nil {
		logger.Error("Failed to create ATS client", "error", err)
		os.Exit(1)
	}

	collector := NewCollector(client)
	prometheus.MustRegister(collector)

	http.Handle(*metricsPath, promhttp.Handler())
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`<html>
<head><title>ATS Exporter</title></head>
<body>
<h1>Apache Traffic Server Exporter</h1>
<p><a href='` + *metricsPath + `'>Metrics</a></p>
</body>
</html>`))
	})

	server := &http.Server{
		Addr:         *listenAddress,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		logger.Info("Listening on address", "address", *listenAddress)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- err
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-errCh:
		logger.Error("Server error", "error", err)
		os.Exit(1)
	case sig := <-quit:
		logger.Info("Received signal, shutting down", "signal", sig.String())
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Server shutdown error", "error", err)
	}

	logger.Info("Server stopped")
}
