#!/bin/sh

source ./config

# 3.3 Time zone
echo "Setting time zone"
ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
hwclock --systohc

# 3.4 Localization
echo "*** Configuring locale ***"
echo $LOCALE >> /etc/locale.gen
locale-gen

echo "*** Setting language ***"
echo LANG="$LANG" > /etc/locale.conf

echo "*** Setting keyboard ***"
echo KEYMAP=$KEYMAP > /etc/vconsole.conf

# 3.5 Network configuration
echo "*** Setting hostname ***"
echo $HOSTNAME > /etc/hostname

echo "*** Configuring pacman ***"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

echo "*** Installing NetworkManager ***"
pacman -S --noconfirm networkmanager wpa_supplicant
systemctl enable NetworkManager
systemctl enable systemd-resolved

echo "*** Installing utilities ***"
pacman -S --noconfirm dosfstools btrfs-progs man-db man-pages texinfo bash-completion openssh sudo

# 3.8 Boot loader
echo "*** Installing GRUB ***"
pacman -S --noconfirm grub efibootmgr  

echo "*** Configurering GRUB ***"
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
#grub-mkconfig -o /boot/grub/grub.cfg #uncomment if command is removed from enabling hibernation

echo "*** Enabling binaries for btrfs at boot ***"
sed -i 's/BINARIES=()/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
#mkinitcpio -P #uncomment if command is removed from enabling hibernation

echo "*** Creating swapfile ***"
SWAPFILE=/swap/swapfile
RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$RAM" > 8000000 ]; then
	SWAP=$(( RAM * 3/2 ))
elif [ "$RAM" > 2000000 ]; then
	SWAP=$(( RAM * 2 ))
else
	SWAP=$(( RAM * 3 ))
fi

btrfs filesystem mkswapfile -s ${SWAP}k $SWAPFILE
echo "$SWAPFILE                                  none            swap            defaults        0 0" >> /etc/fstab

echo "*** Enabling hibernation ***"
sed -i 's/filesystems fsck/filesystems resume fsck/' /etc/mkinitcpio.conf
mkinitcpio -P
OFFSET=$(btrfs inspect-internal map-swapfile -r $SWAPFILE)
UUID=$(findmnt -no UUID -T $SWAPFILE)
sed -i "s/loglevel=3 quiet/loglevel=3 quiet resume=UUID=$UUID resume_offset=$OFFSET/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "*** Installing TLP ***"
pacman -S --noconfirm tlp acpi_call smartmontools ethtool tlp-rdw   
systemctl enable tlp
systemctl mask systemd-rfkill.socket
systemctl mask systemd-rfkill.service
systemctl enable NetworkManager-dispatcher

echo "*** Checking for TRIM support ***"
DISCARD=$(lsblk -n --discard $DISK | awk '/^sda/' | awk '{print $3}')
if [ "$DISCARD" != 0 ];
then 
	echo "*** Enabling TRIM ***"
        systemctl enable fstrim.timer
else
	echo "*** TRIM support not detected on $DISK ***"
fi

echo "*** Setting root password ***"
echo root:$ROOTP | chpasswd

echo "*** Adding $USER ***"
useradd -m -G wheel -U $USER 
echo ${USER}:$USERP | chpasswd

echo "*** Adding $USER to sudo ***"
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers.d/$USER
