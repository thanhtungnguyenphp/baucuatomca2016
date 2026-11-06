# Nearby Connections: kế hoạch plugin dùng lại

**Trạng thái:** tài liệu đề xuất để duyệt, chưa triển khai plugin hoặc sửa game.  
**Ngày:** 06/11/2026.  
**Ứng dụng tham chiếu:** Bầu Cua Tôm Cá — Lộc Xuân, Godot 4.7.1, Android.

## Quyết định đề xuất

Xây dựng **Google Nearby Connections** theo mô hình một máy chủ phòng và tối đa ba máy khách. Đây là API truyền dữ liệu trực tiếp giữa thiết bị gần nhau; nó tự chọn Bluetooth, BLE hoặc Wi‑Fi và không cần kết nối Internet để chơi. “Nearby devices” là nhóm quyền Android, không phải tên giao thức truyền tải. Giải pháp cần **Google Play services** trên máy Android. Chế độ chơi cùng một máy hiện có tiếp tục hoạt động độc lập.

Thiết kế thành hai gói tách biệt:

1. `nearby-core`: thư viện Android/Kotlin, chỉ quản lý khám phá thiết bị, xác thực kết nối, trao đổi bytes và vòng đời kết nối. Không chứa Godot, luật game hay giao diện.
2. `godot-nearby`: Godot Android plugin v2 và GDScript facade, chuyển API/sự kiện của `nearby-core` sang Godot. Game khác có thể dùng gói này; ứng dụng Android thường có thể dùng trực tiếp `nearby-core`.

Mỗi ứng dụng cấp `service_id` riêng khi chạy. Plugin không gắn cứng package `vn.lamgame.baucuatomca`, tên game, asset, AdMob hay cấu trúc màn hình. Giao thức và luật chơi Bầu Cua thuộc ứng dụng sử dụng plugin.

## Phạm vi bản đầu

- Android, Godot 4.7.x, 2–4 thiết bị, topology `P2P_STAR`, một host quyết định trạng thái ván.
- Gửi `BYTES` payload nhỏ; không chuyển file/stream.
- Vào phòng, xác nhận mã xác thực kết nối, chơi năm lượt, xem điểm, chơi lại hoặc rời phòng.
- Thiết bị không hỗ trợ Nearby vẫn chơi được chế độ cục bộ.
- Bản đầu không cần tài khoản, máy chủ Internet, ghép trận từ xa hoặc giao dịch giá trị thật.

## Điểm cần quyết định trước khi viết code

1. Chấp nhận phụ thuộc Google Play services, đồng nghĩa máy Android không có dịch vụ này sẽ không dùng được chơi gần nhau.
2. Chấp nhận Nearby Connections có thể dùng Wi‑Fi dù tên tính năng hiển thị là “Chơi gần nhau”; không hứa “chỉ Bluetooth”.
3. Chấp nhận cập nhật chính sách quyền riêng tư và Data safety trước khi phát hành, vì Google cho biết Nearby SDK thu thập một số dữ liệu sử dụng và thiết bị.
4. Xác nhận quy tắc sản phẩm: tối đa bốn người, năm lượt, host rời thì kết thúc phòng, không vào giữa ván.

Xem [kiến trúc](ARCHITECTURE.md) và [backlog theo ưu tiên](TASKS.md).

## Tài liệu chính thức

- [Nearby Connections: tổng quan](https://developers.google.com/nearby/connections/overview)
- [Nearby Connections: chiến lược kết nối](https://developers.google.com/nearby/connections/strategies)
- [Nearby Connections Android: cài đặt và quyền](https://developers.google.com/nearby/connections/android/get-started)
- [Godot 4.7: Android plugin v2](https://docs.godotengine.org/en/4.7/tutorials/platform/android/android_plugin.html)
