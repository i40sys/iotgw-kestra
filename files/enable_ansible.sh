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

echo "=== Configuring SSH access ==="
mkdir -p /root/.ssh/
wget -O /root/.ssh/authorized_keys https://github.com/example-org.keys
wget -O - https://links.example.com/ssh-pub-key 2>/dev/null >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

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

echo "Minimal OpenWRT setup for using Ansible completed."
