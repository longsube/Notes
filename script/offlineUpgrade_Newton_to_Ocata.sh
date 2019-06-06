Khai báo repo cho Ocata
apt-get install software-properties-common -y
add-apt-repository cloud-archive:ocata -y

apt-get update

Upgrade Keystone
backup cấu hình
mkdir /root/backup_newton/
cp -rp /etc/keystone/ /root/backup_newton/keystone

Để tránh lỗi Name duplicates previous WSGI daemon definition của apache khi có 2 tiến trình wsgi chung 1 name, gớ bổ cấu hình wsgi của newton
cp /etc/apache2/sites-available/keystone.conf /root/backup_newton
rm /etc/apache2/sites-enabled/keystone.conf

Lưu lại các file cấu hình gốc của keystone:
cp /etc/keystone/keystone.conf /root/backup_newton/keystone.conf.orig

Stop service
service apache2 stop
apt-get -o Dpkg::Options::="--force-confold"  install --only-upgrade keystone -y
apt-get -o Dpkg::Options::="--force-confold"  install --only-upgrade python-keystonemiddleware -y
apt-get install python-oslo.middleware -y




Mở file cấu hình keystone: vim /etc/keystone/keystone.conf
Tìm tới section [database] và chỉnh sửa như sau:

[database]
connection = mysql+pymysql://keystone:Welcome123@172.16.68.70/keystone

Tìm tới section [token] và chỉnh sửa như sau:
[token]
provider = fernet

Cập nhật cấu vào trong database keystone:
keystone-manage db_sync --expand
keystone-manage db_sync --migrate

Dùng vi để mở và sửa file /etc/apache2/apache2.conf. Thêm dòng dưới ngay sau dòng # Global configuration
# Global configuration
ServerName 172.16.68.70

service apache2 start

Kiểm tra phiên bản mới của keystone:
root@controller:~# dpkg -l | grep keystone
ii  keystone                            2:11.0.3-0ubuntu1~cloud0                   all          OpenStack identity service - Daemons
ii  python-keystone                     2:11.0.3-0ubuntu1~cloud0                   all          OpenStack identity service - Python library
ii  python-keystoneauth1                2.18.0-0ubuntu2~cloud0                     all          authentication library for OpenStack Identity - Python 2.7
ii  python-keystoneclient               1:3.10.0-0ubuntu1~cloud0                   all          client library for the OpenStack Keystone API - Python 2.x
ii  python-keystonemiddleware           4.14.0-0ubuntu1.2~cloud0                   all          Middleware for OpenStack Identity (Keystone) - Python 2.x


Kiểm tra hoạt động của keystone
root@controller:~# openstack endpoint list
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                                         |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------------+
| 444ff98b5018435aa2338b50c14c4df2 | RegionOne | nova         | compute      | True    | public    | http://172.16.68.70:8774/v2.1/%(tenant_id)s |
| 449664ded76640b68d31affc87766004 | RegionOne | cinder       | volume       | True    | admin     | http://172.16.6870:8776/v1/%(tenant_id)s    |
| 4a1edfb7dc014a4499a795b1c23b859b | RegionOne | nova         | compute      | True    | admin     | http://172.16.68.70:8774/v2.1/%(tenant_id)s |
| 61f68b3f5c73493cb3e59b5193b55b2d | RegionOne | cinderv2     | volumev2     | True    | admin     | http://172.16.68.70:8776/v2/%(tenant_id)s   |
| 6decd051189c4898ac989ed30850bcbc | RegionOne | glance       | image        | True    | admin     | http://172.16.68.70:9292                    |
| 7d524a7d889045459a9216f471df4b1e | RegionOne | keystone     | identity     | True    | internal  | http://172.16.68.70:5000/v3                 |
| 86ff9c6411ec40f08104f75658692347 | RegionOne | cinder       | volume       | True    | internal  | http://172.16.68.70:8776/v1/%(tenant_id)s   |
| 8e971506fffd44a2a677ee7439174bdb | RegionOne | keystone     | identity     | True    | public    | http://172.16.68.70:5000/v3                 |
| 9f0ee80063794f119c9b3c936db2d83e | RegionOne | cinder       | volume       | True    | public    | http://172.16.68.70:8776/v1/%(tenant_id)s   |
| 9f1289b8e2284ed9afc5a11340509626 | RegionOne | keystone     | identity     | True    | admin     | http://172.16.68.70:35357/v3                |
| a245941dc23940f2bdedfc6014a99f57 | RegionOne | neutron      | network      | True    | public    | http://172.16.68.70:9696                    |
| ab8306e016284d0596a0946c27d0f278 | RegionOne | cinderv2     | volumev2     | True    | internal  | http://172.16.68.70:8776/v2/%(tenant_id)s   |
| af39564c34d74eaa8483facde9c92329 | RegionOne | glance       | image        | True    | public    | http://172.16.68.70:9292                    |
| b85dee7e62e3410094bad2eabe06a4d5 | RegionOne | glance       | image        | True    | internal  | http://172.16.68.70:9292                    |
| dc5518c4b4694ca3a8edc5a52a5586bb | RegionOne | neutron      | network      | True    | admin     | http://172.16.68.70:9696                    |
| e4dac0e9043d45f29da58853feb4710f | RegionOne | cinderv2     | volumev2     | True    | public    | http://172.16.68.70:8776/v2/%(tenant_id)s   |
| e5fdcf697af04b39b103b1b33247ee0b | RegionOne | neutron      | network      | True    | internal  | http://172.16.68.70:9696                    |
| fa08e0ce1b2f43ee9db13e18498853b4 | RegionOne | nova         | compute      | True    | internal  | http://172.16.68.70:8774/v2.1/%(tenant_id)s |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------------+


Upgrade Glance
backup cấu hình
cp -rp /etc/glance /root/backup_newton/glance

mysqldump -u root -p --databases glance > /root/backup_newton/glance/glance.sqlbak
Stop service
service glance-api stop
service glance-registry stop
apt-get -o Dpkg::Options::="--force-confold"  install --only-upgrade glance python-glanceclient -y

Chỉnh sửa file /etc/glance/glance-api.conf theo các bước sau:
Tìm tới section [database] sửa lại như sau:
connection = mysql+pymysql://glance:Welcome123@controller/glance

Tìm tới các section [keystone_authtoken] và [paste_deploy] chỉnh sửa lại như sau:
[keystone_authtoken]
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
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
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = Welcome123     

[paste_deploy]
flavor = keystone

Đồng bộ cấu hình của glance vào database:
glance-manage db expand
glance-manage db migrate


Khởi động lại các dịch vụ cần thiết:
service glance-registry restart
service glance-api restart

openstack image list

Kiểm tra phiên bản mới của glance
root@controller:/etc/glance# dpkg -l | grep glance
ii  glance                              2:14.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Daemons
ii  glance-api                          2:14.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - API
ii  glance-common                       2:14.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Common
ii  glance-registry                     2:14.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Registry
ii  glance-store-common                 0.13.0-3ubuntu0.16.04.1                    all          OpenStack Image Service store library - common files
ii  python-glance                       2:14.0.0-0ubuntu1~cloud0                   all          OpenStack Image Registry and Delivery Service - Python library
ii  python-glance-store                 0.13.0-3ubuntu0.16.04.1                    all          OpenStack Image Service store library - Python 2.7
ii  python-glanceclient                 1:2.5.0-0ubuntu1~cloud0                    all          Client library for Openstack glance server - Python 2.x


Upgrade Nova
backup cấu hình
cp -rp /etc/nova /root/backup_newton/nova
mysqldump -u root -p --databases nova > /root/backup_newton/nova/nova.sqlbak

Tạo database nova_api:
Truy cập database client:

mysql -u root -pWelcome123
Tạo database nova_cell0:
CREATE DATABASE nova_cell0;


GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';

EXIT;

Tạo user placement
openstack user create --domain default --password Welcome123 placement

Thêm role admin cho user placement trên project service:
openstack role add --project service --user placement admin

Tạo dịch vụ placement:
openstack service create --name placement --description "Placement API" placement

Tạo endpoint cho placement
openstack endpoint create --region RegionOne placement public http://172.16.68.70:8778
openstack endpoint create --region RegionOne placement internal http://172.16.68.70:8778
openstack endpoint create --region RegionOne placement admin http://172.16.68.70:8778

Stop service
service nova-api stop
service nova-novncproxy stop
service nova-cert stop
service nova-consoleauth stop
service nova-scheduler stop
service nova-conductor stop

apt-get -o Dpkg::Options::="--force-confold"  install --only-upgrade nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-cert -y
apt-get install nova-placement-api python-novaclient -y
pip install --upgrade oslo.middleware




Chỉnh sửa file /etc/nova/nova.conf theo các bước sau:

Trong section [DEFAULT], tìm tới những dòng sau và sửa lại như bên dưới:
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:Welcome123@172.16.68.70
my_ip = 172.16.68.70
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[api]
auth_strategy = keystone

Chú ý: xóa dòng cấu hình tùy chọn log-dir trong section [DEFAULT] để tránh gây lỗi.

Trong các section [api_database] và [database] chỉnh sửa lại như sau:
[api_database]
connection = mysql+pymysql://nova:Welcome123@172.16.68.70/nova_api   

[database]
connection = mysql+pymysql://nova:Welcome123@controller/nova
Trong section [keystone_authtoken] chỉnh sửa lại như sau:
[keystone_authtoken]
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Welcome123



Tìm tới section [vnc] và chỉnh sửa lại như sau:
[vnc]
enabled = true
vncserver_listen = $my_ip
vncserver_proxyclient_address = $my_ip

Tìm tới section [glance] và chỉnh sửa lại như sau:
[glance]
api_servers = http://172.16.68.70:9292

Tìm tới section [oslo_concurrency] và chỉnh sửa lại như sau:
[oslo_concurrency]
lock_path = /var/lib/nova/tmp

Thêm section [neutron] với nội dung như sau:
[neutron]
url = http://172.16.68.709696
auth_url = http://172.16.68.70:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123
service_metadata_proxy = True
metadata_proxy_shared_secret = Welcome123

Trong [placement], cấu hình Placement API:
[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:35357/v3
username = placement
password = Welcome123

Cập nhật cấu hình vào database:
nova-manage db online_data_migrations
su -s /bin/sh -c "nova-manage db sync" nova
nova-manage cell_v2 simple_cell_setup
su -s /bin/sh -c "nova-manage api_db sync" nova


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

nova-manage cell_v2 list_cells
 +-------+--------------------------------------+
 |  Name |                 UUID                 |
 +-------+--------------------------------------+
 | cell0 | 00000000-0000-0000-0000-000000000000 |
 | cell1 | 3ca28930-9d49-4a26-867e-88f7285d3b0e |
 +-------+--------------------------------------+

dpkg -l | grep nova
ii  nova-api                            2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - API frontend
ii  nova-cert                           2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - certificate management
ii  nova-common                         2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - common files
ii  nova-conductor                      2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - conductor service
ii  nova-consoleauth                    2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - Console Authenticator
ii  nova-novncproxy                     2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - NoVNC proxy
ii  nova-placement-api                  2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - placement API frontend
ii  nova-scheduler                      2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - virtual machine scheduler
ii  python-nova                         2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute Python libraries
ii  python-novaclient                   2:7.1.0-0ubuntu1~cloud0                           all          client library for OpenStack Compute API - Python 2.7


## Upgrade Cinder
backup cấu hình
cp -rp /etc/cinder /root/backup_newton/cinder
mysqldump -u root -p --databases cinder> /root/backup_newton/cinder/cinder.sqlbak

apt -o Dpkg::Options::="--force-confold" install --only-upgrade cinder-api cinder-scheduler cinder-volume python-cinderclient -y

Lưu lại cấu hình gốc của cinder:


Chỉnh sửa file /etc/cinder/cinder.conf theo các bước sau:
[database]
connection = mysql+pymysql://cinder:Welcome123@172.16.68.70/cinder
transport_url = rabbit://openstack:Welcome123@172.16.68.70

[DEFAULT]
auth_strategy = keystone
my_ip = 172.16.68.70
enabled_backends = lvm
glance_api_servers = http://172.16.68.70:9292

[keystone_authtoken]
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = cinder
password = Welcome123

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

[lvm]
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
ii  cinder-api                          2:10.0.6-0ubuntu1~cloud0                   all          Cinder storage service - API server
ii  cinder-common                       2:10.0.6-0ubuntu1~cloud0                   all          Cinder storage service - common files
ii  cinder-scheduler                    2:10.0.6-0ubuntu1~cloud0                   all          Cinder storage service - Scheduler server
ii  cinder-volume                       2:10.0.6-0ubuntu1~cloud0                   all          Cinder storage service - Volume server
ii  python-cinder                       2:10.0.6-0ubuntu1~cloud0                   all          Cinder Python libraries
ii  python-cinderclient                 1:1.6.0-2ubuntu1                           all          Python bindings to the OpenStack Volume API - Python 2.x


## Upgrade Neutron
backup cấu hình
cp -rp /etc/neutron /root/backup_newton/neutron
mysqldump -u root -p --databases neutron> /root/backup_newton/neutron/neutron.sqlbak

apt-get -o Dpkg::Options::="--force-confold" install --only-upgrade neutron-server neutron-plugin-ml2  neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent python-neutronclient -y


Cấu hình neutron server:
Lưu lại cấu hình gốc:
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cat /etc/neutron/neutron.conf.orig | egrep -v '^#|^$' > /etc/neutron/neutron.conf

Chỉnh sửa file /etc/neutron/neutron.conf theo các bước sau:
Trong section [database] chỉnh sửa lại như sau:

[database]
connection = mysql+pymysql://neutron:Welcome123@172.16.68.70/neutron

Trong section [DEFAULT], tìm đến các tùy chọn sau và chỉnh sửa lại như dưới:
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
transport_url = rabbit://openstack:Welcome123@172.16.68.70
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

Trong section [keystone_authtoken], chỉnh sửa lại như bên dưới:
[keystone_authtoken]
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = Welcome123

Chú ý: comment hoặc xóa bỏ mọi tùy chọn khác trong section [keystone_authtoken] nếu có.

Trong section [nova], chỉnh sửa lại như sau:
[nova]
auth_url = http://172.16.68.70:35357
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
mechanism_drivers = linuxbridge,l2population
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

Cấu hình LinuxBridge agent:

Lưu lại cấu hình gốc:
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
cat /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/linuxbridge_agent.ini

Chỉnh sửa lại file /etc/neutron/plugins/ml2/linuxbridge_agent.ini theo các bước sau:
Tìm tới section [vxlan], chỉnh sửa lại như sau:
[vxlan]
enable_vxlan = true
local_ip = 10.10.10.190
l2_population = true

Tìm tới section [linux_bridge], chỉnh sửa lại như sau:
[linux_bridge]
local_ip = 172.16.68.70
physical_interface_mappings = provider:eth1
Chú ý giá trị tùy chọn local_ip đặt bằng địa chỉ IP của card thuộc dải DATA NETWORK.

Tìm tới section [securitygroup], chỉnh sửa lại như sau:
[securitygroup]
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

Cấu hình l3 agent:

Lưu lại cấu hình gốc:
cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.orig
cat /etc/neutron/l3_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/l3_agent.ini

Chỉnh sửa file /etc/neutron/l3_agent.ini. Trong section [DEFAULT], chỉnh sửa lại như sau:
[DEFAULT]
interface_driver = linuxbridge


Cấu hình DHCP agent:
Lưu lại cấu hình gốc:
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig
cat /etc/neutron/dhcp_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/dhcp_agent.ini

Chỉnh sửa file /etc/neutron/dhcp_agent.ini. Trong section [DEFAULT], chỉnh sửa lại như sau:
[DEFAULT]
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true

Cấu hình Metadata agent:
Lưu lại cấu hình gốc của metadata agent:
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig
cat /etc/neutron/metadata_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/metadata_agent.ini

Chỉnh sửa file /etc/neutron/metadata_agent.ini, trong section [DEFAULT] tìm tới những dòng sau và chỉnh sửa lại như bên dưới:
[DEFAULT]
nova_metadata_ip = 172.16.68.70
metadata_proxy_shared_secret = Welcome123

Sửa trong file /etc/nova/nova.conf

Trong section [neutron] khai báo mới hoặc sửa thành dòng dưới:
url = http://172.16.68.70:9696
auth_url = http://172.16.68.70:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123
service_metadata_proxy = true
metadata_proxy_shared_secret = Welcome123

neutron-db-manage upgrade --expand

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

root@controller:/etc/neutron/plugins/ml2# dpkg -l | grep neutron
ii  neutron-common                      2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - common
ii  neutron-dhcp-agent                  2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - DHCP agent
ii  neutron-l3-agent                    2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - l3 agent
ii  neutron-linuxbridge-agent           2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - linuxbridge agent
ii  neutron-metadata-agent              2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - metadata agent
ii  neutron-plugin-ml2                  2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - ML2 plugin
ii  neutron-server                      2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - server
ii  python-neutron                      2:10.0.4-0ubuntu2~cloud0                   all          Neutron is a virtual network service for Openstack - Python library
ii  python-neutron-fwaas                1:9.0.2-0ubuntu1~cloud0                    all          Firewall-as-a-Service driver for OpenStack Neutron
ii  python-neutron-lib                  1.1.0-0ubuntu1~cloud0                      all          Neutron shared routines and utilities - Python 2.7
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
cp -rp /etc/openstack-dashboard/ /root/backup_newton/horizon
apt-get -o Dpkg::Options::="--force-confold" install --only-upgrade openstack-dashboard

Backup cấu hình
cp -rp /etc/openstack-dashboard /root/backup_mitaka

Chỉnh sửa lại file /etc/openstack-dashboard/local_settings.py theo các bước sau:

Cấu hình dashboard sử dụng các OpenStack services trên máy controller:
OPENSTACK_HOST = "172.16.68.70"
Cho phép mọi host truy cập dashboard:
ALLOWED_HOSTS = ['*', ]
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
Cấu hình memcached:
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': '172.16.68.70:11211',
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
    "compute": 2,
}

Cấu hình domain mặc định là default:
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"

Cấu hình user là role mặc định cho các user truy cập qua dashboard:
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

Chỉnh sửa lại timezone:
TIME_ZONE = "Asia/Ho_Chi_Minh"

chown www-data:www-data /var/lib/openstack-dashboard/secret_key

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

Mở trình duyệt, truy cập địa chỉ: http://172.16.68.70/horizon. Đăng nhập với domain là default, tài khoản admin hoặc demo, password là Welcome123.


Để sửa lỗi Unable to retrieve Domain, không thể load được danh sách Project và User lên Dashboard. Sửa file /usr/share/openstack-dashboard/openstack_dashboard/api/keystone.py
def _get_endpoint_url(request, endpoint_type, catalog=None):
    if getattr(request.user, "service_catalog", None):
        url = base.url_for(request,
                           service_type='identity',
                           endpoint_type=endpoint_type)
        message = ("The Keystone URL in service catalog points to a v2.0 "
                   "Keystone endpoint, but v3 is specified as the API version "
                   "to use by Horizon. Using v3 endpoint for authentication.")
    else:
        auth_url = getattr(settings, 'OPENSTACK_KEYSTONE_URL')
        url = request.session.get('region_endpoint', auth_url)
        message = ("The OPENSTACK_KEYSTONE_URL setting points to a v2.0 "
                   "Keystone endpoint, but v3 is specified as the API version "
                   "to use by Horizon. Using v3 endpoint for authentication.")

    # TODO(gabriel): When the Service Catalog no longer contains API versions
    # in the endpoints this can be removed.
    url = auth_utils.fix_auth_url_version(url)
    return url





## Hostcompute
add-apt-repository cloud-archive:ocata
Gỡ các repo của mitaka
cd /etc/apt/sources.list.d
mkdir /root/backup_newton
mv cloudarchive-mitaka.list cloudarchive-mitaka.list.distUpgrade  cloudarchive-mitaka.list.save /root/backup_newton/

cp -rp /etc/nova/ /root/backup_newton/nova

apt-get update

apt-get -o Dpkg::Options::="--force-confold" install --only-upgrade nova-compute -y
pip install --upgrade oslo.middleware

cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
cat /etc/nova/nova.conf.orig | egrep -v '^#|^$' > /etc/nova/nova.conf

Chỉnh sửa lại file /etc/nova/nova.conf theo các bước sau:
Sửa trong section [DEFAULT] các tùy chọn như sau:
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:Welcome123@172.16.68.70
auth_strategy = keystone
my_ip = 172.16.68.73
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver

Sửa trong section [keystone_authtoken] các tùy chọn như sau:
[keystone_authtoken]
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
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
novncproxy_base_url = http://172.16.68.70:6080/vnc_auto.html

Sửa hoặc thêm section [glance] với nội dung như sau:
[glance]
api_servers = http://172.16.68.70:9292

Sửa hoặc thêm section [oslo_concurrency] với nội dung như sau:
[oslo_concurrency]
lock_path = /var/lib/nova/tmp

Thêm section [neutron]:
[neutron]
url = http://172.16.68.70:9696
auth_url = http://172.16.68.70:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123

[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://172.16.68.70:35357/v3
username = placement
password = Welcome123


Xóa bỏ tùy chọn log-dir trong section [DEFAULT] để tránh gây lỗi.

service nova-compute restart

root@compute1:/etc/init# dpkg -l | grep nova
ii  nova-common                         2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - common files
ii  nova-compute                        2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - compute node base
ii  nova-compute-kvm                    2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - compute node (KVM)
ii  nova-compute-libvirt                2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute - compute node libvirt support
ii  python-nova                         2:15.0.8-0ubuntu1~cloud0                   all          OpenStack Compute Python libraries
ii  python-novaclient                   2:3.3.1-2ubuntu1                           all          client library for OpenStack Compute API - Python 2.7



## Neutron

cp -rp /etc/neutron/ /root/backup_newton/neutron
apt-get -o Dpkg::Options::="--force-confold" install --only-upgrade neutron-linuxbridge-agent

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cat /etc/neutron/neutron.conf.orig | egrep -v '^#|^$' > /etc/neutron/neutron.conf

[DEFAULT]
transport_url = rabbit://openstack:Welcome123@172.16.68.70

Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.
In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:

[DEFAULT]
auth_strategy = keystone

[keystone_authtoken]
auth_uri = http://172.16.68.70:5000
auth_url = http://172.16.68.70:35357
memcached_servers = 172.16.68.70:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = Welcome123

[neutron]
url = http://172.16.68.70:9696
auth_url = http://172.16.68.70:35357
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123

cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
cat /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/linuxbridge_agent.ini

[linux_bridge]
physical_interface_mappings = provider:eth1

[vxlan]
enable_vxlan = True
local_ip = 172.16.68.73
l2_population = True


[securitygroup]
enable_security_group = True 
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

Cấu hình dịch vụ compute sử dụng dịch vụ network
Sửa file /etc/nova/nova.conf
Trong [neutron] section:

url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123

service neutron-linuxbridge-agent restart
service nova-compute restart

root@compute1:/etc/init# dpkg -l | grep neutron
ii  neutron-common                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - common
ii  neutron-linuxbridge-agent           2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - linuxbridge agent
ii  python-neutron                      2:9.4.1-0ubuntu1~cloud0                    all          Neutron is a virtual network service for Openstack - Python library
ii  python-neutron-fwaas                1:9.0.2-0ubuntu1~cloud0                    all          Firewall-as-a-Service driver for OpenStack Neutron
ii  python-neutron-lib                  0.4.0-0ubuntu1~cloud0                      all          Neutron shared routines and utilities - Python 2.7
ii  python-neutronclient                1:6.0.0-0ubuntu1~cloud1                    all          client API library for Neutron - Python 2.7