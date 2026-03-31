package main

import "time"

type Config struct {
	ATSURL         string
	Timeout        time.Duration
	LogLevel       string
	Method         string
	TrafficCtlPath string
}

const (
	MethodHTTP        = "http"
	MethodTrafficCtl  = "traffic_ctl"
	DefaultTrafficCtl = "traffic_ctl"
)
