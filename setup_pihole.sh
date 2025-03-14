#!/bin/bash -e


echo "Setup PiHole : begin"


# locale
echo "Fixing locale..."
LOCALE_VALUE="en_AU.UTF-8"
locale-gen ${LOCALE_VALUE}
source /etc/default/locale
update-locale ${LOCALE_VALUE}


# unattended / config
echo "Creating PiHole config folder..."
current_ip=$(hostname -i)
conf_folder='/etc/pihole'
mkdir "${conf_folder}"

echo "Creating PiHole setupVars file..."
cat <<EOF > "${conf_folder}/setupVars.conf"
PIHOLE_INTERFACE=${NET_INTERFACE}
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

echo "Creating PiHole-FTL config file..."
cat <<EOF > "${conf_folder}/pihole-FTL.conf"
PRIVACYLEVEL=0
RATE_LIMIT=10000/60
EOF


# custom scripts
echo "Moving and permissioning scripts..."
mv /backup.sh /root/backup.sh
mv /auto_dns.py /root/auto_dns.py
chmod +x /root/backup.sh
echo "...append the following to cron..."
echo "10 00 * * * /root/backup.sh"
echo "* * * * * python3 /root/auto_dns.py > /root/auto_dns.py.log 2>&1"
crontab -e


# install pihole
echo "Downloading & executing PiHole install script..."
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
echo "Stopping unbound..."
service unbound stop
echo "Moving unbound config file..."
mv /pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf
echo "Starting unbound..."
service unbound start
echo "Testing unbound..."
dig pi-hole.net @127.0.0.1 -p 5335
echo "Setup complete - you can access the console at https://$(hostname -I)/"


echo "Setup PiHole : complete"
