#!/bin/sh

echo "PID of goload is $$"
echo "Loading from /dev/$1"

mkdir /mnt/toLoad
mount "/dev/$1" /mnt/toLoad

exec switch_root /mnt/toLoad /sbin/init