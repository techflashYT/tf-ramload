qemu-system-x86_64 -kernel _buildTmp/bzImage -initrd _buildTmp/initramfs.img -append 'init=/bin/sh loglevel=6 console=ttyS0'  -device virtio-blk-pci,drive=drive0,id=virtblk0,num-queues=4 -drive file=disk.qcow2,if=none,id=drive0 -m 16G
