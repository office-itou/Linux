# **test result**

## **media**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |                                    memo                                    |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------------------------------------------------- |
| debian-12.13.0       |     o     |     o     |     o     |     o     |     -     |                                                                            |
| debian-13.3.0        |     o     |     o     |     o     |     o     |     -     |                                                                            |
| debian-14            |     x     |     -     |     -     |     -     |     -     | kernel version mismatch error                                              |
| debian-15            |     -     |     -     |     -     |     -     |     -     | unreleased                                                                 |
| debian-testing       |     x     |     o     |     o     |     o     |     -     | kernel version mismatch error                                              |
| debian-testing-daily |     o     |     -     |     -     |     -     |     -     |                                                                            |
| ubuntu-24.04.3       |     -     |     -     |     o     |     o     |     -     |                                                                            |
| ubuntu-25.10         |     -     |     -     |     o     |     o     |     -     |                                                                            |
| ubuntu-26.04 (snap3) |     -     |     -     |     x     |     x     |     -     | system-install error                                                       |
| fedora-43            |     -     |     o     |     o     |     -     |     -     | systemd-timesyncd not install                                              |
| centos-stream-9      |     -     |     o     |     o     |     -     |     -     |                                                                            |
| centos-stream-10     |     -     |     o     |     o     |     -     |     -     |                                                                            |
| almalinux-9.7        |     -     |     o     |     o     |     -     |     -     |                                                                            |
| almalinux-10.1       |     -     |     o     |     o     |     -     |     -     |                                                                            |
| rockylinux-9.7       |     -     |     o     |     o     |     -     |     -     |                                                                            |
| rockylinux-10.1      |     -     |     o     |     o     |     -     |     -     |                                                                            |
| miraclelinux-9.6     |     -     |     o     |     x     |     -     |     -     | caution hostname length / clamav version mismatch error                    |
| opensuse-leap-15.6   |     -     |     o     |     o     |     -     |     -     |                                                                            |
| opensuse-leap-16.0   |     -     |     x     |     x     |     -     |     -     | selinux bug (systemd-resolved)                                             |
| opensuse-tumbleweed  |     -     |     x     |     x     |     -     |     -     | selinux bug (systemd-resolved)                                             |
| windows-10-22h2      |     -     |     -     |     =     |     -     |     -     |                                                                            |
| windows-11-25h2      |     -     |     -     |     =     |     -     |     -     |                                                                            |
| memtest86plus        |     -     |     -     |     =     |     -     |     -     |                                                                            |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     |                                                                            |
| winpe-x64            |     -     |     -     |     =     |     -     |     -     |                                                                            |
| ati2020x86           |     -     |     -     |     =     |     -     |     -     |                                                                            |
| ati2020x64           |     -     |     -     |     =     |     -     |     -     |                                                                            |

## **pxeboot (ipxe)**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |                                    memo                                    |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------------------------------------------------- |
| debian-12.13.0       |     o     |     =     |     =     |     =     |     o     |                                                                            |
| debian-13.3.0        |     o     |     =     |     =     |     =     |     o     |                                                                            |
| debian-14            |     x     |     -     |     -     |     -     |     -     | kernel version mismatch error                                              |
| debian-15            |     -     |     -     |     -     |     -     |     -     | unreleased                                                                 |
| debian-testing       |     x     |     =     |     =     |     =     |     o     | kernel version mismatch error                                              |
| debian-testing-daily |     o     |     -     |     -     |     -     |     -     |                                                                            |
| ubuntu-24.04.3       |     -     |     -     |     o     |     o     |     -     | desktop requires 12GiB or more                                             |
| ubuntu-25.10         |     -     |     -     |     o     |     o     |     -     | desktop requires 12GiB or more                                             |
| ubuntu-26.04 (snap3) |     -     |     -     |     x     |     x     |     -     | system-install error                                                       |
| fedora-43            |     -     |     o     |     o     |     -     |     -     |                                                                            |
| centos-stream-9      |     -     |     o     |     o     |     -     |     -     |                                                                            |
| centos-stream-10     |     -     |     o     |     o     |     -     |     -     |                                                                            |
| almalinux-9.7        |     -     |     o     |     o     |     -     |     -     |                                                                            |
| almalinux-10.1       |     -     |     o     |     o     |     -     |     -     |                                                                            |
| rockylinux-9.7       |     -     |     o     |     o     |     -     |     -     |                                                                            |
| rockylinux-10.1      |     -     |     o     |     o     |     -     |     -     |                                                                            |
| miraclelinux-9.6     |     -     |     o     |     x     |     -     |     -     | caution hostname length / clamav version mismatch error                    |
| opensuse-leap-15.6   |     -     |     o     |     o     |     -     |     -     |                                                                            |
| opensuse-leap-16.0   |     -     |     x     |     x     |     -     |     -     | selinux bug (systemd-resolved)                                             |
| opensuse-tumbleweed  |     -     |     x     |     o     |     -     |     -     | an unknown error occurred                                                  |
| windows-10-22h2      |     -     |     -     |     o     |     -     |     -     |                                                                            |
| windows-11-25h2      |     -     |     -     |     o     |     -     |     -     |                                                                            |
| memtest86plus        |     -     |     -     |     o     |     -     |     -     |                                                                            |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     | not created                                                                |
| winpe-x64            |     -     |     -     |     o     |     -     |     -     |                                                                            |
| ati2020x86           |     -     |     -     |     o     |     -     |     -     |                                                                            |
| ati2020x64           |     -     |     -     |     o     |     -     |     -     |                                                                            |

## **pxeboot (syslinux)**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |                                    memo                                    |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------------------------------------------------- |
| debian-12            |     ･     |     ･     |     ･     |     ･     |     ･     |                                                                            |
| debian-13            |     ･     |     ･     |     ･     |     ･     |     ･     |                                                                            |
| debian-14            |     ･     |     -     |     -     |     -     |     -     |                                                                            |
| debian-15            |     -     |     -     |     -     |     -     |     -     | unreleased                                                                 |
| debian-testing       |     ･     |     ･     |     ･     |     ･     |     ･     |                                                                            |
| ubuntu-24.04         |     -     |     -     |     ･     |     ･     |     -     |                                                                            |
| ubuntu-25.10         |     -     |     -     |     ･     |     ･     |     -     |                                                                            |
| ubuntu-26.04         |     -     |     -     |     ･     |     ･     |     -     |                                                                            |
| fedora-43            |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| centos-stream-9      |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| centos-stream-10     |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| almalinux-9          |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| almalinux-10         |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| rockylinux-9         |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| rockylinux-10        |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| miraclelinux-9       |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| opensuse-leap-15.6   |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| opensuse-leap-16     |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| opensuse-tumbleweed  |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| windows-10-22h2      |     -     |     -     |     =     |     -     |     -     |                                                                            |
| windows-11-25h2      |     -     |     -     |     =     |     -     |     -     |                                                                            |
| memtest86plus        |     -     |     -     |     =     |     -     |     -     |                                                                            |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     |                                                                            |
| winpe-x64            |     -     |     -     |     =     |     -     |     -     |                                                                            |
| ati2020x86           |     -     |     -     |     =     |     -     |     -     |                                                                            |
| ati2020x64           |     -     |     -     |     =     |     -     |     -     |                                                                            |

## **pxeboot (grub)**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |                                    memo                                    |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------------------------------------------------- |
| debian-12            |     ･     |     ･     |     ･     |     ･     |     ･     |                                                                            |
| debian-13            |     ･     |     ･     |     ･     |     ･     |     ･     |                                                                            |
| debian-14            |     ･     |     -     |     -     |     -     |     -     |                                                                            |
| debian-15            |     -     |     -     |     -     |     -     |     -     | unreleased                                                                 |
| debian-testing       |     ･     |     ･     |     ･     |     ･     |     ･     |                                                                            |
| ubuntu-24.04         |     -     |     -     |     ･     |     ･     |     -     |                                                                            |
| ubuntu-25.10         |     -     |     -     |     ･     |     ･     |     -     |                                                                            |
| ubuntu-26.04         |     -     |     -     |     ･     |     ･     |     -     |                                                                            |
| fedora-43            |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| centos-stream-9      |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| centos-stream-10     |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| almalinux-9          |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| almalinux-10         |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| rockylinux-9         |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| rockylinux-10        |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| miraclelinux-9       |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| opensuse-leap-15.6   |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| opensuse-leap-16     |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| opensuse-tumbleweed  |     -     |     ･     |     ･     |     -     |     -     |                                                                            |
| windows-10-22h2      |     -     |     -     |     =     |     -     |     -     |                                                                            |
| windows-11-25h2      |     -     |     -     |     =     |     -     |     -     |                                                                            |
| memtest86plus        |     -     |     -     |     =     |     -     |     -     |                                                                            |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     |                                                                            |
| winpe-x64            |     -     |     -     |     =     |     -     |     -     |                                                                            |
| ati2020x86           |     -     |     -     |     =     |     -     |     -     |                                                                            |
| ati2020x64           |     -     |     -     |     =     |     -     |     -     |                                                                            |
