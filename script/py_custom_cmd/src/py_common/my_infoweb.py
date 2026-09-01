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
from py_common.my_string                import eprint, omit_middle
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
    def __init__(self):
        self.data: WebData = WebData()
    def get_data(self) -> WebData:
        return self.data
    def get_info(self, session, target_regexp: str, target_path: str) -> WebData:
        self.data = get_info(session, target_regexp, target_path)
        return self.data
    def get_response(self, session, target_url: str) -> WebData:
        self.data = get_response(session, target_url)
    def get_header(self, session, target_url: str) -> WebData:
        self.data = get_header(session, target_url)
    def get_text(self, session, target_url: str) -> WebData:
        self.data = get_text(session, target_url)
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
            async with session(target_url, allow_redirects=True, headers=headers, timeout=10) as response:
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
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
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
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
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
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
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
            if 200 <= data.status <= 299: break
            if data.status == 404: break
            message_warn(function_name, f"retry({i})")
            await asyncio.sleep(3)
    data.regexp = target_regexp
    data.url = target_url
    data.output = target_path
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return data

# --- eof ---------------------------------------------------------------------
