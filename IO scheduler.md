# IO được đối xử như thế nào tại I/O Scheduler
Bài viết được lấy nguồn từ (http://www.ksingh.co.in/blog/2016/06/08/how-application-ios-are-treated-by-i-slash-o-scheduler/)

## FIO và iostat là hai công cụ benchmark ổ đĩa phổ biến, tuy nhiên kết quả từ 2 phép đo này lại không giống nhau. Vậy nguyên do là từ đâu?
Đây là bài đo bởi FIO với bs=4M, seq write

Kết quả ghi được 55 iops

Cùng lúc FIO đang chạy, chúng ta sử dụng công cụ iostat để monitor:

Kết quả nhận được, IOPS ghi là hơn 441

Tại sao lại có sự khác biệt này??

Đây là 2 nguyên nhân:
- I/O scheduler tách  nhỏ các IO > 512k, bất kể là tuần tự hay ngẫu nhiên
- I/O Schueduler gom các IO mà được ghi xuống các vùng liền kề trên ổ đĩa, chỉ đối với seq request.

Nó hoạt động như thế nào??

- Merging xảy ra khi một I/O request gọi xuống một vùng chỉ định hoặc liền kề trên ổ đĩa. Thay vì chuyển request đó, I/O scheduler nhóm request đó vào các request liền kề, giúp làm giảm số lượng request sinh ra.
- Split xảy ra khi IO lớn hơn 512k, I/O scheduler chia IO đó thành các gói nhỏ 512k

Cuối cùng I/O scheduler chọn một request tại 1 thời điểm và chuyển nó xuông block device driver và ghi vào ổ đĩa.

Chứng minh

- FIO phát các IO 4M tới block IO layer, bởi block size > 512k, I/O scheduler cắt nó ra thành 8 gói, mỗi gói là 512k và ghi vào ổ đĩa. Vì việc chia gói này trong suốt với ứng dụng nên FIO không nhận biết được việc này, từ phía FIO vẫn là 4M block size, do đó kết quả là 55 IOPS
- Tuy nhiên, việc ghi thực tế diễn ra ở 512k block size bởi I/O scheduler đã chia cắt IO, do đó kết quả của iostat cao hơn FIO.

