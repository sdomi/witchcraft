#!/usr/bin/env bash
# hooks.sh - dummy hooks functions

spawn_pos=(0 0 0) # default spawn position

# on player dig
function hook_dig() {
	log "received Player Dig"
	rhexlog $a
}

# on player arm swing
function hook_swing() {
	log "received Arm Swing"
}

# on player block placement
function hook_block() {
	log "received Player Block Placement"
	rhexlog $a
}

# on chat message
# msg available as $msg
function hook_chat() {
	chatlog "$nick: $msg"
	pkt_chatmessage "$nick: $msg" "0000000000000000000000000000$eid"
	pkt_chatmessage "$nick: $msg" "0000000000000000000000000000$eid" > $TEMP/players/$nick/broadcast
}

# on move/move+rotation/rotation
# X/Y/Z available as ${pos[0]} through ${pos[2]}
function hook_move() {
	log "received Player Position"
}

# after login, join; intended for loading chunks
function hook_chunks() {
	pkt_chunk FFFFFFFF FFFFFFFF 
	pkt_chunk FFFFFFFF 00000000
	pkt_chunk FFFFFFFF 00000001
	
	pkt_chunk 00000000 FFFFFFFF
	pkt_chunk 00000000 00000000
	pkt_chunk 00000000 00000001
	
	pkt_chunk 00000001 FFFFFFFF
	pkt_chunk 00000001 00000000
	pkt_chunk 00000001 00000001
	
	pkt_chunk FFFFFFFF 00000002
	pkt_chunk 00000000 00000002
	pkt_chunk 00000001 00000002
}

# after spawning the player
function hook_start() {
	:
}

# during login; useful for disabling all multiplayer functionality
function hook_keepalive() {
	keep_alive &
	# sleep probably only needed for testing
	sleep 1 && position_delta &
	sleep 1 && handle_broadcast &
	pkt_chatmessage "+ $nick" "00000000000000000000000000000000" > $TEMP/players/$nick/broadcast
}

# during server ping; allows you to respond with a custom message.
function hook_ping() {
	#json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":100,"online":5,"sample":[{"name":"uwu","id":"4566e69f-c907-48ee-8d71-d7ba5aa00d20"}]},"description":{"text":"Hello world"}}'
	json='{"version":{"name":"§a§kaaa§aUwU§kaaa","protocol":756},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"§aUwU"},"favicon":"data:image/png;base64,'"$(base64 -w0 icon.png)"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	echo "$(hexpacket_len "$res")00$res" | xxd -p -r
}

# on defining inventory contents
function hook_inventory() {
	items=()
	pkt_inventory items
}
