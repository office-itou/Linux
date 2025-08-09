#!/bin/sh

set -eu

_PATH="/dev/loop-control"
if [ ! -e "${_PATH:?}" ]; then
	mknod "${_PATH}" c 10 237
fi

I=0
while [ "${I}" -lt 9 ]
do
	_PATH="/dev/loop${I}"
	if [ ! -e "${_PATH}" ]; then
		mknod "${_PATH}" b 7 "${I}"
	fi
done

exit 0