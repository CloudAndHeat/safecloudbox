#!/bin/sh

# Example script to start safecloudbox on one host, running a 1-replica
# DepSpace, and 4 SafeCloudFS buckets behind a single S3 endpoint. We use
# docker-compose to start the DepSpace and SafeCloudFS containers.
#
# usage:
#   $ export S3_URL=https://object-store-f1a.cloudandheat.com:8080 \
#            S3_ACCESS_KEY=12345678 \
#            S3_SECRET_KEY=pazzzw0rd11!!11
#   $ ./start.sh
#   $ docker-compose logs -f
#
# After both containers are up and all services are running, point your browser
# to port 80 and login to Nextcloud using random passwords (generated newly at
# container start):
#
#   login   password
#   admin   /tmp/scb/admin_pass
#   user    /tmp/scb/user_pass
#
# Cleanup:
#   $ ./stop.sh
#
# Recovery:
#   $ ./start/.sh -k

set -eu


volume=/tmp/scb
confdir=$volume/config
keep=false

err(){
    echo "$0: error: $@"
    exit 1
}

usage(){
    cat << eof
$0 [-k]

options:
    -k : keep old config in $volume, use for recovery
eof
}

while getopts k opt; do
    case $opt in
        k)  keep=true;;
        h)  usage; exit 0;;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))

if $keep; then
    for name in $confdir; do
        [ -d $name ] || err "$name missing"
    done
    for name in $(ls -1 docker/*.sh | sed -re 's|docker/||g'); do
        tgt=$volume/$name
        [ -e $tgt ] || err "$tgt missing"
    done
    for name in safecloudfs.properties accounts.json; do
        tgt=$confdir/$name
        [ -e $tgt ] || err "$tgt missing"
    done
else
    mkdir -p $volume
    rm -rf $volume/*
    mkdir -p $confdir
    # copy init scripts to bind mount
    cp docker/*.sh $volume/

    # generate SafeCloudFS config files, use 4 buckets
    ##. ~/env_f1a.sh
    ./gen-data-files.py 4
    cp safecloudfs.properties accounts.json $confdir
fi

docker-compose up -d

# don't keep this script in the foreground
##docker-compose logs -f
