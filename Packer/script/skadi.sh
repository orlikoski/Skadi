#!/bin/bash

date > /etc/box_build_time

SSH_USER=${SSH_USERNAME:-skadi}
SSH_PASS=${SSH_PASSWORD:-skadi}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

# Set up sudo
echo "==> Giving ${SSH_USER} sudo powers"
echo "${SSH_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/$SSH_USER
chmod 440 /etc/sudoers.d/$SSH_USER

# Fix stdin not being a tty
if grep -q -E "^mesg n$" /root/.profile && sed -i "s/^mesg n$/tty -s \\&\\& mesg n/g" /root/.profile; then
  echo "==> Fixed stdin not being a tty."
fi
