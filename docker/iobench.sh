#!/bin/sh

# Measure IO in the safecloudbox container. Write to Nextcloud's data docker
# volume /var/www/html (NOT a bind mount) and to SafeCloudFS's mount point
# /mnt/safecloudfs/ .

write(){
    local dst=$1
    local size=$2
    echo $size $dst
    for x in $(seq 3); do
        dd if=/dev/zero \
           of=$dst \
           bs=${size} \
           count=1 \
           oflag=direct,sync \
           iflag=fullblock \
           conv=fsync 2>&1 | grep copied
    done
}

/tmp/scb/init-lsyncd.sh stop

write /var/www/html/data/user/files/file 100M
write /mnt/safecloudfs/file 4K
