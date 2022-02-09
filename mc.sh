#!/bin/bash
state=''
dyed=0
keepalive=0
pos=(0 0 0)
players=()
TEMP=/dev/shm/witchcraft/
mkdir -p $TEMP $TEMP/players $TEMP/world

source src/log.sh
source src/int.sh
source src/packet.sh
source src/hooks.sh

if [[ -f "$1" ]]; then
	log "Loading plugin: $1"
	source "$1"
fi

function keep_alive() {
	while true; do
		sleep 5
		log "sending keepalive"
		echo '092100000000000000ff' | xxd -p -r
	done
}

function position_delta() {
	local deltaX
	local deltaY
	local deltaZ

#	pos[0]=0
#	pos[1]=0
#	pos[2]=0
	pos_old[0]=0
	pos_old[1]=0
	pos_old[2]=0

	while true; do
		sleep 0.1
		for i in $(ls "$TEMP/players/"); do
			if [[ "$i" != "$nick" ]]; then
				pos[0]=$(cat $TEMP/players/$i/position | awk -F, '{print($1)}') # idk, floating point broke
				pos[1]=$(cat $TEMP/players/$i/position | awk -F, '{print($2)}')
				pos[2]=$(cat $TEMP/players/$i/position | awk -F, '{print($3)}')
				log "posX: ${pos[0]}"
				deltaX=$((((${pos[0]}*32) - (${pos_old[0]}*32)) * 128))
				deltaY=$(((${pos[1]}*32 - ${pos_old[1]}*32) * 128))
				deltaZ=$(((${pos[2]}*32 - ${pos_old[2]}*32) * 128))

				
				if [[ $deltaX != 0 || $deltaY != 0 || $deltaZ != 0 ]]; then
					pkt_position $deltaX $deltaY $deltaZ $(cat $TEMP/players/$i/eid)
				fi
				pos_old=("${pos[@]}")
			fi
		done
	done
}

function handle_broadcast() {
	while true; do
		for i in $(ls "$TEMP/players/"); do
			if [[ "$i" != "$nick" ]]; then
				if [[ -f $TEMP/players/$i/broadcast ]]; then
					packet="$(cat $TEMP/players/$i/broadcast)"
					if [[ "$last" != "$packet" ]]; then
						cat $TEMP/players/$i/broadcast
						last="$packet"
					fi
				else
					last=''
				fi
			fi
		done
		sleep 1
	done
}

function spawn_players() {
	for i in $(ls "$TEMP/players/"); do # fite me
		if [[ $i != $nick && ${players[@]} != *"$i"* ]]; then
			log "name: $i EID: $eid"
			pkt_playerinfo_add $i $(cat $TEMP/players/$i/eid)
			pkt_spawnplayer $(cat $TEMP/players/$i/eid)
			players+=("$nick")
		fi
	done
}

while true; do
	len=$(varint2int)
	
	a=$(dd count=$len bs=1 status=none | xxd -p)
	if [[ "$a" == '' ]]; then
		log "connection dyed"
		pkill -P $$
		pkt_chatmessage "- $nick" "00000000000000000000000000000000" > $TEMP/players/$nick/broadcast
		sleep 1
		rm -R "$TEMP/players/$nick"
		exit
	fi

	if [[ -f /tmp/block ]]; then
		res="$(encode_position 10 -10 10)"
		res+="01"

		log "$res"
		echo -n "$(hexpacket_len "$res")0c$res" | xxd -p -r
		rm -R /tmp/block
	fi

	if [[ -f /tmp/spawn ]]; then
		spawn_players
		rm /tmp/spawn
	fi

	if [[ $a == "00"* ]]; then
		log "responding to 00; state: $state"

		if [[ "$state" == '01' ]]; then
			log "status response"

			#json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":100,"online":5,"sample":[{"name":"uwu","id":"4566e69f-c907-48ee-8d71-d7ba5aa00d20"}]},"description":{"text":"Hello world"}}'
			json='{"version":{"name":"§a§kaaa§aUwU§kaaa","protocol":756},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"§aUwU"},"favicon":"data:image/png;base64,'"$(base64 -w0 icon.png)"'"}'
			res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
			echo "$(hexpacket_len "$res")00$res" | xxd -p -r

			state=''
		elif [[ "$state" == '02' ]]; then
			nick=$(cut -c 5- <<< "$a" | xxd -p -r | grep -Poh '[A-Za-z0-9_-]*')
			eid=$(printf "%02x" $RANDOM)
			mkdir -p $TEMP/players/$nick
			echo -n $eid > $TEMP/players/$nick/eid
			pkt_chatmessage "+ $nick" "00000000000000000000000000000000" > $TEMP/players/$nick/broadcast
			log "login response"
			if [[ $keepalive == 0 ]]; then
				hook_keepalive
				keepalive=1
			fi

				# random uuid						string len		string (nick)
			res="0000000000000000000000000000$eid$(str_len "$nick")$(echo -n "$nick" | xxd -p)"
			log "$(hexpacket_len "$res")02$res"
			echo -n "$(hexpacket_len "$res")02$res" | xxd -p -r

			
			res="$(encode_position 0 0 0)"
			res+="00000000" # angle as float

			echo -n "$(hexpacket_len "$res")4B$res" | xxd -p -r
			log "sent spawn position"

			#res="00000000" 			# entity id (0 or -2147483648, idk)
			#res+="00" 				# not hardcore
			#res+="00" 				# survival mode
			#res+="01" 				# ... as previously seen on Creative Mode (ignored)
			#res+="01" 				# one dimension
			#res+="13$(echo -n "minecraft:overworld" | xxd -p)"
			#res+="0a000000"				# dimension codec
			#res+="0a000000"				# dimension
			#res+="13$(echo -n "minecraft:overworld" | xxd -p)"	# dimension being spawned into
			#res+="0000000000000000"	# beginning of sha256 of seed
			#res+="0f"				# max players (ignored)
			#res+="02"				# view distance (min 2 chunks)
			#res+="02"				# simulation distance
			#res+="00"				# reduced debug info? (false)
			#res+="00"				# enable respawn screen
			#res+="00"				# is debug (surprisingly, no)
			#res+="01"				# is flat (yeah, sure)

			#rhexlog "$(hexpacket_len "$res")26$res"
			#echo -n "$(hexpacket_len "$res")26$res" | xxd -p -r
			#log "sent join game"

			cat nbt_
			log "sent (hardcoded) join game"
			
			# send inventory (0x14)
			res="00" # inventory id
			res+="00" # state
			res+="09" # item count
			for i in {1..9}; do
				res+="01 0$i 7f 00" # stone block
			done
			res+="01 00 01 00" # again, for held

			echo -n "$(hexpacket_len "$res")14$res" | xxd -p -r
			log "sent inventory"

			pkt_pos

			source src/palette.sh
			
			hook_chunks

			spawn_players
			
			state=''
		else
			if [[ $a == *"01" ]]; then # 01 - next state: status
				log 'set status'
				state='01'
			else # 02 - next state: login
				log 'set login'
				state='02'
			fi
		fi
	elif [[ $a == "01"* ]]; then
		log "responding to 01"
		echo "$len$a" | xxd -p -r
		log "bye"
		exit
	elif [[ $a == "0f"* ]]; then
		log "received keepalive"
		date "+%s" > $TEMP/players/$nick/ping
	elif [[ $a == "11"* ]]; then
		pos[0]=$(from_ieee754 $(cut -c 3-18 <<< "$a"))
		pos[1]=$(from_ieee754 $(cut -c 19-34 <<< "$a"))
		pos[2]=$(from_ieee754 $(cut -c 35-50 <<< "$a"))
		echo "${pos[0]},${pos[1]},${pos[2]}" > $TEMP/players/$nick/position
		hook_move
	elif [[ $a == "12"* ]]; then
		hook_move
	elif [[ $a == "13"* ]]; then
		hook_move
	elif [[ $a == "1a"* ]]; then
		hook_dig
	elif [[ $a == "2c"* ]]; then
		hook_swing
	elif [[ $a == "2e"* ]]; then
		hook_block
	elif [[ $a == "03"* ]]; then
		if [[ $((0x$(cut -c 3-4 <<< "$a"))) -lt 127 ]]; then # lazy varint check
			msg=$(cut -c 5- <<< "$a" | xxd -p -r)
		else
			msg=$(cut -c 3- <<< "$a" | xxd -p -r)
		fi
		hook_chat		
	else
		log "unknown data from client"
		rhexlog "$a"
	fi
	
done
