#!/bin/bash

# MODULES=(
#     virtio_net net_failover
#     virtio_blk virtio_console
#     virtio_balloon virtio_scsi
#     virtio_pci virtio_pci_legacy_dev
#     virtio_pci_modern_dev
#     i8042 bochs
#     drm_vram_helper
#     drm_ttm_helper
# )

build="$PWD/_buildTmp"

busyboxDir="$PWD/deps/busybox"
busyboxFile="https://busybox.net/downloads/busybox-1.36.1.tar.bz2"
busyboxConfig="$PWD/busyboxConfig"

linuxFile="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.8.tar.xz"
linuxDir="$PWD/deps/linux"
linuxConfig="$PWD/linuxConfig"
kernelPath="$linuxDir/arch/x86/boot/bzImage"

util_linuxDir="$PWD/deps/util-linux"
util_linuxFile="https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.39/util-linux-2.39.3.tar.xz"




FILES=(
    "$PWD/ramload.sh:/init"
    "$busyboxDir/busybox:/usr/bin/busybox"
    "$util_linuxDir/blkid:/usr/bin/blkid"
    #"$util_linuxDir/.libs/libblkid.so:/usr/lib/libblkid.so"
    #"$util_linuxDir/.libs/libblkid.so.1:/usr/lib/libblkid.so.1"
    #"$util_linuxDir/.libs/libblkid.so.1.1.0:/usr/lib/libblkid.so.1.1.0"
)

function dload() {
    dir="$1"
    file="$2"
    config="$3"
    name="$4"

    localfname="$(basename "$file")"
    mkdir -p "$(dirname "$dir")"
    if ! [ -d "$dir" ]; then
        wget "$file"
        exitCode=$?
        if [ $exitCode != 0 ]; then
            echo "$name download failed with exit code $exitCode" >&2
            exit 1
        fi
        tar xf "$localfname"
        # e.g. move busybox-1.36.1 to busybox
        mv "${localfname//\.tar.*//}" "$dir"
        # mv "$(echo "$localfname" | sed 's/\.tar.*//g')" "$dir"

        if [ "$config" != "" ]; then
            cp "$config" "$dir/.config"
        fi

        rm "$localfname"
    fi
}


rm -rf "$build"
mkdir "$build/initramfs" -p


# check if we have busybox
dload "$busyboxDir" "$busyboxFile" "$busyboxConfig" "Busybox"

# check if we have the Linux kernel
dload "$linuxDir" "$linuxFile" "$linuxConfig" "Linux kernel"

# check if we have util-linux
dload "$util_linuxDir" "$util_linuxFile" "" "util-linux"


# build busybox
pushd "$busyboxDir" > /dev/null || exit 1
make -j"$(nproc)"
popd > /dev/null || exit 1


# build the Linux kernel
pushd "$linuxDir" > /dev/null || exit 1
make -j"$(nproc)"
popd > /dev/null || exit 1
cp "$kernelPath" "$build/"


# build util-linux
pushd "$util_linuxDir" > /dev/null || exit 1
if ! [ -f Makefile ]; then
    export CFLAGS=-static
    export SUID_CFLAGS=-static
    export SUID_LDFLAGS=-static
    export CPPFLAGS=-static
    export LDFLAGS=-static
    ./configure --enable-static-programs=blkid --disable-shared
fi
# we only need blkid
make blkid -j"$(nproc)" LDFLAGS="--static"
popd > /dev/null || exit 1

# make base initrd structure
pushd "$build/initramfs" > /dev/null || exit 1
mkdir -p usr/bin usr/sbin usr/lib usr/share etc
ln -s usr/bin bin
ln -s usr/sbin sbin
ln -s usr/lib lib
ln -s usr/lib usr/lib64
ln -s usr/lib64 lib64
ln -s busybox bin/sh
popd > /dev/null || exit 1

# get the files and where they need to go
for file in "${FILES[@]}"; do
    hostPath=$(echo $file | cut -f1 -d:)
    initrdPath=$(echo $file | cut -f2 -d:)

    echo "copying $hostPath to $build/initramfs$initrdPath"
    cp "$hostPath" "$build/initramfs$initrdPath"
done

pushd $build/initramfs > /dev/null || exit 1
# find . | cpio -o --format='newc' | lz4 -3 - ../initramfs.img
find . | cpio -o --format='newc' > ../initramfs.img

popd > /dev/null || exit 1