#!/usr/bin/env bash
# int.sh - int conversion functions, and other numeric functions

# int2varint(int)
function int2varint() {
	# very proud of my implementation; haven't seen anyone use a modulo for this ;p
	local a
	local b
	local c
	local out
	out=$(printf '%02x' "$1")
	if [[ $1 -lt 128 ]]; then
		:
	elif [[ $1 -lt 16384 ]]; then
		a=$(($1%128))
		b=$(($1/128))
		out=$(printf "%02x" $((a+128)))$(printf "%02x" $b)
	elif [[ $1 -lt $((128*128*128)) ]]; then
		a=$(($1%128))
		c=$((($1/128)%128))
		b=$(($1/16384))
		out=$(printf "%02x" $((a+128)))$(printf "%02x" $((c+128)))$(printf "%02x" $b)
	fi
	echo -n "$out"
}

# varint2int() <<< varint
function varint2int() {
	local x
	local uwu
	local out
	out=""
	x=1	
	while true; do
		uwu=$(dd count=1 bs=1 status=none | xxd -p)
	
		out=$((out+((0x$uwu&127)*x)))
		x=$((x*128))
		if [[ $((0x$uwu>>7)) == 0 ]]; then
			break
		fi
	done
	echo -n "$out"
}

# parse_position(Position)
# https://wiki.vg/Protocol#Position
function parse_position() {
	x=$((0x$1 >> 38))
	y=$((0x$1 & 0xFFF))
	z=$(((0x$1 >> 12) & 0x3FFFFFF))
	
	[[ $x -gt 33554431 ]] && x=$((x-67108864))
	[[ $y -gt 2047 ]] && y=$((y-4095))
	[[ $z -gt 33554431 ]] && z=$((z-67108864))
}

# encode_position(x, y, z)
function encode_position() {
	local x
	local y
	local z

	x=$1
	y=$2
	z=$3

	[[ $x -lt 33554433 ]] && x=$((x+67108864))
	[[ $y -lt 2049 ]] && y=$((y+4095))
	[[ $z -lt 33554433 ]] && z=$((z+67108864))
	
	printf "%016x" $((((x & 0x3FFFFFF)<<38) | ((z & 0x3FFFFFF)<<12) | (y & 0xFFF)))
}

# packet_len(packet)
function packet_len() {
	int2varint $((($(echo -n "$1" | wc -c)+1)))
}

# hexpacket_len(hexpacket)
function hexpacket_len() {
	int2varint $((($(echo -n "$1" | xxd -p -r | wc -c)+1)))
}

# str_len(string)
function str_len() {
	int2varint $(echo -n "$1" | wc -c)
}

# hexstrl_len(hexstring)
function hexstr_len() {
	int2varint $(echo -n "$1" | xxd -p -r | wc -c)
}

# hex2bin(hexstring)
function hex2bin() {
	# \o/
	echo -n "$1" | sed -E 's/0/0000/g;s/1/0001/g;s/2/0010/g;s/3/0011/g;s/4/0100/g;s/5/0101/g;s/6/0110/g;s/7/0111/g;s/8/1000/g;s/9/1001/g;s/a/1010/g;s/b/1011/g;s/c/1100/g;s/d/1101/g;s/e/1110/g;s/f/1111/g'
}

# from_ieee754(hexstring)
function from_ieee754() {
	local sign
	local exponent
	local asdf
	local exponent_
	local val

	val=$(hex2bin "$1")
	sign=$(cut -c 1 <<< $val)
	exponent=$(cut -c 2-12 <<< $val)
	
	asdf=$(cut -c 13- <<< $val | sed -E 's/./,&/g;s/,//' | tr -d '\n' | awk -F , \
		'{
			power_count=-1
			x=0;
			for(i=1; i<=NF; i++) {
				x=(x + ($i * (2 ** power_count)))
				power_count=power_count-1;
			}
			print(x+1)
		}')

	exponent_=$((2#$exponent))
	
	if [[ $sign == 0 ]]; then
		echo "$asdf $exponent_" | awk '{print (int($1 * (2 ** ($2 - 1023))))}'
	else
		echo "$asdf $exponent_" | awk '{print -(int($1 * (2 ** ($2 - 1023))))}'
	fi
}

# to_short(number) 
function to_short() {
	if [[ $1 -lt 0 && $1 -gt -32769 ]]; then
		printf "%04x" $(($1+65536))
	elif [[ $1 -lt 32768 && $1 -gt -1 ]]; then
		printf "%04x" $1
	elif [[ $1 -lt -32768 ]]; then
		printf "8000"
	elif [[ $1 -gt 32767 ]]; then
		printf "7FFF"
	fi
}
