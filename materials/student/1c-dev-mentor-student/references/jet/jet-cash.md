# 1C:Jet — Phân hệ Quản lý dòng tiền (Subsystem CashManagement)

Khi nào đọc file này: khi sinh viên hỏi về thu/chi tiền mặt, thu/chi ngân hàng, register CashBalance, công nợ khách hàng/nhà cung cấp phát sinh từ thanh toán, tạm ứng (advance), số dư đầu kỳ tiền, report CashStatement — hoặc khi nhóm sinh viên được giao mở rộng phân hệ Dòng tiền của Jet.

Phạm vi nguồn: Jet commit 80884de (config 1.0.2.1), thư mục `cf/`, README và wiki tiếng Anh. Mọi đoạn code dưới đây được chép nguyên văn; chỗ cắt ghi `// ...`.

## Mục lục

1. Thành phần Subsystem · 2. Catalogs · 3. Enumerations · 4. AccumulationRegister CashBalance · 5. Bốn Document thu/chi · 6. Filling · 7. Posting · 8. Form và CashManagementClient/ServerCall · 9. Settlement và tạm ứng · 10. Số dư đầu kỳ · 11. Reports · 12. Role và điểm gắn SSL · 13. Chỗ lạ trong code · 14. Gợi ý mở rộng

## 1. Thành phần của Subsystem CashManagement

Subsystem `CashManagement` (Synonym "Cash management") có 3 subsystem con: `Catalogs`, `Bank`, `CashInHand`. Danh sách `<Content>` lấy từ các file XML:

| Nơi khai báo | Member objects |
|---|---|
| `cf/Subsystems/CashManagement.xml` | `Enum.CashTypes`, `AccumulationRegister.CashBalance`, `Report.CashStatement`, `Enum.BankPaymentOperations`, `Enum.BankReceiptOperations`, `Enum.CashReceiptOperations`, `Enum.CashVoucherOperations`, `CommonModule.CashManagementServerCall`, `CommonModule.CashManagementClient`, `Role.UseCashManagement`, `CommonCommand.AdditionalReportsCashManagement`, `CommonCommand.AdditionalDataProcessorsCashManagement`, `CommonCommand.ReportPanelCashManagement` |
| `.../CashManagement/Subsystems/Catalogs.xml` | `Catalog.Currencies`, `Catalog.CashAccounts`, `Catalog.BankAccounts` |
| `.../CashManagement/Subsystems/Bank.xml` | `Document.BankPayment`, `Document.BankReceipt` |
| `.../CashManagement/Subsystems/CashInHand.xml` | `Document.CashReceipt`, `Document.CashVoucher` |

Ghi chú:
- Register `CustomerBalance`, `SupplierBalance` và report `CustomerBalance`, `SupplierBalance` **không** nằm trong CashManagement: report `CustomerBalance` thuộc `Subsystems/Sales.xml`, report `SupplierBalance` thuộc `Subsystems/Purchases.xml`. Nhưng 4 chứng từ tiền đều ghi vào hai register công nợ này, nên nhóm Dòng tiền buộc phải hiểu chúng.
- `Catalog.Currencies` đồng thời là thành phần của subsystem SSL `StandardSubsystems/Currencies` (cùng `InformationRegister.ExchangeRates`, `CommonModule.CurrencyRateOperations`…). Tức là Currencies là **object của SSL** được Jet đưa vào giao diện phân hệ (xem Bài 21 về SSL).
- Mỗi object (catalog/document) có thêm catalog `...AttachedFiles` (ví dụ `CashReceiptAttachedFiles`) — [suy luận] theo mẫu catalog đính kèm file của subsystem File operations trong SSL (xem Bài 23).

## 2. Catalogs

### 2.1. CashAccounts và BankAccounts

- **CashAccounts** (quỹ tiền mặt): không phân cấp, Code 9 ký tự (Autonumbering), Description 50; attribute duy nhất `Currency` (`CatalogRef.Currencies`, FillChecking = ShowError).
- **BankAccounts** (tài khoản ngân hàng): không có Code (CodeLength = 0), Description 100; attributes `AccountNumber` và `IBAN` (String 34, Indexing = Index), `Bank` (String 100 — tên ngân hàng là chuỗi, không phải catalog), `SWIFT` (String 11), `Currency` (ShowError). InputByString theo Description, IBAN, AccountNumber.
- Cả hai có tabular section `AdditionalAttributes` (Property / Value / TextString — cấu trúc chuẩn của SSL Properties) và ba form ItemForm, ListForm, ChoiceForm.

### 2.2. Khóa đổi tiền tệ sau khi đã ghi

Item form của cả CashAccounts và BankAccounts giống hệt nhau (diff rỗng). Điểm đáng chú ý duy nhất về nghiệp vụ: một khi tài khoản đã được ghi, field `Currency` chuyển sang ReadOnly — vì số dư trong `CashBalance` được lưu theo tiền tệ của tài khoản.

Nguồn: Jet — cf/Catalogs/CashAccounts/Forms/ItemForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LockCurrencyChanges(Object.Ref);
	// ...
EndProcedure
// ...
Procedure LockCurrencyChanges(ObjectRef)
	
	Items.Currency.ReadOnly = Not ObjectRef.IsEmpty();
	
EndProcedure
```

[suy luận] Đây chỉ là khóa trên form; nếu ghi object bằng code thì vẫn đổi được Currency. Muốn chặn triệt để cần kiểm tra ở object module (`BeforeWrite`).

### 2.3. Currencies và ExchangeRates (SSL)

`Catalog.Currencies` (Code 3 ký tự, Description 10) có các attribute `ImportingFromInternet`, `DescriptionFull`, `Markup`, `MainCurrency`, `AmountInWordsParameters`, `RateCalculationFormula`, `RateSource` (`EnumRef.RateSources`), tabular section `Presentations`. Object module bắt đầu bằng dòng bản quyền "Copyright (c) 2024, OOO 1C-Soft … CC BY 4.0" → đây là **code SSL**, không phải code Jet.

`InformationRegister.ExchangeRates`: periodic theo **Day**, WriteMode Independent; Dimension `Currency` (Master); Resources `Rate` (DefinedType `CurrencyExchangeRate`) và `Repetition` (hệ số nhân). Đây là ví dụ thực tế của information register periodic + `SliceLast` (xem Bài 12).

Jet đọc tỷ giá qua function SSL `CurrencyRateOperations.GetCurrencyRate(Currency, DateOfCourse)` — bên trong gọi `InformationRegisters.ExchangeRates.GetLast(...)` và trả Structure có `Rate`, `Repetition`.

"Tiền tệ hạch toán" (presentation currency) lấy bằng function Jet `JetServer.GetPresentationCurrency()` — một dòng `Return Common.ObjectAttributeValue(Catalogs.Companies.MainCompany, "PresentationCurrency");` (đọc attribute của công ty chính qua module SSL `Common`).

## 3. Enumerations

| Enum | Values | Dùng ở |
|---|---|---|
| `CashReceiptOperations` | `Customer`, `Other` | CashReceipt.Operation |
| `CashVoucherOperations` | `Supplier`, `Other` | CashVoucher.Operation |
| `BankReceiptOperations` | `Customer`, `Other` | BankReceipt.Operation |
| `BankPaymentOperations` | `Supplier`, `Other` | BankPayment.Operation |
| `CashTypes` | `Cash`, `NonCash` | Dimension `CashType` của CashBalance |
| `LiabilityTypes` (ngoài CashManagement) | `Liability`, `Advance` | Dimension của CustomerBalance / SupplierBalance |

Thuật toán dựa vào **Enumeration** (không dựa vào chuỗi người dùng sửa được). Fill value mặc định của `Operation`: `Customer` (CashReceipt, BankReceipt) và `Supplier` (CashVoucher, BankPayment). Wiki (Features.md) gọi hai thao tác này là "Counterparty transaction" và "Other (for manual entries and balances)".

## 4. AccumulationRegister CashBalance (và hai register công nợ)

### 4.1. CashBalance
RegisterType = **Balance**. Dimensions: `BankCashAccount` — composite type `CatalogRef.CashAccounts` + `CatalogRef.BankAccounts`; `CashType` — `EnumRef.CashTypes` (cả hai DenyIncompleteValues = true). Resource: `AmountCur` Number(15,2).

Nhận xét cho sinh viên (xem Bài 11):
- Dimension **composite type** là cách gộp tiền mặt và ngân hàng vào một register. [suy luận] `CashType` gần như dư thừa về mặt dữ liệu (suy ra được từ kiểu của `BankCashAccount`) nhưng giúp lọc nhanh trong report.
- Chỉ có **một resource `AmountCur`** — số tiền theo tiền tệ của tài khoản. Không có cột quy đổi ra tiền tệ hạch toán. Vì tiền tệ gắn với tài khoản (và bị khóa sau khi ghi), cộng `AmountCur` theo từng tài khoản là hợp lệ; cộng chéo nhiều tài khoản khác tiền tệ thì không — report CashStatement vì vậy nhóm theo `Currency` trước.
- Register **không có RecordSetModule** → không có kiểm soát số dư âm (khác với `InventoryInWarehouses`, xem mục 14).

Chỉ 4 document CashReceipt, CashVoucher, BankReceipt, BankPayment ghi vào CashBalance (grep toàn bộ `cf/`).
### 4.2. CustomerBalance / SupplierBalance

Cả hai: RegisterType = Balance; Dimensions `LiabilityType` (`EnumRef.LiabilityTypes`), `Counterparty` (`CatalogRef.Counterparties`), `Document`; Resource `Amount` Number(15,2) — nhận giá trị đã quy đổi ra tiền tệ hạch toán (cột `Amount` của PaymentDetails). `Document` của CustomerBalance: `SalesInvoice`, `CashReceipt`, `BankReceipt`; của SupplierBalance: `BankPayment`, `CashVoucher`, `SupplierInvoice`.

Dimension `Document` là "chứng từ thanh toán theo" (settlement document): hóa đơn khi là `Liability`, hoặc chính chứng từ thu/chi khi là `Advance`. Quy ước dấu được giải thích ở mục 9.

## 5. Bốn Document thu/chi: cấu trúc chung

| | CashReceipt | CashVoucher | BankReceipt | BankPayment |
|---|---|---|---|---|
| Nghiệp vụ | Thu tiền mặt | Chi tiền mặt | Thu qua ngân hàng | Chi qua ngân hàng |
| Tài khoản (attribute) | `CashAccount` | `CashAccount` | `BankAccount` | `BankAccount` |
| `Operation` | CashReceiptOperations | CashVoucherOperations | BankReceiptOperations | BankPaymentOperations |
| `Counterparty` ChoiceParameters | `Filter.Customer = true` | `Filter.Supplier = true` | `Filter.Customer = true` | `Filter.Supplier = true` |
| `PaymentDetails.Document` | `DocumentRef.SalesInvoice` | `DocumentRef.SupplierInvoice` | `DocumentRef.SalesInvoice` | `DocumentRef.SupplierInvoice` |
| BasedOn | SalesInvoice | SupplierInvoice | SalesInvoice | SupplierInvoice |
| RegisterRecords | CustomerBalance, CashBalance | SupplierBalance, CashBalance | CustomerBalance, CashBalance | SupplierBalance, CashBalance |
| Thêm riêng | — | — | — | `Paid` (Boolean), `PaymentDate` (Date) |

Header chung: `Operation`, tài khoản (FillChecking = ShowError), `Counterparty` (ShowError), `Currency`, `ExchangeRate` (10,4), `Multiplier` (10,0), `Comment`, `Author` (`CatalogRef.Users`), `PaymentAmount` (15,2 — tổng, tính lại trong `BeforeWrite`).

Tabular section `PaymentDetails`: `Document`, `PaymentAmount` (số tiền theo tiền tệ chứng từ/tài khoản), `Amount` (số tiền quy đổi ra tiền tệ hạch toán).

Thuộc tính posting (cả 4): Posting = Allow, RealTimePosting = Deny, **Post in privileged mode** = true, **Unpost in privileged mode** = true, NumberType String(9), DataLockControlMode = Managed.

Code 4 document gần như sao chép nhau — chỉ khác tên object/enum/register (đã đối chiếu bằng `diff`). Vì vậy file này trích CashReceipt làm mẫu và chỉ ra chỗ khác.

## 6. Filling — tạo chứng từ thanh toán từ hóa đơn

Handler `Filling` trong object module chạy khi tạo mới (kể cả "Create based on" từ SalesInvoice/SupplierInvoice — BasedOn ở mục 5). Đầu tiên gọi module Jet `ObjectFillingJet.FillDocument` để gán tiền tệ mặc định và `Author`:

Nguồn: Jet — cf/CommonModules/ObjectFillingJet/Ext/Module.bsl
```bsl
Procedure FillDocument(DocumentObject, Val FillingData) Export
	
	If TypeOf(FillingData) <> Type("Structure") Then
		FillingData = New Structure;
	EndIf;
	
	AddCurrency(DocumentObject, FillingData);
	FillingData.Insert("Author", Users.AuthorizedUser());
	FillPropertyValues(DocumentObject, FillingData);
	
EndProcedure
```

Sau đó, nếu `FillingData` là hóa đơn, một batch query lấy header hóa đơn, chọn quỹ đầu tiên có cùng tiền tệ, và tính `Amount` quy đổi:

Nguồn: Jet — cf/Documents/CashReceipt/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef.SalesInvoice") Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		// ...
		|INTO DocumentHeader
		// ...
		|SELECT TOP 1
		|	CashAccounts.Ref AS Ref,
		|	CashAccounts.Currency AS Currency
		|INTO CashAccount
		// ...
		|SELECT
		|	VALUE(Enum.CashReceiptOperations.Customer) AS Operation,
		|	DocumentHeader.Customer AS Counterparty,
		|	ISNULL(CashAccount.Ref, VALUE(Catalog.CashAccounts.EmptyRef)) AS CashAccount,
		|	DocumentHeader.Currency AS Currency,
		// ...
		|	DocumentHeader.Ref AS Document,
		|	DocumentHeader.Total AS PaymentAmount,
		|		ELSE CAST(DocumentHeader.Total * DocumentHeader.ExchangeRate / DocumentHeader.Multiplier AS NUMBER(15, 2))
		// ...
		|		LEFT JOIN CashAccount AS CashAccount
		|		ON DocumentHeader.Currency = CashAccount.Currency";
		
		Query.SetParameter("Ref", FillingData);
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			// ...
			FillPropertyValues(ThisObject, Selection);
			
			PaymentDetails.Clear();
			FillPropertyValues(PaymentDetails.Add(), Selection);
			// ...
EndProcedure
```

Điểm học được (Bài 10): temporary table (`INTO`), `TOP 1` (phần cắt: `FROM Catalog.CashAccounts INNER JOIN DocumentHeader` theo `Currency`, điều kiện `NOT CashAccounts.DeletionMark`), `ISNULL(..., VALUE(...EmptyRef))`, `CAST ... AS NUMBER(15, 2)`, và mẹo `FillPropertyValues` cùng một Selection cho cả header lẫn dòng tabular section (field nào trùng tên thì được gán).

Khác biệt ở BankReceipt: hóa đơn bán có attribute `BankAccount`, nên query lấy thêm `SalesInvoice.BankAccount` và dùng `CASE WHEN DocumentHeader.BankAccount = VALUE(Catalog.BankAccounts.EmptyRef) THEN ISNULL(FirstBankAccount.Ref, ...) ELSE DocumentHeader.BankAccount END AS BankAccount` — ưu tiên tài khoản ghi trên hóa đơn, chỉ khi trống mới lấy tài khoản đầu tiên cùng tiền tệ (temp table `FirstBankAccount`).

CashVoucher và BankPayment làm tương tự với `SupplierInvoice` (`SupplierInvoice.Supplier AS Supplier`); BankPayment chọn `TOP 1` từ `Catalog.BankAccounts`.

## 7. Posting — code và luồng PostingManagement

### 7.1. Object module: BeforeWrite, Posting, UndoPosting, FillCheckProcessing

Nguồn: Jet — cf/Documents/CashReceipt/Ext/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Document data initialization.
	Documents.CashReceipt.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	
	// Movements on the CashBalance register
	PostingManagement.ReflectCashBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Movements on the CustomerBalance register
	PostingManagement.ReflectCustomerBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Writing of the records sets.
	PostingManagement.WriteRecordSets(ThisObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Operation = Enums.CashReceiptOperations.Other Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Counterparty"));
	EndIf;
	
EndProcedure
```

- `BeforeWrite` (không trích): bỏ qua khi `DataExchange.Load`, còn lại gán `PaymentAmount = PaymentDetails.Total("PaymentAmount")`.
- `UndoPosting` (không trích) chỉ gọi 3 dòng: `InitializeAdditionalPropertiesForPosting`, `PrepareRecordSetsForWriting`, `WriteRecordSets` — xem 7.3 để hiểu vì sao như vậy là đủ xóa register records.
- Cấu trúc "khung" 5 bước: khởi tạo `AdditionalProperties` → manager module chuẩn bị bảng dữ liệu → xóa record set cũ → nạp bảng vào `RegisterRecords` → ghi. Khác với cách Bài 11 (dùng Record wizard, vòng lặp `For Each ... RegisterRecords.X.Add()`), Jet dùng **query → ValueTable → `RecordSet.Load()`**.
- CashVoucher / BankPayment gọi `ReflectSupplierBalance` thay vì `ReflectCustomerBalance`.
- `FillCheckProcessing`: với `Operation = Other`, bỏ `Counterparty` khỏi danh sách bắt buộc (Bài 12).
- File object module được bọc trong `#If Server Or ExternalConnection Then` (preprocessor, Bài 7).

### 7.2. Manager module: InitializeDocumentData (CashReceipt)

Nguồn: Jet — cf/Documents/CashReceipt/Ext/ManagerModule.bsl
```bsl
Procedure InitializeDocumentData(CashReceiptRef, AdditionalProperties) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	// ...
	|INTO DocumentHeader
	// ...
	|SELECT
	|	DocumentHeader.Ref AS Ref,
	|	DocumentHeader.Date AS Period,
	// ...
	|INTO DocumentPaymentDetails
	|FROM
	|	DocumentHeader AS DocumentHeader
	|		INNER JOIN Document.CashReceipt.PaymentDetails AS CashReceiptPaymentDetails
	|		ON DocumentHeader.Ref = CashReceiptPaymentDetails.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VALUE(Enum.CashTypes.Cash) AS CashType,
	|	DocumentPaymentDetails.Period AS Period,
	|	DocumentPaymentDetails.CashAccount AS BankCashAccount,
	|	SUM(DocumentPaymentDetails.PaymentAmount) AS AmountCur
	|FROM
	|	DocumentPaymentDetails AS DocumentPaymentDetails
	|
	|GROUP BY
	|	DocumentPaymentDetails.Period,
	|	DocumentPaymentDetails.CashAccount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentPaymentDetails.Period AS Period,
	|	CASE
	|		WHEN DocumentPaymentDetails.Document = VALUE(Document.SalesInvoice.EmptyRef)
	|				OR DocumentPaymentDetails.Document = UNDEFINED
	|			THEN VALUE(Enum.LiabilityTypes.Advance)
	|		ELSE VALUE(Enum.LiabilityTypes.Liability)
	|	END AS LiabilityType,
	|	DocumentPaymentDetails.Counterparty AS Counterparty,
	// ...
	|	SUM(DocumentPaymentDetails.Amount) AS Amount
	|FROM
	|	DocumentPaymentDetails AS DocumentPaymentDetails
	|WHERE
	|	DocumentPaymentDetails.Operation = VALUE(Enum.CashReceiptOperations.Customer)
	|
	|GROUP BY
	// ...
	|	DocumentPaymentDetails.Period";
	
	Query.SetParameter("Ref", CashReceiptRef);
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableCashBalance", QueryResult[2].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableCustomerBalance", QueryResult[3].Unload());
	
EndProcedure
```

Đọc query theo từng gói của batch (Bài 10, "batch query"):
- `QueryResult[0]` (phần cắt: `Ref`, `Date`, `Operation`, `Counterparty`, `CashAccount` của chính chứng từ, `WHERE CashReceipt.Ref = &Ref`) và `[1]` (`DocumentPaymentDetails`: header + từng dòng `PaymentDetails` — `Operation`, `Counterparty`, `CashAccount`, `Document`, `PaymentAmount`, `Amount`): temp table, không trả dữ liệu.
- `QueryResult[2]` → bảng cho **CashBalance**: tổng `PaymentAmount` (tiền tệ tài khoản) vào `AmountCur`, `CashType` cố định `Cash`. Tên cột trùng tên dimension/resource của register nên `Load()` nạp thẳng được.
- `QueryResult[3]` → bảng cho **CustomerBalance**: dùng `Amount` (tiền tệ hạch toán); chỉ khi `Operation = Customer`. Dòng không có hóa đơn → `Advance`, và `Document` = chính chứng từ thu (phần cắt `// ...` là một CASE cùng điều kiện: `THEN DocumentPaymentDetails.Ref ELSE DocumentPaymentDetails.Document END AS Document`).

Khác biệt giữa 4 document trong gói `[2]`:

| Document | RecordType (CashBalance) | CashType | Period | Gói `[3]` |
|---|---|---|---|---|
| CashReceipt | Receipt | Cash | `Date` | CustomerBalance, Expense |
| CashVoucher | Expense | Cash | `Date` | SupplierBalance, Expense |
| BankReceipt | Receipt | NonCash | `Date` | CustomerBalance, Expense |
| BankPayment | Expense | NonCash | `PaymentDate` | SupplierBalance, Expense |

Đặc biệt BankPayment chỉ sinh dữ liệu khi đã đánh dấu `Paid`, và kỳ ghi sổ là `PaymentDate` chứ không phải `Date`:

Nguồn: Jet — cf/Documents/BankPayment/Ext/ManagerModule.bsl
```bsl
	"SELECT
	|	BankPayment.Ref AS Ref,
	|	BankPayment.PaymentDate AS PaymentDate,
	// ...
	|INTO DocumentHeader
	|FROM
	|	Document.BankPayment AS BankPayment
	|WHERE
	|	BankPayment.Ref = &Ref
	|	AND BankPayment.Paid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentHeader.Ref AS Ref,
	|	DocumentHeader.PaymentDate AS Period,
```

Nếu `Paid = False`, `DocumentHeader` rỗng → mọi bảng rỗng → các `Reflect...` return sớm → chứng từ vẫn post nhưng không có register records (lệnh chi "đã lập nhưng chưa chi").

### 7.3. PostingManagement (common module của Jet)

Module `PostingManagement`: Server = true, ExternalConnection = true, ServerCall = false (chỉ gọi được từ code server). Dùng chung cho mọi document của Jet.

Nguồn: Jet — cf/CommonModules/PostingManagement/Ext/Module.bsl
```bsl
Procedure PrepareRecordSetsForWriting(DocumentObject) Export
	
	For Each RecordSet In DocumentObject.RegisterRecords Do
		// ...
	EndDo;
	
	RegisterNameArray = GetUsedRegisterNames(DocumentObject.Ref, DocumentObject.AdditionalProperties.DocumentMetadata);
	For Each RegisterName In RegisterNameArray Do
		DocumentObject.RegisterRecords[RegisterName].Write = True;
	EndDo;
	
EndProcedure

Procedure ReflectCashBalance(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableCashBalance = AdditionalProperties.TableForRegisterRecords.TableCashBalance;
	
	If Cancel Or TableCashBalance.Count() = 0 Then
		Return;
	EndIf;
	
	CashBalanceRecord = RegisterRecords.CashBalance;
	CashBalanceRecord.Write = True;
	CashBalanceRecord.Load(TableCashBalance);
	
EndProcedure
```

- `InitializeAdditionalPropertiesForPosting` tạo trong `AdditionalProperties` các khóa `TableForRegisterRecords` (Structure chứa các ValueTable), `ForPosting` (chứa `TempTablesManager`) và `DocumentMetadata`.
- `ReflectCustomerBalance` / `ReflectSupplierBalance` có cấu trúc giống hệt `ReflectCashBalance` (đọc `TableCustomerBalance` / `TableSupplierBalance`, nạp vào register tương ứng).
- `WriteRecordSets` duyệt `RegisterRecords`, với record set có `Write = True` thì gán `RecordSet.AdditionalProperties.ForPosting` rồi gọi `RecordSet.Write()`.

Giải thích cho sinh viên:
- `PrepareRecordSetsForWriting` xóa record set trong bộ nhớ, rồi (qua function private `GetUsedRegisterNames` — query `UNION` các register của document để tìm register nào **đã có** bản ghi của recorder này) bật cờ `Write = True` cho các register đó. Nhờ vậy khi re-post hoặc `UndoPosting`, bản ghi cũ trong DB bị ghi đè bằng tập rỗng — tức là bị xóa. Đây là lý do `UndoPosting` chỉ cần 3 dòng.
- Document có property RegisterRecordsWritingOnPost = `WriteSelected` (trong XML), khớp với cách bật cờ `Write` thủ công.
- `WriteRecordSets` truyền `ForPosting` (có `TempTablesManager`) sang record set — đây là "cửa" để RecordSetModule của register kiểm tra số dư (Jet dùng cho `InventoryInWarehouses`; CashBalance chưa dùng).

## 8. Form của Document và CashManagementClient / CashManagementServerCall

### 8.1. Hai common module của phân hệ

| Module | Flags | Nội dung |
|---|---|---|
| `CashManagementClient` | ClientManagedApplication = true, Server = false | `RecalculateAmountAtExchangeRate` |
| `CashManagementServerCall` | Server = true, ServerCall = true | `CurrencyExchangeRateData` |

Nguồn: Jet — cf/CommonModules/CashManagementClient/Ext/Module.bsl
```bsl
Procedure RecalculateAmountAtExchangeRate(Object, TabSectionName = "PaymentDetails") Export
	
	If Object[TabSectionName].Count() = 0 Then
		Return;
	EndIf;
	
	ExchangeRate = ?(Object.ExchangeRate = 0, 1, Object.ExchangeRate);
	Multiplier = ?(Object.Multiplier = 0, 1, Object.Multiplier);
	
	For Each Row In Object[TabSectionName] Do
		Row.Amount = Round(Row.PaymentAmount * ExchangeRate / Multiplier, 2);
	EndDo;
	
EndProcedure
```

Nguồn: Jet — cf/CommonModules/CashManagementServerCall/Ext/Module.bsl
```bsl
Procedure CurrencyExchangeRateData(DataStructure) Export
	
	PresentationCurrency = JetServer.GetPresentationCurrency();
	
	If ValueIsFilled(DataStructure.CashBankAccount) Then
		
		Currency = Common.ObjectAttributeValue(DataStructure.CashBankAccount, "Currency");
		
		If Currency <> PresentationCurrency Then
			ExchRateStructure = CurrencyRateOperations.GetCurrencyRate(Currency, DataStructure.Date);
			DataStructure.Insert("Currency", Currency);
			DataStructure.Insert("ExchangeRate", ExchRateStructure.Rate);
			DataStructure.Insert("Multiplier", ExchRateStructure.Repetition);
		Else
			// ...
		EndIf;
		// ...
	EndIf;
	
EndProcedure
```

Hai nhánh bị cắt `// ...` (tiền tệ tài khoản = tiền tệ hạch toán, hoặc tài khoản trống) đều gán `Currency = PresentationCurrency`, `ExchangeRate = 1`, `Multiplier = 1`.

Đây là ví dụ đẹp cho Bài 7 và Bài 14: tách module theo context — tính toán thuần (nhân/chia) chạy ở client, việc đọc DB (`Common.ObjectAttributeValue`, `ExchangeRates`) đi qua **một** server call, dữ liệu trao đổi bằng `Structure`. Hai module SSL được gọi: `Common` (Core) và `CurrencyRateOperations` (Currencies).

### 8.2. DocumentForm — event handlers của Jet

Form item `Currency` trên form có `ReadOnly = true`: tiền tệ luôn đi theo tài khoản, người dùng không chọn tay.

Nguồn: Jet — cf/Documents/CashReceipt/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure CashAccountOnChange(Item)
	
	DataStructure = New Structure("CashBankAccount, Date", Object.CashAccount, Object.Date);
	CashManagementServerCall.CurrencyExchangeRateData(DataStructure);
	FillPropertyValues(Object, DataStructure, "Currency, ExchangeRate, Multiplier");
	
	CashManagementClient.RecalculateAmountAtExchangeRate(Object);
	
	FormManagement();
	
EndProcedure

// ...
// ...
&AtClient
Procedure FormManagement()
	
	If Object.Currency = PresentationCurrency Then
		Items.ExchangeRate.ReadOnly = True;
		Items.Multiplier.ReadOnly = True;
	Else
		// ...
	EndIf;
	
	If Object.Operation = PredefinedValue("Enum.CashReceiptOperations.Other") Then
		Items.Counterparty.Visible = False;
		Items.PaymentDetailsDocument.Visible = False;
	Else
		// ...
	EndIf;
	
EndProcedure
```

- Hai handler của cột bảng: `PaymentDetailsPaymentAmountOnChange` tính `Amount = Round(PaymentAmount * ExchangeRate / Multiplier, 2)`, `PaymentDetailsAmountOnChange` tính ngược `PaymentAmount = Round(Amount * Multiplier / ExchangeRate, 2)` (tỷ giá/hệ số = 0 được thay bằng 1). `ExchangeRateOnChange`, `MultiplierOnChange` gọi `CashManagementClient.RecalculateAmountAtExchangeRate(Object)`.
- `PresentationCurrency` là form attribute, gán trong `OnCreateAtServer` bằng `JetServer.GetPresentationCurrency()`; `FormManagement` được gọi ở `OnOpen`, `OperationOnChange`, `CashAccountOnChange`.
- `PredefinedValue(...)` dùng trên client vì không truy cập được `Enums` ở client (Bài 7).
- Phần còn lại của form module là "boilerplate" SSL: `AttachableCommands` (lệnh in, tạo dựa trên…) và `PropertyManager` (Additional attributes) — đặt trong comment `// StandardSubsystems.…` để dễ nhận biết.

BankPayment thêm handler cho `Paid`:

Nguồn: Jet — cf/Documents/BankPayment/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure PaidOnChange(Item)
	
	If Object.Paid Then
		Object.PaymentDate = Object.Date;
	ElsIf ValueIsFilled(Object.PaymentDate) Then
		Object.PaymentDate = Date(1, 1, 1);
	EndIf;
	
	FormManagement();
	
EndProcedure
```

và trong `FormManagement` của BankPayment có thêm dòng `Items.PaymentDate.Enabled = Object.Paid;`.

## 9. Liên kết thanh toán với hóa đơn và tạm ứng (settlement)

### 9.1. Quy ước dấu trong CustomerBalance

Ghép từ code posting của SalesInvoice và CashReceipt/BankReceipt:

| Sự kiện | RecordType | LiabilityType | Document | Ý nghĩa số dư |
|---|---|---|---|---|
| SalesInvoice post | Receipt | Liability | hóa đơn | khách nợ tăng (+) |
| Thu tiền, dòng có hóa đơn | Expense | Liability | hóa đơn | khách nợ giảm |
| Thu tiền, dòng **không** có hóa đơn | Expense | Advance | chính chứng từ thu | số dư Advance **âm** = khách đã trả trước |
| SalesInvoice cấn trừ tạm ứng (`AdvanceClearing`) | Receipt | Advance | chứng từ thu | xóa dần số âm của tạm ứng |
| … đồng thời | Expense | Liability | hóa đơn | giảm nợ hóa đơn tương ứng |

SupplierBalance đối xứng: SupplierInvoice ghi Receipt/Liability; CashVoucher/BankPayment ghi Expense (Liability hoặc Advance). Wiki (Initial Setup Guide, mục 11) xác nhận: "Leave the Document field empty — this tells the system it's an advance".

### 9.2. Cấn trừ tạm ứng nằm ở phía hóa đơn

Tạm ứng không được "gắn" vào hóa đơn trong chứng từ tiền; ngược lại, hóa đơn có tabular section `AdvanceClearing` (SalesInvoice: `Document` kiểu `CashReceipt`/`BankReceipt`; SupplierInvoice: `BankPayment`/`CashVoucher`). Phần ghi sổ trong manager module SalesInvoice gồm hai nhánh `UNION ALL`: Receipt/Advance theo `Document` (chứng từ thu) và Expense/Liability theo `InvoiceDocument` (hóa đơn), cùng số tiền `SUM(DocumentAdvanceClearing.Amount)`:

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentAdvanceClearing.Period,
	|	VALUE(Enum.LiabilityTypes.Advance),
	// ...
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentAdvanceClearing.Period,
	|	VALUE(Enum.LiabilityTypes.Liability),
	|	DocumentAdvanceClearing.Counterparty,
	|	DocumentAdvanceClearing.InvoiceDocument,
```

Danh sách tạm ứng còn dư được chọn qua common form `SelectAdvances` (mở từ command `SelectAdvances` của form hóa đơn, tham số `IsCustomerAdvance`). Query đọc virtual table `Balance` với điều kiện `LiabilityType = Advance`, cộng lại phần hóa đơn hiện tại đã cấn trừ (để khi mở lại hóa đơn đã post không bị trừ hai lần), và đổi register bằng `StrReplace`:

Nguồn: Jet — cf/CommonForms/SelectAdvances/Ext/Form/Module.bsl
```bsl
	|SELECT
	|	BalanceTable.Document AS Document,
	|	BalanceTable.AmountBalance AS Amount,
	// ...
	|INTO TmpAdvanceBalance
	|FROM
	|	AccumulationRegister.CustomerBalance.Balance(
	|			,
	|			LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
	|				AND Counterparty = &Counterparty) AS BalanceTable
	// ...
	|HAVING
	|	SUM(TmpAdvanceBalance.Amount) < 0
	// ...
	
	If Not IsCustomerAdvance Then
		Query.Text = StrReplace(Query.Text, "AccumulationRegister.CustomerBalance", "AccumulationRegister.SupplierBalance");
	EndIf;
```

`HAVING SUM(...) < 0` chính là "chỉ lấy tạm ứng còn dư" theo quy ước dấu ở 9.1. Form này thuộc phân hệ Sales/Purchases nhưng **dữ liệu nó đọc do chứng từ tiền sinh ra** — sửa logic Advance trong chứng từ tiền phải kiểm tra lại form này.

[suy luận] Chứng từ tiền không kiểm tra số tiền trả có vượt nợ còn lại của hóa đơn không; trả thừa trên dòng có hóa đơn sẽ làm số dư `Liability` của hóa đơn âm chứ không chuyển thành `Advance`.

## 10. Nhập số dư đầu kỳ

Jet **không có** document riêng cho số dư đầu kỳ tiền (tìm "Opening/InitialBalance" trong `cf/` không ra object nào). Cách làm theo wiki (1C:Jet-Initial-Setup-Guide.md, mục 10–11):

- **Tiền gửi ngân hàng**: `BankReceipt` với Operation = **Other**.
- **Tiền mặt**: `CashReceipt` với Operation = **Other**.
- Công nợ phải thu/phải trả: dùng `SalesInvoice` / `SupplierInvoice` với một product dịch vụ giả (ví dụ "Opening balances input"), ngày **trước** Start Date.
- Tạm ứng đầu kỳ: chứng từ thu/chi với Operation thường, để trống cột Document.

Code khớp với hướng dẫn: với `Other`, gói `[2]` vẫn ghi CashBalance (Receipt), còn gói `[3]` bị loại bởi `WHERE DocumentPaymentDetails.Operation = VALUE(Enum.CashReceiptOperations.Customer)` → không đụng công nợ; `Counterparty` không bắt buộc (`FillCheckProcessing`) và bị ẩn trên form (`FormManagement`).

Hệ quả: trong report CashStatement, số dư đầu kỳ hiện như một **khoản thu** trong kỳ chứa ngày của chứng từ đó, không phân biệt được với thu "Other" thật (mục 14 có gợi ý).

## 11. Reports

Cả ba report là DCS (Bài 18), chỉ có `MainDataCompositionSchema` và một command mở ngữ cảnh; không có object module.

### 11.1. CashStatement

Query của data set (lấy từ `<query>` trong template; trong XML các ký tự được escape):

Nguồn: Jet — cf/Reports/CashStatement/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
SELECT
	CashBalanceBalanceAndTurnovers.CashType AS CashType,
	ISNULL(BankAccounts.Currency, CashAccounts.Currency) AS Currency,
	CashBalanceBalanceAndTurnovers.BankCashAccount AS BankCashAccount,
	CashBalanceBalanceAndTurnovers.AmountCurOpeningBalance AS AmountCurOpeningBalance,
	CashBalanceBalanceAndTurnovers.AmountCurReceipt AS AmountCurReceipt,
	CashBalanceBalanceAndTurnovers.AmountCurExpense AS AmountCurExpense,
	CashBalanceBalanceAndTurnovers.AmountCurClosingBalance AS AmountCurClosingBalance,
	CashBalanceBalanceAndTurnovers.Recorder AS Recorder
FROM
	AccumulationRegister.CashBalance.BalanceAndTurnovers(, , Auto, , ) AS CashBalanceBalanceAndTurnovers
		LEFT JOIN Catalog.BankAccounts AS BankAccounts
		ON CashBalanceBalanceAndTurnovers.BankCashAccount = BankAccounts.Ref
		LEFT JOIN Catalog.CashAccounts AS CashAccounts
		ON CashBalanceBalanceAndTurnovers.BankCashAccount = CashAccounts.Ref
```

- Virtual table `BalanceAndTurnovers` với periodicity `Auto` và field `Recorder` → DCS tự chi tiết đến từng chứng từ (Bài 11, 18).
- `ISNULL(BankAccounts.Currency, CashAccounts.Currency)`: kỹ thuật lấy attribute từ dimension composite type bằng hai LEFT JOIN.
- Parameters: `ItmPeriod` (StandardPeriod, mặc định `ThisMonth` trong variant), `BeginOfPeriod = &ItmPeriod.StartDate`, `EndOfPeriod = &ItmPeriod.EndDate`.
- Resources: `Sum(...)` của 4 cột AmountCur. Grouping: `Currency` → `BankCashAccount`.
- Hai variant: `CashStatement` và `CashStatementContext`; `ReportsOptionsOverridable` (module SSL Overridable có code Jet) mô tả variant chính "Opening balance, inflow, outflow, closing balance by cash or bank accounts" và tắt variant Context khỏi report panel.

Command `OpenCashStatementReport` (parameter type `CashAccounts`/`BankAccounts`, group `FormNavigationPanelSeeAlso`) mở report ngay từ thẻ tài khoản: tạo `FilterStructure` với `BankCashAccount = CommandParameter` và `CashType` = `Cash` hay `NonCash` tùy `TypeOf(CommandParameter)`, rồi `OpenForm("Report.CashStatement.Form", ...)` với `VariantKey = "CashStatementContext"`, `GenerateOnOpen = True`.

### 11.2. CustomerBalance / SupplierBalance

Hai report dùng chung một mẫu query (thay tên register). Tách số dư theo `LiabilityType` thành hai cột và đảo dấu tạm ứng để hiển thị số dương:

Nguồn: Jet — cf/Reports/CustomerBalance/Templates/MainDataCompositionSchema/Ext/Template.xml
```bsl
	CASE
		WHEN CustomerBalance.LiabilityType = VALUE(Enum.LiabilityTypes.Advance)
			THEN -CustomerBalance.AmountBalance
		ELSE 0
	END AS AmountAdvance,
	// ...
FROM
	AccumulationRegister.CustomerBalance.Balance AS CustomerBalance
```

Các field khác: `LiabilityType`, `Counterparty`, `Document`, `AmountLiability` (CASE tương tự lấy `AmountBalance` khi `Liability`).

Parameter `Period`; resources `Sum(AmountLiability)`, `Sum(AmountAdvance)`, `Sum(AmountTotal)`. `AmountTotal` = biểu thức `AmountLiability` trừ biểu thức `AmountAdvance` = công nợ ròng. Command `OpenCustomerBalanceReport` nhận `CatalogRef.Counterparties` và mở variant `CustomerBalanceContext` lọc theo `Counterparty`.

## 12. Role UseCashManagement và các điểm gắn SSL

Role `UseCashManagement` (đọc từ `Roles/UseCashManagement/Ext/Rights.xml`, chỉ liệt kê quyền = true):
- 4 document tiền: đầy đủ Read/Insert/Update/Posting/UndoPosting/Interactive… (Bài 20).
- `Catalog.CashAccounts`, `BankAccounts`, `Currencies` và các catalog `...AttachedFiles`: Read/Insert/Update/Edit…
- `AccumulationRegister.CashBalance`: **chỉ Read, View** — không có quyền ghi register. Việc ghi xảy ra nhờ **Post in privileged mode** = true trên document.
- `Document.SalesInvoice`, `SupplierInvoice`, `Catalog.Counterparties`: chỉ Read/View/InputByString; `Report.CashStatement`, `Report.Dashboard`: Use/View.
- Role này **không** có quyền trên `CustomerBalance`/`SupplierBalance` (grep = 0) — cũng dựa vào privileged mode khi post.

Các module SSL "*Overridable" có code Jet liên quan phân hệ:
- `PrintManagementOverridable`: `Settings.PrintObjects.Add(Documents.CashReceipt)` (và 3 document còn lại). Nhưng `AddPrintCommands` trong manager module của cả 4 document đang **rỗng** → chưa có mẫu in.
- `PropertyManagerOverridable`: khai báo bộ Additional attributes `Catalog_CashAccounts`, `Catalog_BankAccounts`, `Document_CashReceipt`…
- `ReportsOptionsOverridable`: section "Cash management reports" và mô tả variant CashStatement.
- `AdditionalReportsAndDataProcessorsOverridable`: thêm `Metadata.Subsystems.CashManagement` vào danh sách section → các common command `AdditionalReportsCashManagement` / `AdditionalDataProcessorsCashManagement` mở external report/data processor gắn vào phân hệ (Bài 21).

## 13. Điểm cần lưu ý / chỗ lạ trong code

1. **BankPayment tạo từ hóa đơn sẽ không ghi sổ cho tới khi tick Paid**: `Filling` không gán `Paid`, fill value của `Paid` trống (False) → post xong không có register records. Đây là ý đồ thiết kế (lệnh chi chưa thực hiện), nhưng dễ khiến sinh viên tưởng posting lỗi.
2. **Không kiểm soát âm quỹ**: CashBalance không có RecordSetModule; chi quá số dư vẫn post được.
3. **`TOP 1` không có `ORDER BY`** khi chọn quỹ/tài khoản mặc định trong `Filling` → [suy luận] nếu có nhiều tài khoản cùng tiền tệ, tài khoản được chọn không xác định trước.
4. **Comment sao chép**: manager module của CashReceipt, CashVoucher, BankPayment đều mô tả tham số là `ref to Bank receipt.` (chỉ đúng với BankReceipt; ví dụ CashVoucher: `//  CashVoucherRef - DocumentRef.CashVoucher - ref to Bank receipt.`).
5. **ChoiceParameterLinks của `PaymentDetails.Document`** trong metadata 4 document có Name = `Counterparty` (không có tiền tố `Filter.`), trong khi chính Jet dùng `Filter.Counterparty` cho chiều ngược lại (SalesInvoice.AdvanceClearing.Document). [suy luận] Với tên `Counterparty`, tham số được truyền vào choice form của hóa đơn dưới dạng parameter thường; choice form SalesInvoice không xử lý parameter này, nên danh sách hóa đơn có thể không được lọc theo khách hàng — nên kiểm tra lại trong Enterprise mode.
6. **Không có liên kết bắt buộc giữa `Counterparty` header và khách hàng của hóa đơn ở dòng**: [suy luận] code posting lấy `Counterparty` từ header cho mọi dòng; nếu chọn hóa đơn của khách khác, CustomerBalance sẽ ghi sai đối tượng.
7. Wiki (mục tạm ứng ở Initial Setup Guide) gọi "Cash Payment" — object thật là `CashVoucher`.

## 14. Gợi ý mở rộng cho nhóm sinh viên phân hệ Dòng tiền

Các ý dưới đây là **gợi ý** để nhóm chọn đề tài, dựa trên những chỗ còn trống trong Jet; chưa có trong Jet và chưa được kiểm chứng — nhóm cần thiết kế và chạy thử. Khi làm, nhắc lại nguyên tắc: không sửa trực tiếp code gốc nếu có thể làm bằng configuration extension (Purpose **Add-on** cho object mới, **Customization** khi thay đổi hành vi có sẵn); extension là **upgrade-safe customization** (xem bài Extensions).

### Gợi ý 1 — Chứng từ chuyển tiền nội bộ (CashTransfer)

Bài toán: nộp tiền mặt vào ngân hàng, rút tiền về quỹ, chuyển giữa hai tài khoản — hiện chỉ làm được bằng cặp chứng từ "Other" rời rạc.
- Object mới: `Document.CashTransfer` (header: `AccountFrom`, `AccountTo` — composite `CashAccounts`/`BankAccounts`, `Amount`), RegisterRecords = `CashBalance`.
- Posting theo đúng khuôn Jet: `PostingManagement.InitializeAdditionalPropertiesForPosting` → `Documents.CashTransfer.InitializeDocumentData` (query trả 2 dòng: Expense từ `AccountFrom`, Receipt vào `AccountTo`, `CashType` suy từ kiểu tài khoản như trong `OpenCashStatementReport`) → `ReflectCashBalance` → `WriteRecordSets`.
- Kiểm tra trong `FillCheckProcessing`: hai tài khoản khác nhau, cùng `Currency` (vì CashBalance chỉ có `AmountCur`).
- Đưa vào `Subsystems/CashManagement` và cấp quyền trong `Role.UseCashManagement`; Post in privileged mode như 4 chứng từ hiện có.

### Gợi ý 2 — Kiểm soát số dư âm của quỹ/tài khoản

- Thêm RecordSetModule cho `AccumulationRegister.CashBalance`, mô phỏng `AccumulationRegisters/InventoryInWarehouses/Ext/RecordSetModule.bsl`: `BeforeWrite` lưu bản ghi cũ vào temp table qua `AdditionalProperties.ForPosting.TempTablesManager` (do `PostingManagement.WriteRecordSets` truyền vào), `OnWrite` tính phần thay đổi và đọc `CashBalance.Balance` để báo lỗi nếu âm.
- Có thể thêm Functional option / Constant "Kiểm soát âm quỹ" (Bài 13, 15).
- Liên quan: Bài 11 (Balance), Bài 12 (DataLock, transaction), Bài 16 (thứ tự event).

### Gợi ý 3 — Khoản mục dòng tiền (Cash flow items) và báo cáo lưu chuyển tiền

- Bài toán: chi "Other" không cho biết chi cho việc gì (lương, thuê nhà, điện…). Object mới: `Catalog.CashFlowItems` (hierarchical; có thể có predefined items như "Thu từ khách hàng", "Trả nhà cung cấp").
- Thêm attribute `CashFlowItem` vào 4 document (bắt buộc khi Operation = Other — sửa `FillCheckProcessing` và `FormManagement`).
- Ghi sổ: hoặc thêm dimension vào `CashBalance`, hoặc tạo register **Turnovers** mới `CashFlow` (Period, BankCashAccount, CashFlowItem, Amount) để không ảnh hưởng report cũ. Cần sửa `InitializeDocumentData` của 4 manager module và thêm `ReflectCashFlow` theo mẫu `PostingManagement`.
- Report DCS mới "Cash flow by items" (Bài 18). Chuyển tiền nội bộ (gợi ý 1) không nên tính vào lưu chuyển.

### Gợi ý 4 — Ngân sách dòng tiền: kế hoạch và thực tế

- Tiếp nối gợi ý 3: `Document.CashFlowBudget` (kỳ, tabular section `CashFlowItem` / `Amount`), ghi vào register Turnovers `CashFlowBudget`.
- Report DCS so sánh Plan vs Actual: hai data set (budget và `CashFlow`) nối theo `CashFlowItem` + kỳ, cột chênh lệch (Bài 18: nhiều data set, data set links).
- Có thể thêm Event subscription / cảnh báo khi chứng từ chi làm vượt ngân sách (Bài 16).

### Gợi ý 5 — Mẫu in phiếu thu / phiếu chi

- Jet đã đăng ký 4 document trong `PrintManagementOverridable`, nhưng `AddPrintCommands` trong manager module đang rỗng.
- Việc cần làm: tạo template (spreadsheet), điền `AddPrintCommands` và procedure `Print` trong manager module theo SSL Print (Bài 22); dùng `CurrencyRateOperations.GenerateAmountInWords` (module SSL đã có trong Jet) để in số tiền bằng chữ.

### Gợi ý 6 — Phân biệt số dư đầu kỳ và cải thiện CashStatement

- Thêm giá trị `OpeningBalance` vào `CashReceiptOperations` / `BankReceiptOperations` (hoặc một document `CashOpeningBalance` riêng), xử lý giống `Other` trong posting và form.
- Mở rộng CashStatement: thêm field `Operation`, `Counterparty` (lấy qua `Recorder`) để lọc/nhóm, hoặc thêm resource quy đổi ra tiền tệ hạch toán (cần thêm resource `Amount` vào `CashBalance` và sửa gói `[2]` của 4 `InitializeDocumentData` — lấy `SUM(Amount)` song song với `SUM(PaymentAmount)`).
- Có thể kết hợp sửa các điểm 5–6 ở mục 13 (lọc hóa đơn theo `Counterparty`, kiểm tra hóa đơn thuộc đúng khách hàng) như một phần "Patch" nhỏ.
