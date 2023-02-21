#!/bin/sh
DISK="/dev/sda"
KEYMAP="no-latin1"
LOCALE="en_US.UTF-8 UTF-8"
LANG="en_US.UTF-8"
ZONE="Europe/Oslo"
ROOTP="ilovecoffe"
HOSTNAME="Rocinante"
USER="james"
USERP="ilovenaomi"

# *** HOUSEKEEPING ***
x=9
while [ $x -gt 0 ]
do (
  sed -n "${x}p" arch-install.sh | cat - arch-install-chroot.sh > temp && mv temp arch-install-chroot.sh
  x=$(( $x - 1)) 
)
done

# Configuring pacman
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/" /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

# Comments with numbering is a reference to https://wiki.archlinux.org/title/installation_guide

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
echo "*** Mountint subvol @ ***"
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@ ${DISK}2 /mnt

# Create directories
echo "*** Creating directories ***"
mkdir /mnt/{efi,home,var,swap,.snapshots}

# Mount boot partition

echo "*** Mounting ${DISK}1 at /mnt/efi ***"
mount ${DISK}1 /mnt/efi

# Mount subvolumes
echo "*** Mounting subvolumes ***"
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@home ${DISK}2 /mnt/home
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@var ${DISK}2 /mnt/var
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@snapshots ${DISK}2 /mnt/.snapshots
mount -o defaults,noatime,nodatacow,space_cache=v2,ssd,subvol=@swap ${DISK}2 /mnt/swap

# 2 Installation 
# 2.2 Install essential packages
echo "*** Installing essential packages to new system ***"
pacstrap -K /mnt base linux linux-firmware intel-ucode vim 

# 3 Configure the system
# 3.1 Fstab

echo "*** Generating fstab ***"
genfstab -U /mnt >> /mnt/etc/fstab

# 3.2 Chroot

echo "*** Changing root to new system ***"
cp ./arch-install-chroot.sh /mnt/

cat << EOF | arch-chroot /mnt
./arch-install-chroot.sh
EOF

rm /mnt/arch-install-chroot.sh
DIR=$(pwd)
cp $DIR /mnt/home/$USER

# 4. Reboot
echo "*** Unmounting ***"
umount -R /mnt
echo "*** arch-install copied to /home/$USER ***"
echo "*** Installation done. Reboot when ready ***"

