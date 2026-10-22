# OpenWrt stack harness

Runs provisioning task files the way the Kestra `provisioning` flow does, against
a throw-away **OpenWrt 23.05.4 container**, never a real gateway:

- the pinned runner image (`cytopia/ansible:2.18-tools@sha256:…`), the same
  collections and the `gekmihesg.openwrt` role at the same commit as `Flow.yaml`;
- SSH as root to an `openwrt/rootfs` booted with procd, prepared like the install
  flow prepares a gateway (`files/enable_ansible.sh`: OpenSSH + sftp-server +
  python3, dropbear off).

On OpenWrt hosts the role replaces Ansible modules (`copy`, `file`, `stat`, …)
with BusyBox shell versions. A test with plain Ansible against Alpine passed
while production failed (`Remote copy does not support recursive copy of
directory`); this harness reproduces that, and is what found the next two bugs
(alloy's libgcc_s crash loop, mosquitto's missing `groupadd`).

```bash
tests/harness/run.sh tests/harness/test_observability.yaml   # one stack
tests/harness/run.sh all                                     # every test_*.yaml
HARNESS_KEEP=1 tests/harness/run.sh tests/harness/test_nodered.yaml   # keep the target to debug
```

Needs Docker (privileged containers) and internet (opkg, image pulls). The target
image is built once and cached (`iotgw-harness-target:<hash>`). CI:
`.github/workflows/harness.yml` runs every test on each push to `main`.

| Test | Stack | Checks (after provisioning **twice**) |
|---|---|---|
| `test_observability.yaml` | Alloy | glibc files, ELF loader path, binary runs, configs rendered, enabled at boot, `:12345/-/ready` |
| `test_mosquitto.yaml` | mosquitto (no bridge) | no bridge block, container up, local user pub/sub, anonymous refused |
| `test_nodered.yaml` | Node-RED (no flows repo) | 3.1 → current upgrade: editor up, API 401 without login, login works, runtime version, projects off, the 3.1 flow loaded after the upgrade |
| `test_telegraf.yaml` | telegraf | `.env`, container stays up (config served by the target) |
| `test_duplicati.yaml` | duplicati | both backup jobs valid JSON, web UI on `:8200` |
| `test_netxms.yaml` | NetXMS agent | `nxagentd` running |
| `test_lldpd.yaml` | lldpd | daemon running |
| `test_containers_exporter.yaml` | containers_exporter (pinned image) | runs the pinned digest, stays up, `/metrics` on `127.0.0.1:containers_exporter_port`; a 3rd run recovers a stack dir left without `.env` |
| `test_vscode.yaml` | VSCode / code-server (pinned image) | runs the pinned digest, `:8443/healthz` answers, `/` redirects to the login |
| `test_dockge.yaml` | Dockge | UI on `:5001` |
| `test_uptime_kuma.yaml` | Uptime Kuma + AutoKuma | UI on `:3003`, the bootstrapped admin reads `/metrics` |
| `test_firewall.yaml` | firewall (`tasks/firewall.yaml`, three passes: two `management_cidrs`, `[]`, `null`) | `ManagementIPs` = loopback + `management_cidrs` only, `fw4 check` (nft check mode, never loaded) passes, the nft set carries the CIDRs |

The first pass is a fresh install (no stack directory: the teardown is skipped,
no ignored `fatal:`), the second a re-provisioning (the existing stack is torn
down first). Expect `ignored=0` in the recap.

Docker stacks first run `prep_docker.yaml`: the packages they use from
`files/lists/packages.lst` and the real `tasks/system_docker.yaml`, twice. It
checks that dockerd restarts and runs with the system stack's `daemon.json`
when the config changes, and that it is left alone when the config is unchanged.

Not covered: `system` (rewrites `/etc/config/network`, needs a live wg0),
`ssh_ca` (needs the backend + pki-manager), the EMQX bridge and the Node-RED
flows repo (need external services).
