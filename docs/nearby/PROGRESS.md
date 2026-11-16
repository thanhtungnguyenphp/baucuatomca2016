# Tiến độ nhánh Nearby Connections

**Nhánh:** `codex/feature-nearby-connections`

**Trạng thái (16/11/2026):** bản game Nearby v1 đã qua năm lượt trên hai điện thoại thật. NBY-14–21 của v2 đã hoàn thành code/test headless: host chỉ điều khiển bàn, client đặt nhiều cửa, payout/leaderboard đồng bộ, Rewarded Ad có host xác thực và banner adaptive. NBY-22 đang QA; v2 chưa chơi đủ ván trên thiết bị thật, chưa thử 3–4 máy hoặc cập nhật Store.

## Kế hoạch tối ưu v2 — 16/11/2026

- NBY-14 hoàn thành: người dùng phê duyệt tiến hành tuần tự theo bộ mặc định trong kế hoạch v2.
- NBY-15 hoàn thành: thêm model thuần `DealerPartyMatch` với tối đa ba client, balance/bets/confirm/spectator, host settlement qua `RoundResolver`, leaderboard và quy tắc hoàn stake khi client rời trước settle. Test mới và test hồi quy `PartyMatch`, Nearby v1, core rules đều qua. NBY-16 đang thực hiện.
- NBY-16 hoàn thành: thêm `PartyNearbyAdapterV2` song song adapter v1, service/protocol v2, client action IDs, host validation, snapshot balance/bets/results/leaderboard và từ chối v1 rõ ràng. Test protocol qua action trùng, stale round, forged state và disconnect refund.
- NBY-17 hoàn thành: màn hình Nearby dùng adapter v2; host có badge dealer, không có seat/đường đặt, thấy cược và ready của client, chỉ lắc khi phase `locked`. Test UI host headless đã qua. NBY-18 đang thực hiện.
- NBY-18 hoàn thành: client có balance, sáu chip, đặt nhiều cửa, xóa/xác nhận và khóa UI sau confirm; hết Lộc hiển thị spectator và không chặn host. Test UI client, host và protocol v2 đều qua. NBY-19 đang thực hiện.
- NBY-19 hoàn thành: kết quả, payout/net của từng client và leaderboard được lấy từ snapshot authoritative; test năm lượt xác nhận rank giống nhau, ad bonus không vào `total_net` và rematch reset dữ liệu phiên.
- NBY-20 hoàn thành: preload Rewarded, chỉ gửi claim sau callback earned, host chống request trùng và lifecycle quảng cáo toàn màn hình không đóng phòng. Production ID `ca-app-pub-6352554924566967/7706970639` đã được cấu hình; debug vẫn dùng Google test ID. NBY-21 đang thực hiện.
- NBY-21 hoàn thành code/test: banner dùng anchored adaptive size, Main/Nearby chỉ dành vùng dưới khi native banner báo loaded và trả lại không gian khi no-fill. Test layout qua ở 720×1650 và 1080×2400; bổ sung trạng thái chẩn đoán consent/load. AdMob vẫn cần publisher sửa UMP Privacy & messaging để trạng thái consent không còn `UNKNOWN`. NBY-22 đang thực hiện.
- Đã chốt hướng kiến trúc trong tài liệu: tổng tối đa bốn thiết bị gồm một dealer host và một đến ba client. Host không đặt cược, không có balance và không xuất hiện trên leaderboard.
- Đã bổ sung backlog NBY-14–23 cho model balance/bets, protocol v2, UI host/client, payout/leaderboard, Rewarded Ad, banner/UMP, QA bốn máy và release readiness.
- Adapter/model v1 vẫn được giữ song song để hồi quy; màn hình Nearby hiện dùng protocol/model v2.
- AdMob App ID cùng banner, interstitial và rewarded production ID đã nằm trong code. Log máy thật báo UMP publisher misconfiguration/no form và ads chờ consent status 0; lỗi cấu hình publisher này vẫn cần sửa trong AdMob Privacy & messaging.

## NBY-22 QA v2 đang thực hiện — 16/11/2026

- Toàn bộ regression tự động qua: core rules, engagement, local `PartyMatch`/PartyFlow, Nearby v1, `DealerPartyMatch`, protocol v2, UI host/client, payout/leaderboard/rematch, portrait layout và banner layout 720×1650/1080×2400.
- Export APK debug v2 thành công tại `export/android/bau-cua-tom-ca-debug.apk`, dung lượng khoảng 210 MB, SHA-256 `b25b013084e96f671be2200efce365acefb3789e178e945cf48a27abd093c605`.
- Cài đè package `vn.lamgame.baucuatomca.dev` thành công trên điện thoại Redmi Android 15/API 35 `23021RAAEG` và máy tính bảng Samsung Android 16/API 36 `SM-X110`. Cả hai cùng chạy version `1.2.0`/code `5`, vào foreground, không có crash hoặc ANR lúc khởi động.
- Cả hai máy cùng báo UMP publisher misconfiguration vì App ID chưa có form được cấu hình; game vẫn chạy nhưng banner/rewarded chưa được tải cho đến khi publisher tạo và publish message trong AdMob Privacy & messaging.
- Chưa chạy host–client đủ năm lượt/rematch, disconnect/background rewarded hoặc cổng một host + ba client. NBY-22 giữ trạng thái đang thực hiện.


## Kiểm thử game trên hai điện thoại thật — 15/11/2026

| Thiết bị | Android | Vai | Package |
| --- | --- | --- | --- |
| Redmi 23021RAAEG | 15 / API 35 | Chủ phòng, lắc tô | `vn.lamgame.baucuatomca.dev` |
| Redmi 220333QPG | 11 / API 30 | Khách, chọn linh vật | `vn.lamgame.baucuatomca.dev` |

- Cài cùng APK debug 1.2.0/code 5 qua ADB trên cả hai máy: `Success`. Tạo phòng, tìm phòng và cùng xác nhận mã Nearby trùng nhau; hai máy hiển thị cùng phòng 098415 và 2/4 người.
- Chơi đủ năm lượt trên hai máy. Chủ phòng chọn Bầu, khách chọn Cua; chỉ chủ phòng lắc/đậy tô. Mỗi kết quả ba mặt và bảng điểm đều trùng nhau. Ví dụ lượt 1 là Cua · Cá · Cua, điểm 0–2; hết lượt 5 điểm 1–2 trên cả hai máy. Chạm chơi lại: cả hai về lượt 1/5, điểm 0–0.
- Khách rời khi ván chơi lại đã bắt đầu: chủ phòng quay về lobby 1/4, dừng ván và hiển thị lý do, không treo UI.
- Đã sửa và cài lại hai máy: thông báo xin quyền biến mất khi quyền đã cấp; trạng thái chơi cũng cập nhật sau khi chủ phòng xác nhận lựa chọn. Thử thêm chủ phòng rời: khách thấy thông báo đóng phòng. Phát hiện danh sách khách còn nút phòng cũ sau khi host rời; đã sửa để xóa phòng cũ và bổ sung test hồi quy, chờ cài lại xác minh bản sửa này.
- Đảo vai Android 11 host / Android 15 guest phát hiện lần lượt SDK 8034 và 8036. Fallback xin coarse rồi fine location theo đúng mã lỗi đã được build/cài. Android 15 sau đó tìm thấy phòng Android 11, hai máy cùng hiện mã 1589, chấp nhận và cùng vào phòng 765925 với 2/4 người. Chưa chơi lại đủ năm lượt theo chiều này; chưa thử từ chối quyền, chuyển nền, tắt radio/quyền trong trận, 3–4 máy hoặc reconnect. Không dùng kết quả hai máy để kết luận ổn định bốn máy.

## Tích hợp game — 15/11/2026

- Bật `godot_nearby` trong export Android; game dùng `PartyNearbyAdapter` riêng với giao thức JSON v1, `room_id`, số thứ tự tin nhắn và `service_id` riêng. Plugin vận chuyển không chứa luật game.
- Tạo/tìm phòng `P2P_STAR`, host giữ tối đa ba guest. Hai phía đối chiếu mã xác thực Nearby trước khi chấp nhận. Host cũng là người chơi ghế 0 và là người duy nhất lắc, tạo ba kết quả, cộng điểm và phát snapshot. Khách chỉ gửi lựa chọn; host kiểm tra ghế, lượt, biểu tượng và trạng thái.
- Nếu guest rời khi đang chơi, host dừng ván và đưa những người còn lại về lobby. Nếu mất host, guest kết thúc phòng rõ ràng. Reconnect giữ ghế/chơi tiếp **chưa triển khai**. Phòng tự đóng khi ứng dụng chuyển nền; bỏ qua tạm dừng do hộp xin quyền.
- Test giả lập transport đã qua luồng 4 người × 5 lượt, đồng bộ điểm, rematch, chặn lựa chọn sai lượt/người lạ, và dừng ván khi mất guest. Test `PartyMatch` và core rules cũ cũng qua. Godot headless tải scene mới không lỗi.
- APK debug package `vn.lamgame.baucuatomca.dev` xuất thành công; manifest có `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `NEARBY_WIFI_DEVICES` và quyền Wi-Fi/vị trí theo phiên bản Android. Lần cài thử đầu tiên trước đó bị `INSTALL_FAILED_USER_RESTRICTED`; sau khi kết nối lại hai máy, APK đã cài thành công và qua ván chơi thật nêu trên.
- Chưa tăng version code, chưa tạo AAB phát hành, chưa cập nhật chính sách quyền riêng tư/Data safety trên Store. Các bước này thuộc NBY-12/13 sau QA thiết bị.

## Kiểm tra lịch sử — 11/11/2026

- Nhánh tính năng đồng bộ với `origin`; chưa có thay đổi code mới sau commit chuẩn bị kiểm thử `ca9661f` trước lần cập nhật trạng thái này.
- ADB hiện thấy **một** điện thoại Android 15 (model `23021RAAEG`), chưa thấy điện thoại Android 11 hoặc hai máy bổ sung. Trên máy này Bluetooth, Wi-Fi, Location đều bật; Google Play services và demo Godot Nearby có mặt, các quyền Nearby runtime đã được cấp. Package game phát hành `vn.lamgame.baucuatomca` vẫn có mặt.
- Hai APK demo hiện có là bản build ngày 06/11. Không có lượt kiểm thử hai máy mới trong ngày 11/11; kết quả kết nối bên dưới là bằng chứng của ngày 06/11.
- Bước gần nhất: hoàn tất P1/P2/R1/R2/H1 trong [bảng kiểm NBY-03/04](NBY-04_DEVICE_RUNBOOK.md) khi có hai máy; sau đó NBY-05 cần bốn máy để quyết định Go/No-Go cho 2–4 người.

## Đã thực hiện

- NBY-01: xác lập feature charter, ranh giới giữa `nearby-core`, Godot bridge và luật game; commit mục tiêu đã push trước khi viết code.
- NBY-02: dựng hai Android library, addon Godot v2, demo Godot echo và demo Android/Kotlin không phụ thuộc Godot. AAR debug/release, Android demo debug và Godot demo debug đều build thành công.
- NBY-03: thêm manifest quyền theo API level, xin quyền khi người dùng bấm tạo/tìm phòng, kiểm tra Google Play services và báo lỗi khi thiếu điều kiện. Đã quan sát hộp xin quyền trên Android 15 và cấp quyền thành công. Google Play services 19.3.0 trên máy này trả `SDK_8032` khi `ACCESS_WIFI_STATE` bị giới hạn `maxSdkVersion=32`; bỏ giới hạn cho `ACCESS_WIFI_STATE` và `CHANGE_WIFI_STATE` thì quảng bá phòng thành công. Hai quyền này là normal permissions, không hiện hộp xin quyền riêng.
- NBY-04 (hai máy): đã cài demo Godot trên Android 15 và demo Android thuần trên Android 11. Tạo phòng, tìm phòng, so cùng mã xác thực, chấp nhận, trao đổi `PING`/`ECHO` hai chiều, ngắt và tìm lại phòng đều thành công. Từ chối kết nối trả `8004` cho cả hai phía; hộp xác nhận đóng trên thiết bị còn lại. Đã sửa tín hiệu Godot dùng boxed `Boolean`/`Int`, callback ngắt lặp và danh sách phòng cũ/trùng trong demo.
- NBY-08: rút luật 2–4 người, 5 lượt, lựa chọn và tính điểm ra `PartyMatch`; UI chơi cùng máy dùng model mới. Test PartyMatch, PartyFlow và core rules đều qua.

## Bằng chứng kiểm thử hai máy — 2026-11-06

| Thiết bị | Hệ điều hành | Gói demo | Vai đã thử |
| --- | --- | --- | --- |
| Redmi 23021RAAEG | Android 15 / API 35 | `vn.lamgame.nearby.demo` | Host Godot |
| Redmi 220333QPG | Android 11 / API 30 | `vn.lamgame.nearby.androiddemo` | Guest Kotlin |

- Bluetooth và Wi-Fi đều bật khi thử. Cả hai điện thoại có Google Play services.
- Cùng mã xác thực xuất hiện trên hai máy trước khi chấp nhận; trạng thái chuyển sang `CONNECTED` và mã kết quả `0`.
- Guest gửi `PING`, host nhận và trả `ECHO`; host gửi `PING`, guest nhận và trả `ECHO`.
- Guest dừng: guest về `IDLE`, host về `ADVERTISING` và nhận một sự kiện ngắt. Khởi động tìm phòng lại hiển thị đúng một phòng.
- Host từ chối: hai máy trở lại trạng thái quảng bá/tìm kiếm, mã kết quả `8004`; guest đóng hộp xác nhận. Sau đó thử ghép lại và gửi `PING` thành công.
- Hai APK thử có package riêng. `vn.lamgame.baucuatomca` và `vn.lamgame.baucuatomca.dev` trên cả hai điện thoại không bị gỡ hoặc ghi đè.

## Quyết định kỹ thuật đã kiểm chứng

- Pin `com.google.android.gms:play-services-nearby:19.3.0` cho toolchain Kotlin `2.1.21` hiện tại. Bản `19.4.0` dùng Kotlin metadata `2.3`, bản `19.5.1` dùng metadata `2.4`; nâng SDK cần nâng toolchain Android và kiểm thử export riêng.
- AAR của `nearby-core` không có phụ thuộc Godot. Android demo phụ thuộc trực tiếp core và đã kết nối với Godot demo trên máy thật, xác nhận ranh giới tái sử dụng ở mức build và runtime.
- Hai demo dùng cùng `service_id` kiểm thử `vn.lamgame.nearby.demo`; package ứng dụng có thể khác nhau.

## Chưa xác minh / việc tiếp theo

1. **NBY-22 hai máy:** mở khóa Android 15 và kết nối lại Android 11; chơi đủ năm lượt theo cả hai chiều host/client, rematch, rời phòng và rewarded lifecycle.
2. **NBY-05/NBY-22 bốn máy:** cần thêm hai Android thật để thử một host và ba client với `P2P_STAR`; chưa thể quyết định Go/No-Go bốn thiết bị.
3. **NBY-23:** chỉ bắt đầu sau cổng QA; Rewarded production ID đã có, còn cần sửa/publish UMP message trong AdMob Privacy & messaging trước release.

**Không thực hiện ở giai đoạn này:** build AAB phát hành, tăng version code hoặc gửi bản lên Store.
