#!/usr/bin/env bash
# misc.sh - helper functions

function repeat() {
	printf -- "$2%.0s" $(seq 1 $1)
}

function unhex() {
	xxd -p -r -c999999
}
