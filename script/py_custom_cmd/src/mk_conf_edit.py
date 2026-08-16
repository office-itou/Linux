#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import argparse
import os
import subprocess
import sys

import py_common

flag_debug=""

# --- get command line options ------------------------------------------------
#for argv in sys.argv:
#    match argv:
#        case "-d" | "--debug":
#            flag_debug = "on"

parser = argparse.ArgumentParser()
#parser.add_argument("-h", "--help")
parser.add_argument("-D", "--debug", "--dbg", nargs='?', help="debug")
parser.add_argument("-O", "--debugout", "--dbgout", nargs='?', help="debug out")
#parser.add_argument("-l", "--link")
#parser.add_argument("-c", "--conf")
#parser.add_argument("-p", "--pxe")
#parser.add_argument("-m", "--make")
#parser.add_argument("-P", "--DBGP")
parser.add_argument("-T", "--TREE", nargs='?', type=str, default="", help="tree diagram")

args = parser.parse_args()

print(args)
print(args.debug)
print(args.debugout)
print(args.TREE)

if args.TREE != "":
    dirs_tops = args.TREE
    if not dirs_tops:
        dirs_tops = "/srv"
    cmd = f"tree --charset C -x -a --filesfirst {dirs_tops}"
    print("\n" + cmd + ":\n")
    rt = os.system(cmd) >> 8
    sys.exit(rt)

#sys.exit(0)

# --- get common data file ----------------------------------------------------
conf = py_common.common_cfg.get()                       # get common configuration file
if flag_debug != "":
    py_common.common_cfg.debug(conf)

list_dist = py_common.distribution_dat.get(conf)        # get distribution data file
if flag_debug != "":
    py_common.distribution_dat.debug(list_dist)

list_mdia = py_common.media_dat.get(conf, list_dist)    # get media data file
if flag_debug != "":
    py_common.media_dat.debug(list_mdia)

# --- put common data file ----------------------------------------------------
py_common.distribution_dat.put(conf, list_dist)
py_common.distribution_dat.json2text(conf)
py_common.media_dat.put(conf, list_mdia)
py_common.media_dat.json2text(conf, list_dist)
