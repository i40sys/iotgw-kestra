# IoT Gateway Kestra Project

## Overview

This repository contains Kestra workflows and Ansible playbooks for automated provisioning and configuration of IoT Gateways based on OpenWRT.

## Project Structure

- `Flow.yaml` - Main Kestra provisioning workflow
- `*.yml` / `*.yaml` - Ansible playbooks
- `tasks/` - Ansible task modules
- `templates/` - Jinja2 templates for configuration files
- `files/` - Shell scripts and static files
- `keys/` - SSH keys for remote access
- `inventory/` - Ansible inventory files
- `.claude/skills/` - Claude Code skills for this project

## Key Technologies

- **Kestra** - Workflow orchestration (v1.2+)
- **Ansible** - Configuration management
- **OpenWRT** - Target OS for IoT Gateways
- **Docker** - Container runtime on gateways

## Important Notes

### Kestra Namespace Files
- Starting from Kestra 1.2, namespace files are indexed in the database
- Files must be synced via `sync-namespace-files` flow or uploaded via API
- Direct filesystem changes are NOT automatically reflected in Kestra UI

### Git Sync
- Repository: `i40sys/iotgw-kestra` (private)
- Sync flow: `sync-namespace-files`
- Triggers: Daily at 6 AM + webhook

### Credentials
- GitHub PAT stored in Kestra KV Store as `GITHUB_ACCESS_TOKEN`
- SSH keys in `keys/` directory (permissions 600)
- Credentials for skills stored in `.claude/skills/.env`

## Skills

- `/sync-kestra` - Commit, push to GitHub, and trigger Kestra sync

## Ansible Collections Required

- `community.docker`
- `gekmihesg.openwrt`
- `oriolrius.netmaker`

### Provisioning variable contract (iotgw-ng task-130)
- The deployment JSON (Kestra `json_data`, passed as `-e @vars.json`) is described by the iotgw-ng
  JSON Schema `iotgw-ui/packages/supabase-contract/src/deployment-config.schema.json`.
- `tasks/preflight.yaml` (pre_tasks, controller-only) enforces it: unknown tags, required vars per
  enabled stack (tag selected AND enable flag not false), value shapes. Keep both in sync.
- `templates/network.j2` / `templates/firewall.j2` rewrite `/etc/config/{network,firewall}` wholesale;
  wg0 is re-read from the gateway and asserted first — never feed WireGuard values from the UI.
- The LAN netmask is never a constant (task-131): `local_netmask` (dotted or prefix 8-30) or, when empty,
  the gateway's current `network.lan.netmask`; `tasks/system.yaml` checks the address, DHCP pool and
  `dhcp_hosts` fit it before touching the gateway.
