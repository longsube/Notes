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






Tham khảo:

[1] - https://www.suse.com/documentation/sles11/singlehtml/book_kvm/book_kvm.html#sec.kvm.limits.hardware

[2] - https://access.redhat.com/articles/rhel-limits

[3] - https://access.redhat.com/articles/rhel-kvm-limits

[4] - http://webcache.googleusercontent.com/search?q=cache:5DpEkDjwUo4J:www.linux-kvm.org/images/b/be/KvmForum2008%2524kdf2008_6.pdf+&cd=3&hl=en&ct=clnk&gl=vn