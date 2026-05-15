#!/bin/bash

set -eu

./custom_cmd/mk_live_iso.sh -m \
build:alma:10:server \
build:alma:10:desktop \
build:centos:10:server \
build:centos:10:desktop \
build:fedora:44:server \
build:fedora:44:desktop \
build:opensuse:16.0:server \
build:opensuse:16.0:desktop \
build:opensuse:16.1:server \
build:opensuse:16.1:desktop 
