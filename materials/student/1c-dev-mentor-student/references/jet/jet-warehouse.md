# 1C:Jet — Phân hệ Kho (Subsystem Warehouses)

Khi nào đọc file này: khi sinh viên làm việc với phân hệ Kho của 1C:Jet — hỏi về Catalog Warehouses/Products/Units, ba Document InventoryIncrease / InventoryWriteOff / InventoryTransfer, hai Accumulation register InventoryInWarehouses / InventoryCost, kiểm soát tồn âm, report StockStatement / AvailableStock, hoặc khi nhóm "Kho" cần ý tưởng mở rộng.

Phiên bản nguồn: Jet repo `github.com/1Ci-Company/Jet`, nhánh `community`, commit 80884de, configuration version 1.0.2.1, compatibility 8.3.24. Mọi đường dẫn `cf/...` là bản dump configuration ra file.

## Mục lục

1. [Thành phần của subsystem Warehouses](#1-thành-phần-của-subsystem-warehouses)
2. [Catalogs: Warehouses, Products, Units](#2-catalogs-warehouses-products-units)
3. [Ba Document kho: cấu trúc chung](#3-ba-document-kho-cấu-trúc-chung)
4. [Mẫu Posting của Jet (object module + PostingManagement)](#4-mẫu-posting-của-jet)
5. [InitializeDocumentData của từng Document](#5-initializedocumentdata-của-từng-document)
6. [Accumulation registers InventoryInWarehouses và InventoryCost](#6-accumulation-registers)
7. [Kiểm soát tồn âm (NegativeBalanceControl)](#7-kiểm-soát-tồn-âm)
8. [Sequence InventoryCostRecalculation và Data processor tính lại giá vốn](#8-sequence-và-data-processor-tính-lại-giá-vốn)
9. [Forms của Document](#9-forms-của-document)
10. [Common module InventoryTabularSectionClientServer](#10-common-module-inventorytabularsectionclientserver)
11. [Reports: StockStatement, AvailableStock](#11-reports)
12. [Print forms, Role, các điểm tích hợp SSL](#12-print-forms-role-và-tích-hợp-ssl)
13. [Những điểm cần lưu ý khi đọc code](#13-những-điểm-cần-lưu-ý)
14. [Gợi ý mở rộng cho nhóm sinh viên phân hệ Kho](#14-gợi-ý-mở-rộng-cho-nhóm-sinh-viên-phân-hệ-kho)

---

## 1. Thành phần của subsystem Warehouses

Subsystem `Warehouses` (xem Bài 9 về Subsystem) có `<Content>` trực tiếp và hai subsystem con.

Nguồn: Jet — cf/Subsystems/Warehouses.xml, cf/Subsystems/Warehouses/Subsystems/*.xml

| Vị trí | Object |
|---|---|
| Warehouses (trực tiếp) | AccumulationRegister.InventoryInWarehouses, AccumulationRegister.InventoryCost, Report.AvailableStock, Report.StockStatement, DataProcessor.InventoryCostRecalculation, Sequence.InventoryCostRecalculation, Role.UseWarehouses, CommonCommand.AdditionalReportsWarehouses, CommonCommand.AdditionalDataProcessorsWarehouses, CommonCommand.ReportPanelWarehouses |
| Warehouses → Catalogs | Catalog.Units, Catalog.Warehouses, Catalog.Products |
| Warehouses → Warehouse | Document.InventoryIncrease, Document.InventoryTransfer, Document.InventoryWriteOff |

Ghi chú:
- Ba CommonCommand `AdditionalReportsWarehouses`, `AdditionalDataProcessorsWarehouses`, `ReportPanelWarehouses` là các lệnh gắn với SSL (Additional reports and data processors, Report options — xem Bài 21).
- Ngoài ba Document kho, **SalesInvoice** và **SupplierInvoice** (thuộc phân hệ Sales/Purchases) cũng có `RegisterRecords` gồm `InventoryInWarehouses` và `InventoryCost` — tức hai register kho được ghi bởi 5 Document (xem mục 6).
- Wiki Features.md mô tả phần kho: "Added **Warehouses catalog** with negative balance control", "Inventory increase (for initial balances)", "Inventory write-off", "Inventory transfer", "Added **Warehouse** field to sales and purchase documents".

## 2. Catalogs: Warehouses, Products, Units

Nguồn: Jet — cf/Catalogs/Warehouses.xml, cf/Catalogs/Products.xml, cf/Catalogs/Units.xml

| Catalog | Thuộc tính chính |
|---|---|
| **Warehouses** | CodeLength 9 (String, Autonumbering), DescriptionLength 50, không Hierarchical. Không có attribute riêng; có tabular section `AdditionalAttributes` (SSL Properties) và `ContactInformation` (SSL Contacts). Forms: ItemForm, ListForm, ChoiceForm |
| **Products** | CodeLength 9, DescriptionLength 100, **Hierarchical**. Attributes: `DetailedDescription` (String), `ProductType` (EnumRef.ProductTypes, FillChecking ShowError, FillValue `Inventory`), `Unit` (CatalogRef.Units, FillChecking ShowError), `VATRate` (CatalogRef.VATRates) |
| **Units** | CodeLength 3 (String, không Autonumbering), DescriptionLength 25. Không có form và module riêng trong dump |

Enum `ProductTypes` có hai giá trị: `Inventory`, `Service`.

Form item của Products khóa field `Unit` sau khi sản phẩm đã được ghi: `LockUnitChanges(ObjectRef)` đặt `Items.Unit.ReadOnly = Not ObjectRef.IsEmpty();`, được gọi trong `OnCreateAtServer` và `AfterWriteAtServer`.

[suy luận] Lý do: register chỉ lưu Quantity, không lưu đơn vị; đổi `Unit` của sản phẩm đã có phát sinh sẽ làm sai ý nghĩa số tồn. Đây chỉ là khóa trên form (ReadOnly), không phải kiểm tra ở object module.

Form của Warehouses chỉ gọi SSL: `AttachableCommands`, `PropertyManager`, `ContactsManager` (trong `OnCreateAtServer`, `OnReadAtServer`, `FillCheckProcessingAtServer`, `BeforeWriteAtServer`). Không có logic nghiệp vụ riêng của Jet.

## 3. Ba Document kho: cấu trúc chung

Nguồn: Jet — cf/Documents/InventoryIncrease.xml, InventoryWriteOff.xml, InventoryTransfer.xml

| | InventoryIncrease | InventoryWriteOff | InventoryTransfer |
|---|---|---|---|
| Ý nghĩa | Nhập tăng hàng (theo wiki: dùng cho số dư đầu) | Xuất hủy / ghi giảm | Chuyển kho |
| Header attributes | `Warehouse` (ShowError), `Comment`, `Author` | `Warehouse` (ShowError), `Comment`, `Author` | `Warehouse` (ShowError), **`WarehouseReceiver`** (DontCheck), `Comment`, `Author` |
| Tabular section `Inventory` | `Product` (ShowError), `Quantity` (15,3), **`Price`** (15,2), **`Amount`** (15,2) | `Product` (ShowError), `Quantity` | `Product` (ShowError), `Quantity` |
| RegisterRecords | InventoryInWarehouses, InventoryCost | như bên trái | như bên trái |
| Thuộc Sequence InventoryCostRecalculation | không | có | có |
| Template | `LoadingFromFile` (SSL ImportDataFromFile) | — | — |

Các property chung của cả ba (xem Bài 11, Bài 20):
- `Posting` = Allow, `RealTimePosting` = **Deny**, `RegisterRecordsDeletion` = AutoDeleteOff, `RegisterRecordsWritingOnPost` = WriteSelected, `SequenceFilling` = AutoFill.
- **Post in privileged mode** = true, **Unpost in privileged mode** = true.
- Number: String, length 9, `NumberPeriodicity` = Year, Autonumbering.
- `Author` có kiểu CatalogRef.Users; `AdditionalAttributes` là tabular section của SSL Properties.
- Field `Product` trong tabular section có Choice parameter `Filter.ProductType = Enum.ProductTypes.EnumValue.Inventory` — chỉ chọn được hàng hóa, không chọn được dịch vụ (xem Bài 9 về choice parameters).

**Không có** handler `FillCheckProcessing`, `BeforeWrite` hay `OnWrite` trong object module của ba Document này. Kiểm tra điền dữ liệu chỉ dựa vào property FillChecking (ShowError) của `Warehouse` và `Product`. `FillCheckProcessingAtServer` / `BeforeWriteAtServer` trong form chỉ gọi SSL `PropertyManager` (mục 9).

Handler `Filling` — giống nhau ở cả ba:

Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
EndProcedure
```

`ObjectFillingJet.FillDocument` (code của Jet) chuẩn hóa `FillingData` thành Structure, gán `Author` = `Users.AuthorizedUser()` (hàm SSL), nếu Document có attribute `Currency` thì điền currency mặc định (ba Document kho không có `Currency`), rồi `FillPropertyValues(DocumentObject, FillingData)`.

## 4. Mẫu Posting của Jet

Cả ba Document có object module **giống hệt nhau**, chỉ khác dòng gọi `Documents.<Tên>.InitializeDocumentData`. Đây là "khuôn Posting" chuẩn của Jet, cũng được SalesInvoice và SupplierInvoice dùng.

Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Document data initialization.
	Documents.InventoryTransfer.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	
	// Movements on the InventoryInWarehouses register
	PostingManagement.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the InventoryCost register
	PostingManagement.ReflectInventoryCost(AdditionalProperties, RegisterRecords, Cancel);
	
	// Writing of the records sets.
	PostingManagement.WriteRecordSets(ThisObject);
	
	// Negative balance control
	AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl(Ref, AdditionalProperties, Cancel);
	
EndProcedure
```

Luồng 6 bước (so với Bài 11, nơi Posting viết thẳng `RegisterRecords.X.Add()` trong vòng lặp):

1. **InitializeAdditionalPropertiesForPosting** — tạo trong `AdditionalProperties` các khóa `TableForRegisterRecords` (Structure), `ForPosting` (chứa một `TempTablesManager`), `DocumentMetadata`.
2. **InitializeDocumentData** (manager module của Document) — chạy một batch query, đặt kết quả thành các ValueTable `TableInventoryInWarehouses`, `TableInventoryCost` trong `AdditionalProperties.TableForRegisterRecords`.
3. **PrepareRecordSetsForWriting** — xóa nội dung các record set và bật `Write = True` cho những register mà Document đang có movements (để khi post lại hoặc unpost thì movements cũ bị ghi đè bằng tập rỗng).
4. **ReflectInventoryInWarehouses / ReflectInventoryCost** — `Load()` ValueTable vào record set.
5. **WriteRecordSets** — gọi `RecordSet.Write()` ngay trong Posting, đồng thời truyền `ForPosting` vào `AdditionalProperties` của record set (để record set module dùng chung `TempTablesManager`, xem mục 7).
6. **NegativeBalanceControl** — kiểm tra tồn âm sau khi đã ghi (cùng ý tưởng Bài 12: ghi movements bằng `Write()` rồi mới query số dư).

UndoPosting dùng lại bước 1, 3, 5, 6 — bỏ qua bước 2 và 4, nên record set được ghi **rỗng**. Vì vậy hủy post một InventoryIncrease cũng có thể bị chặn nếu hàng đã được xuất đi.

Code của các bước trong common module `PostingManagement` (module của Jet):

Nguồn: Jet — cf/CommonModules/PostingManagement/Ext/Module.bsl
```bsl
Procedure WriteRecordSets(DocumentObject) Export
	
	For Each RecordSet In DocumentObject.RegisterRecords Do
		If RecordSet.Write Then
			RecordSet.AdditionalProperties.Insert("ForPosting", DocumentObject.AdditionalProperties.ForPosting);
			RecordSet.Write();
			RecordSet.Write = False;
		EndIf;
	EndDo;
	
EndProcedure
// ...
Procedure ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryInWarehouses = AdditionalProperties.TableForRegisterRecords.TableInventoryInWarehouses;
	
	If Cancel Or TableInventoryInWarehouses.Count() = 0 Then
		Return;
	EndIf;
	
	InventoryInWarehousesRecord = RegisterRecords.InventoryInWarehouses;
	InventoryInWarehousesRecord.Write = True;
	InventoryInWarehousesRecord.Load(TableInventoryInWarehouses);
	
EndProcedure
```

`ReflectInventoryCost` có cấu trúc y hệt, đọc `TableInventoryCost` và nạp vào `RegisterRecords.InventoryCost`.

`GetUsedRegisterNames` (Private) dựng động một query `SELECT TOP 1 ... WHERE RegisterTable.Recorder = &Recorder` cho từng register trong `DocumentMetadata.RegisterRecords`, nối bằng `JetServer.GetQueryUnion()` (trả về chuỗi `UNION ALL`), để biết register nào Document đã có movements.

Điểm then chốt cho sinh viên: **tên cột trong ValueTable phải trùng tên dimension/resource của register** (`RecordType`, `Period`, `Warehouse`, `Product`, `Quantity`, `Amount`) thì `Load()` mới nạp đúng — vì thế các query trong `InitializeDocumentData` đặt alias rất cẩn thận.

## 5. InitializeDocumentData của từng Document

### 5.1 InventoryIncrease — đơn giản nhất (chỉ Receipt)

Không có data lock, không đọc số dư. Batch 4 query; kết quả số 2 và 3 (đánh số từ 0) là bảng movements.

Nguồn: Jet — cf/Documents/InventoryIncrease/Ext/ManagerModule.bsl
```bsl
Procedure InitializeDocumentData(InventoryIncreaseRef, AdditionalProperties) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryIncrease.Ref AS Ref,
	|	InventoryIncrease.Date AS Date,
	|	InventoryIncrease.Warehouse AS Warehouse
	|INTO DocumentHeader
	|FROM
	|	Document.InventoryIncrease AS InventoryIncrease
	|WHERE
	|	InventoryIncrease.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// ...
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentInventory.Period AS Period,
	|	DocumentInventory.Warehouse AS Warehouse,
	|	DocumentInventory.Product AS Product,
	|	SUM(DocumentInventory.Quantity) AS Quantity
	|FROM
	|	DocumentInventory AS DocumentInventory
	|
	|GROUP BY
	|	DocumentInventory.Product,
	|	DocumentInventory.Period,
	|	DocumentInventory.Warehouse
	// ...
	
	Query.SetParameter("Ref", InventoryIncreaseRef);
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[2].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[3].Unload());
	
EndProcedure
```

Query thứ 2 (đã lược) tạo temp table `DocumentInventory` = `DocumentHeader` INNER JOIN `Document.InventoryIncrease.Inventory` (lấy `Date AS Period`, `Warehouse`, `Product`, `Quantity`, `Amount`). Query thứ 4 (đã lược) có cùng dạng với query thứ 3 nhưng thêm `SUM(DocumentInventory.Amount) AS Amount` — đó là bảng movements cho InventoryCost.

Nhận xét: temporary table `DocumentHeader` → `DocumentInventory` → hai SELECT có `GROUP BY` để gộp các dòng trùng Product (xem Bài 10 về batch query, temporary tables). Giá trị nhập kho (`Amount`) lấy thẳng từ tabular section.

### 5.2 InventoryWriteOff — Expense, tính giá vốn theo bình quân

Có thêm: managed **data lock** trên `InventoryCost`, đọc số dư `InventoryCost.Balance` tại thời điểm Document, rồi phân bổ giá trị xuất theo tỷ lệ Quantity.

Nguồn: Jet — cf/Documents/InventoryWriteOff/Ext/ManagerModule.bsl
```bsl
	DocumentObject = InventoryWriteOffRef.GetObject();
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("AccumulationRegister.InventoryCost");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = DocumentObject.Inventory;
	LockItem.UseFromDataSource("Product", "Product");
	LockItem.SetValue("Warehouse", DocumentObject.Warehouse);
	DataLock.Lock();
```

`DataLock` khóa độc quyền các bản ghi InventoryCost theo cặp (Product lấy từ tabular section `Inventory`, Warehouse của header) để hai giao dịch đồng thời không cùng đọc một số dư (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).

Phần query đọc số dư và tính Amount:

Nguồn: Jet — cf/Documents/InventoryWriteOff/Ext/ManagerModule.bsl
```bsl
	|SELECT
	|	InventoryCostBalance.Product AS Product,
	|	InventoryCostBalance.Warehouse AS Warehouse,
	|	InventoryCostBalance.QuantityBalance AS Quantity,
	|	InventoryCostBalance.AmountBalance AS Amount
	|INTO InventoryCostBalance
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(
	|			&PointInTime,
	|			(Product, Warehouse) IN
	|				(SELECT
	|					ProductTable.Product,
	|					ProductTable.Warehouse
	|				FROM
	|					ProductTable AS ProductTable)) AS InventoryCostBalance
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryCost.Product,
	|	InventoryCost.Warehouse,
	|	InventoryCost.Quantity,
	|	InventoryCost.Amount
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|WHERE
	|	InventoryCost.Recorder = &Ref
	|;
	// ...
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ProductTable.Period AS Period,
	|	ProductTable.Product AS Product,
	|	ProductTable.Warehouse AS Warehouse,
	|	ProductTable.Quantity AS Quantity,
	|	CASE
	|		WHEN ISNULL(InventoryCostTable.Quantity, 0) = 0
	|			THEN 0
	|		WHEN ProductTable.Quantity = InventoryCostTable.Quantity
	|			THEN InventoryCostTable.Amount
	|		ELSE CAST(InventoryCostTable.Amount * ProductTable.Quantity / InventoryCostTable.Quantity AS NUMBER(15, 2))
	|	END AS Amount
	|FROM
	|	ProductTable AS ProductTable
	|		LEFT JOIN InventoryCostTable AS InventoryCostTable
	|		ON ProductTable.Product = InventoryCostTable.Product
	|			AND ProductTable.Warehouse = InventoryCostTable.Warehouse";
	
	Query.SetParameter("Ref", InventoryWriteOffRef);
	Query.SetParameter("PointInTime", New Boundary(DocumentObject.PointInTime(), BoundaryType.Including));
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[5].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[6].Unload());
```

Giải thích:
- `Balance(&PointInTime, ...)` với `New Boundary(DocumentObject.PointInTime(), BoundaryType.Including)` — số dư **bao gồm** cả thời điểm của Document (xem Bài 11 về PointInTime/Boundary).
- [suy luận] Nhánh `UNION ALL ... WHERE InventoryCost.Recorder = &Ref` cộng ngược movements cũ của chính Document: khi post lại, movements cũ (Expense) vẫn còn trong register lúc query chạy (register chỉ bị ghi đè ở bước WriteRecordSets), nên số dư "Including" đã bị trừ bởi chính Document. Cộng lại Quantity/Amount của chúng sẽ cho số dư "trước khi Document này xuất".
- Công thức giá vốn: nếu xuất hết số tồn → lấy nguyên `Amount` tồn (tránh sai số làm tròn); nếu không → `Amount tồn × Quantity xuất / Quantity tồn`, làm tròn `NUMBER(15, 2)`. Đây là giá **bình quân** theo từng cặp Product + Warehouse. Nếu tồn bằng 0 → Amount = 0.
- Kết quả số 5 (movements InventoryInWarehouses, chỉ Quantity) và số 6 (movements InventoryCost, có Amount).

### 5.3 InventoryTransfer — Expense ở kho xuất + Receipt ở kho nhận

Data lock giống WriteOff. Khác biệt: có `WarehouseReceiver`, nhánh UNION ALL lọc `RecordType = Expense`, và tạo cặp movements.

Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ManagerModule.bsl
```bsl
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|WHERE
	|	InventoryCost.Recorder = &Ref
	|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|;
	// ...
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ProductTable.Period AS Period,
	|	ProductTable.Warehouse AS Warehouse,
	|	ProductTable.Product AS Product,
	|	ProductTable.Quantity AS Quantity
	|FROM
	|	ProductTable AS ProductTable
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	ProductTable.Period,
	|	ProductTable.WarehouseReceiver,
	|	ProductTable.Product,
	|	ProductTable.Quantity
	|FROM
	|	ProductTable AS ProductTable
	// ...
	
	Query.SetParameter("Ref", InventoryTransferRef);
	Query.SetParameter("PointInTime", New Boundary(DocumentObject.PointInTime(), BoundaryType.Including));
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[6].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[7].Unload());
```

Query [7] (đã lược) có cùng dạng Expense/Receipt nhưng đọc từ `ProductTransferTable` và có thêm cột `Amount`.

Batch đầy đủ có 8 query: `DocumentHeader` → `DocumentInventory` → `ProductTable` (GROUP BY) → `InventoryCostBalance` → `InventoryCostTable` (GROUP BY) → `ProductTransferTable` (cùng công thức CASE như WriteOff) → movements InventoryInWarehouses [6] → movements InventoryCost [7]. Kho nhận nhận **đúng Amount** đã tính ở kho xuất, nên giá trị hàng được "chuyển" theo hàng.

[suy luận] Lọc `RecordType = Expense` vì Transfer có cả movements Receipt (vào kho nhận); chỉ cần cộng lại phần đã xuất của chính Document.

## 6. Accumulation registers

Nguồn: Jet — cf/AccumulationRegisters/InventoryInWarehouses.xml, cf/AccumulationRegisters/InventoryCost.xml

| Register | RegisterType | Dimensions | Resources | Module |
|---|---|---|---|---|
| **InventoryInWarehouses** | Balance | `Product` (CatalogRef.Products), `Warehouse` (CatalogRef.Warehouses) — cả hai DenyIncompleteValues = true | `Quantity` (15,3) | ManagerModule (NegativeBalanceControl), RecordSetModule (BeforeWrite, OnWrite) |
| **InventoryCost** | Balance | `Product`, `Warehouse` — DenyIncompleteValues = true | `Quantity` (15,3), `Amount` (15,2) | không có module |

Cả hai có `EnableTotalsSplitting` = true. Không có attribute.

Document ghi vào cả hai register (theo `RegisterRecords` trong XML của Document): InventoryIncrease, InventoryWriteOff, InventoryTransfer, SalesInvoice, SupplierInvoice. Tất cả đều đi qua `PostingManagement.ReflectInventoryInWarehouses` / `ReflectInventoryCost` và gọi `NegativeBalanceControl` trong Posting và UndoPosting.

Vai trò:
- **InventoryInWarehouses** — số lượng tồn theo kho; dùng cho kiểm soát tồn âm và report AvailableStock.
- **InventoryCost** — số lượng + giá trị; nguồn tính giá vốn khi xuất và cho report StockStatement. Là register của Sequence InventoryCostRecalculation (mục 8).

Role `UseWarehouses` chỉ có quyền `Read`, `View` trên hai register (không sửa tay movements).

## 7. Kiểm soát tồn âm

Cơ chế gồm ba mảnh, phối hợp qua `TempTablesManager` dùng chung trong `AdditionalProperties.ForPosting`:

| Bước | Ở đâu | Làm gì |
|---|---|---|
| 1 | RecordSetModule `BeforeWrite` | Lock record set theo Recorder; lưu movements **cũ** của Document vào temp table `InventoryInWarehousesBeforeWrite` (Receipt dương, Expense âm) |
| 2 | RecordSetModule `OnWrite` | So movements cũ với movements **mới** vừa ghi → temp table `InventoryInWarehousesChange` chỉ gồm cặp (Warehouse, Product) có thay đổi; đặt cờ `IsInventoryInWarehousesChange` |
| 3 | ManagerModule `NegativeBalanceControl` | Nếu có thay đổi: join `InventoryInWarehousesChange` với số dư hiện tại, tìm `QuantityBalance < 0`, báo lỗi và đặt `Cancel` |

Nguồn: Jet — cf/AccumulationRegisters/InventoryInWarehouses/Ext/RecordSetModule.bsl
```bsl
Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not AdditionalProperties.Property("ForPosting") Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.InventoryInWarehouses.RecordSet");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Recorder", Filter.Recorder.Value);
	Block.Lock();
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.ForPosting.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Text =
	"SELECT
	|	InventoryInWarehouses.Warehouse AS Warehouse,
	|	InventoryInWarehouses.Product AS Product,
	|	CASE
	|		WHEN InventoryInWarehouses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN InventoryInWarehouses.Quantity
	|		ELSE -InventoryInWarehouses.Quantity
	|	END AS Quantity
	|INTO InventoryInWarehousesBeforeWrite
	|FROM
	|	AccumulationRegister.InventoryInWarehouses AS InventoryInWarehouses
	|WHERE
	|	InventoryInWarehouses.Recorder = &Recorder";
	
	Query.Execute();
	
EndProcedure
```

Điều kiện `Not AdditionalProperties.Property("ForPosting")` — chỉ chạy khi record set được ghi qua `PostingManagement.WriteRecordSets` (nơi gán `ForPosting`). `DataExchange.Load` = true khi ghi trong trao đổi dữ liệu → bỏ qua (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).

Nguồn: Jet — cf/AccumulationRegisters/InventoryInWarehouses/Ext/RecordSetModule.bsl
```bsl
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[2].Select();
	Selection.Next();
	
	AdditionalProperties.ForPosting.Insert("IsInventoryInWarehousesChange", Selection.ChangeCount > 0);
```

Trong `OnWrite` (batch query, đã lược), `PrevInventoryInWarehousesChange` = movements cũ (dấu như BeforeWrite) UNION ALL movements mới **đảo dấu** (Receipt → âm, Expense → dương). Temp table `InventoryInWarehousesChange` = `GROUP BY Warehouse, Product HAVING SUM(QuantityChange) <> 0` (có `INDEX BY Warehouse, Product`), query thứ 3 đếm `COUNT(*) AS ChangeCount`. Tổng theo (Warehouse, Product) ≠ 0 nghĩa là cặp đó bị Document làm thay đổi. [suy luận] Dấu dương của `QuantityChange` nghĩa là tồn kho bị **giảm** so với trước — nhưng code không lọc theo dấu, chỉ lấy `<> 0`. Cuối batch, hai temp table trung gian bị `DROP`; `InventoryInWarehousesChange` được giữ lại trong `TempTablesManager` cho bước 3.

Nguồn: Jet — cf/AccumulationRegisters/InventoryInWarehouses/Ext/ManagerModule.bsl
```bsl
Procedure NegativeBalanceControl(Ref, AdditionalProperties, Cancel) Export
	
	If AdditionalProperties.ForPosting.Property("IsInventoryInWarehousesChange")
		And AdditionalProperties.ForPosting.IsInventoryInWarehousesChange Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.ForPosting.TempTablesManager;
		Query.Text =
		"SELECT
		|	InventoryInWarehousesChange.Warehouse AS Warehouse,
		|	InventoryInWarehousesChange.Product AS Product,
		|	Products.Unit AS Unit,
		|	-InventoryInWarehousesBalance.QuantityBalance AS Shortage
		|FROM
		|	InventoryInWarehousesChange AS InventoryInWarehousesChange
		|		INNER JOIN Catalog.Products AS Products
		|		ON InventoryInWarehousesChange.Product = Products.Ref
		|		INNER JOIN AccumulationRegister.InventoryInWarehouses.Balance(, ) AS InventoryInWarehousesBalance
		|		ON InventoryInWarehousesChange.Warehouse = InventoryInWarehousesBalance.Warehouse
		|			AND InventoryInWarehousesChange.Product = InventoryInWarehousesBalance.Product
		|			AND (InventoryInWarehousesBalance.QuantityBalance < 0)
		|TOTALS BY
		|	Warehouse";
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			
			WarehouseSelection = Result.Select(QueryResultIteration.ByGroups);
			While WarehouseSelection.Next() Do
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Insufficient quantity on %1'"),
					WarehouseSelection.Warehouse);
				Common.MessageToUser(MessageText, Ref, , , Cancel);
				
				Selection = WarehouseSelection.Select();
				While Selection.Next() Do
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Product: %1, shortage %2 %3'"),
						Selection.Product,
						Selection.Shortage,
						Selection.Unit);
					Common.MessageToUser(MessageText, Ref, , , Cancel);
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure
```

Giải thích:
- `Balance(, )` không truyền Period → số dư **hiện tại** (sau tất cả movements), không phải tại thời điểm Document. Kết hợp `RealTimePosting = Deny`, [suy luận] một Document lùi ngày vẫn bị kiểm theo tồn cuối cùng.
- `TOTALS BY Warehouse` + `QueryResultIteration.ByGroups` → mỗi kho một dòng tiêu đề "Insufficient quantity on ...", sau đó từng sản phẩm thiếu (xem Bài 10 về TOTALS).
- `Common.MessageToUser(..., Cancel)` và `StringFunctionsClientServer.SubstituteParametersToString` là hàm SSL; tham số `Cancel` truyền vào làm post bị hủy.
- Kiểm soát này áp dụng **chỉ cho InventoryInWarehouses** (số lượng). InventoryCost không có kiểm soát tồn âm riêng.

So với Bài 12 (query `GoodsInWarehouses.Balance` sau khi `Write()`): Jet làm cùng ý tưởng nhưng chỉ kiểm những cặp (Warehouse, Product) **thực sự thay đổi**, và đặt logic trong register (record set module + manager module) để mọi Document ghi vào register đều dùng chung.

## 8. Sequence và Data processor tính lại giá vốn

Nguồn: Jet — cf/Sequences/InventoryCostRecalculation.xml

- `Documents`: InventoryTransfer, InventoryWriteOff, SalesInvoice (các Document **xuất** hàng — tính giá vốn từ số dư).
- `RegisterRecords`: AccumulationRegister.InventoryCost.
- `MoveBoundaryOnPosting` = Move; `DataLockControlMode` = Managed.

[suy luận] Ý nghĩa: giá vốn xuất được tính từ số dư InventoryCost tại thời điểm Document; nếu sau đó có Document sửa/lùi ngày làm thay đổi số dư quá khứ, các Document xuất phía sau cần post lại theo đúng thứ tự thời gian. Sequence là cơ chế platform để theo dõi "ranh giới" đã đúng thứ tự (Sequence không có trong giáo trình 24 bài — hãy kiểm tra lại trong Syntax assistant).

Data processor `InventoryCostRecalculation` (manager module) có hai function Export: `GetSeqBoundCurrent()` — đọc `Sequences.InventoryCostRecalculation.GetBound()`; `SequenceEnd()` — query `SELECT TOP 1` movements InventoryCost có `RecordType = Expense` và `Active`, `ORDER BY PointInTime DESC` (thời điểm xuất kho mới nhất). Nếu hai mốc khác nhau → cần tính lại.

Form của data processor: command `Recalculate` gọi `RecalculateAtServer()`; nếu `SeqBoundEnd.Compare(SeqBoundCurrent) = 1` thì gọi `Sequences.InventoryCostRecalculation.Restore()` rồi cập nhật lại hai mốc (`SetSeqBounds()`). `Restore()` là method platform khôi phục sequence bằng cách post lại các Document sau ranh giới (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).

Tích hợp SSL **ToDoList**: `ToDoListOverridable.OnDetermineToDoListHandlers` có `ToDoList.Add(DataProcessors.InventoryCostRecalculation);`, và manager module cài `OnFillToDoList`: thêm một dòng `InventoryCostRecalculation` (Owner = `Metadata.Subsystems.Warehouses`) và một dòng con "It may be necessary to recalculate inventory costs" (`Important = True`, `Form = "DataProcessor.InventoryCostRecalculation.Form"`), `HasToDoItems` = kết quả `IsNeedToRecalculate()` (so `GetSeqBoundCurrent()` với `SequenceEnd()`).

## 9. Forms của Document

Mỗi Document có `DocumentForm`, `ListForm`, `ChoiceForm`. Form module của **InventoryWriteOff** và **InventoryTransfer** giống hệt nhau (138 dòng) và chỉ chứa các lệnh gọi SSL:

| Event / handler | Gọi SSL |
|---|---|
| `OnCreateAtServer` | `AttachableCommands.OnCreateAtServer`, `PropertyManager.OnCreateAtServer` (đặt additional attributes vào group `GroupAdditionalAttributes`) |
| `OnReadAtServer`, `OnOpen`, `AfterWrite`, `NotificationProcessing` | `AttachableCommands*`, `PropertyManager*` |
| `FillCheckProcessingAtServer` | `PropertyManager.FillCheckProcessing` |
| `BeforeWriteAtServer` | `PropertyManager.BeforeWriteAtServer` |
Form InventoryTransfer có các input field `Warehouse`, `WarehouseReceiver`, `Number`, `Date`, table `Inventory` (cột `InventoryProduct`, `InventoryQuantity` và một cột hiển thị `Object.Inventory.Product.Unit`), `Comment`, field `Author`.

**InventoryIncrease** thêm logic tính tiền trên client và nhập từ file:

Nguồn: Jet — cf/Documents/InventoryIncrease/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure InventoryAmountOnChange(Item)
	
	TabSectionRow = Items.Inventory.CurrentData;
	
	If TabSectionRow.Quantity <> 0 Then
		TabSectionRow.Price = Round(TabSectionRow.Amount / TabSectionRow.Quantity, 2);
	EndIf;
	
EndProcedure
// ...
&AtClient
Procedure CalculateAmount()
	
	TabSectionRow = Items.Inventory.CurrentData;
	
	If TabSectionRow <> Undefined Then
		TabSectionRow.Amount = TabSectionRow.Quantity * TabSectionRow.Price;
	EndIf;
	
EndProcedure
```

`InventoryQuantityOnChange` và `InventoryPriceOnChange` đều chỉ gọi `CalculateAmount()`. Lưu ý: form này **không** dùng `InventoryTabularSectionClientServer.CalculateAmount` (mục 10) vì tabular section của InventoryIncrease không có VAT.

Nhập tabular section từ file (SSL ImportDataFromFile, template `LoadingFromFile` gồm cột Product, Quantity, Price): command `ImportInventoryFromFile` gọi `ImportDataFromFileClient.ShowImportForm` với `FullTabularSectionName = "InventoryIncrease.Inventory"`; callback `ImportInventoryFromFileEnd` → `ImportInventoryFromFileAtServer` đọc `GetFromTempStorage(ImportedDataAddress)`, bỏ dòng không có `Product`, thêm dòng vào `Object.Inventory` và tính `NewRow.Amount = NewRow.Quantity * NewRow.Price`.

Manager module InventoryIncrease cài các handler SSL `MapDataToImport`, `FillInListOfAmbiguities` bằng cách ủy quyền cho `ImportDataFromFileJet` (module của Jet). `FormManagement()` ẩn nút import trên `MobileClient` bằng `#If MobileClient Then`.

## 10. Common module InventoryTabularSectionClientServer

Module của Jet; flags: `ClientManagedApplication` = true, `Server` = true, `ExternalConnection` = true, `ServerCall` = false, `Global` = false (xem Bài 14).

Nguồn: Jet — cf/CommonModules/InventoryTabularSectionClientServer/Ext/Module.bsl
```bsl
Procedure CalculateAmount(TabSectionRow) Export
	
	TabSectionRow.Amount = TabSectionRow.Quantity * TabSectionRow.Price;
	CalculateVATAmountAndTotal(TabSectionRow);
	
EndProcedure
// ...
Procedure CalculateVATAmountAndTotal(TabSectionRow) Export
	
	VATRate = JetServerCall.GetVATRateValue(TabSectionRow.VATRate);
	TabSectionRow.VATAmount = TabSectionRow.Amount * VATRate / 100;
	TabSectionRow.Total = TabSectionRow.Amount + TabSectionRow.VATAmount;
	
EndProcedure
```

- Yêu cầu dòng tabular section có các cột `Quantity`, `Price`, `Amount`, `VATRate`, `VATAmount`, `Total`.
- Lấy % thuế qua `JetServerCall.GetVATRateValue` (module `ServerCall` = true) → `JetCached.GetVATRateValue` (module reuse return values, xem Bài 14) — nên gọi được từ client mà không tốn nhiều lượt server.
- Người dùng thực tế: form `SalesInvoice`, `SupplierInvoice` và `PriceManagementClient`. **Ba Document kho không dùng** module này (tabular section của chúng không có VAT). Tên module có chữ "Inventory" vì nó phục vụ tabular section tên `Inventory` của các hóa đơn.

## 11. Reports

Cả hai report dùng DCS (xem Bài 18), main schema `MainDataCompositionSchema`, không có form riêng (`DefaultForm` rỗng — dùng form report của SSL Report options). Mô tả variant được khai báo trong `ReportsOptionsOverridable` (mục 12).

### 11.1 AvailableStock — tồn kho theo kho (InventoryInWarehouses)

Nguồn: Jet — cf/Reports/AvailableStock/Templates/MainDataCompositionSchema/Ext/Template.xml (query của DataSet1, đã bỏ XML escape)
```
SELECT
	InventoryInWarehousesBalance.Product AS Product,
	InventoryInWarehousesBalance.Warehouse AS Warehouse,
	InventoryInWarehousesBalance.QuantityBalance AS QuantityBalance
FROM
	AccumulationRegister.InventoryInWarehouses.Balance AS InventoryInWarehousesBalance
```

- Resource: `QuantityBalance` = `Sum(QuantityBalance)`.
- Parameter `Period` (dateTime, use Always) với expression: `CASE WHEN &Period = Undefined OR &Period = NULL OR &Period = DateTime(1,1,1) THEN DateTime(3999,12,31) ELSE DATEADD(EndOfPeriod(&Period, "Day"), "Second", 1) END` — để trống thì lấy tồn hiện tại, chọn ngày thì lấy tồn **cuối ngày** đó. [suy luận] DCS tự truyền `&Period` vào tham số Period của virtual table `Balance`.
- Variant `Default` ("Available stock"): một chart + một table, nhóm theo Warehouse, Product; filter Warehouse, Product (tắt sẵn). Variant `AvailableStockContext`: table nhóm Warehouse, Product.

### 11.2 StockStatement — nhập-xuất-tồn có giá trị (InventoryCost)

Nguồn: Jet — cf/Reports/StockStatement/Templates/MainDataCompositionSchema/Ext/Template.xml (query của DataSet1, đã bỏ XML escape)
```
SELECT ALLOWED
	InventoryCostBalanceAndTurnovers.Recorder AS Recorder,
	// ...
	InventoryCostBalanceAndTurnovers.Product AS Product,
	InventoryCostBalanceAndTurnovers.Warehouse AS Warehouse,
	InventoryCostBalanceAndTurnovers.QuantityOpeningBalance AS QuantityOpeningBalance,
	InventoryCostBalanceAndTurnovers.QuantityClosingBalance AS QuantityClosingBalance,
	InventoryCostBalanceAndTurnovers.QuantityReceipt AS QuantityReceipt,
	InventoryCostBalanceAndTurnovers.QuantityExpense AS QuantityExpense,
	InventoryCostBalanceAndTurnovers.AmountOpeningBalance AS AmountOpeningBalance,
	InventoryCostBalanceAndTurnovers.AmountClosingBalance AS AmountClosingBalance,
	InventoryCostBalanceAndTurnovers.AmountReceipt AS AmountReceipt,
	InventoryCostBalanceAndTurnovers.AmountExpense AS AmountExpense
FROM
	AccumulationRegister.InventoryCost.BalanceAndTurnovers(, , Auto, , ) AS InventoryCostBalanceAndTurnovers
```

- Virtual table `BalanceAndTurnovers` với periodicity `Auto` — DCS chọn mức chi tiết theo grouping người dùng chọn (Recorder, DayPeriod, MonthPeriod…).
- Resources: tổng `Sum(...)` cho 8 field Opening/Receipt/Expense/Closing × Quantity/Amount.
- Parameters: `ItmPeriod` (StandardPeriod), `BeginOfPeriod` = `&ItmPeriod.StartDate`, `EndOfPeriod` = `&ItmPeriod.EndDate`.
- Variant `StockStatement`: nhóm theo Product, filter Product. Variant `StockStatementContext`: nhóm theo Product.
- Report đọc **InventoryCost** (có giá trị), không đọc InventoryInWarehouses.

### 11.3 Lệnh mở report theo ngữ cảnh

Mỗi report có một command (`OpenAvailableStockReport`, `OpenStockStatementReport`; CommandParameterType = CatalogRef.Products, group `FormNavigationPanelSeeAlso`). Từ form sản phẩm, `CommandProcessing` (&AtClient) tạo `FilterStructure = New Structure("Product", CommandParameter)` rồi `OpenForm("Report.AvailableStock.Form", ...)` với các form parameter `VariantKey` = `"AvailableStockContext"` (hoặc `"StockStatementContext"`), `Filter`, `GenerateOnOpen = True`, `ReportOptionsCommandsVisibility = False`.

## 12. Print forms, Role và tích hợp SSL

**Print forms**: ba Document được đăng ký với SSL Print (xem Bài 22):

Nguồn: Jet — cf/CommonModules/PrintManagementOverridable/Ext/Module.bsl
```bsl
	Settings.PrintObjects.Add(Documents.InventoryIncrease);
	Settings.PrintObjects.Add(Documents.InventoryTransfer);
	Settings.PrintObjects.Add(Documents.InventoryWriteOff);
```

Manager module mỗi Document có `OnDefinePrintSettings` (đặt `Settings.OnAddPrintCommands = True`) nhưng `AddPrintCommands(PrintCommands)` có thân **rỗng**, và không có template in nào. Tức là hiện **chưa có print form** cho Document kho — chỉ có "chỗ cắm" sẵn.

**Report options** (`ReportsOptionsOverridable`, code Jet trong module SSL Overridable): thêm section `Metadata.Subsystems.Warehouses` ("Warehouses reports"); mô tả variant `StockStatement` = "Opening balance, receipt, consumption, closing balance by products", `AvailableStock.Default` = "Product stock balances by warehouse"; hai variant `...Context` bị `Enabled = False` (chỉ mở qua command ngữ cảnh).

**Properties** (`PropertyManagerOverridable`): khai báo set additional attributes `Catalog_Warehouses`, `Document_InventoryIncrease`, `Document_InventoryTransfer`, `Document_InventoryWriteOff`.

**Attached files**: role có quyền trên `Catalog.WarehousesAttachedFiles`, `InventoryIncreaseAttachedFiles`, `InventoryTransferAttachedFiles`, `InventoryWriteOffAttachedFiles` (SSL Attached files).

**Role UseWarehouses** (xem Bài 20): trên ba Document kho — Read, Insert, Update, Posting, UndoPosting và các quyền Interactive tương ứng; trên ba Catalog Warehouses/Products/Units — Read, Insert, Update, Edit, InputByString và các quyền Interactive; `Read, View` trên hai register; `Read, Update` trên Sequence; `Use, View` trên hai report và data processor; `View` trên subsystem và ba CommonCommand.

## 13. Những điểm cần lưu ý

Rút ra từ việc đọc code — dùng để giảng giải hoặc làm đề bài, không phải kết luận chính thức của Jet.

1. **`WarehouseReceiver` không bắt buộc** (FillChecking = DontCheck), không có `FillCheckProcessing` kiểm tra kho nhận ≠ kho xuất. [suy luận] Để trống → lỗi platform do dimension `Warehouse` có DenyIncompleteValues, thay vì thông báo thân thiện; chọn trùng kho → hai movements triệt tiêu.
2. **`Quantity` không bắt buộc > 0** (DontCheck, không MinValue).
3. **Kiểm tra tồn âm theo số dư hiện tại** `Balance(, )`, không theo thời điểm Document (mục 7); không có kiểm soát âm cho InventoryCost.
4. **Print form chưa có** dù đã đăng ký với SSL Print (mục 12).
5. `InventoryTabularSectionClientServer` không được Document kho nào dùng (mục 10).
6. Form InventoryWriteOff và InventoryTransfer giống hệt nhau, không có handler riêng cho `WarehouseReceiver`.

## 14. Gợi ý mở rộng cho nhóm sinh viên phân hệ Kho

Các ý tưởng dưới đây là **gợi ý** bài tập, dựa trên object/module có thật trong Jet. Chúng không phải tính năng của Jet. Code cụ thể sinh viên tự viết; khi cần code mẫu, viết theo nguyên tắc "code minh họa — chạy thử để kiểm chứng". Nên làm trong **Configuration extension** (Purpose: Customization hoặc Add-on) để giữ configuration gốc nguyên vẹn (upgrade-safe customization, xem bài Extensions).

### Gợi ý 1 — Kiểm tra dữ liệu cho InventoryTransfer (dễ)
- Mục tiêu: bắt buộc `WarehouseReceiver`, cấm trùng `Warehouse`, cấm `Quantity <= 0`.
- Chạm tới: object module `Document.InventoryTransfer` — thêm handler `FillCheckProcessing` (Bài 12); có thể áp dụng tương tự cho InventoryWriteOff / InventoryIncrease.
- Trong extension: adopt Document InventoryTransfer, thêm handler mới vào object module.
- Kiểm thử: tạo Transfer có kho nhận trống / trùng kho / số lượng 0 → phải bị chặn trước khi Posting chạy.

### Gợi ý 2 — Document mới "Kiểm kê kho" (InventoryCount) theo khuôn InventoryWriteOff (trung bình)
- Mục tiêu: header `Warehouse`; tabular section `Inventory` gồm `Product`, `QuantityBook` (sổ sách), `QuantityActual` (thực tế), `Difference`. Nút "Fill from balance" lấy tồn từ `InventoryInWarehouses.Balance`. Khi post: chênh lệch dương → Receipt, âm → Expense vào hai register.
- Chạm tới:
  - Object module: sao chép khuôn `Posting`/`UndoPosting` gồm `PostingManagement.InitializeAdditionalPropertiesForPosting`, `PrepareRecordSetsForWriting`, `ReflectInventoryInWarehouses`, `ReflectInventoryCost`, `WriteRecordSets`, `AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl`.
  - Manager module: `InitializeDocumentData` — phần thiếu hụt tính Amount theo công thức CASE của InventoryWriteOff, cần `DataLock` trên `InventoryCost` như WriteOff.
  - `Filling` → `ObjectFillingJet.FillDocument`.
  - Thêm Document vào subsystem `Warehouses/Warehouse`, role `UseWarehouses`, `PrintManagementOverridable`, `PropertyManagerOverridable` (nếu cần additional attributes).
  - [suy luận] Cân nhắc thêm vào `Documents` của Sequence `InventoryCostRecalculation` vì Document có phần xuất tính giá vốn.
- Câu hỏi thiết kế cho nhóm: phần thừa (Receipt) lấy Amount từ đâu — nhập giá tay như InventoryIncrease hay dùng giá bình quân hiện tại?

### Gợi ý 3 — Print form "Phiếu chuyển kho" cho InventoryTransfer (trung bình, Bài 17 + 22)
- Mục tiêu: lấp chỗ trống `AddPrintCommands` rỗng.
- Chạm tới: manager module `Document.InventoryTransfer` — cài `AddPrintCommands` và procedure in theo SSL Print; thêm template (spreadsheet) vào Document; `PrintManagementOverridable` đã có sẵn `Settings.PrintObjects.Add(Documents.InventoryTransfer)`.
- Nội dung in: số, ngày, `Warehouse` → `WarehouseReceiver`, bảng Product / Unit / Quantity, `Author`.
- Mở rộng thêm: cột giá trị lấy từ movements `InventoryCost` của chính Document (Recorder = Ref).

### Gợi ý 4 — Report "Thẻ kho" (Stock card) theo một sản phẩm (trung bình, Bài 18)
- Mục tiêu: liệt kê từng chứng từ nhập/xuất của một sản phẩm tại một kho, có tồn đầu – nhập – xuất – tồn cuối theo từng dòng Recorder.
- Chạm tới: Report mới với DCS dựa trên `AccumulationRegister.InventoryInWarehouses.BalanceAndTurnovers(, , Recorder, ...)` hoặc tái dùng cách StockStatement đọc `InventoryCost.BalanceAndTurnovers(, , Auto, , )`; parameter kỳ báo cáo kiểu `StandardPeriod` như `ItmPeriod`.
- Tích hợp: thêm variant vào `ReportsOptionsOverridable` (section Warehouses), thêm command ngữ cảnh trên Products theo mẫu `OpenStockStatementReport` (CommandParameterType = CatalogRef.Products).

### Gợi ý 5 — Tồn kho tối thiểu và cảnh báo (trung bình–khó)
- Mục tiêu: lưu mức tồn tối thiểu theo (Product, Warehouse); report/ToDo cảnh báo sản phẩm dưới mức.
- Chạm tới:
  - Information register mới (non-periodic) dimension `Product`, `Warehouse`, resource `MinQuantity` (Bài 12).
  - Query join register mới với `InventoryInWarehouses.Balance`.
  - Tích hợp SSL ToDoList theo mẫu `DataProcessors.InventoryCostRecalculation.OnFillToDoList` và `ToDoListOverridable.OnDetermineToDoListHandlers`.
  - Hoặc làm report DCS hai data set có link.

### Gợi ý 6 — Kiểm tra tồn âm theo thời điểm Document (khó, thảo luận)
- Mục tiêu: thử phiên bản `NegativeBalanceControl` kiểm số dư tại `PointInTime` của Document thay vì `Balance(, )`, so sánh hai cách với Document lùi ngày.
- Chạm tới: manager module `AccumulationRegister.InventoryInWarehouses` (trong extension: adopt và dùng `&Around` hoặc `&ChangeAndValidate` cho `NegativeBalanceControl`, xem bài Extensions); temp table `InventoryInWarehousesChange` có sẵn trong `AdditionalProperties.ForPosting.TempTablesManager`.
- Lưu ý: procedure được gọi bởi cả SalesInvoice và SupplierInvoice — thay đổi ảnh hưởng phân hệ Sales/Purchases, cần phối hợp với các nhóm khác.
