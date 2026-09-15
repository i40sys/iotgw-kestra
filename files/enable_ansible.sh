#!/bin/sh

MOUNT_PATH="/mnt/p"

echo "Minimal OpenWRT setup for using Ansible"
chroot "${MOUNT_PATH}2" /bin/sh <<'EOF'
set -e

echo "=== Disabling firewall ==="
# Remove any firewall startup scripts (using -f to avoid errors if not present)
# rm -f /etc/rc.d/S[0-9][0-9]firewall

echo "=== Removing dropbear startup links ==="
rm -f /etc/rc.d/S[0-9][0-9]dropbear

echo "=== Setting up environment ==="
mkdir -p /var/lock
chmod 1777 /var/lock
echo "nameserver 8.8.8.8" > /etc/resolv.conf

opkg update
opkg install openssh-server openssh-keygen openssh-sftp-server python3

echo "=== SSH access is installed OUTSIDE the chroot from a vendored key file (task-091) ==="

echo "=== Enabling OpenSSH ==="
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
/etc/init.d/sshd enable

rm /etc/resolv.conf

echo "=== OpenWRT minimal Ansible setup completed inside chroot ==="
EOF

if [ $? -ne 0 ]; then
    echo "Failed: Minimal OpenWRT setup for using Ansible."
    exit 1
fi

# --- SSH access: vendored break-glass keys, NO public-internet fetch (task-091) ---
# The playbook drops the vendored key file at /tmp/authorized_keys (shipped in the
# namespace blob, decision-025). We install it into the target rootfs directly —
# no `wget github.com/*.keys` over plain HTTP redirects.
if [ ! -s /tmp/authorized_keys ]; then
    echo "Failed: /tmp/authorized_keys (vendored break-glass keys) is missing or empty."
    exit 1
fi
mkdir -p "${MOUNT_PATH}2/root/.ssh"
cp /tmp/authorized_keys "${MOUNT_PATH}2/root/.ssh/authorized_keys"
chmod 700 "${MOUNT_PATH}2/root/.ssh"
chmod 600 "${MOUNT_PATH}2/root/.ssh/authorized_keys"
echo "Installed vendored authorized_keys into the target rootfs."

echo "Minimal OpenWRT setup for using Ansible completed."
