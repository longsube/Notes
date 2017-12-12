# Hướng dẫn migrate và upgrade Owncloud tù 7.0.4 -> 10.0.4
## Đầu bài:
Server cũ sử dụng OS Ubuntu 12.04 đang chạy Owncloud phiên bản 7.0.4. Yêu cầu dựng 1 hệ thống Owncloud mới, với phiên bản mới nhất, và di chuyển các dữ liệu từ hệ thống cũ sang, toàn bộ user, quyền đều phải được giữ nguyên.

## Giải pháp:
Server mới sử dụng OS Ubuntu 16.04, cài đặt Owncloud 7.0.4 (giống server cũ), sau khi migrate data từ server cũ sang, sẽ tiến hành upgrade phiên bản theo lộ trình như sau:
7.0.4 -> latest 7.0.x -> latest 8.0.x -> latest 8.1.x -> latest 8.2.x -> latest 9.0.x -> latest 9.1.x

## 1. Cài đặt OwnCloud 7.0.4 trên Ubuntu 16.04
### 1.1. Cài đặt repo để cài đặt php5.6 và các package liên quan (phiên bản php cho owncloud 7.0.4)
```sh
apt-get install software-properties-common -y
add-apt-repository ppa:ondrej/php
apt-get update
apt-get install php7.0 php5.6 php5.6-mysql php-gettext php5.6-mbstring php-xdebug libapache2-mod-php5.6 libapache2-mod-php7.0 php5.6-zip php5.6-XMLwriter php5.6-GD php5.6-ldap ldap-utils curl php5.6-curl smbclient php5.6-smbclient
apt-get install php5.6 php5.6-mysql
apt-get install php5.6-gd php5.6-json php5.6-curl php5.6-intl php5.6-mcrypt php5.6-imagick
```

### 1.2. Cài đăt web server và DB
```sh
apt-get install apache2
apt-get install mysql-server
```

### 1.3. Sau khi cài đặt xong mysql, chạy lệnh `mysql_secure_installation` và thực hiện như sau
```sh
Set root password? [Y/n] y
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] y
Remove test database and access to it? [Y/n] y
Reload privilege tables now? [Y/n] y
```

### 1.4. Download package của owncloud 7.0.4, giải nén và phân quyền
```sh
wget http://ftp.icm.edu.pl/packages/owncloud/owncloud-7.0.4.tar.bz2
tar -xvf owncloud-7.0.4.tar.bz2 -C /var/www/owncloud
chown www-data:www-data -R /var/www/owncloud
```

### 1.5. Đứng trên server cũ, sync toàn bộ thư mục owncloud của Server cũ sang server mới (chú ý 2 server đều phải cài rsync)
```sh
rsync -avz -e "ssh -p 7225" /var/www/owncloud/* new_host:/var/www/owncloud/
```

### 1.6. Đứng trên server cũ, sync toàn bộ thư mục data của Server cũ sang server mới (chú ý 2 server đều phải cài rsync)
```sh
rsync -avz -e "ssh -p 7225" /var/www/ftp/data/* new_host:/var/www/owncloud/data/
```

### 1.7. Chỉnh sửa lại file config.php trong /var/www/owncloud/config với IP của Server mới

```sh
<?php
$CONFIG = array (
  'instanceid' => 'oc35c4d45b53',
  'passwordsalt' => 'd2ef02c23f4c0e3ac4ef34774993df',
  'secret' => 'e017c98424ba8bf28841e8aaeb4fe03372f4ea86a210b23a415a708d7eaa06df8bc168ecdf522ba22208b33c0b5e274e',
  'trusted_domains' =>
  array (
    0 => '123.30.212.230',
  ),
  'datadirectory' => '/var/www/owncloud/data',
  'overwrite.cli.url' => 'http://123.30.212.230/owncloud',
  'dbtype' => 'sqlite3',
  'version' => '7.0.4.2',
  'installed' => true,
);
```







https://central.owncloud.org/t/migrate-owncloud-server-7-0-4-on-ubuntu-12-04-to-owncloud-server-9-on-ubuntu-16-04/2855/



# Upgrade from 7.0.4 to 10.0


wget http://ftp.icm.edu.pl/packages/owncloud/owncloud-8.0.16.tar.bz2


mv owncloud owncloud_old
service apache2 stop
backup /var/www/owncloud/
mv /var/www/owncloud /var/www/owncloud_old

backup database
mysqldump -u root -p owncloud > /var/www/owncloud_old/owncloud_mysql.bak



tar -xvf owncloud-8.0.16.tar.bz2 -C /var/www/
chown -R www-data:www-data /var/www/owncloud/

copy lai config/
cp -p /var/www/owncloud_old/config/config.php /var/www/owncloud/config/config.php





sudo -u www-data php5.6 /var/www/owncloud/occ maintenance:mode --on
sudo -u www-data php5.6 /var/www/owncloud/occ status
sudo -u www-data php5.6 /var/www/owncloud/occ upgrade

sqlite3 data/owncloud.db .dump > owncloud_sqlite_7015.bak
 
service apache2 restart

sudo -u www-data php5.6 occ db:convert-type --all-apps mysql owncloud 127.0.0.1 owncloud

https://www.rosehosting.com/blog/how-to-install-owncloud-7-on-an-ubuntu-14-04-vps/
https://www.2daygeek.com/owncloud-migration-linux/#
https://www.2daygeek.com/how-to-migrate-owncloud-from-sqlite-to-mysql-database/
https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html
https://owncloud.org/blog/upgrading-owncloud-on-debian-stable-to-official-packages/
https://doc.owncloud.org/server/9.1/admin_manual/maintenance/manual_upgrade.html
https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html
https://doc.owncloud.org/server/8.0/admin_manual/configuration_database/db_conversion.html
https://github.com/owncloud/core/issues/28223