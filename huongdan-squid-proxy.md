# Hướng dẫn sử dụng squid làm proxy phục vụ việc kết nối tới hệ thống SCM (Source Code Management) của công ty.
*Chú ý:*
 - Sử dụng image container squid phiên bản `sameersbn/squid:3.3.8-23`, bản mới nhất `3.5.27-2` đang bị lỗi 

# Giới thiệu:
Hệ thống SCM công ty được đặt policy chỉ cho phép kết nối từ LAN nội bộ, để có thể lấy code khi ở ngoài, giải pháp là sử dụng một máy trong mạng LAN để tạo proxy kết nối tới SCM. Các máy bên ngoài sẽ quay VPN để kết nối tới máy proxy.


Trên máy proxy, chạy lệnh sau để tải image và khời chạy container squid (lưu ý máy proxy đã được cài trước các package docker):
```
docker run --name squid -d --restart=always \
  --publish 3128:3128 \
  --volume /srv/docker/squid/cache:/var/spool/squid \
  sameersbn/squid:3.3.8-23
```

Sau khi chạy lệnh trên, container squid tự động chạy và publish port `3128`, qua `http` và `https`. Để các máy client có thể kết nối tới git SCM qua proxy, cấu hình proxy cho git cho máy client:
```
git config --global http.proxy http://172.16.68.49:3128
git ls-remote --exit-code -h "https://[SCM domain]"
```

 - `172.16.68.49`: IP của máy proxy để các máy client kết nối tới
 - `3128`: port được mở của squid proxy cho các client kết nối tới
 - `[SCM domain]`: domain của hệ thống SCM công ty


```

Để kiểm tra việc kết nối tới SCM:
```
git ls-remote --exit-code -h "https://[SCM domain]"
```

Kết quả trả về:
```
fatal: unable to update url base from redirection:
  asked for: https://[SCM domain]/info/refs?service=git-upload-pack
   redirect: https://[SCM domain]/users/sign_in
```

Để gỡ cáu hình proxy cho client, chạy lệnh sau:
```
git config --global --unset http.proxy  
```


Tham khảo:

- https://github.com/sameersbn/docker-squid

