package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"strings"
	"time"
)

type ATSClient struct {
	client         *http.Client
	atsURL         string
	timeout        time.Duration
	method         string
	trafficCtlPath string
}

func NewATSClient(config *Config) (*ATSClient, error) {
	return &ATSClient{
		client: &http.Client{
			Timeout: config.Timeout,
		},
		atsURL:         config.ATSURL,
		timeout:        config.Timeout,
		method:         config.Method,
		trafficCtlPath: config.TrafficCtlPath,
	}, nil
}

func (c *ATSClient) FetchMetrics() (*json.Decoder, error) {
	switch c.method {
	case MethodTrafficCtl:
		return c.fetchMetricsViaTrafficCtl()
	case MethodHTTP:
		return c.fetchMetricsViaHTTP()
	default:
		logger.Error("Unsupported ATS fetch method", "method", c.method)
		return nil, fmt.Errorf("unsupported ATS fetch method: %q", c.method)
	}
}

func (c *ATSClient) fetchMetricsViaHTTP() (*json.Decoder, error) {
	req, err := http.NewRequest(http.MethodGet, c.atsURL, nil)
	if err != nil {
		logger.Error("Failed to create request", "error", err)
		return nil, err
	}

	resp, err := c.client.Do(req)
	if err != nil {
		logger.Error("Failed to fetch metrics from ATS", "error", err, "url", c.atsURL)
		return nil, err
	}

	if resp == nil {
		logger.Error("Empty response from ATS")
		return nil, errors.New("empty response from ATS")
	}

	if resp.StatusCode != http.StatusOK {
		logger.Error("Unexpected status code from ATS",
			"status_code", resp.StatusCode,
			"url", c.atsURL,
		)
		resp.Body.Close()
		return nil, errors.New("unexpected status code")
	}

	body, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		logger.Error("Failed to read response body", "error", err)
		return nil, err
	}

	return json.NewDecoder(bytes.NewBuffer(body)), nil
}

func (c *ATSClient) fetchMetricsViaTrafficCtl() (*json.Decoder, error) {
	cmd := exec.Command(c.trafficCtlPath, "metric", "match", "proxy.process")

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		logger.Error("Failed to execute traffic_ctl",
			"error", err,
			"stderr", stderr.String(),
			"path", c.trafficCtlPath)
		return nil, fmt.Errorf("failed to execute traffic_ctl: %w, stderr: %s", err, stderr.String())
	}

	metricsMap := make(map[string]interface{})
	lines := strings.Split(stdout.String(), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		parts := strings.SplitN(line, " ", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		valueStr := strings.TrimSpace(parts[1])

		var value interface{}
		if strings.Contains(valueStr, ".") {
			if v, err := parseFloat(valueStr); err == nil {
				value = v
			} else {
				value = valueStr
			}
		} else {
			if v, err := parseInt(valueStr); err == nil {
				value = v
			} else {
				value = valueStr
			}
		}

		metricsMap[key] = value
	}

	jsonData := map[string]interface{}{
		"global": metricsMap,
	}

	jsonBytes, err := json.Marshal(jsonData)
	if err != nil {
		logger.Error("Failed to marshal metrics", "error", err)
		return nil, err
	}

	return json.NewDecoder(bytes.NewBuffer(jsonBytes)), nil
}

func parseInt(s string) (int64, error) {
	var i int64
	_, err := fmt.Sscanf(s, "%d", &i)
	return i, err
}

func parseFloat(s string) (float64, error) {
	var f float64
	_, err := fmt.Sscanf(s, "%f", &f)
	return f, err
}

func (c *ATSClient) GetMetricMap() (MetricMap, error) {
	d, err := c.FetchMetrics()
	if err != nil {
		return nil, err
	}
	return MakeMap(d), nil
}
