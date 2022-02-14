FROM alpine:edge

RUN echo -e "http://alpine.sakamoto.pl/alpine/edge/main\nhttp://alpine.sakamoto.pl/alpine/edge/community" > /etc/apk/repositories \
 && apk update \
 && apk upgrade \
 && apk add sed grep nmap-ncat bash alpine-base chrony file 

WORKDIR /witchcraft
COPY . .

EXPOSE 25565

CMD ["/witchcraft/launch.sh"]
