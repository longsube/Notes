# Hướng dẫn upgrade Mitaka lên Newton

Upgrade OS Ubuntu 14.04 lên 16.04
Trươc khi upgrade, cần backup lại toàn bộ DB của OpenStack
mysqldump -uroot -p --all-databases > /root/backup_mitaka/dump.sql
backup lại thư mục cấu hình của mysql
cp -rp /etc/mysql /root/backup_mitaka

Để giữ nguyên version của các package đang cài đặt, sử dụng lệnh sau để upgrade:
do-release-upgrade
Thực hiện theo các hướng dẫn khi upgrade

Sau khi upgrade xong, version cuar mysql se thay doi
mysql -version
mysql  Ver 15.1 Distrib 10.0.31-MariaDB, for debian-linux-gnu (x86_64) using readline 5.2

copy lại file cấu hình của DB
cp -p cp /root/mysql/conf.d/mysqld_openstack.cnf /etc/mysql/mariadb.conf.d/99-openstack.cnf
service mysql restart





Khai báo repo cho Newton
apt-get install software-properties-common
add-apt-repository cloud-archive:newton

Gỡ các repo của mitaka
cd /etc/apt/sources.list.d
mv cloudarchive-mitaka.list cloudarchive-mitaka.list.distUpgrade  cloudarchive-mitaka.list.save /root/backup_mitaka/

apt-get update



Upgrade Keystone
backup cấu hình
cp -rp /etc/keystone /root/backup_mitaka/

Để tránh lỗi Name duplicates previous WSGI daemon definition của apache khi có 2 tiến trình wsgi chung 1 name, gớ bổ cấu hình wsgi của mitaka
cp /etc/apache2/sites-available/wsgi-keystone.conf /root/backup_mitaka
rm /etc/apache2/sites-enabled/wsgi-keystone.conf

Stop service
service apache2 stop
apt-get install --only-upgrade keystone

Mở file cấu hình keystone: vi /etc/keystone/keystone.conf

Tìm tới section [database] và chỉnh sửa như sau:

[database]
connection = mysql+pymysql://keystone:Welcome123@172.16.69.70/keystone
Tìm tới section [token] và chỉnh sửa như sau:
[token]
provider = fernet
Cập nhật cấu vào trong database keystone:
su -s /bin/sh -c "keystone-manage db_sync" keystone

Kiểm tra phiên bản mới của keystone:
root@controller:~# dpkg -l | grep keystone
ii  keystone                            2:10.0.3-0ubuntu1~cloud0                   all          OpenStack identity service - Daemons
ii  python-keystone                     2:10.0.3-0ubuntu1~cloud0                   all          OpenStack identity service - Python library
ii  python-keystoneauth1                2.4.1-1ubuntu0.16.04.1                     all          authentication library for OpenStack Identity - Python 2.7
ii  python-keystoneclient               1:2.3.1-2                                  all          client library for the OpenStack Keystone API - Python 2.x
ii  python-keystonemiddleware           4.4.1-0ubuntu1                             all          Middleware for OpenStack Identity (Keystone) - Python 2.x

Kiểm tra hoạt động của keystone
root@controller:~# openstack endpoint list
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                                         |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------------+
| 444ff98b5018435aa2338b50c14c4df2 | RegionOne | nova         | compute      | True    | public    | http://172.16.68.70:8774/v2.1/%(tenant_id)s |
| 4a1edfb7dc014a4499a795b1c23b859b | RegionOne | nova         | compute      | True    | admin     | http://172.16.68.70:8774/v2.1/%(tenant_id)s |
| 6decd051189c4898ac989ed30850bcbc | RegionOne | glance       | image        | True    | admin     | http://172.16.68.70:9292                    |
| 7d524a7d889045459a9216f471df4b1e | RegionOne | keystone     | identity     | True    | internal  | http://172.16.68.70:5000/v3                 |
| 8e971506fffd44a2a677ee7439174bdb | RegionOne | keystone     | identity     | True    | public    | http://172.16.68.70:5000/v3                 |
| 9f1289b8e2284ed9afc5a11340509626 | RegionOne | keystone     | identity     | True    | admin     | http://172.16.68.70:35357/v3                |
| a245941dc23940f2bdedfc6014a99f57 | RegionOne | neutron      | network      | True    | public    | http://172.16.68.70:9696                    |
| af39564c34d74eaa8483facde9c92329 | RegionOne | glance       | image        | True    | public    | http://172.16.68.70:9292                    |
| b85dee7e62e3410094bad2eabe06a4d5 | RegionOne | glance       | image        | True    | internal  | http://172.16.68.70:9292                    |
| dc5518c4b4694ca3a8edc5a52a5586bb | RegionOne | neutron      | network      | True    | admin     | http://172.16.68.70:9696                    |
| e5fdcf697af04b39b103b1b33247ee0b | RegionOne | neutron      | network      | True    | internal  | http://172.16.68.70:9696                    |
| fa08e0ce1b2f43ee9db13e18498853b4 | RegionOne | nova         | compute      | True    | internal  | http://172.16.68.70:8774/v2.1/%(tenant_id)s |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------------+

Upgrade Glance
backup cấu hình
cp -rp /etc/glance /root/backup_mitaka/

mysqldump -u root -p --databases glance > /root/backup_mitaka/glance.sqlbak
Stop service
service glance-api stop
service glance-registry stop
apt-get install --only-upgrade glance

Cấu hình glance:
Lưu lại các file cấu hình gốc của glance:
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig
cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.orig
cat /etc/glance/glance-api.conf.orig | egrep -v '^#|^$' > /etc/glance/glance-api.conf
cat /etc/glance/glance-registry.conf.orig | egrep -v '^#|^$' > /etc/glance/glance-registry.conf
Chỉnh sửa file /etc/glance/glance-api.conf theo các bước sau:

Tìm tới section [database] sửa lại như sau:
connection = mysql+pymysql://glance:Welcome123@controller/glance
Tìm tới các section [keystone_authtoken] và [paste_deploy] chỉnh sửa lại như sau:
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = Welcome123     

[paste_deploy]
flavor = keystone
Chú ý comment lại tất cả các dòng cấu hình khác của section [keystone_authtoken].

Tìm tới section [glance_store], chỉnh sửa lại như sau:
[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
Chỉnh sửa file /etc/glance/glance-registry.conf theo các bước sau:

Tìm tới section [database] sửa lại như sau:
connection = mysql+pymysql://glance:Welcome123@controller/glance
Tìm tới các section [keystone_authtoken] và [paste_deploy] chỉnh sửa lại như sau:
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = Welcome123     

[paste_deploy]
flavor = keystone
Chú ý comment lại tất cả các dòng cấu hình khác của section [keystone_authtoken].

Đồng bộ cấu hình của glance vào database:

su -s /bin/sh -c "glance-manage db_sync" glance
Khởi động lại các dịch vụ cần thiết:
service glance-registry restart
service glance-api restart

root@controller: openstack image list
+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| c899c31c-e83e-428d-b855-738d0617e1f0 | cirros | active |
+--------------------------------------+--------+--------+

Kiểm tra phiên bản mới của glance
root@controller:/etc/glance# dpkg -l | grep glance
ii  glance                              2:13.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Daemons
ii  glance-api                          2:13.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - API
ii  glance-common                       2:13.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Common
ii  glance-registry                     2:13.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Registry
ii  glance-store-common                 0.13.0-3ubuntu0.16.04.1                    all          OpenStack Image Service store library - common files
ii  python-glance                       2:13.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Python library
ii  python-glance-store                 0.13.0-3ubuntu0.16.04.1                    all          OpenStack Image Service store library - Python 2.7
ii  python-glanceclient                 1:2.0.0-2ubuntu0.16.04.1                   all          Client library for Openstack glance server - Python 2.x


Upgrade Nova
backup cấu hình
cp -rp /etc/nova /root/backup_mitaka/
mysqldump -u root -p --databases nova > /root/backup_mitaka/nova.sqlbak

Tạo database nova_api:
Truy cập database client:
mysql -u root -pWelcome123
Tạo 2 database nova_api và nova:
CREATE DATABASE nova_api;


GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';

EXIT;

Stop service
service nova-api stop
service nova-novncproxy stop
service nova-cert stop
service nova-consoleauth stop
service nova-scheduler stop
service nova-conductor stop

apt-get install --only-upgrade nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler

Lưu lại cấu hình gốc của nova:
cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
cat /etc/nova/nova.conf.orig | egrep -v '^#|^$' > /etc/nova/nova.conf
Chỉnh sửa file /etc/nova/nova.conf theo các bước sau:

Trong section [DEFAULT], tìm tới những dòng sau và sửa lại như bên dưới:
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:Welcome123@controller
auth_strategy = keystone
my_ip = 10.20.0.196
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
Chú ý: xóa dòng cấu hình tùy chọn log-dir trong section [DEFAULT] để tránh gây lỗi.

Trong các section [api_database] và [database] chỉnh sửa lại như sau:
[api_database]
connection = mysql+pymysql://nova:Welcome123@controller/nova_api   

[database]
connection = mysql+pymysql://nova:Welcome123@controller/nova
Trong section [keystone_authtoken] chỉnh sửa lại như sau:
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Welcome123
Tìm tới section [vnc] và chỉnh sửa lại như sau:
[vnc]
vncserver_listen = $my_ip
vncserver_proxyclient_address = $my_ip
Tìm tới section [glance] và chỉnh sửa lại như sau:
[glance]
api_servers = http://controller:9292
Tìm tới section [oslo_concurrency] và chỉnh sửa lại như sau:
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
Thêm section [neutron] với nội dung như sau:
[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123
service_metadata_proxy = True
metadata_proxy_shared_secret = Welcome123
Cập nhật cấu hình vào database:

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
Kết thúc cài đặt Nova
Khởi động lại các dịch vụ cần thiết:
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

Kiểm tra các dịch vụ của nova:
source admin-openrc
openstack compute service list
+----+------------------+------------+----------+---------+-------+----------------------------+
| Id | Binary           | Host       | Zone     | Status  | State | Updated At                 |
+----+------------------+------------+----------+---------+-------+----------------------------+
|  5 | nova-cert        | controller | internal | enabled | up    | 2017-12-18T18:40:54.000000 |
|  6 | nova-consoleauth | controller | internal | enabled | up    | 2017-12-18T18:40:55.000000 |
|  7 | nova-scheduler   | controller | internal | enabled | up    | 2017-12-18T18:40:57.000000 |
|  8 | nova-conductor   | controller | internal | enabled | up    | 2017-12-18T18:40:57.000000 |
|  9 | nova-compute     | compute1   | nova     | enabled | down  | 2017-12-18T17:31:27.000000 |
+----+------------------+------------+----------+---------+-------+----------------------------+

dpkg -l | grep nova
ii  nova-api                            2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - API frontend
ii  nova-cert                           2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - certificate management
ii  nova-common                         2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - common files
ii  nova-conductor                      2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - conductor service
ii  nova-consoleauth                    2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - Console Authenticator
ii  nova-novncproxy                     2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - NoVNC proxy
ii  nova-scheduler                      2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - virtual machine scheduler
ii  python-nova                         2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute Python libraries
ii  python-novaclient                   2:3.3.1-2ubuntu1                           all          client library for OpenStack Compute API - Python 2.7


## Upgrade Cinder
backup cấu hình
cp -rp /etc/cinder /root/backup_mitaka/
mysqldump -u root -p --databases cinder> /root/backup_mitaka/cinder.sqlbak

apt install --only-upgrade cinder-api cinder-scheduler cinder-volume -y

Lưu lại cấu hình gốc của nova:
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.orig
cat /etc/cinder/cinder.conf.orig | egrep -v '^#|^$' > /etc/cinder/cinder.conf
Chỉnh sửa file /etc/cinder/cinder.conf theo các bước sau:

[database]
...
connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
transport_url = rabbit://openstack:RABBIT_PASS@controller

[DEFAULT]
...
auth_strategy = keystone
my_ip = 10.0.0.11
enabled_backends = lvm
glance_api_servers = http://controller:9292

[keystone_authtoken]
...
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = cinder
password = CINDER_PASS

[oslo_concurrency]
...
lock_path = /var/lib/cinder/tmp

[lvm]
...
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = tgtadm

su -s /bin/sh -c "cinder-manage db sync" cinder

service cinder-scheduler restart
service cinder-api restart
service tgt restart
service cinder-volume restart

root@controller:~# cinder list
+----+--------+------+------+-------------+----------+-------------+
| ID | Status | Name | Size | Volume Type | Bootable | Attached to |
+----+--------+------+------+-------------+----------+-------------+
+----+--------+------+------+-------------+----------+-------------+
root@controller:~# dpkg -l | grep cinder
ii  cinder-api                          2:9.1.4-0ubuntu1~cloud0                    all          Cinder storage service - API server
ii  cinder-common                       2:9.1.4-0ubuntu1~cloud0                    all          Cinder storage service - common files
ii  cinder-scheduler                    2:9.1.4-0ubuntu1~cloud0                    all          Cinder storage service - Scheduler server
ii  cinder-volume                       2:9.1.4-0ubuntu1~cloud0                    all          Cinder storage service - Volume server
ii  python-cinder                       2:9.1.4-0ubuntu1~cloud0                    all          Cinder Python libraries
ii  python-cinderclient                 1:1.6.0-2ubuntu1                           all          Python bindings to the OpenStack Volume API - Python 2.x



## Upgrade Neutron
backup cấu hình
cp -rp /etc/neutron /root/backup_mitaka/
mysqldump -u root -p --databases neutron> /root/backup_mitaka/neutron.sqlbak

apt-get install --only-upgrade neutron-server neutron-plugin-ml2 \
neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
neutron-metadata-agent


Cấu hình neutron server:
Lưu lại cấu hình gốc:
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cat /etc/neutron/neutron.conf.orig | egrep -v '^#|^$' > /etc/neutron/neutron.conf
Chỉnh sửa file /etc/neutron/neutron.conf theo các bước sau:

Trong section [database] chỉnh sửa lại như sau:
[database]
connection = mysql+pymysql://neutron:Welcome123@controller/neutron
Trong section [DEFAULT], tìm đến các tùy chọn sau và chỉnh sửa lại như dưới:
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
Trong section [oslo_messaging_rabbit], chỉnh sửa lại như bên dưới:
[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = Welcome123
Trong section [keystone_authtoken], chỉnh sửa lại như bên dưới:
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = Welcome123
Chú ý: comment hoặc xóa bỏ mọi tùy chọn khác trong section [keystone_authtoken] nếu có.

Trong section [nova], chỉnh sửa lại như sau:
[nova]
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = Welcome123
Cấu hình Modular Layer 2 plugin:

Lưu lại cấu hình gốc:

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig
cat /etc/neutron/plugins/ml2/ml2_conf.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/ml2_conf.ini
Chỉnh sửa file /etc/neutron/plugins/ml2/ml2_conf.ini theo các bước sau:

Trong section [ml2], chỉnh sửa lại các tùy chọn như sau:
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security
Trong section [ml2_type_flat], chỉnh sửa lại như sau:
[ml2_type_flat]
flat_networks = provider
Trong section [ml2_type_vxlan], chỉnh sửa lại như sau:
[ml2_type_vxlan]
vni_ranges = 1:1000
Trong section [securitygroup], chỉnh sửa lại như sau:
[securitygroup]
enable_ipset = True
Cấu hình Open vSwitch agent:

Lưu lại cấu hình gốc:

cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig
cat /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/openvswitch_agent.ini
Chỉnh sửa lại file /etc/neutron/plugins/ml2/openvswitch_agent.ini theo các bước sau:

Tìm tới section [agent], chỉnh sửa lại như sau:
[agent]
tunnel_types = vxlan
l2_population = True
Tìm tới section [ovs], chỉnh sửa lại như sau:
[ovs]
local_ip = 10.10.20.196
bridge_mappings = provider:br-ex
Chú ý giá trị tùy chọn local_ip đặt bằng địa chỉ IP của card thuộc dải DATA NETWORK.

Tìm tới section [securitygroup], chỉnh sửa lại như sau:
[securitygroup]
firewall_driver = iptables_hybrid

Nếu dung linuxbridge
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
cat /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[linux_bridge]
physical_interface_mappings = provider:eth1

In the [vxlan] section, disable VXLAN overlay networks:

[vxlan]
enable_vxlan = True
local_ip = 172.16.68.70
l2_population = True

In the [securitygroup] section, enable security groups and configure the Linux bridge iptables firewall driver:

[securitygroup]
...
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


Cấu hình l3 agent:

Lưu lại cấu hình gốc:

cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.orig
cat /etc/neutron/l3_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/l3_agent.ini
Chỉnh sửa file /etc/neutron/l3_agent.ini. Trong section [DEFAULT], chỉnh sửa lại như sau:
[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDrive
external_network_bridge =


Cấu hình DHCP agent:
Lưu lại cấu hình gốc:
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig
cat /etc/neutron/dhcp_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/dhcp_agent.ini
Chỉnh sửa file /etc/neutron/dhcp_agent.ini. Trong section [DEFAULT], chỉnh sửa lại như sau:
[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
dnsmasq_config_file = /etc/neutron/dnsmasq-neutron.conf

Cấu hình Metadata agent:
Lưu lại cấu hình gốc của metadata agent:
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig
cat /etc/neutron/metadata_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/metadata_agent.ini
Chỉnh sửa file /etc/neutron/metadata_agent.ini, trong section [DEFAULT] tìm tới những dòng sau và chỉnh sửa lại như bên dưới:
[DEFAULT]
nova_metadata_ip = controller
metadata_proxy_shared_secret = Welcome123

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

root@controller:/etc/neutron/plugins/ml2# dpkg -l | grep neutron
ii  neutron-common                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - common
ii  neutron-dhcp-agent                  2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - DHCP agent
ii  neutron-l3-agent                    2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - l3 agent
ii  neutron-linuxbridge-agent           2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - linuxbridge agent
ii  neutron-metadata-agent              2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - metadata agent
ii  neutron-plugin-ml2                  2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - ML2 plugin
ii  neutron-server                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - server
ii  python-neutron                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - Python library
ii  python-neutron-fwaas                1:9.0.2-0ubuntu1~cloud0                    all          Firewall-as-a-Service driver for OpenStack Neutron
ii  python-neutron-lib                  0.4.0-0ubuntu1~cloud0                      all          Neutron shared routines and utilities - Python 2.7
ii  python-neutronclient                1:6.0.0-0ubuntu1~cloud1                    all          client API library for Neutron - Python 2.7


root@controller:/etc/neutron/plugins/ml2# neutron agent-list
+--------------------------------------+--------------------+------------+-------------------+-------+----------------+---------------------------+
| id                                   | agent_type         | host       | availability_zone | alive | admin_state_up | binary                    |
+--------------------------------------+--------------------+------------+-------------------+-------+----------------+---------------------------+
| 333a4e9a-f430-45d1-b031-69d8cb7d6f96 | Linux bridge agent | controller |                   | :-)   | True           | neutron-linuxbridge-agent |
| 4c6328a1-d1d1-44c4-a771-985dd6a9b872 | Metadata agent     | controller |                   | :-)   | True           | neutron-metadata-agent    |
| a57f7d00-89ec-4ab9-b9dc-fb1fe55d35aa | L3 agent           | controller | nova              | :-)   | True           | neutron-l3-agent          |
| a6af07c7-b10b-43de-bb3c-00d2c5f39aca | DHCP agent         | controller | nova              | :-)   | True           | neutron-dhcp-agent        |
| f6cfaa30-e63a-4c5e-8447-f0a6951687c5 | Linux bridge agent | compute1   |                   | :-)   | True           | neutron-linuxbridge-agent |
+--------------------------------------+--------------------+------------+-------------------+-------+----------------+---------------------------+


## Horizon
cp -rp /etc/openstack-dashboard/ /root/backup_mitaka/
apt-get install --only-upgrade openstack-dashboard

Chỉnh sửa lại file /etc/openstack-dashboard/local_settings.py theo các bước sau:
Cấu hình dashboard sử dụng các OpenStack services trên máy controller:
OPENSTACK_HOST = "controller"
Cho phép mọi host truy cập dashboard:
ALLOWED_HOSTS = ['*', ]
Cấu hình memcached:
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
Kích hoạt Identity API version 3:
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
Kích hoạt hỗ trợ cho nhiều domains:
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
Chú ý: bước này có thể bỏ qua.
Cấu hình API version:
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
Cấu hình domain mặc định là default:
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"
Cấu hình user là role mặc định cho các user truy cập qua dashboard:
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
Chỉnh sửa lại timezone:
TIME_ZONE = "Asia/Ho_Chi_Minh"
Chú ý kiểm tra timezone trên host cho đúng với cấu hình (thực hiện các lệnh sau trên command line):
timedatectl
# Kết quả tương tự như sau
      Local time: Tue 2016-10-25 11:07:21 ICT
  Universal time: Tue 2016-10-25 04:07:21 UTC
        RTC time: Tue 2016-10-25 04:07:21
       Time zone: Asia/Ho_Chi_Minh (ICT, +0700)
 Network time on: yes
NTP synchronized: yes
 RTC in local TZ: no
Nếu timezone không khớp với giá trị Asia/Ho_Chi_Minh thì thiết lập lại như sau:
timedatectl set-timezone Asia/Ho_Chi_Minh
Kết thúc quá trình cài đặt
Khởi động lại web server apache:
service apache2 reload

Mở trình duyệt, truy cập địa chỉ: http://controller/horizon. Đăng nhập với domain là default, tài khoản admin hoặc demo, password là Welcome123.

## Hostcompute
add-apt-repository cloud-archive:newton
apt-get update

apt-get install --only-upgrade nova-compute
cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
cat /etc/nova/nova.conf.orig | egrep -v '^#|^$' > /etc/nova/nova.conf

Chỉnh sửa lại file /etc/nova/nova.conf theo các bước sau:

Sửa trong section [DEFAULT] các tùy chọn như sau:
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:Welcome123@controller
auth_strategy = keystone
my_ip = 10.20.0.197
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
Sửa trong section [keystone_authtoken] các tùy chọn như sau:
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Welcome123
Chú ý comment lại toàn bộ các dòng cấu hình khác trong sectiion [keystone_authtoken] nếu có.

Sửa trong section [vnc] các tùy chọn như sau:
[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html
Sửa hoặc thêm section [glance] với nội dung như sau:
[glance]
api_servers = http://controller:9292
Sửa hoặc thêm section [oslo_concurrency] với nội dung như sau:
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
Thêm section [neutron]:
[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123
Xóa bỏ tùy chọn log-dir trong section [DEFAULT] để tránh gây lỗi.

service nova-compute restart

root@compute1:/etc/init# dpkg -l | grep nova
ii  nova-common                         2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - common files
ii  nova-compute                        2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - compute node base
ii  nova-compute-kvm                    2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - compute node (KVM)
ii  nova-compute-libvirt                2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute - compute node libvirt support
ii  python-nova                         2:14.0.10-0ubuntu1~cloud0                  all          OpenStack Compute Python libraries
ii  python-novaclient                   2:3.3.1-2ubuntu1                           all          client library for OpenStack Compute API - Python 2.7


## Neutron

cp /etc/neutron/neutron.conf /root/backup_mitaka
apt install --only-upgrade neutron-linuxbridge-agent

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cat /etc/neutron/neutron.conf.orig | egrep -v '^#|^$' > /etc/neutron/neutron.conf

[DEFAULT]
...
transport_url = rabbit://openstack:RABBIT_PASS@controller
Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.

In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:

[DEFAULT]
...
auth_strategy = keystone

[keystone_authtoken]
...
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = NEUTRON_PASS

[neutron]
...
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS

cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
cat /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/linuxbridge_agent.ini

[linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

[vxlan]
enable_vxlan = True
local_ip = 172.16.68.73
l2_population = True


[securitygroup]
...
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

service neutron-linuxbridge-agent restart
service nova-compute restart

root@compute1:/etc/init# dpkg -l | grep neutron
ii  neutron-common                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - common
ii  neutron-linuxbridge-agent           2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - linuxbridge agent
ii  python-neutron                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - Python library
ii  python-neutron-fwaas                1:9.0.2-0ubuntu1~cloud0                    all          Firewall-as-a-Service driver for OpenStack Neutron
ii  python-neutron-lib                  0.4.0-0ubuntu1~cloud0                      all          Neutron shared routines and utilities - Python 2.7
ii  python-neutronclient                1:6.0.0-0ubuntu1~cloud1                    all          client API library for Neutron - Python 2.7



https://lists.gt.net/openstack/operators/59035?page=last
https://docs.openstack.org/nova/latest/user/upgrade.html#	
https://www.hellovinoth.com/upgrading-openstack-lets-give-it-a-try/
https://releases.openstack.org/newton/#newton-nova
https://github.com/congto/OpenStack-Newton-Scripts/tree/master/DOCs-OPS-Newton