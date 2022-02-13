#!/usr/bin/env bash
# chunk.sh - misc chunk functions

function chunk_header() {
	chunk="7fff" # amount of blocks, doesnt matter
	chunk+="08"   # palette - bits per block
	chunk+="$(int2varint ${#palette[@]})" # palette - entries amount

	chunk+="${palette[@]}"
}

function chunk_footer() {
	chunk+="0001" # biome palette
	chunk+="$(repeat 26 "0000000000000001")" # set biome to plains
}

function chunkfix() {
	sed -E 's/(.{8})(.{8})/\2\1/;'
}

function hexchunkfix() {
	sed -E 's/(.{16})(.{16})/\2\1/;'
}
