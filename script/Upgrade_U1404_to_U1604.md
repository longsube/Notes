# Hướng dẫn thực hiện Upgrade OS từ 14.04 lên 16.04 trên các host OpenStack

# 1. Thực hiện trên các host Controller
Việc upgrade này sẽ thực hiện lần lượt trên các host Controller.

## 1.1. Backup MySQL DB
	```
	mkdir  /root/backup_mitaka
	mysqldump -uroot -p $MYSQL_PASS --all-databases > /root/backup_mitaka/dump.sql
	```

## 1.2. Backup MySQL config
	```
	cp -rp /etc/mysql /root/backup_mitaka
	```

## 1.3. Thực hiện upgrade OS, đặt script `upgrade.sh` tại /root, phân quyền thực thi và chạy
	```
	/root/./upgrade.sh
	```

	Kiểm tra log của quá trình upgrade

	```
	tailf upgrade.sh.log
	```

	Sau khi upgrade xong, host sẽ tự động reboot
## 1.4. Sửa lại cấu hình MariaDB trên từng host Controller sau khi upgrade. Sửa file `/etc/mysql/conf.d/cluster.cnf` và thêm dòng
	```
	wsrep_on=ON
	```
## 1.5. Kiểm tra và hủy tiến trình của HAProxy đang chiếm port 3306. Sử dụng lệnh sau để kiểm tra ID của process:
	```
	netstat -anp |grep 3306
	```
	Kết quả:
	```
	tcp        0      0 172.16.68.89:3306            0.0.0.0:*               LISTEN      21018/haproxy
	```

	Hủy tiến trình của HAProxy trên:

	```
	kill -9 21018
	```

## 1.6. Nếu host mariadb đang xử lý là master, sửa file `/var/lib/mysql/grastate.dat`:
	```
	safe_to_bootstrap: 1
	```

	Sau đó tạo lại cluster

	```
	service mysql start --wsrep-new-cluster
	```

## 1.7. Nếu host mariadb đang xử lý không phải master:

	```
	service mysql restart
	```

# 2. Thực hiện trên các host Compute
Trên host compute cần phải live migrate VM sang các host khác trước khi tiến hành upgrade để tránh downtime dịch vụ trên máy ảo.

## 2.1. Thực hiện upgrade OS, đặt script `upgrade.sh` tại /root, phân quyền thực thi và chạy
	```
	/root/./upgrade.sh
	```

	Kiểm tra log của quá trình upgrade

	```
	tailf upgrade.sh.log
	```

	Sau khi upgrade xong, host sẽ tự động reboot

Lưu ý: sau khi upgrade, nếu phải tắt cả 3 host, khi khởi động lại cần phải tạo lại mariadb cluster.
Trên host tắt cuối cùng, chạy lệnh:
mysqld --wresp-new-cluster

Trên các host còn lại, chạy lệnh:
service mysql start

dùng lệnh mysqld để check log

Sau khi upgrade xong toàn bộ các host (Controller + Compute) lên Ubuntu 16.04, ta sẽ tiếp tục thực hiện việc nâng cấp phiên bản OpenStack.
