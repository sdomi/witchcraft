#!/usr/bin/env bash
# digmeout - a score-based minigame
# mine out as much ores before the time runs out

time_left=30
score=0
spawn_pos=(8 -40 8)
gamemode=00

# palette expanded for easier randomization
palette+=("45")			# gold
palette+=("47")			# iron
palette+=("49")			# coal
palette+=("8702")		# lapis
palette+=("d21a")		# diamond
palette+=("cf2a")		# emerald
palette+=("9a8b01")		# copper
palette+=("f11e")		# redstone
for i in {1..15}; do
	palette+=("01")		# stone
	palette+=("02")		# granite
	palette+=("04")		# diorite
done

function hook_chunks() {
	local ore
	local plane
	
	rm -R $TEMP/world/*
	chunk_header

	oremap=()
	for (( y=0; y<16; y++ )); do
		plane=''
		for (( x=0; x<16; x++ )); do
			for (( z=0; z<16; z++ )); do
				ore=$(printf '%02x' $(((RANDOM%52)+31)))
				chunk+="$ore"
				plane+="$ore"
			done
		done
		oremap+=("$plane")
	done

	chunk_footer

	echo "${oremap[@]}" > $TEMP/players/$nick/oremap
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

	echo '0' > $TEMP/players/$nick/score
	pkt_title "Get, set..."
}

function hook_start() {
	timer &
	pkt_title "Go!"
}

function timer() {
	while true; do
		if [[ $time_left -le 0 ]]; then
			pos=$(cat $TEMP/players/$nick/position)
			pkt_effect $(awk -F, '{print $1}' <<< "$pos") $(awk -F, '{print $2}' <<< "$pos") $(awk -F, '{print $3}' <<< "$pos") 1032
			sleep 1
			break
		elif [[ $time_left -le 5 ]]; then
			sleep 1
			pos=$(cat $TEMP/players/$nick/position)
			pkt_effect $(awk -F, '{print $1}' <<< "$pos") $(awk -F, '{print $2}' <<< "$pos") $(awk -F, '{print $3}' <<< "$pos") 1000
			time_left=$((time_left-1))
		elif [[ $time_left -le 10 ]]; then
			sleep 5
			time_left=$((time_left-5))
		else
			sleep 10
			time_left=$((time_left-10))
		fi
		if [[ ! -a $TEMP/players/$nick ]]; then # die if disconnected
			break
		fi
		pkt_chatmessage "§aTime left: §r${time_left}s" "00000000000000000000000000000000"
	done
	pkt_disconnect "Time's up! Your final score: §a$(cat $TEMP/players/$nick/score)"
}

function score() {
	# egh, async in Bash sucks
	score=$(cat $TEMP/players/$nick/score)
	if [[ "$block" == 45 ]]; then
		score=$((score+7))
	elif [[ "$block" == 47 ]]; then
		score=$((score+5))
	elif [[ "$block" == 49 ]]; then
		score=$((score+1))
	elif [[ "$block" == 8702 ]]; then
		score=$((score+6))
	elif [[ "$block" == d21a ]]; then
		score=$((score+25))
	elif [[ "$block" == cf2a ]]; then
		score=$((score+15))
	elif [[ "$block" == 9a8b01 ]]; then
		score=$((score+3))
	elif [[ "$block" == f11e ]]; then
		score=$((score+15))
	fi
	pkt_experience "$score"
	echo "$score" > $TEMP/players/$nick/score
}

function dig_async() {
	if [[ $block == 01 || $block == 02 || $block == 03 ]]; then # stone, granite...
		d=0.015
	elif [[ $block == 9a8b01 || $block == 49 ]]; then # copper, coal
		d=0.04
	else # everything else
		d=0.07
	fi
	for i in {1..9}; do
		if [[ $(cat $TEMP/players/$nick/mining) != "$x,$y,$z" ]]; then
			pkt_blockbreak $x $y $z ff
			break
		else
			pkt_blockbreak $x $y $z 0$i
		fi
		sleep $d
	done

	if [[ $(cat $TEMP/players/$nick/mining) == "$x,$y,$z" ]]; then
		pkt_diggingack $x $y $z 00 02
		score
	fi
}

function hook_dig() {
	ore=$(cat $TEMP/players/$nick/oremap | awk '{print $'"$((y+64))"'}' | sed -E 's/.{32}/&\n/g' | head -n $((z+1)) | tail -n 1 | sed -E 's/(.{16})(.{16})/\2\1/g;s/.{2}/&\n/g' | tail -n $((x+2)) | head -n1)
	block=${palette[$((0x$ore))]}
	if [[ $a == "1a02"* ]]; then # finished digging?
		score
	elif [[ $a == "1a00"* ]]; then
		echo "$x,$y,$z" > $TEMP/players/$nick/mining
		dig_async &
	elif [[ $a == "1a01"* ]]; then
		echo "catgirls" > $TEMP/players/$nick/mining
	fi
}

function hook_move() {
	if [[ ${pos[1]} -lt -96 ]]; then
		# utf-8 is actually only valid for strings created in the UTF world region
		# everything else is just sparkling unicode
		pkt_disconnect "$(xxd -p -r <<< "c2af5c5c5f28e38384295f2fc2af")"
	fi
}

function hook_keepalive() {
	keep_alive &
}

function hook_ping() {
	json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"Minigame: §adigmeout§r | '"$time_left"' seconds per game"},"favicon":"data:image/png;base64,'"$(base64 -w0 icon.png)"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	echo "$(hexpacket_len "$res")00$res" | xxd -p -r
}

function hook_inventory() {
	items=($(repeat 36 "0 "))
	items+=("721")
	pkt_inventory items
}
