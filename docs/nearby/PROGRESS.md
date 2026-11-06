# Tiến độ nhánh Nearby Connections

**Nhánh:** `codex/feature-nearby-connections`
**Trạng thái:** đang triển khai; chưa bật chế độ chơi Nearby trong bản game phát hành.

## Đã thực hiện

- NBY-01: xác lập feature charter, ranh giới giữa `nearby-core`, Godot bridge và luật game; commit mục tiêu đã push trước khi viết code.
- NBY-02: dựng hai Android library, addon Godot v2, demo Godot echo và demo Android/Kotlin không phụ thuộc Godot. Cả hai module AAR biên dịch debug/release; Android demo biên dịch debug; Godot demo export APK debug thành công.
- NBY-03: thêm manifest quyền theo API level, xin quyền khi người dùng bấm tạo/tìm phòng, kiểm tra Google Play services và báo lỗi khi thiếu điều kiện. Manifest của APK Godot demo đã được kiểm tra bằng `aapt`; cần xác minh lời nhắc quyền trên máy thật.
- NBY-08: rút luật 2–4 người, 5 lượt, lựa chọn và tính điểm ra `PartyMatch`; UI chơi cùng máy dùng model mới. Test PartyMatch, PartyFlow và core rules đều qua.

## Quyết định kỹ thuật đã kiểm chứng

- Pin `com.google.android.gms:play-services-nearby:19.3.0` cho toolchain Kotlin `2.1.21` hiện tại. Bản `19.4.0` dùng Kotlin metadata `2.3`, bản `19.5.1` dùng metadata `2.4`, nên không biên dịch bằng Kotlin `2.1.21`. Việc nâng SDK cần đi cùng nâng toolchain Android của game và một vòng kiểm thử export riêng.
- AAR của `nearby-core` không có phụ thuộc Godot. Android demo phụ thuộc trực tiếp core và biên dịch được, xác nhận ranh giới tái sử dụng ở mức build.
- Demo Godot và Android demo dùng cùng `service_id` kiểm thử `vn.lamgame.nearby.demo`, để sau này thử kết nối chéo hai loại ứng dụng.

## Chưa xác minh / việc tiếp theo

1. **NBY-04:** cài hai APK demo lên hai Android thật có Google Play services, cấp quyền, tìm phòng, so mã xác thực hai bên, gửi PING/ECHO hai chiều; thử từ chối quyền và mất kết nối. Hiện ADB chưa thấy thiết bị.
2. **NBY-05:** thử host và ba guest trên bốn Android thật, đo thời gian vào phòng và độ ổn định. Không dùng emulator để kết luận radio thực tế.
3. Sau cổng Go/No-Go: hoàn thiện lifecycle/error API, tích hợp game protocol và phòng chơi, rồi QA quyền riêng tư/Data safety trước khi cân nhắc bản phát hành.

**Không thực hiện ở giai đoạn này:** build AAB phát hành, tăng version code hoặc gửi bản lên Store. Các việc đó nằm sau kiểm thử nhiều máy và rà chính sách dữ liệu.
