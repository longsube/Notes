#!/bin/bash

function stop_service() {
echo "--------Stop all service-------------"
echo

for i in `find /etc/init.d/ -type f -name "neutron-*"`; do $i stop; done;
for i in `find /etc/init.d/ -type f -name "aodh-*"`; do $i stop; done;
for i in `find /etc/init.d/ -type f -name "ceilometer-*"`; do $i stop; done;
for i in `find /etc/init.d/ -type f -name "cinder-*"`; do $i stop; done;
for i in `find /etc/init.d/ -type f -name "glance-*"`; do $i stop; done;
for i in `find /etc/init.d/ -type f -name "nova-*"`; do $i stop; done;
/etc/init.d/apache2 stop
/etc/init.d/pacemaker stop
/etc/init.d/corosync stop
/etc/init.d/memcached stop
/etc/init.d/rabbitmq-server stop
/etc/init.d/mysql stop
/etc/init.d/xinetd stop
/etc/init.d/keystone stop
/etc/init.d/haproxy stop

echo "----------------Stop all service done!--------------"
echo
}

function upgrade_os() {
echo "--------Begin upgrade OS-------------"
echo

sed -i 's/trusty/xenial/' /etc/apt/sources.list
apt-get update
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get dist-upgrade -o Dpkg::Options::="--force-confold" --force-yes -y

echo "--------Upgrade OS done!-------------"

init 6
}

# stop_service 2>&1 >>/root/$0.log

upgrade_os 2>&1 >>/root/$0.log
