#!/usr/bin/env python3
# encoding: utf-8

import inspect
import asyncio
import requests
from functools import partial
from bs4 import BeautifulSoup
import re
import datetime

def url_strip(text):
    text = re.sub(r"^\"", "", text)
    text = re.sub(r"\"$", "", text)
    text = re.sub(r"^/", "", text)
    text = re.sub(r"/$", "", text)
    return(text)

def version_key(v):
    v = re.sub(r"^[^0-9]*([0-9.]+).*$", r"\1", v)
    return [int(x) for x in v.split(".")]

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Connection": "close",
}

async def getsize(url):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", url)
        if not match:
            break
        # === get directory and file name =====================================
        match_dirs = url_strip(url[0:match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(url[match.end():])
        url = match_dirs + "/"
        # --- request ---------------------------------------------------------
        loop = asyncio.get_event_loop()
        func = partial(requests.get, url, allow_redirects=True, headers=headers, timeout=(30, 30))
        response = await loop.run_in_executor(None, func)
        if not response:
            if not response.status_code:
                stat_code = -1
            else:
                stat_code = int(response.status_code)
            if not response.reason:
                stat_mesg = "ABORT (GET)"
            else:
                stat_mesg = response.reason
            print(f"{func_name}({url}) {stat_mesg}")
            return f"{url},\"-\",0,{stat_code},\"{stat_mesg}\""
        else:
            stat_code = int(response.status_code)
            stat_mesg = response.reason
            # --- error detection ---------------------------------------------
            if stat_code < 200 or stat_code > 299:
                file_date = "-"
                file_size = 0
                print(f"{func_name}({url}) ERROR (GET)")
                return f"{url},\"{file_date}\",{file_size},{stat_code},\"{stat_mesg}\""
        # --- pattern matching ------------------------------------------------
        soup = BeautifulSoup(response.text, "html.parser")
        list = []
        for a in soup.find_all('a'):
            href = a.get('href')
            if not href:
                continue
            match = re.match(f"^{match_ptrn}", href)
            if not match:
                continue
            list.append(match.group())
        if not list:
            continue
        list.sort(key=version_key, reverse=True)
        url = url + list[0]
        if match_rear:
            url = url + "/" + match_rear
    # === get file information ================================================
    # --- request -------------------------------------------------------------
    loop = asyncio.get_event_loop()
    func = partial(requests.head, url, allow_redirects=True, headers=headers, timeout=(30, 30))
    response = await loop.run_in_executor(None, func)
    if not response:
        if not response.status_code:
            stat_code = -1
        else:
            stat_code = int(response.status_code)
        if not response.reason:
            stat_mesg = "ABORT (HEAD)"
        else:
            stat_mesg = response.reason
        print(f"{func_name}({url}) {stat_mesg}")
        return f"{url},\"-\",0,{stat_code},\"{stat_mesg}\""
    else:
        stat_code = int(response.status_code)
        stat_mesg = response.reason
        # --- error detection -------------------------------------------------
        if stat_code < 200 or stat_code > 299:
            file_date = "-"
            file_size = 0
            print(f"{func_name}({url}) ERROR (HEAD)")
        else:
            file_size = int(response.headers.get("Content-Length"))
            file_date = datetime.datetime.strptime(response.headers.get("Last-Modified"), "%a, %d %b %Y %H:%M:%S GMT")
            print(f"{func_name}({url}) END")
    return f"{url},\"{file_date}\",{file_size},{stat_code},\"{stat_mesg}\""

async def main():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    tasks = [asyncio.create_task(getsize(url)) for url in urls]
    results = await asyncio.gather(*tasks)
    print("result: ")
    for result in results:
        if not result:
            continue
        print(result)
    print(f"{func_name}() END")

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
