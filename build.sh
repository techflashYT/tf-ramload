#!/bin/bash -e

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

opensshFile="https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.6p1.tar.gz"
opensshDir="$PWD/deps/openssh"

glibcFile="https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.xz"
glibcDir="$PWD/deps/glibc"


FILES=(
    "$PWD/ramload.sh:/init"
    "$busyboxDir/busybox:/usr/bin/busybox"
    "$util_linuxDir/.libs/blkid:/usr/bin/blkid"
    "$util_linuxDir/.libs/libblkid.so:/usr/lib/libblkid.so"
    "$util_linuxDir/.libs/libblkid.so.1:/usr/lib/libblkid.so.1"
    "$util_linuxDir/.libs/libblkid.so.1.1.0:/usr/lib/libblkid.so.1.1.0"
    "$opensshDir/ssh:/usr/bin/ssh"
    "$opensshDir/sshd:/usr/bin/sshd"
    "$opensshDir/scp:/usr/bin/scp"
    "${glibcDir}_install/lib/ld-linux-x86-64.so.2:/usr/lib/ld-linux-x86-64.so.2"
    "${glibcDir}_install/lib/libc.so:/usr/lib/libc.so"
    "${glibcDir}_install/lib/libc.so.6:/usr/lib/libc.so.6"
    "${glibcDir}_install/lib/libm.so:/usr/lib/libm.so"
    "${glibcDir}_install/lib/libresolv.so:/usr/lib/libresolv.so"
    "${glibcDir}_install/lib/libresolv.so.2:/usr/lib/libresolv.so.2"
    "${glibcDir}_install/bin/ldd:/usr/bin/ldd"
    "${glibcDir}_install/sbin/ldconfig:/usr/sbin/ldconfig"
)

function dload() {
    dir="$1"
    file="$2"
    config="$3"
    name="$4"

    localfname="$(basename "$file")"
    mkdir -p "$(dirname "$dir")"
    if ! [ -d "$dir" ]; then
        if ! wget "$file"; then
            echo "$name download failed with exit code $?" >&2
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

# check if we have OpenSSH
dload "$opensshDir" "$opensshFile" "" "OpenSSH"

# check if we have glibc
dload "$glibcDir" "$glibcFile" "" "glibc"

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
    ./configure
fi
# we only need blkid
make blkid -j"$(nproc)"
popd > /dev/null || exit 1


# build OpenSSH
pushd "$opensshDir" > /dev/null || exit 1
if ! [ -f configure ]; then
    autoreconf
fi
if ! [ -f Makefile ]; then
    ./configure \
    --with-security-key-builtin \
    --with-ssl-engine --with-pam \
    --without-zlib-version-check
fi
make -j"$(nproc)"
popd > /dev/null || exit 1


# build glibc
pushd "${glibcDir}" > /dev/null || exit 1
if ! [ -f configure ]; then
    autoreconf
fi
popd > /dev/null || exit 1

mkdir "${glibcDir}_build" -p
pushd "${glibcDir}_build" > /dev/null || exit 1
if ! [ -f Makefile ]; then
    "${glibcDir}/configure" \
    --prefix="${glibcDir}_install"
fi
make -j"$(nproc)"
if ! [ -f "${glibcDir}_install/lib/ld-linux-x86-64.so.2" ]; then
    make -j"$(nproc)" install
fi
popd > /dev/null || exit 1


# make base initrd structure
pushd "$build/initramfs" > /dev/null || exit 1
mkdir -p usr/bin usr/sbin usr/lib usr/share etc
ln -s usr/bin bin
ln -s usr/sbin sbin
ln -s usr/lib lib
ln -s lib usr/lib64
ln -s usr/lib64 lib64
ln -s busybox bin/sh
popd > /dev/null || exit 1

# get the files and where they need to go
for file in "${FILES[@]}"; do
    hostPath=$(echo "$file" | cut -f1 -d:)
    initrdPath=$(echo "$file" | cut -f2 -d:)

    echo "copying $hostPath to $build/initramfs$initrdPath"
    cp "$hostPath" "$build/initramfs$initrdPath"
done

pushd "$build/initramfs" > /dev/null || exit 1
# find . | cpio -o --format='newc' | lz4 -3 - ../initramfs.img
find . | cpio -o --format='newc' > ../initramfs.img

popd > /dev/null || exit 1