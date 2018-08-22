#!/bin/sh

src=/var/www/html/data/user/files
dst=/mnt/safecloudfs

err(){
    echo "$0: error: $@"
    exit 1
}

do_start(){
    lsyncd -direct $src $dst
}

do_stop(){
    for sig in 15 9; do
        pd=$(ps aux | awk '/[l]syncd/ {print $2}')
        [ -n "$pd" ] && kill -s $sig $pd
        sleep 2
    done
}

if [ "$1" = "start" ]; then
    do_start
elif [ "$1" = "stop" ]; then
    do_stop
elif [ "$1" = "restart" ]; then
    do_stop
    do_start
else
    err "illegal command"
fi
