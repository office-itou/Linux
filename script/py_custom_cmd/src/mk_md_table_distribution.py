#!/usr/bin/env python3
# encoding: utf-8

# sudo apt-get install python3-pandas
import pandas as pd

#import py_common
from py_common.common_cfg       import Common_cfg
from py_common.distribution_dat import Distribution_dat
from py_common.media_dat        import Media_dat

# --- 
#class Common_Data:
#    def __init__(self):
#        self.conf = []                  # common configuration file
#        self.dist = []                  # distribution data file
#        self.mdia = []                  # media data file
#    def load_conf(self):
#        self.conf = py_common.common_cfg.get()              # get common configuration file
#        return self.conf
#    def get_conf(self, key):
#        return self.conf[key]
#    def set_conf(self, key, value):
#        self.conf[key] = value

def generate_table_debian():
    return

def generate_table_fedora():
    return

def generate_table():
    return

comm_conf = Common_cfg()
dist_data = Distribution_dat()
mdia_data = Media_dat()

def initialize():
    comm_conf.load()
    conf = comm_conf.dump()
    dist_data.load(conf)
    dist = dist_data.dump()
    mdia_data.load(conf, dist)
    return

def main():
    initialize()
#   print(comm_conf.dump())
#    print("comm_conf.get(\"DIRS_TOPS\"):" + comm_conf.get("DIRS_TOPS"))
#    print("dist_data.dump():")
#    print(dist_data.dump())
#    print("mdia_data.dump():")
#    print(mdia_data.dump())
#    conf = comm_conf.dump()
#    print(conf.keys())
#    for dist in dist_data.dump():
#        print(dist.get("version"))

    dist = dist_data.dump()
    result = pd.json_normalize(data=dist, record_path='')
    print(result)

#   print("dist_data.get(\"version\"):" + dist_data.get("version"))

if __name__ == "__main__":
    main()

#print('グローバル変数:', globals())
#print('ローカル変数:', locals())
