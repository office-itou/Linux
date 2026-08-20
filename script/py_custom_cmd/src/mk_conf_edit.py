#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import argparse
import os
import subprocess
import sys

import py_common
from py_common.common_cfg       import Common_cfg
from py_common.distribution_dat import Distribution_dat
from py_common.media_dat        import Media_dat

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

#print(args)
#print(args.debug)
#print(args.debugout)
#print(args.TREE)

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
comm_conf = Common_cfg()
dist_data = Distribution_dat()
mdia_data = Media_dat()

def initialize():
    comm_conf.load()
    dist_data.load(comm_conf.conf)
    mdia_data.load(comm_conf.conf, dist_data.data)
    return

def debug():
    comm_conf.debug()
    dist_data.debug()
    mdia_data.debug()

def save_json():
    dist_data.save(comm_conf.conf)
    mdia_data.save(comm_conf.conf)

def conv_text():
    py_common.distribution_dat.json2text(comm_conf.conf)
    py_common.media_dat.json2text(comm_conf.conf, dist_data.data)

def conv_json():
    comm_conf.load()
    py_common.distribution_dat.text2json(comm_conf.conf)
    py_common.media_dat.text2json(comm_conf.conf)

#initialize()
#debug()
#save_json()
#conv_text()
conv_json()
