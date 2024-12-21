#!/bin/bash

if [ "$EUID" = 0 ]
  then echo "Please do not run as root"
  exit
fi

# https://wiki.archlinux.org/title/GNOME#Power
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type hibernate
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type hibernate
