#!/usr/bin/env bash

TAPIF="tap0"
TAPADDR="172.16.0.1"
TAPMASK="24"
export TAPIF TAPADDR
echo -n "* Setting tap interface $TAPIF ... "
/usr/bin/ip link show dev $TAPIF 2> /dev/null &> /dev/null || sudo /usr/bin/ip tuntap add dev $TAPIF mode tap user gmascolo group gmascolo
/usr/bin/ip link show dev $TAPIF 2> /dev/null &> /dev/null && echo OK
echo -n "* Bring up tap interface $TAPIF ... "
sudo /usr/bin/ip link set $TAPIF up && echo OK
echo -n "* Assign $TAPADDR to tap interface $TAPIF ... "
/usr/bin/ip addr show dev $TAPIF | grep -w inet | grep -qG "$TAPADDR" || sudo /usr/bin/ip addr add dev $TAPIF ${TAPADDR}/${TAPMASK}
/usr/bin/ip addr show dev $TAPIF | grep -w inet | grep -qG "$TAPADDR" && echo "OK"
echo "* Detect default route interface ... "
ROUTEIF="$(/usr/bin/ip route show default | sed -re "s/.*[[:space:]]+dev[[:space:]]+([^ ]+).*/\1/")"
/usr/bin/ip link show dev $ROUTEIF 2> /dev/null &> /dev/null || exit 1
ROUTEADDR="$(/usr/bin/ip addr show dev $ROUTEIF | egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]+" | grep -w inet | awk '{print $2}' | cut -d '/' -f 1)"
echo "$ROUTEADDR" | egrep "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
echo -e  "\tRoute interface via interface $ROUTEIF has ip $ROUTEADDR"
export ROUTEIF ROUTEADDR
echo -n "* Starting tinyproxy ... "
pidof tinyproxy 2> /dev/null &> /dev/null
if ( [ $? -ne 0 ] ); then {
 TINYCONF="$(mktemp -t tiny.XXXXXXX.conf)"
 TINYLOG="$(mktemp -t tiny.XXXXXXX.log)"
 export TINYLOG
 envsubst < tinyproxy.conf.skel > $TINYCONF
 /usr/bin/tinyproxy -c $TINYCONF
}
fi
pidof tinyproxy 2> /dev/null &> /dev/null
if ( [ $? -eq 0 ] ); then {
 echo OK
 TINYRUNCONF="$(ps -C tinyproxy w | grep "tiny.*conf" | head -1 | sed -re "s/.*tinyproxy -c (.*)/\1/")"
 echo -n "* tinyproxy log file is ... "
 grep LogFile "$TINYRUNCONF" | head -1 | cut -d \" -f 2
} else {
 exit 1
}
fi


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

