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

dialogFile="https://invisible-mirror.net/archives/dialog/dialog-1.3-20231002.tgz"
dialogDir="$PWD/deps/dialog"

ncursesFile="https://ftp.gnu.org/gnu/ncurses/ncurses-6.4.tar.gz"
ncursesDir="$PWD/deps/ncurses"

opensslFile="https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz"
opensslDir="$PWD/deps/openssl"

libxcryptFile="https://github.com/besser82/libxcrypt/releases/download/v4.4.36/libxcrypt-4.4.36.tar.xz"
libxcryptDir="$PWD/deps/libxcrypt"

zlibFile="https://codeload.github.com/madler/zlib/zip/643e17b7498d12ab8d15565662880579692f769d"
zlibDir="$PWD/deps/zlib"

pamFile="https://github.com/linux-pam/linux-pam/releases/download/v1.5.3/Linux-PAM-1.5.3.tar.xz"
pamDir="$PWD/deps/pam"

libmdFile="https://libbsd.freedesktop.org/releases/libmd-1.1.0.tar.xz"
libmdDir="$PWD/deps/libmd"

auditFile="https://github.com/linux-audit/audit-userspace/archive/v3.1.2/audit-userspace-v3.1.2.tar.gz"
auditDir="$PWD/deps/audit"

libcapngFile="https://github.com/stevegrubb/libcap-ng/archive/v0.8.4/libcap-ng-0.8.4.tar.gz"
libcapngDir="$PWD/deps/libcap-ng"

FILES=(
    "$PWD/ramload.sh:/init"
    "$PWD/goLoad.sh:/goLoad"
    "$PWD/sshd_config:/etc/ssh/sshd_config"
    "$PWD/detectDisks.sh:/detectDisks"
    "$busyboxDir/busybox:/usr/bin/busybox"
    "$util_linuxDir/.libs/blkid:/usr/bin/blkid"
    "$util_linuxDir/.libs/libblkid.so:/usr/lib/libblkid.so"
    "$util_linuxDir/.libs/libblkid.so.1:/usr/lib/libblkid.so.1"
    "$util_linuxDir/.libs/libblkid.so.1.1.0:/usr/lib/libblkid.so.1.1.0"
    "$opensshDir/ssh:/usr/bin/ssh"
    "$opensshDir/sshd:/usr/bin/sshd"
    "$opensshDir/ssh-keygen:/usr/bin/ssh-keygen"
    "$opensshDir/scp:/usr/bin/scp"
    "${glibcDir}_install/lib64/ld-linux-x86-64.so.2:/usr/lib/ld-linux-x86-64.so.2"
    "${glibcDir}_install/usr/lib64/libc.so:/usr/lib/libc.so"
    "${glibcDir}_install/lib64/libc.so.6:/usr/lib/libc.so.6"
    "${glibcDir}_install/usr/lib64/libm.so:/usr/lib/libm.so"
    "${glibcDir}_install/lib64/libm.so.6:/usr/lib/libm.so.6"
    "${glibcDir}_install/usr/lib64/libresolv.so:/usr/lib/libresolv.so"
    "${glibcDir}_install/lib64/libresolv.so.2:/usr/lib/libresolv.so.2"
    "${glibcDir}_install/usr/bin/ldd:/usr/bin/ldd"
    "${glibcDir}_install/sbin/ldconfig:/usr/sbin/ldconfig"
    "$ncursesDir/lib/libncursesw.so:/usr/lib/libncursesw.so"
    "$ncursesDir/lib/libncursesw.so.6:/usr/lib/libncursesw.so.6"
    "$ncursesDir/lib/libncursesw.so.6.4:/usr/lib/libncursesw.so.6.4"
    "$ncursesDir/lib/libpanelw.so:/usr/lib/libpanelw.so"
    "$ncursesDir/lib/libpanelw.so.6:/usr/lib/libpanelw.so.6"
    "$ncursesDir/lib/libpanelw.so.6.4:/usr/lib/libpanelw.so.6.4"
    "$ncursesDir/lib/libformw.so:/usr/lib/libformw.so"
    "$ncursesDir/lib/libformw.so.6:/usr/lib/libformw.so.6"
    "$ncursesDir/lib/libformw.so.6.4:/usr/lib/libformw.so.6.4"
    "$ncursesDir/lib/libmenuw.so:/usr/lib/libmenuw.so"
    "$ncursesDir/lib/libmenuw.so.6:/usr/lib/libmenuw.so.6"
    "$ncursesDir/lib/libmenuw.so.6.4:/usr/lib/libmenuw.so.6.4"
    "$ncursesDir/progs/clear:/usr/bin/clear"
    "$opensslDir/libcrypto.so:/usr/lib/libcrypto.so"
    "$opensslDir/libcrypto.so.3:/usr/lib/libcrypto.so.3"
    "$libxcryptDir/.libs/libcrypt.so:/usr/lib/libcrypt.so"
    "$libxcryptDir/.libs/libcrypt.so.2:/usr/lib/libcrypt.so.2"
    "$libxcryptDir/.libs/libcrypt.so.2.0.0:/usr/lib/libcrypt.so.2.0.0"
    "$zlibDir/libz.so:/usr/lib/libz.so"
    "$zlibDir/libz.so.1:/usr/lib/libz.so.1"
    "$zlibDir/libz.so.1.3.0.1-motley:/usr/lib/libz.so.1.3.0.1-motley"
    "$pamDir/libpam/.libs/libpam.so:/usr/lib/libpam.so"
    "$pamDir/libpam/.libs/libpam.so.0:/usr/lib/libpam.so.0"
    "$pamDir/libpam/.libs/libpam.so.0.85.1:/usr/lib/libpam.so.0.85.1"
    "$libmdDir/src/.libs/libmd.so:/usr/lib/libmd.so"
    "$libmdDir/src/.libs/libmd.so.0:/usr/lib/libmd.so.0"
    "$libmdDir/src/.libs/libmd.so.0.1.0:/usr/lib/libmd.so.0.1.0"
    "$auditDir/lib/.libs/libaudit.so:/usr/lib/libaudit.so"
    "$auditDir/lib/.libs/libaudit.so.1:/usr/lib/libaudit.so.1"
    "$auditDir/lib/.libs/libaudit.so.1.0.0:/usr/lib/libaudit.so.1.0.0"
    "$libcapngDir/src/.libs/libcap-ng.so:/usr/lib/libcap-ng.so"
    "$libcapngDir/src/.libs/libcap-ng.so.0:/usr/lib/libcap-ng.so.0"
    "$libcapngDir/src/.libs/libcap-ng.so.0.0.0:/usr/lib/libcap-ng.so.0.0.0"

    "$dialogDir/dialog:/usr/bin/dialog"
    "/usr/share/terminfo/l/linux"
)

function dload() {
    dir="$1"
    file="$2"
    config="$3"
    name="$4"
    optdownloadName="$5"

    localfname="$(basename "$file")"
    mkdir -p "$(dirname "$dir")"
    if ! [ -d "$dir" ]; then
        if [ "$optdownloadName" != "" ]; then
            args="-O $optdownloadName"
            localfname="$optdownloadName"
        fi

        if ! wget "$file" $args; then
            echo "$name download failed with exit code $?" >&2
            exit 1
        fi
        # e.g. move busybox-1.36.1 to busybox
        case "$localfname" in
            *.tar*)       tar xf    "$localfname"; mv "${localfname//\.tar*/}" "$dir" ;;
            *.tgz)        tar xf    "$localfname"; mv "${localfname//\.tgz/}" "$dir"  ;;
            *_github.zip) unzip -qq "$localfname"; mv "${localfname//_github.zip/}"-* "$dir"  ;;
            *) echo "UNIMPLEMENTED FILE TYPE: $localfname" ;;
        esac
            
        # mv "$(echo "$localfname" | sed 's/\.tar.*//g')" "$dir"

        if [ "$config" != "" ]; then
            cp "$config" "$dir/.config"
        fi

        rm "$localfname"
    fi
}


stdbuild() {
    echo "build $2"
    pushd "$2" > /dev/null || exit 1
    if [ "$1" != "" ] && ! { [ -f Makefile ] || [ -f makefile ]; } ; then
        if ! [ -f configure ] && ! [ -f Configure ]; then
            autoreconf -fiv
        fi
        $1
    fi
    make -j"$(nproc)" $3
    popd > /dev/null || exit 1
}


rm -rf "$build"
mkdir "$build/initramfs" -p


dload "$busyboxDir" "$busyboxFile" "$busyboxConfig" "Busybox"
dload "$linuxDir" "$linuxFile" "$linuxConfig" "Linux kernel"
dload "$util_linuxDir" "$util_linuxFile" "" "util-linux"
dload "$opensshDir" "$opensshFile" "" "OpenSSH"
dload "$glibcDir" "$glibcFile" "" "glibc"
dload "$ncursesDir" "$ncursesFile" "" "ncurses"
dload "$dialogDir" "$dialogFile" "" "dialog app"
dload "$opensslDir" "$opensslFile" "" "OpenSSL"
dload "$libxcryptDir" "$libxcryptFile" "" "libxcrypt"
dload "$zlibDir" "$zlibFile" "" "zlib" "zlib_github.zip"
dload "$pamDir" "$pamFile" "" "PAM"
dload "$libmdDir" "$libmdFile" "" "libmd"
dload "$auditDir" "$auditFile" "" "audit" "audit-userspace-3.1.2.tar.gz"
dload "$libcapngDir" "$libcapngFile" "" "libcap-ng"

stdbuild "" "$busyboxDir"

stdbuild "" "$linuxDir"
cp "$kernelPath" "$build/"

stdbuild "./configure" "$util_linuxDir" "blkid"
stdbuild "./configure --with-shared --enable-widec --with-versioned-syms" "$ncursesDir"
stdbuild "./configure --with-ncurses --without-ncursesw" "$dialogDir"
stdbuild "./configure --with-security-key-builtin --with-ssl-engine --with-pam --without-zlib-version-check --prefix=/usr --sysconfdir=/etc/ssh" "$opensshDir"
stdbuild "./Configure shared enable-ktls enable-ec_nistp_64_gcc_128 linux-x86_64" "$opensslDir"
stdbuild "./configure --disable-static --enable-hashes=strong,glibc --enable-obsolete-api=no --disable-failure-tokens" "$libxcryptDir"
if [ "$(sha256sum "$zlibDir/Makefile")" = "ef23b08ce01239843f1ded3f373bfc432627a477d62f945cbf63b2ac03db118a  $zlibDir/Makefile" ]; then
    rm "$zlibDir/Makefile"
fi
stdbuild "./configure" "$zlibDir"
stdbuild "./configure" "$pamDir"
stdbuild "./configure" "$libmdDir"
stdbuild "./configure" "$auditDir"
touch "$libcapngDir/NEWS"
stdbuild "./configure" "$libcapngDir"

# build glibc
pushd "${glibcDir}" > /dev/null || exit 1
if ! [ -f configure ]; then
    autoreconf
fi
popd > /dev/null || exit 1

mkdir "${glibcDir}_build" -p
pushd "${glibcDir}_build" > /dev/null || exit 1

# !!! !!! !!! WARNING !!! !!! !!!
# If this goes wrong at any point, your system glibc may be overwritten
# please do not run this as root!
if ! [ -f Makefile ]; then
    "${glibcDir}/configure" --prefix="/usr"
fi
if ! [ -f "${glibcDir}_install/lib64/ld-linux-x86-64.so.2" ]; then
    make -j"$(nproc)" DESTDIR="${glibcDir}_install" install
fi
popd > /dev/null || exit 1


# make base initrd structure
pushd "$build/initramfs" > /dev/null || exit 1
mkdir -p usr/bin usr/sbin usr/lib usr/share/terminfo/l etc/ssh
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
    cp -d "$hostPath" "$build/initramfs$initrdPath"
done

pushd "$build/initramfs" > /dev/null || exit 1
# find . | cpio -o --format='newc' | lz4 -3 - ../initramfs.img
find . | cpio -o --format='newc' > ../initramfs.img

popd > /dev/null || exit 1