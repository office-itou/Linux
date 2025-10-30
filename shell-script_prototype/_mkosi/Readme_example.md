# **Mkosi example**

## **Build custom OS image**

* Ubuntu 25.10 questing

  * Device usage and tree diagram

    ``` bash:
    $ sudo du -schP $PWD/.workdirs/ubuntu-25.10/
    3.4G    $PWD/.workdirs/ubuntu-25.10/
    3.4G    total
    $ tree --charset C -n --filesfirst -a -L 1 $PWD/.workdirs/ubuntu-25.10/
    $PWD/.workdirs/ubuntu-25.10/
    |-- rootfs.efi
    |-- rootfs.initrd
    |-- rootfs.vmlinuz
    `-- rootfs
    ```

  * Build in the image directory

    ``` bash:
    $ sudo rm -rf $PWD/.workdirs/ubuntu-25.10/
    $ sudo mkosi \
      --force \
      --wipe-build-dir \
      --architecture=x86-64 \
      --root-password=r00t \
      --bootable=yes \
      --bootloader=systemd-boot \
      --format=directory \
      --output=rootfs \
      --output-directory=$PWD/.workdirs/ubuntu-25.10/ \
      --cache-directory=/srv/user/share/cache/ubuntu-25.10/ \
      --distribution=ubuntu \
      --release=questing \
      --repositories=main,restricted,universe,multiverse \
      --package=ubuntu-minimal,ubuntu-standard,systemd-boot-efi,linux-image-generic,linux-firmware
    ```

  * Execution in the image directory

    ``` bash:
    $ sudo mkosi \
      --format=directory \
      --output=rootfs \
      --directory=$PWD/.workdirs/ubuntu-25.10/ \
      --qemu-smp 2 \
      qemu
    ```

## **reference**

* [ArchWiki](https://wiki.archlinux.jp)

  * [Mkosi](https://wiki.archlinux.org/title/Mkosi)
  * [QEMU](https://wiki.archlinux.jp/index.php/QEMU)

* [Debian Manpages](https://manpages.debian.org)

  * [Mkosi](https://manpages.debian.org/trixie/mkosi/mkosi.1.en.html)
  * [QEMU](https://manpages.debian.org/trixie/qemu-system-x86/qemu-system-amd64.1.en.html)

* Packages Search

  * [Debian](https://packages.debian.org/ja/)
  * [Ubuntu](https://packages.ubuntu.com)

## **Environment**

* VMware

  * VMware Workstation 17 Pro (17.6.4 build-24832109)

* Server

  * Virtual-PC

    |    Device   |        Summary        |
    | :---------: | :-------------------- |
    | Processor   | Core 1 / Processor 2  |
    | Memory      | 4GiB                  |
    | Storage     | NVMe 64GiB            |
    | Network     | e1000e                |
    | Sound       | hdaudio               |

  * Base OS

    ``` bash:
    $ cat /etc/os-release
    PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
    NAME="Debian GNU/Linux"
    VERSION_ID="13"
    VERSION="13 (trixie)"
    VERSION_CODENAME=trixie
    DEBIAN_VERSION_FULL=13.1
    ID=debian
    HOME_URL="https://www.debian.org/"
    SUPPORT_URL="https://www.debian.org/support"
    BUG_REPORT_URL="https://bugs.debian.org/"
    ```
