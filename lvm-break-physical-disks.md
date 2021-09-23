# Hướng dẫn xử lý LVM khi ổ cứng vật lý bị lỗi đột ngột
*Chú ý:*
 - 

# Giới thiệu:
Trong quá trình sử dụng, khi một ổ đĩa vật lý bị hỏng đột ngột (không được gỡ ra khỏi LVM một cách tốt đẹp) sẽ khiến các Logical Volume (LV) và Volume Group (VG) nằm trên ổ đĩa đó bị inactive.
Khi này dữ liệu của các logical volume nằm trên ổ đĩa bị hỏng không thể khôi phục được.
Tài liệu này hướng dẫn cách thức để xử lý xoá các VG và LV nằm trên ổ đĩa hỏng.

Khi một ổ đĩa vật lý bị hỏng, các LV rơi vào tình trạng `inactive`:

```
[root@compute02 ~]# vgchange -ay compute02-hdd --activationmode partial
  PARTIAL MODE. Incomplete logical volumes will be processed.
  WARNING: Couldn't find device with uuid Bi33CG-Zmt3-I3MO-a6uI-Hd2F-t0ol-ujjByn.
  WARNING: VG compute02-hdd is missing PV Bi33CG-Zmt3-I3MO-a6uI-Hd2F-t0ol-ujjByn (last written to [unknown]).
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
  Cannot activate compute02-hdd/compute02-hdd-pool_tdata: pool incomplete.
```

Trong đó:
 - `Bi33CG-Zmt3-I3MO-a6uI-Hd2F-t0ol-ujjByn`: UUID của ổ đĩa vật lý bị lỗi

Để có thể xoá được các LV này, cần phải gắn lại một ổ đĩa khác và thay thế vào ổ đĩa bị lỗi ban đầu (chỉ để khôi phục vào map của LVM, còn dữ liệu không thể khôi phục). VD ở đây là ổ `/dev/sdb`

```
pvcreate --uuid Bi33CG-Zmt3-I3MO-a6uI-Hd2F-t0ol-ujjByn /dev/sdb --restorefile /etc/lvm/backup/compute02-hdd
```

Trong đó:
 - `/etc/lvm/backup/compute02-hdd`: đường dẫn tới file metadata của VG cần xoá

Sau khi đã khôi phục xong ổ đĩa với uuid của ổ hỏng. Tiến hành active lại các LV:

```
[root@compute02 ~]# vgchange -ay compute02-hdd --activationmode partial
  PARTIAL MODE. Incomplete logical volumes will be processed.
  WARNING: VG compute02-hdd was previously updated while PV /dev/sdb was missing.
  WARNING: VG compute02-hdd was missing PV /dev/sdb Bi33CG-Zmt3-I3MO-a6uI-Hd2F-t0ol-ujjByn.
  15 logical volume(s) in volume group "compute02-hdd" now active
```

Lúc này, có thể tiến hành xoá các LV và VG:

```
[root@compute02 ~]# lvremove /dev/compute02-hdd/compute02-hdd-pool
  WARNING: VG compute02-hdd was previously updated while PV /dev/sdb was missing.
Removing pool "compute02-hdd-pool" will remove 13 dependent volume(s). Proceed? [y/n]: y
```

Tham khảo:

- http://www.wkiyo.cn/html/2019-11/i1019.html

