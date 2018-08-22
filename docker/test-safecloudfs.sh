#!/bin/sh

# Basic test of the Fuse mount point created by SafeCloudFS. Do simple IO
# operations, compare file hashes and such. Run as root.
#
# usage:
#
# ./this.sh /path/to/mountpoint

set -eu

err(){
    echo "$0: error: $@"
    exit 1
}

fail(){
    echo "$0: FAIL: $@"
    exit 1
}

hsh(){
    sha1sum $1 | cut -d ' ' -f1
}

[ $# -eq 1 ] || err "mountpoint missing"

mountpoint=$(echo "$1" | sed -re 's|(.*)/\s*$|\1|')

# may need this later for async operations
pause=0

mount | grep -q "fuse.*$mountpoint" || err "not mounted"

fn=$(mktemp $mountpoint/create_file.XXXXXXX) || fail "create file"
fn_cp=${fn}_cp
fn_mv=${fn}_mv

sleep $pause
echo foo > $fn || fail "write file"

sleep $pause
cp $fn $fn_cp || fail "cp file"

sleep $pause
mv $fn $fn_mv || fail "mv file"

sleep $pause
rm $fn_mv || fail "rm file"

sleep $pause
dr=$(mktemp $mountpoint/create_dir.XXXXXXXX -d) || fail "create dir"
fn=$dr/foo

sleep $pause
echo foo > $fn || fail "write file in dir"

sleep $pause
rm $fn || fail "rm file in dir"

for size in 10 1K 3K 4095 4K 4097 5K 10K; do
    sleep $pause
    templ=safecloudfs_hash.XXXXXXXXX.$size
    fn_src=$(mktemp /tmp/$templ)
    fn_src_down=${fn_src}_down
    fn_dst=$(mktemp $mountpoint/$templ)
    dd if=/dev/urandom of=$fn_src bs=$size count=1 status=none iflag=fullblock
    cp $fn_src $fn_dst
    [ $(hsh $fn_src) = $(hsh $fn_dst) ] || fail "hash dst $size"
    cp $fn_dst $fn_src_down
    [ $(hsh $fn_src) = $(hsh $fn_src_down) ] || fail "hash src_down $size"
    rm $fn_src $fn_src_down
done

sleep $pause
chown -R www-data:root $mountpoint || fail "chown"
[ "$(stat -c %U $mountpoint)" = "www-data" ] || fail "assert chown user"
[ "$(stat -c %G $mountpoint)" = "root" ] || fail "assert chown group"
