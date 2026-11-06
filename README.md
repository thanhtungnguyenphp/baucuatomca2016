# Bầu Cua Tôm Cá — Godot native

Nền móng mobile native sử dụng **Godot 4.x + GDScript**. Dự án này độc lập với
prototype web và đặt song song với thư mục web cũ.

## Chạy dự án

1. Mở `project.godot` bằng Godot 4.x.
2. Chọn **Run Project**. Scene khởi động là `scenes/Main.tscn`.
3. Trên desktop: chọn chip, chọn linh vật, sau đó bấm **LẮC TÔ** hoặc Space.

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

## Phạm vi setup hiện tại

- Portrait 1080×1920, responsive bằng canvas stretch và renderer Compatibility.
- Logic cược, trả thưởng, combo, thử thách ba ván; `RoundResolver` thuần có test.
- Tô, nắp, xúc xắc và sáu mascot motion sheets đã được trình diễn native.
- Lịch sử ba ván, tiến trình và thiết lập lưu cục bộ qua `ConfigFile`.
- Âm thanh phản hồi native, rung, giảm chuyển động và hiệu ứng confetti tái sử dụng (không
  instantiate node hiệu ứng trên mỗi ván).
- Onboarding, luật chơi và xác nhận trước khi xóa tiến trình.

## Bước tiếp theo

1. Chốt art direction, cắt atlas và nén texture theo Android/iOS.
2. Bổ sung SFX mixer và audio asset đã có quyền sử dụng.
3. Test cảm ứng, hiệu năng, RAM và accessibility trên máy Android/iPhone thật.
4. Cấu hình Android AAB release/iOS Xcode, chốt icon, splash và metadata Store.
5. Rà soát lại định vị "Lộc ảo/cultural-casual" cùng bộ phận pháp lý trước khi
   gửi Store; không thêm tiền thật hay quy đổi thưởng.

Xem [checklist phát hành](docs/RELEASE_CHECKLIST.md) trước khi tạo AAB hoặc
Xcode archive. Khóa ký và định danh Publisher không được lưu trong source.

## Android

- Package ID: `vn.lamgame.baucuatomca`.
- Preset **Android Debug APK** dành cho cài thử nội bộ.
- Preset **Google Play AAB** dùng Gradle cho Play Store. Điền keystore release
  trong Godot Export trước khi export AAB; tuyệt đối không thêm khóa vào source.
- Xem [hướng dẫn build Android](docs/ANDROID_BUILD.md) để build APK/AAB và xác
  minh manifest.
- Artifact debug đã build: `export/android/bau-cua-tom-ca-debug.apk` và
  `export/android/bau-cua-tom-ca-debug.aab` (thư mục export không được commit).
