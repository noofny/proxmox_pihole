#!/bin/bash -e


# functions
function error() {
    echo -e "\e[91m[ERROR] $1\e[39m"
}
function warn() {
    echo -e "\e[93m[WARNING] $1\e[39m"
}
function info() {
    echo -e "\e[36m[INFO] $1\e[39m"
}
function cleanup() {
    popd >/dev/null
    rm -rf $TEMP_FOLDER_PATH
}


TEMP_FOLDER_PATH=$(mktemp -d)
pushd $TEMP_FOLDER_PATH >/dev/null


# prompts/args
DEFAULT_HOSTNAME='pihole-1'
DEFAULT_PASSWORD='pihole'
DEFAULT_IPV4_CIDR='192.168.0.100/24'
DEFAULT_IPV4_GW='192.168.0.1'
DEFAULT_UPSTREAM_DNS_1='1.1.1.1'
DEFAULT_UPSTREAM_DNS_2='1.0.0.1'
DEFAULT_NET_INTERFACE='eth0'
DEFAULT_NET_BRIDGE='vmbr1'
DEFAULT_CONTAINER_ID=$(pvesh get /cluster/nextid)
read -p "Enter a hostname (${DEFAULT_HOSTNAME}) : " HOSTNAME
read -s -p "Enter a password (${DEFAULT_PASSWORD}) : " HOSTPASS
echo -e "\n"
read -p "Enter an IPv4 CIDR (${DEFAULT_IPV4_CIDR}) : " HOST_IP4_CIDR
read -p "Enter an IPv4 Gateway (${DEFAULT_IPV4_GW}) : " HOST_IP4_GATEWAY
read -p "Enter an IPv4 address for upstream DNS 1 (${DEFAULT_UPSTREAM_DNS_1}) : " UPSTREAM_DNS_1
read -p "Enter an IPv4 address for upstream DNS 2 (${DEFAULT_UPSTREAM_DNS_2}) : " UPSTREAM_DNS_2
read -p "Enter the network interface to use (${DEFAULT_NET_INTERFACE}) : " NET_INTERFACE
read -p "Enter the network bridge to use (${DEFAULT_NET_BRIDGE}) : " NET_BRIDGE
read -p "Enter a container ID (${DEFAULT_CONTAINER_ID}) : " CONTAINER_ID
HOSTNAME="${HOSTNAME:-${DEFAULT_HOSTNAME}}"
HOSTPASS="${HOSTPASS:-${DEFAULT_PASSWORD}}"
HOST_IP4_CIDR="${HOST_IP4_CIDR:-${DEFAULT_IPV4_CIDR}}"
HOST_IP4_GATEWAY="${HOST_IP4_GATEWAY:-${DEFAULT_IPV4_GW}}"
UPSTREAM_DNS_1="${UPSTREAM_DNS_1:-${DEFAULT_UPSTREAM_DNS_1}}"
UPSTREAM_DNS_2="${UPSTREAM_DNS_2:-${DEFAULT_UPSTREAM_DNS_2}}"
NET_INTERFACE="${NET_INTERFACE:-${DEFAULT_NET_INTERFACE}}"
NET_BRIDGE="${NET_BRIDGE:-${DEFAULT_NET_BRIDGE}}"
CONTAINER_ID="${CONTAINER_ID:-${DEFAULT_CONTAINER_ID}}"
export HOST_IP4_CIDR=${HOST_IP4_CIDR}
export UPSTREAM_DNS_1=${UPSTREAM_DNS_1}
export UPSTREAM_DNS_2=${UPSTREAM_DNS_2}
CONTAINER_OS_TYPE='ubuntu'
CONTAINER_OS_VERSION='22.04'
CONTAINER_OS_STRING="${CONTAINER_OS_TYPE}-${CONTAINER_OS_VERSION}"
info "Using OS: ${CONTAINER_OS_STRING}"
CONTAINER_ARCH=$(dpkg --print-architecture)
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($CONTAINER_OS_STRING.*\)/\1/p" | sort -t - -k 2 -V)
TEMPLATE="${TEMPLATES[-1]}"
TEMPLATE_STRING="remote:vztmpl/${TEMPLATE}"
info "Using template: ${TEMPLATE_STRING}"


# storage location
STORAGE_LIST=( $(pvesm status -content rootdir | awk 'NR>1 {print $1}') )
if [ ${#STORAGE_LIST[@]} -eq 0 ]; then
    warn "'Container' needs to be selected for at least one storage location."
    die "Unable to detect valid storage location."
elif [ ${#STORAGE_LIST[@]} -eq 1 ]; then
    STORAGE=${STORAGE_LIST[0]}
else
    info "More than one storage locations detected."
    PS3=$"Which storage location would you like to use? "
    select storage_item in "${STORAGE_LIST[@]}"; do
        if [[ " ${STORAGE_LIST[*]} " =~ ${storage_item} ]]; then
            STORAGE=$storage_item
            break
        fi
        echo -en "\e[1A\e[K\e[1A"
    done
fi
info "Using '$STORAGE' for storage location."


# Create the container
info "Creating LXC container..."
pct create "${CONTAINER_ID}" "${TEMPLATE_STRING}" \
    -arch "${CONTAINER_ARCH}" \
    -cores 2 \
    -memory 2048 \
    -swap 0 \
    -onboot 0 \
    -features nesting=1,keyctl=1 \
    -hostname "${HOSTNAME}" \
    -net0 name=eth0,bridge=vmbr1,gw=${HOST_IP4_GATEWAY},ip=${HOST_IP4_CIDR} \
    -ostype "${CONTAINER_OS_TYPE}" \
    -password ${HOSTPASS} \
    -storage "${STORAGE}" \
    --unprivileged 1 \
    || fatal "Failed to create container!"


# Configure container
info "Configuring LXC container..."
pct set "${CONTAINER_ID}" -mp0 /mnt/backups,mp=/mnt/backups


# Start container
info "Starting LXC container..."
pct start "${CONTAINER_ID}" || exit 1
sleep 5
CONTAINER_STATUS=$(pct status $CONTAINER_ID)
if [ ${CONTAINER_STATUS} != "status: running" ]; then
    fatal "Container ${CONTAINER_ID} is not running! status=${CONTAINER_STATUS}"
fi


# Setup OS
info "Fetching setup script..."
wget -qL https://raw.githubusercontent.com/noofny/proxmox_pihole/master/setup_os.sh
info "Executing script..."
pct push "${CONTAINER_ID}" ./setup_os.sh /setup_os.sh -perms 755
pct exec "${CONTAINER_ID}" -- bash -c "/setup_os.sh"
pct reboot "${CONTAINER_ID}"


# Setup pihole
info "Fetching setup script..."
wget -qL https://raw.githubusercontent.com/noofny/proxmox_pihole/master/setup_pihole.sh
wget -qL https://raw.githubusercontent.com/noofny/proxmox_pihole/master/pi-hole.conf
wget -qL https://raw.githubusercontent.com/noofny/proxmox_pihole/master/backup.sh
info "Executing script..."
pct push "${CONTAINER_ID}" ./setup_pihole.sh /setup_pihole.sh -perms 755
pct push "${CONTAINER_ID}" ./pi-hole.conf /pi-hole.conf
pct push "${CONTAINER_ID}" ./backup.sh /backup.sh
pct exec "${CONTAINER_ID}" -- bash -c "/setup_pihole.sh"
info "Please set web console password..."
pct exec "${CONTAINER_ID}" -- bash -c "/usr/local/bin/pihole -a -p"


# Done - reboot!
rm -rf ${TEMP_FOLDER_PATH}
info "Container and app setup - container will restart!"
pct reboot "${CONTAINER_ID}"


echo "Init : complete"
