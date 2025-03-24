# **mk_custom_iso.sh**  
  
## **operation method**  
  
### **commands**  
  
[ sudo ] ./mk_custom_iso.sh [ commands ] [ options ]  
  
|         commands        |                     operation                     |
| :---------------------- | :------------------------------------------------ |
| (empty)                 | Show help message                                 |
| --conf                  | Creating pre-configuration and post-script files  |
| --create                | Start remaking ISO files                          |
| --download              | Start downloading the ISO file                    |
| --update                | Started remaking the updated ISO files            |
  
### **options**  
  
#### **create config files**  
  
[ sudo ] ./mk_custom_iso.sh --conf [ options ]  
  
|         options         |                     operation                     |
| :---------------------- | :------------------------------------------------ |
| cmd                     | preseed kill dhcp / sub command                   |
| preseed                 | preseed.cfg                                       |
| nocloud                 | nocloud                                           |
| kickstart               | kickstart.cfg                                     |
| autoyast                | autoyast.xml                                      |
  
#### **create / download / update iso image files**  
  
[ sudo ] ./mk_custom_iso.sh --create / --download / --update [ options ] [ (empty) | all | id number (1...) ]  
  
|         options         |                     operation                     |
| :---------------------- | :------------------------------------------------ |
| mini / net / dvd / live | mini.iso / netinst / dvd image / live image       |
| (empty)                 | waiting for input                                 |
| a \| all                | create all targets                                |
| id number               | create with selected target id                    |
  
### **Example of operation**  
  
``` bash:
# Creating a configuration file
./mk_custom_iso.sh --conf

# Remake the second one from the mini.iso list
./mk_custom_iso.sh --create mini 2

# Recreate the PXEboot menu after downloading all iso files
./mk_custom_iso.sh --download a && ./mk_pxeboot_conf.sh --create

# Remake update targets from all iso files
./mk_custom_iso.sh --update a
```
  
### **Example of screen**  
  
columns x rows = 120 x 40  
  
``` bash:
root@sv-server:/srv/user/private# ./mk_custom_iso.sh --create
2025/03/24 06:15:34 processing start
--- start --------------------------------------------------------------------------------------------------------------
--- main ---------------------------------------------------------------------------------------------------------------
---- call create -------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------- #
#ID:Version                                   :ReleaseDay:SupportEnd:Memo                                              #
# 1:mini-bullseye-amd64.iso                   :2024-08-27:2026-06-01:Debian 11[ps_debian_server_old.cfg]               #
# 2:mini-bookworm-amd64.iso                   :2025-03-10:2028-06-01:Debian 12[ps_debian_server.cfg]                   #
# 3:mini-trixie-amd64.iso                     :2024-12-27:20xx-xx-xx:Debian 13[ps_debian_server.cfg]                   #
# 4:mini-testing-amd64.iso                    :2024-12-27:20xx-xx-xx:Debian testing[ps_debian_server.cfg]              #
# 5:mini-testing-daily-amd64.iso              :2025-03-24:20xx-xx-xx:Debian testing daily[ps_debian_server.cfg]        #
# 6:mini-focal-amd64.iso                      :2023-03-14:2030-04-23:Ubuntu 20.04[ps_ubuntu_server_old.cfg]            #
# -------------------------------------------------------------------------------------------------------------------- #
enter the number to create:2
===            start: mini-bookworm-amd64.iso ==========================================================================
                copy: mini-bookworm-amd64.iso 62MiB
                copy: /initrd.gz
              unpack: /initrd.gz
              create: boot options for preseed
                edit: add autoinst.cfg to syslinux.cfg
              create: menu entry     0: [initps.gz][linux]
                edit: add autoinst.cfg to grub.cfg
              create: menu entry     0: [/initps.gz][/linux]
              create: theme.txt
              create: remaster initps.gz
              create: remaster iso file
              create: mini-bookworm-amd64_preseed.iso
===         complete: mini-bookworm-amd64.iso ==========================================================================
# -------------------------------------------------------------------------------------------------------------------- #
```
  
