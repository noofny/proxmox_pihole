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

## Commands

```shell
# list available LXC images...
pveam available --section system

# download an LXC image...
pveam download remote ubuntu-22.10-standard_22.10-1_amd64.tar.zst
```

## Inspiration / Reference

- [Install pihole on a ProxMox LXC ubuntu container and setup as Primary DNS for a Unifi Network](https://florianmuller.com/install-pihole-on-a-proxmox-lxc-ubuntu-container-and-setup-as-primary-dns-for-unifi-network)
- [proxmox motioneye container](https://github.com/JedimasterRDW/proxmox_motioneye_container)
- [pveam docs](https://pve.proxmox.com/pve-docs/pveam.1.html)
- [Pi-hole as All-Around DNS Solution](https://docs.pi-hole.net/guides/dns/unbound/)
- [DNSSEC Resolver Test](https://wander.science/projects/dns/dnssec-resolver-test/)
- [Craft Computing # You're running Pi-Hole wrong! Setting up your own Recursive DNS Server!](https://www.youtube.com/watch?v=FnFtWsZ8IP0)
