# Ngân hàng ý tưởng mở rộng 1C:Jet cho bài tập lớn (ngoài 9 đề chính thức)

Khi nào đọc file này: khi nhóm muốn **tự đề xuất đề tài** hoặc cần **ý tưởng bổ sung** cho phần "Phát triển thêm" của bài tập lớn, khi giảng viên/tutor cần gợi ý đề mới không trùng 9 đề trong `de-bai-btl.md`, hoặc khi sinh viên hỏi "còn hướng mở rộng Jet nào khác không / tìm ý tưởng ở đâu".

> Mọi ý tưởng dưới đây là **đề xuất, chưa có trong Jet**. Phần "Jet đang có" đã đối chiếu với cấu hình Jet nhánh `community`, commit `80884de` (thư mục `cf/`). Mức M1/M2/M3, cách chấm và quy định chung theo `de-bai-btl.md` (mục 2.3). Ước lượng công sức là **[ước lượng]** của người soạn, không phải quy định của giảng viên — nhóm cần trao đổi với giảng viên trước khi chốt đề.

**9 đề chính thức (không lặp lại ở đây):** Đề 1 Lô hàng và hạn sử dụng · Đề 2 Định mức tồn kho chuỗi cửa hàng · Đề 3 Đơn đặt hàng nhà cung cấp · Đề 4 Đánh giá nhà cung cấp · Đề 5 Chiết khấu theo số lượng · Đề 6 Nhân viên kinh doanh và khu vực · Đề 7 Hạn thanh toán và tuổi nợ · Đề 8 Khoản mục chi phí và ngân sách · Đề 9 Kiểm kê kho và xử lý chênh lệch. Lưu ý Đề 1: ngay ở M2, cột Lô đã chạm SupplierInvoice và SalesInvoice của nhóm Purchases và Sales — cảnh báo va chạm áp dụng từ M2 (chi tiết: `de-tai-1-5.md`, mục 1.1 và mục 6).

## Mục lục

- [0. Cách đọc một thẻ ý tưởng](#0-cách-đọc-một-thẻ-ý-tưởng)
- [1. Ý tưởng theo phân hệ](#1-ý-tưởng-theo-phân-hệ)
  - [1.1. Warehouses (Kho) — W1–W8](#11-warehouses-kho--w1w8)
  - [1.2. Purchases (Mua hàng) — P1–P7](#12-purchases-mua-hàng--p1p7)
  - [1.3. Sales (Bán hàng) — S1–S7](#13-sales-bán-hàng--s1s7)
  - [1.4. CashManagement (Tiền) — C1–C7](#14-cashmanagement-tiền--c1c7)
  - [1.5. Liên phân hệ / Logistics — L1–L8](#15-liên-phân-hệ--logistics--l1l8)
  - [1.6. Tích hợp, di động, phân tích — I1–I3](#16-tích-hợp-di-động-phân-tích--i1i3-ngoài-24-bài-cho-nhóm-khá)
  - [1.7. Từ case doanh nghiệp thật — E1–E14](#17-từ-case-doanh-nghiệp-thật-đã-ẩn-danh--e1e14)
- [2. Bảng chọn đề nhanh](#2-bảng-chọn-đề-nhanh)
- [3. Nguồn để tìm thêm ý tưởng](#3-nguồn-để-tìm-thêm-ý-tưởng)
- [4. Hướng dẫn tự phát triển ý tưởng](#4-hướng-dẫn-tự-phát-triển-ý-tưởng)

---

## 0. Cách đọc một thẻ ý tưởng

Mỗi thẻ có cùng cấu trúc:

- **Bài toán** — nỗi đau nghiệp vụ của một doanh nghiệp giả định (bối cảnh Việt Nam).
- **Jet đang có** — những gì cấu hình gốc đã ghi nhận được, kèm `Nguồn: Jet — cf/...`.
- **Khoảng trống** — dữ liệu hoặc kiểm soát còn thiếu, gắn với hậu quả (mất tiền, mất hàng, chậm giao, quyết định sai).
- **Đối tượng thêm** — tên gợi ý (tiếng Anh, theo quy ước Jet), loại object 1C, mức M1/M2/M3.
- **Phù hợp** — *nhóm 2 (trái ngành)*: phần M2 đủ để đạt điểm thiết kế, code (nếu có) đơn giản; *nhóm 1 (IT)*: có hạng mục M3 đáng làm (posting, register mới, code form).
- **Khả thi** — công sức [ước lượng] (Thấp ≈ ≤1 tuần nhóm, Vừa ≈ 1–2 tuần, Cao ≈ >2 tuần), và **rủi ro chạm register dùng chung**: `InventoryInWarehouses`, `InventoryCost`, `CustomerBalance`, `SupplierBalance` được nhiều phân hệ ghi (`jet-overview.md` mục 5) — sửa chúng phải phối hợp với nhóm khác.

Quy ước mức (theo `de-bai-btl.md` 2.3): **M2** = Catalog, Enumeration, attribute mới, Information register nhập tay, Document **không ghi sổ**, Subsystem, báo cáo DCS trên dữ liệu có sẵn — không viết mã. **M3** = thêm dimension hoặc Accumulation register mới, sửa logic Posting, tự động hóa trên form.

> Lối tắt cho nhóm 2: Jet có sẵn **Additional attributes** của SSL cho Catalog Products, Counterparties, Warehouses… và cho 9 Document nghiệp vụ (tập `Catalog_Warehouses`, `Document_SalesInvoice`… — Nguồn: Jet — cf/CommonModules/PropertyManagerOverridable/Ext/Module.bsl). Wiki Jet gợi ý dùng công cụ này để thêm trường như "vị trí, người phụ trách, loại kho" cho kho (Nguồn: jet-wiki/1C:Jet-Initial-Setup-Guide.md). Đây là **dữ liệu nhập trong Enterprise mode**, không phải metadata mới — dùng tốt để thử ý tưởng nhanh (M1), nhưng hạng mục M2 của bài tập lớn yêu cầu thao tác trong Designer; hỏi giảng viên nếu muốn tính phần này.

---

## 1. Ý tưởng theo phân hệ

### 1.1. Warehouses (Kho) — W1–W8

#### W1 — Vị trí lưu kho (kệ / ô / bin)
- **Bài toán:** Kho phụ tùng ô tô 2.000 m² ở Bắc Ninh, thủ kho mới mất 10–15 phút tìm một mã hàng; hàng bị đặt sai kệ thì coi như "mất".
- **Jet đang có:** `Catalog.Warehouses` không phân cấp, chỉ có thông tin liên hệ và thuộc tính bổ sung; register kho chỉ phân tích theo `Product`, `Warehouse` (Nguồn: Jet — cf/Catalogs/Warehouses.xml, cf/AccumulationRegisters/InventoryInWarehouses.xml).
- **Khoảng trống:** không biết hàng nằm ở đâu trong kho → chậm soạn hàng, sai sót khi xuất.
- **Đối tượng thêm:**
  - `Catalog.StorageBins` — **Catalog** subordinate tới `Warehouses` (Owner), có thể hierarchical (Dãy → Kệ → Ô) — **M2**.
  - `InformationRegister.ProductLocations` — Warehouse, Product → StorageBin (vị trí mặc định), non-periodic — **M2**.
  - Báo cáo DCS "Tồn kho kèm vị trí": nối `InventoryInWarehouses.Balance` với register vị trí — **M2**.
  - Dimension `StorageBin` trong register tồn theo ô (register mới, không sửa `InventoryInWarehouses`) — **M3**.
- **Phù hợp:** nhóm 2 (phần M2 rất trực quan) / nhóm 1 (phần M3 register theo ô).
- **Khả thi:** M2 Thấp; M3 Cao vì phải ghi register mới từ mọi chứng từ kho. Không cần sửa register dùng chung nếu tách register riêng. Cơ chế: Owner + hierarchy (Bài 1–4), Information register (Bài 12), DCS (Bài 18).

#### W2 — Thủ kho phụ trách và lịch sử bàn giao kho
- **Bài toán:** Chuỗi 4 kho của một công ty phân phối đồ uống ở Đà Nẵng đổi thủ kho thường xuyên; khi thất thoát, không xác định được ai phụ trách kho tại ngày phát sinh.
- **Jet đang có:** Document kho có `Author` (người tạo chứng từ, kiểu `CatalogRef.Users`), không có người chịu trách nhiệm kho (Nguồn: Jet — cf/Documents/InventoryTransfer.xml, cf/Documents/SalesInvoice.xml).
- **Khoảng trống:** "người nhập liệu" khác "người chịu trách nhiệm"; không có lịch sử theo thời gian.
- **Đối tượng thêm:**
  - `Catalog.Employees` (nếu nhóm chưa có) — **M2**.
  - `InformationRegister.WarehouseResponsiblePersons` — **periodic** (Day), Warehouse → Employee — **M2**. Đây đúng mẫu "Companies responsible persons" trong Bài 12.
  - Báo cáo DCS chứng từ kho trong kỳ kèm thủ kho tại ngày chứng từ (SliceLast) — **M2/M3** (DCS có tham số ngày là M2; nếu cần lấy theo từng ngày chứng từ thì query phức tạp hơn).
  - Print form "Phiếu xuất kho" có chữ ký thủ kho — **M3** (`AddPrintCommands` của `InventoryTransfer`, `InventoryWriteOff` đang rỗng — Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ManagerModule.bsl).
- **Phù hợp:** nhóm 2 / nhóm 1 (print form).
- **Khả thi:** Thấp; không chạm register dùng chung. Bài 12 (periodic, independent), Bài 17 + 22 (print).

#### W3 — Kho cách ly hàng lỗi (quarantine) và tồn "có thể bán"
- **Bài toán:** Nhà phân phối điện gia dụng ở TP.HCM nhận hàng móp méo chờ nhà cung cấp xử lý; báo cáo tồn vẫn tính hàng này nên nhân viên bán hứa giao cho khách rồi không có hàng tốt.
- **Jet đang có:** báo cáo `AvailableStock` đọc `InventoryInWarehouses.Balance` cho mọi kho (Nguồn: Jet — cf/Reports/AvailableStock); `InventoryTransfer` chuyển hàng giữa hai kho.
- **Khoảng trống:** không phân biệt kho hàng tốt / kho chờ xử lý → bán nhầm hàng lỗi, sai cam kết giao hàng.
- **Đối tượng thêm:**
  - Attribute `IsQuarantine` (Boolean) hoặc `StockStatus` (Enumeration: Sellable / Quarantine / Damaged) trên `Warehouses` — **M2**.
  - Báo cáo DCS "Tồn có thể bán" lọc theo attribute trên — **M2**.
  - Enumeration `QuarantineReasons` + attribute trên `InventoryTransfer` khi chuyển vào kho cách ly — **M2**.
  - Chặn `SalesInvoice` xuất từ kho cách ly (FillCheckProcessing) — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1 (kiểm tra khi ghi).
- **Khả thi:** Thấp; M3 chạm `SalesInvoice` (của nhóm Sales) — phối hợp. Bài 12 (data validation).
- **Lưu ý trùng:** Đề 2 đã có "Loại kho (Kho tổng / Cửa hàng)" — ý tưởng này là trạng thái chất lượng, không phải loại kho; nhóm làm Đề 2 không chọn thêm.

#### W4 — Phiếu yêu cầu điều chuyển từ cửa hàng
- **Bài toán:** Cửa hàng gọi điện / nhắn Zalo xin hàng, kho tổng quên hoặc chuyển thiếu; không ai biết yêu cầu nào đã được đáp ứng.
- **Jet đang có:** `InventoryTransfer` (Warehouse, WarehouseReceiver, Inventory: Product, Quantity), không có chứng từ yêu cầu; `InventoryTransfer` không có `BasedOn` (Nguồn: Jet — cf/Documents/InventoryTransfer.xml).
- **Khoảng trống:** không có dấu vết "đã xin – đã chuyển – còn thiếu".
- **Đối tượng thêm:**
  - `Document.TransferRequest` — không ghi sổ: cửa hàng yêu cầu, kho nguồn, ngày cần, tabular section hàng — **M2**.
  - Enumeration `RequestStatuses` (New / Approved / PartiallyShipped / Shipped / Rejected) — **M2**.
  - Attribute `TransferRequest` trên `InventoryTransfer` — **M2**.
  - Tạo `InventoryTransfer` dựa trên yêu cầu (Generation + Filling) — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Vừa; không chạm register dùng chung. Bài 11 (Generation).
- **Lưu ý trùng:** khác Đề 2 (Đề 2 tự đề xuất điều chuyển từ định mức); có thể kết hợp nếu nhóm Đề 2 muốn thêm bước phê duyệt.

#### W5 — Quy đổi đơn vị tính (thùng / lốc / chai)
- **Bài toán:** Nhà phân phối nước giải khát nhập theo thùng 24 lon, bán lẻ theo lốc 6 lon; kế toán quy đổi bằng tay và hay sai.
- **Jet đang có:** `Catalog.Units` không có attribute nào; `Products.Unit` chỉ một đơn vị (Nguồn: Jet — cf/Catalogs/Units.xml, cf/Catalogs/Products.xml).
- **Khoảng trống:** một mặt hàng chỉ có một đơn vị → nhập sai số lượng gấp 6 hoặc 24 lần, lệch tồn kho.
- **Đối tượng thêm:**
  - `InformationRegister.ProductUnitConversions` — Product, Unit → Factor (hệ số quy về đơn vị gốc) — **M2**.
  - Cột `Unit` và `QuantityInUnit` trên tabular section `Inventory` của chứng từ — **M2** (chỉ lưu).
  - Tự tính `Quantity` = QuantityInUnit × Factor trên form — **M3**.
- **Phù hợp:** nhóm 2 (M2) / nhóm 1 (M3, cẩn thận vì `InventoryTabularSectionClientServer` dùng chung cho SupplierInvoice và SalesInvoice — Nguồn: Jet — cf/CommonModules/InventoryTabularSectionClientServer/Ext/Module.bsl).
- **Khả thi:** Vừa; M3 chạm form của nhiều chứng từ.

#### W6 — Khối lượng, thể tích và kế hoạch xếp xe
- **Bài toán:** Công ty vật liệu xây dựng giao bằng xe 2,5 tấn và 8 tấn; điều phối không biết một phiếu xuất nặng bao nhiêu nên xe chạy quá tải hoặc chạy rỗng.
- **Jet đang có:** `Products` có `DetailedDescription`, `ProductType`, `Unit`, `VATRate` — không có khối lượng, thể tích (Nguồn: Jet — cf/Catalogs/Products.xml).
- **Khoảng trống:** không tính được tải trọng chuyến → phạt quá tải, tốn chi phí vận chuyển.
- **Đối tượng thêm:**
  - Attribute `Weight`, `Volume` trên `Products` — **M2**.
  - Báo cáo DCS "Tổng khối lượng theo chứng từ xuất" đọc từ tabular section `Inventory` của `SalesInvoice` / `InventoryTransfer` nối với `Products` — **M2**.
  - Cảnh báo khi tổng khối lượng vượt tải trọng xe (kết hợp L1) — **M3**.
- **Phù hợp:** nhóm 2 (rất hợp lớp Logistics).
- **Khả thi:** Thấp; không chạm register. Báo cáo đọc từ chứng từ — xem câu hỏi "báo cáo đọc từ chứng từ khác báo cáo đọc từ sổ" ở Đề 6.

#### W7 — Mã vạch sản phẩm
- **Bài toán:** Siêu thị mini 3.000 mã hàng nhập bằng tay, nhân viên chọn nhầm mã gần tên ("Sữa TH 180ml" và "Sữa TH 110ml").
- **Jet đang có:** `Products` không có trường mã vạch (Nguồn: Jet — cf/Catalogs/Products.xml); có import danh mục từ file qua `ImportDataFromFileJet` (Nguồn: Jet — cf/CommonModules/ImportDataFromFileJet).
- **Khoảng trống:** chọn nhầm hàng → lệch tồn, sai giá.
- **Đối tượng thêm:**
  - `InformationRegister.Barcodes` — Barcode (String) → Product, Unit — **M2** (một sản phẩm nhiều mã, mỗi mã một sản phẩm: chiều là Barcode).
  - Ô nhập mã vạch trên form chứng từ, tìm sản phẩm và thêm dòng — **M3**.
- **Phù hợp:** nhóm 2 (thiết kế register) / nhóm 1 (form).
- **Khả thi:** Thấp–Vừa; không chạm register dùng chung. Câu hỏi thiết kế hay: vì sao Barcode là chiều chứ không phải attribute của Products?

#### W8 — Thẻ kho và nhật ký chứng từ kho
- **Bài toán:** Kế toán kho cần "thẻ kho" theo mẫu quen thuộc (nhập – xuất – tồn từng chứng từ) và một danh sách chung mọi chứng từ kho để rà soát cuối ngày.
- **Jet đang có:** `StockStatement` (tổng hợp theo kỳ, từ `InventoryCost.BalanceAndTurnovers`); Document journal duy nhất là `Interactions` của SSL — không có nhật ký chứng từ kho (Nguồn: Jet — cf/Reports/StockStatement, cf/DocumentJournals/Interactions.xml).
- **Khoảng trống:** khó truy vết từng nghiệp vụ của một mặt hàng.
- **Đối tượng thêm:**
  - Báo cáo DCS "Thẻ kho" theo Recorder — **M2** (DCS trên register có sẵn; xem `jet-warehouse.md` Gợi ý 4).
  - `DocumentJournal.WarehouseDocuments` gồm 5 chứng từ có ghi kho, cột Warehouse — **M2** (Bài 13).
- **Phù hợp:** nhóm 2 — đề "khởi động" tốt, nên ghép với một ý tưởng khác cho đủ khối lượng.
- **Khả thi:** Thấp; chỉ đọc dữ liệu.

### 1.2. Purchases (Mua hàng) — P1–P7

#### P1 — Trả hàng cho nhà cung cấp
- **Bài toán:** Công ty thiết bị y tế trả lại lô máy đo huyết áp lỗi; hiện kế toán "xuất hủy" bằng `InventoryWriteOff` nên công nợ phải trả không giảm.
- **Jet đang có:** chỉ `SupplierInvoice` ghi `SupplierBalance`; `InventoryWriteOff` không có đơn giá, không có nhà cung cấp (Nguồn: Jet — cf/Documents/SupplierInvoice.xml, cf/Documents/InventoryWriteOff.xml).
- **Khoảng trống:** tồn kho giảm nhưng nợ nhà cung cấp không giảm → trả tiền cho hàng đã trả lại.
- **Đối tượng thêm:**
  - `Document.SupplierReturn` — không ghi sổ, attribute `SupplierInvoice` (hóa đơn gốc), tabular section hàng — **M2**.
  - Enumeration `ReturnReasons` (Defective / WrongItem / Excess / Expired) — **M2**.
  - Posting: Expense `InventoryInWarehouses`, `InventoryCost`, `SupplierBalance`; số âm vào `Purchases` — **M3** (chi tiết: `jet-purchases.md` Gợi ý 2).
- **Phù hợp:** nhóm 2 (M2) / nhóm 1 (M3 — đề nặng).
- **Khả thi:** M3 Cao; **chạm 3 register dùng chung** và `Sequence.InventoryCostRecalculation` → phối hợp nhóm Kho và nhóm Tiền.

#### P2 — Bảng giá mua theo nhà cung cấp
- **Bài toán:** Nhà hàng chuỗi mua rau, thịt từ 5 nhà cung cấp, giá đổi hằng tuần; nhân viên mua nhập giá theo trí nhớ.
- **Jet đang có:** `SupplierInvoice` nhập giá tay; `InformationRegister.Prices` (periodic Day, Independent) chỉ dùng cho giá bán theo `PriceType` (Nguồn: Jet — cf/InformationRegisters/Prices.xml).
- **Khoảng trống:** không có giá mua thỏa thuận để đối chiếu → mua đắt mà không biết.
- **Đối tượng thêm:**
  - `InformationRegister.SupplierPrices` — periodic Day, Counterparty, Product → Price — **M2**.
  - Báo cáo DCS so sánh giá thỏa thuận (SliceLast) với giá thực mua (sổ `Purchases`) — **M2**.
  - Tự điền giá khi chọn sản phẩm trên `SupplierInvoice` — **M3** (`jet-purchases.md` Gợi ý 3).
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Thấp–Vừa. **Lưu ý trùng:** Đề 4 có báo cáo giá mua bình quân và cam kết cung ứng; P2 là giá thỏa thuận theo thời gian — nhóm Đề 4 không chọn thêm.

#### P3 — Chi phí mua hàng (vận chuyển, bốc xếp, hải quan)
- **Bài toán:** Công ty nhập khẩu hạt nhựa trả thêm phí vận chuyển nội địa và phí hải quan bằng 5–8% giá hàng; giá vốn trên Jet thấp hơn thực tế nên lãi gộp bị "ảo".
- **Jet đang có:** `InventoryCost` nhận `Amount` từ `SupplierInvoice`; không có chứng từ phân bổ chi phí (Nguồn: Jet — cf/AccumulationRegisters/InventoryCost.xml).
- **Khoảng trống:** giá vốn thiếu chi phí mua → định giá bán sai, báo cáo `ProfitOnSales` cao hơn thực.
- **Đối tượng thêm:**
  - `Document.AdditionalPurchaseCosts` — không ghi sổ: nhà cung cấp dịch vụ, hóa đơn hàng gốc, số tiền, cách phân bổ (Enumeration: ByAmount / ByQuantity / ByWeight) — **M2**.
  - Posting: Receipt chỉ `Amount` vào `InventoryCost`, Receipt `SupplierBalance` — **M3** (`jet-purchases.md` Gợi ý 6, đề khó nhất).
- **Phù hợp:** nhóm 2 (M1 + M2 phân tích tác động giá vốn) / nhóm 1 mạnh (M3).
- **Khả thi:** M3 Cao, rủi ro lớn: `InventoryCost`, `SupplierBalance`, Sequence.

#### P4 — Hợp đồng khung với nhà cung cấp
- **Bài toán:** Công ty xây dựng ký hợp đồng năm với nhà cung cấp thép (giá trần, thời hạn, tổng giá trị); mua vượt giá trị hợp đồng mà không ai hay.
- **Jet đang có:** `Counterparties` có `Customer`, `Supplier`, `LegalName`, `TIN`, `PriceType`… — không có hợp đồng (Nguồn: Jet — cf/Catalogs/Counterparties.xml).
- **Khoảng trống:** không gắn hóa đơn với hợp đồng → vượt hạn mức, mua sau khi hợp đồng hết hạn.
- **Đối tượng thêm:**
  - `Catalog.Contracts` — subordinate tới `Counterparties` (Owner): ValidFrom, ValidTo, ContractAmount, Currency — **M2**.
  - Attribute `Contract` trên `SupplierInvoice`, choice parameter link lọc theo `Supplier` — **M2** (Bài 1–4 có đúng ví dụ Contract lọc theo Customer bằng `Filter.Owner`).
  - Báo cáo DCS "Thực hiện hợp đồng" (đã mua / giá trị hợp đồng) đọc từ chứng từ — **M2**.
  - Chặn ghi hóa đơn ngoài thời hạn hợp đồng — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1. Áp dụng tương tự phía bán (hợp đồng khách hàng).
- **Khả thi:** Thấp–Vừa; không chạm register.

#### P5 — Kiểm tra chất lượng khi nhận hàng (QC)
- **Bài toán:** Công ty thực phẩm đông lạnh phải kiểm nhiệt độ, bao bì khi nhận; hàng không đạt vẫn được nhập kho chung vì không có bước ghi nhận.
- **Jet đang có:** `SupplierInvoice` ghi thẳng vào kho khi post; có print form `PF_MXL_GoodsReceivedNote` (Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl).
- **Khoảng trống:** không có kết quả kiểm định → không có căn cứ đòi nhà cung cấp, hàng lỗi lẫn vào hàng tốt.
- **Đối tượng thêm:**
  - `Document.GoodsInspection` — không ghi sổ: SupplierInvoice, người kiểm, tabular section Product, QuantityChecked, QuantityRejected, Result — **M2**.
  - Enumeration `InspectionResults` (Passed / Rejected / ConditionallyAccepted) — **M2**.
  - Báo cáo DCS tỷ lệ hàng lỗi theo nhà cung cấp — **M2**.
  - Tạo `InventoryTransfer` sang kho cách ly (W3) từ phiếu kiểm — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Vừa; không chạm register ở mức M2.

#### P6 — Hàng mua đang đi đường (nhập khẩu)
- **Bài toán:** Công ty nhập linh kiện từ Thâm Quyến, nhận hóa đơn khi hàng xuống tàu, 7–12 ngày sau mới về kho Hải Phòng; báo cáo tồn kho "có hàng" khi hàng còn trên biển.
- **Jet đang có:** `SupplierInvoice` ghi Receipt vào `Warehouse` của chứng từ ngay khi post (Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl).
- **Khoảng trống:** không tách "đã là của mình nhưng chưa về kho" → hứa giao sai, khó theo dõi container.
- **Đối tượng thêm:**
  - Cách làm **không cần Designer** (M1 + dữ liệu): tạo một item Warehouses "Hàng đi đường", nhập hóa đơn vào kho này, khi hàng về dùng `InventoryTransfer` sang kho thật — dùng để phân tích trong phần "Vận hành Jet gốc".
  - Attribute `ContainerNumber`, `VesselName`, `ETA` (ngày dự kiến về) trên `SupplierInvoice` — **M2**.
  - Báo cáo DCS "Lô hàng đang về theo ETA" — **M2**.
- **Phù hợp:** nhóm 2 (rất hợp Logistics).
- **Khả thi:** Thấp. **Lưu ý trùng:** Đề 3 theo dõi "đã đặt nhưng chưa nhận hóa đơn"; P6 là "đã nhận hóa đơn nhưng hàng chưa về" — hai giai đoạn khác nhau của cùng chuỗi.

#### P7 — Đề nghị mua hàng nội bộ và phê duyệt
- **Bài toán:** Phòng ban gửi email xin mua; giám đốc duyệt miệng; cuối tháng không biết khoản mua nào đã được duyệt.
- **Jet đang có:** không có chứng từ trước `SupplierInvoice`.
- **Khoảng trống:** mua không qua duyệt → chi vượt, khó kiểm soát nội bộ.
- **Đối tượng thêm:**
  - `Document.PurchaseRequest` — không ghi sổ: bộ phận đề nghị, người duyệt, tabular section hàng, lý do — **M2**.
  - Enumeration `ApprovalStatuses` — **M2** (dùng lại cho C6).
  - Role riêng chỉ cho người duyệt sửa trạng thái — **M2/M3** (Bài 20; tạo role là khai báo, nhưng giới hạn theo trạng thái cần code).
- **Phù hợp:** nhóm 2.
- **Khả thi:** Thấp. Bổ sung tự nhiên cho Đề 3 (đề nghị → đơn đặt hàng → hóa đơn).

### 1.3. Sales (Bán hàng) — S1–S7

#### S1 — Đơn đặt hàng của khách (SalesOrder) và giữ hàng
- **Bài toán:** Nhà phân phối thiết bị vệ sinh nhận đơn của đại lý trước 3–5 ngày; hai nhân viên bán cùng một lô cho hai khách vì không ai "giữ hàng".
- **Jet đang có:** chỉ `SalesInvoice` (ghi nhận đã bán); không có đơn bán (Nguồn: Jet — cf/Documents/SalesInvoice.xml; `de-bai-btl.md` mục 1.4).
- **Khoảng trống:** không biết hàng đã hứa cho ai → bán trùng, giao trễ.
- **Đối tượng thêm:**
  - `Document.SalesOrder` — không ghi sổ, header giống `SalesInvoice` (Customer, Warehouse, PriceType…), tabular section `Inventory` cùng cột — **M2**.
  - Enumeration `SalesOrderStatuses` (New / Confirmed / PartiallyShipped / Shipped / Cancelled) — **M2**.
  - Attribute `SalesOrder` trên `SalesInvoice` — **M2**.
  - `AccumulationRegister.SalesOrders` (Balances): SalesOrder ghi Receipt, SalesInvoice ghi Expense; báo cáo "Đơn chưa giao" — **M3** (`jet-sales.md` Gợi ý 1).
- **Phù hợp:** nhóm 2 / nhóm 1 (M3 rất đáng làm).
- **Khả thi:** M2 Thấp, M3 Vừa–Cao; M3 sửa `InitializeDocumentData` của `SalesInvoice` (nhớ chỉ số `QueryResult[i]`). Đề này là "bản đối xứng" của Đề 3 phía bán.

#### S2 — Khách trả hàng
- **Bài toán:** Chuỗi bán lẻ mỹ phẩm cho đổi trả trong 7 ngày; hiện nhập lại bằng `InventoryIncrease` nên doanh số và công nợ khách không giảm.
- **Jet đang có:** `InventoryIncrease` (dùng nhập số dư đầu) ghi kho nhưng không ghi `Sales`, `CustomerBalance` (Nguồn: Jet — cf/Documents/InventoryIncrease.xml).
- **Khoảng trống:** doanh thu và công nợ bị thổi phồng; giá vốn hàng trả lại sai.
- **Đối tượng thêm:**
  - `Document.CustomerReturn` — không ghi sổ, attribute `SalesInvoice`, Enumeration `ReturnReasons` — **M2**.
  - Posting: số âm vào `Sales`, Receipt kho theo giá vốn của hóa đơn gốc, Expense `CustomerBalance` — **M3** (`jet-sales.md` Gợi ý 2).
- **Phù hợp:** nhóm 2 (M2) / nhóm 1 (M3). Với nhóm 1: cơ chế giống bài thực hành Bài 11 (ReturnOfGoodsFromCustomer) — tutor chỉ **gợi ý** theo mục 3a của SKILL.md.
- **Khả thi:** M3 Cao; **chạm `InventoryCost`, `CustomerBalance`**, type của dimension `Sales.SalesDocument`, Sequence; báo cáo `ProfitOnSales` cần xem lại.

#### S3 — Báo giá (Quotation)
- **Bài toán:** Công ty thiết bị văn phòng gửi báo giá cho 30 khách/tuần bằng Excel; không biết tỷ lệ báo giá thành đơn, giá đã báo cho ai.
- **Jet đang có:** report `PriceList` in bảng giá theo loại giá (Nguồn: Jet — cf/Reports/PriceList); không có chứng từ báo giá.
- **Khoảng trống:** mất dấu cơ hội bán, báo giá không nhất quán giữa các nhân viên.
- **Đối tượng thêm:**
  - `Document.Quotation` — không ghi sổ: Customer, ValidUntil, PriceType, tabular section hàng — **M2**.
  - Enumeration `QuotationStatuses` (Sent / Accepted / Rejected / Expired) — **M2**.
  - Báo cáo DCS tỷ lệ chuyển đổi báo giá → hóa đơn — **M2** (nếu có attribute liên kết trên SalesInvoice).
  - Tạo `SalesOrder`/`SalesInvoice` dựa trên báo giá, in báo giá — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Thấp–Vừa; không chạm register.

#### S4 — Nhiều địa chỉ giao hàng của một khách
- **Bài toán:** Một chuỗi siêu thị có 12 điểm nhận hàng; hóa đơn chỉ ghi tên công ty nên xe giao nhầm điểm.
- **Jet đang có:** `Counterparties` có contact information kiểu `CounterpartyActualAddress`, `CounterpartyLegalAddress` (Nguồn: Jet — cf/CommonModules/ContactsManagerOverridable/Ext/Module.bsl); `SalesInvoice` không có địa chỉ giao.
- **Khoảng trống:** không xác định điểm giao trên từng hóa đơn → giao nhầm, tốn chuyến.
- **Đối tượng thêm:**
  - `Catalog.DeliveryPoints` — subordinate tới `Counterparties`: địa chỉ, người nhận, số điện thoại, khung giờ nhận — **M2**.
  - Attribute `DeliveryPoint` trên `SalesInvoice` (lọc theo Customer) — **M2**.
  - Báo cáo DCS sản lượng giao theo điểm — **M2**.
- **Phù hợp:** nhóm 2. Ghép tốt với L1.
- **Khả thi:** Thấp.

#### S5 — Kênh bán hàng (bán buôn / bán lẻ / sàn TMĐT)
- **Bài toán:** Công ty đồ gia dụng bán qua đại lý, cửa hàng, Shopee, TikTok Shop; ban giám đốc muốn biết lãi gộp theo kênh để quyết định đầu tư.
- **Jet đang có:** sổ `Sales` phân tích theo Counterparty, Product, SalesDocument (Nguồn: Jet — cf/AccumulationRegisters/Sales.xml).
- **Khoảng trống:** không phân tích được theo kênh → phân bổ ngân sách marketing sai.
- **Đối tượng thêm:**
  - `Catalog.SalesChannels` (có thể hierarchical: Online → Shopee, TikTok Shop) — **M2**.
  - Attribute `SalesChannel` trên `SalesInvoice` (mặc định từ khách hàng) — **M2**.
  - Báo cáo DCS doanh số theo kênh đọc từ chứng từ — **M2**.
  - Dimension `SalesChannel` trong `Sales` — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Thấp (M2). **Lưu ý trùng:** cùng khuôn với Đề 6 (khu vực, nhân viên) — nhóm Đề 6 không chọn thêm; câu hỏi "gắn vào khách hay vào hóa đơn" của Đề 6 áp dụng y hệt.

#### S6 — Lãi gộp chưa VAT
- **Bài toán:** Giám đốc so lãi gộp trên Jet với báo cáo của kế toán thuế, chênh đúng bằng tiền thuế GTGT.
- **Jet đang có:** report `ProfitOnSales` tính doanh thu gồm VAT:

  Nguồn: Jet — cf/Reports/ProfitOnSales/Templates/MainDataCompositionSchema/Ext/Template.xml
  ```
  	SalesTurnovers.AmountTurnover + SalesTurnovers.VATAmountTurnover
  ```
  còn giá vốn lấy từ `InventoryCost` (giá chưa VAT) — xem `jet-sales.md` mục 12.
- **Khoảng trống:** lợi nhuận gộp bị thổi phồng → định giá và thưởng sai.
- **Đối tượng thêm:** variant hoặc report DCS mới với doanh thu chưa VAT, cột tỷ suất lãi gộp — **M2** (DCS trên dữ liệu có sẵn).
- **Phù hợp:** nhóm 2 (đề phân tích tốt) / nhóm 1 (luyện DCS).
- **Khả thi:** Thấp; chỉ đọc. Nên ghép với ý tưởng khác. Trình bày như "quan sát", không khẳng định là lỗi của Jet.

#### S7 — Hóa đơn điện tử (thông tin quản lý)
- **Bài toán:** Doanh nghiệp Việt Nam phải xuất hóa đơn điện tử (Nghị định 123/2020/NĐ-CP); kế toán xuất trên phần mềm của nhà cung cấp HĐĐT rồi không đối chiếu được với hóa đơn bán trên Jet.
- **Jet đang có:** bản gốc không có gì về hóa đơn điện tử. Bản Thổ Nhĩ Kỳ **Jet-TR** có cả phân hệ `EDI` (xem mục 3.2): `SalesInvoice` thêm `IsEInvoice`, `EDocumentNumber`, `EDocumentScenario`…, register `EDocumentsStatuses` (Independent, dimension `ElectronicDocument`) (Nguồn: Jet-TR — cf/Documents/SalesInvoice.xml, cf/InformationRegisters/EDocumentsStatuses.xml).
- **Khoảng trống:** không biết hóa đơn bán nào đã có HĐĐT, số/ký hiệu nào, đã bị hủy hay thay thế chưa → rủi ro thuế.
- **Đối tượng thêm:**
  - Attribute `EInvoiceSymbol`, `EInvoiceNumber`, `EInvoiceDate` trên `SalesInvoice` — **M2**.
  - Enumeration `EInvoiceStatuses` (NotIssued / Issued / Replaced / Cancelled) — **M2**.
  - `InformationRegister.EInvoiceStatusHistory` — periodic, SalesInvoice → Status — **M2** (mô phỏng `EDocumentsStatuses` của Jet-TR).
  - Báo cáo DCS "Hóa đơn bán chưa xuất HĐĐT" — **M2**.
  - Kết nối thật với nhà cung cấp HĐĐT — **ngoài phạm vi** (Jet-TR dùng `EDMServer`, `UBLServer`; tham khảo, không yêu cầu).
- **Phù hợp:** nhóm 2 / nhóm 1 (đọc code Jet-TR để học cách tổ chức).
- **Khả thi:** M2 Thấp. Nội dung bắt buộc của HĐĐT: tra văn bản pháp luật hiện hành (mục 3.3), không suy đoán.

### 1.4. CashManagement (Tiền) — C1–C7

#### C1 — Chuyển tiền nội bộ (nộp tiền vào ngân hàng, rút về quỹ)
- **Bài toán:** Cửa hàng nộp tiền mặt cuối ngày vào ngân hàng; kế toán phải làm một `CashVoucher` "Other" và một `BankReceipt` "Other" rời rạc, hay quên một nửa.
- **Jet đang có:** 4 chứng từ thu/chi; Operation chỉ có Supplier/Customer và Other (Nguồn: Jet — cf/Enums/CashVoucherOperations.xml, cf/Enums/BankReceiptOperations.xml).
- **Khoảng trống:** tiền "biến mất" khỏi quỹ mà chưa vào ngân hàng → lệch số dư, khó phát hiện thất thoát.
- **Đối tượng thêm:**
  - `Document.CashTransfer` không ghi sổ (lệnh chuyển: AccountFrom, AccountTo, Amount) để ghi nhận yêu cầu — **M2**.
  - Posting 2 dòng vào `CashBalance` (Expense nguồn, Receipt đích) — **M3** (`jet-cash.md` Gợi ý 1).
- **Phù hợp:** nhóm 2 (M2 + phân tích) / nhóm 1 (M3 gọn, đề M3 "nhập môn" tốt).
- **Khả thi:** M3 Vừa; chỉ chạm `CashBalance` (của chính nhóm Tiền).

#### C2 — Kiểm soát quỹ âm
- **Bài toán:** Thủ quỹ chi vượt số tiền đang có, cuối ngày quỹ âm trên sổ — dấu hiệu nhập sai thứ tự hoặc chi không có tiền thật.
- **Jet đang có:** `CashBalance` không có module (không có thư mục `Ext`), trong khi `InventoryInWarehouses` có `RecordSetModule` kiểm tra âm kho (Nguồn: Jet — cf/AccumulationRegisters/CashBalance.xml, cf/AccumulationRegisters/InventoryInWarehouses/Ext/ManagerModule.bsl).
- **Khoảng trống:** không chặn chi quá số dư.
- **Đối tượng thêm:**
  - Báo cáo DCS "Quỹ/tài khoản có số dư âm trong kỳ" từ `CashBalance` — **M2**.
  - Constant "Kiểm soát âm quỹ" — **M2** (Bài 13).
  - Kiểm tra âm quỹ khi post theo mẫu `NegativeBalanceControl` — **M3** (`jet-cash.md` Gợi ý 2).
- **Phù hợp:** nhóm 2 (M2) / nhóm 1 (M3, đề kỹ thuật hay).
- **Khả thi:** M3 Vừa–Cao (DataLock, thứ tự event).

#### C3 — Mẫu in phiếu thu / phiếu chi
- **Bài toán:** Mọi khoản thu chi tiền mặt cần phiếu có chữ ký; hiện kế toán gõ lại trên Word.
- **Jet đang có:** 4 chứng từ đã được đăng ký với SSL Print nhưng `AddPrintCommands` rỗng (Nguồn: Jet — cf/Documents/CashReceipt/Ext/ManagerModule.bsl); có `CurrencyRateOperations.GenerateAmountInWords` để in số tiền bằng chữ (Nguồn: Jet — cf/CommonModules/CurrencyRateOperations/Ext/Module.bsl).
- **Khoảng trống:** không có chứng từ giấy hợp lệ để ký.
- **Đối tượng thêm:** template + print command — **M3** (print form cần code, Bài 17 + 22; `jet-cash.md` Gợi ý 5). Nhóm 2 làm phần M1: thiết kế mẫu phiếu, xác định trường lấy từ đâu.
- **Phù hợp:** nhóm 1.
- **Khả thi:** Vừa; không chạm register.

#### C4 — Đối chiếu sổ phụ ngân hàng
- **Bài toán:** Mỗi tháng kế toán so sổ phụ ngân hàng (file Excel) với Jet bằng mắt, mất 2 ngày; có giao dịch phí ngân hàng chưa ghi.
- **Jet đang có:** `CashBalance` theo `BankCashAccount`, `CashType`; report `CashStatement` (Nguồn: Jet — cf/AccumulationRegisters/CashBalance.xml, cf/Reports/CashStatement).
- **Khoảng trống:** không lưu sổ phụ để đối chiếu → sai số dư, bỏ sót phí.
- **Đối tượng thêm:**
  - `Document.BankStatement` — không ghi sổ: BankAccount, kỳ, tabular section (Date, Amount, Description, MatchedDocument) — **M2**.
  - Báo cáo DCS so sánh tổng phát sinh theo sổ phụ với `CashBalance` — **M2**.
  - Nạp sổ phụ từ Excel, tự khớp chứng từ — **M3** (Bài 19).
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Vừa; chỉ đọc register.

#### C5 — Lịch thu chi dự kiến theo ngày
- **Bài toán:** Công ty thương mại cần biết tuần sau có đủ tiền trả lô hàng nhập 2 tỷ không; hiện ước lượng trên Excel.
- **Jet đang có:** `CashBalance` cho số dư hiện tại; `CustomerBalance`, `SupplierBalance` cho công nợ theo hóa đơn (Nguồn: Jet — cf/AccumulationRegisters/CustomerBalance.xml).
- **Khoảng trống:** không có dòng tiền kỳ vọng theo ngày → thiếu tiền đột xuất, vay nóng.
- **Đối tượng thêm:**
  - `Document.PaymentPlan` — không ghi sổ: tabular section (PlannedDate, Counterparty, Direction: Enumeration Inflow/Outflow, Amount, BaseDocument) — **M2**.
  - Báo cáo DCS "Số dư hiện tại + thu dự kiến – chi dự kiến theo ngày" — **M2/M3** (hai data set, Bài 18).
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Vừa. **Lưu ý trùng:** Đề 8 lập ngân sách theo khoản mục và tháng; C5 theo ngày và đối tác. Đề 7 (hạn thanh toán) là nguồn dữ liệu tự nhiên cho C5 — không chọn cùng lúc với Đề 7.

#### C6 — Phê duyệt chi
- **Bài toán:** Kế toán thanh toán theo tin nhắn của trưởng phòng; kiểm toán nội bộ yêu cầu mọi khoản chi trên 20 triệu phải có người duyệt.
- **Jet đang có:** `BankPayment` có `Paid` và `PaymentDate`, và chỉ ghi sổ khi `Paid` = True:

  Nguồn: Jet — cf/Documents/BankPayment/Ext/ManagerModule.bsl (1C:Jet, MIT)
  ```bsl
  	|WHERE
  	|	BankPayment.Ref = &Ref
  	|	AND BankPayment.Paid
  ```
  `CashVoucher` không có cờ tương tự.
- **Khoảng trống:** không phân biệt "ai đề nghị – ai duyệt – ai chi".
- **Đối tượng thêm:**
  - Enumeration `ApprovalStatuses` + attribute `ApprovalStatus`, `ApprovedBy` trên `CashVoucher`, `BankPayment` — **M2**.
  - Role "Người duyệt chi" — **M2** (Bài 20).
  - Chặn post khi chưa duyệt, hoặc lưu lịch sử duyệt vào information register — **M3** (giống bài thực hành Bài 12 về State và lịch sử state — nhóm 1 chỉ nhận gợi ý).
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** Thấp–Vừa; không chạm register dùng chung.

#### C7 — Tạm ứng cho nhân viên
- **Bài toán:** Công ty vận tải tạm ứng tiền dầu, phí cầu đường cho tài xế; cuối chuyến tài xế quyết toán. Kế toán không biết mỗi tài xế còn giữ bao nhiêu tiền công ty.
- **Jet đang có:** chi "Other" chỉ ghi `CashBalance`, không ghi công nợ với ai (Nguồn: Jet — cf/Documents/CashVoucher/Ext/ManagerModule.bsl: điều kiện `Operation = VALUE(Enum.CashVoucherOperations.Supplier)` cho bảng công nợ).
- **Khoảng trống:** tiền tạm ứng không được theo dõi → thất thoát, quyết toán chậm.
- **Đối tượng thêm:**
  - `Catalog.Employees` — **M2**.
  - Attribute `Employee` trên `CashVoucher`, `CashReceipt` (dùng khi Operation = Other) — **M2**.
  - `Document.AdvanceReport` (báo cáo quyết toán tạm ứng) không ghi sổ — **M2**.
  - `AccumulationRegister.EmployeeSettlements` (Balances: Employee; Amount) — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** M2 Thấp; M3 Vừa (register riêng, không chạm register công nợ của khách/nhà cung cấp). **Lưu ý trùng:** Đề 8 phân loại *mục đích* chi; C7 theo dõi *người giữ tiền* — có thể kết hợp nếu giảng viên đồng ý.

### 1.5. Liên phân hệ / Logistics — L1–L8

#### L1 — Theo dõi giao hàng và vận chuyển
- **Bài toán:** Nhà phân phối hàng tiêu dùng ở Hà Nội có 6 xe tải; khách gọi hỏi "hàng đâu" thì phải gọi tài xế; không đo được tỷ lệ giao đúng hẹn.
- **Jet đang có:** `SalesInvoice`, `InventoryTransfer` ghi nhận xuất kho; không có xe, tài xế, trạng thái giao (Nguồn: Jet — cf/Documents/SalesInvoice.xml).
- **Khoảng trống:** không biết hàng đã rời kho nhưng chưa tới khách; không đánh giá được đội xe / nhà vận chuyển.
- **Đối tượng thêm:**
  - `Catalog.Vehicles` (biển số, tải trọng, thể tích thùng) và `Catalog.Drivers` (hoặc dùng `Employees`) — **M2**.
  - `Document.DeliveryNote` — không ghi sổ: Vehicle, Driver, Carrier (Counterparties), PlannedDate, ActualDate, tabular section các `SalesInvoice`/`InventoryTransfer` trên chuyến — **M2**.
  - Enumeration `DeliveryStatuses` (Planned / InTransit / Delivered / Failed) — **M2**.
  - Báo cáo DCS tỷ lệ giao đúng hẹn theo xe/tài xế — **M2**.
  - Tạo phiếu giao từ hóa đơn, kiểm tra tải trọng (kết hợp W6) — **M3**.
- **Phù hợp:** nhóm 2 (đề "đinh" cho lớp Logistics) / nhóm 1 (phần M3).
- **Khả thi:** M2 Vừa (nhiều object nhưng đều đơn giản); không chạm register.

#### L2 — Hàng đang vận chuyển giữa hai kho
- **Bài toán:** Kho Hà Nội chuyển hàng vào kho TP.HCM mất 3 ngày; `InventoryTransfer` trừ kho xuất và cộng kho nhận cùng lúc nên trong 3 ngày đó kho TP.HCM "có hàng ảo".
- **Jet đang có:** `InventoryTransfer` ghi Expense ở `Warehouse` và Receipt ở `WarehouseReceiver` trong cùng một lần post (Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ManagerModule.bsl).
- **Khoảng trống:** không phản ánh thời gian trên đường → bán hàng chưa về, khó phát hiện mất hàng khi vận chuyển.
- **Đối tượng thêm:**
  - Cách làm **không cần Designer**: thêm item Warehouses "Đang vận chuyển" và chuyển hai bước (M1 + dữ liệu — tốt cho phần vận hành).
  - Attribute `ShippedDate`, `ReceivedDate`, `ReceivedBy` trên `InventoryTransfer` — **M2**.
  - `AccumulationRegister.GoodsInTransit` (Balances: Product, WarehouseFrom, WarehouseTo) và chứng từ xác nhận nhận hàng — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1.
- **Khả thi:** M3 Cao; nếu sửa posting của `InventoryTransfer` thì chạm `InventoryInWarehouses`, `InventoryCost`, Sequence.

#### L3 — Điểm đặt hàng lại theo lead time
- **Bài toán:** Nhà phân phối thuốc thú y mỗi tháng hết hàng 4–5 mã chủ lực vì đặt hàng khi tồn đã gần 0 trong khi nhà cung cấp cần 10–20 ngày.
- **Jet đang có:** tồn kho (`InventoryInWarehouses`), doanh số theo kỳ (`Sales`, kind Turnovers) (Nguồn: Jet — cf/AccumulationRegisters/Sales.xml).
- **Khoảng trống:** không có lead time và mức tiêu thụ bình quân để biết *khi nào* phải đặt.
- **Đối tượng thêm:**
  - `InformationRegister.SupplierLeadTimes` — periodic, Counterparty, Product → LeadTimeDays — **M2**.
  - Báo cáo DCS "Đề xuất đặt hàng": tồn hiện tại so với (bán bình quân/ngày × lead time + tồn an toàn) — **M2/M3** (công thức trong DCS có thể làm bằng calculated field; nếu quá phức tạp thì là M3).
- **Phù hợp:** nhóm 2 (phân tích định lượng tốt) / nhóm 1.
- **Khả thi:** Vừa. **Lưu ý trùng:** dùng ý của Đề 2 (định mức) và Đề 4 (thời gian giao cam kết) — chỉ chọn khi nhóm **không** làm Đề 2 hoặc Đề 4, hoặc làm như phần mở rộng có xin phép.

#### L4 — Đa pháp nhân (chiều Company)
- **Bài toán:** Một chủ sở hữu có 2 công ty (thương mại và dịch vụ vận tải) dùng chung kho và nhân viên; cần báo cáo riêng từng pháp nhân để nộp thuế.
- **Jet đang có:** `Catalog.Companies` với predefined `MainCompany`; tiền tệ hạch toán đọc từ chính item này:

  Nguồn: Jet — cf/CommonModules/JetServer/Ext/Module.bsl (1C:Jet, MIT)
  ```bsl
  	Return Common.ObjectAttributeValue(Catalogs.Companies.MainCompany, "PresentationCurrency");
  ```
  Không Document nghiệp vụ nào có attribute `Company`, không register nào có chiều Company (đối chiếu `cf/Documents/*.xml`, `cf/AccumulationRegisters/*.xml`; `de-bai-btl.md` mục 1.4).
- **Khoảng trống:** số liệu trộn lẫn hai pháp nhân → báo cáo thuế sai, không tính được lãi từng công ty.
- **Đối tượng thêm:**
  - Attribute `Company` trên các chứng từ của phân hệ nhóm phụ trách, mặc định `MainCompany` — **M2**.
  - Báo cáo DCS theo Company đọc từ chứng từ — **M2**.
  - Dimension `Company` trong register của phân hệ — **M3**.
- **Phù hợp:** nhóm 1 (đề kiến trúc). Nhóm 2 làm phần M1 + M2 và phân tích hệ quả.
- **Khả thi:** M3 Cao, **rủi ro cao nhất**: thêm chiều vào register dùng chung buộc mọi nhóm sửa posting. Đây cũng là cơ chế của bài thực hành Bài 12 (Companies, dimension Company trong Sales) — nhóm 1 chỉ nhận gợi ý. Lưu ý: muốn mỗi pháp nhân có tiền tệ riêng thì `GetPresentationCurrency` cũng phải đổi.

#### L5 — Giao hàng thu hộ (COD) qua đơn vị vận chuyển
- **Bài toán:** Shop thời trang online giao qua GHN, Viettel Post; đơn vị vận chuyển thu tiền của khách rồi chuyển lại sau 3–7 ngày, trừ phí ship và hàng hoàn. Chủ shop không biết bên vận chuyển đang giữ bao nhiêu tiền của mình.
- **Jet đang có:** `CashReceipt`/`BankReceipt` thu tiền theo hóa đơn qua `PaymentDetails` (Document, PaymentAmount, Amount); `CustomerBalance` theo khách và hóa đơn (Nguồn: Jet — cf/Documents/BankReceipt.xml, cf/AccumulationRegisters/CustomerBalance.xml).
- **Khoảng trống:** người nợ thực tế là đơn vị vận chuyển, không phải người mua lẻ → không đối soát được tiền COD, phí ship, đơn hoàn.
- **Đối tượng thêm:**
  - Attribute `Carrier` (Counterparties), `TrackingNumber`, `CODAmount`, `ShippingFee` trên `SalesInvoice` — **M2**.
  - `Document.CODReconciliation` — không ghi sổ: Carrier, kỳ, tabular section (SalesInvoice, CODAmount, ShippingFee, Returned) — **M2**.
  - Báo cáo DCS "Tiền COD chưa đối soát theo đơn vị vận chuyển" — **M2**.
  - Posting chuyển công nợ từ khách sang đơn vị vận chuyển — **M3** (chạm `CustomerBalance`).
- **Phù hợp:** nhóm 2 (bối cảnh rất Việt Nam) / nhóm 1.
- **Khả thi:** M2 Vừa; M3 Cao (quy ước dấu của `CustomerBalance` — `jet-cash.md` mục 9.1).

#### L6 — Quy trình hàng trả về khép kín (RMA)
- **Bài toán:** Nhà phân phối điện thoại nhận máy lỗi từ đại lý → kiểm tra → gửi hãng bảo hành hoặc đổi máy mới; hiện không biết một máy lỗi đang ở bước nào.
- **Jet đang có:** không có chứng từ trả hàng ở cả hai chiều (xem S2, P1).
- **Khoảng trống:** mất dấu hàng bảo hành, khách chờ lâu, không đòi được hãng.
- **Đối tượng thêm:**
  - `Document.ReturnAuthorization` (RMA) — không ghi sổ: Customer, SalesInvoice gốc, Product, SerialNumber (String), Issue, Decision — **M2**.
  - Enumeration `RMAStatuses` (Received / Inspecting / SentToVendor / Replaced / Refunded / Closed) và `RMADecisions` — **M2**.
  - `InformationRegister.RMAStatusHistory` (periodic) — **M2**.
  - Liên kết sang `CustomerReturn` (S2), `SupplierReturn` (P1) — **M3**.
- **Phù hợp:** nhóm 2 (đề quy trình) / nhóm 1 (khi đã có S2/P1).
- **Khả thi:** M2 Vừa; không chạm register ở M2.

#### L7 — Phiếu điều phối kho (picking list) cho đơn hàng
- **Bài toán:** Kho cấp 1 của nhà phân phối bánh kẹo soạn 80 đơn/ngày theo hóa đơn in giấy; soạn từng đơn nên đi lại nhiều, sai sót cao.
- **Jet đang có:** `SalesInvoice` in được (template `PF_MXL_SalesInvoice`); không có phiếu soạn hàng gộp (Nguồn: Jet — cf/Documents/SalesInvoice/Templates).
- **Khoảng trống:** không gộp được hàng cần soạn của nhiều đơn theo vị trí → năng suất thấp.
- **Đối tượng thêm:**
  - `Document.PickingList` — không ghi sổ: Warehouse, ngày, danh sách `SalesInvoice`, tabular section Product, Quantity, StorageBin (W1), Picked — **M2**.
  - Báo cáo DCS "Tổng hàng cần soạn theo vị trí" — **M2**.
  - Tự gộp số lượng từ các hóa đơn đã chọn — **M3**.
- **Phù hợp:** nhóm 2 / nhóm 1. Nên đi cùng W1.
- **Khả thi:** Vừa; không chạm register.

#### L8 — Lịch nhận hàng tại kho (dock appointment)
- **Bài toán:** Kho trung chuyển ở Bình Dương có 2 cửa nhận; xe nhà cung cấp đến dồn vào buổi sáng, chờ 3–4 tiếng, bị phạt lưu xe.
- **Jet đang có:** không có kế hoạch nhận hàng; `SupplierInvoice` chỉ ghi khi hàng đã nhận.
- **Khoảng trống:** không điều phối được giờ đến → tắc kho, phát sinh chi phí chờ.
- **Đối tượng thêm:**
  - `Catalog.Docks` (cửa nhận) subordinate tới `Warehouses` — **M2**.
  - `InformationRegister.DockSchedule` — Dock, Date, TimeSlot → Supplier, VehiclePlate, Status — **M2** (câu hỏi thiết kế: chiều nào đảm bảo "một cửa một khung giờ một xe").
  - Báo cáo DCS công suất cửa nhận theo ngày — **M2**.
- **Phù hợp:** nhóm 2.
- **Khả thi:** Thấp–Vừa; không chạm register.

---

### 1.6. Tích hợp, di động, phân tích — I1–I3 (ngoài 24 bài, cho nhóm khá)

> Các ý tưởng này dùng kỹ thuật **ngoài giáo trình** (HTTP service, nền tảng di động) hoặc phân tích nâng cao — chỉ nên chọn khi nhóm có thành viên nền IT và giảng viên đồng ý. Nguồn tham khảo: `code-review/nguon-ngoai.md`.

#### I1 — Tra cứu tồn kho qua HTTP service (JSON)
- **Bài toán:** Website / ứng dụng bán hàng của công ty phải gọi điện hỏi kho "còn hàng không" — thông tin chậm, bán hàng không có sẵn.
- **Jet đang có:** register tồn kho theo kho và sản phẩm (xem `jet-warehouse.md`); chưa có HTTP service nào cho bên ngoài.
- **Khoảng trống:** hệ thống ngoài không đọc được tồn kho tức thời.
- **Đối tượng thêm:**
  - `HTTPService.Stock` với template `/stock/{ProductCode}` trả JSON `{ product, warehouse, quantity }`, đọc `.Balance` với điều kiện trong tham số virtual table — **M3** (ngoài giáo trình: HTTP service, `JSONWriter`; cần publish lên web server).
  - Role riêng chỉ đọc tồn kho cho tài khoản tích hợp — **M2** (Bài 20).
- **Phù hợp:** nhóm 1 (code) — nhóm 2 thiết kế dữ liệu trả về.
- **Khả thi:** Vừa; không ghi register. Thử bằng trình duyệt / Postman. Tham khảo phía gọi: thư viện Connector (`nguon-ngoai.md`).

#### I2 — Phân tích ABC / XYZ và vòng quay hàng tồn
- **Bài toán:** Cửa hàng không biết mặt hàng nào mang lại phần lớn doanh thu (A) và mặt hàng nào bán thất thường (Z) để đặt hàng hợp lý.
- **Jet đang có:** register doanh số / giá vốn và tồn kho; báo cáo lãi bán hàng (xem `jet-sales.md`, `jet-warehouse.md`).
- **Khoảng trống:** không có phân loại mặt hàng, không đo số ngày tồn.
- **Đối tượng thêm:**
  - Báo cáo DCS ABC theo doanh thu kỳ (cột tỷ trọng lũy kế, nhóm A/B/C bằng calculated field) — **M2**.
  - Báo cáo vòng quay = giá vốn kỳ / tồn bình quân, số ngày tồn — **M2**.
  - `InformationRegister.ProductClasses` (periodic Month) lưu kết quả phân loại do data processor tính hằng tháng — **M3**.
- **Phù hợp:** nhóm 2 (Logistics) — mạnh về nghiệp vụ, ít code.
- **Khả thi:** Thấp–Vừa; chỉ đọc dữ liệu. Câu hỏi thiết kế hay: phân loại tính lúc xem báo cáo hay lưu lại theo tháng?

#### I3 — Kiểm kê bằng điện thoại (quét mã vạch)
- **Bài toán:** Kiểm kê cuối tháng ghi giấy rồi nhập lại, sai sót nhiều.
- **Jet đang có:** chưa có mã vạch (xem W7); kiểm kê là Đề 9 chính thức.
- **Khoảng trống:** nhập liệu kiểm kê thủ công.
- **Đối tượng thêm:** ứng dụng di động riêng (cấu hình *Mobile device*) quét mã vạch bằng camera, đếm số lượng, gửi kết quả về Jet qua HTTP service — **M3+** (ngoài giáo trình: nền tảng di động, `MultimediaTools`, đồng bộ dữ liệu). Mẫu tham khảo: MobileScanner của 1C Developer Network (`nguon-ngoai.md`) — chỉ đọc để hiểu, không chép (repo không ghi giấy phép, có chỗ viết kiểu cũ).
- **Phù hợp:** nhóm có thành viên IT, sau khi xong W7 hoặc Đề 9.
- **Khả thi:** Cao; cần điện thoại Android và bản platform di động. Có thể làm phiên bản rút gọn: form nhập mã vạch trên web client thay cho điện thoại.

### 1.7. Từ case doanh nghiệp thật (đã ẩn danh) — E1–E14

> Rút từ hồ sơ khảo sát, file vận hành và tài liệu giải pháp của 1C Việt Nam; bối cảnh từng ngành: `erp-cases/case-doanh-nghiep.md`. Một số ý tưởng gần với thẻ đã có (ghi "gần") — chọn một, không làm trùng. Phần "Jet đang có" xem các file `jet/`.

**Hợp lộ trình J (trên Jet):**

#### E1 — Kho 2 pha: phiếu kho tách khỏi hóa đơn
- **Bài toán:** kế toán xuất hóa đơn, thủ kho xuất hàng vào lúc khác → tồn sổ và tồn thực lệch, hai bên đổ lỗi cho nhau.
- **Đối tượng thêm:** thuộc tính `TwoPhase` của kho — **M2**; `Document.GoodsIssue` tạo trên cơ sở SalesInvoice (chưa ghi sổ) — **M2**; register `GoodsToShip` (hàng phải xuất theo hóa đơn) và sửa posting để kho 2 pha chỉ trừ tồn khi có phiếu xuất — **M3**; báo cáo chênh lệch hóa đơn – phiếu xuất — **M3**.
- **Phù hợp:** nhóm Logistics; câu hỏi thiết kế hay: register nào "biết" hàng đã bán nhưng chưa rời kho?

#### E2 — Gửi hàng cho đại lý bán hộ (ký gửi) + hoa hồng
- **Bài toán:** hàng nằm ở đại lý vẫn là hàng của công ty, nhưng sổ sách coi như đã bán.
- **Đối tượng thêm:** Catalog `Contracts` (loại hợp đồng ký gửi, cách tính hoa hồng) — **M2**; `ConsignmentTransfer`, `ConsigneeReport` — **M2**; register `GoodsAtConsignees` — **M3**; báo cáo đại lý ghi doanh số và công nợ (trừ hoa hồng) — **M3** (chạm register dùng chung).

#### E3 — Kho dịch vụ 3PL: nhận giữ hộ hàng của chủ hàng
- **Bài toán:** công ty logistics giữ hàng cho nhiều chủ hàng, tính phí lưu kho theo pallet-ngày; hàng giữ hộ không phải tài sản của mình.
- **Đối tượng thêm:** `SafekeepingReceipt`, `SafekeepingRelease` — **M2**; register `GoodsInSafekeeping` (chủ hàng, kho, sản phẩm) — **M3**; InformationRegister `StorageTariffs` + báo cáo phí lưu kho — **M2/M3**.
- **Phù hợp:** **rất sát ngành Logistics**; không chạm register tồn kho của Jet (đúng bản chất: không phải hàng của công ty).

#### E4 — Đóng bộ / tách bộ (giỏ quà, combo)
- **Đối tượng thêm:** Catalog `KitSpecifications` (thành phần) — **M2**; `Document.KitAssembly` (đóng bộ / tách bộ) xuất thành phần, nhập bộ, giá vốn bộ = tổng giá vốn thành phần — **M3**.
- **Phù hợp:** dịch vụ giá trị gia tăng trong kho; câu hỏi hay: giá vốn của bộ tính thế nào?

#### E5 — Lương khoán bốc xếp / soạn hàng theo kiện
- **Đối tượng thêm:** Catalog `WarehouseOperations` (bốc, xếp, soạn; đơn giá) — **M2**; `PieceWorkSheet` (tổ, người, số lượng, hệ số chia) — **M2**; register `PayrollAccrued` (Turnovers) — **M3**.
- **Phù hợp:** năng suất kho — nhóm Logistics.

#### E6 — Cổng nhà máy: chuyến xe, cân 2 lần, xuất hàng (gần L1, L8)
- **Bài toán:** xe đợi nhiều giờ, cân và xuất hàng ghi tay, sai lệch khối lượng.
- **Đối tượng thêm:** `Document.Trip`, `WeighingTicket` — **M2**; InformationRegister lịch sử trạng thái chuyến (đăng ký → cân vào → xếp hàng → cân ra → rời cổng) — **M2**; chặn xuất khi lệch cân quá ngưỡng, mô phỏng đầu cân bằng data processor — **M3**.

#### E7 — Hạn mức tín dụng đại lý + duyệt vượt hạn mức
- **Đối tượng thêm:** InformationRegister `CreditLimits` (periodic theo khách) — **M2**; kiểm số dư `CustomerBalance` khi post SalesInvoice, vượt thì chặn hoặc chờ duyệt — **M3**; role người duyệt — **M2**.
- **Câu hỏi thiết kế hay:** phê duyệt có cần là Document không, hay chỉ là trạng thái / nhiệm vụ?

#### E8 — Cấp phát công cụ, đồ bảo hộ cho bộ phận
- **Đối tượng thêm:** Catalog `Departments` — **M2**; `IssueToUse` / `ReturnFromUse` — **M2**; register `ItemsInUse` (bộ phận, người, sản phẩm) — **M3**.

#### E9 — Case trọn vẹn: doanh nghiệp vật liệu trang trí nhỏ (PU-D)
- **Bài toán:** 3 kho, 4 mức giá cho một sản phẩm theo kiểu hoàn thiện, giá cố định theo từng khách, chiết khấu cuối năm theo doanh thu, thuê gia công hoàn thiện.
- **Đối tượng thêm:** dùng dạng giá của Jet cho 4 mức giá + InformationRegister giá riêng theo khách — **M2**; chiết khấu bậc thang cuối năm (query lũy kế doanh số) — **M3** (gần Đề 5); register hàng đang ở đơn vị gia công — **M3**.
- **Phù hợp:** **đề tài trọn vẹn cho một nhóm J** — đủ mua, bán, kho, tiền.

#### E10 — Kho giấy theo khổ cho xưởng carton (CARTON-C)
- **Đối tượng thêm:** thuộc tính khổ / định lượng của sản phẩm giấy, báo cáo nhập – xuất – tồn theo khổ — **M2**; đề xuất đặt giấy theo đơn và cơ cấu lớp (data processor) — **M3**; phần sản xuất chỉ phân tích ở M1.

**Hợp lộ trình M (cấu hình trống) hoặc nhóm khá:**

#### E11 — Xưởng may mini (MAY-A)
- Thiết kế đầy đủ: mã hàng (công đoạn + thời gian chuẩn), đơn hàng theo màu × size, định mức hai phiên bản, nhập vải theo cây, phiếu trải cắt, bán thành phẩm theo công đoạn, sản lượng theo giờ (InformationRegister), báo cáo cân đối vải, tiến độ đơn, hiệu suất chuyền, quyết toán mã hàng. Bối cảnh và KPI: `case-doanh-nghiep.md` mục 1.1.

#### E12 — Bảo trì thiết bị (mini-CMMS)
- Thiết bị theo cây khu vực, InformationRegister vị trí / tình trạng (periodic), yêu cầu sửa chữa → phiếu công việc → xuất phụ tùng, kế hoạch bảo trì định kỳ, scheduled job sinh phiếu đến hạn, báo cáo chi phí và thiết bị hỏng nhiều. Nhóm J: đổi bối cảnh sang xe nâng, băng tải của kho.

#### E13 — Kho nguyên liệu dược theo lô, hạn dùng, trạng thái QC (DƯỢC-E, gần Đề 1)
- Lô (hạn dùng), register tồn theo lô và vị trí, InformationRegister trạng thái lô, phiếu kiểm nghiệm; posting chặn xuất lô biệt trữ, gợi ý xuất FEFO.

**Đề phương pháp (ghép với bất kỳ đề nào, phần M1):**

#### E14 — Từ file Excel đến ma trận fit-gap
- Nhận 2–3 file Excel vận hành **đã ẩn danh / sinh lại** → kiểm kê file (ai cập nhật, tần suất, nguồn số) → vẽ quy trình as-is → ma trận fit-gap với Jet theo `erp-cases/khung-khao-sat.md` → danh sách lỗi Excel (hằng số trong công thức, liên kết ngoài, ngày đảo) và cách hệ thống kiểm soát. Biến thể: làm sạch danh mục (tách tên hàng dài thành thuộc tính) trước khi nhập.

## 2. Bảng chọn đề nhanh

Cột "Mức" ghi mức tối thiểu đạt được → mức cao nhất của ý tưởng. "Công" là [ước lượng] cho phần M2 / phần M3. "Register dùng chung" = có phải sửa `InventoryInWarehouses`, `InventoryCost`, `CustomerBalance`, `SupplierBalance` ở mức M3 không.

| ID | Ý tưởng | Phân hệ | Mức | Nhóm 2 | Nhóm 1 | Công M2 / M3 | Register dùng chung |
|---|---|---|---|---|---|---|---|
| W1 | Vị trí lưu kho | Warehouses | M2 → M3 | ●● | ● | Thấp / Cao | Không (register mới) |
| W2 | Thủ kho phụ trách | Warehouses | M2 → M3 | ●● | ● | Thấp / Vừa | Không |
| W3 | Kho cách ly, tồn có thể bán | Warehouses | M2 → M3 | ●● | ● | Thấp / Vừa | Không (sửa kiểm tra SalesInvoice) |
| W4 | Yêu cầu điều chuyển | Warehouses | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| W5 | Quy đổi đơn vị tính | Warehouses | M2 → M3 | ● | ●● | Vừa / Vừa | Không (sửa form dùng chung) |
| W6 | Khối lượng, xếp xe | Warehouses | M2 → M3 | ●● | ● | Thấp / Vừa | Không |
| W7 | Mã vạch | Warehouses | M2 → M3 | ● | ●● | Thấp / Vừa | Không |
| W8 | Thẻ kho, nhật ký chứng từ kho | Warehouses | M2 | ●● | — | Thấp / — | Không |
| P1 | Trả hàng nhà cung cấp | Purchases | M2 → M3 | ● | ●● | Thấp / Cao | **Có** (3 register + Sequence) |
| P2 | Bảng giá mua | Purchases | M2 → M3 | ●● | ● | Thấp / Vừa | Không |
| P3 | Chi phí mua hàng | Purchases | M1/M2 → M3 | ● | ●● | Vừa / Cao | **Có** (InventoryCost, SupplierBalance) |
| P4 | Hợp đồng khung | Purchases | M2 → M3 | ●● | ● | Thấp / Vừa | Không |
| P5 | Kiểm tra chất lượng nhận hàng | Purchases | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| P6 | Hàng mua đang đi đường | Purchases | M2 | ●● | — | Thấp / — | Không |
| P7 | Đề nghị mua hàng | Purchases | M2 | ●● | ● | Thấp / Vừa | Không |
| S1 | Đơn bán và giữ hàng | Sales | M2 → M3 | ●● | ●● | Thấp / Vừa–Cao | Không (register mới; sửa posting SalesInvoice) |
| S2 | Khách trả hàng | Sales | M2 → M3 | ● | ●● | Thấp / Cao | **Có** (InventoryCost, CustomerBalance) |
| S3 | Báo giá | Sales | M2 → M3 | ●● | ● | Thấp / Vừa | Không |
| S4 | Nhiều điểm giao hàng | Sales | M2 | ●● | — | Thấp / — | Không |
| S5 | Kênh bán hàng | Sales | M2 → M3 | ●● | ● | Thấp / Vừa | Không (Sales chỉ nhóm Sales ghi) |
| S6 | Lãi gộp chưa VAT | Sales | M2 | ●● | ● | Thấp / — | Không |
| S7 | Hóa đơn điện tử (quản lý) | Sales | M2 | ●● | ● | Thấp / — | Không |
| C1 | Chuyển tiền nội bộ | Cash | M2 → M3 | ● | ●● | Thấp / Vừa | Không (CashBalance của nhóm Tiền) |
| C2 | Kiểm soát quỹ âm | Cash | M2 → M3 | ● | ●● | Thấp / Vừa–Cao | Không |
| C3 | In phiếu thu/chi | Cash | M1 → M3 | ● (M1) | ●● | — / Vừa | Không |
| C4 | Đối chiếu sổ phụ ngân hàng | Cash | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| C5 | Lịch thu chi dự kiến | Cash | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| C6 | Phê duyệt chi | Cash | M2 → M3 | ●● | ● | Thấp / Vừa | Không |
| C7 | Tạm ứng nhân viên | Cash | M2 → M3 | ●● | ● | Thấp / Vừa | Không (register mới) |
| L1 | Theo dõi giao hàng | Liên phân hệ | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| L2 | Hàng chuyển kho đang đi đường | Warehouses | M2 → M3 | ● | ●● | Thấp / Cao | **Có** nếu sửa posting InventoryTransfer |
| L3 | Điểm đặt hàng lại | Warehouses + Purchases | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| L4 | Đa pháp nhân (Company) | Tất cả | M2 → M3 | ● | ●● | Vừa / Cao | **Có** (mọi register) |
| L5 | COD qua đơn vị vận chuyển | Sales + Cash | M2 → M3 | ●● | ● | Vừa / Cao | **Có** ở M3 (CustomerBalance) |
| L6 | Quy trình RMA | Sales + Purchases | M2 → M3 | ●● | ● | Vừa / Cao | Có nếu nối S2/P1 |
| L7 | Phiếu soạn hàng | Warehouses + Sales | M2 → M3 | ●● | ● | Vừa / Vừa | Không |
| L8 | Lịch nhận hàng tại kho | Warehouses + Purchases | M2 | ●● | — | Thấp–Vừa / — | Không |

Ký hiệu: ●● rất phù hợp · ● phù hợp · — không có phần đáng làm cho nhóm này.

**Gợi ý ghép đề cho đủ khối lượng** [ước lượng]: một ý tưởng "Thấp" thường chưa đủ cho cả học kỳ. Ghép theo chuỗi nghiệp vụ, ví dụ W1 + L7 (vị trí → soạn hàng), S4 + L1 + W6 (điểm giao → chuyến xe → tải trọng), P5 + W3 (kiểm định → kho cách ly), S7 + S6 (hóa đơn điện tử + lãi gộp chưa VAT). Không ghép với ý tưởng trùng 9 đề của nhóm khác trong lớp.

---

## 3. Nguồn để tìm thêm ý tưởng

### 3.1. Repo và Wiki của Jet

| Nguồn | Có gì dùng được | Cách dùng |
|---|---|---|
| README Jet (`github.com/1Ci-Company/Jet`) | Mô tả mục tiêu, danh sách bản địa hóa Jet-TR / Jet-ES / Jet-ID, kênh Telegram cộng đồng **t.me/jet1ci** (Nguồn: jet/README.md) | Hỏi cộng đồng khi vướng; xem các bản địa hóa để tìm tính năng mẫu |
| Wiki — trang *Features* | Danh sách chức năng chính thức: SSL, Purchases, Sales, Warehouse, Cash & Bank, AP/AR, Costing (Nguồn: jet-wiki/Features.md) | Đối chiếu "Jet đã có gì" trước khi viết phần khoảng trống |
| Wiki — *1C:Jet Initial Setup Guide* | Hướng dẫn dùng **Additional attributes** để thêm trường cho kho, sản phẩm, đối tác (Nguồn: jet-wiki/1C:Jet-Initial-Setup-Guide.md) | Thử nhanh một ý tưởng bằng dữ liệu trước khi khai báo metadata |
| Wiki — *How to Send E-Invoices via EDM* | Mô tả luồng Jet ↔ nhà tích hợp EDM ↔ cơ quan thuế Thổ Nhĩ Kỳ (Nguồn: jet-wiki/How-to-Send-E‐Invoices-via-EDM.md) | Tham khảo khi làm S7 |
| Mục "Gợi ý mở rộng" trong `references/jet/` | `jet-warehouse.md` mục 14, `jet-purchases.md` mục 13, `jet-sales.md` mục 11, `jet-cash.md` mục 14 — kèm các object/module Jet sẽ chạm tới | Lấy chi tiết kỹ thuật cho phần M3 |
| Mục "điểm lạ trong code" | `jet-warehouse.md` mục 13, `jet-purchases.md` mục 12, `jet-sales.md` mục 12, `jet-cash.md` mục 13 | Mỗi điểm lạ là một khoảng trống tiềm năng (trình bày như quan sát, không khẳng định lỗi) |

### 3.2. Các bản địa hóa Jet — so sánh với Jet gốc

Đã clone nông (shallow) ba repo và so danh sách object trong `cf/Documents`, `Catalogs`, `InformationRegisters`, `AccumulationRegisters`, `DataProcessors` (cùng `Enums`, `CommonModules`, `Constants`, `Subsystems`, `Roles`) với Jet gốc (`community`, `80884de`):

| Repo (nhánh mặc định, commit) | Kết quả so sánh |
|---|---|
| **Jet-ES** (`develop-es`, `b9dddec`) | **Không có object nghiệp vụ mới.** Khác biệt là bản dịch: chuỗi `NStr` thêm `es_CO` (ví dụ `cf/Documents/SalesInvoice/Ext/ManagerModule.bsl`). |
| **Jet-ID** (`develop-id`, `73135ff`) | **Không có object nghiệp vụ mới.** Chuỗi `NStr` thêm `id` (ví dụ `cf/AccumulationRegisters/InventoryInWarehouses/Ext/ManagerModule.bsl`). |
| **Jet-TR** (`community-tr`, `3f4949d`) | **Có phân hệ mới `EDI`** (hóa đơn điện tử) và **khấu trừ VAT (VAT withholding)** — danh sách dưới đây. |

Object có trong Jet-TR nhưng không có trong Jet gốc (đường dẫn trong repo Jet-TR):

| Loại | Object | Ghi chú (đọc từ metadata) |
|---|---|---|
| Subsystem | `cf/Subsystems/EDI.xml` | Content gồm các object EDI bên dưới, `Role.UseEDI`, `CommonForm.EInvoicePrintForm` |
| Catalog | `EDIProfiles`, `EDocumentStatuses`, `TaxExemptionReasons`, `VATWithholdingCodes`, `VATWithholdingRates`, `XSLT` | `EDIProfiles` có `Company`, `UseEInvoice`, `EInvoiceStartDate`, `Provider`, `URL`…; `EDocumentStatuses` có `IsFinal`, `IsRejected` |
| Information register | `EDIUUIDs` (non-periodic), `EDocumentsStatuses` (periodicity Second, Independent), `TaxpayerList` (non-periodic) | `EDocumentsStatuses`: dimension `ElectronicDocument` (DocumentRef.SalesInvoice), resource `Provider`, `Status` |
| Enumeration | `EDIProviders`, `EDocumentDeliveryType`, `EDocumentScenario`, `EDocumentStatus`, `EDocumentType`, `EInvoiceTypeCode` | Giá trị theo quy định Thổ Nhĩ Kỳ (ví dụ `EArchive`, `EInvoice`) |
| Common module | `EDIClient`, `EDIClientServer`, `EDIServer`, `EDIServerCall`, `EDMServer`, `UBLServer`, `VATWithholdingServerCall`, `JetAddressManager`, `JetAddressManagerClientServer`, `JetContactsManagerLocalization` | Logic gửi/nhận, tạo UBL, khấu trừ VAT, địa chỉ |
| Data processor | `FirstLaunch` | Template nạp sẵn lý do miễn thuế, mã khấu trừ VAT khi chạy lần đầu |
| Constant / Functional option | `EDIApplicationNameEDM`, `UseVATWithholdingFromSales` (Constant + Functional option cùng tên) | Bật/tắt khấu trừ VAT |
| Attribute thêm vào object có sẵn | `SalesInvoice`: `IsEInvoice`, `EDocumentNumber`, `EDocumentScenario`, `EDocumentDeliveryType`, `UseTaxExemptionReason`, `TaxExemptionReason`, `VATWithholding`…; `Counterparties`: `EDocumentScenario`, `TaxOffice`; `Companies`: `MersisNumber`, `TaxOffice`; `Products`: `VATWithholdingCode`, `VATWithholdingRate` | So với `cf/Documents/SalesInvoice.xml` gốc |

Form của `SalesInvoice` trong Jet-TR gọi module EDI ngay trong handler của form — một mẫu tốt để học cách "cắm" tính năng mới vào chứng từ có sẵn:

Nguồn: Jet-TR — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl (1C:Jet, MIT)
```bsl
	EDIServer.OnCreateAtServer_DocumentForm(EDIParametersOnCreate);
```

**Cách dùng cho đề tài:** Jet-TR là "đề mẫu đã giải" cho ý tưởng S7: xem cách họ chọn Catalog cho trạng thái có thuộc tính (`EDocumentStatuses` có `IsFinal`) nhưng Enumeration cho tập giá trị luật định (`EDocumentType`), và periodic Information register cho lịch sử trạng thái. Nhóm Việt Nam chỉ **mô phỏng cấu trúc**, không chép giá trị luật Thổ Nhĩ Kỳ. Clone: `GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://github.com/1Ci-Company/Jet-TR.git`, rồi so thư mục `cf/` như trên.

### 3.3. Nguồn nghiệp vụ bên ngoài (đã mở và kiểm tra)

| Nguồn | Nội dung | Sinh viên dùng thế nào |
|---|---|---|
| 1Ci Knowledge Base — *Trade company processes in 1C:Drive* (kb.1ci.com/1C_Drive/Tutorials/Sales_purchases/Trade_company_processes_in_1C_Drive/) | Quy trình công ty thương mại trên 1C:Drive: purchase order, sales order, giá mua/giá bán, lô và hạn dùng | So một sản phẩm 1C đầy đủ với Jet để tìm khoảng trống |
| 1Ci KB — *Warehouses catalog* của 1C:Drive (kb.1ci.com/1C_Drive/Guides/1C_Drive_User_Guide/Setting_up_business_processes/Master_catalogs/Warehouse_management_catalogs/Warehouses_catalog) | Kho có loại (Warehouse / Point of sale), storage bins tùy chọn, người phụ trách, loại giá bán lẻ | Ý tưởng cho W1, W2, W3; xem cách 1C đặt thuộc tính cho kho |
| 1Ci KB — *Purchase order overview* (kb.1ci.com/1C_Drive/Guides/1C_Drive_User_Guide/Purchases/Purchase_orders/Purchase_order_overview) | Đơn mua, trạng thái, báo cáo "ordered, received, expected goods" | Tham chiếu cho S1 (đối xứng phía bán) và P7 |
| 1Ci KB — *Practical developer guide 8.3* (kb.1ci.com/1C_Enterprise_Platform/Tutorials/Practical_developer_guide_8.3/) | Hướng dẫn chính thức tạo accumulation register, posting trong Designer | Đọc thêm khi làm M3, song song với Bài 11 |
| APQC Process Classification Framework — Cross-Industry (apqc.org/pcf-excel) | Phân loại quy trình chuẩn; nhóm 4.0 "Manage Supply Chain for Physical Products" có 4.4 logistics và kho (nhận, cất, soạn, giao, vận tải, hàng trả về) | Duyệt danh mục quy trình cấp 3–4, chọn một quy trình Jet chưa có → thành ý tưởng |
| ASCM SCOR Digital Standard (ascm.org/corporate-solutions/standards-tools/scor-ds/) | 7 nhóm quy trình chuỗi cung ứng: Orchestrate, Plan, Order, Source, Transform, Fulfill, Return; công bố theo Creative Commons | Xếp từng chứng từ Jet vào Order / Source / Fulfill / Return để thấy nhóm nào trống (Jet không có Transform, không có Return) |
| Nghị định 123/2020/NĐ-CP về hóa đơn, chứng từ (thuvienphapluat.vn/van-ban/Thue-Phi-Le-Phi/Nghi-dinh-123-2020-ND-CP-hoa-don-chung-tu-445980.aspx) | Ban hành 19/10/2020, hiệu lực 01/07/2022; Điều 10 liệt kê nội dung bắt buộc của hóa đơn điện tử. Đã được sửa đổi bởi Nghị định 70/2025/NĐ-CP; theo thuvienphapluat, Nghị định 254/2026/NĐ-CP (hiệu lực 01/07/2026) hướng dẫn thêm | Lấy danh sách trường cần lưu cho S7 — kiểm tra văn bản hiện hành tại thời điểm làm bài |

### 3.4. Bài giảng dạy cơ chế cần cho từng loại hạng mục

| Hạng mục | Bài | File |
|---|---|---|
| Catalog, Enumeration, Document, attribute, tabular section; hierarchy, Owner, choice parameter links, predefined | Bài 1–4 | `references/lessons/bai-01-04.md` |
| Subsystem, form, đặt field lên form | Bài 9 | `references/lessons/bai-09.md` |
| Query (join, CASE, nhóm khoảng) cho báo cáo | Bài 10 | `references/lessons/bai-10.md` |
| Accumulation register, Balances/Turnovers, Posting, Generation (tạo chứng từ dựa trên chứng từ khác) | Bài 11 | `references/lessons/bai-11.md` |
| FillCheckProcessing, Information register (periodic, SliceLast, independent) | Bài 12 | `references/lessons/bai-12.md` |
| Constant, Document journal, Chart of characteristic types | Bài 13 | `references/lessons/bai-13.md` |
| Functional option (bật/tắt tính năng) | Bài 15 | `references/lessons/bai-15.md` |
| Event, Event subscription (điền mặc định cho nhiều chứng từ) | Bài 16 | `references/lessons/bai-16.md` |
| Print form | Bài 17, Bài 22 | `references/lessons/bai-17.md`, `bai-22.md` |
| Báo cáo DCS (data set, parameters, nhiều data set) | Bài 18 | `references/lessons/bai-18.md` |
| Data processor, nạp Excel | Bài 19 | `references/lessons/bai-19.md` |
| Role, quyền | Bài 20 | `references/lessons/bai-20.md` |
| Extension (Customization / Add-on) | Bài Extensions | `references/lessons/bai-extensions.md` |
| Thêm object vào Jet đúng chỗ (subsystem, role, print, properties) | — | `references/jet/jet-extending.md` |

---

## 4. Hướng dẫn tự phát triển ý tưởng

Phương pháp 5 bước — áp dụng cho cả hai nhóm; nhóm 2 dừng ở bước 5 với mức M2, nhóm 1 đi tiếp lên M3.

**Bước 1 — Bắt đầu từ một nỗi đau nghiệp vụ, không phải từ object.** Viết một câu: "Doanh nghiệp X **mất** (tiền / hàng / thời gian / khách) **vì** không biết / không kiểm soát được Y." Ví dụ: "Shop online mất tiền vì không biết đơn vị vận chuyển đang giữ bao nhiêu tiền COD." Nếu không nêu được hậu quả cụ thể, ý tưởng chưa đủ mạnh cho phần phân tích khoảng trống (25% điểm).

**Bước 2 — Tìm xem Jet đang ghi nhận gì liên quan.** Theo phương pháp "khai báo → nhập liệu → quan sát hệ quả":
1. Tìm chứng từ gần nhất trong bảng "Chứng từ nào ghi vào sổ nào" (`de-bai-btl.md` mục 1.3).
2. Nhập thử một chứng từ, post, mở báo cáo trước/sau — ghi vào phiếu quan sát.
3. Ghi lại: dữ liệu nào **đã có** (trường trên chứng từ, chiều trong sổ), dữ liệu nào **phải nhập ngoài Jet** (Excel, giấy, Zalo).

**Bước 3 — Xác định chính xác cái còn thiếu.** Phân loại khoảng trống thành một trong bốn dạng:

| Dạng thiếu | Dấu hiệu | Ví dụ |
|---|---|---|
| Thiếu **dữ liệu mô tả** | Cần thêm một trường / danh sách để phân loại, lọc | Kênh bán (S5), khối lượng (W6) |
| Thiếu **dữ liệu thay đổi theo thời gian** | "Tại ngày X giá trị là gì?" | Thủ kho phụ trách (W2), giá mua (P2) |
| Thiếu **ghi nhận một sự kiện** | Có một việc xảy ra, có ngày, có người, cần lưu vết | Kiểm định (P5), giao hàng (L1) |
| Thiếu **số liệu tích lũy / kiểm soát** | "Còn bao nhiêu?", "Đã phát sinh bao nhiêu?", cần chặn khi vượt | Hàng đã hứa giao (S1), quỹ âm (C2) |

**Bước 4 — Chọn loại object.** Dùng bảng quyết định sau (căn cứ: Bài 1–4 cho Catalog/Enumeration/Document, Bài 11 cho Accumulation register, Bài 12 cho Information register, Bài 13 cho Constant/Chart of characteristic types):

| Câu hỏi | Nếu "có" → chọn | Căn cứ trong bài | Ví dụ Jet |
|---|---|---|---|
| Tập giá trị **cố định**, người dùng **không được thêm**, thuật toán dựa vào từng giá trị? | **Enumeration** | Bài 3: lưu giá trị cố định, dùng khi thuật toán dựa vào giá trị đó | `ProductTypes`, `LiabilityTypes`, `CashVoucherOperations` |
| Danh sách người dùng **tự thêm/sửa**, mỗi phần tử cần **thông tin bổ sung**, chọn từ danh sách thay vì gõ chữ? | **Catalog** (hierarchical nếu cần phân cấp; có Owner nếu "thuộc về" một đối tượng khác) | Bài 3: nhập liệu nhất quán, lưu thông tin bổ sung; Bài 4: hierarchy, Owner | `Products`, `Warehouses`, `BankAccounts` |
| Chỉ **một giá trị** cho cả hệ thống, ít thay đổi? | **Constant** | Bài 13 | (ví dụ cờ "Kiểm soát âm quỹ" ở C2) |
| Thông tin **gắn với một tổ hợp** (ví dụ Kho + Sản phẩm), mỗi tổ hợp **một giá trị**, có thể cần **lịch sử theo ngày**? | **Information register** (periodic nếu cần lịch sử; independent nếu nhập tay) | Bài 12: duy nhất theo tập dimensions; periodic + SliceLast; write mode Independent | `Prices` (PriceType, Product → Price; periodic Day) |
| Một **sự kiện nghiệp vụ** có ngày, có người, cần lưu vết và có thể làm đổi số liệu? | **Document** (không ghi sổ ở M2; ghi sổ ở M3) | Bài 3: phản ánh nghiệp vụ, gắn thời gian, có thể post; thuật ngữ: không phải Document nào cũng post | `InventoryTransfer`, `PricesSetupAuxiliary` (không post) |
| Cần **cộng dồn số** theo các chiều và hỏi "còn bao nhiêu" (Balances) hoặc "đã phát sinh bao nhiêu trong kỳ" (Turnovers), chỉ thay đổi qua chứng từ? | **Accumulation register** (M3) | Bài 11: số liệu theo dimensions, records chỉ thay đổi qua recorder | `InventoryInWarehouses` (Balances), `Sales` (Turnovers) |
| Thuộc tính **chưa biết trước**, khác nhau theo nhóm đối tượng, người dùng tự định nghĩa? | **Chart of characteristic types** — trong Jet dùng sẵn Additional attributes của SSL | Bài 13 | `AdditionalAttributesAndInfo` (SSL) |

Ba câu hỏi kiểm tra nhanh trước khi chốt (cũng là dạng câu hỏi phân tích hay gặp trong 9 đề):
- **Gắn vào danh mục hay vào chứng từ?** Nếu giá trị có thể đổi mà dữ liệu cũ phải giữ nguyên (khu vực của khách, kênh bán), cân nhắc lưu trên chứng từ, hoặc dùng Information register periodic.
- **Báo cáo đọc từ chứng từ hay từ sổ?** Đọc từ chứng từ là M2 (không cần sửa posting) nhưng không có số dư; cần "còn bao nhiêu" thì phải có sổ (M3).
- **Có chạm register dùng chung không?** Nếu có, ghi rõ trong thiết kế và thống nhất với nhóm phân hệ kia (SKILL.md mục 6).

**Bước 5 — Chọn mức và lập bảng thiết kế đối tượng.**
1. Tách ý tưởng thành các hạng mục, gán mức như cách 9 đề làm: phần khai báo (Catalog, Enumeration, attribute, Information register, Document không ghi sổ, Subsystem, DCS) là **M2**; register mới, dimension mới, posting, tự động trên form là **M3**.
2. Lập bảng thiết kế bắt buộc: Tên — Loại object 1C — Các trường (kiểu) — **Lý do chọn loại object** (trích căn cứ ở bảng bước 4).
3. Đặt tên theo quy ước Jet: tiếng Anh, PascalCase, Catalog/Document số nhiều hoặc danh từ nghiệp vụ (`Warehouses`, `SalesInvoice`), Synonym tiếng Việt để người dùng thấy tên quen thuộc.
4. Xác định nơi phải đăng ký object mới trong Jet (subsystem, role `Use<Subsystem>`, properties, print) theo checklist `jet-extending.md` mục 5–7 — thiếu bước đăng ký là lỗi phổ biến nhất.
5. Viết 2–3 câu hỏi phân tích cho chính đề của nhóm theo mẫu của 9 đề (lựa chọn loại object, đánh đổi giữa các phương án, ai trong doanh nghiệp được quyền vượt kiểm soát) — chuẩn bị cho phần trình bày 15%.

Tutor lưu ý: với nhóm 1, khi ý tưởng trùng cơ chế với một bài thực hành của giáo trình (ví dụ trả hàng của khách — Bài 11; Company và lịch sử trạng thái — Bài 12), áp dụng mục 3a của SKILL.md: gợi ý theo bậc, không đưa lời giải.
