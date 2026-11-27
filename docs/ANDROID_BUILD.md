# Build Android

## Cấu hình hiện tại

- Package ID: `vn.lamgame.baucuatomca`
- Version: `1.4.2` / version code `9`
- Min SDK: `24`; Target/Compile SDK: `36`
- ABI: `armeabi-v7a`, `arm64-v8a`
- Quyền chính: rung, Internet/Advertising ID và nhóm Nearby/Bluetooth/Wi-Fi theo API level.
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
- AAB release `1.4.2`/code `9` đã export tại
  `export/android/bau-cua-tom-ca-release.aab`; ZIP hợp lệ, `jarsigner` xác nhận
  chữ ký và manifest merged xác nhận package/version/SDK.
- Manifest APK đã kiểm tra bằng Android `aapt`: package ID, SDK 24/36, version
  và các quyền bắt buộc đều đúng; kiểm tra lại sau mỗi lần tăng version.
- Bản `1.4.2` đã được publisher upload và phát hành thành công trên Google Play.
- Upload key cục bộ chỉ dùng ký AAB để Play xác thực. Google Play ký APK giao cho
  người dùng bằng app-signing key; không sideload APK production cục bộ lên thiết
  bị đang dùng bản Store.

## Còn cần thực hiện trên thiết bị

1. Kết nối Android qua ADB, cài APK debug và chơi tối thiểu 20 ván.
2. Kiểm tra touch, rung, âm thanh, animation giảm chuyển động, background/foreground.
3. Chạy update test từ bản cũ cài qua Google Play/Internal testing lên bản mới.
4. QA Nearby 1+3/1+5 thiết bị, rewarded, mất radio và background/foreground.

## Quy tắc package khi QA

- ADB/debug: `vn.lamgame.baucuatomca.dev`.
- Google Play production: `vn.lamgame.baucuatomca`.
- Không cài production APK ký bằng upload key đè lên bản Google Play. Android yêu
  cầu chứng thư update khớp; nếu đã sideload nhầm thì phải gỡ bản cũ và cài lại
  từ Play, thao tác này xóa dữ liệu cục bộ.
