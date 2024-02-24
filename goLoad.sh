#!/bin/sh

echo "PID of goload is $$"
echo "Loading from /dev/$1"
if [ -n "$2" ]; then
	echo "mount args $2"
fi

mkdir /mnt/disk
mount "/dev/$1" /mnt/disk $2

mkdir /mnt/toLoad
mount -t tmpfs tmpfs /mnt/toLoad
cp -av /mnt/disk/* /mnt/toLoad/
cp -av /mnt/disk/.* /mnt/toLoad/
umount /mnt/disk

exec switch_root /mnt/toLoad /sbin/init
