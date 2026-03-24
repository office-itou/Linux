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

<details><summary>mkosi (debian)</summary>

|              Name              |                                   Description                                   |
| :----------------------------- | :------------------------------------------------------------------------------ |
| apt                            | commandline package manager                                                     |
| apt-utils                      | package management related utility programs                                     |
| bash                           | GNU Bourne Again SHell                                                          |
| btrfs-progs                    | Checksumming Copy on Write Filesystem utilities                                 |
| ca-certificates                | Common CA certificates                                                          |
| coreutils                      | GNU core utilities                                                              |
| cpio                           | GNU cpio -- a program to manage archives of files                               |
| curl                           | command line tool for transferring data with URL syntax                         |
| debian-archive-keyring         | OpenPGP archive certificates of the Debian archive                              |
| dnf                            | Dandified Yum package manager                                                   |
| dnf-plugins-core               | Core plugins for DNF, the Dandified Yum package manager                         |
| dosfstools                     | utilities for making and checking MS-DOS FAT filesystems                        |
| e2fsprogs                      | ext2/ext3/ext4 file system utilities                                            |
| erofs-utils                    | Utilities for EROFS File System                                                 |
| grub-common                    | GRand Unified Bootloader (common files)                                         |
| keyutils                       | Linux Key Management Utilities                                                  |
| kmod                           | tools for managing Linux kernel modules                                         |
| libarchive-tools               | FreeBSD implementations of 'tar' and 'cpio' and other archive tools             |
| libcryptsetup12:amd64          | disk encryption support - shared library                                        |
| libseccomp2:amd64              | high level interface to Linux seccomp filter                                    |
| libtss2-dev:amd64              | TPM2 Software stack library - development files                                 |
| mtools                         | Tools for manipulating MSDOS files                                              |
| opensc                         | Smart card utilities with support for PKCS#15 compatible cards                  |
| openssl                        | Secure Sockets Layer toolkit - cryptographic utility                            |
| pkcs11-provider:amd64          | OpenSSL 3 provider for PKCS11                                                   |
| policycoreutils                | SELinux core policy utilities                                                   |
| python3                        | interactive high-level object-oriented language (default python3 version)       |
| python3-pefile                 | Portable Executable (PE) parsing module for Python                              |
| sbsigntool                     | Tools to manipulate signatures on UEFI binaries and drivers                     |
| squashfs-tools                 | Tool to create and append to squashfs filesystems                               |
| systemd                        | system and service manager                                                      |
| systemd-boot-tools             | simple UEFI boot manager - tools                                                |
| systemd-repart                 | Provides the systemd-repart and systemd-sbsign utilities                        |
| systemd-ukify                  | tool to build Unified Kernel Images                                             |
| tar                            | GNU version of the tar archiving utility                                        |
| xfsprogs                       | Utilities for managing the XFS filesystem                                       |
| xz-utils                       | XZ-format compression utilities                                                 |
| zstd                           | fast lossless compression algorithm -- CLI tool                                 |

</details>

<details><summary>mkosi (almalinux)</summary>

|              Name              |                                   Description                                   |
| :----------------------------- | :------------------------------------------------------------------------------ |
| apt                            | Command-line package manager for Debian packages                                |
| apt-utils                      | Package management related utility programs                                     |
| bash                           | The GNU Bourne Again shell                                                      |
| btrfs-progs                    | Userspace programs for btrfs                                                    |
| ca-certificates                | The Mozilla CA root certificate bundle                                          |
| coreutils                      | A set of basic GNU tools commonly used in shell scripts                         |
| cpio                           | A GNU archiving program                                                         |
| createrepo_c                   | Creates a common metadata repository                                            |
| curl                           | A utility for getting files from remote servers (FTP, HTTP, and others)         |
| dnf                            | Package manager                                                                 |
| dnf-plugins-core               | Core Plugins for DNF                                                            |
| dosfstools                     | Utilities for making and checking MS-DOS FAT filesystems on Linux               |
| e2fsprogs                      | Utilities for managing ext2, ext3, and ext4 file systems                        |
| erofs-utils                    | Utilities for working with EROFS                                                |
| grub2-tools                    | Support tools for GRUB.                                                         |
| keyutils                       | Linux Key Management Utilities                                                  |
| kmod                           | Linux kernel module management utilities                                        |
| libseccomp                     | Enhanced seccomp library                                                        |
| mtools                         | Programs for accessing MS-DOS disks without mounting the disks                  |
| opensc                         | Smart card library and applications                                             |
| openssl                        | Utilities from the general purpose cryptography library with TLS implementation |
| pkcs11-provider                | A PKCS#11 provider for OpenSSL 3.0+                                             |
| policycoreutils                | SELinux policy core utilities                                                   |
| python3                        | Python 3.12 interpreter                                                         |
| python3-pefile                 | Python module for working with Portable Executable files                        |
| qemu-img                       | QEMU command line tool for manipulating disk images                             |
| squashfs-tools                 | Utility for the creation of squashfs filesystems                                |
| systemd                        | System and Service Manager                                                      |
| systemd-repart                 |                                                                                 |
| systemd-udev                   | Rule-based device node and kernel event manager                                 |
| systemd-ukify                  | Tool to build Unified Kernel Images                                             |
| tar                            | GNU file archiving program                                                      |
| xfsprogs                       | Utilities for managing the XFS filesystem                                       |
| xz                             | LZMA compression utilities                                                      |
| zstd                           | Zstd compression library                                                        |

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
