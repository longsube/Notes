# Backup VM Openstack sử dụng Ceph-snapshot

Bài Lab thực hiện nhằm mục đích xem luồng hoạt động phía dưới của Ceph như thế nào. Hình ảnh dưới đây mô tả cách thực hiện bài Lab

<img src=https://i.imgur.com/0qIdMWQ.png>

- 1: Khởi tạo VM, Thực hiện tạo bản backup: ***backup01***, ***backup01-incremental***
- 2: Restore về bản ***backup01***, lần lượt ghi dữ liệu và tạo bản backup: ***backup03***
- 3: Restore về bản ***backup01-incremental***, lần lượt ghi dữ liệu và tạo bản backup: ***backup01-incremental02***
- 4: Restore về bản ***backup02***, lần lượt ghi dữ liệu và tạo bản backup: ***backup02-incremental03***
- 5: Restore về bản ***backup03***, lần lượt ghi dữ liệu và tạo bản backup: ***backup04***, ***backup04-incremental04***

## 1. Quá trình thực hiện Lab
### 1.1 Tạo VM boot từ volume trên hệ thống Openstack

Volume có ID là: 2f30d501-0889-4a65-8b5d-205ef7d6b258

<img src=https://i.imgur.com/7pcPEOX.png>

### 1.2 Kiểm tra dưới hệ thống Ceph
```sh
$ rbd -p volumes_ssd ls | grep 2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/GGWlgC3.png>

**Thực hiện ghi dữ liệu vào VM, tắt VM và tạo bản backup full thứ 1**

<img src=https://i.imgur.com/Nf2gIsy.png>

```sh
openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --force --name backup01
```
**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản backup vừa tạo.
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/TLxZzj0.png>

- Kiểm tra pool backups, xuất hiện image tương ứng với bản backup vừa tạo, image này có bản snapshot tương ứng với bản backup vừa tạo
```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.ecd13f8a-fbfc-453e-8177-b6d1a43ee6e0
```

<img src=https://i.imgur.com/gSKefp7.png>

**Thực hiện bật VM, ghi dữ liệu, tắt VM và tạo bản snapshot thứ 1**

<img src=https://i.imgur.com/bL2g2Ay.png>

```sh
$ openstack volume snapshot create --volume 2f30d501-0889-4a65-8b5d-205ef7d6b258 snap01-vmcirros --force
```

**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản snapshot vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/sYYiD6g.png>


**Thực hiện bật VM, ghi dữ liệu, tắt VM và tạo bản backup incremental thứ 1 từ bản backup full thứ 1**

<img src=https://i.imgur.com/6gBEWOt.png>

```sh
$ openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --incremental --force --name backup01-incre
```

**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản backup vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/7UiM5CR.png>

- Kiểm tra pool backups, không thấy xuất hiện image tương ứng với bản backup vửa tạo, kiểm tra trong bản backup full thứ 1 thấy có thêm bản snapshot tương ứng với bản backup-incremental vừa tạo
```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.ecd13f8a-fbfc-453e-8177-b6d1a43ee6e0
```
<img src=https://i.imgur.com/y3vdtVf.png>

**Thực hiện bật VM, ghi dữ liệu, tắt VM và tạo bản backup full thứ 2**

<img src=https://i.imgur.com/IlOG2al.png>
```sh
openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --force --name backup02
```

**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản backup vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/GDfSuNK.png>

- Kiểm tra pool backups, xuất hiện image tương ứng với bản backup full vửa tạo, image này có bản snapshot tương ứng với bản backup full vừa tạo.
```sh
rbd -p backups ls
rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.49b7df4b-4380-4a83-a201-3e180e9e10c4
```
<img src=https://i.imgur.com/E3NR3yj.png>

**Thực hiện bật VM, ghi dữ liệu, tắt VM và tạo bản snapshot thứ 2**
<img src=https://i.imgur.com/lxIqoh1.png>
```sh
$ openstack volume snapshot create --volume 2f30d501-0889-4a65-8b5d-205ef7d6b258 snap02-vmcirros --force
```

**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản snapshot vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/EBEwVfs.png>

**Thực hiện restore về bản backup full thứ 1, kiểm tra dữ liêu, ghi dữ liệu, tắt VM, tạo bản backup full thứ 3**

<img src=https://i.imgur.com/eeJCd9K.png>
```sh
$ openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --force --name backup03
```
**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản backup thứ 3 vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/maq1l4o.png>

- Kiểm tra pool backups, xuất hiện image tương ứng với bản backup full vửa tạo. Image này có bản snapshot tương với với bản backup full vừa tạo

```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.f3d63d4f-8b3c-4a81-b45e-55e8be7a0b93
```
<img src=https://i.imgur.com/VKaguoH.png>

**Thực hiện bật VM, ghi dữ liệu, tắt VM và tạo bản snapshot thứ 3**

<img src=https://i.imgur.com/1pE4FBs.png>

```sh
$ openstack volume snapshot create --volume 2f30d501-0889-4a65-8b5d-205ef7d6b258 snap03-vmcirros --force
```
**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản snapshot thứ 3 vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/uHOKcGd.png>

**Thực hiện restore về bản backup-incremental thứ 1, kiểm tra dữ liệu, ghi dữ liệu, tắt VM, tạo bản backup-incremental thứ 2 từ bản backup-incremental thứ 1**

<img src=https://i.imgur.com/BGNNhYA.png>

```sh
$ openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --incremental --force --name backup01-incre02
```
**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản backup-incremental thứ 2 vừa tạo
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/EguJTD7.png>

- Kiểm tra pool backups, không xuất hiện thêm image nào, kiểm tra image của bản backup full thứ 3 thấy xuất hiện thêm bản snapshot tương ứng với bản backup-incremental thứ 2 vừa tạo. Trong image tương ứng với bản backup full thứ 1 không xuất hiện bản snapshot tương ứng với bản backup-incremental thứ 2 tạo từ bản backup-incremental thứ 1.
```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.f3d63d4f-8b3c-4a81-b45e-55e8be7a0b93
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.ecd13f8a-fbfc-453e-8177-b6d1a43ee6e0
```
<img src=https://i.imgur.com/iCQ49xv.png>

**Thực hiện restore về bản backup thứ 2, ghi dữ liệu, tắt VM, tạo bản backup-incremental thứ 3**

<img src=https://i.imgur.com/zOz45Zu.png>

```sh
$ openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --incremental --force --name backup02-incre03
```

**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, có bản snapshot được tạo ra tương ứng với bản backup-incremental thứ 3 tạo từ bản backupfull thứ 2

```sh
rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/5Lx43rE.png>

- Kiểm tra pool backups, không xuất hiện thêm image nào, kiểm tra image của bản backup full thứ 3 thấy xuất hiện thêm bản snapshot tương ứng với bản backup-incremental thứ 3 vừa tạo. Trong image tương ứng với bản backup full thứ 2 không xuất hiện bản snapshot tương ứng với bản backup-incremental thứ 3 tạo từ bản backup-full thứ 2.

```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.f3d63d4f-8b3c-4a81-b45e-55e8be7a0b93
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.ecd13f8a-fbfc-453e-8177-b6d1a43ee6e0
```
<img src=https://i.imgur.com/52nUd0X.png>

**Thực hiện restore về bản backupfull thứ 3, ghi dữ liệu, tắt VM, tạo bản backup full thứ 4**

<img src=https://i.imgur.com/lkTannR.png>
```sh
$ openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --force --name backup04
```
**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, xuất hiện thêm bản snapshot được tạo ra tương ứng với bản backup thứ 4
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/LmpyU0x.png>

- Kiểm tra pool backups, thấy xuất hiện thêm image tương ứng với bản backup full thứ 4. Kiểm tra image này thấy xuất hiện bản snapshot tương ứng với bản backup full thứ 4.
```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.a0c80031-e68a-4746-b612-eaa920a04cf6
```
<img src=https://i.imgur.com/qpCmP9U.png>

**Thực hiện bật VM, ghi dữ liệu, tắt VM, tạo bản backup-incrementalfull thứ 4**

<img src=https://i.imgur.com/iMYWxW9.png>
```sh
$ openstack volume backup create 2f30d501-0889-4a65-8b5d-205ef7d6b258 --incremental --force --name backup04-incre04
```
**Kiểm tra dưới hệ thống Ceph**

- Kiểm tra pool volume, xuất hiện thêm bản snapshot được tạo ra tương ứng với bản backup-incremental thứ 4 tạo từ bản backup full thứ 4
```sh
$ rbd snap ls volumes_ssd/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258
```
<img src=https://i.imgur.com/RrJPbNE.png>

- Kiểm tra pool backups, không thấy xuất hiện thêm image. Kiểm tra image tương ứng với bản backup full thứ 4 thấy xuất hiện thêm bản snapshot tương ứng với bản backup-incremental thứ 4 vửa tạo.
```sh
$ rbd -p backups ls
$ rbd snap ls backups/volume-2f30d501-0889-4a65-8b5d-205ef7d6b258.backup.a0c80031-e68a-4746-b612-eaa920a04cf6
```
<img src=https://i.imgur.com/Q9NYodO.png>

## 2. Kết quả thực hiện bài Lab

- Khi thực hiện tạo các bản backup hay snapshot cho volume thì trong rbd-image tương ứng với volume đó dưới Ceph sẽ tạo ra các bản backup và snapshot tương ứng.
- Khi tạo ra các bản backup full thì trong pool backup sẽ tạo ra các rbd-image độc lập và các rbd-image này sẽ chứa bản snapshot của chính nó.
- Khi thực hiện tạo các bản backup-incremental thì các bản backup-incremental này sẽ là các bản snapshot của rbd-image backupfull gần nhất mà hệ thống Ceph tạo ra.
