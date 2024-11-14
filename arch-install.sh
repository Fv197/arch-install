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

echo "*** Creating new partitions on $DISK ***"
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:efi $DISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:arch $DISK

# 1.10 Format partitions
echo "*** Formating partitions on $DISK ***"
mkfs.vfat -F32 -n EFI ${DISK}1
mkfs.btrfs -f -L ARCH ${DISK}2

# 1.11 Mount the file systems
echo "*** Mounting ${DISK}2 ***"
mount ${DISK}2 /mnt

# Create btrfs subvolumes
echo "*** Creating subvolumes ***"
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap

# Unmount root partition
echo "*** Unmounting ${DISK}2 ***"
umount /mnt

# Mount root subvolume
BTRFSOPT=defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,
echo "*** Mountint subvol @ ***"
mount -o ${BTRFSOPT}subvol=@ ${DISK}2 /mnt

# Create directories
echo "*** Creating directories ***"
mkdir /mnt/{efi,home,var,swap,.snapshots}

# Mount boot partition
echo "*** Mounting ${DISK}1 at /mnt/efi ***"
mount ${DISK}1 /mnt/efi

# Mount subvolumes
echo "*** Mounting subvolumes ***"
mount -o ${BTRFSOPT}subvol=@home ${DISK}2 /mnt/home
mount -o ${BTRFSOPT}subvol=@var ${DISK}2 /mnt/var
mount -o ${BTRFSOPT}subvol=@snapshots ${DISK}2 /mnt/.snapshots
mount -o noatime,nodatacow,space_cache=v2,ssd,subvol=@swap ${DISK}2 /mnt/swap

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

# Removing install files to new system
echo "*** Removing install files from new system ***"
rm /mnt/arch-install-chroot.sh
rm /mnt/config
rm /mnt/gnome-pkglist.txt
rm /mnt/utils-pkglist.txt

DIR=$(pwd)
cp -r $DIR /mnt/home/$USER
chown -R $USER:$USER /mnt/home/$USER
echo "*** $DIR copied to /home/$USER ***"

# 4. Reboot
echo "*** Unmounting ***"
umount -R /mnt

echo "*** Run scripts in post-install after reboot ***"
echo "*** Be aware that config file containing user and root passwords is available in /home/$USER/arch-install/config ***"
echo "*** Installation done. Reboot when ready ***"
