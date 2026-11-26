# Kế hoạch tối ưu chơi gần nhau v2

**Ngày cập nhật:** 22/11/2026
**Trạng thái:** v2 đã triển khai; đang QA phản hồi kết quả và hồ sơ người chơi
**Nhánh:** `codex/feature-nearby-connections`

## 1. Mục tiêu sản phẩm

Chế độ Nearby dùng mô hình **một máy chủ điều khiển bàn và một đến năm máy con đặt cược**. Tổng giới hạn là sáu thiết bị: một host và tối đa năm client. Bản hiện tại dùng protocol/service v4 để mọi máy cùng hiểu countdown cược authoritative 30 giây và không ghép nhầm client v3 trở về trước.

- Host tạo phòng, duyệt kết nối, bắt đầu ván, lắc/mở/đậy tô và phát trạng thái chính thức.
- Host không có số dư, không được chọn chip hoặc đặt cược và không xuất hiện trên leaderboard.
- Client đặt Lộc ảo trên một hoặc nhiều linh vật, xác nhận cược, nhận kết quả và phần thưởng do host tính.
- Mọi thiết bị hiển thị cùng tiền đặt, trạng thái sẵn sàng, ba kết quả, payout và leaderboard.
- Không có tiền thật, đổi thưởng, chuyển Lộc giữa người chơi hoặc mua Lộc trong phạm vi này.

## 2. Luồng ván chuẩn

```text
LOBBY → BETTING → LOCKED → ROLLING → REVEALED → SETTLED → NEXT_ROUND / FINISHED
```

1. Host bắt đầu khi có ít nhất một client.
2. Client chọn chip, đặt trên linh vật và bấm xác nhận.
3. Client đã xác nhận không thể sửa cược trong lượt đó.
4. Host chỉ được lắc khi mọi client đang hoạt động đã xác nhận. Client hết Lộc chuyển thành spectator và không chặn lượt.
5. Host sinh ba kết quả, dùng `RoundResolver` để tính từng client, rồi phát một snapshot chính thức.
6. Mọi máy trình bày cùng animation, payout và leaderboard trước khi host chuyển lượt.

## 3. Mô hình trạng thái authoritative

Host giữ dữ liệu phiên chơi:

```text
room_id, protocol_version, phase, round_id, seq
players[]: player_id, endpoint_id, name, color, connected, spectator,
           balance, bets, ready, round_stake, round_payout,
           round_net, total_net, wins, reward_claims
results[3], leaderboard[]
```

Client chỉ gửi ý định. Host kiểm tra `room_id`, `protocol_version`, `round_id`, `seq`, `action_id`, người gửi, trạng thái ván, mệnh giá, số dư và giới hạn cược. Client không được gửi balance, payout, kết quả lắc hoặc thứ hạng.

Giao thức game nâng lên v2. Các message chính:

- Client → host: `HELLO`, `PLACE_BET`, `CLEAR_BETS`, `CONFIRM_BETS`, `REWARD_CLAIM`, `LEAVE`.
- Host → client: `STATE`, `BET_ACCEPTED`, `BET_REJECTED`, `ROUND_RESULT`, `REWARD_RESULT`, `LEAVE`, `ERROR`.
- `STATE` là snapshot phục hồi duy nhất; các message còn lại giúp phản hồi thao tác nhanh và rõ lỗi.

Bản v1 và v2 không ghép phòng với nhau. UI phải báo “Phiên bản game không tương thích” thay vì im lặng thất bại.

## 4. Trả thưởng và leaderboard

Luật payout tái sử dụng `RoundResolver`: stake được trừ khi host khóa cược; khi biểu tượng xuất hiện, payout gồm hoàn stake của biểu tượng thắng và phần thắng theo số lần xuất hiện. Host tính đúng một lần.

Leaderboard chỉ gồm client và sắp theo:

1. `total_net` giảm dần.
2. Số lượt thắng giảm dần.
3. Thứ tự vào phòng tăng dần để kết quả ổn định.

Điểm nhận từ quảng cáo làm tăng `balance` nhưng không cộng `total_net`, vì vậy xem quảng cáo không làm tăng hạng. Mỗi lượt hiển thị stake, payout, net; cuối năm lượt hiển thị hạng, tổng net, số lượt thắng và số dư.

## 5. Hết Lộc và Rewarded Ad

Banner không dùng để cấp thưởng vì không có sự kiện xác nhận hoàn thành xem. Khi balance thấp hơn chip nhỏ nhất:

- Client chuyển thành spectator, vẫn xem được ván và không chặn host.
- Hiện nút `XEM VIDEO · NHẬN LỘC` khi rewarded ad đã tải.
- Chỉ tạo `REWARD_CLAIM` sau callback `user earned reward`.
- Host chống claim trùng bằng `reward_id`, giới hạn số lần trong một phòng và chỉ cho client trở lại từ lượt tiếp theo.
- Quảng cáo không tải hoặc mất mạng phải có trạng thái rõ; không làm treo phòng.
- Khi quảng cáo toàn màn hình mở, lifecycle guard giữ kết nối Nearby; callback pause do quảng cáo không được gọi `room.leave()`.

Development dùng rewarded test unit của Google. Trước release cần một Rewarded Ad Unit ID production do publisher tạo trong AdMob.

## 6. Banner và bố cục

- Sửa UMP/consent trước khi đánh giá no-fill. Log thiết bị ngày 15/11/2026 cho thấy publisher chưa có consent form phù hợp và ads đang chờ ở status 0.
- Dùng anchored adaptive banner ở đáy màn hình.
- Nút hành động nằm trên banner với khoảng cách an toàn; game dành vùng bằng chiều cao banner cộng navigation safe area.
- `Main` và `NearbyPartyMode` cùng lắng nghe `banner_visibility_changed`; khi banner load fail, trả vùng trống lại cho nội dung.

### Lobby nhiều thiết bị và khả năng khám phá

- Màn hình chính có CTA riêng **Chơi cùng bạn ở gần**, không giấu trong Hành trình/Nhiệm vụ.
- Lobby luôn thể hiện ba ghế client và tiến trình: nhập tên → tạo/tìm phòng → so mã → chờ bạn → bắt đầu.
- Mỗi yêu cầu `connection_initiated` được đưa vào hàng đợi FIFO. Chỉ hiện một mã xác thực tại một thời điểm; xác nhận/từ chối xong mới chuyển yêu cầu kế tiếp để hai client vào đồng thời không ghi đè nhau.
- Host có thể bắt đầu với 1–5 client, nhưng khi chưa đủ năm phải xác nhận rõ là bắt đầu ngay hay tiếp tục chờ. Sau khi ván đã bắt đầu, yêu cầu mới bị từ chối với thông báo phòng đang chơi hoặc đã đầy.
- Tên thương mại trong UI là “chơi gần nhau”; chú thích kỹ thuật nói rõ Nearby có thể phối hợp Bluetooth và Wi-Fi, không tuyên bố đây là kết nối Bluetooth thuần.
- Debug chỉ dùng test ad unit. Ghi log trạng thái consent, SDK init, load, loaded, no-fill và failure.
- Banner không che nút, popup, bàn cược hoặc nằm sát vùng chạm để tránh click nhầm.

## 7. Thứ tự triển khai đã khóa

1. Chốt luật vai trò, số dư ban đầu, chip và mức rewarded.
2. Tạo model thuần cho client bets, balance, settlement và leaderboard.
3. Nâng protocol v2 và host authority.
4. Làm UI host chỉ điều khiển bàn.
5. Làm UI client đặt cược và xác nhận.
6. Đồng bộ payout và leaderboard.
7. Tích hợp Rewarded Ad và lifecycle guard.
8. Sửa UMP, banner adaptive và safe area.
9. Test hai máy hai chiều, sau đó tăng dần một host + ba client và một host + năm client.
10. Cập nhật Privacy Policy, Data safety, release note và build internal test.

## 8. Cổng nghiệm thu

- Host không thể đặt cược qua UI hoặc message giả.
- Client không thể đặt quá balance, sửa cược sau confirm hoặc làm host settle hai lần.
- Snapshot trên mọi máy có cùng round, bets, balances, results và leaderboard.
- Reward chỉ cấp qua callback hoàn thành; reward không tác động thứ hạng.
- Xem rewarded ad không làm mất phòng.
- Banner hiển thị dưới nút trên hai tỷ lệ 720×1650 và 1080×2400, không che UI.
- Một host + năm client chơi đủ năm lượt và rematch trên thiết bị thật.

## 9. Bộ giá trị đề xuất cần duyệt trước khi code

| Quyết định | Giá trị đề xuất | Lý do |
| --- | --- | --- |
| Quy mô phòng | 1 host + 1–5 client, tối đa 6 thiết bị | Protocol v4; lobby cuộn, thẻ cược thu gọn và countdown host 30 giây cho mỗi lượt. |
| Balance đầu phòng | 1.000.000 Lộc riêng cho phiên Nearby | Đồng nhất với `GameConstants.INITIAL_BALANCE`, công bằng giữa các máy và không làm thay đổi save local. |
| Chip | 10.000, 20.000, 50.000, 100.000, 200.000, 500.000 | Tái sử dụng asset/UX và hằng số hiện tại. |
| Số cửa được đặt | Nhiều linh vật trong cùng lượt | Giống chế độ một máy và luật payout hiện có. |
| Rewarded grant | 200.000 Lộc/lần, tối đa 3 lần trong một phòng | Đủ chơi lại từ chip nhỏ nhưng không làm mất ý nghĩa balance. Host kiểm tra giới hạn phòng. |
| Hết Lộc | Chuyển spectator; nhận reward thì trở lại từ lượt kế | Không bắt cả phòng chờ quảng cáo của một client. |
| Client rời trước settle | Hủy lượt hiện tại, hoàn toàn bộ stake chưa settle, tiếp tục với người còn lại | Tránh host chốt kết quả khi thành phần người chơi đã đổi. |
| Client rời sau settle | Giữ kết quả lượt đã chốt; xóa client trước lượt kế | Không đảo ngược payout đã hiển thị trên các máy. |
| Leaderboard | Xếp theo `total_net`; reward không tính vào hạng | Người xem quảng cáo không được lợi thế thứ hạng. |

Nếu không có điều chỉnh, NBY-15 sẽ dùng bộ giá trị này làm mặc định.

## 10. Nhận diện người chơi và phản hồi tương tác

- Tên hiển thị được lưu cục bộ, làm sạch và gửi trong `HELLO`; host là nguồn tên chính thức và tự thêm hậu tố khi hai client nhập giống nhau.
- Host vẫn là dealer, không có seat. Tên host chỉ xuất hiện trong badge vai trò/phòng; leaderboard chỉ gồm client.
- Mỗi dòng cược phải chứa tên và số Lộc. Mỗi dòng kết quả chứa hạng, tên, THẮNG/HÒA/THUA, net lượt và tổng net; máy con đánh dấu chính mình bằng `BẠN`.
- Sau reveal, sprite cũ chạy nhịp chuyển động ngắn rồi chuyển sang atlas reaction mới. Cửa trúng hiện `TRÚNG ×n`, viền vàng và pulse; cửa hụt giảm sáng, lắc nhẹ và hiện `KHÔNG TRÚNG`.
- Hiệu ứng thắng/thua chỉ dựa trên snapshot authoritative, không sinh thêm message mạng và không thay đổi payout. `reduce_motion` rút animation về thời lượng tối thiểu.
- Chỉ client phát phản hồi thắng/thua cá nhân. Host hiển thị tóm tắt tất cả client để tránh hiểu nhầm chủ phòng cũng tham gia cược.

