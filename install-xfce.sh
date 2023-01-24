#!/bin/bash

#X
pacman -S xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies firefox arc-gtk-theme arc-icon-theme vlc xdg-user-dirs xdg-utils
sudo systemctl enable lightdm
 
#Configuration
xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Arc"
