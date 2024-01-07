#!/bin/sh
/bin/busybox --install -s
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

v_ma=0
v_mi=0
v_pa=1


debug() {
    printf "\x1b[1;30m[DEBUG] %s\x1b[0m\n" "$1"
}

info() {
    printf "\x1b[1;39m[INFO] %s\x1b[0m\n" "$1"
}

warn() {
    printf "\x1b[1;33m[WARN] %s\x1b[0m\n" "$1"
}

error() {
    printf "\x1b[1;31m[ERROR] %s\x1b[0m\n" "$1"
}



info "Techflash RAMLoad v$v_ma.$v_mi.$v_pa starting up..."

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

debug "Setting up sshd group & user"
touch /etc/group
touch /etc/passwd
addgroup -S sshd
adduser -SH sshd -G sshd

. /detectDisks

# did we mount the shared storage?
while ! mountpoint -q /mnt/shared_storage; do
    error "No shared storage detected!  Dropping to a shell so you can examine the situation."
    info "Shared storage is necessary to store SSH Keys, user accounts,"
    info "and any add-in files you want to add to the distro before boot."
    info ""
    info "If you simply forgot to make one, go reboot, add one, and"
    info "make the \`.tf_ramload_shared_storage' file (see the docs for format)."
    info "The whole partition doesn't need to be more than 100M or so."
    info ""
    info "If you have one that just wasn't detected, you can try to debug it here."
    info "When the problem is fixed, either reboot the machine, or exit your shell."
    info "We will try to continue the boot process after you exit"
    warn "If it fails, you will get a shell again."
    info "OK.  Good luck!"
    ash
    . /detectDisks
done
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