#!/bin/bash

# Install nbd-client for  manipulating nbd-labeled virtual network disks
DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get install nbd-client -y

# Device to exclude from wiping (e.g., OS disk)
EXCLUDE_DEVICE="/dev/sda"

# Get a list of all block devices except the excluded one
devices=$(lsblk -d -o NAME | awk 'FNR>1' | grep -v "$(basename $EXCLUDE_DEVICE)")

# Function to zap and wipe a disk
zap_and_wipe_disk() {
    local disk=$1
    local dev_path="/dev/$disk"

    echo "Zapping and wiping disk: $dev_path"

    # Step 1: Zap the disk to a fresh, usable state
    sgdisk --zap-all "$dev_path"

    # Step 2: Wipe a large portion of the beginning of the disk to remove LVM metadata
    dd if=/dev/zero of="$dev_path" bs=1M count=100 oflag=direct,dsync

    # Step 3: If the disk is an SSD, clean it with blkdiscard
    if cat /sys/block/"$disk"/queue/rotational | grep -q 0; then
        blkdiscard "$dev_path" || echo "blkdiscard failed on $dev_path (not an SSD?)"
    fi

    # Step 4: Inform the OS of partition table changes
    partprobe "$dev_path"

    echo "Disk $dev_path has been successfully zapped and wiped."
}

# Cleanup Ceph-related device mappings and directories
cleanup_ceph_devices() {
    echo "Cleaning up Ceph-related devices and directories..."

    # Remove any Ceph-related device mapper entries
    ls /dev/mapper/ceph-* 2>/dev/null | xargs -I% -- dmsetup remove %

    # Remove Ceph-related directories in /dev and /dev/mapper
    rm -rf /dev/ceph-* /dev/mapper/ceph--*

    echo "Ceph-related devices and directories have been cleaned up."
}

# Perform Ceph device cleanup once
cleanup_ceph_devices

# Iterate over all devices and zap/wipe them (except the excluded one)
for device in $devices; do
    zap_and_wipe_disk $device
done

echo "All non-system disks have been zapped, wiped, and prepared for use, except $EXCLUDE_DEVICE."

# Delete all nbd disks from all nodes

sleep 3
for i in $(lsblk |grep nbd |awk '{print $1}'); do
        nbd-client -d /dev/$i;
done

# Delete the /var/lib/rook directory 
rm -rf /var/lib/rook
