# GLPI Agent Docker Stack

This documentation describes the purpose, configuration, and usage of the GLPI Agent Docker stack, along with how the Docker image is built and the features provided by the GLPI Agent. The stack is designed for private network usage due to the lack of authentication (AuthN) and authorization (AuthZ) mechanisms.

## 1. General Purpose of the Stack

### Overview

The **GLPI Agent Docker Stack** allows you to run the GLPI Agent as a Docker container, which collects hardware and software inventory, as well as monitoring data, and sends it to a GLPI server. This stack is deployed and configured via **Docker Compose** and **Ansible**, which automates the installation and provisioning steps.

### Installation and Provisioning via Ansible

The stack is deployed using Ansible, and the main tasks performed include:

1. **Check if Docker Stack is Running**: Ansible checks if a GLPI Agent Docker stack is already running. If so, it stops the service to prevent conflicts.
2. **Remove Existing Installation**: Ansible removes any existing GLPI Agent directories (`/opt/stacks/glpi-agent`) to ensure a clean installation.
3. **Clone the Repository**: The repository containing the Docker Compose configuration and related files is cloned into the target directory.
4. **Add Git Hooks**: A Git pre-push hook is added to automate tasks like code validation.
5. **Template the Environment Variables**: Ansible templates an `env.j2` file to create the `.env` file with the necessary environment variables for the GLPI Agent.
6. **Login to GitHub Container Registry**: The playbook logs into `ghcr.io` to pull the required Docker images.
7. **Start Docker Stack**: The Docker Compose stack is started, and the service is launched.
8. **Display Startup Logs**: Ansible displays the logs of the running stack to verify successful deployment.

### Configuration

- **Volumes**:
  - `/etc/glpi-agent`: Maps the agent’s configuration directory.
  - `/var/lib/glpi-agent`: Maps the data directory for the agent, storing inventory data and logs.
- **Network**: The container runs in `host` network mode for direct access to the network stack.
- **Environment Variables**:
  - `GLPI_SERVER`: The URL of the GLPI server.
  - `GLPI_USER` and `GLPI_PASSWORD`: Optional credentials for the GLPI server.
  - `EXTRA_ARGS`: Additional command-line arguments for the agent (e.g., `--httpd-trust`).

> **Note**: The stack should only be used in **private networks** because it does not support modern security mechanisms.

### Running the Stack

Once installed, the GLPI Agent stack can be started using Docker Compose, either manually or as part of the automated Ansible process.

## 2. How the Docker Image is Built

### Building the Docker Image

The Docker image for the GLPI Agent is created using the following process:

1. **Base Image**: The Dockerfile defines a base image that includes the necessary system dependencies for the GLPI Agent.
2. **Install GLPI Agent**: The agent is downloaded and installed into the Docker image.
3. **Include Configuration and Scripts**: The `entrypoint.sh` script is added to handle initialization of the agent when the container starts.

### Steps to Build and Push the Image

To build and push the Docker image for the GLPI Agent:

```bash
docker login ghcr.io
docker compose build
docker compose push
```

- **Login**: You need to authenticate with GitHub Container Registry (`ghcr.io`) to pull and push images.
- **Build**: This command builds the Docker image using the instructions in the Dockerfile.
- **Push**: Push the newly built image to `ghcr.io/sabatligats/iotgw_glpi-agent:latest` so it can be used for deployments.

### Docker Compose Configuration (`docker-compose.yml`)

The Docker Compose file defines the GLPI Agent service with the following key components:

```yaml
services:
  glpi-agent:
    image: ghcr.io/sabatligats/iotgw_glpi-agent:latest
    container_name: glpi-agent
    build:
      context: .
      dockerfile: Dockerfile
    env_file:
      - .env
    volumes:
      - ./etc:/etc/glpi-agent
      - ./data:/var/lib/glpi-agent
      - /dev:/dev
      - /proc:/proc
      - /sys:/sys
    network_mode: host
    privileged: true
    restart: unless-stopped
    dns:
      - 192.168.1.16
      - 192.168.210.61
```

- **Volumes**: Mounts for configuration and data directories.
- **Privileged Mode**: The container runs in privileged mode to enable access to system hardware for monitoring.
- **Network**: Uses `host` network mode.
- **Restart Policy**: The service automatically restarts unless stopped manually.

## 3. Understanding GLPI Agent Features

### Key Features

The GLPI Agent provides several powerful features:

- **Hardware and Software Inventory**: The agent automatically collects detailed information about the hardware and software on the machine where it runs, including CPU, memory, storage, network interfaces, and installed software.
- **System Monitoring**: It monitors key system metrics, such as CPU usage, memory consumption, and disk usage, and sends this information to the GLPI server for further analysis.
- **Remote Inventory**: The agent can also collect inventory from remote machines using SSH or other protocols via `glpi-remote`.

### Environment Variables and Extra Arguments

The behavior of the GLPI Agent can be customized using environment variables:
- **`GLPI_SERVER`**: The URL of the GLPI server where the agent will send collected data.
- **`GLPI_USER`** and **`GLPI_PASSWORD`**: (Optional) Credentials for authenticating with the GLPI server.
- **`EXTRA_ARGS`**: Additional options passed to the GLPI Agent command (e.g., `--httpd-trust 10.0.0.0/8`).

### Running the Agent in Docker

When the container starts, the `entrypoint.sh` script is executed. It performs the following:

1. Verifies that `GLPI_SERVER` is set.
2. Launches the GLPI Agent with any additional configuration provided via environment variables.

### Example Command to Add Remote Inventory

To add a remote machine for inventory collection:

```bash
docker exec -it $(docker ps | grep glpi-agent | awk '{print $1}') glpi-remote add ssh://user:password@ip --no-check
```

This command runs `glpi-remote` inside the container to connect to a remote machine using SSH.

## Security Considerations

- **Private Network Only**: This stack should only be used in **private networks** because it currently does not support any modern authentication or authorization mechanisms.
- **Network Exposure**: Avoid exposing the GLPI Agent to public networks as it lacks robust security controls.

