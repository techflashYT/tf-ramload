#!/bin/sh
/bin/busybox --install -s
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# mount stuff
mkdir proc sys
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

for dev in $(echo /sys/class/block/* | tr ' ' '\n' | grep -vE 'loop[0-9]'); do
    size=$(cat "$dev/size")
    eval "$(blkid -o export "/dev/$(basename "$dev")")"
    echo "blkdev: $(basename "$dev"); size=$(($size * 512)) bytes; type=$TYPE"
    if [ "$PTTYPE" = "dos" ] || [ "$PTTYPE" = "gpt" ]; then
        echo "$(basename "$dev") is a full disk w/ partition table, not a filesystem."
    fi
    unset PTUUID PARTUUID BLOCK_SIZE DEVNAME PART_SIZE TYPE UUID PARTLABEL

done
ash