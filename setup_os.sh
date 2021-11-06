#!/bin/bash


echo "Setup OS : begin"


# timezone
echo "Setting timezone..."
timedatectl set-timezone Australia/Sydney


# locale
echo "Setting locale..."
LOCALE_VALUE="en_AU.UTF-8"
echo ">>> locale-gen..."
locale-gen ${LOCALE_VALUE}
cat /etc/default/locale
source /etc/default/locale
echo ">>> update-locale..."
update-locale ${LOCALE_VALUE}
echo ">>> hack /etc/ssh/ssh_config..."
sed -e '/SendEnv/ s/^#*/#/' -i /etc/ssh/ssh_config


# patch
echo "Patching..."
apt-get update
apt-get upgrade -y


# packages
echo "Installing packages..."
apt-get install -y \
    curl \
    wget \
    htop \
    net-tools \
    ntp


# firewall
echo "Enabling and configuring firewall..."
ufw enable
ufw allow 53
ufw allow 80
ufw allow 443
ufw allow http
ufw allow https
ufw status


echo "Setup OS : script complete!"
