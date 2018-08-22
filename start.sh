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
#   $ docker-compose rm -sf

set -eu 

volume=/tmp/scb
confdir=$volume/config
mkdir -p $volume
rm -rf $volume/*
mkdir -p $confdir

# copy init scripts to bind mount
cp docker/*.sh /tmp/scb/

# generate SafeCloudFS config files, use 4 buckets
##. ~/env_f1a.sh
./gen-data-files.py 4
cp safecloudfs.properties accounts.json $confdir

docker-compose up
