## mmdebstrapを使用したDebian/Ubuntu**日本語版Live DVD**作成シェル  
  
### ・Debian上のdebootstrap.sh ヘルプ画面（GPG key指定有り）
  
``` bash:Debian上のdebootstrap.sh ヘルプ画面（GPG key指定有り）
master@sv-server:~/mkcd$ ./debootstrap.sh -k ./keyring/
  usage: sudo ./debootstrap.sh -a architecture -s suite [ -k directory ]

    -h,--help  : This message.
    -l,--log   : Output log to text file.
    -a,--arch  : See arch below.
    -s,--suite : See suite below.
    -k,--key   : GPG key file directory.

    arch       : suite           : distribution
    amd64,i386 : oldoldstable    : Debian  9.xx(stretch)
    amd64,i386 : oldstable       : Debian 10.xx(buster)
    amd64,i386 : stable          : Debian 11.xx(bullseye)
    amd64,i386 : testing         : Debian 12.xx(bookworm)
    amd64,i386 : bionic          : Ubuntu 18.04(Bionic Beaver):LTS
    amd64      : focal           : Ubuntu 20.04(Focal Fossa):LTS
    amd64      : impish          : Ubuntu 21.10(Impish Indri)
    amd64      : jammy           : Ubuntu 22.04(Jammy Jellyfish):LTS
    amd64      : kinetic         : Ubuntu 22.10(Kinetic Kudu)
```
  
### ・実行方法の例（全スイート対象・GPG key指定・ログ出力）  
``` bash:実行方法の例（全スイート対象・GPG key指定・ログ出力）
sudo bash -c '
rm -f ./debootstrap.log
for S in oldoldstable oldstable stable testing bionic focal impish jammy kinetic
do
  for A in amd64 i386
  do
    ./debootstrap.sh -a $A -s $S -k ./keyring/ -l
  done
done
'
```
  
実行時のログ例：[debootstrap.log](https://github.com/office-itou/Linux/blob/master/live/debootstrap.log)
  
### ・GPG keyファイルのダウンロードと解凍（Ubuntu上にて）  
``` bash:GPG keyファイルのダウンロードと解凍（Ubuntu上にて）
sudo rm -rf ./work/ ./keyring/
sudo mkdir -p ./work ./keyring
apt-get download ubuntu-keyring
apt-get download debian-archive-keyring
ls -l
sudo dpkg -x ./debian-archive-keyring_2021.1.1ubuntu2_all.deb ./work/
sudo dpkg -x ./ubuntu-keyring_2021.03.26_all.deb ./work/
sudo find ./work/ -type f -name "*.gpg" -print -exec cp -p {} ./keyring/ \;
```
  
### ・ディレクトリー／ファイル構成  
``` bash: ディレクトリー／ファイル構成
.
|   debootstrap.sh  （実行ファイル）
|   debootstrap.log （ログファイル）
|
|-- debootstrap
|   |   debian-live-9-oldoldstable-amd64-debootstrap.iso    amd64：oldoldstable
|   |   debian-live-9-oldoldstable-i386-debootstrap.iso     i386 ：〃
|   |   debian-live-10-oldstable-amd64-debootstrap.iso      amd64：oldstable
|   |   debian-live-10-oldstable-i386-debootstrap.iso       i386 ：〃
|   |   debian-live-11-stable-amd64-debootstrap.iso         amd64：stable
|   |   debian-live-11-stable-i386-debootstrap.iso          i386 ：〃 （2022/6/5現在作成不可）
|   |   debian-live-sid-testing-amd64-debootstrap.iso       amd64：testing
|   |   debian-live-sid-testing-i386-debootstrap.iso        i386 ：〃
|   |   ubuntu-live-18.04-bionic-amd64-debootstrap.iso      amd64：bionic
|   |   ubuntu-live-18.04-bionic-i386-debootstrap.iso       i386 ：〃
|   |   ubuntu-live-20.04-focal-amd64-debootstrap.iso       amd64：focal
|   |   ubuntu-live-21.10-impish-amd64-debootstrap.iso      amd64：impish
|   |   ubuntu-live-22.04-jammy-amd64-debootstrap.iso       amd64：jammy
|   |   ubuntu-live-22.10-kinetic-amd64-debootstrap.iso     amd64：kinetic
|   |
|   |-- debian.oldoldstable.amd64
|   |-- debian.oldoldstable.i386
|   |-- debian.oldstable.amd64
|   |-- debian.oldstable.i386
|   |-- debian.stable.amd64
|   |-- debian.stable.i386
|   |-- debian.testing.amd64
|   |-- debian.testing.i386
|   |-- ubuntu.bionic.amd64
|   |-- ubuntu.bionic.i386
|   |-- ubuntu.focal.amd64
|   |-- ubuntu.impish.amd64
|   |-- ubuntu.jammy.amd64
|   +-- ubuntu.kinetic.amd64
|       |   0000-user.conf
|       |   9999-user.conf
|       |   9999-user-setting
|       |   debian-cd_info-stable-amd64.tar.gz
|       |   inst-net.sh
|       |   linux_signing_key.pub
|       |   splash.png
|       |
|       |-- _work
|       |-- cdimg
|       |-- fsimg
|       +-- media
|
+-- keyring
        debian-archive-bullseye-automatic.gpg
        debian-archive-bullseye-security-automatic.gpg
        debian-archive-bullseye-stable.gpg
        debian-archive-buster-automatic.gpg
        debian-archive-buster-security-automatic.gpg
        debian-archive-buster-stable.gpg
        debian-archive-keyring.gpg
        debian-archive-removed-keys.gpg
        debian-archive-stretch-automatic.gpg
        debian-archive-stretch-security-automatic.gpg
        debian-archive-stretch-stable.gpg
        ubuntu-archive-keyring.gpg
        ubuntu-archive-removed-keys.gpg
        ubuntu-cloudimage-keyring.gpg
        ubuntu-cloudimage-removed-keys.gpg
        ubuntu-keyring-2012-cdimage.gpg
        ubuntu-keyring-2018-archive.gpg
        ubuntu-master-keyring.gpg
```
  
## 参考  
* [日本語版Live DVDの作成：mmdebstrap debian / ubuntu](https://qiita.com/office-itou/items/f212b93d990ac97f6c98)  
  
## スクリーンショット  
|   debian 11 stable   | ubuntu 22.10 kinetic |
| :------------------: | :------------------: |
| <img src="https://github.com/office-itou/Linux/raw/master/live/picture/debian-live-11-stable-amd64-debootstrap.01.png" width="640"> | <img src="https://github.com/office-itou/Linux/raw/master/live/picture/ubuntu-live-22.10-kinetic-amd64-debootstrap.01.png" width="640"> |
| <img src="https://github.com/office-itou/Linux/raw/master/live/picture/debian-live-11-stable-amd64-debootstrap.02.png" width="640"> | <img src="https://github.com/office-itou/Linux/raw/master/live/picture/ubuntu-live-22.10-kinetic-amd64-debootstrap.02.png" width="640"> |
| <img src="https://github.com/office-itou/Linux/raw/master/live/picture/debian-live-11-stable-amd64-debootstrap.03.png" width="640"> | <img src="https://github.com/office-itou/Linux/raw/master/live/picture/ubuntu-live-22.10-kinetic-amd64-debootstrap.03.png" width="640"> |
  
