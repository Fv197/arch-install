#!/bin/bash

# Verify that script is run as root
if [ "$EUID" != 0 ]
  then echo "!!! Please run as root !!!"
  exit
fi

# Verify internet connectivity
if nc -zw1 archlinux.org 443; then
	echo "*** Internet connectivity detected ***"
else
	echo "!!! Unable to detect internet connectivity. Verify connection before running installation !!!"
 	exit
fi



echo "*** Installing snapper, grub-btrfs and snap-pac ***"
pacman -S --noconfirm snapper grub-btrfs snap-pac

echo "*** Configure snapper ***"
umount /.snapshots
rm -r /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots/
mkdir /.snapshots
mount -a
ID=$(btrfs subvol list / | head -n 1 | awk '{print $2}')
btrfs subvolume set-default $ID /
sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMiT_MONTHLY="0"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root
chown -R :wheel /.snapshots
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

echo "*** Creating base snapshot ***"
snapper -c root create -d "*** BASE ***"
