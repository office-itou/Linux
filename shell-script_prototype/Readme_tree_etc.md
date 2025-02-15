# **Linux server tree diagram (developed for debian)**  
  
## command  
  
``` bash:
tree --charset C -n --filesfirst -d /etc/
```
  
## /etc/  
  
``` bash:
/etc/
|-- fstab
|-- hostname
|-- hosts
|-- nsswitch.conf
|-- resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
|-- sudoers
|-- apache2
|   `-- sites-available
|       `-- 999-site.conf -------------------------- virtual host configuration file for users
|-- connman
|   `-- main.conf
|-- default
|   |-- dnsmasq
|   `-- grub
|-- dnsmasq.d
|   |-- default.conf ------------------------------- dnsmasq configuration file
|   `-- pxeboot.conf ------------------------------- pxeboot configuration file
|-- firewalld
|   `-- zones
|       `-- home_use.xml
|-- samba
|   `-- smb.conf ----------------------------------- samba configuration file
|-- skel
|   |-- .bash_history
|   |-- .bashrc
|   |-- .curlrc
|   `-- .vimrc
|-- ssh
|   `-- sshd_config.d
|       `-- default.conf --------------------------- ssh configuration file
`-- systemd
    |-- resolved.conf.d
    |   `-- default.conf
    |-- system
    |   `-- connman.service.d
    |       `-- disable_dns_proxy.conf
    `-- timesyncd.conf.d
        `-- local.conf
```
  
