# **Application settings**

## nfs

### sv-server

<details><summary>cat /etc/exports.d/srv.exports</summary>

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

</details>

<details><summary>grep 'nfs' /etc/fstab</summary>

``` bash:
$ grep 'nfs' /etc/fstab
/srv/hgfs       /srv/nfs/hgfs   none    bind            0       0
/srv/http       /srv/nfs/http   none    bind            0       0
/srv/samba      /srv/nfs/samba  none    bind            0       0
/srv/tftp       /srv/nfs/tftp   none    bind            0       0
/srv/user       /srv/nfs/user   none    bind            0       0
```

</details>

### sv-developer

<details><summary>grep -E '(nfs|fuse)' /etc/fstab</summary>

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

</details>

## samba

<details><summary>cat /etc/samba/smb.conf</summary>

``` bash:
$ cat /etc/samba/smb.conf
# Global parameters
[global]
    allow insecure wide links = Yes
    disable netbios = Yes
    dos charset = CP932
    log file = /var/log/samba/log.%m
    logging = file
    map to guest = Bad User
    max log size = 1000
    obey pam restrictions = Yes
    pam password change = Yes
    panic action = /usr/share/samba/panic-action %d
    passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
    passwd program = /usr/bin/passwd %u
    server role = standalone server
    smb ports = 445
    usershare allow guests = Yes
    idmap config * : backend = tdb
    mangling char = ~


[homes]
    browseable = No
    comment = Home Directories
    create mask = 0700
    directory mask = 02700
    valid users = %S
    write list = @sambashare


[printers]
    browseable = No
    comment = All Printers
    create mask = 0700
    path = /var/tmp
    printable = Yes


[print$]
    comment = Printer Drivers
    path = /var/lib/samba/printers


[adm]
    browseable = No
    comment = Administrator directories
    create mask = 0660
    directory mask = 02770
    force group = sambashare
    force user = sambauser
    path = /srv/samba/adm
    valid users = @sambashare
    write list = @sambaadmin


[pub]
    comment = Public directories
    create mask = 0660
    directory mask = 02770
    force group = sambashare
    force user = sambauser
    path = /srv/samba/pub
    valid users = @sambashare
    write list = @sambaadmin


[usr]
    browseable = No
    comment = User directories
    create mask = 0660
    directory mask = 02770
    force group = sambashare
    force user = sambauser
    path = /srv/samba/usr
    valid users = @sambaadmin
    write list = @sambaadmin


[share]
    browseable = No
    comment = Shared directories
    create mask = 0660
    directory mask = 02770
    force group = sambashare
    force user = sambauser
    path = /srv/samba
    valid users = @sambaadmin
    write list = @sambaadmin


[dlna]
    browseable = No
    comment = DLNA directories
    create mask = 0660
    directory mask = 02770
    force group = sambashare
    force user = sambauser
    path = /srv/samba/pub/contents/dlna
    valid users = @sambashare
    write list = @sambaadmin


[share-html]
    browseable = No
    comment = Shared directory for HTML
    guest ok = Yes
    path = /srv/http/html
    wide links = Yes


[share-tftp]
    browseable = No
    comment = Shared directory for TFTP
    guest ok = Yes
    path = /srv/tftp
    wide links = Yes


[share-conf]
    browseable = No
    comment = Shared directory for configuration files
    create mask = 0664
    directory mask = 02775
    force group = sambashare
    force user = sambauser
    path = /srv/user/share/conf
    valid users = @sambashare
    write list = @sambaadmin


[share-isos]
    browseable = No
    comment = Shared directory for iso image files
    create mask = 0664
    directory mask = 02775
    force group = sambashare
    force user = sambauser
    path = /srv/user/share/isos
    valid users = @sambashare
    write list = @sambaadmin


[share-rmak]
    browseable = No
    comment = Shared directory for remake files
    create mask = 0664
    directory mask = 02775
    force group = sambashare
    force user = sambauser
    path = /srv/user/share/rmak
    valid users = @sambashare
    write list = @sambaadmin
```

</details>
