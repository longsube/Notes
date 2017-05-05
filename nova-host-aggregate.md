# Hướng dẫn sử dụng Nova Host Aggregate để điều phối máy ảo
*Chú ý:*
 - Hướng dẫn sau thực hiện trên phiên bản OpenStack Mitaka

## 1. Giới thiệu về tính năng Host Aggregate
Tính năng này gom nhóm các node compute thành các nhóm logic. Host aggregate có metadata để đánh tag các nhóm compute node. VD, ta có thể nhóm các node với SSD disk thành một Host aggregate, và các node có NIC 10Gbps thành 1 Host aggregate.
Bài lab sau sẽ gom các compute node thành 2 Host aggreagate: mycloudvnn và smartcloud


## 2. Tạo các host aggregate 
```
root@controller1:~# nova aggregate-create mycloudvnn
root@controller1:~# nova aggregate-create smartcloud
```

Kết quả:

```
+----+------------+-------------------+-------+----------+
| Id | Name       | Availability Zone | Hosts | Metadata |
+----+------------+-------------------+-------+----------+
| 3  | mycloudvnn | -                 |       |          |
+----+------------+-------------------+-------+----------+

+----+------------+-------------------+-------+----------+
| Id | Name       | Availability Zone | Hosts | Metadata |
+----+------------+-------------------+-------+----------+
| 5  | smartcloud | -                 |       |          |
+----+------------+-------------------+-------+----------+
```

## 3. Thêm các compute node vào các Host aggregate, bài lab này chỉ có 2 node compute, do đó mỗi nhóm sẽ chỉ dùng 1 node compute
```
root@controller1:~# nova aggregate-add-host mycloudvnn compute1
root@controller1:~# nova aggregate-add-host smartcloud compute2
```

Kết quả:

```
+----+------------+-------------------+--------------------+-------------------+
| Id | Name       | Availability Zone | Hosts              | Metadata          |
+----+------------+-------------------+--------------------+-------------------+
| 3  | mycloudvnn | -                 | 'compute1'         |  	               |
+----+------------+-------------------+--------------------+-------------------+

+----+------------+-------------------+--------------------+-------------------+
| Id | Name       | Availability Zone | Hosts              | Metadata          |
+----+------------+-------------------+--------------------+-------------------+
| 5  | smartcloud | -                 | 'compute2'         |  	               |
+----+------------+-------------------+--------------------+-------------------+
```

## 4. Đặt các 'tag' metadata cho từng Host aggregate
```
root@controller1:~# nova aggregate-set-metadata mycloudvnn mycloudvnn=true
root@controller1:~# nova aggregate-set-metadata smartcloud smartcloud=true
```

Kết quả:

```
+----+------------+-------------------+--------------------+-------------------+
| Id | Name       | Availability Zone | Hosts              | Metadata          |
+----+------------+-------------------+--------------------+-------------------+
| 3  | mycloudvnn | -                 | 'compute1'         | 'mycloudvnn=true' |
+----+------------+-------------------+--------------------+-------------------+

+----+------------+-------------------+--------------------+-------------------+
| Id | Name       | Availability Zone | Hosts              | Metadata          |
+----+------------+-------------------+--------------------+-------------------+
| 5  | smartcloud | -                 | 'compute2'         | 'smartcloud=true' |
+----+------------+-------------------+--------------------+-------------------+
```

## 5. Thực hiện tạo các flavor tương ứng với từng Host aggregate

```
root@controller1:~# nova flavor-create --is-public true mycloudvnn.small 100 1024 10 1
root@controller1:~# nova flavor-create --is-public true smartcloud.small 101 1024 10 1
```

Kết quả:

```
+-----+------------------+-----------+------+-----------+------+-------+-------------+-----------+
| ID  | Name             | Memory_MB | Disk | Ephemeral | Swap | VCPUs | RXTX_Factor | Is_Public |
+-----+------------------+-----------+------+-----------+------+-------+-------------+-----------+
| 100 | mycloudvnn.small | 1024      | 10   | 0         |      | 1     | 1.0         | True      |
+-----+------------------+-----------+------+-----------+------+-------+-------------+-----------+

+-----+------------------+-----------+------+-----------+------+-------+-------------+-----------+
| ID  | Name             | Memory_MB | Disk | Ephemeral | Swap | VCPUs | RXTX_Factor | Is_Public |
+-----+------------------+-----------+------+-----------+------+-------+-------------+-----------+
| 101 | smartcloud.small | 1024      | 10   | 0         |      | 1     | 1.0         | True      |
+-----+------------------+-----------+------+-----------+------+-------+-------------+-----------+
```

## 6. Update metadata cho các flavor với các metadata đã gán cho từng Host aggregate trước đó

```
root@controller1:~# nova flavor-key mycloudvnn.small set mycloudvnn=true
root@controller1:~# nova flavor-key smartcloud.small set smartcloud=true
```
 
## 7. Kiểm tra lại thông tin của flavor

```
root@controller1:~# nova flavor-show mycloudvnn.small
root@controller1:~# nova flavor-show smartcloud.small
```

Kết quả:

```
+----------------------------+------------------------+
| Property                   | Value                  |
+----------------------------+------------------------+
| OS-FLV-DISABLED:disabled   | False                  |
| OS-FLV-EXT-DATA:ephemeral  | 0                      |
| disk                       | 10                     |
| extra_specs                | {"mycloudvnn": "true"} |
| id                         | 100                    |
| name                       | mycloudvnn.small       |
| os-flavor-access:is_public | True                   |
| ram                        | 1024                   |
| rxtx_factor                | 1.0                    |
| swap                       |                        |
| vcpus                      | 1                      |
+----------------------------+------------------------+


+----------------------------+------------------------+
| Property                   | Value                  |
+----------------------------+------------------------+
| OS-FLV-DISABLED:disabled   | False                  |
| OS-FLV-EXT-DATA:ephemeral  | 0                      |
| disk                       | 10                     |
| extra_specs                | {"smartcloud": "true"} |
| id                         | 101                    |
| name                       | smartcloud.small       |
| os-flavor-access:is_public | True                   |
| ram                        | 1024                   |
| rxtx_factor                | 1.0                    |
| swap                       |                        |
| vcpus                      | 1                      |
+----------------------------+------------------------+
```

## 8. Mặc định, nova scheduler không hỗ trợ filter trên `extre_specs` của flavor hay image. Do đó cần bổ sung các filter cho nova scheduler trên Controller node.

`root@controller1:~# vim /etc/nova/nova.conf`

```
scheduler_default_filters=AggregateInstanceExtraSpecsFilter,RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter
```

## 9. Khởi động lại nova-scheduler trên Controller node
```
root@controller1:~# service nova-scheduler restart
```

## 10. Tạo máy ảo dựa trên các flavor này
```
root@controller1:~# nova boot --flavor mycloudvnn.small --image cirros --nic net-id=f3fc4125-0b3e-4b78-bd26-055afff3bda6 cr-mycloudvnn
root@controller1:~# nova boot --flavor smartcloud.small --image cirros --nic net-id=f3fc4125-0b3e-4b78-bd26-055afff3bda6 cr-smartcloud
```

## 11. Kiểm tra lại host chứa máy ảo
```
nova show cr-mycloudvnn
```

Kết quả:

```
+--------------------------------------+----------------------------------------------------------+
| Property                             | Value                                                    |
+--------------------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig                    | AUTO                                                     |
| OS-EXT-AZ:availability_zone          | nova                                                     |
| OS-EXT-SRV-ATTR:host                 | compute1                                                 |
| OS-EXT-SRV-ATTR:hostname             | cr-mycloud                                               |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute1                                                 |
| OS-EXT-SRV-ATTR:instance_name        | instance-000000d7                                        |
| OS-EXT-SRV-ATTR:kernel_id            |                                                          |

```

Tham khảo:

[1] - https://blog.russellbryant.net/2013/05/21/availability-zones-and-host-aggregates-in-openstack-compute-nova/

[2] - http://egonzalez.org/openstack-segregation-with-availability-zones-and-host-aggregates/

[3] - https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/4/html/Configuration_Reference_Guide/host-aggregates.html