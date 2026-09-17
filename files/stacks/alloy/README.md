# Grafana Alloy Service for OpenWRT

Running Grafana Alloy on OpenWRT as a native service.

**Note:** This document provides an overview of the installation and configuration steps performed automatically by an Ansible playbook. You do not need to execute these steps manually. The purpose of this documentation is to outline what the automated process does for transparency and troubleshooting.

Based on the work done at:
https://git.oriolrius.cat/oriolrius/alloy-openwrt

## Overview

The automated installation process using Ansible performs the following actions:

- Removes any existing Alloy installation.
- Clones the Alloy repository into `/opt/stacks/alloy`.
- Creates necessary directories for binaries and libraries.
- Installs required glibc libraries and links them with the OS.
- Downloads and installs the latest Alloy binary.
- Configures Alloy using a template.
- Sets up Alloy as a service that starts on boot.
- Starts the Alloy service immediately.

## Automated Installation and Configuration Process

The following steps are executed by the Ansible playbook to set up Grafana Alloy on OpenWRT:

### 1. Remove Existing Alloy Installation

The playbook ensures that any previous installation of Alloy is removed to prevent conflicts:

```bash
rm -rf /opt/stacks/alloy
```

### 2. Clone the Alloy Repository

It clones the Alloy repository into `/opt/stacks/alloy`:

```bash
git clone git@github.com:sabatligats/alloy.git /opt/stacks/alloy
```

### 3. Create Required Directories

Necessary directories for binaries and libraries are created:

```bash
mkdir -p /opt/stacks/alloy/bin
mkdir -p /opt/stacks/alloy/lib
```

### 4. Install glibc Libraries

The `glibc.tar.gz` file, required for the Alloy binary, is extracted:

```bash
tar -xzf /opt/stacks/alloy/contrib/glibc.tar.gz -C /opt/stacks/alloy/lib/
```

### 5. Link glibc Libraries with the OS

Symbolic links are created to ensure the system recognizes the glibc libraries:

```bash
ln -s /opt/stacks/alloy/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu
ln -s /opt/stacks/alloy/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2
```

### 6. Download and Install the Latest Alloy Binary

#### a. Fetch the Latest Alloy Version

The latest release tag from the Grafana Alloy GitHub repository is retrieved:

```bash
ALLOY_VERSION=$(curl -sL https://api.github.com/repos/grafana/alloy/releases/latest | jq -r ".tag_name")
```

#### b. Download the Alloy Binary

The latest Alloy binary zip file is downloaded:

```bash
curl -L "https://github.com/grafana/alloy/releases/download/${ALLOY_VERSION}/alloy-linux-amd64.zip" -o /tmp/alloy.zip
```

#### c. Unzip the Alloy Binary

The downloaded file is unzipped into the binary directory:

```bash
unzip /tmp/alloy.zip -d /opt/stacks/alloy/bin
```

#### d. Clean Up the Zip File

The downloaded zip file is removed to save space:

```bash
rm /tmp/alloy.zip
```

#### e. Rename and Set Permissions

The binary is renamed for convenience, and executable permissions are set:

```bash
mv /opt/stacks/alloy/bin/alloy-linux-amd64 /opt/stacks/alloy/bin/alloy
chmod 0755 /opt/stacks/alloy/bin/alloy
```

### 7. Configure Alloy

#### a. Prepare the Configuration Template

The playbook fetches the `config.alloy.j2` ([repos link](https://github.com/sabatligats/iotgw_alloy/blob/master/etc/config.alloy.j2)) template and processes it:

```bash
# Template processing is done via Ansible and the result is placed at:
/opt/stacks/alloy/etc/config.alloy
```

#### b. Edit the Configuration Files (If Needed)

Configuration files are at `/opt/stacks/alloy/etc/`.

### 8. Set Up Alloy as a Service

#### a. Create a Service Script

A service script is created by linking the provided `service.sh`:

```bash
ln -s /opt/stacks/alloy/contrib/alloy /etc/init.d/alloy
chmod +x /etc/init.d/alloy
```

#### b. Enable the Service on Boot

The Alloy service is enabled to start on system boot:

```bash
/etc/init.d/alloy enable
```

### 9. Start the Alloy Service

The Alloy service is started immediately:

```bash
/etc/init.d/alloy start
```

## Verification

To check if the Alloy service is running:

```bash
ps | grep alloy
```

You should see the Alloy process listed.

## Notes

- **Automation:** All the above steps are performed automatically by the Ansible playbook. There is no need for manual intervention unless troubleshooting is required.
- **Dependencies:** Ensure that `curl`, `jq`, `git`, and `unzip` are installed on your OpenWRT device. The playbook assumes these are present.
- **User Permissions:** The playbook runs commands as the `root` user.

## Troubleshooting

If you encounter issues, consider the following:

- **Service Fails to Start:** Check the logs located at `/var/log/alloy.log` for any error messages.
- **Binary Not Executable:** Ensure that the Alloy binary has the correct permissions: `chmod 0755 /opt/stacks/alloy/bin/alloy`.
- **Missing Libraries:** Verify that the glibc libraries are correctly linked.

## Reference

- https://git.oriolrius.cat/oriolrius/alloy-openwrt for the foundational work on integrating Alloy with OpenWRT.
- https://github.com/sabatligats/iotgw_alloy
- [rsyslog](https://www.rsyslog.com/doc/configuration/converting_to_new_format.html)
- [rsyslog OpenWRT](https://openwrt.org/docs/guide-user/perf_and_log/log.rsyslog)
