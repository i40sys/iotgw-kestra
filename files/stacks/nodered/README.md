# Node-RED Docker Stack

The **Node-RED Docker Stack** provides a containerized instance of Node-RED, an open-source flow-based programming tool for wiring together hardware devices, APIs, and online services. This setup is specifically tailored for IoT Gateway deployments, offering:

- Customized configurations using environment variables.
- Volume mappings for persistent data storage.
- Git-based project management for flow version control, with a dedicated repository per IoT Gateway.
- Automated provisioning and deployment using Ansible.

## Table of Contents

1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Prerequisites](#prerequisites)
4. [Configuration and Deployment](#configuration-and-deployment)
   - [Docker Compose Setup](#docker-compose-setup)
   - [Environment Variables](#environment-variables)
   - [Volume Mappings](#volume-mappings)
   - [Node-RED Project Configuration](#node-red-project-configuration)
   - [Healthcheck Configuration](#healthcheck-configuration)
5. [Provisioning with Ansible](#provisioning-with-ansible)
   - [Overview of Ansible Tasks](#overview-of-ansible-tasks)
6. [Troubleshooting](#troubleshooting)
   - [Common Issues](#common-issues)
7. [Security Considerations](#security-considerations)
8. [Conclusion](#conclusion)

## Overview

This stack is designed to deploy and configure **Node-RED** within a Docker container, focusing on integrating with IoT devices and services. Each IoT Gateway (`iot-gw`) has its own dedicated GitHub repository for Node-RED flows, enabling version control and easy management of flow configurations. The stack uses **Docker Compose** for container orchestration and **Ansible** for automated provisioning and management.

## Key Features

- **Customizable Node-RED Instance**: Deploys Node-RED with customizable settings using environment variables.
- **Persistent Data Storage**: Maps host directories to the container for data persistence.
- **Device Access**: Provides access to host devices via volume mapping.
- **Git-Based Project Management**: Sets up a default Node-RED project linked to a GitHub repository specific to each IoT Gateway.
- **Automated Provisioning**: Uses Ansible playbooks for consistent deployment and configuration management.
- **Health Checks**: Implements a health check mechanism to monitor the Node-RED instance.

## Prerequisites

- **Docker** and **Docker Compose** installed on the host machine.
- **Ansible** installed for provisioning.
- SSH access to the host machine with appropriate permissions.
- Access to the Git repository containing the Node-RED flows for your specific IoT Gateway.
- SSH keys configured for Git operations.
- Knowledge of your IoT Gateway's hostname or identifier.
- **.env File** configured with the necessary environment variables.

## Configuration and Deployment

### Docker Compose Setup

Create a `compose.yaml` file with the following content:

```yaml
services:
  nodered:
    image: nodered/node-red:${NODERED_VERSION}
    restart: unless-stopped
    container_name: node-red
    hostname: ${HOSTNAME}
    privileged: true
    env_file:
      - .env
    volumes:
      - /dev:/host/dev
      - /opt/stacks/nodered/data:/data
    network_mode: host
    healthcheck:
      test: ["CMD-SHELL", "node /healthcheck.js"]
      interval: 60s
      timeout: 3s
      retries: 3
      start_period: 30s
```

**Explanation:**

- **Image**: Uses the `nodered/node-red` image with a version specified by the `NODERED_VERSION` environment variable.
- **Restart Policy**: Restarts the container unless it is stopped manually.
- **Container Name and Hostname**: Sets the container name to `node-red` and hostname from the `HOSTNAME` environment variable.
- **Privileged Mode**: Runs the container in privileged mode to allow access to host devices.
- **Environment Variables**: Loads variables from the `.env` file.
- **Volume Mappings**:
  - `/dev:/host/dev`: Maps host devices to the container, enabling Node-RED to interact with hardware.
  - `/opt/stacks/nodered/data:/data`: Maps the data directory for persistent storage.
- **Network Mode**: Uses `host` networking for direct access to network interfaces.
- **Healthcheck**: Uses a custom health check script to monitor the Node-RED instance.

### Environment Variables

Create an `.env` file in the root directory of your project with the following variables:

```env
NODERED_VERSION='3.1'
TZ='Europe/Madrid'
HOSTNAME='iot-gw_maqX'
NODE_RED_USER='admin'
NODE_RED_PASSWORD='$2a$08$2fd5hMwc81S7MYjua93bh.6jp/3t/xWiRwMk3xT1kLPUFxET.s5MG'
```

**Explanation:**

- **NODERED_VERSION**: Specifies the Node-RED Docker image version (`3.1` in this case).
- **TZ**: Sets the timezone for the container (`Europe/Madrid`).
- **HOSTNAME**: Sets the hostname for the container, which should match your IoT Gateway's hostname (`iot-gw_maqX`).
- **NODE_RED_USER**: Defines the username for the Node-RED admin user (`admin`).
- **NODE_RED_PASSWORD**: Provides the hashed password for the Node-RED admin user. The password is hashed using bcrypt and should be enclosed in single quotes. (Generated using Ansible tasks)

### Volume Mappings

- **Host Devices**: The mapping `/dev:/host/dev` provides the container access to the host's devices, enabling Node-RED to interact with hardware devices connected to the IoT Gateway.
- **Persistent Data**: The mapping `/opt/stacks/nodered/data:/data` ensures that Node-RED's data persists between container restarts, preserving your flows and configurations. (**IMPORTANT** owner and group of the folder hast to be `1000`:`1000`)

### Node-RED Project Configuration

#### Default Project Setup

The Node-RED instance is configured to use a default project, which is connected to a GitHub repository specific to your IoT Gateway. This setup allows for:

- **Version Control**: Track changes to your Node-RED flows over time.
- **Collaboration**: Enable multiple developers to work on the same project.
- **Easy Deployment**: Quickly deploy updates and new features across multiple IoT Gateways.

#### Git Repository per IoT Gateway

- **Repository Naming Convention**: Each IoT Gateway has its own GitHub repository named following the pattern `flows.<iotgw_hostname>.git`.
  - **Example**: For an IoT Gateway with the hostname `iot-gw_maq3`, the corresponding repository would be `flows.iot-gw_maq3.git`.
- **Purpose**: This approach ensures that each IoT Gateway has its own set of flows, tailored to its specific requirements.

#### Cloning the Repository

During deployment, the Ansible playbook clones the appropriate GitHub repository into the Node-RED data directory:

- **Target Directory**: `/opt/stacks/nodered/data/projects/flows.<iotgw_hostname>`
- **SSH Keys**: The deployment uses SSH keys for secure access to the GitHub repository.
- **Branch Management**: You can manage different branches for development, testing, and production environments.

#### Updating Node-RED Configuration Files

To ensure Node-RED recognizes the cloned project as its default:

- **Configuration File**: `.config.projects.json` is updated with the new hostname and project details.
- **Template Rendering**: Ansible templates this file using variables, inserting the correct project name and settings.

### Healthcheck Configuration

The health check uses a script (`/healthcheck.js`) to monitor the Node-RED instance's health:

- **Purpose**: Ensures that the Node-RED service is running and responsive.
- **Configuration**: Specified in the `docker-compose.yml` file under the `healthcheck` section.
- **Customization**: You can modify the health check script to suit your monitoring requirements.

## Provisioning with Ansible

Ansible automates the provisioning and deployment of the Node-RED Docker stack, ensuring consistent and repeatable setups across all IoT Gateways.

### Overview of Ansible Tasks

1. **Check and Teardown Existing Stack**:

   - **Objective**: Determine if the Node-RED Docker stack is already running and remove it if necessary to ensure a clean deployment.
   - **Process**: Ansible checks the Docker Compose project status and tears down the stack if it's running.

2. **Clean Up Old Installations**:

   - **Objective**: Remove any previous installations to prevent conflicts.
   - **Process**: Deletes the `/opt/stacks/nodered` directory and its contents.

3. **Clone the Stack Repository**:

   - **Objective**: Retrieve the latest version of the Node-RED stack setup.
   - **Process**: Uses Git to clone the `iotgw_nodered` repository to `/opt/stacks/nodered`.

4. **Set Up the Data Directory**:

   - **Objective**: Create the data directory for Node-RED with the correct permissions.
   - **Process**: Ansible ensures the directory exists and sets ownership to `uid:1000` and `gid:1000` (typical for Node-RED containers).

5. **Generate Hashed Admin Password**:

   - **Objective**: Secure the Node-RED instance with an admin password.
   - **Process**: Runs a temporary Node-RED container to generate a bcrypt-hashed password from the provided plaintext password.
   - **Note**: The hashed password is then stored in the `.env` file under `NODE_RED_PASSWORD`.

6. **Template Environment Variables**:

   - **Objective**: Customize the `.env` file with the necessary environment variables.
   - **Process**: Renders the `.env` file from a template, inserting values like `NODERED_VERSION`, `TZ`, `HOSTNAME`, `NODE_RED_USER`, and `NODE_RED_PASSWORD`.

7. **Update Node-RED Configuration Files**:

   - **Objective**: Ensure Node-RED recognizes the correct default project.
   - **Process**: Templates the `.config.projects.json` file with the IoT Gateway's hostname and project details.

8. **Clone the Node-RED Flows Repository**:

   - **Objective**: Retrieve the specific flows for the IoT Gateway.
   - **Process**: Clones the GitHub repository `flows.<iotgw_hostname>.git` into the Node-RED projects directory.

9. **Set Ownership and Permissions**:

   - **Objective**: Prevent permission issues when Node-RED accesses files.
   - **Process**: Recursively sets the correct ownership (`uid:1000` and `gid:1000`) and permissions on all files and directories within `/opt/stacks/nodered/data`.

10. **Manage SSH Keys**:

    - **Objective**: Securely handle SSH keys used for Git operations within Node-RED.
    - **Process**: Sets strict permissions (`0600`) on the SSH key files and ensures they are owned by the correct user.

11. **Start the Docker Stack**:

    - **Objective**: Launch the Node-RED service.
    - **Process**: Uses Docker Compose to bring up the stack, applying all configurations.

12. **Verify Deployment**:

    - **Objective**: Confirm that the Node-RED instance is running correctly.
    - **Process**: Optionally, Ansible can display startup logs or perform additional checks to verify the deployment.

**Variables to Define in Ansible Playbook**:

- `nodered_password`: The plaintext admin password for Node-RED, which will be hashed and stored in the `.env` file.
- `iotgw_hostname`: The hostname or identifier of the IoT Gateway (e.g., `iot-gw_maq3`).
- `NODERED_VERSION`: The version of Node-RED to deploy (e.g., `'3.1'`).
- `TZ`: The timezone setting for the container (e.g., `'Europe/Madrid'`).
- `GIT_REPO_BASE_URL`: Base URL for the Git repositories (e.g., `git@github.com:sabatligats`).

**Note**: The Ansible playbook uses these variables to dynamically configure the deployment for each IoT Gateway.

## Troubleshooting

### Common Issues

- **Container Fails to Start**:

  - **Solution**: Check the Docker logs using `docker logs node-red` to identify any errors. Ensure that all environment variables are set correctly in the `.env` file and that the `docker-compose.yml` references them properly.

- **Permission Denied Errors**:

  - **Solution**: Verify that the ownership and permissions of the data directory and its contents are set to `uid:1000` and `gid:1000`. This ensures the Node-RED container has the necessary access.

- **SSH Key Problems**:

  - **Solution**: Ensure that the SSH keys have the correct permissions (`0600`) and are owned by the appropriate user. Verify that the keys are valid and have access to the GitHub repositories.

- **Health Check Failures**:

  - **Solution**: Confirm that the `healthcheck.js` script exists and is executable within the container. Check the script for errors.

- **Git Repository Not Found**:

  - **Solution**: Make sure the GitHub repository for your IoT Gateway exists. Verify that the `iotgw_hostname` variable matches the repository name pattern and that you have access permissions.

- **Incorrect Flows Loaded**:

  - **Solution**: Ensure that the correct repository is cloned and that the `.config.projects.json` file is correctly configured to point to the default project.

- **Environment Variable Issues**:

  - **Solution**: Double-check that all required environment variables are defined in the `.env` file and that they match those expected by your configuration.

## Security Considerations

- **Admin Password**:

  - Use a strong, complex password for the Node-RED admin user.
  - The password should be hashed using bcrypt before being stored in the `.env` file under `NODE_RED_PASSWORD`.
  - Avoid storing plaintext passwords in configuration files.

- **SSH Keys**:

  - Protect SSH keys by setting strict permissions (`0600`) and secure storage practices.
  - Limit access to the keys to authorized personnel only.

- **Privileged Mode**:

  - Running containers in privileged mode can pose security risks.
  - Only enable privileged mode if necessary for hardware access, and ensure the host system is secure.

- **Network Access**:

  - Limit exposure by configuring firewalls and network policies to restrict access to the Node-RED instance.
  - Consider implementing authentication and HTTPS for the Node-RED web interface.

- **Git Repository Access**:

  - Ensure GitHub repositories are private and access is controlled.
  - Use deploy keys or service accounts with limited permissions when possible.

- **Data Encryption**:

  - If sensitive data is processed, consider encrypting data at rest and in transit.
  - Use secure protocols and certificates for any external communications.

## Conclusion

This **Node-RED Docker Stack** provides a flexible and automated way to deploy Node-RED for IoT applications, tailored to individual IoT Gateways. By utilizing Git-based project management, you can maintain version control over your Node-RED flows, enabling collaborative development and streamlined updates. Leveraging Ansible for deployment ensures consistency across environments and simplifies management tasks.
