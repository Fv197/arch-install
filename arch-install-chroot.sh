#!/bin/sh
source arch-install.cfg   

# 3.3 Time zone
echo "Setting time zone"
ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
hwclock --systohc

# 3.4 Localization
echo "Configuring locale"
echo $LOCALE >> /etc/locale.gen

locale-gen

echo "Setting language"
echo 'LANG="$LANG"' > /etc/locale.conf
echo "Setting keyboard"
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# 3.5 Network configuration
echo "Setting hostname"
echo $HOSTNAME > /etc/hostname

echo "Installing NetworkManager and enabling services"
pacman -S --noconfirm networkmanager wpa_supplicant
systemctl enable NetworkManager
systemctl enable systemd-resolved

echo "Installing utilities"
pacman -S --noconfirm dosfstools btrfs-progs man-db man-pages texinfo bash-completion openssh sudo

echo "Checking for TRIM support"
DISCARD=$(lsblk -n --discard $DISK | awk '/^sda/' | awk '{print $3}')
if [ "$DISCARD" != 0 ]
then 
	echo "Enabling TRIM"
        systemctl enable fstrim.timer
else
	echo "TRIM support not detected on $DISK"
fi

echo "Setting root password"
echo root:$ROOTP | chpasswd

echo "Adding users"
useradd -m -G wheel -U $USER 
echo ${USER}:$USERP | chpasswd

echo "Adding users to sudo"
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers.d/$USER

# 3.8 Boot loader
echo "Installing bootloader"
pacman -S --noconfirm grub efibootmgr grub-btrfs
 
echo "Configurering GRUB"
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg