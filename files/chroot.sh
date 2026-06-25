#!/bin/sh

echo "Getting ready, a chroot env for openwrt..."

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

# Determine partition prefix based on the disk name.
# If TARGET_DISK ends with a digit, add "p"; otherwise, use TARGET_DISK as-is.
case "$TARGET_DISK" in
    *[0-9])
        PART_PREFIX="${TARGET_DISK}p"
        ;;
    *)
        PART_PREFIX="${TARGET_DISK}"
        ;;
esac

MOUNT_PATH="/mnt/p"

echo "Creating mount directories."
mkdir -p "${MOUNT_PATH}1"
mkdir -p "${MOUNT_PATH}2"

echo "Mounting ${PART_PREFIX}1 to ${MOUNT_PATH}1"
mount "${PART_PREFIX}1" "${MOUNT_PATH}1"
if [ $? -ne 0 ]; then
    echo "Failed to mount ${PART_PREFIX}1 to ${MOUNT_PATH}1"
    exit 1
fi

echo "Mounting ${PART_PREFIX}2 to ${MOUNT_PATH}2"
mount "${PART_PREFIX}2" "${MOUNT_PATH}2"
if [ $? -ne 0 ]; then
    echo "Failed to mount ${PART_PREFIX}2 to ${MOUNT_PATH}2"
    exit 1
fi

echo "Binding /dev, /proc, and /sys"
mount -o bind /dev "${MOUNT_PATH}2/dev"
mount -o bind /proc "${MOUNT_PATH}2/proc"
mount -o bind /sys "${MOUNT_PATH}2/sys"

echo "Creating boot and efi directories."
mkdir -p "${MOUNT_PATH}2/boot"
mkdir -p "${MOUNT_PATH}2/efi"

echo "Binding boot and efi directories."
mount -o bind "${MOUNT_PATH}1/boot" "${MOUNT_PATH}2/boot"
mount -o bind "${MOUNT_PATH}1/efi" "${MOUNT_PATH}2/efi"

echo "chroot env, ready."
