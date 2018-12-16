#!/bin/bash

sudo apt-get -y install curl wget apt-transport-https dirmngr
sudo cp /tmp/sources.list /etc/apt/sources.list
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install linux-image-4.9-amd64
sudo apt-get -y install xen-linux-system-amd64 xen-tools xenstore-utils xen-hypervisor-4.4-amd64 xen-utils-4.4
sudo sed -ri 's/.*autoballoon.*/autoballon=0/' /etc/xen/xl.conf
sudo sed -ri 's/.*GRUB_CMDLINE_XEN.*//' /etc/default/grub
sudo sed -ri 's/.*GRUB_CMDLINE_LINUX_DEFAULT.*//' /etc/default/grub
sudo sed -ri 's/.*GRUB_TERMINAL.*//' /etc/default/grub
echo 'GRUB_CMDLINE_LINUX_DEFAULT="console=hvc0"' | sudo tee -a /etc/default/grub
echo 'GRUB_TERMINAL="console"' | sudo tee -a /etc/default/grub
echo 'GRUB_CMDLINE_XEN="dom0_mem=512M,max:512M console=com1,vga noreboot=true loglvl=all guest_loglvl=all"' | sudo tee -a /etc/default/grub
sudo update-grub
