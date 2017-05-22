# Các giới hạn của KVM Hypervisor

Việc ảo hóa máy ảo sử dụng KVM tồn tại một số các giới hạn sau:
- Các giới hạn chung
- Giới hạn về phần cứng
- Giới hạn về hiệu năng

## 1. Các giới hạn chung
 - Overcommit: đây là tính năng cấp quá tài nguyên, có nghĩa người dùng có thể sử dụng vượt số lượng tài nguyên của host vật lý. KVM cho phépCPU, RAM và disk space có thể overcommit. Tuy nhiên, việc này sẽ dẫn đến việc hiệu năng chung của host bị ảnh hưởng.

 - Time sychronization: Các máy ảo cần phải đồng bộ thời gian với host. Thông thường, `kvm-clock` được sử dụng. NTP hoặc các giao thức đồng bộ thờ gian tương tự cũng được đề xuất.

 - MAC address: nếu NIC máy ảo không được gán địa chỉ MAC, một địa chỉ mặc định sẽ được gán, điều này có thể gây nên lỗi mạng.

 - Live migration: tính năng này chỉ hoạt động với điều kiện các host có cùng các CPU feature. 

 - User permission: Các công cụ quản lý. VD: virsh, virt-install phải xác thực với `libvirt`. Để thực hiện câu lệnh `qemu-kvm`, user phải nằm trong group `kvm`.

## 2. Giới hạn về phần cứng 
Bảng sau mô tả các giới hạn về phần cứng ảo hóa cho máy ảo


```
| alo                                                                     | RHEL 5 for Unlimited Guests | RHEL 6 for Unlimited Guests | RHEL 7 for Unlimited Guests | SUSE Linux Enterprise Server 11 SP4                           |
|-------------------------------------------------------------------------|-----------------------------|-----------------------------|-----------------------------|---------------------------------------------------------------|
| Tổng số máy ảo cho phép chạy đồng thời                                  | Không giới hạn              | Không giới hạn              | Không giới hạn              | Tổng số vCPU không vượt quá 8 lần số CPU core của Host vật lý |
| Lượng vCPU lớn nhất có thể gán cho máy ảo                               | 16                          | 240                         | 240                         | 256                                                           |
| Lượng RAM lớn nhất có thể gán cho máy ảo                                | 512 GB                      | 4000 GB                     | 4000 GB                     | 4000 GB                                                       |
| Lượng RAM nhỏ nhất có thể gán cho máy ảo                                | 512 MB                      | 512 MB                      | 512 MB                      | chưa có thông tin                                             |
| Lượng NIC lớn nhất có thể gán cho máy ảo  (sử dụng`virtio-net`)         | 28                          | 28                          | 28                          | 8                                                             |
| Lượng Block device lớn nhất có thể gán cho máy ảo (sử dụng`virtio-blk`) | 28                          | 28                          | 28                          | 20                                                            |             |
```


Tham khảo:

[1] - https://www.suse.com/documentation/sles11/singlehtml/book_kvm/book_kvm.html#sec.kvm.limits.hardware

[2] - https://access.redhat.com/articles/rhel-limits

[3] - https://access.redhat.com/articles/rhel-kvm-limits

[4] - http://webcache.googleusercontent.com/search?q=cache:5DpEkDjwUo4J:www.linux-kvm.org/images/b/be/KvmForum2008%2524kdf2008_6.pdf+&cd=3&hl=en&ct=clnk&gl=vn