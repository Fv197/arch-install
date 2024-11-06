# arch install

Personal installation script for Arch Linux on Thinkpad T560 

## Description

* Base installation
* BTRFS
  - Snapper (post-install)
  - Swapfile
* Hibernation
* GRUB
* Gnome desktop 

## Instructions

1. Clone this repo
2. Edit `config`
3. Run `./arch-install.sh`
4. Run scripts in `post-install` after reboot

## TODO

* Setting correct keymap in GNOME
* Setting user ownership of arch-install post boot
* Adding verification of internet connectivty in 00-snapper 
