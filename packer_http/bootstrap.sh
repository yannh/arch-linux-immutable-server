#!/bin/bash -e

sgdisk --zap-all /dev/vda
printf "n\n1\n\n+200M\nef00\nw\ny\n" | gdisk /dev/vda
mkfs.fat -F32 -n EFIBOOT /dev/vda1
printf "n\n2\n\n\n8304\nw\ny\n"| gdisk /dev/vda
mkfs.ext4 -L ROOT -m 0 -U 4f68bce3-e8cd-4db1-96e7-fbcaf984b709 /dev/vda2

mount -L ROOT /mnt/
mkdir /mnt/boot
mount -L EFIBOOT /mnt/boot

yes '' | pacstrap -i /mnt base linux

genfstab -Lp /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash -e <<CHROOTEOF
pacman -Sy --noprogressbar --noconfirm efibootmgr dosfstools gptfdisk

bootctl install

cat << BOOTCTL > /boot/loader/entries/arch-uefi.conf
title          Arch Linux
linux          /vmlinuz-linux
initrd         /initramfs-linux.img
options        root=LABEL=ROOT rw
BOOTCTL

cat << BOOTCTL > /boot/loader/loader.conf
default   arch-uefi
timeout   1
BOOTCTL

pacman -Sy --noprogressbar --noconfirm python3 ansible openssh

# Bootstrap network setup
cat > /etc/systemd/network/10-en-dhcp.network <<EOF
[Match]
Name=en*

[Network]
DHCP=ipv4

[DHCP]
UseDomains=true
EOF
systemctl enable systemd-networkd

# SSHd setup
sed -i "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl enable sshd

# Sets bootstrap root password
echo "root:changeme" | chpasswd

# DNS setup
systemctl enable systemd-resolved

# Generating initramfs
sed -i 's/^HOOKS.*/HOOKS=(base systemd keymap modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

CHROOTEOF

reboot

