# libvirt + xen

## Why?

I want to try a clean open source xen installed in debian in my pc. It is possible to install xen hypervisor INSIDE a virtual machine itself. This method
is called nested vm.
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
[a relative link](scripts/start-emu.sh)
