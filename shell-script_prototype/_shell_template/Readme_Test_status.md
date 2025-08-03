# **Test results for DVD media and PXEboot installation**

## **Updated: 2025/xx/xx**

|           version           | iso mini| iso net | iso dvd | iso live| pxe mini| pxe net | pxe dvd | pxe live| life |  release   |support end | long term  |    rhel    |         kerne         |        code name         |
| :-------------------------- | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :--: | :--------: | :--------: | :--------: | :--------: | :-------------------- | :----------------------- |
|  Debian-12.0 (12.11.0)      |    O    |    O    |    -    |    -    |    O    |    X    |    X    |    O    |      | 2023/06/10 | 2026/06/xx | 2028/06/xx |            | 6.1                   | Bookworm (stable)        |
|  Debian-13.0 (RC2)          |    K    |    O    |    -    |    -    |    K    |    X    |    X    |    -    |      | 2025/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Trixie   (testing)       |
| _Debian-14.0_               |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2027/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Forky                    |
| _Debian-15.0_               |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Duke                     |
|  Debian-testing             |    K    |    -    |    -    |    -    |    K    |    X    |    X    |    O    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Testing                  |
|  Debian-testing (daily)     |    O    |    -    |    -    |    -    |    O    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Testing (daily build)    |
|  Debian-sid                 |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | SID                      |
|  Ubuntu-24.04 (24.04.2)     |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    O    |      | 2024/04/25 | 2029/05/31 | 2034/04/25 |            | 6.8                   | Noble Numbat             |
|  Ubuntu-24.10 (24.10)       |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    O    |      | 2024/10/10 | 2025/07/xx |            |            | 6.11                  | Oracular Oriole          |
|  Ubuntu-25.04 (25.04)       |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    O    |      | 2025/04/17 | 2026/01/xx |            |            | 6.14                  | Plucky Puffin            |
|  Ubuntu-25.10 (Develop)     |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    X    |      | 2025/10/09 | 2026/07/xx |            |            |                       | Questing Quokka          |
|  Fedora-42                  |    -    |    -    |    -    |    -    |    -    |    O    |    -    |    -    |      | 2025/04/15 | 2026/05/13 |            |            | 6.14                  |                          |
| _Fedora-43_                 |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2025/11/11 | 2026/12/02 |            |            |                       |                          |
|  CentOS Stream-9            |    -    |    -    |    -    |    -    |    -    |    O    |    -    |    -    |      | 2021/12/03 | 2027/05/31 |            |            | 5.14.0                |                          |
|  CentOS Stream-10           |    -    |    -    |    -    |    -    |    -    |    3    |    -    |    -    |      | 2024/12/12 | 2030/05/31 |            |            | 6.12.0                | Coughlan                 |
|  AlmaLinux-9.6              |    -    |    -    |    -    |    -    |    -    |    O    |    -    |    -    |      | 2025/05/20 |            |            | 2025/05/20 | 5.14.0-570.12.1       | Sage Margay              |
|  AlmaLinux-10.0             |    -    |    -    |    -    |    -    |    -    |    3    |    -    |    -    |      | 2025/05/27 |            |            | 2025/05/13 | 6.12.0-55.9.1         | Purple Lion              |
|  Rocky Linux-9.6            |    -    |    -    |    -    |    -    |    -    |    O    |    -    |    -    |      | 2025/06/04 |            |            | 2025/05/20 | 5.14.0-570.17.1       | Blue Onyx                |
|  Rocky Linux-10.0           |    -    |    -    |    -    |    -    |    -    |    3    |    -    |    -    |      | 2025/06/11 |            |            | 2025/05/20 | 6.12.0-55.12.1        | Red Quartz               |
|  Miracle Linux-9.6          |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2025/07/xx |            |            | 2025/xx/xx | 5.14.0-570.16.1.el9_6 | Feige                    |
|  openSUSE-15.6              |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2024/06/12 | 2025/12/31 |            |            | 6.4                   |                          |
|  openSUSE-16.0 (Beta)       |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2025/10/xx | 20xx/xx/xx |            |            | 6.12                  |                          |
|  openSUSE-tumbleweed        |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2014/11/xx | 20xx/xx/xx |            |            |                       |                          |
|  Windows-10 (22h2)          |    -    |    -    |    -    |    -    |    -    |    -    |    O    |    -    |      | 2022/10/18 | 2025/10/14 |            |            |                       |                          |
|  Windows-11 (24h2)          |    -    |    -    |    -    |    -    |    -    |    -    |    O    |    -    |      | 2024/10/01 | 2026/10/13 |            |            |                       |                          |
|  memtest86plus-7.20         |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    O    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                          |
|  WinPE-x64                  |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    O    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                          |
|~~WinPE-x86~~                |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                          |
|  ATI2020x64 (WinPE-64bit)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    O    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                          |
|  ATI2020x86 (WinPE-32bit)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                          |

| media |        edition        |
| :---: | :-------------------- |
| mini  | mini.iso              |
| net   | net install           |
| dvd   | server                |
| live  | desktop or live media |

| mark |               status                         |
| :--: | :------------------------------------------- |
|  O   | OK                                           |
|  X   | NG (Installation cannot continue)            |
|  K   | Kernel version difference                    |
|  3   | Not compatible with 3D graphics acceleration |
|  -   | Excluded                                     |
|  *   | Depends on H/W configuration                 |

## **PXEboot server**

``` bash:
~$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

## **VMware**

|      Device      |  server  |  client  |
| :--------------- | :------: | :------: |
| Core/Processor   |  1 / 2   |  1 / 2   |
| Memory           |  8 GiB   |  8 GiB   |
| NVMe 1           |  64 GiB  |  64 GiB  |
| NVMe 2           | 250 GiB  |    -     |
| CD/DVD (SATA)    |   Yes    |   Yes    |
| Network (Bridge) | vmxnet3  |  e1000e  |
| USB controller   | USB 3.1  | USB 3.1  |
| Sound card       |    -     | hdaudio  |
| Display          |   3D     |   3D     |
| Bluetooth        |    -     |   Yes    |
