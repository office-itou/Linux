# **Bridge Connection**

## Package

<details><summary>mkosi</summary>

|              Name              |                       Description                       |
| :----------------------------- | :------------------------------------------------------ |
| git                            | fast, scalable, distributed revision control system     |
| apt                            | commandline package manager                             |
| dnf                            | Dandified Yum package manager                           |
| zypper                         | command line software manager using libzypp             |
| debian-archive-keyring         | OpenPGP archive certificates of the Debian archive      |
| ubuntu-keyring                 | all GnuPG keys used by Ubuntu Project                   |
| grub-pc-bin                    | GRand Unified Bootloader, version 2 (PC/BIOS modules)   |
| syslinux-common                | collection of bootloaders (common)                      |
| isolinux                       | collection of bootloaders (ISO 9660 bootloader)         |
| systemd-boot                   | simple UEFI boot manager - integration and services     |
| systemd-container              | systemd container/nspawn tools                          |
| jq                             | lightweight and flexible command-line JSON processor    |
| parted                         | disk partition manipulator                              |
| squashfs-tools                 | Tool to create and append to squashfs filesystems       |
| xorriso                        | command line ISO-9660 and Rock Ridge manipulation tool  |

</details>

<details><summary>qemu</summary>

|              Name              |                       Description                       |
| :----------------------------- | :------------------------------------------------------ |
| qemu-system                    | QEMU full system emulation binaries                     |
| bridge-utils                   | Utilities for configuring the Linux Ethernet bridge     |
| websockify                     | WebSockets support for any application/server           |
| novnc                          | HTML5 VNC client - daemon and programs                  |
| libvirt-daemon                 | virtualization daemon                                   |

</details>

## setup

<details><summary>install (apt-get)</summary>

``` bash:
sudo bash -c '
  apt-get update
  apt-get install qemu-system bridge-utils websockify novnc
'
```

</details>

<details><summary>bridge</summary>

``` bash:
sudo bash -c '
  mkdir -p /etc/qemu
  echo "allow br0" > /etc/qemu/bridge.conf
'
```

</details>

<details><summary>network (permanent)</summary>

``` bash:
sudo bash -c '
  [[ -e /etc/NetworkManager/system-connections/Wired\ connection\ 1 ]] && nmcli connection delete Wired\ connection\ 1
  [[ -e /etc/NetworkManager/system-connections/ens160.nmconnection  ]] && nmcli connection delete ens160
  [[ -e /etc/NetworkManager/system-connections/br0.nmconnection     ]] && nmcli connection delete br0
  nmcli connection add type bridge \
    autoconnect yes \
    con-name br0 \
    ifname br0 \
    bridge.stp no \
    ipv4.addresses 192.168.1.1/24 \
    ipv4.gateway 192.168.1.254 \
    ipv4.dns 192.168.1.254 \
    ipv4.dns-search workgroup \
    ipv4.method manual \
    ipv6.method auto \
    connection.zone home_use
  nmcli connection add type bridge-slave autoconnect yes con-name ens160 master br0
  brctl stp br0 off
  brctl show
  nmcli connection show
  sleep 1
  reboot
'
```

</details>

<details><summary>qemu (nvme) (debian/ubuntu)</summary>

* qemu

  ``` bash:
  mkdir -p ~/qemu
  cd ~/qemu
  qemu-img create -f raw qemu-nvme.raw 20G
  sudo qemu-system-x86_64 \
    -cpu Skylake-Client \
    -machine pc \
    -enable-kvm \
    -m size=4G \
    -boot menu=on \
    -cdrom /srv/user/share/isos/linux/debian/mini-trixie-amd64.iso \
    -device nvme,id=nvme-ctrl-0,serial=deadbeef \
    -drive file=qemu-nvme.raw,format=raw,if=none,id=nvm-1 \
    -device nvme-ns,drive=nvm-1 \
    -audiodev alsa,id=snd0 \
    -device ich9-intel-hda \
    -device hda-output,audiodev=snd0 \
    -nic bridge \
    -vga std \
    -full-screen \
    -display curses,charset=CP932 \
    -k ja \
    -monitor stdio \
    -vnc :0
  echo -e "\x12\x1bc"
  ```

* novnc

  ``` bash:
  /usr/share/novnc/utils/novnc_proxy
  ```

* vnc access example:  
  http://sv-developer:6080/vnc.html

</details>

## configuration files

<details><summary>cat /etc/NetworkManager/system-connections/br0.nmconnection</summary>

``` bash
$ sudo cat /etc/NetworkManager/system-connections/br0.nmconnection
[connection]
id=br0
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
type=bridge
interface-name=br0
zone=home_use

[ethernet]

[bridge]
stp=false

[ipv4]
address1=192.168.1.1/24
dns=192.168.1.254;
dns-search=workgroup;
gateway=192.168.1.254
method=manual

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
```

</details>

<details><summary>cat /etc/NetworkManager/system-connections/ens160.nmconnection</summary>

``` bash
$ sudo cat /etc/NetworkManager/system-connections/ens160.nmconnection
[connection]
id=ens160
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
type=ethernet
controller=br0
port-type=bridge

[ethernet]

[bridge-port]
```

</details>
