#!/bin/sh
# test
set -e

MOUNT_PATH="/mnt/p"
ROOTFS="${MOUNT_PATH}2"
WGCONF="/etc/wireguard/wg0.conf"

parse_wg_conf() {
  # Endpoint line: "Endpoint = 203.0.113.10:443"
  endpoint=$(awk '/^Endpoint/ {print $3; exit}' "$WGCONF")
  vpn_server_ip=${endpoint%%:*}
  vpn_server_port=${endpoint##*:}

  # PrivateKey from [Interface]
  vpn_private_key=$(awk '
    /^\[Interface\]/ {inf=1; next}
    /^\[/ && !/^\[Interface\]/ {inf=0}
    inf && /^PrivateKey/ {print $3; exit}
  ' "$WGCONF")

  # PublicKey from [Peer] section
  vpn_public_key=$(awk '
    /^\[Peer\]/ {inpeer=1; next}
    /^\[/ && !/^\[Peer\]/ {inpeer=0}
    inpeer && /^PublicKey/ {print $3; exit}
  ' "$WGCONF")

  # Address from [Interface]
  vpn_ip_address=$(awk '
    /^\[Interface\]/ {inf=1; next}
    /^\[/ && !/^\[Interface\]/ {inf=0}
    inf && /^Address/ {print $3; exit}
  ' "$WGCONF")

  # Default GW from "ip route add ... via X.X.X.X dev ..."
  ip_route_default_gw=$(awk '
    /ip route add/ {
      for (i = 1; i <= NF; i++) {
        if ($i == "via") {
          print $(i+1)
          exit
        }
      }
    }
  ' "$WGCONF")
}

parse_wg_conf

# Pin the VPN endpoint to the WAN only when wg0.conf names the WAN gateway.
# The live image's wg0.conf has no "ip route add ... via" line, and a route
# with an empty gateway becomes on-link (216.45.62.117 dev eth0 scope link):
# the endpoint is ARPed on the LAN, the handshake never leaves and wg0 stays
# down. Without it the WAN default (metric 0) already beats wg0's default
# (metric 5). Not falling back to the live host's gateway on purpose: that
# would bake the install site's router into a gateway that may move.
ROUTE_BLOCK=""
if [ -n "$ip_route_default_gw" ]; then
  ROUTE_BLOCK="
config route
        option interface 'wan'
        option target '${vpn_server_ip}'
        option netmask '255.255.255.255'
        option gateway '${ip_route_default_gw}'"
fi

# Create helper script INSIDE the chroot filesystem
INNER_SCRIPT="${ROOTFS}/tmp/wg_import.sh"
mkdir -p "${ROOTFS}/tmp"

cat > "${INNER_SCRIPT}" <<EOF
#!/bin/sh
set -e

NETCONF="/etc/config/network"
FWCONF="/etc/config/firewall"

echo "=== Setting up environment ==="
mkdir -p /var/lock
chmod 1777 /var/lock
echo "nameserver 8.8.8.8" > /etc/resolv.conf

opkg update
opkg install wireguard-tools luci-proto-wireguard

# Append to /etc/config/network
cat <<'EON' >> "\$NETCONF"

########## Added by WireGuard import script ##########
config interface 'wg0'
        option proto 'wireguard'
        option private_key '${vpn_private_key}'
        list addresses '${vpn_ip_address}'
        option metric '5'

config wireguard_wg0 'wgserver'
        option public_key '${vpn_public_key}'
        option endpoint_host '${vpn_server_ip}'
        option endpoint_port '${vpn_server_port}'
        option persistent_keepalive '25'
        option route_allowed_ips '1'
        list allowed_ips '0.0.0.0/0'
        option description 'netmaker.example.com'
${ROUTE_BLOCK}
########## End WireGuard import ##########
EON

# Append to /etc/config/firewall
cat <<'EOFW' >> "\$FWCONF"

########## Added by WireGuard import script ##########
config zone
        option name 'vpn'
        list network 'wg0'
        option input 'ACCEPT'
        option output 'ACCEPT'
        option forward 'ACCEPT'
        option masq '1'
########## End WireGuard import ##########
EOFW

rm /etc/resolv.conf

echo "WireGuard network + firewall config applied inside chroot."
EOF

chmod +x "${INNER_SCRIPT}"

echo "=== Applying WireGuard config inside OpenWrt chroot ==="
if chroot "${ROOTFS}" /bin/sh /tmp/wg_import.sh; then
  echo "WireGuard config successfully imported into /etc/config/network and /etc/config/firewall."
else
  echo "Failed: WireGuard import inside chroot."
  exit 1
fi
