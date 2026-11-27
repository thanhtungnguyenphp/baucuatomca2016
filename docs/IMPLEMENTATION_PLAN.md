# Kế hoạch triển khai native Godot

## Mục tiêu kỹ thuật

Phát triển game mobile native bằng Godot 4.x/GDScript. Bản web được dùng làm
tham chiếu luật chơi và asset, không dùng làm runtime cho app Store.

## Chặng 1 — Foundation và game engine — hoàn thành

- [x] Godot project portrait, renderer Compatibility cho mobile.
- [x] Tách luật chơi thuần thành `RoundResolver`.
- [x] Tạo `GameSession` autoload quản lý số Lộc, cược, combo, thử thách và lịch sử.
- [x] Tách vòng đời ván thành `begin_round()` và `settle_round()` để animation
      luôn trình bày cùng kết quả đã chốt.
- [x] Thêm test tự động cho payout, combo và mission.

## Chặng 2 — Trình diễn native tối thiểu — hoàn thành

- [x] Nhập asset tô, nắp, xúc xắc 3D giả lập và six mascot sheets.
- [x] Tạo `MascotCard.tscn`: thẻ UI hiển thị sprite animation theo từng linh vật.
- [x] Tạo `Bowl.tscn`: tô lắc, mở nắp, lộ ba xúc xắc theo kết quả chốt trước.
- [x] Khóa lựa chọn và nút lắc trong lúc trình diễn một ván.

## Chặng 3 — VFX, âm thanh và cảm ứng — hoàn thành phạm vi Android hiện tại

- [x] Object pool cho confetti native Canvas: node được tạo một lần, tái sử dụng
      sau mỗi ván thắng; tương thích ổn định với renderer Compatibility.
- [x] SFX mixer native: chạm chip, lắc, mở nắp và thắng; âm tạm được tổng hợp
      trong runtime để không đưa asset không rõ quyền vào binary.
- [x] Haptic Android/iOS qua API Godot chuẩn; không cần plugin bên thứ ba.
- [x] Thiết lập cục bộ: tắt rung và giảm chuyển động, lưu bằng `ConfigFile`.

> Khi export Android, cần bật quyền `VIBRATE` trong Android export preset để phản
> hồi rung hoạt động. Hiệu ứng hạt có thể được thay bằng `GPUParticles2D` sau khi
> art direction chốt texture/shape; bản pool hiện tại tránh chi phí instantiate
> lặp và hoạt động an toàn trên máy cấu hình thấp.
> Trước release, thay procedural SFX bằng bộ âm thanh đã mix/master và có quyền sử
> dụng; kiến trúc `AudioDirector` giữ nguyên điểm gọi trong gameplay.

## Chặng 4 — Hoàn thiện sản phẩm mobile — hoàn thành bản Android 1.4.2

- [x] Menu luật chơi, lịch sử ba ván gần nhất và màn hình thiết lập.
- [x] Lưu tiến trình cục bộ qua `ConfigFile`; không dùng tài khoản hay cloud cho V1.
- [x] Onboarding ngắn cho lần mở đầu tiên và nút chủ động xóa tiến trình có xác nhận.
- [ ] Chuyển cơ chế cược sang "dự đoán/lộc xuân" nếu định vị cultural-casual
      nhằm giảm rủi ro phân loại Store.
- [x] Thiết kế icon, splash, store screenshots và Privacy Policy cho Android.

## Chặng 5 — Tối ưu và phát hành — Android đã phát hành, tiếp tục hậu kiểm

- [x] Cache `AtlasTexture` theo frame cho mascot sprite; không tạo texture region
      mới ở mỗi `_process()`.
- [x] Kiểm tra tablet Android và sửa GridContainer bị co chiều rộng mascot card;
      tăng vùng chạm chip, tránh nắp tô che vùng thống kê sau khi reveal; đổi sang
      symbol atlas rõ nét và xử lý Android `go_back_requested` để đóng popup trước
      khi thoát app.
- [ ] Tạo atlas đã nén trên từng nền tảng, đo RAM và APK/AAB size.
- [ ] Profile Android cấu hình thấp và iPhone thật; đặt ngân sách 60 FPS.
- [x] Export/ký Android AAB và phát hành Google Play đến `1.4.2`/code `9`.
- [x] Hoàn tất Google Play metadata, Content rating, Data safety và Advertising ID.
- [ ] Export iOS Xcode archive, ký release và TestFlight.
- [ ] Hoàn thiện crash/ANR triage, update testing và QA Nearby nhiều thiết bị.

Chi tiết các đầu vào thuộc publisher và quy trình release: `RELEASE_CHECKLIST.md`.

## Nguyên tắc bắt buộc

1. `RoundResolver` là nguồn sự thật duy nhất cho kết quả và phần thưởng.
2. Scene/animation không tự quay kết quả hoặc tự tính thưởng.
3. Asset gốc chỉ là đầu vào; trước release phải atlas, nén và profile trên máy thật.
4. Không thêm tiền thật, đổi thưởng hoặc cơ chế mua Lộc khi chưa có quyết định
   sản phẩm/pháp lý riêng.

## Kế hoạch chơi gần nhau (đã tích hợp, đang QA tải lớn)

Thiết kế plugin Nearby Connections tái sử dụng và backlog theo thứ tự ưu tiên nằm trong [`nearby/README.md`](nearby/README.md), [`nearby/ARCHITECTURE.md`](nearby/ARCHITECTURE.md) và [`nearby/TASKS.md`](nearby/TASKS.md). Gameplay dealer host + tối đa năm client, leaderboard, rewarded và countdown 30 giây đã tích hợp và phát hành. Tiến độ/giới hạn kiểm thử nằm trong [`nearby/PROGRESS.md`](nearby/PROGRESS.md); QA 1+3/1+5, reconnect và lifecycle radio/background vẫn thuộc phase tiếp theo.

Tổng hợp bàn giao mới nhất: [`PHASE_HANDOFF_2026-11-27.md`](PHASE_HANDOFF_2026-11-27.md).
