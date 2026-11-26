# BẦU CUA TÔM CÁ — DESIGN GUIDE A: MODERN TẾT

**Dự án:** lamgame.vn | **Phiên bản:** 1.0 | **Đối tượng:** UI/UX, Unity Developer, QA

Tài liệu triển khai dựa trên ảnh gameplay hiện tại và mockup so sánh. Các số đo là đề xuất thiết kế, chưa phải kết quả đo từ thiết bị.

## 1. Định hướng

Giữ nền đỏ và vàng kim, asset tô sơn son và sáu linh vật gốc từ mockup. Tối ưu bằng bố cục gọn và ít hiệu ứng hơn mockup: một điểm nhấn chính, không biến toàn màn hình thành nhiều khối phát sáng. Phù hợp nâng cấp nhanh bản hiện tại của lamgame.vn.

## 2. Wireframe gameplay (không banner khi chơi)

```text
┌──────────────────────────────┐
│ lamgame.vn             [☰]   │
│ BẦU CUA TÔM CÁ               │
│ [ Lộc: 970.000 | Ván: 02 ]    │
│                              │
│        TÔ LẮC LỚN            │
│       nền sân khấu nhẹ       │
│        Chọn linh vật         │
│ [ BẦU ] [ CUA ] [ TÔM ]      │
│ [ CÁ  ] [ GÀ  ] [ NAI ]      │
│ [ Mệnh giá hiện tại: 10K ▾ ]  │
│ Trên bàn: 0 Lộc              │
│         [ LẮC ]              │
│ Hôm nay: 1/3 ván             │
└──────────────────────────────┘
```

Thanh menu chứa chơi cùng bạn, hướng dẫn, âm thanh, lịch sử/thống kê nếu có. Không bắt buộc bottom navigation 5 mục như mockup; giảm tải UI và tránh chạm nhầm.

## 3. Bố trí chi tiết

Khung tham chiếu 390×844 logical dp, giả định safe content 390×800. Các chiều cao gồm padding nội bộ; tổng ngân sách dưới đây 800 dp, thay đổi theo safe area thực tế.

| Block | Cao dp | Bố trí |
|---|---:|---|
| Header | 72 | Logo nhỏ 12sp, title 24sp, menu vùng chạm 48dp |
| HUD | 48 | Một hàng Lộc / Ván, số 18sp, label 12sp |
| Bowl stage | 218 | Tô rộng 65–72% content, căn giữa, bóng đổ mềm |
| Instruction | 28 | Một dòng 14sp, không lặp CTA |
| Animal grid | 236 | 3×2, gap 8, mỗi cell cao 114 |
| Existing value control | 56 | Giữ điều khiển hiện có, nhãn rõ; không cần thêm dãy nút mới |
| Total + primary action | 88 | Tổng 16sp, nút Lắc cao 52dp |
| Secondary status | 30 | Hôm nay 1/3 ván nếu dữ liệu có |
| Flexible spacing | 24 | Phân bổ giữa các block |

- Padding ngang 16 dp; content width 358 dp, cell width 114 dp. Card radius 12 dp, viền 1 dp. Icon art chiếm khoảng 70% chiều cao cell; label dưới icon, giữ khoảng trống nhất quán.
- Header không cần slogan khi màn thấp. Menu ở góc trên phải, không đè lên title. Tô luôn lớn hơn kích thước hiện tại nhưng không đẩy grid xuống khỏi vùng thao tác.
- Dùng một lớp nền tối phía sau HUD và bàn linh vật. Hoa đào/mai chỉ ở góc, tối đa khoảng 15% vùng trung tâm có họa tiết; không đặt texture đậm sau chữ.
- CTA màu vàng kem, text đỏ sẫm. Disabled dùng nền nâu và text sáng đủ tương phản, kèm giải thích ngắn khi cần.

## 4. Design tokens

| Token | Value | Dùng cho |
|---|---|---|
| Background | #650B0C | Nền |
| Surface | #481416 | Card |
| Primary | #9B1619 | Panel |
| Accent | #FFD36A | Viền chọn/CTA |
| Text primary | #FFEBC2 | Text trên nền tối |
| Text secondary | #D5A66A | Label phụ |
| CTA text | #650B0C | Text trên vàng |

Font Be Vietnam Pro (kiểm tra license/atlas), heading Bold, body Medium/Regular, số SemiBold. Border gold tiết chế; glow chỉ thoáng qua cho phản hồi, không chạy liên tục. Animation 100–180ms cho feedback, 300–500ms cho chuyển cảnh UI; animation tô theo logic hiện có.

## 5. Hành vi và trạng thái gameplay

- Giữ nguyên luật chơi, dữ liệu Lộc, thứ tự Bầu/Cua/Tôm/Cá/Gà/Nai và logic hiện có; Lộc chỉ là điểm ảo không quy đổi thành tiền hay tài sản thật.
- Chỉ có một hành động chính là Lắc. Chạm tô có thể gọi cùng command nếu cần tương thích với phiên bản cũ; không hiển thị hai CTA cạnh tranh.
- Idle: hiển thị hướng dẫn ngắn nếu chưa chọn linh vật, nút Lắc disabled kèm lý do; không phụ thuộc riêng vào màu để thể hiện trạng thái.
- Selected: viền, dấu check và nhãn số Lộc trên ô đã chọn; số tổng phải phản ánh dữ liệu thực. Không để ô được chọn trong khi tổng hiển thị 0 như mockup minh họa.
- Shaking: khóa input theo state machine, không gọi lệnh hai lần; giữ layout ổn định.
- Revealing: nâng nắp, hiển thị kết quả thực tế của game; không thay đổi kết quả theo quảng cáo.
- Result: giữ kết quả đủ lâu để đọc; dùng chữ và icon, không chỉ màu; chuyển ván theo logic hiện có.
- Không tự thêm xếp hạng, thống kê hay lịch sử nếu backend/local data chưa hỗ trợ. Tạm ẩn mục chưa có chức năng. Giữ tính năng chơi cùng bạn 2–6 thiết bị, không cần Internet, trong menu hoặc màn hình Home.
- Không thêm hiệu ứng tạo áp lực, đếm ngược giả hoặc quảng cáo đổi lấy điểm tham gia trò chơi.

## 6. AdMob — thiết kế vùng quảng cáo và chính sách hiển thị

### 6.1. Placement matrix

| Screen/state | Placement | Điều kiện |
|---|---|---|
| Home/Mode selection | Anchored adaptive banner, đáy Safe Area | Có vùng cách ly, không cạnh nút chơi/menu |
| Lịch sử / Thống kê (nếu có) | Anchored adaptive banner, đáy Safe Area | Không sát hàng tương tác; ẩn nếu thiếu diện tích |
| Gameplay active, chọn linh vật, lắc, mở tô | Không có banner, interstitial hoặc rewarded | Không gián đoạn thao tác |
| Tổng kết phiên / chuyển về Home | Interstitial tùy chọn | Chỉ tại điểm chuyển cảnh tự nhiên; không phải sau mỗi lần lắc |
| Multiplayer đang kết nối hoặc đang chơi | Không quảng cáo | Không chặn kết nối hay đồng bộ |
| Offline hoặc no-fill | Không quảng cáo | Game tiếp tục bình thường |

Google khuyến cáo tránh banner trên màn gameplay tương tác liên tục. Vì vậy không chèn banner ngay dưới nút Lắc, cạnh các ô linh vật hoặc thanh điều hướng. Nếu bắt buộc nghiên cứu banner gameplay, cần đánh giá chính sách và thiết kế lại placement ở màn hình không tương tác trước khi phát hành; không bật mặc định.

### 6.2. Wireframe màn Home có banner (không phải gameplay)

```text
┌─────────────────────────────┐
│ SAFE TOP / LOGO             │
│ BẦU CUA TÔM CÁ              │
│                             │
│       Artwork chủ đề        │
│       [ Chơi đơn ]          │
│       [ Chơi cùng bạn ]     │
│       [ Hướng dẫn ]         │
│                             │
│ Vùng đệm không tương tác    │
│ ─────────────────────────── │
│      ADMOB ADAPTIVE         │
│       BANNER SLOT           │
│ SAFE BOTTOM                 │
└─────────────────────────────┘
```

- `AdContainer` là vùng giữ chỗ layout; banner thật là native view của SDK, không phải sprite Unity hay nút giả.
- Chiều rộng bằng chiều rộng an toàn do SDK hỗ trợ; chiều cao lấy từ ad size thực tế. Thiết kế mockup có thể dùng 50–90 dp để minh họa, không coi đây là kích thước bắt buộc.
- Đệm không tương tác đề xuất 24 dp trở lên giữa banner và vùng thao tác; đây là quy ước nội bộ, không phải ngưỡng đảm bảo tuân thủ chính sách Google. Nếu vẫn có nguy cơ click nhầm thì tăng đệm hoặc bỏ banner.
- Nền slot trung tính, không trang trí giả làm quảng cáo, không có mũi tên hoặc chữ kêu gọi click. Không dùng 300×250 trên gameplay.
- Không đặt banner chồng lên nội dung, không che Android navigation bar, không di chuyển banner theo scroll, không đổi vị trí ngay khi người dùng chạm.
- Nếu load lỗi: giữ layout ổn định trong màn hiện tại; thu gọn slot ở lần chuyển màn hoặc lúc an toàn. Không hiển thị placeholder quảng cáo giả khi offline.

### 6.3. Tích hợp Unity

1. Tách ad unit theo placement (home_banner, history_banner, session_end_interstitial); có cấu hình bật/tắt từng vị trí. Không hardcode ID thật trong repository công khai.
2. Dùng Google Mobile Ads Unity Plugin; gọi `MobileAds.Initialize` theo quy trình consent/SDK hiện hành. Kiểm tra UMP và yêu cầu consent theo thị trường.
3. Tính safe width bằng API SDK phù hợp; sử dụng `AdSize.GetCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(...)`. Đồng bộ kích thước native banner với Canvas (dp/native pixels và Canvas units không đồng nhất).
4. Chỉ tạo/show banner khi route được phép; hide trước khi vào gameplay hoặc popup che khu vực quảng cáo; destroy khi không còn sử dụng. Tính lại kích thước khi orientation/safe area thay đổi.
5. Interstitial tải trước ở thời điểm phù hợp, chỉ show nếu đã sẵn sàng và người dùng thật sự tới điểm chuyển cảnh. Nếu không sẵn sàng thì tiếp tục, không buộc chờ. Có frequency cap theo phiên/thời gian, không đặt ngưỡng nhằm tối đa hóa click; khởi đầu conservative (ví dụ tối đa một lần mỗi 10 phút, không tự động hiện nếu không có chuyển cảnh). Không phải ngưỡng chính sách Google.
6. Dùng test ad unit hoặc test device khi dev/QA. Không click quảng cáo thật để test. Log load/show/fail/close theo placement; không ghi dữ liệu cá nhân không cần thiết.
7. Rà soát phân loại simulated gambling, độ tuổi đối tượng, chính sách Google Play/AdMob, thị trường phân phối và giới hạn quảng cáo trước release. Không mặc định game chủ đề dân gian được phép hướng đến trẻ em; không có tiền thật, rút tiền hoặc giải thưởng có giá trị thực.

### 6.4. Tài liệu chính thức

- [Banner guidance](https://support.google.com/admob/answer/6128877)
- [Recommended banner implementations](https://support.google.com/admob/answer/6275335)
- [Unity anchored adaptive banners](https://developers.google.com/admob/unity/banner/anchored-adaptive)
- [Interstitial guidance](https://support.google.com/admob/answer/6066980)
- [Disallowed interstitial implementations](https://support.google.com/admob/answer/6201362)

## 7. Unity UI hierarchy và responsive

```text
Canvas (Screen Space Overlay, Canvas Scaler)
├── Background (full bleed, raycast off)
│   ├── Base
│   ├── Decorations
│   └── AmbientEffects
├── SafeAreaRoot
│   ├── Header / HUD
│   ├── GameplayContent
│   │   ├── BowlStage
│   │   ├── Instruction
│   │   └── AnimalGrid (3×2)
│   ├── ActionPanel
│   │   ├── ExistingValueControl
│   │   ├── TotalLộc
│   │   └── PrimaryAction
│   └── SecondaryStatus
├── Overlay (modal + input blocker)
└── HomeOrHistoryLayout (separate route)
    ├── Content
    ├── NonInteractiveSpacer
    └── AdContainer (native ad slot reservation)
```

- Canvas Scaler: Scale With Screen Size, reference 1080×2340, match 0.5 làm điểm bắt đầu; kiểm thử thực tế. Các số dp trong tài liệu là logical design units, cần quy đổi theo scale.
- SafeAreaRoot cập nhật theo Screen.safeArea và kích thước màn. Artwork full bleed nhưng text, controls không nằm dưới notch/system navigation.
- Grid cell width = (content width − 2 × gap)/3; chiều cao theo ngân sách chiều cao còn lại. Không scale méo sprite; dùng preserve aspect và chuẩn hóa bounding box của asset.
- ActionPanel anchor bottom trong safe content, Header anchor top; phần giữa flexible. Dùng LayoutElement cho min/preferred/flexible height; tránh vòng lặp ContentSizeFitter với LayoutGroup trên cùng trục.
- Với màn thấp: bỏ slogan và status phụ trước, giảm khoảng cách tới 8 dp, thu nhỏ bowl stage, sau đó giảm hình linh vật (không giảm vùng chạm dưới 48 dp). Nếu vẫn thiếu chỗ, cho phần nội dung giữa scroll, giữ CTA và header cố định; tuyệt đối không overlap.
- Với tablet: max content width khoảng 520–600 dp, căn giữa; artwork nền mở rộng. Không kéo giãn toàn bộ grid.
- Font dùng TMP có đủ dấu tiếng Việt; dùng atlas phù hợp, fallback và kiểm tra số 1.000.000, label dài, text scaling.
- Tách canvas động (bowl/FX) và tĩnh nếu profiling cho thấy rebuild đắt; atlas sprites, hạn chế overdraw, không đặt particle lên text/controls.

## 8. Task triển khai và acceptance criteria

### P0 — Layout và chức năng
- [ ] Tạo prefab Header, HUD, BowlStage, AnimalCell, ActionPanel, SafeAreaRoot.
- [ ] Xóa khoảng trống dư, giữ đủ sáu linh vật và toàn bộ CTA trên 390×844.
- [ ] Chuyển multiplayer vào Home/menu nhưng vẫn dễ tìm, tối đa hai thao tác từ gameplay.
- [ ] State UI nhất quán với game state, không có double-trigger khi lắc.
- [ ] Không thay đổi game rules, số dư hay kết quả khi đổi theme.

### P1 — Theme và quảng cáo
- [ ] Tạo theme tokens/prefab variants; reuse logic controller chung.
- [ ] AdContainer chỉ hoạt động trên route được phép; xác nhận native ad không che UI.
- [ ] Kiểm thử consent, test ads, no-fill, offline, hide/destroy và resume app.
- [ ] Các màn có quảng cáo giữ vùng đệm không tương tác, không có click target kề sát.
- [ ] Kiểm tra phân loại nội dung, độ tuổi và chính sách trước publish.

### P2 — Polish và QA
- [ ] Test 360×640, 360×800, 390×844, 412×915, tablet 768×1024 (logical units).
- [ ] Test notch, gesture navigation, 3-button navigation, font tiếng Việt và số lớn.
- [ ] Test idle, selected, shaking, revealing, result, pause/resume, mất mạng.
- [ ] Test thao tác tay trái/phải; mục tiêu vùng chạm tối thiểu 48×48 dp, text thường tương phản ≥4.5:1.
- [ ] Profiling Android cấu hình thấp, mục tiêu 30 FPS ổn định trở lên, 60 FPS nếu thiết bị hỗ trợ; đo thực tế thay vì cam kết từ mockup.
- [ ] Không còn quảng cáo trên gameplay active, không lỗi layout do banner tải muộn, không bị che CTA.

## 9. Deliverables cho team

- Figma: frame gameplay, home có ad, compact gameplay, result, menu; component variants và design tokens.
- Unity: prefab theo hierarchy, theme ScriptableObject (hoặc cấu hình tương đương), ad routing service, safe area utility.
- Asset: giữ sprite gốc sáu linh vật và tô; xuất nền, hoa văn, button/frame riêng; không bake chữ vào hình.
- QA: ảnh chụp trên các tỷ lệ màn hình, video state transitions, checklist quảng cáo và log test.
