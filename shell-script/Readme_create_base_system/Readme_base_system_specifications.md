# **Base system specifications**  
  
## **Machine specs**  
  
### **Virtual machine**
  
VMware Workstation 16 Pro (16.2.5 build-20904516)
  
| device    | specification      | note                          |
| :-------- | :----------------- | :---------------------------- |
| processor | 1processor / 2core | core i7-6700                  |
| memory    | 4GiB               | Most distributions            |
| storage   | NVMe 500GiB        |                               |
| nic       | e1000e             |                               |
| sound     | ES1371             |                               |
  
### **Storage usage**  
  
| directory name        |   usage    | contents                        |
| :-------------------- | ---------: | :------------------------------ |
| /                     |     500GiB | root directory                  |
| /srv/                 |     480GiB | shared directory                |
| /srv/hgfs/            | (external) | vmware shared directory         |
| /srv/http/html/       |       1GiB | html contents                   |
| /srv/samba/           |       1GiB | samba shared directory (empty)  |
| /srv/tftp/            |       1GiB | tftp contents                   |
| /srv/user/            |     450GiB | user file                       |
| /srv/user/private/    |       1GiB | personal use                    |
| /srv/user/share/      |     450GiB | shared                          |
| /srv/user/share/conf/ |       1GiB | configuration file              |
| /srv/user/share/imgs/ |     150GiB | iso file extraction destination |
| /srv/user/share/isos/ |     150GiB | iso file                        |
| /srv/user/share/load/ |       5GiB | load module                     |
| /srv/user/share/rmak/ |     140GiB | remake file                     |
  
### **Install packages**  
  
|      package      |              debian / ubuntu                 | rhel (fedora,centos-stream,miraclelinux,...) |                   openSUSE                   |
| :---------------- | :------------------------------------------- | :------------------------------------------- | :------------------------------------------- |
| apparmor          | apparmor apparmor-utils                      |                                              |                                              |
| usrmerge          | usrmerge                                     |                                              |                                              |
| sudo              | sudo                                         | sudo                                         | sudo                                         |
| firewalld         | firewalld                                    | firewalld                                    | firewalld                                    |
| traceroute        | traceroute                                   | traceroute                                   | traceroute                                   |
| network manager   | connman                                      | NetworkManager                               | NetworkManager                               |
| bash-completion   | bash-completion                              | bash-completion                              | bash-completion                              |
| build-essential   | build-essential                              |                                              |                                              |
| curl              | curl                                         | curl                                         | curl                                         |
| vim               | vim                                          | vim                                          | vim                                          |
| bc                | bc                                           | bc                                           | bc                                           |
| tree              | tree                                         | tree                                         | tree                                         |
| shellcheck        | shellcheck                                   |                                              |                                              |
| clamav            | clamav                                       |                                              | clamav                                       |
| openssh-server    | openssh-server                               | openssh-server                               | openssh-server                               |
| systemd-resolved  | systemd-resolved                             | systemd-resolved                             | systemd-network                              |
| dnsmasq           | dnsmasq bind9-dnsutils                       | dnsmasq tftp-server bind-utils               | dnsmasq tftp bind-utils                      |
| apache2           | apache2                                      | httpd                                        | apache2                                      |
| samba             | samba smbclient cifs-utils libnss-winbind    | samba samba-client cifs-utils samba-winbind  | samba samba-client cifs-utils samba-winbind  |
| open-vm-tools     | open-vm-tools open-vm-tools-desktop          | open-vm-tools open-vm-tools-desktop fuse     | open-vm-tools open-vm-tools-desktop fuse     |
  
