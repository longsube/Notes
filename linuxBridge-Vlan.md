# Hướng dẫn cài đặt Linux bridge để tạo nhiều Vlan (Subinterface)
Hướng dẫn sau sẽ thực hiện việc add 2 VLAN 20,21 vào dường trunk (kết nối tới NIC eno3 trên host vật lý), các VLAN này sử dụng để làm dải Provider cho các máy ảo.

Yêu cầu:
 - Các đường kết nối trunk như mô hình
 - Trên SW đã cấu hình các VLAN

	 ------------     ------------
     |		    |	  |			 | 
     |	 SV2    |	  |	  SV3    |
     |		    | 	  |          |
     |   eno3   |  	  |	  eno3   |
     ------------     ------------
          |                |
        trunk            trunk
        20,21            20,21          
          |                |
          |                |
     -----------------------------
     |                           |
     |     cisco IOS switch      |
     |                           |     
     |         Gi1/0/13          |  
     -----------------------------
            	   |           
            	   |           
          	     trunk       
         		 20,21     
            	   |           
        -----------------------
        |        eno3         |
        |                     |
        |         SV1         |
        -----------------------

Thực hiện trên Host vật lý SV1

## Update package
```sh
apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
```

## Cài đặt các gói phần mề cho ảo hóa và linux bridge
```sh
apt-get -y virtinst bridge-utils
```

## Cấu hình mode dot1q
```sh 
modprobe 8021q
```

## Add Vlan 20, 21 cho port eno3
```sh
/sbin/vconfig add eno3 20
/sbin/vconfig add eno3 21
```

## Cấu hình /etc/network/interfaces
```sh
auto eno3
iface eno3 inet manual

auto eno3.20
iface eno3.20 inet manual
vlan-raw-device eno3

auto br20
iface br20 inet static
address 10.10.20.8
netmask 255.255.255.0
dns-nameservers 8.8.8.8
bridge_ports eno3.20
bridge_stp off
auto br20

auto eno3.21
iface eno3.21 inet manual
vlan-raw-device eno3

auto br21
iface br21 inet static
address 192.168.10.8
netmask 255.255.255.0
bridge_ports eno3.21
bridge_stp off
auto br21
```

## Khởi động lại network
```sh
service networking restart
```

## Kiểm tra linuxbridge
```sh
brctl show
```
Kết quả:
```sh
br20		8000.44a8421ea02c	no		eno3.20
br21		8000.44a8421ea02c	no		eno3.21
```

Tham khảo:

[1] - http://net.doit.wisc.edu/~dwcarder/captivator/linux_trunking_bridging.txt

[2] - http://blog.frosty-geek.net/2011/02/ubuntu-tagged-vlan-interfaces-and.html