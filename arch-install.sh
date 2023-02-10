#!/bin/sh

# Comments with numbering is a reference to https://wiki.archlinux.org/title/installation_guide

source arch-install.cfg

# 1.9 Partition the disks

echo "Removing old partitions on $DISK"
sgdisk --zap-all $DISK


echo "Creating new partitions on $DISK"
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:efi $DISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:arch $DISK

# 1.10 Format partitions

echo "Formating partitions on $DISK"
mkfs.vfat -F32 -n EFI ${DISK}1
mkfs.btrfs -f -L ARCH ${DISK}2

# 1.11 Mount the file systems

echo "Mounting ${DISK}2"
mount ${DISK}2 /mnt

# Create btrfs subvolumes
echo "Creating subvolumes"
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap

# Unmount root partition
echo "Unmounting ${DISK}2"
umount /mnt

# Mount root subvolume
echo "Mountint subvol @"
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@ ${DISK}2 /mnt

# Create directories
echo "Creating directories"
mkdir /mnt/{efi,home,var,swap,.snapshots}

# Mount boot partition

echo "Mounting ${DISK}2 at /mnt/efi"
mount ${DISK}1 /mnt/efi

# Mount subvolumes
echo "Mounting subvolumes"
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@home ${DISK}2 /mnt/home
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@var ${DISK}2 /mnt/var
mount -o defaults,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@snapshots ${DISK}2 /mnt/.snapshots

# 2 Installation 
# 2.2 Install essential packages
#
echo "Installing essential packages to new system"
pacstrap -K /mnt base linux linux-firmware intel-ucode vim 

# 3 Configure the system
# 3.1 Fstab

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# 3.2 Chroot

echo "Changing root to new system"
cp arch-install-chroot.sh /mnt/
cp arch-install.cfg /mnt

cat << EOF | arch-chroot /mnt
./arch-install-chroot.sh
EOF

rm /mnt/arch-install-chroot.sh
rm /mnt/arch-install.cfg

mkdir /mnt/home/$USER/arch-install
cp arch-install* /mnt/home/$USER/arch-install

echo "source /mnt/home/$USER/arch-install/arch-install-post.sh" >> /mnt/root/.bashrc

# 4. Reboot
echo "Unmounting"
umount -R /mnt
echo "Installation done. Reboot when ready"
echo "Login as root after reboot"
