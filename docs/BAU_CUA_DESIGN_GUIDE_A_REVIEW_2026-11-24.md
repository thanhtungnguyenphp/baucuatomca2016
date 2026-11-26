# Đánh giá Design Guide A — Modern Tết

**Ngày đánh giá:** 24/11/2026
**Tài liệu nguồn:** `docs/BAU_CUA_DESIGN_GUIDE_A_MODERN_TET.md`
**Nền tảng thực tế:** Godot 4.x / Android, không phải Unity

## Kết luận

Guide đúng hướng về phân cấp thị giác, một CTA chính, vùng chạm mobile và quảng cáo không chen vào gameplay. Mức phù hợp định hướng: **cao**. Phần kỹ thuật Unity không dùng trực tiếp; đã chuyển khái niệm Canvas/Prefab/TMP thành Godot Control/Scene/Theme và test viewport.

Ưu tiên triển khai ngay là: header gọn, HUD có surface, CTA Lắc rõ trạng thái, một bộ chọn mệnh giá, menu mở rộng và route quảng cáo theo màn hình. Không thay luật, số dư, payout hoặc kết quả.

## Hiệu chỉnh sau khi nhận mockup chi tiết

Bản NBY-39 mới chỉ áp dụng theme/hierarchy lên layout cũ nên mức thay đổi thị giác chưa đủ. Mockup được cung cấp sau đó xác nhận cần **tái cấu trúc toàn bộ màn gameplay**, không phải tiếp tục tinh chỉnh lớp màu.

NBY-40 đã thay đổi quyết định UI như sau:

- Tô là hero thực sự: kích thước riêng cho gameplay, glow sân khấu và hint pill ngay bên dưới.
- Sáu mệnh giá hiện trực tiếp thành pill một hàng; bỏ selector popup ở màn chơi đơn. Giá trị game hiện có được giữ để không phá economy/protocol.
- CTA Lắc tăng từ 104 lên 136 px, dạng capsule vàng; card và chip được chọn có glow cùng phản hồi bounce.
- Khôi phục quick-nav năm mục theo mockup: Lịch sử, Thống kê, Chơi gần, Hướng dẫn, Âm thanh. Hamburger vẫn giữ vai trò menu đầy đủ/mở rộng.
- Bỏ CTA Nearby lớn độc lập; **Chơi gần** nằm giữa quick-nav và là mục đầu trong menu để vừa gọn vừa dễ khám phá.
- Trên bàn chỉ giữ status capsule `Trên bàn / Hôm nay`; câu hướng dẫn phụ được ẩn.

## Hiệu chỉnh sau QA trên thiết bị — NBY-41

Mockup cho hướng thị giác, nhưng QA thao tác thực tế xác nhận multiplayer phải là CTA nổi trội hơn quick-nav. Quyết định cuối:

- Ẩn năm nút tiện ích khỏi Main; chúng vẫn có trong hamburger.
- Khôi phục CTA **Chơi cùng bạn ở gần** lớn/highlight ngay trên vùng banner AdMob.
- Main cho phép banner adaptive; Nearby và thời điểm chuyển scene vẫn tắt banner.
- Trở lại selector mệnh giá mở popup 3×2 vì sáu pill trên màn hẹp khó chọn.
- Pill dưới tô là hướng dẫn theo state: chạm để lắc, đang lắc, chạm để đậy, đang đậy.
- Kết quả tách khỏi tip: overlay sáng hiển thị trong 3 giây, đồng thời card trúng dùng reaction/glow/phóng lớn và card hụt giảm sáng.
- Layout dùng kích thước bowl/card/margin nội suy theo chiều cao; CTA Nearby, status và gameplay margin cùng dời khi banner load để không tạo khoảng trắng giả khi no-fill.

## Đối chiếu với game trước khi tối ưu

| Hạng mục guide | Trạng thái trước | Đánh giá |
| --- | --- | --- |
| Một CTA chính là Lắc | Chỉ có dòng “Chạm vào tô để lắc”; tô là vùng chạm | Thiếu affordance và trạng thái disabled |
| Header/HUD gọn, có surface | Title/slogan lớn; Lộc/Ván nổi trực tiếp trên nền hoa văn | Cần tăng phân cấp và tương phản |
| Một điều khiển mệnh giá | Đã hoàn thành ở NBY-36 | Phù hợp guide |
| Menu thay bottom navigation | Đã hoàn thành ở NBY-38 | Phù hợp guide, dễ mở rộng |
| Không banner trong gameplay | Banner native vẫn hiện dưới gameplay và Nearby | Không phù hợp, cần sửa P0 |
| Interstitial tại chuyển cảnh tự nhiên | Có trigger theo số ván khi đậy tô | Không phù hợp, cần tắt trong gameplay |
| Grid 3×2 và sprite giữ tỉ lệ | Đã có | Phù hợp |
| Lock input khi shaking/revealing | Đã có state `is_animating`/`is_round_in_progress` | Phù hợp |
| No real money / no cash reward | Đã có nội dung và luật điểm ảo | Phù hợp |
| Responsive/safe area | Có test 720×1650, 1080×1920, 1080×2400 | Tốt, cần mở rộng ma trận thiết bị thật |

## Thay đổi đã triển khai

### 1. Header và HUD

- Thêm brand `lamgame.vn` ở góc trái.
- Giảm title còn 56 px; slogan tự ẩn trên màn thấp.
- Menu hamburger vẫn ở góc phải, không đè title.
- Lộc/Ván đặt trên HUD surface tối, viền vàng nâu tiết chế.
- Thêm surface trong suốt nhẹ sau vùng gameplay để chữ không nằm trực tiếp trên texture đậm.

### 2. Hành động chính

- Thêm nút **LẮC TÔ** cao 104 px, nền vàng kem và chữ đỏ sẫm.
- Chưa đặt cược: disabled và ghi **CHỌN LINH VẬT TRƯỚC**.
- Có cược: hiển thị tổng cược ngay trên CTA.
- Đang animation: khóa và ghi **ĐANG XỬ LÝ…**.
- Đã mở tô: đổi thành **ĐẬY TÔ · VÁN TIẾP**.
- Chạm trực tiếp vào tô vẫn gọi cùng command để tương thích, nhưng không còn dòng CTA cạnh tranh.

### 3. Quảng cáo theo route

- `AdPlacement` tách `banner_loaded` khỏi `banner_route_allowed`.
- Gameplay chính và Nearby mặc định không cho phép banner.
- Banner chỉ được phép khi mở menu hoặc popup thông tin; khi đóng sẽ hide native view và trả lại safe area.
- Onboarding không hiện banner.
- Bỏ trigger interstitial khi đậy tô; chờ Home/session-summary thật trước khi bật lại.
- No-fill/offline không tạo khoảng trống giả.

### 4. Responsive và accessibility

- Giữ vùng chạm menu 104×80, CTA Lắc 104 px, chip 112 px.
- Giữ grid 3×2, sprite preserve aspect và text tiếng Việt.
- Back đóng overlay/popup trước khi thoát.
- Acceptance test chạy ở 720×1650, 1080×1920 và 1080×2400.

## Điểm đã điều chỉnh so với guide

- Guide dùng đơn vị dp trên khung 390×844; dự án dùng viewport tham chiếu 1080×1920 và `canvas_items`. Kích thước được quy đổi theo vùng chạm thực tế, không sao chép số dp trực tiếp.
- Guide viết cho Unity. Mapping tương đương: Prefab → Godot Scene, Canvas/LayoutGroup → Control/Container, ScriptableObject theme → constants/theme overrides, TMP → font/theme Godot.
- Countdown Nearby 30 giây được giữ vì đây là deadline authoritative điều khiển phase, không phải countdown giả để gây áp lực quảng cáo.
- CTA Nearby vẫn độc lập ngoài menu để tính năng multiplayer không bị giảm discoverability.

## Chưa triển khai và lý do

| Hạng mục | Trạng thái/khuyến nghị |
| --- | --- |
| Home/mode-selection scene riêng | Nên làm phase tiếp theo; hiện Main vẫn là gameplay. Cần chốt flow Back, onboarding và banner Home trước khi tách route. |
| Be Vietnam Pro | Chưa có font asset/license trong repo. Chỉ tích hợp sau khi kiểm tra OFL/license, atlas và fallback tiếng Việt. |
| Safe area notch bằng API riêng | Hiện dùng margin/viewport; cần QA thiết bị notch và system navigation thật trước khi thêm utility. |
| 360×640, 360×800, 390×844, 412×915, 768×1024 | Hiện có ba viewport tương đương dự án; cần bổ sung ma trận logical và ảnh máy thật. |
| Rewarded 200K khi client hết Lộc | **Xung đột guide.** Đây là chức năng đã được yêu cầu trước đó. Không tự xóa; cần chủ sản phẩm duyệt giữ, chuyển ra session summary hay bỏ trước release. |

## Acceptance hiện tại

- CTA chính có text + disabled reason, không chỉ dựa vào màu.
- Gameplay/Nearby không cho phép banner.
- Menu/popup thông tin có thể cho banner và tự trả layout khi đóng.
- Không còn interstitial tự bật trong vòng lặp lắc/đậy tô.
- Luật, balance, payout và RNG không thay đổi.
- Test hồi quy và test Modern Tết phải đạt trước khi build thiết bị.

## Kết quả QA thiết bị ngày 24/11/2026

- Đã export APK debug 236.743.755 byte, SHA-256 `bccdb4c1ae1f7ea4994b00d2874ec5eecddd09c014c4dcb2cf7fa836a22ab2e0`.
- Đã cài và mở trên Redmi `23021RAAEG` với package DEV, không ghi đè bản Store.
- Trạng thái idle: title/HUD/tô/grid 3×2, bộ chọn mệnh giá, CTA và Nearby CTA không chồng nhau; gameplay không có banner.
- Sau khi chọn Bầu: thẻ hiển thị 10.000 Lộc, tổng cược và CTA vàng **LẮC TÔ · CƯỢC 10.000 Lộc** đồng bộ.
- Menu: bốn mục có vùng chạm lớn và mô tả hai tầng; banner test chỉ xuất hiện tại route menu như thiết kế.
- Còn phải lặp lại ma trận ảnh/video trên POCO và tablet trước khi coi NBY-39 hoàn tất QA đa thiết bị.

## Backlog đề xuất

1. P0: QA ảnh/video trên Redmi, POCO và tablet cho idle/selected/shaking/result/menu.
2. P0: quyết định chính sách rewarded multiplayer.
3. P1: tách Home/mode selection, chuyển banner về Home và History.
4. P1: đánh giá font Be Vietnam Pro và fallback.
5. P2: mở rộng viewport/notch/gesture/3-button navigation và profiling 30/60 FPS.
