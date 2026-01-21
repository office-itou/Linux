# **test result**

## **media**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |               memo               |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------- |
| debian-12            |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-13            |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-14            |     ･     |     -     |     -     |     -     |     -     |                                  |
| debian-15            |     -     |     -     |     -     |     -     |     -     |                                  |
| debian-testing       |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-testing-daily |     ･     |     -     |     -     |     -     |     -     |                                  |
| ubuntu-24.04         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| ubuntu-25.04         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| ubuntu-25.10         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| fedora-43            |     -     |     ･     |     ･     |     -     |     -     |                                  |
| centos-stream-9      |     -     |     ･     |     ･     |     -     |     -     |                                  |
| centos-stream-10     |     -     |     ･     |     ･     |     -     |     -     |                                  |
| almalinux-9          |     -     |     ･     |     ･     |     -     |     -     |                                  |
| almalinux-10         |     -     |     ･     |     ･     |     -     |     -     |                                  |
| rockylinux-9         |     -     |     ･     |     ･     |     -     |     -     |                                  |
| rockylinux-10        |     -     |     ･     |     ･     |     -     |     -     |                                  |
| miraclelinux-9       |     -     |     ･     |     ･     |     -     |     -     |                                  |
| opensuse-leap-16     |     -     |     ･     |     ･     |     -     |     -     |                                  |
| opensuse-tumbleweed  |     -     |     ･     |     ･     |     -     |     -     |                                  |
| windows-10-22h2      |     -     |     -     |     =     |     -     |     -     |                                  |
| windows-11-25h2      |     -     |     -     |     =     |     -     |     -     |                                  |
| memtest86plus        |     -     |     -     |     =     |     -     |     -     |                                  |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     |                                  |
| winpe-x64            |     -     |     -     |     =     |     -     |     -     |                                  |
| ati2020x86           |     -     |     -     |     =     |     -     |     -     |                                  |
| ati2020x64           |     -     |     -     |     =     |     -     |     -     |                                  |

## **pxeboot (ipxe)**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |               memo               |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------- |
| debian-12            |     o     |     =     |     =     |     =     |     o     |                                  |
| debian-13            |     o     |     =     |     =     |     =     |     o     |                                  |
| debian-14            |     x     |     -     |     -     |     -     |     -     | kernel version mismatch error    |
| debian-15            |     -     |     -     |     -     |     -     |     -     | unreleased                       |
| debian-testing       |     x     |     =     |     =     |     =     |     o     | kernel version mismatch error    |
| debian-testing-daily |     o     |     -     |     -     |     -     |     -     |                                  |
| ubuntu-24.04         |     -     |     -     |     o     |     x     |     -     | out of memory at 8GiB            |
| ubuntu-25.04         |     -     |     -     |     o     |     x     |     -     | out of memory at 8GiB            |
| ubuntu-25.10         |     -     |     -     |     o     |     x     |     -     | out of memory at 8GiB            |
| fedora-43            |     -     |     o     |     o     |     -     |     -     |                                  |
| centos-stream-9      |     -     |     o     |     ･     |     -     |     -     |                                  |
| centos-stream-10     |     -     |     o     |     ･     |     -     |     -     |                                  |
| almalinux-9          |     -     |     o     |     ･     |     -     |     -     |                                  |
| almalinux-10         |     -     |     o     |     ･     |     -     |     -     |                                  |
| rockylinux-9         |     -     |     o     |     ･     |     -     |     -     |                                  |
| rockylinux-10        |     -     |     o     |     ･     |     -     |     -     |                                  |
| miraclelinux-9       |     -     |     o     |     ･     |     -     |     -     |                                  |
| opensuse-leap-16     |     -     |     o     |     ･     |     -     |     -     |                                  |
| opensuse-tumbleweed  |     -     |     x     |     x     |     -     |     -     | network device not working       |
| windows-10-22h2      |     -     |     -     |     o     |     -     |     -     |                                  |
| windows-11-25h2      |     -     |     -     |     o     |     -     |     -     |                                  |
| memtest86plus        |     -     |     -     |     o     |     -     |     -     |                                  |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     | not created                      |
| winpe-x64            |     -     |     -     |     o     |     -     |     -     |                                  |
| ati2020x86           |     -     |     -     |     o     |     -     |     -     |                                  |
| ati2020x64           |     -     |     -     |     o     |     -     |     -     |                                  |

## **pxeboot (syslinux)**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |               memo               |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------- |
| debian-12            |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-13            |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-14            |     ･     |     -     |     -     |     -     |     -     |                                  |
| debian-15            |     -     |     -     |     -     |     -     |     -     |                                  |
| debian-testing       |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| ubuntu-24.04         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| ubuntu-25.04         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| ubuntu-25.10         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| fedora-43            |     -     |     ･     |     ･     |     -     |     -     |                                  |
| centos-stream-9      |     -     |     ･     |     ･     |     -     |     -     |                                  |
| centos-stream-10     |     -     |     ･     |     ･     |     -     |     -     |                                  |
| almalinux-9          |     -     |     ･     |     ･     |     -     |     -     |                                  |
| almalinux-10         |     -     |     ･     |     ･     |     -     |     -     |                                  |
| rockylinux-9         |     -     |     ･     |     ･     |     -     |     -     |                                  |
| rockylinux-10        |     -     |     ･     |     ･     |     -     |     -     |                                  |
| miraclelinux-9       |     -     |     ･     |     ･     |     -     |     -     |                                  |
| opensuse-leap-16     |     -     |     ･     |     ･     |     -     |     -     |                                  |
| opensuse-tumbleweed  |     -     |     ･     |     ･     |     -     |     -     |                                  |
| windows-10-22h2      |     -     |     -     |     =     |     -     |     -     |                                  |
| windows-11-25h2      |     -     |     -     |     =     |     -     |     -     |                                  |
| memtest86plus        |     -     |     -     |     =     |     -     |     -     |                                  |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     |                                  |
| winpe-x64            |     -     |     -     |     =     |     -     |     -     |                                  |
| ati2020x86           |     -     |     -     |     =     |     -     |     -     |                                  |
| ati2020x64           |     -     |     -     |     =     |     -     |     -     |                                  |

## **pxeboot (grub)**

|     distribution     |   mini    |  netinst  |    dvd    | liveinst  |   live    |               memo               |
| :------------------- | :-------: | :-------: | :-------: | :-------: | :-------: | :------------------------------- |
| debian-12            |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-13            |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| debian-14            |     ･     |     -     |     -     |     -     |     -     |                                  |
| debian-15            |     -     |     -     |     -     |     -     |     -     |                                  |
| debian-testing       |     ･     |     ･     |     ･     |     ･     |     ･     |                                  |
| ubuntu-24.04         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| ubuntu-25.04         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| ubuntu-25.10         |     -     |     -     |     ･     |     ･     |     -     |                                  |
| fedora-43            |     -     |     ･     |     ･     |     -     |     -     |                                  |
| centos-stream-9      |     -     |     ･     |     ･     |     -     |     -     |                                  |
| centos-stream-10     |     -     |     ･     |     ･     |     -     |     -     |                                  |
| almalinux-9          |     -     |     ･     |     ･     |     -     |     -     |                                  |
| almalinux-10         |     -     |     ･     |     ･     |     -     |     -     |                                  |
| rockylinux-9         |     -     |     ･     |     ･     |     -     |     -     |                                  |
| rockylinux-10        |     -     |     ･     |     ･     |     -     |     -     |                                  |
| miraclelinux-9       |     -     |     ･     |     ･     |     -     |     -     |                                  |
| opensuse-leap-16     |     -     |     ･     |     ･     |     -     |     -     |                                  |
| opensuse-tumbleweed  |     -     |     ･     |     ･     |     -     |     -     |                                  |
| windows-10-22h2      |     -     |     -     |     =     |     -     |     -     |                                  |
| windows-11-25h2      |     -     |     -     |     =     |     -     |     -     |                                  |
| memtest86plus        |     -     |     -     |     =     |     -     |     -     |                                  |
| winpe-x86            |     -     |     -     |     =     |     -     |     -     |                                  |
| winpe-x64            |     -     |     -     |     =     |     -     |     -     |                                  |
| ati2020x86           |     -     |     -     |     =     |     -     |     -     |                                  |
| ati2020x64           |     -     |     -     |     =     |     -     |     -     |                                  |
