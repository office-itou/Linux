import asyncio
import requests
from functools import partial
import datetime

urls = [
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-13.6.0-amd64-DVD-1.iso",
    "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso"
]

async def getsize(url):
    print(f"getsize({url}) START")
#    loop = asyncio.get_event_loop()
#    func = partial(requests.head, url, allow_redirects=True)
#    r = await loop.run_in_executor(None, func)
#    file_size = int(r.headers.get('Content-Length', 0))
#    file_date = datetime.datetime.strptime(r.headers["Last-Modified"], "%a, %d %b %Y %H:%M:%S GMT")
#    status = r.status_code
#    print(f"getsize({url}) END {file_date} {file_size} bytes ({status})")

#    loop = asyncio.get_event_loop()
#    func = partial(requests.get, url, allow_redirects=True)
#    response = await loop.run_in_executor(None, func)
#    user_data = response.json()  
#    print(f"getsize({url}) END {user_data["Last-Modified"]} {user_data["Content-Length"]} bytes")

    loop = asyncio.get_event_loop()
    func = partial(requests.head, url, allow_redirects=True)
    response = await loop.run_in_executor(None, func)
    status = response.status_code
    user_data = response.json()
    file_size = int({user_data["Content-Length"]})
    file_date = datetime.datetime.strptime({user_data["Last-Modified"]}, "%a, %d %b %Y %H:%M:%S GMT")
    print(f"getsize({url}) END {file_date} {file_size} bytes ({status})")

async def main():
    print('main() START')
    tasks = [asyncio.create_task(getsize(url)) for url in urls]
    await asyncio.gather(*tasks)
    print('main() END')

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
