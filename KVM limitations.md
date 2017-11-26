# Các giới hạn của KVM Hypervisor

Việc ảo hóa máy ảo sử dụng KVM tồn tại một số các giới hạn sau:
- Các giới hạn chung
- Giới hạn về phần cứng
- Giới hạn về hiệu năng

## 1. Các giới hạn chung
 - Overcommit: đây là tính năng cấp quá tài nguyên, có nghĩa người dùng có thể sử dụng vượt số lượng tài nguyên của host vật lý. KVM cho phépCPU, RAM và disk space có thể overcommit. Tuy nhiên, việc này sẽ dẫn đến việc hiệu năng chung của host bị ảnh hưởng.

 - Time sychronization: Các máy ảo cần phải đồng bộ thời gian với host. Thông thường, `kvm-clock` được sử dụng. NTP hoặc các giao thức đồng bộ thờ gian tương tự cũng được đề xuất.

 - MAC address: nếu NIC máy ảo không được gán địa chỉ MAC, một địa chỉ mặc định sẽ được gán, điều này có thể gây nên lỗi mạng.

 - Live migration: tính năng này chỉ hoạt động với điều kiện các host có cùng các CPU feature. Model CPU duy nhất được hỗ trợ migration là `cpu qemu64` (mặc định), đây là model không có các tính năng add-on đặc biệt. Thiết bị lưu trữ của máy ảo phải được chia sẻ trên cả 2 host vật lý.

 - User permission: Các công cụ quản lý. VD: virsh, virt-install phải xác thực với `libvirt`. Để thực hiện câu lệnh `qemu-kvm`, user phải nằm trong group `kvm`.

## 2. Giới hạn về phần cứng 
- Bảng sau mô tả các giới hạn về phần cứng ảo hóa cho máy ảo


```
|                                                                         | RHEL 5 for Unlimited Guests | RHEL 6 for Unlimited Guests | RHEL 7 for Unlimited Guests | SUSE Linux Enterprise Server 11 SP4                           |
|-------------------------------------------------------------------------|-----------------------------|-----------------------------|-----------------------------|---------------------------------------------------------------|
| Tổng số máy ảo cho phép chạy đồng thời                                  | Không giới hạn              | Không giới hạn              | Không giới hạn              | Tổng số vCPU không vượt quá 8 lần số CPU core của Host vật lý |
| Lượng vCPU lớn nhất có thể gán cho máy ảo                               | 16                          | 240                         | 240                         | 256                                                           |
| Lượng RAM lớn nhất có thể gán cho máy ảo                                | 512 GB                      | 4000 GB                     | 4000 GB                     | 4000 GB                                                       |
| Lượng RAM nhỏ nhất có thể gán cho máy ảo                                | 512 MB                      | 512 MB                      | 512 MB                      | chưa có thông tin                                             |
| Lượng NIC lớn nhất có thể gán cho máy ảo  (sử dụng`virtio-net`)         | 28                          | 28                          | 28                          | 8                                                             |
| Lượng Block device lớn nhất có thể gán cho máy ảo (sử dụng`virtio-blk`) | 28                          | 28                          | 28                          | 20                                                            |
```

- Bảng sau mô tả các giới hạn về phần cứng cho Host vật lý (vì KVM là hypervisor trên Linux Kernel, do đó các giới hạn về phần cứng của KVM thực chất là các giới hạn của Linux Kernel)

```
|                                                              | RHEL 5 for Unlimited Guests      | RHEL 6 for Unlimited Guests       | RHEL 7 for Unlimited Guests       | SUSE Linux Enterprise Server 11 SP4 |
|--------------------------------------------------------------|----------------------------------|-----------------------------------|-----------------------------------|-------------------------------------|
| Lượng logical CPU lớn nhất cho host vật lý                   | 32bit: 160 CPUs, 64bit: 255 CPUs | 32bit: 384 CPUs, 64bit: 4096 CPUs | 32bit: 384 CPUs, 64bit: 5120 CPUs | 4096 CPUs                           |
| Lượng RAM lớn nhất cho host vật lý                           | 32bit: 1 TB, 64bit: 1 TB         | 32bit: 12 TB, 64bit: 64 TB        | 32bit: 12 TB, 64bit: 64 TB        | 16 TB                               |
| Lượng block device lớn nhất  ("sd" devices)  cho host vật lý | 1,024                            | 8,192                             | 10,000                            | chưa có thông tin                   |
```

## 3. Giới hạn về hiệu năng

Ta có 3 hình thức ảo hóa devices khi sử dụng QEMU-KVM:
 - Full-virtualized
 - Para-virtualized
 - Host Past-through

Bảng sau so sánh hiệu năng của các hình thức ảo hóa với hiệu năng khi chạy trên môi trường vật lý không ảo hóa. (tính bằng %)

```
| Category                                                           | Fully Virtualized                  | Paravirtualized  | Host Pass-through                                                                          |
|--------------------------------------------------------------------|------------------------------------|------------------|--------------------------------------------------------------------------------------------|
| CPU, MMU                                                           | 7%                                 | not applicable   | 97% (Hardware Virtualization with Extended Page Tables (Intel) or Nested Page Tables (AMD) |
|                                                                    |                                    |                  | 85% (Hardware Virtualization with shadow page tables)                                      |
| Network I/O (1GB LAN)                                              | 60% (e1000 emulated NIC)           | 75% (virtio-net) | 95%                                                                                        |
| Disk I/O                                                           | 40% (IDE emulation)                | 85% (virtio-blk) | 95%                                                                                        |
| Graphics (non-accelerated)                                         | 50% (VGA or Cirrus)                | not applicable   | not applicable                                                                             |
| Time accuracy (worst case, using recommended settings without NTP) | 95% - 105% (where 100% = accurate) | 100% (kvm-clock) | not applicable                                                                             |
```

Tham khảo:

[1] - https://www.suse.com/documentation/sles11/singlehtml/book_kvm/book_kvm.html#sec.kvm.limits.hardware

[2] - https://access.redhat.com/articles/rhel-limits

[3] - https://access.redhat.com/articles/rhel-kvm-limits

[4] - http://webcache.googleusercontent.com/search?q=cache:5DpEkDjwUo4J:www.linux-kvm.org/images/b/be/KvmForum2008%2524kdf2008_6.pdf+&cd=3&hl=en&ct=clnk&gl=vn