
# Hướng dẫn resize lại phân vùng boot (trong trường hợp phân vùng này quá nhỏ sẽ không thể upgrade kernel mới)
Bài lab này sẽ cắt một phần dung lượng của swap partition (sda2) cho boot partition (sda1)


## List các phân vùng
```sh
lsblk
```

Kết quả:
```sh
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  4.1T  0 disk 
├─sda1   8:1    0   94M  0 part /boot
├─sda2   8:2    0 14.9G  0 part [SWAP]
└─sda3   8:3    0  4.1T  0 part /
sr0     11:0    1 1024M  0 rom  
```

## Kiểm tra sector của từng partition
```sh
fdisk -l
```
Kết quả:
```sh
Disk /dev/sda: 4.1 TiB, 4494998896640 bytes, 8779294720 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: EB398577-0AD2-4569-B974-CEBACFFD00B7

Device        Start        End    Sectors  Size Type
/dev/sda1      2048     194559     192512   94M Linux filesystem
/dev/sda2    194560   31444991   31250432 14.9G Linux swap
/dev/sda3  31444992 8779292671 8747847680  4.1T Linux filesystem
```

Ta thấy phân vùng cho swap có kích thước 100MB, ta sẽ mở rộng phân vùng này lên 500MB bằng cách cắt bớt từ phân vùng swap


## Tắt swap
```sh
swapoff -a
```

## Xóa phân vùng swap cũ và tạo phân vùng mới
```sh
fdisk /dev/sda

Command (m for help): d
Partition number (1-3, default 3): 2

Partition 2 has been deleted.


Command (m for help): n
Partition number (2,4-128, default 2): 2
First sector (194560-8779294686, default 194560): 994560     
Last sector, +sectors or +size{K,M,G,T,P} (994560-31444991, default 31444991): 

Created a new partition 2 of type 'Linux filesystem' and of size 14.5 GiB.

Command (m for help): t   
Partition number (1-3, default 3): 2
Hex code (type L to list all codes): 19

Changed type of partition 'Linux filesystem' to 'Linux swap'.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Re-reading the partition table failed.: Device or resource busy

The kernel still uses the old table. The new table will be used at the next reboot or after you run partprobe(8) or kpartx(8).
```

## Để áp cấu hình mới, chạy lệnh
```sh
partprobe
```

## Tạo Swap
```sh
mkswap -L SWAP-sda2 /dev/sda2
```
Kết quả:
```sh
Setting up swapspace version 1, size = 14.5 GiB (15590617088 bytes)
LABEL=SWAP-sda2, UUID=37b8bdb3-d205-4726-875f-93210f62105c
```

## Có thể kiểm tra UUID của phân vùng swap mới tạo bằng lệnh
```sh
ls -l /dev/disk/by-uuid/
```
Kết quả:
```sh
total 0
lrwxrwxrwx 1 root root 10 Nov 26 01:37 37b8bdb3-d205-4726-875f-93210f62105c -> ../../sda2
lrwxrwxrwx 1 root root 10 Nov 26 01:36 9618459e-94f7-4b1e-bb6d-400908fa60c6 -> ../../sda1
lrwxrwxrwx 1 root root 10 Nov 26 01:36 c8fe7287-1130-450f-8945-f02bb3d1e61a -> ../../sda3
```

## Sửa /etc/fstab để mount phân vùng swap khi boot
```sh
UUID=37b8bdb3-d205-4726-875f-93210f62105c none            swap    sw              0       0
```

## Khởi động swap
```sh
swapon -a
```

## Tắt phân vùng boot
```sh
umount /boot
tune2fs -O ^has_journal /dev/sda1
```


## Xóa phân vùng boot cũ và tạo phân vùng mới với kích thước lớn hơn
```sh
fdisk /dev/sda

Command (m for help): d
Partition number (1-3, default 3): 1

Partition 1 has been deleted.

Command (m for help): n
Partition number (1,4-128, default 1):           
First sector (34-8779294686, default 2048): 
Last sector, +sectors or +size{K,M,G,T,P} (2048-994559, default 994559): 

Created a new partition 1 of type 'Linux filesystem' and of size 484.6 MiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Re-reading the partition table failed.: Device or resource busy

The kernel still uses the old table. The new table will be used at the next reboot or after you run partprobe(8) or kpartx(8).
```

## Để áp cấu hình mới, chạy lệnh
```sh
partprobe
```


## Kiểm tra phân vùng làm boot
```sh
e2fsck -f /dev/sda1
```
Kết quả:
```sh
e2fsck 1.42.13 (17-May-2015)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/sda1: 299/24096 files (1.3% non-contiguous), 62180/96256 blocks
```

## Giãn phân vùng sda1, là phân vùng boot
```sh
resize2fs /dev/sda1
```
Kết quả:
```sh
resize2fs 1.42.13 (17-May-2015)
Resizing the filesystem on /dev/sda1 to 496256 (1k) blocks.
The filesystem on /dev/sda1 is now 496256 (1k) blocks long.
```

## Tạo lại boot
```sh
tune2fs -j /dev/sda1
```
Kết quả:
```sh
Creating journal inode: done
```

## Mount phân vùng boot
```sh
mount /boot
```

## Kiểm tra lại các phân vùng
```sh
lsblk
```
Kết quả phân vùng boot đã được nới rộng lên 500MB
```sh
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   4.1T  0 disk 
├─sda1   8:1    0 484.6M  0 part /boot
├─sda2   8:2    0  14.5G  0 part [SWAP]
└─sda3   8:3    0   4.1T  0 part /
sr0     11:0    1  1024M  0 rom  
```

Tham khảo:
[1] - http://www2.fugitol.com/2012/04/linux-resizing-boot-partition.html
[2] - https://liquidat.wordpress.com/2007/10/15/short-tip-get-uuid-of-hard-disks/



