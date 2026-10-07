# Thêm đối tượng mới vào Jet đúng cách

Khi nào đọc file này: nhóm sinh viên chuẩn bị thêm Document / Catalog / Report mới vào một subsystem của Jet (Warehouses, Purchases, Sales, CashManagement), phân vân nên sửa thẳng configuration hay làm Extension, hoặc thêm xong mà object "không hiện", "không in được", "Access violation!".

Phiên bản: repo `1Ci-Company/Jet`, nhánh `community`, commit 80884de, configuration `Jet` 1.0.2.1, Compatibility mode `Version8_3_24`. Code và XML chép nguyên văn từ dump `cf/`. Chỗ nào là suy luận được đánh dấu **[suy luận]**.

## Mục lục

1. [Phương pháp: lần theo một Document có sẵn](#1-phương-pháp-lần-theo-một-document-có-sẵn)
2. [Bản đồ touchpoint của InventoryTransfer](#2-bản-đồ-touchpoint-của-inventorytransfer)
3. [Chi tiết từng touchpoint](#3-chi-tiết-từng-touchpoint)
4. [Hai chiến lược: sửa trực tiếp hay Extension](#4-hai-chiến-lược-sửa-trực-tiếp-hay-extension)
5. [Checklist: Thêm một Document mới](#5-checklist-thêm-một-document-mới)
6. [Checklist: Thêm một Catalog mới](#6-checklist-thêm-một-catalog-mới)
7. [Checklist: Thêm một Report (DCS) mới](#7-checklist-thêm-một-report-dcs-mới)
8. [Lỗi thường gặp](#8-lỗi-thường-gặp)

---

## 1. Phương pháp: lần theo một Document có sẵn

Một Document trong Jet không chỉ là `Documents/<Tên>.xml` + module. Vì Jet được xây trên **SSL (Standard Subsystems Library)**, document còn phải được "đăng ký" ở nhiều chỗ khác: subsystem, role, defined type, event subscription, module Overridable… Cách chắc chắn nhất để biết phải đăng ký ở đâu là **tìm mọi chỗ nhắc tới một document mẫu** bên ngoài thư mục của chính nó:

```bash
cd cf
grep -rl "InventoryTransfer" . --include=*.xml --include=*.bsl \
  | grep -v "^./Documents/InventoryTransfer"
```

Kết quả (17 file): `Configuration.xml`; `Subsystems/Warehouses/Subsystems/Warehouse.xml`, `Subsystems/InternalSubsystem.xml`; `Roles/UseWarehouses`, `Roles/FullAccess`; `CommonModules/PrintManagementOverridable`, `CommonModules/PropertyManagerOverridable`; `Catalogs/InventoryTransferAttachedFiles.xml`; `DefinedTypes/` `AttachedFile`, `AttachedFileObject`, `AttachedFilesOwner`, `ReminderSubject`, `ReminderSubjectObject`; `EventSubscriptions/` `DetermineAttachedFileForm`, `SetDeletionMarkForAttachedDocumentFiles`; `ExchangePlans/InfobaseUpdate/Ext/Content.xml`; `Sequences/InventoryCostRecalculation.xml`.

Đây là **danh sách việc phải làm** khi thêm một document kho tương tự. Với nhóm Purchases/Sales, hãy chạy lại lệnh với `SupplierInvoice` / `SalesInvoice` — hai document này có thêm vài touchpoint (mục 3.10).

Mẹo: chạy lệnh tương tự cho object mới của nhóm sau khi làm xong, rồi so số file với document mẫu — thiếu file nào là thiếu bước đăng ký đó.

---

## 2. Bản đồ touchpoint của InventoryTransfer

| # | Touchpoint | File | Ai sở hữu | Bắt buộc cho document mới? |
|---|---|---|---|---|
| 1 | Danh sách object của configuration | `Configuration.xml` | platform | Có — [suy luận] Designer tự thêm khi tạo object |
| 2 | Subsystem Content | `Subsystems/Warehouses/Subsystems/Warehouse.xml` | Jet | Có — để hiện trên giao diện |
| 3 | Role nghiệp vụ | `Roles/UseWarehouses/Ext/Rights.xml` | Jet | Có |
| 4 | Role FullAccess | `Roles/FullAccess/Ext/Rights.xml` | SSL role | Có — bỏ InteractiveDelete |
| 5 | Print subsystem | `CommonModules/PrintManagementOverridable` | SSL Overridable, có code Jet | Có nếu muốn nút Print |
| 6 | Additional attributes (Properties) | `CommonModules/PropertyManagerOverridable` | SSL Overridable, có code Jet | Có nếu copy form từ document mẫu |
| 7 | Catalog attached files | `Catalogs/InventoryTransferAttachedFiles.xml` | Jet | Tuỳ chọn (Files operations) |
| 8 | Defined types file | `DefinedTypes/AttachedFile*.xml` | SSL | Đi kèm #7 |
| 9 | Event subscriptions file | `EventSubscriptions/DetermineAttachedFileForm.xml`, `SetDeletionMarkForAttachedDocumentFiles.xml` | SSL | Đi kèm #7 |
| 10 | Exchange plan InfobaseUpdate | `ExchangePlans/InfobaseUpdate/Ext/Content.xml` | SSL | Đi kèm #7 |
| 11 | InternalSubsystem | `Subsystems/InternalSubsystem.xml` | Jet | Đi kèm #7 (nơi chứa catalog kỹ thuật) |
| 12 | Defined types reminder | `DefinedTypes/ReminderSubject*.xml` | SSL | Tuỳ chọn (nhắc việc) |
| 13 | Sequence | `Sequences/InventoryCostRecalculation.xml` | Jet | Có nếu document ghi vào `InventoryCost` |

Những chỗ **không** nhắc tới InventoryTransfer (dễ tưởng là phải sửa nhưng không cần) — xem mục 3.11.

---

## 3. Chi tiết từng touchpoint

### 3.1 Bản thân document: properties quan trọng

Nguồn: Jet — cf/Documents/InventoryTransfer.xml
```xml
			<Posting>Allow</Posting>
			<RealTimePosting>Deny</RealTimePosting>
			<RegisterRecordsDeletion>AutoDeleteOff</RegisterRecordsDeletion>
			<RegisterRecordsWritingOnPost>WriteSelected</RegisterRecordsWritingOnPost>
			<SequenceFilling>AutoFill</SequenceFilling>
			<RegisterRecords>
				<xr:Item xsi:type="xr:MDObjectRef">AccumulationRegister.InventoryInWarehouses</xr:Item>
				<xr:Item xsi:type="xr:MDObjectRef">AccumulationRegister.InventoryCost</xr:Item>
			</RegisterRecords>
			<PostInPrivilegedMode>true</PostInPrivilegedMode>
			<UnpostInPrivilegedMode>true</UnpostInPrivilegedMode>
			<IncludeHelpInContents>false</IncludeHelpInContents>
			<DataLockFields/>
			<DataLockControlMode>Managed</DataLockControlMode>
```

Cần nhân bản cho document mới:
- **Post in privileged mode / Unpost in privileged mode** = true (xem Bài 20). [suy luận] Nhờ vậy role `UseWarehouses` chỉ cấp `Read`/`View` cho register (mục 3.3) mà user vẫn post được; nếu tắt hai property này, role phải có quyền ghi register.
- **DataLockControlMode = Managed** — vì manager module dùng `DataLock` (mục 3.4).
- **SequenceFilling = AutoFill** — đây là giá trị mặc định, mọi document của Jet đều có (kể cả InventoryIncrease, SupplierInvoice, các chứng từ tiền). Bản thân property này **không** đưa document vào sequence; bước quyết định là thêm document vào `Documents` của `Sequence.InventoryCostRecalculation` (3.9).
- Tabular section `AdditionalAttributes` và khối `<Characteristics>` — xem 3.7.
- Attribute `Author` — được điền bởi `ObjectFillingJet.FillDocument` (3.4).

### 3.2 Subsystem Content

Nguồn: Jet — cf/Subsystems/Warehouses/Subsystems/Warehouse.xml
```xml
			<Content>
				<xr:Item xsi:type="xr:MDObjectRef">Document.InventoryIncrease</xr:Item>
				<xr:Item xsi:type="xr:MDObjectRef">Document.InventoryTransfer</xr:Item>
				<xr:Item xsi:type="xr:MDObjectRef">Document.InventoryWriteOff</xr:Item>
			</Content>
```

Document nằm trong subsystem con `Warehouse` của `Warehouses`; catalog nằm trong subsystem con `Catalogs`; report, register, role nằm thẳng trong `Warehouses` (xem 7.3). Một object có thể nằm trong nhiều subsystem (Bài 9). Với document mới: tick vào đúng subsystem con của nhóm mình trong tab Subsystems của object.

### 3.3 Roles và mẫu quyền

**Role nghiệp vụ** của nhóm kho là `UseWarehouses`. Mẫu quyền cho một Document có posting:

Nguồn: Jet — cf/Roles/UseWarehouses/Ext/Rights.xml
```xml
	<setForNewObjects>false</setForNewObjects>
	<setForAttributesByDefault>true</setForAttributesByDefault>
	<independentRightsOfChildObjects>false</independentRightsOfChildObjects>
	<!-- ... -->
	<object>
		<name>Document.InventoryTransfer</name>
		<right>
			<name>Read</name>
			<value>true</value>
		</right>
		<right>
			<name>Insert</name>
			<value>true</value>
		</right>
		<!-- ... -->
```

Danh sách đầy đủ quyền `true` của `Document.InventoryTransfer` trong `UseWarehouses` (đọc từ cùng file): `Read`, `Insert`, `Update`, `Posting`, `UndoPosting`, `View`, `InteractiveInsert`, `Edit`, `InteractiveSetDeletionMark`, `InteractiveClearDeletionMark`, `InteractivePosting`, `InteractivePostingRegular`, `InteractiveUndoPosting`, `InteractiveChangeOfPosted`, `InputByString`. **Không có** `Delete` / `InteractiveDelete` — đúng khuyến nghị Bài 20 (chỉ để quyền xóa ở FullAccess/SystemAdministrator).

Cùng role còn cấp `View` cho `Subsystem.Warehouses` và `Subsystem.Warehouses.Subsystem.Warehouse`, `Read`+`Update` cho `Sequence.InventoryCostRecalculation`, `Read`+`View` cho `AccumulationRegister.InventoryInWarehouses` và `AccumulationRegister.InventoryCost`:

Nguồn: Jet — cf/Roles/UseWarehouses/Ext/Rights.xml
```xml
	<object>
		<name>Subsystem.Warehouses.Subsystem.Warehouse</name>
		<right>
			<name>View</name>
			<value>true</value>
		</right>
	</object>
```

Tổng hợp những gì một role nghiệp vụ phải có cho document mới:
- Quyền trên document (15 quyền như trên).
- `View` trên subsystem cha và subsystem con chứa document (Bài 20: thiếu `View` subsystem thì user không thấy object).
- `Read`/`View` trên các register mà document post vào (và mà form/report đọc).
- `Read` + `Update` trên Sequence nếu document thuộc Sequence.
- Quyền trên catalog `<Tên>AttachedFiles` nếu có (mẫu giống catalog thường: `Read`, `Insert`, `Update`, `View`, `InteractiveInsert`, `Edit`, `InteractiveSetDeletionMark`, `InteractiveClearDeletionMark`, `InputByString`).
- Nếu nhóm khác cần **xem** document của bạn, thêm quyền đọc vào role của họ. Ví dụ `UseCashManagement` chỉ có `Read`, `View`, `InputByString` trên `Document.SupplierInvoice`.

**Role FullAccess** có `setForNewObjects = true` nên object mới tự nhận đủ quyền; việc cần làm là **tắt** `InteractiveDelete` như mọi document của Jet:

Nguồn: Jet — cf/Roles/FullAccess/Ext/Rights.xml
```xml
	<setForNewObjects>true</setForNewObjects>
	<!-- ... -->
	<object>
		<name>Document.InventoryTransfer</name>
		<right>
			<name>InteractiveDelete</name>
			<value>false</value>
		</right>
	</object>
```

Với Catalog, FullAccess còn tắt thêm các quyền trên predefined data (xem 6.2).

### 3.4 Object module và manager module: khung posting của Jet

Đây là **code của Jet** (common module `PostingManagement`, `ObjectFillingJet`), không phải SSL. Document mới nên theo đúng khung này.

Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectFillingJet.FillDocument(ThisObject, FillingData);
	
EndProcedure

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

Phân công:
- **Manager module** — `InitializeDocumentData(Ref, AdditionalProperties)`: khóa dữ liệu (`DataLock`), chạy batch query, đặt các bảng kết quả vào `AdditionalProperties.TableForRegisterRecords` với tên `Table<TênRegister>`.
- **PostingManagement.Reflect<Register>** — đọc bảng `Table<TênRegister>` và `Load` vào record set. Có sẵn: `ReflectPurchases`, `ReflectSales`, `ReflectInventoryInWarehouses`, `ReflectCashBalance`, `ReflectCustomerBalance`, `ReflectSupplierBalance`, `ReflectInventoryCost`.

Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ManagerModule.bsl
```bsl
Procedure InitializeDocumentData(InventoryTransferRef, AdditionalProperties) Export
	
	DocumentObject = InventoryTransferRef.GetObject();
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("AccumulationRegister.InventoryCost");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = DocumentObject.Inventory;
	LockItem.UseFromDataSource("Product", "Product");
	LockItem.SetValue("Warehouse", DocumentObject.Warehouse);
	DataLock.Lock();
	// ...
	QueryResult = Query.ExecuteBatch();
	
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult[6].Unload());
	AdditionalProperties.TableForRegisterRecords.Insert("TableInventoryCost", QueryResult[7].Unload());
	
EndProcedure
```

Tên bảng phải khớp với tên mà `PostingManagement` đọc: `ReflectInventoryInWarehouses` lấy `AdditionalProperties.TableForRegisterRecords.TableInventoryInWarehouses`, thoát nếu `Cancel` hoặc bảng rỗng, rồi `Write = True` và `Load(...)` vào `RegisterRecords.InventoryInWarehouses`. Nếu document mới post vào **register mới** của nhóm, thêm `Reflect<RegisterMới>` vào `PostingManagement` theo đúng mẫu đó (hoặc viết trong object module của mình). `PrepareRecordSetsForWriting` / `WriteRecordSets` là chung cho mọi document, không cần sửa.

`ObjectFillingJet.FillDocument` (code Jet) điền `Author = Users.AuthorizedUser()` và, nếu document có attribute `Currency`, điền tiền tệ/tỷ giá (`Common.HasObjectAttribute` — SSL).
→ Document mới nên có attribute `Author` (kiểu như document mẫu) để handler `Filling` dùng chung được.

### 3.5 Forms: kết nối SSL AttachableCommands và Properties

Cả 3 form (`DocumentForm`, `ListForm`, `ChoiceForm`) của InventoryTransfer đều gọi **AttachableCommands** (module SSL). Đây là điều kiện để nút Print và các command gắn kèm hoạt động (Bài 22).

Nguồn: Jet — cf/Documents/InventoryTransfer/Forms/ListForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure
// ...
// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure
// ...
```

List form còn có `ListOnActivateRow` (gọi `AttachableCommandsClient.StartCommandUpdate`) và 3 procedure `Attachable_ContinueCommandExecutionAtServer`, `ExecuteCommandAtServer`, `Attachable_UpdateCommands`. Ở list form tham số là `Items.List`, ở object form là `Object`.

`DocumentForm` gọi thêm **Properties** (PropertyManager của SSL) để vẽ additional attributes vào group `GroupAdditionalAttributes`:

Nguồn: Jet — cf/Documents/InventoryTransfer/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
EndProcedure
```

Trong DocumentForm các khối `// StandardSubsystems.Properties` còn xuất hiện ở `OnReadAtServer`, `OnOpen`, `NotificationProcessing`, `FillCheckProcessingAtServer`, `BeforeWriteAtServer`, cùng các procedure `Attachable_PropertiesExecuteCommand`, `UpdateAdditionalAttributesDependencies`, `Attachable_OnChangeAdditionalAttribute`, `UpdateAdditionalAttributesItems`. Khối AttachableCommands có ở `OnCreateAtServer`, `OnReadAtServer`, `OnOpen`, `AfterWrite` và 4 procedure `Attachable_*`. Cách an toàn nhất: **copy nguyên form module** của document mẫu sang document mới, giữ nguyên các comment `// StandardSubsystems.…` (Bài 22, Bài 23 đều khuyến nghị đặt code trong service comments).

[suy luận] Form của InventoryTransfer **không** gọi `FilesOperations.OnCreateAtServer` (khác ví dụ Bài 23); hyperlink file đính kèm đến từ common command `AttachedFiles` (Group `FormNavigationPanelGoTo`, Command parameter type `DefinedType.AttachedFilesOwner`) — tức là chỉ cần document có mặt trong defined type là command tự hiện.

### 3.6 Print: PrintManagementOverridable + manager module

**Bước 1 — đăng ký object** (dòng do Jet thêm vào module Overridable của SSL):

Nguồn: Jet — cf/CommonModules/PrintManagementOverridable/Ext/Module.bsl
```bsl
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.PrintObjects.Add(Documents.SupplierInvoice);
	// ...
	Settings.PrintObjects.Add(Documents.InventoryTransfer);
	Settings.PrintObjects.Add(Documents.InventoryWriteOff);
	
EndProcedure
```

**Bước 2 — manager module** của document: InventoryTransfer có khung nhưng **chưa có print command nào** (`AddPrintCommands` rỗng):

Nguồn: Jet — cf/Documents/InventoryTransfer/Ext/ManagerModule.bsl
```bsl
// StandardSubsystems.Print
// ...
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure
// ...
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

// End StandardSubsystems.Print
```

Mẫu có print command thật là SupplierInvoice (template `PF_MXL_GoodsReceivedNote`, kiểu SpreadsheetDocument, kèm template `PrintData` kiểu DataCompositionSchema):

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl
```bsl
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.Id = "Document.SupplierInvoice.PF_MXL_GoodsReceivedNote";
	PrintCommand.Presentation = NStr("en = 'Goods received note'");
	
EndProcedure
```

[suy luận] Ở đây `PrintManager = "PrintManagement"` và Id dạng `Document.<Tên>.PF_MXL_<Template>`; manager module của SupplierInvoice không có procedure `Print` riêng, nên việc in được SSL làm dựa trên template (khác cách viết procedure `Print` trong Bài 22). Muốn chắc chắn, đọc chú thích của `PrintManagement.CreatePrintCommandsCollection` trong SSL (ngoài giáo trình — kiểm tra lại).

**Bước 3** — form đã kết nối AttachableCommands (3.5).

### 3.7 Additional attributes (Properties) và Chart of characteristic types

Ba chỗ phải khớp nhau qua chuỗi `Document_InventoryTransfer`:

(a) Khai báo predefined set trong module Overridable (dòng của Jet):

Nguồn: Jet — cf/CommonModules/PropertyManagerOverridable/Ext/Module.bsl
```bsl
	Set = Sets.Rows.Add();
	Set.Name = "Document_InventoryTransfer";
	Set.Id = New UUID("546bad9f-2907-4f16-99a9-058007509ca2");
```

(b) Khối `Characteristics` trong metadata document, trỏ tới Chart of characteristic types `AdditionalAttributesAndInfo` (Bài 13) qua catalog `AdditionalAttributesAndInfoSets`, lọc theo cùng tên set:

Nguồn: Jet — cf/Documents/InventoryTransfer.xml
```xml
			<Characteristics>
				<xr:Characteristic>
					<xr:CharacteristicTypes from="Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalAttributes">
						<xr:KeyField>Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalAttributes.Attribute.Property</xr:KeyField>
						<xr:TypesFilterField>Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalAttributes.Attribute.PredefinedSetName</xr:TypesFilterField>
						<xr:TypesFilterValue xsi:type="xs:string">Document_InventoryTransfer</xr:TypesFilterValue>
						<!-- ... -->
					<xr:CharacteristicValues from="Document.InventoryTransfer.TabularSection.AdditionalAttributes">
						<xr:ObjectField>Document.InventoryTransfer.TabularSection.AdditionalAttributes.StandardAttribute.Ref</xr:ObjectField>
						<xr:TypeField>Document.InventoryTransfer.TabularSection.AdditionalAttributes.Attribute.Property</xr:TypeField>
						<xr:ValueField>Document.InventoryTransfer.TabularSection.AdditionalAttributes.Attribute.Value</xr:ValueField>
```

(c) Tabular section `AdditionalAttributes` của document (`Property` kiểu `ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo`, `Value` kiểu `Characteristic.AdditionalAttributesAndInfo`, `TextString`) + group `GroupAdditionalAttributes` trên DocumentForm + code form ở 3.5.

Khi copy document mẫu để làm document mới: đổi tên set thành `Document_<TênMới>` ở **cả (a) và (b)**, và [suy luận] tạo **UUID mới** cho `Set.Id` — các set trong Jet đều có UUID khác nhau, không được dùng lại UUID của set mẫu. Cách tạo UUID mới (ví dụ `New UUID()` trong debugger) là ngoài giáo trình — kiểm tra lại.

Functional option liên quan: `UseAdditionalAttributesAndInfo` (Content gồm `Catalog.AdditionalAttributesAndInfoSets`, `ChartOfCharacteristicTypes.AdditionalAttributesAndInfo`, …) — **không** cần thêm document mới vào đây.

### 3.8 Attached files (FilesOperations của SSL)

Jet dùng cách 1 của Bài 23: mỗi owner có catalog riêng `<Tên>AttachedFiles`. Toàn bộ các bước trùng với Bài 23:

| Bước Bài 23 | Chỗ tương ứng trong Jet |
|---|---|
| 1. Tạo catalog `<Tên>AttachedFiles`, bỏ InteractiveDelete trong FullAccess | `Catalogs/InventoryTransferAttachedFiles.xml`; FullAccess có `InteractiveDelete=false` cho catalog này |
| 2. Kiểu của `FileOwner` = ref owner | `cfg:DocumentRef.InventoryTransfer` |
| 5. Defined types `AttachedFile`, `AttachedFileObject` | có |
| 6. Exchange plan `InfobaseUpdate` | có |
| 7. Hai event subscription | `DetermineAttachedFileForm` (catalog manager), `SetDeletionMarkForAttachedDocumentFiles` (document object) |
| 8. Defined type `AttachedFilesOwner` | có `DocumentRef.InventoryTransfer` |
| 9. `AttachedFilesOwnerObject` (chỉ khi owner không phải document) | Document → không có; Catalog `Warehouses` thì có (6.2) |

Nguồn: Jet — cf/Catalogs/InventoryTransferAttachedFiles.xml
```xml
					<Name>FileOwner</Name>
					<!-- ... -->
					<Type>
						<v8:Type>cfg:DocumentRef.InventoryTransfer</v8:Type>
					</Type>
```

Ba defined type (SSL) mỗi file thêm đúng một dòng: `AttachedFile` ← `cfg:CatalogRef.InventoryTransferAttachedFiles`, `AttachedFileObject` ← `cfg:CatalogObject.InventoryTransferAttachedFiles`, `AttachedFilesOwner` ← `cfg:DocumentRef.InventoryTransfer`.

Nguồn: Jet — cf/EventSubscriptions/DetermineAttachedFileForm.xml
```xml
				<v8:Type>cfg:CatalogManager.InventoryTransferAttachedFiles</v8:Type>
				<!-- ... -->
			<Event>FormGetProcessing</Event>
			<Handler>CommonModule.FilesOperationsClientServer.DetermineAttachedFileForm</Handler>
```

Nguồn: Jet — cf/EventSubscriptions/SetDeletionMarkForAttachedDocumentFiles.xml
```xml
			<Source>
				<v8:Type>cfg:DocumentObject.BankReceipt</v8:Type>
				<!-- ... -->
				<v8:Type>cfg:DocumentObject.InventoryTransfer</v8:Type>
				<!-- ... -->
			</Source>
			<Event>BeforeWrite</Event>
			<Handler>CommonModule.FilesOperations.SetAttachedDocumentFilesDeletionMark</Handler>
```

Lưu ý: tên handler trong Jet là `SetAttachedDocumentFilesDeletionMark`; bảng trong Bài 23 ghi `SetDeletionMarkForAttachedDocumentFiles` (trùng tên subscription). Khi làm bài, tick thêm type vào subscription **có sẵn** chứ không tạo subscription mới.

Exchange plan `InfobaseUpdate` có item `<Metadata>Catalog.InventoryTransferAttachedFiles</Metadata>` với `<AutoRecord>Deny</AutoRecord>`; `Subsystems/InternalSubsystem.xml` có `Catalog.InventoryTransferAttachedFiles` trong Content. `InternalSubsystem` có `IncludeInCommandInterface = false` — nơi Jet gom các catalog kỹ thuật để chúng không hiện trên giao diện.

Manager module của catalog file (code SSL, copy nguyên từ catalog mẫu) có `OnFillAccessRestriction` với text `AllowRead WHERE ObjectReadingAllowed(FileOwner)` / `AllowUpdateIfReadingAllowed WHERE ObjectUpdateAllowed(FileOwner)` — [suy luận] quyền trên file đính kèm đi theo quyền trên owner.

### 3.9 Reminder và Sequence

**Reminder** (nhắc việc của SSL): document có trong hai defined type. Common command `Remind` có Command parameter type `DefinedType.ReminderSubject`, nên [suy luận] thêm document vào defined type là command "Remind" tự hiện trên form.

Hai dòng tương ứng: `cfg:DocumentRef.InventoryTransfer` trong `DefinedTypes/ReminderSubject.xml`, `cfg:DocumentObject.InventoryTransfer` trong `DefinedTypes/ReminderSubjectObject.xml`.

**Sequence** `InventoryCostRecalculation` (object của Jet) gom các document làm giảm giá vốn để data processor `InventoryCostRecalculation` tính lại:

Nguồn: Jet — cf/Sequences/InventoryCostRecalculation.xml
```xml
			<MoveBoundaryOnPosting>Move</MoveBoundaryOnPosting>
			<Documents>
				<xr:Item xsi:type="xr:MDObjectRef">Document.InventoryTransfer</xr:Item>
				<xr:Item xsi:type="xr:MDObjectRef">Document.InventoryWriteOff</xr:Item>
				<xr:Item xsi:type="xr:MDObjectRef">Document.SalesInvoice</xr:Item>
			</Documents>
			<RegisterRecords>
				<xr:Item xsi:type="xr:MDObjectRef">AccumulationRegister.InventoryCost</xr:Item>
			</RegisterRecords>
```

Sequence không có trong giáo trình 24 bài. [suy luận] Quy tắc thực tế: document mới nào **xuất kho có tính giá vốn** (ghi `Expense` vào `InventoryCost`) thì thêm vào `Documents` của sequence này (`SequenceFilling = AutoFill` là mặc định, không cần đổi); `InventoryIncrease` và `SupplierInvoice` (nhập kho) không có trong sequence. Cơ chế boundary của sequence — ngoài giáo trình, kiểm tra lại.

### 3.10 Touchpoint chỉ có ở SupplierInvoice / SalesInvoice

Chạy lệnh ở mục 1 với `SupplierInvoice`, `SalesInvoice` thấy thêm:

| Touchpoint | Ý nghĩa | Cần cho document mới khi… |
|---|---|---|
| `DefinedTypes/InteractionSubject.xml`, `CommonModules/InteractionsClientServerOverridable` | document làm "subject" cho Interactions (email, call…) | muốn gắn email/cuộc gọi vào document |
| `DefinedTypes/MessageTemplateSubject.xml` + khối `// StandardSubsystems.MessagesTemplates` trong manager module | message templates | muốn gửi email theo mẫu |
| `DefinedTypes/NotesSubject*.xml`, `ObjectWithAdditionalCommands.xml`, `EventSubscriptions/SetDocumentDeletionMarkChangeStatus.xml` | Notes (chỉ SalesInvoice) | muốn ghi chú gắn document |
| `FilterCriteria/RelatedDocuments.xml` | "Related documents" | document được document khác tham chiếu (ví dụ tabular section `AdvanceClearing`, `PaymentDetails`) |
| `Ext/MainSectionCommandInterface.xml` | command `OpenList` trên trang chính | muốn hiện ở main section |
| `AccumulationRegisters/Purchases.xml`, `SupplierBalance.xml`… | dimension có kiểu `DocumentRef.SupplierInvoice` | register của bạn có dimension kiểu document |
| Templates `LoadingFromFile` + khối `// StandardSubsystems.ImportDataFromFile` | import tabular section từ file | cần import dòng hàng từ Excel |

Ví dụ `InteractionsClientServerOverridable.OnDeterminePossibleSubjects` của Jet chỉ có hai dòng `SubjectsTypes.Add("DocumentRef.SalesInvoice");` và `SubjectsTypes.Add("DocumentRef.SupplierInvoice");`.

### 3.11 Những nơi KHÔNG cần sửa cho document mới

Đã kiểm tra trong dump — InventoryTransfer (và các document nghiệp vụ khác) **không** xuất hiện ở:

- **DocumentJournals**: Jet chỉ có journal `Interactions` (của SSL, chứa Meeting, PhoneCall, IncomingEmail…). Không có journal cho document nghiệp vụ. Nhóm muốn có journal kiểu Bài 13 thì tạo mới.
- **FunctionalOptions**: không option nào chứa document nghiệp vụ.
- **CommonAttributes**: chỉ có `EditedPredefinedAttributes` (SSL), Content là các catalog SSL.
- **CommonCommands**: không command nào nêu tên document; chúng nhận document qua **DefinedTypes** (ví dụ `AttachedFiles` ← `AttachedFilesOwner`, `Remind` ← `ReminderSubject`, `CreateSubjectNote` ← `NotesSubject`). Vì vậy "đăng ký command" = thêm type vào defined type.
- **AccessManagementOverridable**: mọi procedure rỗng, chỉ có `SimplifiedInterface = True`. Jet không khai báo access kinds/record-level restriction cho document → không cần đăng ký.
- **AttachableCommandsOverridable**, **ObjectsFillingOverridable**: chỉ có procedure rỗng / comment.
- **FilesOperationsOverridable**: chỉ có dòng comment ví dụ.
- **InfobaseUpdateJet** (module Jet): chỉ có một update handler `UpdatePredefinedContactInformationKinds`; không cần sửa trừ khi nhóm cần điền dữ liệu khi cập nhật version (ngoài giáo trình — kiểm tra lại cách viết update handler).
- **ReportsOptionsOverridable**: chỉ đăng ký report (xem 7.2), không đăng ký document.

---

## 4. Hai chiến lược: sửa trực tiếp hay Extension

### 4.1 Bối cảnh của Jet

- Jet là mã nguồn mở, **MIT License** (`LICENSE`: "Copyright (c) 2025 1Ci (1C International)"). Trang Wiki *Contributing* hướng dẫn: fork `1Ci-Company/Jet` → làm việc trên nhánh `community` → commit, push lên fork → mở pull request vào `community`. Mỗi nhóm có thể **fork** và sửa thoải mái.
- Cách cài từ repository (Wiki): tạo infobase rỗng → Designer → *Configuration - Open configuration* → *Configuration - Restore configuration from files* trỏ tới thư mục `cf` → *Debug - Start debugging*. Tức là nhóm làm việc trực tiếp trên configuration chính.
- Dump có `cf/Ext/ParentConfigurations/Jet.cf` và `Configuration.xml` khai báo `ConfigurationExtensionCompatibilityMode = Version8_3_24`.
- Nhiều touchpoint ở mục 3 là **object của SSL** (defined types, event subscriptions, module `*Overridable`). Bài 21: muốn sửa object SSL phải bật khả năng thay đổi trong *Configuration - Support - Support options*. [suy luận] Nếu sau khi restore, Designer không cho sửa các object này (biểu tượng khóa), làm theo Bài 21; việc infobase restore từ dump có đang "under support" hay không — ngoài giáo trình, kiểm tra lại.

### 4.2 Chiến lược A — sửa trực tiếp configuration Jet (trên fork)

Ưu điểm cho đồ án sinh viên:
- Đi đúng checklist mục 5–7: mọi touchpoint (subsystem Content, roles, defined types, event subscription Source, `*Overridable`) đều sửa được ngay trong Designer.
- Code nằm trong repo Git của nhóm (dump `cf/`), review bằng diff, có thể gửi PR ngược về Jet theo Wiki *Contributing*.
- Không phải học thêm các ràng buộc của adopted object, safe mode, restructure DB.

Nhược điểm:
- Bốn nhóm cùng sửa các file dùng chung (`PrintManagementOverridable`, `PropertyManagerOverridable`, `DefinedTypes/*`, `Roles/FullAccess`) → dễ **xung đột khi merge** nếu dùng chung một repo. [suy luận] Nên mỗi nhóm một fork/nhánh, hoặc thống nhất ai sửa file chung lúc nào.
- Khi Jet ra version mới, phải tự so sánh/merge thay đổi (đây chính là vấn đề mà Bài Extensions nói extension giải quyết).

### 4.3 Chiến lược B — Extension (Customization hoặc Add-on)

Theo Bài Extensions, extension là **upgrade-safe customization**: mở rộng configuration mà không sửa nó. Chọn Purpose:
- **Customization** — điều chỉnh Jet theo yêu cầu cụ thể (ví dụ thêm attribute cho document có sẵn của nhóm, sửa form, thêm logic sau khi post).
- **Add-on** — tính năng mới ít gắn với version (ví dụ bộ report mới cho subsystem).
- **Patch** — sửa lỗi; không phải mục đích của đồ án.

Extension làm được (Bài Extensions): tạo object mới; adopt object có sẵn để thêm attributes, tabular sections, commands, templates, sửa form; mở rộng procedure/function bằng "Before" / "After" / `&Around` / `&ChangeAndValidate`. Object mới tự mang **prefix** (ví dụ `crm_`), role mặc định `<prefix>DefaultRole`.

Giới hạn **có trong giáo trình** cần biết trước khi chọn extension:
- Property **Name** của adopted object luôn là *controlled*; các property *controlled* khác (ví dụ "Hierarchical", "Code Type") không khớp thì extension **không áp dụng được** → không đổi được các property đó của object Jet qua extension.
- Extension mặc định chạy **safe mode**: chỉ cho mở rộng form handlers; mở rộng method trong **manager module** (ví dụ `InitializeDocumentData` của Jet) phải tắt safe mode.
- "Before"/"After" **không dùng cho function**; dùng `&Around` + `ProceedWithCall()`.
- Adopt tabular section không adopt attributes của nó; adopt form chưa làm việc được với form attributes/commands cho đến khi adopt attribute `Object`. Khuyến nghị sửa form **bằng code** (`Items.Add()`, `ChangeAttributes()`…).
- Thêm attribute vào object Jet qua extension → restructure DB; xóa extension → dữ liệu của attribute đó **mất vĩnh viễn**.
- Giá trị mặc định của parameter không chuyển sang extension.

Điểm **không có trong giáo trình** (ngoài giáo trình — kiểm tra lại): extension có thể thêm type mới vào một **defined type** có sẵn của Jet/SSL không (giáo trình chỉ nói defined type được adopt *by reference*); có thể thêm object vào **Source** của event subscription có sẵn, vào **Content** của subsystem có sẵn, vào **Documents** của Sequence `InventoryCostRecalculation`, hay sửa quyền trong role `UseWarehouses` có sẵn không. Đây đúng là các touchpoint ở mục 3 — nếu không làm được thì phải viết lại bằng object riêng của extension (subsystem riêng, role riêng, event subscription riêng) hoặc mở rộng procedure `*Overridable` bằng "After".

[suy luận] Hướng mở rộng module `*Overridable` từ extension: adopt `PrintManagementOverridable` rồi mở rộng `OnDefinePrintSettings` bằng "After" để `Settings.PrintObjects.Add(Documents.<prefix>TênMới)`. Theo giáo trình, đây là method của common module (không phải form handler) nên cần tắt safe mode như trường hợp manager module — kiểm tra lại.

### 4.4 Khuyến nghị cho đồ án

| Tiêu chí | A. Sửa trực tiếp (fork) | B. Extension |
|---|---|---|
| Độ khó với sinh viên vừa học 24 bài | Thấp — giống các bài thực hành | Cao hơn — thêm adopted object, safe mode, prefix |
| Đăng ký vào SSL (defined types, subscriptions, Overridable) | Làm trực tiếp | Phần lớn ngoài giáo trình, phải tự kiểm chứng |
| Cập nhật khi Jet ra version mới | Phải merge tay | Upgrade-safe (mục đích của extension) |
| Phù hợp cho | Document/Catalog mới gắn chặt vào posting, role, print | Report mới (Add-on), attribute/form/logic thêm cho object có sẵn (Customization) |

[suy luận] Với đồ án một học kỳ: dùng **A** cho phần lõi (document/catalog/register mới của subsystem), có thể làm thêm một **extension Add-on** nhỏ (ví dụ một report DCS) để luyện Bài Extensions.

---

## 5. Checklist: Thêm một Document mới

Mẫu để bắt chước: **InventoryTransfer** (document kho, 2 register, sequence). Nhóm Purchases/Sales nhìn thêm SupplierInvoice/SalesInvoice; nhóm CashManagement nhìn CashReceipt/BankPayment.

**A. Metadata**
1. Copy document mẫu (hoặc tạo mới) → đặt Name, Synonym. Nếu copy: đổi `Documents.InventoryTransfer.InitializeDocumentData` trong object module thành tên document mới.
2. Attributes header, tabular section hàng (mẫu: `Warehouse`, `WarehouseReceiver`, `Comment`, `Author`, tabular section `Inventory` với `Product`, `Quantity`).
3. Tab Posting: `Posting = Allow`, chọn Register records; **Post in privileged mode** và **Unpost in privileged mode** = true (3.1).
4. `DataLockControlMode = Managed`.
5. Tabular section `AdditionalAttributes` + khối Characteristics với `TypesFilterValue = Document_<TênMới>` (3.7).
6. Forms: `DocumentForm`, `ListForm`, `ChoiceForm` — copy từ document mẫu để giữ code SSL; DocumentForm phải có group `GroupAdditionalAttributes`.

**B. Code**

7. Object module: `Filling` → `ObjectFillingJet.FillDocument`; `Posting` / `UndoPosting` theo khung `PostingManagement` (3.4).
8. Manager module: `InitializeDocumentData` (DataLock + batch query → `TableForRegisterRecords.Table<Register>`); khối `// StandardSubsystems.Print` với `OnDefinePrintSettings` (`OnAddPrintCommands = True`) và `AddPrintCommands`.
9. Register mới → thêm `Reflect<Register>` vào `PostingManagement` (mẫu `ReflectInventoryInWarehouses`).
10. Kiểm soát tồn âm (nếu xuất kho): gọi `AccumulationRegisters.InventoryInWarehouses.NegativeBalanceControl` như mẫu.

**C. Đăng ký**

11. Subsystem: thêm vào Content của subsystem con của nhóm (mẫu `Warehouses.Warehouse`).
12. Role nhóm (`UseWarehouses` / `UsePurchases` / `UseSales` / `UseCashManagement`): 15 quyền document, `View` subsystem, `Read`/`View` register, quyền Sequence nếu có (3.3).
13. FullAccess: `InteractiveDelete = false` cho document.
14. `PrintManagementOverridable.OnDefinePrintSettings`: `Settings.PrintObjects.Add(Documents.<TênMới>)`.
15. `PropertyManagerOverridable.OnGetPredefinedPropertiesSets`: set `Document_<TênMới>` với UUID mới.
16. Sequence `InventoryCostRecalculation`: thêm nếu document ghi Expense vào `InventoryCost` (3.9).

**D. Tuỳ chọn SSL**

17. Attached files: catalog `<TênMới>AttachedFiles` (copy `InventoryTransferAttachedFiles`, đổi kiểu `FileOwner`) → `InternalSubsystem` → defined types `AttachedFile`, `AttachedFileObject`, `AttachedFilesOwner` → `InfobaseUpdate` → hai event subscription → FullAccess `InteractiveDelete = false` → role nhóm quyền trên catalog (3.8).
18. Reminder: `ReminderSubject` + `ReminderSubjectObject`.
19. Interactions / message templates / notes / import from file: theo bảng 3.10.

**E. Kiểm tra**

20. `grep -rl "<TênMới>" cf ...` (mục 1) và so với document mẫu.
21. Chạy Enterprise mode bằng **user chỉ có role nhóm** (không FullAccess): mở list, tạo, post, unpost, in, đính kèm file.

---

## 6. Checklist: Thêm một Catalog mới

Mẫu: **Warehouses** (catalog của nhóm kho, có additional attributes, contact information, attached files). Kết quả grep (mục 1) cho `Catalog.Warehouses` / `CatalogRef.Warehouses` / `Catalog_Warehouses`… ngoài thư mục của nó: các register và document dùng nó làm kiểu, `PropertyManagerOverridable`, `DefinedTypes/AttachedFilesOwner`, `AttachedFilesOwnerObject`, `ContactInformationOwner`, report `AvailableStock`, `Roles/FullAccess`, `Roles/UseWarehouses`, `Subsystems/Warehouses/Subsystems/Catalogs.xml`.

### 6.1 Các bước

1. Tạo catalog, đặt `CodeLength`, `DescriptionLength`, hierarchy (Warehouses: `Hierarchical = false`, `CodeLength = 9`, `DescriptionLength = 50`).
2. Forms `ItemForm`, `ListForm`, `ChoiceForm` — copy từ Warehouses (code AttachableCommands + Properties, thêm ContactInformation nếu cần).
3. Subsystem: thêm vào subsystem con `Catalogs` của nhóm.
4. Role nhóm: `Read`, `Insert`, `Update`, `View`, `InteractiveInsert`, `Edit`, `InteractiveSetDeletionMark`, `InteractiveClearDeletionMark`, `InputByString` (mẫu `Catalog.Warehouses` trong `UseWarehouses`) + `View` subsystem `Catalogs`.
5. FullAccess: tắt `InteractiveDelete` và các quyền predefined (6.2).
6. Additional attributes: set `Catalog_<TênMới>` trong `PropertyManagerOverridable` + Characteristics với `TypesFilterValue` cùng tên + tabular section `AdditionalAttributes`.
7. Attached files (tuỳ chọn): như document, nhưng owner là catalog → thêm `CatalogRef` vào `AttachedFilesOwner` **và** `CatalogObject` vào `AttachedFilesOwnerObject` (Bài 23 bước 9); **không** thêm vào subscription `SetDeletionMarkForAttachedDocumentFiles` (Source của nó chỉ có DocumentObject).
8. Contact information (tuỳ chọn): `DefinedTypes/ContactInformationOwner` + tabular section `ContactInformation` + region trong `ContactsManagerOverridable.OnInitialItemsFilling` (6.3).
9. Dùng catalog làm kiểu attribute/dimension ở document/register của nhóm.

### 6.2 Mẫu quyền FullAccess cho Catalog

Nguồn: Jet — cf/Roles/FullAccess/Ext/Rights.xml
```xml
		<name>Catalog.Warehouses</name>
		<right>
			<name>InteractiveDelete</name>
			<value>false</value>
		</right>
		<right>
			<name>InteractiveDeletePredefinedData</name>
			<value>false</value>
		</right>
		<right>
			<name>InteractiveSetDeletionMarkPredefinedData</name>
			<value>false</value>
		</right>
```

(Trong cùng object còn `InteractiveClearDeletionMarkPredefinedData` và `InteractiveDeleteMarkedPredefinedData` = false — đúng danh sách "không đặt trong role nào" của Bài 20.)

Owner là catalog nên Warehouses có `cfg:CatalogObject.Warehouses` trong `DefinedTypes/AttachedFilesOwnerObject.xml` (document thì không).

### 6.3 Contact information (SSL ContactsManager) — mẫu Warehouses

`ContactsManagerOverridable.OnInitialItemsFilling` có `#Region Warehouses` (code Jet trong module SSL) tạo predefined kind dạng folder `CatalogWarehouses` và kind con `WarehouseActualAddress` (`Item.Parent = "CatalogWarehouses"`, `Item.Type = Enums.ContactInformationTypes.Address`). Và `cfg:CatalogObject.Warehouses` trong `DefinedTypes/ContactInformationOwner.xml`. ContactsManager không có trong giáo trình — ngoài giáo trình, kiểm tra lại trong tài liệu SSL trước khi dùng.

---

## 7. Checklist: Thêm một Report (DCS) mới

Mẫu: **StockStatement**. Grep `StockStatement` ngoài thư mục report chỉ ra 5 file: `ReportsOptionsOverridable`, `Configuration.xml`, `Roles/UseWarehouses`, `Subsystems/Warehouses.xml`, `Subsystems/Warehouses/Ext/CommandInterface.xml`. Report **không có** object module, manager module hay form riêng — chỉ có template DCS và một command.

### 7.1 Report và template DCS

Nguồn: Jet — cf/Reports/StockStatement.xml
```xml
			<UseStandardCommands>true</UseStandardCommands>
			<DefaultForm/>
			<AuxiliaryForm/>
			<MainDataCompositionSchema>Report.StockStatement.Template.MainDataCompositionSchema</MainDataCompositionSchema>
			<DefaultSettingsForm/>
			<AuxiliarySettingsForm/>
			<DefaultVariantForm/>
			<VariantsStorage/>
			<SettingsStorage/>
```

`DefaultForm` để trống → dùng form chung của configuration (SSL):

Nguồn: Jet — cf/Configuration.xml
```xml
			<DefaultReportForm>CommonForm.ReportForm</DefaultReportForm>
```

Template `MainDataCompositionSchema` (Bài 18) có query bắt đầu bằng `SELECT ALLOWED` và **hai settings variant**: `StockStatement` (dùng trong section) và `StockStatementContext` (mở từ form Product, có filter).

### 7.2 Đăng ký report option (ReportsOptionsOverridable — dòng của Jet)

Nguồn: Jet — cf/CommonModules/ReportsOptionsOverridable/Ext/Module.bsl
```bsl
	// Warehouses reports
	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.StockStatement, "StockStatement");
	OptionSettings.LongDesc = NStr("en = 'Opening balance, receipt, consumption, closing balance by products'");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.StockStatement, "StockStatementContext");
	OptionSettings.Enabled = False;
```

Tên option (tham số thứ 3) phải trùng `dcsset:name` của settings variant trong DCS. Variant "Context" được `Enabled = False` — [suy luận] để nó không hiện trong danh sách report của section mà chỉ dùng khi mở bằng command có filter.

### 7.3 Subsystem, command interface, command ngữ cảnh

`Report.StockStatement` nằm trong Content của subsystem cha `Warehouses` (không phải subsystem con). Command interface của subsystem đặt lệnh mở report vào nhóm Reports:

Nguồn: Jet — cf/Subsystems/Warehouses/Ext/CommandInterface.xml
```xml
		<Command name="Report.StockStatement.StandardCommand.Open">
			<CommandGroup>ActionsPanelReports</CommandGroup>
		</Command>
```

Command ngữ cảnh của report (Group `FormNavigationPanelSeeAlso`, Command parameter type `CatalogRef.Products`, Parameter usage mode `Single` — Bài 14) mở variant Context với filter theo product:

Nguồn: Jet — cf/Reports/StockStatement/Commands/OpenStockStatementReport/Ext/CommandModule.bsl
```bsl
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterStructure = New Structure("Product", CommandParameter);
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "StockStatementContext");
	FormParameters.Insert("Filter", FilterStructure);
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	OpenForm("Report.StockStatement.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
```

### 7.4 Quyền

Nguồn: Jet — cf/Roles/UseWarehouses/Ext/Rights.xml
```xml
		<name>Report.StockStatement</name>
		<right>
			<name>Use</name>
			<value>true</value>
		</right>
		<right>
			<name>View</name>
			<value>true</value>
		</right>
```

Command riêng `Report.StockStatement.Command.OpenStockStatementReport` được cấp `View` trong cùng role.

Cộng thêm `Read` trên các register mà query DCS đọc (StockStatement đọc `InventoryCost` — `UseWarehouses` có `Read`/`View`).

### 7.5 Các bước

1. Tạo Report, tạo Main data composition schema (Bài 18); dùng `SELECT ALLOWED` như mẫu.
2. Tạo settings variant chính (+ variant `...Context` nếu cần mở từ form khác).
3. `ReportsOptionsOverridable.CustomizeReportsOptions`: một `OptionDetails` cho mỗi variant, `LongDesc` cho variant chính, `Enabled = False` cho variant context.
4. Thêm report vào Content subsystem cha của nhóm; trong Command interface của subsystem, đặt `StandardCommand.Open` vào nhóm `ActionsPanelReports`.
5. Role nhóm: `Use` + `View` trên report, `View` trên command riêng (nếu có), `Read` trên register nguồn.
6. (Tuỳ chọn) Command ngữ cảnh như `OpenStockStatementReport`.
7. Report panel của section (`CommonCommand.ReportPanelWarehouses` gọi `ReportsOptionsClient.ShowReportBar("Warehouses", ExecutionParameters)`) đã có sẵn cho 4 subsystem — không cần tạo lại.

Nếu làm report bằng **extension Add-on**: report là object mới (có prefix), nhưng bước 3–5 chạm vào object có sẵn (`ReportsOptionsOverridable`, subsystem, role) — xem giới hạn ở 4.3.

---

## 8. Lỗi thường gặp

Chỉ liệt kê lỗi có căn cứ từ wiring ở trên hoặc từ file bài.

| Triệu chứng | Nguyên nhân | Căn cứ | Sửa |
|---|---|---|---|
| "Access violation!" khi mở list/post bằng user thường | Role nhóm chưa có quyền trên object mới. Role `Use*` có `setForNewObjects = false` nên object mới **không** tự nhận quyền | Bài 20; `Roles/Use*/Ext/Rights.xml` | Cấp 15 quyền document / 9 quyền catalog (3.3, 6.1) |
| Access violation khi mở form/report dù đã có quyền document | Thiếu `Read` trên register mà form/query đọc | Bài 20 (lỗi đọc register trong OnCreateAtServer) | Cấp `Read`/`View` register |
| Có quyền nhưng không thấy object trên giao diện | Object chưa vào Content subsystem, hoặc role thiếu `View` trên subsystem (cha **và** con, ví dụ `Subsystem.Warehouses.Subsystem.Warehouse`) | Bài 9, Bài 20 | Sửa subsystem Content + quyền View |
| Admin thấy nút Delete trên object mới | FullAccess có `setForNewObjects = true`, object mới nhận cả `InteractiveDelete` | Bài 20, Bài 23 ("nhớ bỏ quyền interactive deletion… khỏi role FullAccess") | Tắt `InteractiveDelete` (và các quyền predefined cho catalog) |
| Không có nút Print | Thiếu `Settings.PrintObjects.Add(...)` trong `PrintManagementOverridable`, hoặc thiếu `OnAddPrintCommands = True` | Bài 22; 3.6 | Thêm cả hai |
| Nút Print có nhưng bấm không chạy / list form không có lệnh | Form (object form **và** list form) chưa kết nối AttachableCommands | Bài 22; 3.5 | Copy khối `// StandardSubsystems.AttachableCommands` |
| Lỗi thiếu method khi mở list form của object đã thêm vào PrintObjects | Manager module chưa có `OnDefinePrintSettings` | Bài 22 | Thêm khối `// StandardSubsystems.Print` |
| Hyperlink file đính kèm không có / form file không mở / xóa document không đánh dấu file | Thiếu một trong: defined type `AttachedFilesOwner`, `AttachedFile`, `AttachedFileObject`, subscription `DetermineAttachedFileForm` / `SetDeletionMarkForAttachedDocumentFiles`, `InfobaseUpdate` | Bài 23; 3.8 | Đi đủ bảng 3.8 |
| Không có nhóm "Additional attributes" trên form, hoặc attribute thêm cho document mới lại hiện ở document mẫu | [suy luận] `TypesFilterValue` trong Characteristics không khớp `Set.Name` ở `PropertyManagerOverridable`, hoặc copy nguyên set/UUID của document mẫu | 3.7 | Đổi cả hai chỗ thành `Document_<TênMới>`, UUID mới |
| Post lỗi ở `PostingManagement.Reflect…` (không có property `Table…`) | [suy luận] Tên bảng trong `TableForRegisterRecords.Insert("Table<Register>", …)` không khớp tên mà `Reflect<Register>` đọc | 3.4 | Đặt đúng `Table<TênRegister>` |
| Document mới post vào cost nhưng data processor tính lại giá vốn bỏ qua | [suy luận] Document chưa có trong Sequence `InventoryCostRecalculation` | 3.9 | Thêm vào `Documents` của sequence + `SequenceFilling = AutoFill` + quyền Sequence trong role |
| User thường post bị Access violation trên register | [suy luận] Tắt Post in privileged mode trong khi role chỉ có `Read`/`View` register | 3.1, Bài 20 | Giữ privileged mode = true như mẫu, hoặc cấp quyền ghi |
| Report không có mô tả / variant context hiện trong danh sách | Chưa đăng ký trong `ReportsOptionsOverridable` | 7.2 | Thêm `OptionDetails` |
| Copy document mẫu nhưng post ra số liệu của document mẫu | Object module vẫn gọi `Documents.InventoryTransfer.InitializeDocumentData` | 3.4 | Đổi sang `Documents.<TênMới>` |
| (Extension) Không mở rộng được `InitializeDocumentData` / method common module | Safe mode chỉ cho mở rộng form handlers | Bài Extensions | Tắt safe mode, khởi động lại |
| (Extension) Mất dữ liệu attribute thêm vào object Jet | Xóa extension / xóa attribute khỏi extension → restructure | Bài Extensions | Sao lưu trước khi gỡ extension |
| Không sửa được defined type / event subscription / module Overridable | Object SSL đang khóa theo support | Bài 21, Bài 23 | Bật khả năng thay đổi trong Support options |

**Quy tắc vàng**: sau khi thêm object, chạy lại `grep` ở mục 1 cho object mới và cho object mẫu; mỗi file object mẫu có mà object mới không có là một câu hỏi "mình có cần bước này không?" — trả lời bằng bảng mục 2.
