# Ansible playbook and shell script that wipes and zaps disks on remote hosts
Script that wipes disks on remote hosts, that were subject of a Ceph cluster deployment (with or without Rook).

It uses an Ansible playbook to run the script on remote hosts and wipe all disks except `sda` assuming that the OS runs on `sda`.

The script also zaps all disks (except `sda`) and ensures that any Ceph-related entries are wiped clean, including removal of `/var/lib/rook/` directory. 
