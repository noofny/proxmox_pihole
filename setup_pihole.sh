#!/bin/bash


# # locale
# echo "Setting locale..."
# LOCALE_VALUE="en_AU.UTF-8"
# echo ">>> locale-gen..."
# locale-gen ${LOCALE_VALUE}
# cat /etc/default/locale
# source /etc/default/locale
# echo ">>> update-locale..."
# update-locale ${LOCALE_VALUE}
# echo ">>> hack /etc/ssh/ssh_config..."
# sed -e '/SendEnv/ s/^#*/#/' -i /etc/ssh/ssh_config


# unattended
current_ip=$(hostname -i)
conf_folder='/etc/pihole'
conf_filename='setupVars.conf'
conf_path="${conf_folder}/${conf_filename}"
mkdir "${conf_folder}"
cat <<EOF > ${conf_path}
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=${HOST_IP4_CIDR}
IPV6_ADDRESS=
PIHOLE_DNS_1=${UPSTREAM_DNS_1}
PIHOLE_DNS_2=${UPSTREAM_DNS_2}
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
BLOCKING_ENABLED=true
WEBTHEME=default-darker
EOF


# install
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
echo "Setup complete - you can access the console at https://$(hostname -I)/"
