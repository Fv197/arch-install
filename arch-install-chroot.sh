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
pacman -S --noconfirm networkmanager
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
echo "*** Configuring systemd-boot ***"
bootctl install
bootctl --esp-path=/efi --boot-path=/boot install
echo "default arch.conf" > /efi/loader/loader.conf
echo "timeout 0" >> /efi/loader/loader.conf
echo "title Arch Linux" > /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
RUUID=$(findmnt -no UUID -T /)
echo "options root=PARTUUID=$RUUID rw" >> /boot/loader/entries/arch.conf

echo "*** Enabling binaries for btrfs at boot ***"
sed -i 's/BINARIES=()/BINARIES=(btrfs)/' /etc/mkinitcpio.conf

echo "*** Enabling hibernation ***"
sed -i 's/filesystems fsck/filesystems resume fsck/' /etc/mkinitcpio.conf
mkinitcpio -P

echo "*** Checking $DISK for TRIM support ***"
DEV="${DISK%"${DISK##*[!/]}"}"
DEV="${DEV##*/}"
DISCGRAN=$(lsblk -n --discard $DISK | awk "/^$DEV/" | awk '{print $3}')
DISCMAX=$(lsblk -n --discard $DISK | awk "/^$DEV/" | awk '{print $4}')
if [ "$DISCGRAN" != 0 && "$DISCMAX" != 0 ];
then 
	echo "*** Enabling TRIM ***"
        systemctl enable fstrim.timer
else
	echo "*** TRIM support not detected on $DISK ***"
fi

echo "*** Adding $USER user ***"
useradd -m -G wheel -U $USER 
echo ${USER}:$USERP | chpasswd

mv -r /$DIR /home/$USER
chown -R $USER:$USER /home/$USER/$DIR

echo "*** Adding $USER to sudo ***"
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers.d/$USER
