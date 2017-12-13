## Hướng dẫn sử dụng OpenVPN để cung cấp dịch vụ VPN trong OpenStack

### Mục tiêu LAB
- Mô hình này sử dụng 2 máy ảo trong OpenStack (cùng tenant), trong đó:
  - VM PFsense cài đặt OpenVPN, có thể sử dụng nhiều distro Linux để cài đặt, trong bài lab này sẽ sử dụng Ubuntu 14.04
  - VM Client
Bài lab thành công khi máy remote quay VPN thành công, nhận IP của dải 10.8.2.0/24 và ping được tới dải VM Client (dải Private) trong tenant.

## Mô hình 
- Sử dụng mô hình dưới để cài đặt
![img](../images/OpenVPN-OpenStackVM-TUN/image_1.jpg)

## IP Planning
- Phân hoạch IP cho các máy chủ trong mô hình trên
![img](../images/OpenVPN-OpenStackVM-TUN/image_2.jpg)

## Chuẩn bị và môi trường LAB
- Máy remote: OS Ubunu 14.04
- Máy Client: OS Ubuntu 14.04
- Máy OpenVPN: OS Ubuntu 14.04
 

## Thực hiện trên host OpenVPN
	- Cài đặt OpenVPN và Easy-RSA
	```sh
	apt-get update
	apt-get install openvpn easy-rsa –y
	```

	- Giải nén các file config mẫu vào thư mục /etc/openvpn
	```sh
	gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
	```

	- Để forward gói tin giữa các dải mạng trong VPN Server, sửa file `/etc/sysctl.conf`. Thêm vào dòng cuối cùng của file
	```sh
	net.ipv4.ip_forward = 1
	```

	Save lại và chạy lệnh:
	```sh
	sysctl -p
	```

	Kết quả:
	```sh
	net.ipv4.ip_forward = 1
	```

	- Copy các script vào thư mục /etc/openvpn
	```sh
	cp -r /usr/share/easy-rsa/ /etc/openvpn
	```

	- Tạo thư mục chứa key
	```sh
	mkdir /etc/openvpn/easy-rsa/keys
	```

	- Sửa file `/etc/openvpn/easy-rsa/vars`. Thêm các cấu hình sau
	```sh
	#Khai báo kích thước key tương ứng với key size DH 
	export KEY_SIZE=2048
	#Khai báo các thông tin mặc định của key
	export KEY_COUNTRY="VN"
	export KEY_PROVINCE="HN"
	export KEY_CITY="HN"
	export KEY_ORG="VDC"
	export KEY_EMAIL="duyhiep@vnpt.vn"
	export KEY_EMAIL=mail@host.domain
	export KEY_CN=changeme
	export KEY_NAME=changeme
	export KEY_OU=changeme
	export PKCS11_MODULE_PATH=changeme
	export PKCS11_PIN=1234
	export KEY_ALTNAMES="something"
	```

	- Tạo DH key
	```sh
	openssl dhparam -out /etc/openvpn/dh2048.pem 2048
	```

	- Tạo CA key cho VPN Server
	```sh
	cd /etc/openvpn/easy-rsa
	source vars
	./clean-all
	./build-ca
	```

	Enter liên tục để lấy các giá trị mặc định
	Kết quả

	```sh
	Generating a 2048 bit RSA private key
	
	....................................................................+++
	...........+++
	writing new private key to 'ca.key'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [VN]:
	State or Province Name (full name) [HN]:
	Locality Name (eg, city) [HN]:
	Organization Name (eg, company) [VDC]:
	Organizational Unit Name (eg, section) [changeme]:
	Common Name (eg, your name or your server's hostname) [changeme]:
	Name [EasyRSA]:
	Email Address [mail@host.domain]:
	```

	- Tạo cert và key cho VPN Server, lấy tên là `lab
	```sh
	./build-key-server lab
	```
	Lựa chọn các giá trị mặc định.

	```sh
	Generating a 2048 bit RSA private key
	.+++
	.............+++
	writing new private key to 'lab.key'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [VN]:
	State or Province Name (full name) [HN]:
	Locality Name (eg, city) [HN]:
	Organization Name (eg, company) [VDC]:
	Organizational Unit Name (eg, section) [changeme]:
	Common Name (eg, your name or your server's hostname) [lab]:
	Name [EasyRSA]:
	Email Address [mail@host.domain]:

	Please enter the following 'extra' attributes
	to be sent with your certificate request
	A challenge password []:
	An optional company name []:
	Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
	Check that the request matches the signature
	Signature ok
	The Subject's Distinguished Name is as follows
	countryName           :PRINTABLE:'VN'
	stateOrProvinceName   :PRINTABLE:'HN'
	localityName          :PRINTABLE:'HN'
	organizationName      :PRINTABLE:'VDC'
	organizationalUnitName:PRINTABLE:'changeme'
	commonName            :PRINTABLE:'lab'
	name                  :PRINTABLE:'EasyRSA'
	emailAddress          :IA5STRING:'mail@host.domain'
	Certificate is to be certified until May 29 06:49:49 2027 GMT (3650 days)
	```

	Khi gặp các thông báo sau, lựa chọn ‘y’
	```sh
	Sign the certificate? [y/n]y
	1 out of 1 certificate requests certified, commit? [y/n]y
	```

	Nếu thành công, sẽ xuất hiện thông báo
	```sh
	Write out database with 1 new entries
	Data Base Updated
	```

	- Copy các file ca, crt và key ra thư mục /etc/openvpn
	```sh
	cp /etc/openvpn/easy-rsa/keys/{lab.crt,lab.key,ca.crt} /etc/openvpn
	```

	- Sửa file `/etc/openvpn/server.conf`. Thêm các cấu hình sau:
	```sh
	# Sủ dụng cơ chế tun để client kết nối tới VPN Server
	dev tun
	# Khai báo các cert, key và CA của VPN server
	ca ca.crt
	cert lab.crt
	key lab.key
	# Sử dụng khóa Diffie Hellman 2048 bits
	dh dh2048.pem
	server 10.8.2.0 255.255.255.0
	# Add route để VPN Client có thể truy cập vào dải mạng 20.20.20.0/24
	push "route 20.20.20.0 255.255.255.0"
	# Khai báo log trạng thái của OpenVPN
	status /var/log/openvpn-status.log
	# Khai báo log hoạt động của OpenVPN
	log         /var/log/openvpn.log
	log-append  /var/log/openvpn.log
	```

	- Cài đặt Linux Bridge
	```sh
	apt-get install bridge-utils -y
	```

	- Sửa file `/etc/network/interfaces` để gắn eth1 vào br0
	```sh
	auto eth0
	iface eth0 inet dhcp
	auto eth1
	iface eth1 inet manual
	up ip link set dev $IFACE up
	down ip link set dev $IFACE down
	auto br0
	iface br0 inet static
	address 20.20.20.4
	netmask 255.255.255.0
	bridge_ports eth1
	bridge_fd 9
	bridge_hello 2
	bridge_maxage 12
	bridge_stp off
	# Set mac của br0 trugf với mac của eth1
	post-up ip link set br0 address fa:16:3e:33:57:85
	```

	- Khởi động lại card mạng
	```sh
	ifdown –a && ifup -a
	```

	- Add thêm rule vào iptables để các máy ảo trong hệ thống có thể ra Internet thông qua GW là máy ảo VPN
	```sh
	iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
	iptables --append FORWARD --in-interface br0 -j ACCEPT
	```

	- Cài đặt iptables-persistent
	```sh
	apt-get install iptables-persistent -y
	```

	- Save các rule trên iptables vào iptables-persistent
	```sh
	iptables-save > /etc/iptables/rules.v4
	```

	- Khởi động và kiểm tra trạng thái OpenVPN server
	```sh
	service openvpn start
	service openvpn status
	```

	Nếu thành công, sẽ xuất hiện thông báo
	```sh
	VPN 'server' is running
	```

 	- Kiểm tra card mạng của VPN server
 	```sh
 	ip a
 	```
 	Kết quả xuất hiện TUN cho dải 10.8.2.0
 	```sh
 	tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.8.2.1 peer 10.8.2.2/32 scope global tun0
       valid_lft forever preferred_lft forever
    ```

    - Tạo certificate và key cho Client (ở đây lấy tên là client1)
	```sh
	cd /etc/openvpn/easy-rsa/
	source vars
	./build-key client1
	```
	Enter liên tục để lấy các giá trị mặc định

	- Copy các file cấu hình, certificate và key cho client vừa tạo ra về các máy client
	```sh
	/etc/openvpn/ca.crt
	/etc/openvpn/easy-rsa/keys/client1.crt
	/etc/openvpn/easy-rsa/keys/client1.key
	```

	
## Thực hiện trên host Controller của OpenStack
  - Lấy thông tin id port của VM PFsense thưộc VLAN Private (IP: 40.40.40.2)
  ```sh
  neutron port-list | grep 20.20.20.4
  ```
  Kết quả:
  ```sh
  | c8cc67a8-2090-4d25-8875-80dcd3f90985 |      | fa:16:3e:33:57:85 | {"subnet_id": "fc5ce69d-e32b-4200-a07c-25f74bf85595", "ip_address": "20.20.20.4"}    |
  ```

  - Cho phép nhiều VLAN được đi qua port này
  ```sh
  neutron port-update c8cc67a8-2090-4d25-8875-80dcd3f90985 --allowed-address-pairs list=true type=dict ip_address=0.0.0.0/0
  ```
  Kết quả: 
  ```sh
  Updated port: c8cc67a8-2090-4d25-8875-80dcd3f90985
  ```

  - Kiểm tra thông tin port
  ```sh
  neutron port-show c8cc67a8-2090-4d25-8875-80dcd3f90985
  ```
  Kết quả:
  ```sh
	+-----------------------+-----------------------------------------------------------------------------------+
	| Field                 | Value                                                                             |
	+-----------------------+-----------------------------------------------------------------------------------+
	| admin_state_up        | True                                                                              |
	| allowed_address_pairs | {"ip_address": "0.0.0.0/0", "mac_address": "fa:16:3e:33:57:85"}                   |
	| binding:host_id       | compute1                                                                          |
	| binding:profile       | {}                                                                                |
	| binding:vif_details   | {"port_filter": true}                                                             |
	| binding:vif_type      | bridge                                                                            |
	| binding:vnic_type     | normal                                                                            |
	| created_at            | 2017-12-01T04:28:11                                                               |
	| description           |                                                                                   |
	| device_id             | 60bc0150-c791-4ed7-88bf-66b1cdccce37                                              |
	| device_owner          | compute:nova                                                                      |
	| extra_dhcp_opts       |                                                                                   |
	| fixed_ips             | {"subnet_id": "fc5ce69d-e32b-4200-a07c-25f74bf85595", "ip_address": "20.20.20.4"} |
	| id                    | c8cc67a8-2090-4d25-8875-80dcd3f90985                                              |
	| mac_address           | fa:16:3e:33:57:85                                                                 |
	| name                  |                                                                                   |
	| network_id            | 11593b25-de2e-4939-acc0-7a2b50196604                                              |
	| port_security_enabled | True                                                                              |
	| security_groups       | 8a7f2519-8bfa-4b11-a29e-b22fdfec18ce                                              |
	| status                | ACTIVE                                                                            |
	| tenant_id             | cc53359b83b0435397235399f144948a                                                  |
	| updated_at            | 2017-12-13T03:29:28                                                               |
	+-----------------------+-----------------------------------------------------------------------------------+
```

## Thực hiện trên máy ảo Client
  - Add route cho dải mạng 10.8.3.0/24
  ```sh
  ip route add 10.8.2.0/24 via 20.20.20.4 dev eth2
  ```

## Thực hiện trên host Remote, kết nối VPN
  - Trên host Remote, cài đặt OpenVPN
    ```sh
    apt-get update -y
    appt-get install openvpn
    ```

  - Copy các file cấu hình, certificate, key vào thư mục /etc/openvpn
  	```sh
  	mkdir /etc/openvpn/lab
  	mv /root/client1.crt /root/client1.key /root/ca.crt /etc/openvpn/lab
  	```

 	- Tạo file cấu hình VPN `/etc/openvpn/client1.conf` cho Client1
	```sh
	client
	dev tun
	proto udp
	remote 172.16.69.178 1194
	resolv-retry infinite
	nobind
	persist-key
	persist-tun
	ca /etc/openvpn/ca.crt
	cert /etc/openvpn/client1.crt
	key /etc/openvpn/client1.key
	ns-cert-type server
	comp-lzo
	verb 3
	```

	- Thêm quyền thực thi cho `lab.conf`
	```sh
	chmod +x /etc/openvpn/lab.conf
	```

  	- Kết nối VPN
  	```sh
  	openvpn --config lab.conf
  	```

  	- Kiểm tra bằng lệnh `ip a`, host đã nhận IP của Tunnel
  	```sh
  	tun1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.8.2.6 peer 10.8.2.5/32 scope global tun1
       valid_lft forever preferred_lft forever
  	```

  	- Kiểm tra ping vào dải mạng 20.20.20.0/24
  	```sh
  	ping 20.20.20.3
  	```


Tham khảo:

[1] - http://superuser.openstack.org/articles/managing-port-level-security-openstack/

[2] - https://dev.cloudwatt.com/en/blog/openvpn-in-a-vm-running-in-an-opencontrail-subnet.html
