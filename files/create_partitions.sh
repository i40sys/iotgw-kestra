#!/bin/bash

echo "Script started."

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

# Determine partition prefix:
# If the disk name ends with a digit (e.g. /dev/nvme0n1), then use "p" as a separator,
# Otherwise (e.g. /dev/sda), no separator is needed.
if [[ $TARGET_DISK =~ [0-9]$ ]]; then
    PART_PREFIX="${TARGET_DISK}p"
else
    PART_PREFIX="${TARGET_DISK}"
fi
echo "Partition prefix: $PART_PREFIX"

# Function to unmount all partitions on the target disk
unmount_partitions() {
    local disk="$1"
    echo "Finding mounted partitions on $disk"
    local mounted_partitions
    mounted_partitions=$(mount | grep "$disk" | cut -f 1 -d " " | xargs)

    if [ -z "$mounted_partitions" ]; then
        echo "No mounted partitions found on $disk"
    else
        echo "Unmounting partitions on $disk"
        for partition in $mounted_partitions; do
            echo "Unmounting $partition"
            umount -l "$partition" 2>/dev/null || {
                echo "Failed to unmount $partition"
                exit 1
            }
        done
    fi
}

# Warning message
echo "Warning: The existing disk label on $TARGET_DISK will be destroyed and all data on this disk will be lost. Proceeding with the operation..."

# Unmount all partitions on the target disk
unmount_partitions "$TARGET_DISK"

# Wipe the existing partitions and create a GPT partition table
echo "Wiping existing partitions and creating GPT partition table on $TARGET_DISK"
sgdisk --zap-all "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to wipe partitions and create GPT partition table"
    exit 1
fi

# Create partitions using sgdisk
echo "Creating partitions on $TARGET_DISK"
# Create a bios_grub partition with ID 128
sgdisk --new=128:2048:6143 --typecode=128:ef02 --change-name=128:"bios_grub" "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create bios_grub partition"
    exit 1
fi

# Create FAT16 partition
sgdisk --new=1:6144:40959 --typecode=1:0C00 --change-name=1:"primary" "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create FAT16 partition"
    exit 1
fi
# Set the legacy_boot flag and remove the msftdata flag
parted "$TARGET_DISK" set 1 legacy_boot on
# Remove the msftdata flag
parted $TARGET_DISK set 1 msftdata off

echo "Creating FAT16 filesystem on ${PART_PREFIX}1"
mkfs.fat -F16 -I "${PART_PREFIX}1"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create FAT16 filesystem"
    exit 1
fi

# Create ext4 partition for 19MiB to 100GB
sgdisk --new=2:40960:195312500 --typecode=2:8300 --change-name=2:"primary" "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create ext4 partition (19MiB to 100GB)"
    exit 1
fi

echo "Creating ext4 filesystem on ${PART_PREFIX}2"
mkfs.ext4 -F "${PART_PREFIX}2"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create ext4 filesystem"
    exit 1
fi

# Create ext4 partition for 100GB to 100%
sgdisk --new=3:195312501:0 --typecode=3:8300 --change-name=3:"primary" "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create ext4 partition (100GB to 100%)"
    exit 1
fi

echo "Formatting XFS filesystem on ${PART_PREFIX}3"
mkfs.xfs -i nrext64=0 -f "${PART_PREFIX}3"

    # -b size=4096 \
    # -m crc=1,finobt=1,reflink=1,bigtime=1,inobtcount=1 \
    # -d su=0,sw=0 \
    # -i size=512 \
    # -l version=2,size=107312b \

if [ $? -ne 0 ]; then
    echo "Error: Failed to create XFS filesystem"
    exit 1
fi

# Inform the OS of partition table changes
echo "Informing the OS of partition table changes"
partprobe "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to inform the OS of partition table changes"
    exit 1
fi

# Print the resulting partition table
echo "Printing the resulting partition table"
sgdisk -p "$TARGET_DISK"
if [ $? -ne 0 ]; then
    echo "Error: Failed to print the partition table"
    exit 1
fi

echo "Partitioning completed successfully."
