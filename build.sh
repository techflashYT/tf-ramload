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

FILES=(
    "$PWD/ramload.sh:/init"
)

rm -rf _buildTmp
mkdir _buildTmp

