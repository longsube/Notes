# Hướng dẫn cài đặt SFTP server trên Ubuntu 18.04

*Chú ý:*
 - Hướng dẫn sau thực hiện trên máy ảo Ubuntu18.04.

Cài đặt SSH server
```
apt-get install openssh-server -y
```

Cài đặt vsftpd package
```
apt-get install vsftpd -y
```

Backup lại file `/etc/vsftpd.conf`
```
mv /etc/vsftpd.conf /etc/vsftpd.conf_orig
```
 
Chỉnh sửa các cấu hình sau trong file `/etc/vsftpd.conf`
``` 
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
pasv_enable=Yes
pasv_min_port=10000
pasv_max_port=10100
allow_writeable_chroot=YES
```

Khởi động lại service vsftpd
```
service vsftpd restart
```

Chỉnh sửa file `/etc/ssh/sshd_config`, đặt cấu hình sau vào cuối file
```
Match group sftp
ChrootDirectory /home/DVCQG
X11Forwarding no
AllowTcpForwarding no
ForceCommand internal-sftp
```

Khời động lại service ssh
```
service ssh restart
```

Tạo user group `sftp`, các users trong group này sẽ có quyền truy cập vào sftp server
```
addgroup sftp
```

Tạo user `sftpuser`, đây là user được quyền đọc sftp server, các user khác tạo tương tự
```
useradd -m sftpuser -g sftp
```

Cấu hình để đóng quyền login vào server của user `sftpuser` 
```
usermod -s /sbin/nologin sftpuser
```

Đặt password cho user `sftpuser`
```
passwd sftpuser 
```

Tạo user `sftpadmin`, đây là user được quyền ghi vào sftp server
```
useradd -m sftpadmin -g root
usermod -s /sbin/nologin sftpadmin
passwd sftpadmin
```

Thay đổi quyền của thư mục dành cho sftp server
```
chmod 775 /home/DVCQG/
```

Kiểm thử việc truy cập vào sftpserver, thay `localhost` bằng IP của sftp server khi truy cập từ máy khác
```
sftp sftpuser@localhost
```

Tham khảo:
[1] - https://linuxconfig.org/how-to-setup-sftp-server-on-ubuntu-18-04-bionic-beaver-with-vsftpd