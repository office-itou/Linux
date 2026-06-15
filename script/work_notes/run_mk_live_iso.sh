#!/bin/bash

set -eu

#__FLAG_DEBI="1"
#__FLAG_UBUT="1"
#__FLAG_RHEL="1"
__FLAG_SUSE="1"

if [[ -n "${__FLAG_DEBI:-}" ]]; then
	if ! ./custom_cmd/mk_live_iso.sh -m \
		build:debian:13.0:server \
		build:debian:13.0:desktop \
	; then
		exit "$?"
	fi
fi

if [[ -n "${__FLAG_UBUT:-}" ]]; then
	if ! ./custom_cmd/mk_live_iso.sh -m \
		build:ubuntu:26.04:server \
		build:ubuntu:26.04:desktop \
	; then
		exit "$?"
	fi
fi

if [[ -n "${__FLAG_RHEL:-}" ]]; then
	if ! ./custom_cmd/mk_live_iso.sh -m \
		build:fedora:44:server \
		build:fedora:44:desktop \
		build:centos:10:server \
		build:centos:10:desktop \
		build:alma:10:server \
		build:alma:10:desktop \
	; then
		exit "$?"
	fi
fi

if [[ -n "${__FLAG_SUSE:-}" ]]; then
	if ! ./custom_cmd/mk_live_iso.sh -m \
		build:opensuse:16.0:server \
		build:opensuse:16.0:desktop \
	; then
		exit "$?"
	fi
fi

exit 0
