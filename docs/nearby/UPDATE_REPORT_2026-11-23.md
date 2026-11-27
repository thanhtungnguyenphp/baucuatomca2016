# Báo cáo cập nhật game — 23/11/2026

## Tổng quan

Bản cập nhật hiện tại tập trung vào trải nghiệm chơi gần nhau, khả năng nhận biết tính năng multiplayer, độ rõ ràng của lobby và phản hồi trong ván. Quy mô phòng mới là **1 máy host + tối đa 5 máy con**, tổng cộng 2–6 thiết bị Android ở gần nhau.

APK debug mới:

- File: `export/android/bau-cua-tom-ca-debug.apk`
- Dung lượng: 236.755.194 byte, khoảng 226 MiB.
- SHA-256: `8f9f6778b7453fd19d79596215393d7ef2691db7a834279b86a7c6bc95ac3ab9`
- Phiên bản: `1.3.0` (`versionCode 6`).
- Artifact NBY-41 mới nhất đã được cài sạch trên tablet Samsung `SM-X110` và POCO `220333QPG` ngày 25/11/2026. Tablet đã qua smoke test giao diện chính và banner; POCO đã xác nhận package/version nhưng còn chờ mở khóa để QA trực quan.

## Tính năng mới và cải tiến đã hoàn thành

### 1. Phòng Nearby 2–6 thiết bị

- Một host làm chủ bàn, chỉ lắc/mở/đậy tô và đồng bộ trạng thái.
- Một đến năm máy con đặt Lộc, xác nhận cược và nhận kết quả riêng.
- Host không có balance, không đặt cược và không xuất hiện trong leaderboard.
- Máy con thứ sáu bị từ chối rõ ràng khi phòng đã đủ năm client.

### 2. Protocol v4 và cách ly bản cũ

- Protocol v3 từng mở rộng phòng lên năm client; bản hiện tại nâng tiếp lên v4 để đồng bộ hợp đồng countdown 30 giây.
- Đổi service ID sang `vn.lamgame.baucuatomca.party.v4`.
- APK cũ giới hạn ba client không nhìn thấy hoặc ghép nhầm phòng mới.
- Host tiếp tục là nguồn dữ liệu authoritative cho kết quả, balance, payout và thứ hạng.

### 3. Sửa lỗi mất máy khi nhiều người cùng tham gia

- Thay biến xác nhận đơn bằng hàng đợi FIFO.
- Các yêu cầu đối chiếu mã đến gần đồng thời được xử lý lần lượt, không ghi đè endpoint trước.
- Chống thêm trùng cùng endpoint vào hàng đợi.
- Khi thoát phòng, các yêu cầu đang chờ được từ chối và dọn sạch.

### 4. Lobby năm ghế dễ hiểu

- Hiển thị riêng năm ghế máy con với tên và trạng thái kết nối.
- Hiển thị số máy đã vào phòng theo dạng `x/5`.
- Luồng hướng dẫn: nhập tên → tạo/tìm phòng → so mã → chờ bạn → bắt đầu.
- Nút host thay đổi theo số người: chờ người, bắt đầu với N bạn hoặc đủ phòng.
- Nếu chưa đủ năm client, host phải chọn rõ **Bắt đầu ngay** hoặc **Chờ thêm bạn**.
- Chú thích rõ Nearby có thể dùng Bluetooth và Wi-Fi, không cần Internet.

### 4.1. Vùng chạm và luồng tham gia phòng

- Nút tạo/tìm phòng cao 112 px và ghi rõ vai trò **máy này lắc tô** hoặc **tham gia đặt Lộc**.
- Khi chuyển sang tìm phòng, phần nhập tên và nút tạo/tìm được ẩn; mỗi phòng là một card riêng với nút **Tham gia** 250×104 px.
- Khi đã tạo hoặc vào lobby, toàn bộ thao tác setup được ẩn để không thể vô tình tạo lại phòng.
- Hộp so mã được tăng lên 980×650; mã xác thực được giãn từng ký tự để dễ đối chiếu.
- Hai nút **Mã giống nhau · Kết nối** và **Mã khác nhau · Từ chối** có màu đối lập, cách nhau 28 px và vùng chạm thực tế lớn hơn 330×104 px.

### 4.2. Phòng chờ kiểu MOBA

- Sau khi tạo phòng, host chuyển thẳng sang màn hình chờ với thẻ chủ bàn ở trung tâm và hiệu ứng loading kết nối.
- Mỗi client được đưa vào một trong năm vị trí; slot cập nhật ngay khi host nhận HELLO hợp lệ.
- Host có thể tiếp tục chờ hoặc bấm bắt đầu với số người hiện có.
- Client sau khi tham gia thấy tên chủ bàn ở giữa, trạng thái của mình được đánh dấu `BẠN`, cùng danh sách các client đã vào và vị trí còn trống.
- Client không thấy nút bắt đầu; màn hình chỉ thông báo đã tham gia và đang chờ chủ bàn.
- `host_name` và `betting_seconds_left` được gửi trong snapshot authoritative của protocol v4 để mọi client luôn hiển thị cùng chủ bàn và thời gian cược.

### 5. Khả năng khám phá multiplayer trên màn hình chính

- Thêm CTA riêng **Chơi cùng bạn ở gần — 2–6 thiết bị · Không cần Internet**.
- Chế độ Nearby không còn bị giấu trong Hành trình.
- Điều hướng phụ được đổi thành nhãn hai tầng:
  - Luật chơi / Cách tính.
  - Nhiệm vụ / Quà & bộ sưu tập.
  - Lịch sử / Ván đã chơi.
  - Cài đặt / Âm thanh & riêng tư.
- Vùng chạm của menu được tăng lên và vẫn tránh khu vực banner AdMob.

### 6. Tên người chơi và nhận diện trong phòng

- Tên được lưu cục bộ trên từng thiết bị.
- Chuẩn hóa tên tối đa 24 ký tự.
- Tên trùng được tự thêm hậu tố `(2)`, `(3)`…
- Máy con được đánh dấu `BẠN` trong trạng thái và leaderboard.
- Tên xuất hiện cùng cược, kết quả lượt và bảng xếp hạng.

### 7. Đồng bộ cược, kết quả và leaderboard

- Mỗi máy con có balance, cược nhiều cửa, xóa cược và xác nhận riêng.
- Host thấy trạng thái đang đặt/đã chốt của mọi client.
- Kết quả, payout, net lượt, tổng net và rank được host phát tới toàn phòng.
- Khi trên hai người cùng đặt một linh vật, thẻ chuyển sang dạng `N NGƯỜI · TỔNG ...` để tránh chữ chồng lên hình.
- Máy hết Lộc chuyển sang khán giả và có thể xem rewarded ad để nhận thêm Lộc.

### 8. Phản hồi thắng/thua và sprite linh vật

- Thêm banner kết quả THẮNG/HÒA/THUA theo từng máy.
- Âm thanh và rung riêng cho thắng/thua.
- Linh vật trúng dùng reaction sprite, viền/vệt sáng và nhấn mạnh số lần trúng.
- Linh vật không trúng giảm sáng và rung nhẹ.
- Host thấy tóm tắt kết quả của tất cả người chơi.

### 8.1. Điều khiển cược tối ưu cho cảm ứng

- Thay sáu nút mệnh giá nhỏ bằng một nút **Mệnh giá hiện tại** cao 104 px.
- Nút mở bottom sheet 3×2; mỗi mệnh giá cao 112 px, có dấu chọn, rung nhẹ và tự đóng sau khi chọn.
- Mệnh giá vượt phần balance còn có thể đặt được tự động vô hiệu hóa.
- **Xóa tất cả** và **Xác nhận** cao 120 px, tỷ lệ chiều ngang 35/65; xác nhận hiển thị tổng cược trực tiếp.
- Sau khi chốt, bộ chọn và nút xóa biến mất; nút chính đổi thành **Đã chốt · Chờ chủ bàn**.
- Trên client, tô và thẻ linh vật được thu gọn theo vai để thanh cược lớn vẫn nằm hoàn toàn phía trên banner.

### 8.2. Đồng nhất gameplay chính và giới hạn thời gian cược

- Màn hình chơi chính dùng cùng CTA mệnh giá và bottom sheet 3×2 như client Nearby, thay cho sáu nút nhỏ luôn hiện.
- Mỗi lượt Nearby có 30 giây đặt cược do host quản lý; mọi client nhận cùng `betting_seconds_left` qua protocol v4.
- Hết giờ, cược đang chọn được tự chốt; người chưa đặt vào lượt với stake 0 và host được chuyển sang bước lắc.
- Đồng hồ đổi màu khi còn 10/5 giây; client khóa thao tác tại giây 0.

### 8.3. Menu gameplay mở rộng

- Thay bốn nút Luật/Nhiệm vụ/Lịch sử/Cài đặt dưới đáy bằng một hamburger trên header để bàn chơi gọn hơn.
- Menu dạng danh sách cuộn, item lớn có tiêu đề và mô tả; bấm mở đúng popup tương ứng.
- Back ưu tiên đóng menu; CTA **Chơi cùng bạn ở gần** vẫn hiển thị độc lập.
- Dùng helper thêm item chung để bổ sung chức năng mới mà không sửa lại layout gameplay.

### 8.4. Modern Tết gameplay hierarchy

- Header thêm `lamgame.vn`, title gọn và HUD Lộc/Ván có surface tăng tương phản.
- Thêm CTA **Lắc tô** có disabled reason, tổng cược, trạng thái xử lý và đậy tô/ván tiếp.
- Gameplay/Nearby không còn banner; menu và popup thông tin dùng banner route-aware.
- Không còn interstitial tự bật trong vòng lặp lắc/đậy tô.

### 8.5. CTA Nearby, banner và phản hồi kết quả

- Ẩn năm quick-nav khỏi Main; các tiện ích vẫn nằm trong hamburger.
- Khôi phục CTA **Chơi cùng bạn ở gần** lớn/highlight ngay trên banner adaptive.
- Mệnh giá trở lại selector 104 px và popup 3×2 để vùng chạm đủ lớn.
- Pill dưới tô chỉ hướng dẫn thao tác lắc/đậy theo state.
- Overlay kết quả sáng xuất hiện 3 giây; linh vật trúng dùng reaction/glow/phóng lớn, linh vật hụt giảm sáng rồi tự reset.
- Main cho phép banner; Nearby tiếp tục không banner trong phiên chơi nhóm.

### 9. Quảng cáo và vùng an toàn giao diện

- Banner adaptive neo phía dưới và chỉ giữ chỗ sau khi load thành công.
- Banner không che menu hoặc nút hành động.
- Interstitial không chen vào lúc ghép nối/đặt cược/reveal.
- Rewarded ad chỉ cộng Lộc sau callback earned; host chống claim trùng.
- UMP consent và Privacy options đã được tích hợp.

## Kiểm thử tự động

Đã đạt 21/21 bộ test liên quan:

- Luật game và engagement.
- Model dealer với năm client.
- Protocol v4 mô phỏng một host + năm client và countdown authoritative 30 giây.
- Từ chối client thứ sáu.
- Host/client UI, payout, leaderboard và rematch.
- Lobby năm ghế trên 720×1650, 1080×1920 và 1080×2400.
- Bàn chơi có năm người cùng đặt một cửa.
- Portrait layout và adaptive banner.
- Luồng tìm phòng, kích thước vùng chạm và dialog so mã.
- Thanh cược mobile, bottom sheet chọn mệnh giá và safe area phía trên banner ở ba kích thước màn hình.
- Bộ chọn mệnh giá màn hình chính và tự chốt cược khi timeout.
- Menu header mở rộng, điều hướng bốn popup và hành vi Back trên ba viewport.
- Modern Tết header/HUD/CTA và routing quảng cáo theo màn hình.

## Trạng thái triển khai

| Hạng mục | Trạng thái |
| --- | --- |
| Code phòng 1 host + 5 client | Hoàn thành |
| Protocol/service v4 | Hoàn thành code/test; luồng hai máy đạt, chờ QA tải 1+3/1+5 |
| Lobby năm ghế và hàng đợi pairing | Hoàn thành |
| Test mô phỏng sáu thiết bị | Đạt |
| APK debug mới | Đã build |
| Cài APK lên thiết bị thật | Đạt trên Samsung `SM-X110` và POCO `220333QPG`; cùng artifact NBY-41, version `1.3.0`/code 6 |
| QA 1 host + 3 client | Chờ thiết bị |
| QA 1 host + 5 client | Chờ sáu thiết bị Android |
| AAB/Production rollout | `1.4.2`/code `9` đã ký và phát hành thành công trên Google Play ngày 26–27/11/2026 |

## Rủi ro và bước tiếp theo

1. Cài cùng APK protocol v4 lên tất cả thiết bị; APK v3 trở về trước không ghép chung được.
2. Test tăng dần 1 host + 1, 3 rồi 5 client thay vì vào ngay sáu máy.
3. Cho các client vào gần đồng thời để xác minh hàng đợi mã kết nối.
4. Chơi đủ năm lượt và rematch; so balance, result và rank trên mọi máy.
5. Thử rời phòng, chuyển nền, radio yếu và rewarded ad trong phiên.
6. Production đã được publisher phát hành; phase tiếp theo phải hậu kiểm update qua
   Play và không dùng rollout thành công để thay thế cổng QA sáu thiết bị.

Theo dõi chi tiết tại `docs/nearby/TASKS.md` (NBY-31/NBY-32) và `docs/nearby/PROGRESS.md`.
