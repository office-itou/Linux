# **PXEBOOT**  
  
## System configuration  
  
| Module         | Detail                          |
| -------------- | ------------------------------- |
| Virtual system | VMware Workstation 16 Pro       |
| Processor      | 1 processor / 2 cores (i7-6700) |
| Memory         | 4GiB (Live mode is 8GiB)        |
| Storage        | NVMe 64 GiB / SATA 20GiB        |
| Network        | NIC1 e1000e / NIC2 e1000e       |
  
## Result  
  
| Media        | File name                                  | Looding | Booting | Install | Note                                      |
| ------------ | ------------------------------------------ | :-----: | :-----: | :-----: | ----------------------------------------- |
| mini.iso     | mini-buster-amd64.iso                      |    O    |    O    |    O    | Network installation only                 |
|              | mini-bullseye-amd64.iso                    |    O    |    O    |    O    | "                                         |
|              | mini-bookworm-amd64.iso                    |    O    |    O    |    O    | "                                         |
|              | mini-trixie-amd64.iso                      |    O    |    O    |    O    | "                                         |
|              | mini-testing-amd64.iso                     |    O    |    O    |    O    | "                                         |
|              | mini-bionic-amd64.iso                      |    O    |    O    |    O    | "                                         |
|              | mini-focal-amd64.iso                       |    O    |    O    |    O    | "                                         |
| Net install  | debian-10.13.0-amd64-netinst.iso           |    O    |    O    |    X    | Unable to detect media                    |
|              | debian-11.9.0-amd64-netinst.iso            |    O    |    O    |    X    | "                                         |
|              | debian-12.5.0-amd64-netinst.iso            |    O    |    O    |    X    | "                                         |
|              | debian-testing-amd64-netinst.iso           |    O    |    O    |    X    | "                                         |
|              | Fedora-Server-netinst-x86_64-38-1.6.iso    |    O    |    O    |    O    | No special mention                        |
|              | Fedora-Server-netinst-x86_64-39-1.5.iso    |    O    |    O    |    O    | "                                         |
|              | Fedora-Server-netinst-x86_64-40-1.14.iso   |    O    |    O    |    O    | "                                         |
|              | CentOS-Stream-8-x86_64-latest-boot.iso     |    O    |    O    |    O    | "                                         |
|              | CentOS-Stream-9-latest-x86_64-boot.iso     |    O    |    O    |    O    | "                                         |
|              | AlmaLinux-9-latest-x86_64-boot.iso         |    O    |    O    |    O    | "                                         |
|              | Rocky-8.9-x86_64-boot.iso                  |    O    |    O    |    O    | "                                         |
|              | Rocky-9-latest-x86_64-boot.iso             |    O    |    O    |    O    | "                                         |
|              | MIRACLELINUX-8.8-rtm-minimal-x86_64.iso    |    O    |    O    |    O    | "                                         |
|              | MIRACLELINUX-9.2-rtm-minimal-x86_64.iso    |    O    |    O    |    O    | "                                         |
|              | openSUSE-Leap-15.5-NET-x86_64-Media.iso    |    O    |    O    |    O    | No special mention                        |
|              | openSUSE-Leap-15.6-NET-x86_64-Media.iso    |    O    |    O    |    O    | "                                         |
|              | openSUSE-Tumbleweed-NET-x86_64-Current.iso |    O    |    O    |    O    | "                                         |
| DVD          | debian-10.13.0-amd64-DVD-1.iso             |    O    |    O    |    X    | Unable to detect media                    |
|              | debian-11.9.0-amd64-DVD-1.iso              |    O    |    O    |    X    | "                                         |
|              | debian-12.5.0-amd64-DVD-1.iso              |    O    |    O    |    X    | "                                         |
|              | debian-testing-amd64-DVD-1.iso             |    O    |    O    |    X    | "                                         |
|              | ubuntu-18.04.6-server-amd64.iso            |    O    |    O    |    O    | No special mention                        |
|              | ubuntu-18.04.6-live-server-amd64.iso       |    O    |    X    |    X    | Unable to continue automatic installation |
|              | ubuntu-20.04.6-live-server-amd64.iso       |    O    |    X    |    X    | "                                         |
|              | ubuntu-22.04.4-live-server-amd64.iso       |    O    |    O    |    O    | No special mention                        |
|              | ubuntu-23.10-live-server-amd64.iso         |    O    |    O    |    O    | "                                         |
|              | ubuntu-24.04-live-server-amd64.iso         |    O    |    O    |    O    | "                                         |
|              | Fedora-Server-dvd-x86_64-38-1.6.iso        |    O    |    O    |    O    | No special mention                        |
|              | Fedora-Server-dvd-x86_64-39-1.5.iso        |    O    |    O    |    O    | "                                         |
|              | Fedora-Server-dvd-x86_64-40-1.14.iso       |    O    |    O    |    O    | "                                         |
|              | CentOS-Stream-8-x86_64-latest-dvd1.iso     |    O    |    O    |    O    | "                                         |
|              | CentOS-Stream-9-latest-x86_64-dvd1.iso     |    O    |    O    |    O    | "                                         |
|              | AlmaLinux-9-latest-x86_64-dvd.iso          |    O    |    O    |    O    | "                                         |
|              | Rocky-8.9-x86_64-dvd1.iso                  |    O    |    O    |    O    | "                                         |
|              | Rocky-9-latest-x86_64-dvd.iso              |    O    |    O    |    O    | "                                         |
|              | MIRACLELINUX-8.8-rtm-x86_64.iso            |    O    |    O    |    O    | "                                         |
|              | MIRACLELINUX-9.2-rtm-x86_64.iso            |    O    |    O    |    O    | "                                         |
|              | openSUSE-Leap-15.5-DVD-x86_64-Media.iso    |    O    |    O    |    O    | No special mention                        |
|              | openSUSE-Leap-15.6-DVD-x86_64-Media.iso    |    O    |    O    |    O    | "                                         |
|              | openSUSE-Tumbleweed-DVD-x86_64-Current.iso |    O    |    O    |    O    | "                                         |
|              | Win10_22H2_Japanese_x64.iso                |    X    |    X    |    X    | Not tested                                |
|              | Win11_23H2_Japanese_x64v2_custom.iso       |    X    |    X    |    X    | "                                         |
| Live DVD     | debian-live-10.13.0-amd64-lxde.iso         |    O    |    O    |    X    | Unable to detect media                    |
|              | debian-live-11.9.0-amd64-lxde.iso          |    O    |    O    |    X    | "                                         |
|              | debian-live-12.5.0-amd64-lxde.iso          |    O    |    O    |    X    | "                                         |
|              | debian-live-testing-amd64-lxde.iso         |    O    |    O    |    X    | "                                         |
|              | ubuntu-20.04.6-desktop-amd64.iso           |    O    |    O    |    X    | Unable to continue automatic installation |
|              | ubuntu-22.04.4-desktop-amd64.iso           |    O    |    O    |    X    | "                                         |
|              | ubuntu-23.10.1-desktop-amd64.iso           |    O    |    O    |    X    | Unable to continue due to installer bug   |
|              | ubuntu-24.04-desktop-amd64.iso             |    O    |    O    |    X    | "                                         |
|              | ubuntu-23.10-desktop-legacy-amd64.iso      |    O    |    O    |    O    | Unable to detect media                    |
| Live mode    | debian-live-10.13.0-amd64-lxde.iso         |    O    |    O    |    -    | No special mention                        |
|              | debian-live-11.9.0-amd64-lxde.iso          |    O    |    O    |    -    | "                                         |
|              | debian-live-12.5.0-amd64-lxde.iso          |    O    |    O    |    -    | "                                         |
|              | debian-live-testing-amd64-lxde.iso         |    O    |    O    |    -    | "                                         |
|              | ubuntu-20.04.6-desktop-amd64.iso           |    O    |    X    |    -    | Unable to start live mode                 |
|              | ubuntu-22.04.4-desktop-amd64.iso           |    O    |    X    |    -    | "                                         |
|              | ubuntu-23.10.1-desktop-amd64.iso           |    O    |    O    |    -    | No special mention                        |
|              | ubuntu-24.04-desktop-amd64.iso             |    O    |    X    |    -    | Unable to start live mode                 |
|              | ubuntu-23.10-desktop-legacy-amd64.iso      |    O    |    O    |    -    | No special mention                        |
| System tools | mt86plus_7.00_64.grub.iso                  |    O    |    O    |    -    | No special mention                        |
|              | WinPEx64.iso                               |    O    |    X    |    -    | Hang on boot                              |
|              | WinPE_ATI2020x64.iso                       |    O    |    O    |    -    | No special mention                        |
|              | WinPE_ATI2020x86.iso                       |    O    |    O    |    -    | "                                         |
  
## Note  
  
･Live mode minimum memory is 8GiB  
･pxeboot is very slow and transfer speed is around 1.9MiB/s  
  
## tree diagram
  
```bash:
~/share/
|-- conf ---------------------- configuration file
|   |-- _template
|   |-- autoyast
|   |-- kickstart
|   |-- nocloud
|   `-- preseed
|-- html ---------------------- html contents
|   |-- conf -> ../conf
|   |-- imgs -> ../imgs
|   |-- isos -> ../isos
|   `-- rmak -> ../rmak
|-- imgs ---------------------- iso file extraction destination
|-- isos ---------------------- iso file
|-- rmak ---------------------- remake file
|-- temp ---------------------- temporary directory
`-- tftp ---------------------- tftp contents
    |-- boot
    |   `-- grub
    |       |-- grub.cfg ------ menu base
    |       |-- menu.cfg ------ menu file
    |       |-- fonts
    |       |   `-- unicode.pf2
    |       |-- i386-pc
    |       |   `-- pxelinux.0 --- bootloader
    |       |-- locale
    |       `-- x86_64-efi
    |           `-- bootx64.efi -- bootloader
    |-- menu-bios
    |   |-- syslinux.cfg ------ syslinux configuration for mbr environment
    |   |-- boot -> ../load
    |   `-- pxelinux.cfg
    |       `-- default -> ../syslinux.cfg
    |-- menu-efi64
    |   |-- syslinux.cfg ------ syslinux configuration for uefi(x86_64) environment
    |   |-- boot -> ../load
    |   `-- pxelinux.cfg
    |       `-- default -> ../syslinux.cfg
    |-- load ------------------ load module
    |-- imgs -> ../imgs
    |-- isos -> ../isos
    `-- rmak -> ../rmak
/var/tftp/ -> ~/share/tftp
/var/www/
`-- html -> ~/share/html
```
  
