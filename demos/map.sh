#!/usr/bin/env bash
# map.sh - simple map modification showcase

function hook_chunks() {
	chunk_header
	for (( i=0; i<4096; i++ )); do
		chunk+="$(printf '%02x' $((RANDOM%30)))"
	done
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000000

	pkt_chunk FFFFFFFF FFFFFFFF 00
	pkt_chunk FFFFFFFF 00000000 00
	pkt_chunk FFFFFFFF 00000001 00

	pkt_chunk 00000000 FFFFFFFF 00
	pkt_chunk 00000000 00000000
	pkt_chunk 00000000 00000001 00
	
	pkt_chunk 00000001 FFFFFFFF 00
	pkt_chunk 00000001 00000000 00
	pkt_chunk 00000001 00000001 00
}
