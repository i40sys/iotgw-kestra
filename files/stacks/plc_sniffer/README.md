# plc_sniffer Documentation

plc_sniffer is a Docker Compose stack designed to capture and forward PLC (Programmable Logic Controller) network traffic. It is ideal for industrial automation scenarios where monitoring and analysis of PLC communications are required.

## Overview

This document outlines the automated installation and setup process for plc_sniffer using Ansible. The steps described below are performed automatically by an Ansible playbook. You do not need to execute these steps manually; this documentation is for transparency and troubleshooting.

## Automated Installation and Deployment


The Ansible playbook performs the following steps:

This stack is based on the upstream project [oriolrius/plc_sniffer](https://github.com/oriolrius/plc_sniffer). For full documentation, features, and configuration options, refer to the upstream repository and its docs.

### 1. Check for Existing PLC Sniffer Stack

- **Purpose:** Ensure no conflicting plc_sniffer stack is running.
- **Action:** The playbook checks for an existing stack and stops/removes it if found.

### 2. Remove Existing Installation Directory

- **Purpose:** Clean up old files and configurations.
- **Action:** The `/opt/stacks/plc_sniffer` directory is removed if it exists.

### 3. Clone plc_sniffer Repository

- **Purpose:** Obtain the latest version of plc_sniffer.
- **Action:** The repository is cloned into `/opt/stacks/plc`.

### 4. Add Git Pre-Push Hook

- **Purpose:** Automate code checks or tests before pushing changes.
- **Action:** A pre-push hook is added to `.git/hooks/pre-push`.

### 5. Start Docker Stack

- **Purpose:** Deploy plc_sniffer using Docker Compose.
- **Action:** The stack is started, pulling the `ghcr.io/oriolrius/plc_sniffer:latest` image and running the container.

### 6. Display Startup Logs

- **Purpose:** Verify successful startup.
- **Action:** Startup logs are displayed for troubleshooting.

## Configuration


- **compose.yaml:** Defines the Docker Compose stack, including environment variables for network interface, filter, destination IP/port, rate limit, packet size, log level, and health check port.
- **env.j2:** Jinja2 template for environment variables, allowing dynamic configuration via Ansible.

### Main Features

- **Packet Capture:** Efficient UDP packet capture using BPF filters
- **Security:** Input validation, rate limiting, and packet size limits
- **Monitoring:** Built-in health checks and Prometheus metrics
- **Containerized:** Secure Docker deployment with non-root execution
- **Configurable:** Environment-based configuration with validation
- **Production-Ready:** Comprehensive testing, CI/CD, and documentation

### Key Environment Variables

| Variable           | Description                          | Default        |
|--------------------|--------------------------------------|---------------|
| INTERFACE          | Network interface to capture packets | eth0          |
| FILTER             | BPF filter expression                | udp           |
| DESTINATION_IP     | IP to forward packets to             | 127.0.0.1     |
| DESTINATION_PORT   | Port to forward packets to           | 8514          |
| LOG_LEVEL          | Logging verbosity                    | INFO          |
| MAX_PACKET_SIZE    | Maximum packet size in bytes         | 65535         |
| RATE_LIMIT         | Max packets per second (0=unlimited) | 0             |
| HEALTH_CHECK_PORT  | Port for health checks (0=disabled)  | 8080          |

See [docs/configuration.md](https://github.com/oriolrius/plc_sniffer/blob/main/docs/configuration.md) for detailed configuration options.

### Monitoring & Metrics

- **Health Checks:**
  - Liveness: `curl http://localhost:8080/health`
  - Readiness: `curl http://localhost:8080/ready`
- **Prometheus Metrics:**
  - `plc_sniffer_packets_processed_total`: Total packets processed
  - `plc_sniffer_packets_forwarded_total`: Successfully forwarded packets
  - `plc_sniffer_packets_dropped_total`: Dropped packets
  - `plc_sniffer_current_packet_rate`: Current packets per second
  - And more...

For more details, see [docs/api.md](https://github.com/oriolrius/plc_sniffer/blob/main/docs/api.md) and [docs/troubleshooting.md](https://github.com/oriolrius/plc_sniffer/blob/main/docs/troubleshooting.md).

## Intended Audience

plc_sniffer is designed for users in industrial automation and network monitoring. It provides a simple way to capture and forward PLC traffic without complex setup.

## Troubleshooting

- **Service Fails to Start:** Check Docker Compose logs for errors:
  ```bash
  docker-compose logs
  ```
- **Network Issues:** Ensure the correct network interface and filter are set in environment variables.
- **Container Permissions:** The stack runs with `privileged: true` for packet capture. Adjust as needed for your environment.

## Future Improvements

- Enhanced configuration options
- Improved logging and health checks
- Support for additional PLC protocols
