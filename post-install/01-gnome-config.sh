#!/bin/sh

# Script to be run as normal user

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type hibernate
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type hibernate

sudo echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment

mkdir $HOME/.local/share/applications
cp applications/* $HOME/.local/share/applications

# Todo
# Install and enable alphabetical-grid-extension
