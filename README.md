# Bầu Cua Tôm Cá: Lộc Xuân — Godot native

Nền móng mobile native sử dụng **Godot 4.x + GDScript**. Dự án này độc lập với
prototype web và đặt song song với thư mục web cũ.

## Chạy dự án

1. Mở `project.godot` bằng Godot 4.x.
2. Chọn **Run Project**. Scene khởi động là `scenes/Main.tscn`.
3. Trên desktop: chọn mệnh giá, chọn linh vật, sau đó chạm tô hoặc nhấn Space.

Kiểm tra luật chơi bằng terminal:

```sh
godot --headless --path . --script res://tests/run_core_tests.gd
```

## Cấu trúc

- `scripts/core/`: luật chơi thuần GDScript; không phụ thuộc UI/animation.
- `scripts/ui/`: điều phối input, popup và vòng đời trình diễn của ván chơi.
- `scripts/presentation/`: trình diễn tô/xúc xắc, sprite linh vật và hiệu ứng.
- `scenes/`: các scene Godot; `Main.tscn` là màn hình chơi native.
- `assets/art/`: asset tham chiếu đã nhập từ prototype để dựng bản native; phải
  kiểm tra quyền và tối ưu atlas trước release.
- `resources/`: cấu hình linh vật/combo/âm thanh bằng Godot Resource ở pha kế tiếp.
- `tests/`: kiểm tra tự động các công thức trả Lộc, combo và thử thách.

`RoundResolver` nhận cược và kết quả, rồi trả một summary bất biến cho UI. Khi
thêm tô/xúc xắc 2.5D hoặc 3D, animation phải nhận summary đã chốt này để hình
ảnh không bao giờ mâu thuẫn với phần thưởng.

## Trạng thái hiện tại

- Android production `vn.lamgame.baucuatomca`, bản mới nhất `1.4.2`/code `9`
  đã phát hành trên Google Play.
- Portrait responsive, renderer Compatibility; đã kiểm tra tự động trên
  720×1650, 1080×1920 và 1080×2400.
- Logic cược, trả thưởng, combo, thử thách ba ván; `RoundResolver` thuần có test.
- Tô, nắp, xúc xắc và sáu mascot motion sheets đã được trình diễn native.
- Lịch sử ba ván, tiến trình và thiết lập lưu cục bộ qua `ConfigFile`.
- Âm thanh phản hồi native, rung, giảm chuyển động và hiệu ứng confetti tái sử dụng (không
  instantiate node hiệu ứng trên mỗi ván).
- Onboarding một lần, luật chơi, popup mobile và xác nhận trước khi xóa tiến trình.
- AdMob/UMP và Google Nearby Connections: một dealer host + tối đa năm client,
  countdown 30 giây, payout và leaderboard authoritative.

## Bước tiếp theo

1. QA Nearby 1+3 và 1+5 thiết bị thật, gồm disconnect/background/radio yếu.
2. Test update qua Google Play/Internal testing, rewarded lifecycle và 20 ván liên tiếp.
3. Profile FPS/RAM/cold start, accessibility và các chế độ thanh điều hướng Android.
4. Chốt license art/SFX và tối ưu texture atlas/ETC2-ASTC theo số đo thực tế.
5. Chuẩn bị phase iOS/plugin tái sử dụng sau khi các gate Android đạt.

Xem [checklist phát hành](docs/RELEASE_CHECKLIST.md) trước khi tạo AAB hoặc
Xcode archive. Khóa ký và định danh Publisher không được lưu trong source.

## Android

- Package ID: `vn.lamgame.baucuatomca`.
- Preset **Android Debug APK** dành cho cài thử nội bộ.
- Preset **Google Play AAB** dùng Gradle cho Play Store. Điền keystore release
  trong Godot Export trước khi export AAB; tuyệt đối không thêm khóa vào source.
- Xem [hướng dẫn build Android](docs/ANDROID_BUILD.md) để build APK/AAB và xác
  minh manifest.
- Artifact không được commit. Bản DEV dùng package `vn.lamgame.baucuatomca.dev`;
  production chỉ cài từ Google Play hoặc artifact do Play ký để tránh xung đột chữ ký.

Xem [bàn giao phase ngày 27/11/2026](docs/PHASE_HANDOFF_2026-11-27.md) để biết
phần đã hoàn thành, backlog còn lại và điều kiện bắt đầu phase tiếp theo.
