# Bài 12 — Data validation, Information registers, Transactions, Errors & Event log

## Khái niệm chính

### Data validation (kiểm tra dữ liệu)
- Kiểm tra đơn giản: property **"Required field"** = **"Display error"** của attribute/tabular section.
- Kiểm tra phức tạp: không chỉ kiểm tra đã điền mà còn kiểm tra dữ liệu đúng (ví dụ: bán hàng chịu VAT thì mỗi dòng phải có VAT rate; Sales order có "Shipment date" không được sớm hơn ngày document).
- Trước tiên xác định khi nào kiểm tra: mọi lần ghi, lúc posting, lúc ghi/post nhưng chỉ interactively (từ form). Với document thường kiểm tra lúc posting (document chưa post giống bản nháp).
- Event **FillCheckProcessing** của object — xảy ra trong 2 trường hợp:
  - Làm việc interactive (trực tiếp từ giao diện): với document có posting mode — khi posting interactive; với object khác có event này — khi ghi interactive.
  - Làm việc từ code: gọi method **CheckFilling()** của object kích hoạt FillCheckProcessing. Không gọi method này thì kể cả posting document từ code cũng không phát sinh event.
- 2 tham số của procedure:
  - **Cancel**: mặc định False; đổi thành True → posting (hoặc ghi, với object không có posting) không thực hiện, user thấy cửa sổ hệ thống báo thao tác thất bại.
  - **CheckedAttributes**: chứa tên các attributes và tabular sections sẽ được kiểm tra khi thoát procedure.
- Cách điển hình cho kiểm tra có điều kiện: đặt "Required field" = "Display error", rồi trong handler loại attribute/tabular section khỏi danh sách kiểm tra theo điều kiện.
- Ví dụ: Sales Invoice có 2 tabular sections Products và Services, yêu cầu ít nhất một dòng ở một trong hai → đặt cả hai bắt buộc, trong FillCheckProcessing loại Services khỏi kiểm tra nếu Products có dòng, và ngược lại.
- Phần tử mảng phải xóa theo index; lấy index bằng method **Find()** — trả về Undefined nếu không tìm thấy. Code tìm và xóa lặp lại → tách ra procedure riêng.
- Ví dụ phức tạp hơn: cột Amount của Products bắt buộc, trừ sản phẩm khuyến mãi (attribute "Promotional" của catalog Products, giá 0).
  - Ẩn "Weight" và "Promotional" với product kiểu Service: thêm group trên form, dùng handler **OnChange** của field Type; đồng thời gọi cập nhật visibility từ event client **OnOpen** (vì khi mở form, visibility là mặc định). Tách code thành procedure riêng gọi từ cả hai handler.
  - Kiểm tra bằng query chọn các dòng Products có amount rỗng, product thuộc kiểu product và không "Promotional" (Promotional = False).
  - **Rất quan trọng**: FillCheckProcessing chạy TRƯỚC khi object được ghi vào database → không thể chọn dữ liệu object theo reference; phải dùng dữ liệu object hiện có: truyền dữ liệu tabular section vào query, chọn vào temporary table, rồi dùng temporary table trong các query sau.
  - Hủy ghi/post: đổi Cancel = True và thông báo lỗi cho user (thông báo cho từng dòng lỗi, ví dụ dòng 1 và 3).

### Information registers
- Mục đích: lưu thông tin cần cho các nhiệm vụ khác nhau. Khác accumulation register (resources luôn là số), information register lưu được mọi loại thông tin (người chịu trách nhiệm của tổ chức, email settings, giá sản phẩm...).
- Cấu trúc giống accumulation register: dimensions, resources, details (attributes). Khác biệt: nền tảng kiểm soát **tính duy nhất của records theo tập dimensions** → không thể có 2 records cùng tập dimensions (sẽ phát sinh exception).
- Ví dụ: Dimensions: Organization; Resources: CEO, Chief Accountant, CTO.

### Periodic information registers
- Property **"periodicity"**: lưu giá trị theo tập dimensions + period. Giá trị: **None, Second, Day, Month, Quarter, Year**.
- Ví dụ periodicity "Day" → chỉ đổi resources cho cùng tổ chức tối đa một lần/ngày. Nền tảng kiểm soát duy nhất theo dimensions + service attribute **Period** (tự thêm trong periodic register).
- Giá trị **"By recorder position"**: chỉ chọn được ở periodic information register subordinate to recorder; cho phép records cùng dimensions + period với các recorder khác nhau. Thực tế gần như không gặp.

### Virtual tables của information register
- Chỉ có virtual tables khi register là periodic. 2 virtual tables: **SliceFirst** và **SliceLast**.
- SliceLast trả về dữ liệu mới nhất cho từng tập dimensions tại ngày chỉ định (ví dụ tại 1/25/2024 → Development company bản 1/15, Best chocolate bản 1/22; tại 1/21/2024 11:59:59 PM → Best chocolate trả bản 1/15).

### Write mode
- Records information register có thể thay đổi trực tiếp, không cần recorder document — gọi là **independent** register. Điều khiển bằng property **"Write mode"** = **"Independent"** (mặc định khi tạo register).
- Independent register dùng khi không gắn với business processes hoặc không cần hạn chế user truy cập trực tiếp register. (Ví dụ: giá sản phẩm nên đổi qua document cài đặt giá riêng để tránh user sửa register không để lại dấu vết.) Thường là service registers: "Email settings", "Exchange history", "Financial accounting policy"...
- Document là phản ánh một nghiệp vụ; nếu không có nghiệp vụ thiết lập người chịu trách nhiệm thì không tạo document → register "Companies responsible persons" nên là independent.
- Ghi vào independent register từ code giống register subordinate to recorder, nhưng không cần reference tới recorder.

### Đọc dữ liệu information register
- Bằng query tới virtual tables, hoặc bằng methods của register:
  1. Tương đương hoàn toàn query: **SliceFirst(<BeginOfPeriod>, <Filter>)**, **SliceLast(<EndOfPeriod>, <Filter>)** → trả về value table (có thể rỗng nếu không có dữ liệu khớp).
  2. Chỉ lấy resource values của một tập dimensions: **GetFirst(<BeginOfPeriod>, <Filter>)**, **GetLast(<EndOfPeriod>, <Filter>)** → trả về structure với properties trùng resources; nếu không có record khớp, giá trị là default của kiểu resource.
- Dữ liệu chỉ đọc được trên server → dùng handler **OnCreateAtServer** của form.
- **FillPropertyValues()** (global method): tham số Receiver, Source; các giá trị trùng tên được điền vào Receiver.
- Ghi dữ liệu form vào register: lấy lại bản ghi cuối cho ngày hiện tại, so sánh resources với attributes của form; nếu ít nhất một khác → thêm record với giá trị form và ngày hiện tại. Ban đầu đặt ở **AfterWriteAtServer** (sau khi object đã ghi và transaction đã commit); code lấy bản ghi cuối tách thành hàm riêng. (Sau đó được chuyển sang OnWriteAtServer — xem phần Transactions.)

### RecordSet và RecordManager
- **RecordSet**: công cụ chung để đọc, ghi, xóa records register. Khi làm việc với movements accumulation register từ document cũng là RecordSet (lấy từ property RegisterRecords).
- **RecordManager**: add-on của RecordSet, tiện cho làm việc với MỘT record của information register. Chỉ dùng được cho **independent** information registers.
  - **Note**: RecordManager ở mức hệ thống dùng 2 RecordSets (một xóa record cũ, một thêm record mới) → không khuyến khích khi xử lý số lượng lớn records; dùng RecordSet.
- Cả hai có method **Write()** với tham số **Replace** (Boolean): có ghi đè records nếu đã tồn tại records cùng tập dimensions hay không. Ví dụ cần thay giá trị cũ vì có thể đổi người chịu trách nhiệm trong cùng ngày.
- Xóa: RecordManager xóa một record; RecordSet xóa bao nhiêu cũng được theo filter giá trị dimensions và period (với periodic registers). Với RecordSet: xóa từng record bằng **Delete()**, hoặc xóa toàn bộ theo selection bằng **Write(True)** (ghi đè cưỡng bức).
- Information register subordinate to recorder làm việc giống accumulation register.

### Quick navigation tới register records
- Ví dụ SalesInvoice ghi vào GoodsInWarehouses và Sales: mở form document → tab **Command interface** → mở nhánh **"Go to"** → bật flag ở cột **Visible**. Khi chuyển sang tab register records, danh sách được lọc theo recorder = document hiện tại.
- Với independent register (không có recorder): records có thể subordinate tới objects là dimensions của register. Chọn dimension cần hiển thị, bật property **"Master"** của dimension. Property này nghĩa là record subordinate tới object được tham chiếu trong dimension; nếu object đó bị xóa khỏi database, nền tảng tự động xóa các records subordinate.

### Transactions
- Transaction: chuỗi thao tác dữ liệu không thể chia, đưa database từ trạng thái toàn vẹn này sang trạng thái toàn vẹn mới. Mọi thao tác trong transaction hoặc được commit (transaction commit) hoặc bị hủy (transaction rollback).
- **Implicit**: nền tảng tự bắt đầu và kết thúc khi thay đổi thông tin trong database; developer có thể xây dựng thuật toán để ngắt chúng.
- **Explicit**: developer điều khiển bằng code qua global context methods **BeginTransaction()**, **CommitTransaction()**, **RollbackTransaction()**.
- Ví dụ: import counterparty và contract (CounterpartyContracts subordinate tới Counterparties, standard attribute **Owner** bắt buộc). Lỗi khi ghi contract → phải hủy cả counterparty. Code đặt trong `Try - Except - EndTry`.
  - Mọi thay đổi sau khi bắt đầu transaction không có hiệu lực trong database cho đến khi CommitTransaction() → đặt cuối khối Try.
  - Trong khối Except, bước đầu tiên là RollbackTransaction(), rồi ghi log, báo user...
- Event diagram của Document khi posting từ form ("Post" / "Post and close"): các event trong transaction do nền tảng tự bắt đầu/kết thúc. Developer có thể hủy transaction bằng cách đặt Cancel = True trong handler chạy trong transaction hoặc raise exception. Object không có posting thì không có event Posting, các event còn lại và thứ tự giống nhau.
- Vấn đề với **AfterWriteAtServer**: chạy sau khi transaction ghi đã commit → object có thể đã ghi nhưng ghi register lỗi; cờ form modified (property **"Modified"**) đã bị bỏ → user mất một phần thay đổi và không thể hủy.
  - Giải pháp: chuyển thuật toán sang **OnWriteAtServer** (chạy trong transaction, có thể hủy nếu lỗi). Nếu cần ghi register cả khi ghi từ object (không chỉ từ form) → đặt vào event object **OnWrite** (trong object module); event **BeforeWrite** xảy ra trước khi object được ghi vào database.
- 2 cách hủy transaction từ event: (1) đổi **Cancel** = True; (2) raise exception. Khác biệt:
  - Với user: raise exception → cửa sổ có error text, icon lỗi, nút OK. Cancel = True → error text hiện trong message window dưới form; cửa sổ có nút OK chỉ hiện cho event Post Processing, không có error text mà là text do nền tảng tạo báo document không post được.
  - Với chương trình: raise exception ngắt thực thi code tiếp theo; Cancel = True thì không. Khi không nên ngắt code (ví dụ kiểm tra cột Amount của Products — để báo tất cả các dòng lỗi) → dùng cách Cancel; nếu không, user chỉ nhận thông báo cho một dòng.

### Errors và exception handling
- Implicit exceptions: lỗi không do developer gọi bằng **Raise**, ví dụ truy cập property không tồn tại, chia cho 0, lỗi khi làm việc với database object.
- Có thể phòng một số lỗi bằng kiểm tra (ví dụ kiểm tra số chia khác 0). Nhưng có lỗi không thể lường trước (ví dụ mọi lý do khiến document tạo/post bằng code bị lỗi) → dùng `Try - Except - EndTry`: lỗi trong Try không làm vỡ thực thi mà chuyển sang Except, nơi developer xử lý lỗi.
- Có khi chỉ cần ghi Event Log; có khi cần báo user. Nếu không còn ý nghĩa thực thi code tiếp → sau khi xử lý, raise exception tường minh bằng **Raise** (explicit tốt hơn implicit vì developer có thể thực hiện hành động liên quan và sửa thông báo cho dễ hiểu).
- Lấy thông tin lỗi (chỉ có ý nghĩa trong khối Except): **ErrorInfo()**, **ErrorDescription()**, và global context object **ErrorProcessing** (kiểu **ErrorProcessingManager**).
  - ErrorInfo() trả về object kiểu **ErrorInfo**.
  - WriteEventLog() thêm record vào Event log.
  - Mô tả ngắn: method **BriefErrorDescription** của ErrorProcessing.
- Không bỏ qua xử lý exception: không để khối Except rỗng. Lý tưởng: luôn ghi thông tin exception vào Event log.

### Event log
- Dùng để biết sự kiện nào xảy ra tại thời điểm nào, user nào thực hiện hành động gì; admin lấy lịch sử thao tác.
- Event log **không phải là một phần của database** và không được lưu khi export/import infobase.
- 1C:Enterprise ghi các hành động chính: thay đổi infobase, cấp/từ chối truy cập, routine operations, đăng nhập, đăng xuất...
- Ghi log bằng code: method **WriteLogEvent()** — khuyến nghị dùng khi admin cần thông tin chẩn đoán bổ sung về sự kiện mà nền tảng không ghi (cả trong interactive và background (scheduled) tasks). Một entry ứng với một sự kiện.
- WriteLogEvent() chạy trên server, có 6 tham số:
  - **EventName** (String): nhóm theo "Event group name.Event name" (ví dụ "Tasks.New task notification"). Không đưa giá trị cụ thể từ infobase/hệ thống ngoài vào tên sự kiện (sai: "Cannot cancel posting document <Sales KP00-00002 dated 11/10/2020>"; đúng: "Document posting.Cannot unpost", "Employees.Employee not found in the infobase").
  - **Level** (EventLogLevel): "Error" (lỗi nghiêm trọng, lỗi business logic, hỏng ứng dụng), "Warning" (vấn đề tiềm ẩn, lỗi không nghiêm trọng), "Information" (thao tác thành công), "Comment" (mức thấp nhất).
  - **MetadataObject**: chỉ định metadata object liên quan; nếu không gắn object cụ thể, chỉ định module nơi lỗi xảy ra (ví dụ `Metadata.CommonModules.IntegrationWith<ServiceName>`).
  - **Data**: reference tới object cụ thể, hoặc primitive types, Undefined, Null, Type. Chỉ điền khi giúp lọc chính xác hơn; không điền reference tới object chưa được ghi (object không tồn tại).
  - **Commentary** (String): thông tin dạng text không cấu trúc; không gộp nhiều sự kiện vào một comment; không đặt dữ liệu có kích thước không biết trước (nội dung file, response web service...) — hướng tới tối đa **10 KB**.
  - **TransactionMode** (EventLogEntryTransactionMode): independent hoặc transactional; sự kiện trong transaction → dùng "Transactional".
- Ghi thông tin exception vào log: `ErrorProcessing.DetailErrorDescription(ErrorInfo())`.
- Mở Event log: Designer — menu **Administration - Event log**; Enterprise mode — menu **"Functions for technician"** (technician mode thường bị tắt trong infobase mới, cần bật trước).

## Cú pháp & ví dụ code

FillPropertyValues:
```bsl
FillPropertyValues(ThisObject, LastValues);
```

Explicit transaction:
```bsl
Procedure LoadCounterpartyAndContract(ExternalData)
    // no need to begin a transaction inside the Try statement
    BeginTransaction(); 
    Try
        Counterparty = Catalogs.Counterparties.CreateItem();
        FillPropertyValues(Counterparty, ExternalData);
        Counterparty.Write();
        
        CounterpartyContract = Catalogs.CounterpartyContracts.CreateItem();
        FillPropertyValues(CounterpartyContract, ExternalData);
        
        CounterpartyContract.Owner = Counterparty.Ref;
        CounterpartyContract.Write();
        // If no errors occurred, commit all changes to the database
        CommitTransaction();
    Except
        // If there was an error, cancel all changes, so they won't be written to the database
        RollbackTransaction();
        
        ErrorInformation = DetailErrorDescription(ErrorInfo());
        
        WriteLogEvent(
            "Data import",
            EventLogLevel.Error,,,
            ErrorInformation,
            EventLogEntryTransactionMode.Transactional
        );
        
        Message(ErrorInformation);
    EndTry;
EndProcedure
```

Implicit exceptions — truy cập property không tồn tại:
```bsl
IntegrationSettings = New Structure;
IntegrationSettings.Insert("Name", "James Bond");
IntegrationSettings.Insert("Password", "007");
WebAddress = IntegrationSettings.WebAddress;
```

Chia cho 0:
```bsl
Amount = 10;
Quantity = 0;
Price = Amount/Quantity;
```

Lỗi khi làm việc với database object:
```bsl
NewSalesInvoice = Documents.SalesInvoice.CreateDocument();
NewSalesInvoice.Write(DocumentWriteMode.Posting);
```

WriteLogEvent — chữ ký:
```bsl
WriteLogEvent(
    EventName (String),
    Level (EventLogLevel),
   MetadataObject (Metadata.Documents.SalesInvoice, Metadata.CommonModules.TasksClient...),
   Data (Type: Any reference, Number, String, Date, Boolean, Undefined,Null, Type),
   Commentary (String),
   TransactionMode (EventLogEntryTransactionMode)
);
```

Tên sự kiện:
```bsl
"Tasks.New task notification"
"Tasks.Pending task notification"

// Correct:
"Document posting.Cannot unpost"
"Employees.Employee not found in the infobase"
```

Ghi exception vào log:
```bsl
ErrorProcessing.DetailErrorDescription(ErrorInfo())
```

[ghi chú ngoài nguồn] Các ví dụ khác (FillCheckProcessing với CheckedAttributes và Find(), visibility theo Type, query kiểm tra Amount qua temporary table, GetLast trong OnCreateAtServer, ghi bằng RecordManager, xóa bằng RecordSet, xử lý exception với BriefErrorDescription) chỉ có dạng ảnh chụp màn hình, không có văn bản code nên không được chép lại. → FillCheckProcessing với Find(), visibility theo Type, query Amount qua temporary table, GetLast trong OnCreateAtServer, RecordManager và BriefErrorDescription → xem mục Code demo của bài Theory (nhánh lesson/12-theory). Riêng ví dụ xóa bằng RecordSet không có trong nhánh lesson/12-theory nên vẫn chưa có code.

## Thuộc tính/thiết lập quan trọng trong Designer
- Attribute / tabular section: **Required field** = **Display error**.
- Object event: **FillCheckProcessing** (tham số **Cancel**, **CheckedAttributes**); method **CheckFilling()**.
- Form events: **OnOpen**, **OnCreateAtServer**, **OnWriteAtServer**, **AfterWriteAtServer**; field event **OnChange**; form property **Modified**.
- Object events: **BeforeWrite**, **OnWrite**, **Posting**.
- Information register: **Periodicity** (None, Second, Day, Month, Quarter, Year, **By recorder position**); service attribute **Period**; **Write mode** = **Independent** (mặc định) / subordinate to recorder.
- Dimension: property **Master**.
- Document form: tab **Command interface** → nhánh **Go to** → cột **Visible**.
- Catalog subordinate: standard attribute **Owner**.
- Event log: Designer **Administration - Event log**; Enterprise **Functions for technician**.

## Lỗi thường gặp / lưu ý
- Posting document từ code không kích hoạt FillCheckProcessing nếu không gọi CheckFilling().
- Trong FillCheckProcessing không thể đọc dữ liệu object theo reference (object chưa được ghi) → dùng dữ liệu object hiện tại qua temporary table.
- Xóa phần tử mảng phải theo index (Find() trả Undefined nếu không có).
- Visibility chỉ cập nhật trong OnChange → phải gọi thêm từ OnOpen.
- Thêm record trùng tập dimensions (+ Period nếu periodic) vào information register → exception.
- RecordManager chỉ dùng cho independent register; không dùng cho số lượng lớn records (dùng 2 RecordSets bên trong).
- Ghi register trong AfterWriteAtServer (sau commit) → có thể mất một phần thay đổi; chuyển sang OnWriteAtServer / OnWrite.
- Đặt CommitTransaction() cuối khối Try; RollbackTransaction() đầu khối Except; BeginTransaction() không cần đặt trong Try.
- Raise exception ngắt code — khi cần báo tất cả lỗi, dùng Cancel = True.
- Không để khối Except rỗng; luôn ghi exception vào Event log.
- Event name không chứa giá trị cụ thể; comment không gộp nhiều sự kiện, không quá ~10 KB; không truyền reference tới object chưa ghi vào Data.
- Event log không nằm trong database, không theo export/import infobase.

## Điểm cần nhớ
- FillCheckProcessing: Cancel + CheckedAttributes; kích hoạt khi post/ghi interactive hoặc khi gọi CheckFilling().
- Information register: duy nhất theo dimensions (+ Period nếu periodic); resources có thể là bất kỳ kiểu nào.
- Chỉ periodic register mới có virtual tables SliceFirst / SliceLast; methods SliceFirst/SliceLast (value table) và GetFirst/GetLast (structure).
- Write mode Independent cho phép ghi trực tiếp; RecordSet (nhiều records) vs RecordManager (một record, chỉ independent); Write(Replace).
- Property Master của dimension: điều hướng "Go to" cho independent register + tự xóa records khi object bị xóa.
- Transactions: BeginTransaction / CommitTransaction / RollbackTransaction trong Try-Except; OnWriteAtServer/OnWrite chạy trong transaction, AfterWriteAtServer thì không.
- Cancel = True không ngắt code; Raise ngắt code.
- WriteLogEvent(EventName, Level, MetadataObject, Data, Commentary, TransactionMode); ghi exception bằng ErrorProcessing.DetailErrorDescription(ErrorInfo()).

## Thẻ gợi ý bài thực hành (Practice 12)

> Thẻ gợi ý dẫn hướng cho từng yêu cầu của 12. Practice.docx; không có lời giải hoàn chỉnh. Nhắc lại yêu cầu chung của đề: mọi object mới phải nằm trong subsystem phù hợp và có synonym đúng cho list form, item form, record form.

### Bài tập 1 — InventoryTransfer: chặn posting khi kho gửi = kho nhận
- **Đề bài (tóm tắt):** Không cho post document có WarehouseSender trùng WarehouseRecepient, kèm thông báo rõ ràng.
- **Gợi ý 1 — Hướng đi:** Kiểm tra logic giữa hai attribute (không chỉ "đã điền") → event **FillCheckProcessing** của object (mục Data validation); hủy bằng tham số **Cancel**.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Object module của InventoryTransfer, `Procedure FillCheckProcessing(Cancel, CheckedAttributes)`; so sánh hai attribute; `Message(...)` để báo user.
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If ___ Then
		// hủy posting: Cancel = ___
		// thông báo cho user: ___
	EndIf;
EndProcedure
```
- **Lỗi hay gặp:**
  - Đặt kiểm tra trong `Posting` → vẫn chạy được nhưng sai vị trí; FillCheckProcessing là chỗ dành cho kiểm tra dữ liệu nhập.
  - Quên rằng post từ code không gọi FillCheckProcessing nếu không gọi `CheckFilling()`.
  - Hai kho đều rỗng cũng "bằng nhau" → nên để Required field xử lý trường hợp rỗng.
- **Tự kiểm tra:** Chọn cùng một kho ở hai field rồi Post → không post được, thấy thông báo; đổi kho nhận khác → post bình thường.

### Bài tập 2 — Catalog Companies và attribute Company trong documents
- **Đề bài (tóm tắt):** Tạo object lưu danh sách công ty của mình; thêm attribute bắt buộc Company vào PurchaseInvoice, SalesInvoice, ReturnOfGoodsFromCustomer; sửa Filling của return để chép Company từ sales invoice.
- **Gợi ý 1 — Hướng đi:** Danh sách công ty → Catalog; "bắt buộc" → property **Required field** = Display error; Filling của return đã có từ Bài 11, chỉ cần thêm một dòng gán.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Catalog `Companies`; attribute `Company` (`CatalogRef.Companies`, Required field) trong ba documents + đặt field lên form; handler `Filling` trong object module của ReturnOfGoodsFromCustomer.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo catalog Companies, đưa vào subsystem (ví dụ Master data).
  2. Thêm attribute Company vào 3 documents, đặt Required field, kéo lên form.
  3. Trong Filling của return: thêm phép gán Company từ `FillingData`.
- **Lỗi hay gặp:**
  - Sửa Filling bằng cách chạy lại Generation settings wizard → mất phần đã sửa tay ở Bài 11.
- **Tự kiểm tra:** Tạo return từ một sales invoice có Company → field Company được điền; xóa Company rồi post → báo lỗi field bắt buộc.

### Bài tập 3 — Dimension Company trong register Sales
- **Đề bài (tóm tắt):** Thêm dimension Company vào accumulation register Sales và sửa Posting của mọi document ghi register này.
- **Gợi ý 1 — Hướng đi:** Thêm dimension mới → mọi nơi tạo record của register phải gán dimension đó (mục Document posting, RegisterRecords).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Register `Sales` → dimension `Company`; Posting của SalesInvoice và ReturnOfGoodsFromCustomer: thêm phép gán Company cho record ở **mọi** vòng lặp ghi Sales.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm dimension.
  2. Tìm mọi chỗ `RegisterRecords.Sales.Add()` (Edit → Find in modules).
  3. Ở mỗi chỗ, gán `Company` của document.
- **Lỗi hay gặp:**
  - Chỉ sửa vòng Services hoặc chỉ vòng Products. [ghi chú ngoài nguồn] Một bản lời giải trung gian của khóa chỉ gán Company ở vòng Services, quên vòng Products — đừng lặp lại lỗi này.
  - Quên document ReturnOfGoodsFromCustomer.
- **Tự kiểm tra:** Re-post một sales invoice có cả goods và services, mở records của register Sales → mọi dòng đều có Company.

### Bài tập 4 — Banks, BankAccounts (subordinate tới Companies/Counterparties), subsystem Funds
- **Đề bài (tóm tắt):** Catalog Banks và BankAccounts: một bank có nhiều account, mỗi account có đúng một bank bắt buộc; subsystem Funds; mỗi bank account subordinate tới một company **hoặc** counterparty.
- **Gợi ý 1 — Hướng đi:** "Subordinate tới company hoặc counterparty" → catalog **subordinate** với property **Owners** chứa hai catalog (standard attribute **Owner**); liên kết với bank → attribute thường, bắt buộc.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** `BankAccounts`: tab Owners → thêm `Catalog.Companies` và `Catalog.Counterparties`; attribute `Bank` (`CatalogRef.Banks`, Required field = Display error); subsystem `Funds` chứa cả hai catalog.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo/kiểm tra catalog Banks (nếu đã làm ở Bài 10, tái sử dụng).
  2. BankAccounts: đặt Owners, thêm attribute Bank bắt buộc.
  3. Tạo subsystem Funds và đưa hai catalog vào.
- **Lỗi hay gặp:**
  - Đặt Banks làm owner (thay vì attribute) → không còn chỗ cho owner Companies/Counterparties như đề yêu cầu.
  - Quên Required field cho Bank.
- **Tự kiểm tra:** Mở item form của một company/counterparty → có link tới danh sách bank accounts của nó; không lưu được account chưa có bank.

### Bài tập 5 — Attribute "Bank account" với giới hạn lựa chọn
- **Đề bài (tóm tắt):** Thêm attribute bắt buộc BankAccount vào PurchaseInvoice, SalesInvoice, ReturnOfGoodsFromCustomer; PurchaseInvoice chỉ chọn account của counterparty (Vendor) trong document; SalesInvoice và return chỉ chọn account của Company.
- **Gợi ý 1 — Hướng đi:** Lọc danh sách chọn theo giá trị field khác bằng **choice parameter links** của attribute: `Filter.Owner` lấy từ attribute tương ứng của document — không cần code.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Attribute `BankAccount` (`CatalogRef.BankAccounts`, Required field); properties palette → **Choice parameter links** → thêm link tên `Filter.Owner`, data path tới attribute `Vendor` (PurchaseInvoice) hoặc `Company` (SalesInvoice, return).
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm attribute vào 3 documents, đặt lên form.
  2. Ở từng document, đặt Choice parameter links như trên.
  3. Cân nhắc chế độ thay đổi giá trị (Clear) khi Vendor/Company đổi.
  4. Bổ sung BankAccount vào Filling của return.
- **Lỗi hay gặp:**
  - Link nhầm sang Customer ở SalesInvoice (đề yêu cầu account của **Company**). Lưu ý: attribute Contract của SalesInvoice có link `Filter.Owner` theo Customer (đúng), còn BankAccount phải theo Company — đừng nhầm hai link.
  - Đặt choice parameters (giá trị cố định) thay vì choice parameter links (theo field).
- **Tự kiểm tra:** Đổi Company trên sales invoice → danh sách Bank account chỉ còn account của company đó.

### Bài tập 6 — Kiểm tra đủ hàng trong kho khi post SalesInvoice và InventoryTransfer
- **Đề bài (tóm tắt):** Kiểm tra trong handler **Posting**: không đặt `Write = True` cho GoodsInWarehouses, mà thêm records, gọi `Write()`, rồi query tìm số dư âm; với mỗi product thiếu báo "Not enough %1 units of product %2 in the warehouse %3" và hủy posting. InventoryTransfer kiểm tra theo WarehouseSender.
- **Gợi ý 1 — Hướng đi:** Sau khi `Write()`, movements của chính document đã nằm trong database (trong transaction posting) → đọc virtual table **Balance** tại **PointInTime** của document **bao gồm** chính thời điểm đó (**Boundary** Including, mục Date, PointInTime, Boundary của Bài 11) và lọc số dư `< 0`. Dùng `Cancel = True` (không `Raise`) để báo **mọi** product thiếu (mục Transactions — Cancel vs Raise).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Object module, trong `Posting`: bỏ `Write = True` của GoodsInWarehouses; sau vòng lặp gọi `RegisterRecords.GoodsInWarehouses.Write()`; rồi gọi procedure kiểm tra (có thể tách riêng, nhận `Cancel`).
  - Query: `AccumulationRegister.GoodsInWarehouses.Balance(&Period, Product IN (&Products) AND Warehouse = &Warehouse)`; `&Period` = `New Boundary(PointInTime(), BoundaryType.Including)`; `&Products` = mảng product từ tabular section (`UnloadColumn`).
  - Thông báo: `StrTemplate(...)` với số thiếu = giá trị âm đổi dấu.
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure ___(Cancel)
	// Query: SELECT Product, QuantityBalance FROM ...Balance(&Period, ___) WHERE ___ < 0
	// Period = New Boundary(___, BoundaryType.___)
	// Products = ___ ; Warehouse = ___
	// While Selection.Next(): Message(StrTemplate("Not enough %1 ...", ___)); Cancel = ___
EndProcedure
```
- **Lỗi hay gặp:**
  - Giữ `Write = True` và không gọi `Write()` → khi query chạy, movements của document chưa có, kiểm tra luôn "đủ".
  - Dùng Period kiểu Date hoặc PointInTime không có Boundary → không thấy movements của chính document.
  - Kiểm tra trong FillCheckProcessing → không đọc được movements của document (object chưa ghi).
  - Dùng `Raise` → chỉ báo product đầu tiên.
  - Sales invoice: kiểm tra theo `Warehouse`; Inventory transfer: theo `WarehouseSender` (không phải kho nhận).
- **Tự kiểm tra:** Kho có 5 cái, tạo sales invoice bán 7 → không post được, thông báo "Not enough 2 units ..."; bán 5 → post được. Re-post một document cũ đã post cũng phải kiểm tra đúng (số lượng cũ của chính nó không bị tính hai lần).

### Bài tập 7 — Attribute State của SalesInvoice (Planned, InDelivery, Completed)
- **Đề bài (tóm tắt):** Attribute State với 3 giá trị cố định, user không thêm được giá trị; mặc định Planned; ở state Planned không ghi movement hàng hóa.
- **Gợi ý 1 — Hướng đi:** Tập giá trị cố định do developer định nghĩa → **Enumeration**; giá trị mặc định → property **Fill value** của attribute; điều kiện trong Posting.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Enumeration `SalesInvoiceStates` (Planned, InDelivery, Completed); attribute `State` kiểu `EnumRef.SalesInvoiceStates`, Fill value = Planned; trong `Posting` so sánh `State` với `Enums.SalesInvoiceStates.Planned` ở đầu procedure.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo enumeration và attribute, đặt Fill value, kéo field lên form.
  2. Trong Posting: nếu State là Planned thì không ghi movements (thoát sớm hoặc bọc phần ghi trong điều kiện).
- **Lỗi hay gặp:**
  - Dùng catalog cho State → user tự thêm được giá trị (trái đề).
  - Chỉ bỏ movements GoodsInWarehouses nhưng vẫn ghi Sales — đề nói "movement of goods"; quyết định rõ và nhất quán. [ghi chú ngoài nguồn] Lời giải tham khảo của khóa bỏ qua toàn bộ movements khi Planned.
- **Tự kiểm tra:** Document mới có State = Planned; post → không có records trong GoodsInWarehouses; đổi sang InDelivery và post lại → có records.

### Bài tập 8 — Lịch sử state của SalesInvoice
- **Đề bài (tóm tắt):** Object lưu lịch sử: ngày đặt state, Document, State. Chỉ thêm record khi state **thay đổi** so với giá trị trong database (document mới: ghi state lúc ghi lần đầu); phân tích trước khi ghi object; ghi lịch sử cùng lúc với document — lỗi thì document không được ghi và có record lỗi trong event log.
- **Gợi ý 1 — Hướng đi:**
  - Lưu lịch sử theo thời gian → **periodic information register**, **independent** (ghi khi chỉ "Write", không cần post).
  - Lấy giá trị cũ **trước khi ghi** trong **BeforeWrite** (đọc qua `Ref`), truyền sang **OnWrite** bằng **AdditionalProperties** (mục AdditionalProperties của Bài 11).
  - Ghi trong **OnWrite** của object (chạy trong transaction ghi document, mục Transactions) bằng **RecordManager**; bọc trong `Try - Except` + **WriteLogEvent** + hủy ghi.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Information register `SalesInvoiceStates`: Periodicity đủ nhỏ để đổi nhiều lần trong ngày (ví dụ Second), Write mode Independent; dimension `SalesInvoice` (`DocumentRef.SalesInvoice`, có thể bật Master), resource `State`.
  - Object module SalesInvoice: `BeforeWrite(Cancel, WriteMode, PostingMode)` và `OnWrite(Cancel)`.
  - `InformationRegisters.SalesInvoiceStates.CreateRecordManager()`, `Write(True)`; `CurrentSessionDate()` cho ngày.
  - Trong Except: `WriteLogEvent(<"Nhóm.Sự kiện">, EventLogLevel.Error, ..., DetailErrorDescription(ErrorInfo()), EventLogEntryTransactionMode.Transactional)` rồi `Cancel = True` (hoặc Raise).
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	// lưu state cũ trong database vào AdditionalProperties: ___
EndProcedure

Procedure OnWrite(Cancel)
	// If state hiện tại <> state cũ Then
	//   Try: tạo RecordManager, gán Period, SalesInvoice, State = ___; Write(___)
	//   Except: WriteLogEvent(___); Cancel = ___
	// EndIf
EndProcedure
```
- **Lỗi hay gặp:**
  - So sánh trong OnWrite bằng `Ref.State` → lúc này database đã có giá trị mới, luôn "không đổi".
  - Ghi ở form `AfterWriteAtServer` → ngoài transaction, lỗi không hủy được việc ghi document; và không chạy khi ghi từ code.
  - Periodicity Day → đổi state hai lần trong ngày bị ghi đè/lỗi trùng.
  - Khối Except rỗng; [ghi chú ngoài nguồn] lời giải tham khảo của khóa thiếu phần `Try - Except` + `WriteLogEvent` mà đề yêu cầu — bạn cần tự thêm.
  - Document mới: `Ref` rỗng nên state cũ là giá trị rỗng → lần ghi đầu luôn tạo record (đúng đề).
- **Tự kiểm tra:** Tạo document, đổi state Planned → InDelivery trước khi ghi, ghi → register có 1 record InDelivery; đổi lại Planned, ghi → thêm record; ghi lại không đổi state → không thêm. Để thử nhánh lỗi, tạm gây exception trong Try và xem Event log (Designer: Administration - Event log).

### Bài tập 9 — Giá theo ngày: document PriceSetup và register ProductPrices
- **Đề bài (tóm tắt):** Lưu giá theo ngày bắt đầu hiệu lực, mỗi product đổi giá tối đa một lần/ngày; giá được đặt (lẻ hoặc hàng loạt) bằng document PriceSetup, ngày document là ngày hiệu lực; register ProductPrices; đưa vào Sales.
- **Gợi ý 1 — Hướng đi:** Giá theo thời gian → **periodic information register** với Periodicity **Day**; giá chỉ được đổi qua document để có dấu vết → Write mode **subordinate to recorder** (mục Write mode); document ghi register trong **Posting** giống accumulation register.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Register `ProductPrices`: dimension `Product`, resource `Price`, Periodicity Day, Write mode Subordinate to recorder. Document `PriceSetup`: tabular section `Products` (Product, Price); tab Posting → `ProductPrices`; object module `Posting` với `RegisterRecords.ProductPrices`, `Period = Date`.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo register và document, đưa vào subsystem Sales.
  2. Chọn register trong tab Posting của PriceSetup (Record wizard sinh được khung).
  3. Posting: mỗi dòng một record (Period, Product, Price).
- **Lỗi hay gặp:**
  - Để register Independent → user sửa giá trực tiếp, không dấu vết (trái tinh thần đề).
  - Hai dòng cùng product trong một PriceSetup → trùng dimensions + Period → lỗi khi post.
- **Tự kiểm tra:** Post PriceSetup ngày 01 giá 100 và ngày 10 giá 120 → list của register có 2 records với recorder là các document.

### Bài tập 10 — SalesInvoice tự điền giá theo register, khóa Price/Amount
- **Đề bài (tóm tắt):** Khi chọn/đổi product → tự điền giá từ register (nếu có); giữ các xử lý liên quan khi đổi giá, trừ kiểm tra giá tối thiểu (tắt lời gọi, không xóa code); không cho sửa Price và Amount; thiếu giá thì không post được.
- **Gợi ý 1 — Hướng đi:** Giá có hiệu lực tại ngày document = record mới nhất tại ngày đó → virtual table **SliceLast** (hoặc method `GetLast`) của periodic register (mục Đọc dữ liệu information register). Dữ liệu register chỉ đọc trên server → client gọi một function server.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form module SalesInvoice: handler OnChange của cột Product (cả Products và Services) và ChoiceProcessing (khi Pick) cùng gọi một procedure client "khi đổi product".
  - Function `&AtServerNoContext` (hoặc export function trong manager module của register) nhận Product và Date, trả giá: query `InformationRegister.ProductPrices.SliceLast(&Period, Product = &Product)`, không có dòng → 0.
  - Sau khi gán giá: gọi lại tính Amount dòng; lời gọi kiểm tra giá tối thiểu thì comment lại.
  - Cột Price, Amount: ReadOnly trên form; Price trong tabular section đặt **Required field** để thiếu giá thì posting báo field rỗng.
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtClient
Procedure ___(CurrentData)
	// CurrentData.Price = ___(CurrentData.Product, Object.Date)
	// // ControlMinimumSalesPrice(___);  <- tắt lời gọi, giữ procedure
	// tính lại Amount của dòng: ___
EndProcedure

&AtServerNoContext
Function ___(Product, Date)
	// query SliceLast(&Period, Product = &Product); không có dòng -> Return ___
EndFunction
```
- **Lỗi hay gặp:**
  - Đọc register trực tiếp trong procedure `&AtClient` → lỗi (register không truy cập được trên client).
  - Chỉ xử lý OnChange, quên dòng thêm bằng Pick (ChoiceProcessing).
  - Không đặt Required field cho Price → document có giá 0 vẫn post được.
  - Đổi Date của document không tự cập nhật giá các dòng đã có — đề không bắt buộc, nhưng nên biết.
- **Tự kiểm tra:** Đặt giá 100 từ ngày 01, 120 từ ngày 10 → sales invoice ngày 05 nhận 100, ngày 12 nhận 120; product không có giá → Price = 0 và post báo lỗi field rỗng; không gõ được vào Price/Amount.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/12-theory)

So với nhánh lesson/11-theory, nhánh lesson/12-theory thêm: FillCheckProcessing của SalesInvoice, ẩn/hiện group Weight/Promotional trên item form của Products, catalog Companies và independent information register `CompaniesResponsiblePersons` (periodicity `Day`, Write mode `Independent`, dimension `Company` có flag `Master` = true).

### FillCheckProcessing của Sales invoice: Products/Services, Find() và query qua temporary table
Nguồn: nhánh lesson/12-theory — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If Products.Count() > 0 Then
		DeleteAttributeFromChecking(CheckedAttributes, "Services");
	ElsIf Services.Count() > 0 Then	
		DeleteAttributeFromChecking(CheckedAttributes, "Products");
	EndIf;

	// Turn off checking by the platform
	DeleteAttributeFromChecking(CheckedAttributes, "Products.Amount");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Products.LineNumber AS LineNumber,
	|	Products.Product AS Product,
	|	Products.Amount AS Amount
	|INTO TempTableProducts
	|FROM
	|	&Products AS Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTableProducts.LineNumber AS LineNumber,
	|	TempTableProducts.Product AS Product,
	|	TempTableProducts.Amount AS Amount
	|FROM
	|	TempTableProducts AS TempTableProducts
	|		INNER JOIN Catalog.Products AS Products
	|		ON TempTableProducts.Product = Products.Ref
	|WHERE
	|	NOT Products.Promotional
	|	AND TempTableProducts.Amount = 0";
	
	Query.SetParameter("Products", Products);
	
	// Execute query and select data from the query result
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		MessageText = StrTemplate(
			"The ""Amount"" is required on line %1 of the ""Products"" list.",
			Selection.LineNumber
		);
		Message(MessageText);
		Cancel = True;
		
	EndDo;
	
EndProcedure

Procedure DeleteAttributeFromChecking(CheckedAttributes, AttributeToDelete)

	IndexOfAttribute = CheckedAttributes.Find(AttributeToDelete);
	If IndexOfAttribute <> Undefined Then
	
		CheckedAttributes.Delete(IndexOfAttribute);
	
	EndIf;

EndProcedure
```
- Đúng ví dụ trong lý thuyết: cả Products và Services đều "Required field"; tabular section nào có dòng thì tabular section kia bị loại khỏi `CheckedAttributes`.
- Việc tìm index bằng `Find()` rồi `Delete()` được tách thành procedure riêng `DeleteAttributeFromChecking` vì dùng lặp lại.
- `"Products.Amount"` bị loại khỏi kiểm tra của nền tảng, thay bằng query riêng: vì FillCheckProcessing chạy TRƯỚC khi ghi, tabular section được truyền vào parameter `&Products`, chọn INTO `TempTableProducts`, rồi join với `Catalog.Products` để bỏ qua sản phẩm `Promotional`.
- Dùng `Cancel = True` (không `Raise`) trong vòng lặp → user nhận thông báo cho **tất cả** các dòng thiếu Amount.

### Ẩn group Weight/Promotional khi product là Service (OnOpen + OnChange)
Nguồn: nhánh lesson/12-theory — cf/Catalogs/Products/Forms/ItemForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure OnOpen(Cancel)
	ChangeVisibilityOfWeightPromotional();
EndProcedure

&AtClient
Procedure TypeOnChange(Item)
	ChangeVisibilityOfWeightPromotional();
EndProcedure

&AtClient
Procedure ChangeVisibilityOfWeightPromotional()

	If Object.Type = PredefinedValue("Enum.ProductTypes.Service") Then
		Items.GroupWeightPromotional.Visible = False;
	Else
		Items.GroupWeightPromotional.Visible = True;
	EndIf;	

EndProcedure
```
- Một procedure client `ChangeVisibilityOfWeightPromotional()` được gọi từ cả event form `OnOpen` (khi mở form visibility là mặc định) và `TypeOnChange` của field Type.
- So sánh với giá trị enumeration trên client phải dùng `PredefinedValue("Enum.ProductTypes.Service")`.
- Ẩn cả group `GroupWeightPromotional` thay vì từng field.

### Đọc người chịu trách nhiệm bằng GetLast và FillPropertyValues trong OnCreateAtServer
Nguồn: nhánh lesson/12-theory — cf/Catalogs/Companies/Forms/ItemForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ResponsiblePersons = ResponsiblePersons(CurrentSessionDate(), Object.Ref);
	
	FillPropertyValues(ThisObject, ResponsiblePersons);
	
EndProcedure
// ...
&AtServerNoContext
Function ResponsiblePersons(Period, Company)

	Filter = New Structure("Company", Company);
	
	Return InformationRegisters.CompaniesResponsiblePersons.GetLast(
		Period,
		Filter
	);
	
EndFunction
```
- `GetLast(<EndOfPeriod>, <Filter>)` trả về structure có các properties trùng resources (CEO, ChiefAccountant, CTO); nếu chưa có record → giá trị default.
- Filter là `Structure` với key là tên dimension (`Company`).
- `FillPropertyValues(ThisObject, ResponsiblePersons)` điền các form attributes cùng tên — đúng ví dụ "GetLast trong OnCreateAtServer" của lý thuyết.
- Function đặt `&AtServerNoContext` vì chỉ cần tham số, không cần dữ liệu form; dữ liệu register chỉ đọc được trên server.

### Ghi bằng RecordManager trong OnWriteAtServer, bắt lỗi bằng BriefErrorDescription
Nguồn: nhánh lesson/12-theory — cf/Catalogs/Companies/Forms/ItemForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Try
	
		UpdateResponsiblePersons(CurrentObject.Ref);
	
	Except
		
		Cancel = True;
		ErrorText = StrTemplate(
			"Failed to update responsible persons with the error: %1",
			ErrorProcessing.BriefErrorDescription(ErrorInfo())
		);
		Message(ErrorText);

	EndTry;
	
EndProcedure

&AtServer
Procedure UpdateResponsiblePersons(Company)

	Period = CurrentSessionDate();
	
	ResponsiblePersons = ResponsiblePersons(Period, Company);
	
	If ResponsiblePersons.CEO <> CEO
		Or ResponsiblePersons.ChiefAccountant <> ChiefAccountant
		Or ResponsiblePersons.CTO <> CTO Then
				
		RecordManager = InformationRegisters.CompaniesResponsiblePersons.CreateRecordManager();
		
		RecordManager.Company = Company;
		RecordManager.Period = Period;
		
		RecordManager.CEO = CEO;
		RecordManager.ChiefAccountant = ChiefAccountant;
		RecordManager.CTO = CTO;
		
		RecordManager.Write(True);
		
	EndIf;

EndProcedure
```
- Thuật toán nằm ở `OnWriteAtServer` (trong transaction ghi object) chứ không ở `AfterWriteAtServer` → lỗi ghi register thì `Cancel = True` hủy luôn việc ghi company.
- Chỉ thêm record khi ít nhất một resource khác với bản ghi cuối (so sánh qua `ResponsiblePersons(...)`).
- `CreateRecordManager()` dùng được vì register là independent; `Write(True)` (Replace = True) ghi đè record cùng Company + Period nếu đổi người chịu trách nhiệm nhiều lần trong ngày.
- `ErrorProcessing.BriefErrorDescription(ErrorInfo())` cho mô tả ngắn để hiện cho user; khi cần ghi Event log thì dùng `DetailErrorDescription` như ví dụ Explicit transaction ở mục "Cú pháp & ví dụ code".

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Thẩm định dữ liệu](https://www.youtube.com/watch?v=DVdxgqJrd14&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=12) (14:16) — Bài 12 — Data validation, FillCheckProcessing, CheckFilling() _(mã nội bộ JC-13)_
- [Đối tượng và tập hợp bản ghi](https://www.youtube.com/watch?v=L4OkNedrIeQ&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=16) (5:26) — Bài 15 — object vs non-object entities; Bài 12 — RecordSet / RecordManager _(mã nội bộ JC-17)_
- [Biểu ghi thông tin](https://www.youtube.com/watch?v=2opmwhrnU2A&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=23) (7:54) — Bài 12 — Information register, periodic, SliceLast/SliceFirst, RecordSet/RecordManager _(mã nội bộ JC-24)_
