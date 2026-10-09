# Bài tập lớn — hướng dẫn Đề 6, 7, 8, 9 (Sales, CashManagement, Warehouses)

**Khi nào đọc file này:** sinh viên (nhóm 1 — có nền IT, hoặc nhóm 2 — trái ngành) hỏi về Đề 6 (Nhân viên kinh doanh và khu vực), Đề 7 (Hạn thanh toán và tuổi nợ), Đề 8 (Khoản mục chi phí và ngân sách) hoặc Đề 9 (Kiểm kê kho và xử lý chênh lệch) trong `references/btl/de-bai-btl.md`: kiểm chứng phần "Jet gốc đang có", gợi ý dữ liệu mẫu, cách khai báo M2, hướng làm M3, ý tưởng mở rộng, gợi mở câu hỏi phân tích.

## Mục lục

0. [Cách dùng file này](#0-cách-dùng-file-này)
1. [Đề 6 — Nhân viên kinh doanh và khu vực](#đề-6--nhân-viên-kinh-doanh-và-khu-vực)
2. [Đề 7 — Hạn thanh toán và tuổi nợ](#đề-7--hạn-thanh-toán-và-tuổi-nợ)
3. [Đề 8 — Khoản mục chi phí và ngân sách](#đề-8--khoản-mục-chi-phí-và-ngân-sách)
4. [Đề 9 — Kiểm kê kho và xử lý chênh lệch](#đề-9--kiểm-kê-kho-và-xử-lý-chênh-lệch)
5. [Bảng va chạm giữa các nhóm](#5-bảng-va-chạm-giữa-các-nhóm)

## 0. Cách dùng file này

- Mọi khẳng định về Jet dựa trên dump `cf/` nhánh `community`, commit `80884de` (xem `references/jet/jet-overview.md`). Bản Jet khác có thể lệch — đối chiếu trong Designer.
- **Nhóm 2 (trái ngành):** đi theo thứ tự "nghiệp vụ trước, thuật ngữ sau" và "khai báo → nhập liệu → quan sát hệ quả". Mục "code minh họa" cho M3 được phép đưa nguyên vẹn, có giảng viên kèm.
- **Nhóm 1 (thành viên có nền IT):** từ bản 1.8, mọi thành viên nhóm J đều được **code hoàn chỉnh** cho M3 (`references/chinh-sach-code.md`); với nhóm 1 giải thích theo khối thay vì từng dòng. Phần recipe / code minh họa M3 của đề dùng được cho cả nhóm. Mục "Thang gợi ý M3 cho nhóm 1" giữ làm **lối tự xây** khi thành viên muốn tự viết — khi đó gợi ý mỗi lần một bậc. Phần trùng bài thực hành của giáo trình vẫn chỉ gợi ý.
- Tên object mới trong file (Regions, SalesReps, PaymentTerms, ExpenseItems, InventoryCount…) là **gợi ý**, nhóm được đặt tên khác; Synonym ghi tiếng Việt.
- Thao tác Designer lấy theo ghi chú bài học (`references/lessons/`). Nhãn nào không có trong ghi chú được đánh dấu "(tên nút/menu có thể khác theo phiên bản — kiểm tra trên máy)".
- Chiến lược: với đồ án một học kỳ, sửa trực tiếp configuration Jet trên bản fork của nhóm là đơn giản nhất; extension khó hơn (adopted object, safe mode) — xem `references/jet/jet-extending.md` mục 4.
- Code Jet trích nguyên văn theo giấy phép MIT — ghi công "1C:Jet (MIT)". Thiếu bước đăng ký (subsystem, role) là lỗi phổ biến nhất (`jet-extending.md` 3.2, 3.3, 8).

---

## Đề 6 — Nhân viên kinh doanh và khu vực

### 6.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| SalesInvoice có Customer, Warehouse, PriceType, Author, Total… | **Đúng.** Header đủ: `Customer` (Counterparties), `Warehouse`, `Currency`, `ExchangeRate`, `Multiplier`, `PriceType`, `Comment`, `Author`, `Total`, `BankAccount`, `ExemptFromVAT`; tabular section `Inventory`, `AdvanceClearing` | `cf/Documents/SalesInvoice.xml` |
| Sổ Sales: Counterparty, Product, SalesDocument | **Đúng.** Kind Turnovers; resources `Quantity`, `Amount`, `VATAmount` | `cf/AccumulationRegisters/Sales.xml` |
| Báo cáo Sales, ProfitOnSales | **Đúng**, cả hai trong Content của subsystem Sales. Sales đọc `Sales.Turnovers`; ProfitOnSales ghép `Sales.Turnovers` với `InventoryCost.Turnovers` | `cf/Subsystems/Sales.xml`, `cf/Reports/*/Templates/MainDataCompositionSchema/Ext/Template.xml` |
| Author là người tạo chứng từ, không phải người bán | **Đúng.** Kiểu `CatalogRef.Users` (người đăng nhập), được điền tự động khi tạo chứng từ; trên form là `LabelField` (chỉ hiển thị, không sửa) | `cf/Documents/SalesInvoice.xml`; `cf/CommonModules/ObjectFillingJet/Ext/Module.bsl`; `cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form.xml` |

Cách Jet điền `Author` (gọi từ `Filling` của mọi Document nghiệp vụ):

Nguồn: Jet — cf/CommonModules/ObjectFillingJet/Ext/Module.bsl
```bsl
	AddCurrency(DocumentObject, FillingData);
	FillingData.Insert("Author", Users.AuthorizedUser());
	FillPropertyValues(DocumentObject, FillingData);
```

Quan sát thêm (không có trong đề, đáng ghi vào phân tích gap):
- `Users` là danh mục **người dùng phần mềm**. Nhân viên kinh doanh đi thị trường có thể không có tài khoản; kế toán nhập hộ thì Author là kế toán. Dùng Author làm "người bán" sẽ tính hoa hồng sai.
- Counterparties có tabular section `ContactInformation` (SSL) với cột `State`, `City` — là địa chỉ dạng thông tin liên hệ, không phải danh mục vùng để phân tích. [suy luận] Không nên dùng làm "khu vực" vì không chuẩn hóa được (gõ tay, viết khác nhau).
- Mọi dòng của SalesInvoice đều vào `Sales` (cả dòng dịch vụ), còn chỉ dòng `ProductType = Inventory` mới vào sổ kho (`cf/Documents/SalesInvoice/Ext/ManagerModule.bsl`, temp table `ProductTable`).

### 6.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** công ty phân phối dược mỹ phẩm giả định, 1 kho tổng tại Hà Nội, ~20 mặt hàng (kem chống nắng, sữa rửa mặt, vitamin…), 2 loại giá (`PriceTypes`: Bán buôn, Bán lẻ), 12–15 khách hàng là nhà thuốc/cửa hàng ở 6–8 tỉnh thuộc 3 miền, 8 nhân viên kinh doanh (3 Bắc, 3 Nam, 2 Trung), 1 kế toán bán hàng là người nhập hóa đơn.

**Dữ liệu nền trên Jet gốc:** Warehouses (1), Products (20, `ProductType` = Inventory, 1–2 dịch vụ "Phí giao hàng"), Counterparties (khách, tick `Customer`, gán `PriceType`), giá trong `Prices` qua DataProcessor `PricesSetup`, tồn đầu bằng 1 InventoryIncrease. Tạo ít nhất 2 user (kế toán, trưởng phòng) để thấy Author khác nhau.

**Bộ chứng từ một tháng (≥15, phân hệ Sales):**

| # | Ngày | Chứng từ | Nội dung | Mục đích làm lộ gap |
|---|---|---|---|---|
| 1 | 01 | InventoryIncrease | Tồn đầu kho tổng | Chuẩn bị (không tính vào 15) |
| 2–6 | 02–08 | SalesInvoice ×5 | Khách miền Bắc, do 3 NV Bắc bán; kế toán nhập tất cả | Author giống nhau dù người bán khác nhau |
| 7–10 | 09–15 | SalesInvoice ×4 | Khách miền Nam, 1 hóa đơn trưởng phòng tự nhập | Author lúc là kế toán, lúc là trưởng phòng — không phản ánh người bán |
| 11–12 | 16–18 | SalesInvoice ×2 | Khách miền Trung, có dòng dịch vụ "Phí giao hàng" | Dịch vụ vào Sales, có tính hoa hồng không? |
| 13 | 20 | SalesInvoice | Một khách lớn mua qua 2 NV (chia đôi hoa hồng) | Một hóa đơn — một người bán là đủ không? |
| 14 | 22 | SalesInvoice | Khách chuyển từ Thanh Hóa (Bắc) sang Nghệ An (Trung) rồi mua tiếp | Dẫn vào câu hỏi 1 |
| 15–17 | 24–30 | SalesInvoice ×3 | Bán thêm, 1 hóa đơn bị hủy (đánh dấu xóa / bỏ ghi sổ) | Báo cáo đọc từ chứng từ phải lọc Posted |
| 18 | 30 | CashReceipt | Thu tiền một hóa đơn (không bắt buộc) | Hoa hồng tính trên doanh số hay trên tiền đã thu? |

**5 chứng từ cho phiếu quan sát trước/sau:** #2 (hóa đơn đầu tiên), #7 (Author khác), #11 (có dịch vụ), #13 (hai người bán), #14 (khách đổi vùng). **Báo cáo theo dõi:** `Sales` (theo Counterparty, Product) và `ProfitOnSales`. Điều cần ghi nhận: sau mỗi lần ghi sổ, báo cáo tăng đúng doanh số, nhưng **không có cột nào** trả lời "ai bán, vùng nào".

### 6.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Catalog `Regions` (Khu vực, phân cấp Miền → Tỉnh)**
- Loại: Catalog. Tab Hierarchy: **Hierarchical**; **Hierarchy type** = *Folder and item hierarchy* (Miền là nhóm, Tỉnh là phần tử) hoặc *Item hierarchy* (Miền và Tỉnh đều là phần tử chọn được); bật **Limit level count**, **Level count** = 2 (theo `references/lessons/bai-01-04.md`, Bài 4). Đổi Synonym của standard attribute **Parent** thành "Miền".
- Lựa chọn hierarchy type là một quyết định thiết kế: với *Folder and item*, Miền (nhóm) thường không chọn được làm giá trị trên Counterparties — đúng nếu muốn bắt buộc gán đến cấp Tỉnh.
- Mẫu Jet để bắt chước: `Products` / `Counterparties` (`Hierarchical = true`, `HierarchyFoldersAndItems`) — `cf/Catalogs/Products.xml`.

**b) Catalog `SalesReps` (Nhân viên kinh doanh)**
- Attributes: `Region` (CatalogRef.Regions — khu vực phụ trách), `CommissionRate` (Number, Length 5, Precision 2, Nonnegative — % hoa hồng), tùy chọn `User` (CatalogRef.Users — nếu nhân viên có tài khoản). Không phân cấp. Mẫu: `Warehouses` (`cf/Catalogs/Warehouses.xml`, `Hierarchical = false`).
- Nếu tỷ lệ hoa hồng đổi theo thời gian, `CommissionRate` trên catalog chỉ giữ giá trị hiện tại — đây chính là câu hỏi 3, nhóm cần cân nhắc information register periodic (Bài 12).

**c) Attribute mới trên object có sẵn**
- `Counterparties.Region` (CatalogRef.Regions). Counterparties dùng chung với Purchases (nằm ở `Subsystems/Purchases/Subsystems/Catalogs.xml` và `Subsystems/Sales/Subsystems/Catalogs.xml`) — báo nhóm Purchases biết.
- `SalesInvoice.SalesRep` (CatalogRef.SalesReps), **Fill checking** = Show error nếu công ty bắt buộc mọi hóa đơn có người bán.
- Đặt lên form: mở `DocumentForm` của SalesInvoice → kéo attribute từ cây `Object` sang Form items, đặt cạnh `Customer` (Bài 9, Form editor). Trên ListForm thêm cột `SalesRep` để lọc nhanh. (tên nút/menu có thể khác theo phiên bản — kiểm tra trên máy)
- Tự điền `SalesRep` theo khách (ví dụ khách có NV phụ trách mặc định) là **tự động hóa trên form = M3**, giống cách Jet điền `PriceType` khi chọn khách (`CustomerOnChange` → `GetCustomerPriceType`, `cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl`).

**d) Báo cáo DCS doanh số theo nhân viên và khu vực, đọc từ chứng từ**
- Report mới → Main data composition schema → Data set Query (Bài 18). Nguồn: `Document.SalesInvoice.Inventory` (dòng hàng) nối header qua `Ref`: `Ref.SalesRep`, `Ref.Customer.Region`, `Ref.Date`, `Amount`, `Quantity`, `Product`.
- Bắt buộc lọc `Ref.Posted = TRUE` (và loại `Ref.DeletionMark`) — chứng từ chưa ghi sổ không phải doanh số. Đây là khác biệt đầu tiên giữa "đọc từ chứng từ" và "đọc từ sổ" (câu hỏi 2).
- `Amount` trên dòng là **tiền theo đồng tiền chứng từ**; sổ Sales lưu `Amount * ExchangeRate / Multiplier` (xem `InitializeDocumentData`). Nếu có hóa đơn ngoại tệ, báo cáo đọc từ chứng từ sẽ lệch với báo cáo Sales.
- Hoa hồng: calculated field `Amount * CommissionRate / 100` (Bài 18, Calculated fields) — lấy `CommissionRate` bằng cách đưa `Ref.SalesRep.CommissionRate` vào query.
- Settings: grouping Region (kiểu *hierarchy* để có tổng theo Miền — Bài 18) → SalesRep; parameter Period kiểu StandardPeriod.
- Mẫu Jet: report `Sales` (`cf/Reports/Sales.xml` + template), đăng ký option tham khảo `jet-extending.md` 7.2 (tùy chọn, một dòng code trong `ReportsOptionsOverridable`).

**e) Đăng ký**
- Subsystem: `Regions`, `SalesReps` → subsystem con `Sales/Catalogs`; report → subsystem cha `Sales` (`jet-extending.md` 3.2, 7.3).
- Role `UseSales`: 9 quyền catalog cho hai catalog mới; `Use` + `View` cho report (mẫu `Report.Sales` trong `cf/Roles/UseSales/Ext/Rights.xml`). FullAccess: tắt `InteractiveDelete` (`jet-extending.md` 6.2).

### 6.4. Hướng M3

Đề có một hạng mục M3: **thêm chiều Nhân viên, Khu vực vào sổ Sales** (kèm báo cáo đọc từ sổ).

Đoạn Jet sẽ phải sửa — query thứ 7 (chỉ số 6) của batch trong `InitializeDocumentData`, nơi tạo bảng cho sổ Sales:

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
	|SELECT
	|	DocumentInventory.Period AS Period,
	|	DocumentInventory.Counterparty AS Counterparty,
	|	DocumentInventory.Document AS SalesDocument,
	|	DocumentInventory.Product AS Product,
	|	SUM(DocumentInventory.Quantity) AS Quantity,
	|	SUM(DocumentInventory.Amount) AS Amount,
	|	SUM(DocumentInventory.VATAmount) AS VATAmount
	|FROM
	|	DocumentInventory AS DocumentInventory
	// ...
	AdditionalProperties.TableForRegisterRecords.Insert("TableSales", QueryResult[6].Unload());
```

#### Recipe M3 cho nhóm 2 (có giảng viên kèm)

Ý nghĩa nghiệp vụ: hiện sổ doanh số (Sales) chỉ "nhớ" bán cho ai, mặt hàng gì, hóa đơn nào. Ta dạy sổ nhớ thêm "ai bán" và "vùng nào" — từ đó mọi báo cáo đọc sổ đều chia được theo người và vùng.

Bước 1 (Designer, không code): AccumulationRegister `Sales` → Dimensions → thêm `SalesRep` (CatalogRef.SalesReps) và `Region` (CatalogRef.Regions). Cập nhật database configuration.

Bước 2 (code): sửa `InitializeDocumentData` trong manager module của SalesInvoice ở 3 chỗ. Không thêm query mới nên các chỉ số `QueryResult[6..9]` **giữ nguyên**.

code minh họa — chạy thử để kiểm chứng
```bsl
	// (1) Query đầu tiên — DocumentHeader: lấy thêm người bán và vùng
	"SELECT
	|	SalesInvoice.Ref AS Ref,
	|	SalesInvoice.Date AS Date,
	|	SalesInvoice.Customer AS Customer,
	|	SalesInvoice.SalesRep AS SalesRep,
	|	SalesInvoice.Customer.Region AS Region,
	|	SalesInvoice.Warehouse AS Warehouse,
	// ... phần còn lại giữ nguyên

	// (2) Query thứ hai — DocumentInventory: chuyển hai cột xuống từng dòng hàng
	|SELECT
	|	DocumentHeader.Date AS Period,
	|	DocumentHeader.Customer AS Counterparty,
	|	DocumentHeader.SalesRep AS SalesRep,
	|	DocumentHeader.Region AS Region,
	// ... phần còn lại giữ nguyên

	// (3) Query cho sổ Sales (chỉ số 6): đưa hai cột ra và thêm vào GROUP BY
	|SELECT
	|	DocumentInventory.Period AS Period,
	|	DocumentInventory.Counterparty AS Counterparty,
	|	DocumentInventory.SalesRep AS SalesRep,
	|	DocumentInventory.Region AS Region,
	|	DocumentInventory.Document AS SalesDocument,
	|	DocumentInventory.Product AS Product,
	|	SUM(DocumentInventory.Quantity) AS Quantity,
	|	SUM(DocumentInventory.Amount) AS Amount,
	|	SUM(DocumentInventory.VATAmount) AS VATAmount
	|FROM
	|	DocumentInventory AS DocumentInventory
	|
	|GROUP BY
	|	DocumentInventory.Product,
	|	DocumentInventory.Counterparty,
	|	DocumentInventory.SalesRep,
	|	DocumentInventory.Region,
	|	DocumentInventory.Period,
	|	DocumentInventory.Document
```

Giải thích từng chỗ, theo góc nhìn nghiệp vụ:
- (1) `SalesInvoice.SalesRep` — đọc người bán ghi trên hóa đơn. `SalesInvoice.Customer.Region` — đi "qua dấu chấm" từ hóa đơn sang khách, lấy vùng của khách **tại lúc ghi sổ**. Đây là một lựa chọn: nếu sau này khách đổi vùng mà không ghi sổ lại hóa đơn cũ, doanh số cũ vẫn nằm ở vùng cũ; nếu ghi sổ lại, nó chạy sang vùng mới. Nhóm phải lý giải lựa chọn này ở câu hỏi 1.
- (2) Bảng tạm `DocumentInventory` là "mỗi dòng hàng một dòng"; ta chép người bán và vùng của header xuống từng dòng để bước sau dùng được.
- (3) Bảng cuối phải có **đúng tên cột** trùng tên dimension của sổ (`SalesRep`, `Region`), vì `PostingManagement.ReflectSales` chỉ việc `Load` bảng vào sổ — không đổi tên giúp. Mọi cột không phải tổng (`SUM`) phải nằm trong `GROUP BY`.

Bước 3: ghi sổ lại (re-post) toàn bộ SalesInvoice đã có — bản ghi cũ trong sổ không tự có giá trị cho chiều mới.

Bước 4 (DCS, không code): report `Sales` của Jet liệt kê field cố định trong query (`SalesTurnovers.Counterparty AS Counterparty…`), nên phải thêm `SalesTurnovers.SalesRep AS SalesRep`, `SalesTurnovers.Region AS Region` vào query của template rồi tạo settings variant mới; hoặc làm report riêng đọc `AccumulationRegister.Sales.Turnovers`.

Kiểm chứng: ghi sổ một hóa đơn → mở report Sales, nhóm theo SalesRep → doanh số đúng người; đổi `Region` của một khách, **không** ghi sổ lại → doanh số cũ đứng yên; ghi sổ lại hóa đơn đó → doanh số chuyển vùng.

#### Thang gợi ý M3 cho nhóm 1 (nhóm tự xây)

- **Bậc 1 — Hướng đi:** sổ chỉ phân tích được theo những gì là dimension. Muốn sổ Sales trả lời "ai bán, vùng nào" thì dimension phải tồn tại **và** bảng mà chứng từ đẩy vào sổ lúc Posting phải mang giá trị đó (Bài 11; khung posting của Jet ở `jet-overview.md` 10.1).
- **Bậc 2 — Dùng gì, đặt ở đâu:** register `cf/AccumulationRegisters/Sales.xml` (thêm dimension); `cf/Documents/SalesInvoice/Ext/ManagerModule.bsl`, procedure `InitializeDocumentData` — các temp table `DocumentHeader` → `DocumentInventory` → query trả bảng cho `TableSales` (chỉ số 6); `PostingManagement.ReflectSales` không cần sửa (chỉ `Load`). Report `Sales` (template DCS). Câu hỏi tự đặt: lấy Region từ hóa đơn hay từ khách, tại thời điểm nào?
- **Bậc 3 — Khung:**

```bsl
	// DocumentHeader:   SalesInvoice.___ AS SalesRep,  ___ AS Region,
	// DocumentInventory: DocumentHeader.___ AS SalesRep, DocumentHeader.___ AS Region,
	// Query cho TableSales: thêm 2 cột ___ và bổ sung ___ vào GROUP BY
	// Sau khi sửa: QueryResult[___] cho TableSales có đổi không? Vì sao?
```

- **Cảnh báo va chạm:** Đề 5 (cùng phân hệ Sales) cũng sửa sổ `Sales` và cùng `InitializeDocumentData` của SalesInvoice (doanh thu trước/sau chiết khấu); Đề 7 cũng chạm SalesInvoice (Hạn thanh toán, chặn bán). Thống nhất ai sửa file nào, merge cẩn thận. Thêm dimension vào sổ có dữ liệu → phải re-post; `ProfitOnSales` đọc `Sales.Turnovers` theo tên field nên không gãy, nhưng muốn lãi gộp theo nhân viên thì phải sửa cả nhánh `InventoryCost` (sổ đó không có SalesRep).

### 6.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Information register periodic `CommissionRates` (SalesRep → tỷ lệ, Periodicity Month); báo cáo hoa hồng đọc `SliceLast` theo ngày hóa đơn | M2 (khai báo + DCS) | nhóm 2 / nhóm 1 |
| Information register `CustomerAssignments` (Counterparty → SalesRep phụ trách, periodic) để biết khách thuộc ai trong từng giai đoạn | M2 | nhóm 2 |
| Chỉ tiêu doanh số tháng theo nhân viên (information register Month) + báo cáo % hoàn thành chỉ tiêu (DCS Union data set) | M2 | nhóm 2 / nhóm 1 |
| Tự điền SalesRep khi chọn khách (theo `CustomerOnChange` của Jet) | M3 | nhóm 1 (nhóm 2 nếu có giảng viên) |
| Hoa hồng chỉ tính khi đã thu tiền: đọc thêm CustomerBalance theo Document | M3 | nhóm 1 |

### 6.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Khu vực gắn vào khách hay từng hóa đơn? Khách đổi vùng thì doanh số cũ tính cho vùng nào?**
- Quan sát: thử kịch bản #14 trên Jet đã mở rộng — đổi Region của khách rồi mở lại báo cáo đọc từ chứng từ (đọc `Ref.Customer.Region` lúc chạy báo cáo) và báo cáo đọc từ sổ (giá trị lúc ghi sổ). Hai báo cáo có khớp nhau không?
- Cân nhắc: một chỗ khai báo (khách) thì ít nhập liệu; ghi thêm trên hóa đơn thì "chụp" lại lịch sử nhưng có thể nhập sai.
- Liên hệ: khu vực có nên là vùng của **nhân viên** thay vì của khách không — khi một nhân viên được điều chuyển vùng?
- Ai trong doanh nghiệp quyết định doanh số cũ thuộc về ai (thưởng vùng, chỉ tiêu)?

**2. Báo cáo đọc từ chứng từ khác gì đọc từ sổ? Khi nào cách thứ nhất không đủ?**
- Quan sát: chứng từ chưa ghi sổ / đã đánh dấu xóa / hóa đơn ngoại tệ — báo cáo nào phải tự lọc, tự quy đổi?
- Nghĩ đến chứng từ thứ hai cũng làm thay đổi doanh số (ví dụ khách trả hàng nếu có): đọc từ chứng từ thì phải ghép mấy nguồn?
- Hiệu năng và "một nguồn sự thật": sổ do Posting tạo, đã qua kiểm tra; chứng từ thì ai cũng sửa được.

**3. Tỷ lệ hoa hồng thay đổi theo thời gian thì lưu ở đâu?**
- So sánh: attribute trên catalog (chỉ giá trị hiện tại), information register periodic (Bài 12: SliceLast theo ngày), hay ghi tỷ lệ lên từng hóa đơn.
- Jet đã có một ví dụ "giá trị đổi theo ngày": sổ thông tin `Prices` (Periodicity Day, `cf/InformationRegisters/Prices.xml`). Hóa đơn cũ dùng giá nào khi giá đổi?
- Hoa hồng tính lại cho tháng đã chốt có được phép không?

---

## Đề 7 — Hạn thanh toán và tuổi nợ

### 7.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| CustomerBalance: LiabilityType (Liability / Advance), Counterparty, Document; Amount | **Đúng.** Kind Balance. Enum `LiabilityTypes`: `Liability` (Synonym "Liability"), `Advance` (Synonym "Advance payments"). `Document` là kiểu phức hợp: SalesInvoice / CashReceipt / BankReceipt | `cf/AccumulationRegisters/CustomerBalance.xml`, `cf/Enums/LiabilityTypes.xml` |
| CashReceipt, BankReceipt có PaymentDetails (Document, PaymentAmount, Amount) | **Đúng.** `Document` kiểu `DocumentRef.SalesInvoice`. `PaymentAmount` = tiền theo đồng tiền chứng từ (vào CashBalance), `Amount` = tiền quy đổi (vào CustomerBalance) | `cf/Documents/CashReceipt.xml`, `BankReceipt.xml`; `CashReceipt/Ext/ManagerModule.bsl` |
| SalesInvoice có AdvanceClearing | **Đúng.** Cột `Document` (CashReceipt / BankReceipt), `Amount`, `AmountCur` | `cf/Documents/SalesInvoice.xml` |
| Báo cáo CustomerBalance thuộc phân hệ Sales | **Đúng** — nằm trong Content của `Subsystems/Sales.xml`, không có trong CashManagement | `cf/Subsystems/Sales.xml` |
| Không có hạn thanh toán, không có hạn mức nợ | **Đúng.** SalesInvoice không có attribute ngày đến hạn; Counterparties không có attribute hạn mức | `SalesInvoice.xml`, `Counterparties.xml` |

**Điểm lệch cần biết (quan trọng với nhóm CashManagement):** role `UseCashManagement` **không có quyền** trên `AccumulationRegister.CustomerBalance` và `Report.CustomerBalance` (chỉ `UseSales` có); với SalesInvoice nó chỉ có `Read`, `View`, `InputByString` (`cf/Roles/UseCashManagement/Ext/Rights.xml`). User chỉ có role của nhóm Tiền sẽ không mở được báo cáo nợ — khi demo bằng user thường phải cấp thêm quyền.

Quy ước dấu trong sổ (chi tiết: `references/jet/jet-cash.md` mục 9.1): hóa đơn ghi Receipt/Liability (+); thu tiền có chọn hóa đơn ghi Expense/Liability; thu tiền **không** chọn hóa đơn ghi Expense/Advance với `Document` = chính phiếu thu (số dư Advance âm). Đoạn quyết định trong posting của phiếu thu:

Nguồn: Jet — cf/Documents/CashReceipt/Ext/ManagerModule.bsl
```bsl
	|	CASE
	|		WHEN DocumentPaymentDetails.Document = VALUE(Document.SalesInvoice.EmptyRef)
	|				OR DocumentPaymentDetails.Document = UNDEFINED
	|			THEN VALUE(Enum.LiabilityTypes.Advance)
	|		ELSE VALUE(Enum.LiabilityTypes.Liability)
	|	END AS LiabilityType,
```

Báo cáo CustomerBalance của Jet tách hai cột như sau (đổi dấu Advance cho dễ đọc):

Nguồn: Jet — cf/Reports/CustomerBalance/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
	CASE
		WHEN CustomerBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
			THEN -CustomerBalance.AmountBalance
		ELSE 0
	END AS AmountAdvance,
```

### 7.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** công ty văn phòng phẩm giả định bán cho ~10 doanh nghiệp, điều khoản 30 hoặc 60 ngày, 1 quỹ tiền mặt (`CashAccounts`), 1 tài khoản ngân hàng (`BankAccounts`), 1 kho. Hai khách "xấu" trả chậm, một khách hay trả trước.

**Dữ liệu nền:** khách (`Customer` = true), 15–20 mặt hàng, giá. **Công nợ đầu kỳ:** Jet không có chứng từ số dư công nợ riêng; Wiki hướng dẫn dùng SalesInvoice với một mặt hàng dịch vụ "Opening balances input", ngày trước ngày bắt đầu (Wiki *1C:Jet Initial Setup Guide*, mục 11). Dùng cách này để có nợ cũ 40–90 ngày — giúp báo cáo tuổi nợ có đủ các nhóm.

**Bộ chứng từ một tháng (≥15):**

| # | Chứng từ | Nội dung | Mục đích |
|---|---|---|---|
| 1–3 | SalesInvoice (ngày tháng trước, hàng "Opening balances input") | Nợ cũ của 3 khách: 75, 45, 20 ngày tuổi | Tạo dữ liệu cho mọi nhóm tuổi nợ |
| 4–10 | SalesInvoice ×7 | Bán chịu trong tháng cho 6 khách | Nợ mới "chưa đến hạn" |
| 11 | BankReceipt | Khách A trả đủ 1 hóa đơn (chọn Document) | Liability của hóa đơn về 0 |
| 12 | CashReceipt | Khách B trả **một phần** hóa đơn | Còn nợ dở dang trên một hóa đơn |
| 13 | BankReceipt | Khách C trả một lần cho 2 hóa đơn (2 dòng PaymentDetails) | Thấy vai trò chiều Document |
| 14 | BankReceipt | Khách D chuyển khoản trước, không chọn hóa đơn | Sinh Advance |
| 15 | SalesInvoice | Bán cho khách D, cấn trừ ở AdvanceClearing | Advance và Liability cùng giảm |
| 16 | SalesInvoice | Bán thêm cho khách đang nợ quá hạn 75 ngày | Jet không cảnh báo gì → gap "dừng bán" |
| 17 | CashReceipt | Trả thừa trên dòng có hóa đơn | Quan sát số dư Liability âm (xem `jet-cash.md` 9.2, [suy luận]) |

**5 chứng từ cho phiếu quan sát:** #4, #12, #13, #14, #15. **Báo cáo theo dõi:** `CustomerBalance` (cột Liability, Advance, Total; nhóm theo Counterparty → Document). Điều cần ghi nhận: báo cáo cho biết **còn bao nhiêu trên từng hóa đơn**, nhưng không có cột "đến hạn ngày nào" hay "quá hạn bao nhiêu ngày".

### 7.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Information register `PaymentTerms` (Điều khoản thanh toán)**
- Dimension: `Counterparty` (CatalogRef.Counterparties), bật **Master** (records đi theo khách, có "Go to" từ form khách — Bài 12).
- Resources: `CreditDays` (Number, Length 3, Precision 0, Nonnegative — số ngày được nợ), `CreditLimit` (Number, Length 15, Precision 2 — hạn mức nợ).
- **Periodicity** = Day hoặc Month (điều khoản đổi theo hợp đồng — chọn và giải thích); **Write mode** = Independent (nhập tay, không cần chứng từ — Bài 12). Có Period nên giữ được lịch sử thay đổi điều khoản.
- Mẫu Jet: `InformationRegister.Prices` (Periodicity Day, Independent, dimension có Master) — `cf/InformationRegisters/Prices.xml`.

**b) Attribute `DueDate` (Hạn thanh toán) trên SalesInvoice**
- Kiểu Date, Date format = Date (không giờ — Bài 2/3). Đặt trên form cạnh `Date`.
- M2 thuần: người dùng tự nhập. Tự tính `DueDate = Date + CreditDays` khi chọn khách là tự động hóa form (M3) — mẫu Jet: `CustomerOnChange` của SalesInvoice.
- Lưu ý va chạm: SalesInvoice là chứng từ của nhóm Sales. Nhóm Tiền thêm attribute vào đó phải báo nhóm Đề 5/Đề 6.

**c) Đăng ký**
- Register → subsystem `CashManagement` (hoặc subsystem con `Catalogs` của nó); role `UseCashManagement`: quyền `Read`, `Update`, `View`, `Edit` (mẫu quyền của `InformationRegister.Prices` trong `UseSales`).
- Cấp thêm `Read`/`View` trên `AccumulationRegister.CustomerBalance` và `Use`/`View` trên report CustomerBalance cho `UseCashManagement` (điểm lệch ở 7.1).

### 7.4. Hướng M3

Hai hạng mục M3: (1) **báo cáo tuổi nợ** — DCS trên sổ, phần "code" chỉ là query; (2) **cảnh báo/chặn bán khi vượt hạn mức** — sửa logic ghi sổ. Hạng mục (1) đơn giản hơn → recipe cho nhóm 2; nhóm 1 xây cả hai, dùng thang gợi ý.

#### Recipe M3 cho nhóm 2 — báo cáo tuổi nợ

Ý nghĩa nghiệp vụ: lấy "còn nợ trên từng hóa đơn" mà Jet đã có, đặt cạnh "hạn trả" mà nhóm vừa thêm, rồi đếm số ngày trễ và xếp vào ngăn: chưa đến hạn / 1–30 / 31–60 / trên 60.

Bước 1: Report mới `AccountsReceivableAging` → Main data composition schema → Data set Query, dán query sau.

code minh họa — chạy thử để kiểm chứng
```bsl
SELECT ALLOWED
	Debts.Counterparty AS Counterparty,
	Debts.Document AS Document,
	Debts.Debt AS Debt,
	Debts.DueDate AS DueDate,
	DATEDIFF(Debts.DueDate, &ReportDate, DAY) AS DaysOverdue,
	CASE
		WHEN DATEDIFF(Debts.DueDate, &ReportDate, DAY) <= 0
			THEN "1. Not due"
		WHEN DATEDIFF(Debts.DueDate, &ReportDate, DAY) <= 30
			THEN "2. 1-30 days"
		WHEN DATEDIFF(Debts.DueDate, &ReportDate, DAY) <= 60
			THEN "3. 31-60 days"
		ELSE "4. Over 60 days"
	END AS AgingGroup
FROM
	(SELECT
		CustomerBalanceBalance.Counterparty AS Counterparty,
		CustomerBalanceBalance.Document AS Document,
		CustomerBalanceBalance.AmountBalance AS Debt,
		CASE
			WHEN SalesInvoices.DueDate = DATETIME(1, 1, 1)
				THEN SalesInvoices.Date
			ELSE SalesInvoices.DueDate
		END AS DueDate
	FROM
		AccumulationRegister.CustomerBalance.Balance(
				&BalanceDate,
				LiabilityType = VALUE(Enum.LiabilityTypes.Liability)) AS CustomerBalanceBalance
			LEFT JOIN Document.SalesInvoice AS SalesInvoices
			ON CustomerBalanceBalance.Document = SalesInvoices.Ref) AS Debts
```

Giải thích theo nghiệp vụ:
- `CustomerBalance.Balance(...)` — "ảnh chụp" công nợ tại một ngày (virtual table Balance, Bài 11). Điều kiện `LiabilityType = Liability` chỉ lấy **nợ hóa đơn**, bỏ tiền trả trước — đây là một lựa chọn thiết kế, nhóm phải lý giải ở câu hỏi 2 (có thể bỏ điều kiện này để thử).
- `LEFT JOIN Document.SalesInvoice ... ON Document = Ref` — từ dòng nợ đi sang chính hóa đơn để lấy ngày đến hạn. Chiều `Document` của sổ chính là "sợi dây" này (câu hỏi 1).
- Query con `Debts` (trong ngoặc) gom phần "còn nợ + hạn trả" một lần, để query ngoài khỏi lặp lại; khối `CASE ... DATETIME(1, 1, 1)` — hóa đơn cũ chưa nhập hạn thì ngày trống; tạm coi hạn = ngày hóa đơn (lựa chọn khác: lấy `CreditDays` từ `PaymentTerms` — làm ở mức nâng cao).
- `DATEDIFF(hạn, &ReportDate, DAY)` — số ngày từ hạn đến ngày xem báo cáo; âm hoặc 0 là chưa đến hạn (Bài 10, DATEDIFF lấy tham số thứ hai trừ tham số thứ nhất).
- `AgingGroup` — tên ngăn có số thứ tự đầu để sắp xếp đúng.

Bước 2 — Parameters (Bài 18): `ReportDate` (Date, Include in custom settings, Quick access). `BalanceDate` không cho người dùng thấy (Availability restriction), Expression bắt chước đúng cách Jet tính ngày cho report CustomerBalance — lấy hết ngày đó, vì Balance(ngày) không tính chính giây biên (Bài 11):

Nguồn: Jet — cf/Reports/CustomerBalance/Templates/MainDataCompositionSchema/Ext/Template.xml
```text
		<expression>CASE WHEN &amp;Period = Undefined OR &amp;Period = NULL OR &amp;Period = DateTime(1,1,1) THEN DateTime(3999,12,31) ELSE DATEADD(EndOfPeriod(&amp;Period, "Day"), "Second", 1) END</expression>
```
(Trong Designer gõ `&` thay cho `&amp;`; thay `&Period` bằng `&ReportDate`.)

Bước 3 — Resources: `Debt` = Sum. Settings: bảng (table) dòng Counterparty → Document, cột AgingGroup; hoặc grouping AgingGroup → Counterparty. Conditional appearance tô đỏ nhóm "Over 60 days".

Bước 4 — Đăng ký: report vào subsystem `CashManagement`, role `UseCashManagement` có `Use`/`View` report **và** `Read` sổ CustomerBalance.

Kiểm chứng: đổi `ReportDate` lùi/tiến 30 ngày → khoản nợ dịch ngăn; ghi sổ phiếu thu #12 → `Debt` của hóa đơn giảm đúng phần đã trả.

#### Thang gợi ý M3 cho nhóm 1 — cảnh báo/chặn bán khi vượt hạn mức

- **Bậc 1 — Hướng đi:** kiểm tra phải chạy **sau khi** bản ghi của hóa đơn đã vào sổ công nợ (để số dư đã gồm hóa đơn đang ghi), trong cùng giao dịch Posting, và đặt `Cancel` nếu chặn. Jet đã có đúng khuôn này cho tồn kho âm (Bài 11, Bài 12 — transaction, `Cancel`).
- **Bậc 2 — Dùng gì, đặt ở đâu:**
  - Mẫu bắt chước: `AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl` (`cf/AccumulationRegisters/InventoryInWarehouses/Ext/ManagerModule.bsl`) — được gọi trong `Posting` của SalesInvoice **sau** `PostingManagement.WriteRecordSets(ThisObject)` (`cf/Documents/SalesInvoice/Ext/ObjectModule.bsl`).
  - Lưu ý: `NegativeBalanceControl` chỉ chạy khi `AdditionalProperties.ForPosting.IsInventoryInWarehousesChange` = True; cờ này và bảng tạm `InventoryInWarehousesChange` do `OnWrite` trong `cf/AccumulationRegisters/InventoryInWarehouses/Ext/RecordSetModule.bsl` tạo ra. CustomerBalance không có record set module nên **không chép điều kiện đó** — chỉ bắt chước vị trí gọi (sau `WriteRecordSets`) và cách báo lỗi.
  - Nơi đặt thủ tục mới: manager module của `AccumulationRegister.CustomerBalance` (hiện chưa có module) hoặc common module của nhóm; gọi từ `Posting` của SalesInvoice.
  - Dữ liệu cần: `InformationRegister.PaymentTerms.SliceLast(&Date, Counterparty = &Customer)` (Bài 12) và `AccumulationRegister.CustomerBalance.Balance(, Counterparty = &Customer)`; báo lỗi bằng `Common.MessageToUser(..., Ref, , , Cancel)` như mẫu.
  - "Chỉ cảnh báo" vs "chặn": cảnh báo không đặt `Cancel`; quyền vượt hạn mức có thể kiểm tra bằng role riêng (Bài 20) — xem câu hỏi 3.
- **Bậc 3 — Khung:**

```bsl
Procedure CreditLimitControl(Ref, Customer, Date, Cancel) Export
	// Query: hạn mức từ PaymentTerms.SliceLast(___, Counterparty = &Customer)
	//        nợ hiện tại từ CustomerBalance.Balance(___, Counterparty = &Customer)
	// Có tính số dư Advance (âm) không? ___
	// If <nợ> > <hạn mức> And <hạn mức> > 0 Then
	//     Common.MessageToUser(___, Ref, , , Cancel);
	// EndIf;
EndProcedure
```

- **Cảnh báo va chạm:** sửa `Posting` của SalesInvoice = sửa chứng từ của nhóm Sales (Đề 5, Đề 6 cũng sửa SalesInvoice). Hạn mức đặt sai sẽ chặn cả việc nhóm Sales ghi sổ dữ liệu demo. `NegativeBalanceControl` đang dùng `Balance(, )` (số dư hiện tại, không theo thời điểm chứng từ — `jet-warehouse.md` mục 7, 13): cân nhắc cùng vấn đề khi ghi sổ lùi ngày.

### 7.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Thêm `CreditDays` mặc định vào báo cáo tuổi nợ: hóa đơn chưa nhập DueDate thì lấy Date + CreditDays từ PaymentTerms (SliceLast) | M3 (query) | nhóm 2 có kèm / nhóm 1 |
| Báo cáo "khách cần dừng bán": nợ quá hạn > 60 ngày hoặc vượt hạn mức, đọc PaymentTerms + CustomerBalance | M2/M3 (DCS hai data set) | nhóm 2 / nhóm 1 |
| Enumeration `CustomerCreditStatus` (Bình thường / Theo dõi / Dừng bán) + attribute trên Counterparties, cập nhật tay | M2 | nhóm 2 |
| Tự điền DueDate khi chọn khách / đổi ngày hóa đơn | M3 (form) | nhóm 1 |
| Áp dụng tương tự cho phải trả nhà cung cấp (SupplierBalance) — lịch trả tiền | M2/M3 | nhóm 1 |

### 7.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Vì sao CustomerBalance cần chiều Document? Bỏ chiều này thì mất khả năng phân tích gì?**
- Thử tưởng tượng sổ chỉ còn Counterparty: kịch bản #12 (trả một phần) và #13 (một lần trả hai hóa đơn) sẽ hiện ra thế nào?
- Nhìn query báo cáo tuổi nợ: phép JOIN sang hóa đơn để lấy hạn dựa vào cột nào?
- Đổi lại: chiều Document làm sổ có nhiều dòng hơn — cái giá về dung lượng/hiệu năng có đáng không với công ty 10 khách? 10.000 khách?
- Tạm ứng (Advance) dùng `Document` = chính phiếu thu: điều đó cho phép cấn trừ theo từng khoản trả trước như thế nào (`jet-cash.md` 9.2)?

**2. Tiền khách ứng trước (Advance) có tính vào tuổi nợ không?**
- Tuổi nợ đo "khoản phải thu trễ bao lâu"; tiền ứng trước là doanh nghiệp đang **nợ lại** khách — cùng bản chất không?
- Khách D vừa nợ hóa đơn cũ vừa có tiền ứng chưa cấn trừ: hiển thị riêng, trừ thẳng, hay nhắc kế toán cấn trừ?
- Ảnh hưởng tới quyết định dừng bán và tới chặn hạn mức (khung bậc 3 có một dòng `___` đúng chỗ này).

**3. Chặn bán hay chỉ cảnh báo khi vượt hạn mức — ai được quyền vượt?**
- Chi phí hai phía: mất đơn hàng/mất khách vs mất tiền vì nợ xấu. Doanh nghiệp giả định của nhóm nghiêng về bên nào?
- Kiểm soát nội bộ: người lập hóa đơn có nên tự vượt? Phân quyền theo role (Bài 20) hay phê duyệt bằng chứng từ riêng?
- Vượt hạn mức nên để lại dấu vết gì (ai, khi nào, lý do)?
- Thời điểm kiểm tra: lúc ghi sổ hóa đơn, lúc lập đơn hàng (Jet không có đơn bán), hay cả hai?

---

## Đề 8 — Khoản mục chi phí và ngân sách

### 8.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| CashVoucher, BankPayment có Operation là liệt kê chỉ có 2 giá trị Supplier và Other | **Đúng**, nhưng là **hai enumeration riêng**: `CashVoucherOperations` và `BankPaymentOperations`, mỗi cái có `Supplier` (Synonym "Payment to supplier") và `Other`. Fill value = Supplier, Fill checking = Show error | `cf/Enums/CashVoucherOperations.xml`, `BankPaymentOperations.xml`; `cf/Documents/CashVoucher.xml` |
| Sổ CashBalance: BankCashAccount, CashType (Cash/NonCash); AmountCur | **Đúng.** `BankCashAccount` phức hợp CashAccounts/BankAccounts; Enum `CashTypes`: `Cash` ("Cash-in-hand"), `NonCash` ("Non cash"). Chỉ có `AmountCur` (tiền theo đồng tiền tài khoản), không có số quy đổi | `cf/AccumulationRegisters/CashBalance.xml`, `cf/Enums/CashTypes.xml` |
| Báo cáo CashStatement | **Đúng**, đọc `CashBalance.BalanceAndTurnovers`, có field `Recorder`, không có field nào nói mục đích chi | `cf/Reports/CashStatement/Templates/MainDataCompositionSchema/Ext/Template.xml` |

Quan sát thêm (dùng được ngay cho M2):
- Khi `Operation = Other`, form **ẩn** `Counterparty` và cột `Document` của PaymentDetails, object module **bỏ kiểm tra bắt buộc** `Counterparty`; posting chỉ ghi sổ công nợ cho dòng `Supplier`. Tức là chi "Other" chỉ đi vào CashBalance.

Nguồn: Jet — cf/Documents/CashVoucher/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
	If Object.Operation = PredefinedValue("Enum.CashVoucherOperations.Other") Then
		Items.Counterparty.Visible = False;
		Items.PaymentDetailsDocument.Visible = False;
	Else
		Items.Counterparty.Visible = True;
		Items.PaymentDetailsDocument.Visible = True;
	EndIf;
```

Nguồn: Jet — cf/Documents/CashVoucher/Ext/ObjectModule.bsl
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Operation = Enums.CashVoucherOperations.Other Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Counterparty"));
	EndIf;
	
EndProcedure
```

- BankPayment chỉ ghi sổ khi `Paid` = True và lấy `PaymentDate` làm ngày ghi sổ (`cf/Documents/BankPayment/Ext/ManagerModule.bsl`, `WHERE ... AND BankPayment.Paid`). Lệnh chi chưa tick Paid sẽ không vào CashStatement — báo cáo chi phí đọc từ chứng từ phải xử lý giống vậy.
- `PaymentDetails.PaymentAmount` là tiền theo đồng tiền chứng từ, `Amount` là tiền quy đổi (form tính `Amount = PaymentAmount * ExchangeRate / Multiplier`).

### 8.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** công ty vận tải nội địa giả định, 12 xe tải, 1 quỹ tiền mặt ở bãi xe, 1 tài khoản ngân hàng; chi phí chính: nhiên liệu, cầu đường (BOT), sửa chữa, lương tài xế, thuê bãi. Kế hoạch tháng do giám đốc duyệt.

**Dữ liệu nền:** `CashAccounts`, `BankAccounts`, vài Counterparties là nhà cung cấp (cây xăng, gara). **Số dư tiền đầu kỳ:** Wiki hướng dẫn dùng CashReceipt / BankReceipt với Operation = Other (Wiki *Initial Setup Guide*, mục 11).

**Bộ chứng từ một tháng (≥15):**

| # | Chứng từ | Operation | Nội dung | Mục đích |
|---|---|---|---|---|
| 1–2 | CashReceipt, BankReceipt | Other | Số dư đầu kỳ | Chuẩn bị |
| 3–6 | CashVoucher ×4 | Other | Đổ dầu tại trạm (tiền mặt) | Nhiều khoản nhiên liệu lẫn trong "Other" |
| 7–8 | CashVoucher ×2 | Other | Vé cầu đường | |
| 9 | BankPayment | Other | Lương tài xế (Paid) | Khoản lớn, cần phân loại |
| 10 | BankPayment | Other | Thuê bãi tháng (Paid) | |
| 11 | BankPayment | Other | Lương tháng sau — **chưa** tick Paid | Không vào CashStatement; báo cáo chi phí có tính không? |
| 12 | SupplierInvoice | — | Gara sửa xe, ghi nợ (Purchases) | Chi phí phát sinh qua nhà cung cấp |
| 13 | BankPayment | Supplier | Trả gara theo #12 | Dẫn vào câu hỏi 2 |
| 14 | CashVoucher | Other | Sửa xe nhỏ trả tiền mặt ngay | Cùng mục "sửa chữa" nhưng đi đường khác #12–13 |
| 15–17 | CashVoucher, BankPayment | Other | Nhiên liệu cuối tháng, phí ngân hàng, tiếp khách | Đủ đa dạng cho báo cáo |

**5 chứng từ cho phiếu quan sát:** #3, #9, #11, #13, #14. **Báo cáo theo dõi:** `CashStatement` (nhóm theo BankCashAccount, chi tiết Recorder). Điều cần ghi nhận: số dư quỹ/tài khoản giảm đúng, nhưng muốn biết "tháng này nhiên liệu bao nhiêu" phải mở từng chứng từ đọc Comment.

### 8.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Catalog `ExpenseItems` (Khoản mục chi phí, phân cấp)**
- Tab Hierarchy: Hierarchical, Hierarchy type = *Folder and item hierarchy* (nhóm "Vận hành", "Nhân sự"…, phần tử "Nhiên liệu", "Cầu đường"…), Limit level count tùy nhóm (Bài 4). Synonym của Parent: "Nhóm khoản mục".
- Có thể tạo **predefined items** cho các khoản mục mà thuật toán dựa vào (Bài 4: thuật toán dựa vào predefined, không dựa vào Description người dùng sửa được).
- Mẫu: `Products` (hierarchical) — `cf/Catalogs/Products.xml`.

**b) Attribute `ExpenseItem` trên CashVoucher và BankPayment**
- Header, kiểu CatalogRef.ExpenseItems. Đặt trên form cạnh `Operation`.
- **Chỉ hiện khi Operation = Other** cần code: thêm 2 dòng vào `FormManagement` của từng form (đúng chỗ Jet đang ẩn `Counterparty`), ví dụ `Items.ExpenseItem.Visible = (Object.Operation = PredefinedValue("Enum.CashVoucherOperations.Other"));`. Về phân loại mức, đây là "tự động hóa trên biểu mẫu" (M3 nhẹ). Phương án M2 thuần: luôn hiện field, ghi Tooltip "Chỉ điền khi chi khác".
- **Bắt buộc khi Other** cũng cần code (thêm điều kiện vào `FillCheckProcessing`, ngược lại với cách Jet bỏ kiểm tra `Counterparty`). M2 thuần: không bắt buộc, kiểm soát bằng báo cáo "chi Other chưa có khoản mục".
- Hai form khác nhau ở tên enum (`CashVoucherOperations` / `BankPaymentOperations`) — đừng chép nhầm.

**c) Information register `ExpenseBudgets` (Ngân sách)**
- Dimension `ExpenseItem` (CatalogRef.ExpenseItems, Master); resource `Amount` (Number 15,2). **Periodicity = Month**, Write mode = Independent (Bài 12). Tùy chọn thêm dimension `Vehicle`/`Department` nếu doanh nghiệp lập ngân sách chi tiết hơn.
- Có Period → mỗi tháng một bản ghi; sửa ngân sách giữa năm thì thêm bản ghi tháng mới, bản cũ còn nguyên (câu hỏi 3).

**d) Báo cáo DCS chi phí thực tế theo khoản mục, đọc từ chứng từ**
- Data set Query gồm hai phần UNION ALL (Bài 10): `Document.CashVoucher.PaymentDetails` và `Document.BankPayment.PaymentDetails`, lấy `Ref.ExpenseItem`, `Amount` (quy đổi), ngày.
- Điều kiện: `Ref.Posted`, `Ref.Operation = Other` (hoặc không lọc — câu hỏi 2); với BankPayment thêm `Ref.Paid` và dùng `Ref.PaymentDate` thay `Ref.Date` để khớp CashStatement.
- Grouping ExpenseItem kiểu *hierarchy* để có tổng theo nhóm khoản mục (Bài 18).
- Có thể thêm data set thứ hai đọc `ExpenseBudgets` → so sánh kế hoạch ngay ở mức M2 (Union data set, Bài 18) — xem 8.5.

**e) Đăng ký:** catalog → `CashManagement/Catalogs`; register, report → `CashManagement`; role `UseCashManagement` (catalog 9 quyền, register `Read`/`Update`/`View`/`Edit`, report `Use`/`View`).

### 8.4. Hướng M3

Hạng mục M3: **sổ Chi phí (Turnovers) + báo cáo kế hoạch – thực tế**. Tách hai phần: (1) sổ + ghi sổ từ CashVoucher (recipe nhóm 2); (2) ghi sổ từ BankPayment và báo cáo kế hoạch–thực tế (thang gợi ý nhóm 1 — nhóm 1 làm cả hai phần).

Mẫu Jet để bắt chước: `ReflectSales` / `ReflectInventoryInWarehouses` trong `cf/CommonModules/PostingManagement/Ext/Module.bsl` (trích ở `jet-overview.md` 10.1).

#### Recipe M3 cho nhóm 2 — sổ Expenses ghi từ CashVoucher

Ý nghĩa nghiệp vụ: chứng từ chi là "biên lai"; sổ Chi phí là "cuốn sổ tổng hợp" mà mỗi lần ghi sổ phiếu chi, Jet tự chép số tiền vào đúng trang khoản mục. Sổ kiểu Turnovers vì câu hỏi là "trong kỳ đã chi bao nhiêu", không phải "còn bao nhiêu" (Bài 11).

Bước 1 (Designer): AccumulationRegister `Expenses`, **Register kind = Turnovers**; Dimension `ExpenseItem` (CatalogRef.ExpenseItems); Resource `Amount` (Number 15,2).

Bước 2 (Designer): Document CashVoucher → tab Posting → tick `Expenses` (Register records).

Bước 3 (code) — `cf/Documents/CashVoucher/Ext/ManagerModule.bsl`, procedure `InitializeDocumentData`:

code minh họa — chạy thử để kiểm chứng
```bsl
	// (1) DocumentHeader: thêm một dòng sau CashVoucher.CashAccount AS CashAccount
	|	CashVoucher.CashAccount AS CashAccount,
	|	CashVoucher.ExpenseItem AS ExpenseItem
	|INTO DocumentHeader

	// (2) DocumentPaymentDetails: thêm một dòng
	|	DocumentHeader.CashAccount AS CashAccount,
	|	DocumentHeader.ExpenseItem AS ExpenseItem,

	// (3) Thêm query MỚI vào CUỐI batch, ngay trước dấu "; đóng chuỗi
	|	DocumentPaymentDetails.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentPaymentDetails.Period AS Period,
	|	DocumentPaymentDetails.ExpenseItem AS ExpenseItem,
	|	SUM(DocumentPaymentDetails.Amount) AS Amount
	|FROM
	|	DocumentPaymentDetails AS DocumentPaymentDetails
	|WHERE
	|	DocumentPaymentDetails.Operation = VALUE(Enum.CashVoucherOperations.Other)
	|
	|GROUP BY
	|	DocumentPaymentDetails.Period,
	|	DocumentPaymentDetails.ExpenseItem";

	// (4) Sau hai dòng Insert có sẵn ([2] TableCashBalance, [3] TableSupplierBalance)
	AdditionalProperties.TableForRegisterRecords.Insert("TableExpenses", QueryResult[4].Unload());
```

Bước 4 (code) — `cf/CommonModules/PostingManagement/Ext/Module.bsl`, thêm thủ tục mới cạnh các `Reflect…` khác:

code minh họa — chạy thử để kiểm chứng
```bsl
// Movements on the Expenses register.
//
// Parameters:
//  AdditionalProperties -  Structure - additional properties.
//  RegisterRecords - RegisterRecordsCollection - collection of document register record recordsets.
//  Cancel - Boolean - if set True, the document will not be posted.
//
Procedure ReflectExpenses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableExpenses = AdditionalProperties.TableForRegisterRecords.TableExpenses;
	
	If Cancel Or TableExpenses.Count() = 0 Then
		Return;
	EndIf;
	
	ExpensesRecord = RegisterRecords.Expenses;
	ExpensesRecord.Write = True;
	ExpensesRecord.Load(TableExpenses);
	
EndProcedure
```

Bước 5 (code) — `cf/Documents/CashVoucher/Ext/ObjectModule.bsl`, trong `Posting`, thêm trước `PostingManagement.WriteRecordSets(ThisObject);`:

code minh họa — chạy thử để kiểm chứng
```bsl
	// Movements on the Expenses register
	PostingManagement.ReflectExpenses(AdditionalProperties, RegisterRecords, Cancel);
```

Giải thích theo nghiệp vụ:
- (1)(2) Đưa khoản mục từ đầu phiếu xuống từng dòng chi tiết, để query cuối biết dòng tiền nào thuộc khoản mục nào.
- (3) Query mới cộng tiền (`Amount` — đã quy đổi ra đồng tiền hạch toán) theo ngày và khoản mục. Sổ Turnovers không cần cột `RecordType` (khác query của CashBalance). Điều kiện `Operation = Other` là lựa chọn — câu hỏi 2 hỏi đúng chỗ này.
- Đặt query ở **cuối** batch nên các chỉ số cũ `[2]`, `[3]` không đổi; query mới là `[4]`. Chen vào giữa thì phải sửa lại hết chỉ số (lỗi hay gặp — `jet-overview.md` 10.1).
- (4) `ReflectExpenses` chép nguyên khuôn `ReflectSales`: nhận bảng tên `TableExpenses` rồi nạp vào sổ. Tên bảng ở bước 3 và bước 4 phải trùng nhau.
- (5) Gọi trước `WriteRecordSets` vì thủ tục này mới là bước ghi thật.
- `UndoPosting` không cần sửa: `PrepareRecordSetsForWriting` tự tìm sổ đang có bản ghi cũ của chứng từ và xóa (`jet-overview.md` 10.1).

Bước 6: role `UseCashManagement` → `Read`, `View` trên `AccumulationRegister.Expenses`; register vào subsystem `CashManagement`. Ghi sổ lại các CashVoucher đã có.

Kiểm chứng: ghi sổ phiếu #3 → mở tab "Register records" của chứng từ (hoặc report đọc `Expenses.Turnovers`) thấy dòng Nhiên liệu; đổi Operation sang Supplier, ghi sổ lại → dòng Expenses biến mất.

#### Thang gợi ý M3 cho nhóm 1

**(a) Ghi sổ Expenses từ BankPayment**
- **Bậc 1:** cùng khuôn với CashVoucher, nhưng BankPayment có "lệnh chi" và "đã chi": điều kiện ghi sổ và ngày ghi sổ khác phiếu chi tiền mặt.
- **Bậc 2:** `cf/Documents/BankPayment/Ext/ManagerModule.bsl` — `DocumentHeader` đã có `AND BankPayment.Paid` và lấy `PaymentDate AS Period`; thêm query cuối batch, `Insert("TableExpenses", QueryResult[___])`; object module `Posting` gọi `ReflectExpenses`; tab Posting tick `Expenses`. Enum ở điều kiện là `BankPaymentOperations`.
- **Bậc 3:**

```bsl
	// DocumentHeader: BankPayment.___ AS ExpenseItem
	// Query cuối: SELECT Period, ___ AS ExpenseItem, SUM(___) AS Amount
	//             WHERE Operation = VALUE(Enum.___.Other) GROUP BY ___
	// Insert("TableExpenses", QueryResult[___].Unload());
```

**(b) Báo cáo kế hoạch – thực tế**
- **Bậc 1:** hai nguồn khác loại — ngân sách là information register periodic Month, thực tế là sổ Turnovers; cần đặt cạnh nhau theo khoản mục + tháng mà không mất khoản mục chỉ có một phía.
- **Bậc 2:** DCS (Bài 18): data set `ExpenseBudgets` (bảng register, Period trong khoảng) và data set `Expenses.Turnovers(&BeginOfPeriod, &EndOfPeriod, Month)` lấy `MonthPeriod`. Bài 18 ghi **mọi data set link là left join** — cân nhắc **Union data set** thay vì link (field cùng Path gộp từ hai data set). Resources: `PlanAmount`, `ActualAmount`, calculated field chênh lệch / % thực hiện.
- **Bậc 3:**

```bsl
	// Data set 1: SELECT Period AS Month, ExpenseItem, Amount AS PlanAmount, 0 AS ActualAmount FROM InformationRegister.___ WHERE Period BETWEEN ___ AND ___
	// Data set 2: SELECT MonthPeriod AS Month, ExpenseItem, 0, AmountTurnover AS ActualAmount FROM AccumulationRegister.___.Turnovers(___, ___, Month, )
	// Resource: Variance = ___ - ___
```

- **Cảnh báo va chạm:** CashVoucher/BankPayment cũng ghi `SupplierBalance` — sổ của phía Purchases (Đề 3, Đề 4 dùng báo cáo SupplierBalance). Sửa query mà làm lệch chỉ số `[3]` sẽ làm hỏng công nợ nhà cung cấp. `PostingManagement` là common module dùng chung cho mọi Document: chỉ **thêm** thủ tục mới, đừng sửa `Reflect…` có sẵn. Đề 7 (cùng phân hệ) có thể chạm role `UseCashManagement` — gộp thay đổi role cẩn thận.

### 8.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Báo cáo kế hoạch – thực tế ở mức M2: Union data set gồm `ExpenseBudgets` và query đọc chứng từ chi (không cần sổ mới) | M2 | nhóm 2 |
| Thêm dimension `Vehicle` (Catalog Xe) vào ngân sách và chứng từ chi → chi phí theo xe | M2 | nhóm 2 / nhóm 1 |
| Báo cáo kiểm soát "chi Other chưa có khoản mục" | M2 | nhóm 2 |
| Cảnh báo khi phiếu chi làm vượt ngân sách tháng (đọc Budget SliceLast + Expenses.Turnovers trong Posting) | M3 | nhóm 1 |
| Ghi Expenses cả từ SupplierInvoice (chi phí qua nhà cung cấp, dòng dịch vụ) — sửa chứng từ của nhóm Purchases | M3 | nhóm 1 (phối hợp nhóm Purchases) |

### 8.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Operation là liệt kê, Khoản mục chi phí là danh mục — tiêu chí nào để chọn?**
- Ai thêm giá trị mới: lập trình viên (Enumeration, sửa configuration) hay người dùng (Catalog)? Tần suất thay đổi?
- Code có rẽ nhánh theo giá trị không? Jet rẽ nhánh theo `Operation` trong form, `FillCheckProcessing`, posting — điều gì xảy ra nếu người dùng tự thêm được một Operation mới?
- Cần thông tin kèm theo (nhóm cha, mã kế toán, người duyệt)? Enumeration không có attribute.
- Predefined item (Bài 4) là "điểm giữa" — khi nào dùng?

**2. Khoản chi trả nhà cung cấp (Operation = Supplier) có cần gắn khoản mục không?**
- Kịch bản #12–14: cùng là "sửa chữa" nhưng đi đường SupplierInvoice → BankPayment Supplier, hoặc CashVoucher Other. Báo cáo của nhóm có bị **thiếu** hay **trùng** không?
- Chi phí ghi nhận lúc phát sinh (hóa đơn nhà cung cấp) hay lúc trả tiền? Hai cách cho số tháng khác nhau.
- Một lần trả nhà cung cấp có thể gồm nhiều hóa đơn của nhiều khoản mục — header một khoản mục còn đủ không?

**3. Ngân sách đổi giữa năm — sổ thông tin định kỳ giữ lịch sử thế nào?**
- Periodicity Month: sửa ngân sách tháng 7 là ghi đè bản ghi tháng 7 hay thêm bản ghi mới? Còn biết ngân sách **ban đầu** không?
- Có cần phân biệt "kế hoạch gốc" và "kế hoạch điều chỉnh" (thêm dimension phiên bản, hay dùng chứng từ duyệt ngân sách ghi register subordinate to recorder — Bài 12)?
- Báo cáo so sánh nên dùng ngân sách nào: bản tại thời điểm chi, hay bản mới nhất?

---

## Đề 9 — Kiểm kê kho và xử lý chênh lệch

### 9.1. Kiểm chứng "Jet gốc đang có"

| Khẳng định trong đề | Kết quả | Căn cứ |
|---|---|---|
| InventoryIncrease: Warehouse; phần bảng Product, Quantity, Price, Amount; ban đầu để nhập tồn đầu kỳ | **Đúng.** Header `Warehouse`, `Comment`, `Author`. Wiki hướng dẫn dùng chứng từ này nhập tồn đầu, `Price` là **giá vốn** | `cf/Documents/InventoryIncrease.xml`; Wiki *Initial Setup Guide*, mục 11 |
| InventoryWriteOff: Warehouse; Product, Quantity — không đơn giá, không lý do | **Đúng.** Chỉ có `Comment` (chuỗi tự do) ở header | `cf/Documents/InventoryWriteOff.xml` |
| Cả hai ghi InventoryInWarehouses và InventoryCost; giá trị giảm theo bình quân | **Đúng.** Increase ghi Receipt với `Amount` người dùng nhập; WriteOff ghi Expense, `Amount` = giá trị tồn × SL xuất / SL tồn (bình quân tại thời điểm chứng từ) | `cf/Documents/InventoryIncrease/Ext/ManagerModule.bsl`, `InventoryWriteOff/Ext/ManagerModule.bsl` |
| StockStatement, AvailableStock cho số lượng sổ sách | **Đúng một phần:** AvailableStock chỉ có số lượng (`InventoryInWarehouses.Balance`); StockStatement có **cả số lượng và giá trị** (`InventoryCost.BalanceAndTurnovers`) | Template DCS hai report |
| Không có chứng từ kiểm kê | **Đúng.** Danh sách Document của Jet không có | `cf/Documents/` |

Cách WriteOff tính giá trị hàng giảm (đây là "giá trị hàng thiếu" khi xử lý kiểm kê — câu hỏi 2):

Nguồn: Jet — cf/Documents/InventoryWriteOff/Ext/ManagerModule.bsl
```bsl
	|	CASE
	|		WHEN ISNULL(InventoryCostTable.Quantity, 0) = 0
	|			THEN 0
	|		WHEN ProductTable.Quantity = InventoryCostTable.Quantity
	|			THEN InventoryCostTable.Amount
	|		ELSE CAST(InventoryCostTable.Amount * ProductTable.Quantity / InventoryCostTable.Quantity AS NUMBER(15, 2))
	|	END AS Amount
```

Quan sát thêm:
- InventoryWriteOff nằm trong Sequence `InventoryCostRecalculation`, InventoryIncrease thì không (`cf/Sequences/InventoryCostRecalculation.xml`).
- `Posting` của InventoryIncrease cũng gọi `NegativeBalanceControl` (`cf/Documents/InventoryIncrease/Ext/ObjectModule.bsl`) — bỏ ghi sổ một phiếu tăng có thể bị chặn nếu hàng đã xuất.
- Kiểm tra tồn âm dùng số dư hiện tại `Balance(, )`, không theo thời điểm chứng từ (`jet-warehouse.md` mục 7) — liên quan câu hỏi 3 khi ghi sổ điều chỉnh lùi ngày.

### 9.2. Hồ sơ doanh nghiệp & dữ liệu mẫu gợi ý

**Hồ sơ gợi ý:** nhà phân phối phụ tùng xe máy giả định, 1 kho chính (nhập ~30 mã đại diện cho 300 mã: bugi, má phanh, ốc, gioăng…), thêm 1 kho phụ "Hàng lỗi chờ xử lý" để luyện InventoryTransfer. Kiểm kê cuối quý.

**Dữ liệu nền:** Warehouses (2), Products (30, giá trị thấp, số lượng lớn), tồn đầu bằng InventoryIncrease (Wiki). Một vài SupplierInvoice/SalesInvoice để tồn biến động (chứng từ của phân hệ khác, không tính vào 15).

**Bộ chứng từ (≥15, phân hệ Warehouses):**

| # | Chứng từ | Nội dung | Mục đích |
|---|---|---|---|
| 1 | InventoryIncrease | Tồn đầu kho chính (Price = giá vốn) | Chuẩn bị |
| 2–6 | InventoryTransfer ×5 | Chuyển hàng lỗi sang kho phụ trong tháng | Biến động tồn |
| 7–9 | InventoryWriteOff ×3 | Hủy hàng lỗi ở kho phụ | Comment là nơi duy nhất ghi lý do |
| 10 | InventoryWriteOff | Mất 20 bugi (phát hiện ngẫu nhiên) | Mất mát và hư hỏng đi cùng một loại chứng từ |
| 11 | InventoryIncrease | Tìm thấy hàng thừa do nhập sai lần trước | Price nhập tay — lấy giá nào? |
| 12–13 | InventoryTransfer ×2 | Chuyển nhầm rồi chuyển lại | Nguồn chênh lệch "nhập xuất sai" |
| 14–15 | InventoryWriteOff ×2 | Điều chỉnh thiếu sau kiểm kê cuối quý (10 mã) | Không nối được về cuộc kiểm kê |
| 16 | InventoryIncrease | Điều chỉnh thừa sau kiểm kê (3 mã) | |
| 17 | InventoryWriteOff | Hao hụt tự nhiên (dầu nhớt rò rỉ) | Lý do khác, cùng chứng từ |

**5 chứng từ cho phiếu quan sát:** #1, #10, #11, #14, #16. **Báo cáo theo dõi:** `StockStatement` (số lượng + giá trị, theo Warehouse → Product) và `AvailableStock`. Điều cần ghi nhận: tồn sổ sách đã được "chỉnh cho khớp", nhưng không còn dấu vết số trước kiểm kê, số đếm thực tế, và lý do.

### 9.3. Hướng dẫn hiện thực M2 (cả hai nhóm)

**a) Document `InventoryCount` (Phiếu kiểm kê, không ghi sổ)**
- Tab Posting: **Posting = Deny** (Jet có một Document như vậy: `PricesSetupAuxiliary`, `Posting` = Deny, không có RegisterRecords — `cf/Documents/PricesSetupAuxiliary.xml`).
- Header: `Warehouse` (CatalogRef.Warehouses, Fill checking = Show error), `Counter` (người kiểm — CatalogRef.Users nếu người kiểm có tài khoản, hoặc String 100, hoặc catalog nhân viên riêng; chọn và giải thích), `Comment` (String).
- Tabular section `Inventory`: `Product` (CatalogRef.Products), `BookQuantity` (Number 15,3 — SL sổ sách), `ActualQuantity` (Number 15,3 — SL thực tế), `Difference` (Number 15,3 — Chênh lệch, có thể âm), `Reason` (EnumRef.DiscrepancyReasons).
- `Difference` tự tính khi gõ `ActualQuantity` cần code OnChange (Bài 1–4 thẻ gợi ý về OnChange; mẫu Jet: `InventoryQuantityOnChange` → `CalculateAmount` trong form InventoryIncrease). M2 thuần: người kiểm tự ghi, hoặc để báo cáo tính `ActualQuantity - BookQuantity`.
- Mẫu cấu trúc để bắt chước: `InventoryWriteOff` (header `Warehouse`, tabular section `Inventory`). Copy forms để giữ code SSL (`jet-extending.md` mục 5, bước A6).

**b) Enumeration `DiscrepancyReasons` (Lý do chênh lệch)**
- Values: `NaturalLoss` (Hao hụt tự nhiên), `Loss` (Mất mát), `Damage` (Hư hỏng), `RecordingError` (Nhập xuất sai). Mẫu: `ProductTypes` (`cf/Enums/ProductTypes.xml`). Dùng ở cột `Reason` của phiếu kiểm kê.

**c) Attribute trên InventoryIncrease, InventoryWriteOff**
- `InventoryCount` (DocumentRef.InventoryCount — "Theo phiếu kiểm kê") và `Reason` (EnumRef.DiscrepancyReasons).
- Quyết định: `Reason` ở **header** (mỗi phiếu điều chỉnh một lý do — phải tách nhiều phiếu) hay ở **cột phần bảng** (một phiếu nhiều lý do)? Ghi lý do chọn vào bảng thiết kế.
- `InventoryCount` không bắt buộc (hủy hàng lỗi thường ngày không qua kiểm kê).

**d) Báo cáo DCS tổng hợp chênh lệch theo lý do và mặt hàng qua các kỳ**
- Nguồn: `Document.InventoryCount.Inventory` — `Ref.Date`, `Ref.Warehouse`, `Product`, `Reason`, `Difference` (hoặc `ActualQuantity - BookQuantity`); lọc `NOT Ref.DeletionMark` (phiếu không ghi sổ nên không có `Posted` để lọc).
- Groupings: Reason → Product; cột theo `Ref.Date` nhóm quý. Muốn có giá trị tiền: nối thêm `InventoryCost.Balance` (bình quân) — vượt M2 thuần, xem 9.5.
- Mẫu report: `StockStatement` (`jet-extending.md` 7).

**e) Đăng ký:** Document → subsystem con `Warehouses/Warehouse`; enum, report → `Warehouses`; role `UseWarehouses` — 15 quyền document **trừ** `Posting`, `UndoPosting`, `InteractivePosting…` (phiếu không ghi sổ), `Use`/`View` report; FullAccess tắt `InteractiveDelete` (`jet-extending.md` 3.3).

### 9.4. Hướng M3

Hai việc trong một hạng mục M3: (1) **tự điền SL sổ sách** từ InventoryInWarehouses — đơn giản nhất, recipe cho nhóm 2; (2) **tự tạo InventoryIncrease/InventoryWriteOff từ phiếu** — thang gợi ý cho nhóm 1.

#### Recipe M3 cho nhóm 2 — nút "Điền SL sổ sách"

Ý nghĩa nghiệp vụ: thay vì thủ kho chép tay số tồn từ báo cáo, phiếu kiểm kê tự hỏi sổ kho "kho này, đến ngày của phiếu, mỗi mặt hàng còn bao nhiêu" rồi điền vào cột SL sổ sách. Người kiểm chỉ còn việc đếm và ghi SL thực tế.

Bước 1 (Designer): DocumentForm của InventoryCount → Form commands → thêm command `FillBookQuantity` (Title "Điền SL sổ sách"), Action tạo handler; kéo command lên command bar của bảng `Inventory` (Bài 9, Form commands).

Bước 2 (code) — form module của InventoryCount. Mẫu Jet cho việc "server thêm dòng vào bảng của form": `ImportInventoryFromFileAtServer` (`NewRow = Object.Inventory.Add()` …) trong `cf/Documents/InventoryIncrease/Forms/DocumentForm/Ext/Form/Module.bsl`.

code minh họa — chạy thử để kiểm chứng
```bsl
#Region FormCommandsEventHandlers

&AtClient
Procedure FillBookQuantity(Command)
	
	If Not ValueIsFilled(Object.Warehouse) Then
		CommonClient.MessageToUser(NStr("en = 'Select a warehouse first.'"), , "Warehouse");
		Return;
	EndIf;
	
	FillBookQuantityAtServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventory

&AtClient
Procedure InventoryActualQuantityOnChange(Item)
	
	TabSectionRow = Items.Inventory.CurrentData;
	TabSectionRow.Difference = TabSectionRow.ActualQuantity - TabSectionRow.BookQuantity;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillBookQuantityAtServer()
	
	CountDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryInWarehousesBalance.Product AS Product,
	|	InventoryInWarehousesBalance.QuantityBalance AS BookQuantity
	|FROM
	|	AccumulationRegister.InventoryInWarehouses.Balance(
	|			&Period,
	|			Warehouse = &Warehouse) AS InventoryInWarehousesBalance
	|
	|ORDER BY
	|	InventoryInWarehousesBalance.Product.Description";
	
	Query.SetParameter("Period", New Boundary(CountDate, BoundaryType.Including));
	Query.SetParameter("Warehouse", Object.Warehouse);
	
	Selection = Query.Execute().Select();
	
	Object.Inventory.Clear();
	
	While Selection.Next() Do
		NewRow = Object.Inventory.Add();
		NewRow.Product = Selection.Product;
		NewRow.BookQuantity = Selection.BookQuantity;
		NewRow.Difference = NewRow.ActualQuantity - NewRow.BookQuantity;
	EndDo;
	
	Modified = True;
	
EndProcedure

#EndRegion
```

Giải thích theo nghiệp vụ:
- `FillBookQuantity` chạy ở máy người dùng (`&AtClient`) — chỉ kiểm tra đã chọn kho chưa, rồi nhờ server làm phần đọc sổ. Dữ liệu sổ chỉ đọc được trên server (Bài 7). `CommonClient.MessageToUser` là cách Jet báo lỗi trên client (ví dụ form Meeting); có thể dùng `Message(...)` như giáo trình.
- `InventoryActualQuantityOnChange` — mỗi lần gõ SL thực tế, tính lại chênh lệch ngay trên client (không cần server). Tên handler phải trùng tên gắn ở event OnChange của cột `ActualQuantity`.
- `FillBookQuantityAtServer` (`&AtServer`): hỏi virtual table `InventoryInWarehouses.Balance` (Bài 11) chỉ cho kho của phiếu. `New Boundary(..., BoundaryType.Including)` = tính cả các chứng từ trong đúng giây của ngày phiếu (Bài 11, Boundary). Phiếu mới chưa có ngày thì dùng ngày hiện tại của phiên (`CurrentSessionDate()` chỉ có trên server).
- `Object.Inventory.Clear()` — xóa bảng cũ rồi điền lại. **Cẩn thận:** bấm nút lần hai sẽ xóa luôn SL thực tế đã đếm. Đây là chỗ nhóm nên thảo luận (câu hỏi 3) — có thể chỉ cập nhật cột sổ sách cho dòng đã có.
- `ActualQuantity` để trống (0) có chủ ý: điền sẵn bằng SL sổ sách thì người kiểm dễ "xác nhận cho nhanh" mà không đếm.
- `Modified = True` — báo form có thay đổi chưa ghi, giống Jet.

Kiểm chứng: tạo phiếu ngày 30, bấm nút → so cột SL sổ sách với `AvailableStock` cùng ngày; ghi sổ thêm một InventoryWriteOff ngày 29 rồi bấm lại → số giảm tương ứng; đổi ngày phiếu về ngày 15 → số khác.

#### Thang gợi ý M3 cho nhóm 1 — tự tạo InventoryIncrease/InventoryWriteOff từ phiếu

- **Bậc 1 — Hướng đi:** dòng chênh lệch âm thành phiếu giảm, dòng dương thành phiếu tăng; phiếu điều chỉnh phải "nhớ" phiếu kiểm kê gốc. Platform có sẵn cơ chế "tạo chứng từ dựa trên chứng từ khác" (Bài 11: Generated based on + handler `Filling`).
- **Bậc 2 — Dùng gì, đặt ở đâu:**
  - Tab Generation (Generated based on) của InventoryWriteOff và InventoryIncrease → thêm `Document.InventoryCount` (Bài 11).
  - Object module của hai chứng từ, handler `Filling`: giữ dòng `ObjectFillingJet.FillDocument(ThisObject, FillingData);` rồi thêm nhánh `TypeOf(FillingData) = Type("DocumentRef.InventoryCount")`. Mẫu Jet đầy đủ: `Filling` của `cf/Documents/CashVoucher/Ext/ObjectModule.bsl` (query từ chứng từ nguồn → `FillPropertyValues` header → thêm dòng bảng).
  - Phiếu tăng cần `Price`/`Amount`: lấy từ đâu? Gợi ý đọc `InventoryCost.Balance` giống cách WriteOff tính bình quân (`cf/Documents/InventoryWriteOff/Ext/ManagerModule.bsl`) — hoặc nhập tay. Đây là câu hỏi 2.
  - Phương án khác: một command trên form phiếu kiểm kê tạo cả hai chứng từ bằng `Documents.InventoryWriteOff.CreateDocument()` + `Write(DocumentWriteMode.Posting)` (Bài 11, Bài 12) — cân nhắc có nên ghi sổ tự động hay để thủ kho duyệt (câu hỏi 1).
- **Bậc 3 — Khung:**

```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef.___") Then
		// Query: Warehouse từ header phiếu; dòng có Difference ___ 0 (âm cho WriteOff)
		// FillPropertyValues(ThisObject, ___);   InventoryCount = ___;  Reason = ___
		// For each dòng: NewRow = Inventory.Add(); NewRow.Product = ___; NewRow.Quantity = ___
	EndIf;
	
EndProcedure
```

- **Cảnh báo va chạm:** phân hệ Warehouses có **ba** đề: Đề 1 thêm cột Lô vào `Inventory` của InventoryIncrease, InventoryWriteOff (và có thể thêm chiều vào InventoryInWarehouses/InventoryCost); Đề 2 thêm attribute cho Warehouses; Đề 9 thêm attribute và sửa `Filling` của cùng hai chứng từ. InventoryWriteOff ghi `InventoryCost` và nằm trong Sequence — điều chỉnh kiểm kê lùi ngày làm thay đổi giá vốn của SalesInvoice sau đó, tức là đổi số `ProfitOnSales` của nhóm Sales. Nếu Đề 1 thêm chiều Lô vào InventoryInWarehouses, query `Balance` trong nút "Điền SL sổ sách" sẽ trả nhiều dòng một mặt hàng — phối hợp.

### 9.5. Ý tưởng mở rộng quanh đề

| Ý tưởng | Mức | Phù hợp |
|---|---|---|
| Thêm cột giá trị chênh lệch vào báo cáo: nối `InventoryCost.Balance` tại ngày phiếu để nhân với giá bình quân | M2 (DCS nhiều data set) / M3 | nhóm 2 / nhóm 1 |
| Enumeration `CountStatus` (Đang đếm / Đã chốt / Đã điều chỉnh) + attribute trên phiếu; chốt thì khóa sửa (khóa cần code) | M2 (+M3 khóa) | nhóm 2 |
| Kiểm kê chọn mẫu (cycle count): information register `CountSchedule` (Product → tần suất A/B/C) | M2 | nhóm 2 / nhóm 1 |
| Ngưỡng hao hụt tự nhiên cho phép theo mặt hàng (information register) + báo cáo vượt ngưỡng | M2 | nhóm 2 |
| Print form "Biên bản kiểm kê" qua SSL Print (Bài 22, `jet-extending.md` 3.6) | M3 | nhóm 1 |

### 9.6. Câu hỏi phân tích bắt buộc — gợi mở

**1. Phiếu kiểm kê có nên tự ghi sổ tồn kho? Vì sao tách "ghi nhận kết quả" và "điều chỉnh sổ"?**
- Ai có quyền gì: người đếm, thủ kho, kế toán, giám đốc duyệt khoản hủy? Một chứng từ gộp cả hai bước thì phân quyền thế nào (Bài 20)?
- Đếm lại: phát hiện sai sau khi đã điều chỉnh sổ thì phải hoàn tác những gì?
- Tách hai bước có cái giá gì (thêm chứng từ, khả năng quên điều chỉnh)? Báo cáo nào giúp phát hiện phiếu kiểm kê chưa được xử lý?

**2. InventoryWriteOff không có đơn giá — giá trị hàng thiếu lấy từ đâu, ảnh hưởng lợi nhuận thế nào?**
- Quan sát đoạn CASE ở 9.1 và thử: hủy cùng một mặt hàng trước và sau một SupplierInvoice giá cao — giá trị khác nhau ra sao?
- Phía thừa (InventoryIncrease): người dùng nhập `Price` — dùng giá mua gần nhất, giá bình quân, hay 0? Mỗi cách làm giá vốn bình quân về sau thay đổi thế nào?
- Báo cáo `ProfitOnSales` chỉ lấy giá vốn của SalesInvoice (`REFS Document.SalesInvoice` trong template) — khoản hao hụt nằm ở đâu trong bức tranh lãi lỗ? Doanh nghiệp có thấy được không?

**3. Kho vẫn nhập xuất trong lúc kiểm — SL sổ sách lấy tại thời điểm nào? Quy trình gì để tránh sai lệch?**
- Thử với recipe: ngày giờ của phiếu quyết định số sổ sách (Boundary). Phiếu tạo lúc 8h, đếm xong 17h, có hàng xuất lúc 10h?
- Phương án nghiệp vụ: đóng kho, khoanh vùng đếm, ghi chú hàng đang di chuyển, "cắt" theo mốc giờ; phương án hệ thống: điền lại SL sổ sách khi chốt, khóa ghi sổ chứng từ kho trong ngày kiểm.
- Kiểm tra tồn âm của Jet đọc số dư hiện tại, không theo thời điểm chứng từ — điều chỉnh ghi lùi ngày có bị chặn sai hoặc lọt không?

---

## 5. Bảng va chạm giữa các nhóm

| Đề | Object/module Jet bị sửa | Nhóm khác cùng chạm | Cần thống nhất |
|---|---|---|---|
| 6 | `Sales` (thêm dimension), `SalesInvoice` (attribute + `InitializeDocumentData`), `Counterparties` (attribute) | Đề 5 (sổ Sales, SalesInvoice), Đề 7 (SalesInvoice), Purchases (Counterparties) | Thứ tự merge `InitializeDocumentData`; re-post sau khi đổi sổ |
| 7 | `SalesInvoice` (DueDate, `Posting` chặn hạn mức), role `UseCashManagement` (thêm quyền CustomerBalance) | Đề 5, Đề 6 (SalesInvoice); Đề 8 (role chung) | Hạn mức demo không chặn dữ liệu của nhóm Sales |
| 8 | `CashVoucher`, `BankPayment` (attribute, form, posting), `PostingManagement` (thêm `ReflectExpenses`) | Purchases (SupplierBalance do hai chứng từ này ghi); Đề 7 (role) | Không làm lệch chỉ số `QueryResult[3]` của SupplierBalance |
| 9 | `InventoryIncrease`, `InventoryWriteOff` (attribute, `Filling`), Document mới | Đề 1 (cột Lô, chiều Lô), Đề 2 (Warehouses); Sales (giá vốn qua Sequence) | Ai sửa tabular section `Inventory` trước; ngày ghi sổ điều chỉnh |
