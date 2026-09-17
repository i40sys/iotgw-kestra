# dockge Documentation

dockge is a web interface for managing Docker Compose stacks. It simplifies the deployment and management of Docker Compose applications, making it ideal for users who are not advanced system administrators.

## Overview

This document provides an overview of the automated installation and setup process for dockge using Ansible. The steps described below are performed automatically by an Ansible playbook. You do not need to execute these steps manually. The purpose of this documentation is to outline what the automated process does for transparency and troubleshooting.

## Automated Installation and Deployment

The automated installation and deployment process involves several steps to ensure dockge is properly set up and running. Below is a detailed list of the actions performed by the Ansible playbook:

### 1. Check for Existing Docker Stack

- **Purpose:** To determine if a dockge Docker stack is already running.
- **Action:** The playbook checks the system for an existing dockge stack to avoid conflicts with previous installations.

### 2. Teardown Existing Stack (If Necessary)

- **Purpose:** To remove any existing dockge stack that might interfere with the new installation.
- **Action:** If a running stack is detected, the playbook stops and removes it, ensuring a clean environment for the new deployment.

### 3. Remove Existing Installation Directory

- **Purpose:** To delete old dockge files and configurations.
- **Action:** The `/opt/stacks/dockge` directory is removed if it exists, clearing out residual files from previous installations.

### 4. Clone dockge Repository

- **Purpose:** To obtain the latest version of dockge.
- **Action:** The dockge repository is cloned into the `/opt/stacks/dockge` directory from GitHub.

  > **Note:** Ensure that SSH keys are correctly configured on the system if cloning via SSH.

### 5. Add Git Pre-Push Hook

- **Purpose:** To automate tasks like code checks or tests before pushing changes to the repository.
- **Action:** A Git pre-push hook script is added to the cloned repository in `.git/hooks/pre-push`.

### 6. Start Docker Stack

- **Purpose:** To deploy dockge using Docker Compose.
- **Action:** The Docker Compose stack is started, pulling necessary Docker images and running containers as defined in the `docker-compose.yml` file.

### 7. Display Startup Logs

- **Purpose:** To verify that the dockge service has started correctly.
- **Action:** The playbook captures and displays the startup logs from the Docker stack, aiding in troubleshooting if there are issues.

## Post-Installation Steps

**Important:** Currently, it's not possible to provision user credentials automatically during installation. This is a known limitation, and efforts are underway to address it in future updates. After installation, you will need to set up credentials manually to log into the dockge web interface.

### Setting Up User Credentials

1. **Access the Web Interface**

   Open a web browser and navigate to:

   ```
   http://<your-server-ip>:5000
   ```

2. **Create a New User**

   Since no user credentials are configured by default, you'll be prompted to create a new user account. Follow the on-screen instructions to set up your username and password.

## Data Directory

The data directory is not included in the repository because it is based on SQLite and is automatically generated once the stacks directory is scanned. This ensures that your stack configurations and data remain persistent across deployments.

## Intended Audience

dockge is designed for users who are not advanced system administrators. It provides an easy-to-use web interface for managing Docker Compose applications without the need for complex command-line interactions.

## Troubleshooting

- **Service Fails to Start**

  If the dockge service fails to start, check the Docker Compose logs for any error messages:

  ```bash
  docker-compose logs
  ```

- **Unable to Log In**

  Ensure that you have manually set up user credentials after installation, as automatic provisioning is not yet available.

- **Docker Stack Issues**

  If you encounter issues with the Docker stack, you can manually stop and remove it:

  ```bash
  cd /opt/stacks/dockge
  docker-compose down
  ```

## Future Improvements

- **Automated Credential Provisioning**

  Work is in progress to enable automatic provisioning of user credentials during installation. This will simplify the setup process further and will be updated in future releases.
