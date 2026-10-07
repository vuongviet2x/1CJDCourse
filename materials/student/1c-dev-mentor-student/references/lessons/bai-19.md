# Bài 19 — Data processors (built-in & external)

## Khái niệm chính

### Basics
- **Data processor**: configuration object riêng để thực hiện các thao tác lập trình — phân tích dữ liệu, xử lý documents, upload/download thông tin, tính toán phức tạp, thao tác quản trị infobase...
- Khác đa số metadata objects: **không gắn với bảng database**, **không lưu thông tin** trong DB; chỉ thực hiện chức năng developer cài vào — công cụ cho user.

### Types of data processors
- Theo cách lưu:
  1. **Built-in data processors** — nằm trong configuration.
  2. **External data processors** — lưu riêng thành file, kết nối với bất kỳ infobase nào mà **không đổi configuration**.
- Theo mục đích:
  - **Service** — quản trị DB hoặc gọi từ subsystem khác (tạo/xoá dữ liệu, đổi password user...).
  - **Additional interface solutions** — tăng usability (user desktop, configuration overview…).
  - **Data processing** — thay đổi hàng loạt (đổi giá sản phẩm, nhập opening balances, month closing).
  - **Data exchange** — import/export (Excel, XML, JSON).

### Ví dụ: Import prices from Excel
- Chuẩn bị: catalog **"PriceTypes"** trong subsystem mới **"Prices"** (con của Sales); independent information register **"ProductPrices"**, periodicity **Day**: Dimensions **PriceType**, **Product**; Resources **Price**. Hỗ trợ nhiều loại giá (wholesale, retail, partner).
- Data processor **"Import prices from Excel"** trong subsystem "Prices"; form có attribute **PriceType** kiểu `CatalogRef.PriceTypes`, bắt buộc điền.
- **Spreadsheet document trên form** dùng cho 2 mục đích:
  1. Đọc nội dung file và ghi dữ liệu ra file OpenOffice/Excel: **.ods, .xls, .xlsx, .xlsm**.
  2. Cho user xem nội dung file trước khi nạp.
  - Bài chỉ hỗ trợ Excel. Attribute **SpreadsheetDocument**, tắt title, **ReadOnly** = True.
- Attribute **PathToFile** kiểu String độ dài **200**, bắt buộc; field bật choice và clear buttons.
- Handler choice: **FileDialog** mode **Open**, đặt title, filter 3 nhóm:
  - chung cho 3 extension;
  - **Excel 1997-2003** cho .xls;
  - **Excel** cho .xlsx, .xlsm.
  - Gọi **`Show`** với callback handler description.
  - Filter phân tách bằng **"|"**; ký hiệu "|" cũng dùng để xuống dòng trong string value → khi viết nhiều dòng sẽ thấy **"||"** đầu dòng mới (cái đầu để tiếp tục chuỗi, cái thứ hai là separator). Viết một dòng thì chỉ một "|".
- Callback: kiểm tra **SelectedFiles** khác **Undefined** (Undefined khi đóng cửa sổ không chọn). Nếu chọn → kiểu **Array** chứa full path (nhiều file nếu property **"Multiselection"** = True); lấy phần tử đầu.
- Đọc file: method **`Read(FullPathToFile)`** của SpreadsheetDocument, qua command **"Read"** — handler client + procedure server (vì **`Read()` không có trên client**).
- **MessageToUser**: hiển thị cùng loại thông báo như platform khi fill check; tập trung vào field trong property **"Field"**, cho phép chuyển giữa các field bằng mũi tên (nếu nhiều field); ngoài message panel còn có pop-up chỉ vào field.
- Command **"LoadPrices"** (client handler + server procedure), nút làm **default button**:
  - Kiểm tra bắt buộc bằng **`CheckFilling()`** (platform đảm nhận kiểm tra mọi attribute bắt buộc).
  - Kích thước bảng: properties **TableWidth**, **TableHeight**. Nếu số dòng hoặc cột **< 2** → báo lỗi và dừng (cần ít nhất cột Product, Price; dòng 1 là header).
  - Cách xác định cột: (a) header theo tên định sẵn (không phân biệt hoa thường, ví dụ "price"); (b) user nhập số cột (ProductColumnNumber, PriceColumnNumber) — khi đó kiểm tra cột có tồn tại. Bài chọn (a) vì ít thao tác cho user (cột Excel đánh chữ, dễ nhập sai), đổi lại yêu cầu format file chặt hơn.
  - Biến **ColumnNumbers** kiểu **Structure**: key = tên cột bắt buộc, value = số cột.
  - Lặp cột 1..số cột, lấy ô bằng method **`Area()`** (truyền vùng ô như `GetArea()`), ví dụ `"R1C" + i`; đọc property **Text**, bỏ ký tự thừa hai bên bằng **`TrimAll()`**.
  - Tìm tên trong ColumnNumbers: có → gán số cột `i`; không → báo user cột đó sẽ bị bỏ qua.
  - Sau vòng lặp kiểm tra mọi property đã điền; thiếu → báo và set biến **ColumnsError** = True; dừng **sau** vòng lặp để báo **tất cả** cột thiếu cùng lúc.
  - Lặp dòng 2..số dòng; tìm product bằng **`FindByDescription()`** với **exact match** (tránh "Teapot" khớp "Electric Teapot", "Aluminum Teapot"...). Không tìm thấy → báo kèm description; tìm thấy → tạo record bằng **record manager** của register giá. Ngày lấy **một lần trước vòng lặp** để mọi record cùng ngày.
  - `Write` của record manager với **Replace = True**: trùng ngày + product + price type → ghi đè. Muốn user chọn → attribute riêng truyền vào tham số Write.
- Cải tiến: attribute **Period** (kiểu date) thay ngày hiện tại; khởi tạo trong **OnCreateAtServer** bằng ngày hiện tại. Đặt Period và PriceType trong một group.
- Nút **"Test"** phía trên cây form elements trong Designer: xem form ở các kích thước cửa sổ khác nhau.
- Field "Price type" giãn quá rộng → tắt **"AutoMaxWidth"** rồi đặt **"MaxWidth"**: độ rộng tối đa; form không đủ chỗ thì tự thu nhỏ.
- Kết quả kiểm thử: thiếu Price type → lỗi; dòng có product "Test" → "Unable to find a product by description Test"; các dòng khác nạp thành công.
- Gợi ý cải tiến (tự luyện): báo số giá nạp thành công; đọc price type từ file hoặc kết hợp với lựa chọn của user (radio buttons); xử lý file bị xoá/move/rename giữa lúc chọn và đọc.

### Làm việc với file ở client-server mode
- Client và server thường ở máy khác nhau → file theo **local path** (ví dụ `D:\Work`) trên máy client không truy cập được từ server; network path (ví dụ `\\Accountant-computer\Work`) server cũng có thể không có quyền. Đọc file trên server → lỗi vì server tìm trong file system của nó.
- Giải pháp: đưa binary data file vào **temporary storage**, gửi địa chỉ lên server; server tạo **temp file name**, ghi binary data ra temp file, đọc vào spreadsheet document, rồi **xoá temp file**.
- Tránh tách rời chọn file và đọc file (file có thể đổi giữa hai bước): xoá field PathToFile, chuyển code từ handler **"StartChoice"** sang command handler **"Read"**, đổi tên thành **"ReadFile"**.
- Sau khi có full path → **`BeginPutFileToServer`**: truyền callback handler, path file, **unique form identifier** (khi form đóng, platform tự xoá temporary storage gắn identifier này).
- Callback: kiểm tra tham số đầu **PlacedFileDescription** khác **Undefined** (Undefined = đặt file thất bại); gọi server procedure với địa chỉ trong temporary storage và **extension** file (cần để temp file ở format Excel) — lấy từ **`FileRef.Extension`** của PlacedFileDescription.
- Server: lấy binary data từ temporary storage → **`GetTempFileName()`** → ghi binary data ra file → đọc vào spreadsheet document → xoá file bằng **`DeleteFiles()`**, nên đặt trong **Try** (lỗi xoá → xử lý và ghi **event log**). File có thể 5-10-20 MB, vài trăm file sẽ chiếm đáng kể dung lượng.
- **Information**: platform tự xoá temp files cuối session, nhưng ở client-server, temp file tạo trên server thuộc session của **1C server**, không phải client session → có thể tích tụ nhiều ngày/tuần. Syntax assistant của `GetTempFileName()` khuyến nghị tự xoá.

### External data processors
- File có cấu trúc riêng, extension **.epf**, tạo trong Designer; làm được gần như mọi thứ như built-in, **trừ manager module** (chỉ object trong configuration mới có object manager).
- Tạo: menu **File → "New"** hoặc nút **"New Document"** trên panel "Configuration" → chọn **"External data processor"** → editor mở ra (chưa lưu); lưu lần đầu → chọn tên và path file.
- Ví dụ use case: thêm attribute bắt buộc vào catalog/document làm hỏng dữ liệu cũ (document cũ không post được vì attribute bắt buộc chưa điền) → developer phải điền dữ liệu hiện có. Cơ chế **update handlers** của **standard subsystem library (SSL)** (học sau); khi không có SSL hoặc lý do khác → dùng external data processor, chạy trên nhiều infobase có configuration tương tự, kể cả của khách hàng khác, không cần đưa vào configuration.
- Ví dụ: thêm attribute **"PriceType"** (kiểu catalog "PriceTypes") bắt buộc vào document Sales invoice. Phương án 1: cutoff date + 2 price types (trước/sau ngày) + nút **"Fill price type"**. Phương án linh hoạt (được chọn): chọn period (2 field date hoặc 1 field **StandardPeriod**) + một field PriceType → điền dần theo từng khoảng thời gian.
- Server procedure: query mọi document trong period **có filter PriceType chưa điền** (tránh ghi đè document user đã điền sau khi update configuration). Với mỗi document: lấy object, điền price type, write; lỗi → ghi chi tiết vào **event log**. Biến **NumberProcessed**, **NumberUnprocessed** khởi tạo 0, tăng theo kết quả; cuối cùng nếu thay đổi → thông báo.
- Chạy: lưu data processor (không cần lưu configuration hay restart debugging), vào Enterprise mode, **mở data processor từ file**.
- Platform cảnh báo chỉ mở file từ nguồn tin cậy (có thể thực hiện thao tác nguy hiểm). SSL có **role riêng** cho quyền mở external reports và data processors; user không có role không mở được từ file. (Reports cũng có thể là external.)
- Chuyển đổi trong configuration tree (right-click):
  - **"Insert external report or data processor"** — thêm external vào configuration (right-click branch).
  - **"Save as external report or data processor"** — lưu built-in thành external.
  - **"Replace with external report or data processor"** — nạp built-in từ external.
  - Nút compare and merge với external report/data processor — chọn thủ công từng phần, kết quả thay thế built-in object.
- Lưu built-in thành external → **code trong manager module bị mất**.

## Cú pháp & ví dụ code

Lấy ô header cột thứ i:
```bsl
"R1C" + i
```

Tạo binary data / các method được nêu trong bài (không có đoạn code văn bản đầy đủ):
```bsl
Read(FullPathToFile)
CheckFilling()
Area()
TrimAll()
FindByDescription()
BeginPutFileToServer
GetTempFileName()
DeleteFiles()
```

[ghi chú ngoài nguồn] Các đoạn code của bài (FileDialog với filter, callback, ReadAtServer, LoadPrices, BeginPutFileToServer, external data processor điền PriceType) chỉ có dạng ảnh trong tài liệu nên không chép lại. Phiên bản demo của bài (ReadFile, filter có .xlsm, LoadPrices ghi register độc lập bằng record manager) → xem mục Code demo của bài Theory (nhánh lesson/19-theory). (Riêng external data processor điền PriceType không có trong nhánh lesson/19-theory — nhánh chỉ có attribute PriceType bắt buộc của Sales invoice — nên vẫn chưa có code.)

## Thuộc tính/thiết lập quan trọng trong Designer
- Information register "ProductPrices": independent, periodicity **Day**; Dimensions PriceType, Product; Resource Price.
- Form attributes: **PriceType** (`CatalogRef.PriceTypes`, bắt buộc), **SpreadsheetDocument** (ReadOnly = True, title tắt), **PathToFile** (String 200, bắt buộc, choice + clear buttons), **Period** (Date).
- FileDialog: mode **Open**, **Title**, **Filter**, **Multiselection**.
- MessageToUser: property **Field**.
- SpreadsheetDocument: **TableWidth**, **TableHeight**; cell property **Text**.
- Command button: **DefaultButton**.
- Form field: **AutoMaxWidth**, **MaxWidth**; nút **Test** trong form editor.
- External data processor: file **.epf**; File → New / New Document → External data processor.
- Configuration tree: Insert / Save as / Replace with external report or data processor; compare and merge.

## Lỗi thường gặp / lưu ý
- `Read()` của SpreadsheetDocument không có trên client → gọi ở server.
- SelectedFiles = Undefined khi user huỷ chọn file → phải kiểm tra.
- Bảng < 2 dòng hoặc < 2 cột → không có dữ liệu hợp lệ, báo lỗi.
- Báo tất cả cột thiếu một lần (dùng cờ ColumnsError, dừng sau vòng lặp).
- `FindByDescription()` không exact match có thể tìm nhầm sản phẩm tương tự.
- Form trong Designer trông khác Enterprise mode → dùng nút "Test", MaxWidth.
- File có thể bị xoá/move/rename giữa lúc chọn và đọc → gộp chọn + đọc vào một command.
- Client-server: server không đọc được file theo local path của client (và có thể không có quyền với network path) → dùng `BeginPutFileToServer` + temporary storage + temp file.
- PlacedFileDescription = Undefined → đặt file thất bại.
- Tự xoá temp file (`DeleteFiles()` trong Try) — ở client-server temp file trên server có thể tích tụ nhiều ngày/tuần.
- Chỉ mở external data processor từ nguồn tin cậy; cần role phù hợp (SSL).
- External data processor không có manager module; save built-in thành external làm mất code manager module.
- Khi điền hàng loạt bằng external processor, chỉ chọn document chưa điền để không ghi đè dữ liệu user đã sửa.

## Điểm cần nhớ
- Data processor không lưu dữ liệu trong DB; chỉ thực thi thao tác. Hai loại: built-in và external (.epf).
- 4 mục đích: Service, Additional interface solutions, Data processing, Data exchange.
- Import Excel: FileDialog (filter "|") → SpreadsheetDocument.`Read()` trên server → duyệt TableWidth/TableHeight, `Area("R1C"+i).Text` → tìm cột bằng Structure → `FindByDescription` exact → record manager `Write(True)`.
- MessageToUser với property Field để chỉ vào field lỗi; `CheckFilling()` để kiểm tra attribute bắt buộc.
- Client-server: `BeginPutFileToServer` (kèm form UUID) → server `GetTempFileName()` → ghi, đọc → `DeleteFiles()` trong Try.
- External data processor: tạo từ File → New, chạy bằng cách mở file trong Enterprise mode, không cần update configuration; dùng cho điền dữ liệu khi thêm attribute bắt buộc (khi không có SSL update handlers).
- Insert / Save as / Replace with external report or data processor; external không có manager module.

## Thẻ gợi ý bài thực hành (Practice 19)

19. Practice chỉ có một bài lớn. Thẻ dưới đây chia nó thành các phần nhỏ theo đúng các yêu cầu của đề.

### Bài tập 1 — Data processor nạp giá từ Excel vào document PriceSetup

- **Đề bài (tóm tắt):** Data processor đọc file .xls/.xlsx gồm 3 cột Date – Product – Price. Vì register giá **subordinate to recorder**, giá được nạp vào document `PriceSetup`, mỗi ngày khác nhau một document, ghi ở chế độ **Posting**. Product tìm theo description exact match (sau khi bỏ ký tự thừa); không tìm thấy thì bỏ qua và báo. Mỗi ngày chỉ có một document **đã post** được nạp từ file: nếu đã có thì chỉ thêm product mới hoặc sửa giá khi khác. Không có thay đổi thì không ghi. Lỗi khi ghi được ghi vào event log. Có 3 loại thông báo: created / updated / not loaded.
- **Gợi ý 1 — Hướng đi:**
  - Phần đọc file giống bài lý thuyết (mục "Ví dụ: Import prices from Excel" và "Làm việc với file ở client-server mode"): FileDialog → `BeginPutFileToServer` → server dùng temp file → `SpreadsheetDocument.Read()` → `DeleteFiles()` trong Try.
  - Khác bài lý thuyết: register không ghi trực tiếp được, nên phải tạo/sửa **document**. Tip của đề: đọc hết bảng vào **collection trung gian** trước, lấy danh sách ngày, query tất cả document đã có trong **một** query (không query trong vòng lặp).
  - Phân biệt document tự động bằng một attribute riêng do bạn thiết kế, đồng thời hiện điều này trên form document.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form của data processor: attribute SpreadsheetDocument (ReadOnly), command đọc file và command nạp giá (DefaultButton).
  - Client: `New FileDialog(FileDialogMode.Open)` với `Filter` cho .xls và .xlsx, `Show(CallbackDescription)`; callback Export kiểm tra `SelectedFiles`, gọi `BeginPutFileToServer(..., UUID)`; callback thứ hai kiểm tra `PlacedFileDescription` và lấy địa chỉ cùng extension.
  - Server: `GetFromTempStorage`, `GetTempFileName(<extension>)`, `Read(..., SpreadsheetDocumentValuesReadingMode.Value)` để đọc **Value** của ô Date, `DeleteFiles` + `WriteLogEvent`.
  - Đọc bảng: `TableWidth`/`TableHeight`, `Area("R1C" + i).Text`, Structure tên cột → số cột, `TrimAll()`, `Catalogs.Products.FindByDescription(<tên>, True)`.
  - Collection trung gian: ValueTable (Date, Product, Price) + mảng ngày duy nhất.
  - Function `&AtServerNoContext` query `Document.PriceSetup` theo danh sách ngày (`BEGINOFPERIOD(..., DAY) IN (&Dates)`), lọc theo attribute đánh dấu "nạp từ file".
  - Document PriceSetup: attribute Boolean đánh dấu (ví dụ `LoadedFromFile`); `OnCreateAtServer` của form hiển thị dấu hiệu cho user. Ghi bằng `Write(DocumentWriteMode.Posting)` trong Try.
- **Gợi ý 3 — Khung bài làm:**
  1. Đọc file (client → temporary storage → server temp file → spreadsheet document → xoá temp file).
  2. Kiểm tra kích thước bảng (ít nhất 2 dòng, 3 cột); xác định cột theo tiêu đề và báo **tất cả** cột thiếu một lần.
  3. Duyệt dòng 2..N: đọc Date (Value), Product (Text + TrimAll), Price; tìm product; đưa vào ValueTable hoặc báo không tìm thấy.
  4. Một query lấy document tự động đã có cho mọi ngày.
  5. Với mỗi ngày: lấy object có sẵn hoặc tạo mới (đặt Date và cờ đánh dấu); duyệt các dòng của ngày đó: thêm product mới, sửa giá khi khác, giống thì bỏ qua; ghi nhận "có thay đổi".
  6. Có thay đổi thì ghi Posting trong Try và báo created/updated (in ref để có presentation); lỗi thì WriteLogEvent. Không có thay đổi thì báo "Prices for … were not loaded".
  ```bsl
  For Each Date In ___ Do
  	___ // tìm document có sẵn cho ngày này -> GetObject() / CreateDocument() + cờ "từ file"
  	For Each Row In ___ Do      // các dòng của ngày này trong collection trung gian
  		___ // chưa có product -> thêm; có nhưng giá khác -> sửa; giống -> Continue
  	EndDo;
  	If ___ Then                  // có thay đổi
  		___ // Try: Write(Posting) + thông báo created/updated; Except: ghi event log
  	Else
  		___ // thông báo "Prices for <ngày> were not loaded"
  	EndIf;
  EndDo;
  ```
- **Lỗi hay gặp:**
  - Đọc file trực tiếp theo local path trên server. Ở client-server server không thấy file đó, nên phải đi qua temporary storage + temp file.
  - Query document **trong vòng lặp** theo từng ngày, trái với tip của đề.
  - Đọc ngày bằng `.Text` rồi tự chuyển chuỗi thành ngày (dễ lỗi format). Đặt format ô là Date và đọc `.Value`.
  - Ghi lại document kể cả khi không có thay đổi, trái với yêu cầu "không thay đổi thì không ghi".
  - [ghi chú ngoài nguồn] Lời giải tham khảo của khóa có hai chỗ hở nên tránh: (1) query document cũ chưa lọc `Posted`/`DeletionMark`, trong khi đề nói "một document **đã post** mỗi ngày"; (2) ngày mà mọi product đều không tìm thấy không được báo "not loaded" nếu file còn ngày hợp lệ khác. Hãy xử lý cả hai trường hợp.
  - Quên xoá temp file hoặc không đặt `DeleteFiles` trong Try.
- **Tự kiểm tra:** Dùng đúng bảng trong đề và đối chiếu từng dòng với cột Result: lần nạp đầu tạo 3 document (02.02 có 2 product, 19.02, 03.03). Nạp lại cùng file: không có document nào bị ghi lại, chỉ có thông báo "not loaded". Sửa một giá trong file rồi nạp: document của ngày đó báo "updated". Mở document tự động: thấy dấu hiệu "tạo từ data processor". Kiểm tra register giá (Register records của PriceSetup) có giá mới. Cố tình gây lỗi ghi (ví dụ khoá document) rồi xem Event log.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/19-theory)

### Phiên bản demo của LoadPrices: CheckFilling, Period từ OnCreateAtServer, ghi register giá bằng record manager

Nguồn: nhánh lesson/19-theory — cf/DataProcessors/ImportPricesFromExcel/Forms/Form/Ext/Form/Module.bsl

```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Period = CurrentSessionDate();
EndProcedure
// ...
&AtServer
Procedure LoadPricesAtServer()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	// TableWidth contains number of table columns.
	ColumnsCount = SpreadsheetDocument.TableWidth; 
	// TableHeight contains number of table rows.
	RowsCount 	 = SpreadsheetDocument.TableHeight;
	
	If ColumnsCount < 2 Or RowsCount < 2 Then
		Message("Table should contain at least 2 rows (1 is for column titles) and 2 columns");
		Return;
	EndIf;
	
	ColumnNumbers = New Structure;
	ColumnNumbers.Insert("Product");
	ColumnNumbers.Insert("Price");
	
// ...
	For i = 2 To RowsCount Do
		ProductDescription 	= TrimAll(SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Product).Text);
		ProductPrice 		= TrimAll(SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Price).Text);
		
		Product = Catalogs.Products.FindByDescription(ProductDescription, True);
		If ValueIsFilled(Product) Then
			NewRecord = InformationRegisters.ProductPrices.CreateRecordManager();
			
			NewRecord.Period 	= Period;
			NewRecord.Product 	= Product;
			NewRecord.PriceType = PriceType;
			NewRecord.Price 	= ProductPrice;
			
			NewRecord.Write(True);
		Else
			Message(StrTemplate("Unable to find a product by description %1", ProductDescription));
		EndIf;
		
	EndDo;
	
EndProcedure
```

- Đúng phiên bản của bài Theory (bài Practice 19 khác: đọc thêm cột Date và tạo document PriceSetup — xem Thẻ gợi ý bài thực hành): file chỉ cần 2 cột Product, Price; ngày lấy từ form attribute `Period`, khởi tạo trong `OnCreateAtServer` bằng `CurrentSessionDate()`.
- `CheckFilling()` ở đầu procedure → platform tự kiểm tra mọi attribute bắt buộc của form (PriceType); thiếu thì dừng.
- Ở đây register `ProductPrices` là **independent** → ghi thẳng bằng `InformationRegisters.ProductPrices.CreateRecordManager()`, `Write(True)` (Replace) ghi đè record trùng Period + Product + PriceType.
- `FindByDescription(ProductDescription, True)` — exact match; không tìm thấy thì báo "Unable to find a product by description ..." (đúng kết quả kiểm thử với dòng "Test" trong bài).

### Filter của FileDialog trong bài Theory (thêm .xlsm) và command ReadFile

Nguồn: nhánh lesson/19-theory — cf/DataProcessors/ImportPricesFromExcel/Forms/Form/Ext/Form/Module.bsl

```bsl
&AtClient
Procedure ReadFile(Command)
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = "Choose a file with prices for import";
	Dialog.Filter = 
		"Tables (*.xls,*.xlsx,*.xlsm)|*.xls;*.xlsx;*.xlsm;
		||Microsoft Excel 1997-2003 (*.xls)|*.xls
		||Microsoft Excel (*.xlsx,*.xlsm)|*.xlsx;*.xlsm";

	Dialog.Show(New CallbackDescription("FileFinishChoice", ThisObject));

EndProcedure
```

- Command đã đổi tên thành `ReadFile` như bài mô tả (gộp chọn file + đọc file, bỏ field PathToFile/StartChoice).
- Filter 3 nhóm đúng như lý thuyết: chung cho .xls/.xlsx/.xlsm, "Excel 1997-2003" cho .xls, "Excel" cho .xlsx/.xlsm.
- Phần còn lại (`FileFinishChoice` → `BeginPutFileToServer` → `ReadFinishPuttingFile` → `ReadOnServer` với temp file) cũng có trong cùng module của nhánh, theo đúng chuỗi lý thuyết mô tả (`BeginPutFileToServer` kèm UUID của form, `GetTempFileName`, `DeleteFiles` trong Try).

### Attribute PriceType bắt buộc trong document SalesInvoice (bối cảnh của external data processor)

Nguồn: nhánh lesson/19-theory — cf/Documents/SalesInvoice.xml

```xml
			<Attribute uuid="46bbe897-139e-4ada-a90f-fae6e982909b">
				<Properties>
					<Name>PriceType</Name>
					<Synonym>
						<v8:item>
							<v8:lang>en</v8:lang>
							<v8:content>Price type</v8:content>
						</v8:item>
					</Synonym>
					<Comment/>
					<Type>
						<v8:Type>cfg:CatalogRef.PriceTypes</v8:Type>
					</Type>
					<PasswordMode>false</PasswordMode>
<!-- ... -->
					<FillChecking>ShowError</FillChecking>
```

- Nhánh lesson/19-theory có attribute `PriceType` (kiểu `CatalogRef.PriceTypes`, `FillChecking` = `ShowError`) — đúng thay đổi làm document cũ không post được, lý do cần external data processor trong bài.
- Bản thân external data processor (.epf) điền PriceType theo period **không** có trong nhánh (repo chỉ chứa dump configuration cf/, external data processor là file riêng).

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

Không có video bài giảng tương ứng — chỉ dẫn tài liệu Theory/Practice của bài.

<!-- video-qa-thuchanh:start -->

Video giải đáp tình huống thực chiến và video thực hành từng bước liên quan tới bài này (thẻ chi tiết, triệu chứng, lưu ý khi giới thiệu: `references/video-qa-thuc-chien.md`, `references/video-thuc-hanh.md`; cùng mẫu câu dẫn ở trên):

- [Kết nhập file excel vào danh mục sản phẩm](https://www.youtube.com/watch?v=DlXBXRzBJGw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=13) (38:42) — nhập dữ liệu từ Excel (giải đáp tình huống; Bài 19 chính) _(mã nội bộ QA-13)_
- [Lưu bộ xử lý ngoài](https://www.youtube.com/watch?v=DTRivJSbAoI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=15) (1:40) — bộ xử lý ngoài (.epf) (giải đáp tình huống; Bài 19 chính) _(mã nội bộ QA-15)_
- [Tạo chức năng sửa password với vai trò người dùng](https://www.youtube.com/watch?v=taKIdmcCmIQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=9) (26:39) — cho người dùng tự đổi mật khẩu (giải đáp tình huống; Bài 19 liên quan) _(mã nội bộ QA-9)_

<!-- video-qa-thuchanh:end -->
