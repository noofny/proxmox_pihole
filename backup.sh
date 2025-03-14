#!/bin/bash

# NOTE: set using crontab -e and...
# 10 00 * * * /root/backup.sh

REMOTE_PATH="/mnt/backups/pihole/"
HOSTNAME=$(hostname)


log() {
   echo "$(date +%Y%m%d_%H%M%S) [${HOSTNAME}] $1" >> "${REMOTE_PATH}backup.log"
}

cd "${REMOTE_PATH}"
log "Backup starting on $(hostname)..."
pihole-FTL --teleporter &
process_id=$!
wait $process_id
find ${REMOTE_PATH} -mindepth 1 -mtime +7 -delete
log "Backup complete on $(hostname) with status $?"
