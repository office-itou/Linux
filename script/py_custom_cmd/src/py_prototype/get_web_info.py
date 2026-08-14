import asyncio
import requests
from functools import partial
import datetime

urls = [
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-13.6.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso",
    "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso.dummy"
]

async def getsize(url):
    print(f"getsize({url}) START")
    loop = asyncio.get_event_loop()
    func = partial(requests.head, url, allow_redirects=True)
    response = await loop.run_in_executor(None, func)
    stat_nums = int(response.status_code)
    stat_mesg = response.reason
    if stat_nums == 200:
        file_size = int(response.headers.get("Content-Length"))
        file_date = datetime.datetime.strptime(response.headers.get("Last-Modified"), "%a, %d %b %Y %H:%M:%S GMT")
        print(f"getsize({url}) END {file_date} {file_size} bytes ({stat_nums})")
    else:
        print(f"getsize({url}) END status: {stat_nums} [{stat_mesg}]")

async def main():
    print('main() START')
    tasks = [asyncio.create_task(getsize(url)) for url in urls]
    await asyncio.gather(*tasks)
    print('main() END')

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
