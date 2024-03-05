#!/bin/bash -e


echo "Setup OS : begin"


# locale
echo "Fixing locale..."
LOCALE_VALUE="en_AU.UTF-8"
locale-gen ${LOCALE_VALUE}
source /etc/default/locale
update-locale ${LOCALE_VALUE}


# timezone
echo "Setting timezone..."
timedatectl set-timezone Australia/Sydney


# patch
echo "Patching..."
apt-get update && apt-get upgrade -y


# packages
echo "Installing packages..."
apt-get update && apt-get install -y \
    curl \
    wget \
    htop \
    net-tools \
    ntp \
    unbound


# firewall
echo "Enabling and configuring firewall..."
ufw enable
ufw allow 22
ufw allow 53
ufw allow 80
ufw allow 443
ufw allow http
ufw allow https
ufw status


# ssh/user
echo "Configuring SSH and user access..."
SSH_USER=piholeadmin
adduser --gecos "" ${SSH_USER}
usermod -aG sudo ${SSH_USER}
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa_pihole_ssh -q -N ""
cat ~/.ssh/id_rsa_pihole_ssh
mkdir /home/${SSH_USER}/.ssh
cp ~/.ssh/id_rsa_pihole_ssh /home/${SSH_USER}/.ssh/id_rsa_pihole_ssh
cp ~/.ssh/id_rsa_pihole_ssh.pub /home/${SSH_USER}/.ssh/id_rsa_pihole_ssh.pub
cat ~/.ssh/id_rsa_pihole_ssh.pub >> /home/${SSH_USER}/.ssh/authorized_keys
chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}
chmod 600 /home/${SSH_USER}/.ssh/id_rsa*
chmod 600 /home/${SSH_USER}/.ssh/authorized_keys
sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh


echo "Setup OS : complete!"
