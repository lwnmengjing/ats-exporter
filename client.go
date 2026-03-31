package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"
)

type ATSClient struct {
	client  *http.Client
	atsURL  string
	timeout time.Duration
}

func NewATSClient(config *Config) (*ATSClient, error) {
	return &ATSClient{
		client: &http.Client{
			Timeout: config.Timeout,
		},
		atsURL:  config.ATSURL,
		timeout: config.Timeout,
	}, nil
}

func (c *ATSClient) FetchMetrics() (*json.Decoder, error) {
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

func (c *ATSClient) GetMetricMap() (MetricMap, error) {
	d, err := c.FetchMetrics()
	if err != nil {
		return nil, err
	}
	return MakeMap(d), nil
}