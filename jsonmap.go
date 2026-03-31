package main

import (
	"encoding/json"
	"strconv"
	"strings"
)

type MetricMap map[string]float64

func MakeMap(d *json.Decoder) MetricMap {
	flMap := make(MetricMap)
	var output map[string]interface{}
	if d == nil {
		return flMap
	}

	if err := d.Decode(&output); err != nil {
		return flMap
	}
	addFields(&flMap, "", output)
	return flMap
}

func addFields(toMap *MetricMap, basename string, source map[string]interface{}) {
	prefix := ""
	if basename != "" {
		prefix = basename + "."
	}
	for k, v := range source {
		key := prefix + k
		switch value := v.(type) {
		case float64:
			(*toMap)[stripGlobalPrefix(key)] = value
		case string:
			f, err := strconv.ParseFloat(value, 64)
			if err == nil {
				(*toMap)[stripGlobalPrefix(key)] = f
			}
		case map[string]interface{}:
			addFields(toMap, key, value)
		}
	}
}

func stripGlobalPrefix(key string) string {
	return strings.TrimPrefix(key, "global.")
}
