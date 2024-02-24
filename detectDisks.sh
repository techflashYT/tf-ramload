#!/bin/sh
for dev in $(echo /sys/class/block/* | tr ' ' '\n' | grep -vE 'loop[0-9]'); do
    # get disk size
    size=$(cat "$dev/size")

    # get some env vars about the disk
    eval "$(blkid -o export "/dev/$(basename "$dev")")"

    # double check which one it is
    if [ "$PTTYPE" != "" ] && [ "$TYPE" = "" ]; then
        TYPE="$PTTYPE"
    fi

    # print the info
    debug "blkdev: $(basename "$dev"); size=$((size * 512)) bytes; type=$TYPE"

    unset size

    # print info about the type, particularly if it is odd
    case "$TYPE" in
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
            str="an unknown filesystem type \"$TYPE\"!  Please report this error!  Skipping." ;;
    esac
    unset PTUUID PARTUUID BLOCK_SIZE DEVNAME PART_SIZE TYPE UUID PARTLABEL PTTYPE mountArgs

    info "$(basename "$dev") is $str"
    unset str
    if [ "$checkme" = "true" ]; then
        unset checkme
        
        # check the type of this partition
        mkdir -p /mnt/test
        mount "/dev/$(basename "$dev")" /mnt/test
        if [ -f /mnt/test/@/.tf_ramload_info ]; then
		umount /mnt/test
		mountArgs="-o subvol=@"
		mount "/dev/$(basename "$dev")" /mnt/test $mountArgs
	fi
        if [ -f /mnt/test/.tf_ramload_info ]; then
            . /mnt/test/.tf_ramload_info
            info "Found distro \"$DISTRO_NAME\" on disk type \"$DISK_TYPE\" with estimated load time of \"$LOAD_TIME\"!"
            cp /mnt/test/.tf_ramload_info "/$(basename "$dev").found_distro"
            umount /mnt/test
        elif [ -f /mnt/test/.tf_ramload_shared_storage ]; then
            . /mnt/test/.tf_ramload_shared_storage
            info "Found shared storage with *info TBD*!"
            umount /mnt/test
            mount "/dev/$(basename "$dev")" /mnt/shared_storage
        else
            warn "Disk neither contains a distro, nor shared storage compatible with Techflash RAMLoad!" >&2
            umount /mnt/test
        fi
    fi
done
