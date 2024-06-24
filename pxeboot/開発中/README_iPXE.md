# **PXEBOOT (iPXE)**  
  
## Result  
  
| Media        | File name                                  | kernel  | Looding | Booting | Install | Note                                       |
| ------------ | ------------------------------------------ | ------- | :-----: | :-----: | :-----: | ------------------------------------------ |
| mini.iso     | mini-buster-amd64.iso                      | 4.19.0  |    O    |    X    |    -    | Crash during startup                       |
|              | mini-bullseye-amd64.iso                    | 5.10.0  |    O    |    O    |    O    | Network installation only                  |
|              | mini-bookworm-amd64.iso                    | 6.1.0   |    O    |    O    |    O    | "                                          |
|              | mini-trixie-amd64.iso                      | 6.1.0   |    -    |    -    |    -    | Kernel module mismatch                     |
|              | mini-testing-amd64.iso                     | 6.8.12  |    O    |    O    |    O    | Network installation only                  |
|              | mini-bionic-amd64.iso                      | 4.15.0  |    O    |    X    |    -    | Crash during startup                       |
|              | mini-focal-amd64.iso                       | 5.4.0   |    O    |    X    |    -    | "                                          |
| Net install  | debian-10.13.0-amd64-netinst.iso           | 4.19.0  |    O    |    X    |    -    | Crash during startup                       |
|              | debian-11.9.0-amd64-netinst.iso            | 5.10.0  |    O    |    O    |    X    | Unable to detect media                     |
|              | debian-12.5.0-amd64-netinst.iso            | 6.1.0   |    O    |    O    |    X    | "                                          |
|              | debian-testing-amd64-netinst.iso           | 6.8.12  |    O    |    O    |    X    | "                                          |
|              | Fedora-Server-netinst-x86_64-39-1.5.iso    | 6.5.6   |    O    |    O    |    O    | No special mention                         |
|              | Fedora-Server-netinst-x86_64-40-1.14.iso   | 6.8.5   |    O    |    O    |    O    | "                                          |
|              | CentOS-Stream-9-latest-x86_64-boot.iso     | 5.14.0  |    O    |    O    |    O    | "                                          |
|              | AlmaLinux-9-latest-x86_64-boot.iso         | 5.14.0  |    O    |    O    |    O    | "                                          |
|              | Rocky-8.9-x86_64-boot.iso                  | 4.18.0  |    O    |    X    |    -    | Crash during startup                       |
|              | Rocky-9-latest-x86_64-boot.iso             | 5.14.0  |    O    |    O    |    O    | No special mention                         |
|              | MIRACLELINUX-8.8-rtm-minimal-x86_64.iso    | 4.18.0  |    O    |    X    |    -    | Crash during startup                       |
|              | MIRACLELINUX-9.2-rtm-minimal-x86_64.iso    | 5.14.0  |    O    |    O    |    O    | No special mention                         |
|              | openSUSE-Leap-15.5-NET-x86_64-Media.iso    | 5.14.21 |    O    |    O    |    O    | No special mention                         |
|              | openSUSE-Leap-15.6-NET-x86_64-Media.iso    | 6.4.0   |    O    |    O    |    O    | "                                          |
|              | openSUSE-Tumbleweed-NET-x86_64-Current.iso | 6.9.5   |    O    |    O    |    O    | "                                          |
| DVD          | debian-10.13.0-amd64-DVD-1.iso             | 4.19.0  |    O    |    X    |    -    | Crash during startup                       |
|              | debian-11.9.0-amd64-DVD-1.iso              | 5.10.0  |    O    |    O    |    X    | Unable to detect media                     |
|              | debian-12.5.0-amd64-DVD-1.iso              | 6.1.0   |    O    |    O    |    X    | "                                          |
|              | debian-testing-amd64-DVD-1.iso             | 6.8.12  |    O    |    O    |    X    | "                                          |
|              | ubuntu-18.04.6-server-amd64.iso            | 4.15.0  |    O    |    X    |    -    | Crash during startup                       |
|              | ubuntu-18.04.6-live-server-amd64.iso       | 4.15.0  |    O    |    X    |    -    | "                                          |
|              | ubuntu-20.04.6-live-server-amd64.iso       | 5.4.0   |    O    |    X    |    -    | "                                          |
|              | ubuntu-22.04.4-live-server-amd64.iso       | 5.15.0  |    O    |    X    |    -    | Hangs during startup                       |
|              | ubuntu-23.10-live-server-amd64.iso         | 6.5.0   |    O    |    O    |    O    | No special mention                         |
|              | ubuntu-24.04-live-server-amd64.iso         | 6.8.0   |    O    |    O    |    O    | "                                          |
|              | oracular-live-server-amd64.iso             | 6.8.0   |    O    |    O    |    O    | "                                          |
|              | Fedora-Server-dvd-x86_64-39-1.5.iso        | 6.5.6   |    O    |    O    |    O    | No special mention                         |
|              | Fedora-Server-dvd-x86_64-40-1.14.iso       | 6.8.5   |    O    |    O    |    O    | "                                          |
|              | CentOS-Stream-9-latest-x86_64-dvd1.iso     | 5.14.0  |    O    |    O    |    ?    | "                                          |
|              | AlmaLinux-9-latest-x86_64-dvd.iso          | 5.14.0  |    O    |    O    |    O    | "                                          |
|              | Rocky-8.9-x86_64-dvd1.iso                  | 4.18.0  |    O    |    X    |    -    | Crash during startup                       |
|              | Rocky-9-latest-x86_64-dvd.iso              | 5.14.0  |    O    |    O    |    O    | No special mention                         |
|              | MIRACLELINUX-8.8-rtm-x86_64.iso            | 4.18.0  |    O    |    X    |    -    | Crash during startup                       |
|              | MIRACLELINUX-9.2-rtm-x86_64.iso            | 5.14.0  |    O    |    O    |    O    | No special mention                         |
|              | openSUSE-Leap-15.5-DVD-x86_64-Media.iso    | 5.14.21 |    O    |    O    |    O    | No special mention                         |
|              | openSUSE-Leap-15.6-DVD-x86_64-Media.iso    | 6.4.0   |    O    |    O    |    O    | "                                          |
|              | openSUSE-Tumbleweed-DVD-x86_64-Current.iso | 6.9.5   |    O    |    O    |    O    | "                                          |
|              | Win10_22H2_Japanese_x64.iso                |    -    |    O    |    O    |    O    | samba connection requires manual operation |
|              | Win11_23H2_Japanese_x64v2_custom.iso       |    -    |    O    |    O    |    O    | "                                          |
| Live DVD     | debian-live-10.13.0-amd64-lxde.iso         | 4.19.0  |    O    |    X    |    -    | Crash during startup                       |
|              | debian-live-11.9.0-amd64-lxde.iso          | 5.10.0  |    O    |    O    |    X    | Unable to detect media                     |
|              | debian-live-12.5.0-amd64-lxde.iso          | 6.1.0   |    O    |    O    |    X    | "                                          |
|              | debian-live-testing-amd64-lxde.iso         | 6.7.12  |    O    |    O    |    X    | "                                          |
|              | ubuntu-20.04.6-desktop-amd64.iso           | 5.15.0  |    O    |    O    |    X    | Unable to detect media                     |
|              | ubuntu-22.04.4-desktop-amd64.iso           | 6.5.0   |    O    |    O    |    X    | "                                          |
|              | ubuntu-23.10.1-desktop-amd64.iso           | 6.5.0   |    O    |    O    |    O    | Minimum memory is 8GiB                     |
|              | ubuntu-24.04-desktop-amd64.iso             | 6.8.0   |    O    |    O    |    X    | Unable to start install mode               |
|              | ubuntu-23.10-desktop-legacy-amd64.iso      | 6.5.0   |    O    |    O    |    O    | No special mention                         |
|              | oracular-desktop-amd64.iso                 | 6.8.0   |    O    |    O    |    X    | Hangs during install                       |
| Live mode    | debian-live-10.13.0-amd64-lxde.iso         | 4.19.0  |    O    |    X    |    -    | Crash during startup                       |
|              | debian-live-11.9.0-amd64-lxde.iso          | 5.10.0  |    O    |    O    |    -    | Boot of live mode                          |
|              | debian-live-12.5.0-amd64-lxde.iso          | 6.1.0   |    O    |    O    |    -    | "                                          |
|              | debian-live-testing-amd64-lxde.iso         | 6.7.12  |    O    |    O    |    -    | "                                          |
|              | ubuntu-20.04.6-desktop-amd64.iso           | 5.15.0  |    O    |    -    |    -    | Unable to detect media                     |
|              | ubuntu-22.04.4-desktop-amd64.iso           | 6.5.0   |    O    |    -    |    -    | "                                          |
|              | ubuntu-23.10.1-desktop-amd64.iso           | 6.5.0   |    O    |    O    |    -    | Boot of live mode                          |
|              | ubuntu-24.04-desktop-amd64.iso             | 6.8.0   |    O    |    O    |    -    | Unable to start live mode                  |
|              | ubuntu-23.10-desktop-legacy-amd64.iso      | 6.5.0   |    O    |    O    |    -    | Minimum memory is 8GiB                     |
|              | oracular-desktop-amd64.iso                 | 6.8.0   |    O    |    O    |    -    | "                                          |
| System tools | mt86plus_7.00_64.grub.iso                  |    -    |    O    |    O    |    -    | No special mention                         |
|              | WinPEx64.iso                               |    -    |    O    |    O    |    -    | "                                          |
|              | WinPE_ATI2020x64.iso                       |    -    |    O    |    O    |    -    | "                                          |
|              | WinPE_ATI2020x86.iso                       |    -    |    O    |    O    |    -    | "                                          |
  
Note:  
* Ubuntu Desktop minimum memory is 8GiB  
  
