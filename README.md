# IoT Gateway Kestra

Kestra workflows and Ansible playbooks for automated provisioning and configuration of IoT Gateways based on OpenWRT.

## Overview

This repository contains the automation infrastructure for deploying and managing IoT Gateway devices. It integrates [Kestra](https://kestra.io/) workflow orchestration with Ansible playbooks to provide a complete provisioning pipeline.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│     Kestra      │────▶│     Ansible      │────▶│   IoT Gateway   │
│   (Workflows)   │     │   (Playbooks)    │     │   (OpenWRT)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Directory Structure

```
.
├── Flow.yaml                    # Main Kestra provisioning workflow
├── i11_provisioning_iotgw.yaml  # Software and configuration provisioning
├── d01_install_owrt.yml         # OpenWRT installation playbook
├── connectivity_check.yml       # Ansible connectivity test
├── device_update.yml            # Netmaker device management
├── device_delete.yml            # Device deletion workflow
├── network_*.yml                # Network management playbooks
├── files/                       # Shell scripts and configuration files
│   ├── chroot.sh               # Chroot setup script
│   ├── copy_files.sh           # File copying utilities
│   ├── create_partitions.sh    # Disk partitioning
│   ├── grub_*.sh               # GRUB bootloader scripts
│   ├── setup_vpn.sh            # VPN configuration
│   └── credentials/            # SSH keys
├── inventory/                   # Ansible inventory files
├── keys/                        # SSH keys for remote access
├── playbooks/                   # Additional Ansible playbooks
├── scripts/                     # Utility scripts
├── tasks/                       # Ansible task modules
│   ├── system.yaml             # System configuration
│   ├── firewall.yaml           # Firewall rules
│   ├── nodered.yaml            # Node-RED deployment
│   ├── mosquitto.yaml          # MQTT broker
│   ├── telegraf.yaml           # Metrics collection
│   ├── observability.yaml      # Monitoring stack
│   └── ...                     # Additional services
└── templates/                   # Jinja2 templates
    ├── firewall.j2             # Firewall configuration
    ├── network.j2              # Network settings
    ├── zerotier.j2             # ZeroTier VPN
    └── ...                     # Additional templates
```

## Kestra Workflows

### Provisioning Flow (`Flow.yaml`)

The main workflow that orchestrates the complete IoT Gateway provisioning:

1. Receives JSON input with target configuration
2. Generates dynamic Ansible inventory
3. Executes OpenWRT installation playbook

**Input Parameters:**
```json
{
  "target_disk": "/dev/nvme0n1",
  "openwrt_version": "23.05.4",
  "target_ip": "10.0.0.1"
}
```

## Ansible Tasks

| Task | Description |
|------|-------------|
| `system.yaml` | System hostname, timezone, DNS configuration |
| `firewall.yaml` | OpenWRT firewall zones and rules |
| `syslog.yaml` | Remote syslog configuration |
| `shell.yaml` | Shell environment setup |
| `credentials.yaml` | SSH keys and authentication |
| `dockge.yaml` | Docker stack manager |
| `vscode.yaml` | VS Code Server deployment |
| `nodered.yaml` | Node-RED flow editor |
| `mosquitto.yaml` | MQTT broker |
| `telegraf.yaml` | Metrics collection agent |
| `observability.yaml` | Monitoring and logging stack |
| `glpi-agent.yaml` | GLPI inventory agent |
| `duplicati.yaml` | Backup solution |
| `netxms-agent.yaml` | Network monitoring agent |
| `lldpd.yaml` | Link Layer Discovery Protocol |
| `uptime-kuma.yaml` | Uptime monitoring |
| `plc_sniffer.yaml` | PLC communication sniffer |

## Deployed Services

The provisioning deploys the following Docker-based services:

- **Node-RED** - Flow-based programming for IoT
- **Mosquitto** - MQTT message broker
- **Telegraf** - Metrics collection and reporting
- **Dockge** - Docker Compose stack manager
- **Uptime Kuma** - Self-hosted monitoring tool
- **Duplicati** - Backup solution
- **VS Code Server** - Remote development environment

## Requirements

### Kestra
- Kestra instance with Ansible plugin
- Container image: `cytopia/ansible:latest-tools`

### Ansible Collections
- `community.docker`
- `gekmihesg.openwrt`
- `oriolrius.netmaker`

### Target System
- x86_64 hardware compatible with OpenWRT
- Network connectivity (direct or via VPN)
- SSH access enabled

## Usage

### Via Kestra

Trigger the provisioning workflow with:

```yaml
namespace: iotgw-ng
flow: provisioning
inputs:
  json_data:
    target_disk: "/dev/sda"
    openwrt_version: "23.05.4"
    target_ip: "192.168.1.100"
```

### Via Ansible CLI

```bash
# Test connectivity
ansible-playbook -i inventory/iotgw.yaml connectivity_check.yml

# Install OpenWRT
ansible-playbook -i inventory/iotgw.yaml d01_install_owrt.yml \
  -e "target_disk=/dev/sda openwrt_version=23.05.4"

# Provision software
ansible-playbook -i inventory/iotgw.yaml i11_provisioning_iotgw.yaml

# Run specific tasks
ansible-playbook -i inventory/iotgw.yaml i11_provisioning_iotgw.yaml --tags nodered
```

## Network Integration

The IoT Gateways integrate with:

- **Netmaker** - Mesh VPN for secure connectivity
- **ZeroTier** - Alternative VPN solution
- **WireGuard** - VPN tunnels

## Git Sync Configuration

This repository is automatically synchronized with Kestra namespace files using the `sync-namespace-files` flow.

### Sync Flow

The sync is configured in `sync-namespace-files.yaml`:

```yaml
id: sync-namespace-files
namespace: iotgw-ng

tasks:
  - id: sync_from_git
    type: io.kestra.plugin.git.SyncNamespaceFiles
    username: i40sys
    password: "{{ kv('GITHUB_ACCESS_TOKEN') }}"
    url: https://github.com/i40sys/iotgw-kestra
    branch: main
    namespace: iotgw-ng
    gitDirectory: .
    delete: true
    dryRun: false
```

### Triggers

| Trigger | Type | Schedule/Key |
|---------|------|--------------|
| `daily_sync` | Schedule | `0 6 * * *` (daily at 6 AM) |
| `github_webhook` | Webhook | `REDACTED_WEBHOOK_KEY` |

### Setup Requirements

1. **KV Store**: Create a KV pair named `GITHUB_ACCESS_TOKEN` with a GitHub Personal Access Token that has `repo` scope.

2. **GitHub Webhook** (optional): Configure a webhook in GitHub repository settings:
   - Payload URL: `http://<kestra-host>:8080/api/v1/executions/webhook/iotgw-ng/sync-namespace-files/REDACTED_WEBHOOK_KEY`
   - Content type: `application/json`
   - Events: `push`

### Notes

- Starting from Kestra 1.2, namespace files are indexed in the database rather than read directly from the filesystem
- The `delete: true` option removes files from Kestra that no longer exist in the repository
- Manual sync can be triggered from the Kestra UI or via API

## Related Repositories

- [i40sys/iotgw](https://github.com/i40sys/iotgw) - IoT Gateway based on OpenWRT
- [i40sys/iot_stack](https://github.com/i40sys/iot_stack) - Ansible Collection for IoT Gateway

## License

Private repository - All rights reserved.
