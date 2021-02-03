# Thử nghiệm việc sử dụng `virtio-scsi` driver để cấp RBS image cho máy ảo - volume boot và volume thường
*Chú ý:*
 - Phiên bản thử nghiệm: OpenStack Ussuri

# Giới thiệu:
KVM và QEMU hỗ trợ 2 loại ảo hóa paravirtulized cho storage là `virtio-blk` và `virtio-scsi`. Driver đang được sử dụng mặc định để cấp Volume cho máy ảo là `virtio-blk`

Kiến trúc của `virtio-blk`:

```
guest: app -> Block Layer -> virtio-blk
host: QEMU -> Block Layer -> Block Device Driver -> Hardware
```

Kiến trúc của `virtio-scsi` (dùng QEMU là iSCSI target):

```
guest: app -> Block Layer -> SCSI Layer -> scsi_mod
host: QEMU -> Block Layer -> SCSI Layer -> Block Device Driver -> Hardware
```

Tham khảo: https://mpolednik.github.io/2017/01/23/virtio-blk-vs-virtio-scsi/

Kiến trúc của `virtio-scsi` phức tạp hơn `virtio-blk`, ảnh hưởng tới performance. 

Kiến trúc `virtio-scsi` phát huy lợi thế hơn `virtio-blk` khi:
- Direct passthrough của SCSI LUN tới VirIO SCSI adapter, by-pass qua Block layer của host vật lý. Máy ảo gắn thẳng các ổ đĩa vật lý của host
- QEMU truy cập trực tiếp tới iSCSI devices (trên SAN). Máy ảo gắn các ổ đĩa iSCSI LUN của SAN
- Hỗ trợ nhiều volume gắn vào máy ảo hơn, hàng trăm volume khi so với 25 volume của `virtio-blk`
- Hỗ trợ SCSI Unmap command (TRIM hoặc DISCARD trong Linux)
- Map ổ đĩa vào máy ảo như ổ SCSI bình thường, format name `/dev/sd*`, thuận tiện trong các trường hợp convert từ máy vật lý sang máy ảo hoặc ngược lại
Trong cả 2 trường hợp trên, hiệu năng được cải thiện do by-pass được Block layer của host khi sử dụng `virtio-scsi`


## 1. Thực hiện add thêm metadata cho image
```
openstack image set --property hw_scsi_model=virtio-scsi --property hw_disk_bus=scsi [image_ID]
```
Khi boot máy ảo với image này, ổ đĩa sẽ xuất hiện trong OS với tên theo , khác với `virtio-blk` là `/dev/vd*`

## 2. Kiểm tra tính năng DISCARD của `virtio-scsi`
 - Trên Ceph Cluster, kiểm tra block name của Volume máy ảo

```
rbd info volumes_hdd/volume-47b91e2a-6863-4eb5-ac1c-87065e929f21
```

Kết quả:
```
...
        block_name_prefix: rbd_data.1fc69b35251b29
...
```

Kiểm tra lượng object của volume máy ảo dựa theo block name

```
rados -p vms ls |grep rbd_data.1fc69b35251b29 | wc -l
```

Kết quả:
```
325
```

 - Trên máy ảo, mount ổ đĩa vào thư mục `test_discard` với option `discard`

```
mount -o discard /dev/sdb /test_discard/
```

Đẩy dung lượng vào ổ đĩa
```
dd if=/dev/zero of=/test_discard/test bs=1M count=550 oflag=direct
```

Kiểm tra lại lượng object của volume máy ảo dưới Ceph Cluster
```
rados -p vms ls |grep rbd_data.1fc69b35251b29 | wc -l
```

Kết quả:
```
942
```

 - Tiếp tục đẩy dung lượng vào ổ đĩa
```
dd if=/dev/zero of=/test_discard/test bs=1M count=920 oflag=direct
```

Kiểm tra lại lượng object của volume máy ảo dưới Ceph Cluster
```
rados -p vms ls |grep rbd_data.1fc69b35251b29 | wc -l
```

Kết quả:
```
537
```

 - Xóa thư mục `/test_discard/test` trong máy ảo
```
rm /test_discard/test
```
Kiểm tra lại lượng object của volume máy ảo dưới Ceph Cluster
```
rados -p vms ls |grep rbd_data.1fc69b35251b29 | wc -l
```

Kết quả:
```
365
```

Như vậy dung lượng của RBD image dưới Ceph Cluster đã thay đổi khi dung lượng ổ đĩa thay đổi (tăng hoặd giảm), đây là tính năng DISCARD (hay TRIM) của `virtio-scsi`.


Tham khảo:

- https://ceph.io/planet/more-recommendations-for-ceph-and-openstack/
- https://wiki.openstack.org/wiki/Virtio-scsi-for-bdm
- https://mpolednik.github.io/2017/01/23/virtio-blk-vs-virtio-scsi/
- https://www.sebastien-han.fr/blog/2015/02/02/openstack-and-ceph-rbd-discard/


