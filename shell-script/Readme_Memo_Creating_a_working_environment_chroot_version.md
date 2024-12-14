# **Creating a working environment**  
  
##  package installation 
  
``` bash:
sudo apt-get install mmdebstrap
```
  
##  create chroot environment 
  
### debian bookworm 
  
``` bash:
sudo umount $(awk '{print $2;}' /proc/mounts | grep './share_chrt/' | sort -r)
sudo rm -rf --one-file-system ./share_chrt
sudo mkdir -p ./share_chrt
sudo mmdebstrap \
--variant=minbase \
--mode=sudo \
--format=directory \
--include=" \
  systemd \
  fakechroot \
  iproute2 \
  iputils-ping \
  gnupg \
  apt-utils \
  apt-listchanges \
  bash-completion \
  locales-all \
  locales \
  less \
  vim \
  shellcheck \
  file \
" \
--components='main contrib non-free non-free-firmware' \
bookworm \
./share_chrt
```
  
### ubuntu plucky 
  
``` bash:
sudo umount $(awk '{print $2;}' /proc/mounts | grep './share_chrt/' | sort -r)
sudo rm -rf --one-file-system ./share_chrt
sudo mkdir -p ./share_chrt
sudo mmdebstrap \
--variant=minbase \
--mode=sudo \
--format=directory \
--include=" \
  systemd \
  fakechroot \
  iproute2 \
  iputils-ping \
  gnupg \
  apt-utils \
  apt-listchanges \
  bash-completion \
  locales-all \
  locales \
  less \
  vim \
  shellcheck \
  file \
" \
--components='main restricted universe multiverse' \
plucky \
./share_chrt
```
  
## setting up your work environment 
  
### alias 
  
``` bash:
sudo sed -i share_chrt/root/.bashrc -e '/alias[ \t]\+ls=/ s/^#/ /' -e '/export LS_OPTIONS/ s/^#/ /'
```
  
### .vimrc 
  
``` bash:
cat <<- '_EOT_' | sudo tee ./share_chrt/root/.vimrc > /dev/null
set number              " Print the line number in front of each line.
set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
set nowrap              " This option changes how text is displayed.
set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
set laststatus=2        " The value of this option influences when the last window will have a status line always.
set mouse-=a            " Disable mouse usage
syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
```
  
## running a chroot environment 
  
### mount work environment 
  
``` bash:
sudo mkdir -p ./share_chrt/mnt/hgfs/workspace
sudo mkdir -p ./share_chrt/srv/user/share
sudo mount --bind /mnt/hgfs/workspace/ ./share_chrt/mnt/hgfs/workspace/
sudo mount --bind ./share/ ./share_chrt/srv/user/share/
```
  
### mount system directory 
  
``` bash:
sudo mount --rbind /dev  ./share_chrt/dev
sudo mount  --bind /proc ./share_chrt/proc
sudo mount  --bind /run  ./share_chrt/run
sudo mount --rbind /sys  ./share_chrt/sys
sudo mount --rbind /tmp  ./share_chrt/tmp
sudo mount --make-rslave ./share_chrt/dev
sudo mount --make-rslave ./share_chrt/sys
sudo systemctl daemon-reload
```
  
### start the chroot environment 
  
``` bash:
sudo usermod -s /bin/bash root          # only if root login is prohibited
sudo chroot ./share_chrt/
```
  
### working in a chroot environment 
  
``` bash:
ln -s /mnt/hgfs/workspace/Image/linux/bin/{install.sh,mk_custom_iso.sh,mk_live_media.sh,mk_pxeboot_conf.sh} /srv/user/
apt-get install bzip2 cpio curl fdisk initramfs-tools-core isolinux isomd5sum lz4 lzop wget xorriso xxd xz-utils zstd
apt-get install curl grub-common grub-efi-amd64-bin grub-pc-bin pxelinux rsync syslinux-common syslinux-efi
```
  
### exiting the chroot environment 
  
``` bash:
sudo umount $(awk '{print $2;}' /proc/mounts | grep './share_chrt/' | sort -r)
```
  
