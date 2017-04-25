# Hướng dẫn sử dụng công cụ đo hiệu năng ổ cứng VDBench

*Chú ý:*
 - Đây là công cụ do Oracle phát triển, có cả phiên bản cho Linux và Windows
 - Hướng dẫn sau thực hiện trên máy ảo Ubuntu14.04, kernel 3.13.0-32-generic

## 1. Cài đặt
Cài đặt môi trường java 7 jdk trên máy cần test
```
apt-get install openjdk-7-jre -y
```

## 2. Tải gói công cụ vdbench tại đây
http://www.oracle.com/technetwork/server-storage/vdbench-downloads-1901681.html

![download vdbench](http://image.prntscr.com/image/b34e957ca4d34303a95496c3ceb1dc6e.png)

Sau khi tải về, đặt tại thư mục /root của máy cần test.
```
root@ubuntu:~# cd vdbench50406/
```

## 3. Tạo kịch bản để chạy test
```
root@ubuntu:~/vdbench50406# vim single-vol
```
Nội dung

```
*This is a python generated script for vdbench
*compratio=4
data_errors=50000000
hd=default,vdbench=/root/vdbench50406,user=root,shell=vdbench
sd=default,openflags=o_direct,range=(1,10)
sd=sd0_1,lun=/dev/sdb
wd=wd1_0,sd=sd*,rdpct=0,seekpct=100,xfersize=(4k,100)
rd=rd1,wd=wd1_*,iorate=max,elapsed=1h,interval=15,forthreads=16
```

Một số thông số cần lưu ý:

`data_errors=50000000`: số error cho phép xảy ra (nếu quá số lượng này sẽ ngắt script)

`hd=default,vdbench=/vdbench,user=root,shell=vdbench`
 - `hd=default`: (Host Definition) khai báo IP hoặc hosename của host được test, `default` sẽ sử dụng localhost
 - `vdbench=/root/vdbench50406`: khai báo đường dẫn tới thư mục chứa chương trình chạy vdbench
 - `user=root`: khai báo user thực hiện test
 - `shell=vdbench`: khai báo daemon để chạy vdbench

`sd=default,openflags=o_direct,range=(1,10)`
 - `sd=default`: (Storage Definition) khai báo các thông số mặc định cho tất cả các Storage definition
 - `openflags=o_direct`: truy xuất trực tiếp vào thiết bị dạng raw (/dev/xxx)
 - `range=(1,10)`: Sử dụng 10% block đầu tiên của ổ cứng đê test, 90% còn lại free

`sd=sd0_1,lun=/dev/sdb`
 - `sd=sd0_1`: (Storage definition) định nghĩa thiết bị lưu trữ được test
 - `lun=/dev/sdb`: khai báo thiết bị lưu trữ được test, ở đây là test trực tiếp xuống raw device `/dev/sdb`

`wd=wd1_0,sd=sd*,rdpct=0,seekpct=100,xfersize=(4k,100)`
 - `wd=wd1_0`: (Work Definition): khai báo tên của job chạy
 - `sd=sd*`: thực hiện trên tất cả các SD có tên chứa 'sd*'
 - `rdpct=0`: tỉ lệ read request, ở đây là 0% read, 100% write
 - `seekpct=100`: thể hiện số truy xuất ngẫu nhiên (random), có thể set là `seekpct=100` hoặc `seekpct=random`, nếu tuần tự thì set là `seekpct=seq`
 - `xfersize=(4k,100)`: `4k` thể hiện blocksize script sử dụng. `100` là số % IO sử dụng blocksize này

`rd=rd1,wd=wd1_*,iorate=max,elapsed=1h,interval=15,forthreads=16`
 - `rd=rd1`: (Run Definition): khai báo các thông số trong quá trình chạy job
 - `wd=wd1_*`: thực hiện trên tất cả các WD có tên chứa 'wd1_*'
 - `iorate=max`: không kiểm soát về số lượng IO
 - `elapsed=1h`: thời gian chạy script(1 giờ)
 - `interval=15`: interval: khoảng thời gian giữa 2 lần chạy (15 giây)
 - `forthreads=16`: thực hiện 1 lần chạy với 16 thread


## 4. Chạy kịch bản test
```
root@ubuntu:~/vdbench50406# ./vdbench -f single-vol -o singleout/
```

Trong đó:
`single-vol`: tên của script được chạy
`singleout`: tên thư mục chứa file kết quả test (nằm cùng mức với thư mục chứa chương trình chạy `/root/vdbench50406`)

Tham khảo:

[1] - https://support.zadarastorage.com/hc/en-us/articles/213024266-How-To-use-Vdbench-to-measure-performance-in-Linux

[2] - https://blogs.oracle.com/henk/entry/vdbench_workload_skew

[3] - [VDBench Guide](/docs/vdbench.pdf)