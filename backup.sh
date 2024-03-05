#!/bin/bash

# NOTE: set using crontab -e and...
# 0 18 * * * /root/backup.sh


TIMESTAMP=$(date +%Y%m%d%H%M%S)
HOSTNAME=$(hostname)
LOCAL_PATH="/mnt/pve/ceph-fs-1"
REMOTE_PATH="/mnt/pve/remote"


log() {
   echo "$(date +%Y%m%d_%H%M%S) [${HOSTNAME}] $1" >> "${REMOTE_PATH}/backup.log"
}


log "Backup starting..."

mount -a
cd /root

# NOTE: Node backup contains sensitive content, so do this manually for now.
#       TODO: put this behind a conditional flag/switch.
# NODE_BACKUP_FILENAME="backup_${HOSTNAME}_${TIMESTAMP}.tar.gz"
# log "Creating NODE backup: ${NODE_BACKUP_FILENAME}..."
# mkdir -p /etc/pve/os_and_system/root
# mkdir -p /etc/pve/os_and_system/etc
# mkdir -p /etc/pve/os_and_system/etc/kernel
# mkdir -p /etc/pve/os_and_system/etc/modprobe.d
# cp /root/*.* /etc/pve/os_and_system/root/
# cp /etc/hosts /etc/pve/os_and_system/etc/hosts
# cp /etc/fstab /etc/pve/os_and_system/etc/fstab
# cp /etc/kernel/cmdline /etc/pve/os_and_system/etc/kernel/cmdline
# cp /etc/modules /etc/pve/os_and_system/etc/modules
# cp /etc/default/grub /etc/pve/os_and_system/etc/grub
# cp /etc/modprobe.d/iommu_unsafe_interrupts.conf /etc/pve/os_and_system/etc/modprobe.d/iommu_unsafe_interrupts.conf
# crontab -l > /etc/pve/os_and_system/etc/crontab.txt
# ip address > /etc/pve/os_and_system/ip_address.txt
# tar -zcvf "${NODE_BACKUP_FILENAME}" /etc/pve/
# log "Pushing NODE backup to remote: ${NODE_BACKUP_FILENAME}"
# mv "${NODE_BACKUP_FILENAME}" "${REMOTE_PATH}/node_backups/${NODE_BACKUP_FILENAME}"
# find "${REMOTE_PATH}/node_backups/" -mindepth 1 -mtime +7 -delete

log "Pushing VM backups to remote..."
rsync -r -h --progress --ignore-existing "${LOCAL_PATH}/" "${REMOTE_PATH}/"
log "Pushed VM backups to remote"

log "Backup completed"
