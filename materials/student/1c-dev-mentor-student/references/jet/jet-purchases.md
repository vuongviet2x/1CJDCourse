# 1C:Jet — Subsystem Purchases (phân hệ Mua hàng)

**Khi nào đọc file này:** khi sinh viên hỏi về phân hệ Mua hàng của Jet (Document `SupplierInvoice`, nhà cung cấp, VAT, ứng trước cho nhà cung cấp, register `Purchases` / `SupplierBalance`, report Purchases / SupplierBalance), hoặc khi nhóm sinh viên cần chọn hướng mở rộng cho phân hệ này.

Nguồn: cấu hình Jet (repo 1Ci-Company/Jet, nhánh `community`, commit 80884de, version 1.0.2.1) — mọi đường dẫn `cf/...` bên dưới là file trong bản dump cấu hình. Chỗ nào là suy luận được ghi "[suy luận]".

## Mục lục

1. [Thành phần của Subsystem Purchases](#1-thành-phần-của-subsystem-purchases)
2. [Catalog Counterparties — phía nhà cung cấp](#2-catalog-counterparties--phía-nhà-cung-cấp)
3. [Catalog VATRates](#3-catalog-vatrates)
4. [Document SupplierInvoice — metadata](#4-document-supplierinvoice--metadata)
5. [SupplierInvoice — form module: tính lại số tiền, VAT, tỷ giá](#5-supplierinvoice--form-module-tính-lại-số-tiền-vat-tỷ-giá)
6. [SupplierInvoice — Filling, BeforeWrite, Posting](#6-supplierinvoice--filling-beforewrite-posting)
7. [Common module PostingManagement — khung Posting dùng chung](#7-common-module-postingmanagement--khung-posting-dùng-chung)
8. [Accumulation register Purchases và SupplierBalance](#8-accumulation-register-purchases-và-supplierbalance)
9. [Ứng trước và thanh toán cho nhà cung cấp](#9-ứng-trước-và-thanh-toán-cho-nhà-cung-cấp)
10. [Report Purchases và SupplierBalance (DCS)](#10-report-purchases-và-supplierbalance-dcs)
11. [Các điểm tích hợp SSL](#11-các-điểm-tích-hợp-ssl)
12. [Những điểm đáng chú ý trong code](#12-những-điểm-đáng-chú-ý-trong-code)
13. [Gợi ý mở rộng cho nhóm sinh viên phân hệ Mua hàng](#13-gợi-ý-mở-rộng-cho-nhóm-sinh-viên-phân-hệ-mua-hàng)

---

## 1. Thành phần của Subsystem Purchases

Subsystem `Purchases` (cf/Subsystems/Purchases.xml) có `Picture` = `CommonPicture.SectionPurchases` và hai subsystem con. Đây là cách chia nhóm chức năng trên giao diện đã học ở Bài 9.

| Cấp | Member object (`<Content>`) |
|---|---|
| `Purchases` (cấp trên) | `AccumulationRegister.Purchases`, `AccumulationRegister.SupplierBalance`, `Report.Purchases`, `Report.SupplierBalance`, `Role.UsePurchases`, `CommonCommand.AdditionalReportsPurchases`, `CommonCommand.AdditionalDataProcessorsPurchases`, `CommonCommand.ReportPanelPurchases` |
| `Purchases.Purchases` (con) | `Document.SupplierInvoice` |
| `Purchases.Catalogs` (con) | `Catalog.Counterparties`, `Catalog.Products`, `Catalog.Units` |

Command interface của subsystem (cf/Subsystems/Purchases/Ext/CommandInterface.xml): hai report được đưa vào nhóm `ActionsPanelReports`; thứ tự subsystem con là `Catalogs` trước, `Purchases` sau. Ở subsystem con `Catalogs` (cf/Subsystems/Purchases/Subsystems/Catalogs/Ext/CommandInterface.xml), lệnh `Catalog.Counterparties.StandardCommand.OpenList` và `Catalog.Counterparties.Command.Customers` bị ẩn (`Visibility` = false) — trong phân hệ Mua hàng người dùng chỉ thấy lệnh **`Suppliers`** của Counterparties.

Ba common command là cầu nối sang SSL (xem Bài 21 — Additional reports and data processors): `AdditionalReportsPurchases` / `AdditionalDataProcessorsPurchases` gọi `AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm(..., "Purchases")` (module SSL), còn `ReportPanelPurchases` gọi `ReportsOptionsClient.ShowReportBar("Purchases", ExecutionParameters)` (module SSL). Để các lệnh này hoạt động, Jet khai báo section `Purchases` trong các module SSL "*Overridable": `AdditionalReportsAndDataProcessorsOverridable` (`Sections.Add(Metadata.Subsystems.Purchases)`) và `ReportsOptionsOverridable` (`Sections.Add(Metadata.Subsystems.Purchases, NStr("en = 'Purchases reports'"))`).

**Object liên quan nhưng không nằm trong subsystem này:** `Catalog.VATRates` (thuộc `Company.Taxes`), `Catalog.Warehouses`, `Catalog.Currencies`, `AccumulationRegister.InventoryInWarehouses` và `InventoryCost` (phân hệ Kho), `Document.BankPayment` / `CashVoucher` (phân hệ Dòng tiền — dùng để trả tiền / ứng trước cho nhà cung cấp), `CommonForm.SelectAdvances`.

**Role `UsePurchases`** (cf/Roles/UsePurchases/Ext/Rights.xml) cấp: toàn quyền tương tác với `Document.SupplierInvoice` (gồm Posting, UndoPosting, InteractivePosting…), `Catalog.Counterparties`, `Catalog.Products`, `Catalog.Units` và các catalog `*AttachedFiles`; chỉ Read/View với `AccumulationRegister.Purchases` và `SupplierBalance`; Use/View hai report; View `CommonForm.SelectAdvances`; Read/Update `Sequence.InventoryCostRecalculation`. Role này **không** có quyền trên `Catalog.VATRates`, `Catalog.Warehouses`, `AccumulationRegister.InventoryInWarehouses`, `InventoryCost` — các quyền đó nằm ở `UseCompany`, `UseWarehouses` (xem Bài 20). [suy luận] Người dùng thực tế cần được gán thêm các role đó; việc ghi vào register kho khi post vẫn chạy được vì Document bật **Post in privileged mode** (mục 4).

---

## 2. Catalog Counterparties — phía nhà cung cấp

Jet dùng **một** catalog `Counterparties` cho cả khách hàng và nhà cung cấp; phân biệt bằng hai attribute Boolean `Customer` và `Supplier` (cf/Catalogs/Counterparties.xml). Catalog có hierarchy kiểu `HierarchyFoldersAndItems`, `CodeLength` 9, `DescriptionLength` 25. Các attribute khác: `LegalName`, `TIN`, `PriceType` (`CatalogRef.PriceTypes`), `IsIndividual`; tabular section `AdditionalAttributes` (SSL Properties) và `ContactInformation` (SSL Contact information). Attribute `Supplier` có `FillFromFillingValue` = true.

**Lọc chỉ nhà cung cấp khi chọn trong SupplierInvoice** — làm bằng metadata, không cần code: attribute `SupplierInvoice.Supplier` có Choice parameter `Filter.Supplier` = `true` (cf/Documents/SupplierInvoice.xml). Đây là ví dụ tốt để nhắc sinh viên: nhiều yêu cầu lọc giải quyết được bằng thuộc tính metadata trước khi nghĩ tới code.

**Command `Suppliers`** (cf/Catalogs/Counterparties/Commands/Suppliers/Ext/CommandModule.bsl, &AtClient) mở `Catalog.Counterparties.ListForm` với `FormParameters` gồm `Supplier` = True và `PurposeUseKey` = `"SupplierList"` (để form lưu cài đặt riêng cho danh sách nhà cung cấp).

List form đọc `Parameters.Supplier` / `Parameters.Customer` trong `OnCreateAtServer` rồi gọi `SetFilterCustomersSuppliers`. `SetFilterCustomersSuppliers` là procedure `&AtClientAtServerNoContext` (gọi được cả từ `OnCreateAtServer` lẫn từ handler client `FilterSuppliersOnChange`), dùng các hàm SSL `CommonClientServer.ChangeFilterItems`, `FindFilterItemByPresentation`, `CreateFilterItemGroup`, `AddCompositionItem` để thêm điều kiện vào `List.SettingsComposer.FixedSettings.Filter` (nhóm OR tên `"CustomersOrSuppliers"`).

Report `Purchases` và `SupplierBalance` mỗi cái có một command (`OpenPurchasesReport`, `OpenSupplierBalanceReport`) với `CommandParameterType` = `CatalogRef.Counterparties`, nhóm `FormNavigationPanelSeeAlso` — nên trên form của một counterparty sẽ có liên kết "xem thêm" mở report đã lọc theo counterparty đó (mục 10).

---

## 3. Catalog VATRates

Catalog đơn giản: không hierarchy, `CodeLength` 0, `DescriptionLength` 25, một attribute `Rate` (Number 5.2). `Catalog.Products` có attribute `VATRate` (`CatalogRef.VATRates`) — thuế suất mặc định của mặt hàng.

Item form có `RateOnChange` (&AtClient): nếu `Description` trống thì đặt `Description = String(Object.Rate) + "%"`.

Manager module có một function export, dùng khi chứng từ được đánh dấu "miễn thuế":

Nguồn: Jet — cf/Catalogs/VATRates/Ext/ManagerModule.bsl
```bsl
Function GetExemptFromVATRate() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	VATRates.Ref AS Ref
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	NOT VATRates.DeletionMark
	|	AND VATRates.Rate = 0";
	
	// ...
	NewVATRate = Catalogs.VATRates.CreateItem();
	NewVATRate.Description = "0%";
	NewVATRate.Rate = 0;
	NewVATRate.Write();
	// ...
	
EndFunction
```

Lưu ý: thuật toán tìm theo **giá trị `Rate` = 0**, không theo Description — đúng nguyên tắc "không dựa vào dữ liệu người dùng có thể sửa tùy ý" (terminology.md mục 2), dù Jet không dùng Predefined data ở đây.

Giá trị phần trăm được đọc qua một chuỗi module Jet: `JetServerCall.GetVATRateValue` (common module **Server call** = true) → `JetCached.GetVATRateValue` (common module có **Reuse return values** = `DuringSession`, xem Bài 14):

`JetCached.GetVATRateValue` trả về `?(ValueIsFilled(VATRate), Common.ObjectAttributeValue(VATRate, "Rate"), 0)`.

[suy luận] Vì cache theo session, nếu ai đó sửa `Rate` của một thuế suất đang dùng, người dùng khác có thể vẫn thấy giá trị cũ cho tới khi mở lại phiên.

---

## 4. Document SupplierInvoice — metadata

Synonym "Supplier invoice" (hóa đơn nhà cung cấp / phiếu nhập mua). Thuộc tính chính (cf/Documents/SupplierInvoice.xml):

| Property | Giá trị |
|---|---|
| Number | String, length 9, Variable, Autonumbering, CheckUnique |
| Posting | Allow; RealTimePosting = Deny |
| RegisterRecordsDeletion | AutoDeleteOff |
| RegisterRecordsWritingOnPost | WriteSelected |
| Post in privileged mode / Unpost in privileged mode | true / true |
| DataLockControlMode | Managed |
| BasedOn | (trống) — SupplierInvoice không được tạo từ document khác |
| Register records | `Purchases`, `SupplierBalance`, `InventoryInWarehouses`, `InventoryCost` |
| Templates | `PF_MXL_GoodsReceivedNote` (in), `PrintData` (DCS dữ liệu in), `LoadingFromFile` (mẫu import) |

**Header attributes**

| Attribute | Type | Ghi chú |
|---|---|---|
| `Supplier` | CatalogRef.Counterparties | FillChecking = ShowError; Choice parameter `Filter.Supplier` = true |
| `Warehouse` | CatalogRef.Warehouses | ShowError |
| `Currency` | CatalogRef.Currencies | ShowError |
| `ExchangeRate` | Number 10.4, Nonnegative | tỷ giá |
| `Multiplier` | Number 10.0, Nonnegative | "bội số" tỷ giá (Repetition) |
| `Comment` | String (không giới hạn) | |
| `Author` | CatalogRef.Users | điền khi tạo (mục 6) |
| `Total` | Number 15.2 | tính lại trong `BeforeWrite` |
| `ExemptFromVAT` | Boolean | miễn VAT |

Standard attribute `Date` có FillChecking = ShowError.

**Tabular section `Inventory`**: `Product` (CatalogRef.Products), `Quantity` (15.3), `Price`, `Amount`, `VATRate` (CatalogRef.VATRates), `VATAmount`, `Total` (đều 15.2). Quy ước: `Amount` = trước thuế, `Total` = sau thuế, tất cả tính theo **tiền của chứng từ** (`Currency`).

**Tabular section `AdvanceClearing`** (cấn trừ ứng trước): `Document` (composite type: `DocumentRef.BankPayment`, `DocumentRef.CashVoucher`), `Amount` (theo presentation currency), `AmountCur` (theo tiền chứng từ).

**Tabular section `AdditionalAttributes`**: `Property`, `Value`, `TextString` — phục vụ SSL Properties.

**Form `DocumentForm`** (cf/Documents/SupplierInvoice/Forms/DocumentForm/Ext/Form.xml): header gồm `Supplier`, `Currency`, `ExchangeRate`, `Multiplier`, `ExemptFromVAT`, `Number`, `Date`, `Warehouse`; ba page: `GroupInventory` (bảng `Inventory` + nút `ImportInventoryFromFile` + nhóm tổng `GroupTotal`), `GroupAdvanceClearing` (bảng `AdvanceClearing` + nút `SelectAdvances`), `GroupAdditionalInfo` (`Comment`, `Author`, nhóm thuộc tính bổ sung). Cột `InventoryUnit` là LabelField với DataPath `Object.Inventory.Product.Unit` — hiển thị đơn vị tính bằng dereference, không lưu vào document. Form attribute ngoài `Object`: `PresentationCurrency`.

---

## 5. SupplierInvoice — form module: tính lại số tiền, VAT, tỷ giá

### 5.1. Bản đồ handler → module được gọi

| Handler (directive) | Sự kiện | Gọi tới |
|---|---|---|
| `OnCreateAtServer` (&AtServer) | tạo form | `JetServer.GetPresentationCurrency`; SSL `AttachableCommands`, `PropertyManager` |
| `OnOpen` (&AtClient) | mở form | `FormManagement()`; SSL |
| `FillCheckProcessingAtServer` (&AtServer) | kiểm tra trước khi ghi | `Common.MessageToUser` (SSL) |
| `CurrencyOnChange` (&AtClient) | đổi tiền tệ | `GetExchangeRateData` (&AtServerNoContext) → SSL `CurrencyRateOperations.GetCurrencyRate` |
| `ExemptFromVATOnChange` (&AtClient) | bật/tắt miễn thuế | `FillVATRateByVATExemption` (&AtServer) |
| `InventoryProductOnChange` (&AtClient) | chọn sản phẩm | `GetProductData` (&AtServerNoContext), `InventoryTabularSectionClientServer.CalculateAmount` |
| `InventoryQuantityOnChange`, `InventoryPriceOnChange` | đổi SL / đơn giá | `InventoryTabularSectionClientServer.CalculateAmount` |
| `InventoryAmountOnChange` | sửa thành tiền | tính ngược `Price`, rồi `CalculateVATAmountAndTotal` |
| `InventoryVATRateOnChange` | đổi thuế suất | `InventoryTabularSectionClientServer.CalculateVATAmountAndTotal` |
| `AdvanceClearingAmountOnChange`, `AdvanceClearingAmountCurOnChange` | sửa số cấn trừ | `JetClientServer.CalculateFromCurrencyToCurrency` |
| `SelectAdvances` (command) | chọn khoản ứng trước | `CommonForm.SelectAdvances` (mục 9) |
| `ImportInventoryFromFile` (command) | import Excel | SSL `ImportDataFromFileClient` |

### 5.2. Product / Quantity / Price / VAT

Nguồn: Jet — cf/Documents/SupplierInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure InventoryProductOnChange(Item)
	
	// ...
	GetProductData(DataStructure);
	
	FillPropertyValues(CurrentData, DataStructure);
	
	InventoryTabularSectionClientServer.CalculateAmount(CurrentData);
	
EndProcedure

// ...
&AtClient
Procedure InventoryAmountOnChange(Item)
	
	TabSectionRow = Items.Inventory.CurrentData;
	
	If TabSectionRow.Quantity <> 0 Then
		TabSectionRow.Price = Round(TabSectionRow.Amount / TabSectionRow.Quantity, 2);
	EndIf;
	
	InventoryTabularSectionClientServer.CalculateVATAmountAndTotal(TabSectionRow);
	
EndProcedure
```

`GetProductData` chạy `&AtServerNoContext` — chỉ truyền một Structure nhỏ lên server, không truyền cả form (xem Bài 7, context vs non-context call):

Nguồn: Jet — cf/Documents/SupplierInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServerNoContext
Procedure GetProductData(DataStructure)
	
	// ...
		ProductAttributes = Common.ObjectAttributesValues(DataStructure.Product, "VATRate");
	// ...
	If DataStructure.Property("ExemptFromVAT") And DataStructure.ExemptFromVAT Then
		DataStructure.Insert("VATRate", Catalogs.VATRates.GetExemptFromVATRate());
	Else
		DataStructure.Insert("VATRate", ProductAttributes.VATRate);
	EndIf;
	
	DataStructure.Insert("Quantity", 1);
	
EndProcedure
```

So sánh: `GetProductData` trong form của `SalesInvoice` có thêm hai dòng lấy giá bằng `PriceManagementServerCall.GetProductPriceByPriceType`. Ở SupplierInvoice **không tự điền giá** — người dùng nhập `Price` bằng tay (ý tưởng mở rộng ở mục 13).

Công thức nằm trong common module Jet `InventoryTabularSectionClientServer` (Client (managed application) = true, Server = true, Server call = false — chạy được cả hai phía, dùng chung với các document khác có tabular section `Inventory`):

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

Chuỗi gọi khi sửa Quantity trên client: `InventoryQuantityOnChange` (client) → `CalculateAmount` (client) → `CalculateVATAmountAndTotal` (client) → `JetServerCall.GetVATRateValue` (**server call**) → `JetCached.GetVATRateValue` (server, cache). [suy luận] Mỗi lần sửa một ô là một lần gọi server; cache giúp phía server nhanh nhưng vẫn có round-trip.

### 5.3. Miễn thuế (ExemptFromVAT)

Nguồn: Jet — cf/Documents/SupplierInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure FillVATRateByVATExemption()
	
	If Object.ExemptFromVAT Then
		
		ExemptFromVATRate = Catalogs.VATRates.GetExemptFromVATRate();
		
		For Each InventoryRow In Object.Inventory Do
			InventoryRow.VATRate = ExemptFromVATRate;
			InventoryRow.VATAmount = 0;
			InventoryRow.Total = InventoryRow.Amount;
		EndDo;
	Else
		For Each InventoryRow In Object.Inventory Do
			InventoryRow.VATRate = InventoryRow.Product.VATRate;
			InventoryTabularSectionClientServer.CalculateVATAmountAndTotal(InventoryRow);
		EndDo;
	EndIf;
	
EndProcedure
```

Directive `&AtServer` (có context) vì phải duyệt và sửa toàn bộ `Object.Inventory`; dòng `InventoryRow.Product.VATRate` dùng dereference nên chỉ viết được ở server. `FormManagement()` (client) ẩn các cột `InventoryVATRate`, `InventoryVATAmount`, `InventoryTotal` và tổng VAT khi `ExemptFromVAT` = true, và khóa `ExchangeRate`/`Multiplier` khi `Currency` = presentation currency.

### 5.4. Tiền tệ và tỷ giá

`CurrencyOnChange` (&AtClient) gom `Currency`, `PresentationCurrency`, `Date` vào Structure rồi gọi `GetExchangeRateData` (&AtServerNoContext): nếu tiền tệ khác presentation currency thì lấy `CurrencyRateOperations.GetCurrencyRate(Currency, Date)` và gán `ExchangeRate = Rate`, `Multiplier = Repetition`; ngược lại gán 1 / 1. `CurrencyRateOperations` là module SSL (Currencies subsystem). Presentation currency lấy từ `JetServer.GetPresentationCurrency()` = attribute `PresentationCurrency` của `Catalogs.Companies.MainCompany` (predefined item). Đổi tiền tệ **không** tự quy đổi lại giá trong bảng — chỉ cập nhật `ExchangeRate`, `Multiplier`.

### 5.5. Kiểm tra trước khi ghi

Nguồn: Jet — cf/Documents/SupplierInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.Inventory.Total("Total") < Object.AdvanceClearing.Total("AmountCur") Then
		MessageText = NStr("en = 'The invoice amount is less than the clearing amount.'");
		Common.MessageToUser(MessageText,,,, Cancel);
	EndIf;
	// ...
EndProcedure
```

So sánh tổng hóa đơn với tổng cấn trừ **cùng theo tiền chứng từ** (`AmountCur`). Lưu ý đây là `FillCheckProcessingAtServer` của **form**, không phải `FillCheckProcessing` của object module (xem Bài 12, Bài 16) — nếu document được ghi bằng code (không qua form) thì kiểm tra này không chạy.

---

## 6. SupplierInvoice — Filling, BeforeWrite, Posting

Object module ngắn gọn; toàn bộ logic dữ liệu được đẩy sang manager module và common module.

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ObjectModule.bsl
```bsl
#If Server Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Document data initialization.
	Documents.SupplierInvoice.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	
	// Movements on the Purchases register
	PostingManagement.ReflectPurchases(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the InventoryInWarehouses register
	PostingManagement.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the SupplierBalance register
	PostingManagement.ReflectSupplierBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the InventoryCost register
	PostingManagement.ReflectInventoryCost(AdditionalProperties, RegisterRecords, Cancel);
	
	// Writing of the records sets.
	PostingManagement.WriteRecordSets(ThisObject);
	
	// Negative balance control
	AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl(Ref, AdditionalProperties, Cancel);
	
EndProcedure

// ...
```

Các điểm cần giải thích cho sinh viên:

- **Filling** gọi `ObjectFillingJet.FillDocument` (common module Jet, chỉ Server): nếu `FillingData` không phải Structure thì thay bằng Structure rỗng; điền `Currency` = presentation currency với `ExchangeRate` = 1, `Multiplier` = 1 (hoặc lấy tỷ giá qua `CurrencyRateOperations.GetCurrencyRate` nếu FillingData có Currency); điền `Author` = `Users.AuthorizedUser()` (SSL). Vì không có `BasedOn`, SupplierInvoice hiện chỉ được "điền" khi tạo mới, không có Generation từ document khác.
- **Posting** theo mẫu 3 bước: (1) chuẩn bị dữ liệu bằng **một batch query** trong manager module → (2) nạp từng bảng vào record set bằng `PostingManagement.Reflect*` → (3) ghi và kiểm soát tồn âm. So với cách "duyệt tabular section, `RegisterRecords.X.Add()`" ở Bài 11, đây là cách làm của ứng dụng thật: tách truy vấn khỏi ghi sổ, dễ mở rộng thêm register.
- **UndoPosting** xóa các record set (record set rỗng được ghi lại) và vẫn chạy `NegativeBalanceControl` — hủy một phiếu nhập có thể làm tồn kho âm nếu hàng đã được bán.
- **BeforeWrite** tính `Total` header; kiểm tra `DataExchange.Load` để bỏ qua khi nạp dữ liệu trao đổi.

### 6.1. InitializeDocumentData — batch query

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl
```bsl
Procedure InitializeDocumentData(SupplierInvoiceRef, AdditionalProperties) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	// ...
	|INTO DocumentHeader
	// ...
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentHeader.Date AS Period,
	|	DocumentHeader.Supplier AS Counterparty,
	|	DocumentHeader.Warehouse AS Warehouse,
	|	DocumentHeader.Ref AS Document,
	|	SupplierInvoiceInventory.Product AS Product,
	|	SupplierInvoiceInventory.Quantity AS Quantity,
	|	SupplierInvoiceInventory.Amount * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS Amount,
	|	SupplierInvoiceInventory.VATAmount * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS VATAmount,
	|	SupplierInvoiceInventory.Total * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS Total
	|INTO DocumentInventory
	|FROM
	|	DocumentHeader AS DocumentHeader
	|		INNER JOIN Document.SupplierInvoice.Inventory AS SupplierInvoiceInventory
	|		ON DocumentHeader.Ref = SupplierInvoiceInventory.Ref
	|;
	|
	// ...
	|		INNER JOIN Catalog.Products AS Products
	|		ON DocumentInventory.Product = Products.Ref
	|			AND (Products.ProductType = VALUE(Enum.ProductTypes.Inventory))
	// ...
```

Bốn query đầu (index 0–3) tạo temporary table (xem Bài 10 — temporary tables, batch query):

| Temp table | Nội dung |
|---|---|
| `DocumentHeader` | header của document |
| `DocumentInventory` | các dòng `Inventory`, số tiền đã **quy đổi sang presentation currency**: `× ExchangeRate / Multiplier` |
| `ProductTable` | chỉ các sản phẩm `ProductType = Inventory` (loại `Service` bị loại), gộp theo Period/Warehouse/Product |
| `DocumentAdvanceClearing` | các dòng cấn trừ ứng trước |

Bốn query sau (index 4–7) trả ra bảng cho từng register: `Purchases` (từ `DocumentInventory`, gộp theo Product/Counterparty/Period/Document, `Document AS PurchaseDocument`), `InventoryInWarehouses` (Receipt từ `ProductTable`), `SupplierBalance` (ba khối `UNION ALL` — trích dưới đây), `InventoryCost` (Receipt từ `ProductTable`, có `Amount`):

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl
```bsl
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentInventory.Period AS Period,
	|	VALUE(Enum.LiabilityTypes.Liability) AS LiabilityType,
	|	DocumentInventory.Counterparty AS Counterparty,
	|	DocumentInventory.Document AS Document,
	|	SUM(DocumentInventory.Total) AS Amount
	|FROM
	|	DocumentInventory AS DocumentInventory
	|
	|GROUP BY
	|	DocumentInventory.Document,
	|	DocumentInventory.Period,
	|	DocumentInventory.Counterparty
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentAdvanceClearing.Period,
	|	VALUE(Enum.LiabilityTypes.Advance),
	|	DocumentAdvanceClearing.Counterparty,
	|	DocumentAdvanceClearing.Document,
	|	SUM(DocumentAdvanceClearing.Amount)
	|FROM
	|	DocumentAdvanceClearing AS DocumentAdvanceClearing
	// ...
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentAdvanceClearing.Period,
	|	VALUE(Enum.LiabilityTypes.Liability),
	|	DocumentAdvanceClearing.Counterparty,
	|	DocumentAdvanceClearing.InvoiceDocument,
	|	SUM(DocumentAdvanceClearing.Amount)
	|FROM
	|	DocumentAdvanceClearing AS DocumentAdvanceClearing
	// ...
	
	Query.SetParameter("Ref", SupplierInvoiceRef);
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TablePurchases", QueryResult[4].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[5].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableSupplierBalance", QueryResult[6].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[7].Unload());
	
EndProcedure
```

Tóm tắt register records của một SupplierInvoice:

| Register | Kiểu | Bản ghi | Dữ liệu |
|---|---|---|---|
| `Purchases` | Turnovers | không có RecordType | mọi dòng (kể cả Service): Counterparty, Product, PurchaseDocument = chính document; Quantity, Amount, VATAmount (presentation currency) |
| `InventoryInWarehouses` | Balance | Receipt | chỉ hàng `Inventory`: Warehouse, Product, Quantity |
| `SupplierBalance` | Balance | Receipt `Liability` | công nợ phải trả = tổng `Total` (sau thuế) theo document |
| | | Receipt `Advance` | mỗi dòng `AdvanceClearing`: Document = chứng từ ứng trước |
| | | Expense `Liability` | cùng số tiền, Document = chính hóa đơn |
| `InventoryCost` | Balance | Receipt | chỉ hàng `Inventory`: Quantity, Amount = giá trị **trước thuế** |

Mẹo dạy: tên cột trong mỗi query **trùng tên** dimension/resource của register, nhờ vậy `RecordSet.Load(ValueTable)` nạp thẳng được (mục 7). Đây cũng là lý do giá vốn nhập kho (`InventoryCost.Amount`) lấy `Amount` trước thuế, còn công nợ (`SupplierBalance.Amount`) lấy `Total` sau thuế.

---

## 7. Common module PostingManagement — khung Posting dùng chung

`PostingManagement` là common module Jet dùng cho mọi document có Posting (SupplierInvoice, SalesInvoice, BankPayment…).

Nguồn: Jet — cf/CommonModules/PostingManagement/Ext/Module.bsl
```bsl
Procedure PrepareRecordSetsForWriting(DocumentObject) Export
	
	For Each RecordSet In DocumentObject.RegisterRecords Do
		If RecordSet.Count() > 0 Then
			RecordSet.Clear();
		EndIf;
	EndDo;
	
	RegisterNameArray = GetUsedRegisterNames(DocumentObject.Ref, DocumentObject.AdditionalProperties.DocumentMetadata);
	For Each RegisterName In RegisterNameArray Do
		DocumentObject.RegisterRecords[RegisterName].Write = True;
	EndDo;
	
EndProcedure

// ...
Procedure ReflectPurchases(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TablePurchases = AdditionalProperties.TableForRegisterRecords.TablePurchases;
	
	If Cancel Or TablePurchases.Count() = 0 Then
		Return;
	EndIf;
	
	PurchaseRecord = RegisterRecords.Purchases;
	PurchaseRecord.Write = True;
	PurchaseRecord.Load(TablePurchases);
	
EndProcedure
```

`WriteRecordSets` duyệt `RegisterRecords`, với record set có `Write = True` thì chép `ForPosting` vào `RecordSet.AdditionalProperties`, gọi `RecordSet.Write()` rồi đặt lại `Write = False`.

`ReflectSupplierBalance`, `ReflectInventoryInWarehouses`, `ReflectInventoryCost` có cấu trúc giống hệt `ReflectPurchases`, chỉ khác tên bảng/register.

Ý nghĩa:

- `InitializeAdditionalPropertiesForPosting` thêm vào `AdditionalProperties` ba khóa: `TableForRegisterRecords` (New Structure), `ForPosting` (Structure chứa `TempTablesManager` = New TempTablesManager), `DocumentMetadata` (= `DocumentRef.Metadata()`).
- `AdditionalProperties` (property có sẵn của data object) được dùng như "túi" truyền dữ liệu giữa các bước: `TableForRegisterRecords` chứa ValueTable cho từng register; `ForPosting.TempTablesManager` được chuyền tiếp vào record set để register module dùng chung temp table.
- `PrepareRecordSetsForWriting`: xóa record set đang có trong bộ nhớ, rồi tìm (bằng hàm private `GetUsedRegisterNames` — một query `UNION ALL` các `SELECT TOP 1 … WHERE Recorder = &Recorder` trên từng register trong `DocumentMetadata.RegisterRecords`) những register **đã có bản ghi cũ** của document và đặt `Write = True` cho chúng. Nhờ vậy khi post lại, register nào không còn bản ghi mới vẫn được ghi đè bằng record set rỗng → bản ghi cũ bị xóa. Kết hợp với `RegisterRecordsWritingOnPost` = WriteSelected (mục 4): [suy luận] platform chỉ tự ghi những record set có `Write = True` khi post (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).
- Thứ tự trong `Posting` quan trọng: `NegativeBalanceControl` chạy **sau** `WriteRecordSets`, vì nó dựa vào temp table `InventoryInWarehousesChange` do record set module của `InventoryInWarehouses` tạo ra khi ghi (`BeforeWrite`/`OnWrite` của record set, có `DataLock` Exclusive theo Recorder). Đây là phân hệ Kho — chi tiết ở file Jet về Warehouses.

---

## 8. Accumulation register Purchases và SupplierBalance

### 8.1. AccumulationRegister.Purchases

cf/AccumulationRegisters/Purchases.xml — **Register type: Turnovers** (chỉ có doanh số, không có số dư; xem Bài 11). `EnableTotalsSplitting` = true. Recorder duy nhất: `Document.SupplierInvoice`. Không có module.

| Loại | Tên | Type |
|---|---|---|
| Dimension | `Counterparty` | CatalogRef.Counterparties |
| Dimension | `Product` | CatalogRef.Products |
| Dimension | `PurchaseDocument` | DocumentRef.SupplierInvoice |
| Resource | `Quantity` | Number 15.3 |
| Resource | `Amount` | Number 15.2 |
| Resource | `VATAmount` | Number 15.2 |

Không có `Total` trong register — report tự tính `Amount + VAT` (mục 10). Vì là Turnovers nên không có RecordType; [suy luận] muốn giảm doanh số mua (ví dụ trả hàng) thì ghi số âm.

### 8.2. AccumulationRegister.SupplierBalance

cf/AccumulationRegisters/SupplierBalance.xml — **Register type: Balance**. `EnableTotalsSplitting` = true. Recorders: `SupplierInvoice`, `BankPayment`, `CashVoucher`. Không có module.

| Loại | Tên | Type | DenyIncompleteValues |
|---|---|---|---|
| Dimension | `LiabilityType` | EnumRef.LiabilityTypes (`Liability`, `Advance`) | true |
| Dimension | `Counterparty` | CatalogRef.Counterparties | true |
| Dimension | `Document` | DocumentRef.BankPayment, DocumentRef.CashVoucher, DocumentRef.SupplierInvoice | false |
| Resource | `Amount` | Number 15.2 (presentation currency) | |

Quy ước dấu (rút ra từ code posting):

| Nghiệp vụ | RecordType | LiabilityType | Document |
|---|---|---|---|
| SupplierInvoice ghi nợ phải trả | Receipt | Liability | hóa đơn |
| BankPayment/CashVoucher trả cho một hóa đơn | Expense | Liability | hóa đơn được trả |
| BankPayment/CashVoucher trả không gắn hóa đơn (ứng trước) | Expense | Advance | chính phiếu chi |
| SupplierInvoice cấn trừ ứng trước | Receipt Advance + Expense Liability | | phiếu chi / hóa đơn |

→ Balance `Liability` dương = còn nợ nhà cung cấp; Balance `Advance` **âm** = đã ứng trước chưa cấn trừ. Report SupplierBalance đảo dấu khi hiển thị (mục 10). Dimension `Document` giúp theo dõi công nợ **theo từng chứng từ** (open-item), không chỉ theo nhà cung cấp.

### 8.3. Register phân hệ Kho mà SupplierInvoice ghi vào

- `InventoryInWarehouses` (Balance): dimension `Product`, `Warehouse`; resource `Quantity`. Có ManagerModule (`NegativeBalanceControl`) và RecordSetModule.
- `InventoryCost` (Balance): dimension `Product`, `Warehouse`; resource `Quantity`, `Amount`. Giá vốn bình quân được tính khi xuất (SalesInvoice, InventoryTransfer, InventoryWriteOff) — các document này nằm trong `Sequence.InventoryCostRecalculation`; **SupplierInvoice không nằm trong sequence đó** (xem mục 12).

---

## 9. Ứng trước và thanh toán cho nhà cung cấp

Wiki Jet (How-to-Start-Using-1C:Jet.md, mục 4 "Advance clearing") mô tả quy trình: trả trước bằng Bank payment hoặc Cash voucher → mở Supplier invoice → tab "Advance clearing" → "Select" → chọn chứng từ ứng trước → số ứng trước được trừ vào tổng hóa đơn.

### 9.1. Trả tiền: BankPayment / CashVoucher (phân hệ CashManagement)

`BankPayment` và `CashVoucher` có `BasedOn` = `Document.SupplierInvoice` — tức là từ hóa đơn có thể tạo phiếu chi (Generation, Bài 11). Trong tabular section `PaymentDetails`, attribute `Document` có type `DocumentRef.SupplierInvoice`. `Filling` của BankPayment (cf/Documents/BankPayment/Ext/ObjectModule.bsl), khi `TypeOf(FillingData) = Type("DocumentRef.SupplierInvoice")`, chạy một batch query lấy header hóa đơn và tài khoản ngân hàng đầu tiên cùng tiền tệ, rồi điền `Operation = Enum.BankPaymentOperations.Supplier`, `Counterparty = Supplier`, tiền tệ/tỷ giá, và một dòng `PaymentDetails` với `Document` = hóa đơn, `PaymentAmount` = `Total`, `Amount` = `Total × ExchangeRate / Multiplier`.

Phần ghi `SupplierBalance` khi post BankPayment — dòng nào không gắn hóa đơn thì thành **ứng trước** với Document = chính phiếu chi:

Nguồn: Jet — cf/Documents/BankPayment/Ext/ManagerModule.bsl
```bsl
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentPaymentDetails.Period AS Period,
	|	CASE
	|		WHEN DocumentPaymentDetails.Document = VALUE(Document.SupplierInvoice.EmptyRef)
	|				OR DocumentPaymentDetails.Document = UNDEFINED
	|			THEN VALUE(Enum.LiabilityTypes.Advance)
	|		ELSE VALUE(Enum.LiabilityTypes.Liability)
	|	END AS LiabilityType,
	|	DocumentPaymentDetails.Counterparty AS Counterparty,
	|	CASE
	|		WHEN DocumentPaymentDetails.Document = VALUE(Document.SupplierInvoice.EmptyRef)
	|				OR DocumentPaymentDetails.Document = UNDEFINED
	|			THEN DocumentPaymentDetails.Ref
	|		ELSE DocumentPaymentDetails.Document
	|	END AS Document,
	|	SUM(DocumentPaymentDetails.Amount) AS Amount
	|FROM
	|	DocumentPaymentDetails AS DocumentPaymentDetails
	|WHERE
	|	DocumentPaymentDetails.Operation = VALUE(Enum.BankPaymentOperations.Supplier)
```

BankPayment chỉ post các bản ghi khi `Paid` = true (`WHERE … AND BankPayment.Paid` trong `DocumentHeader`), period = `PaymentDate`. `CashVoucher` có logic SupplierBalance gần như y hệt (chỉ khác `Enum.CashVoucherOperations.Supplier`, period = `Date`).

### 9.2. Cấn trừ: CommonForm.SelectAdvances

Command `SelectAdvances` (&AtClient) trên form SupplierInvoice: báo lỗi nếu chưa chọn `Supplier`; đưa `Object.AdvanceClearing.Unload()` vào temporary storage (`PutAdvanceClearingToStorage`, &AtServer); mở `CommonForm.SelectAdvances` với các tham số `AddressInStorage`, `InvoiceRef`, `Counterparty`, `Currency`, `ExchangeRate`, `Multiplier`, `InvoiceAmount` (= `Object.Inventory.Total("Total")`) và `IsCustomerAdvance` = False (cùng form dùng cho SalesInvoice); callback là `New CallbackDescription("SelectAdvancesOnClose", ...)`.

Khi form đóng với `DialogReturnCode.OK`, `SelectAdvancesOnClose` gọi `GetAdvanceClearingFromStorage` (&AtServer) để `Object.AdvanceClearing.Load(...)` và đặt `Modified = True`. Đây là mẫu "truyền bảng giữa hai form qua temporary storage" (xem Bài 19 về file/storage trong client-server).

Bên trong `SelectAdvances`, query số dư ứng trước (procedure `FillAdvanceBalance`, &AtServer) được viết cho virtual table `AccumulationRegister.CustomerBalance.Balance(, LiabilityType = VALUE(Enum.LiabilityTypes.Advance) AND Counterparty = &Counterparty)` rồi **thay chuỗi** sang `SupplierBalance` khi không phải khách hàng:

Nguồn: Jet — cf/CommonForms/SelectAdvances/Ext/Form/Module.bsl
```bsl
	If Not IsCustomerAdvance Then
		Query.Text = StrReplace(Query.Text, "AccumulationRegister.CustomerBalance", "AccumulationRegister.SupplierBalance");
	EndIf;
```

Logic: lấy số dư `Advance` hiện tại của nhà cung cấp (âm), **cộng bù lại** các bản ghi Advance của chính hóa đơn đang sửa (`Recorder = &Ref` — để hóa đơn đã post vẫn thấy lại khoản ứng trước nó đã cấn), trừ đi các dòng đang có trong bảng cấn trừ, giữ các chứng từ còn số dư âm (`HAVING SUM(TmpAdvanceBalance.Amount) < 0`) và đảo dấu thành số dương để hiển thị. Lệnh `FillInAdvClearing` tự phân bổ: `FillAdvClearingTable(InvoiceAmount)` lần lượt lấy từng khoản ứng trước cho tới khi đủ tổng hóa đơn (dòng cuối có thể chỉ lấy một phần, quy đổi bằng `JetClientServer.CalculateFromCurrencyToCurrency`).

Hàm quy đổi tiền tệ của Jet:

Nguồn: Jet — cf/CommonModules/JetClientServer/Ext/Module.bsl
```bsl
Function CalculateFromCurrencyToCurrency(Amount, SourceRate, SourceMultiplier, NewRate = 1, NewMultiplier = 1) Export
	// ...
	Return Round((Amount * SourceRate * NewMultiplier) / (NewRate * SourceMultiplier), 2);
	
EndFunction
```

Trong form SupplierInvoice: sửa `Amount` (presentation currency) → `AmountCur` = `CalculateFromCurrencyToCurrency(Amount, 1, 1, ExchangeRate, Multiplier)`; sửa `AmountCur` → `Amount` = `CalculateFromCurrencyToCurrency(AmountCur, ExchangeRate, Multiplier)`.

`FilterCriteria.RelatedDocuments` có `Document.SupplierInvoice.TabularSection.AdvanceClearing.Attribute.Document` trong content — nên từ phiếu chi có thể xem các hóa đơn đã cấn trừ nó.

---

## 10. Report Purchases và SupplierBalance (DCS)

Cả hai report chỉ có `MainDataCompositionSchema`, không có object module hay form riêng — form report chuẩn của SSL Report options hiển thị (xem Bài 18, Bài 21). Mô tả biến thể được khai báo trong `ReportsOptionsOverridable` (module SSL Overridable, đoạn code Jet).

### 10.1. Report.Purchases

Nguồn: Jet — cf/Reports/Purchases/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT
	PurchasesTurnovers.Recorder AS Recorder,
	// ...
	PurchasesTurnovers.DayPeriod AS DayPeriod,
	// ...
	PurchasesTurnovers.MonthPeriod AS MonthPeriod,
	// ...
	PurchasesTurnovers.Counterparty AS Counterparty,
	PurchasesTurnovers.Product AS Product,
	PurchasesTurnovers.PurchaseDocument AS PurchaseDocument,
	PurchasesTurnovers.QuantityTurnover AS Quantity,
	PurchasesTurnovers.AmountTurnover AS Amount,
	PurchasesTurnovers.VATAmountTurnover AS VATAmount,
	PurchasesTurnovers.AmountTurnover + PurchasesTurnovers.VATAmountTurnover AS Total
FROM
	AccumulationRegister.Purchases.Turnovers(, , Auto, ) AS PurchasesTurnovers
```

- Virtual table `Turnovers` với Periodicity = `Auto` → DCS cung cấp mọi trường kỳ (`DayPeriod`, `MonthPeriod`…) để người dùng nhóm theo thời gian.
- Parameters: `ItmPeriod` (StandardPeriod, tiêu đề "Accounting period"); `BeginOfPeriod` = `&ItmPeriod.StartDate`, `EndOfPeriod` = `&ItmPeriod.EndDate` (ẩn với người dùng — `useRestriction` = true). [suy luận] DCS tự đẩy hai parameter này vào tham số kỳ của virtual table vì trùng tên chuẩn.
- Resources: `Sum(Quantity)`, `Sum(Amount)`, `Sum(VATAmount)`, `Sum(Total)`.
- Variants: `Default` — biểu đồ + nhóm `Product` / `Counterparty` → `Product` → `PurchaseDocument`, filter `Counterparty`, `Product`; `PurchasesContext` — nhóm `Product` → `PurchaseDocument`, dùng khi mở từ form counterparty (bị tắt khỏi report panel: `OptionSettings.Enabled = False`).

Lệnh mở theo ngữ cảnh `OpenPurchasesReport` (cf/Reports/Purchases/Commands/OpenPurchasesReport/Ext/CommandModule.bsl) gọi `OpenForm("Report.Purchases.Form", ...)` với `VariantKey` = `"PurchasesContext"`, `Filter` = `New Structure("Counterparty", CommandParameter)`, `GenerateOnOpen` = True, `ReportOptionsCommandsVisibility` = False.

### 10.2. Report.SupplierBalance

Nguồn: Jet — cf/Reports/SupplierBalance/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT
	SupplierBalance.LiabilityType AS LiabilityType,
	SupplierBalance.Counterparty AS Counterparty,
	SupplierBalance.Document AS Document,
	CASE
		WHEN SupplierBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Liability)
			THEN SupplierBalance.AmountBalance
		ELSE 0
	END AS AmountLiability,
	CASE
		WHEN SupplierBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
			THEN -SupplierBalance.AmountBalance
		ELSE 0
	END AS AmountAdvance,
	CASE
		WHEN SupplierBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Liability)
			THEN SupplierBalance.AmountBalance
		ELSE 0
	END - CASE
		WHEN SupplierBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
			THEN -SupplierBalance.AmountBalance
		ELSE 0
	END AS AmountTotal
FROM
	AccumulationRegister.SupplierBalance.Balance AS SupplierBalance
```

- Một virtual table `Balance`, tách thành hai cột: `AmountLiability` (còn phải trả) và `AmountAdvance` (đã ứng trước, đảo dấu thành dương); `AmountTotal` = phải trả − ứng trước = công nợ ròng.
- Parameter `Period` (Date) với expression: nếu trống thì `DateTime(3999,12,31)`, ngược lại `DATEADD(EndOfPeriod(&Period, "Day"), "Second", 1)` — tức số dư **tính đến hết ngày** được chọn. [suy luận] Cộng thêm 1 giây vì virtual table Balance không tính các bản ghi đúng tại thời điểm truyền vào (xem Bài 11 về Boundary). Đây là chi tiết hay để giải thích PointInTime/Boundary (Bài 11).
- Resources: `Sum(AmountLiability)`, `Sum(AmountAdvance)`, `Sum(AmountTotal)`. Variants: `SupplierBalance` (nhóm `Counterparty` → `Document`, kèm biểu đồ theo `Counterparty`), `SupplierBalanceContext` (mở từ form counterparty, command `OpenSupplierBalanceReport` y hệt `OpenPurchasesReport` với `VariantKey` = `"SupplierBalanceContext"`).

---

## 11. Các điểm tích hợp SSL

SupplierInvoice là ví dụ đầy đủ về cách một document Jet "cắm" vào SSL. Phân biệt rõ: **code của Jet** là các procedure trong manager module/form module và đoạn thêm vào module `*Overridable`; **module SSL được gọi** là `PrintManagement`, `PropertyManager`, `AttachableCommands`, `ImportDataFromFileClient`, `Interactions`…

| Subsystem SSL | Phía SupplierInvoice (code Jet) |
|---|---|
| Print (Bài 22) | Manager module: `OnDefinePrintSettings` (`Settings.OnAddPrintCommands = True`), `AddPrintCommands` thêm lệnh `PrintManager = "PrintManagement"`, `Id = "Document.SupplierInvoice.PF_MXL_GoodsReceivedNote"`, Presentation "Goods received note"; `PrintManagementOverridable.OnDefinePrintSettings` có `Settings.PrintObjects.Add(Documents.SupplierInvoice)` |
| Properties (thuộc tính bổ sung) | Tabular section `AdditionalAttributes`; form gọi `PropertyManager.OnCreateAtServer` với `ItemForPlacementName` = `"GroupAdditionalAttributes"`; `PropertyManagerOverridable` thêm set `"Document_SupplierInvoice"` |
| Attachable commands | Form gọi `AttachableCommands.OnCreateAtServer`, `Attachable_ExecuteCommand`… |
| Interactions | Manager module `GetContacts`, `ContactsQueryText` (contact = `Supplier`); `InteractionsClientServerOverridable` thêm `"DocumentRef.SupplierInvoice"` vào SubjectsTypes; list form `ListDragCheck`/`ListDrag` |
| Message templates | Manager module có các procedure rỗng `OnPrepareMessageTemplate`, `OnCreateMessage`… |
| Import data from file | Template `LoadingFromFile` (cột Product, Quantity, Price, VAT rate); manager module `MapDataToImport`, `FillInListOfAmbiguities` chuyển tiếp sang module Jet `ImportDataFromFileJet`; form `ImportInventoryFromFileAtServer` thêm dòng và gọi `InventoryTabularSectionClientServer.CalculateAmount` |
| Attached files | Catalog `SupplierInvoiceAttachedFiles` |


---

## 12. Những điểm đáng chú ý trong code

Dùng các điểm này khi ra câu hỏi thảo luận hoặc review code — đừng trình bày như "lỗi" chắc chắn của Jet nếu chưa chạy thử.

1. **SupplierInvoice không có trong `Sequence.InventoryCostRecalculation`** (cf/Sequences/InventoryCostRecalculation.xml chỉ có `InventoryTransfer`, `InventoryWriteOff`, `SalesInvoice`), dù SupplierInvoice ghi Receipt vào `InventoryCost`. [suy luận] Nếu nhập lùi ngày một hóa đơn mua sau khi đã có phiếu xuất, ranh giới sequence không tự lùi lại, nên giá vốn bình quân của các phiếu xuất sau đó có thể không được đánh dấu cần tính lại. Nên kiểm thử trên dữ liệu thật.
2. **Purchases ghi cả dịch vụ, kho thì không**: `TablePurchases` lấy từ `DocumentInventory` (mọi dòng), còn `InventoryInWarehouses`/`InventoryCost` lấy từ `ProductTable` (chỉ `ProductTypes.Inventory`). Hợp lý về nghiệp vụ, là ví dụ tốt về "không phải dòng nào cũng vào mọi register".
3. **Kiểm tra cấn trừ chỉ ở form** (`FillCheckProcessingAtServer`), object module không có `FillCheckProcessing` — ghi bằng code hoặc import sẽ bỏ qua kiểm tra này.
4. **Round-trip server khi sửa ô**: `CalculateVATAmountAndTotal` chạy trên client nhưng gọi `JetServerCall.GetVATRateValue` mỗi lần.
5. **`GetExemptFromVATRate` có thể tạo dữ liệu** (`CreateItem` … `Write()` trong privileged mode) ngay trong lúc người dùng tích "Exempt from VAT" — tác dụng phụ ít gặp trong một hàm "Get…".
6. **Thay chuỗi trong query** (`StrReplace(Query.Text, "AccumulationRegister.CustomerBalance", "AccumulationRegister.SupplierBalance")`) để tái dùng một form cho cả khách hàng và nhà cung cấp — gọn nhưng dễ vỡ nếu đổi tên register.
7. **Đổi tiền tệ không quy đổi lại giá dòng hàng**: `CurrencyOnChange` chỉ cập nhật `ExchangeRate`/`Multiplier`.
8. **Role `UsePurchases` không có quyền** đọc `Warehouses`, `VATRates` — cần kết hợp role (mục 1).

---

## 13. Gợi ý mở rộng cho nhóm sinh viên phân hệ Mua hàng

> Các mục dưới đây là **gợi ý** đề tài, không có trong Jet. Mỗi gợi ý nêu object/module Jet sẽ chạm tới để nhóm tự thiết kế. Theo nguyên tắc dạy ở SKILL.md, khi sinh viên làm đề tài thì **gợi ý trước**, không đưa lời giải đầy đủ ngay. Có thể làm trực tiếp trong configuration (bản học tập) hoặc dưới dạng **configuration extension** Purpose **Add-on** (xem bài Extensions) — cách sau là upgrade-safe customization, giữ Jet gốc không đổi.

### Gợi ý 1 — Document PurchaseOrder (đơn đặt hàng nhà cung cấp) trước SupplierInvoice

- **Bài toán:** theo dõi hàng đã đặt nhưng chưa về; tạo hóa đơn từ đơn hàng.
- **Object mới:** `Document.PurchaseOrder` (header giống SupplierInvoice: `Supplier` với Choice parameter `Filter.Supplier` = true, `Warehouse`, `Currency`, `ExchangeRate`, `Multiplier`; tabular section `Inventory` cùng cấu trúc để dùng lại `InventoryTabularSectionClientServer`); `AccumulationRegister.OrdersToSuppliers` (Balance; dimension `Counterparty`, `Product`, `PurchaseOrder`; resource `Quantity`).
- **Chạm vào Jet:** `SupplierInvoice.xml` — thêm `BasedOn` = PurchaseOrder, thêm attribute `PurchaseOrder`, thêm register vào Register records; `SupplierInvoice/Ext/ObjectModule.bsl` `Filling` — xử lý `TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder")` theo mẫu `BankPayment.Filling` (mục 9.1); `SupplierInvoice/Ext/ManagerModule.bsl` `InitializeDocumentData` — thêm query trả bảng Expense cho `OrdersToSuppliers`; `PostingManagement` — thêm `ReflectOrdersToSuppliers` theo mẫu `ReflectPurchases`; `Subsystems/Purchases` (content), `Role.UsePurchases`.
- **Liên hệ bài:** Bài 11 (Generation, Balance register), Bài 12 (kiểm tra không nhận quá số đặt).

### Gợi ý 2 — Document SupplierReturn (trả hàng cho nhà cung cấp)

- **Bài toán:** trả lại hàng lỗi; giảm tồn kho và giảm công nợ phải trả.
- **Object mới:** `Document.SupplierReturn`, `BasedOn` = SupplierInvoice, attribute `SupplierInvoice` (hóa đơn gốc).
- **Register records:** `InventoryInWarehouses` Expense (gọi `AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl` như SupplierInvoice); `InventoryCost` Expense; `SupplierBalance` Expense `Liability` với Document = hóa đơn gốc; `Purchases` với số lượng/số tiền âm (Turnovers register — xem mục 8.1).
- **Chạm vào Jet:** `PostingManagement` (dùng lại các `Reflect*` sẵn có), `AccumulationRegister.SupplierBalance` (thêm type `DocumentRef.SupplierReturn` vào dimension `Document`, thêm recorder), `AccumulationRegister.Purchases` (cân nhắc thêm type vào `PurchaseDocument` hoặc ghi theo hóa đơn gốc), `Sequence.InventoryCostRecalculation` (thêm document vì nó ghi Expense giá vốn — so với cách SalesInvoice tính giá vốn trong `Documents/SalesInvoice/Ext/ManagerModule.bsl`).
- **Liên hệ bài:** Bài 11, Bài 12 (DataLock), Bài 16 (thứ tự event).

### Gợi ý 3 — Tự điền giá mua theo bảng giá nhà cung cấp

- **Bài toán:** SupplierInvoice hiện bắt nhập giá tay (mục 5.2), trong khi Jet đã có `InformationRegister.Prices` (dimension `PriceType`, `Product`; resource `Price`), `Catalog.PriceTypes` và attribute `Counterparties.PriceType`.
- **Chạm vào Jet:** thêm attribute `PriceType` vào `SupplierInvoice`; trong form, khi đổi `Supplier` lấy `PriceType` của nhà cung cấp (mẫu: `GetCustomerPriceType` và `CustomerOnChange` trong form SalesInvoice); trong `GetProductData` thêm lời gọi `PriceManagementServerCall.GetProductPriceByPriceType(DataStructure)` như SalesInvoice; có thể dùng `PriceManagementClient.RefillTabularSectionPricesByPriceType`.
- **Mở rộng thêm:** khi post SupplierInvoice, ghi giá mua mới nhất vào `Prices` (Information register periodic, `SliceLast` — Bài 12).

### Gợi ý 4 — Hạn thanh toán và báo cáo tuổi nợ phải trả

- **Bài toán:** biết hóa đơn nào sắp/đã quá hạn trả.
- **Chạm vào Jet:** thêm attribute `DueDate` (hoặc `PaymentTermDays` trong `Counterparties`, điền `DueDate` trong `Filling`/form); report mới (hoặc variant mới của `Report.SupplierBalance`) với query DCS nối `AccumulationRegister.SupplierBalance.Balance` (lọc `LiabilityType = Liability`) với `Document.SupplierInvoice` qua dimension `Document` để lấy `DueDate`, tính số ngày quá hạn bằng `DATEDIFF`, nhóm theo khoảng tuổi nợ bằng `CASE`. Đăng ký variant trong `ReportsOptionsOverridable`, thêm report vào `Subsystems/Purchases` và `Role.UsePurchases`.
- **Liên hệ bài:** Bài 10 (CASE, join), Bài 18 (DCS parameters, resources), Bài 21 (Report options).

### Gợi ý 5 — Đưa kiểm tra cấn trừ ứng trước xuống object module

- **Bài toán:** chuyển kiểm tra "tổng hóa đơn < tổng cấn trừ" (mục 5.5) từ form xuống `FillCheckProcessing` của object module để áp dụng cả khi ghi bằng code/import; thêm kiểm tra khoản cấn trừ không vượt số dư ứng trước thật trong `SupplierBalance` (dùng lại logic query của `CommonForm.SelectAdvances`).
- **Chạm vào Jet:** `SupplierInvoice/Ext/ObjectModule.bsl`, form module (bỏ trùng lặp), có thể đưa query số dư ứng trước ra một common module server để form và object module dùng chung.
- **Làm bằng extension:** đề tài phù hợp để thực hành `&Before`/`&After` trên `FillCheckProcessing` hoặc `&ChangeAndValidate` (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant cho cú pháp cụ thể).

### Gợi ý 6 — Chi phí mua hàng phân bổ vào giá vốn (landed cost)

- **Bài toán:** phí vận chuyển/hải quan cộng vào giá trị hàng nhập.
- **Chạm vào Jet:** document mới (ví dụ `AdditionalPurchaseCosts`) tham chiếu SupplierInvoice, phân bổ chi phí theo `Amount` từng dòng `Inventory`; ghi Receipt chỉ resource `Amount` (Quantity = 0) vào `InventoryCost`; ghi `SupplierBalance` Receipt `Liability` cho nhà cung cấp dịch vụ vận chuyển. Phải xem xét `Sequence.InventoryCostRecalculation` và `DataProcessor.InventoryCostRecalculation` (cùng vấn đề ở mục 12, điểm 1).
- **Mức độ:** khó nhất trong các gợi ý — dành cho nhóm mạnh.
