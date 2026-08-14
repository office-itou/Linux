#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import sys
import os
import glob
import re

import py_common
import mk_ipxe_menu

flg_debug=""

# --- get command line options ------------------------------------------------
for argv in sys.argv:
    match argv:
        case "-d" | "--debug":
            flg_debug = "on"

# --- get setting items -------------------------------------------------------
file_conf="common.cfg"                  # common configuration file
path_conf=""                            # common configuration file
for path in ["./" + file_conf, "/srv/user/share/conf/_data/" + file_conf]:
    if not os.path.exists(path):
        continue
    path_conf = path
    break

if path_conf == "":
    print("file not found: " + file_conf)
    sys.exit(1)

#path_conf = "/srv/user/share/conf/_data/common.cfg"
conf = py_common.common_cfg.get(path_conf)
if flg_debug != "":
    py_common.common_cfg.debug(conf)

# --- create from templates ---------------------------------------------------
def create_from(dirs_tmpl, dirs_tftp):
    for file_impt in glob.glob(dirs_tmpl + '/ipxe/*.ipxe'):
        file_name = os.path.basename(file_impt)
        dirs_outp = dirs_tftp + "/ipxe"
        if file_name != "autoexec.ipxe":
            dirs_outp = dirs_outp + "/menu"
        file_outp = dirs_outp + "/" + file_name
        text = ""
        for line in open(file_impt, "r", encoding='utf-8'):
            match = re.search(r":_[a-zA-Z0-9]+_[a-zA-Z0-9]+_:", line)
            if match:
                match_text  = match.group()
                match_key   = re.sub(r"^:_", "", match_text)
                match_key   = re.sub(r"_:$", "", match_key)
                match_value = conf[match_key]
                line = re.sub(r":_" + match_key + "_:", match_value, line)
            text = text + line
        with open(file_outp, "w", encoding='utf-8') as f:
            print("create of " + file_outp)
            f.write(text)

# --- Create of templates -----------------------------------------------------
def create_of_sub(dirs_tmpl, obj):
    path = dirs_tmpl + "/ipxe/" + obj.filename
    text = obj.script + mk_ipxe_menu.ipxe_menu_common.script
    print("create of " + path)
    with open(path, "w", encoding='utf-8') as f:
        f.write(text)

def create_of(dirs_tmpl):
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_autoexec)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_booting)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_debian)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_ubuntu)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_fedora)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_centos)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_almalinux)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_rockylinux)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_miraclelinux)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_opensuse)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_windows)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_live)
    create_of_sub(dirs_tmpl, mk_ipxe_menu.ipxe_menu_custom_live)

dirs_tmpl = conf["DIRS_TMPL"]           # templates for various configuration files : '/srv/user/share/conf/_template'
dirs_tftp = conf["DIRS_TFTP"]           # tftp contents                             : '/srv/tftp'

create_of(dirs_tmpl)
create_from(dirs_tmpl, dirs_tftp)
