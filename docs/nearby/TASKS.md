# Backlog triển khai Nearby Connections

**Trạng thái:** đang triển khai; xem [tiến độ và bằng chứng kiểm thử](PROGRESS.md).
**Ưu tiên:** P0 = chứng minh khả thi và khóa ranh giới plugin; P1 = hoàn thiện tính năng; P2 = kiểm thử và phát hành.
**Ước lượng:** ngày công kỹ thuật, chưa tính thời gian chờ thiết bị hoặc duyệt Store.

| Thứ tự | ID | Ưu tiên | Task / sản phẩm bàn giao | Phụ thuộc | Ước lượng | Tiêu chí hoàn thành |
| --- | --- | --- | --- | --- | ---: | --- |
| 1 | NBY-01 | P0 | Chốt phạm vi và hợp đồng API: `nearby-core`, `godot-nearby`, cấu hình `service_id`, sơ đồ trạng thái, mã lỗi, chính sách disconnect. | — | 1–2 ngày | API/luồng được duyệt; không còn logic game trong plugin. |
| 2 | NBY-02 | P0 | Tạo repo/module độc lập, Gradle Android library, Godot plugin v2, demo Godot và app Kotlin tối thiểu. | 01 | 2–3 ngày | Hai demo build và khởi động; app game không cần sửa để build plugin. |
| 3 | NBY-03 | P0 | Ma trận quyền/thiết bị, kiểm tra Play services, runtime permission và merged manifest. | 02 | 2–3 ngày | Trả lý do cụ thể khi thiếu điều kiện; chế độ chơi cục bộ không bị chặn. |
| 4 | NBY-04 | P0 | Spike 2 máy thật: advertise, discover, đối chiếu mã, accept/reject, echo `BYTES`, cleanup. | 03 | 2–4 ngày | Kết nối và trao đổi hai chiều ổn định trên ít nhất hai phiên bản Android; từ chối quyền/kết nối có lỗi rõ. |
| 5 | NBY-05 | P0 | Spike 4 máy thật với `P2P_STAR`, đo thời gian vào phòng, tỷ lệ mất kết nối và hành vi radio. | 04 | 2–3 ngày | Host giữ ba guest, mỗi guest nhận payload; có báo cáo giới hạn và quyết định Go/No-Go. |
| 6 | NBY-06 | P1 | Hoàn thiện core: state machine, timeout, retry có giới hạn, callback main thread, giới hạn bytes, dọn tài nguyên, test unit. | 05 | 3–5 ngày | Test state/error/cleanup qua; không rò kết nối sau `stop_all()`. |
| 7 | NBY-07 | P1 | Khóa API Godot, đóng gói addon versioned, tài liệu tích hợp, changelog, demo độc lập. | 06 | 2–3 ngày | Dùng addon trong một dự án Godot trống và core trong app Kotlin demo. |
| 8 | NBY-08 | P1 | Tách `PartyMatch` thuần khỏi `party_mode.gd`; giữ nguyên chế độ chơi cùng máy và test luật năm lượt. | 01 | 2–3 ngày | Local party cho kết quả/điểm như trước; không phụ thuộc plugin. |
| 9 | NBY-09 | P1 | Giao thức Bầu Cua v1 và `PartyNearbyAdapter`: host authoritative, sequence, snapshot, xác thực message. | 07, 08 | 3–4 ngày | Thông điệp lặp/cũ/sai lượt không gây cộng điểm sai. |
| 10 | NBY-10 | P1 | UX phòng: tạo/tìm phòng, quyền, mã xác thực, ready, 2–4 người, lỗi rõ ràng. | 09 | 3–5 ngày | Người mới vào phòng và chơi được không cần hướng dẫn ngoài app; Local party vẫn truy cập được. |
| 11 | NBY-11 | P1 | Xử lý rời phòng, mất kết nối, guest nối lại/snapshot, chơi lại; điều chỉnh vị trí quảng cáo. | 10 | 3–5 ngày | Không treo trận; mọi máy đồng bộ hoặc thoát phòng rõ ràng sau lỗi. |
| 12 | NBY-12 | P2 | Ma trận QA thiết bị thật, hiệu năng và hồi quy UI/UX, kiểm tra AAB/manifest. | 11 | 3–5 ngày | 2/3/4 máy chơi trọn năm lượt và rematch; các tình huống mất quyền/radio/mạng có kết quả mong đợi. |
| 13 | NBY-13 | P2 | Cập nhật Privacy Policy/Data safety, mô tả quyền, release note, internal testing và quyết định phát hành. | 12 | 1–2 ngày | Nội dung Store khớp SDK/manifest thực tế; internal test qua trước khi phát hành. |

**Tổng sơ bộ:** khoảng 29–47 ngày công, có thể làm song song NBY-08 với NBY-06/07 sau khi NBY-01 được duyệt. Đây là ước lượng lập kế hoạch, không phải cam kết lịch. Rủi ro lớn nhất là độ ổn định `P2P_STAR` trên bốn máy và quyền trên các phiên bản Android; NBY-04/05 kiểm chứng trước khi đầu tư UI/game.

## Cổng duyệt

1. **Duyệt thiết kế trước NBY-02:** xác nhận Nearby Connections, phụ thuộc Google Play services, mô hình hai gói và luật phòng.
2. **Go/No-Go sau NBY-05:** nếu bốn máy không ổn định, giới hạn bản đầu ở hai máy hoặc đánh giá transport khác; ghi lại dữ liệu thử nghiệm rồi quyết định.
3. **Duyệt phát hành sau NBY-13:** xác nhận bản AAB, quyền, Data safety và trải nghiệm trên máy thật.

## Ngoài phạm vi bản đầu

- iOS bridge, ghép phòng qua Internet, Play Games Services, bảng xếp hạng online.
- Chuyển file/stream, giao dịch hoặc thưởng có giá trị tiền, tự động kết nối không cần xác nhận.
- Hỗ trợ máy Android không có Google Play services bằng transport thứ hai. Có thể bổ sung sau nhờ ranh giới `nearby-core`/game adapter.

## Điều kiện để plugin tái sử dụng thực sự

- Không import `PartyMatch`, asset, `GameSession`, `AdPlacement` hay package Bầu Cua trong hai gói plugin.
- `service_id`, tên hiển thị, chiến lược, giới hạn payload và chính sách timeout là cấu hình hoặc API công khai.
- Có demo Godot và demo Android thuần; chạy smoke test tích hợp với một dự án không phải Bầu Cua trước khi gắn nhãn 1.0.
- Có tài liệu quyền Android, cách export Gradle, khả năng thiếu Play services, API versioning và changelog.
