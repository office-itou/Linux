#!/bin/bash

set -eu

cp -a  /srv/tftp/ipxe/autoexec.ipxe                 "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/"
cp -a  /srv/tftp/ipxe/menu/booting.ipxe             "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu.ipxe                "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_almalinux.ipxe      "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_centos.ipxe         "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_custom_live.ipxe    "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_debian.ipxe         "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_fedora.ipxe         "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_live.ipxe           "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_miraclelinux.ipxe   "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_opensuse.ipxe       "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_rockylinux.ipxe     "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_ubuntu.ipxe         "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
cp -a  /srv/tftp/ipxe/menu/menu_windows.ipxe        "${SUDO_HOME:-"${HOME}"}/linux/script/py_custom_cmd/doc/test_artifacts/ipxe/menu/"
