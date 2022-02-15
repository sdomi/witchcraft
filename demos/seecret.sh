#!/usr/bin/env bash
# this example requires 'libqrencode'

palette+=("af0b") # black wool
palette+=("a00b") # white wool


data="$(qrencode -t ASCII "$(base64 -d <<< "aHR0cHM6Ly95b3V0dS5iZS9kUXc0dzlXZ1hjUQ==")" | grep -vP '^ *$' | sed -E 's/##/#/g;s/  / /g;s/^    //')"
m="$(echo -n "$data" | cut -c 1-16 | head -n 16)"
m2="$(echo -n "$data" | cut -c 17- | head -n 16 | sed -E 's/$/   /g')"
m3="$(echo -n "$data" | cut -c 1-16 | tail -n 9)"
m4="$(echo -n "$data" | cut -c 17- | tail -n 9 | sed -E 's/$/   /g')"

function hook_chunks() {
	rm -R $TEMP/world/*
	chunk_header
	chunk+=$(echo -n "$m2" | chunkfix | sed -E 's/#/1f/g;s/ /20/g')
	chunk+=$(repeat $((4096-256)) 00)
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000000

	chunk_header
	chunk+=$(echo -n "$m4" | chunkfix | sed -E 's/#/1f/g;s/ /20/g')
	chunk+=$(repeat $((4096-256)) 00)
	chunk+=$(repeat $((9*16)) 00)
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000001

	chunk_header
	chunk+=$(echo -n "$m" | chunkfix | sed -E 's/#/1f/g;s/ /20/g')
	chunk+=$(repeat $((4096-256)) 00)
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000100000000

	chunk_header
	chunk+=$(echo -n "$m3" | chunkfix | sed -E 's/#/1f/g;s/ /20/g')
	chunk+=$(repeat $((4096-256)) 00)
	chunk+=$(repeat $((9*16)) 00)
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000100000001

	pkt_chunk FFFFFFFF FFFFFFFF 00
	pkt_chunk FFFFFFFF 00000000 00
	pkt_chunk FFFFFFFF 00000001 00
	pkt_chunk FFFFFFFF 00000002 00

	pkt_chunk 00000000 FFFFFFFF 00
	pkt_chunk 00000000 00000000 00
	pkt_chunk 00000000 00000001 00
	pkt_chunk 00000000 00000002 00

	pkt_chunk 00000001 FFFFFFFF 00
	pkt_chunk 00000001 00000000 00
	pkt_chunk 00000001 00000001 00
	pkt_chunk 00000001 00000002 00

	pkt_chunk 00000002 FFFFFFFF 00
	pkt_chunk 00000002 00000000 00
	pkt_chunk 00000002 00000001 00
	pkt_chunk 00000002 00000002 00
}
