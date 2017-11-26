# Quản lý ổ đĩa trong Server Dell
MEGACLI là công cụ được Dell cung cấp, được dùng để tạo, xóa và sửa các ổ đĩa logic và vật lý trên smart array controller (RAID Card) trên Server Dell.

## 1. Cài đặt
Cài đặt gói `megacli` tại http://hwraid.le-vert.net/debian/pool-wheezy/ 
```
wget http://hwraid.le-vert.net/debian/pool-wheezy/megacli_8.07.14-1_amd64.deb
dpkg -i megacli_8.07.14-1_amd64.deb
```

## 2. Kiểm tra thông tin về RAID Controller;
```
megacli -AdpAllInfo -aAll
```

## 3. Kiểm tra thông tin về ổ đĩa logic:
```
megacli -LDInfo -Lall -aALL
```

## 4. Kiểm tra thông tin về ổ đĩa vật lý:
```
megacli -PDList -aALL
```

## 5. Sử dụng Script sau để kiểm tra nhanh tình trạng ổ đĩa:
```
# wget https://raw.githubusercontent.com/longsube/megaclisas-status/master/megaclisas-status
# python megaclisas-status
-- Controller info --
-- ID | Model
c0 | PERC H710 Mini

-- Arrays info --
-- ID | Drives | Type | Size | Status | InProgress
c0u0 | 2 | RAID1 | 558G | Degraded | None

-- Disks info --
-- ID | Model | Status
c0u0p0 | SEAGATE ST3600057SS ES666SL77V3T | Failed
c0u0p1 | SEAGATE ST3600057SS ES666SL78VV5 | Online, Spun Up
```
Như vậy, 2 ổ đĩa đang được cấu hình RAID 1, với dung lượng sau RAID là 558 GB, trong đó 1 ổ đã bị lỗi.

Tham khảo:

https://artipc10.vub.ac.be/wordpress/2011/09/12/megacli-useful-commands/

http://hwraid.le-vert.net/wiki/LSIMegaRAIDSAS

http://hwraid.le-vert.net/wiki/DebianPackages