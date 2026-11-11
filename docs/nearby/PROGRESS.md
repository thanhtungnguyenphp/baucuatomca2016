# Tiến độ nhánh Nearby Connections

**Nhánh:** `codex/feature-nearby-connections`

**Trạng thái (11/11/2026):** demo transport đã qua kiểm thử hai máy thật ngày 06/11; chưa tích hợp chế độ chơi Nearby vào game phát hành. Backlog: 3 task hoàn thành, 2 đang kiểm thử biên, 1 chờ đủ bốn thiết bị, 7 chờ phụ thuộc.

## Kiểm tra hiện tại — 11/11/2026

- Nhánh tính năng đồng bộ với `origin`; chưa có thay đổi code mới sau commit chuẩn bị kiểm thử `ca9661f` trước lần cập nhật trạng thái này.
- ADB hiện thấy **một** điện thoại Android 15 (model `23021RAAEG`), chưa thấy điện thoại Android 11 hoặc hai máy bổ sung. Trên máy này Bluetooth, Wi-Fi, Location đều bật; Google Play services và demo Godot Nearby có mặt, các quyền Nearby runtime đã được cấp. Package game phát hành `vn.lamgame.baucuatomca` vẫn có mặt.
- Hai APK demo hiện có là bản build ngày 06/11. Không có lượt kiểm thử hai máy mới trong ngày 11/11; kết quả kết nối bên dưới là bằng chứng của ngày 06/11.
- Bước gần nhất: hoàn tất P1/P2/R1/R2/H1 trong [bảng kiểm NBY-03/04](NBY-04_DEVICE_RUNBOOK.md) khi có hai máy; sau đó NBY-05 cần bốn máy để quyết định Go/No-Go cho 2–4 người.

## Đã thực hiện

- NBY-01: xác lập feature charter, ranh giới giữa `nearby-core`, Godot bridge và luật game; commit mục tiêu đã push trước khi viết code.
- NBY-02: dựng hai Android library, addon Godot v2, demo Godot echo và demo Android/Kotlin không phụ thuộc Godot. AAR debug/release, Android demo debug và Godot demo debug đều build thành công.
- NBY-03: thêm manifest quyền theo API level, xin quyền khi người dùng bấm tạo/tìm phòng, kiểm tra Google Play services và báo lỗi khi thiếu điều kiện. Đã quan sát hộp xin quyền trên Android 15 và cấp quyền thành công. Google Play services 19.3.0 trên máy này trả `SDK_8032` khi `ACCESS_WIFI_STATE` bị giới hạn `maxSdkVersion=32`; bỏ giới hạn cho `ACCESS_WIFI_STATE` và `CHANGE_WIFI_STATE` thì quảng bá phòng thành công. Hai quyền này là normal permissions, không hiện hộp xin quyền riêng.
- NBY-04 (hai máy): đã cài demo Godot trên Android 15 và demo Android thuần trên Android 11. Tạo phòng, tìm phòng, so cùng mã xác thực, chấp nhận, trao đổi `PING`/`ECHO` hai chiều, ngắt và tìm lại phòng đều thành công. Từ chối kết nối trả `8004` cho cả hai phía; hộp xác nhận đóng trên thiết bị còn lại. Đã sửa tín hiệu Godot dùng boxed `Boolean`/`Int`, callback ngắt lặp và danh sách phòng cũ/trùng trong demo.
- NBY-08: rút luật 2–4 người, 5 lượt, lựa chọn và tính điểm ra `PartyMatch`; UI chơi cùng máy dùng model mới. Test PartyMatch, PartyFlow và core rules đều qua.

## Bằng chứng kiểm thử hai máy — 2026-11-06

| Thiết bị | Hệ điều hành | Gói demo | Vai đã thử |
| --- | --- | --- | --- |
| Redmi 23021RAAEG | Android 15 / API 35 | `vn.lamgame.nearby.demo` | Host Godot |
| Redmi 220333QPG | Android 11 / API 30 | `vn.lamgame.nearby.androiddemo` | Guest Kotlin |

- Bluetooth và Wi-Fi đều bật khi thử. Cả hai điện thoại có Google Play services.
- Cùng mã xác thực xuất hiện trên hai máy trước khi chấp nhận; trạng thái chuyển sang `CONNECTED` và mã kết quả `0`.
- Guest gửi `PING`, host nhận và trả `ECHO`; host gửi `PING`, guest nhận và trả `ECHO`.
- Guest dừng: guest về `IDLE`, host về `ADVERTISING` và nhận một sự kiện ngắt. Khởi động tìm phòng lại hiển thị đúng một phòng.
- Host từ chối: hai máy trở lại trạng thái quảng bá/tìm kiếm, mã kết quả `8004`; guest đóng hộp xác nhận. Sau đó thử ghép lại và gửi `PING` thành công.
- Hai APK thử có package riêng. `vn.lamgame.baucuatomca` và `vn.lamgame.baucuatomca.dev` trên cả hai điện thoại không bị gỡ hoặc ghi đè.

## Quyết định kỹ thuật đã kiểm chứng

- Pin `com.google.android.gms:play-services-nearby:19.3.0` cho toolchain Kotlin `2.1.21` hiện tại. Bản `19.4.0` dùng Kotlin metadata `2.3`, bản `19.5.1` dùng metadata `2.4`; nâng SDK cần nâng toolchain Android và kiểm thử export riêng.
- AAR của `nearby-core` không có phụ thuộc Godot. Android demo phụ thuộc trực tiếp core và đã kết nối với Godot demo trên máy thật, xác nhận ranh giới tái sử dụng ở mức build và runtime.
- Hai demo dùng cùng `service_id` kiểm thử `vn.lamgame.nearby.demo`; package ứng dụng có thể khác nhau.

## Chưa xác minh / việc tiếp theo

1. **NBY-03/04:** từ chối quyền Nearby tại hộp hệ thống, tắt Bluetooth/Wi-Fi trong phiên, và thử đảo vai Android 11 host / Android 15 guest. Dùng [bảng kiểm thiết bị thật](NBY-04_DEVICE_RUNBOOK.md) và `plugins/nearby-connections/device-report.sh` để ghi nhận có thể lặp lại; kiểm tra ngày 11/11 ADB chỉ thấy một máy Android 15.
2. **NBY-05:** cần thêm hai Android thật để thử một host và ba guest với `P2P_STAR`, đo thời gian vào phòng và độ ổn định. Chưa thể quyết định Go/No-Go cho chế độ 2–4 người.
3. Sau cổng Go/No-Go: hoàn thiện lifecycle/timeout/retry, tích hợp game protocol và UI phòng, rồi QA quyền riêng tư/Data safety trước khi cân nhắc phát hành.

**Không thực hiện ở giai đoạn này:** build AAB phát hành, tăng version code hoặc gửi bản lên Store.
