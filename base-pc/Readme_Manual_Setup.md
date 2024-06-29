# **Manual Setup**  
  
The following is running on a minimal install of Debian stable
  
## script  
  
``` bash:
wget https://raw.githubusercontent.com/office-itou/Linux/master/shell-script/example/.vimrc
wget https://raw.githubusercontent.com/office-itou/Linux/master/shell-script/install.sh
wget https://raw.githubusercontent.com/office-itou/Linux/master/shell-script/mk_custom_iso.sh
wget https://raw.githubusercontent.com/office-itou/Linux/master/shell-script/mk_pxeboot_conf.sh
chmod +x install.sh mk_custom_iso.sh mk_pxeboot_conf.sh
```
  
## conf  
  
``` bash:
mkdir -p share/conf/_template
cd share/conf/_template
wget https://raw.githubusercontent.com/office-itou/Linux/master/conf/_template/kickstart_common.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/master/conf/_template/nocloud-ubuntu-user-data
wget https://raw.githubusercontent.com/office-itou/Linux/master/conf/_template/preseed_debian.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/master/conf/_template/preseed_ubuntu.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/master/conf/_template/yast_opensuse.xml
cd
```
  
## package  
  
``` bash:
sudo apt-get install \
    curl isolinux isomd5sum xorriso xxd \
    7zip apache2 dnsmasq grub-pc-bin lz4 lzop pxelinux rsync syslinux-common syslinux-efi tftpd-hpa \
    shellcheck tree vim
```
  
## dnsmasq  
  
``` bash:
wget https://raw.githubusercontent.com/office-itou/Linux/master/shell-script/example/server/etc/dnsmasq.d/pxe.conf
sed -e '/^#/! {' -e '/^$/! s/^/#/g}' \
    -e '/dhcp-range=.*,proxy/ s/^#//' \
    -e '/ipxe block/,/^$/ {' -e '/^# /! s/^#//g}' \
    pxe.conf | \
    sudo tee /etc/dnsmasq.d/pxe.conf > /dev/null
sudo systemctl restart dnsmasq.service
```
  
## tftpd  
  
``` bash:
sudo sed -e '/^TFTP_DIRECTORY=/ s%=.*$%="/var/lib/tftpboot"%' -i /etc/default/tftpd-hpa
sudo systemctl restart tftpd-hpa.service
```
  
## setup  
  
``` bash:
sudo ./mk_custom_iso.sh --conf
```
  
## run (target mini.iso file)  
  
``` bash:
sudo ./mk_custom_iso.sh --create mini
sudo ./mk_pxeboot_conf.sh --create
```
  
