#!/usr/bin/env bash
# log.sh - logging functions

function log() {
	echo "[INFO] $@" >&2
}
function warn() {
	echo "[WARN] $@" >&2	
}
function err() {
	echo "[FAIL] $@" >&2		
}
function chatlog() {
	echo "[CHAT] $@" >&2	
}
function hexlog() {
	echo -n "$@" | xxd >&2	
}
function rhexlog() {
	echo -n "$@" | unhex | xxd >&2		
}
