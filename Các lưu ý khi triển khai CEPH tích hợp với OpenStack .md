# 1. Ceph hoạt động với OpenStack như thế nào?
Ceph là loại hình lưu trũ hợp nhất có thể cung cấp tất cả các loại lưu trữ: Object, Block và Files. Ceph cung cấp lưu trữ cho Cinder volumes, Nova ephemeral disk và Glance images. Ceph cũng có thể thay thế Swift, thông qua radosgw (gateway HTTP REST cho RADOS object store). Tương tự, Manila, dịch vụ file system chia sẻ cho OpenStack, cung có driver để dùng CEPHFS làm backend.
Một tính năng khác có thể sử dụng là copy-on-write cho volumes. Copy-on-write volumes yêu cầu ít tài nguyên và cung cấp khả năng khởi tạo máy ảo nhanh chóng. Máy ảo trên CEph (ephemeral disk nằm trên Ceph) có thể live-migrate. Nó cũng giúp di chuyển máy ảo từ các host bị lỗi.

# 2.Triển khai Ceph
## 2.1 Yêu cầu phần cứng
Việc triển khai Ceph bắt đầu từ việc lên kế hoạch cho phần cứng và mạng. Đây là thách thức đầu tiên-làm sao để đưa ra yêu cầu về dung lượng và hiệu năng (latency, IOPS, throughput), để từ đó chọn ra được kiến trức và thiết bị phù hợp. Tham khảo các lựa chọn sau đây:
- Object Storage Device (OSD)
<ul>
  <li>Server với 6 HDD (ít nhất 2 TB, 7200 rpm)</li>
  <li>1 OSD / 1 HDD</li>
  <li>SSD làm OSD journal</li>
  <li>Ít nhất 2 NIC 10 GbE</li>
  <li>1 core CPU 1 Ghz / 1 OSD</li>
  <li>1 GB RAM / 1 TB lưu trữ OSD</li>
</ul>
- Monitor
<ul>
 <li>Số lượng Server là số lẻ (khuyến nghị 3 Server)</li>
 <li>Mỗi node monitor nằm trên 1 server độc lập</li>
 <li>Ít nhất 16 GB RAM</li>
 <li>Ít nhất 100 GB ổ cứng, sử dụng SSD cho các cluster lớn</li>
</ul>
-Metadata
<ul>
 <li>Ít nhất CPU 4 nhân</li>
 <li>It nhất 16 GB RAM</li>
</ul>

## 2.2 Triển khai Ceph, quản lý và các công cu giám sát
Một thách thức khác là làm sao để chọn ra công cụ thích hợp để triển khai Ceph Cluster, tích hợp nó với OpenStack, sau đó giám sát và quản lý cluster đó. Ceph-deploy là công cụ triển khai mã nguồn mở cho ceph. Một số công cụ troeẻn khai OpenStack từ các vendor cũng cho phép triển khai OpenStack với Ceph. Để giám sát, các tính năng giám sát và tự kiểm tra của Ceph kết hợp với các công cụ
giám sát mã nguồn mở của bên thứ ba, VD như CEPH plugin cho Zabbix hoặc cho Nagios

# 3. Vận hành CEPH
### 3.1 Clock drift và network latency
Cần cài đặt NTP trên các node Ceph, đặc biệt trên các node Monitor

### 3.2 Splitting Placement Groups
Khi thêm OSD vào ceph cluster, tiến trình recovery sẽ kéo dài với một số lượng OSD và số lượng tương tự PG. Giải pháp cho vấn đề này là tăng số PG bằng cách tách nhỏ các PG đang có. Ceph cho phép tăng số lượng PG bằng cácg update các thông của pool. Cách tốt nhất là tăng số lượng PG qua những lần tăng nhỏ.

### 3.3 Mật độ lưu trữ thấp
Mặc định, cơ chế nhân bản của Ceph là 3, có nghĩa mỗi object được sao chép trên nhiều đĩa. Để giảm số lượng nhân bản xuống dưới 3, bạn có thể sử dụng erasure code (per pool), kết hợp với SSD caching pool.
Erasure code cho phép chia object ban đầu thành N chunk nhỏ, kết hợp dữ liệu gốc với dữ liệu được tính tính toán. các object sau khi chuyển đoỏi sẽ chứa duy nhất N + K chunk (so sách với 3 * N khi sử dụng replication pool); cần số lượng N chunk để hkôi phục dữ liệu. Lưu ý rằng để đảm bảo mật độ lưu trữ khi sử dụng erasure coding, bạn cần sử dụng thêm caching pool để hỗ trợ việc ghi xuống các object. Và cũng cầnbổ xung thêm CPU và RAM cho erasure coded pool. Erasure code phát huy ưu điểm với backkup và lưu trữ dữ liệu ít sử dụng, khi hiệu năng đọc/ghi không cần tốt nhất,
Tuy nhiên, erasure code không nên dùng với RBD

### 3.4 Ưu tiên dữ liệu cục bộ
Trong Ceph, primary OSD phục vụ việc đọc và ghi khi một object được yêu cầu. Tuy nhiên, cần đảm bảo rầng primary OSD được đặt trên cùng một rack hoặc DC với client. Ceph cho phép sử dụng tính năng primary OSD affinity để thực hiện điểu này. Mặc định, bất cứ OSD nào cũng có thể được chon là primary và tât cả OSD có primary ratio  là 1.0. Nếu priamry ratio giảm về 0, OSD sẽ không thể trơ thành primary OSD

### 3.5 Bucket hierarchy 
Crush map trong Ceph cluster liệt kê các node vật lý khả dụng và các thiết bị lưu trữ của nó. CRUSH map cũng bao gồm một hạ tầng lưu trữ được định nghĩa trước, Bucket mặc định gồm server, rack, row và site. Có thể thêm nhiều bucket vào hierarchy để mô phỏng hạ tầng DC thực tế. Bạn cũng có thể định nghĩa các policy cho việc backup dựa trên các bucket khả dụng trong CRUSH map

# 4. Ceph Troubleshooting
Đê khởi động cluster sau khi restart:
 1. Đảm bảo kết nối mạng giữa các node
 2. Bật các node monitor
 3. Chờ quorum được thiết lập
 4. Khởi động các OSD

Lưu ý: trạng thái peering có thể mất thời gian ở các cluster lớn. Bạn có thể tăng heartneat interval, heartbeat timeout và OSD report timeput cho các cluster này

## 4.1 Vấn đề với OSD
Nếu cluster có vấn đề, Ceph status sẽ có các thông tin sau:
 - Trạng thái hiện tại của OSD (up/down và out/in)
 - OSD gần đặt tới hạn dung lượng (near full/full)
 - Trạng thái hiện thời của PG

### 4.1.1 Ceph gần hết dung lượng
Trạng thái warning và error có thể xem thông qua các câu lệnh 'ceph -s' và 'ceph health'.Dung lượng OSD được xem bằng lệnh 'ceph osd df'. Khi một OSD gần tới ngưỡng đầy (mặc định là 95%), nó sẽ tạm dừng tât cả lệnh ghi xuống, trong khi lệnh đọc vẫn được thực thi. Giải pháp là thêm các OSD (hoặc giải pháp tạm thời là thay đổi CRUSH map, thay đổi weight chọn OSD)

### 4.1.2 OSD hết dung lượng
Dùng 'ceph osd out [osd-id]' để OSD ngừng ghi dữ liệu vào OSD đó

### 4.1.3 Mất OSD journal
Khi một OSD journal bị lỗi, tất cả OSD dùng journal lỗi đó cần được gỡ khỏi cluster

### 4.1.4 Stale PG 
Khi tất cả các OSD có các bản copy của một PG nào đó bị down và roi vào trạng thái out, PG đó bị đánh dấu là stale. Để giải quyết tình trạng này cần phải có ít nhất 1 OSD chứa bản copy của PG, nếu không PG đó coi như mất.

## 4.2 Vấn đề với Monitor
Khi một node Monitor lỗi, gỡ ra khỏi cluster và thêm một node mới

# 5. Hiệu năng của Ceph
Hiệu năng của Ceph phụ thuộc nhiều yếu tó, gồm cấu hình một node đơn lẻ và cấu trúc của Ceph cluster. Cấu hình sai hoặc không tối ưu sẽ đãn tới viẹc đọc ghi dữ liệu/journal chậm, OSD không trả lời, backfill và recovery chậm, do đó đạt hiệu năng tối ưu cho Ceph là 1 thách thức

## 5.1 Lưu trữ
<ul>
<li>Dùng các ổ riêng biệt cho OS, OSD data và OSD journal</li>
<li>Dùng SSD cho OSD journal. Có thể dùng nhiều journal trêm 1 SSD , nhưng đảm bảo SSD không bị thắt cổ chai. Đảm bảo tỉ lệ truyền dữ liệu và IOPS trên SSD đáp ứng yêu cầu. Cần chú ý rằng khi SSD bị lỗi, toàn bộ OSD đặt journal trên SSD đó sẽ không thê sử dụng được. Không đặt quá 5-6 OSD journal trên 1 SSD.</li>
<li>Không chạy nhiều OSD trên 1 disk</li>
<li>Càng dùng nhiều OSD node, hiệu năng trung bình càng cao</li>
</ul>

## 5.2 Filesystem
Ceph hỗ trợ btrfs, XFS và ext4. Tuy nhiên không nên dùng btrfs để production vì các vấn đề liên quan đến tính ổn định. Ceph sử dụng Extended Attribute (XATTRs) của filesystem để chứa trạng thái object và metadata. Ext4 bị giới hạn ở xattr metadata, do đó XFS được ưu tiên sử dụng

## 5.3 Placement Groups
Tổng số lượng PG có thể ảnh hưởng đến hiệu năng của Ceph cluster. Nếu số PG quá lớn, cluster sẽ tiêu tốn quá nhiều tài nguyên CPU và RAM. Nếu số PG quá nhỏ, việc recovery sẽ tốn nhiều thời gian
Cần tìm ra số PG phù hợp ở 2 mức sau:
- Mức cluster (tổng)
- Mức pool (PG cho pool)
Số PG được đê xuất cho mối OSD là 100-200

## 5.4 RAM/CPU
Không nên cài OSD trên cùng 1 node với các dịch vụ khác, VD là nova-compute. OSD balance, backfill và recovery tiêu tốn rất nhiều tài nguyên CPU và RAM, do đó server có thể bị quá tải

## 5.5 Network
- Dùng đường mạng riêng biệt cho các lưu lượng replication và client  
- Dùng đường 10 GbE

## 5.6 RADOS Gateway
RADOS Gateway có thể là một nút thắt cổ chai cho OpenStack cloud. Giải pháp là sử dụng nhiều radosgw kết hợp với load balancing


