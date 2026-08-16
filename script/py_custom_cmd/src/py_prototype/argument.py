#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import argparse
#import os
import subprocess
import sys

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
    cmd = ["tree", "--charset", "C", "-x", "-a", "--filesfirst", "{dirs_tops}"]
    print("\n" + cmd + ":\n")
    subprocess.run = cmd
#   rt = os.system(cmd) >> 8
#   sys.exit(rt)

sys.exit(0)
