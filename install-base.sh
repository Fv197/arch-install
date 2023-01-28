#!/bin/bash

# Verify which computer this installation is for

read -n 1 -p "Are you taking Rocinante (R) or Normandy (N) for a spin? " ans;

PS3='Which ship are you taking out for a spin? (1-2)'
options=("Normandy" "Rocinante")
select opt in "${options[@]}"
do
    case $opt in
        "Normandy")
            echo "You Exist Because We Allow It. And You Will End Because We Demand It."
            ship=Normandy
	    break
	    ;;
        "Rocinante")
            echo "Dangsin-eun junbiga coyo?"
            ship=Rocinante
	    break
	    ;;
        *) echo "Invalid option. Try again";;
    esac
done

#Set time and locale settings
ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
hwclock --systohc
sed -i '177s/.//' /etc/locale.gen #en_US
sed -i '360s/.//' /etc/locale.gen #nb_NO
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=no-latin1" >> /etc/vconsole.conf
echo $ship >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $ship.localdomain $ship" >> /etc/hosts

#Network 
pacman -S openssh iwd
systemctl enable systemd-networkd
systemctl enable systemd-reseolvd
systemctl enable iwd


#Utilities
pacman -S mtools dosfstools btrfs-progs exfatprogs reflector base-devel git nfs-utils bluez bluez-utils ntfs-3g util-linux nano vim bash-completion htop neofetch man-db man-pages texinfo
systemctl enable bluetooth
systemctl enable reflector.timer
systemctl enable fstrim.timer

#Sound 
pacman -S alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack  

#Power 
pacman -S acpi acpi_call acpid tlp 
systemctl enable acpid
systemctl enable tlp

#Bootloader
bootctl install

echo "default  arch.conf" > /boot/loader/loader.conf
echo "timeout  4" >> /boot/loader/loader.conf
echo "console-mode max" >> /boot/loader/loader.conf
echo "editor   no" >> /boot/loader/loader.conf

echo "title   Arch Linux" > /boot/loader/entries/arch.conf
echo "linux   /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd  /intel-ucode.img" >> /boot/loader/entries/arch.conf
echo "initrd  /initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo 'options root="LABEL=arch" rw' >> /boot/loader/entries/arch.conf

##TEST

#User configuration
useradd -m aleksander
echo aleksander:password | chpasswd
echo "aleksander ALL=(ALL) ALL" >> /etc/sudoers.d/aleksander
