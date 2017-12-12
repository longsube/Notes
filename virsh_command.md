# Một số lệnh của virsh để quản trị máy ảo
Virsh là một công cụ sử dụng libvirt API tương tác với qemu-kvm để quản trị máy ảo

### 1. Các lệnh để kiểm tra trạng thái máy ảo
- Liệt kê tất cả máy ảo
	```sh
	virsh list --all
	```
- Hiển thị file xml của máy ảo
	```sh
	virsh dumpxml instance-00000015
	```
- Kiểm tra tình trạng sủ dụng RAM máy ảo
	```sh
	virsh dommemstat instance-00000020
	```
- Khởi động máy ảo
	```sh
	virsh start vm
	```
- Tắt máy ảo
	```sh
	virsh shutdown vm
	```
- Hủy máy ảo
	```sh
	virsh destroy vm
	```

### 2. Các lệnh để kiểm tra trạng thái ổ đĩa máy ảo
- Kiểm tra trạng thái ổ đĩa vda máy ảo
	```sh
	virsh domblkstat instance-00000015 vda --human
	```

### 3. Các lệnh để kiểm tra trạng thái network máy ảo
- Liệt kê tất cả các network đang có trên host KVM
	```sh
	virsj net-list --all
	```
- Kiểm tra trạng thái một card mạng của máy ảo
	```sh
	virsh domifstat instance-00000015 tapbc55e0b5-1e --human
	```
- Thay đổi cấu hình của một network trong Host KVM
	```sh
	virsh net-edit vmnet2
	```
- Khởi động một network trong host KVM
	```sh
	virsh net-start vmnet2
	```
- Tắt một network trong host KVM
	```sh
	virsh net-destroy vmnet2
	```

Tham khảo:

[1] - https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/virtualization/chap-virtualization-managing_guests_with_virsh

[2] - https://www.centos.org/docs/5/html/5.2/Virtualization/chap-Virtualization-Managing_guests_with_virsh.html