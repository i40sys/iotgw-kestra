#!/bin/bash

echo "Script started."

# Check if the parameters are empty
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <target_disk> <open_wrt_version>"
    echo "Example: $0 /dev/nvme0n1 23.05.4"
    exit 1
fi

TARGET_DISK="$1"
echo "Target disk: $TARGET_DISK"

# Check if the target disk exists
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: $TARGET_DISK does not exist or is not a block device"
    exit 1
fi

VERSION="$2"
IMAGE="openwrt-${VERSION}-x86-64-generic-ext4-combined-efi.img"
WDIR="/root/image"

echo "Changing directory to /"
cd / || { echo "Failed to change directory to /"; exit 1; }
echo "Removing and recreating working directory ${WDIR}"
rm -rf "${WDIR}"
mkdir -p "${WDIR}" || { echo "Failed to create directory ${WDIR}"; exit 1; }
cd "${WDIR}" || { echo "Failed to change directory to ${WDIR}"; exit 1; }

echo "Downloading OpenWrt image"
wget "https://downloads.openwrt.org/releases/${VERSION}/targets/x86/64/${IMAGE}.gz"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download ${IMAGE}.gz"
    exit 1
fi

echo "Decompressing image"
gzip -d "${IMAGE}.gz"
DECOMPRESS_EXIT=$?
if [ $DECOMPRESS_EXIT -ne 0 ] && [ $DECOMPRESS_EXIT -ne 2 ]; then
    echo "Error: Failed to decompress ${IMAGE}.gz"
    exit 1
fi

echo "Setting up loop device for ${IMAGE}"
LOOPDEV=$(losetup -f --show -P "${IMAGE}")
if [ $? -ne 0 ] || [ -z "$LOOPDEV" ]; then
    echo "Error: Failed to set up loop device for ${IMAGE}"
    exit 1
fi
echo "Loop device: $LOOPDEV"

# Mounting image partitions
echo "Mounting image partitions"
mkdir -p /mnt/boot /mnt/root
mount "${LOOPDEV}p1" /mnt/boot
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount ${LOOPDEV}p1"
    exit 1
fi
mount "${LOOPDEV}p2" /mnt/root
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount ${LOOPDEV}p2"
    exit 1
fi

# Mounting target disk partitions
echo "Mounting target disk partitions"
# Determine partition prefix for target disk
case "$TARGET_DISK" in
    *[0-9])
        TARGET_PART_PREFIX="${TARGET_DISK}p"
        ;;
    *)
        TARGET_PART_PREFIX="${TARGET_DISK}"
        ;;
esac

mkdir -p /mnt/target_boot /mnt/target_root
mount "${TARGET_PART_PREFIX}1" /mnt/target_boot
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount ${TARGET_PART_PREFIX}1"
    exit 1
fi
mount "${TARGET_PART_PREFIX}2" /mnt/target_root
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount ${TARGET_PART_PREFIX}2"
    exit 1
fi

# Copying files from image to target disk
echo "Copying files from image to target disk"
cp -Ra /mnt/boot/* /mnt/target_boot
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files from /mnt/boot to /mnt/target_boot"
    exit 1
fi
cp -Ra /mnt/root/* /mnt/target_root
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files from /mnt/root to /mnt/target_root"
    exit 1
fi
mkdir -p /mnt/target_root/opt

# Setting up default network configuration
echo "Setting up default network configuration"
if [ -f /mnt/target_root/etc/config/network ]; then
    cp /mnt/target_root/etc/config/network /mnt/target_root/etc/config/network.orig
fi
cat <<EOF > /mnt/target_root/etc/config/network
config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config globals 'globals'

config device
	option name 'br-lan'
	option type 'bridge'
	list ports 'eth1'
	list ports 'eth2'
	list ports 'eth3'
	list ports 'eth4'
	list ports 'eth5'
	option ipv6 '0'

config interface 'lan'
	option device 'br-lan'
	option proto 'static'
	option ipaddr '10.254.253.1'
	option netmask '255.255.255.0'
	option ip6assign '60'
	option delegate '0'
	list dns_search ''

config interface 'wan'
	option device 'eth0'
	option proto 'dhcp'
EOF

# Setting up default DHCP configuration
echo "Setting up DHCP server for LAN"
if [ -f /mnt/target_root/etc/config/dhcp ]; then
    cp /mnt/target_root/etc/config/dhcp /mnt/target_root/etc/config/dhcp.orig
fi
cat <<EOF > /mnt/target_root/etc/config/dhcp
config dnsmasq
	option domainneeded '1'
	option rebind_protection '0'
	option local '/lan/'
	option domain 'lan'
	option expandhosts '1'
	option cachesize '1000'
	option authoritative '1'
	option readethers '1'
	option leasefile '/tmp/dhcp.leases'
	option resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'
	option localservice '0'
	option ednspacket_max '1232'
	list interface 'lan'
	option boguspriv '0'

config dhcp 'lan'
	option interface 'lan'
	option start '100'
	option limit '120'
	option leasetime '24h'
	option dhcpv4 'server'
	list dhcp_option ' 42,10.121.105.1'
	list dhcp_option '6,10.121.105.1'

config dhcp 'wan'
	option interface 'wan'
	option ignore '1'
	option start '100'
	option limit '150'
	option leasetime '12h'

config odhcpd 'odhcpd'
	option maindhcp '0'
	option leasefile '/tmp/hosts/odhcpd'
	option leasetrigger '/usr/sbin/odhcpd-update'
	option loglevel '4'
EOF

# Unmounting image and target disk partitions
echo "Unmounting image and target disk partitions"
umount /mnt/boot
if [ $? -ne 0 ]; then
    echo "Error: Failed to unmount /mnt/boot"
    exit 1
fi
umount /mnt/root
if [ $? -ne 0 ]; then
    echo "Error: Failed to unmount /mnt/root"
    exit 1
fi
umount /mnt/target_boot
if [ $? -ne 0 ]; then
    echo "Error: Failed to unmount /mnt/target_boot"
    exit 1
fi
umount /mnt/target_root
if [ $? -ne 0 ]; then
    echo "Error: Failed to unmount /mnt/target_root"
    exit 1
fi

# Detaching loop device
echo "Detaching loop device"
kpartx -d "${LOOPDEV}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to delete partitions for loop device ${LOOPDEV}"
    exit 1
fi

losetup -d "${LOOPDEV}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to detach loop device ${LOOPDEV}"
    exit 1
fi

echo "Script completed successfully."
