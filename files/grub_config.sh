#!/bin/bash

echo "Script started."

# Check if the parameter is empty
if [ -z "$1" ]; then
    echo "Usage: $0 <target_disk>"
    exit 1
fi

# Trim leading and trailing spaces from the input parameter
TARGET_DISK=$(echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
echo "Target disk: $TARGET_DISK"

# Check if the target disk exists
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: $TARGET_DISK does not exist or is not a block device"
    exit 1
fi

# Determine partition prefix:
# If the disk name ends with a digit (e.g. /dev/nvme0n1), then use "p" as a separator,
# Otherwise (e.g. /dev/sda), no separator is needed.
if [[ $TARGET_DISK =~ [0-9]$ ]]; then
    PART_PREFIX="${TARGET_DISK}p"
else
    PART_PREFIX="${TARGET_DISK}"
fi
echo "Partition prefix: $PART_PREFIX"

MOUNT_PATH="/mnt/p1"

echo "Retrieving ROOT_UUID for ${PART_PREFIX}2"
ROOT_UUID=$(partx -g -o UUID "${PART_PREFIX}2")
if [ $? -ne 0 ]; then
    echo "Failed to retrieve ROOT_UUID"
    exit 1
fi
echo "ROOT_UUID: $ROOT_UUID"

echo "Changing directory to /"
cd /

echo "Unmounting ${MOUNT_PATH} if already mounted"
umount -l "${MOUNT_PATH}" 2>/dev/null
# Continue even if unmount fails

echo "Removing ${MOUNT_PATH} directory"
rm -rf "${MOUNT_PATH}"

echo "Creating ${MOUNT_PATH} directory"
mkdir -p "${MOUNT_PATH}"
if [ $? -ne 0 ]; then
    echo "Failed to create directory ${MOUNT_PATH}"
    exit 1
fi

echo "Mounting ${PART_PREFIX}1 to ${MOUNT_PATH}"
mount "${PART_PREFIX}1" "${MOUNT_PATH}"
if [ $? -ne 0 ]; then
    echo "Failed to mount ${PART_PREFIX}1 to ${MOUNT_PATH}"
    exit 1
fi

GRUB_CFG="${MOUNT_PATH}/boot/grub/grub.cfg"
if [ -f "${GRUB_CFG}" ]; then
    echo "Updating grub configuration in ${GRUB_CFG}"
    sed -i -r -e "s|(PARTUUID=)\S+|\1${ROOT_UUID}|g" "${GRUB_CFG}"
    if [ $? -ne 0 ]; then
        echo "Failed to update grub configuration"
        umount "${MOUNT_PATH}"
        exit 1
    fi
else
    echo "Warning: ${GRUB_CFG} not found, skipping grub update"
fi

echo "Unmounting ${MOUNT_PATH}"
umount "${MOUNT_PATH}"
if [ $? -ne 0 ]; then
    echo "Failed to unmount ${MOUNT_PATH}"
    exit 1
fi

echo "Removing ${MOUNT_PATH} directory"
rm -rf "${MOUNT_PATH}"
if [ $? -ne 0 ]; then
    echo "Failed to remove directory ${MOUNT_PATH}"
    exit 1
fi

echo "Script completed successfully."


# original script:
# # /sys/devices/pci0000:00/0000:00:1d.4/0000:08:00.0/nvme/nvme0/nvme0n1/nvme0n1p2
# ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e '$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
# # /dev/nvme0n1
# ROOT_DISK="/dev/$(basename "${ROOT_BLK%/*}")"
# # /dev/nvme0n1p2
# ROOT_DEV="/dev/${ROOT_BLK##*/}"
# # 80cdd189-4ce8-125d-9e5c-32a6bb5c6502
# ROOT_UUID="$(partx -g -o UUID "${ROOT_DEV}" "${ROOT_DISK}")"
# # replace the config file
# sed -i -r -e "s|(PARTUUID=)\S+|\1${ROOT_UUID}|g" /boot/grub/grub.cfg