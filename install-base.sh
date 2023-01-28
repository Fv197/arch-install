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
            eth=enp9s31f6
	    wifi=wlan0
	    break
	    ;;
        *) echo "Invalid option. Try again";;
    esac
done

#Set time and locale settings

ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "nb_NO.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=no-latin1" >> /etc/vconsole.conf

echo $ship >> /etc/hostname

echo root:password | chpasswd 

#Network 
pacman -S openssh iwd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable iwd
systemctl enable sshd

echo "[Match]" > /etc/systemd/network/20-wired.network
echo "Name=$eth" >> /etc/systemd/network/20-wired.network
echo "[Network]" >> /etc/systemd/network/20-wired.network
echo "DHCP=yes" >> /etc/systemd/network/20-wired.network

echo "[Match]" > /etc/systemd/network/25-wireless.network
echo "Name=$wifi" >> /etc/systemd/network/25-wireless.network 
echo "[Network]" >> /etc/systemd/network/25-wireless.network
echo "DHCP=yes" >> /etc/systemd/network/25-wireless.network
echo "IgnoreCarrierLoss=3s" >> /etc/systemd/network/25-wireless.network

#Utilities
pacman -S mtools dosfstools btrfs-progs exfatprogs reflector base-devel git nfs-utils bluez bluez-utils ntfs-3g util-linux nano vim bash-completion htop man-db man-pages texinfo
systemctl enable bluetooth
systemctl enable reflector.timer
systemctl enable fstrim.timer
echo "--country Norway,Denmark,Sweden" >> /etc/xdg/reflector/reflector.conf

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

echo "title   Arch Linux (fallback)" > /boot/loader/entries/arch-fallback.conf
echo "linux   /vmlinuz-linux" >> /boot/loader/entries/arch-fallback.conf
echo "initrd  /intel-ucode.img" >> /boot/loader/entries/arch-fallback.conf
echo "initrd  /initramfs-linux-fallback.img" >> /boot/loader/entries/arch-fallback.conf
echo 'options root="LABEL=arch" rw' >> /boot/loader/entries/arch-fallback.conf

#User configuration
useradd -m aleksander
echo aleksander:password | chpasswd
echo "aleksander ALL=(ALL) ALL" >> /etc/sudoers.d/aleksander
