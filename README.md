Debian/Ubuntu/CentOS/Knoppix�̃J�X�^�}�C�Y
**���{�ꉻ��C���X�g�[���⏕�Ɉȉ��̃V�F�����쐬���܂����B**
�EDebian/Ubuntu/Knoppix��Live DVD�C���[�W�̃J�X�^�}�C�Y
�EDebian/Ubuntu/CentOs7�̃C���X�g�[��DVD�C���[�W�̃J�X�^�}�C�Y
�EDebian/Ubuntu�̃C���X�g�[��mini.iso�C���[�W�̃J�X�^�}�C�Y
�EDebian/Ubuntu/CrntOS7�̃C���X�g�[���⏕(VMware�Ή�)
*��VMware14���mbr��uefi���œ���m�F*

**Live CD�p** (���{�ꉻ��Debian/Ubuntu�̃��W���[���ŐV��)
�E[debian-lxde.sh](https://github.com/office-itou/Linux/blob/master/customize/debian-lxde.sh?ts=4)
�E[ubuntu-live.sh](https://github.com/office-itou/Linux/blob/master/customize/ubuntu-live.sh?ts=4)
�E[knoppix-live.sh](https://github.com/office-itou/Linux/blob/master/customize/knoppix-live.sh?ts=4)

**DVD�p** (preseed.cfg,kickstart.cfg���g�p�������l�C���X�g�[���̎���) 
�E[dist_remaster_dvd.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_dvd.sh?ts=4)
**mini.iso�p** (preseed.cfg���g�p�������l�C���X�g�[���̎���) 
�E[dist_remaster_mini.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_mini.sh?ts=4)

**preseed.cfg** (OS�̖��l�C���X�g�[���ݒ�)
�E[preseed_debian.cfg](https://github.com/office-itou/Linux/blob/master/installer/preseed_debian.cfg?ts=4)
�E[preseed_ubuntu.cfg](https://github.com/office-itou/Linux/blob/master/installer/preseed_ubuntu.cfg?ts=4) (mini.iso�g�p�𐄏��ADVD�ł͑S�@�\�̓���������Ȃ�)
**kickstart.cfg** (OS�̖��l�C���X�g�[���ݒ�)
�E[kickstart_centos.cfg](https://github.com/office-itou/Linux/blob/master/installer/kickstart_centos.cfg?ts=4)

**Debian/Ubuntu/CentOS7���ݒ�** (OS������̊��ݒ�)
�E[install.sh](https://github.com/office-itou/Linux/blob/master/installer/install.sh?ts=4)

**preseed.cfg�̊��ݒ�l��** (�e���̊��ɍ��킹�ĕύX�肢�܂�)
�Q�ƁF[preseed�̗��p](https://www.debian.org/releases/stable/amd64/apbs02.html.ja)

```text
# == Network configuration ====================================================
  d-i netcfg/choose_interface select auto
  d-i netcfg/disable_dhcp boolean true
# -- Static network configuration. --------------------------------------------
  d-i netcfg/get_ipaddress string 192.168.1.1
  d-i netcfg/get_netmask string 255.255.255.0
  d-i netcfg/get_gateway string 192.168.1.254
  d-i netcfg/get_nameservers string 192.168.1.254
  d-i netcfg/confirm_static boolean true
# -- hostname and domain names ------------------------------------------------
  d-i netcfg/get_hostname string sv-debian
  d-i netcfg/get_domain string workgroup
```

```text
# == Account setup ============================================================
  d-i passwd/root-login boolean false
  d-i passwd/make-user boolean true
# -- Root password, either in clear text or encrypted -------------------------
# d-i passwd/root-password password r00tme
# d-i passwd/root-password-again password r00tme
# d-i passwd/root-password-crypted password [crypt(3) hash]
# -- Normal user's password, either in clear text or encrypted ----------------
  d-i passwd/user-fullname string Master
  d-i passwd/username string master
  d-i passwd/user-password password master
  d-i passwd/user-password-again password master
# d-i passwd/user-password-crypted password [crypt(3) hash]
```

```text
# == Package selection ========================================================
  tasksel tasksel/first multiselect \
    desktop, lxde-desktop, ssh-server, web-server
  d-i pkgsel/include string \
    sudo tasksel network-manager curl bc \
    perl apt-show-versions libapt-pkg-perl libauthen-pam-perl libio-pty-perl libnet-ssleay-perl perl-openssl-defaults \
    clamav bind9 dnsutils apache2 vsftpd isc-dhcp-server ntpdate samba smbclient cifs-utils rsync \
    chromium chromium-l10n
```
**�g�p��**

```text:dist_remaster_dvd.sh
master@sv-debian:~/iso$ sudo ./dist_remaster_dvd.sh
*******************************************************************************
2018/05/06 09:50:44 �쐬�������J�n���܂��B
*******************************************************************************
# ---------------------------------------------------------------------------#
# ID�FVersion                       �F�����[�X���F�T�|�I�����F���l           #
#  1�Fdebian-7.11.0-amd64-DVD-1     �F2013-05-04�F2018-05-31�Foldoldstable   #
#  2�Fdebian-8.10.0-amd64-DVD-1     �F2015-04-25�F2020-04-xx�Foldstable      #
#  3�Fdebian-9.4.0-amd64-DVD-1      �F2017-06-17�F2022-xx-xx�Fstable         #
#  4�Fubuntu-14.04.5-server-amd64   �F2014-04-17�F2019-04-xx�FTrusty Tahr    #
#  5�Fubuntu-14.04.5-desktop-amd64  �F    �V    �F    �V    �F  �V           #
#  6�Fubuntu-16.04.4-server-amd64   �F2016-04-21�F2021-04-xx�FXenial Xerus   #
#  7�Fubuntu-16.04.4-desktop-amd64  �F    �V    �F    �V    �F  �V           #
#  8�Fubuntu-17.10.1-server-amd64   �F2017-10-19�F2018-07-xx�FArtful Aardvark#
#  9�Fubuntu-17.10.1-desktop-amd64  �F    �V    �F    �V    �F  �V           #
# 10�Fubuntu-18.04-server-amd64     �F2018-04-26�F2023-04-xx�FBionic Beaver  #
# 11�Fubuntu-18.04-desktop-amd64    �F    �V    �F    �V    �F  �V           #
# 12�Fubuntu-18.04-live-server-amd64�F    �V    �F    �V    �F  �V           #
# 13�FCentOS-7-x86_64-DVD-1708      �F2017-09-14�F2024-06-30�F               #
# ---------------------------------------------------------------------------#
ID�ԍ�+Enter����͂��ĉ������B
{1..11} 13
   �` �ȗ� �`
```

```text:dist_remaster_mini.sh
master@sv-debian:~/iso$ sudo ./dist_remaster_mini.sh
*******************************************************************************
2018/05/06 09:42:07 �쐬�������J�n���܂��B
*******************************************************************************
# ---------------------------------------------------------------------------#
# ID�FVersion     �F�R�[�h�l�[��    �F�����[�X���F�T�|�I�����F���l           #
#  1�FDebian  7.xx�Fwheezy          �F2013-05-04�F2018-05-31�Foldoldstable   #
#  2�FDebian  8.xx�Fjessie          �F2015-04-25�F2020-04-xx�Foldstable      #
#  3�FDebian  9.xx�Fstretch         �F2017-06-17�F2022-xx-xx�Fstable         #
#  4�FDebian 10.xx�Fbuster          �F2019(�\��)�F          �Ftesting        #
#  5�FUbuntu 14.04�FTrusty Tahr     �F2014-04-17�F2019-04-xx�F               #
#  6�FUbuntu 16.04�FXenial Xerus    �F2016-04-21�F2021-04-xx�F               #
#  7�FUbuntu 17.10�FArtful Aardvark �F2017-10-19�F2018-07-xx�F               #
#  8�FUbuntu 18.04�FBionic Beaver   �F2018-04-26�F2023-04-xx�F               #
# ---------------------------------------------------------------------------#
ID�ԍ�+Enter����͂��ĉ������B
{1..8}
  �` �ȗ� �`
*******************************************************************************
2018/05/06 09:44:59 �쐬�������I�����܂����B
*******************************************************************************
```