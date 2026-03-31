package main

import "time"

type Config struct {
	ATSURL   string
	Timeout  time.Duration
	LogLevel string
}