# Tiến độ nhánh Nearby Connections

**Nhánh tích hợp:** `main`

**Trạng thái (27/11/2026):** NBY-24–26 và NBY-28–42 đã hoàn thành code/test; Android `1.4.2`/code `9` đã phát hành trên Google Play. Bản hiện tại có phòng 1 dealer host + tối đa 5 client, protocol v4/countdown 30 giây, lobby MOBA, điều khiển cược mobile và Home Modern Tết. NBY-22/NBY-27/NBY-30/NBY-32 vẫn cần QA nhiều thiết bị; reconnect/plugin packaging và profiling thuộc phase kế tiếp.

## Chốt phase và phát hành 1.4.2 — 27/11/2026

- NBY-42 hoàn thành: thay shadow blur sau tô bằng sunburst halo native; splash và
  adaptive icon có nền đỏ Tết; onboarding đóng một lần được lưu; CTA Nearby nằm
  trong content flow; mệnh giá và tổng cược cùng hàng; tooltip lắc/đậy được thu
  gọn, căn giữa và giữ vùng chạm.
- Toàn bộ 22 entrypoint test core/Main/Party/Nearby đạt; không phát hiện hồi quy.
  Quy trình đầy đủ được ghi trong
  `docs/PHASE_HANDOFF_2026-11-27.md`.
- AAB `1.4.2`/code `9`, package `vn.lamgame.baucuatomca`, min SDK 24, target SDK
  36 đã ký và được publisher phát hành thành công trên Google Play.
- Một thiết bị phát triển không update được nhưng gỡ/cài lại từ Store thành công.
  Nguyên nhân phù hợp lịch sử là production APK từng sideload bằng upload key,
  trong khi Play giao APK bằng app-signing key. Từ phase sau, ADB chỉ cài package
  `.dev`; test update production phải đi qua Play/Internal testing.
- Chưa dùng việc publish thành công để đóng các gate 1+3/1+5 thiết bị, reconnect,
  rewarded lifecycle, radio/background hoặc profiling dài hạn.

## Tối ưu nhận diện người chơi và phản hồi kết quả — 22/11/2026

- NBY-24 hoàn thành: tên được lưu trong `settings.cfg`, giới hạn 24 ký tự, bỏ xuống dòng/khoảng trắng thừa và tự đổi `An`, `An (2)`, `An (3)` khi trùng. Lobby, danh sách cược và leaderboard dùng tên authoritative từ host; client hiện nhãn `BẠN`.
- NBY-25 hoàn thành: mỗi client nhận banner THẮNG/HÒA/CHƯA GẶP LỘC theo `round_net`; thắng dùng chime, rung thưởng và pháo giấy, thua dùng âm giảm dần và rung nhẹ. Host thấy outcome/net của từng client thay vì có kết quả cá nhân.
- NBY-26 hoàn thành: tạo sáu atlas game-ready 3072×512 từ sprite reaction đã duyệt. `MascotCard` chạy bốn frame chuyển động cũ trước, sau đó chuyển sang pose reaction; cửa trúng có viền vàng/pulse, cửa hụt giảm sáng/lắc nhẹ, caption nêu số lần trúng và người đã đặt.
- Test qua: `DealerPartyMatch`, protocol v2, UI host/client, payout/leaderboard/rematch, banner adaptive, portrait layout, core rules và engagement. Kiểm tra trực quan 1080×1920 xác nhận banner kết quả, thẻ và nút không chồng lấn.
- Việc còn lại: NBY-27 phải cài bản mới lên phone/tablet, chơi đủ năm lượt và xác minh tên Unicode/trùng tên, thắng/hòa/thua, reduce motion, âm thanh/rung và FPS thực tế.

## Kế hoạch tối ưu v2 — 16/11/2026

- NBY-14 hoàn thành: người dùng phê duyệt tiến hành tuần tự theo bộ mặc định trong kế hoạch v2.
- NBY-15 hoàn thành: thêm model thuần `DealerPartyMatch` với tối đa ba client, balance/bets/confirm/spectator, host settlement qua `RoundResolver`, leaderboard và quy tắc hoàn stake khi client rời trước settle. Test mới và test hồi quy `PartyMatch`, Nearby v1, core rules đều qua. NBY-16 đang thực hiện.
- NBY-16 hoàn thành: thêm `PartyNearbyAdapterV2` song song adapter v1, service/protocol v2, client action IDs, host validation, snapshot balance/bets/results/leaderboard và từ chối v1 rõ ràng. Test protocol qua action trùng, stale round, forged state và disconnect refund.
- NBY-17 hoàn thành: màn hình Nearby dùng adapter v2; host có badge dealer, không có seat/đường đặt, thấy cược và ready của client, chỉ lắc khi phase `locked`. Test UI host headless đã qua. NBY-18 đang thực hiện.
- NBY-18 hoàn thành: client có balance, sáu chip, đặt nhiều cửa, xóa/xác nhận và khóa UI sau confirm; hết Lộc hiển thị spectator và không chặn host. Test UI client, host và protocol v2 đều qua. NBY-19 đang thực hiện.
- NBY-19 hoàn thành: kết quả, payout/net của từng client và leaderboard được lấy từ snapshot authoritative; test năm lượt xác nhận rank giống nhau, ad bonus không vào `total_net` và rematch reset dữ liệu phiên.
- NBY-20 hoàn thành: preload Rewarded, chỉ gửi claim sau callback earned, host chống request trùng và lifecycle quảng cáo toàn màn hình không đóng phòng. Production ID `ca-app-pub-6352554924566967/7706970639` đã được cấu hình; debug vẫn dùng Google test ID.
- NBY-21 hoàn thành và xác minh máy thật 17/11/2026: banner dùng anchored adaptive size, Main/Nearby chỉ dành vùng dưới khi native banner báo loaded và trả lại không gian khi no-fill. UMP publisher đã nhận message, consent trả `NOT_REQUIRED`; Mobile Ads SDK, Banner, Interstitial và Rewarded đều load thành công trên Android 11. Đã sửa crash do gọi load ad trước callback `MobileAds.initialize`.
- Đã chốt hướng kiến trúc trong tài liệu: tổng tối đa bốn thiết bị gồm một dealer host và một đến ba client. Host không đặt cược, không có balance và không xuất hiện trên leaderboard.
- Đã bổ sung backlog NBY-14–23 cho model balance/bets, protocol v2, UI host/client, payout/leaderboard, Rewarded Ad, banner/UMP, QA bốn máy và release readiness.
- Adapter/model v1 vẫn được giữ song song để hồi quy; màn hình Nearby hiện dùng protocol/model v2.
- AdMob App ID cùng banner, interstitial và rewarded production ID đã nằm trong code. UMP Privacy & messaging và URL chính sách quyền riêng tư đã được publisher hoàn tất, xác minh runtime thành công.

## UX khám phá Nearby và sửa ghép 3 máy — 23/11/2026

- Đưa **Chơi cùng bạn ở gần** thành CTA chính ngay màn hình game, ghi rõ 2–6 thiết bị và không cần Internet. Điều hướng phụ đổi thành Luật chơi/Cách tính, Nhiệm vụ/Quà & bộ sưu tập, Lịch sử/Ván đã chơi và Cài đặt/Âm thanh & riêng tư; vùng chạm cao 92 px.
- Lobby mới giải thích năm bước, hiển thị riêng năm ghế máy con, số lượng đã kết nối và vai trò. Nút host đổi theo số người; nếu chưa đủ năm client, hộp xác nhận buộc chọn **Bắt đầu ngay** hoặc **Chờ thêm bạn**.
- Xác định nguyên nhân máy thứ ba biến mất: UI trước đây chỉ có một `_pending_endpoint`, nên yêu cầu xác thực đến gần đồng thời ghi đè nhau. Đã thay bằng hàng đợi FIFO, xử lý từng mã xác thực và chống trùng endpoint.
- Adapter vẫn dùng `P2P_STAR`; lớp transport vốn lưu nhiều endpoint và không tự dừng advertising sau kết nối đầu tiên. Giới hạn game được nâng lên một host + tối đa năm client.
- Protocol/service được nâng từ v2 lên v3 để bản cũ giới hạn ba ghế không nhìn thấy hoặc ghép nhầm phòng sáu thiết bị. Snapshot tiếp tục bị giới hạn 16 KiB.
- Test headless đạt: hàng đợi pairing, protocol mô phỏng 1 host + 5 client, UI host/client, payout/leaderboard, portrait layout và adaptive banner. Chưa coi quy mô sáu thiết bị đã ổn định cho đến khi NBY-32 chạy trên máy thật.
- APK debug protocol v3 + UX cảm ứng mới đã export tại `export/android/bau-cua-tom-ca-debug.apk` (236.711.382 byte), SHA-256 `d034f5ea0a9d13450ccd1dc893bd45d8bdd67d41b8e9e4fdde601f56bdf32e9f`. Đã cài thành công lên Redmi `23021RAAEG` và tablet Samsung `SM-X110`; cả hai mở foreground, chưa thấy crash/ANR khi khởi động. Chờ người dùng thao tác ghép phòng để QA cảm giác bấm thực tế.
- NBY-33 hoàn thành code/test: màn hình idle có hai nút vai trò cao 112 px; trạng thái tìm phòng dùng card và nút tham gia 250×104; sau khi tạo/vào phòng ẩn phần nhập tên/tạo/tìm; dialog so mã 980×650, mã giãn ký tự, hai hành động màu đối lập với vùng chạm thực tế trên 330×104. Chờ cài lại để QA cảm ứng trên máy thật.
- NBY-34 hoàn thành code/test: lobby chuyển sang flow kiểu MOBA. Host nằm ở card trung tâm, năm vị trí client dùng grid hai cột, client tự đánh dấu `BẠN`, hiệu ứng loading chạy khi tìm/chờ, và `host_name` được truyền trong snapshot v3 thay vì phụ thuộc danh sách discovery. Host có nút bắt đầu động; client chỉ thấy trạng thái đã tham gia và chờ chủ bàn.
- APK lobby MOBA đã export tại `export/android/bau-cua-tom-ca-debug.apk` (236.714.274 byte), SHA-256 `71429b6fa06208d7798e234bef2c43773ecbab0d8174e009278a103756d803e5`. Đã cài thành công lên POCO `220333QPG` và Redmi `23021RAAEG`; cả hai mở foreground, chưa thấy crash/ANR lúc khởi động.
- NBY-35 hoàn thành code/test: client dùng một nút **Mệnh giá** cao 104 px mở bottom sheet 3×2; sáu chip cao 112 px và tự đóng sau khi chọn. **Xóa tất cả**/**Xác nhận** cao 120 px theo tỷ lệ 35/65, xác nhận hiển thị tổng cược và chuyển thành trạng thái đã chốt. Tô/thẻ client thu gọn theo vai để thanh cược luôn nằm trên banner; test layout đạt ở 720×1650, 1080×1920 và 1080×2400.
- APK debug NBY-35 đã export tại `export/android/bau-cua-tom-ca-debug.apk` (236.720.869 byte), SHA-256 `7b1588f49a36840264332416f1c08d11821b532d8c5fe3a1414ff2b15835be62`. Bản `1.3.0` (`versionCode 6`) đã cài và mở foreground thành công trên POCO `220333QPG` và tablet Samsung `SM-X110`; log khởi động không có crash/ANR. Chờ QA thao tác chọn mệnh giá, xóa và xác nhận trên màn hình cảm ứng thật.

## Tối ưu gameplay và giới hạn thời gian cược — 24/11/2026

- NBY-36 hoàn thành code/test: màn hình chơi chính chỉ còn một CTA **Mệnh giá** cao 104 px; bottom sheet 3×2 dùng chip 112 px, nêu số Lộc còn có thể đặt, khóa chip vượt số dư và tự đóng sau khi chọn. Luật chơi đơn vẫn giữ flow chọn cửa rồi lắc tô. Test đạt ở 720×1650, 1080×1920 và 1080×2400, kể cả safe area khi banner hiện.
- NBY-37 hoàn thành code/test: mỗi lượt Nearby bắt đầu countdown authoritative 30 giây tại host và phát số giây còn lại qua protocol/service v4. Client khóa thao tác ở giây 0; cược hợp lệ chưa bấm xác nhận được tự chốt, người không đặt được đánh dấu ready với stake 0, sau đó host chuyển sang `locked` để lắc. Đồng hồ đổi xanh/vàng/đỏ theo 30/10/5 giây; layout client đã thu gọn tô còn 260 px để toàn bộ điều khiển nằm trên banner ở ba viewport.
- APK debug NBY-36/37 đã export tại `export/android/bau-cua-tom-ca-debug.apk` (236.730.647 byte), SHA-256 `57ebc2c7db3fff3522ea79ad3bef6f586313c8bd866a59e0d71d7df37a16ab83`. Ngày 24/11/2026 đã gỡ sạch package DEV cũ rồi cài lại cùng artifact trên Redmi `23021RAAEG` và POCO `220333QPG`; cả hai chạy foreground đúng `vn.lamgame.baucuatomca.dev`, version `1.3.0`/code 6 và không có crash/ANR lúc khởi động. Bản Store được giữ nguyên.
- NBY-38 hoàn thành code/test: ẩn thanh bốn nút phụ dưới gameplay, thêm hamburger 104×80 ở góc phải header. Panel menu có scroll và bốn item 116 px với nhãn hai tầng cho Luật chơi, Nhiệm vụ, Lịch sử, Cài đặt; Back đóng menu trước khi thoát. CTA Nearby vẫn độc lập ở đáy và được dời sát safe area banner. Hàm `_add_header_menu_entry()` cho phép thêm chức năng mới mà không thay bố cục bàn chơi.
- APK NBY-38 đã export tại `export/android/bau-cua-tom-ca-debug.apk` (236.737.390 byte), SHA-256 `09e84284aa9981c7f900bf55d1c6ebf176b9d8b42894fc9df3dd0df86ea9b1bc`. Đã cài đè đúng package DEV duy nhất trên Redmi `23021RAAEG` và POCO `220333QPG`; cả hai foreground, không crash/ANR. Kiểm tra ảnh thật trên Redmi xác nhận hamburger/menu/item/CTA Nearby không chồng banner.
- NBY-39 hoàn thành code/test theo Design Guide A: thêm `lamgame.vn`, HUD surface, gameplay surface nhẹ và CTA Lắc 104 px có bốn trạng thái; giữ chạm tô làm input tương thích nhưng bỏ CTA chữ trùng. `AdPlacement` tách banner loaded/route allowed: gameplay chính, onboarding và Nearby không banner; menu/popup thông tin mới được show. Đã bỏ trigger interstitial khỏi vòng lặp đậy tô. Báo cáo đánh giá lưu tại `docs/BAU_CUA_DESIGN_GUIDE_A_REVIEW_2026-11-24.md`; 19/19 test đạt. APK mới có dung lượng 236.743.755 byte, SHA-256 `bccdb4c1ae1f7ea4994b00d2874ec5eecddd09c014c4dcb2cf7fa836a22ab2e0`; đã cài trên Redmi `23021RAAEG`. Ảnh thật xác nhận trạng thái idle/đã cược/menu rõ ràng, CTA không chồng Nearby và banner chỉ hiện trong menu; chờ lặp QA trên POCO/tablet.
- NBY-40 hoàn thành code/test theo mockup chi tiết của chủ sản phẩm: đây là tái cấu trúc thay vì chỉnh theme. Header có brand/title/ribbon/HUD; tô được mở rộng riêng cho gameplay và có glow; hint chạm tô thành pill; sáu mệnh giá hiện trực tiếp; nút Lắc cao 136 px; card/chip được chọn có glow/bounce; status capsule và quick-nav năm mục neo đáy. **Chơi gần** nằm ở trung tâm quick-nav và là mục đầu menu. Bốn test layout đạt ở ba viewport. APK cuối 236.748.727 byte, SHA-256 `3fb0bdebf2a12cfc0bf0cf38e4be84219bda1b39dd1381f671ae67672e648dd3`; chờ Redmi/POCO kết nối lại để cài artifact cuối (bản tái cấu trúc trước tinh chỉnh cuối đã được chụp QA trên cả hai máy).
- NBY-41 hoàn thành 24/11/2026 theo vòng QA tiếp theo: ẩn năm quick-nav khỏi Main và giữ chúng trong hamburger; CTA **Chơi cùng bạn ở gần** trở lại dạng lớn/highlight; banner AdMob native chiếm vùng đáy và CTA/status tự dời lên sau callback loaded. Mệnh giá trở lại một selector 104 px mở popup 3×2. Pill dưới tô chỉ hiển thị tip `lắc/đậy`, không hiển thị chuỗi kết quả. Sau reveal, overlay vàng hiển thị ba kết quả trong 3 giây; các thẻ trúng sáng/animation lớn, thẻ hụt giảm sáng, rồi toàn bộ tự reset. Layout co giãn theo chiều cao để bỏ khoảng trống. Hồi quy 21/21 đạt, gồm core, party, Nearby, banner, popup, result feedback và ba viewport. APK debug cuối 236.755.194 byte, SHA-256 `8f9f6778b7453fd19d79596215393d7ef2691db7a834279b86a7c6bc95ac3ab9`. Ngày 25/11/2026 đã gỡ package DEV cũ trên Samsung `SM-X110` và POCO `220333QPG`, gỡ thêm demo `vn.lamgame.nearby.androiddemo` trên POCO, rồi cài sạch cùng artifact NBY-41. Cả hai xác nhận `1.3.0`/code 6; bản Store được giữ nguyên. Tablet đã xác nhận màn hình chính mới và banner test hiển thị đúng; POCO đã cài nhưng đang khóa/ngủ nên còn chờ QA hình ảnh/tương tác sau khi mở khóa.
- Ngày 25/11/2026 đã nâng bản Store lên `1.4.0`/code `7` và chạy lại 21/21 bộ test thành công. AAB này sau đó được thay thế và xóa khi người dùng phản hồi Store chưa thể hiện UX/tính năng mới.
- Ngày 26/11/2026 đã xóa toàn bộ APK/AAB cũ cùng cache export/Gradle, nâng version lên `1.4.1`/code `8` và thêm nhãn phiên bản trong Cài đặt. Hồi quy sạch đạt 21/21. AAB duy nhất tại `export/android/bau-cua-tom-ca-v1.4.1-code8.aab`, dung lượng 97.560.585 byte, SHA-256 `f3541fd7cf1081a5c5953d306e77bba9fc27f6d6ed3ad0a646c5b08298cff6c2`. Artifact đã xác nhận có Main scene mới, mã Nearby 1 host + 5 client, sáu atlas reaction; manifest là package `vn.lamgame.baucuatomca`, version 1.4.1/code 8, min SDK 24, target SDK 36; ZIP và chữ ký JAR hợp lệ.

## NBY-22 QA v2 đang thực hiện — 16/11/2026

- Toàn bộ regression tự động qua: core rules, engagement, local `PartyMatch`/PartyFlow, Nearby v1, `DealerPartyMatch`, protocol v2, UI host/client, payout/leaderboard/rematch, portrait layout và banner layout 720×1650/1080×2400.
- Export APK debug v2 thành công tại `export/android/bau-cua-tom-ca-debug.apk`, dung lượng khoảng 210 MB, SHA-256 `b25b013084e96f671be2200efce365acefb3789e178e945cf48a27abd093c605`.
- Cài đè package `vn.lamgame.baucuatomca.dev` thành công trên điện thoại Redmi Android 15/API 35 `23021RAAEG` và máy tính bảng Samsung Android 16/API 36 `SM-X110`. Cả hai cùng chạy version `1.2.0`/code `5`, vào foreground, không có crash hoặc ANR lúc khởi động.
- Lỗi UMP publisher misconfiguration trước đó đã được xử lý ngày 17/11/2026. Lần xác minh mới phát hiện và sửa crash thứ tự SDK initialization; sau khi cài lại, tiến trình sống ổn định và cả ba định dạng quảng cáo debug đều load.
- Chưa chạy host–client đủ năm lượt/rematch, disconnect/background rewarded hoặc cổng một host + ba client. NBY-22 giữ trạng thái đang thực hiện.

## NBY-23 release candidate — 17/11/2026

- Tăng Android version lên `1.3.0`/code `6` cho cả debug và release; release giữ package `vn.lamgame.baucuatomca`.
- Chạy lại 12/12 bộ test tự động: core, engagement, local party, Nearby v1/v2, dealer model, UI host/client, leaderboard, portrait và quảng cáo đều đạt.
- Smoke test một máy Android 11 đạt: đặt Lộc, lắc/mở tô, tính balance/lượt và banner hoạt động. Luật chơi, Nhật ký và Tùy chỉnh đã kiểm tra; sửa bottom sheet để nút cuối không bị banner che.
- Xuất AAB release đã ký tại `export/android/bau-cua-tom-ca-v1.3.0-code6.aab`, dung lượng khoảng 82 MB, SHA-256 `dc985ffd857c1d38e9631eb349b8204a5b9c440aaeb2a2203edfa121b122fb60`.
- `bundletool 1.18.3 validate` đạt. Manifest xác nhận min SDK 24, target SDK 36, App ID AdMob production và các quyền Nearby. SHA-256 certificate trùng AAB 1.2.0/code 5.
- Release notes 1.3.0 đã tạo. Bản này chỉ nên đưa lên Internal testing cho tới khi NBY-22 hoàn tất kiểm thử hai/bốn thiết bị.


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

1. **NBY-22/NBY-27:** hai máy theo cả hai chiều host/client với rewarded
   earned/cancel/fail/offline, background/foreground, reduce motion và FPS.
2. **NBY-05/NBY-30:** một host + 2/3 client vào gần đồng thời, từ chối/rời trước
   khi bắt đầu, năm lượt/rematch và snapshot thống nhất.
3. **NBY-32:** một host + năm client thật, phòng đầy/client thứ sáu, radio yếu và
   disconnect. Test mô phỏng sáu thiết bị không thay thế gate này.
4. **NBY-06/07/11:** hardening timeout/retry/cleanup, reconnect đúng ghế và đóng
   gói addon versioned dùng được trong dự án Godot trống.
5. **Release quality:** update test qua Google Play, pre-launch/crash/ANR, 20 ván,
   FPS/RAM/cold start, TalkBack/notch/navigation và license art/SFX.

**Giới hạn hiện tại:** production đã phát hành theo quyết định của publisher,
nhưng chưa có đủ bằng chứng để tuyên bố Nearby ổn định ở tải tối đa sáu thiết bị.
