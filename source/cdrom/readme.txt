・開発環境
  sudo aptitude install linux-headers-`uname -r` build-essential indent

・使用方法
  ### driver ###
  cd dev
  make clean && make
  sudo insmod srdev.ko
  sudo rmmod srdev && sudo insmod srdev.ko
  ### mounter ###
  cd cmd
  make clean && make
  sudo ./sr_mount cdda.cue /dev/srdev0
  ### testing ###
  sudo rm -f data.toc data.bin && sudo cdrdao read-cd --device /dev/srdev0 data.toc

・注意事項
　未検証品につき重大な事故が起きてもリカバリーできる環境にて実施する事。
　当方ではどの様な損害が発生しても責任は負わないのでその旨を理解の上使用する事。
