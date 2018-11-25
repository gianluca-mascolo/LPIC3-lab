# LPIC3-lab
lab for lpic3 study

this is a lab built with vagrant to experiment with centos7 cluster (pacemaker/corosync)

# vagrant commands

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
