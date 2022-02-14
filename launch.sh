#!/usr/bin/env bash

ncat -l -p 25565 -k -c "./mc.sh $1"
