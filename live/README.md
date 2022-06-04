## mmdebstrapを使用したDebian/Ubuntuの**日本語版Live DVD**の作成シェル  
  
### ・Debian上のdebootstrap.sh のヘルプ画面（GPG key指定有り）
  
``` bash:Debian上のdebootstrap.sh のヘルプ画面（GPG key指定有り）
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
  
### ・GPG keyファイルの保存例  
``` bash:ls ./keyring/
master@sv-server:~/mkcd$ ls ./keyring/
debian-archive-bullseye-automatic.gpg           debian-archive-stretch-security-automatic.gpg
debian-archive-bullseye-security-automatic.gpg  debian-archive-stretch-stable.gpg
debian-archive-bullseye-stable.gpg              ubuntu-archive-keyring.gpg
debian-archive-buster-automatic.gpg             ubuntu-archive-removed-keys.gpg
debian-archive-buster-security-automatic.gpg    ubuntu-cloudimage-keyring.gpg
debian-archive-buster-stable.gpg                ubuntu-cloudimage-removed-keys.gpg
debian-archive-keyring.gpg                      ubuntu-keyring-2012-cdimage.gpg
debian-archive-removed-keys.gpg                 ubuntu-keyring-2018-archive.gpg
debian-archive-stretch-automatic.gpg            ubuntu-master-keyring.gpg
```
  
### ・実行結果の例  
``` bash:ls ./debootstrap/
master@sv-server:~/mkcd$ ls ./debootstrap/
debian-live-10-oldstable-amd64-debootstrap.iso    debian.stable.i386
debian-live-10-oldstable-i386-debootstrap.iso     debian.testing.amd64
debian-live-11-stable-amd64-debootstrap.iso       debian.testing.i386
debian-live-9-oldoldstable-amd64-debootstrap.iso  ubuntu-live-18.04-bionic-i386-debootstrap.iso
debian-live-9-oldoldstable-i386-debootstrap.iso   ubuntu.bionic.amd64
debian-live-sid-testing-amd64-debootstrap.iso     ubuntu.bionic.i386
debian.oldoldstable.amd64                         ubuntu.focal.amd64
debian.oldoldstable.i386                          ubuntu.impish.amd64
debian.oldstable.amd64                            ubuntu.jammy.amd64
debian.oldstable.i386                             ubuntu.kinetic.amd64
debian.stable.amd64
```
  
## 参考  
* [日本語版Live DVDの作成：mmdebstrap debian / ubuntu](https://qiita.com/office-itou/items/f212b93d990ac97f6c98)  
  
## スクリーンショット  
| OS Ver.              | 画像1 | 画像2 | 画像3 |
| ---------------------| ----- | ----- | ----- |
| debian 11    stable  | (debian-live-11-stable-amd64-debootstrap.01.png)[https://github.com/office-itou/Linux/raw/master/live/picture/debian-live-11-stable-amd64-debootstrap.01.png] | (debian-live-11-stable-amd64-debootstrap.02.png)[https://github.com/office-itou/Linux/raw/master/live/picture/debian-live-11-stable-amd64-debootstrap.02.png] | (debian-live-11-stable-amd64-debootstrap.03.png)[https://github.com/office-itou/Linux/raw/master/live/picture/debian-live-11-stable-amd64-debootstrap.03.png] |
| ubuntu 22.10 kinetic | (ubuntu-live-22.10-kinetic-amd64-debootstrap.01.png)[https://github.com/office-itou/Linux/raw/master/live/picture/ubuntu-live-22.10-kinetic-amd64-debootstrap.01.png] | (ubuntu-live-22.10-kinetic-amd64-debootstrap.02.png)[https://github.com/office-itou/Linux/raw/master/live/picture/ubuntu-live-22.10-kinetic-amd64-debootstrap.02.png] | (ubuntu-live-22.10-kinetic-amd64-debootstrap.03.png)[https://github.com/office-itou/Linux/raw/master/live/picture/ubuntu-live-22.10-kinetic-amd64-debootstrap.03.png] |
  
