# **[mk_custom_iso.sh](./custom_cmd/mk_custom_iso.sh)**

## **help**

``` bash:
$ sudo ./mk_custom_iso.sh
usage: [sudo] ./mk_custom_iso.sh (options) [command]
  commands:
    -h|--help   : this message output
    -l|--link   : making directories and symbolic links
    -c|--conf   : making preconfiguration files
    -p|--pxe    : making pxeboot menu
    -m|--make   : making iso files
    -P|--DBGP   : debug output for internal global variables
    -T|--TREE   : debug output in a directory tree-like format
  options:
    -D|--debug   |--dbg     : debug output with code
    -O|--debugout|--dbgout  : debug output without code
```

## **making directories and symbolic links**

``` bash:
# Recreate all directories
$ sudo ./mk_custom_iso.sh -l create
```

## **making preconfiguration files**

``` bash:
# Recreate all files: [a|all]
$ sudo ./mk_custom_iso.sh -c a
# Recreate each file: [ agama | autoyast | kickstart | nocloud | preseed ]
$ sudo ./mk_custom_iso.sh -c preseed kickstart
```

## **making pxeboot menu**

``` bash:
# Recreate all files: [a|all]
$ sudo ./mk_custom_iso.sh -p a
# Recreate each file: [ mini:[a|n] | netinst:[a|n] | dvd:[a|n] | liveinst:[a|n] | live:[a|n] | tool ]
$ sudo ./mk_custom_iso.sh -p mini:a netinst:{2..4} dvd:2
```

## **making iso files**

``` bash:
# Recreate all files: [a|all]
$ sudo ./mk_custom_iso.sh -m a
# Recreate each file: [ mini:[a|n] | netinst:[a|n] | dvd:[a|n] | liveinst:[a|n] | live:[a|n] | tool ]
$ sudo ./mk_custom_iso.sh -m mini:a netinst:{2..4} dvd:2
# Waiting for number entry (If you do not specify anything after the colon)
$ sudo ./mk_custom_iso.sh -m netinst:
```
