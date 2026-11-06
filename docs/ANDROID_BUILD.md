# Build Android

## Cấu hình hiện tại

- Package ID: `vn.lamgame.baucuatomca`
- Version: `0.1.0` / version code `1`
- Min SDK: `24`; Target/Compile SDK: `36`
- ABI: `armeabi-v7a`, `arm64-v8a`
- Quyền duy nhất được thêm: `android.permission.VIBRATE`
- `android/` là Gradle build template do Godot cài đặt để tạo AAB.

Hai preset nằm trong `export_presets.cfg`:

| Preset | Mục đích | Ký |
| --- | --- | --- |
| `Android Debug APK` | Cài thử trực tiếp | Debug keystore tự động của Godot |
| `Google Play AAB` | Upload Google Play | Gradle; cần release keystore trước khi xuất release |

## Lệnh build

Từ thư mục project:

```sh
godot --headless --path . --export-debug "Android Debug APK" export/android/bau-cua-tom-ca-debug.apk
godot --headless --path . --export-debug "Google Play AAB" export/android/bau-cua-tom-ca-debug.aab
```

AAB debug chỉ dùng để xác minh build/internal testing. Để xuất AAB nộp Play,
điền Release Keystore, Release User và Release Password trong Godot Export,
sau đó chạy:

```sh
godot --headless --path . --export-release "Google Play AAB" export/android/bau-cua-tom-ca-release.aab
```

Không thêm `.jks`, `.keystore`, mật khẩu hay Apple/Google credential vào source.
Có thể cung cấp các keystore parameter qua biến môi trường `GODOT_ANDROID_*`
trong máy/CI thay vì ghi vào `export_presets.cfg`.

## Xác minh đã thực hiện

- APK debug đã export và ký debug thành công.
- AAB debug Gradle đã export thành công.
- Manifest APK đã kiểm tra bằng Android `aapt`: package ID, SDK 24/36, version
  `1`/`0.1.0` và quyền `VIBRATE` đều đúng.
- Manifest AAB debug cũng đã kiểm tra: package ID và quyền `VIBRATE` có mặt.

## Còn cần thực hiện trên thiết bị

1. Kết nối Android qua ADB, cài APK debug và chơi tối thiểu 20 ván.
2. Kiểm tra touch, rung, âm thanh, animation giảm chuyển động, background/foreground.
3. Chốt icon adaptive/background và splash trước khi nộp Store.
4. Sau khi có release keystore, tạo AAB release và upload Internal testing.
