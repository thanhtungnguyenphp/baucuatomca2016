# Checklist phát hành mobile

## Các quyết định cần chủ dự án cung cấp

- Android package ID: `vn.lamgame.baucuatomca`. iOS Bundle ID và tên publisher
  chính thức vẫn cần xác nhận.
- Keystore Android release (lưu riêng, có sao lưu) và Apple Developer Team.
- Phân loại tuổi/mô tả Store đã được bộ phận pháp lý chấp thuận. Sản phẩm hiện
  chỉ dùng Lộc ảo, không có tiền thật, nạp tiền, đổi thưởng hoặc vật phẩm quy đổi.
- Bộ icon, splash, screenshot Store và Privacy Policy Android đã được dùng cho bản phát hành.

Không ghi khóa ký, mật khẩu, Apple certificate/provisioning profile hoặc thông tin
tài khoản vào repository.

## Asset và âm thanh

- [ ] Xác nhận quyền sử dụng cho toàn bộ art đã nhập từ prototype web.
- [ ] Cắt sprite sheet thành atlas platform-specific; nén ETC2/ASTC sau khi đo
      chất lượng trên thiết bị thật.
- [ ] Thay âm procedural trong `AudioDirector` bằng SFX đã master và được cấp
      quyền; giữ các cue `TAP`, `SHAKE`, `REVEAL`, `WIN` để không đổi gameplay.
- [x] Chốt adaptive icon foreground/background và splash Android nền đỏ Tết.
- [ ] Chốt icon/splash iOS sau khi có Bundle ID và Apple Team.

## Android

- [x] Cấu hình Android SDK/JDK trên máy build.
- [x] Tạo preset `Android Debug APK` và `Google Play AAB` với package ID chính
      thức, ARMv7/ARM64 và quyền `VIBRATE`.
- [x] Export APK debug và AAB debug; kiểm tra manifest package/version/SDK/quyền.
- [x] Tạo upload keystore, ký AAB release và giữ khóa ngoài source; chủ dự án vẫn phải xác nhận bản sao lưu an toàn.
- [x] Xóa artifact/cache cũ và xuất AAB release `1.4.2`/code `9`; xác minh manifest, ZIP và chữ ký JAR hợp lệ.
- [x] Upload và phát hành thành công `1.4.2`/code `9` trên Google Play.
- [ ] Test update có kiểm soát qua Google Play/Internal testing: cài bản cũ từ
      Play rồi nâng bản; không dùng production APK sideload.
- [ ] Hoàn tất ma trận offline, xoay màn, background/foreground, tắt âm/rung và xóa tiến trình.

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

- [x] Toàn bộ 22 entrypoint automation cho core/Main/Party/Nearby chạy đạt ngày
      27/11/2026; AAB release ký thành công và manifest cuối đã kiểm tra.
- [ ] Có thiết bị thật xác nhận audio, haptic và lựa chọn giảm chuyển động.
- [x] Metadata, age rating và Privacy Policy đã được publisher hoàn tất cho bản Google Play.
- [x] Không có bất kỳ đường dẫn thanh toán, nạp tiền hay quy đổi phần thưởng nào.
- [x] Privacy Policy HTTPS và email hỗ trợ đã được khai báo trên Store.
- [x] Data safety đã khai theo AdMob/Nearby và artifact Android hiện tại.
- [x] Hoàn tất IARC Content Rating, khai báo mô phỏng cơ chế đặt Lộc ảo và không chọn Designed for Families.
- [ ] Bộ phận pháp lý xác nhận tên, mô tả, thị trường phát hành và định vị không phải cờ bạc bằng tiền thật.

Quy trình Android tái lập được ghi tại `ANDROID_BUILD.md`.

Backlog chưa hoàn thành và điều kiện mở phase tiếp theo nằm tại
`PHASE_HANDOFF_2026-11-27.md`.
