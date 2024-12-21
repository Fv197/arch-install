#!/bin/bash

if [ "$EUID" = 0 ]
  then echo "Please do not run as root"
  exit
fi
# removes unnessary desktop entries
# https://wiki.archlinux.org/title/Desktop_entries#Hide_desktop_entries
mkdir -p $HOME/.local/share/applications
cp applications/* $HOME/.local/share/applications
