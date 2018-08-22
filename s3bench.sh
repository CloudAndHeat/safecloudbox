#!/bin/zsh

# Need to execute "time <command>" in a subshell, else "time" will time
# <command> and the "sed" command :). The sed regex is only valid for zsh's
# version of "time", bash has different output.

# env_f1a.sh
#   export S3_ACCESS_KEY=XXXXXXXXXXXX
#   export S3_SECRET_KEY=YYYYYYYYYYYY
#   export S3_URL=https://object-store-f1a.cloudandheat.com:8080
# 
# usage:
#   $ . ~/env_f1a.sh
#   $ ./s3bench.sh steveschmerler@dashboard-f1a.cloudandheat.com

ssh_dc=$1

# MB
size=500
dd if=/dev/urandom of=file bs=${size}M count=1 iflag=fullblock status=none

echo "scp"
for x in $(seq 3); do 
    dt=$( (time scp file ${ssh_dc}:) 2>&1 \
        | sed -re 's/.*cpu (.*) total/\1/')
    echo "$size / $dt" | bc -l
done

echo "S3"
for x in $(seq 3); do 
    dt=$( (time ./s3tool.py put speed file) 2>&1 \
        | sed -re 's/.*cpu (.*) total/\1/')
    echo "$size / $dt" | bc -l
done
