#!/usr/bin/env bash
# Remove all snapshots prior to these steps
# Zero out disk
dd if=/dev/zero of=/EMPTY bs=1M ;rm -f /EMPTY

# Remove history
sudo rm /root/.bash_history;touch /root/.bash_history
rm .bash_history;touch .bash_history;history -c

# Once complete run the following on the host OS to compress the image
# "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe" -k <path to skadi2018_disk1.vmdk>
