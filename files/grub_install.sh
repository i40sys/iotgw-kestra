#!/bin/sh

echo "Script for grub-bios-setup."

# Check if the parameter is empty
if [ -z "$1" ]; then
    echo "Usage: $0 <target_disk>"
    exit 1
fi

TARGET_DISK="$1"
echo "Target disk: $TARGET_DISK"

# Check if the target disk exists
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: $TARGET_DISK does not exist or is not a block device"
    exit 1
fi

MOUNT_PATH="/mnt/p"

# Ensure that the chroot mount point for partition 2 exists
if [ ! -d "${MOUNT_PATH}2" ]; then
    echo "Error: Mount point ${MOUNT_PATH}2 does not exist. Please mount your root partition at ${MOUNT_PATH}2 before running this script."
    exit 1
fi

echo "Running grub-bios-setup in chroot environment..."
chroot "${MOUNT_PATH}2" grub-bios-setup "${TARGET_DISK}"
if [ $? -ne 0 ]; then
    echo "grub-bios-setup failed."
    exit 1
fi

echo "Script for grub-bios-setup: done."
