

 - Cài đặt EPEL repo trên các host
	```sh
	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
	rpm -ivh epel-release-7-10.noarch.rpm
	```

yum -y update
yum install redis -y
systemctl start redis.service
systemctl status redis.service
redis-benchmark -q -n 1000 -c 10 -P 5

vim /etc/redis/redis.conf
```
tcp-keepalive 60
#bind 127.0.0.1
requirepass your_redis_master_password

maxmemory-policy noeviction
appendonly yes
appendfilename "appendonly.aof"
```
systemctl restart redis.service