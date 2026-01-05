# **samba**

``` bash:
$ cat /etc/samba/smb.conf
# Global parameters
[global]
        allow insecure wide links = Yes
        dos charset = CP932
        interfaces = ens160
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
        usershare allow guests = Yes
        idmap config * : backend = tdb
        mangling char = ~


[homes]
        browseable = No
        comment = Home Directories
        create mask = 0660
        directory mask = 02770
        force group = sambashare
        force user = sambauser
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
