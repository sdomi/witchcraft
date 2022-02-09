#!/usr/bin/env bash
# hooks.sh - dummy hooks functions

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

# during login; useful for disabling all multiplayer functionality
function hook_keepalive() {
	keep_alive &
	# sleep probably only needed for testing
	sleep 1 && position_delta &
	sleep 1 && handle_broadcast &
}
