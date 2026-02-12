# **Reference for development environment creation procedures**

``` bash:
# --- get live media ----------------------------------------------------------
# curl -L -# -O -R -S "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.3.0-amd64-standard.iso"
# --- start live media --------------------------------------------------------
# boot "debian-live-13.3.0-amd64-standard.iso"
# --- install package ---------------------------------------------------------
# for debian / ubuntu
sudo bash -c '
apt-get update 
apt-get install openssh-server
apt-get install gawk tree gzip zstd bzip2 lzop xorriso xxd
'
# for rhel
#sudo dnf install gawk tree gzip zstd bzip2 lzop xorriso    
# --- user add ----------------------------------------------------------------
sudo bash -c '
groupadd --system sambashare
useradd --no-create-home --groups sambashare --system sambauser
id sambauser
'
# --- remove lvm --------------------------------------------------------------
sudo bash -c '
lvdisplay
lvremove /dev/sv-debian-vg/root /dev/sv-debian-vg/swap_1
'
# --- create filesystem -------------------------------------------------------
sudo bash -c '
sfdisk --wipe always /dev/nvme0n1 << __EOT__
,,,,
__EOT__
mkfs.ext4 -F /dev/nvme0n1p1
'
# --- mount filesystem --------------------------------------------------------
sudo bash -c '
mkdir -p /srv/
mount /dev/nvme0n1p1 /srv/
'
# --- work preparation --------------------------------------------------------
sudo bash -c '
mkdir -p /srv/user/share/conf/{_data,_template,script}/
cd /srv/user/share/conf/_data/
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_data/common.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_data/media.dat
cd /srv/user/share/conf/_template/
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/agama_opensuse.json
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/kickstart_rhel.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/preseed_debian.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/preseed_ubuntu.cfg
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/user-data_ubuntu
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/yast_opensuse.xml
cd /srv/user/share/conf/script/
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_early.sh
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_late.sh
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_part.sh
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_run.sh
cd /home/"${SUDO_USER:?}"
wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/script/custom_cmd/mk_custom_iso.sh
chmod +x mk_custom_iso.sh
cd
'
# --- create directory --------------------------------------------------------
sudo bash -c '
/home/"${SUDO_USER:?}"/mk_custom_iso.sh -l create
/home/"${SUDO_USER:?}"/mk_custom_iso.sh -T
'
sudo bash -c '
mkdir -p /home/"${SUDO_USER:?}"/.workdirs/
mount --bind /srv/user/private/ /home/"${SUDO_USER:?}"/.workdirs/
'
# --- create iso file ---------------------------------------------------------
sudo ./mk_custom_iso.sh -c a
sudo ./mk_custom_iso.sh -m netinst:
# --- eot ---------------------------------------------------------------------
```
