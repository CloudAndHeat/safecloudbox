#!/bin/sh

mountpoint=/mnt/safecloudfs
log=/var/log/safecloudfs.log

err(){
    echo "$0: error: $@"
    exit 1
}

do_start(){
    mkdir -pv $mountpoint
    cd /usr/src/safecloudfs
    mvn exec:java -Ddir=$mountpoint -Duid=`id -u` -Dgid=`id -g` 2>&1 | tee -a $log &
}

do_stop(){
    for sig in 15 9; do
        pd=$(ps aux | awk '/[j]ava.*maven.*safecloudfs/ {print $2}')
        [ -n "$pd" ] && kill -s $sig $pd
        sleep 2
    done
    if mount | grep -q "fuse.*$mountpoint"; then
        fusermount -u $mountpoint
    fi
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
