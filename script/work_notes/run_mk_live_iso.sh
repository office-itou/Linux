#!/bin/bash

set -eu

#./custom_cmd/mk_live_iso.sh -m \
#build:debian:13.0:server \
#build:debian:13.0:desktop \
#build:ubuntu:26.04:server \
#build:ubuntu:26.04:desktop \
#build:fedora:44:server \
#build:fedora:44:desktop \
#build:centos:10:server \
#build:centos:10:desktop \
#build:alma:10:server \
#build:alma:10:desktop \
./custom_cmd/mk_live_iso.sh -m \
build:opensuse:16.0:server \
build:opensuse:16.0:desktop \
build:opensuse:16.1:server \
build:opensuse:16.1:desktop 
