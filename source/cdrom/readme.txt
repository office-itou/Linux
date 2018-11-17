・開発環境
  sudo aptitude install linux-headers-`uname -r` build-essential indent
  (debian 9.6とubuntu 18.10でにて開発。その他OS/kernelは未定)

・使用方法
  ### driver ###
  cd knl
  make clean && env LANG=C make
  sudo insmod sremu.ko
  sudo rmmod sremu && sudo insmod sremu.ko
  ### mounter ###
  cd cmd
  make clean && make
  sudo ./sr_mount cdda.cue /dev/sremu0
  ### testing ###
  sudo rm -f data.toc data.bin && sudo cdrdao read-cd --device /dev/sremu0 --read-raw --with-cddb data.toc
  sudo cdparanoia 1- -p -d /dev/sremu0 data.pcm

・注意事項
　未検証品につき重大な事故が起きてもリカバリーできる環境にて実施する事。
　当方ではどの様な損害が発生しても責任は負わないのでその旨を理解の上使用する事。
