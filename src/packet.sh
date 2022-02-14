#!/usr/bin/env bash
# packet.sh - play state packets

# pkt_pos(x, y, z)
function pkt_pos() {
		res="$(to_ieee754 $1)"	# X
		res+="$(to_ieee754 $2)"	# Y
		res+="$(to_ieee754 $3)"	# Z
		res+="00000000"			# yaw
		res+="00000000"			# pitch
		res+="00"				# bit field; all absolute
		res+="00"				# teleport id (?)
		res+="00"				# dismount vehicle?

		echo -n "$(hexpacket_len "$res")38$res" | xxd -p -r
		log "sent player look and position"
}

# pkt_chunk(chunk_x, chunk_z, fill)
function pkt_chunk() {
	# palettes are really cool once you figure them out :3
	# https://wiki.vg/Protocol#Chunk_Data_And_Update_Light
	
	local chunk
	local fill
	if [[ $3 == '' ]]; then
		fill='01'
	else
		fill="$3"
	fi

	res="$1" # chunk X
	res+="$2" # chunk Z

	# here goes the scary NBT field
	#     nbt tag       MOTION_BLOCKING                 len       light data for a superflat map
	res+="0a00000c000f  4d4f54494f4e5f424c4f434b494e47  00000025  010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804010080402010080401008040201008040100804020100804  0000000020100804 00"

	if [[ -f $TEMP/world/$1$2 ]]; then
		chunk=$(cat $TEMP/world/$1$2)
	else
		chunk_header
		
		l=$(echo -n "8002" | xxd -p -r | varint2int)

		chunk+="$(repeat $((l*16)) "$fill")"

		chunk_footer
		echo -n "$chunk" > $TEMP/world/$1$2
	fi

	res+="$(hexstr_len "$chunk")" # Data len
	res+="$chunk" # Chunk data itself

	res+="00 01 00 00 00 00 00 00" # empty bitsets and light arrays

	echo -n "$(hexpacket_len "$res")22$res" | xxd -p -r
	
	log "sending chunk data"
}

# pkt_effect(x, y, z, effect_id)
function pkt_effect() {
	res="$(printf '%08x' $4)"
	res+="$(encode_position $1 $2 $3)"
	res+="00000000"
	res+="00"
	echo -n "$(hexpacket_len "$res")23$res" | xxd -p -r
	log "sending effect"
}

# pkt_particle(x, y, z, particle_id, count)
function pkt_particle() {
	res="$(printf '%08x' $4)" # particle id
	res+="01" # long distance
	res+="$(to_ieee754 $1)" # X
	res+="$(to_ieee754 $2)" # Y
	res+="$(to_ieee754 $3)" # Z
	res+="3f800000" # X offset
	res+="3f800000" # Y offset
	res+="3f800000" # Z offset
	res+="00000001" # particle data
	res+="$(printf '%08x' $5)" # particle count
	res+="" # data (left blank)
	echo -n "$(hexpacket_len "$res")24$res" | xxd -p -r

	log $(to_ieee754 $1) $(to_ieee754 $2) $(to_ieee754 $3)
	
	rhexlog "$res"
	log "sending particle"
}

# pkt_playerinfo(name, eid)
function pkt_playerinfo_add() {
	res="00" # add player
	res+="01" # total players
	res+="0000000000000000000000000000$2" # UUID

	res+="$(str_len "$1")$(echo -n "$1" | xxd -p)"
	
	res+="00" # array len; can be zero, but no skins then

	res+="01" # gamemode: creative
	res+="01" # ping: 1ms
	res+="00" # has display name: false

	echo -n "$(hexpacket_len "$res")36$res" | xxd -p -r
	
	log "sent playerinfo"
}

# pkt_spawnplayer(eid)
function pkt_spawnplayer() {
	res="$(int2varint $((0x$1)))" # entity id
	res+="0000000000000000000000000000$1" # a really badly made UUID
	res+="00 00 00 00 00 00 00 00" # X
	res+="00 00 00 00 00 00 00 00" # Y
	res+="00 00 00 00 00 00 00 00" # Z

	res+="00" # Angle (256 steps)
	res+="00" # Pitch (...)

	echo -n "$(hexpacket_len "$res")04$res" | xxd -p -r
	rhexlog "$(hexpacket_len "$res")04$res"
	log "sent spawnplayer"
}

# pkt_position(deltaX, deltaY, deltaZ, eid)
function pkt_position() {
	local deltaX
	local deltaY
	local deltaZ
	local stepX
	local stepY
	local stepZ
	local n

	deltaX=$1
	deltaY=$2
	deltaZ=$3
	stepX=0
	stepY=0
	stepZ=0

	while true; do
		n=false
		if [[ $deltaX -gt 32767 ]]; then
			stepX=32767
			deltaX=$((deltaX-32767))
			n=true
		fi
		if [[ $deltaX -lt -32768 ]]; then
			stepX=-32768
			deltaX=$((deltaX+32768))
			n=true
		fi
		if [[ $deltaY -gt 32767 ]]; then
			stepY=32767
			deltaY=$((deltaY-32767))
			n=true			
		fi
		if [[ $deltaY -lt -32768 ]]; then
			stepY=-32768
			deltaY=$((deltaY+32768))
			n=true
		fi
		if [[ $deltaZ -gt 32767 ]]; then
			stepZ=32767
			deltaX=$((deltaZ-32767))
			n=true
		fi
		if [[ $deltaZ -lt -32768 ]]; then
			stepZ=-32768
			deltaZ=$((deltaZ+32768))
			n=true
		fi

		[[ $n == false ]] && break

		pkt_position $stepX $stepY $stepZ
	done

	res="$(int2varint $((0x$4)))" # entity ID
	res+="$(to_short $deltaX)"
	res+="$(to_short $deltaY)"
	res+="$(to_short $deltaZ)" 
	res+="00" # on ground
	echo -n "$(hexpacket_len "$res")29$res" | xxd -p -r
}

# pkt_chatmessage(msg, sender_uuid)
function pkt_chatmessage() {
	local msg
	local json
	local res
	
	msg=$(sed -E 's/"//g;s@\\@@g' <<< "$1")
	json='{"text":"'"$msg"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	res+="00" # position: chat box
	res+="$2"
	
	echo -n "$(hexpacket_len "$res")0F$res" | xxd -p -r	
}

# pkt_title(msg)
function pkt_title() {
	local txt
	txt='{"text":"'"$1"'"}'
	res="$(str_len "$txt")$(echo -n "$txt" | xxd -p)"
	echo -n "$(hexpacket_len "$res")5a$res" | xxd -p -r
}

# pkt_subtitle(msg)
function pkt_subtitle() {
	local txt
	txt='{"text":"'"$1"'"}'
	res="$(str_len "$txt")$(echo -n "$txt" | xxd -p)"
	echo -n "$(hexpacket_len "$res")58$res" | xxd -p -r
}

# pkt_disconnect(reason)
function pkt_disconnect() {
	txt='{"text":"'"$1"'"}'
	res="$(str_len "$txt")$(echo -n "$txt" | xxd -p)"
	log "$txt"
	echo -n "$(hexpacket_len "$res")1a$res" | xxd -p -r
	
	pkill -P $$
	pkt_chatmessage "- $nick" "00000000000000000000000000000000" > $TEMP/players/$nick/broadcast
	sleep 0.3
	rm -R "$TEMP/players/$nick"
	exit
}

# pkt_experience(lvl)
function pkt_experience() {
	res="00000000" # experience bar
	res+="$(int2varint $1)"
	res+="00"
	echo -n "$(hexpacket_len "$res")51$res" | xxd -p -r
}

# pkt_inventory(items)
function pkt_inventory() {
	local -n _items=$1
	
	res="00" # inventory id
	res+="00" # state
	res+="$(int2varint ${#_items[@]})" # item count
	for i in ${!_items[@]}; do
		if [[ $i == 0 ]]; then
			res+="00"
		else
			res+="01 $(int2varint ${_items[$i]}) 01 00"
		fi
	done
	res+="01 00 01 00"

	echo -n "$(hexpacket_len "$res")14$res" | xxd -p -r
	log "sent inventory"
}

# pkt_digginack(x, y, z, block, status)
function pkt_diggingack() {
	res="$(encode_position $1 $2 $3)"
	res+="$4"
	res+="$5"
	res+="01"
	echo -n "$(hexpacket_len "$res")08$res" | xxd -p -r
	log "sent dig ack"
}

# pkt_blockbreak(x, y, z, stage)
function pkt_blockbreak() {
	res="$(int2varint $((0x$eid)))"
	res+="$(encode_position $1 $2 $3)"
	res+="$4"
	echo -n "$(hexpacket_len "$res")09$res" | xxd -p -r
}

# pkt_soundeffect(x, y, z, id)
# TODO: unbreak this
function pkt_soundeffect() {
	res="$(int2varint $4)" # sound ID
	res+="05" # "block" category
	res+="$(printf '%08x' $(($1*8)))" # x
	res+="$(printf '%08x' $(($2*8)))" # y
	res+="$(printf '%08x' $(($3*8)))" # z
	res+="3f800000" # volume
	res+="3f800000" # pitch

	echo -n "$(hexpacket_len "$res")5d$res" | xxd -p -r
	log "sound $(hexpacket_len "$res")5d$res"
}

# pkt_sendblock(x, y, z, id)
function pkt_sendblock() {
	res="$(encode_position $1 $2 $3)"
	res+="$(int2varint $4)"
	
	echo -n "$(hexpacket_len "$res")0c$res" | xxd -p -r
}
