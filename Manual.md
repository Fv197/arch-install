# Arch Install (WIP)

## Configuring pacman

```
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf
```

## Partitioning disk

Use fdisk to identify your disk drive
```
fdisk -l
```
Change DISK to your drive
```
DISK=/dev/sda
```

Removing old partitions
```
sgdisk -z $DISK
```

Creating new partitions
```
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:efi $DISK
sgdisk -n 0:0:+4GiB -t 0:ef02 -c 0:boot $DISK
sgdisk -n 0:0:0 -t 0:8309 -c 0:arch $DISK
```

## Encrypt partition

```
cryptsetup luksFormat -v -s 512 -h sha512 ${DISK}3
```

Map encrypted partition

```
cryptsetup open ${DISK}3 lvm
```

## LVM setup

Create physical volume
```
pvcreate /dev/mapper/lvm
```

Create volume group
```
vgcreate arch /dev/mapper/lvm
```

Create logical volumes
```
lvcreate -n swap -L 8G arch
```
```
lvcreate -n root -l +100%FREE arch
```

## Format Partitions

```
mkfs.vfat -F32 -n EFI ${DISK}1
```
```
mkfs.ext4 -L BOOT ${DISK}2
```
```
mkfs.btrfs -f -L ARCH /dev/mapper/arch-root
```

## Setup Swap

```
mkswap /dev/mapper/arch-swap
swapon /dev/mapper/arch-swap
swapon -a
```

## Setup BTRFS subvolumes

```
mount /dev/mapper/arch-root /mnt
```
```
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@varlog
btrfs subvolume create /mnt/@snapshots
```
```
umount /mnt
```
## Mount all partitions and subvolumes
```
mount -o defaults,subvol=@ /dev/mapper/arch-root /mnt
```
```
mkdir /mnt/{boot,home,var,.snapshots}
mkdir /mnt/var/log
```
```
mount ${DISK}2 /mnt/boot
mkdir /mnt/boot/efi
mount ${DISK}1 /mnt/boot/efi
```
```
mount -o $defaults,subvol=@home /dev/mapper/arch-root /mnt/home
mount -o $defaults,subvol=@varlog /dev/mapper/arch-root /mnt/var/log
mount -o $defaults,subvol=@snapshots /dev/mapper/arch-root /mnt/.snapshots
```

## Install Arch
```
pacstrap -K /mnt base base-devel linux linux-firmware neovim intel-ucode
```
```
genfstab -U -p /mnt > /mnt/etc/fstab
```

## Enter new enviroment
```
arch-chroot /mnt
```
Set up variables
```
DISK=/dev/sda
ZONE="Europe/Oslo"
LOCALE="en_US.UTF-8 UTF-8"
LANG="en_US.UTF-8"
KEYMAP="no-latin1"
HOSTNAME=Galactica
```

```
ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
hwclock --systohc
```
```
echo $LOCALE >> /etc/locale.gen
locale-gen
```
```
echo LANG="$LANG" > /etc/locale.conf
```
```
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
```
```
echo $HOSTNAME > /etc/hostname
```
Configure pacman
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

pacman -S --noconfirm --needed dosfstools btrfs-progs man-db man-pages texinfo bash-completion openssh sudo lvm2

sed -i 's/BINARIES=()/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/block filesystems/block encrypt lvm2 filesystems/' /etc/mkinitcpio.conf
mkinitcpio -P

pacman -S --noconfirm grub efibootmgr 
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

 
UUID=$(blkid -s UUID -o value ${DISK}3)
sed -i "s|loglevel=3 quiet|loglevel=3 quiet root=/dev/mapper/arch-root cryptdevice=UUID=$UUID:LVM|" /etc/default/grub

mkdir /secure
dd if=/dev/random of=/secure/root_keyfile.bin bs=512 count=8
chmod 000 /secure/*

cryptsetup luksAddKey /dev/sda3 /secure/root_keyfile.bin

sed -i "s|FILES=()|FILES=(/secure/root_keyfile.bin)|" /etc/mkinitcpio.conf

grub-mkconfig -o /boot/grub/grub.cfg
grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg

echo "NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org" >> /etc/systemd/timesyncd.conf
echo "FallbackNTP=0.pool.ntp.org 1.pool.ntp.org" >> /etc/systemd/timesyncd.conf

systemctl enable systemd-timesyncd.service

tbd
