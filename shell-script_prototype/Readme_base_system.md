# **Create base system**  
  
## **Automatic installation**  
  
### **Download**  
  
1. [mini.iso](https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/mini.iso "debian stable mini.iso")  
2. [preseed_kill_dhcp.sh](https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script_prototype/conf/preseed/preseed_kill_dhcp.sh)  
3. [preseed_late_command.sh](https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script_prototype/conf/preseed/preseed_late_command.sh)  
4. [ps_debian_server.cfg](https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script_prototype/conf/preseed/ps_debian_server.cfg)  
  
### **Copy to USB stick**  
  
* Copy the downloaded files except for mini.iso to a USB stick.  
(The USB stick must be formatted in fat32 (vfat))
  
## **Start the installation**  
  
### **Boot from mini.iso**  
  
* Insert the media and start the computer.  
(Assuming UEFI mode)  
  
### **Editing command options**  
  
* When the menu appears, place the cursor on the 'Install' line and press the 'e' key.  
* Add auto=true to the end of the Linux line and press F10.  
  
<img width="320" src="./_picture/2025-03-07-21-20-33.png">  
  
### **Enter the hostname and domain name**  
  
* Enter the host name and domain name and press Enter.  
  
<img width="320" src="./_picture/2025-03-07-21-21-09.png">  
  
### **Load from USB stick**  
  
* When the console screen appears waiting for input, press 'Alt+F2'.  
* When the new screen opens, enter the following.  
(Assume the usb stick is /deb/sda1)  

  
``` bash:
modprobe vfat
mount /dev/sda1 /mnt
ls -l /mnt
```
  
<img width="320" src="./_picture/2025-03-07-21-21-56.png">  
  
### **Automatic installation process begins**  
  
* Press 'Alt+F1' to return to the original screen.  
* Enter the preseed file name and press Enter.  
(Assume the file name is /mnt/preseed.cfg)  
  
<img width="320" src="./_picture/2025-03-07-21-22-17.png">  
  
## **Booting the base system**  
  
* Once the installation is completed successfully, the system will reboot and start up into the base system.  
  
