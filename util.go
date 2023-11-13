package main

import "os"

// MustHostname returns the hostname of the machine or panics
func MustHostname() string {
	name, err := os.Hostname()
	if err != nil {
		panic(err)
	}
	return name
}
