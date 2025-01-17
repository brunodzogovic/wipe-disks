#!/bin/bash

# Device to exclude from wiping (e.g., OS disk)
EXCLUDE_DEVICE="/dev/sda"

# Get a list of all block devices except the excluded one
devices=$(lsblk -d -o NAME |awk 'FNR>1' | grep -v "$(basename $EXCLUDE_DEVICE)")

# Function to wipe a disk
wipe_disk() {
    local disk=$1
    echo "Wiping disk: /dev/$disk"

    # Wipe the disk's filesystem signatures and partition tables
    wipefs --all --force "/dev/$disk"

    # Optionally, you can also use dd to wipe the first 1MB of the disk, to clear partition table:
    # dd if=/dev/zero of="/dev/$disk" bs=1M count=1 oflag=sync
}

# Iterate over all devices and wipe them (except the excluded one)
for device in $devices; do
    wipe_disk $device
done

echo "All non-system disks have been wiped except $EXCLUDE_DEVICE."
