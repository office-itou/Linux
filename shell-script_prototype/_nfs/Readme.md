# **About NFS settings**

## **Tree diagram**

``` bash:
sudo tree -L 2 --charset C -n --filesfirst -d /srv/
```

``` bash:
/srv/
|-- hgfs
|-- http
|-- nfs
|   |-- hgfs
|   |-- http
|   |-- samba
|   |-- tftp
|   `-- user
|-- samba
|-- tftp
`-- user
```

## **Commands**

### **Server**

#### **Install packages**

##### **RHEL** (Fedora / Centos stream / Alma / Rocky)

``` bash:
sudo dnf install nfs-utils
```

##### **Debian / Ubuntu**

``` bash:
sudo apt-get -y install nfs-kernel-server
```

#### **Create an export directory and bind mount it**

``` bash:
sudo bash -c '
  mkdir -p /srv/nfs/{hgfs,http,samba,tftp,user}
  [ ! -e /etc/fstab.back ] && cp -a /etc/fstab /etc/fstab.back
  cp -a /etc/fstab.back /etc/fstab
  cat <<- _EOT_ >> /etc/fstab
/srv/hgfs       /srv/nfs/hgfs   none    bind            0       0
/srv/http       /srv/nfs/http   none    bind            0       0
/srv/samba      /srv/nfs/samba  none    bind            0       0
/srv/tftp       /srv/nfs/tftp   none    bind            0       0
/srv/user       /srv/nfs/user   none    bind            0       0
_EOT_
  systemctl daemon-reload
  mount -a
'
```

#### **Create export configuration file**

``` bash:
sudo bash -c '
  mkdir -p /etc/exports.d
  cat <<- _EOT_ > /etc/exports.d/srv.exports
/srv           192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0)
/srv/nfs       192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0)
#/srv/nfs/hgfs  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=1)
/srv/nfs/http  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/samba 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/tftp  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/user  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
_EOT_
  exportfs -ar
  exportfs -v
'
```

### **Client**

#### **Add nfs mount to fstab** (nfs version 3)

``` bash:
sudo bash -c '
  mkdir -p /srv/nfs/{hgfs,http,samba,tftp,user}
  [ ! -e /etc/fstab.back ] && cp -a /etc/fstab /etc/fstab.back
  cp -a /etc/fstab.back /etc/fstab
  sed -i /etc/fstab -e '\''\%^.host:/% s/^/#/'\''
  cat <<- _EOT_ >> /etc/fstab
#sv-server:/         /srv        nfs4             nofail,defaults,bg 0 0
#sv-server:/hgfs     /srv/hgfs   nfs              nofail,defaults,bg 0 0
sv-server:/srv/http  /srv/http   nfs              nofail,defaults,bg 0 0
sv-server:/srv/samba /srv/samba  nfs              nofail,defaults,bg 0 0
sv-server:/srv/tftp  /srv/tftp   nfs              nofail,defaults,bg 0 0
sv-server:/srv/user  /srv/user   nfs              nofail,defaults,bg 0 0
.host:/              /srv/hgfs   fuse.vmhgfs-fuse nofail,allow_other,defaults 0 0
_EOT_
  systemctl daemon-reload
  mount -a
'
```
