#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import inspect
import time
import re
import asyncio
import requests
from functools import partial
import datetime
import sys

def url_strip(text):
    text = re.sub(r"^\"", "", text)
    text = re.sub(r"\"$", "", text)
    text = re.sub(r"^/", "", text)
    text = re.sub(r"/$", "", text)
    return(text)

def version_key(v):
    v = re.sub(r"^[^0-9]*([0-9.]+).*$", r"\1", v)
#   print("v:" + v)
    return [int(x) for x in v.split(".")]

def getinfo_head(url):
#   func_name = inspect.currentframe().f_code.co_name
#   print(f"{func_name}({url}) START")
#   time.sleep(2)
    response = requests.head(url, allow_redirects=True, timeout=(10.0, 30.0))
    stat_code = int(response.status_code)
    stat_mesg = response.reason
    if stat_code == 200:
        file_size = int(response.headers.get("Content-Length"))
        file_date = datetime.datetime.strptime(response.headers.get("Last-Modified"), "%a, %d %b %Y %H:%M:%S GMT")
    else:
        file_size = 0
        file_date = "-"
#   print(f"{func_name}({url}) END [{stat_code}:\"{stat_mesg}\"]")
    return [url, f"{file_date}", file_size, stat_code, f"{stat_mesg}"]

def getinfo_filename(url, ptrn):
#   func_name = inspect.currentframe().f_code.co_name
#   print(f"{func_name}({url}) START")
#   time.sleep(2)
    response = requests.get(url, allow_redirects=True, timeout=(10.0, 30.0))
    stat_code = int(response.status_code)
    stat_mesg = response.reason
    match_text = ""
    if stat_code == 200:
        result = re.findall(r'<a href="' + ptrn + r'/*"[^>]*>', response.text)
#       print("result")
#       print(result)
        list = []
        for text in result:
            text = re.sub(r"^[^\"]*", "", text)
            text = re.sub(r"[^\"]*$", "", text)
            text = url_strip(text)
            list.append(text)
#       print("list")
#       print(list)
        list.sort(key=version_key, reverse=True)
#       print(list)
        match_text = list[0]
#   print(f"{func_name}({url}) END [{stat_code}:\"{stat_mesg}\"]")
    return [f"{match_text}", stat_code, f"{stat_mesg}"]

def getinfo(url):
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", url)
        if not match:
            list = getinfo_head(url)
            return(list)
        else:
            match_dirs = url_strip(url[0:match.start()])
            match_ptrn = url_strip(match.group())
            match_rear = url_strip(url[match.end():])
#           print(match_dirs)
#           print(match_ptrn)
#           print(match_rear)
            list = getinfo_filename(match_dirs + "/", match_ptrn)
            if not match_rear:
#               list = getinfo_filename(match_dirs, match_ptrn)
                url = match_dirs + "/" + list[0]
            else:
#               list = getinfo_filename(match_dirs + "/", match_ptrn)
                url = match_dirs + "/" + list[0] + "/" +match_rear
#           print(url)

url = "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso"
list = getinfo(url)
print(list)

url = "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.[0-9.]*-amd64-netinst.iso"
list = getinfo(url)
print(list)

url = "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso"
list = getinfo(url)
print(list)
