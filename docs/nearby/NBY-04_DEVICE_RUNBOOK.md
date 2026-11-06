# NBY-03/04: kiểm thử biên trên hai điện thoại Android

Chạy trên hai máy thật đã cài APK demo Godot và Kotlin. Ghi lại model, API, phiên bản Google Play services, trạng thái radio và quyền trước mỗi kịch bản. Script `plugins/nearby-connections/device-report.sh` chỉ đọc trạng thái; có thể truyền số serial ADB hoặc để trống để đọc mọi máy đã được cấp quyền USB.

## Chuẩn bị

1. Kết nối hai điện thoại, mở khóa và chấp nhận USB debugging. `adb devices -l` phải hiện trạng thái `device` cho cả hai.
2. Chạy `plugins/nearby-connections/device-report.sh` và xác nhận cả hai có Google Play services. APK thử dùng `vn.lamgame.nearby.demo` và `vn.lamgame.nearby.androiddemo`. Không gỡ `vn.lamgame.baucuatomca` hay bản dev.
3. Bật Bluetooth, Wi-Fi và Location trên cả hai máy để có baseline. Mở hai demo; dùng cùng `service_id` `vn.lamgame.nearby.demo` và topology `STAR`.

## Kịch bản còn thiếu

| ID | Thao tác | Kết quả cần quan sát |
| --- | --- | --- |
| P1 | Trên Android 15, gỡ quyền Nearby devices của demo Godot trong Settings; bấm **Tạo phòng**, từ chối hộp xin quyền. | Demo không vào `ADVERTISING`, hiển thị quyền còn thiếu; game Bầu Cua đã phát hành vẫn mở được. Cấp lại quyền rồi thử tạo phòng. |
| P2 | Trên Android 11, gỡ quyền Location của demo Kotlin; bấm **Tìm phòng**, từ chối. | Demo không vào `DISCOVERING`, nêu quyền còn thiếu; cấp lại quyền rồi tìm phòng thành công. |
| R1 | Khi chưa kết nối, tắt Bluetooth trên host, thử tạo phòng; bật lại rồi thử tiếp. Lặp với Wi-Fi và Location từng cái một. | Ghi trạng thái/mã lỗi thực tế. Nearby có thể dùng radio khác, nên không mặc định coi việc một radio tắt là lỗi nếu kết nối vẫn hoạt động. |
| R2 | Khi hai máy đang `CONNECTED`, tắt rồi bật Bluetooth, sau đó Wi-Fi từng cái một. | Ghi thời gian ngắt hoặc chuyển transport, trạng thái hai bên và khả năng ghép lại. Không để UI kẹt ở `PAIRING`/`CONNECTED` khi kết nối đã mất. |
| H1 | Đảo vai: Android 11 **Tạo phòng**, Android 15 **Tìm phòng**; so mã, xác nhận cả hai, gửi `PING`/`ECHO` hai chiều. | Cả hai vào `CONNECTED`, payload hai chiều đúng; dừng guest và tìm lại phòng không trùng mục. |

Với mỗi trường hợp, ghi **thời điểm, model/API, quyền/radio trước và sau, trạng thái trên cả hai máy, mã lỗi SDK, ảnh chụp màn hình**. Nếu bị từ chối quyền vĩnh viễn, kiểm tra lối vào Settings và cách quay lại demo. Không dùng kết quả emulator để kết luận độ ổn định Bluetooth/Wi-Fi.

## Điều kiện kết thúc NBY-04

Các trường hợp P1, P2, R1, R2, H1 được ghi nhận và lỗi phát hiện được sửa hoặc có giới hạn rõ ràng. Sau đó thử NBY-05 với bốn máy thật: một host, ba guest, mỗi guest nhận payload, đo thời gian vào phòng và tỷ lệ ngắt. Chưa tích hợp vào game hay build Store trước khi qua cổng này.
