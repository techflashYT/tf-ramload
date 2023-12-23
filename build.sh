MODULES=(
    virtio_net net_failover
    virtio_blk virtio_console
    virtio_balloon virtio_scsi
    virtio_pci virtio_pci_legacy_dev
    virtio_pci_modern_dev
    i8042 bochs
    drm_vram_helper
    drm_ttm_helper
)

build="$PWD/_buildTmp"
busyboxDir="$PWD/busybox-1.36.1"
busyboxFile="https://busybox.net/downloads/busybox-1.36.1.tar.bz2"
busyboxConfig="busyboxConfig"

FILES=(
    "$PWD/ramload.sh:/init"
    "$busyboxDir/busybox:/bin/busybox"
)

rm -rf "$build"
mkdir "$build"


# check if we have busybox
if ! [ -d "$busyboxDir" ]; then
    wget "$busyboxFile"
    exitCode=$?
    if [ $exitCode != 0 ]; then
        echo "Busybox download failed with exit code $exitCode" >&2
        exit 1
    fi
    tar xf "$busyboxFile"
    cp "$busyboxConfig" "$busyboxDir/.config"
fi

# build busybox
pushd "$busyboxDir" > /dev/null
make
popd > /dev/null



# make base initrd structure
cd "$build"
mkdir -p usr/bin usr/lib usr/share etc
ln -s usr/bin bin
ln -s usr/lib lib
ln -s usr/lib usr/lib64
ln -s usr/lib64 lib64
cd ..

# get the files and where they need to go
for file in ${FILES[@]}; do
    hostPath=$(echo $file | cut -f1 -d:)
    initrdPath=$(echo $file | cut -f2 -d:)

    echo "copying $hostPath to $build$initrdPath"
    cp "$hostPath" "$build$initrdPath"
done


