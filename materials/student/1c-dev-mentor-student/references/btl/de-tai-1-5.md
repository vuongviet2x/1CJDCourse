# Bài tập lớn — hướng dẫn Đề 1, 2, 3, 4, 5 (Warehouses, Purchases, Sales)

**Khi nào đọc file này:** sinh viên (nhóm 1 — có nền IT, hoặc nhóm 2 — trái ngành) hỏi về Đề 1 (Lô hàng và hạn sử dụng), Đề 2 (Định mức tồn kho chuỗi cửa hàng), Đề 3 (Đơn đặt hàng nhà cung cấp), Đề 4 (Đánh giá nhà cung cấp) hoặc Đề 5 (Chiết khấu theo số lượng) trong `references/btl/de-bai-btl.md`: kiểm chứng phần "Jet gốc đang có", gợi ý dữ liệu mẫu, cách khai báo M2, hướng làm M3, ý tưởng mở rộng, gợi mở câu hỏi phân tích.

## Mục lục

0. [Cách dùng file này](#0-cách-dùng-file-này)
1. [Đề 1 — Lô hàng và hạn sử dụng](#đề-1--lô-hàng-và-hạn-sử-dụng)
2. [Đề 2 — Định mức tồn kho chuỗi cửa hàng](#đề-2--định-mức-tồn-kho-chuỗi-cửa-hàng)
3. [Đề 3 — Đơn đặt hàng nhà cung cấp](#đề-3--đơn-đặt-hàng-nhà-cung-cấp)
4. [Đề 4 — Đánh giá nhà cung cấp](#đề-4--đánh-giá-nhà-cung-cấp)
5. [Đề 5 — Chiết khấu theo số lượng](#đề-5--chiết-khấu-theo-số-lượng)
6. [Bảng va chạm giữa các nhóm](#6-bảng-va-chạm-giữa-các-nhóm)

## 0. Cách dùng file này

- Mọi khẳng định về Jet dựa trên dump `cf/` nhánh `community`, commit `80884de` (xem `references/jet/jet-overview.md`). Bản Jet khác có thể lệch — đối chiếu trong Designer.
- **Nhóm 2 (trái ngành):** đi theo thứ tự "nghiệp vụ trước, thuật ngữ sau" và "khai báo → nhập liệu → quan sát hệ quả". Mục "Recipe M3 cho nhóm 2" được phép đưa nguyên vẹn, có giảng viên kèm.
- **Nhóm 1 (HTTT, IT đối tác):** M3 là phần nhóm **tự xây**. Chỉ dùng thang gợi ý (hướng đi → dùng gì, đặt ở đâu → khung có `___`), mỗi lần một bậc. **Không** đưa cho nhóm 1 phần recipe của cùng đề.
- Tên object mới (Batches, StockNorms, PurchaseOrder, SupplyCommitments, DiscountTiers…) là **gợi ý**; Synonym ghi tiếng Việt. Thao tác Designer theo `references/lessons/`; nhãn không có trong ghi chú được đánh dấu "(tên nút/menu có thể khác theo phiên bản — kiểm tra trên máy)".
- Sửa trực tiếp configuration Jet trên fork của nhóm là đơn giản nhất; extension khó hơn (`references/jet/jet-extending.md` mục 4). Code Jet trích nguyên văn — ghi công "1C:Jet (MIT)". Thiếu bước đăng ký (subsystem, role) là lỗi phổ biến nhất (`jet-extending.md` 3.2, 3.3, 8).
- Quy tắc quyền đã kiểm trong dump: role `UseWarehouses`/`UsePurchases`/`UseSales` có `setForNewObjects = false` → object mới **không** tự có quyền. Catalog cần 9 quyền (mẫu `Catalog.Warehouses` trong `cf/Roles/UseWarehouses/Ext/Rights.xml`), Document 15 quyền, report/data processor `Use` + `View`, information register sửa tay `Read`, `Update`, `View`, `Edit` (mẫu `InformationRegister.Prices` trong `cf/Roles/UseSales/Ext/Rights.xml`). **Enumeration không xuất hiện trong role nào** của Jet — không cần cấp quyền.

---

## Đề 1 — Lô hàng và hạn sử dụng

### 1.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| Danh mục Warehouses, Products (có ProductType: Inventory/Service) | **Đúng.** Products: `Hierarchical = true` (folder và item), attribute `DetailedDescription`, `ProductType` (EnumRef.ProductTypes, bắt buộc), `Unit`, `VATRate`. Enum `ProductTypes` có đúng 2 giá trị `Inventory`, `Service`. Warehouses: không phân cấp, không có attribute nghiệp vụ | `cf/Catalogs/Products.xml`, `cf/Enums/ProductTypes.xml`, `cf/Catalogs/Warehouses.xml` |
| InventoryIncrease, InventoryTransfer, InventoryWriteOff | **Đúng.** Tabular section `Inventory`: Increase có `Product, Quantity, Price, Amount`; Transfer và WriteOff chỉ có `Product, Quantity` | `cf/Documents/Inventory*.xml` |
| SupplierInvoice và SalesInvoice đều có Warehouse | **Đúng**, `Warehouse` bắt buộc (`FillChecking = ShowError`) ở cả hai | `cf/Documents/SupplierInvoice.xml`, `SalesInvoice.xml` |
| InventoryInWarehouses và InventoryCost cùng phân tích theo Product, Warehouse | **Đúng.** Cả hai kind Balance; InventoryInWarehouses resource `Quantity`; InventoryCost `Quantity`, `Amount`. Hai dimension của InventoryInWarehouses có `DenyIncompleteValues = true` | `cf/AccumulationRegisters/InventoryInWarehouses.xml`, `InventoryCost.xml` |
| Báo cáo AvailableStock, StockStatement | **Đúng.** AvailableStock đọc `InventoryInWarehouses.Balance`; StockStatement đọc `InventoryCost.BalanceAndTurnovers` | `cf/Reports/*/Templates/MainDataCompositionSchema/Ext/Template.xml` |

**Điểm lệch / bổ sung cần ghi vào phân tích:**
- Bảng yêu cầu M2 liệt kê cột Lô cho SupplierInvoice, InventoryIncrease, SalesInvoice, InventoryWriteOff nhưng **thiếu InventoryTransfer**. Công ty có 2 kho → chuyển kho mà không ghi lô thì lô "mất dấu" ở kho nhận. Nhóm nên tự bổ sung và giải thích.
- **Va chạm nhóm khác bắt đầu từ M2, không chỉ từ M3:** cột Lô ở mức M2 đã phải thêm vào tabular section `Inventory` của SupplierInvoice (phân hệ Purchases — Đề 3, 4) và SalesInvoice (phân hệ Sales — Đề 5, 6). Cảnh báo va chạm, thống nhất thứ tự sửa (mục 6) và sao lưu `.dt` áp dụng ngay từ phần M2.
- Trong Jet **không có catalog nào có Owner** thuộc phần nghiệp vụ (tab Owners của Products, Warehouses, Counterparties đều trống). Mẫu "catalog cấp dưới" phải lấy từ giáo trình (Bài 4: CounterpartyContracts thuộc Counterparties), không có mẫu Jet để copy.
- SupplierInvoice và SalesInvoice chỉ đưa dòng `ProductType = Inventory` vào sổ kho (temp table `ProductTable` trong `InitializeDocumentData`). Dòng dịch vụ không cần lô.

Chỗ M3 sẽ phải thêm cột lô: query thứ 3 (chỉ số 2) của `InitializeDocumentData` trong `cf/Documents/InventoryIncrease/Ext/ManagerModule.bsl` — `SELECT VALUE(AccumulationRecordType.Receipt) AS RecordType, … Product, SUM(Quantity) … GROUP BY Product, Period, Warehouse` (bản đã sửa ở recipe 1.4).

### 1.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** công ty phân phối thực phẩm khô, 2 kho (Kho Long Biên — kho chính, Kho Hà Đông — kho vệ tinh), ~40 mặt hàng chia nhóm (folder) Mì, Đồ hộp, Bánh kẹo; 4 nhà cung cấp, 10 khách (siêu thị mini, tạp hóa). Hạn sử dụng: mì 6 tháng, đồ hộp 24 tháng, bánh 9 tháng. Chính sách: hủy hàng còn dưới 15 ngày.

**Dữ liệu nền trên Jet gốc:** Warehouses (2), Products (≥12 mặt hàng có giao dịch, `ProductType = Inventory`), Units (thùng, gói), Counterparties (NCC tick `Supplier`, khách tick `Customer`). Trên Jet gốc **chưa có lô** → ghi số lô và hạn dùng vào `Comment` của chứng từ để làm lộ khoảng trống.

**Bộ chứng từ một tháng (≥15, phân hệ Warehouses):**

| # | Ngày | Chứng từ | Nội dung | Mục đích làm lộ gap |
|---|---|---|---|---|
| 1–2 | 01 | InventoryIncrease ×2 | Tồn đầu 2 kho; Comment ghi "Lô L01 HSD 15/…" | Lô chỉ nằm trong ghi chú, báo cáo không đọc được |
| 3–5 | 03–06 | InventoryIncrease ×3 | Nhập thêm cùng mặt hàng mì, lô mới hạn xa hơn | Tồn cộng dồn, không phân biệt lô cũ/mới |
| 6–9 | 07–15 | InventoryTransfer ×4 | Chuyển mì, đồ hộp từ Long Biên sang Hà Đông | Kho nhận không biết hạn của hàng nhận |
| 10–12 | 16–20 | InventoryWriteOff ×3 | Hủy bánh hết hạn | Không có lý do, không có lô, giá trị lấy bình quân |
| 13 | 22 | InventoryIncrease | Nhập lô bánh mới giá cao hơn | Giá vốn bình quân trộn lô cũ và mới |
| 14–15 | 25–28 | InventoryTransfer ×2 | Chuyển ngược hàng cận date về kho chính để hủy | Dẫn vào câu hỏi 3 |
| 16–17 | 30 | InventoryWriteOff ×2 | Hủy cuối tháng | So sánh giá trị hủy với giá nhập của lô thật |
Có thể thêm 2–3 SupplierInvoice / SalesInvoice làm bối cảnh (không tính vào 15).

**5 chứng từ cho phiếu quan sát trước/sau:** #1 (tồn đầu), #3 (lô thứ hai cùng mặt hàng), #6 (chuyển kho), #10 (hủy đầu tiên), #13 (lô giá cao). **Báo cáo theo dõi:** `AvailableStock` (số lượng theo kho) và `StockStatement` (giá trị). Điều cần ghi nhận: sau #3 tồn tăng nhưng không có dòng nào cho biết "bao nhiêu thùng hết hạn tháng nào"; sau #10 giá trị hủy là bình quân, không phải giá của lô hủy.

### 1.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Catalog `Batches` (Lô hàng, cấp dưới của Products)**
- Tab **Owners**: thêm `Catalog.Products` (Bài 4, Subordination). Standard attribute **Owner** — đổi Synonym thành "Mặt hàng".
- Attributes: `ProductionDate` (Date, Date format = Date), `ExpiryDate` (Date, Date format = Date, **Fill checking** = Show error), tùy chọn `Supplier` (CatalogRef.Counterparties). `Description` = số lô in trên thùng.
- Numbering: **Code series** = *Within subordination to owner* (Bài 4) để mã lô đếm lại theo từng mặt hàng. Không phân cấp.
- Mẫu Jet cho phần còn lại (form, quyền): `Warehouses` (`cf/Catalogs/Warehouses.xml`).

**b) Cột `Batch` trong tabular section `Inventory`**
- Thêm attribute `Batch` (CatalogRef.Batches) vào `Inventory` của SupplierInvoice, InventoryIncrease, SalesInvoice, InventoryWriteOff (và nên thêm InventoryTransfer).
- **Choice parameter links**: `Filter.Owner` ← cột `Product` của cùng dòng (Bài 4 — giống Contract lọc theo Customer), để chỉ chọn được lô của đúng mặt hàng. (cách chọn cột của tabular section trong hộp thoại có thể khác theo phiên bản — kiểm tra trên máy)
- Đặt lên form: mở `DocumentForm` → kéo `Inventory.Batch` vào bảng `Inventory`, cạnh `InventoryProduct` (Bài 9). Các form có sẵn của Jet: `InventoryProduct`, `InventoryQuantity`… (`cf/Documents/*/Forms/DocumentForm/Ext/Form.xml`).
- **Không** đặt Fill checking bắt buộc cho `Batch` trên SupplierInvoice/SalesInvoice — dòng dịch vụ không có lô.
- Thêm cột **không** làm hỏng code tính tiền của Jet: `InventoryTabularSectionClientServer.CalculateAmount` chỉ đọc `Quantity`, `Price`.

**c) Báo cáo DCS "Lô sắp hết hạn" trên danh mục**
- Report mới → Main data composition schema → Data set Query (Bài 18) trên `Catalog.Batches`: `Owner` (mặt hàng), `Description`, `ExpiryDate`, `DATEDIFF(&ReportDate, Batches.ExpiryDate, DAY) AS DaysLeft` (Bài 10, DATEDIFF); điều kiện `DaysLeft <= &DaysThreshold`.
- Parameters: `ReportDate` (Date), `DaysThreshold` (Number) — **Include in custom settings**, **Quick access** (Bài 18).
- Conditional appearance: tô đỏ khi `DaysLeft < 0` (đã hết hạn).
- Hạn chế cố ý ghi vào phân tích: báo cáo đọc **danh mục** nên lô đã bán hết vẫn hiện. Muốn biết "lô sắp hết hạn **còn bao nhiêu**" thì cần sổ có chiều Lô → M3.

**d) Đăng ký**
- `Batches` → subsystem con `Warehouses/Catalogs` (`cf/Subsystems/Warehouses/Subsystems/Catalogs.xml`); report → subsystem cha `Warehouses` (`jet-extending.md` 7.3).
- Role `UseWarehouses`: 9 quyền catalog; `Use` + `View` report (mẫu `Report.AvailableStock`). Nếu nhóm Purchases/Sales cần chọn lô trên hóa đơn: thêm `Read`, `View`, `InputByString` cho `Catalog.Batches` vào `UsePurchases`, `UseSales`. FullAccess: tắt `InteractiveDelete` (`jet-extending.md` 6.2).

### 1.4. Hướng M3

Hai hạng mục M3: (1) thêm chiều Lô vào InventoryInWarehouses + xử lý InventoryCost; (2) báo cáo tồn theo lô và hạn dùng. Recipe cho nhóm 2 làm **phần nhỏ nhất** của (1) — chiều Lô cho hai chứng từ kho thuần (InventoryIncrease, InventoryWriteOff) — rồi (2) bằng DCS. Phần còn lại của (1) là thang gợi ý cho nhóm 1.

#### Recipe M3 cho nhóm 2 (có giảng viên kèm)

Ý nghĩa nghiệp vụ: sổ tồn kho hiện "nhớ" mặt hàng nào, ở kho nào, còn bao nhiêu. Ta dạy sổ nhớ thêm "thuộc lô nào". Khi đó báo cáo hỏi được "kho Long Biên còn bao nhiêu thùng mì lô L03".

Bước 1 (Designer, không code): AccumulationRegister `InventoryInWarehouses` → Dimensions → thêm `Batch` (CatalogRef.Batches). **Không** bật "không cho phép giá trị rỗng" cho dimension mới (Jet bật `DenyIncompleteValues` cho Product/Warehouse — tên property này ngoài giáo trình, hãy kiểm tra lại trong Syntax assistant) vì các chứng từ chưa sửa vẫn ghi lô rỗng. Cập nhật database configuration. Không đụng InventoryCost.

Bước 2 (code): sửa `InitializeDocumentData` của InventoryIncrease — 2 chỗ, không thêm query nên `QueryResult[2]`, `QueryResult[3]` giữ nguyên.

code minh họa — chạy thử để kiểm chứng
```bsl
	// cf/Documents/InventoryIncrease/Ext/ManagerModule.bsl
	// (1) Query thứ hai — DocumentInventory: thêm cột lô của từng dòng
	|SELECT
	|	DocumentHeader.Date AS Period,
	|	DocumentHeader.Warehouse AS Warehouse,
	|	InventoryIncreaseInventory.Product AS Product,
	|	InventoryIncreaseInventory.Batch AS Batch,
	|	InventoryIncreaseInventory.Quantity AS Quantity,
	|	InventoryIncreaseInventory.Amount AS Amount
	|INTO DocumentInventory
	// ... phần còn lại giữ nguyên

	// (2) Query cho InventoryInWarehouses (chỉ số 2): đưa Batch ra và vào GROUP BY
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentInventory.Period AS Period,
	|	DocumentInventory.Warehouse AS Warehouse,
	|	DocumentInventory.Product AS Product,
	|	DocumentInventory.Batch AS Batch,
	|	SUM(DocumentInventory.Quantity) AS Quantity
	|FROM
	|	DocumentInventory AS DocumentInventory
	|
	|GROUP BY
	|	DocumentInventory.Product,
	|	DocumentInventory.Batch,
	|	DocumentInventory.Period,
	|	DocumentInventory.Warehouse
	|;
	// Query cho InventoryCost (chỉ số 3) giữ nguyên: giá vốn vẫn theo mặt hàng + kho
```

Bước 3 (code): InventoryWriteOff làm cùng ý, khác một điểm: query sổ tồn kho (chỉ số 5) hiện đọc `ProductTable` (đã gộp theo mặt hàng, còn dùng cho giá vốn). Thêm `InventoryWriteOffInventory.Batch AS Batch` vào `DocumentInventory`, rồi cho query chỉ số 5 đọc `FROM DocumentInventory` với cột `Batch` và `GROUP BY Period, Warehouse, Product, Batch`, `RecordType` = Expense. `ProductTable` và query giá vốn giữ nguyên; `QueryResult[5]`, `[6]` giữ nguyên.

Giải thích theo nghiệp vụ:
- `DocumentInventory` là bảng tạm "mỗi dòng hàng một dòng"; thêm `Batch` để bước sau biết dòng nào thuộc lô nào. Hai dòng cùng mặt hàng khác lô → hai bản ghi trong sổ; cùng lô → gộp một.
- Bảng cuối phải có **đúng tên cột** trùng tên dimension (`Batch`), vì `PostingManagement.ReflectInventoryInWarehouses` chỉ `Load` bảng vào sổ, không đổi tên giúp. Cột không phải `SUM` phải nằm trong `GROUP BY`.
- Giá vốn (InventoryCost) vẫn bình quân theo mặt hàng + kho — quyết định của câu hỏi 1–2, ta chưa đổi.

Bước 4 (DCS, không code): report mới đọc `AccumulationRegister.InventoryInWarehouses.Balance` lấy `Product`, `Warehouse`, `Batch`, `Batch.ExpiryDate`, `QuantityBalance`, cộng `DATEDIFF(&ReportDate, InventoryInWarehousesBalance.Batch.ExpiryDate, DAY) AS DaysLeft`; grouping Warehouse → Product → Batch; sắp theo `ExpiryDate` tăng dần (thứ tự FEFO).
Bước 5: ghi sổ lại các InventoryIncrease/WriteOff đã có.

Kiểm chứng: nhập 2 lô cùng mặt hàng → báo cáo có 2 dòng lô; hủy 5 thùng lô 1 → chỉ lô 1 giảm; `AvailableStock` của Jet vẫn chạy (cộng các lô lại). **Cảnh báo:** khi chưa sửa SalesInvoice/InventoryTransfer, bán hàng sẽ ghi lô rỗng và kiểm tra âm kho (`NegativeBalanceControl`) báo thiếu ở dòng lô rỗng — xem thang nhóm 1.

#### Thang gợi ý M3 cho nhóm 1 (nhóm tự xây)

- **Bậc 1 — Hướng đi:** khi sổ có thêm chiều, **mọi** chứng từ ghi vào sổ đó phải mang giá trị cho chiều mới, nếu không số dư tách thành dòng "lô rỗng" âm. Kiểm soát âm kho của Jet đọc `Balance(, )` của sổ, nên nó sẽ thấy từng lô. Quyết định riêng: InventoryCost có cần chiều Lô (câu hỏi 2).
- **Bậc 2 — Dùng gì, đặt ở đâu:**
  - `cf/AccumulationRegisters/InventoryInWarehouses.xml` (dimension), có thể `InventoryCost.xml`.
  - `InitializeDocumentData` của **5** chứng từ: `cf/Documents/{InventoryIncrease, InventoryWriteOff, InventoryTransfer, SupplierInvoice, SalesInvoice}/Ext/ManagerModule.bsl`. Với SupplierInvoice/SalesInvoice, `ProductTable` lọc `ProductType = Inventory` và còn nuôi query InventoryCost — cân nhắc tách bảng như recipe hay thêm Batch vào `ProductTable` (khi đó InventoryCost nhận cột thừa nếu sổ không có chiều Batch — tự kiểm chứng `Load` xử lý cột thừa thế nào).
  - InventoryTransfer: query cuối có `UNION ALL` Expense ở `Warehouse` / Receipt ở `WarehouseReceiver` — lô phải đi theo cả hai vế.
  - Kiểm soát âm kho: `cf/AccumulationRegisters/InventoryInWarehouses/Ext/RecordSetModule.bsl` (temp table chỉ có `Warehouse`, `Product`) và `ManagerModule.bsl` (`NegativeBalanceControl` join theo `Warehouse`, `Product`) — thông báo thiếu hàng hiện chưa nêu lô.
  - Nếu thêm Batch vào InventoryCost: phần CASE tính giá vốn bình quân trong SalesInvoice/WriteOff/Transfer phải join thêm Batch; Sequence `InventoryCostRecalculation` vẫn hoạt động nhưng tính theo lô.
- **Bậc 3 — Khung** (SalesInvoice):

```bsl
	// DocumentInventory: SalesInvoiceInventory.___ AS Batch,
	// Nhánh sổ tồn kho (chỉ số 7): đọc từ ___ (ProductTable hay DocumentInventory?), lọc ProductType = ___
	//   SELECT VALUE(AccumulationRecordType.___) AS RecordType, ..., ___ AS Batch, SUM(___) AS Quantity
	//   GROUP BY ___
	// QueryResult[___] cho TableInventoryInWarehouses có đổi không nếu thêm một temp table?
```

- **Cảnh báo va chạm:** SupplierInvoice là của nhóm Purchases (Đề 3, 4), SalesInvoice của nhóm Sales (Đề 5, 6) — họ cũng sửa cùng `InitializeDocumentData` / cùng tabular section `Inventory`. Đề 2 đọc `InventoryInWarehouses.Balance` theo Product × Warehouse — có Batch thì phải gộp (`SUM`) lại. Đề 9 (kiểm kê) điền SL sổ sách từ cùng sổ. Thêm dimension vào sổ có dữ liệu → re-post toàn bộ chứng từ kho, theo đúng thứ tự ngày.

### 1.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Attribute `ShelfLifeDays` (Number) trên Products + báo cáo so sánh hạn còn lại / hạn chuẩn (% hạn còn) | M2 | nhóm 2 |
| Enumeration `WriteOffReasons` (Hết hạn / Hư hỏng / Thu hồi) + attribute `Reason` trên InventoryWriteOff, báo cáo giá trị hủy theo lý do | M2 | nhóm 2 / nhóm 1 |
| Information register `CustomerShelfLifeRules` (khách → số ngày hạn tối thiểu khi nhận hàng, ví dụ siêu thị yêu cầu ≥ 2/3 hạn) | M2 | nhóm 2 |
| Gợi ý lô FEFO khi nhập Quantity trên SalesInvoice (đọc sổ theo lô, sắp `ExpiryDate`) | M3 | nhóm 1 |
| Chặn bán lô đã hết hạn trong `Posting` (theo mẫu `NegativeBalanceControl`) | M3 | nhóm 1 |

### 1.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Jet tính giá vốn bình quân theo mặt hàng và kho. Theo dõi lô thì có cần giá vốn theo lô?**
- Quan sát: đoạn CASE tính giá vốn trong `InventoryWriteOff/Ext/ManagerModule.bsl` chia `Amount` cho `Quantity` của cả kho. Thử hủy lô cũ ngay sau khi nhập lô giá cao (#13): giá trị hủy là của lô nào?
- Cân nhắc: chênh lệch giá giữa các lô mì/đồ hộp có lớn không? Lợi ích thông tin so với công sức và rủi ro sai.
- Chuẩn mực kế toán Việt Nam cho phép những phương pháp tính giá xuất kho nào — nhóm tự tra, không cần trả lời bằng code.

**2. Thêm chiều Lô vào cả InventoryCost hay chỉ InventoryInWarehouses?**
- So sánh số chứng từ phải sửa, query nào trong Sequence `InventoryCostRecalculation` bị ảnh hưởng, báo cáo `StockStatement`/`ProfitOnSales` thay đổi gì.
- Nếu chỉ InventoryInWarehouses: hai sổ còn "khớp số lượng" theo mặt hàng + kho không? Ai kiểm tra?
- Câu hỏi 1 và 2 phụ thuộc nhau: chọn giá vốn theo lô thì gần như bắt buộc chiều Lô ở InventoryCost.

**3. Hủy hàng hết hạn dùng chứng từ nào? Chứng từ đó thiếu gì?**
- Mở InventoryWriteOff: header `Warehouse`, `Comment`, `Author`; bảng chỉ `Product`, `Quantity` (`cf/Documents/InventoryWriteOff.xml`). Liệt kê thông tin biên bản hủy thực tế cần (lô, lý do, người duyệt, chứng kiến, giá trị) và cái nào thiếu.
- Giá trị hủy do hệ thống tính (bình quân), người dùng không thấy trên phiếu — nhìn ở đâu? (gợi ý: StockStatement, Recorder).
- Đề 9 cũng phân tích InventoryWriteOff từ góc kiểm kê — có thể đối chiếu với nhóm đó.

---

## Đề 2 — Định mức tồn kho chuỗi cửa hàng

### 2.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| InventoryTransfer với Warehouse (kho xuất) và WarehouseReceiver (kho nhận) | **Đúng.** `Warehouse` bắt buộc; `WarehouseReceiver` **không** bắt buộc (`FillChecking = DontCheck`); bảng `Inventory` chỉ `Product`, `Quantity` | `cf/Documents/InventoryTransfer.xml` |
| Sổ InventoryInWarehouses theo Product, Warehouse | **Đúng** (kind Balance, resource `Quantity`) | `cf/AccumulationRegisters/InventoryInWarehouses.xml` |
| Báo cáo AvailableStock, StockStatement | **Đúng** | `cf/Subsystems/Warehouses.xml` (Content) |
| Warehouses không có thuộc tính nghiệp vụ riêng (chỉ liên hệ và thuộc tính bổ sung) | **Đúng.** Chỉ `Code`, `Description` + tabular section `AdditionalAttributes` (SSL Properties) và `ContactInformation` (SSL). Item form có page `GroupGeneral` và `ContactInformationGroup` | `cf/Catalogs/Warehouses.xml`, `cf/Catalogs/Warehouses/Forms/ItemForm/Ext/Form.xml` |

Bổ sung: Jet có sẵn **thuộc tính bổ sung** (additional attributes, SSL) cho Warehouses — người dùng tự thêm "Loại kho" trong Enterprise mode mà không cần Designer. Nhóm nên thử và so sánh với cách M2 (attribute thật + Enumeration): thuộc tính bổ sung không dùng được trong thuật toán ổn định như Enumeration (Bài 3, Bài 4). InventoryTransfer ghi sổ hai vế trong một query `UNION ALL`: Expense ở `Warehouse`, Receipt ở `WarehouseReceiver` (`cf/Documents/InventoryTransfer/Ext/ManagerModule.bsl`) — dùng khi phân tích "cửa hàng nào nhận nhiều nhất".

### 2.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** chuỗi 5 cửa hàng tiện lợi (Cầu Giấy, Đống Đa, Hoàn Kiếm, Thanh Xuân, Long Biên) + 1 kho tổng; 15–20 mặt hàng chủ lực (nước suối, mì ly, sữa hộp, snack…); 2–3 nhà cung cấp; cửa hàng bán lẻ — trên Jet mô phỏng bán lẻ bằng vài SalesInvoice khách "Khách lẻ cửa hàng X" (không tính vào 15).

**Dữ liệu nền:** Warehouses (6), Products, tồn đầu kho tổng và cửa hàng bằng InventoryIncrease.

**Bộ chứng từ một tháng (≥15, phân hệ Warehouses):**

| # | Ngày | Chứng từ | Nội dung | Mục đích làm lộ gap |
|---|---|---|---|---|
| 1–6 | 01 | InventoryIncrease ×6 | Tồn đầu kho tổng + 5 cửa hàng | Cửa hàng lệch nhau, không có chuẩn so sánh |
| 7–11 | 03–07 | InventoryTransfer ×5 | Bổ sung hàng cho 5 cửa hàng, số lượng "theo cảm tính" | Không có định mức để kiểm |
| 12 | 10 | InventoryTransfer | Cửa hàng Cầu Giấy xin gấp nước suối (đã về 0) | Hết hàng mà không ai được cảnh báo |
| 13 | 12 | InventoryTransfer | Chuyển nhầm: kho nhận = kho xuất | `WarehouseReceiver` không bị kiểm tra |
| 14–16 | 14–20 | InventoryTransfer ×3 | Cầu Giấy và Đống Đa nhận lần 2, 3 | Cửa hàng chuyển nhiều nhất → câu hỏi 3 |
| 17 | 22 | InventoryTransfer | Chuyển hàng ế từ Long Biên về kho tổng | Tồn tối đa: chiều ngược lại |
| 18 | 28 | InventoryWriteOff | Hủy hàng vỡ ở một cửa hàng | Không liên quan định mức, làm nhiễu số |

**5 chứng từ cho phiếu quan sát:** #1, #7, #12, #13, #17. **Báo cáo theo dõi:** `AvailableStock` (lọc theo kho). Ghi nhận: báo cáo cho biết "còn bao nhiêu", không cho biết "thiếu bao nhiêu so với mức cần có".

### 2.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Enumeration `WarehouseTypes` + attribute `WarehouseType` trên Warehouses**
- Enumerations → Add → tab Enum values: `CentralWarehouse` (Synonym "Kho tổng"), `Store` ("Cửa hàng") (Bài 3).
- Catalog Warehouses → attribute `WarehouseType` (EnumRef.WarehouseTypes), **Fill value** = `Store`, **Fill checking** = Show error (cách làm như Practice 3 bài tập 4, `references/lessons/bai-01-04.md`).
- Đặt lên ItemForm của Warehouses: kéo vào page `GroupGeneral`, dưới `Description`.
- Vì sao Enumeration: thuật toán đề xuất điều chuyển (M3) sẽ dựa vào giá trị "Kho tổng" — Bài 3/4: thuật toán dựa vào Enumeration/predefined, không dựa vào tên do người dùng gõ.

**b) Information register `StockNorms` (Định mức tồn kho)**
- Dimensions: `Warehouse` (CatalogRef.Warehouses), `Product` (CatalogRef.Products) — bật **Master** cho cả hai (Bài 12) để mở được định mức từ thẻ kho/thẻ hàng. Resources: `MinQuantity`, `MaxQuantity` (Number 15,3 — cùng độ chính xác với `Quantity` của InventoryInWarehouses).
- **Write mode** = Independent (sửa tay, Bài 12). **Periodicity**: None nếu định mức cố định; Month nếu theo mùa (câu hỏi 1). Mẫu Jet: `Prices` (Day, Independent, hai dimension Master) — `cf/InformationRegisters/Prices.xml`.

**c) Báo cáo DCS "Tồn thực tế so với định mức"**
- Query data set: **bảng chính là `InformationRegister.StockNorms`** (nếu periodic thì `.SliceLast(&ReportDate)`), `LEFT JOIN AccumulationRegister.InventoryInWarehouses.Balance(&ReportDate)` theo Warehouse + Product; `ISNULL(QuantityBalance, 0) AS Actual`.
- Lý do bảng chính là định mức: virtual table Balance **chỉ trả dòng có số dư khác 0** — mặt hàng đã về 0 (đúng là mặt hàng hết, cần cảnh báo nhất) sẽ biến mất nếu lấy Balance làm bảng chính. [suy luận từ cách sổ Balance lưu tổng — tự kiểm chứng bằng #12]
- Calculated fields: `Shortage = MinQuantity - Actual`, `ProposedTransfer = MaxQuantity - Actual` (Bài 18).
- Conditional appearance: nền đỏ khi `Actual < MinQuantity`, vàng khi `Actual > MaxQuantity`. Filter `Warehouse.WarehouseType = Cửa hàng`, quick access.
- Mẫu tham khảo đã có trong giáo trình: Practice 18 bài 2 "Goods movement" với cột Required minimum (`references/lessons/bai-18.md`).

**d) Đăng ký**
- Enumeration: chỉ cần thuộc subsystem (không cần quyền). Register `StockNorms` → subsystem cha `Warehouses` (cùng chỗ với hai sổ tích lũy). Report → `Warehouses`.
- Role `UseWarehouses`: register `Read`, `Update`, `View`, `Edit` (mẫu `InformationRegister.Prices` trong `UseSales`); report `Use`, `View`. Attribute mới trên Warehouses tự có quyền vì role có `setForAttributesByDefault = true`.

### 2.4. Hướng M3

Đề có một hạng mục M3: **tự tạo InventoryTransfer đề xuất từ báo cáo cảnh báo** (Data processor). Nhóm 2 dùng recipe; nhóm 1 tự xây theo thang (không xem recipe).

#### Recipe M3 cho nhóm 2 (có giảng viên kèm)

Ý nghĩa nghiệp vụ: thay vì quản lý nhìn báo cáo rồi tự gõ phiếu chuyển, một "nút bấm" đọc định mức của cửa hàng, đọc tồn của cửa hàng và kho tổng, rồi lập sẵn một **phiếu chuyển kho chưa ghi sổ** để quản lý xem lại trước khi ghi sổ.

Bước 1 (Designer): Data processors → Add → `TransferProposal` (Synonym "Đề xuất điều chuyển") (Bài 19). Form: attributes `CentralWarehouse`, `Store` (CatalogRef.Warehouses, bắt buộc). Choice parameters của `CentralWarehouse`: `Filter.WarehouseType` = Kho tổng; của `Store`: = Cửa hàng (Bài 9). Command `CreateTransfer`, kéo lên form. Thêm vào subsystem `Warehouses`; role `UseWarehouses`: `Use`, `View` (mẫu `DataProcessor.InventoryCostRecalculation`).

Bước 2 (code) — form module của data processor:

code minh họa — chạy thử để kiểm chứng
```bsl
#Region FormCommandsEventHandlers
&AtClient
Procedure CreateTransfer(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	TransferRef = CreateTransferAtServer();
	
	If ValueIsFilled(TransferRef) Then
		OpenForm("Document.InventoryTransfer.ObjectForm", New Structure("Key", TransferRef));
	Else
		Message(NStr("en = 'All products of the store are above the minimum quantity.'"));
	EndIf;
EndProcedure
#EndRegion

#Region Private
&AtServer
Function CreateTransferAtServer()
	Query = New Query;
	Query.Text =
	"SELECT
	|	StockNorms.Product AS Product,
	|	StockNorms.MaxQuantity - ISNULL(StoreBalance.QuantityBalance, 0) AS Need,
	|	ISNULL(CentralBalance.QuantityBalance, 0) AS Available
	|FROM
	|	InformationRegister.StockNorms AS StockNorms
	|		LEFT JOIN AccumulationRegister.InventoryInWarehouses.Balance(, Warehouse = &Store) AS StoreBalance
	|		ON StockNorms.Product = StoreBalance.Product
	|		LEFT JOIN AccumulationRegister.InventoryInWarehouses.Balance(, Warehouse = &CentralWarehouse) AS CentralBalance
	|		ON StockNorms.Product = CentralBalance.Product
	|WHERE
	|	StockNorms.Warehouse = &Store
	|	AND ISNULL(StoreBalance.QuantityBalance, 0) < StockNorms.MinQuantity";
	
	Query.SetParameter("Store", Store);
	Query.SetParameter("CentralWarehouse", CentralWarehouse);
	
	Selection = Query.Execute().Select();
	
	DocumentObject = Documents.InventoryTransfer.CreateDocument();
	DocumentObject.Date = CurrentSessionDate();
	DocumentObject.Fill(Undefined);
	DocumentObject.Warehouse = CentralWarehouse;
	DocumentObject.WarehouseReceiver = Store;
	DocumentObject.Comment = NStr("en = 'Proposed by stock norms'");
	
	While Selection.Next() Do
		Quantity = Selection.Need;
		If Quantity > Selection.Available Then
			Quantity = Selection.Available;
		EndIf;
		If Quantity > 0 Then
			NewRow = DocumentObject.Inventory.Add();
			NewRow.Product = Selection.Product;
			NewRow.Quantity = Quantity;
		EndIf;
	EndDo;
	
	If DocumentObject.Inventory.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DocumentObject.Write();
	
	Return DocumentObject.Ref;
EndFunction
#EndRegion
```

Giải thích theo nghiệp vụ:
- `CreateTransfer` (`&AtClient`): `CheckFilling()` bắt chọn đủ hai kho (Bài 19). Phần đọc sổ và tạo chứng từ phải làm trên server (Bài 7); xong thì mở phiếu vừa tạo cho quản lý xem. Tham số `Key` mở đúng chứng từ — Jet dùng cách này trong `cf/Catalogs/Companies/Commands/CompanyDetails/Ext/CommandModule.bsl`.
- Query: bắt đầu từ **định mức của cửa hàng** (mặt hàng tồn 0 vẫn có mặt), nối với tồn cửa hàng và tồn kho tổng. `Balance(, Warehouse = &Store)` — để trống ngày = số dư hiện tại; điều kiện đặt **trong** virtual table (Bài 11). `ISNULL(..., 0)`: không có dòng tồn nghĩa là 0. Chỉ lấy mặt hàng **dưới mức tối thiểu**; số đề xuất = bù đến **mức tối đa**.
- `CreateDocument()` tạo phiếu mới trong bộ nhớ. `Fill(Undefined)` chạy event `Filling` của InventoryTransfer — tức là `ObjectFillingJet.FillDocument`, điền `Author` như khi người dùng tạo tay (Bài 11, Fill).
- Vòng lặp: không đề xuất quá tồn kho tổng; dòng 0 thì bỏ. `Write()` chỉ **ghi**, không ghi sổ — quản lý kiểm tra rồi tự ghi sổ, kiểm soát âm kho của Jet vẫn chạy.
- Nếu `StockNorms` là periodic: thay `InformationRegister.StockNorms AS StockNorms` bằng `InformationRegister.StockNorms.SliceLast(, Warehouse = &Store) AS StockNorms` và bỏ điều kiện Warehouse ở WHERE.

Kiểm chứng: đặt định mức nước suối Cầu Giấy Min 50 / Max 200, tồn 10, kho tổng 500 → phiếu đề xuất 190; kho tổng chỉ còn 100 → đề xuất 100; tồn 60 → không có dòng.

#### Thang gợi ý M3 cho nhóm 1 (nhóm tự xây)

- **Bậc 1 — Hướng đi:** data processor không lưu dữ liệu, chỉ "đọc — tính — tạo chứng từ" (Bài 19). Ba nguồn: định mức (information register), tồn cửa hàng và tồn kho tổng (virtual table Balance, Bài 11). Chứng từ tạo bằng code nên mang đủ giá trị mặc định như khi tạo tay.
- **Bậc 2 — Dùng gì, đặt ở đâu:** form module của data processor, cặp `&AtClient` command → `&AtServer` function; query một lần cho mọi mặt hàng (không query trong vòng lặp); `Documents.InventoryTransfer.CreateDocument()`; điền `Author` qua event `Filling` (đọc `Filling` trong `cf/Documents/InventoryTransfer/Ext/ObjectModule.bsl`). Quyết định: ghi hay ghi sổ luôn (`Write(DocumentWriteMode.Posting)`, Bài 11)? Một phiếu cho mỗi cửa hàng hay cho cả 5?
- **Bậc 3 — Khung:**

```bsl
&AtServer
Function ___()
	// Query: FROM InformationRegister.___ LEFT JOIN ...Balance(, Warehouse = &___) ... WHERE tồn < ___
	// DocumentObject = Documents.___.CreateDocument();  DocumentObject.___(Undefined);
	// Warehouse = ___; WarehouseReceiver = ___
	// While Selection.Next(): Quantity = min(___, ___); If Quantity > 0 -> Inventory.Add()
	// Không có dòng -> Return ___ ; có -> DocumentObject.Write(); Return ___
EndFunction
```

- **Cảnh báo va chạm:** Đề 1 thêm chiều Batch vào InventoryInWarehouses → `Balance` trả nhiều dòng cho một mặt hàng, join theo Product sẽ nhân dòng (phải gộp `SUM` trước khi join). Nếu Đề 1 thêm cột `Batch` vào `Inventory` của InventoryTransfer, phiếu đề xuất phải điền lô. Đề 9 cũng thêm attribute/Filling cho chứng từ kho — thống nhất thứ tự merge.

### 2.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Kiểm tra `WarehouseReceiver` bắt buộc và khác `Warehouse` (Fill checking + `FillCheckProcessing`) | M2 (Fill checking) + M3 | nhóm 2 / nhóm 1 |
| Choice parameters `Filter.WarehouseType` cho `WarehouseReceiver` = Cửa hàng | M2 | nhóm 2 |
| Information register `StoreManagers` (Warehouse → người phụ trách) + phân quyền xem theo cửa hàng | M2 | nhóm 2 |
| Báo cáo "số lần hết hàng" đọc `InventoryInWarehouses` BalanceAndTurnovers theo ngày | M2 (DCS) | nhóm 1 |
| Đưa cảnh báo dưới định mức vào To-do list của SSL (mẫu `ToDoListOverridable` + `DataProcessors.InventoryCostRecalculation`, `jet-warehouse.md` gợi ý 5) | M3 | nhóm 1 |

### 2.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Định mức cố định hay theo mùa? Nếu đổi thì sổ có cần định kỳ?**
- Xem `Prices` của Jet (Periodicity Day) và cách đọc `SliceLast` (Bài 12): hóa đơn tháng trước dùng giá nào?
- Mùa (Tết, hè) ảnh hưởng mặt hàng nào của doanh nghiệp nhóm? Đổi tay mỗi mùa có mất lịch sử không?
- Periodicity Day/Month/Quarter — chọn đơn vị nào khớp với nhịp điều chỉnh định mức thực tế?

**2. Vì sao định mức là sổ thông tin, không phải thuộc tính của Products?**
- Đếm "mấy giá trị định mức cho một mặt hàng" ở chuỗi 5 cửa hàng. Attribute của catalog lưu được mấy giá trị?
- Products dùng chung với Purchases và Sales (có mặt trong cả 3 subsystem `Catalogs`) — ai được sửa thẻ hàng, ai được sửa định mức?
- Còn lựa chọn tabular section trong Warehouses — so sánh khi cần báo cáo, khi cần lịch sử.

**3. Từ số liệu tháng, cửa hàng nào nhận điều chuyển nhiều nhất? Điều đó nói gì về định mức?**
- Đếm theo chứng từ InventoryTransfer (`WarehouseReceiver`) hay theo dòng Receipt trong sổ với `Recorder REFS Document.InventoryTransfer` (Bài 10, REFS)? Hai cách có ra cùng con số?
- Nhiều lần chuyển nhỏ: định mức tối đa quá thấp, hay sức bán thực sự cao, hay quản lý chuyển "cho chắc"?
- Chi phí mỗi chuyến xe — có nên thêm ngưỡng "số lượng chuyển tối thiểu"?

---

## Đề 3 — Đơn đặt hàng nhà cung cấp

### 3.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| SupplierInvoice (Supplier, Warehouse, Currency, phần bảng Inventory, AdvanceClearing) | **Đúng.** Header đủ: `Supplier`, `Warehouse`, `Currency`, `ExchangeRate`, `Multiplier`, `Comment`, `Author`, `Total`, `ExemptFromVAT`. `Inventory`: `Product, Quantity, Price, Amount, VATRate, VATAmount, Total`. `AdvanceClearing`: `Document` (BankPayment / CashVoucher), `Amount`, `AmountCur`. `Supplier` có Choice parameter `Filter.Supplier` | `cf/Documents/SupplierInvoice.xml` |
| Ghi vào 4 sổ: InventoryInWarehouses, InventoryCost, Purchases, SupplierBalance | **Đúng** (`<RegisterRecords>` và 4 lời gọi `Reflect…` trong `Posting`) | `SupplierInvoice.xml`, `SupplierInvoice/Ext/ObjectModule.bsl` |
| Không có chứng từ đặt hàng nhà cung cấp | **Đúng.** Không có Document nào tên *Order*; SupplierInvoice có `BasedOn` rỗng và `Filling` chỉ gọi `ObjectFillingJet.FillDocument` | `cf/Documents/`, `SupplierInvoice.xml` |

Bổ sung: Jet đã có mẫu "tạo chứng từ dựa trên chứng từ khác" ở phía Tiền: CashVoucher và BankPayment có `BasedOn` = SupplierInvoice và xử lý `TypeOf(FillingData) = Type("DocumentRef.SupplierInvoice")` trong `Filling` (`cf/Documents/CashVoucher/Ext/ObjectModule.bsl`). Đơn đặt hàng → hóa đơn mua làm giống hệt.

Thứ tự bảng ghi sổ của SupplierInvoice — quan trọng cho M3 (thêm sổ mới là thêm một query và một chỉ số):

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl
```bsl
	AdditionalProperties.TableForRegisterRecords.Insert("TablePurchases", QueryResult[4].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[5].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableSupplierBalance", QueryResult[6].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[7].Unload());
```

### 3.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** doanh nghiệp nhập khẩu thiết bị điện gia dụng (nồi cơm, quạt, máy lọc không khí), 1 kho, 3 nhà cung cấp (Trung Quốc — USD, Thái Lan — USD, 1 nhà phân phối trong nước — VND), đặt trước 2–6 tuần, giao nhiều đợt.

**Dữ liệu nền:** Currencies (USD + tỷ giá), Counterparties (NCC), Products (~15), Warehouses (1). Trên Jet gốc **chưa có đơn đặt hàng** → nhóm ghi đơn đặt hàng ra bảng Excel ngoài (đúng "cách doanh nghiệp đang làm") để thấy khoảng trống.

**Bộ chứng từ một tháng (≥15, phân hệ Purchases — chủ yếu SupplierInvoice):**

| # | Ngày | Chứng từ | Nội dung | Mục đích làm lộ gap |
|---|---|---|---|---|
| 1–3 | 02–05 | SupplierInvoice ×3 | Nhận đợt 1 của 3 đơn (Excel), mỗi đơn 40–60% | Jet không biết còn thiếu bao nhiêu |
| 4–6 | 08–12 | SupplierInvoice ×3 | Nhận đợt 2; một đơn giao dư 5 cái | Không phát hiện giao dư |
| 7 | 13 | SupplierInvoice | Nhận hàng không có đơn (mua gấp) | Không phân biệt hàng có đơn / không đơn |
| 8–10 | 15–20 | SupplierInvoice ×3 | Hóa đơn USD, tỷ giá khác ngày đặt | Giá đặt và giá nhận khác nhau |
| 11 | 21 | SupplierInvoice | Nhân viên đặt trùng vì không biết hàng đang về | Hậu quả chính của gap |
| 12–14 | 23–28 | SupplierInvoice ×3 | Đợt cuối; một đơn giao thiếu và NCC báo không giao bù | Câu hỏi 3 |
| 15–16 | 29–30 | SupplierInvoice ×2 | Hàng đơn tháng sau về sớm | Kỳ đặt và kỳ nhận khác nhau |
| 17 | 30 | BankPayment | Thanh toán một hóa đơn (bối cảnh) | Không bắt buộc |

**5 chứng từ cho phiếu quan sát:** #1, #4, #7, #8, #12. **Báo cáo theo dõi:** `Purchases` (Counterparty × Product) và `AvailableStock`. Ghi nhận: sau mỗi lần ghi sổ, tồn và lượng mua tăng — nhưng câu "đơn A còn thiếu bao nhiêu" chỉ trả lời được bằng Excel.

### 3.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Enumeration `PurchaseOrderStatuses`**: `New` (Mới), `Confirmed` (Đã xác nhận), `PartiallyReceived` (Nhận một phần), `Received` (Nhận đủ), `Cancelled` (Hủy). Tab Enum values (Bài 3).

**b) Document `PurchaseOrder` (không ghi sổ)**
- Header: `Supplier` (CatalogRef.Counterparties, Fill checking Show error, **Choice parameters** `Filter.Supplier` = True — chép đúng cách Jet làm ở SupplierInvoice), `Warehouse` (CatalogRef.Warehouses), `ExpectedDate` (Date, Date format = Date), `Status` (EnumRef.PurchaseOrderStatuses, Fill value = New), `Comment` (String), `Author` (CatalogRef.Users).
- Tabular section `Inventory`: `Product`, `Quantity`, `Price`, `Amount` — **giữ đúng tên cột của Jet** để sau này dùng lại `InventoryTabularSectionClientServer.CalculateAmount` (module này chỉ cần `Quantity`, `Price`, `Amount`; `CalculateVATAmountAndTotal` cần thêm `VATRate`, `VATAmount`, `Total`).
- Tab Posting: **Posting** = Deny (Bài 11; Jet có `PricesSetupAuxiliary` với `Posting = Deny` làm ví dụ chứng từ không ghi sổ).
- Muốn `Author` tự điền: event `Filling` gọi `ObjectFillingJet.FillDocument` (1 dòng code — nếu giữ M2 thuần thì bỏ, nhập tay).
- Mẫu bắt chước: SupplierInvoice (`cf/Documents/SupplierInvoice.xml`); form tạo mới, kéo field (Bài 9). Nếu copy SupplierInvoice để có form sẵn: đổi tên set additional attributes `Document_PurchaseOrder` ở cả `PropertyManagerOverridable` và `Characteristics` (`jet-extending.md` 3.7) — copy có nhiều rủi ro hơn tạo mới.

**c) Attribute `PurchaseOrder` trên SupplierInvoice**
- Kiểu DocumentRef.PurchaseOrder; **Choice parameter links** `Filter.Supplier` ← `Supplier` của chính hóa đơn (Bài 4) để chỉ chọn đơn của đúng NCC.
- Đặt lên DocumentForm: nhóm `GroupRight`, dưới `Warehouse`.
- Thêm `Document.PurchaseOrder` vào tab Generation (Generated based on) của SupplierInvoice là khai báo (M2); nhưng để nút "tạo dựa trên" điền dữ liệu thì cần code trong `Filling` → M3.

**d) Đăng ký**
- Document → subsystem con `Purchases/Purchases` (cùng SupplierInvoice, `cf/Subsystems/Purchases/Subsystems/Purchases.xml`).
- Role `UsePurchases`: quyền Document **trừ** `Posting`, `UndoPosting`, `InteractivePosting…` khi chưa ghi sổ (mẫu 15 quyền của `Document.SupplierInvoice` trong `cf/Roles/UsePurchases/Ext/Rights.xml`). FullAccess: tắt `InteractiveDelete`. Nhóm Warehouses nếu cần xem đơn → `Read`, `View` trong `UseWarehouses`.

### 3.4. Hướng M3

Hai hạng mục M3: sổ `OrdersToSuppliers` (đơn đặt ghi tăng, SupplierInvoice ghi giảm) và báo cáo đơn chưa hoàn thành. Recipe nhóm 2: **sổ + ghi tăng từ PurchaseOrder + báo cáo**. Thang nhóm 1: **ghi giảm từ SupplierInvoice** (chạm vào code dùng chung).

#### Recipe M3 cho nhóm 2 (có giảng viên kèm)

Ý nghĩa nghiệp vụ: một "sổ hàng đang chờ" — mỗi đơn đặt hàng cộng vào sổ số lượng đã đặt; sau này mỗi lần nhận hàng thì trừ đi. Số dư của sổ = hàng đã đặt mà chưa về.

Bước 1 (Designer): AccumulationRegister `OrdersToSuppliers`, kind **Balance** (Bài 11). Dimensions `Counterparty` (CatalogRef.Counterparties), `Product` (CatalogRef.Products), `PurchaseOrder` (DocumentRef.PurchaseOrder). Resource `Quantity` (Number 15,3). PurchaseOrder → tab Posting: Posting = Allow, chọn `OrdersToSuppliers`; bật **Post in privileged mode** và **Unpost in privileged mode** như mọi chứng từ Jet (`jet-extending.md` 3.1). Role `UsePurchases`: `Read`, `View` cho sổ; thêm quyền Posting cho Document.

Bước 2 (code) — common module `PostingManagement`, thêm một procedure **chép đúng mẫu** `ReflectInventoryInWarehouses`:

code minh họa — chạy thử để kiểm chứng
```bsl
// Movements on the OrdersToSuppliers register.
Procedure ReflectOrdersToSuppliers(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableOrdersToSuppliers = AdditionalProperties.TableForRegisterRecords.TableOrdersToSuppliers;
	
	If Cancel Or TableOrdersToSuppliers.Count() = 0 Then
		Return;
	EndIf;
	
	OrdersToSuppliersRecord = RegisterRecords.OrdersToSuppliers;
	OrdersToSuppliersRecord.Write = True;
	OrdersToSuppliersRecord.Load(TableOrdersToSuppliers);
EndProcedure
```

Bước 3 (code) — manager module của PurchaseOrder:

code minh họa — chạy thử để kiểm chứng
```bsl
#If Server Or ExternalConnection Then
#Region Public
Procedure InitializeDocumentData(PurchaseOrderRef, AdditionalProperties) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PurchaseOrder.Ref AS Ref,
	|	PurchaseOrder.Date AS Date,
	|	PurchaseOrder.Supplier AS Supplier
	|INTO DocumentHeader
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref = &Ref
	|	AND PurchaseOrder.Status <> VALUE(Enum.PurchaseOrderStatuses.Cancelled)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentHeader.Date AS Period,
	|	DocumentHeader.Supplier AS Counterparty,
	|	PurchaseOrderInventory.Product AS Product,
	|	DocumentHeader.Ref AS PurchaseOrder,
	|	SUM(PurchaseOrderInventory.Quantity) AS Quantity
	|FROM
	|	DocumentHeader AS DocumentHeader
	|		INNER JOIN Document.PurchaseOrder.Inventory AS PurchaseOrderInventory
	|		ON DocumentHeader.Ref = PurchaseOrderInventory.Ref
	|
	|GROUP BY
	|	DocumentHeader.Date,
	|	DocumentHeader.Supplier,
	|	PurchaseOrderInventory.Product,
	|	DocumentHeader.Ref";
	
	Query.SetParameter("Ref", PurchaseOrderRef);
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableOrdersToSuppliers", QueryResult[1].Unload());
EndProcedure
#EndRegion
#EndIf
```

Bước 4 (code) — object module của PurchaseOrder, khung giống SupplierInvoice:

code minh họa — chạy thử để kiểm chứng
```bsl
#If Server Or ExternalConnection Then
#Region EventHandlers
Procedure Filling(FillingData, FillingText, StandardProcessing)
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
EndProcedure

Procedure Posting(Cancel, PostingMode)
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	Documents.PurchaseOrder.InitializeDocumentData(Ref, AdditionalProperties);
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	PostingManagement.ReflectOrdersToSuppliers(AdditionalProperties, RegisterRecords, Cancel);
	PostingManagement.WriteRecordSets(ThisObject);
EndProcedure

Procedure UndoPosting(Cancel)
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	PostingManagement.WriteRecordSets(ThisObject);
EndProcedure
#EndRegion
#EndIf
```

Giải thích theo nghiệp vụ:
- `ReflectOrdersToSuppliers` không có "logic nghiệp vụ": chỉ lấy bảng tên `TableOrdersToSuppliers` đổ vào sổ. Tên bảng phải khớp đúng chữ (`jet-extending.md` mục 8).
- `InitializeDocumentData`: query 1 lấy đầu đơn, bỏ đơn Hủy (đơn hủy ghi sổ không sinh dòng → chờ về bằng 0). Query 2 cộng số lượng theo mặt hàng; `Receipt` = "cộng vào sổ"; `QueryResult[1]` = query thứ hai (đếm từ 0).
- `Posting`: 5 bước chuẩn của Jet (khởi tạo → lấy dữ liệu → dọn bản ghi cũ → nạp bảng → ghi); `UndoPosting` chỉ dọn bản ghi cũ; không cần kiểm soát âm kho. `Filling` điền `Author` như mọi chứng từ Jet.

Bước 5 (DCS, không code): report "Hàng đặt chưa về" đọc `AccumulationRegister.OrdersToSuppliers.Balance(&ReportDate)`, lấy `Counterparty`, `PurchaseOrder`, `PurchaseOrder.ExpectedDate`, `Product`, `QuantityBalance`; grouping Counterparty → PurchaseOrder; conditional appearance đỏ khi `ExpectedDate < &ReportDate` (đơn trễ hẹn).

Kiểm chứng: ghi sổ đơn 100 quạt → báo cáo 100; đặt Status = Hủy rồi ghi sổ lại → dòng biến mất. (Ghi giảm khi nhận hàng là phần của SupplierInvoice — làm cùng giảng viên hoặc nhóm Purchases.)

#### Thang gợi ý M3 cho nhóm 1 (nhóm tự xây) — SupplierInvoice ghi giảm

- **Bậc 1 — Hướng đi:** sổ chờ về chỉ đúng khi mỗi lần nhận hàng có một bản ghi trừ đi đúng đơn. Hóa đơn mua phải "biết" đơn của mình (attribute M2 `PurchaseOrder`) và có thêm một bảng ghi sổ.
- **Bậc 2 — Dùng gì, đặt ở đâu:**
  - `cf/Documents/SupplierInvoice.xml`: thêm `OrdersToSuppliers` vào Register records.
  - `cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl`, `InitializeDocumentData`: temp table `DocumentHeader` lấy thêm `PurchaseOrder`; thêm **một query cuối batch** (để không làm lệch `QueryResult[4..7]`) trả bảng Expense; `TableForRegisterRecords.Insert("TableOrdersToSuppliers", QueryResult[___])`.
  - `cf/Documents/SupplierInvoice/Ext/ObjectModule.bsl`, `Posting`: thêm lời gọi `PostingManagement.ReflectOrdersToSuppliers` trước `WriteRecordSets`.
  - Hóa đơn không có đơn (#7): bỏ qua dòng nào? Giao dư (#4): trừ quá → số dư âm — chặn hay cho phép (mẫu chặn: `NegativeBalanceControl`)?
  - Tạo hóa đơn từ đơn: `BasedOn` + nhánh `TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder")` trong `Filling`, mẫu `cf/Documents/CashVoucher/Ext/ObjectModule.bsl`; nên điền số **còn lại** (đọc `OrdersToSuppliers.Balance`) thay vì số đã đặt.
  - Tự đổi `Status` của đơn khi nhận đủ: sửa đơn khác từ trong posting của hóa đơn có nên không? (không sửa object qua reference — `terminology.md` mục 2).
- **Bậc 3 — Khung:**

```bsl
	// DocumentHeader: SupplierInvoice.___ AS PurchaseOrder,
	// Query cuối batch:
	//   SELECT VALUE(AccumulationRecordType.___) AS RecordType, DocumentInventory.Period AS Period,
	//          ___ AS Counterparty, ___ AS Product, ___ AS PurchaseOrder, SUM(___) AS Quantity
	//   FROM DocumentInventory ... WHERE ___ <> VALUE(Document.PurchaseOrder.EmptyRef)
	//   GROUP BY ___
	// AdditionalProperties.TableForRegisterRecords.Insert("Table___", QueryResult[___].Unload());
```

- **Cảnh báo va chạm:** SupplierInvoice cũng bị Đề 1 (cột/chiều Batch trong cùng `InitializeDocumentData`) và Đề 4 (attribute `PromisedDate`) sửa. CashVoucher/BankPayment của nhóm CashManagement đang "dựa trên" SupplierInvoice — không ảnh hưởng nếu chỉ thêm query cuối, nhưng thêm attribute bắt buộc trên SupplierInvoice sẽ làm hóa đơn cũ không ghi lại được. `PostingManagement` là module dùng chung của mọi nhóm — chỉ **thêm** procedure, không sửa procedure có sẵn.

### 3.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Document journal "Chứng từ mua" gom PurchaseOrder và SupplierInvoice (Bài 13) | M2 | nhóm 2 |
| Attribute `ConfirmedDate` (NCC xác nhận ngày giao) cạnh `ExpectedDate`; báo cáo đơn trễ | M2 | nhóm 2 |
| Print form "Đơn đặt hàng" gửi NCC qua SSL Print (`jet-extending.md` 3.6, mẫu `PF_MXL_GoodsReceivedNote`) | M3 | nhóm 1 |
| Báo cáo "tồn dự kiến" = tồn hiện tại + hàng đang về (DCS hai data set: InventoryInWarehouses.Balance và OrdersToSuppliers.Balance) | M2 (khi đã có sổ) | nhóm 2 / nhóm 1 |
| Cấn trừ tạm ứng theo đơn (NCC nước ngoài yêu cầu đặt cọc) — liên kết BankPayment với PurchaseOrder | M3 | nhóm 1 |

### 3.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Sổ Hàng đặt chưa về nên là Balances hay Turnovers?**
- Viết ra câu hỏi nghiệp vụ chính xác mà bộ phận mua cần hỏi ("tại ngày X còn bao nhiêu chưa về?" hay "tháng này đã đặt bao nhiêu?").
- So với hai kind trong Jet: `InventoryInWarehouses` (Balance) và `Purchases` (Turnovers) — mỗi sổ trả lời loại câu hỏi nào (Bài 11)?
- Một sổ Balance có trả lời được câu "tháng này đã đặt bao nhiêu" không (virtual table nào)?

**2. Đơn đặt hàng có nên ghi vào InventoryInWarehouses?**
- Báo cáo `AvailableStock` và kiểm soát âm kho đọc sổ đó — hàng chưa về mà có trong sổ thì bán hàng/chuyển kho sẽ ra sao?
- InventoryCost đi cặp với InventoryInWarehouses — đơn đặt có giá trị vốn chưa?
- "Hàng đang về" có giá trị thông tin — đặt ở đâu để không làm sai "hàng đang có"?

**3. NCC giao thiếu và không giao bù — trạng thái và số liệu xử lý thế nào?**
- Nếu chỉ đổi Status mà sổ vẫn còn số dư, báo cáo chờ về có sai không?
- Các hướng: bản ghi đóng phần còn lại (Expense) khi Status = Nhận đủ/Đóng; sửa số lượng đơn rồi ghi sổ lại; chứng từ "Đóng đơn" riêng. Mỗi hướng để lại dấu vết kiểm toán ra sao?
- Ai được phép đóng đơn thiếu? Có cần lý do (Enumeration) không?

---

## Đề 4 — Đánh giá nhà cung cấp

### 4.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| Counterparties với cờ Supplier | **Đúng.** `Supplier`, `Customer` đều Boolean; một đối tác có thể vừa là khách vừa là NCC. Catalog phân cấp (folder và item) | `cf/Catalogs/Counterparties.xml` |
| Sổ Purchases (Turnovers): Counterparty, Product, PurchaseDocument; Quantity, Amount, VATAmount | **Đúng.** `PurchaseDocument` kiểu DocumentRef.SupplierInvoice | `cf/AccumulationRegisters/Purchases.xml` |
| Báo cáo Purchases | **Đúng** — đọc `Purchases.Turnovers`, tính thêm `Total = Amount + VATAmount` | `cf/Reports/Purchases/Templates/MainDataCompositionSchema/Ext/Template.xml` |
| PriceType trên Counterparties là loại giá **bán** (SalesInvoice tự điền), không phải bảng giá mua | **Đúng.** Form SupplierInvoice không nhắc tới `PriceType` (form module, object module, manager module đều 0 lần); chỉ `CustomerOnChange` của SalesInvoice đọc nó | `cf/Documents/SupplierInvoice/...`, `cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl` |

**Lưu ý khi tính "giá mua bình quân" từ sổ Purchases:**
- `Amount` trong sổ là tiền **chưa VAT, đã quy đổi** ra presentation currency (`Amount * ExchangeRate / Multiplier` trong `InitializeDocumentData`). So sánh NCC nước ngoài và trong nước trên cùng đồng tiền — tốt; nhưng giá phụ thuộc tỷ giá ngày hóa đơn.
- Sổ Purchases nhận **mọi dòng** kể cả dịch vụ (vận chuyển) — khác hai sổ kho (`jet-purchases.md` mục 12, điểm 2). Lọc `Product.ProductType` khi tính giá hàng.
- Sổ không có ngày giao, ngày hẹn — chỉ có `Period` = ngày hóa đơn.

Điểm xuất phát cho báo cáo giá bình quân: query của report Purchases đọc `AccumulationRegister.Purchases.Turnovers(, , Auto, )` với `QuantityTurnover AS Quantity`, `AmountTurnover AS Amount` (`cf/Reports/Purchases/Templates/MainDataCompositionSchema/Ext/Template.xml`) — chưa có field đơn giá.

### 4.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** công ty thương mại vật liệu xây dựng, 2 kho bãi; mặt hàng chính xi măng PCB40 (tấn/bao), thép cuộn D6, thép thanh D16; 3 NCC cho mỗi mặt hàng: A (giá rẻ, hay trễ), B (giá cao, đúng hẹn), C (trung bình, hay giao thiếu).

**Dữ liệu nền:** Counterparties (3–4 NCC tick `Supplier`, 5 khách), Products (6–8), Units. Ngày hẹn giao trên Jet gốc **không có chỗ ghi** → nhóm ghi vào `Comment` dạng "Hẹn 10/…" để làm lộ gap.

**Bộ chứng từ một tháng (≥15, SupplierInvoice):**

| # | Ngày | Chứng từ | Nội dung | Mục đích làm lộ gap |
|---|---|---|---|---|
| 1–3 | 02–04 | SupplierInvoice ×3 | Xi măng từ A, B, C cùng tuần; giá A < C < B | Báo cáo Purchases đã thấy chênh giá |
| 4–6 | 06–09 | SupplierInvoice ×3 | Thép D6 từ A, B, C | Cần giá/tấn, không phải tổng tiền |
| 7–8 | 12–14 | SupplierInvoice ×2 | A giao xi măng trễ 5 ngày so với hẹn (Comment) | Trễ hẹn không đo được |
| 9 | 15 | SupplierInvoice | C giao thiếu 20% so với đơn | Không có số đặt để so |
| 10–11 | 18–20 | SupplierInvoice ×2 | B giao đúng hẹn, giá tăng 3% | Giá — độ tin cậy đánh đổi |
| 12 | 21 | SupplierInvoice | Có dòng dịch vụ vận chuyển | Dịch vụ làm sai giá bình quân nếu không lọc |
| 13–16 | 23–30 | SupplierInvoice ×4 | Lượt mua cuối tháng, A trễ thêm 1 lần | Dữ liệu cho xếp hạng |

**5 chứng từ cho phiếu quan sát:** #1, #4, #7, #9, #12. **Báo cáo theo dõi:** `Purchases` (Counterparty × Product) và `SupplierBalance`. Ghi nhận: thấy "đã mua bao nhiêu tiền", không thấy "đơn giá bình quân", "đúng hẹn bao nhiêu %".

### 4.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Báo cáo DCS giá mua bình quân (NCC × mặt hàng)**
- Query data set trên `AccumulationRegister.Purchases.Turnovers(&BeginOfPeriod, &EndOfPeriod, , )` (Bài 18), lấy `Counterparty`, `Product`, `QuantityTurnover`, `AmountTurnover`; điều kiện `Product.ProductType = VALUE(Enum.ProductTypes.Inventory)`.
- Resource `AvgPrice` với Expression `CASE WHEN Sum(Quantity) = 0 THEN 0 ELSE Sum(Amount) / Sum(Quantity) END` — **phải là resource**, vì giá bình quân ở cấp nhóm = tổng tiền / tổng lượng, không phải trung bình các đơn giá (Bài 18: Resources tính theo grouping).
- Settings: table (dòng Product, cột Counterparty) để đặt 3 NCC cạnh nhau (Bài 18, kiểu Table). Period kiểu StandardPeriod.

**b) Information register `SupplyCommitments` (Cam kết cung ứng)**
- Dimensions `Counterparty` (Choice parameters `Filter.Supplier` = True), `Product` — bật Master. Resources `LeadTimeDays` (Number 3,0), `MinOrderQuantity` (Number 15,3). Write mode Independent. Periodicity: None hoặc Month (cam kết theo hợp đồng năm — Bài 12). Mẫu: `cf/InformationRegisters/Prices.xml`.

**c) Attribute `PromisedDate` trên SupplierInvoice + báo cáo tỷ lệ đúng hẹn**
- Attribute Date (Date format = Date), đặt trên DocumentForm nhóm `GroupRight` cạnh `Date`.
- Báo cáo DCS đọc từ **chứng từ** `Document.SupplierInvoice`: `Supplier`, `Date`, `PromisedDate`, `DATEDIFF(PromisedDate, Date, DAY) AS DelayDays`, `CASE WHEN Date <= PromisedDate THEN 1 ELSE 0 END AS OnTime` (Bài 10). Bắt buộc lọc `Posted = TRUE`. Resource `OnTimeRate = Sum(OnTime) / Count(Ref)`. Chú ý `Date` của chứng từ có cả giờ — so ngày với ngày (`BEGINOFPERIOD(Date, DAY)`, có trong ví dụ DCS của SSL `Reports/OverdueTasks` — ngoài giáo trình, kiểm tra trong Syntax assistant).

**d) Enumeration `SupplierRatings` (A/B/C) + attribute `Rating` trên Counterparties**
- Đặt lên ItemForm của Counterparties: nhóm `GroupCustomerSupplier` (cạnh hai checkbox Customer/Supplier) — `cf/Catalogs/Counterparties/Forms/ItemForm/Ext/Form.xml`.
- Nhập tay theo kết quả báo cáo; tự tính là M3.

**e) Đăng ký**: report → subsystem cha `Purchases`; register → `Purchases`; role `UsePurchases` (report `Use`/`View`, register `Read`/`Update`/`View`/`Edit`). Counterparties dùng chung với Sales — attribute `Rating` hiện cả trên form khách hàng; cân nhắc ẩn khi `Supplier = False` (cần code → M3).

### 4.4. Hướng M3

**Đề 4 không có hạng mục M3.** Các mục dưới là **gợi ý điểm cộng** — xác nhận với giảng viên trước khi làm.

#### Recipe M3 cho nhóm 2 — cảnh báo mua dưới lượng tối thiểu cam kết

Ý nghĩa nghiệp vụ: NCC cam kết giá/hạn giao với điều kiện mỗi lần mua ít nhất N tấn. Khi nhân viên lập hóa đơn mua ít hơn, hệ thống nhắc (không chặn) để họ biết cam kết có thể không được áp dụng.

Vị trí: `#Region EventHandlers` của `cf/Documents/SupplierInvoice/Ext/ObjectModule.bsl` (đã có `Filling`, `Posting`, `UndoPosting`, `BeforeWrite`), event mới `FillCheckProcessing` (Bài 12) — chạy trên server mỗi lần ghi, kể cả khi ghi bằng code (Jet hiện chỉ kiểm tra ở form — `jet-purchases.md` mục 12, điểm 3).

code minh họa — chạy thử để kiểm chứng
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentRows.Product AS Product,
	|	DocumentRows.Quantity AS Quantity
	|INTO DocumentRows
	|FROM
	|	&Inventory AS DocumentRows
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentRows.Product AS Product,
	|	SUM(DocumentRows.Quantity) AS Quantity,
	|	SupplyCommitments.MinOrderQuantity AS MinOrderQuantity
	|FROM
	|	DocumentRows AS DocumentRows
	|		INNER JOIN InformationRegister.SupplyCommitments AS SupplyCommitments
	|		ON DocumentRows.Product = SupplyCommitments.Product
	|			AND (SupplyCommitments.Counterparty = &Supplier)
	|
	|GROUP BY
	|	DocumentRows.Product,
	|	SupplyCommitments.MinOrderQuantity
	|
	|HAVING
	|	SUM(DocumentRows.Quantity) < SupplyCommitments.MinOrderQuantity";
	
	Query.SetParameter("Inventory", Inventory.Unload());
	Query.SetParameter("Supplier", Supplier);
	
	Selection = Query.ExecuteBatch()[1].Select();
	While Selection.Next() Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Product %1: quantity %2 is below the committed minimum %3.'"),
			Selection.Product, Selection.Quantity, Selection.MinOrderQuantity);
		Common.MessageToUser(MessageText, Ref);
	EndDo;
EndProcedure
```

Giải thích theo nghiệp vụ:
- Hóa đơn chưa ghi thì dòng hàng chưa có trong cơ sở dữ liệu; `Inventory.Unload()` đưa bảng hàng **đang soạn** vào query như một bảng tạm (Bài 10: tạo temp table từ value table — cột phải có kiểu, bảng của tabular section có sẵn kiểu).
- Query 2 cộng số lượng theo mặt hàng (một mặt hàng có thể nhập nhiều dòng), nối với cam kết của **đúng NCC trên hóa đơn**, chỉ giữ mặt hàng mua dưới mức (`HAVING` — lọc sau khi cộng). Mặt hàng không có cam kết → không nối được → không cảnh báo.
- `Common.MessageToUser(MessageText, Ref)` là cách Jet báo lỗi (ví dụ `NegativeBalanceControl`). **Không truyền `Cancel`** → chỉ nhắc, hóa đơn vẫn ghi được. Muốn chặn thì truyền `Cancel` như Jet — đó là quyết định quản trị (câu hỏi kiểm soát).

Kiểm chứng: cam kết NCC A xi măng tối thiểu 20 tấn; lập hóa đơn 15 tấn → có thông báo, vẫn ghi sổ được; 2 dòng 10 + 12 tấn → không thông báo.

#### Thang gợi ý M3 cho nhóm 1 — tự xếp hạng NCC theo trọng số

- **Bậc 1 — Hướng đi:** xếp hạng = điểm tổng hợp của 3 chỉ số đo được từ dữ liệu (giá bình quân tương đối, % đúng hẹn, % giao đủ); trọng số là tham số doanh nghiệp đặt. Kết quả ghi vào attribute `Rating` của từng NCC — tức là **sửa catalog bằng code**.
- **Bậc 2 — Dùng gì, đặt ở đâu:** data processor (Bài 19) có form attributes cho 3 trọng số và kỳ; một batch query (temp table cho từng chỉ số, Bài 10) đọc `Purchases.Turnovers` và `Document.SupplierInvoice`; ngưỡng A/B/C. Ghi: lấy object từ reference rồi `Write()` (không sửa được qua reference — `terminology.md`). Trọng số nên lưu ở đâu để lần sau còn (Constant — Bài 13, hay information register periodic)?
- **Bậc 3 — Khung:**

```bsl
	// Batch: INTO PriceIndex (Counterparty, Product, giá / giá thấp nhất cùng mặt hàng) ; INTO OnTime (...) ; 
	// SELECT Counterparty, ___ * &WPrice + ___ * &WOnTime + ___ * &WComplete AS Score ...
	// While Selection.Next(): CounterpartyObject = Selection.Counterparty.___(); CounterpartyObject.Rating = ___; CounterpartyObject.___();
```

- **Cảnh báo va chạm:** Counterparties là catalog dùng chung Sales/Purchases (Đề 6 thêm `Region`, Đề 7 có thể thêm hạn mức) — thống nhất thứ tự thêm attribute. SupplierInvoice bị Đề 1 và Đề 3 cùng sửa; nếu Đề 3 có PurchaseOrder thì `PromisedDate` nên lấy từ đơn (câu hỏi 3).

### 4.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Attribute `ReceivedQuantity` / `OrderedQuantity` theo dòng → báo cáo % giao đủ | M2 | nhóm 2 |
| Information register periodic `SupplierEvaluations` (Counterparty, kỳ Quý → điểm chất lượng do QC chấm tay) | M2 | nhóm 2 |
| Báo cáo xu hướng giá mua theo tháng (DCS, grouping MonthPeriod, biểu đồ) | M2 | nhóm 2 / nhóm 1 |
| Tự điền giá mua theo bảng giá NCC (`jet-purchases.md` gợi ý 3, dùng lại `PriceManagementServerCall`) | M3 | nhóm 1 |
| Cảnh báo khi chọn NCC hạng C trên SupplierInvoice (`SupplierOnChange`) | M3 | nhóm 2 (có giảng viên) / nhóm 1 |

### 4.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Trọng số giữa giá, thời gian giao, độ tin cậy? Đổi trọng số thì xếp hạng đổi thế nào?**
- Lập bảng điểm 3 NCC từ dữ liệu tháng của nhóm; thử 2–3 bộ trọng số (ví dụ 60/20/20 và 30/40/30). NCC nào đổi hạng?
- Chỉ số nào đo được trực tiếp trong Jet (giá), chỉ số nào phải thêm dữ liệu (hẹn giao, giao đủ)?
- Mặt hàng chiến lược (thép cho công trình đang chạy) có nên dùng trọng số khác mặt hàng thường?

**2. Xếp hạng nên là liệt kê hay danh mục? Khi nào đổi sang danh mục?**
- Tiêu chí của giáo trình (Bài 3): Enumeration khi giá trị cố định và thuật toán dựa vào nó; Catalog khi người dùng cần thêm/sửa và cần lưu thêm thông tin.
- Khi doanh nghiệp muốn thêm hạng "D — tạm ngưng", hoặc mỗi hạng có "ngưỡng điểm", "màu", "hạn mức mua" → ai phải sửa phần mềm?
- Jet có ví dụ cả hai: `ProductTypes` (Enumeration, thuật toán posting dựa vào), `PriceTypes` (Catalog, người dùng tự thêm).

**3. Đề này và Đề 3 bổ sung nhau thế nào? Có đơn đặt hàng thì Ngày hẹn giao nằm ở đâu?**
- Ngày hẹn được thỏa thuận lúc nào — lúc đặt hay lúc nhận? Hóa đơn được lập khi nào trong Jet?
- Một đơn nhiều đợt giao, mỗi dòng hàng một ngày hẹn — đặt ở header hay tabular section?
- Nếu có PurchaseOrder: tỷ lệ đúng hẹn tính theo đơn hay theo từng đợt nhận? Hai nhóm có thể dùng chung dữ liệu không?

---

## Đề 5 — Chiết khấu theo số lượng

### 5.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| Danh mục PriceTypes; sổ Prices (PriceType, Product → Price), định kỳ theo ngày | **Đúng.** PriceTypes không phân cấp, `CodeLength = 0`, không có attribute riêng. Prices: Periodicity **Day**, Write mode **Independent**, hai dimension có **Master**, resource `Price` (Number 15,2) | `cf/Catalogs/PriceTypes.xml`, `cf/InformationRegisters/Prices.xml` |
| **Chứng từ PricesSetupAuxiliary để cập nhật giá hàng loạt** | **Lệch.** `PricesSetupAuxiliary` có `Posting = Deny`, chỉ có tabular section `ProductPrices` (`Product`, `CurrentPrice`, `NewPrice`), nằm trong `InternalSubsystem` (ẩn khỏi giao diện); chỉ được dùng làm **bảng đích khi nhập giá từ file** trong form của DataProcessor `PricesSetup`. Việc cập nhật giá hàng loạt do **DataProcessor `PricesSetup`** làm, ghi thẳng record set của `Prices`. (Ghi chú dưới bảng mục 1.3 của đề "PricesSetupAuxiliary ghi vào sổ thông tin Prices" cũng lệch theo.) | `cf/Documents/PricesSetupAuxiliary.xml`, `cf/Subsystems/InternalSubsystem.xml`, `cf/DataProcessors/PricesSetup/Forms/Form/Ext/Form/Module.bsl` |
| Counterparties có PriceType; chọn khách trên SalesInvoice thì loại giá tự điền và giá điền lại | **Đúng, kèm điều kiện:** chỉ khi khách **có** `PriceType` (nếu trống thì giữ loại giá cũ, không điền lại). Giá cũng điền lại khi đổi `PriceType`; **không** điền lại khi đổi `Date` | `cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl` |
| Báo cáo PriceList | **Đúng** — đọc `Prices.SliceLast(&Period, PriceType = &PriceType)` | `cf/Reports/PriceList/...` |

DataProcessor `PricesSetup` ghi giá bằng một record set lọc theo `Period` = ngày hiệu lực và `PriceType` (`InformationRegisters.Prices.CreateRecordSet()` … `RecordSet.Write()` trong form module) — [suy luận] ghi lại cùng ngày + loại giá là thay thế cả bộ giá của ngày đó (cơ chế Filter của record set — ngoài giáo trình, hãy kiểm tra lại trong Syntax assistant).

Chọn khách → `CustomerOnChange` gọi `GetCustomerPriceType` (`&AtServerNoContext`), nếu có loại giá thì gán `Object.PriceType` và gọi `PriceManagementClient.RefillTabularSectionPricesByPriceType(ThisObject)` — procedure này tính lại `Amount` của mọi dòng bằng `CalculateAmount` (`cf/CommonModules/PriceManagementClient/Ext/Module.bsl`).

Cách tính tiền dòng — **không có chỗ cho chiết khấu**, và module này dùng chung với SupplierInvoice và `PriceManagementClient`:

Nguồn: Jet — cf/CommonModules/InventoryTabularSectionClientServer/Ext/Module.bsl
```bsl
Procedure CalculateAmount(TabSectionRow) Export
	
	TabSectionRow.Amount = TabSectionRow.Quantity * TabSectionRow.Price;
	CalculateVATAmountAndTotal(TabSectionRow);
	
EndProcedure
```

### 5.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** nhà phân phối nước giải khát (nước suối, trà xanh, nước tăng lực — đơn vị thùng), 1 kho; 3 loại giá (`PriceTypes`): Đại lý cấp 1, Đại lý cấp 2, Bán lẻ; ~12 khách (2 đại lý cấp 1, 4 cấp 2, 6 cửa hàng). Bậc chiết khấu ví dụ cho cấp 1: ≥100 thùng 3%, ≥300 thùng 5%, ≥500 thùng 7%.

**Dữ liệu nền:** giá cho 3 loại giá qua `PricesSetup` (ngày 01); khách gán `PriceType`; tồn đầu bằng InventoryIncrease. Trên Jet gốc **không có chỗ ghi chiết khấu** → nhân viên giảm `Price` bằng tay hoặc sửa `Amount` (Jet tự tính ngược `Price = Amount / Quantity` trong `InventoryAmountOnChange`).

**Bộ chứng từ một tháng (≥15, SalesInvoice):**

| # | Ngày | Chứng từ | Nội dung | Mục đích làm lộ gap |
|---|---|---|---|---|
| 1–3 | 02–05 | SalesInvoice ×3 | Bán lẻ cho cửa hàng, số lượng nhỏ | Giá theo loại giá chạy đúng |
| 4–5 | 06–08 | SalesInvoice ×2 | Đại lý cấp 1 mua 120 và 350 thùng — nhân viên sửa `Price` giảm 3%, 5% | Chiết khấu "biến mất" vào giá, báo cáo không tách |
| 6 | 09 | SalesInvoice | Cùng khách, nhân viên khác giảm 6% cho 350 thùng | Không có chuẩn, mỗi người một mức |
| 7 | 10 | (PricesSetup) | Tăng giá 5% từ ngày 10 | Không phải chứng từ — quan sát hóa đơn cũ |
| 8–9 | 11–13 | SalesInvoice ×2 | Đơn lớn nhập ngày 09 (lùi ngày) và ngày 12 | Đổi `Date` không điền lại giá |
| 10 | 15 | SalesInvoice | Khách chưa gán PriceType | Giá 0 / phải chọn tay |
| 11–13 | 16–22 | SalesInvoice ×3 | Đại lý cấp 2, một đơn sửa `Amount` cho tròn số | `Price` bị tính ngược lẻ |
| 14–16 | 24–30 | SalesInvoice ×3 | Cuối tháng đại lý ôm hàng để đạt bậc 500 thùng | Chiết khấu theo đơn hay theo tháng? |

**5 chứng từ cho phiếu quan sát:** #1, #4, #6, #8, #11. **Báo cáo theo dõi:** `Sales` (Counterparty × Product) và `ProfitOnSales`. Ghi nhận: doanh thu sau chiết khấu là con số duy nhất; không trả lời được "tháng này chiết khấu bao nhiêu tiền, cho ai, ai duyệt".

### 5.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Information register `DiscountTiers` (Bậc chiết khấu)**
- Dimensions: `PriceType` (CatalogRef.PriceTypes, Master), `Product` (CatalogRef.Products, Master), `MinQuantity` (Number 15,3 — ngưỡng số lượng). Resource: `DiscountPercent` (Number 5,2, không âm).
- Vì sao `MinQuantity` là **dimension** chứ không phải resource: một mặt hàng có nhiều bậc; information register bắt buộc duy nhất theo bộ dimension (Bài 12) — nếu ngưỡng là resource thì mỗi loại giá × mặt hàng chỉ có **một** bậc.
- Write mode Independent. Periodicity: Day (giống `Prices`, giữ lịch sử chương trình chiết khấu — câu hỏi 1) hoặc None.
- Đăng ký: subsystem con `Sales/Pricing` (cùng `Prices`, `cf/Subsystems/Sales/Subsystems/Pricing.xml`); role `UseSales`: `Read`, `Update`, `View`, `Edit` (đúng mẫu `InformationRegister.Prices`).

**b) Cột `DiscountPercent` trong `Inventory` của SalesInvoice (nhập tay)**
- Attribute Number 5,2 trong tabular section; kéo vào bảng `Inventory` của DocumentForm, giữa `InventoryPrice` và `InventoryAmount`.
- **Quan sát quan trọng cho phân tích:** chỉ khai báo cột thì `Amount` **không** thay đổi khi nhập % — `CalculateAmount` vẫn là `Quantity * Price`. Cột M2 chỉ là "ghi chú có cấu trúc". Muốn tiền đúng thì cần M3, hoặc nhân viên tự sửa `Amount` (rủi ro — câu hỏi 3).
- Cột mới **không** tự vào sổ Sales, print form `PF_MXL_SalesInvoice`, hay báo cáo — đọc được bằng báo cáo DCS trên chứng từ `Document.SalesInvoice.Inventory` (lọc `Ref.Posted`).

**c) Báo cáo DCS kiểm tra (M2, gợi ý thêm):** đọc `Document.SalesInvoice.Inventory` nối `InformationRegister.DiscountTiers` để so % đã nhập với % đúng bậc — phát hiện chiết khấu sai chính sách mà chưa cần code.

### 5.4. Hướng M3

Hai hạng mục M3: (1) tự áp chiết khấu khi nhập số lượng — **recipe cho nhóm 2**; (2) báo cáo doanh thu trước/sau chiết khấu (sửa sổ Sales) — **thang cho nhóm 1**.

#### Recipe M3 cho nhóm 2 — tự áp chiết khấu khi nhập số lượng

Ý nghĩa nghiệp vụ: nhân viên gõ số thùng, hệ thống tự tra bảng bậc của loại giá của khách và điền % chiết khấu, rồi tính tiền đã trừ chiết khấu. Nhân viên không phải nhớ bảng bậc, và không ai "giảm tay" khác chính sách.

Vị trí: form module `cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl`. **Không sửa** `InventoryTabularSectionClientServer.CalculateAmount` vì SupplierInvoice dùng chung.

code minh họa — chạy thử để kiểm chứng
```bsl
// region FormTableItemsEventHandlersInventory — thay nội dung handler có sẵn
&AtClient
Procedure InventoryQuantityOnChange(Item)
	TabSectionRow = Items.Inventory.CurrentData;
	TabSectionRow.DiscountPercent = GetDiscountPercent(Object.PriceType, TabSectionRow.Product,
		TabSectionRow.Quantity, Object.Date);
	CalculateAmountWithDiscount(TabSectionRow);
EndProcedure

// handler mới, gắn vào event OnChange của cột DiscountPercent (sửa tay % vẫn tính lại tiền)
&AtClient
Procedure InventoryDiscountPercentOnChange(Item)
	CalculateAmountWithDiscount(Items.Inventory.CurrentData);
EndProcedure

// region Private
&AtClient
Procedure CalculateAmountWithDiscount(TabSectionRow)
	TabSectionRow.Amount = Round(TabSectionRow.Quantity * TabSectionRow.Price
		* (100 - TabSectionRow.DiscountPercent) / 100, 2);
	InventoryTabularSectionClientServer.CalculateVATAmountAndTotal(TabSectionRow);
EndProcedure

&AtServerNoContext
Function GetDiscountPercent(PriceType, Product, Quantity, Date)
	If Not ValueIsFilled(PriceType) Or Not ValueIsFilled(Product) Then
		Return 0;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DiscountTiersSliceLast.DiscountPercent AS DiscountPercent
	|FROM
	|	InformationRegister.DiscountTiers.SliceLast(
	|			&Date,
	|			PriceType = &PriceType
	|				AND Product = &Product) AS DiscountTiersSliceLast
	|WHERE
	|	DiscountTiersSliceLast.MinQuantity <= &Quantity
	|
	|ORDER BY
	|	DiscountTiersSliceLast.MinQuantity DESC";
	
	Query.SetParameter("Date", BegOfDay(Date));
	Query.SetParameter("PriceType", PriceType);
	Query.SetParameter("Product", Product);
	Query.SetParameter("Quantity", Quantity);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DiscountPercent;
	EndIf;
	
	Return 0;
EndFunction
```

Thêm một dòng vào cuối `InventoryProductOnChange` và `InventoryPriceOnChange` có sẵn (sau lời gọi `CalculateAmount`) để đổi mặt hàng/giá cũng áp chiết khấu: `CalculateAmountWithDiscount(Items.Inventory.CurrentData);` — với `InventoryProductOnChange` cần tra lại % trước, như trong `InventoryQuantityOnChange`.

Giải thích theo nghiệp vụ:
- `InventoryQuantityOnChange` chạy trên máy người dùng mỗi khi sửa số lượng: hỏi server "% chiết khấu nào?", ghi % vào dòng, rồi tính tiền.
- `CalculateAmountWithDiscount`: tiền = số lượng × giá × (100 − %)/100, làm tròn 2 số (Jet cũng dùng `Round(..., 2)` trong `InventoryAmountOnChange`). Sau đó gọi lại **đúng hàm VAT của Jet** — VAT tính trên tiền đã chiết khấu.
- `GetDiscountPercent` chạy trên server (`&AtServerNoContext`) vì sổ chỉ đọc được trên server, và không cần dữ liệu form — cùng kiểu với `GetCustomerPriceType` của Jet. `SliceLast(&Date, …)`: bảng bậc **đang hiệu lực** tại ngày hóa đơn — y như cách Jet đọc giá (`PriceManagementServerCall`, cũng dùng `BegOfDay`). `MinQuantity <= &Quantity` + sắp giảm dần + `TOP 1` = lấy **bậc cao nhất đã đạt**. Không có bậc → 0%.
- Nếu `DiscountTiers` không định kỳ (Periodicity None): thay virtual table bằng `InformationRegister.DiscountTiers` và đưa hai điều kiện PriceType/Product xuống `WHERE`.

**Ba chỗ của Jet sẽ "phá" chiết khấu — nhóm phải biết (và nên kiểm thử):**
1. `PriceManagementClient.RefillTabularSectionPricesByPriceType` (gọi khi đổi khách/loại giá) tính lại `Amount` bằng `CalculateAmount` — **mất chiết khấu** trên mọi dòng.
2. `InventoryAmountOnChange`: sửa tay `Amount` → Jet tính ngược `Price = Amount / Quantity`, nên chiết khấu bị "nhét" vào giá.
3. Sổ `Sales` chỉ nhận `Amount` (đã trừ chiết khấu) — doanh thu trước chiết khấu không còn ở đâu (đây là M3 thứ hai).

Kiểm chứng: bậc cấp 1 nước suối 100→3%, 300→5%; nhập 120 thùng → 3%, sửa thành 350 → 5%, sửa thành 50 → 0%; đổi khách sang khách bán lẻ → kiểm tra hiện tượng (1).

#### Thang gợi ý M3 cho nhóm 1 — doanh thu trước và sau chiết khấu

- **Bậc 1 — Hướng đi:** báo cáo đọc từ sổ chỉ thấy những gì posting đẩy vào sổ. Muốn so trước/sau chiết khấu thì sổ phải có thêm một chỉ tiêu (resource) — tiền chiết khấu hoặc tiền trước chiết khấu — và chỉ tiêu đó phải được tính trong query ghi sổ, đã quy đổi tỷ giá như `Amount`.
- **Bậc 2 — Dùng gì, đặt ở đâu:**
  - `cf/AccumulationRegisters/Sales.xml`: thêm resource (ví dụ `DiscountAmount`). Resource thay vì dimension — vì sao?
  - `cf/Documents/SalesInvoice/Ext/ManagerModule.bsl`, `InitializeDocumentData`: temp table `DocumentInventory` (tính từ `Quantity * Price` và `Amount`, nhân `ExchangeRate / Multiplier`), và query trả `TableSales` (chỉ số 6) thêm `SUM(...)`. Không thêm query → các chỉ số giữ nguyên.
  - Report `Sales` (template DCS liệt kê field cố định) và `ProfitOnSales` (đang tính `RevenueAmount = AmountTurnover + VATAmountTurnover` — `jet-sales.md` mục 12).
  - Re-post hóa đơn cũ. Hóa đơn tạo trước khi có cột `DiscountPercent` có giá trị gì?
- **Bậc 3 — Khung:**

```bsl
	// DocumentInventory:
	//   SalesInvoiceInventory.___ * SalesInvoiceInventory.___ * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier
	//     - SalesInvoiceInventory.Amount * DocumentHeader.___ / DocumentHeader.___ AS DiscountAmount,
	// Query cho TableSales: SUM(DocumentInventory.___) AS ___
	// Report Sales: thêm SalesTurnovers.___Turnover AS ___ vào query của template
```

- **Cảnh báo va chạm:** Đề 6 cũng thêm dimension vào sổ `Sales` và sửa đúng query chỉ số 6 — hai nhóm sửa cùng một khối text query, phải merge tay. Đề 1 thêm cột `Batch` vào cùng tabular section `Inventory` và có thể sửa `ProductTable` của SalesInvoice. Đề 7 thêm hạn thanh toán / chặn bán trên SalesInvoice. Print form `PF_MXL_SalesInvoice` (template + `PrintData`) cần cột chiết khấu nếu in cho khách.

### 5.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Attribute `MaxManualDiscount` trên PriceTypes (mức % tối đa được sửa tay) — dữ liệu cho kiểm soát | M2 | nhóm 2 |
| Báo cáo chiết khấu theo người lập (`Author`) và khách, đọc từ chứng từ | M2 | nhóm 2 / nhóm 1 |
| Chiết khấu riêng cho khách cụ thể: thêm dimension `Customer` (rỗng = áp cho mọi khách của loại giá) | M2 | nhóm 1 |
| Chặn ghi khi % trên dòng lớn hơn bậc + `MaxManualDiscount` (kiểm tra trong `FillCheckProcessing` của object module) | M3 | nhóm 1 |
| Chiết khấu lũy kế theo tháng (thưởng doanh số cuối tháng): đọc `Sales.Turnovers` của khách trong tháng (giống Practice 11 bài 8) | M3 | nhóm 1 |

### 5.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Vì sao Prices định kỳ theo ngày? Hóa đơn cũ ra sao khi giá đổi?**
- Mở một hóa đơn trước ngày tăng giá (#4) sau khi chạy PricesSetup (#7): `Price` trên dòng có đổi không? Giá trên hóa đơn được **lưu trong chứng từ** hay đọc lại từ sổ mỗi lần mở?
- Hóa đơn lùi ngày (#8): Jet không điền lại giá khi đổi `Date` — rủi ro gì?
- `SliceLast` theo ngày (Bài 12): vì sao Day mà không Second — có cần hai mức giá trong cùng một ngày không?

**2. Chiết khấu phụ thuộc loại giá, khách cụ thể, hay cả hai?**
- Đếm số dòng trong bảng bậc cho mỗi phương án (loại giá × mặt hàng × bậc so với khách × mặt hàng × bậc).
- Ngoại lệ cho một đại lý chiến lược: thêm khách vào dimension, hay tạo loại giá riêng cho khách đó (Jet cho phép, vì `PriceType` gán theo khách)?
- Khi cả hai cùng có: quy tắc ưu tiên nào (lấy cao hơn, lấy riêng của khách)?

**3. Chỉ nhập tay chiết khấu thì rủi ro kiểm soát nội bộ là gì?**
- Từ dữ liệu #4–#6: hai nhân viên, hai mức cho cùng một khách. Phát hiện được bằng báo cáo nào?
- Jet ghi `Author` = người lập chứng từ — đủ làm dấu vết chưa? Ai duyệt?
- Biện pháp có thể: bảng bậc do một người quản lý, giới hạn % sửa tay, quyền sửa cột theo role (Bài 20), báo cáo ngoại lệ hàng tuần. Biện pháp nào cần code, biện pháp nào chỉ cần quy trình?

---

## 6. Bảng va chạm giữa các nhóm

| Đề | Object/module Jet bị sửa | Nhóm khác cùng chạm | Cần thống nhất |
|---|---|---|---|
| 1 | `Inventory` của 5 chứng từ (cột `Batch`); `InventoryInWarehouses` (+`InventoryCost`) dimension; `InitializeDocumentData` của 5 chứng từ; `NegativeBalanceControl` | Đề 2, 9 (đọc/ghi cùng sổ, cùng chứng từ kho); Đề 3, 4 (SupplierInvoice); Đề 5, 6 (SalesInvoice) | Ai sửa `InitializeDocumentData` trước; re-post theo thứ tự ngày; demo SalesInvoice khi chiều Lô đã có |
| 2 | `Warehouses` (attribute), register mới, data processor tạo `InventoryTransfer` | Đề 1 (chiều Lô làm nhân dòng khi join Balance; cột Batch trên Transfer); Đề 9 | Join theo Product phải gộp lô trước |
| 3 | Document mới; `SupplierInvoice` (attribute, Register records, `InitializeDocumentData`, `Posting`, `Filling`, BasedOn); `PostingManagement` (thêm `ReflectOrdersToSuppliers`) | Đề 1, 4 (SupplierInvoice); CashManagement (CashVoucher/BankPayment dựa trên SupplierInvoice) | Thêm query ở **cuối** batch; chỉ thêm procedure vào `PostingManagement` |
| 4 | `SupplierInvoice` (attribute, `FillCheckProcessing`), `Counterparties` (attribute `Rating`), register mới | Đề 3 (ngày hẹn nên ở đơn); Đề 6, 7 (Counterparties) | Thứ tự thêm attribute vào Counterparties |
| 5 | `SalesInvoice` (cột `DiscountPercent`, form module), sổ `Sales` + `InitializeDocumentData` (M3), report `Sales`/`ProfitOnSales` | Đề 6 (cùng query `TableSales`, cùng sổ); Đề 1 (cột Batch cùng bảng); Đề 7 (SalesInvoice) | Merge tay khối query chỉ số 6; không sửa `InventoryTabularSectionClientServer` / `PriceManagementClient` dùng chung |
