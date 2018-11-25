# cluster and drbd commands

## note for me: disable selinux or learn to configure it!!!
auth cluster
```
[root@centosbox01 ~]# pcs cluster auth centosbox01.local.lab centosbox02.local.lab -u hacluster -p labcluster
centosbox02.local.lab: Authorized
centosbox01.local.lab: Authorized
```
start cluster

```
[root@centosbox01 ~]# pcs cluster setup --start --name labcluster centosbox01.local.lab centosbox02.local.lab 
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

disable stonith
```
[root@centosbox01 ~]# pcs property set stonith-enabled=false
```

## configure drbd

### note: drbd on centos is part of elrepo

create drbd

copy drbd0.res from configs to /etc/drbd.d

verify res is valid
```
[root@centosbox01 ~]# drbdadm dump all
```
if valid will dump the conf. if not print errors

create device on both nodes
```
[root@centosbox01 ~]# drbdadm -- --ignore-sanity-checks create-md drbd0
```

start on both nodes
```
[root@centosbox01 ~]# drbdadm up drbd0
```
promote only ONE node to be primary
```
[root@centosbox01 drbd.d]# drbdadm primary --force drbd0
[root@centosbox01 drbd.d]# drbd-overview 
NOTE: drbd-overview will be deprecated soon.
Please consider using drbdtop.

 0:drbd0/0  SyncSource Primary/Secondary UpToDate/Inconsistent 
	[===>................] sync'ed: 23.1% (43600/51160)K           
[root@centosbox01 drbd.d]# drbd-overview 
NOTE: drbd-overview will be deprecated soon.
Please consider using drbdtop.

 0:drbd0/0  SyncSource Primary/Secondary UpToDate/Inconsistent 
	[=====>..............] sync'ed: 30.8% (39164/51160)K           
[root@centosbox01 drbd.d]# 
```
verify setup

```
[root@centosbox01 ~]# drbd-overview 
```

format the filesystem
```
[root@centosbox01 ~]# mkfs.xfs /dev/drbd0 
```
configure drbd in cluster
```
pcs resource create drbd0-r0 ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=15 role=Master op monitor interval=30 role=Slave
pcs resource master ms-drbd0-r0 drbd0-r0 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
```

manage drbd filesystem
```
pcs resource create  drbd-r0-fs ocf:heartbeat:Filesystem device="/dev/drbd0" directory="/shared" fstype=xfs op start timeout=60 op monitor timeout=40 interval=20
pcs constraint colocation add drbd-r0-fs ms-drbd0-r0 INFINITY with-rsc-role=Master
pcs constraint order promote ms-drbd0-r0 then start drbd-r0-fs

```

how to enqueue/push multiple pcs commands at a time (it writes a local cib file)
```
[root@centosbox01 ~]# pcs cluster cib drbd_cfg
[root@centosbox01 ~]# ls
anaconda-ks.cfg  drbd_cfg  original-ks.cfg
[root@centosbox01 ~]# pcs -f drbd_cfg resource create drbd0-r0 ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=15 role=Master op monitor interval=30 role=Slave
[root@centosbox01 ~]# pcs resource master ms-drbd0-r0 drbd0-r0 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
Error: Unable to find resource or group with id drbd0-r0
[root@centosbox01 ~]# pcs -f drbd_cfg resource master ms-drbd0-r0 drbd0-r0 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
[root@centosbox01 ~]# pcs -f drbd_cfg resource show
 Master/Slave Set: ms-drbd0-r0 [drbd0-r0]
     Stopped: [ centosbox01.local.lab centosbox02.local.lab ]
[root@centosbox01 ~]# pcs cluster cib-push drbd_cfg 
CIB updated
```

## configure an high available iscsi target backed by drbd

first configure drbd
```
pcs resource create drbd0-r0 ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=15 role=Master op monitor interval=30 role=Slave
pcs resource master ms-drbd0-r0 drbd0-r0 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
```

install target utils on both nodes
```
yum install scsi-target-utils targetcli
```

assign a vip for the target and create a target and a lun. use `lio-t` for implementation. `lio-t` make use of the `targetcli` backend command. if you specify only `lio` (the default)
you will get an error about a missing command `tcm_node`. this is from the old lio-utils package not supported anymore.

```
pcs resource create iscsi-tgt-ip ocf:heartbeat:IPaddr2 ip=192.168.50.100 cidr_netmask=32 op monitor interval=10 timeout=20
pcs resource create iscsi-tgt ocf:heartbeat:iSCSITarget implementation=lio-t iqn=iqn.2018-11.lab.cluster:clustertgt
pcs resource create iscsilun0 ocf:heartbeat:iSCSILogicalUnit implementation=lio-t target_iqn="iqn.2018-11.lab.cluster:clustertgt" path="/dev/drbd0" lun=0 allowed_initiators="iqn.2018-11.lab.cluster:centosbox01 iqn.2018-11.lab.cluster:centosbox02"
```
group all together and make sure that iscsi target is started after drbd

```
pcs resource group add iscsigroup iscsi-tgt-ip iscsi-tgt iscsilun0
pcs constraint order start ms-drbd0-r0 then start iscsigroup
pcs constraint colocation add iscsigroup ms-drbd0-r0 INFINITY with-rsc-role=Master
```
