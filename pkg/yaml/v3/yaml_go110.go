// This file contains changes that are only compatible with go 1.10 and onwards.

// +build go1.10
package v3

import (
	"github.com/json-iterator/go"
)

// DisallowUnknownFields configures the JSON decoder to error out if unknown
// fields come along, instead of dropping them by default.
func DisallowUnknownFields(d *json.Decoder) *json.Decoder {
	d.DisallowUnknownFields()
	return d
}
