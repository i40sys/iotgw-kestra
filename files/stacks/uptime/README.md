# Uptime Kuma Docker Stack

Local monitoring of the gateway with Uptime Kuma and AutoKuma; Grafana Alloy
scrapes Kuma's Prometheus `/metrics`. Deployed by `tasks/uptime-kuma.yaml`
(provisioning tag `uptime-kuma`, deployment flag `uptime_kuma`).

## How it is bootstrapped

There is no prepared database. Every provisioning run recreates the stack:

1. `kuma` starts with an empty database.
2. `contrib/bootstrap-admin.js` (run inside the kuma container, which ships
   `socket.io-client`) creates the admin user from `autokuma_username` /
   `autokuma_password`, or only checks the login if the admin already exists.
3. `autokuma` starts and creates, from the labels in `compose.yml` and the
   snippets in `.env`, the local Docker socket and the monitors.

The same account is used by AutoKuma and by Alloy's basic auth on `/metrics`.
Don't create API keys in the UI: once one exists, Kuma's `/metrics` stops
accepting the user's login and the Alloy scrape fails.

## Monitors

Only the gateway's own services:

- `docker_containers`: every container labelled `kuma.__container`.
- `local_services`: the gateway's DNS resolving `<iotgw_hostname>.<local_domain>`,
  the MQTT broker port (when the `mqtt` flag is on) and Alloy's HTTP port (when
  the `obs` flag is on).

## Documentation

- [Uptime Kuma](https://github.com/louislam/uptime-kuma/wiki)
- [Autokuma](https://github.com/BigBoot/AutoKuma)
- [Autokuma Specific Properties](https://github.com/BigBoot/AutoKuma/blob/master/ENTITY_TYPES.md)
