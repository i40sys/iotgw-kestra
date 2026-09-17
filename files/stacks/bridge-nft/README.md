# Bridge NFTables

This project provides a script to manage NFTables bridge rules using [bridge.nft](bridge.nft) with a service script ([bridge-nft](bridge-nft)).

## Installation
1. Assuming, there is a directory `/opt/stacks`:
   ```bash
   cd /opt/stacks
   git clone git@github.com:sabatligats/iotgw_bridge-nft.git
   ```
2. Make it executable:  
   ```bash
   ln -s /opt/stacks/bridge-nft /etc/init.d/bridge-nft
   chmod +x /etc/init.d/bridge-nft
   ```
3. Symlink the service to run on startup:
   ```bash
   /etc/init.d/bridge-nft enable
   ```

## Usage
- **Start** load nftables bridge rules:  
  ```sh
  /etc/init.d/bridge-nft start
  ```
- **Stop** remove nftables bridge rules:  
  ```sh
  /etc/init.d/bridge-nft stop
  ```
- **Restart** reload nftables bridge rules:  
  ```sh
  /etc/init.d/bridge-nft restart
  ```
- **Check** status, return if the nft bridge rules are loaded and if the service is enabled:  
  ```sh
  /etc/init.d/bridge-nft status
  ```
- **Dump** the nftables bridge rules:  
  ```sh
  /etc/init.d/bridge-nft dump
  ```
- **Enable** the service to run on startup:  
  ```sh
  /etc/init.d/bridge-nft enable
  ```
- **Disable** the service to run on startup:  
  ```sh
  /etc/init.d/bridge-nft disable
  ```


## Files
- [bridge-nft](bridge-nft): Shell script to manage NFTables on system startup.
- [bridge.nft](bridge.nft): NFTables rules for the bridge table.

## License
MIT License
