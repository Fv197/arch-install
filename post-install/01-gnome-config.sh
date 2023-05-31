#!/bin/sh

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type hibernate
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type hibernate
gsettings set org.gnome.settings-daemon.plugins.power power-button-action suspend

sudo echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment

# Todo
# Install and enable alphabetical-grid-extension
