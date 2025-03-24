# **Common User Settings**  
  
## **User environment**  
  
**Modify to suit your environment**  
  
### **VMware shared**  
  
#### **open-vm-tools**  
  
``` bash:
declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/Image"	# vmware shared directory
```
  
#### **symbolic link list**  
  
``` bash:
declare -r -a LIST_LINK=(                                                                                           \
	"a  ${DIRS_CONF}                                    ${DIRS_HTML}/"                                              \
	"a  ${DIRS_IMGS}                                    ${DIRS_HTML}/"                                              \
	"a  ${DIRS_ISOS}                                    ${DIRS_HTML}/"                                              \
	"a  ${DIRS_LOAD}                                    ${DIRS_HTML}/"                                              \
	"a  ${DIRS_RMAK}                                    ${DIRS_HTML}/"                                              \
	"a  ${DIRS_IMGS}                                    ${DIRS_TFTP}/"                                              \
	"a  ${DIRS_ISOS}                                    ${DIRS_TFTP}/"                                              \
	"a  ${DIRS_LOAD}                                    ${DIRS_TFTP}/"                                              \
	"r  ${DIRS_TFTP}/${DIRS_IMGS##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
	"r  ${DIRS_TFTP}/${DIRS_ISOS##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
	"r  ${DIRS_TFTP}/${DIRS_LOAD##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
	"r  ${DIRS_TFTP}/menu-bios/syslinux.cfg             ${DIRS_TFTP}/menu-bios/pxelinux.cfg/default"                \
	"r  ${DIRS_TFTP}/${DIRS_IMGS##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
	"r  ${DIRS_TFTP}/${DIRS_ISOS##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
	"r  ${DIRS_TFTP}/${DIRS_LOAD##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
	"r  ${DIRS_TFTP}/menu-efi64/syslinux.cfg            ${DIRS_TFTP}/menu-efi64/pxelinux.cfg/default"               \
	"a  ${HGFS_DIRS}/linux/bin/conf                     ${DIRS_CONF}"                                               \
	"a  ${HGFS_DIRS}/linux/bin/rmak                     ${DIRS_RMAK}"                                               \
) #	0:r	1:target										2:symlink
```
  
### **Network settings for the remake menu**  
  
#### **tftp / web server address**  
  
``` bash:
              SRVR_ADDR="$(LANG=C ip -4 -oneline address show scope global | awk '{split($4,s,"/"); print s[1];}')"
readonly      SRVR_ADDR
```
  
#### **network parameter**  
  
``` bash:
declare -r    WGRP_NAME="workgroup"						# domain
declare -r    ETHR_NAME="ens160"						# network device name
declare -r    IPV4_ADDR="${SRVR_ADDR%.*}.1"				# IPv4 address
declare -r    IPV4_CIDR="24"							# IPv4 cidr
declare -r    IPV4_MASK="255.255.255.0"					# IPv4 subnetmask
declare -r    IPV4_GWAY="${SRVR_ADDR%.*}.254"			# IPv4 gateway
declare -r    IPV4_NSVR="${SRVR_ADDR%.*}.254"			# IPv4 nameserver
```
  
### **List Data**  
  
#### **media information**  
  
``` bash:
#  0: [m] menu / [o] output / [else] hidden
#  1: iso image file copy destination directory
#  2: entry name
#  3: [unused]
#  4: iso image file directory
#  5: iso image file name
#  6: boot loader's directory
#  7: initial ramdisk
#  8: kernel
#  9: configuration file
# 10: iso image file copy source directory
# 11: release date
# 12: support end
# 13: time stamp
# 14: file size
# 15: volume id
# 16: status
# 17: download URL
# 18: time stamp of remastered image file
```
  
#### **mini.iso**  
  
``` bash:
declare -r -a DATA_LIST_MINI=(                                                                      ...
	"m  menu-entry                      Auto%20install%20mini.iso               -                   
	"x  debian-mini-10                  Debian%2010                             debian              
	"o  debian-mini-11                  Debian%2011                             debian              
	"o  debian-mini-12                  Debian%2012                             debian              
	"o  debian-mini-13                  Debian%2013                             debian              
	"-  debian-mini-14                  Debian%2014                             debian              
	"o  debian-mini-testing             Debian%20testing                        debian              
	"o  debian-mini-testing-daily       Debian%20testing%20daily                debian              
	"x  ubuntu-mini-18.04               Ubuntu%2018.04                          ubuntu              
	"o  ubuntu-mini-20.04               Ubuntu%2020.04                          ubuntu              
	"m  menu-entry                      -                                       -                   
) #  0  1                               2                                       3                   
```
  
#### **netinst**  
  
``` bash:
declare -r -a DATA_LIST_NET=(                                                                       ...
	"m  menu-entry                      Auto%20install%20Net%20install          -                   
	"x  debian-netinst-10               Debian%2010                             debian              
	"o  debian-netinst-11               Debian%2011                             debian              
	"o  debian-netinst-12               Debian%2012                             debian              
	"o  debian-netinst-13               Debian%2013                             debian              
	"-  debian-netinst-14               Debian%2014                             debian              
	"o  debian-netinst-testing          Debian%20testing                        debian              
	"x  fedora-netinst-38               Fedora%20Server%2038                    fedora              
	"x  fedora-netinst-39               Fedora%20Server%2039                    fedora              
	"o  fedora-netinst-40               Fedora%20Server%2040                    fedora              
	"o  fedora-netinst-41               Fedora%20Server%2041                    fedora              
	"x  fedora-netinst-41               Fedora%20Server%2041                    fedora              
	"x  centos-stream-netinst-8         CentOS%20Stream%208                     centos              
	"o  centos-stream-netinst-9         CentOS%20Stream%209                     centos              
	"o  centos-stream-netinst-10        CentOS%20Stream%2010                    centos              
	"o  almalinux-netinst-9             Alma%20Linux%209                        almalinux           
	"x  rockylinux-netinst-8            Rocky%20Linux%208                       Rocky               
	"o  rockylinux-netinst-9            Rocky%20Linux%209                       Rocky               
	"x  miraclelinux-netinst-8          Miracle%20Linux%208                     miraclelinux        
	"o  miraclelinux-netinst-9          Miracle%20Linux%209                     miraclelinux        
	"x  opensuse-leap-netinst-15.5      openSUSE%20Leap%2015.5                  openSUSE            
	"o  opensuse-leap-netinst-15.6      openSUSE%20Leap%2015.6                  openSUSE            
	"o  opensuse-leap-netinst-16.0      openSUSE%20Leap%2016.0                  openSUSE            
	"o  opensuse-tumbleweed-netinst     openSUSE%20Tumbleweed                   openSUSE            
	"-  opensuse-leap-netinst-16.0      openSUSE%20Leap%2016.0                  openSUSE            
	"-  opensuse-leap-netinst-pxe-16.0  openSUSE%20Leap%2016.0%20PXE            openSUSE            
	"m  menu-entry                      -                                       -                   
) #  0  1                               2                                       3                   
```
  
#### **dvd image**  
  
``` bash:
declare -r -a DATA_LIST_DVD=(                                                                       ...
	"m  menu-entry                      Auto%20install%20DVD%20media            -                   
	"x  debian-10                       Debian%2010                             debian              
	"o  debian-11                       Debian%2011                             debian              
	"o  debian-12                       Debian%2012                             debian              
	"o  debian-13                       Debian%2013                             debian              
	"-  debian-14                       Debian%2014                             debian              
	"o  debian-testing                  Debian%20testing                        debian              
	"x  ubuntu-server-14.04             Ubuntu%2014.04%20Server                 ubuntu              
	"-  ubuntu-server-16.04             Ubuntu%2016.04%20Server                 ubuntu              
	"x  ubuntu-server-18.04             Ubuntu%2018.04%20Server                 ubuntu              
	"x  ubuntu-live-18.04               Ubuntu%2018.04%20Live%20Server          ubuntu              
	"o  ubuntu-live-20.04               Ubuntu%2020.04%20Live%20Server          ubuntu              
	"o  ubuntu-live-22.04               Ubuntu%2022.04%20Live%20Server          ubuntu              
	"x  ubuntu-live-23.04               Ubuntu%2023.04%20Live%20Server          ubuntu              
	"x  ubuntu-live-23.10               Ubuntu%2023.10%20Live%20Server          ubuntu              
	"o  ubuntu-live-24.04               Ubuntu%2024.04%20Live%20Server          ubuntu              
	"o  ubuntu-live-24.10               Ubuntu%2024.10%20Live%20Server          ubuntu              
	"o  ubuntu-live-25.04               Ubuntu%2025.04%20Live%20Server          ubuntu              
	"-  ubuntu-live-24.10               Ubuntu%2024.10%20Live%20Server%20Beta   ubuntu              
	"-  ubuntu-live-oracular            Ubuntu%20oracular%20Live%20Server       ubuntu              
	"x  fedora-38                       Fedora%20Server%2038                    fedora              
	"x  fedora-39                       Fedora%20Server%2039                    fedora              
	"o  fedora-40                       Fedora%20Server%2040                    fedora              
	"o  fedora-41                       Fedora%20Server%2041                    fedora              
	"x  fedora-41                       Fedora%20Server%2041                    fedora              
	"x  centos-stream-8                 CentOS%20Stream%208                     centos              
	"o  centos-stream-9                 CentOS%20Stream%209                     centos              
	"o  centos-stream-10                CentOS%20Stream%2010                    centos              
	"o  almalinux-9                     Alma%20Linux%209                        almalinux           
	"x  rockylinux-8                    Rocky%20Linux%208                       Rocky               
	"o  rockylinux-9                    Rocky%20Linux%209                       Rocky               
	"x  miraclelinux-8                  Miracle%20Linux%208                     miraclelinux        
	"o  miraclelinux-9                  Miracle%20Linux%209                     miraclelinux        
	"x  opensuse-leap-15.5              openSUSE%20Leap%2015.5                  openSUSE            
	"o  opensuse-leap-15.6              openSUSE%20Leap%2015.6                  openSUSE            
	"o  opensuse-leap-16.0              openSUSE%20Leap%2016.0                  openSUSE            
	"o  opensuse-tumbleweed             openSUSE%20Tumbleweed                   openSUSE            
	"o  windows-10                      Windows%2010                            windows             
	"o  windows-11                      Windows%2011                            windows             
	"-  windows-11                      Windows%2011%20custom                   windows             
	"m  menu-entry                      -                                       -                   
) #  0  1                               2                                       3                   
```
  
#### **live media install mode**  
  
``` bash:
declare -r -a DATA_LIST_INST=(                                                                      ...
	"m  menu-entry                      Live%20media%20Install%20mode           -                   
	"x  debian-live-10                  Debian%2010%20Live                      debian              
	"o  debian-live-11                  Debian%2011%20Live                      debian              
	"o  debian-live-12                  Debian%2012%20Live                      debian              
	"o  debian-live-13                  Debian%2013%20Live                      debian              
	"o  debian-live-testing             Debian%20testing%20Live                 debian              
	"x  ubuntu-desktop-14.04            Ubuntu%2014.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-16.04            Ubuntu%2016.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-18.04            Ubuntu%2018.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-20.04            Ubuntu%2020.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-22.04            Ubuntu%2022.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-23.04            Ubuntu%2023.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-23.10            Ubuntu%2023.10%20Desktop                ubuntu              
	"o  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop                ubuntu              
	"-  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop%20Beta         ubuntu              
	"o  ubuntu-desktop-25.04            Ubuntu%2025.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              
	"-  ubuntu-desktop-oracular         Ubuntu%20oracular%20Desktop             ubuntu              
	"x  ubuntu-legacy-23.04             Ubuntu%2023.04%20Legacy%20Desktop       ubuntu              
	"x  ubuntu-legacy-23.10             Ubuntu%2023.10%20Legacy%20Desktop       ubuntu              
	"m  menu-entry                      -                                       -                   
) #  0  1                               2                                       3                   
```
  
#### **live media live mode**  
  
``` bash:
declare -r -a DATA_LIST_LIVE=(                                                                      ...
	"m  menu-entry                      Live%20media%20Live%20mode              -                   
	"x  debian-live-10                  Debian%2010%20Live                      debian              
	"o  debian-live-11                  Debian%2011%20Live                      debian              
	"o  debian-live-12                  Debian%2012%20Live                      debian              
	"o  debian-live-13                  Debian%2013%20Live                      debian              
	"o  debian-live-testing             Debian%20testing%20Live                 debian              
	"x  ubuntu-desktop-14.04            Ubuntu%2014.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-16.04            Ubuntu%2016.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-18.04            Ubuntu%2018.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-20.04            Ubuntu%2020.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-22.04            Ubuntu%2022.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-23.04            Ubuntu%2023.04%20Desktop                ubuntu              
	"x  ubuntu-desktop-23.10            Ubuntu%2023.10%20Desktop                ubuntu              
	"o  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop                ubuntu              
	"-  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop%20Beta         ubuntu              
	"x  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              
	"o  ubuntu-desktop-25.04            Ubuntu%2025.04%20Desktop                ubuntu              
	"-  ubuntu-desktop-oracular         Ubuntu%20oracular%20Desktop             ubuntu              
	"x  ubuntu-legacy-23.04             Ubuntu%2023.04%20Legacy%20Desktop       ubuntu              
	"x  ubuntu-legacy-23.10             Ubuntu%2023.10%20Legacy%20Desktop       ubuntu              
	"m  menu-entry                      -                                       -                   
) #  0  1                               2                                       3                   
```
  
#### **tool**  
  
``` bash:
declare -r -a DATA_LIST_TOOL=(                                                                      ...
	"m  menu-entry                      System%20tools                          -                   
	"x  memtest86plus                   Memtest86+%207.00                       memtest86+          
	"o  memtest86plus                   Memtest86+%207.20                       memtest86+          
	"o  winpe-x64                       WinPE%20x64                             windows             
	"o  winpe-x86                       WinPE%20x86                             windows             
	"o  ati2020x64                      ATI2020x64                              windows             
	"o  ati2020x86                      ATI2020x86                              windows             
	"m  menu-entry                      -                                       -                   
) #  0  1                               2                                       3                   
```
  

