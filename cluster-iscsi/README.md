# cluster commands

## auth cluster
```
[root@centosbox01 ~]# pcs cluster auth centosbox01.local.lab centosbox02.local.lab -u hacluster -p labcluster
centosbox02.local.lab: Authorized
centosbox01.local.lab: Authorized
```
## start cluster

```
[root@centosbox01 ~]# pcs cluster setup --enable --start --name labcluster centosbox01.local.lab centosbox02.local.lab 
Destroying cluster on nodes: centosbox01.local.lab, centosbox02.local.lab...
centosbox01.local.lab: Stopping Cluster (pacemaker)...
centosbox02.local.lab: Stopping Cluster (pacemaker)...
centosbox02.local.lab: Successfully destroyed cluster
centosbox01.local.lab: Successfully destroyed cluster

Sending 'pacemaker_remote authkey' to 'centosbox01.local.lab', 'centosbox02.local.lab'
centosbox01.local.lab: successful distribution of the file 'pacemaker_remote authkey'
centosbox02.local.lab: successful distribution of the file 'pacemaker_remote authkey'
Sending cluster config files to the nodes...
centosbox01.local.lab: Succeeded
centosbox02.local.lab: Succeeded

Starting cluster on nodes: centosbox01.local.lab, centosbox02.local.lab...
centosbox01.local.lab: Starting Cluster...
centosbox02.local.lab: Starting Cluster...

Synchronizing pcsd certificates on nodes centosbox01.local.lab, centosbox02.local.lab...
centosbox02.local.lab: Success
centosbox01.local.lab: Success
Restarting pcsd on the nodes in order to reload the certificates...
centosbox02.local.lab: Success
centosbox01.local.lab: Success
[root@centosbox01 ~]# 
```
## verify status
```
[root@centosbox01 ~]# pcs status
Cluster name: labcluster
WARNING: no stonith devices and stonith-enabled is not false
Stack: corosync
Current DC: centosbox02.local.lab (version 1.1.18-11.el7_5.3-2b07d5c5a9) - partition with quorum
Last updated: Sat Dec  1 15:26:03 2018
Last change: Sat Dec  1 15:25:56 2018 by hacluster via crmd on centosbox02.local.lab

2 nodes configured
0 resources configured

Online: [ centosbox01.local.lab centosbox02.local.lab ]

No resources


Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
[root@centosbox01 ~]# 
```

## fencing virtualbox
There is a fence_vbox agent installed on each machine. fence_vbox works by connecting via ssh to the host running VMs (that is: your computer).
I decided to use it with ssh keypairs, so I must enable ssh on my laptop and exchange keys with root user of the vms and my localuser on laptop.
The agent then will be able to connect by ssh to my laptop and use VBoxManage to fence a machine. Note that I need to define a precise vmname in
vagrantfile otherwise vagrant will choose a randomname for each vm.

```
[root@centosbox02 ~]# ssh-keygen -t rsa -b 2048
```
copy the generated public key to authorized_keys on my laptop. test ssh connection
```
[root@centosbox02 ~]# ssh -l gmascolo 192.168.50.1 hostname
```
test the fencing agent
```
[root@centosbox02 ~]# fence_vbox -a 192.168.50.1 -l gmascolo -x -k ~/.ssh/id_rsa -o reboot -n centosbox01
Success: Rebooted
[root@centosbox02 ~]# 
```
(you will see centosbox01 reboot)

## enable  stonith
```
[root@centosbox01 ~]# pcs stonith create fence_centosbox01 fence_vbox identity_file="/root/.ssh/id_rsa" inet4_only=true secure=true login="gmascolo" ipaddr="192.168.50.1" port="centosbox01" pcmk_host_list="centosbox01.local.lab" pcmk_host_check=static-list pcmk_host_map="" op monitor interval=60s
[root@centosbox01 ~]# pcs constraint location fence_centosbox01 avoids centosbox01.local.lab
[root@centosbox01 ~]# pcs stonith create fence_centosbox02 fence_vbox identity_file="/root/.ssh/id_rsa" inet4_only=true secure=true login="gmascolo" ipaddr="192.168.50.1" port="centosbox02" pcmk_host_list="centosbox02.local.lab" pcmk_host_check=static-list pcmk_host_map="" op monitor interval=60s
[root@centosbox01 ~]# pcs constraint location fence_centosbox02 avoids centosbox02.local.lab
[root@centosbox01 ~]# pcs stonith show
 fence_centosbox01	(stonith:fence_vbox):	Started centosbox02.local.lab
 fence_centosbox02	(stonith:fence_vbox):	Started centosbox01.local.lab
[root@centosbox01 ~]# pcs constraint 
Location Constraints:
  Resource: fence_centosbox01
    Disabled on: centosbox01.local.lab (score:-INFINITY)
  Resource: fence_centosbox02
    Disabled on: centosbox02.local.lab (score:-INFINITY)
Ordering Constraints:
Colocation Constraints:
Ticket Constraints:
[root@centosbox01 ~]# pcs status
Cluster name: labcluster
Stack: corosync
Current DC: centosbox02.local.lab (version 1.1.18-11.el7_5.3-2b07d5c5a9) - partition with quorum
Last updated: Sat Dec  1 15:42:44 2018
Last change: Sat Dec  1 15:41:56 2018 by root via cibadmin on centosbox01.local.lab

2 nodes configured
2 resources configured

Online: [ centosbox01.local.lab centosbox02.local.lab ]

Full list of resources:

 fence_centosbox01	(stonith:fence_vbox):	Started centosbox02.local.lab
 fence_centosbox02	(stonith:fence_vbox):	Started centosbox01.local.lab

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
[root@centosbox01 ~]#
```
## Test stonith
```
[root@centosbox01 ~]# echo c > /proc/sysrq-trigger
```
centosbox01 will freeze (crash) and centosbox02 will use VBoxManage to force shutdown
```
[root@centosbox02 ~]# egrep "(pengine|stonith-ng|crmd|fence)" /var/log/messages  | tail
Dec  1 15:45:06 centosbox02 stonith-ng[1676]:  notice: fence_centosbox01 can fence (reboot) centosbox01.local.lab: static-list
Dec  1 15:45:32 centosbox02 fence_vbox: Timed out waiting to power ON
Dec  1 15:45:32 centosbox02 stonith-ng[1676]: warning: fence_vbox[2234] stderr: [ 2018-12-01 15:45:32,168 ERROR: Timed out waiting to power ON ]
Dec  1 15:45:32 centosbox02 stonith-ng[1676]: warning: fence_vbox[2234] stderr: [  ]
Dec  1 15:45:32 centosbox02 stonith-ng[1676]:  notice: Operation 'reboot' [2234] (call 2 from crmd.1680) for host 'centosbox01.local.lab' with device 'fence_centosbox01' returned: 0 (OK)
Dec  1 15:45:32 centosbox02 stonith-ng[1676]:  notice: Operation reboot of centosbox01.local.lab by centosbox02.local.lab for crmd.1680@centosbox02.local.lab.939413ad: OK
Dec  1 15:45:32 centosbox02 crmd[1680]:  notice: Stonith operation 2/1:10:0:aaeff28f-d52c-460c-b56d-164a3706e37d: OK (0)
Dec  1 15:45:32 centosbox02 crmd[1680]:  notice: Peer centosbox01.local.lab was terminated (reboot) by centosbox02.local.lab on behalf of crmd.1680: OK
Dec  1 15:45:32 centosbox02 crmd[1680]:  notice: Transition 10 (Complete=4, Pending=0, Fired=0, Skipped=0, Incomplete=0, Source=/var/lib/pacemaker/pengine/pe-warn-0.bz2): Complete
Dec  1 15:45:32 centosbox02 crmd[1680]:  notice: State transition S_TRANSITION_ENGINE -> S_IDLE
[root@centosbox02 ~]# 
```
## create the iscsi target on iscsisan
first create a partition on sdb (this is the custom vdi created by vagrantfile)
```
[root@iscsisan ~]# parted /dev/sdb
GNU Parted 3.1
Using /dev/sdb
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) mklabel msdos
(parted) mkpart pri 2048s -1
(parted) align-check opt 1
1 aligned
(parted) print
Model: ATA VBOX HARDDISK (scsi)
Disk /dev/sdb: 3221MB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  3220MB  3219MB  primary

(parted) quit
Information: You may need to update /etc/fstab.

[root@iscsisan ~]#
```
install targetcli
```
[root@iscsisan ~]# yum -y install targetcli
```
create an iscsi target
```
[root@iscsisan ~]# targetcli 
Warning: Could not load preferences file /root/.targetcli/prefs.bin.
targetcli shell version 2.1.fb46
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> cd backstores/
/backstores> cd block 
/backstores/block> create name=sdb1 dev=/dev/sdb1 
Created block storage object sdb1 using /dev/sdb1.
/backstores/block> ls
o- block ................................................ [Storage Objects: 1]
  o- sdb1 ....................... [/dev/sdb1 (0 bytes) write-thru deactivated]
    o- alua ................................................. [ALUA Groups: 1]
      o- default_tg_pt_gp ..................... [ALUA state: Active/optimized]
/backstores/block> cd /iscsi 
/iscsi> create wwn=iqn.2018-12.lab.local:clustertgt
Created target iqn.2018-12.lab.local:clustertgt.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.
/iscsi> ls
o- iscsi ........................................................ [Targets: 1]
  o- iqn.2018-12.lab.local:clustertgt .............................. [TPGs: 1]
    o- tpg1 ........................................... [no-gen-acls, no-auth]
      o- acls ...................................................... [ACLs: 0]
      o- luns ...................................................... [LUNs: 0]
      o- portals ................................................ [Portals: 1]
        o- 0.0.0.0:3260 ................................................. [OK]
/iscsi> cd iqn.2018-12.lab.local:clustertgt/tpg1/
iqn.2018-12.lab.local:clustertgt/tpg1/acls/     
iqn.2018-12.lab.local:clustertgt/tpg1/luns/     
iqn.2018-12.lab.local:clustertgt/tpg1/portals/  
/iscsi> cd iqn.2018-12.lab.local:clustertgt/tpg1/portals/
/iscsi/iqn.20.../tpg1/portals> delete 0.0.0.0 3260
Deleted network portal 0.0.0.0:3260
/iscsi/iqn.20.../tpg1/portals> create 192.168.50.7 3260
Using default IP port 3260
Created network portal 192.168.50.7:3260.
/iscsi/iqn.20.../tpg1/portals> cd /iscsi/
/iscsi> ls
o- iscsi ........................................................ [Targets: 1]
  o- iqn.2018-12.lab.local:clustertgt .............................. [TPGs: 1]
    o- tpg1 ........................................... [no-gen-acls, no-auth]
      o- acls ...................................................... [ACLs: 0]
      o- luns ...................................................... [LUNs: 0]
      o- portals ................................................ [Portals: 1]
        o- 192.168.50.7:3260 ............................................ [OK]
/iscsi> cd iqn.2018-12.lab.local:clustertgt/tpg1/acls 
/iscsi/iqn.20...tgt/tpg1/acls> create wwn=iqn.2018-12.lab.local:centosbox01
Created Node ACL for iqn.2018-12.lab.local:centosbox01
/iscsi/iqn.20...tgt/tpg1/acls> create wwn=iqn.2018-12.lab.local:centosbox02
Created Node ACL for iqn.2018-12.lab.local:centosbox02
/iscsi/iqn.20...tgt/tpg1/acls> cd /
/> ls
o- / ................................................................... [...]
  o- backstores ........................................................ [...]
  | o- block ............................................ [Storage Objects: 1]
  | | o- sdb1 ................... [/dev/sdb1 (0 bytes) write-thru deactivated]
  | |   o- alua ............................................. [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ................. [ALUA state: Active/optimized]
  | o- fileio ........................................... [Storage Objects: 0]
  | o- pscsi ............................................ [Storage Objects: 0]
  | o- ramdisk .......................................... [Storage Objects: 0]
  o- iscsi ...................................................... [Targets: 1]
  | o- iqn.2018-12.lab.local:clustertgt ............................ [TPGs: 1]
  |   o- tpg1 ......................................... [no-gen-acls, no-auth]
  |     o- acls .................................................... [ACLs: 2]
  |     | o- iqn.2018-12.lab.local:centosbox01 .............. [Mapped LUNs: 0]
  |     | o- iqn.2018-12.lab.local:centosbox02 .............. [Mapped LUNs: 0]
  |     o- luns .................................................... [LUNs: 0]
  |     o- portals .............................................. [Portals: 1]
  |       o- 192.168.50.7:3260 .......................................... [OK]
  o- loopback ................................................... [Targets: 0]
/> cd iscsi/iqn.2018-12.lab.local:clustertgt/tpg1/luns 
/iscsi/iqn.20...tgt/tpg1/luns> create /backstores/block/sdb1 
Created LUN 0.
Created LUN 0->0 mapping in node ACL iqn.2018-12.lab.local:centosbox02
Created LUN 0->0 mapping in node ACL iqn.2018-12.lab.local:centosbox01
/iscsi/iqn.20...tgt/tpg1/luns> cd /
/> ls
o- / ................................................................... [...]
  o- backstores ........................................................ [...]
  | o- block ............................................ [Storage Objects: 1]
  | | o- sdb1 ..................... [/dev/sdb1 (0 bytes) write-thru activated]
  | |   o- alua ............................................. [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ................. [ALUA state: Active/optimized]
  | o- fileio ........................................... [Storage Objects: 0]
  | o- pscsi ............................................ [Storage Objects: 0]
  | o- ramdisk .......................................... [Storage Objects: 0]
  o- iscsi ...................................................... [Targets: 1]
  | o- iqn.2018-12.lab.local:clustertgt ............................ [TPGs: 1]
  |   o- tpg1 ......................................... [no-gen-acls, no-auth]
  |     o- acls .................................................... [ACLs: 2]
  |     | o- iqn.2018-12.lab.local:centosbox01 .............. [Mapped LUNs: 1]
  |     | | o- mapped_lun0 ............................ [lun0 block/sdb1 (rw)]
  |     | o- iqn.2018-12.lab.local:centosbox02 .............. [Mapped LUNs: 1]
  |     |   o- mapped_lun0 ............................ [lun0 block/sdb1 (rw)]
  |     o- luns .................................................... [LUNs: 1]
  |     | o- lun0 ................ [block/sdb1 (/dev/sdb1) (default_tg_pt_gp)]
  |     o- portals .............................................. [Portals: 1]
  |       o- 192.168.50.7:3260 .......................................... [OK]
  o- loopback ................................................... [Targets: 0]
/> exit
Global pref auto_save_on_exit=true
Configuration saved to /etc/target/saveconfig.json
[root@iscsisan ~]# 

```
enable target service or configuration will be lost at reboot!!
```
[root@iscsisan ~]# systemctl enable --now target
Created symlink from /etc/systemd/system/multi-user.target.wants/target.service to /usr/lib/systemd/system/target.service.
[root@iscsisan ~]# 
```
## configure iscsi initiator on nodes
on both nodes
```
[root@centosbox01 ~]# yum -y install iscsi-initiator-utils
```
configure the initiator name. this MUST match the one used in acls in iscsi target
```
[root@centosbox01 ~]# cat /etc/iscsi/initiatorname.iscsi 
InitiatorName=iqn.1994-05.com.redhat:78d965d4f3f4
[root@centosbox01 ~]# echo "InitiatorName=iqn.2018-12.lab.local:centosbox01" > /etc/iscsi/initiatorname.iscsi 
[root@centosbox01 ~]# 
```
discover the target and login
```
[root@centosbox01 ~]#  iscsiadm -m discovery -t st -p 192.168.50.7:3260
192.168.50.7:3260,1 iqn.2018-12.lab.local:clustertgt
[root@centosbox01 ~]# iscsiadm -m node -T iqn.2018-12.lab.local:clustertgt -l
Logging in to [iface: default, target: iqn.2018-12.lab.local:clustertgt, portal: 192.168.50.7,3260] (multiple)
Login to [iface: default, target: iqn.2018-12.lab.local:clustertgt, portal: 192.168.50.7,3260] successful.
[root@centosbox01 ~]# lsscsi 
[0:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sda 
[0:0:1:0]    cd/dvd  VBOX     CD-ROM           1.0   /dev/sr0 
[2:0:0:0]    disk    LIO-ORG  sdb1             4.0   /dev/sdb 
[root@centosbox01 ~]# 
```
**IMPORTANT**:when you shutdown you vagrant machines please be sure to first shutdown nodes then shutdown iscsisan

## setup cluster lvm

configuration is `/etc/lvm/lvm.conf`

lvm works with physical volumes, volume groups and logical volumes.
the problem is now this: when you mount a shared volume, like an iscsi lun,
you have the same device (let's say /dev/sdb) in all of your servers.
When you create a LVM vol on top of that physical volume, the volume group
(that stores the lvm metadata) risk to be corrupted if two nodes try to write to the same
block. For this reason we need a special version of lvm used for clusters,
and some locking mechanism. We shoud also disable lvm metadata management on the
single node and let the cluster manage it.  
  
distributed lock manager, or dlm, manage locks.  
clvmd is the clustered lvm daemon.  
  
in redhat centos you can use HALVM or cLVM models. with HALVM you make an lvm vol writable
only by one node at a time (that is, you use an active/passive model). If one node fail
the other take on and mount the vol as read/write.  
cLVM on the other side let you write simultaneosly from both nodes but for that you will need
a clustered file system like GFS or OCFS2
