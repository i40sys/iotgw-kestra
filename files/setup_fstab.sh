#!/bin/sh

# Check if a target disk was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <target_disk>"
    exit 1
fi

TARGET_DISK="$1"
echo "Target disk: $TARGET_DISK"

MOUNT_PATH="/mnt/p"

echo "Setting /etc/config/fstab"
chroot "${MOUNT_PATH}2" /bin/sh <<EOF
TARGET_DISK="${TARGET_DISK}"

# Determine partition prefix based on TARGET_DISK.
case "\$TARGET_DISK" in
    *[0-9])
        PART_PREFIX="\${TARGET_DISK}p"
        ;;
    *)
        PART_PREFIX="\${TARGET_DISK}"
        ;;
esac

# Define partitions and mount points.
PART1="\${PART_PREFIX}3"
MOUNT_POINT1="/opt"
FSTYPE1="xfs"

PART2="\${PART_PREFIX}1"
MOUNT_POINT2="/boot"
FSTYPE2="vfat"

# Prepare environment.
mkdir -p /var/lock
chmod 1777 /var/lock
echo nameserver 8.8.8.8 > /etc/resolv.conf
opkg update
opkg install block-mount kmod-fs-xfs

# Function to configure a partition.
configure_partition() {
    PART=\$1
    MOUNT_POINT=\$2
    FSTYPE=\$3

    # Get the UUID for the partition.
    UUID=\$(block info | grep "\$PART" | cut -f 2 -d " " | cut -f 2 -d "=")
    UUID=\${UUID//\"/}

    if [ -z "\$UUID" ]; then
        echo "Error: Failed to obtain UUID for \$PART"
        exit 1
    fi

    # Find the fstab entry ID for the partition.
    MOUNT_ID=\$(uci show fstab | grep "\$UUID" | sed -n 's/.*fstab.\(.*\).uuid.*/\1/p')
    if [ -z "\$MOUNT_ID" ]; then
        echo "Error: No fstab entry found for UUID \$UUID"
        exit 1
    fi

    # Configure the fstab entry.
    uci set fstab.\$MOUNT_ID.target="\$MOUNT_POINT"
    uci set fstab.\$MOUNT_ID.enabled='1'
    uci set fstab.\$MOUNT_ID.fstype="\$FSTYPE"

    echo "The partition \$PART has been configured to mount at \$MOUNT_POINT with the \$FSTYPE filesystem."
}

# Configure partition for /opt (XFS)
configure_partition "\$PART1" "\$MOUNT_POINT1" "\$FSTYPE1"

# Configure partition for /boot (VFAT)
configure_partition "\$PART2" "\$MOUNT_POINT2" "\$FSTYPE2"

uci commit fstab
rm /etc/resolv.conf
EOF

if [ $? -ne 0 ]; then
    echo "Failed: /etc/config/fstab setup."
    exit 1
fi
