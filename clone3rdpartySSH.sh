#!/bin/bash

# URL=https://pitebustash.win.ansys.com:8443/scm/ebu/3rdparty.git
URL=ssh://git@pitebustash.win.ansys.com:7999/ebu/3rdparty_ssh.git

git clone ${URL} 3rdparty
cd 3rdparty
git submodule init
git submodule update
