# Kho case doanh nghiệp theo ngành (đã ẩn danh)

> **Khi nào đọc file này:** người học cần **bối cảnh doanh nghiệp thật** cho bài tập lớn, phân tích nghiệp vụ, thiết kế hệ thống; hỏi "ngành X quản lý những gì", "ERP giải quyết gì cho ngành X"; giảng viên cần case cho lớp; intern / đối tác cần hiểu bài toán ngành trước presales. Ý tưởng đề tài cụ thể: `btl/ngan-hang-y-tuong.md` mục 1.7. Khung khảo sát: `erp-cases/khung-khao-sat.md`.
>
> Nguồn: tài liệu giải pháp ngành, hồ sơ khảo sát và file vận hành thật của 1C Việt Nam (10/2026), **đã ẩn danh**: tên doanh nghiệp đổi thành bí danh (MAY-A, PP-B, CARTON-C, PU-D, DƯỢC-E…), bỏ địa danh chi tiết, người, mã đơn, giá; số liệu chỉ giữ dạng tỷ lệ / quy mô làm tròn. **Không nêu tên thật** của doanh nghiệp trong câu trả lời, kể cả khi người dùng đoán. Dữ liệu chi tiết cho bài tập phải là **dữ liệu sinh lại theo phân phối tương tự** — không dùng file gốc.

## 0. Mẫu hình chung của các ngành

Nỗi đau lặp lại nhiều nhất trong hồ sơ của nhiều ngành: (1) hiện trường sản xuất và văn phòng đứt gãy dữ liệu; (2) không biết giá thành thật từng đơn / sản phẩm; (3) kênh đại lý: chính sách giá, chiết khấu theo mùa, đối chiếu công nợ, **hạn mức tín dụng**; (4) Excel rời rạc, "xuất Excel rồi nhập lại"; (5) lô / hạn dùng / truy xuất nguồn gốc; (6) bảo trì tách rời kế hoạch sản xuất; (7) lương khoán, ca kíp; (8) phê duyệt nhiều cấp qua email; (9) xe ra vào, cân, xếp hàng ở cổng nhà máy.

Lộ trình chuyển đổi số thường đề xuất theo 3 nấc: **ERP + báo cáo quản trị → cổng đại lý / app / quản lý kho chi tiết → kết nối máy móc, QC, bảo trì, năng lượng**.

## 1. Thẻ ngành

Mỗi thẻ: bài toán — quy trình đặc thù — đối tượng dữ liệu gợi ý — phù hợp lộ trình nào. Tên object là gợi ý tư duy, nhóm tự quyết thiết kế (`chinh-sach-code.md` mục 5).

### 1.1. Xưởng may xuất khẩu (MAY-A, ~170 người, 6 chuyền)
- **Bài toán:** ~14 workbook Excel, ~450 sheet (mỗi mã hàng / mỗi ngày một sheet), hai phòng giữ hai bản trùng, hàng trăm liên kết giữa file. Vải nhận theo cây thường **ngắn hơn số trên tem** (trong một mẫu dữ liệu: trung vị khoảng 3 %, khoảng 1/3 số cây thiếu quá 5 %) mà không có dữ liệu theo nhà cung cấp / lot để khiếu nại. Sản lượng theo giờ có dấu hiệu "điền cho đẹp".
- **Quy trình:** đơn hàng (mã × màu × size, dung sai ±3 %) → định mức nguyên phụ liệu (hai phiên bản: của buyer và của nhà máy) → cân đối vải theo lịch xuất → kiểm vải → trải vải, cắt (sơ đồ, số lá, đầu tấm) → phát lên chuyền / gia công ngoài → may (sản lượng theo giờ) → hoàn thiện, đóng gói → xuất → quyết toán mã hàng.
- **Dữ liệu:** Catalog mã hàng (tabular section công đoạn + thời gian chuẩn SAM), nguyên phụ liệu, màu, size, chuyền; Document đơn hàng, nhập vải theo cây, phiếu trải cắt, phát chuyền, sản lượng may, hoàn thiện, xuất hàng; AccumulationRegister tồn NPL (theo lot, **chủ sở hữu khách / công ty**), bán thành phẩm theo công đoạn (WIP), hao hụt vải (Turnovers), sản lượng; InformationRegister định mức (chiều "loại định mức"), kế hoạch chuyền theo ngày, **sản lượng theo khung giờ** (dữ liệu ghi nhận — không cần Document).
- **KPI:** % đạt khoán; hiệu suất chuyền = (SL × SAM) / (số công nhân × phút làm việc); chênh lệch tiêu hao vải; % âm cây; tỷ lệ cắt / đơn, xuất / đơn.
- **Phù hợp:** lộ trình M (thiết kế đầy đủ ~8 catalog, 6–8 document, 5–6 accumulation register); lộ trình J chỉ phần mua NPL – kho – xuất thành phẩm (M1 vẽ luồng 15 bước); intern: lương khoán công đoạn, nhập sản lượng giờ trên mobile.

### 1.2. Bao bì carton (CARTON-C)
- **Bài toán:** đặt giấy theo khổ, lệnh sản xuất tổ sóng, theo dõi đơn qua ~9 công đoạn bằng Excel; nhật ký lỗi (in sai bản thiết kế, rộp, bế lệch) — có trường hợp hỏng cả đơn vì in sai bản thiết kế.
- **Quy trình:** đơn hàng (kích thước thùng, 3 / 5 lớp) → **cơ cấu giấy theo lớp** → tính lượng giấy → tổ sóng → in → bế → dán → kiểm → giao.
- **Dữ liệu:** Catalog giấy (khổ × định lượng), cơ cấu lớp (tabular section), bản thiết kế in có phiên bản; Document lệnh sản xuất, báo cáo công đoạn, phiếu lỗi; register tồn giấy theo khổ, tiến độ đơn theo công đoạn.
- **Phù hợp:** J — kho giấy + bán hàng (Jet) và M1 phân tích phần sản xuất; M — tính định mức giấy bằng code, theo dõi công đoạn.

### 1.3. Bao bì PP dệt (PP-B, nhiều pháp nhân)
- **Bài toán:** ~4 500 mã hàng, **thông số nhồi vào tên hàng** (màu, denier, gsm, khổ, kiểu dệt, in, tên khách); nhiều pháp nhân trên nhiều phần mềm; muốn tách phiếu kho khỏi hóa đơn, tồn min / max, theo dõi **phế liệu quay vòng thành nguyên liệu**, giá thành bình quân.
- **Quy trình:** hạt nhựa → sợi → manh (vải dệt) → bao; một số công đoạn gia công ngoài; duyệt báo giá → đơn → đề nghị mua → so sánh giá → đơn mua.
- **Dữ liệu:** Catalog sản phẩm + **Chart of characteristic types** cho thông số; tổ chức (nhiều pháp nhân); register tồn theo tầng sản phẩm, phế liệu.
- **Phù hợp:** M nâng cao, intern; bài tập "tách tên hàng thành thuộc tính", "làm sạch danh mục trước khi nhập ERP".

### 1.4. Vật liệu trang trí PU (PU-D, nhỏ: 7 người dùng, 3 kho)
- **Bài toán:** so sánh định mức nguyên liệu với thực tế; **cố định giá bán theo từng khách**; 4 mức giá cho một sản phẩm (theo hoàn thiện); chiết khấu cuối năm theo doanh thu / sản lượng; thuê gia công dát vàng, vân gỗ; muốn chuyển công nhật sang công theo sản lượng; giá thành gồm nguyên liệu + lương + khấu hao.
- **Phù hợp:** **J — case sát Jet nhất** (mua, bán nhiều kiểu giá, 3 kho, chiết khấu) + M2 mở rộng phần sản xuất đơn giản; M — đủ cho một hệ thống nhỏ trọn vẹn.

### 1.5. Dược phẩm GMP (DƯỢC-E)
- **Bài toán:** bộ yêu cầu ~125 dòng theo GMP: ai làm gì, lúc nào, **lịch sử thay đổi**; lô và hạn dùng; xuất FEFO / FIFO; **trạng thái QC** (biệt trữ → đạt / không đạt); vị trí pallet; giá thành.
- **Dữ liệu:** Catalog lô (hạn dùng), register tồn theo lô và vị trí, InformationRegister trạng thái lô (periodic), Document phiếu kiểm nghiệm; posting chặn xuất lô biệt trữ.
- **Phù hợp:** M, intern; J làm phiên bản kho (lô + trạng thái QC) — trùng một phần Đề 1 (lô và hạn dùng).
- **Lưu ý:** các yêu cầu tuân thủ (21 CFR Part 11, EU Annex 11) là **khẳng định pháp lý** — không nói "1C đáp ứng" khi chưa có văn bản của đội sản phẩm.

### 1.6. Xi măng / vật liệu xây dựng
- **Bài toán:** xe ra vào nhà máy: đăng ký → cân lần 1 → xếp hàng / xuất → cân lần 2 → hóa đơn, có RFID, barrier, app tài xế; kênh đại lý lớn với **hạn mức tín dụng**, phê duyệt nhiều cấp; vỏ bao.
- **Dữ liệu:** Document chuyến xe, phiếu cân; InformationRegister lịch sử trạng thái chuyến (state machine); register hàng chờ xuất, công nợ đại lý; InformationRegister hạn mức (periodic).
- **Phù hợp:** J (bán hàng, công nợ của Jet + chứng từ mới) và M; bài "từ sơ đồ swimlane sang metadata".

### 1.7. Nhựa / đá nhân tạo / hóa chất
- **Bài toán:** công thức phối liệu, nhiều công đoạn có bán thành phẩm, **khuôn** (tài sản đặc thù cần bảo trì), dừng máy, giá thành khi nguyên liệu biến động; kênh nhà phân phối với chiết khấu.
- **Phù hợp:** M (công đoạn, bán thành phẩm, khuôn); J — chiết khấu / hạn mức nhà phân phối.

### 1.8. Cơ khí theo đơn
- **Bài toán:** sản xuất theo bản vẽ, báo giá nhiều phương án, **nhận / thuê gia công** (vật tư không thuộc sở hữu của mình), lương khoán theo công đoạn; doanh nghiệp lớn hơn vào chuỗi ô tô cần quy trình chất lượng chặt.
- **Phù hợp:** M (routing, lương khoán); J — gia công: "tồn kho của ai" (register riêng cho vật tư của khách / vật tư ở đơn vị gia công).

### 1.9. Nội thất
- **Bài toán:** **BOM tham số** (kích thước, chất liệu thay đổi theo đơn), vật tư thay thế, giá thành kế hoạch trước khi nhận đơn.
- **Phù hợp:** M (Chart of characteristic types, query cây BOM); J chỉ M1 đọc BOM.

### 1.10. Thực phẩm / thương mại / phân phối
- **Bài toán:** bảng giá nhiều cấp, chiết khấu theo điều kiện, đơn từ app / sàn TMĐT, **hàng hoàn từ sàn** (tỷ lệ vài phần trăm, phải kiểm và khiếu nại trong thời hạn ngắn), đơn PDF hàng trăm dòng nhập tay, kho nhiều file Excel, lô / hạn dùng; nhiều pháp nhân.
- **Phù hợp:** **J** — sát Jet nhất (mua, bán, kho, tiền); xem ý tưởng E-series trong ngân hàng ý tưởng.

### 1.11. Nông nghiệp — vườn cây
- **Bài toán:** quản lý lô vườn, kiểm đếm cây, thu hoạch theo ngày / tổ, vật tư cho vườn.
- **Phù hợp:** M — bài mô hình hóa "vườn = kho, cây = tài sản, thu hoạch = sản xuất"; dữ liệu phải hư cấu.

### 1.12. Bảo trì thiết bị (mọi nhà máy, kho)
- **Bài toán:** báo hỏng → phiếu sửa chữa → vật tư thay thế → lịch bảo trì định kỳ → lịch sử từng thiết bị; tách rời kế hoạch sản xuất.
- **Dữ liệu (mini-CMMS):** Catalog thiết bị (hierarchy theo khu vực), loại công việc, phụ tùng; InformationRegister vị trí / tình trạng thiết bị (periodic), kế hoạch bảo trì; Document yêu cầu sửa chữa, phiếu công việc, xuất phụ tùng; AccumulationRegister tồn phụ tùng, chi phí bảo trì; báo cáo DCS: thiết bị hỏng nhiều, chi phí theo thiết bị, việc quá hạn; tự động sinh phiếu bảo trì khi đến hạn (scheduled job — M3).
- **Phù hợp:** M (rất tốt để dạy periodic InformationRegister); J — đổi bối cảnh sang bảo trì **xe nâng, băng tải** trong kho.

## 2. Jet và giải pháp thương mại của 1C — "Jet là bản thu nhỏ"

Jet (`jet/`) dùng cùng mẫu thiết kế với giải pháp quản trị doanh nghiệp vừa và nhỏ của 1C (1C:Company Management): dạng giá + bảng giá, công nợ theo chứng từ có tạm ứng. Phần giải pháp đầy đủ có mà Jet chưa có là nguồn đề tài:

| Khối | Giải pháp đầy đủ | Jet | Khoảng trống → đề tài |
|---|---|---|---|
| Danh mục | Đối tác + hợp đồng, mặt hàng + đặc tính / lô / sê-ri, kho + ô | Counterparties, Products, Warehouses | Hợp đồng, lô, ô kho, sê-ri |
| Bán | Đơn hàng → giao → trả hàng → thu tiền; ký gửi; bán lẻ | SalesInvoice → thu tiền | Đơn hàng, dự phòng hàng, trả hàng, ký gửi, bán lẻ |
| Mua | Nhu cầu → đơn NCC → nhận → chi phí mua → trả NCC | SupplierInvoice → chi tiền | Đơn NCC, chi phí mua phân bổ, trả NCC |
| Kho | 1 pha / 2 pha, ô hàng, kiểm kê, điều chuyển nhiều mục đích | InventoryIncrease / Transfer / WriteOff | Kho 2 pha, kiểm kê, ô kho, cấp phát sử dụng |
| Tiền | Kế hoạch, lịch thanh toán, đề nghị thanh toán có duyệt, tạm ứng | Thu chi + tạm ứng | Lịch thanh toán, duyệt chi |
| Sản xuất, lương, tài sản | Có | Không | Lộ trình M hoặc đề tài nâng cao |

Tên register phía giải pháp đầy đủ trong bảng là suy ra từ giao diện người dùng — khi cần chính xác, mở cấu hình thật để đối chiếu.

