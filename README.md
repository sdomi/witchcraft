# Witchcraft - a Minecraft server, written in Bash

Requires busybox 1.35.0 or later (crashes on 1.34, for some reason), bash, gnu grep, gnu sed and nmap-ncat. Grep was actually only used once, so maybe I could make it work with the bb one?

## How to use

To get the "plain" experience:

```
./launch.sh
```

If it doesn't work (tested only on Alpine Edge), go for the docker route:

```
docker build -t witchcraft .
docker run --rm -it -p25565:25565 witchcraft ./launch.sh
```

The above would launch the basic server without any plugins. You should check out the digmeout demo tho, it's kinda addictive:

```
./launch.sh demos/digmeout.sh
```

### What works

- joining the game
- chat
- hooks (you can write your own.. plugins? check out `demos/`)
- breaking blocks, to some extent
- serializing and sending chunks
- sending effects
- possibly more

### What does not

- multiple players (server tries to send the movement packets, but I haven't finished it)
- breaking blocks with tools (client acts as if there isn't a tool in your hand)
- capitalism (IRL; I wouldn't want to try implementing it here)

