# **QEMU(rootfs connection)**

## main specifications

<details><summary>spec</summary>

|         |                                                |
| :------ | :--------------------------------------------- |
| cpu     | host                                           |
| machine | q35                                            |
| memory  | 4G                                             |
| file    | rtdisk.raw                                     |
| rootfs  | rtfs/                                          |
| socket  | /var/run/vm001-vhost-fs.sock                   |
| kernel  | rtfs/boot/vmlinuz-6.12.74+deb13+1-amd64        |
| initrd  | rtfs/boot/initrd.img-6.12.74+deb13+1-amd64     |
| append  | console=ttyS0 root=myfs rootfstype=virtiofs rw |

</details>

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

<details><summary>mount</summary>

``` bash:
$ sudo fdisk -l rtdisk.raw
Disk rtdisk.raw: 4.82 GiB, 5178601472 bytes, 10114456 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Device      Start      End  Sectors  Size Type
rtdisk.raw1  2048 10114415 10112368  4.8G Linux root (x86-64)
$ sudo mount -o offset=$((2048*512)) rtdisk.raw rtfs/
```

</details>

<details><summary>virtiofsd</summary>

``` bash:
sudo /usr/libexec/virtiofsd --socket-path=/var/run/vm001-vhost-fs.sock -o source=rtfs/
```

</details>

<details><summary>qemu</summary>

``` bash
sudo qemu-system-x86_64 \
  -cpu host \
  -machine q35 \
  -enable-kvm \
  -m size=4G \
  -chardev socket,id=chr0,path=/var/run/vm001-vhost-fs.sock \
  -device vhost-user-fs-pci,chardev=chr0,tag=myfs \
  -object memory-backend-memfd,id=mem,size=4G,share=on \
  -numa node,memdev=mem \
  -nic bridge \
  -vga std \
  -full-screen \
  -display curses,charset=CP932 \
  -k ja \
  -vnc :0 \
  -kernel rtfs/boot/vmlinuz-6.12.74+deb13+1-amd64 \
  -initrd rtfs/boot/initrd.img-6.12.74+deb13+1-amd64 \
  -append "console=ttyS0 root=myfs rootfstype=virtiofs rw" \
  -nographic
```

</details>
