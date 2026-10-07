# ERP_Practice — ứng dụng mẫu "xây từ cấu hình trống" (Jack of All Trades)

> **Khi nào đọc file này:** người học (đặc biệt lộ trình **M** — nhóm MIS xây phân hệ mua/bán/kho/tiền từ cấu hình trống, và Intern Dev) cần **một ứng dụng nhỏ hoàn chỉnh** để tham khảo cách nối Catalog → Document → Register → Report; cần ví dụ posting có kiểm tra tồn kho, giá vốn bình quân, sổ kế toán, characteristics, exchange plan; hoặc cần ý tưởng / khung cho bài tập lớn (BTL). **Không** dùng file này để hướng lộ trình J (Jet) sang cấu trúc khác.

## Nguồn

- Repo `github.com/vuongviet2x/ERP_Practice`, nhánh `master`, commit `de6ec9d` (2026-04-16). Định dạng **1C:EDT** (`Configuration/src/...`, metadata `.mdo`, code `.bsl`). Tên cấu hình trong repo: `Lesson24`; compatibility 8.3.24.
- Đây là cấu hình làm theo sách **1C:Enterprise 8.3 Practical Developer's Guide** (công ty dịch vụ sửa chữa "Jack of All Trades"; file `practical_developer_guide.pdf` trong project). Số "listing" trong ghi chú dưới đây là số trong sách.
- Giảng viên đồng ý dùng repo này làm nguồn mẫu cho skill và cho BTL. Code bên dưới chép nguyên văn; chỗ lệch hoặc lỗi được ghi "[ghi chú ngoài nguồn]".

## Bức tranh nghiệp vụ

Công ty sửa chữa nhận vật tư vào kho (**GoodsReceipt**), kỹ thuật viên thực hiện dịch vụ cho khách và xuất vật tư (**Services**), hệ thống theo dõi tồn kho, giá vốn, doanh thu theo khách/kỹ thuật viên và ghi sổ kế toán.

| Nhóm | Object | Ghi chú |
|---|---|---|
| Danh mục | `Catalog.MaterialsAndServices` (hierarchical; attribute `MaterialServiceType` = Enum Material/Service) | Vật tư và dịch vụ chung một catalog, phân biệt bằng enum |
| | `Catalog.MaterialOptions` (owner: MaterialsAndServices) | "Bộ thuộc tính" của vật tư (màu, tiết diện…) |
| | `Catalog.Customers`, `Catalog.Employees` (Company, StartDate, EndDate, JobTitle), `Catalog.Warehouse` | |
| | `Catalog.AdditionalMaterialProperties` (owner: ChartOfCharacteristicTypes.MaterialProperties), `Catalog.ExtraDimensions` | Giá trị cho characteristics |
| Characteristics | `ChartOfCharacteristicTypes.MaterialProperties` + `InformationRegister.MaterialPropertyValues` (dim PropertySet, PropertyType; res Value) | Thuộc tính động của vật tư (Bài 13) |
| | `ChartOfCharacteristicTypes.ExtraDimensionTypes` | Loại phân tích (extra dimension) cho tài khoản |
| Chứng từ | `Document.GoodsReceipt` (Warehouse; TS `Materials`: Material, Quantity, Price, Total, PropertySet) | Ghi `BalanceOfMaterials`, `CostOfMaterials`, `Primary` |
| | `Document.Services` (Warehouse, Customer, Technician; TS `MaterialsAndServices`: MaterialOrService, Quantity, Price, Total, PropertySet) | Ghi `BalanceOfMaterials`, `CostOfMaterials`, `Sales`, `Primary`; có lệnh Print |
| | `Document.InputOpeningMaterialBalances` (Posting = Deny) | Nhập tồn đầu kỳ: register records nhập tay trên form |
| Register | `AccumulationRegister.BalanceOfMaterials` (Balances; dim Material, Warehouse, PropertySet; res Quantity) | Tồn kho |
| | `AccumulationRegister.CostOfMaterials` (Balances; dim Material; res Cost) | Giá trị tồn — dùng tính giá vốn bình quân |
| | `AccumulationRegister.Sales` (**Turnovers**; dim MaterialOrService, Customer, Technician; res Quantity, Revenue, Cost) | Doanh thu / giá vốn |
| | `InformationRegister.Prices` (periodic, Second; dim MaterialOrService; res Price) | Bảng giá bán theo thời gian |
| | `ChartOfAccounts.Main` (extra dimensions: ExtraDimensionTypes, tối đa 2) + `AccountingRegister.Primary` (res Sum, Quantity) | Kế toán (Bài 24) |
| Khác | `Constant.NumberingPrefix`, `ExchangePlan.Branches` (attribute Main), `DataProcessor.DataExchange`, `ScheduledJob` UpdateIndex / MergeIndexes | Đánh số theo chi nhánh, trao đổi dữ liệu, full-text search |
| Report (DCS) | Materials, MaterialBalanceByProperty, GenericReport, ProfitByCustomer, RevenueByTechnician, ServiceEvaluation, ServiceList, ServicesDocumentRegister, TrialBalance | Xem mục "Report" |
| Phân quyền | Roles Accountant, Administrator, CEO, PayrollAccountant, Technician; subsystems Accounting, Enterprise, `Intventory` (sai chính tả trong nguồn), Payroll, Services | |

### Đối chiếu với giáo trình 24 bài

| Nội dung trong ERP_Practice | Bài |
|---|---|
| Catalog hierarchical, owner, enum | 3–4 |
| Form handler client gọi common module, `Items.<TS>.CurrentData` | 7, 9, 14 |
| Query với temp tables, virtual table `.Balance(...)`, `SliceLast` | 10 |
| Posting ghi accumulation register, kiểm tra tồn khi posting real-time, `LockForUpdate` | 11 |
| `InformationRegister.Prices` + `GetLast` | 12 |
| Constant, chart of characteristic types, characteristics | 13 |
| Common modules (`CatalogProcessing`, `DocumentProcessing`, `Exchange`) | 14 |
| `PresentationGetProcessing`, `OnSetNewCode/OnSetNewNumber` | 16 |
| Print form từ template (command + manager module) | 17 |
| Report DCS | 18 |
| Data processor trao đổi dữ liệu | 19 (data processor) — exchange plan là nội dung **ngoài giáo trình 24 bài** |
| Roles | 20 |
| Chart of accounts + accounting register | 24 |

## Code mẫu

### Đánh số theo chi nhánh (Constant + common module + event)
Nguồn: CommonModules/Exchange/Module.bsl; Catalogs/*/ObjectModule.bsl; Documents/*/ObjectModule.bsl
```bsl
Function GetNumberingPrefix() Export
	Return Constants.NumberingPrefix.Get();
EndFunction
```
```bsl
Procedure OnSetNewCode(StandardProcessing, Prefix)
	Prefix = Exchange.GetNumberingPrefix();
EndProcedure
```
(Documents dùng `OnSetNewNumber(StandardProcessing, Prefix)` với cùng thân.)

### Tính thành tiền dòng và lấy giá bán (common module + form)
Nguồn: CommonModules/DocumentProcessing/Module.bsl; CommonModules/CatalogProcessing/Module.bsl; Documents/Services/Forms/DocumentForm/Module.bsl
```bsl
Procedure CalculateTotal (TabularSectionRow) Export
	TabularSectionRow.Total = TabularSectionRow.Quantity
	* TabularSectionRow.Price;
EndProcedure
```
```bsl
 Function RetailPrice(EffectiveDate, MaterialOrServiceItem) Export
	 //Creating auxiliary Filter object
	 Filter = New Structure("MaterialOrService",
	 MaterialOrServiceItem);
	 //Getting effective register resource values
	 ResourceValues =
	 InformationRegisters.Prices.GetLast(EffectiveDate, Filter);
	 Return ResourceValues.Price;
 EndFunction
```
```bsl
&AtClient
Procedure MaterialsAndServicesMaterialOrServiceOnChange(Item)
	// Getting current tabular section row
	TabularSectionRow = Items.MaterialsAndServices.CurrentData;
	// Setting price
	TabularSectionRow.Price = CatalogProcessing.RetailPrice(Object.Date,
	TabularSectionRow.MaterialOrService);
	//Recalculating row total
	DocumentProcessing.CalculateTotal(TabularSectionRow);
EndProcedure
```
- `RetailPrice` được gọi trực tiếp từ handler `&AtClient`: common module `CatalogProcessing` có cờ **Server** + **Server call** (đọc register ở server). `DocumentProcessing` có cờ **Client (managed application)** + **Server** nên `CalculateTotal` chạy ngay trên client. Khi người học chép mẫu này, nhắc kiểm tra cờ của common module (Bài 7, 14).

### Posting GoodsReceipt — ghi 3 register (wizard + sửa tay)
Nguồn: Documents/GoodsReceipt/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, Mode)
	//{{__REGISTER_REGISTERRECORDS_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.
	
	RegisterRecords.BalanceOfMaterials.Write = True;  
	
	RegisterRecords.CostOfMaterials.Write = True;
	
	RegisterRecords.Primary.Write = True;
	
	For Each CurRowMaterials In Materials Do 
		// register BalanceOfMaterials Receipt
		
		Record = RegisterRecords.BalanceOfMaterials.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Material = CurRowMaterials.Material;
		Record.Warehouse = Warehouse;
		Record.Quantity = CurRowMaterials.Quantity; 
		Record.PropertySet = CurRowMaterials.PropertySet;
		
		
		// register CostOfMaterials Receipt
		
		Record = RegisterRecords.CostOfMaterials.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Material = CurRowMaterials.Material;
		Record.Cost = CurRowMaterials.Total;     
		
		// register Primary
		Record = RegisterRecords.Primary.Add();
		Record.AccountDr = ChartsOfAccounts.Main.Inventory;
		Record.AccountCr = ChartsOfAccounts.Main.AccountsPayable;
		Record.Period = Date;
		Record.Sum = CurRowMaterials.Total;  
		Record.QuantityDr = CurRowMaterials.Quantity;
		Record.ExtDimensionsDr[ChartsOfCharacteristicTypes.ExtraDimensionTypes.Materials] = CurRowMaterials.Material;
	EndDo;
	
	//}}__REGISTER_REGISTERRECORDS_WIZARD
EndProcedure
```
- Code nằm trong khối `//{{__REGISTER_REGISTERRECORDS_WIZARD` nhưng đã sửa tay (PropertySet, CostOfMaterials, Primary): chạy lại Register records wizard sẽ **ghi đè** phần sửa tay — nhắc người học điều này.

### Posting Services — giá vốn bình quân + kiểm tra tồn kho
Nguồn: Documents/Services/ObjectModule.bsl (tương ứng listing 14.x, 15.x, 16.3 của sách)
```bsl
Procedure Posting(Cancel, Mode)
	RegisterRecords.BalanceOfMaterials.Write = True; 
	RegisterRecords.CostOfMaterials.Write = True;    
	RegisterRecords.Sales.Write = True;   
	RegisterRecords.Primary.Write = True;
	
	
	// Creating temporary tables manager
	TTManager = New TempTablesManager;    
	#Region DocumentMaterialAndServices
	Query = New Query;
	// Specifying the temporary tables manager used by the query
	Query.TempTablesManager = TTManager;    
	
	Query.Text = 
	"SELECT
	|	ServicesMaterialsAndServices.MaterialOrService AS MaterialOrService,
	|	ServicesMaterialsAndServices.MaterialOrService.MaterialServiceType AS MaterialServiceType,
	|	SUM(ServicesMaterialsAndServices.Quantity) AS QuantityInDocument,
	|	SUM(ServicesMaterialsAndServices.Total) AS TotalInDocument,
	|	ServicesMaterialsAndServices.PropertySet AS PropertySet
	|INTO DocumentMaterialsAndServices
	|FROM
	|	Document.Services.MaterialsAndServices AS ServicesMaterialsAndServices
	|WHERE
	|	ServicesMaterialsAndServices.Ref = &Ref
	|
	|GROUP BY
	|	ServicesMaterialsAndServices.MaterialOrService,
	|	ServicesMaterialsAndServices.MaterialOrService.MaterialServiceType,
	|	ServicesMaterialsAndServices.PropertySet";
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute(); 
	#EndRegion
	#Region RegisterRecords
	Query2 = New Query;
	Query2.TempTablesManager = TTManager;
	Query2.Text = "SELECT
	|	DocumentMaterialsAndServices.MaterialOrService AS MaterialOrService,
	|	DocumentMaterialsAndServices.MaterialServiceType AS MaterialServiceType,
	|	DocumentMaterialsAndServices.QuantityInDocument AS QuantityInDocument,
	|	DocumentMaterialsAndServices.TotalInDocument AS TotalInDocument,
	|	ISNULL(CostOfMaterialsBalance.CostBalance, 0) AS Cost,
	|	ISNULL(BalanceOfMaterialsBalance.QuantityBalance, 0) AS Quantity,
	|	DocumentMaterialsAndServices.PropertySet AS PropertySet
	|FROM
	|	DocumentMaterialsAndServices AS DocumentMaterialsAndServices
	|		LEFT JOIN AccumulationRegister.CostOfMaterials.Balance(
	|				,
	|				Material IN
	|					(SELECT
	|						DocumentMaterialsAndServices.MaterialOrService
	|					FROM
	|						DocumentMaterialsAndServices)) AS CostOfMaterialsBalance
	|		ON DocumentMaterialsAndServices.MaterialOrService = CostOfMaterialsBalance.Material
	|		LEFT JOIN AccumulationRegister.BalanceOfMaterials.Balance(
	|				,
	|				Material IN
	|					(SELECT
	|						DocumentMaterialsAndServices.MaterialOrService
	|					FROM
	|						DocumentMaterialsAndServices)) AS BalanceOfMaterialsBalance
	|		ON DocumentMaterialsAndServices.MaterialOrService = BalanceOfMaterialsBalance.Material";
	
	
	// Setting data locks for the CostOfMaterials and BalanceOfMaterials registers
	RegisterRecords.CostOfMaterials.LockForUpdate = True;
	RegisterRecords.BalanceOfMaterials.LockForUpdate = True;
	// Writing empty record sets to read balances without the data added by this document
	RegisterRecords.CostOfMaterials.Write();
	RegisterRecords.BalanceOfMaterials.Write();
	
	QueryResult = Query2.Execute();     
	VT = QueryResult.Unload();
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do   
		If SelectionDetailRecords.Quantity = 0 Then
			MaterialCost = 0;
		Else
			MaterialCost = SelectionDetailRecords.Cost / SelectionDetailRecords.Quantity;
		EndIf;
		If SelectionDetailRecords.MaterialServiceType = Enums.MaterialServiceTypes.Material Then    
			// register BalanceOfMaterials Expense
			
			Record = RegisterRecords.BalanceOfMaterials.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Material = SelectionDetailRecords.MaterialOrService;
			Record.Warehouse = Warehouse;
			Record.Quantity = SelectionDetailRecords.QuantityInDocument;   
			Record.PropertySet = SelectionDetailRecords.PropertySet;
			
			
			// register CostOfMaterials Expense
			
			Record = RegisterRecords.CostOfMaterials.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Material = SelectionDetailRecords.MaterialOrService;
			Record.Cost = SelectionDetailRecords.QuantityInDocument * MaterialCost;        
			
			// register Primary
			// First posting: Dr 2000 (AccountsReceivable) – Cr 9000 (Income)
			// Total
			Record = RegisterRecords.Primary.Add();
			Record.AccountDr = ChartsOfAccounts.Main.AccountsReceivable;
			Record.AccountCr = ChartsOfAccounts.Main.Income;
			Record.Period = Date;
			Record.Sum = SelectionDetailRecords.TotalInDocument;
			Record.ExtDimensionsDr[ChartsOfCharacteristicTypes.
			ExtraDimensionTypes.Customers] = Customer;
			// Second posting: Dr 9000 (Income) – Cr 5000 (Inventory) Cost
			Record = RegisterRecords.Primary.Add();
			Record.AccountDr = ChartsOfAccounts.Main.Income;
			Record.AccountCr = ChartsOfAccounts.Main.Inventory;
			Record.Period = Date;
			Record.Sum = MaterialCost * SelectionDetailRecords.QuantityInDocument;
			Record.QuantityCr = SelectionDetailRecords.QuantityInDocument;
			Record.ExtDimensionsCr[ChartsOfCharacteristicTypes.ExtraDimensionTypes.Materials] = SelectionDetailRecords.MaterialOrservice;
		EndIf;   
		// register Sales
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.MaterialOrService =
		SelectionDetailRecords.MaterialOrService;
		Record.Customer = Customer;
		Record.Technician = Technician;
		Record.Quantity = SelectionDetailRecords.QuantityInDocument;
		Record.Revenue = SelectionDetailRecords.TotalInDocument;
		Record.Cost = SelectionDetailRecords.QuantityInDocument
		* MaterialCost;
	EndDo;            
	
	RegisterRecords.Write();
	#EndRegion
	#Region BalanceCheck
	
	If Mode = DocumentPostingMode.RealTime Then
		Query3 = New Query;
		Query3.TempTablesManager = TTManager;
		Query3.Text = "SELECT
		|	BalanceOfMaterialsBalance.Material AS Material,
		|	BalanceOfMaterialsBalance.QuantityBalance AS QuantityBalance,
		|	BalanceOfMaterialsBalance.PropertySet AS PropertySet
		|FROM
		|	AccumulationRegister.BalanceOfMaterials.Balance(
		|			,
		|			Material IN
		|					(SELECT
		|						DocumentMaterialsAndServices.MaterialOrService
		|					FROM
		|						DocumentMaterialsAndServices)
		|				AND Warehouse = &Warehouse) AS BalanceOfMaterialsBalance
		|WHERE
		|	BalanceOfMaterialsBalance.QuantityBalance < 0";   
		Query3.SetParameter("Warehouse", Warehouse);
		QueryResult = Query3.Execute();
		SelectionDetailRecords = QueryResult.Select();  
		While SelectionDetailRecords.Next() Do
			Message = New UserMessage();
			Message.Text = String(- SelectionDetailRecords.QuantityBalance)
			+ " units shortage for """ + SelectionDetailRecords.Material
			+ """ with """ + SelectionDetailRecords.PropertySet
			+ """ property set.";  
			Message.Message();
			
			Cancel = True;
		EndDo;
	EndIf;
	
	#EndRegion
	
EndProcedure
```
Các ý dạy được từ đoạn này:
- **Temp table** (`INTO DocumentMaterialsAndServices` + `TempTablesManager`) để gộp dòng trùng và dùng lại trong nhiều query.
- **Giá vốn bình quân** = `CostBalance / QuantityBalance` đọc từ virtual table `.Balance(...)` (không truyền kỳ → số dư hiện tại).
- **Ghi record set rỗng trước khi đọc số dư** (`RegisterRecords.X.Write()` + `LockForUpdate = True`) để khi re-post không đọc lẫn record cũ của chính chứng từ.
- Dịch vụ (`MaterialServiceType = Service`) chỉ ghi `Sales`, không ghi kho/giá vốn/sổ.
- **Kiểm tra tồn sau khi ghi**: chỉ khi `Mode = DocumentPostingMode.RealTime`; tồn âm → `UserMessage` + `Cancel = True` (phương pháp "ghi rồi kiểm tra").
- [ghi chú ngoài nguồn] Lệch so với sách (listing 15.6): sách lọc số dư theo cặp `(Material, PropertySet) IN (...)`, code trong repo lọc chỉ theo `Material IN (...)` → thông báo thiếu hàng vẫn hiện PropertySet nhưng điều kiện không xét bộ thuộc tính được chọn. Tương tự, giá vốn tính theo Material, không theo PropertySet/Warehouse. Biến `VT` được tạo nhưng không dùng.
- [ghi chú ngoài nguồn] Bút toán thứ hai ghi Dr Income – Cr Inventory cho giá vốn (theo đúng sách, vì sách đơn giản hóa kế toán); không phải cách hạch toán giá vốn thông thường — nói rõ khi người học hỏi về kế toán thật.

### Nhập tồn đầu kỳ: document không posting, đồng bộ ngày register records
Nguồn: Documents/InputOpeningMaterialBalances/ObjectModule.bsl
```bsl
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	// Determining whether updating register record dates is required
	UpdateRegisterRecordsDate = IsNew() Or RegisterRecords.BalanceOfMaterials.Modified();
	If Not UpdateRegisterRecordsDate Then
		// Verifying that the date changed
		Query = New Query;
		Query.SetParameter("CurDocument", Ref);
		Query.Text =
		"SELECT
		| Date
		|FROM
		| Document.InputOpeningMaterialBalances
		|WHERE
		| Ref = &CurDocument";
		Selection = Query.Execute().Select();
		Selection.Next();
		UpdateRegisterRecordsDate = Selection.Date <> Date;
	EndIf;
	// Assigning the new date to all records, if required
	If UpdateRegisterRecordsDate Then
		If Not RegisterRecords.BalanceOfMaterials.Selected() And Not RegisterRecords.BalanceOfMaterials.Modified() Then
			RegisterRecords.BalanceOfMaterials.Read();
		EndIf;
		For Each RegisterRecord In RegisterRecords.BalanceOfMaterials Do
			RegisterRecord.Period = Date;
		EndDo;
	EndIf;
EndProcedure
```
- Document có Posting = **Deny**; register records được nhập trực tiếp trên form (register records là một phần của chứng từ). Form module còn giữ bản handler client `BeforeWrite` đã comment — cách cũ, được thay bằng handler server ở object module.

### Presentation của catalog
Nguồn: Catalogs/MaterialsAndServices/ManagerModule.bsl
```bsl
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	Fields.Add("Description");
	Fields.Add("MaterialServiceType");
EndProcedure     

Procedure PresentationGetProcessing(Data, Presentation,
	StandardProcessing)
	StandardProcessing = False;
	If ValueIsFilled(Data.MaterialServiceType) Then
		Presentation = Data.Description + " (" + Lower(String(Data.MaterialServiceType)) + ")";
	Else
		Presentation = Data.Description;
	EndIf;
EndProcedure
```

### Ẩn cột theo filter khi mở form từ chủ sở hữu
Nguồn: Catalogs/MaterialOptions/Forms/ListForm/Module.bsl (InformationRegisters/MaterialPropertyValues/Forms/ListForm tương tự với `PropertySet`)
```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Filter.Property("Owner") Then
		Items.Code.Visible = False;
	EndIf;
EndProcedure
```

### Print form (command → manager module, template)
Nguồn: Documents/Services/Commands/Print/CommandModule.bsl; Documents/Services/ManagerModule.bsl
```bsl
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//{{_PRINT_WIZARD(Print)
	Spreadsheet = New SpreadsheetDocument;
	Print(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show();
	//}}
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter)
	Documents.Services.Print(Spreadsheet, CommandParameter);
EndProcedure
```
```bsl
Procedure Print(Spreadsheet, Ref) Export
	//{{_PRINT_WIZARD(Print)
	Template = Documents.Services.GetTemplate("Print");
	Query = New Query;
	Query.Text =
	"SELECT
	|	Services.Customer,
	|	Services.Date,
	|	Services.Number,
	|	Services.Technician,
	|	Services.Warehouse,
	|	Services.MaterialsAndServices.(
	|		LineNumber,
	|		MaterialOrService,
	|		Quantity,
	|		Price,
	|		Total
	|	)
	|FROM
	|	Document.Services AS Services
	|WHERE
	|	Services.Ref IN (&Ref)";
	Query.Parameters.Insert("Ref", Ref);
	Selection = Query.Execute().Select();

	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	AreaMaterialsAndServicesHeader = Template.GetArea("MaterialsAndServicesHeader");
	AreaMaterialsAndServices = Template.GetArea("MaterialsAndServices");   
	AreaTotal = Template.GetArea("Total"); // New line
	Spreadsheet.Clear();

	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;

		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());

		Spreadsheet.Put(AreaMaterialsAndServicesHeader);
		SelectionMaterialsAndServices = Selection.MaterialsAndServices.Select();   
		
		TotalSum = 0; // New line
		
		
		While SelectionMaterialsAndServices.Next() Do
			AreaMaterialsAndServices.Parameters.Fill(SelectionMaterialsAndServices);
			Spreadsheet.Put(AreaMaterialsAndServices, SelectionMaterialsAndServices.Level());  
			
			TotalSum = TotalSum + SelectionMaterialsAndServices.Total; // New line                   
			
		EndDo;
		
		AreaTotal.Parameters.DocumentTotal = TotalSum; // New line    
		
		Spreadsheet.Put(AreaTotal); // New line           
		
		InsertPageBreak = True;
	EndDo;
	//}}
EndProcedure
```

### Exchange plan và data processor trao đổi dữ liệu (ngoài giáo trình 24 bài)
Nguồn: DataProcessors/DataExchange/Forms/Form/Module.bsl; ExchangePlans/Branches/Forms/ListForm/Module.bsl; ExchangePlans/Branches/Forms/NodeForm/Module.bsl
```bsl
&AtServerNoContext
Procedure StartDataExchangeAtServer() 
	
	NodeSelection = ExchangePlans.Branches.Select();
	While NodeSelection.Next() Do
		// Exchanging data with all nodes, except for the current
		// node (ThisNode)
		If NodeSelection.Ref <> ExchangePlans.Branches.ThisNode() Then
			NodeObject = NodeSelection.GetObject();
			// Receiving message
			NodeObject.ReadMessageWithChanges();
			// Generating message
			NodeObject.WriteMessageWithChanges();
		EndIf;
	EndDo;                      
	
EndProcedure
	
&AtClient
Procedure StartDataExchange(Command)    
	
	StartDataExchangeAtServer();        
	
EndProcedure
```
```bsl
&AtServerNoContext
Procedure WriteChangesAtServer(Node)
	ExchangePlans.RecordChanges(Node);
EndProcedure

&AtClient
Procedure WriteChanges(Command)
	WriteChangesAtServer();
EndProcedure

&AtServerNoContext
Function PredefinedNode(Node)
	Return Node = ExchangePlans.Branches.ThisNode();
EndFunction

&AtClient
Procedure ListOnActivateRow(Item)
	If PredefinedNode(Item.CurrentRow) Then
		Items.FormWriteChanges.Enabled = False;
	Else
		Items.FormWriteChanges.Enabled = True;
	EndIf;
EndProcedure
```
- [ghi chú ngoài nguồn] Lỗi trong nguồn: `WriteChanges` gọi `WriteChangesAtServer()` **không truyền** tham số `Node` mà procedure bắt buộc có → lỗi khi bấm lệnh. Cần truyền node đang chọn, ví dụ `WriteChangesAtServer(Items.List.CurrentRow)` (form có item `List`).
- `ReadMessageWithChanges()` / `WriteMessageWithChanges()` / `RecordChanges()` là method trong module của exchange plan theo sách, không có trong repo dạng `.bsl` → (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).

### Scheduled jobs: cập nhật chỉ mục full-text search
Nguồn: CommonModules/ScheduleProcedures/Module.bsl
```bsl
Procedure UpdateIndex() Export
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable
		Then
		If Not FullTextSearch.IndexTrue()Then
			FullTextSearch.UpdateIndex( , True);
		EndIf;
	EndIf;
EndProcedure


Procedure MergeIndexes() Export
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable
		Then
		If Not FullTextSearch.IndexTrue()Then
			FullTextSearch.UpdateIndex(True);
		EndIf;
	EndIf;
EndProcedure
```

## Report (DCS) — query chính
Nguồn: Reports/<Tên>/Templates/MainDataCompositionSchema/Template.dcs

| Report | Nguồn dữ liệu | Điểm đáng chú ý |
|---|---|---|
| Materials | `AccumulationRegister.BalanceOfMaterials.BalanceAndTurnovers` theo Warehouse, Material | Đầu kỳ / nhập / xuất / cuối kỳ |
| MaterialBalanceByProperty | `BalanceOfMaterials.BalanceAndTurnovers` theo Material, PropertySet | Dùng characteristics của bộ thuộc tính |
| GenericReport | `AccumulationRegister.Sales.Turnovers` | Report tổng quát người dùng tự cấu hình |
| ProfitByCustomer | `Sales.Turnovers`: Customer, Revenue, Cost | Lợi nhuận = Revenue − Cost (resource tính trong DCS) |
| RevenueByTechnician | `Sales.Turnovers(, , Day, )` | Turnover theo ngày |
| ServiceEvaluation | `Catalog.MaterialsAndServices` LEFT JOIN `Sales.Turnovers`, `IsFolder = FALSE`, tham số `&MaterialServiceType` | Xếp hạng dịch vụ theo doanh thu |
| ServiceList | `Catalog.MaterialsAndServices` LEFT JOIN `InformationRegister.Prices.SliceLast(&ReportDate, )` | Bảng giá theo nhóm (Parent) tại một ngày |
| ServicesDocumentRegister | `Document.Services` | Danh sách chứng từ |
| TrialBalance | `ChartOfAccounts.Main` LEFT JOIN `AccountingRegister.Primary.BalanceAndTurnovers` (`SumOpeningSplittedBalanceDr/Cr`, `SumTurnoverDr/Cr`, `SumClosingSplittedBalanceDr/Cr`) | Bảng cân đối số phát sinh |

## Dùng cho bài tập lớn (BTL)

- **Lộ trình M (MIS, xây từ cấu hình trống):** ERP_Practice là ví dụ quy mô vừa đủ cho một nhóm: 2 chứng từ chính (nhập / xuất), 3 accumulation register (tồn, giá trị, doanh thu), 1 information register giá, report DCS. Gợi ý ánh xạ: GoodsReceipt ≈ phân hệ **mua** (nhập kho), Services ≈ phân hệ **bán** (xuất kho + doanh thu), BalanceOfMaterials/CostOfMaterials ≈ **kho**. ERP_Practice **không có** phân hệ tiền (thu/chi, công nợ theo register riêng) — nhóm dòng tiền phải tự thiết kế; có thể học cách ghi Dr/Cr qua `AccountingRegister.Primary` nhưng không bắt buộc kế toán.
- Dùng như **mẫu tham khảo cấu trúc**, không chép nguyên cấu hình làm bài nộp: nhóm phải tự xác định quy mô công ty, quy trình và object của mình (theo đề BTL).
- Các bẫy cần nhắc khi tham khảo: sửa tay trong khối wizard bị ghi đè; tính giá vốn trước khi ghi record set rỗng sẽ đọc lẫn record cũ; kiểm tra tồn phải lọc đúng chiều (kho, bộ thuộc tính) mà hệ thống quản lý.
- **Lộ trình J (Jet):** không dùng ERP_Practice làm khung; chỉ dẫn sang khi người học hỏi cụ thể một kỹ thuật (ví dụ giá vốn bình quân) và nói rõ đây là ví dụ ngoài Jet.
