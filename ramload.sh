#!/bin/sh
/bin/busybox --install -s
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# mount stuff
mkdir proc sys
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

for dev in $(echo /sys/class/block/* | tr ' ' '\n' | grep -vE 'loop[0-9]'); do
    # get disk size
    size=$(cat "$dev/size")

    # get some env vars about the disk
    eval "$(blkid -o export "/dev/$(basename "$dev")")"

    # print the info
    echo "blkdev: $(basename "$dev"); size=$(($size * 512)) bytes; type=$PTTYPE"

    # print info about the type, particularly if it is odd
    case "$PTTYPE" in
        "dos"|"gpt")
            str="a full disk w/ partition table, not a filesystem.  Skipping." ;;
        "")
            str="an empty/unknown filesystem.  Skipping." ;;
        "ext"*|"xfs"|"btrfs")
            str="a normal on-disk filesystem.  Marked for checking."
            checkme=true ;;
        "vfat"|*"msdos")
            str="\
some form of FAT.  EFI System Partition?  \
Either way, neither suitable for a distro nor shared info partition.  Skipping." ;;
        *)
            str="an unknown filesystem type \"$PTTYPE\"!  Please report this error!  Skipping." ;;
    esac
    unset PTUUID PARTUUID BLOCK_SIZE DEVNAME PART_SIZE TYPE UUID PARTLABEL PTTYPE

    echo "$(basename "$dev") is $str"
    if [ "$checkme" = "true" ]; then
        echo "checking this partition"
    fi

done
ash