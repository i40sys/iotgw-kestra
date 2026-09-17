# Uptime Kuma Docker Stack

Active local monitoring with Autokuma and Uptime Kuma. In the contrib/ folder is `kuma-cli` to interact with the Kuma API.

Very easy to use and simple to for monitoring local services and exposing prometheus metrics.

## Remarkable notes

`data_clean.tar.gz` is a clean SQL lite DB with some stuff preconfigured.
  - dark theme enabled
  - u/p admin/Fence3-Dusk9
  - API Key: `uk1_<REDACTED-set-via-env>`
  - Docker Host: `unix_socket`

## Use env.j2 to generate the .env file

Ready for being used by Ansible to deploy the stack.
The only required variable is `num_maquina` which is used to generate the local IP address. By `default` it will be `0`.

## Uptime Kuma API Key

```
API_KEY="uk1_<REDACTED-set-via-env>"
```

## Grafana Alloy connectoin to the /metrics endpoint using basic auth (API_KEY)

```yaml

```

## Documentation

- [Uptime Kuma](https://github.com/louislam/uptime-kuma/wiki)
- [Autokuma](https://github.com/BigBoot/AutoKuma)
- [Autokuma Specific Properties](https://github.com/BigBoot/AutoKuma/blob/master/ENTITY_TYPES.md)
