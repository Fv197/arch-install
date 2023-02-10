
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

sed 's_source /mnt/home/$USER/arch-install/arch-install-post.sh__' .bashrc

if nc -zw1 archlinux.org 443; 
then
  echo "Internett access confirmed"
else
  echo "Unable to connect to internett. Connection to $SSID"
  nmcli device wifi connect $SSID password $SSIDP
fi

echo "Waiting for connection..."
sleep 1
echo "Waiting for connection..."
sleep 1
echo "Waiting for connection..."
sleep 1

if nc -zw1 archlinux.org 443; 
then
  echo "Internett access confirmed"
else
  echo "Unable to connect to internett"
  echo "Run /mnt/home/$USER/arch-install/install-part2.sh again when connected to internett"
  exit 1;
fi

echo "Installing snapper"
pacman -S --noconfirm snapper 

echo "Configure snapper"
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

systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

SWAPFILE=/swap/swapfile
RAM=$(grep MemTotal /proc/meminfo | awk '{print $3}')


echo "Creating swapfile"

btrfs filesystem mkswapfile -s ${RAM}g $SWAPFILE
swapon $SWAPFILE
echo "$SWAPFILE                                  none            swap            defaults        0 0" >> /etc/fstab

# Enable hibernation
echo "Enabling hibernation"
sed -i 's/filesystems fsck/filesystems resume fsck/' /etc/mkinitcpio.conf
mkinitcpio -P

OFFSET=$(btrfs inspect-internal map-swapfile -r $SWAPFILE)

UUID=$(findmnt -no UUID -T $SWAPFILE)

sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet resume=UUID=$UUID resume_offset=$OFFSET"/' /etc/default/grub


# Enable TLP
echo "Installing TLP"
pacman -S --noconfirm  tlp acpi_call smartmontools tp_smapi ethtool tlp-rdw   

sudo systemctl enable tlp
sudo systemctl mask systemd-rfkill.socket
sudo systemctl mask systemd-rfkill.service
sudo systemctl enable NetworkManager-dispatcher

echo "Creating base snapshot"
snapper -c root create -d "***BASE***"
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing snap-pac"
pacman -S --noconfirm snap-pac
