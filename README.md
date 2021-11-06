# PiHole on ProxMox

<p align="center">
    <img height="200" alt="PiHole Logo" src="img/logo_pihole.png">
    <img height="200" alt="ProxMox Logo" src="img/logo_proxmox.png">
</p>

Create a [ProxMox](https://www.proxmox.com/en/) LXC container running Ubuntu and install [PiHole.](https://pi-hole.net/)

Tested on ProxMox v7 and PiHole v5.6

## Usage

SSH to your ProxMox server as a privileged user and run...

```shell
bash -c "$(wget --no-cache -qLO - https://raw.githubusercontent.com/noofny/proxmox_pihole/master/setup.sh)"
```

## Inspiration

- [Install pihole on a ProxMox LXC ubuntu container and setup as Primary DNS for a Unifi Network](https://florianmuller.com/install-pihole-on-a-proxmox-lxc-ubuntu-container-and-setup-as-primary-dns-for-unifi-network)
- [proxmox motioneye container](https://github.com/JedimasterRDW/proxmox_motioneye_container)
