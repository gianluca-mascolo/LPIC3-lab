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

