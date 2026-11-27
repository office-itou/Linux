# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_ipfilter(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)


# --- ipfilter.conf -------------------------------------------------------
# 	__PATH="${_DIRS_TGET:-}/usr/lib/systemd/system/systemd-logind.service.d/ipfilter.conf"  # noqa: E501
# 	fnFile_backup "${__PATH}"			# backup original file
# 	mkdir -p "${__PATH%/*}"
# 	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
# 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
# 		[Service]
# 		IPAddressDeny=any           # 0.0.0.0/0      ::/0
# 		IPAddressAllow=localhost    # 127.0.0.0/8    ::1/128
# 		IPAddressAllow=link-local   # 169.254.0.0/16 fe80::/64
# 		IPAddressAllow=multicast    # 224.0.0.0/4    ff00::/8
# 		IPAddressAllow=${NICS_IPV4%.*}.0/${NICS_BIT4}
# _EOT_
# 	fnDbgdump "${__PATH}"				# debugout
# 	fnFile_backup "${__PATH}" "init"	# backup initial file
