#!/bin/sh
/bin/busybox --install -s
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# mount stuff
mkdir proc sys
mount -t proc proc /proc
mount -t sysfs sysfs /sys

for dev in $(echo /sys/class/block/* | tr ' ' '\n' | grep -vE 'loop[0-9]'); do
    echo "blkdev: $(basename "$dev"); size=$(cat "$dev/size")"
done
ash