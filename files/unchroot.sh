#!/bin/sh

echo "Unsetting chroot env."

# Check if a target disk is provided.
if [ -z "$1" ]; then
    echo "Usage: $0 <target_disk>"
    exit 1
fi

TARGET_DISK="$1"
echo "Target disk: $TARGET_DISK"

# Check if the target disk exists.
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: $TARGET_DISK does not exist or is not a block device"
    exit 1
fi

MOUNT_PATH="/mnt/p"

echo "Unmounting boot, efi, sys, proc, and dev from chroot environment."
umount "${MOUNT_PATH}2/boot" 2>/dev/null
umount "${MOUNT_PATH}2/efi" 2>/dev/null
umount "${MOUNT_PATH}2/sys" 2>/dev/null
umount "${MOUNT_PATH}2/proc" 2>/dev/null
umount "${MOUNT_PATH}2/dev" 2>/dev/null

echo "Unmounting ${MOUNT_PATH}2 and ${MOUNT_PATH}1."
umount "${MOUNT_PATH}2" 2>/dev/null
umount "${MOUNT_PATH}1" 2>/dev/null

echo "Removing mount directories."
rm -rf "${MOUNT_PATH}1" "${MOUNT_PATH}2"

echo "Chroot environment unset."
