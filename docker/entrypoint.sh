#!/bin/sh

cp /tmp/scb/config/* /usr/src/safecloudfs/config/
/tmp/scb/init-safecloudfs.sh start 
/tmp/scb/init-nextcloud.sh start
/tmp/scb/init-lsyncd.sh start

while true; do
    sleep 100
done
