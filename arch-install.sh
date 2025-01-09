#!/bin/sh
# Comments with numbering is a reference to https://wiki.archlinux.org/title/installation_guide

# Verify that config file is available
if [ -f "config" ]; then
	echo "*** Config file available ***"
	source ./config
else
	echo "!!! Config file does not exist. Clone the entire arch-install repository before running installation !!!"
	exit
fi


# 1.6 Verify the boot mode
BOOT=$(cat /sys/firmware/efi/fw_platform_size)
if [ "$BOOT" = 64 ]; then
	echo "*** UEFI mode detected ***"
elif [ "$BOOT" = 32 ]; then
	echo "*** 32-bit UEFI mode detected ***"
else
	echo "!!! Unable to verify UEFI boot mode. Boot in UEFI before running installation !!!"
 	exit
fi

# 1.7 Connect to the internet
if nc -zw1 archlinux.org 443; then
	echo "*** Internet connectivity detected ***"
else
	echo "!!! Unable to detect internet connectivity. Verify connection before running installation !!!"
 	exit
fi

# Verify that arch-install-chroot.sh file is available
if [ -f "arch-install-chroot.sh" ]; then
	echo "*** arch-install-chroot.sh file available ***"
else
       	echo "!!! arch-install-chroot.sh does not exit. Clone the entire arch-install repository before running installation !!!"
	exit
fi


# Request confirmation to proceed
echo "*** All content on $DISK will be lost ***"
echo '*** Content of "config" will be used for this install ***'
read -p "Are you sure you want to continue <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" ]]; then
	echo "*** Starting arch install ***"
else
	echo "!!! Aborting arch install !!!"
	exit 0
fi

# Configuring pacman
echo "*** Enabling parallel downsloads in Pacman ***"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

# 1.8 Update the system clock
echo "*** Updating the system clock ***"
timedatectl

# 1.9 Partition the disk
echo "*** Removing old partitions on $DISK ***"
sgdisk -z $DISK

echo "*** Detcting needed swap size ***"
RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
echo "*** RAM size $RAM kB detected ***"
if [ "$RAM" > 8000000 ]; then
	SWAP=$(( RAM * 3/2 ))
 	echo "*** Setting swap size to $SWAP kB ***"
elif [ "$RAM" > 2000000 ]; then
	SWAP=$(( RAM * 2 ))
 	echo "*** Setting swap size to $SWAP kB ***"
else
	SWAP=$(( RAM * 3 ))
 	echo "*** Setting swap size to $SWAP kB ***"
fi

echo "*** Creating new partitions on $DISK ***"
sgdisk -n 0:0:+1GiB -t 0:ef00 -c 0:efi $DISK
sgdisk -n 0:0:+${SWAP}KiB -t 0:8200 -c 0:swap $DISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:arch $DISK

# 1.10 Format partitions
echo "*** Formating partitions on $DISK ***"
mkfs.vfat -F32 -n EFI ${DISK}1
mkswap -L SWAP ${DISK}2
mkfs.btrfs -f -L ARCH ${DISK}3
swapon ${DISK}2
# 1.11 Mount the file systems
echo "*** Mounting ${DISK}3 ***"
mount ${DISK}3 /mnt

# Create btrfs subvolumes
echo "*** Creating subvolumes ***"
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots

# Unmount root partition
echo "*** Unmounting ${DISK}3 ***"
umount /mnt

# Mount root subvolume
echo "*** Mountint subvol @ ***"
mount -o subvol=@ ${DISK}3 /mnt

# Create directories
echo "*** Creating directories ***"
mkdir /mnt/{efi,home,var,.snapshots}

# Mount boot partition
echo "*** Mounting ${DISK}1 at /mnt/efi ***"
mount ${DISK}1 /mnt/efi

# Mount subvolumes
echo "*** Mounting subvolumes ***"
mount -o subvol=@home ${DISK}3 /mnt/home
mount -o subvol=@var ${DISK}3 /mnt/var
mount -o subvol=@snapshots ${DISK}3 /mnt/.snapshots

# 2 Installation 
# 2.2 Install essential packages
echo "*** Installing essential packages to new system ***"
pacstrap -K /mnt base linux linux-firmware intel-ucode vim 

# 3 Configure the system
# 3.1 Fstab
echo "*** Generating fstab ***"
genfstab -U /mnt >> /mnt/etc/fstab

# Adding install files to new system
echo "*** Adding install files to new system ***"
cp ./arch-install-chroot.sh /mnt
cp ./config /mnt
cp ./gnome-pkglist.txt /mnt
cp ./utils-pkglist.txt /mnt

# 3.2 Chroot
echo "*** Changing root to new system ***"
cat << EOF | arch-chroot /mnt
./arch-install-chroot.sh
EOF

# Moving arch-install to home folder to created user
DIRPATH=$(pwd)
DIR=${PWD##*/}
rm $DIRPATH/config
cp -R $DIRPATH /mnt/home/$USER/
echo "*** $DIRPATH copied to /home/$USER/$DIR ***"

# Removing install files to new system
echo "*** Removing install files from new system ***"
rm /mnt/arch-install-chroot.sh
rm /mnt/config
rm /mnt/gnome-pkglist.txt
rm /mnt/utils-pkglist.txt

# 4. Reboot
echo "*** Installation done ***"
echo "*** Run scripts in /home/$USER/$DIR/post-install after reboot ***"
echo "*** Ready to reboot ***"
echo "!!! Run "umount -R /mnt" before rebooting !!!"
