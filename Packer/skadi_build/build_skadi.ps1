#! /usr/bin/pwsh
$ErrorActionPreference = "Stop"

packer build -force create_basebox.json
packer build -force create_boxes.json
vagrant.exe box add box/virtualbox/skadi_server-2019.4.box --name skadivm/skadi_server --force
vagrant.exe box add box/vmware/skadi_server-2019.4.box --name skadivm/skadi_server --force
