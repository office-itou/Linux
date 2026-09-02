# --- Python library ----------------------------------------------------------
from dataclasses                        import dataclass, asdict
from pathlib                            import Path
from aiohttp                            import ClientError, ClientTimeout
from bs4                                import BeautifulSoup
from datetime                           import datetime, timezone
from natsort                            import natsort_keygen
#from tqdm import tqdm
#from urllib.parse import urlparse
import aiohttp # sudo apt-get install python3-aiohttp
import asyncio
import inspect
import re

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_colors                import color
from py_common.my_string                import eprint, omit_middle, generate_comment
from py_common.my_message               import message_warn, message_alert
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
@dataclass
class WebData:
    regexp:         str = ""
    url:            str = ""
    tmstamp:        str = ""
    size:           int = 0
    check:          str = ""
    status:         int = 0
    reason:         str = ""
    mime:           str = ""
    contents:       str = ""
    output:         str = ""

class InfoWeb:
    def __init__(self, data: WebData = None):
        self.data: WebData = data if data is not None else WebData()

    def get_data(self) -> WebData:
        return self.data

    async def get_info(self, session, target_regexp: str, target_path: str) -> WebData:
        self.data = await get_info(session, target_regexp, target_path)
        return self.data

    async def get_response(self, session, target_url: str) -> WebData:
        self.data = await get_response(session, target_url)
        return self.data

    async def get_header(self, session, target_url: str) -> WebData:
        self.data = await get_header(session, target_url)
        return self.data

    async def get_text(self, session, target_url: str) -> WebData:
        self.data = await get_text(session, target_url)
        return self.data

    def url_strip(self, data: str) -> str:
        return url_strip(data)

headers = {
    "Accept"                    : "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Encoding"           : "gzip, deflate, br, zstd",
    "Accept-Language"           : "ja,en;q=0.9,en-GB;q=0.8,en-US;q=0.7,ja-JP;q=0.6",
    "Cache-Control"             : "max-age=0",
    "Connection"                : "keep-alive",
    "Content-Security-Policy"   : "upgrade-insecure-requests",
    "User-Agent"                : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0",
}

# -----------------------------------------------------------------------------
# descript: url stripping
#   input : data                  : input 
#   output:                       : unused
#   return: text                  : output
#   global:                       : unused
# -----------------------------------------------------------------------------
def url_strip(data: str) -> str:
    text = re.sub(r"[\n|\r\n]$", '', data)      # remove lf or crlf
    text = re.sub(r"^\""       , '', text)      # remove the first double quotation mark
    text = re.sub(r"\"$"       , '', text)      # remove the last double quotation mark
    text = re.sub(r"^/"        , '', text)      # remove the first '/'
    text = re.sub(r"/$"        , '', text)      # remove the last '/'
    return text

# -----------------------------------------------------------------------------
# descript: get response
#   input : session               : input 
#   input : target_url            : input 
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
async def get_response(session, target_url: str) -> WebData:
    host = re.sub(r"http[s]*://([^/]+)/.*$", r"\1", target_url)
    headers['Host'] = host
    info = WebData()
    for r in range(3):
        try:
            async with session(target_url, allow_redirects=True, timeout=60) as response:
                info.url = target_url
                info.status = response.status if hasattr(response, 'status') else 0
                info.reason = response.reason if hasattr(response, 'reason') else ''
#               if info.status == 200:
                info.size = int(response.headers.get('Content-Length')) if response.headers.get('Content-Length') else 0
                info.tmstamp = datetime.strptime(response.headers.get('Last-Modified'), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if response.headers.get('Last-Modified') else ''
                info.memi = response.headers.get("content-type")
                info.contents = await response.text() if hasattr(response, 'text') else ''
                response.raise_for_status()
                break
        except aiohttp.ClientConnectorError as e:
            eprint(f"{color.bg_red}Connection failed: {e}{color.reset}")
            eprint(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except aiohttp.ClientResponseError as e:
            eprint(f"{color.bg_red}HTTP error status {e.status}: {e.message}{color.reset}")
            eprint(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except aiohttp.ClientError as e:
            eprint(f"{color.bg_red}Aiohttp general error: {e}{color.reset}")
            eprint(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except asyncio.TimeoutError:
            eprint(f"{color.bg_red}The request timed out.{color.reset}")
            eprint(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except Exception as e:
            eprint(f"{color.bg_red}Exception error: {e}{color.reset}")
            raise SystemExit
        else:
            pass
        finally:
            pass
    return info

# -----------------------------------------------------------------------------
# descript: get header
#   input : session               : input 
#   input : target_url            : input 
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
async def get_header(session, target_url: str) -> WebData:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{target_url}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    info = await get_response(session.head, target_url)
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return info if info else None

# -----------------------------------------------------------------------------
# descript: get text
#   input : session               : input 
#   input : target_url            : input 
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
async def get_text(session, target_url: str) -> WebData:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{target_url}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    info = await get_response(session.get, target_url)
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return info if info else None

# -----------------------------------------------------------------------------
# descript: get web information data
#   input : session               : input 
#   input : target_regexp         : input 
#   input : target_path           : input 
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
async def get_info(session, target_regexp: str, target_path: str) -> WebData:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{target_regexp}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    data = WebData()
    target_url = target_regexp
    match_dirs = ''
    match_ptrn = ''
    match_rear = ''
    while True:
        status = True
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", target_url)
        if not match:
            break
        match_dirs = url_strip(target_url[0:match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(target_url[match.end():])
        if match_rear:
            match_ptrn = match_ptrn + "/"
        target_url = match_dirs
        for i in range(3):
            data = await get_text(session, target_url)
            if data.status == 200: break
#           if data.status == 404: break
            message_warn(function_name, f"retry({i})")
            await asyncio.sleep(3)
        if data.status != 200:
            status = False
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, '# ' + '-' * infosystem.data.columns + ' #')
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"target_regexp:[{target_regexp}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"target_url   :[{target_url}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.regexp   :[{data.regexp}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.url      :[{data.url}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.tmstamp  :[{data.tmstamp}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.size     :[{data.size}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.check    :[{data.check}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.status   :[{data.status}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.reason   :[{data.reason}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.mime     :[{data.mime}]")
            if re.sub(r"/[^/]+$", '', data.mime) == 'text':
                debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.contents :[{data.contents}]")
            else:
                debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.contents :error: mime({data.mime})")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, f"web.output   :[{data.output}]")
            debugout(Path(__file__).stem + '('+ function_name + ')', 'Debugout', color.yellow, '# ' + '-' * infosystem.data.columns + ' #')
            break
        match_url = list()
        soup = BeautifulSoup(data.contents, "html.parser")
        for a in soup.find_all('a'):
            href = a.get('href')
            if not href:
                continue
            match = re.match(f"{match_ptrn}", href)
            if not match:
                continue
            match_url.append(match.group())
        if not match_url:
            continue
        match_url.sort(key=natsort_keygen(), reverse=True)
        target_url = target_url + "/" + match_url[0]
        if match_rear:
            target_url = target_url + match_rear
    # -------------------------------------------------------------------------
    if status == True:
        for i in range(5):
            data = await get_header(session, target_url)
            if data.status == 200: break
            if data.status == 404: break
            message_warn(function_name, f"retry({i})")
            await asyncio.sleep(3)
    # -------------------------------------------------------------------------
    data.regexp = target_regexp if target_regexp else '-'
    data.url = target_url if target_url else '-'
    filename = re.sub(r"^.+/", '', target_url)
    match filename:
        case 'mini.iso':
            match target_url:
                # https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso
                # https://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso
                case s if re.match(r"^http(|s)://.+/(debian|ubuntu)/dists/.+$", s):
                    arch = re.sub(r"/current/.+$", '', s)
                    arch = re.sub(r"^.+/.+-", '', arch)
                    code = re.sub(r"/main/.+$", '', s)
                    code = re.sub(r"^.+/", '', code)
                    code = re.sub(r"-.+$", '', code)
                    filename = f"mini-{code}-{arch}.iso"
                # https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso
                case s if re.match(r"^http(|s)://d-i.debian.org/daily-images/.+$", s):
                    arch = re.sub(r"/daily/.+$", '', s)
                    arch = re.sub(r"^.+/", '', arch)
                    filename = f"mini-testing-daily-{arch}.iso"
                case _:
                    pass
        # https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso                 
        # https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso    
        # https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso
        case s if re.match(r"debian-testing-.+-netinst\.iso", s):
            edtn = re.sub(r"^.+/cdimage/", '', target_url)
            edtn = re.sub(r"-.+", '', edtn)
            arch = re.sub(r"/iso-cd/.+$", '', target_url)
            arch = re.sub(r"^.+/", '', arch)
            bild = re.sub(r"/" + arch + r"/.+$", '', target_url)
            bild = re.sub(r"^.+/", '', bild)
            if bild: edtn = f"{edtn}-{bild}"
            filename = re.sub(arch, f"{edtn}-{arch}", filename)
        case _:
            pass
    data.output = str(Path(target_path).with_name(filename) if target_path and filename else '-')
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return data

# --- eof ---------------------------------------------------------------------
