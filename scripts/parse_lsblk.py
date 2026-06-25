#!/usr/bin/env python3
import json
import sys

# Read input JSON from stdin
lsblk_output = sys.stdin.read()

# Parse the JSON
data = json.loads(lsblk_output)

# Initialize the dictionary
mountpoint_device_map = {}

# Process each block device
for device in data['blockdevices']:
    # Check if there are child devices
    if 'children' in device:
        for child in device['children']:
            if child['mountpoints']:
                for mountpoint in child['mountpoints']:
                    if mountpoint is not None:
                        mountpoint_device_map[mountpoint] = child['name']

    # Process root-level device
    if device['mountpoints']:
        for mountpoint in device['mountpoints']:
            if mountpoint is not None:
                mountpoint_device_map[mountpoint] = device['name']

# Output the resulting dictionary
print(json.dumps(mountpoint_device_map))
