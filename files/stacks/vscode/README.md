# VSCode Docker Stack

The **VSCode Docker Stack** sets up a containerized instance of Visual Studio Code Server, allowing you to access a full-featured VSCode environment through your web browser. This setup is ideal for remote development and provides access to your host's filesystem and devices.

## Key Features

- **Web-Based VSCode**: Access VSCode through a web browser from any location.
- **Host Integration**: Mounts the host's root directory and SSH configuration into the container for seamless access to files and SSH keys.
- **Persistent Configuration**: Stores user settings and extensions persistently.
- **Automated Deployment**: Uses Ansible and Docker Compose for consistent and repeatable deployments.

## Prerequisites

- **Docker** and **Docker Compose** installed on the host machine.
- **Ansible** installed for provisioning.
- SSH access to the host machine with appropriate permissions.
- Access to the Git repository containing the stack's configuration.

## Deployment Instructions

### Clone the Repository

Clone the VSCode stack repository to `/opt/stacks/vscode`:

```bash
git clone git@github.com:sabatligats/iotgw_vscode.git /opt/stacks/vscode
```

### Configure Environment Variables

Create an `.env` file in the `/opt/stacks/vscode` directory with any necessary environment variables. If an `.env.j2` template is provided, render it using your preferred method, such as Ansible or manually.

### Start the Docker Stack

Navigate to the `/opt/stacks/vscode` directory and deploy the stack using Docker Compose:

```bash
docker-compose up -d
```

## Docker Compose Configuration

The `docker-compose.yml` defines the VSCode service:

```yaml
services:
  code:
    image: lscr.io/linuxserver/code-server:latest
    container_name: vscode
    volumes:
      - /opt/stacks/vscode/config:/config
      - /opt/stacks/vscode/config/.ssh:/root/.ssh
      - /root/.bashrc:/config/.bashrc
      - /:/mnt
    restart: unless-stopped
    network_mode: host
    env_file:
      - .env
```

**Explanation:**

- **Image**: Uses the `lscr.io/linuxserver/code-server` image to run VSCode Server.
- **Volumes**:
  - `/opt/stacks/vscode/config:/config`: Stores VSCode configurations and extensions persistently.
  - `/opt/stacks/vscode/config/.ssh:/root/.ssh`: Shares SSH keys with the container.
  - `/root/.bashrc:/config/.bashrc`: Shares the bash configuration.
  - `/:/mnt`: Mounts the host's root directory for full filesystem access.
- **Network Mode**: Set to `host` to allow direct network access.
- **Environment Variables**: Loaded from the `.env` file.
- **Restart Policy**: Restarts automatically unless stopped manually.

## Accessing VSCode Server

After deployment, access VSCode Server through your web browser:

```plaintext
https://your-server-address:8443
```

**Note:** If you are using `network_mode: host`, ensure the service is listening on the correct port and that your firewall allows incoming connections.

## Security Considerations

- **Authentication**: Set up a password or use other authentication methods to secure access.
- **SSL/TLS**: Configure SSL certificates to secure the connection.
- **Host Access**: Mounting the host's root directory and SSH keys gives the container significant access. Ensure that only authorized users can access the VSCode Server.
- **Network Mode**: Using `network_mode: host` can pose security risks. Consider mapping specific ports instead.

## Automated Deployment with Ansible

Ansible playbooks automate the provisioning and deployment process:

1. **Check Existing Stack**: Determines if the VSCode Docker stack is running and stops it if necessary.
2. **Clone Repository**: Retrieves the latest configuration from the Git repository.
3. **Template Environment Variables**: Renders the `.env` file using Ansible templates.
4. **Start Docker Stack**: Deploys the VSCode service using Docker Compose.

## Conclusion

The **VSCode Docker Stack** provides a powerful, web-based development environment accessible from anywhere. By leveraging Docker and Ansible, you can deploy a consistent and secure setup tailored to your development needs.
