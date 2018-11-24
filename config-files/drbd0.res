resource drbd0 {
   protocol C;
disk {
   on-io-error pass_on;
}
on centosbox01.local.lab {
   device /dev/drbd0;
   disk /dev/sdb;
   address 192.168.50.4:7676;
   meta-disk internal;
}
on centosbox02.local.lab {
   device /dev/drbd0;
   disk /dev/sdb;
   address 192.168.50.5:7676;
   meta-disk internal;
}
}
