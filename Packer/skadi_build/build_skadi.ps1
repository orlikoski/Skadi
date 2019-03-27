packer build -force create_basebox.json
packer build -force create_boxes.json
vagrant.exe box add box/virtualbox/skadi_server-2019.2.box --name skadivm/skadi_server
vagrant.exe box add box/vmware/skadi_server-2019.2.box --name skadivm/skadi_server
