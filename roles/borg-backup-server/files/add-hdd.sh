#!/bin/bash
## Проверяем какой диск свободен
hdd () {
    lsblk | grep 2G | awk '{print $1}'
}
sudo pvcreate /dev/$(hdd)
sudo vgcreate vg0 /dev/$(hdd)
sudo lvcreate -l100%FREE -n backup vg0
sudo mkfs.ext4 -L backup /dev/vg0/backup
sudo chmod o+w /etc/fstab
sudo echo "LABEL=backup /var/Backuprepo ext4 defaults 0 0" >> /etc/fstab
sudo chmod o-w /etc/fstab
sudo mount -a