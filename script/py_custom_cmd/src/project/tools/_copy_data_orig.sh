#!/bin/bash

set -eu

cp -a /srv/user/share/conf/_data/common.cfg            /srv/user/share/conf/_data/_common.cfg
cp -a /srv/user/share/conf/_data/distribution.dat      /srv/user/share/conf/_data/_distribution.dat
cp -a /srv/user/share/conf/_data/distribution.dat.json /srv/user/share/conf/_data/_distribution.dat.json
cp -a /srv/user/share/conf/_data/media.dat             /srv/user/share/conf/_data/_media.dat
cp -a /srv/user/share/conf/_data/media.dat.json        /srv/user/share/conf/_data/_media.dat.json
