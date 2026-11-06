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

## Chặng 3 — VFX, âm thanh và cảm ứng — đang thực hiện

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

## Chặng 4 — Hoàn thiện sản phẩm mobile — cần thực hiện

- [x] Menu luật chơi, lịch sử ba ván gần nhất và màn hình thiết lập.
- [x] Lưu tiến trình cục bộ qua `ConfigFile`; không dùng tài khoản hay cloud cho V1.
- [x] Onboarding ngắn cho lần mở đầu tiên và nút chủ động xóa tiến trình có xác nhận.
- [ ] Chuyển cơ chế cược sang "dự đoán/lộc xuân" nếu định vị cultural-casual
      nhằm giảm rủi ro phân loại Store.
- [ ] Thiết kế icon, splash, store screenshots và Privacy Policy.

## Chặng 5 — Tối ưu và phát hành — cần thực hiện

- [x] Cache `AtlasTexture` theo frame cho mascot sprite; không tạo texture region
      mới ở mỗi `_process()`.
- [x] Kiểm tra tablet Android và sửa GridContainer bị co chiều rộng mascot card;
      tăng vùng chạm chip, tránh nắp tô che vùng thống kê sau khi reveal; đổi sang
      symbol atlas rõ nét và xử lý Android `go_back_requested` để đóng popup trước
      khi thoát app.
- [ ] Tạo atlas đã nén trên từng nền tảng, đo RAM và APK/AAB size.
- [ ] Profile Android cấu hình thấp và iPhone thật; đặt ngân sách 60 FPS.
- [ ] Export Android AAB và iOS Xcode archive, ký release.
- [ ] Internal test, crash triage, App Store/Google Play metadata.

Chi tiết các đầu vào thuộc publisher và quy trình release: `RELEASE_CHECKLIST.md`.

## Nguyên tắc bắt buộc

1. `RoundResolver` là nguồn sự thật duy nhất cho kết quả và phần thưởng.
2. Scene/animation không tự quay kết quả hoặc tự tính thưởng.
3. Asset gốc chỉ là đầu vào; trước release phải atlas, nén và profile trên máy thật.
4. Không thêm tiền thật, đổi thưởng hoặc cơ chế mua Lộc khi chưa có quyết định
   sản phẩm/pháp lý riêng.

## Kế hoạch chơi gần nhau (chờ duyệt)

Thiết kế plugin Nearby Connections tái sử dụng và backlog theo thứ tự ưu tiên nằm trong [`nearby/README.md`](nearby/README.md), [`nearby/ARCHITECTURE.md`](nearby/ARCHITECTURE.md) và [`nearby/TASKS.md`](nearby/TASKS.md). Chưa triển khai tính năng trong game.
