#!/bin/sh

source ./config

# 3.3 Time zone
echo "Setting time zone"
ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
hwclock --systohc

# 3.4 Localization
echo "*** Generating the locales ***"
echo $LOCALE >> /etc/locale.gen
locale-gen

echo "*** Setting language ***"
echo LANG="$LANG" > /etc/locale.conf

echo "*** Setting keyboard ***"
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
echo XKBLAYOUT=$KEYMAP >> /etc/vconsole.conf

# 3.5 Network configuration
echo "*** Setting hostname ***"
echo $HOSTNAME > /etc/hostname

echo "*** Configuring pacman ***"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

echo "*** Installing NetworkManager ***"
pacman -S --noconfirm networkmanager wpa_supplicant
echo "*** Enabling network services ***"
systemctl enable NetworkManager
systemctl enable systemd-resolved

echo "*** Installing utilities ***"
pacman -S --noconfirm --needed - < utils-pkglist.txt

echo "*** Installing Gnome Desktop ***"
pacman -S --noconfirm --needed - < gnome-pkglist.txt

echo "*** Enabling services ***"
systemctl enable gdm
systemctl enable bluetooth

# 3.7 Root password
echo "*** Setting root password ***"
echo root:$ROOTP | chpasswd

# 3.8 Boot loader
echo "*** Installing GRUB ***"
pacman -S --noconfirm grub efibootmgr  

echo "*** Configurering GRUB ***"
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
#grub-mkconfig -o /boot/grub/grub.cfg #uncomment if command is removed from Enabling hibernation

echo "*** Enabling binaries for btrfs at boot ***"
sed -i 's/BINARIES=()/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
#mkinitcpio -P #uncomment if command is removed from Enabling hibernation

echo "*** Creating swapfile ***"
SWAPFILE=/swap/swapfile
RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
echo "*** RAM size $RAM kB detected ***"
if [ "$RAM" > 8000000 ]; then
	SWAP=$(( RAM * 3/2 ))
 	echo "*** Setting swap file size to $SWAP kB ***"
elif [ "$RAM" > 2000000 ]; then
	SWAP=$(( RAM * 2 ))
 	echo "*** Setting swap file size to $SWAP kB ***"
else
	SWAP=$(( RAM * 3 ))
 	echo "*** Setting swap file size to $SWAP kB ***"
fi

btrfs filesystem mkswapfile -s ${SWAP}k $SWAPFILE
echo "*** Adding swapfile to fstab ***"
echo "$SWAPFILE                                  none            swap            defaults        0 0" >> /etc/fstab

echo "*** Enabling hibernation ***"
sed -i 's/filesystems fsck/filesystems resume fsck/' /etc/mkinitcpio.conf
mkinitcpio -P
OFFSET=$(btrfs inspect-internal map-swapfile -r $SWAPFILE)
UUID=$(findmnt -no UUID -T $SWAPFILE)
sed -i "s/loglevel=3 quiet/loglevel=3 quiet resume=UUID=$UUID resume_offset=$OFFSET/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "*** Checking $DISK for TRIM support ***"
DISCARD=$(lsblk -n --discard $DISK | awk '/^sda/' | awk '{print $3}')
if [ "$DISCARD" != 0 ];
then 
	echo "*** Enabling TRIM ***"
        systemctl enable fstrim.timer
else
	echo "*** TRIM support not detected on $DISK ***"
fi

echo "*** Adding $USER user ***"
useradd -m -G wheel -U $USER 
echo ${USER}:$USERP | chpasswd

echo "*** Adding $USER to sudo ***"
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers.d/$USER
