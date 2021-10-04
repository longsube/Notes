# Hướng dẫn cài đặt lưu history command line của tất cả các user

Tạo và chạy script sau:
```
#!/bin/bash
echo "local6.*  /var/log/cmdlog.log" >> /etc/rsyslog.d/50-default.conf
array1="export PROMPT_COMMAND="
array2=('RETRN_VAL=$?;logger -p local6.debug -t bash "$(whoami) [$$]: $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//" ) [$RETRN_VAL]"')
echo "$array1'$array2'" >>  /etc/bash.bashrc
/etc/init.d/rsyslog restart
systemctl restart rsyslog.service
```

Sau khi chạy, kiểm tra log cmd được lưu trong file `/var/log/cmdlog.log`
