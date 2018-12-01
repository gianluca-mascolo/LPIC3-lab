# LPIC3-lab
lab for lpic3 304 study.

this is a lab built with vagrant to experiment with centos7 cluster (pacemaker/corosync)

## vagrant commands

```
[gmascolo@gmascolo-pc vagrant]$ vagrant plugin list
vagrant-disksize (0.1.3, global)
vagrant-hostmanager (1.8.9, global)
[gmascolo@gmascolo-pc vagrant]$ 
```
resync playbook
```
$ vagrant rsync
```

replay ansible on a node
```
[vagrant@centosbox01 ~]$ ansible-playbook -c local -i 'localhost,' /vagrant/playbook.yml 
```

## install vbox addition on a node
insert vbox additions cdrom
```
[root@iscsisan ~]# mount -t iso9660 -o ro /dev/sr0 /mnt/
[root@iscsisan ~]# cd /mnt/
[root@iscsisan mnt]# ./VBoxLinuxAdditions.run 
Verifying archive integrity... All good.
Uncompressing VirtualBox 5.2.22 Guest Additions for Linux........
VirtualBox Guest Additions installer
Copying additional installer modules ...
Installing additional modules ...
VirtualBox Guest Additions: Building the VirtualBox Guest Additions kernel modules.  This may take a while.
VirtualBox Guest Additions: Starting.
[root@iscsisan mnt]# logout
[vagrant@iscsisan ~]$ logout
Connection to 127.0.0.1 closed.
~/P/L/cluster-iscsi (master|heads/master-0-g2d2ddb) 
$ vagrant halt iscsisan
==> iscsisan: Attempting graceful shutdown of VM...
~/P/L/cluster-iscsi (master|heads/master-0-g2d2ddb) 
```
change node configuration to paravirt io network for better performance
```
$ vagrant up iscsisan
Bringing machine 'iscsisan' up with 'virtualbox' provider...
==> iscsisan: Checking if box 'centos/7' is up to date...
==> iscsisan: Clearing any previously set forwarded ports...
==> iscsisan: Clearing any previously set network interfaces...
$ vagrant ssh iscsisan
Last login: Sat Dec  1 16:03:58 2018 from 10.0.2.2
[vagrant@iscsisan ~]$ sudo su -
Last login: Sat Dec  1 16:04:11 UTC 2018 on pts/0
[root@iscsisan ~]# ethtool -i eth0
driver: virtio_net
version: 1.0.0
firmware-version: 
expansion-rom-version: 
bus-info: 0000:00:03.0
supports-statistics: no
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no
[root@iscsisan ~]# 
```
