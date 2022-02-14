#!/usr/bin/env bash
# v.sh - a valentine card for my gfs <3

palette+=("c10b") # red tulip
palette+=("c20b") # orange tulip
palette+=("c30b") # white tulip
palette+=("00") # air (for the random gen)
palette+=("00") # air
palette+=("00") # air
palette+=("e64b") # red concrete
palette+=("f98001") # polished blackstone bricks
palette+=("d84b") # white concrete
palette+=("ae0b") # red wool

spawn_pos=(8 -63 5)
gamemode=00

function hook_chunks() {
	log "hooking chunks"

	if [[ $nick != 'selfisekai' && $nick != 'MaeIsBadAtDev' && $nick != 'Domi_UwU' ]]; then
		pkt_disconnect "§asomething something hmu if you wanna go in"
	fi
	
	rm -R $TEMP/world/* # regenerate chunks

	mmm='
________________
________________
________________
________________
____^^____^^____
___^..^__^..^___
__^.,..__....^__
__^....^^....^__
__^..........^__
__^..........^__
___^........^___
____^......^____
_____^....^_____
______^..^______
______@^^@______
_____@@@@@@_____
________________'
	mmmap="$(echo -n "$mmm" | chunkfix | sed -E 's/\./25/g;s/#/02/g;s/,/27/g;s/_/00/g;s/@/26/g;s/\^/28/g')"
	chunk_header

	#chunk+="$mmmap"
	#for (( j=0; j<15; j++ )); do
	#	for (( i=0; i<256; i++ )); do
	#		chunk+="$(printf '%02x' 00)"
	#	done
	#done

	for (( y=0; y<16; y++ )); do
		if [[ $y == 0 ]]; then
			#for (( x=0; x<16; x++ )); do
			#	if [[ $x == 8 ]]; then
			#		chunk+="08"
			#	else
			#		chunk+="02"
			#	fi
			#done
			chunk+="$(repeat 256 "02")"
		elif [[ $y == 1 ]]; then
			for (( i=0; i<$((256-16)); i++ )); do
				chunk+=$(printf '%02x' $(((RANDOM%6)+31)))
			done
			b=''
			for i in {1..5}; do b+=$(printf '%02x' $(((RANDOM%6)+31))); done
			for i in {1..6}; do b+='26'; done
			for i in {1..5}; do b+=$(printf '%02x' $(((RANDOM%6)+31))); done
			chunk+="$(tr -d '\n' <<< "$b" | hexchunkfix)"			
		else
			for (( x=0; x<16; x++ )); do
				if [[ $x == 15 ]]; then
					chunk+="$(echo -n "$mmmap" | tail -n $((y+1)) | head -n1)"
					log "Y: $y, X: $x, $(echo -n "$mmmap" | tail -n $y | head -n1)"
				else
					for (( z=0; z<16; z++ )); do
						chunk+="00"
					done
				fi
			done
		fi
	done

	#for (( i=0; i<256; i++ )); do
	#	chunk+="00"
	#done

	chunk_footer

	echo "$chunk" > $TEMP/world/0000000000000000
	#log "$chunk"

	chunk_header
	chunk+="$(repeat 256 "02")"

	for (( i=0; i<256; i++ )); do
		chunk+="$(printf '%02x' $(((RANDOM%6)+31)))"
	done
	
	chunk+="$(repeat $((4096-512)) "00")"
	chunk_footer
	
	echo "$chunk" > $TEMP/world/FFFFFFFFFFFFFFFF
	echo "$chunk" > $TEMP/world/FFFFFFFF00000000
	echo "$chunk" > $TEMP/world/FFFFFFFF00000001

	echo "$chunk" > $TEMP/world/00000000FFFFFFFF
	echo "$chunk" > $TEMP/world/0000000000000001

	echo "$chunk" > $TEMP/world/00000001FFFFFFFF
	echo "$chunk" > $TEMP/world/0000000100000000
	echo "$chunk" > $TEMP/world/0000000100000001


	pkt_chunk FFFFFFFE FFFFFFFE 01
	pkt_chunk FFFFFFFE FFFFFFFF 01
	pkt_chunk FFFFFFFE 00000000 01
	pkt_chunk FFFFFFFE 00000001 01
	pkt_chunk FFFFFFFE 00000002 01

	pkt_chunk FFFFFFFF FFFFFFFE 01
	pkt_chunk FFFFFFFF FFFFFFFF
	pkt_chunk FFFFFFFF 00000000
	pkt_chunk FFFFFFFF 00000001
	pkt_chunk FFFFFFFF 00000002

	pkt_chunk 00000000 FFFFFFFE 01
	pkt_chunk 00000000 FFFFFFFF
	pkt_chunk 00000000 00000000
	pkt_chunk 00000000 00000001
	pkt_chunk 00000000 00000002
	
	pkt_chunk 00000001 FFFFFFFE 01
	pkt_chunk 00000001 FFFFFFFF
	pkt_chunk 00000001 00000000
	pkt_chunk 00000001 00000001
	pkt_chunk 00000001 00000002

	pkt_chunk 00000002 FFFFFFFE 01
	pkt_chunk 00000002 FFFFFFFF
	pkt_chunk 00000002 00000000
	pkt_chunk 00000002 00000001
	pkt_chunk 00000002 00000002

	pkt_particle ${spawn_pos[0]} ${spawn_pos[1]} ${spawn_pos[2]} 33 100
}

function async_particles() {
	while true; do
		pkt_particle 4 -60 12 33 10
		pkt_particle 12 -60 12 33 10
		sleep 0.5
		if [[ ! -a $TEMP/players/$nick ]]; then # die if disconnected
			break
		fi
	done	
}

function hook_swing() {
	pkt_particle 4 -60 12 33 128
	pkt_particle 12 -60 12 33 128
	log "received Arm Swing"
}

function hook_ping() {
	json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"§c♡♡♡§a h,,hi --><-- §c♡♡♡  §r \ncome see what I made?"},"favicon":"data:image/png;base64,'"$(base64 -w0 icon.png)"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	echo "$(hexpacket_len "$res")00$res" | xxd -p -r
}

function hook_start() {
	pkt_particle ${spawn_pos[0]} ${spawn_pos[1]} ${spawn_pos[2]} 33 10
	if [[ $nick == "selfisekai" ]]; then
		pkt_title "§dLauren §c<3"
		sleep 2
		pkt_title "Thanks for being here ^^"
		pkt_subtitle "You mean the world to me <3"
	elif [[ $nick == "MaeIsBadAtDev" ]]; then
		pkt_title "§aMaja §c<3"
		sleep 2
		pkt_title "Thanks for being awesome ^^"
		pkt_subtitle "I love you <3"
	elif [[ $nick == "Domi_UwU" ]]; then
		pkt_title "§ddomi §cDEBUG"
		sleep 2
		pkt_title "Thanks for being here for me ^^"
		pkt_subtitle "You mean a lot to me <3"
		pkt_subtitle uwu
		pkt_subtitle uwu
		pkt_subtitle uwu
	fi
	async_particles &
}
