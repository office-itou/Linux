## mmdebstrapを使用したDebian/Ubuntuの**日本語版Live DVD**の作成シェル  
  
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
  
## 参考  
* [日本語版Live DVDの作成：mmdebstrap debian / ubuntu](https://qiita.com/office-itou/items/f212b93d990ac97f6c98)  
