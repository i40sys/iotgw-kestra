# template file
all:
  children:
    openwrt:
      hosts:
        {{ target_ip }}:
  vars:
    ansible_user: 'root'
    #ansible_ssh_pass: ''
    #ansible_port: 5555
    #ansible_connection: 'ssh'
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_private_key_file: "keys/id_rsa"
    ansible_ssh_common_args: >-
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
      -o ProxyCommand="ssh -i keys/id_rsa -o IdentitiesOnly=yes
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
      -W %h:%p -q root@203.0.113.10"
