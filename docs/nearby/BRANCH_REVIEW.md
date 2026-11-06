# Tổng kết để review nhánh Nearby Connections

**Nhánh:** `codex/feature-nearby-connections` (tách từ `main` tại `4db4744`)

**Ngày cập nhật:** 06/11/2026

**Trạng thái:** bản thử plugin đã kết nối hai điện thoại thật; chế độ chơi qua Nearby chưa được tích hợp vào game phát hành.

## Mục tiêu

Xây dựng lớp kết nối thiết bị gần nhau có thể dùng lại cho nhiều game Godot hoặc ứng dụng Android. Sau khi kiểm chứng transport, game Bầu Cua sẽ dùng một máy làm host quyết định kết quả, tối đa ba máy khách, cùng chơi một trận năm lượt. Chế độ chơi cùng máy hiện tại vẫn độc lập.

## Những gì đã có trên nhánh

| Phần | Kết quả hiện tại |
| --- | --- |
| `nearby-core` | Thư viện Kotlin Android độc lập với Godot và Bầu Cua: advertise, discover, so mã xác thực, accept/reject, gửi bytes tối đa 16 KiB, stop/disconnect, kiểm tra quyền và Play services. |
| `godot-bridge` và `addons/godot_nearby` | Godot Android plugin v2 cùng GDScript facade; AAR debug/release đã được đóng gói trong addon. |
| Hai demo độc lập | Một dự án Godot và một ứng dụng Kotlin dùng chung `service_id` thử nghiệm; không dùng package hoặc asset game. |
| `PartyMatch` | Luật năm lượt và điểm của chế độ chơi cùng máy đã được tách khỏi giao diện, chuẩn bị để dùng chung với adapter Nearby. |
| Tài liệu | [Kiến trúc](ARCHITECTURE.md), [backlog](TASKS.md), [tiến độ và bằng chứng](PROGRESS.md), hướng dẫn build trong `plugins/nearby-connections/README.md`. |

Các commit chính: `98d2951` chốt mục tiêu; `bf9a76a` tạo transport/addon; `a543449` tách luật trận; `6d41146` sửa lỗi phát hiện qua kiểm thử hai máy. Commit `719c915` chỉ bổ sung metadata import của ảnh đã có để project Godot tái lập được.

## Kiểm chứng thực tế

- Android 15 chạy demo Godot làm host; Android 11 chạy demo Kotlin làm guest. Cả hai điện thoại đã cài APK thử mới, còn nguyên game đã phát hành và bản dev.
- Host quảng bá phòng; guest tìm thấy phòng. Hai máy hiện cùng mã xác thực và kết nối thành công (`status 0`).
- `PING` và `ECHO` đã truyền được theo cả hai chiều. Guest dừng thì host quay về trạng thái quảng bá, guest quay về `IDLE`; tìm lại phòng không tạo nút trùng.
- Host từ chối một yêu cầu kết nối: hai máy trả `8004`, hộp xác nhận ở guest đóng. Yêu cầu kế tiếp vẫn kết nối và gửi payload thành công.
- Đã sửa lỗi signal Godot nhận boxed `Boolean`/`Int`; bỏ giới hạn phiên bản cho quyền Wi-Fi state sau khi Android 15 trả `SDK_8032`; giữ mã lỗi SDK để chẩn đoán; loại callback ngắt lặp.
- Build AAR debug/release, build Android demo và export Godot APK debug thành công. Chi tiết kiểm thử ở [PROGRESS.md](PROGRESS.md).

## Giới hạn và cổng tiếp theo

1. Chưa thử một host với ba guest, nên **chưa đạt cổng Go/No-Go cho bốn người chơi**. Cần thêm hai điện thoại Android thật.
2. Chưa kiểm tra từ chối quyền hệ thống, tắt Bluetooth/Wi-Fi giữa phiên, đảo vai host/guest, timeout và ứng dụng chuyển nền. Các tình huống này thuộc NBY-03/04/06.
3. Chưa có giao thức ván và `PartyNearbyAdapter`, màn hình phòng, đồng bộ kết quả/điểm, xử lý reconnect hoặc rematch. Đây là NBY-09–11.
4. Chưa thay đổi AAB, version code, Data safety hoặc cấu hình Store. Chỉ xem xét phát hành sau QA 2/3/4 máy, rà quyền và chính sách dữ liệu theo NBY-12/13.

**Đề nghị review:** xem ranh giới tái sử dụng của plugin, kết quả kiểm thử hai máy và các rủi ro còn lại. Giữ nhánh này tách khỏi `main` cho đến khi đạt cổng bốn máy và có bản chơi hoàn chỉnh.
