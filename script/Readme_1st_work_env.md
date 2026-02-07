# **Reference for development environment creation procedures**

``` bash:
# --- get live media ----------------------------------------------------------
# curl -L -# -O -R -S "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.3.0-amd64-standard.iso"
# --- start live media --------------------------------------------------------
# boot "debian-live-13.3.0-amd64-standard.iso"
# sudo apt-get update
# sudo apt-get install openssh-server
# --- remove lvm --------------------------------------------------------------
sudo lvdisplay
sudo lvremove /dev/sv-debian-vg/root /dev/sv-debian-vg/swap_1
# --- create filesystem -------------------------------------------------------
sudo sfdisk --wipe always /dev/nvme0n1 << __EOT__
,,,,
__EOT__
sudo mkfs.ext4 /dev/nvme0n1p1
# --- mount filesystem --------------------------------------------------------
sudo mkdir -p /srv/
sudo mount /dev/nvme0n1p1 /srv/
# --- user add ----------------------------------------------------------------
sudo groupadd --system sambashare
sudo useradd --no-create-home --groups sambashare --system sambauser
sudo id sambauser
# --- work preparation --------------------------------------------------------
sudo mkdir -p /srv/user/share/conf/_data/
cd /srv/user/share/conf/_data/
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_data/common.cfg
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_data/media.dat
cd /srv/user/share/conf/_template/
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/_template/preseed_debian.cfg
cd /srv/user/share/conf/script/
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_early.sh
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_late.sh
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_part.sh
sudo wget https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/conf/script/autoinst_cmd_run.sh
cd
# download shell
chmod +x mk_custom_iso.sh
# --- install package ---------------------------------------------------------
sudo apt-get install \
gawk \
tree \
gzip zstd bzip2 lzop \
xorriso
# --- create directory --------------------------------------------------------
sudo ./mk_custom_iso.sh -l create
sudo ./mk_custom_iso.sh -T
mkdir -p .workdirs/
sudo mount --bind /srv/user/private/ .workdirs/
# --- create iso file ---------------------------------------------------------
sudo ./mk_custom_iso.sh -c preseed
sudo ./mk_custom_iso.sh -m mini:2
# --- eot ---------------------------------------------------------------------
```
