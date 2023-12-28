#!/bin/sh

echo "PID of goload is $$"
echo "Loading from /dev/$1"

mkdir /mnt/disk
mount "/dev/$1" /mnt/disk

mkdir /mnt/toLoad
mount -t tmpfs tmpfs /mnt/toLoad
cp -av /mnt/disk/* /mnt/toLoad/
cp -av /mnt/disk/.* /mnt/toLoad/
umount /mnt/disk

exec switch_root /mnt/toLoad /sbin/init