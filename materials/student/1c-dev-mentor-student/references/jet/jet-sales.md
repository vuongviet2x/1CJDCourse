# 1C:Jet — Phân hệ Bán hàng (Subsystem Sales)

Khi nào đọc file này: sinh viên/nhóm thực hành mở rộng phân hệ **Sales** của Jet, hỏi về `SalesInvoice`, giá bán (`PriceTypes`, `Prices`), giá vốn hàng bán, công nợ khách hàng, các report bán hàng, hoặc print form hóa đơn bán.

Nguồn: Jet (repo 1Ci-Company/Jet, nhánh `community`, commit 80884de, config 1.0.2.1). Mọi đoạn code dưới đây chép nguyên văn; `// ...` là chỗ lược bớt. Phần ghi "[suy luận]" là diễn giải của người viết, không có trong code.

## Mục lục

1. [Thành phần của Subsystem Sales](#1-thành-phần-của-subsystem-sales)
2. [Catalog PriceTypes và Counterparties (phía khách hàng)](#2-catalog-pricetypes-và-counterparties-phía-khách-hàng)
3. [Giá bán: InformationRegister Prices — ghi giá và đọc giá](#3-giá-bán-informationregister-prices--ghi-giá-và-đọc-giá)
4. [Document SalesInvoice — metadata](#4-document-salesinvoice--metadata)
5. [SalesInvoice — form: tự điền giá, tính Amount / VAT](#5-salesinvoice--form-tự-điền-giá-tính-amount--vat)
6. [SalesInvoice — Posting](#6-salesinvoice--posting)
7. [Giá vốn hàng bán — average costing](#7-giá-vốn-hàng-bán--average-costing)
8. [AccumulationRegister Sales và CustomerBalance](#8-accumulationregister-sales-và-customerbalance)
9. [Các report của phân hệ (DCS)](#9-các-report-của-phân-hệ-dcs)
10. [Print form SalesInvoice qua SSL Print](#10-print-form-salesinvoice-qua-ssl-print)
11. [Gợi ý mở rộng cho nhóm sinh viên phân hệ Bán hàng](#11-gợi-ý-mở-rộng-cho-nhóm-sinh-viên-phân-hệ-bán-hàng)
12. [Những điểm lạ / cần lưu ý trong code Jet](#12-những-điểm-lạ--cần-lưu-ý-trong-code-jet)

---

## 1. Thành phần của Subsystem Sales

Subsystem `Sales` (xem Bài 9 về Subsystem) có 3 subsystem con: `Sales`, `Catalogs`, `Pricing`. Nội dung `<Content>` theo từng file XML:

| Subsystem | Member objects |
|---|---|
| `Sales` (gốc) — `cf/Subsystems/Sales.xml` | `AccumulationRegister.Sales`, `AccumulationRegister.CustomerBalance`, `Report.Sales`, `Report.CustomerBalance`, `Report.ProfitOnSales`, `Report.PriceList`, `Role.UseSales`, `CommonCommand.AdditionalReportsSales`, `CommonCommand.AdditionalDataProcessorsSales`, `CommonCommand.ReportPanelSales` |
| `Sales.Sales` — `cf/Subsystems/Sales/Subsystems/Sales.xml` | `Document.SalesInvoice` |
| `Sales.Catalogs` — `.../Subsystems/Catalogs.xml` | `Catalog.Counterparties`, `Catalog.Products`, `Catalog.Units` |
| `Sales.Pricing` — `.../Subsystems/Pricing.xml` | `Catalog.PriceTypes`, `DataProcessor.PricesSetup`, `CommonModule.PriceManagementServerCall`, `InformationRegister.Prices` |

Lưu ý:
- `Catalog.Counterparties` cũng nằm trong `Purchases/Subsystems/Catalogs.xml` — một catalog có thể thuộc nhiều subsystem. Nhóm Bán và nhóm Mua **dùng chung** Counterparties, `Products`.
- `Document.SalesInvoice` còn ghi vào `AccumulationRegister.InventoryInWarehouses` và `InventoryCost` — hai register này **không** thuộc Subsystem Sales (thuộc phân hệ kho). Khi sửa posting của SalesInvoice, nhóm Bán chạm vào dữ liệu của nhóm Kho.
- `Document.PricesSetupAuxiliary` không nằm trong Sales mà trong `Subsystems/InternalSubsystem.xml` (subsystem ẩn) — xem mục 3.
- `CommonCommand.ReportPanelSales` chỉ gọi `ReportsOptionsClient.ShowReportBar("Sales", ExecutionParameters)` (module SSL).

### Role UseSales

`Role.UseSales` (`cf/Roles/UseSales/Ext/Rights.xml`, xem Bài 20): `Document.SalesInvoice` đủ quyền (gồm Posting, UndoPosting, InteractiveChangeOfPosted); `AccumulationRegister.Sales`, `CustomerBalance` chỉ **Read, View** (register chỉ được ghi qua posting); `InformationRegister.Prices` Read/Update/Edit; các catalog `PriceTypes`, `Counterparties`, `Products`, `Units` đọc/ghi; `DataProcessor.PricesSetup` Use; `Sequence.InventoryCostRecalculation` Read/Update; 4 report của phân hệ và `Dashboard` Use. Khi thêm object mới vào phân hệ, nhớ thêm quyền vào `UseSales`, nếu không user chỉ có role này sẽ không thấy object.

---

## 2. Catalog PriceTypes và Counterparties (phía khách hàng)

### Catalog PriceTypes

Catalog rất đơn giản: không hierarchy, `CodeLength` = 0 (không có Code), `DescriptionLength` = 50. **Không có attribute riêng** nào ngoài tabular section `AdditionalAttributes` (của SSL Properties). Không có object module / manager module. Nghĩa là một "loại giá" (bán lẻ, bán buôn…) chỉ là một tên; giá cụ thể nằm ở `InformationRegister.Prices` (mục 3).

[suy luận] PriceTypes không có Currency hay cờ "giá đã gồm VAT" — giá trong `Prices` được hiểu là giá theo presentation currency, chưa gồm VAT (VAT cộng thêm trong document, xem mục 5).

### Catalog Counterparties — phần dùng cho bán hàng

Hierarchical, `CodeLength` 9, `DescriptionLength` 25. Attribute (cấp header): `Customer` (Boolean), `Supplier` (Boolean), `LegalName`, `TIN`, `PriceType` (CatalogRef.PriceTypes), `IsIndividual`. Tabular section: `AdditionalAttributes`, `ContactInformation` (của SSL ContactInformation).

Hai điểm gắn với bán hàng:

1. **Cờ `Customer`** — attribute `Customer` của `SalesInvoice` có Choice parameter `Filter.Customer = true` (trong `cf/Documents/SalesInvoice.xml`), nên khi chọn khách hàng chỉ hiện counterparty có cờ `Customer`. Command `Customers` của catalog mở list form với tham số lọc (`cf/Catalogs/Counterparties/Commands/Customers/Ext/CommandModule.bsl`: `FormParameters.Insert("Customer", True)` rồi `OpenForm("Catalog.Counterparties.ListForm", FormParameters, ...)`.)

List form đọc tham số `Customer`/`Supplier` trong `OnCreateAtServer` và đặt filter cố định cho dynamic list (`SetFilterCustomersSuppliers`, dùng `CommonClientServer.ChangeFilterItems` của SSL).

2. **`PriceType` mặc định của khách** — khi chọn khách trong `SalesInvoice`, form lấy `PriceType` của khách để điền lại giá (mục 5).

Ngoài ra, item form của Counterparties có command `Report.Sales.Command.OpenSalesReport` (panel "See also"), mở report Sales lọc theo khách — xem mục 9.

---

## 3. Giá bán: InformationRegister Prices — ghi giá và đọc giá

### Cấu trúc register

`InformationRegister.Prices` (xem Bài 12 — periodic information register):
- `InformationRegisterPeriodicity` = **Day**, `WriteMode` = **Independent** (không có recorder — không document nào post vào đây).
- Dimensions: `PriceType` (CatalogRef.PriceTypes), `Product` (CatalogRef.Products).
- Resource: `Price` (Number).
- Không có module BSL; có `RecordForm`, `ListForm`.

Vì Independent nên user có thể sửa trực tiếp qua list form của register, hoặc qua data processor `PricesSetup` (cách chính).

### Ghi giá: DataProcessor PricesSetup

Command `PricesSetup` mở form của data processor. Form có các form attribute: `PriceType`, `EffectiveDate`, `ProductPrices` (ValueTable: Product, CurrentPrice, NewPrice), `SourcePriceType`, `PriceAdjustmentMethod`, `AdjustmentPercent`, `AdjustmentAmount`… Luồng làm việc:

1. **Fill in** (`FillInProcessingAtServer`) — chọn "source price type", lấy giá hiện hành bằng `InformationRegister.Prices.SliceLast(&Period, PriceType = &PriceTypeToCopy)` làm `NewPrice`, LEFT JOIN với `SliceLast(&Period, PriceType = &PriceType)` làm `CurrentPrice`.
Ý nghĩa: có thể **sao chép** bảng giá từ loại giá khác (ví dụ lấy giá bán buôn làm gốc cho giá bán lẻ), cột `CurrentPrice` luôn là giá hiện tại của `PriceType` đích.

2. **Apply new prices** — tăng/giảm theo % hoặc số tiền (`IncByPercent`, `DecByPercent`, `IncByAmount`, `DecByAmount`), chạy hoàn toàn ở client trên `ProductPrices` (`ModifyProductPrices`), giá âm bị đưa về 0.

3. **Set** — ghi vào register bằng **RecordSet** (Bài 12). Batch query (`ResultsArray[2]`) báo sản phẩm trùng và hủy, rồi ghi các bản ghi `Price > 0` (`ResultsArray[3]`):

Nguồn: Jet — cf/DataProcessors/PricesSetup/Forms/Form/Ext/Form/Module.bsl
```bsl
	Query.SetParameter("ProductTable", ProductPrices.Unload());
	
	ResultsArray = Query.ExecuteBatch();
	// ...
	
	ResultTable = ResultsArray[3].Unload();
	If ResultTable.Count() > 0 Then
		RecordSet = InformationRegisters.Prices.CreateRecordSet();
		RecordSet.Filter.Period.Set(EffectiveDate);
		RecordSet.Filter.PriceType.Set(PriceType);
		RecordSet.Load(ResultTable);
		RecordSet.Write();
	EndIf;
```
Điểm quan trọng: filter của RecordSet chỉ có `Period` + `PriceType` (không có `Product`), nên `Write()` **thay thế toàn bộ** giá của loại giá đó tại ngày đó. Vì vậy trước khi ghi, `SetPrices` gọi `CheckPricesExist()` và hỏi user nếu ngày đó đã có giá cho sản phẩm **không có** trong danh sách ("Setting the new prices will delete them. Continue?").

Lưu ý: query truyền cả ValueTable `&ProductTable` làm nguồn dữ liệu (`FROM &ProductTable AS ProductTable`) — kỹ thuật dùng value table làm tham số query (xem Bài 10, temporary tables).

### Document PricesSetupAuxiliary — chỉ để import từ file

`Document.PricesSetupAuxiliary`: `Posting` = **Deny**, có tabular section `ProductPrices` (Product, CurrentPrice, NewPrice) và template `LoadingFromFile`. Không ai tạo document này. Nó chỉ tồn tại vì subsystem SSL `ImportDataFromFile` cần một tabular section thật (có template và manager module) để làm "khuôn" import. Form `PricesSetup` dùng nó như sau:

Nguồn: Jet — cf/DataProcessors/PricesSetup/Forms/Form/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure ImportPricesFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "PricesSetupAuxiliary.ProductPrices";
	ImportParameters.Title = NStr("en = 'Import prices from file'");
	
	CallbackDescription = New CallbackDescription("ImportPricesFromFileEnd", ThisObject);
	
	ImportDataFromFileClient.ShowImportForm(ImportParameters, CallbackDescription);
	
EndProcedure
```
Manager module của `PricesSetupAuxiliary` cài đặt `MapDataToImport` (tìm `Products` theo `Description`, báo ambiguity nếu trùng tên) và `FillInListOfAmbiguities` (gọi `ImportDataFromFileJet`).

### Đọc giá: PriceManagementServerCall + PriceManagementClient

Hai common module của Jet:
- `PriceManagementServerCall` — flag Server + **ServerCall** = true (gọi được từ client, xem Bài 7/14).
- `PriceManagementClient` — flag ClientManagedApplication.

Đọc giá **một** sản phẩm:

Nguồn: Jet — cf/CommonModules/PriceManagementServerCall/Ext/Module.bsl
```bsl
Function GetProductPriceByPriceType(DataStructure) Export
	
	Price = 0;
	
	If Not (ValueIsFilled(DataStructure.Product) And ValueIsFilled(DataStructure.PriceType)) Then
		Return Price;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	PricesSliceLast.Price * &DocumentRepetition / &DocumentRate AS Price
	|FROM
	|	InformationRegister.Prices.SliceLast(
	|			&PriceDate,
	|			PriceType = &PriceType
	|				AND Product = &Product) AS PricesSliceLast";
	
	Query.SetParameter("PriceDate",				BegOfDay(DataStructure.Date));
	Query.SetParameter("Product",				DataStructure.Product);
	Query.SetParameter("PriceType",				DataStructure.PriceType);
	Query.SetParameter("DocumentRate",			?(DataStructure.ExchangeRate = 0, 1, DataStructure.ExchangeRate));
	Query.SetParameter("DocumentRepetition",	?(DataStructure.Multiplier = 0, 1, DataStructure.Multiplier));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Price = Selection.Price;
	EndIf;
	
	Return Price;
	
EndFunction
```
Giải thích:
- `SliceLast(&PriceDate, <điều kiện>)` — lát cắt cuối: giá có hiệu lực gần nhất **tính đến** ngày `&PriceDate` (Bài 12). Điều kiện filter đặt **trong tham số** virtual table, không đặt ở `WHERE` — đúng khuyến nghị hiệu năng.
- `BegOfDay(...)`: register có periodicity Day nên lấy đầu ngày của document.
- `* &DocumentRepetition / &DocumentRate`: đổi giá (presentation currency) sang tiền tệ document. Nếu document bằng ngoại tệ, rate = tỷ giá, giá được chia cho tỷ giá.
- `SELECT ALLOWED`: chỉ trả bản ghi user có quyền đọc (Bài 20).

Đọc giá **nhiều** sản phẩm cùng lúc — `GetTabularSectionPricesByPriceType`, trả về `Map` Product → Price; sản phẩm không có giá → 0 (tìm trong `PriceTable` có index theo `Product`):

Nguồn: Jet — cf/CommonModules/PriceManagementServerCall/Ext/Module.bsl
```bsl
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	PricesSliceLast.Product AS Product,
	|	PricesSliceLast.Price * &DocumentRepetition / &DocumentRate AS Price
	|FROM
	|	InformationRegister.Prices.SliceLast(
	|			&PriceDate,
	|			PriceType = &PriceType
	|				AND Product IN (&ProductArray)) AS PricesSliceLast";
	// ...
	PriceTable = Query.Execute().Unload();
	PriceTable.Indexes.Add("Product");
	// ...
```

Phía client, `RefillTabularSectionPricesByPriceType` đóng gói `Date`, `PriceType`, `ExchangeRate`, `Multiplier` của document vào Structure, gom các `Product` không trùng vào `ProductArray`, gọi server **một lần**, rồi điền giá và tính lại tiền cho từng dòng:

Nguồn: Jet — cf/CommonModules/PriceManagementClient/Ext/Module.bsl
```bsl
Procedure RefillTabularSectionPricesByPriceType(Form, TabularSectionName = "Inventory") Export
	
	Object = Form.Object;
	ProductArray = New Array;
	// ...
	DataStructure.Insert("ProductArray", ProductArray);
	
	ProductPriceMap = PriceManagementServerCall.GetTabularSectionPricesByPriceType(DataStructure);
	
	For Each ProductPriceItem In ProductPriceMap Do
		
		FilterStructure = New Structure("Product", ProductPriceItem.Key);
		RowArray = Object[TabularSectionName].FindRows(FilterStructure);
		For Each Row In RowArray Do
			Row.Price = ProductPriceItem.Value;
			InventoryTabularSectionClientServer.CalculateAmount(Row);
		EndDo;
		
	EndDo;
	
EndProcedure
```
Đây là mẫu tốt để dạy "tránh gọi server trong vòng lặp" (Bài 7): một server call cho cả bảng.

---

## 4. Document SalesInvoice — metadata

Nguồn: `cf/Documents/SalesInvoice.xml`.

Thuộc tính chính của document:
- Numbering: `NumberType` String, `NumberLength` 9, `NumberPeriodicity` Year, `Autonumbering`, `CheckUnique` (Bài 4).
- `Posting` Allow, `RealTimePosting` **Deny** (không có chế độ post real-time — Bài 11), `RegisterRecordsDeletion` AutoDeleteOff, `RegisterRecordsWritingOnPost` WriteSelected.
- **Post in privileged mode** = true, **Unpost in privileged mode** = true — nhờ đó Role `UseSales` chỉ cần Read trên các register mà posting vẫn ghi được.
- Register records: `AccumulationRegister.Sales`, `CustomerBalance`, `InventoryInWarehouses`, `InventoryCost`.
- Thuộc Sequence `InventoryCostRecalculation` (mục 7).
- Là "based on" cho `CashReceipt` và `BankReceipt` (thu tiền dựa trên hóa đơn — khai báo trong `<BasedOn>` của hai document đó).

Header attributes:

| Attribute | Type | Ghi chú |
|---|---|---|
| `Customer` | CatalogRef.Counterparties | FillChecking ShowError; choice parameter `Filter.Customer = true` |
| `Warehouse` | CatalogRef.Warehouses | ShowError |
| `Currency` | CatalogRef.Currencies | ShowError |
| `ExchangeRate`, `Multiplier` | Number | tỷ giá và bội số |
| `PriceType` | CatalogRef.PriceTypes | |
| `Comment` | String | |
| `Author` | CatalogRef.Users | điền trong `Filling` |
| `Total` | Number | tổng tiền, tính trong `BeforeWrite` |
| `BankAccount` | CatalogRef.BankAccounts | `BankReceipt.Filling` đọc field này khi tạo dựa trên hóa đơn |
| `ExemptFromVAT` | Boolean | miễn VAT |

Tabular sections:
- `Inventory`: `Product`, `Quantity`, `Price`, `Amount`, `VATRate` (CatalogRef.VATRates), `VATAmount`, `Total`.
- `AdvanceClearing` (cấn trừ tiền khách trả trước): `Document` (DocumentRef.CashReceipt / BankReceipt), `Amount`, `AmountCur`.
- `AdditionalAttributes` (SSL Properties).

Forms: `DocumentForm`, `ListForm`, `ChoiceForm`. Templates: `PF_MXL_SalesInvoice` (SpreadsheetDocument), `PrintData` (DataCompositionSchema), `LoadingFromFile`.

### Object module

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
EndProcedure
```
Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Total = Inventory.Total("Total");
	
EndProcedure
```
`ObjectFillingJet.FillDocument` (module của Jet) điền `Currency` = presentation currency (tỷ giá 1/1) nếu chưa có, và `Author` = `Users.AuthorizedUser()` (SSL).

---

## 5. SalesInvoice — form: tự điền giá, tính Amount / VAT

Nguồn chung: `cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl`. Form chỉ có 2 form attribute: `Object` và `PresentationCurrency`. Bảng sự kiện được gắn trong Form.xml:

| Item | Event | Handler |
|---|---|---|
| Customer | OnChange | `CustomerOnChange` |
| PriceType | OnChange | `PriceTypeOnChange` |
| Currency | OnChange | `CurrencyOnChange` |
| ExemptFromVAT | OnChange | `ExemptFromVATOnChange` |
| Inventory.Product / Quantity / Price / Amount / VATRate | OnChange | `InventoryProductOnChange`, `InventoryQuantityOnChange`, `InventoryPriceOnChange`, `InventoryAmountOnChange`, `InventoryVATRateOnChange` |
| AdvanceClearing.Amount / AmountCur | OnChange | `AdvanceClearingAmountOnChange`, `AdvanceClearingAmountCurOnChange` |

### Chọn khách → lấy PriceType của khách → điền lại giá

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure CustomerOnChange(Item)
	
	PriceType = GetCustomerPriceType(Object.Customer);
	If ValueIsFilled(PriceType) Then
		Object.PriceType = PriceType;
		PriceManagementClient.RefillTabularSectionPricesByPriceType(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTypeOnChange(Item)
	
	If ValueIsFilled(Object.PriceType) Then
		PriceManagementClient.RefillTabularSectionPricesByPriceType(ThisObject);
	EndIf;
	
EndProcedure
```
`GetCustomerPriceType` là `&AtServerNoContext`, trả về `Common.ObjectAttributeValue(Customer, "PriceType")` (hàm SSL) — non-context vì chỉ đọc một attribute của reference, không cần dữ liệu form (Bài 7).
`&AtServerNoContext` vì chỉ cần đọc một attribute của reference, không cần dữ liệu form (Bài 7 — non-context call nhẹ hơn). `Common.ObjectAttributeValue` là hàm SSL.

### Chọn sản phẩm → lấy VATRate + giá

`InventoryProductOnChange` (&AtClient) đóng gói `Product`, `PriceType`, `Date`, `ExchangeRate`, `Multiplier`, `ExemptFromVAT` vào `DataStructure`, gọi `GetProductData(DataStructure)`, rồi `FillPropertyValues(CurrentData, DataStructure)` và `InventoryTabularSectionClientServer.CalculateAmount(CurrentData)`.

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServerNoContext
Procedure GetProductData(DataStructure)
	
	ProductAttributes = New Structure;
	ProductAttributes.Insert("VATRate", Catalogs.VATRates.EmptyRef());
	
	If ValueIsFilled(DataStructure.Product) Then
		ProductAttributes = Common.ObjectAttributesValues(DataStructure.Product, "VATRate");
	EndIf;
	
	If DataStructure.Property("ExemptFromVAT") And DataStructure.ExemptFromVAT Then
		DataStructure.Insert("VATRate", Catalogs.VATRates.GetExemptFromVATRate());
	Else
		DataStructure.Insert("VATRate", ProductAttributes.VATRate);
	EndIf;
	
	DataStructure.Insert("Quantity", 1);
	
	Price = PriceManagementServerCall.GetProductPriceByPriceType(DataStructure);
	DataStructure.Insert("Price", Price);
	
EndProcedure
```
Mẫu "đóng gói tham số vào Structure → 1 server call → `FillPropertyValues` vào dòng hiện tại" là mẫu chuẩn nên dạy lại. Lưu ý `Quantity` được đặt = 1 mỗi khi đổi sản phẩm.

### Tính Amount, VAT, Total — InventoryTabularSectionClientServer

Module của Jet, flag Client + Server (không ServerCall) — chạy được ở cả hai phía (Bài 14), dùng chung cho `SalesInvoice` và `SupplierInvoice`:

Nguồn: Jet — cf/CommonModules/InventoryTabularSectionClientServer/Ext/Module.bsl
```bsl
Procedure CalculateAmount(TabSectionRow) Export
	
	TabSectionRow.Amount = TabSectionRow.Quantity * TabSectionRow.Price;
	CalculateVATAmountAndTotal(TabSectionRow);
	
EndProcedure
```
Nguồn: Jet — cf/CommonModules/InventoryTabularSectionClientServer/Ext/Module.bsl
```bsl
Procedure CalculateVATAmountAndTotal(TabSectionRow) Export
	
	VATRate = JetServerCall.GetVATRateValue(TabSectionRow.VATRate);
	TabSectionRow.VATAmount = TabSectionRow.Amount * VATRate / 100;
	TabSectionRow.Total = TabSectionRow.Amount + TabSectionRow.VATAmount;
	
EndProcedure
```
Công thức: `Amount = Quantity × Price`; `VATAmount = Amount × Rate / 100`; `Total = Amount + VATAmount` — tức giá **chưa gồm** VAT. Giá trị `Rate` lấy qua `JetServerCall.GetVATRateValue` → `JetCached.GetVATRateValue` (module có reuse return values — Bài 14), nên gọi lặp với cùng VATRate không tốn thêm server call trong phiên.

Các handler còn lại: `InventoryAmountOnChange` tính ngược `Price = Round(Amount / Quantity, 2)` (khi `Quantity <> 0`) rồi gọi `CalculateVATAmountAndTotal`. `Quantity`/`Price` đổi → `CalculateAmount`; `VATRate` đổi → `CalculateVATAmountAndTotal`.

### Miễn VAT

`ExemptFromVATOnChange` gọi `FillVATRateByVATExemption()` (&AtServer): nếu miễn VAT thì mọi dòng nhận `Catalogs.VATRates.GetExemptFromVATRate()`, `VATAmount = 0`, `Total = Amount`; nếu bỏ miễn thì lấy lại `InventoryRow.Product.VATRate` và gọi `CalculateVATAmountAndTotal`.
`FormManagement()` (client) ẩn các cột `InventoryVATRate`, `InventoryVATAmount`, `InventoryTotal`… khi `ExemptFromVAT`, và khóa `ExchangeRate`/`Multiplier` khi `Currency` = presentation currency.

### Kiểm tra trước khi ghi và cấn trừ tạm ứng

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.Inventory.Total("Total") < Object.AdvanceClearing.Total("AmountCur") Then
		MessageText = NStr("en = 'The invoice amount is less than the clearing amount.'");
		Common.MessageToUser(MessageText,,,, Cancel);
	EndIf;
	// ...
```
Command `SelectAdvances` mở `CommonForm.SelectAdvances` (dùng chung với SupplierInvoice, tham số `IsCustomerAdvance = True`) và trao đổi bảng `AdvanceClearing` qua temporary storage (`PutToTempStorage` / `GetFromTempStorage` — Bài 19).

[suy luận] Kiểm tra này nằm ở **form** (`FillCheckProcessingAtServer`), không ở object module — nên khi ghi document bằng code (không qua form) thì kiểm tra không chạy. Đây là điểm sinh viên có thể cải tiến (chuyển sang `FillCheckProcessing` của object module — Bài 12).

---

## 6. SalesInvoice — Posting

### Posting handler

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Document data initialization.
	Documents.SalesInvoice.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	
	// Movements on the Sales register
	PostingManagement.ReflectSales(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the InventoryInWarehouses register
	PostingManagement.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the CustomerBalance register
	PostingManagement.ReflectCustomerBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the InventoryCost register
	PostingManagement.ReflectInventoryCost(AdditionalProperties, RegisterRecords, Cancel);
	
	// Writing of the records sets.
	PostingManagement.WriteRecordSets(ThisObject);
	
	// Negative balance control
	AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl(Ref, AdditionalProperties, Cancel);
	
EndProcedure
```
`UndoPosting` gọi `InitializeAdditionalPropertiesForPosting` → `PrepareRecordSetsForWriting` → `WriteRecordSets` (ghi record set rỗng) → `NegativeBalanceControl`.

Kiến trúc posting của Jet (khác cách "duyệt tabular section, `RegisterRecords.X.Add()`" của Bài 11):

1. `PostingManagement.InitializeAdditionalPropertiesForPosting` tạo trong `AdditionalProperties` một Structure `TableForRegisterRecords`, một Structure `ForPosting` chứa `TempTablesManager`, và `DocumentMetadata`.
2. **Manager module** `InitializeDocumentData` chạy **một batch query** sinh sẵn bảng bản ghi cho từng register, cất vào `TableForRegisterRecords`.
3. `PrepareRecordSetsForWriting` xóa record set cũ và đánh dấu `Write = True` cho register mà document đã từng có bản ghi (để ghi đè thành rỗng nếu lần này không còn).
4. `ReflectXxx` chỉ `Load()` bảng có sẵn vào `RegisterRecords.Xxx`.
5. `WriteRecordSets` ghi các record set có `Write = True`, truyền `ForPosting` vào `RecordSet.AdditionalProperties` (để record set module của `InventoryInWarehouses` dùng chung TempTablesManager).
6. Kiểm soát âm kho sau khi ghi.

Nguồn: Jet — cf/CommonModules/PostingManagement/Ext/Module.bsl
```bsl
Procedure ReflectSales(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSales = AdditionalProperties.TableForRegisterRecords.TableSales;
	
	If Cancel Or TableSales.Count() = 0 Then
		Return;
	EndIf;
	
	SalesRecord = RegisterRecords.Sales;
	SalesRecord.Write = True;
	SalesRecord.Load(TableSales);
	
EndProcedure
```
`Load()` cần tên cột của bảng trùng tên dimension/resource/standard field của register (`RecordType`, `Period`…) (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant) — vì vậy các query trong `InitializeDocumentData` đặt alias đúng tên field register.

### InitializeDocumentData — batch query

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
Procedure InitializeDocumentData(SalesInvoiceRef, AdditionalProperties) Export
	
	DocumentObject = SalesInvoiceRef.GetObject();
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("AccumulationRegister.InventoryCost");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = DocumentObject.Inventory;
	LockItem.UseFromDataSource("Product", "Product");
	LockItem.SetValue("Warehouse", DocumentObject.Warehouse);
	DataLock.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SalesInvoice.Ref AS Ref,
	// ...
	|INTO DocumentHeader
	// ...
	|SELECT
	|	DocumentHeader.Date AS Period,
	|	DocumentHeader.Customer AS Counterparty,
	|	DocumentHeader.Warehouse AS Warehouse,
	|	DocumentHeader.Ref AS Document,
	|	SalesInvoiceInventory.Product AS Product,
	|	SalesInvoiceInventory.Quantity AS Quantity,
	|	SalesInvoiceInventory.Amount * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS Amount,
	|	SalesInvoiceInventory.VATAmount * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS VATAmount,
	|	SalesInvoiceInventory.Total * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS Total
	|INTO DocumentInventory
	|FROM
	|	DocumentHeader AS DocumentHeader
	|		INNER JOIN Document.SalesInvoice.Inventory AS SalesInvoiceInventory
	|		ON DocumentHeader.Ref = SalesInvoiceInventory.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentInventory.Period AS Period,
	|	DocumentInventory.Warehouse AS Warehouse,
	|	DocumentInventory.Product AS Product,
	|	SUM(DocumentInventory.Quantity) AS Quantity
	|INTO ProductTable
	|FROM
	|	DocumentInventory AS DocumentInventory
	|		INNER JOIN Catalog.Products AS Products
	|		ON DocumentInventory.Product = Products.Ref
	|			AND (Products.ProductType = VALUE(Enum.ProductTypes.Inventory))
	|
	|GROUP BY
	|	DocumentInventory.Product,
	|	DocumentInventory.Period,
	|	DocumentInventory.Warehouse
	|;
	// ...
```
Các bước của batch (đánh số theo chỉ số `QueryResult[i]`):

| # | Kết quả | Dùng làm |
|---|---|---|
| 0 | `DocumentHeader` (temp) | header |
| 1 | `DocumentInventory` (temp) | dòng hàng, **đã quy đổi sang presentation currency** (`* ExchangeRate / Multiplier`) |
| 2 | `ProductTable` (temp) | chỉ hàng `ProductType = Inventory` (loại `Service` không trừ kho, không tính giá vốn) |
| 3 | `DocumentAdvanceClearing` (temp) | dòng cấn trừ tạm ứng |
| 4 | `InventoryCostBalance` (temp) | tồn giá vốn (mục 7) |
| 5 | `InventoryCostTable` (temp) | tồn giá vốn đã cộng gộp |
| 6 | bảng `Sales` | → `TableSales` |
| 7 | bảng `InventoryInWarehouses` | → `TableInventoryInWarehouses` |
| 8 | bảng `CustomerBalance` | → `TableCustomerBalance` |
| 9 | bảng `InventoryCost` | → `TableInventoryCost` |

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
	Query.SetParameter("Ref", SalesInvoiceRef);
	Query.SetParameter("PointInTime", New Boundary(DocumentObject.PointInTime(), BoundaryType.Including));
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableSales", QueryResult[6].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[7].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableCustomerBalance", QueryResult[8].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[9].Unload());
```
Nếu thêm/bớt một query trong batch, **mọi chỉ số `QueryResult[i]` phía sau phải sửa theo** — lỗi rất hay gặp khi mở rộng.

### Bản ghi Sales và InventoryInWarehouses

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
	|
	|GROUP BY
	|	DocumentInventory.Product,
	|	DocumentInventory.Counterparty,
	|	DocumentInventory.Period,
	|	DocumentInventory.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ProductTable.Period AS Period,
	|	ProductTable.Warehouse AS Warehouse,
	|	ProductTable.Product AS Product,
	|	ProductTable.Quantity AS Quantity
	|FROM
	|	ProductTable AS ProductTable
	|;
```
`Sales` là register Turnovers nên không có `RecordType`. `Sales` nhận **cả dịch vụ** (lấy từ `DocumentInventory`), còn `InventoryInWarehouses` chỉ nhận hàng tồn kho (từ `ProductTable`) với `Expense`.

### Bản ghi CustomerBalance

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
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
	// ...
```
Ba phần:
1. `Receipt` / `Liability` / Document = hóa đơn, Amount = `Total` (gồm VAT): khách nợ thêm.
2. `Receipt` / `Advance` / Document = phiếu thu tạm ứng: "trả lại" số dư tạm ứng (tạm ứng được ghi âm bởi phiếu thu, xem mục 8).
3. (phần thứ ba của UNION, đã lược) `Expense` / `Liability` / Document = `InvoiceDocument` (hóa đơn): giảm nợ của hóa đơn đúng bằng số tạm ứng đã cấn trừ.

---

## 7. Giá vốn hàng bán — average costing

`AccumulationRegister.InventoryCost` (Balance): dimensions `Product`, `Warehouse`; resources `Quantity`, `Amount`. `SupplierInvoice` ghi `Receipt` với `Amount` = giá mua (đã quy đổi); `SalesInvoice` ghi `Expense` với giá vốn tính theo **bình quân gia quyền tại thời điểm bán** (moving average theo Product + Warehouse).

### Bước 1 — khóa dữ liệu

Đầu `InitializeDocumentData` đặt managed lock `Exclusive` trên `AccumulationRegister.InventoryCost` theo từng `Product` của tabular section và `Warehouse` của document (code ở mục 6). Mục đích [suy luận]: hai hóa đơn bán cùng sản phẩm/kho post đồng thời không đọc cùng một số tồn để tính giá vốn.

### Bước 2 — đọc tồn giá vốn tại thời điểm document

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
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
```
- `&PointInTime` = `New Boundary(DocumentObject.PointInTime(), BoundaryType.Including)` — tồn **bao gồm** cả bản ghi của chính document (Bài 11, PointInTime/Boundary).
- Vì Including, khi **re-post** một hóa đơn đã post, tồn đã bị trừ bởi bản ghi cũ của chính nó. Phần `UNION ALL ... WHERE InventoryCost.Recorder = &Ref` cộng ngược lại các bản ghi cũ (Expense lưu số dương trong bảng vật lý) để có tồn "trước khi bán".

  [suy luận] Cộng trực tiếp `Quantity`/`Amount` của bảng vật lý chỉ đúng vì mọi bản ghi `InventoryCost` của SalesInvoice đều là `Expense`.
- Điều kiện `(Product, Warehouse) IN (SELECT ...)` đặt trong tham số virtual table để chỉ đọc đúng cặp cần thiết.

### Bước 3 — gộp và tính giá vốn

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
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
```
Công thức: **Giá vốn = Amount tồn × Số lượng bán / Số lượng tồn**.
- Không có tồn → giá vốn 0 (tránh chia cho 0).
- Bán hết toàn bộ tồn → lấy nguyên `Amount` tồn (tránh lệch làm tròn để lại số dư "rác").
- Ngược lại làm tròn 2 chữ số bằng `CAST(... AS NUMBER(15, 2))`.

### Sequence InventoryCostRecalculation

Giá vốn tính lúc post phụ thuộc thứ tự thời gian. Nếu user post/sửa một chứng từ **lùi ngày**, giá vốn của các hóa đơn sau đó bị sai. Jet dùng metadata **Sequence** `InventoryCostRecalculation` (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant) với:
- Documents: `InventoryTransfer`, `InventoryWriteOff`, `SalesInvoice`; RegisterRecords: `InventoryCost`; `MoveBoundaryOnPosting` = Move.

DataProcessor `InventoryCostRecalculation` (thuộc phân hệ kho) so sánh biên của sequence (`GetBound()`) với bản ghi `Expense` cuối cùng và gọi `Sequences.InventoryCostRecalculation.Restore()` — [suy luận] re-post lại các chứng từ sau biên theo thứ tự thời gian.
Data processor này cũng thêm mục "It may be necessary to recalculate inventory costs" vào To-do list của SSL (`OnFillToDoList` trong manager module của nó).

### Kiểm soát âm kho

`AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl` (manager module register `InventoryInWarehouses`, thuộc phân hệ kho) dùng temp table `InventoryInWarehousesChange` mà **record set module** của register tạo ra trong `BeforeWrite`/`OnWrite` (qua `AdditionalProperties.ForPosting.TempTablesManager`), rồi join với `InventoryInWarehouses.Balance(, )` lọc `QuantityBalance < 0` và báo "Insufficient quantity on %1" với `Cancel = True`.
Lưu ý: kiểm soát này chỉ trên `InventoryInWarehouses` (số lượng), không kiểm `InventoryCost`.

---

## 8. AccumulationRegister Sales và CustomerBalance

Cả hai không có module BSL (không có thư mục `cf/AccumulationRegisters/Sales/`, `.../CustomerBalance/`).

### AccumulationRegister Sales — kind **Turnovers**

| Loại | Field | Type |
|---|---|---|
| Dimension | `Counterparty` | CatalogRef.Counterparties |
| Dimension | `Product` | CatalogRef.Products |
| Dimension | `SalesDocument` | DocumentRef.SalesInvoice |
| Resource | `Quantity`, `Amount`, `VATAmount` | Number |

Chỉ `SalesInvoice` ghi vào. `Amount` = doanh thu chưa VAT, đã quy đổi presentation currency. [suy luận] Dimension `SalesDocument` chỉ có type `DocumentRef.SalesInvoice` — nếu thêm document trả hàng hay bán lẻ ghi vào register này, phải mở rộng type của dimension.

### AccumulationRegister CustomerBalance — kind **Balance**

| Loại | Field | Type |
|---|---|---|
| Dimension | `LiabilityType` | EnumRef.LiabilityTypes (`Liability`, `Advance`) |
| Dimension | `Counterparty` | CatalogRef.Counterparties |
| Dimension | `Document` | DocumentRef.SalesInvoice, CashReceipt, BankReceipt |
| Resource | `Amount` | Number |

Ai ghi vào:
- `SalesInvoice`: như mục 6.
- `CashReceipt` / `BankReceipt` (phân hệ CashManagement) với operation `Customer`: `Expense`; nếu dòng thanh toán không chỉ định hóa đơn (`Document` rỗng) thì `LiabilityType` = `Advance` và `Document` = chính phiếu thu (`cf/Documents/CashReceipt/Ext/ManagerModule.bsl`).
Quy ước dấu [suy luận từ code + report]: số dư `Liability` dương = khách còn nợ; số dư `Advance` **âm** = khách đã trả trước (vì phiếu thu ghi `Expense` mà không có `Receipt` tương ứng). Report CustomerBalance đổi dấu `-AmountBalance` cho cột tạm ứng (mục 9).

---

## 9. Các report của phân hệ (DCS)

Cả 4 report chỉ có `MainDataCompositionSchema` (không form, không module — Bài 18). Mô tả report option được đặt trong `ReportsOptionsOverridable.CustomizeReportsOptions` (module SSL overridable, code Jet), bằng `ReportsOptions.OptionDetails(Settings, Metadata.Reports.<Report>, "<Option>")`. Các option `...Context` bị `Enabled = False`; [suy luận] chúng chỉ dùng khi mở từ command trên form khác (xem `OpenSalesReport` bên dưới), nên ẩn khỏi report panel.

### Report Sales

Settings variants: `Default`, `SalesContext`, `SalesByDate` (biểu đồ theo ngày), `SalesByProduct` (biểu đồ theo sản phẩm). Tham số `BeginOfPeriod` = `&ItmPeriod.StartDate`, `EndOfPeriod` = `&ItmPeriod.EndDate`. Total fields: `Sum(...)` cho Quantity, Amount, VATAmount, Total.

Nguồn: Jet — cf/Reports/Sales/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT
	SalesTurnovers.Recorder AS Recorder,
	SalesTurnovers.SecondPeriod AS SecondPeriod,
	// ...
	SalesTurnovers.YearPeriod AS YearPeriod,
	SalesTurnovers.Counterparty AS Counterparty,
	SalesTurnovers.Product AS Product,
	SalesTurnovers.SalesDocument AS SalesDocument,
	SalesTurnovers.QuantityTurnover AS Quantity,
	SalesTurnovers.AmountTurnover AS Amount,
	SalesTurnovers.VATAmountTurnover AS VATAmount,
	SalesTurnovers.AmountTurnover + SalesTurnovers.VATAmountTurnover AS Total
FROM
	AccumulationRegister.Sales.Turnovers(, , Auto, ) AS SalesTurnovers
```
`Turnovers(, , Auto, )`: để trống Begin/End để DCS tự gắn tham số `BeginOfPeriod`/`EndOfPeriod`; periodicity `Auto` cho phép DCS chọn nhóm theo ngày/tháng… tùy field user dùng (các field `DayPeriod`, `MonthPeriod`…).

Command `OpenSalesReport` (parameter type `CatalogRef.Counterparties`, group `FormNavigationPanelSeeAlso`) mở form report với `VariantKey` = `"SalesContext"`, `Filter` = `New Structure("Counterparty", CommandParameter)`, `GenerateOnOpen` = True.
`Report.CustomerBalance` có command `OpenCustomerBalanceReport` y hệt (option `CustomerBalanceContext`).

### Report PriceList

Tham số `Period`, `PriceType`; total `Min(Price)`.

Nguồn: Jet — cf/Reports/PriceList/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT
	PricesSliceLast.Product AS Product,
	PricesSliceLast.Price AS Price
FROM
	InformationRegister.Prices.SliceLast(&Period, PriceType = &PriceType) AS PricesSliceLast
```

### Report ProfitOnSales

Ghép giá vốn (Expense của `InventoryCost` do `SalesInvoice` ghi) với doanh thu (`Sales`):

Nguồn: Jet — cf/Reports/ProfitOnSales/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT ALLOWED
	InventoryCostTurnovers.Recorder AS Recorder,
	InventoryCostTurnovers.SecondPeriod AS SecondPeriod,
	// ...
	InventoryCostTurnovers.YearPeriod AS YearPeriod,
	InventoryCostTurnovers.Product AS Product,
	InventoryCostTurnovers.AmountExpense AS CostAmount,
	0 AS RevenueAmount
FROM
	AccumulationRegister.InventoryCost.Turnovers(, , Auto, ) AS InventoryCostTurnovers
WHERE
	InventoryCostTurnovers.Recorder REFS Document.SalesInvoice

UNION ALL

SELECT
	SalesTurnovers.Recorder,
	SalesTurnovers.SecondPeriod,
	// ...
	SalesTurnovers.YearPeriod,
	SalesTurnovers.Product,
	0,
	SalesTurnovers.AmountTurnover + SalesTurnovers.VATAmountTurnover
FROM
	AccumulationRegister.Sales.Turnovers(, , Auto, ) AS SalesTurnovers
```
(`// ...` là chỗ lược các field period giống hệt nhau.) Calculated field `Profit` = `RevenueAmount - CostAmount`; totals `Sum` cho cả ba.

Lưu ý: `REFS Document.SalesInvoice` (Bài 10) lọc riêng giá vốn do bán hàng, loại trừ Expense của `InventoryWriteOff`/`InventoryTransfer`. Xem thêm mục 12 về việc `RevenueAmount` **gồm VAT**.

### Report CustomerBalance

Tham số `Period` có expression: rỗng → `DateTime(3999,12,31)`, ngược lại → `DATEADD(EndOfPeriod(&Period, "Day"), "Second", 1)` (lấy số dư đến hết ngày được chọn). Variants: `CustomerBalance`, `CustomerBalanceContext`.

Nguồn: Jet — cf/Reports/CustomerBalance/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT
	CustomerBalance.LiabilityType AS LiabilityType,
	CustomerBalance.Counterparty AS Counterparty,
	CustomerBalance.Document AS Document,
	CASE
		WHEN CustomerBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Liability)
			THEN CustomerBalance.AmountBalance
		ELSE 0
	END AS AmountLiability,
	CASE
		WHEN CustomerBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
			THEN -CustomerBalance.AmountBalance
		ELSE 0
	END AS AmountAdvance,
	CASE
		WHEN CustomerBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Liability)
			THEN CustomerBalance.AmountBalance
		ELSE 0
	END - CASE
		WHEN CustomerBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
			THEN -CustomerBalance.AmountBalance
		ELSE 0
	END AS AmountTotal
FROM
	AccumulationRegister.CustomerBalance.Balance AS CustomerBalance
```
`AmountTotal` = nợ − tạm ứng = công nợ ròng của khách.

---

## 10. Print form SalesInvoice qua SSL Print

Print form dùng **subsystem Print của SSL** (Bài 22), nhưng kiểu "template + PrintData", **không có procedure `Print` riêng** trong manager module. Ba mảnh ghép:

**(1) Đăng ký object in** trong module SSL overridable `PrintManagementOverridable.OnDefinePrintSettings` (code Jet): `Settings.PrintObjects.Add(Documents.SalesInvoice);` (cùng các document khác của Jet).


**(2) Manager module** khai báo print command, với `PrintManager = "PrintManagement"` (tức SSL tự in) và `Id` = đường dẫn đầy đủ tới template:

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
// StandardSubsystems.Print
// ...
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure
// ...
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.Id = "Document.SalesInvoice.PF_MXL_SalesInvoice";
	PrintCommand.Presentation = NStr("en = 'Sales invoice'");
	
EndProcedure

// End StandardSubsystems.Print
```

**(3) Hai template**:
- `PF_MXL_SalesInvoice` (SpreadsheetDocument) — chứa text với tham số trong ngoặc vuông: `Invoice #[Number] date [Date]`, `[Company.LegalName]`, `[Customer.LegalName]`, `[Warehouse]`, `[Inventory.LineNumber]`, `[Inventory.Product]`, `[Inventory.Quantity]`, `[Inventory.Price]`, `[Inventory.Amount]`, `[Inventory.VATAmount]`, `[Inventory.Total]`, `[Total]`, `[CommonAttributes.CurrentUser]`, `[CommonAttributes.CurrentDate]`.
- `PrintData` (DataCompositionSchema) — cung cấp các field đó. SSL tìm template tên `"PrintData"` của object (`PrintManagement`, hàm `FieldsSourceDataCompositionSchemes`: `MetadataObject.Templates.Find("PrintData")`). Query của nó:

Nguồn: Jet — cf/Documents/SalesInvoice/Templates/PrintData/Ext/Template.xml
```bsl
SELECT
	SalesInvoice.Ref AS Ref,
	SalesInvoice.Number AS Number,
	SalesInvoice.Date AS Date,
	VALUE(Catalog.Companies.MainCompany) AS Company,
	SalesInvoice.Customer AS Customer,
	SalesInvoice.Warehouse AS Warehouse,
	// ...
	SalesInvoice.Total AS Total,
	SalesInvoice.Inventory.(
		LineNumber AS LineNumber,
		Product AS Product,
		Quantity AS Quantity,
		// ...
		Total AS Total
	) AS Inventory
FROM
	Document.SalesInvoice AS SalesInvoice
```
`Company` lấy từ predefined `Catalog.Companies.MainCompany` (Jet chỉ có một công ty). Tham số dạng `[Customer.LegalName]` là truy cập attribute qua dấu chấm của field reference.

Phía form: print command hiện trên form nhờ khối `// StandardSubsystems.AttachableCommands` (`AttachableCommands.OnCreateAtServer`, `Attachable_ExecuteCommand`…) trong `DocumentForm` và `ListForm` — đúng như quy trình Bài 22.

[suy luận] Vì layout nằm trong template + PrintData, user có thể sửa mẫu in bằng trình chỉnh template của SSL mà không cần developer; muốn thêm field (ví dụ địa chỉ khách) thì thêm vào query `PrintData` rồi đặt `[...]` trong template.

---

## 11. Gợi ý mở rộng cho nhóm sinh viên phân hệ Bán hàng

Các mục dưới đây là **gợi ý** (không có trong Jet), bám vào object/module có thật để sinh viên biết bắt đầu từ đâu. Cân nhắc làm bằng **Configuration extension** (Purpose = Customization hoặc Add-on — upgrade-safe customization, xem bài Extensions) nếu nhóm muốn giữ nguyên cấu hình gốc của Jet.

### Gợi ý 1 — Document SalesOrder (đơn đặt hàng của khách)

- Tạo `Document.SalesOrder` với header giống `SalesInvoice` (`Customer`, `Warehouse`, `Currency`, `ExchangeRate`, `Multiplier`, `PriceType`) và tabular section `Inventory` cùng tên cột → **tái dùng nguyên** `PriceManagementClient.RefillTabularSectionPricesByPriceType` (tham số `TabularSectionName` mặc định "Inventory") và `InventoryTabularSectionClientServer`.
- Thêm `Document.SalesOrder` vào `<BasedOn>` của `SalesInvoice`, viết nhánh `TypeOf(FillingData) = Type("DocumentRef.SalesOrder")` trong `Filling` của `SalesInvoice` (mẫu có sẵn: `Filling` của `CashReceipt` khi `FillingData` là `DocumentRef.SalesInvoice`). Giữ lời gọi `ObjectFillingJet.FillDocument`.
- Nâng cao: AccumulationRegister `SalesOrders` (Balance: `SalesOrder`, `Product`; resource `Quantity`) — SalesOrder ghi Receipt, SalesInvoice ghi Expense. Khi đó phải thêm attribute `SalesOrder` vào `SalesInvoice`, thêm register vào RegisterRecords, thêm một query trong `InitializeDocumentData` (**sửa lại chỉ số `QueryResult[i]`**), thêm `ReflectSalesOrders` vào `PostingManagement`.
- Nhớ: thêm vào Subsystem `Sales.Sales`, Role `UseSales`, Sequence nếu có ghi `InventoryCost` (SalesOrder thì không).

### Gợi ý 2 — Document CustomerReturn (khách trả hàng)

- Header: `Customer`, `Warehouse`, `Currency`…, thêm attribute `SalesInvoice` (DocumentRef.SalesInvoice). Based on `SalesInvoice`.
- Posting theo đúng kiến trúc `PostingManagement`: `Sales` ghi số **âm** (register Turnovers), `InventoryInWarehouses` `Receipt`, `CustomerBalance` `Expense` / `Liability` theo hóa đơn gốc.
- `InventoryCost` `Receipt` với giá vốn lấy từ bản ghi `Expense` của hóa đơn gốc (query `AccumulationRegister.InventoryCost` `WHERE Recorder = &SalesInvoice`), không lấy giá bán.
- Phải mở rộng type của dimension `Sales.SalesDocument` và `CustomerBalance.Document`; thêm document vào Sequence `InventoryCostRecalculation`; xem lại report `ProfitOnSales` (đang lọc `REFS Document.SalesInvoice`).

### Gợi ý 3 — Chiết khấu (discount) theo dòng

- Thêm cột `DiscountPercent`, `DiscountAmount` vào tabular section `Inventory` của `SalesInvoice`.
- Không sửa thẳng `InventoryTabularSectionClientServer.CalculateAmount` (đang dùng chung với `SupplierInvoice`); thay vào đó viết hàm riêng, hoặc trong extension dùng `&Around` trên `CalculateAmount` có kiểm tra cột tồn tại.
- Cập nhật `InventoryAmountOnChange` (tính ngược `Price` hiện chưa tính chiết khấu), query `PrintData` + template `PF_MXL_SalesInvoice`, và có thể thêm resource `DiscountAmount` vào register `Sales` để report `Sales` thống kê.
- Nâng cao: chiết khấu mặc định theo khách — attribute `DiscountPercent` trên `Counterparties`, đọc trong `CustomerOnChange` giống `GetCustomerPriceType`.

### Gợi ý 4 — Hạn mức công nợ (credit limit) cho khách

- Thêm attribute `CreditLimit` (Number) vào `Catalog.Counterparties`.
- Trong `Posting` của `SalesInvoice`, sau `WriteRecordSets`, viết thủ tục kiểm tra (đặt trong manager module của `CustomerBalance` hoặc module mới), theo mẫu `InventoryInWarehouses.NegativeBalanceControl`: đọc `AccumulationRegister.CustomerBalance.Balance(, Counterparty = &Customer)` và set `Cancel = True` kèm `Common.MessageToUser` nếu vượt hạn mức.
- Lưu ý: `NegativeBalanceControl` chỉ chạy khi `AdditionalProperties.ForPosting.IsInventoryInWarehousesChange` = True — cờ này do `OnWrite` trong `InventoryInWarehouses/Ext/RecordSetModule.bsl` đặt. Kiểm tra hạn mức chỉ chép vị trí gọi và cách báo lỗi, không chép điều kiện này (CustomerBalance không có record set module, nên chép nguyên thì kiểm tra không bao giờ chạy).
- Thảo luận: có nên trừ số dư `Advance` (âm) khỏi nợ không — xem quy ước dấu ở mục 8.

### Gợi ý 5 — Giá theo tiền tệ / giá đã gồm VAT trên PriceTypes

- Thêm attribute `PriceIncludesVAT` (Boolean) và/hoặc `Currency` cho `Catalog.PriceTypes` (hiện chưa có attribute nào).
- Sửa `PriceManagementServerCall.GetProductPriceByPriceType` và `GetTabularSectionPricesByPriceType` để quy đổi đúng; `InventoryTabularSectionClientServer.CalculateVATAmountAndTotal` phải tách VAT ra khỏi giá khi `PriceIncludesVAT`.
- Cập nhật report `PriceList` (thêm cột tiền tệ) và form `DataProcessor.PricesSetup`.

### Gợi ý 6 — Report bán hàng theo nhân viên / hoặc thêm cột lợi nhuận chưa VAT

- `SalesInvoice` đã có `Author`. Thêm dimension `Manager` (CatalogRef.Users) vào register `Sales`, thêm vào query bảng `Sales` trong `InitializeDocumentData`, rồi thêm field vào DCS của report `Sales` và một settings variant mới; đăng ký option trong `ReportsOptionsOverridable.CustomizeReportsOptions`.
- Hoặc bài nhỏ hơn: trong report `ProfitOnSales` thêm field doanh thu chưa VAT (`SalesTurnovers.AmountTurnover`) để so sánh với `RevenueAmount` hiện tại (xem mục 12).
- Sau khi thêm dimension vào register đã có dữ liệu, phải re-post các `SalesInvoice` cũ.

---

## 12. Những điểm lạ / cần lưu ý trong code Jet

Khi sinh viên đọc code, nên chỉ ra các điểm sau (đừng chép lại mà không hiểu):

1. **ProfitOnSales tính doanh thu gồm VAT**: `RevenueAmount` = `AmountTurnover + VATAmountTurnover`, trong khi `CostAmount` lấy từ `InventoryCost` (SupplierInvoice ghi `Amount` — giá chưa VAT). Như vậy `Profit` bao gồm cả thuế VAT phải nộp. [suy luận] Về kế toán, lợi nhuận gộp thường so sánh doanh thu **chưa VAT** với giá vốn.
2. **ProfitOnSales: doanh thu dịch vụ có, giá vốn dịch vụ không** — `Sales` nhận cả dòng `Service`, còn `InventoryCost` chỉ nhận `ProductType = Inventory`. Điều này hợp lý (dịch vụ không có giá vốn kho) nhưng cần biết khi đọc report.
3. **Kiểm tra "invoice amount < clearing amount" chỉ ở form** (`FillCheckProcessingAtServer`), không ở object module.
4. **Thay đổi `Date` của document không tự điền lại giá** — không có handler `DateOnChange` trong form; giá chỉ được lấy lại khi đổi `Customer`, `PriceType` hoặc `Product`. Tương tự, `CurrencyOnChange` cập nhật tỷ giá nhưng **không** quy đổi lại `Price` các dòng đã có.
5. Trong `SalesInvoice.xml`, attribute `ExchangeRate`/`Multiplier` có FillChecking `DontCheck`; nếu bằng 0 thì query posting `* ExchangeRate / Multiplier` sẽ chia cho 0 hoặc ra 0. `ObjectFillingJet.AddCurrency` và `GetExchangeRateData` luôn điền 1/1 khi là presentation currency nên bình thường không xảy ra.
6. Hằng ngữ trong form `PricesSetup`: chuỗi `"Effective date is requred."` viết sai chính tả (requred) — có trong nguồn, không phải lỗi chép.
