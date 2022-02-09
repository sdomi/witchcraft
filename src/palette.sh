#!/bin/bash
# palette.sh - up to 255 block definitions
# maps first 32 IDs to pre-flattening IDs, just for fun; rest is rather random
# empty blocks (00) is what I can't easily implement :(
# https://minecraft.fandom.com/wiki/Java_Edition_data_values/Pre-flattening/Block_IDs

palette=()

palette+=("00") # air
palette+=("01") # stone
palette+=("09") # grass
palette+=("0a") # dirt
palette+=("0e") # cobblestone
palette+=("0f") # planks
palette+=("15") # sapling
palette+=("21") # bedrock
palette+=("00") #
palette+=("31") # water
palette+=("00") #
palette+=("41") # lava
palette+=("42") # sand
palette+=("44") # gravel
palette+=("45") # gold ore
palette+=("47") # iron ore

palette+=("49") # coal ore
palette+=("4d") # wood
palette+=("9401") # leaves
palette+=("8402") # sponge
palette+=("8602") # glass
palette+=("8702") # lapis ore
palette+=("8902")
palette+=("00") #
palette+=("9602") # sandstone
palette+=("00") #
palette+=("00") #
palette+=("00") #
palette+=("00") #
palette+=("00") #
palette+=("f60a") # grass
