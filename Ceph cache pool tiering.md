# Ceph cache pool tiering: hê thống cache phân tán và có thể mở rộng
Ceph, trong phiên bản Firefly đã lần đầu giới thiệu một cơ chế cache mới là cache pool tiering.

## 1 Giới thiệu Cache pool Tiering
Các giải pháp cache như Flashcache, bcache, hay fatcache đã trở nên rất phổ biến. Tuy nhiên, nhược điểm chính của các hệ thống này là chúng quá phức tạp để triển khai và duy trì bảo dưỡng. Các hệ thống cache này giúp tăng hiệu năng đáng kể, tuy nhiên việc vận hành chúng quả là kinh khủng.
Cache pool trong Ceph mang tới khả năng giãn nở và phân tán cho cache. Một vài mode có thể cấu hình như sau:
 - Read-write pool (hay writeback): đặt cache pool ở phía trước pool dữ liệu đã có trước đó. Luồng ghi sẽ ghi vào cache pool và ngay lập tức gửi ack tới client. Sau đó *flush* dữ liệu vào data pool theo các policy được định nghĩa trước.
 - Read-only pool, độ nhất quán thấp: Có 1 data pool và thêm một hoặc nhiều cache pools. Ta copy dữ liệu vào cache pool để đọc. Lệnh ghi được đưa thẳng vào data pool. Các dữ liệu cũ hết hạn trên cache pool dựa theo các policy được định nghĩa trước.

 Như các giải pháp cache khác, cache pool có các thông số để tuning, VD như cache size (số lượng object hoặc kích thước), thời gian lưu trữ dữ liệu trên cache, tỉ lệ cache cũ.

## 2 Giải pháp thiết kế
![ceph-openstack](http://image.prntscr.com/image/08045be4a6064497ae107368af14ace9.png)
### Mô tả thiết kế
 - Các node Controller được cài đặt Ceph Monitor daemon.
 - Các node Compute được đặt các SSD làm cache, dữ liệu 'nóng' sẽ được đặt trên 2 lớp cache là RBD cache và SSD cache pool để phục vụ việc đọc liên tục, trong khi dữ liệu được ghi xuống data pool. SSD cache pool sẽ không được sao chép nhiều phiên bản, hoặc chỉ sao chép giữa các local SSD. Việc bổ xung tài nguyên tính toán đon giản là chỉ cần thêm các node Compute với SSD cache.
 - Dữ liệu 'nguội' (ít được truy xuất) sẽ được ghi lên Data pool, bao gồm các Server chứa các SATA disk dung lượng lớn, pool này sử dụng Erasure code để tiết kiệm tài nguyên, vì không cần tốc độ truy xuất cao, chỉ cần dung lượng lớn. Các dữ liệu được truy xuất nhiều sẽ được đẩy ngược lên SSD cache pool (tùy theo policy cấu hình).

Mục đích của thiết kế:

 - **Khả năng mở rộng**: Tất cả compute và storage nodes đều có thể mở rộng theo chiều ngang. Nếu cần thêm tài nguyên, chỉ cần bổ xung thêm Server.
 - **Tính đãn hồi và sẵn sàng**: giống như các pool khác trong ceph cả Cache pool và Erasure code pool đểu có thể phân tán trên nhiều Server.
 - **Lưu trữ tốc độ cao**: với cơ chế cache này có thẻ đạt được hiêu năng rất cao, bằng cách đặt SSD trên các compute node, ta có thể kiểm soát IO ởm ức hypervisor. Việc này cho phép cache hit tại local, giúp giảm đáng kể latency.
 - **Lưu trữ mật độ cao giá thành thấp **: Khi đặt các dữ liệu "nóng" trên cache pool. Dữ liệu nóng được luân chuyển thường xuyên từ cachl tới data pool, ở đây data pool được gọi là dữ liệu "nguội". Pool này được cấu hình erasure code. Nhờ erasure code, ta có thể lưu trữ dữ liệu hiệu quả hơn và tiết kiệm tài nguyên hơn nhờ vào các thông số cài đặt trên erassure pool.
 Ở đây ta sử dụng các ổ đĩa SATA dung lượng lớn.
 - **Dễ dàng trong quản trị **: Mô hình này giúp việc quản trị rất đơn giản.

 Tham khảo:
 http://www.sebastien-han.fr/blog/2014/06/10/ceph-cache-pool-tiering-scalable-cache/

