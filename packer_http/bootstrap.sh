#!/bin/bash -e

printf "n\np\n1\n\n+200M\nw\n" | fdisk /dev/vda
printf "n\np\n2\n\n\nt\n2\n8e\nw\n" | fdisk /dev/vda
yes | mkfs.ext4 -m 1 /dev/vda1
yes | mkfs.ext4 -m 1 /dev/vda2

e2label /dev/vda1 boot
e2label /dev/vda2 root

mount /dev/vda2 /mnt/
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot

yes '' | pacstrap -i /mnt base linux

genfstab -Lp /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash -e <<CHROOTEOF && reboot
pacman -Sy
pacman -Sy --noconfirm openssh grub python3 ansible

# Configure grub
grub-install /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg

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
CHROOTEOF
reboot

