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
