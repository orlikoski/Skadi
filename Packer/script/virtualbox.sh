#!/bin/bash -eux

SSH_USER=skadi
#SSH_USER="root"


echo "==> Installing VirtualBox guest additions"
# Assuming the following packages are installed
#apt-get install -y linux-headers-$(uname -r) build-essential perl
#apt-get install -y dkms

VBOX_VERSION=$(cat /home/$SSH_USER/.vbox_version)
mount -o loop /home/$SSH_USER/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/$SSH_USER/*
rm -rf /home/$SSH_USER/.vbox_version
