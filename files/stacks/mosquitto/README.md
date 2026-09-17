# Mosquitto MQTT Broker Docker Stack

The **Mosquitto MQTT Broker Stack** provides an MQTT service running inside a Docker container. This setup includes:

- A bi-directional bridge for syncing topics between the local broker and an external broker.
- User authentication.
- Configuration management through templated configuration files.

## Table of Contents

1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Prerequisites](#prerequisites)
4. [Configuration and Deployment](#configuration-and-deployment)
   - [Docker Compose Setup](#docker-compose-setup)
   - [Configuration Template](#configuration-template)
   - [User Management](#user-management)
5. [Provisioning with Ansible](#provisioning-with-ansible)
   - [Key Ansible Tasks](#key-ansible-tasks)
6. [Troubleshooting](#troubleshooting)
   - [Logging](#logging)
   - [Common Issues](#common-issues)
7. [Security Considerations](#security-considerations)
8. [Conclusion](#conclusion)

## Overview

This stack is designed to deploy and configure the **Mosquitto MQTT broker**, focusing on integrating with IoT gateways. It provides MQTT services on port 1883 and bridges messages with external brokers. The stack uses **Docker Compose** and **Ansible** for installation and management.

## Key Features

- **MQTT Service on Port 1883**: Sets up a non-encrypted MQTT service.
- **Bi-directional Topic Bridging**: Syncs specific topics between the local broker and an external broker.
- **Configuration Management**: Utilizes a Jinja2 templated configuration file (`mosquitto.conf.j2`) rendered during deployment.
- **User Authentication**: Manages MQTT users via a password file.
- **Ansible Automation**: Fully automates deployment and configuration management.

## Prerequisites

- **Docker** and **Docker Compose** installed on the host machine.
- **Ansible** installed for provisioning.
- Access to the external MQTT broker (e.g., EMQX), including credentials.
- Clone or access to the repository containing the stack's files.

## Configuration and Deployment

### Docker Compose Setup

Create a `docker-compose.yml` file with the following content:

```yaml
version: '3'
services:
  mqtt:
    container_name: mqtt
    image: eclipse-mosquitto:2.0
    network_mode: host
    volumes:
      - /opt/stacks/mosquitto/etc:/mosquitto/config
      - /opt/stacks/mosquitto/data:/mosquitto/data
    restart: unless-stopped
```

**Explanation:**

- **Network Mode**: Using `host` mode allows the container to use the host's network interfaces directly.
- **Volumes**:
  - `/opt/stacks/mosquitto/etc`: Stores Mosquitto configuration files.
  - `/opt/stacks/mosquitto/data`: Stores Mosquitto's persistence files.
- **Restart Policy**: The container restarts automatically unless it is stopped manually.

### Configuration Template

Create a Jinja2 template file named `mosquitto.conf.j2`:

```ini
# Mosquitto Bridge Configuration
connection emqx1
address {{ iiot_host }}
bridge_protocol_version mqttv50

# Remote Broker Credentials
remote_clientid mosquitto_{{ iotgw_hostname }}
remote_username {{ iiot_mqtt_user }}
remote_password {{ iiot_mqtt_password }}

# Topic Configuration
topic sabat/stantoni/oee/morrions/{{ iotgw_hostname | regex_search('(\d+)$')}}/# both 0
topic sabat/stantoni/produccio/morrions/{{ iotgw_hostname | regex_search('(\d+)$')}}/# both 0

# Listener Configuration
listener 1883 {{ local_ip_address }}

# Security Configuration
allow_anonymous false
password_file /mosquitto/config/mqtt_users

# Persistence Configuration
persistence true
autosave_interval 60
persistence_file /mosquitto/data/persistence.db
persistent_client_expiration 1d

# Logging Configuration
log_type information
log_timestamp true
log_dest stdout
```

**Explanation:**

- **Bridge Configuration**: Establishes a connection with an external broker (e.g., EMQX).
- **Remote Broker Credentials**: Uses variables to insert the external broker's credentials.
- **Topic Configuration**: Specifies which topics to bridge between brokers.
- **Listener Configuration**: Sets the local IP address and port for Mosquitto to listen on.
- **Security Configuration**: Disables anonymous access and specifies the password file.
- **Persistence Configuration**: Enables persistence for client data and session information.
- **Logging Configuration**: Configures logging preferences.

### User Management

User credentials for the MQTT service are stored in `/opt/stacks/mosquitto/etc/mqtt_users`. Users are added by generating hashed passwords using the `mosquitto_passwd` command.

**Example Command:**

```bash
mosquitto_passwd -b /opt/stacks/mosquitto/etc/mqtt_users <username> <password>
```

## Provisioning with Ansible

The entire stack is provisioned using Ansible to ensure consistent deployment and configuration management.

### Key Ansible Tasks

1. **Check Docker Stack Status**: Verify if the Mosquitto Docker stack is already running.
2. **Remove Existing Stack**: Stop and remove the existing stack if it's running.
3. **Clone Repository**: Clone the stack's repository to `/opt/stacks/mosquitto`.
4. **Create Directories**: Ensure that configuration and data directories exist.
5. **Render Configuration File**: Use Ansible to render the `mosquitto.conf.j2` template into `/opt/stacks/mosquitto/etc/mosquitto.conf`.
6. **Manage MQTT Users**: Add or update users in the `mqtt_users` file using `mosquitto_passwd`.
7. **Configure External Broker (EMQX)**: Use Ansible to interact with the EMQX API, ensuring users exist and are properly configured.
8. **Start Docker Stack**: Launch the Mosquitto Docker stack and verify it's running correctly.

**Note:** The Ansible playbook should be adjusted with the appropriate variables and paths specific to your environment.

## Troubleshooting

### Logging

To increase the verbosity of Mosquitto logs for troubleshooting, modify the logging configuration in `mosquitto.conf`:

```ini
log_type all
```

### Common Issues

- **Connection Issues**: Ensure the local IP address and port are correctly set in the `mosquitto.conf` file, and that your firewall allows traffic on port 1883.
- **Bridge Connectivity**: Verify that the external broker's address and credentials are correct.
- **User Authentication**: Check that usernames and passwords in `/opt/stacks/mosquitto/etc/mqtt_users` are correct and properly hashed.

## Security Considerations

- **Unencrypted MQTT Traffic**: The default setup runs an unencrypted MQTT server on port 1883. For production environments, it's strongly recommended to use SSL/TLS encryption.
- **Enabling SSL/TLS**: To enable secure communication, update the `mosquitto.conf.j2` template with SSL/TLS configurations and use port 8883.
- **Firewall Settings**: Ensure that only trusted networks and clients can access the MQTT broker.

**Example SSL/TLS Configuration:**

```ini
listener 8883 {{ local_ip_address }}
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key
```

## Conclusion

This **Mosquitto MQTT Broker Docker Stack** provides a robust solution for deploying an MQTT broker with bridging capabilities to an external broker. By leveraging Docker Compose and Ansible, you can automate the deployment and management process, ensuring consistency and ease of use.
