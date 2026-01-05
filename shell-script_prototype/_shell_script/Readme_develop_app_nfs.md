# **nfs**

## **sv-server**

``` bash:
$ cat /etc/exports.d/srv.exports
/srv           192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0)
/srv/nfs       192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0)
#/srv/nfs/hgfs  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=1)
/srv/nfs/http  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/samba 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/tftp  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/user  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

``` bash:
$ grep 'nfs' /etc/fstab
/srv/hgfs       /srv/nfs/hgfs   none    bind            0       0
/srv/http       /srv/nfs/http   none    bind            0       0
/srv/samba      /srv/nfs/samba  none    bind            0       0
/srv/tftp       /srv/nfs/tftp   none    bind            0       0
/srv/user       /srv/nfs/user   none    bind            0       0
```

## **sv-developer**

``` bash:
$ grep -E '(nfs|fuse)' /etc/fstab
#.host:/         /srv/hgfs       fuse.vmhgfs-fuse nofail,allow_other,defaults 0       0
#sv-server:/         /srv        nfs4             nofail,defaults,bg 0 0
#sv-server:/hgfs     /srv/hgfs   nfs              nofail,defaults,bg 0 0
sv-server:/srv/http  /srv/http   nfs              nofail,defaults,bg 0 0
sv-server:/srv/samba /srv/samba  nfs              nofail,defaults,bg 0 0
sv-server:/srv/tftp  /srv/tftp   nfs              nofail,defaults,bg 0 0
sv-server:/srv/user  /srv/user   nfs              nofail,defaults,bg 0 0
.host:/              /srv/hgfs   fuse.vmhgfs-fuse nofail,allow_other,defaults 0 0
```
