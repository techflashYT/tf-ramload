#!/bin/sh
/bin/busybox --install -s
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

v_ma=0
v_mi=0
v_pa=1
echo "Techflash RAMLoad v$v_ma.$v_mi.$v_pa starting up..."


debug() {
    printf "\x1b[1;30m[DEBUG] %s\x1b[0m\n" "$1"
}

info() {
    printf "\x1b[1;39m[INFO] %s\x1b[0m\n" "$1"
}

warn() {
    printf "\x1b[1;33m[WARN] %s\x1b[0m\n" "$1"
}

# mount stuff
debug "Mounting filesystems..."

mkdir proc sys tmp
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /tmp
debug "Filesystems mounted"


debug "Updating ldconfig..."
ldconfig
debug "ldconfig updated"

touch /etc/group
touch /etc/passwd
addgroup -S sshd
adduser -SH sshd -G sshd

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
    debug "blkdev: $(basename "$dev"); size=$(($size * 512)) bytes; type=$TYPE"

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
    unset PTUUID PARTUUID BLOCK_SIZE DEVNAME PART_SIZE TYPE UUID PARTLABEL PTTYPE

    info "$(basename "$dev") is $str"
    unset str
    if [ "$checkme" = "true" ]; then
        unset checkme
        
        # check the type of this partition
        mkdir -p /mnt/test
        mount "/dev/$(basename "$dev")" /mnt/test
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
ash
counter=0
set -- ""
for f in /*.found_distro; do
    export counter=$(($counter + 1))
    . "$f"

    # Remove `.found_distro` and the leading `/`.
    disk=$(echo "$f" | sed 's/\..*//' | cut -c 2-)
    eval "distroNum_${counter}=$disk"
    if [ "$@" = "" ]; then
        set -- $counter "$DISTRO_NAME [$DISK_TYPE] (ETA $LOAD_TIME)"
    else
        set -- "$@" $counter "$DISTRO_NAME [$DISK_TYPE] (ETA $LOAD_TIME)"
    fi
done
ash

# Use dialog to create a menu from the menu items
if [ "$WIDTH" = "" ]; then export WIDTH=80; fi
if [ "$HEIGHT" = "" ]; then export HEIGHT=25; fi

exec 3>&1
if [ "$selection" = "" ]; then
    selection=0
fi
until [ "$selection" -gt "0" ] && [ "$selection" -le "$counter" ]; do
    selection=$(dialog --menu "Please select an OS" $(($HEIGHT - 2)) $(($WIDTH - 4)) "$counter" "$@" 2>&1 1>&3)
    if [ "$selection" = "" ]; then
        selection=0
    fi
done
exec 3>&-
clear

# Call goLoad with the selected disk
echo "the selection is equal to $selection"
disk="$(eval "echo \$distroNum_$selection")"

# get rid of sshd to goLoad can be pid1
killall -9 sshd

echo "PID of ramload is $$"
exec /goLoad "$disk"