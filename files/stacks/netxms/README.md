# NetXMS Agent Documentation

NetXMS Agent is a monitoring agent that provides comprehensive system monitoring capabilities. It collects system metrics, performs checks, and communicates with NetXMS server for centralized monitoring and management.

## Project References

- **Original NetXMS Project**: [NetXMS Official Website](https://www.netxms.org/) - Enterprise-grade open source network management and monitoring system
- **Docker Port**: [docker-netxms](https://github.com/oriolrius/docker-netxms) - Docker implementation of NetXMS components by Oriol Rius
- **Docker Image**: `ghcr.io/oriolrius/docker-netxms-agent:v1.0.0` - Pre-built container image available on GitHub Container Registry

## Overview

This document provides an overview of the automated installation and setup process for NetXMS Agent using Ansible. The steps described below are performed automatically by an Ansible playbook. You do not need to execute these steps manually. The purpose of this documentation is to outline what the automated process does for transparency and troubleshooting.

## Automated Installation and Deployment

The automated installation and deployment process involves several steps to ensure NetXMS Agent is properly set up and running. Below is a detailed list of the actions performed by the Ansible playbook:

### 1. Check for Existing Docker Stack

- **Purpose:** To determine if a NetXMS Agent Docker stack is already running.
- **Action:** The playbook checks the system for an existing NetXMS Agent stack to avoid conflicts with previous installations.

### 2. Teardown Existing Stack (If Necessary)

- **Purpose:** To remove any existing NetXMS Agent stack that might interfere with the new installation.
- **Action:** If a running stack is detected, the playbook stops and removes it, ensuring a clean environment for the new deployment.

### 3. Remove Existing Installation Directory

- **Purpose:** To delete old NetXMS Agent files and configurations.
- **Action:** The `/opt/stacks/netxms-agent` directory is removed if it exists, clearing out residual files from previous installations.

### 4. Clone NetXMS Agent Repository

- **Purpose:** To obtain the latest version of NetXMS Agent configuration.
- **Action:** The NetXMS Agent repository is cloned into the `/opt/stacks/netxms-agent` directory from GitHub.

  > **Note:** Ensure that SSH keys are correctly configured on the system if cloning via SSH.

### 5. Add Git Pre-Push Hook

- **Purpose:** To automate tasks like code checks or tests before pushing changes to the repository.
- **Action:** A Git pre-push hook script is added to the cloned repository in `.git/hooks/pre-push`.

### 6. Start Docker Stack

- **Purpose:** To deploy NetXMS Agent using Docker Compose.
- **Action:** The Docker Compose stack is started, pulling necessary Docker images and running containers as defined in the `compose.yaml` file.

### 7. Display Startup Logs

- **Purpose:** To verify that the NetXMS Agent service has started correctly.
- **Action:** The playbook captures and displays the startup logs from the Docker stack, aiding in troubleshooting if there are issues.

## Configuration

The NetXMS Agent is configured through environment variables defined in the `compose.yaml` file:

### Environment Variables

- **SERVER**: The IP address of the NetXMS server (default: 172.20.0.2)
- **MASTER_SERVERS**: The network range of allowed NetXMS master servers (default: 172.20.0.0/16)
- **DEBUG_LEVEL**: Debug logging level (default: 1)
- **PROXY_AGENT**: Enable agent proxy functionality (default: Yes)
- **PROXY_SNMP**: Enable SNMP proxy functionality (default: Yes)

### Network Configuration

The agent runs in host network mode with privileged access to monitor all system resources effectively. This includes:

- Full access to network interfaces and routing
- Process monitoring capabilities
- System resource monitoring
- Hardware sensor access

## Data Directory

The agent stores its configuration and runtime data in the `./agent` directory, which is mounted to `/var/lib/netxms` inside the container. This ensures that agent configurations and collected data remain persistent across container restarts.

## Monitoring Integration

The NetXMS Agent is integrated with Uptime Kuma for container health monitoring through Docker labels. The health check ensures the agent process is running correctly.

## Troubleshooting

- **Service Fails to Start**

  If the NetXMS Agent service fails to start, check the Docker Compose logs for any error messages:

  ```bash
  docker-compose logs netxms-agent
  ```

- **Connection Issues**

  Ensure that the NetXMS server IP address is correct and reachable from the host:

  ```bash
  ping ${NETXMS_SERVER_IP}
  ```

- **Agent Not Appearing in NetXMS Console**

  1. Check that the MASTER_SERVERS range includes your NetXMS server
  2. Verify firewall rules allow communication on NetXMS ports
  3. Check agent logs for authentication or connection errors

- **Docker Stack Issues**

  If you encounter issues with the Docker stack, you can manually stop and remove it:

  ```bash
  cd /opt/stacks/netxms-agent
  docker-compose down
  ```

## Security Considerations

The NetXMS Agent runs with elevated privileges to access system resources. Ensure that:

- The NetXMS server is properly secured
- Network access is restricted to authorized NetXMS servers only
- Regular security updates are applied to both the host system and container images

## Maintenance

- **Updating the Agent**

  To update the NetXMS Agent to a newer version, update the image tag in `compose.yaml` and restart the stack:

  ```bash
  docker-compose pull
  docker-compose up -d
  ```

- **Log Rotation**

  Docker logs are automatically rotated with a maximum size of 10MB and keeping only 3 files, as configured in the logging section.
  