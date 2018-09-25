#!/bin/bash -eux

#SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER="root"


echo "==> Installing VirtualBox guest additions"
# Assuming the following packages are installed
# apt-get install -y linux-headers-$(uname -r) build-essential perl
# apt-get install -y dkms

#VBOX_VERSION=$(cat /home/${SSH_USER}/.vbox_version)
mount -o loop /${SSH_USER}/VBoxGuestAdditions.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm /${SSH_USER}/VBoxGuestAdditions_$VBOX_VERSION.iso
rm /${SSH_USER}/.vbox_version
