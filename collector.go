package main

import (
	"sync"

	"github.com/prometheus/client_golang/prometheus"
)

type Collector struct {
	client   *ATSClient
	mutex    sync.RWMutex
	metrics  map[string]*prometheus.Desc
	upMetric prometheus.Gauge
}

func NewCollector(client *ATSClient) *Collector {
	return &Collector{
		client:  client,
		metrics: initMetricDescriptions(),
		upMetric: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "ats_up",
			Help: "Was the last scrape of Apache Traffic Server successful.",
		}),
	}
}

func initMetricDescriptions() map[string]*prometheus.Desc {
	metrics := make(map[string]*prometheus.Desc)

	for _, m := range MetricDefinitions {
		metrics[m.ATSKey] = prometheus.NewDesc(
			m.Name,
			m.Help,
			nil,
			nil,
		)
	}

	return metrics
}

func (c *Collector) Describe(ch chan<- *prometheus.Desc) {
	for _, desc := range c.metrics {
		ch <- desc
	}
	ch <- c.upMetric.Desc()
}

func (c *Collector) Collect(ch chan<- prometheus.Metric) {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	metricMap, err := c.client.GetMetricMap()
	if err != nil {
		c.upMetric.Set(0)
		ch <- c.upMetric
		logger.Error("Failed to collect metrics from ATS", "error", err)
		return
	}

	c.upMetric.Set(1)
	ch <- c.upMetric

	for key, desc := range c.metrics {
		if value, ok := metricMap[key]; ok {
			metric, err := prometheus.NewConstMetric(desc, prometheus.GaugeValue, value)
			if err != nil {
				logger.Error("Failed to create metric", "key", key, "error", err)
				continue
			}
			ch <- metric
		}
	}

	logger.Debug("Metrics collected successfully")
}