# Checklist phát hành mobile

## Các quyết định cần chủ dự án cung cấp

- Android package ID: `vn.lamgame.baucuatomca`. iOS Bundle ID và tên publisher
  chính thức vẫn cần xác nhận.
- Keystore Android release (lưu riêng, có sao lưu) và Apple Developer Team.
- Phân loại tuổi/mô tả Store đã được bộ phận pháp lý chấp thuận. Sản phẩm hiện
  chỉ dùng Lộc ảo, không có tiền thật, nạp tiền, đổi thưởng hoặc vật phẩm quy đổi.
- Bộ icon, splash, screenshot Store và Privacy Policy đã duyệt.

Không ghi khóa ký, mật khẩu, Apple certificate/provisioning profile hoặc thông tin
tài khoản vào repository.

## Asset và âm thanh

- [ ] Xác nhận quyền sử dụng cho toàn bộ art đã nhập từ prototype web.
- [ ] Cắt sprite sheet thành atlas platform-specific; nén ETC2/ASTC sau khi đo
      chất lượng trên thiết bị thật.
- [ ] Thay âm procedural trong `AudioDirector` bằng SFX đã master và được cấp
      quyền; giữ các cue `TAP`, `SHAKE`, `REVEAL`, `WIN` để không đổi gameplay.
- [x] Gán emblem hiện có làm launcher icon Android tạm thời để debug build.
- [ ] Chốt adaptive icon foreground/background, icon iOS và splash chính thức
      sau khi art direction được duyệt.

## Android

- [x] Cấu hình Android SDK/JDK trên máy build.
- [x] Tạo preset `Android Debug APK` và `Google Play AAB` với package ID chính
      thức, ARMv7/ARM64 và quyền `VIBRATE`.
- [x] Export APK debug và AAB debug; kiểm tra manifest package/version/SDK/quyền.
- [ ] Tạo keystore release, ký AAB release và sao lưu khóa ở kho bí mật ngoài repository.
- [ ] Test internal track qua Google Play: cài mới, update, offline, xoay màn
      hình, background/foreground, tắt âm/rung và xóa tiến trình.

## iOS

- [ ] Export Xcode project trên macOS, gán Team và Bundle ID chính thức.
- [ ] Kiểm tra safe area trên iPhone có tai thỏ/Dynamic Island và iPad nếu hỗ trợ.
- [ ] Archive/TestFlight: cài mới, update, background/foreground và accessibility.

## Hiệu năng và chất lượng

- [ ] Profile máy Android cấu hình thấp, Android phổ thông và iPhone thật.
- [ ] Mục tiêu: 60 FPS trong màn chơi, không spike khi lắc/mở tô/thắng.
- [ ] Đo RAM, kích thước AAB/IPA, cold start và thời gian load texture.
- [ ] Thử 20 ván liên tiếp để xác nhận lịch sử, tiến trình và hiệu ứng không rò rỉ.
- [ ] Rà soát text, VoiceOver/TalkBack và tương phản màu.

## Gate trước khi gửi Store

- [ ] Toàn bộ test automation chạy đạt; build release không warning/error.
- [ ] Có thiết bị thật xác nhận audio, haptic và lựa chọn giảm chuyển động.
- [ ] Metadata, age rating và Privacy Policy khớp với hành vi thực tế.
- [ ] Không có bất kỳ đường dẫn thanh toán, nạp tiền hay quy đổi phần thưởng nào.
- [ ] Xuất bản Privacy Policy HTTPS công khai; thay toàn bộ placeholder trong `PRIVACY_POLICY_VI.md`.
- [ ] Điền Data safety dựa trên artifact cuối và toàn bộ SDK thực tế.
- [ ] Hoàn tất IARC Content Rating, khai báo chính xác mô phỏng cơ chế đặt Lộc ảo; không chọn Designed for Families.
- [ ] Bộ phận pháp lý xác nhận tên, mô tả, thị trường phát hành và định vị không phải cờ bạc bằng tiền thật.

Quy trình Android tái lập được ghi tại `ANDROID_BUILD.md`.
