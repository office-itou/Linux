# **machine spec**

## **distribution**

``` bash
$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.2
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

## **vmware**

``` bash:
$ LANG=C vmware-checkvm
VMware software version 6 (good)
```

## **cpu**

``` bash:
$ lscpu -e=SOCKET,CPU,CORE,MODELNAME
SOCKET CPU CORE MODELNAME
     0   0    0 Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz
     0   1    1 Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz
  ```

## **memory**

``` bash:
$ LANG=C lsmem
RANGE                                 SIZE  STATE REMOVABLE BLOCK
0x0000000000000000-0x00000000bfffffff   3G online       yes  0-23
0x0000000100000000-0x000000023fffffff   5G online       yes 32-71

Memory block size:                128M
Total online memory:                8G
Total offline memory:               0B
```

## **storage**

* **sv-server**

  ``` bash:
  $ LANG=C lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS,FSSIZE,FSUSED,FSUSE%
  NAME                       SIZE TYPE MOUNTPOINTS    FSSIZE FSUSED FSUSE%
  sr0                       1024M rom
  nvme0n1                     64G disk
  |-nvme0n1p1                976M part /boot/efi      974.1M   8.8M     1%
  |-nvme0n1p2                977M part /boot          943.2M  74.6M     8%
  `-nvme0n1p3               62.1G part
    |-sv--server--vg-root   58.9G lvm  /               57.7G   3.2G     6%
    `-sv--server--vg-swap_1  3.2G lvm  [SWAP]
  nvme0n2                    800G disk
  `-nvme0n2p1                800G part /srv/nfs/user  786.4G 553.5G    70%
                                       /srv/nfs/tftp
                                       /srv/nfs/samba
                                       /srv/nfs/http
                                       /srv
  ```

* **sv-developer**

  ``` bash:
  $ LANG=C lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS,FSSIZE,FSUSED,FSUSE%
  NAME                          SIZE TYPE MOUNTPOINTS FSSIZE FSUSED FSUSE%
  sr0                          1024M rom
  nvme0n1                        64G disk
  |-nvme0n1p1                   976M part /boot/efi   974.1M   8.8M     1%
  |-nvme0n1p2                   977M part /boot       943.2M  74.6M     8%
  `-nvme0n1p3                  62.1G part
    |-sv--developer--vg-root   58.9G lvm  /            57.7G   3.2G     6%
    `-sv--developer--vg-swap_1  3.2G lvm  [SWAP]
  ```

  ``` bash:
  $ LANG=C df -h -t nfs -t fuse.vmhgfs-fuse
  Filesystem            Size  Used Avail Use% Mounted on
  vmhgfs-fuse           3.7T  2.9T  848G  78% /srv/hgfs
  sv-server:/srv/tftp   787G  554G  193G  75% /srv/tftp
  sv-server:/srv/user   787G  554G  193G  75% /srv/user
  sv-server:/srv/samba  787G  554G  193G  75% /srv/samba
  sv-server:/srv/http   787G  554G  193G  75% /srv/http
  ```
