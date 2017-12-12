# Hướng dẫn cài đặt Owncloud 10.0 trên Ubuntu 16.04

### 1. Update OS và cài đặt gói LAMP
```sh
apt-get update
apt-get install lamp-server^ -y
```

### 2. Cài đặt repo cho owncloud
```sh
apt-get install curl -y
apt-get install apt-transport-https -y
curl https://download.owncloud.org/download/repositories/stable/Ubuntu_16.04/Release.key | sudo apt-key add -
echo 'deb https://download.owncloud.org/download/repositories/stable/Ubuntu_16.04/ /' | sudo tee /etc/apt/sources.list.d/owncloud.list
apt-get update
```

### 3. Cài đặt package owncloud-files và các thành phần bổ trợ (hiện giờ owncloud package đã không còn, phải cài owncloud-file và các gói bổ trợ riêng lẻ)
```sh
apt-get install owncloud-files -y
apt install -y apache2 mariadb-server libapache2-mod-php7.0 \
    php7.0-gd php7.0-json php7.0-mysql php7.0-curl \
    php7.0-intl php7.0-mcrypt php-imagick \
    php7.0-zip php7.0-xml php7.0-mbstring
chown -R www-data:www-data /var/www/owncloud/
```

### 4. Tạo owncloud.conf trong /etc/apache2/sites-available/
```sh
Alias /owncloud "/var/www/owncloud/"

<Directory /var/www/owncloud/>
  Options +FollowSymlinks
  AllowOverride All

 <IfModule mod_dav.c>
  Dav off
 </IfModule>

 SetEnv HOME /var/www/owncloud
 SetEnv HTTP_HOME /var/www/owncloud
 Satisfy Any


</Directory>
```

### 5. Link owncloud.conf sang sites-enables, và khởi động lại apache2
```sh
ln -s /etc/apache2/sites-available/owncloud.conf /etc/apache2/sites-enabled/owncloud.conf
a2enmod rewrite
service apache2 restart
```

### 6. Enable SSL cho apache2
#### 6.1. Tạo cert và private key cho web
```sh
mkdir /etc/apache2/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/owncloud.key -out /etc/apache2/ssl/owncloud.crt
```
#### 6.2. Chỉnh sửa default-ssl.conf trong /etc/apache2/sites-available/
```sh
SSLCertificateFile /etc/apache2/ssl/owncloud.crt
SSLCertificateKeyFile /etc/apache2/ssl/owncloud.key
```
#### 6.3. Enable SSL cho apache2
```sh
a2enmod ssl
a2ensite default-ssl
service apache2 reload
```

### 7. Tạo DB mariadb cho owncloud
```sh
mysql -u root -p

CREATE DATABASE owncloud;
GRANT ALL ON owncloud.* to 'owncloud'@'localhost' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;
exit;
```

### 8. Truy cập vào OwnCloud
Truy cập vào địa chỉ `https:ip_address/owncloud`

Tham khảo:

[1] - https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-owncloud-on-ubuntu-16-04

[2] - https://doc.owncloud.org/server/10.0/admin_manual/installation/source_installation.html

[3] - https://www.youtube.com/watch?v=cpyKIBEk5m0

[4] - https://www.avoiderrors.net/enable-ssl-owncloud-ubuntu/




