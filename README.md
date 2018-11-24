# LPIC3-lab
lab for lpic3 study

this is a lab built with vagrant to experiment with centos7 cluster (pacemaker/corosync)

#commands examples

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

configure drbd in cluster
```
pcs resource create drbd0-r0 ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=15 role=Master op monitor interval=30 role=Slave
pcs resource master ms-drbd0-r0 drbd0-r0 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
```

verify setup

```
[root@centosbox01 ~]# drbd-overview 
```
