# Quản lý ổ đĩa trong Server HP
HPACUCLI (HP Array Configuration Utility CLI) là công cụ được HP cung cấp, được dùng để tạo, xóa và sửa các ổ đĩa logic và vật lý trên smart array controller (RAID Card) trên Server HP.

## 1. Cài đặt
Cài đặt gói `hpcucli.deb` tại http://hwraid.le-vert.net/debian/pool-wheezy/ 
```
wget http://hwraid.le-vert.net/debian/pool-wheezy/hpacucli_9.20.9.0-1_amd64.deb
dpkg -i hpacucli_9.20.9.0-1_amd64.deb
```

## 2. Có 2 cách để thực thi câu lệnh
 - Cách 1: gõ `hpacucli`, sau đó gõ các câu lênh cần thực thi
```
# hpacucli
HP Array Configuration Utility CLI 9.20.9.0
Detecting Controllers...Done.
Type "help" for a list of supported commands.
Type "exit" to close the console.

=> rescan
=> exit
```

 - Cách 2: gõ trực tiếp câu lệnh
 ```
 # hpacucli rescan
 ```

 ## 3. Hiển thị trạng thái của Controller và ổ đĩa
 ```
  hpacucli
HP Array Configuration Utility CLI 9.20.9.0
Detecting Controllers...Done.
Type "help" for a list of supported commands.
Type "exit" to close the console.

=> ctrl all show config

Smart Array P420i in Slot 0 (Embedded)    (sn: 001438030E455F0)

   array A (SAS, Unused Space: 0  MB)


      logicaldrive 1 (1.6 TB, RAID 0, OK)

      physicaldrive 1I:1:1 (port 1I:box 1:bay 1, SAS, 600 GB, OK)
      physicaldrive 1I:1:2 (port 1I:box 1:bay 2, SAS, 600 GB, OK)
      physicaldrive 1I:1:3 (port 1I:box 1:bay 3, SAS, 600 GB, OK)

   SEP (Vendor ID PMCSIERA, Model SRCv8x6G) 380 (WWID: 5001438030E455FF)
```

Hệ thống hiện có 3 ổ đĩa, mỗi ổ có dung lượng 600 GB. Ba ổ này đang được cấu hình RAID 0, dung lượng lưu trữ sau RAID là 1.6 TB

## 4. Kiểm tra trạng thái RAID Controller
```
=> ctrl all show status

Smart Array P420i in Slot 0 (Embedded)
   Controller Status: OK
   Cache Status: OK
   Battery/Capacitor Status: OK
```
Thông tin hiển thị gồm trạng thái card RAID, trạng thái cache và Pin của card.

## 5. Kiểm tra thông tin ổ cứng
```
=> ctrl slot=0 pd all show status

   physicaldrive 1I:1:1 (port 1I:box 1:bay 1, 600 GB): OK
   physicaldrive 1I:1:2 (port 1I:box 1:bay 2, 600 GB): OK
   physicaldrive 1I:1:3 (port 1I:box 1:bay 3, 600 GB): OK
```
Như ta thấy, ổ cứng đang được gắn từ bay 1-3 trên Server, tất cả đêu trong trạng thái tốt.

## 6. Kiểm tra trạng thái của một ổ
```
=> ctrl slot=0 pd 1I:1:1 show detail

Smart Array P420i in Slot 0 (Embedded)

   array A

      physicaldrive 1I:1:1
         Port: 1I
         Box: 1
         Bay: 1
         Status: OK
         Drive Type: Data Drive
         Interface Type: SAS
         Size: 600 GB
         Rotational Speed: 10000
         Firmware Revision: HPDC
         Serial Number:         KWH9X84R
         Model: HP      EG0600FBVFP
         Current Temperature (C): 33
         Maximum Temperature (C): 40
         PHY Count: 2
         PHY Transfer Rate: 6.0Gbps, Unknown
         Drive Authentication Status: OK
         Carrier Application Version: 11
         Carrier Bootloader Version: 6
```

Trong câu lệnh, `pd` là ổ đĩa vật lý, `1I:1:1` là kí hiệu của ổ tại bay 1. Câu lệnh cho ra các thông tin về: dung lượng, vòng quay, Serial number, model, nhiệt độ hiện tại và cao nhất,...

## 7. Kiểm tra tất cả các ổ đĩa logic
```
=> ctrl slot=0 ld all show

Smart Array P420i in Slot 0 (Embedded)

   array A

      logicaldrive 1 (1.6 TB, RAID 0, OK)
```
Hiển thị trạng thái của các ổ đĩa logic tạo trên RAID, như trên ta có 1 ổ đĩa logic 1.6TB

## 8. Kiểm tra chi tiết trạng thái ổ đĩa vật lý
```
=> ctrl slot=0 ld 1 show

Smart Array P420i in Slot 0 (Embedded)

   array A

      Logical Drive: 1
         Size: 1.6 TB
         Fault Tolerance: RAID 0
         Heads: 255
         Sectors Per Track: 32
         Cylinders: 65535
         Strip Size: 256 KB
         Full Stripe Size: 256 KB
         Status: OK
         Caching:  Enabled
         Unique Identifier: 600508B1001C8E5EE7B94BC101CBFD3E
         Disk Name: /dev/sda
         Mount Points: /boot 487 MB
         OS Status: LOCKED
         Logical Drive Label: A46B7F43001438030E455F0FF96
         Drive Type: Data
```

## 9. Bật/tắt cache
```
=> ctrl slot=0 modify dwc=disable

=> ctrl slot=0 modify dwc=enable
```
Câu lệnh để bật hoặc tắt trên RAID Controller.

## 10. Nháy đèn thông báo ổ đĩa
```
=> ctrl slot=0 ld 1 modify led=on
=> ctrl slot=0 ld 1 modify led=off
```
Câu lệnh trên sẽ bật tắt đèn trên các ổ đĩa vật lý mà thuộc ổ đĩa logic số 2.

Tham khảo:
http://www.thegeekstuff.com/2014/07/hpacucli-examples/
http://hwraid.le-vert.net/wiki/SmartArray