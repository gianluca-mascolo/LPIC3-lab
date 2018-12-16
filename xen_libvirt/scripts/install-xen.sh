#!/bin/bash

apt-get -y install xen-linux-system-amd64 xen-tools xenstore-utils xen-hypervisor-4.4-amd64 xen-utils-4.4
sed -ri 's/.*autoballoon.*/autoballon=0/' /etc/xen/xl.conf
sed -ri 's/.*GRUB_CMDLINE_XEN.*//' /etc/default/grub
echo 'GRUB_CMDLINE_XEN="dom0_mem=512M,max:512M"' >> /etc/default/grub
update-grub
