**Hướng dẫn sử dụng script**

*Môi trường thực hiện:*
 - OS: Ubuntu 14.04.5, kernel 4.4.0-142-generic

## 1. Script liệt kê số file trong 1 thư mục
 - Script để liệt kê các file trong 1 thư mục được chỉ định, nếu thư mục không tồn tại sẽ cảnh bảo.

 - Đặt script tại thư mục `root` và cấp quyền thực thi
 ```
 chmod +x /root/listFile_Dir.sh.sh
 ```

 - Nội dung script:
 ```
 !/bin/bash
###############################################################################
#
# listfiles - lists all files in a particular directory
#
###############################################################################

dir=$1

# Check if directory exists first
if [ ! -d $dir ]
then
    echo 'The '$dir' directory has not been created yet.'
    exit 0
fi

# List all the files in the directory
echo '========== Files in the '$1' =========='
ls -l $dir

exit 0
```

- Thực thi script:
```
bash /root/listFile_Dir.sh.sh /home/longlq
```
	`/home/longlq`: tham sô truyền vào là đường dẫn thư mục cần liệt kê số lượng file

- Kết quả:
```
========== Files in the /home/longlq ==========
total 76
drwxrwxrwx 1 root   longlq  4096 Th05  7  2019 DATA
drwxr-xr-x 2 longlq longlq  4096 Th09 25 15:57 Desktop
drwxr-xr-x 6 longlq longlq  4096 Th12  3  2017 Documents
drwxr-xr-x 5 longlq longlq 20480 Th10 25 10:51 Downloads
-rw-r--r-- 1 longlq longlq  8980 Th10 25  2017 examples.desktop
-rw-r--r-- 1 root   longlq  8038 Th07 27  2017 linux_signing_key.pub
drwxr-xr-x 2 longlq longlq  4096 Th10 26  2017 Music
drwxr-xr-x 2 longlq longlq  4096 Th10 26  2017 Pictures
drwxr-xr-x 2 longlq longlq  4096 Th10 26  2017 Public
drwxr-xr-x 5 longlq longlq  4096 Th10 11 10:22 snap
drwxr-xr-x 2 longlq longlq  4096 Th10 26  2017 Templates
drwxr-xr-x 2 longlq longlq  4096 Th10 26  2017 Videos
```

## 2. Script đếm số file trong 1 thư mục
- Script để đếm các file trong 1 thư mục được chỉ định, nếu thư mục không tồn tại hoặc không có file trong thư mục sẽ cảnh bảo

- Đặt script tại thư mục `root` và cấp quyền thực thi
```
 chmod +x /root/countFiles_Dir.sh
```

- Nội dung script:
```
#!/bin/bash
###############################################################################
#
# count files - returns the number of files in a particular directory
#
###############################################################################

dir=$1

# Check if directory exists first
if [ ! -d $dir ]
then
    echo 'The '$dir' has not been created yet.'
    exit 0
fi

# Get the number of files in the directory.
number_of_files=$(ls $dir -1 | wc -l)

# Display a nice warning if there's no files and exit the program.
if [ $number_of_files -eq 0 ]
then
    echo 'There is no files in '$1'.'
    exit 0
fi

# Display a number of files in directory
echo 'Number of files in '$1': '$number_of_files

exit 0
```
- Thực thi script:
```
bash /root/countFiles_Dir.sh /home/longlq
```
	`/home/longlq`: tham sô truyền vào là đường dẫn thư mục cần liệt kê số lượng file

- Kết quả:
```
Number of files in /home/longlq: 12
```