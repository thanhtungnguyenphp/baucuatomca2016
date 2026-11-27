# Bàn giao phase hiện tại — 27/11/2026

## Trạng thái phát hành

- Android production: `vn.lamgame.baucuatomca`.
- Bản mới nhất: `1.4.2`, version code `9`, min SDK `24`, target SDK `36`.
- AAB release đã ký, kiểm tra ZIP/chữ ký/manifest và đã được phát hành thành công trên Google Play.
- Bản cài thử dùng package riêng `vn.lamgame.baucuatomca.dev`; không cài APK production ký cục bộ đè lên bản Google Play vì hai bản có thể dùng chứng thư khác nhau.
- AAB mới nhất được giữ cục bộ tại `export/android/bau-cua-tom-ca-release.aab`; thư mục `export/` không commit.

## Đã hoàn thành

### Game và mobile UX

- Luật chơi, payout và trạng thái ván có model/test độc lập; UI không tự sinh hoặc sửa kết quả.
- Màn hình Modern Tết responsive, header/menu, HUD, tô hero, lưới 3×2, popup chọn mệnh giá và CTA Nearby nổi bật.
- Tooltip lắc/đậy gọn; hào quang sắc nét; overlay kết quả ba giây và reaction trúng/hụt cho sáu linh vật.
- Onboarding một lần, popup mobile, âm thanh/rung, reduced motion, lịch sử, Hành trình và lưu cục bộ.
- Splash và adaptive icon Android nền đỏ Tết, loại bỏ nền trắng mặc định.

### Quảng cáo và quyền riêng tư

- AdMob banner, interstitial và rewarded production ID đã cấu hình; debug dùng test ID.
- UMP consent và Privacy options đã tích hợp; banner anchored adaptive chỉ dành vùng khi native ad tải thành công.
- Privacy Policy/Data safety/Advertising ID/Content rating đã được publisher hoàn thành để phát hành Google Play.

### Chơi gần nhau

- Google Nearby Connections `P2P_STAR`, protocol v4, một dealer host và tối đa năm client.
- Host không đặt cược; client đặt nhiều cửa, xác nhận cược, nhận payout và leaderboard authoritative.
- Tên người chơi, lobby kiểu MOBA, hàng đợi xác nhận mã, countdown 30 giây, spectator/rewarded và rematch đã có code/test.
- Luồng hai thiết bị đã chơi đủ năm lượt và rematch trên máy thật; mô phỏng headless đã phủ một host + năm client.

### Build và Store

- Android SDK/JDK/Gradle template, debug APK và release AAB có quy trình tái lập.
- Google Play production đã phát hành đến `1.4.2 (9)`.
- Lỗi cập nhật trên thiết bị phát triển được xác định là bản production từng sideload bằng upload key; gỡ và cài lại từ Play chuyển thiết bị về app-signing key của Google. Không phải migration code của game.

## Chưa hoàn thành — backlog phase kế tiếp

### P0 — độ ổn định phát hành

1. Chạy ma trận update thật từ một bản cũ cài qua Google Play/Internal testing lên bản mới; không dùng APK production sideload.
2. QA Nearby 1 host + 2/3 client vào gần đồng thời, từ chối một mã, rời trước khi bắt đầu và chơi đủ năm lượt/rematch.
3. QA tải lớn nhất 1 host + 5 client, client thứ sáu vào phòng đầy, background/foreground, tắt radio và mạng yếu.
4. QA rewarded lifecycle khi client hết Lộc: earned/cancel/fail/offline, không mất phòng và không cộng hạng sai.

### P1 — chất lượng

1. Profile FPS/RAM/cold start trên Android cấu hình thấp; thử 20 ván liên tiếp và theo dõi leak/spike.
2. Kiểm tra TalkBack, tương phản, cỡ chữ lớn, notch/gesture/3-button navigation và bàn phím.
3. Chốt quyền sử dụng art/SFX; thay âm procedural bằng bộ âm thanh master có license.
4. Tối ưu texture atlas/ETC2-ASTC sau khi đo chất lượng và kích thước tải từ Play.
5. Hoàn thiện reconnect/snapshot để client có thể quay lại đúng ghế thay vì kết thúc phòng.

### P2 — nền tảng và tăng trưởng

1. Đóng gói `nearby-core`/`godot-nearby` thành addon versioned và thử trong một dự án Godot trống.
2. Xây pipeline crash/ANR và theo dõi hiệu quả quảng cáo/retention theo chính sách dữ liệu đã công bố.
3. iOS: Bundle ID, Apple Team, Xcode export, safe area, TestFlight và bridge Nearby tương đương nếu tiếp tục hỗ trợ chơi gần nhau.

## Điều kiện bắt đầu phase mới

- `main` sạch và đồng bộ `origin/main`.
- Toàn bộ 22 entrypoint test tự động đạt và AAB release cuối không lỗi.
- Giữ đúng ranh giới package: DEV qua ADB, production chỉ qua Google Play hoặc artifact do Play ký.
- Backlog mới phải tham chiếu tài liệu này và không đánh dấu QA nhiều thiết bị hoàn thành nếu chưa có bằng chứng máy thật.
