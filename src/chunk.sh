#!/usr/bin/env bash
# chunk.sh - misc chunk functions

function chunk_header() {
	chunk="7fff"  # amount of blocks, doesnt matter
	chunk+="08"   # palette - bits per block
	chunk+="$(int2varint ${#palette[@]})" # palette - entries amount

	chunk+="${palette[@]}"

	chunk+="8004" # len of next array
}

function chunk_footer() {
	chunk+="00 01 00" # biome palette (plains): bits, biome, array length
	chunk+="$(repeat 23 "0000 000000 000100")"  # empty (air) paletted container + plains palette
}

function chunkfix() {
	sed -E 's/(.{8})(.{8})/\2\1/;'
}

function hexchunkfix() {
	sed -E 's/(.{16})(.{16})/\2\1/;'
}
