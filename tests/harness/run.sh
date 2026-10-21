#!/usr/bin/env bash
# OpenWrt stack harness: run a provisioning task file the way production does,
# against a throw-away OpenWrt container — never a real gateway.
#
#   tests/harness/run.sh tests/harness/<test>.yaml [ansible-playbook args…]
#   tests/harness/run.sh all                       # every tests/harness/test_*.yaml
#
# Same as the Kestra `provisioning` runner (Flow.yaml): the pinned
# cytopia/ansible image, the same collections and the gekmihesg.openwrt role at
# the same commit, over SSH as root. The target is openwrt/rootfs booted with
# procd and prepared like the install flow prepares a gateway
# (files/enable_ansible.sh: OpenSSH + sftp-server + python3, dropbear off).
# The role swaps Ansible modules for BusyBox shell versions on such hosts; a
# plain Ansible-against-Alpine test passed while production failed ("Remote
# copy does not support recursive copy of directory"). This harness exists to
# catch that class of bug.
#
# Keep RUNNER_IMAGE / OPENWRT_ROLE_REF in sync with Flow.yaml and OPENWRT_IMAGE
# with the gateways' release (deployment-config schema `openwrt_version`).
set -euo pipefail

RUNNER_IMAGE="cytopia/ansible:2.18-tools@sha256:da5e5a6066afb11ef1541a7eff690ec28a1af9647c4f04533f71d3f7fcd1affe"
OPENWRT_ROLE_REF="01fda612aeedd0b6578aaede330c28a47fca3013"
OPENWRT_IMAGE="${OPENWRT_IMAGE:-openwrt/rootfs:x86-64-23.05.4}"

repo="$(cd "$(dirname "$0")/../.." && pwd)"
[ $# -ge 1 ] || { sed -n '2,6p' "$0"; exit 2; }

if [ "$1" = all ]; then
  shift
  rc=0
  for t in "$repo"/tests/harness/test_*.yaml; do
    echo "=== ${t#"$repo"/}"
    "$0" "${t#"$repo"/}" "$@" || rc=1
  done
  exit $rc
fi

test_file="$1"; shift
[ -f "$repo/$test_file" ] || { echo "no such test: $test_file" >&2; exit 2; }

id="iotgw-harness-$$"
work="$(mktemp -d)"
cleanup() {
  if [ -n "${HARNESS_KEEP:-}" ]; then
    echo "HARNESS_KEEP: target left running — docker exec -it $id-target ash; clean up with: docker rm -f $id-target && docker network rm $id" >&2
    rm -rf "$work"; return
  fi
  docker rm -f "$id-target" "$id-build" >/dev/null 2>&1 || true
  docker volume rm "$id-target-docker" "$id-build-docker" >/dev/null 2>&1 || true
  docker network rm "$id" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

# Fixed addresses: at boot netifd applies /etc/config/network, and the image
# default (192.168.1.1 on br-lan) leaves a container with no network at all.
net="10.250.$((RANDOM % 250))"
docker network create --subnet "$net.0/24" "$id" >/dev/null

# start_openwrt <name> <image> <ip>: boot OpenWrt (procd as PID 1) on $id/<ip>.
start_openwrt() {
  cat > "$work/network" <<EOF
config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config interface 'lan'
	option device 'eth0'
	option proto 'static'
	option ipaddr '$3'
	option netmask '255.255.255.0'
	option gateway '$net.1'
	list dns '1.1.1.1'
EOF
  # --privileged: procd needs it (mounts, cgroups). The container is the only
  # thing the playbook can touch.
  # /opt/docker on a volume: dockerd (data-root /opt/docker, overlay2 — the
  # system stack's daemon.json) cannot layer overlay2 on the container's own
  # overlay filesystem.
  docker create --name "$1" --hostname gw-harness --network "$id" --ip "$3" \
    -v "$1-docker:/opt/docker" --privileged "$2" /sbin/init >/dev/null
  docker cp "$work/network" "$1:/etc/config/network"
  docker start "$1" >/dev/null
}

# wait_banner <ip> <seconds>: until an SSH daemon answers on <ip>:22 (services
# restart when netifd brings lan up, so a running process is not enough).
wait_banner() {
  for _ in $(seq 1 "$2"); do
    if timeout 3 bash -c "exec 3<>/dev/tcp/$1/22; head -c 7 <&3" 2>/dev/null | grep -q SSH-2.0; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# The target image, built once and cached locally, keyed by the base image,
# files/enable_ansible.sh and this script.
target_image="iotgw-harness-target:$(printf '%s' "$OPENWRT_IMAGE" | cat - "$repo/files/enable_ansible.sh" "$0" | sha256sum | cut -c1-12)"
if ! docker image inspect "$target_image" >/dev/null 2>&1; then
  echo "building $target_image (once)…"
  start_openwrt "$id-build" "$OPENWRT_IMAGE" "$net.20"
  wait_banner "$net.20" 180 || { echo "build container has no network" >&2; exit 1; }
  # The chroot part of files/enable_ansible.sh, minus its chroot wrapper.
  docker exec "$id-build" sh -c '
    set -e
    rm -f /etc/rc.d/S[0-9][0-9]dropbear
    mkdir -p /var/lock && chmod 1777 /var/lock
    opkg update >/dev/null
    opkg install openssh-server openssh-keygen openssh-sftp-server python3 >/dev/null
    sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
    /etc/init.d/sshd enable
    mkdir -p /root/.ssh && chmod 700 /root/.ssh'
  docker stop "$id-build" >/dev/null
  docker commit "$id-build" "$target_image" >/dev/null
  docker rm "$id-build" >/dev/null
fi

target_ip="$net.10"
start_openwrt "$id-target" "$target_image" "$target_ip"
wait_banner "$target_ip" 180 || {
  echo "target never answered on $target_ip:22" >&2
  docker exec "$id-target" logread 2>/dev/null | tail -20 >&2
  exit 1
}
# Gateways get root's authorized_keys from the install flow (break-glass key).
ssh-keygen -q -t ed25519 -N '' -f "$work/id" -C harness
docker exec -i "$id-target" sh -c 'cat > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys' < "$work/id.pub"

cat > "$work/inventory.yml" <<EOF
all:
  children:
    openwrt:
      hosts:
        $id-target:
          ansible_host: $target_ip
          ansible_user: root
          ansible_ssh_private_key_file: /harness/id
          ansible_ssh_common_args: -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

extra=""
[ $# -eq 0 ] || extra="$(printf '%q ' "$@")"

docker run --rm --network "$id" \
  -v "$repo:/src:ro" -v "$work:/harness" \
  -e ANSIBLE_FORCE_COLOR=1 \
  "$RUNNER_IMAGE" bash -c "
    set -e
    mkdir -p /work && cp -a /src/. /work/ && cd /work && rm -rf .git
    mkdir -p /etc/ansible/collections /etc/ansible/roles
    # Same installs as Flow.yaml.
    ansible-galaxy collection install community.docker -p /etc/ansible/collections >/dev/null 2>&1
    ansible-galaxy collection install community.general -p /etc/ansible/collections >/dev/null 2>&1
    ansible-galaxy role install git+https://github.com/gekmihesg/ansible-openwrt.git,$OPENWRT_ROLE_REF,gekmihesg.openwrt -p /etc/ansible/roles >/dev/null 2>&1
    cat > ansible.cfg <<'CFG'
[defaults]
roles_path = /etc/ansible/roles:~/.ansible/roles:/usr/share/ansible/roles
collections_paths = /etc/ansible/collections:~/.ansible/collections:/usr/share/ansible/collections
CFG
    # From the repo root, like i11_provisioning_iotgw.yaml: files/ lookups and
    # task paths resolve exactly as in production.
    cp '$test_file' ./harness-test.yaml
    ansible-playbook -i /harness/inventory.yml harness-test.yaml ${extra}
  "
