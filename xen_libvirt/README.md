# libvirt + xen

## Why?

I want to try a clean open source xen installed in debian in my pc. It is possible to install xen hypervisor INSIDE a virtual machine itself. This method
is called nested vm. **NOTE:** I was able to run only PV guests in xen. When I tried to run HVM the xen host die.
## How?
I will install xen inside a kvm machine. First of all I've to enable nesting in kvm.

```
[gmascolo-pc default]# cat /etc/modprobe.d/kvm.conf 
options kvm_intel nested=1
options kvm_intel ept=1
options kvm_intel ignore_msrs=1
options kvm_intel emulate_invalid_guest_state=0
[gmascolo-pc default]# 
```
(not sure about the last two options, but the first two are really necessary)  
Then I enable iommu on grub
```
[gmascolo-pc default]# cat /etc/default/grub | grep mmu
GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=UUID=2ce09f86-6465-4414-ab52-adcb0c757059 vsyscall=emulate intel_iommu=on"
[gmascolo-pc default]# 
```
(insert grub options may use a different file on your distro, I'm using Manjaro)  
## First try: install debian manually with qemu
First try I've done is to install a plain debian inside qemu image and start it. I prepared two qcow2 disk images with qemu-img, one to use for the OS,
the other is a data disk and will be used as an lvm volume for guests. To start the vm I use a small script, [start-me.sh](scripts/start-emu.sh).
This script setup a tap0 interface and startup a [tinyproxy](https://github.com/tinyproxy/tinyproxy) process on my laptop to allow accessing internet
from xen host. I know there are other methods like bridging and iptables, but I don't won't to mess up too much networking into my laptop because I use
it for my daily job. And to setup bridging or iptables I will need to disable NetworkManager or shutdown docker, while a tinyproxy is enough for the exercise.
The important stuff here are the options used to launch qemu:
```
qemu-system-x86_64 \
	-accel kvm -enable-kvm -cpu host \
	-machine q35,kernel_irqchip=split,accel=kvm \
	-smp cpus=2,cores=1 \
	-device intel-iommu,intremap=on,caching-mode=on \
	-name debian \
	-hda ./debian.img \
	-hdb ./debian-data.img \
	-boot c -m 2048 \
	-netdev tap,id=qnet0,ifname=tap0,script=no,downscript=no -device virtio-net,netdev=qnet0
```
please note the `-cpu host` that enable passing the vmx flags to the guest.

```
$ vagrant up --provider=libvirt
Bringing machine 'default' up with 'libvirt' provider...
==> default: Box 'debian/jessie64' could not be found. Attempting to find and install...
    default: Box Provider: libvirt
    default: Box Version: >= 0
==> default: Loading metadata for box 'debian/jessie64'
    default: URL: https://vagrantcloud.com/debian/jessie64
==> default: Adding box 'debian/jessie64' (v8.11.0) for provider: libvirt
    default: Downloading: https://vagrantcloud.com/debian/boxes/jessie64/versions/8.11.0/providers/libvirt.box
    default: Download redirected to host: vagrantcloud-files-production.s3.amazonaws.com
```
