# 1C:Jet — tổng quan, kiến trúc và cách tổ chức code

Khi nào đọc file này: sinh viên hỏi "Jet là gì", "Document X post vào register nào", "code posting của Jet nằm ở đâu", "muốn thêm tính năng vào subsystem Warehouses/Purchases/Sales/CashManagement thì bắt đầu từ đâu", hoặc cần bản đồ object của Jet trước khi làm bài thực hành nhóm.

Phiên bản được mô tả: repo `1Ci-Company/Jet`, nhánh `community`, commit 80884de, configuration `Jet` version 1.0.2.1, Compatibility mode `Version8_3_24`. Mọi đoạn code dưới đây chép nguyên văn từ dump cấu hình (`cf/`).

## Mục lục

1. [Jet là gì](#1-jet-là-gì)
2. [Cài đặt và mở Jet](#2-cài-đặt-và-mở-jet)
3. [Kiến trúc: lớp ứng dụng Jet trên SSL](#3-kiến-trúc-lớp-ứng-dụng-jet-trên-ssl)
4. [Sáu subsystem ứng dụng](#4-sáu-subsystem-ứng-dụng)
5. [Bảng tổng: Document → Accumulation register](#5-bảng-tổng-document--accumulation-register)
6. [Bảy Accumulation register](#6-bảy-accumulation-register)
7. [Information register chính](#7-information-register-chính)
8. [Catalog chính và Enumeration](#8-catalog-chính-và-enumeration)
9. [Report của Jet](#9-report-của-jet)
10. [Cách Jet tổ chức code](#10-cách-jet-tổ-chức-code)
11. [Cách tự tìm đường trong Jet](#11-cách-tự-tìm-đường-trong-jet)

---

## 1. Jet là gì

Theo README và Wiki của repo:

- **1C:Jet** là một applied solution trên nền tảng 1C, được làm ra **cho người mới học lập trình 1C**. Mục tiêu: giới thiệu sự linh hoạt và khả năng của platform qua một dự án mã nguồn mở có chức năng thực tế.
- Nghiệp vụ: kế toán cơ bản cho công ty nhỏ — mua hàng, bán hàng, kho, tiền mặt/ngân hàng, tạm ứng (advance payments), tính lợi nhuận. README nhấn mạnh code "clean, readable" và đơn giản.
- Giấy phép **MIT**. Có các bản địa hoá riêng (Jet-TR, Jet-ES, Jet-ID) với nhánh `community-tr`, `community-es`, `community-id`.
- Nền tảng khuyến nghị: **8.3.24** (README). Trang Wiki cài platform hướng dẫn bản Training Platform 8.3.25.1445 tải từ my.1ci.com.

Chức năng theo trang Wiki *Features* (rút gọn):

| Mảng | Có gì |
|---|---|
| Base functionality (SSL) | Users & rights, external reports/data processors, currencies, notes, reminders, contact info, additional properties, batch edit, print forms, to-do list, marked objects deletion, report options |
| Purchases | Catalog Counterparties, Products, Tax rates (VATRates); Document Supplier invoice; report Purchases |
| Sales | Price types, price list; Document Sales invoice; report Sales |
| Warehouse | Catalog Warehouses "with negative balance control"; Document Inventory increase (nhập số dư đầu), Inventory write-off, Inventory transfer; report Warehouse balance |
| Cash & Bank | Catalog Cash accounts, Bank accounts; Document Cash receipt / Cash voucher, Bank receipt / Bank payment; hai operation: Counterparty transaction và Other |
| AP/AR | Advance payments; report công nợ khách hàng / nhà cung cấp |
| Costing & profit | "average cost tracking via document sequencing"; report Cost of goods in stock, Sales revenue |

## 2. Cài đặt và mở Jet

> **Cho sinh viên của khóa:** dùng thư mục cài đặt của khóa (platform Windows / macOS, `jet.dt`, `jet.cf`, `queryconsole.epf`) và platform **8.3.25.1445** — xem `references/tai-nguyen.md`. Phần dưới đây là cách cài theo Wiki của repo Jet.

Tóm tắt Wiki (chi tiết: các trang *How to install platform*, *How to install Jet using the installer / using the repository*, *1C:Jet Initial Setup Guide*):

1. Cài platform 1C:Enterprise (đăng ký tài khoản Developer trên my.1ci.com → Distributives → Tools for Developers → Training Platform).
2. Cài Jet — hai cách:
   - **Installer**: chạy `setup.exe` → mở platform → "Create infobase from template" → chọn **1C:Jet (demo)** (có dữ liệu mẫu) hoặc **1C:Jet** (trống).
   - **Từ repository** (cách sinh viên nên dùng khi làm dự án): clone repo → tạo infobase "with no configuration" → mở **Designer** → Configuration → Open configuration → **Configuration → Restore configuration from files** → chọn thư mục `cf` → Debug → Start debugging.
3. Lần đầu vào **Enterprise mode**: tạo user có quyền Administrator, đăng nhập lại bằng user đó, bật các tính năng cần (properties, notes & reminders, email, message templates, additional reports and data processors…), nhập thông tin công ty và chọn **presentation currency**.
4. Đóng góp code: fork repo, làm trên nhánh `community`, mở pull request vào `community` (trang *Contributing*).

## 3. Kiến trúc: lớp ứng dụng Jet trên SSL

Jet = **SSL (Standard Subsystems Library) + lớp ứng dụng Jet**. Phần lớn object trong `cf/` (Users, AccessGroups, Files, Interactions, PrintManagement, AttachableCommands…) là của SSL — module `InfobaseUpdateSSL` khai báo SSL version "3.1.10.348". Phần nghiệp vụ của Jet nhỏ và dễ đọc: 16 Document thì 9 là của Jet, 7 Accumulation register, ~10 Catalog, 14 common module.

Thuộc tính configuration (từ `cf/Configuration.xml`): `Name` = Jet, `Version` = 1.0.2.1, `DefaultRunMode` = ManagedApplication, `ScriptVariant` = English, `DataLockControlMode` = Managed, `CompatibilityMode` = Version8_3_24.

### 3.1. Common module của Jet

Cờ lấy từ `cf/CommonModules/<Name>.xml` (chỉ liệt kê cờ = true). Cột "Reuse" là `ReturnValuesReuse` (xem Bài 14 về reuse return values).

| Module | Cờ | Reuse | Vai trò (đọc từ code) |
|---|---|---|---|
| `PostingManagement` | Server, ExternalConnection | DontUse | Khung posting dùng chung cho mọi Document: khởi tạo `AdditionalProperties`, chuẩn bị và ghi record set, các thủ tục `Reflect<Register>` nạp bảng giá trị vào `RegisterRecords` |
| `ObjectFillingJet` | Server, ExternalConnection | DontUse | `FillDocument` — điền mặc định khi tạo Document: `Author`, `Currency`/`ExchangeRate`/`Multiplier` |
| `InfobaseUpdateJet` | Server, ExternalConnection, ClientOrdinaryApplication | DontUse | Khai báo Jet là một "subsystem" với SSL (Name, Version) và đăng ký update handler |
| `JetServer` | Server, ExternalConnection | DontUse | `GetPresentationCurrency` (đọc từ `Catalogs.Companies.MainCompany`), `GetQueryUnion`, `GetQueryDelimeter` — chuỗi ghép query text |
| `JetServerCall` | Server, ServerCall | DontUse | `GetVATRateValue` — cầu nối client gọi server, chuyển tiếp sang `JetCached` |
| `JetCached` | Server | DuringSession | `GetVATRateValue` — đọc `Rate` của VATRates, cache trong phiên |
| `JetClientServer` | ClientManagedApplication, Server, ExternalConnection | DontUse | `CalculateFromCurrencyToCurrency` — quy đổi số tiền giữa hai tỷ giá |
| `InventoryTabularSectionClientServer` | ClientManagedApplication, Server, ExternalConnection | DontUse | `CalculateAmount`, `CalculateVATAmountAndTotal` — tính dòng của tabular section `Inventory` |
| `PriceManagementClient` | ClientManagedApplication | DontUse | `RefillTabularSectionPricesByPriceType` — điền lại giá cả bảng theo `PriceType` của form |
| `PriceManagementServerCall` | Server, ServerCall | DontUse | `GetProductPriceByPriceType`, `GetTabularSectionPricesByPriceType` — query `InformationRegister.Prices.SliceLast` |
| `CashManagementClient` | ClientManagedApplication | DontUse | `RecalculateAmountAtExchangeRate` — tính lại cột `Amount` của `PaymentDetails` theo tỷ giá |
| `CashManagementServerCall` | Server, ServerCall | DontUse | `CurrencyExchangeRateData` — lấy currency + tỷ giá theo cash/bank account và ngày |
| `ImportDataFromFileJet` | Server, ExternalConnection | DontUse | `MapDataToImport`, `FillInListOfAmbiguities` — ánh xạ dữ liệu import từ file vào Products (dùng cho SSL ImportDataFromFile) |
| `UserRemindersJet` | Server, ExternalConnection | DontUse | `OnFillToDoList` — đưa số reminder của user vào To-do list của SSL |

Quy ước tên dễ thấy: hậu tố `Client`, `ServerCall`, `ClientServer`, `Cached` khớp với cờ của module (giống quy ước SSL — xem Bài 14, Bài 21); hậu tố `Jet` (`ObjectFillingJet`, `InfobaseUpdateJet`, `UserRemindersJet`, `ImportDataFromFileJet`) đánh dấu module Jet "cắm" vào một cơ chế SSL cùng tên.

### 3.2. Jet cắm vào SSL ở đâu

SSL có các common module `*Overridable` để configuration điền code riêng. Trong Jet, các chỗ có code Jet thật (không phải comment mẫu):

| Module SSL (Overridable) | Code Jet trong đó |
|---|---|
| `ConfigurationSubsystemsOverridable.OnAddSubsystems` | `SubsystemsModules.Add("InfobaseUpdateJet");` |
| `PrintManagementOverridable.OnDefinePrintSettings` | Đăng ký manager của 9 Document Jet vào `Settings.PrintObjects` |
| `ToDoListOverridable.OnDetermineToDoListHandlers` | Thêm `DataProcessors.InventoryCostRecalculation` và (nếu bật functional option `UseUserReminders`) `UserRemindersJet` |
| `AdditionalReportsAndDataProcessorsOverridable` | Thêm các section như `Metadata.Subsystems.Warehouses` |
| `ContactsManagerOverridable` | Contact information kinds cho Counterparties, Warehouses |
| `InteractionsClientServerOverridable` | SalesInvoice, SupplierInvoice làm subject; Counterparties làm contact |

Ngoài ra Jet dùng **Defined types** của SSL để gắn object vào chức năng SSL, ví dụ `AttachedFilesOwner` (Counterparties, Products, Warehouses, các Document), `ReminderSubject`, `NotesSubject`, `ObjectWithAdditionalCommands` (chỉ có `DocumentRef.SalesInvoice`).

## 4. Sáu subsystem ứng dụng

Lấy từ `<Content>` trong `cf/Subsystems/<Name>.xml` và các subsystem con `cf/Subsystems/<Name>/Subsystems/*.xml`. Một object có thể nằm ở nhiều subsystem (Products, Counterparties, Units, Currencies). Bốn subsystem đầu là nơi các nhóm sinh viên mở rộng.

| Subsystem (Synonym) | Subsystem con → thành viên | Thành viên trực tiếp |
|---|---|---|
| **Warehouses** | Catalogs → Catalog Units, Warehouses, Products · Warehouse → Document InventoryIncrease, InventoryTransfer, InventoryWriteOff | AccumulationRegister InventoryInWarehouses, InventoryCost · Report AvailableStock, StockStatement · DataProcessor InventoryCostRecalculation · Sequence InventoryCostRecalculation · Role UseWarehouses · CommonCommand AdditionalReportsWarehouses, AdditionalDataProcessorsWarehouses, ReportPanelWarehouses |
| **Purchases** | Purchases → Document SupplierInvoice · Catalogs → Catalog Counterparties, Products, Units | AccumulationRegister Purchases, SupplierBalance · Report Purchases, SupplierBalance · Role UsePurchases · CommonCommand AdditionalReportsPurchases, AdditionalDataProcessorsPurchases, ReportPanelPurchases |
| **Sales** | Sales → Document SalesInvoice · Catalogs → Catalog Counterparties, Products, Units · Pricing → Catalog PriceTypes, DataProcessor PricesSetup, CommonModule PriceManagementServerCall, InformationRegister Prices | AccumulationRegister Sales, CustomerBalance · Report Sales, CustomerBalance, ProfitOnSales, PriceList · Role UseSales · CommonCommand AdditionalReportsSales, AdditionalDataProcessorsSales, ReportPanelSales |
| **CashManagement** ("Cash management") | Bank → Document BankPayment, BankReceipt · CashInHand ("Cash-in-hand") → Document CashReceipt, CashVoucher · Catalogs → Catalog Currencies, CashAccounts, BankAccounts | AccumulationRegister CashBalance · Report CashStatement · Enum CashTypes, BankPaymentOperations, BankReceiptOperations, CashReceiptOperations, CashVoucherOperations · CommonModule CashManagementServerCall, CashManagementClient · Role UseCashManagement · CommonCommand AdditionalReportsCashManagement, AdditionalDataProcessorsCashManagement, ReportPanelCashManagement |
| **Company** | Company → Catalog Companies, Currencies · Taxes → Catalog VATRates | Role UseCompany · CommonCommand AdditionalReportsCompany, AdditionalDataProcessorsCompany |
| **Administration** | UserMonitoring → các report về user/quyền (AccessRightsAnalysis, RolesRights, UsersInfo…) | Gần như toàn bộ là object SSL: Catalog Users, AccessGroups, Currencies…, DataProcessor SSLAdministrationPanel, EventLog, ImportDataFromFile… |

Mỗi subsystem nghiệp vụ đi kèm một Role `Use<Subsystem>` — khi thêm object mới vào subsystem, nhớ cấp quyền trong role tương ứng (xem Bài 20).

## 5. Bảng tổng: Document → Accumulation register

Cột "RegisterRecords" đọc từ `<RegisterRecords>` trong `cf/Documents/<Doc>.xml`; cột "Reflect…" là các lời gọi `PostingManagement.Reflect…` trong procedure `Posting` của `ObjectModule.bsl`; hướng ghi (Receipt/Expense) đọc từ query trong `InitializeDocumentData` của `ManagerModule.bsl`. Cả 9 Document đều có `Posting` = Allow, `RealTimePosting` = Deny, `RegisterRecordsDeletion` = AutoDeleteOff, `RegisterRecordsWritingOnPost` = WriteSelected, **Post in privileged mode** = true.

| Document | Subsystem | RegisterRecords | Hướng ghi chính | Ghi chú |
|---|---|---|---|---|
| `SupplierInvoice` | Purchases | Purchases, SupplierBalance, InventoryInWarehouses, InventoryCost | InventoryInWarehouses/InventoryCost: Receipt; SupplierBalance: Receipt (Liability), kèm cặp Receipt Advance / Expense Liability khi cấn trừ tạm ứng | Chỉ dòng `ProductType = Inventory` mới vào 2 register kho; có control âm kho |
| `SalesInvoice` | Sales | Sales, CustomerBalance, InventoryInWarehouses, InventoryCost | InventoryInWarehouses/InventoryCost: Expense; giá vốn tính bình quân từ `InventoryCost.Balance` | Nằm trong Sequence `InventoryCostRecalculation`; có control âm kho |
| `InventoryIncrease` | Warehouses | InventoryInWarehouses, InventoryCost | Receipt | Dùng nhập số dư đầu kỳ |
| `InventoryTransfer` | Warehouses | InventoryInWarehouses, InventoryCost | Expense ở `Warehouse`, Receipt ở `WarehouseReceiver` | Nằm trong Sequence |
| `InventoryWriteOff` | Warehouses | InventoryInWarehouses, InventoryCost | Expense | Nằm trong Sequence |
| `CashReceipt` | CashManagement | CashBalance, CustomerBalance | CashBalance: Receipt, `CashType` = Cash; CustomerBalance: Expense | `BasedOn` = SalesInvoice |
| `CashVoucher` | CashManagement | CashBalance, SupplierBalance | CashBalance: Expense, Cash; SupplierBalance: Expense | `BasedOn` = SupplierInvoice |
| `BankReceipt` | CashManagement | CashBalance, CustomerBalance | CashBalance: Receipt, NonCash; CustomerBalance: Expense | `BasedOn` = SalesInvoice |
| `BankPayment` | CashManagement | CashBalance, SupplierBalance | CashBalance: Expense, NonCash; SupplierBalance: Expense | Chỉ ghi khi `Paid` = True; `Period` = `PaymentDate`; `BasedOn` = SupplierInvoice |

Với 4 chứng từ tiền: nếu dòng `PaymentDetails` không chỉ ra hoá đơn (`Document` rỗng) thì bản ghi công nợ có `LiabilityType` = Advance và `Document` = chính chứng từ thanh toán; ngược lại là Liability theo hoá đơn. Khi Operation = Other, query chỉ lấy dòng có Operation Supplier/Customer cho register công nợ, nên chứng từ "Other" chỉ ghi CashBalance.

Các Document còn lại **không phải nghiệp vụ Jet**: `IncomingEmail`, `OutgoingEmail`, `Meeting`, `PhoneCall`, `PlannedInteraction`, `SMSMessage` (thuộc subsystem Interactions của SSL) và `PricesSetupAuxiliary` (Document phụ, `Posting` = Deny, chỉ có tabular section `ProductPrices`, dùng làm bảng đích khi import giá trong DataProcessor `PricesSetup`). Không Document nào trong số này có RegisterRecords.

**Sequence** `InventoryCostRecalculation` (`cf/Sequences/InventoryCostRecalculation.xml`): Documents = InventoryTransfer, InventoryWriteOff, SalesInvoice; RegisterRecords = InventoryCost; `MoveBoundaryOnPosting` = Move. Đây là cơ chế "average cost tracking via document sequencing": DataProcessor `InventoryCostRecalculation` gọi `Sequences.InventoryCostRecalculation.Restore()` để post lại các chứng từ xuất khi biên sequence bị lùi. [suy luận] SupplierInvoice và InventoryIncrease không nằm trong sequence vì chứng từ nhập không phụ thuộc giá vốn bình quân hiện có.

## 6. Bảy Accumulation register

Đọc từ `cf/AccumulationRegisters/<Name>.xml`. Không register nào có Attribute. Nhắc lại: kind **Balances** có virtual table Balance/BalanceAndTurnovers; **Turnovers** chỉ có Turnovers (Bài 11).

| Register | Kind | Dimensions | Resources | Ai ghi |
|---|---|---|---|---|
| `InventoryInWarehouses` | Balances | `Product` (CatalogRef.Products), `Warehouse` (CatalogRef.Warehouses) | `Quantity` | SupplierInvoice, SalesInvoice, InventoryIncrease, InventoryTransfer, InventoryWriteOff |
| `InventoryCost` | Balances | `Product` (Products), `Warehouse` (Warehouses) | `Quantity`, `Amount` | như trên |
| `Purchases` | Turnovers | `Counterparty` (Counterparties), `Product` (Products), `PurchaseDocument` (DocumentRef.SupplierInvoice) | `Quantity`, `Amount`, `VATAmount` | SupplierInvoice |
| `Sales` | Turnovers | `Counterparty`, `Product`, `SalesDocument` (DocumentRef.SalesInvoice) | `Quantity`, `Amount`, `VATAmount` | SalesInvoice |
| `SupplierBalance` | Balances | `LiabilityType` (EnumRef.LiabilityTypes), `Counterparty`, `Document` (DocumentRef.BankPayment / CashVoucher / SupplierInvoice) | `Amount` | SupplierInvoice, BankPayment, CashVoucher |
| `CustomerBalance` | Balances | `LiabilityType`, `Counterparty`, `Document` (DocumentRef.SalesInvoice / CashReceipt / BankReceipt) | `Amount` | SalesInvoice, BankReceipt, CashReceipt |
| `CashBalance` | Balances | `BankCashAccount` (CatalogRef.CashAccounts / BankAccounts), `CashType` (EnumRef.CashTypes) | `AmountCur` | CashReceipt, CashVoucher, BankReceipt, BankPayment |

Điểm đáng học: dimension `Document` và `BankCashAccount` có **kiểu phức hợp** (composite type); `InventoryCost` có `EnableTotalsSplitting` = true. Chỉ `InventoryInWarehouses` có module: `ManagerModule.bsl` (procedure `NegativeBalanceControl`) và `RecordSetModule.bsl` (`BeforeWrite`/`OnWrite` tính phần thay đổi để kiểm tra âm kho — xem mục 10.2).

## 7. Information register chính

| Register | Periodicity | WriteMode | Dimensions | Resources | Ghi chú |
|---|---|---|---|---|---|
| `Prices` (Jet) | Day | Independent | `PriceType` (CatalogRef.PriceTypes), `Product` (CatalogRef.Products) | `Price` | Ghi bởi DataProcessor `PricesSetup` (`InformationRegisters.Prices.CreateRecordSet()`); đọc bằng `SliceLast` trong `PriceManagementServerCall` và report `PriceList` |
| `ExchangeRates` | Day | Independent | `Currency` (CatalogRef.Currencies) | `Rate`, `Repetition` | [suy luận] thuộc phần tiền tệ của SSL; Jet đọc qua `CurrencyRateOperations.GetCurrencyRate` (module SSL) |

Hầu hết ~80 Information register khác (Access…, Files…, Update…, UserReminders…) là của SSL.

Ví dụ đọc giá theo `SliceLast` (xem Bài 12):

Nguồn: Jet — cf/CommonModules/PriceManagementServerCall/Ext/Module.bsl
```bsl
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	PricesSliceLast.Price * &DocumentRepetition / &DocumentRate AS Price
	|FROM
	|	InformationRegister.Prices.SliceLast(
	|			&PriceDate,
	|			PriceType = &PriceType
	|				AND Product = &Product) AS PricesSliceLast";
```

## 8. Catalog chính và Enumeration

Chỉ liệt kê attribute developer thêm (ngoài standard attributes Code/Description). Gần như mọi Catalog/Document của Jet có tabular section `AdditionalAttributes` — đó là phần của SSL Properties, không phải dữ liệu nghiệp vụ.

| Catalog | Hierarchical | Attribute chính | Ghi chú |
|---|---|---|---|
| `Products` | true | `DetailedDescription`, `ProductType` (Enum.ProductTypes), `Unit` (Catalog.Units), `VATRate` (Catalog.VATRates) | Dòng có `ProductType` = Service không ghi vào register kho |
| `Counterparties` | true | `Customer`, `Supplier` (Boolean), `LegalName`, `TIN`, `PriceType` (Catalog.PriceTypes), `IsIndividual` | Tabular section `ContactInformation` (SSL); command `Customers`, `Suppliers` |
| `Warehouses` | false | — | `ContactInformation` |
| `PriceTypes` | false | — | |
| `CashAccounts` | false | `Currency` | |
| `BankAccounts` | false | `AccountNumber`, `IBAN`, `Bank`, `SWIFT`, `Currency` | |
| `Companies` | false | `LegalName`, `TIN`, `PresentationCurrency` (Catalog.Currencies), `IsIndividual`, `RegistrationNumber`, `RegistrationCountry`, `RegistrationDate` | Predefined item `MainCompany`; `JetServer.GetPresentationCurrency` đọc từ đây |
| `Units` | false | — | |
| `VATRates` | false | `Rate` | Manager module có `GetExemptFromVATRate` (tìm hoặc tạo mức 0%) |
| `Currencies` | false | `ImportingFromInternet`, `DescriptionFull`, `Markup`, `MainCurrency`, `AmountInWordsParameters`, `RateCalculationFormula`, `RateSource` | [suy luận] Catalog của SSL (module có logic tỷ giá kiểu SSL) |

Enumeration nghiệp vụ: `ProductTypes` (Inventory, Service) · `LiabilityTypes` (Liability, Advance) · `CashTypes` (Cash, NonCash) · `BankPaymentOperations` / `CashVoucherOperations` (Supplier, Other) · `BankReceiptOperations` / `CashReceiptOperations` (Customer, Other).

Header của Document nghiệp vụ (để biết field nào có sẵn):

| Document | Header attributes | Tabular sections |
|---|---|---|
| SupplierInvoice | `Supplier`, `Warehouse`, `Currency`, `ExchangeRate`, `Multiplier`, `Comment`, `Author`, `Total`, `ExemptFromVAT` | `Inventory` (Product, Quantity, Price, Amount, VATRate, VATAmount, Total), `AdvanceClearing` (Document: BankPayment/CashVoucher, Amount, AmountCur) |
| SalesInvoice | `Customer`, `Warehouse`, `Currency`, `ExchangeRate`, `Multiplier`, `PriceType`, `Comment`, `Author`, `Total`, `BankAccount`, `ExemptFromVAT` | `Inventory` (như trên), `AdvanceClearing` (Document: CashReceipt/BankReceipt, Amount, AmountCur) |
| InventoryIncrease | `Warehouse`, `Comment`, `Author` | `Inventory` (Product, Quantity, Price, Amount) |
| InventoryTransfer | `Warehouse`, `WarehouseReceiver`, `Comment`, `Author` | `Inventory` (Product, Quantity) |
| InventoryWriteOff | `Warehouse`, `Comment`, `Author` | `Inventory` (Product, Quantity) |
| CashReceipt / CashVoucher | `Operation`, `CashAccount`, `Counterparty`, `Currency`, `ExchangeRate`, `Multiplier`, `Comment`, `Author`, `PaymentAmount` | `PaymentDetails` (Document, PaymentAmount, Amount) |
| BankReceipt | như trên nhưng `BankAccount` thay `CashAccount` | `PaymentDetails` |
| BankPayment | như BankReceipt + `Paid`, `PaymentDate` | `PaymentDetails` |

## 9. Report của Jet

Tất cả là report DCS với template `MainDataCompositionSchema` (Bài 18). Nguồn dữ liệu (đọc từ template):

| Report | Subsystem | Nguồn |
|---|---|---|
| AvailableStock | Warehouses | `AccumulationRegister.InventoryInWarehouses.Balance` |
| StockStatement | Warehouses | `AccumulationRegister.InventoryCost.BalanceAndTurnovers` |
| Purchases | Purchases | `AccumulationRegister.Purchases.Turnovers` |
| SupplierBalance | Purchases | `AccumulationRegister.SupplierBalance.Balance` |
| Sales | Sales | `AccumulationRegister.Sales.Turnovers` |
| CustomerBalance | Sales | `AccumulationRegister.CustomerBalance.Balance` |
| ProfitOnSales | Sales | `AccumulationRegister.Sales.Turnovers` + `AccumulationRegister.InventoryCost.Turnovers` |
| PriceList | Sales | `InformationRegister.Prices.SliceLast` |
| CashStatement | CashManagement | `AccumulationRegister.CashBalance.BalanceAndTurnovers` |

## 10. Cách Jet tổ chức code

### 10.1. Posting: một khung chung cho mọi Document

Mọi Document nghiệp vụ của Jet post theo cùng một khuôn 3 tầng:

1. **Object module** (`Posting`) — chỉ điều phối, gọi lần lượt các bước.
2. **Manager module** (`InitializeDocumentData`) — một batch query đọc dữ liệu chứng từ, tạo sẵn các bảng giá trị có đúng cột của register, cất vào `AdditionalProperties.TableForRegisterRecords` với tên `Table<RegisterName>`.
3. **Common module `PostingManagement`** — code chung: khởi tạo, xoá bản ghi cũ, `Load` bảng vào record set, ghi.

So với Bài 11 (viết thẳng `RegisterRecords.X.Add()` trong vòng lặp), cách này tách "lấy dữ liệu bằng query" khỏi "ghi register", và dùng lại được cho mọi Document.

**Bước 1 — Object module của Document.** Đây là toàn bộ `Posting` và `UndoPosting` của SupplierInvoice:

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ObjectModule.bsl
```bsl
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

Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties for document posting.
	PostingManagement.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	PostingManagement.PrepareRecordSetsForWriting(ThisObject);
	
	// Writing of the records sets.
	PostingManagement.WriteRecordSets(ThisObject);
	
	// Negative balance control
	AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl(Ref, AdditionalProperties, Cancel);
	
EndProcedure
```

Các Document khác giống hệt, chỉ khác tên Document và danh sách `Reflect…` (ví dụ BankPayment gọi `ReflectCashBalance` + `ReflectSupplierBalance`, không gọi `NegativeBalanceControl`). `UndoPosting` không nạp bảng nào nên chỉ xoá bản ghi cũ.

**Bước 2 — Manager module: `InitializeDocumentData`.** Batch query dùng temporary table (`INTO DocumentHeader`, `INTO DocumentInventory`, `INTO ProductTable`…), mỗi query cuối trả về đúng cột của một register (có cả `RecordType`, `Period`). Phần kết của SupplierInvoice:

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl
```bsl
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ProductTable.Period AS Period,
	|	ProductTable.Product AS Product,
	|	ProductTable.Warehouse AS Warehouse,
	|	ProductTable.Quantity AS Quantity,
	|	ProductTable.Amount AS Amount
	|FROM
	|	ProductTable AS ProductTable";
	
	Query.SetParameter("Ref", SupplierInvoiceRef);
	
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TablePurchases", QueryResult[4].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[5].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableSupplierBalance", QueryResult[6].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[7].Unload());
	
EndProcedure
```

Chú ý chỉ số `QueryResult[n]` phải khớp thứ tự query trong batch — thêm/bớt một query ở giữa là phải sửa lại các chỉ số này (lỗi hay gặp khi sinh viên mở rộng).

**Bước 3 — `PostingManagement`.** Ba thủ tục khung:

Nguồn: Jet — cf/CommonModules/PostingManagement/Ext/Module.bsl
```bsl
Procedure InitializeAdditionalPropertiesForPosting(DocumentRef, AdditionalProperties) Export
	
	// Structure that will contain values table with data for movings execution.
	AdditionalProperties.Insert("TableForRegisterRecords", New Structure);
	
	// Contains the properties required for posting.
	AdditionalProperties.Insert("ForPosting", New Structure);
	
	// Stores the value of the temporary table manager
	AdditionalProperties.ForPosting.Insert("TempTablesManager", New TempTablesManager);
	
	// Contains the document metadata.
	AdditionalProperties.Insert("DocumentMetadata", DocumentRef.Metadata());
	
EndProcedure

// ...

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

Procedure WriteRecordSets(DocumentObject) Export
	
	For Each RecordSet In DocumentObject.RegisterRecords Do
		If RecordSet.Write Then
			RecordSet.AdditionalProperties.Insert("ForPosting", DocumentObject.AdditionalProperties.ForPosting);
			RecordSet.Write();
			RecordSet.Write = False;
		EndIf;
	EndDo;
	
EndProcedure
```

Và mỗi register có một `Reflect<Register>` cùng một mẫu (7 bản: Purchases, Sales, InventoryInWarehouses, CashBalance, CustomerBalance, SupplierBalance, InventoryCost):

Nguồn: Jet — cf/CommonModules/PostingManagement/Ext/Module.bsl
```bsl
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

Ý nghĩa từng bước:

- `PrepareRecordSetsForWriting` xoá record set trong bộ nhớ, rồi dùng hàm private `GetUsedRegisterNames` (query `SELECT TOP 1 … WHERE RegisterTable.Recorder = &Recorder` ghép bằng `JetServer.GetQueryUnion()` cho từng register trong `DocumentMetadata.RegisterRecords`) để tìm các register **đang có bản ghi cũ** của chứng từ và đặt `Write = True` — nhờ vậy bản ghi cũ bị ghi đè bằng tập rỗng nếu lần post này không còn ghi vào register đó. Điều này đi cùng thuộc tính `RegisterRecordsWritingOnPost` = WriteSelected (chỉ record set có `Write = True` mới được platform ghi — ngoài giáo trình, hãy kiểm tra lại trong Syntax assistant).
- `Reflect…` chỉ `Load` bảng đã chuẩn bị — không có logic nghiệp vụ. Logic nằm hết trong query của manager module.
- `WriteRecordSets` ghi chủ động từng record set và **truyền `ForPosting` (chứa `TempTablesManager`) sang `RecordSet.AdditionalProperties`** — đây là cầu nối để record set module của register dùng chung temporary table với chứng từ.

### 10.2. Kiểm soát âm kho (negative balance control)

Chuỗi xử lý trải trên 3 nơi:

1. `RecordSetModule` của `InventoryInWarehouses`, event `BeforeWrite`: đặt managed lock (`DataLock`, mode Exclusive) theo `Recorder`, lưu bản ghi cũ vào temp table `InventoryInWarehousesBeforeWrite`.
2. Event `OnWrite`: tính chênh lệch cũ/mới vào temp table `InventoryInWarehousesChange`, đặt cờ `AdditionalProperties.ForPosting.IsInventoryInWarehousesChange`.
3. Object module gọi `AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl` sau `WriteRecordSets`: nếu cờ bật, join temp table với `Balance(, )` để tìm số dư < 0 và báo lỗi bằng `Common.MessageToUser(..., Cancel)` (module SSL).

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
```

Đây là phương án "kiểm tra sau khi ghi" (ghi trước, đọc Balance sau, nếu âm thì `Cancel`) — khác với cách kiểm tra trước khi ghi trong Bài 11–12; đáng để sinh viên so sánh.

### 10.3. Giá vốn bình quân trong SalesInvoice

`InitializeDocumentData` của SalesInvoice khoá `AccumulationRegister.InventoryCost` theo Product/Warehouse, rồi đọc `InventoryCost.Balance(&PointInTime, …)` với `PointInTime` = `New Boundary(DocumentObject.PointInTime(), BoundaryType.Including)` (Bài 11), cộng lại bản ghi cũ của chính chứng từ, và chia tỷ lệ:

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
	|	CASE
	|		WHEN ISNULL(InventoryCostTable.Quantity, 0) = 0
	|			THEN 0
	|		WHEN ProductTable.Quantity = InventoryCostTable.Quantity
	|			THEN InventoryCostTable.Amount
	|		ELSE CAST(InventoryCostTable.Amount * ProductTable.Quantity / InventoryCostTable.Quantity AS NUMBER(15, 2))
	|	END AS Amount
```

InventoryTransfer và InventoryWriteOff dùng cùng ý tưởng.

### 10.4. Region trong module

Jet dùng các tên `#Region` chuẩn SSL (Bài 23). Đếm trên các object nghiệp vụ của Jet:

| Loại module | Region dùng |
|---|---|
| Object module | `EventHandlers` (bọc trong `#If Server Or ExternalConnection Then … #EndIf`) |
| Manager module | `Public` (gồm `InitializeDocumentData` và các khối SSL như `// StandardSubsystems.Print … // End StandardSubsystems.Print`) |
| Form module | `FormEventHandlers`, `FormHeaderItemsEventHandlers`, `FormTableItemsEventHandlers<TênBảng>` (ví dụ `FormTableItemsEventHandlersInventory`, `…PaymentDetails`, `…AdvanceClearing`, `…List`), `FormCommandsEventHandlers`, `Private` |
| Common module Jet | `Public`, `Private` (JetServer có region lồng `WorkWithQuery`; InfobaseUpdateJet có `ForCallsFromOtherSubsystems`) |

Trong một region, code gọi SSL được bọc bằng cặp comment `// StandardSubsystems.<Tên>` … `// End StandardSubsystems.<Tên>` — dấu hiệu nhanh để phân biệt "code Jet" với "đoạn tích hợp SSL".

### 10.5. Quy ước đặt tên

- Object: danh từ tiếng Anh, PascalCase, Catalog số nhiều (`Products`, `Warehouses`), Document số ít (`SalesInvoice`).
- Tabular section dùng lại tên cố định: `Inventory` (hàng hoá), `PaymentDetails` (chứng từ tiền), `AdvanceClearing` (cấn trừ tạm ứng) — nhờ vậy `InventoryTabularSectionClientServer` và `CashManagementClient` dùng chung được.
- Cặp tiền tệ trên header: `Currency`, `ExchangeRate`, `Multiplier`; số tiền quy đổi ra presentation currency trong query (`Amount * ExchangeRate / Multiplier`).
- Bảng trong `TableForRegisterRecords`: `Table<RegisterName>`; thủ tục ghi: `Reflect<RegisterName>`.
- Form item handler: `<Bảng><Cột>OnChange` (ví dụ `InventoryProductOnChange`), form tự đặt `FormManagement()` để bật/tắt item.
- Handler của SSL trong form có tiền tố `Attachable_` (`Attachable_ExecuteCommand`, `Attachable_UpdateCommands`, `Attachable_PropertiesExecuteCommand`).
- Cách chia client/server trong form: handler `&AtClient` gom tham số vào một `Structure` (`DataStructure`) rồi gọi procedure `&AtServerNoContext` (`GetProductData`, `GetExchangeRateData`) hoặc common module `…ServerCall` — đúng nguyên tắc giảm số lần gọi server (Bài 7).

### 10.6. Filling: `ObjectFillingJet`

Cả 9 Document nghiệp vụ có event `Filling` gọi một dòng:

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
EndProcedure
```

`FillDocument` gán `Author` = `Users.AuthorizedUser()` (SSL) và, nếu Document có attribute `Currency` (kiểm tra bằng `Common.HasObjectAttribute`), điền presentation currency với tỷ giá 1 hoặc tỷ giá của currency được truyền vào. Chứng từ tiền (BankPayment, CashReceipt…) sau dòng đó còn xử lý `FillingData` kiểu `DocumentRef.SupplierInvoice` / `DocumentRef.SalesInvoice` — đó là "nhập dựa trên" (`BasedOn` trong `.xml`, Bài 16).

### 10.7. Print forms

Wiring theo SSL Print (Bài 22):

1. `PrintManagementOverridable.OnDefinePrintSettings` thêm manager Document vào `Settings.PrintObjects`.
2. Manager module của Document: `OnDefinePrintSettings` đặt `Settings.OnAddPrintCommands = True`; `AddPrintCommands` thêm lệnh in.
3. Template trong `Templates/` của Document: `PF_MXL_<Tên>` (SpreadsheetDocument có tham số kiểu `[Customer.LegalName]`, `[Inventory.Product]`…) và `PrintData` (DataCompositionSchema làm nguồn dữ liệu).

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.Id = "Document.SalesInvoice.PF_MXL_SalesInvoice";
	PrintCommand.Presentation = NStr("en = 'Sales invoice'");
```

Hiện chỉ SalesInvoice (`PF_MXL_SalesInvoice`) và SupplierInvoice (`PF_MXL_GoodsReceivedNote`) có lệnh in; 7 Document còn lại đã đăng ký nhưng `AddPrintCommands` rỗng — chỗ tốt để giao bài tập "thêm print form".

### 10.8. Attachable commands, Properties, Import from file

- **Attachable commands** (SSL): form của Document gọi `AttachableCommands.OnCreateAtServer(ThisObject)` trong `OnCreateAtServer`, `AttachableCommandsClientServer.UpdateCommands` trong `OnReadAtServer`, và có bộ handler `Attachable_ExecuteCommand` / `Attachable_ContinueCommandExecutionAtServer` / `Attachable_UpdateCommands`. Các procedure trong `AttachableCommandsOverridable` của Jet đều rỗng.
- **Properties** (SSL): `PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters)` với `ItemForPlacementName` = "GroupAdditionalAttributes" — dữ liệu nằm ở tabular section `AdditionalAttributes`.
- **Import from file** (SSL ImportDataFromFile): command form `ImportInventoryFromFile` gọi `ImportDataFromFileClient.ShowImportForm` với `FullTabularSectionName` = "SupplierInvoice.Inventory"; template `LoadingFromFile` của Document mô tả cột; manager module có `MapDataToImport` / `FillInListOfAmbiguities` chuyển tiếp sang `ImportDataFromFileJet`. Có ở SupplierInvoice, SalesInvoice, InventoryIncrease và `PricesSetupAuxiliary.ProductPrices`.

### 10.9. `InfobaseUpdateJet`

Jet đăng ký mình với cơ chế cập nhật infobase của SSL qua `ConfigurationSubsystemsOverridable.OnAddSubsystems` (mục 3.2). Trong module:

Nguồn: Jet — cf/CommonModules/InfobaseUpdateJet/Ext/Module.bsl
```bsl
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "Jet";
	LongDesc.Version = "1.0.2.1";
	LongDesc.DeferredHandlersExecutionMode = "Sequentially";
	
	LongDesc.RequiredSubsystems1.Add("StandardSubsystems");
	
EndProcedure
// ...
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version			= "1.0.2.1";
	Handler.InitialFilling	= False;
	Handler.ExecutionMode	= "Exclusively";
	Handler.Procedure		= "InfobaseUpdateJet.UpdatePredefinedContactInformationKinds";
	
EndProcedure
```

Khi nhóm sinh viên thêm dữ liệu cần khởi tạo (ví dụ predefined item mới, giá trị mặc định cho attribute mới), đây là chỗ thêm handler — nhớ tăng version của configuration cho khớp `Handler.Version` [suy luận: theo cách SSL so version infobase với version handler].

## 11. Cách tự tìm đường trong Jet

Đường dẫn tính từ thư mục `cf/` (dump) — trong Designer là cây Configuration tương ứng.

| Muốn biết / sửa | Xem ở đâu |
|---|---|
| Document X post vào register nào | `Documents/X.xml` → `<RegisterRecords>`; rồi `Documents/X/Ext/ObjectModule.bsl` → `Posting` |
| Bản ghi register được tính thế nào | `Documents/X/Ext/ManagerModule.bsl` → `InitializeDocumentData` (query) — đếm thứ tự query để khớp `QueryResult[n]` |
| Thêm register mới cho một Document | (1) tạo register; (2) thêm vào `RegisterRecords` của Document; (3) thêm query + `TableForRegisterRecords.Insert("Table<Reg>", …)` trong manager module; (4) thêm `Reflect<Reg>` vào `PostingManagement` theo mẫu; (5) gọi nó trong `Posting`; (6) cấp quyền trong role `Use<Subsystem>` |
| Cấu trúc register (dimension/resource) | `AccumulationRegisters/<Reg>.xml` |
| Kiểm tra âm kho | `AccumulationRegisters/InventoryInWarehouses/Ext/RecordSetModule.bsl` + `ManagerModule.bsl` |
| Giá vốn, post lại chứng từ xuất | `Documents/SalesInvoice/Ext/ManagerModule.bsl`, `Sequences/InventoryCostRecalculation.xml`, `DataProcessors/InventoryCostRecalculation` |
| Giá bán theo PriceType | `InformationRegisters/Prices.xml`, `CommonModules/PriceManagementServerCall`, `DataProcessors/PricesSetup` |
| Tỷ giá, presentation currency | `CommonModules/JetServer` (`GetPresentationCurrency`), `CommonModules/CashManagementServerCall`, `CommonModules/ObjectFillingJet` |
| Tính Amount/VAT trên dòng hàng | `CommonModules/InventoryTabularSectionClientServer`, form `DocumentForm` → region `FormTableItemsEventHandlersInventory` |
| Giá trị mặc định khi tạo chứng từ | `CommonModules/ObjectFillingJet`; nhập dựa trên: event `Filling` của chứng từ tiền + `<BasedOn>` trong `.xml` |
| Kiểm tra bắt buộc nhập | `FillCheckProcessing` trong object module (ví dụ BankPayment bỏ kiểm tra `Counterparty` khi Operation = Other) và `FillCheckProcessingAtServer` trong form |
| Giao diện form, ẩn/hiện item | `Documents/X/Forms/DocumentForm/Ext/Form.xml` (item) + `Form/Module.bsl` → `FormManagement()` |
| Print form | `CommonModules/PrintManagementOverridable`, manager module → `AddPrintCommands`, `Documents/X/Templates/PF_MXL_*` |
| Report | `Reports/<R>/Templates/MainDataCompositionSchema` (mở bằng DCS designer) |
| Object thuộc subsystem/menu nào | `Subsystems/<S>.xml` và `Subsystems/<S>/Subsystems/*.xml` → `<Content>` |
| Quyền | `Roles/Use<Subsystem>` |
| Một module là của Jet hay SSL | Danh sách 14 module ở mục 3.1 là Jet; còn lại là SSL. Trong module SSL `*Overridable`, code Jet là dòng không bị comment có nhắc tới object Jet |
| Thêm update handler / dữ liệu khởi tạo | `CommonModules/InfobaseUpdateJet` → `OnAddUpdateHandlers` |

Mẹo thực hành:

- Bắt đầu đọc từ **một Document** của subsystem nhóm mình: `.xml` → object module → manager module → form module. Ba file đầu thường dưới 250 dòng.
- Tìm "ai gọi hàm này": trong Designer dùng Edit → Find in all modules (hoặc grep thư mục `cf/` nếu làm việc với dump).
- Không sửa module SSL (trừ `*Overridable`) — đó là thư viện; nếu cần thay hành vi, ưu tiên extension (upgrade-safe customization, xem file bài Extensions).
- Đặt breakpoint ở `PostingManagement.WriteRecordSets` rồi post một chứng từ để xem `AdditionalProperties.TableForRegisterRecords` trong Expression window (Bài 8) — cách nhanh nhất để hiểu dữ liệu đi vào register.
