# Tối ưu dung lượng Ceilometer MongoDB
*Chú ý:*
 - Hướng dẫn sau thực hiện trên phiên bản OpenStack Mitaka

## 1. Vấn đề
Ceilometer chia các thông tin thu thập làm 2 loại:
 - metric: đây là các thông số của các máy ảo được thể hiện dạng datapoint, được thu thập thông qua các cơ chế polling (đẩy từ host giám sát) hoặc consuming (lấy từ message queue của OpenStack).
 - event: đây là thông tin về trạng thái của các resource (tài nguyên) tại từng thời điểm, vd: tạo, sửa, xóa máy ảo.

 Danh sách các metric đang lưu trữ:
  - Các metric của disk
	- "disk.read.bytes"
	- "disk.read.requests"
	- "disk.write.bytes"
	- "disk.write.requests"
	- "disk.device.read.bytes"
	- "disk.device.read.requests"
	- "disk.device.write.bytes"
	- "disk.device.write.requests"

  - Các metric của cpu
  	- cpu_util
  	- cpu_delta

  - Các metric của network
  	- "network.incoming.bytes"
  	- "network.incoming.packets"
  	- "network.outgoing.bytes"
  	- "network.outgoing.packets"

  - Các metric của image
  - Các metric của volume

 Danh sách các event đang lưu trữ
  - event của máy ảo: tạo, sửa, xóa, update
  - event của volume
  - event của image
  - event của keystone
  - event của network

  Danh sách chi tiết:
  https://docs.openstack.org/admin-guide/telemetry-measurements.html

 Ceilometer hiện đang lưu toàn bộ các thông tin thu thập được, cả metric và event tại MongoDB.

 ### 1.1. Policy

 Đối với metric:
  - Thời gian lấy mẫu là 1 phút/lần.
  - Thời gian lưu trữ metric là 30 ngày.

 Đối với event:
  - Chỉ thu thập khi xuất hiện event.
  - Thời gian lưu trữ là 30 ngày.

Qua khảo sát, nhận thấy thời gian dung lượng Mongo tăng lên theo 4.3GB/ngày, với số lượng máy ảo là 168 máy.
![Dungluongtang](../images/MongoDB_2.png)

![Soluongmayao](../images/MongoDB_1.png)

Tạm tính dung lượng cho một máy là: 4.300/168 = 26MB/1máy/1ngày với thời gian lấy mẫu là 10p/lần.

## 2. Giải pháp
Như vậy, với 30GB, ta có thể lưu trữ lượng metric trong vòng ~8 ngày.



