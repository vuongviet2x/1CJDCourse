# Bài 11 — Accumulation registers & Document posting

## Khái niệm chính

### Accumulation register — mục đích
- Mục đích của accumulation register: thu thập dữ liệu số theo các tập measurements (dimensions). Ví dụ register "Goods in warehouses" cho phép lấy số dư theo quantity và amount của hàng hóa tại kho tại bất kỳ thời điểm nào.
- Lý do dùng register thay vì tính số dư từ documents:
  - Nhiều loại document ảnh hưởng số dư ("Purchase invoice", "Movement of goods", "Inventory capitalization" tăng; "Sales", "Movement of goods", "Inventory write-off" giảm); danh sách có thể mở rộng → phải sửa thuật toán mỗi lần.
  - Business-process có thể thay đổi (ví dụ thêm attribute Status, chỉ "Approved" mới giảm số dư) → thuật toán càng phức tạp.
  - Số lượng document tăng → tính toán ngày càng nặng (ví dụ 50 nghìn document/năm → sau 5 năm là 250 nghìn).
- Records của accumulation register phụ thuộc (subordinate) vào documents là **recorders** của register → không thể thêm/sửa/xóa trực tiếp, chỉ thay đổi được qua document ảnh hưởng tới register.
- Cấu trúc register:
  - **Dimensions**: dữ liệu theo đó quantity/amount được ghi nhận (ví dụ Product, Warehouse).
  - **Resources**: những gì được tích lũy (ví dụ Quantity, Amount).
  - **Attributes**: lưu thông tin bổ sung cho mỗi record.

### Register kind
- Property **"Register kind"**: **Balances** hoặc **Turnovers**.
- Register kiểu Turnovers dùng khi cần lấy nhanh turnovers cho một kỳ (ví dụ chiết khấu theo doanh số trong tháng/quý/năm). Ví dụ: register Sales kiểu Turnovers, dimension Counterparty, resource Amount.
- Real table chứa dữ liệu từ một bảng vật lý; virtual table được tạo lúc thực thi query và có thể lấy dữ liệu từ một hoặc nhiều bảng vật lý.
- Virtual tables:
  - Register kiểu **Balances**: 3 virtual tables — **Balance**, **Turnovers**, **BalanceAndTurnovers**.
  - Register kiểu **Turnovers**: 1 virtual table — **Turnovers**.
- Ở mức database, accumulation register mọi kiểu lưu dữ liệu trong 2 bảng vật lý: **movement table** và **totals table** (totals table của hai kiểu khác nhau). Movement table chứa mọi record được đưa vào khi posting document.

### Bảng của register kiểu Balances
- Totals table lưu số dư theo mọi dimensions với tần suất tháng, tại đầu tháng. Hệ thống tính totals table dựa trên movement table; khoảng thời gian lưu số dư bị giới hạn bởi **period of calculated totals** — chỉ định là ngày cuối tháng mà totals được tính (ví dụ 31.05.2024 → totals được tính tới 01.06.2024 bao gồm). Ngoài ra, current totals được lưu riêng trong totals table.
- Ví dụ: record đầu tiên ngày 03.12.2023, period of calculated totals là 31.02.2024 → tại 10.03.2024, totals table lưu totals cho 01.01.2024, 01.02.2024, 01.03.2024 và current totals.
- Current totals có period **01.11.3999**.
- **Balance** (virtual table): luôn dùng totals table, đôi khi dùng movement table (tùy thời điểm tính và period of calculated totals). Chiến lược:
  1. Chọn thời điểm totals gần nhất lớn hơn hoặc bằng thời điểm cần tính.
  2. Lấy số dư từ totals table tại thời điểm đó.
  3. Nếu không trùng, tính số dư dựa trên movements từ thời điểm yêu cầu tới thời điểm totals.
  - Ví dụ: số dư tại 01.02.2024 = 42, movement chi (Expense) 3 trong khoảng 15.01–01.02 → số dư tại 15.01.2024 = 42 − (−3) = 45.
- **Turnovers** (virtual table của register Balances): luôn dùng dữ liệu từ movement table, bất kể period of calculated totals → nếu cần lấy turnovers thường xuyên, nên tạo register kiểu Turnovers.
- **BalanceAndTurnovers**: tính đồng thời balance và turnovers. Nếu không chỉ định periodicity → một query (chứa subqueries); nếu chỉ định periodicity → 2 query riêng, kết quả được kết hợp.

### Bảng của register kiểu Turnovers
- Totals table lưu turnovers đã tính (movements nhóm theo dimensions) với tần suất tháng, cho mọi kỳ có movements. **Không thể lấy balances** từ register này.
- Virtual table Turnovers lấy dữ liệu từ movement table, totals table hoặc cả hai, tùy period và periodicity:
  - Periodicity được chỉ định và nhỏ hơn tháng → chỉ dùng movement table.
  - Không chỉ định periodicity hoặc ≥ tháng → phụ thuộc period: các tháng trọn vẹn lấy từ totals table, phần còn lại lấy từ movement table. Không chỉ định period → lấy toàn bộ thời gian từ movement đầu tới cuối, cùng thuật toán.
  - Ví dụ (periodicity Month): 01.11.2023–30.11.2023 → chỉ totals table; 25.10.2023–15.01.2024 → tháng 11 từ totals table, (25.10–31.10) và (01.01–15.01) từ movement table; 25.10.2023–25.11.2024 → theo tài liệu: chỉ từ movement table vì kỳ không chứa tháng trọn vẹn.

### Lấy dữ liệu từ virtual tables
- 2 cách: built-in code và query.
- Built-in code: methods **Balance** và **Turnovers** của accumulation register, trả về value table (cột = dimensions và resources, có thể giới hạn qua tham số); có thể chỉ định period, filter, dimensions và resources.
- Built-in code không hỗ trợ lấy balances và turnovers cùng lúc.
- Gọi method Balance cho register kiểu Turnovers → ném exception.
- Lấy bằng query phổ biến hơn vì cho phép chọn lọc phức tạp, join và merge dữ liệu.
- Trong query wizard: chọn virtual table trong node AccumulationRegisters; mở virtual table settings bằng nút bánh răng (nếu nút không khả dụng, chọn bảng trong danh sách bảng đã chọn).
- **Balance** virtual table: 2 tham số — **period** và **condition**. Không chỉ định period → lấy current balances. Period thường là query parameter (`&` + tên). Condition: điều kiện bất kỳ trong query language, thường lọc theo giá trị dimensions; có thể dùng nested query (ví dụ lọc theo product trong temporary table).
  - **Note**: nested query trong condition phải tự viết, không tạo được bằng constructor.
- **Turnovers** virtual table: **BeginOfPeriod**, **EndOfPeriod**, **Periodicity** (tần suất nhóm records: Day, Month, ...). Khi periodicity tăng, records cùng giá trị dimensions được gộp trong kỳ, period đổi thành đầu kỳ.
  - Records chỉ nhóm theo các dimensions có trong selection (không phải tất cả dimensions của register).
  - **Note**: không có turnovers cho một tập dimensions trong kỳ → không trả về record (ví dụ tháng 12/2023 → kết quả rỗng).
  - Nếu mọi resource được chọn đều = 0 cho một tập dimensions (ví dụ +10 −10 = 0) → không có record. Nếu ít nhất một resource ≠ 0 → record được trả về (có thể có resource = 0).
- **BalanceAndTurnovers** virtual table: mỗi resource có 5 trường — Opening balance, Turnover, Receipt, Expense, Closing balance (Turnover/Receipt/Expense tính theo periodicity).
  - Tham số **ComplementMethod**: **RegisterRecords** → không gồm boundary periods (chỉ các kỳ có movements); **RegisterRecordsAndPeriodBoundaries** → gồm boundary periods bất kể có movements hay không.
- **Important**: luôn giới hạn dữ liệu chọn từ virtual table càng nhiều càng tốt. Bước đầu tiên của query là lấy dữ liệu từ virtual table; nếu lọc ở WHERE, database trước tiên lấy toàn bộ số dư (có thể hàng chục nghìn records) rồi mới lọc. Đặt điều kiện trong parameters của virtual table → chỉ lấy dữ liệu cần thiết ngay từ đầu.

### Document posting
- Cần xác định documents nào là recorders của accumulation register (hoặc ngược lại — chỉ định cho document các register nó có thể ghi).
- Viết code thêm records vào register. Công cụ **Record wizard** (Register record wizard): mở từ Document object editor, tab **Posting**, hoặc chuột phải vào document → **Wizards - Register record wizard**.
- Thường records được ghi trong event handler **Posting** — document ghi movements khi posting. Posting là dấu hiệu cần ghi nhận các thay đổi liên quan đến sự kiện đã xảy ra (ví dụ Sales invoice: trừ hàng khỏi kho, ghi nhận công nợ của người mua...).
- Record wizard:
  - Nếu object module đã có procedure Posting → cảnh báo procedure sẽ bị thay toàn bộ.
  - Bước đầu chọn một register; trong wizard có thể thêm các register khác.
  - Register kiểu Turnovers không cho chỉ định loại movement (receipt, expense); các kiểu register có icon khác nhau.
  - Điền tuần tự danh sách dưới (thuật toán điền register records) bằng cách chọn register ở danh sách trên.
  - Nếu document có tabular section, phải chọn nó trước để attributes xuất hiện trong danh sách Document attributes.
  - Nút **Fill Expressions**: tự điền các trường register trùng tên với trường document. Sau đó sửa bằng double-click trên trường có sẵn hoặc viết trực tiếp vào cột **Expression**.
  - Chọn đúng register record type (**Receipt**, **Expense**) — ví dụ Sales invoice giảm số dư kho → Expense.
  - Wizard để lại service comments đầu/cuối: code bên trong do Wizard tạo, mọi chỉnh sửa tay sẽ mất lần dùng Wizard tiếp theo. Mỗi lần dùng Record wizard và bấm OK, code procedure Posting bị thay toàn bộ, dù không sửa tay.
- 2 nhược điểm của code do Record wizard tạo:
  1. Không cho tạo movements từ nhiều tabular sections cùng lúc (ví dụ Products và Services — chỉ chọn được Products; Services phải tự viết).
  2. Việc duyệt cùng tabular section không được gộp cho nhiều register (duyệt Products 2 lần) → nên tối ưu.
- **RegisterRecords**: collection đặc biệt chứa record sets của mọi register mà document này là recorder. Truy cập record set qua property theo tên, ví dụ `RegisterRecords.Sales`, `RegisterRecords.GoodsByWarehouses`.
- Property **Write** của record set: sau khi thoát procedure Posting, các record set có Write = True sẽ được nền tảng tự ghi (mặc định False). Muốn ghi trước khi kết thúc Posting → dùng method `Write()`.

### Posting mode
- 2 loại: **real time** và **regular** (backdated). Real time posting xảy ra khi: metadata của document có properties "posting", "real time posting" và ngày document tại lúc posting là hôm nay. Khi đó nền tảng tự đổi thời gian document thành hiện tại.
- Real time dùng khi thời điểm thao tác chính xác tới giây là quan trọng (ví dụ bán lẻ: cấm bán rượu sau giờ nhất định, business lunch theo giờ, nhiều quầy thu ngân song song, gửi electronic checks lên hệ thống nhà nước chỉ nhận trong tuần gần nhất).
- Thời gian bị chỉnh về giây hiện tại khi posting → nên tắt real time posting cho document không cần.
- Document dịch vụ không phản ánh nghiệp vụ thực → có thể tắt posting.

### Date, PointInTime, Boundary
- Không có hạn chế nhập nhiều document cùng date/time → rủi ro số dư không chính xác tại ngày của một trong các document đó.
- Virtual table **Balance** với period kiểu Date: lấy dữ liệu **TRƯỚC** giây chỉ định. Virtual table **Turnovers**: lấy dữ liệu **BAO GỒM** các giây chỉ định trong BeginOfPeriod và EndOfPeriod.
  - Ví dụ: 4 Sales invoice, 0002–0004 cùng 10.01.2024 01:12:14 PM → từ document 0003, kiểm tra số dư theo ngày document không tính các document khác cùng giây.
- **PointInTime**: kiểu giá trị để làm việc chi tiết hơn trên trục thời gian; gồm 2 phần: date và link. Dù trùng giây, các document vẫn có thứ tự trên trục thời gian. Truyền PointInTime vào Period của Balance → lấy số dư ngay trước PointInTime đó (không tính chính document). Ví dụ "Pen": theo ngày → 100 cho cả 0002, 0003, 0004; theo PointInTime → 100, 85, 65.
- Tạo PointInTime: method `PointInTime()` hoặc `New PointInTime(...)`.
- Lấy số dư của giây kế tiếp (`DocumentDate + 1`) cũng được nhưng có thể gây hiểu nhầm cho developer khác.
- **Boundary**: đối tượng làm rõ việc bao gồm/loại trừ giá trị biên của kỳ — `BoundaryType.Including`, `BoundaryType.Excluding`. Có thể kết hợp Boundary và PointInTime để lấy số dư tại PointInTime bao gồm movements tại thời điểm đó.

### Features of document writing
- Khác biệt giữa chế độ interactive (user thao tác ở Enterprise mode) và programmatic (từ code).
- Khi tạo document form, property **RepostOnWrite** bật mặc định → user lưu document đã post từ form → nền tảng post lại.
- Từ code: method `Write()` có 2 tham số:
  - **WriteMode**: Posting, UndoPosting, Write.
  - **PostingMode**: RealTime, Regular.
  - Mặc định: Write mode = Write, Posting mode = Regular.
- Object và link tới document có method `Copy()` — tạo object mới chưa ghi vào database. Phải ghi object sau khi thay đổi xong, nếu không mọi thay đổi bị mất.
- Form table có method `Refresh()` để làm mới danh sách.
- Ví dụ lệnh "Copy and Post": thêm command vào list form Sales Invoice, nút trên command bar, tạo handler qua nút kính lúp ở property Action → "Create on client and a procedure on server".
- **Note**: trong list form, main attribute là dynamic list. Với form element kiểu Table gắn với attribute kiểu dynamic list, giá trị property **CurrentRow**: nếu main table là bảng của reference object → chứa link tới object được chọn, hoặc Undefined nếu không chọn dòng nào (thường chỉ khi danh sách rỗng). Với bảng gắn attribute kiểu khác, CurrentRow thường chứa row identifier (số).

### AdditionalProperties
- Property **AdditionalProperties** của object (reference objects như Catalog, Document; non-reference như Information register record set, accumulation register record set), kiểu **Structure**, để lưu/truyền thông tin bổ sung giữa các event handlers và methods.
- Ví dụ: không thể kiểm tra document có mới không trong handler Posting (khi đó object đã ghi vào database, có link nên không còn "new"). Kiểm tra trong event **BeforeWrite** rồi truyền qua AdditionalProperties.
- `IsNew()`: True với object mới, False với object đã ghi; chỉ reference objects có hàm này.

### Generation (tạo đối tượng dựa trên đối tượng khác)
- Cho phép tạo object mới dựa trên object khác, chuyển dữ liệu và mô tả thuật toán điền theo điều kiện (ví dụ theo loại object nguồn).
- Cấu hình: trong object editor, tab **Generation**, danh sách **"Generated based on"** → chọn metadata objects (bao nhiêu cũng được).
- Mô tả thuật toán điền trong event handler **Filling**. Event Filling xảy ra khi:
  - tạo object mới interactively;
  - tạo object mới dựa trên object khác;
  - gọi method `Fill()` của object từ code.
- Công cụ **Generation settings wizard**: giống Record wizard; nút Fill Expressions; tạo procedure `Filling()` trong object module với service comments — code bị thay toàn bộ lần dùng wizard tiếp theo.
- Ở Enterprise mode, list form và form của document nguồn có submenu **Generate**.
- Nên tạo attribute liên kết tới document nguồn (ví dụ `SalesDocument` kiểu `DocumentRef.SalesInvoice`) và điền trong Filling. Trên form: field không cho sửa, kiểu **"Label Field"** và bật property **hyperlink** để mở document nguồn.

## Cú pháp & ví dụ code

Methods Balance và Turnovers của accumulation register:
```bsl
// Get quantity and amount balance of all products at all warehouses
GoodsBalance = AccumulationRegisters.GoodsInWarehouses.Balance(Date);

// Get quantity balance of all products at the "Additional" warehouse
Filter = New Structure("Warehouse", AdditionalWarehouse);
GoodsBalance = AccumulationRegisters.GoodsInWarehouses.Balance(Date, Filter, "Product", "Quantity");

// Get turnovers for one product for the current month for all clients
Filter = New Structure("Product", ProductForSearch);
SalesTurnovers = AccumulationRegisters.Sales.Turnovers(
BegOfMonth(Date), EndOfMonth(Date), Filter, "Customer");
```

Write — method và property:
```bsl
// This is a method
RegisterRecords.Sales.Write();

// and this is a property
RegisterRecords.Sales.Write = True;
```

PointInTime:
```bsl
Query.SetParameter("Period", ThisObject.PointInTime());
```

```bsl
PointInTime = New PointInTime(DocumentOrAnyOtherDate, RefToDocument);
```

Lấy số dư giây kế tiếp (không khuyến khích vì dễ gây hiểu nhầm):
```bsl
Query.SetParameter("Period", DocumentDate + 1);
```

Boundary:
```bsl
Boundary = New Boundary(DocumentDate, BoundaryType.Including);
Query.SetParameter("Period", Boundary);
```

```bsl
StartDate = Date(2024, 01, 10);
EndDate = New Boundary(DocumentDate, BoundaryType.Excluding);
Query.SetParameter("StartDate", StartDate);
Query.SetParameter("EndDate", EndDate);
```

Ghi document từ code:
```bsl
Write(DocumentWriteMode.Posting, DocumentPostingMode.RealTime);

// The method has default values for both of the parameters:
// Write mode = Write, Posting mode = Regular
Write();
```

[ghi chú ngoài nguồn] Các ví dụ khác trong tài liệu gốc (query lấy Balance/Turnovers/BalanceAndTurnovers, code Posting do Record wizard tạo và bản đã tối ưu, kết hợp Boundary + PointInTime, lệnh "Copy and Post", BeforeWrite + AdditionalProperties, Filling do Generation settings wizard tạo) chỉ có dạng ảnh chụp màn hình, không có văn bản code nên không được chép lại. → Posting bản tối ưu, BeforeWrite + AdditionalProperties (IsNew), Filling do wizard tạo và lệnh "Copy and Post" → xem mục Code demo của bài Theory (nhánh lesson/11-theory); query Balance/Turnovers, Posting do Record wizard tạo và Boundary + PointInTime → xem Thẻ gợi ý bài thực hành. Query BalanceAndTurnovers vẫn chưa có.

## Thuộc tính/thiết lập quan trọng trong Designer
- Accumulation register: **Register kind** (**Balances** / **Turnovers**); Dimensions, Resources, Attributes; period of calculated totals.
- Virtual table parameters:
  - Balance: **Period**, **Condition**.
  - Turnovers: **BeginOfPeriod**, **EndOfPeriod**, **Periodicity**, condition.
  - BalanceAndTurnovers: thêm **ComplementMethod** (**RegisterRecords** / **RegisterRecordsAndPeriodBoundaries**).
- Document: tab **Posting** (recorders, Record wizard); properties **posting**, **real time posting**; tab **Generation** → **Generated based on**.
- Record wizard: nút **Fill Expressions**, cột **Expression**, register record type **Receipt**/**Expense**.
- Document form: property **RepostOnWrite** (mặc định bật).
- Command: property **Action** → "Create on client and a procedure on server".
- Form table: **CurrentRow**, method **Refresh()**.
- Form field: kiểu **Label Field**, property **hyperlink**.
- Record set: property **Write**, method **Write()**.
- Object: **AdditionalProperties**, **IsNew()**, **Copy()**, **Fill()**, **PointInTime()**.

## Lỗi thường gặp / lưu ý
- Gọi method Balance cho register kiểu Turnovers → exception.
- Không lấy được balances từ register kiểu Turnovers.
- Virtual table Turnovers của register Balances luôn đọc movement table → nếu cần turnovers thường xuyên, tạo register kiểu Turnovers.
- Lọc ở WHERE thay vì trong parameters của virtual table → lấy dữ liệu thừa, tốn tài nguyên.
- Dùng lại Record wizard / Generation settings wizard → code Posting / Filling bị thay toàn bộ, mất code tay và mất movements của các register bị quên.
- Record wizard không xử lý nhiều tabular sections và duyệt lặp tabular section cho từng register → cần tự sửa/tối ưu.
- Quên chọn đúng record type (Receipt/Expense).
- Real time posting ép thời gian về giây hiện tại → tắt cho document không cần.
- Balance với Date lấy dữ liệu trước giây chỉ định → các document cùng giây không được tính; dùng PointInTime/Boundary.
- Dùng `DocumentDate + 1` gây khó hiểu cho developer khác.
- Không kiểm tra được IsNew() trong Posting (object đã được ghi) — kiểm tra ở BeforeWrite.
- Sau `Copy()` phải ghi object, nếu không mất thay đổi.
- Nested query trong condition của virtual table phải tự viết.

## Điểm cần nhớ
- Accumulation register = dimensions + resources (số) + attributes; records chỉ thay đổi qua recorder documents.
- Register Balances có 3 virtual tables (Balance, Turnovers, BalanceAndTurnovers); register Turnovers chỉ có Turnovers.
- Mỗi register có movement table + totals table; totals theo tháng; current totals có period 01.11.3999.
- Luôn đặt filter trong parameters của virtual table, không ở WHERE.
- Ghi movements trong handler Posting qua RegisterRecords; record set có Write = True được tự ghi khi thoát Posting.
- Balance (Date) lấy dữ liệu trước giây chỉ định; Turnovers bao gồm giây biên; PointInTime = date + link; Boundary Including/Excluding.
- `Write(DocumentWriteMode..., DocumentPostingMode...)` — mặc định Write + Regular.
- Generation: tab Generation → Generated based on + handler Filling (Generation settings wizard).

## Thẻ gợi ý bài thực hành (Practice 11)

> Thẻ gợi ý dẫn hướng cho từng yêu cầu của 11. Practice.docx; không có lời giải hoàn chỉnh. Làm theo thứ tự Gợi ý 1 → 2 → 3.

### Bài tập 1 — Accumulation register GoodsInWarehouses
- **Đề bài (tóm tắt):** Tạo register cho biết bao nhiêu hàng, trị giá bao nhiêu đang ở từng kho; đưa vào subsystem phù hợp.
- **Gợi ý 1 — Hướng đi:** Cần **số dư** tại thời điểm bất kỳ → accumulation register, **Register kind = Balances** (mục Register kind, Bảng của register kiểu Balances).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Register `GoodsInWarehouses`: Dimensions `Product` (`CatalogRef.Products`), `Warehouse` (`CatalogRef.Warehouses`); Resources `Quantity`, `Amount` (Number). Subsystem: Warehouse.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo register, chọn Register kind.
  2. Thêm 2 dimensions, 2 resources.
  3. Đặt subsystem, synonym.
  4. (Register chưa lưu được dữ liệu cho tới khi có recorder — Bài tập 2.)
- **Lỗi hay gặp:**
  - Chọn kiểu Turnovers → không lấy được balances (gọi Balance sẽ lỗi).
  - Đặt Amount là dimension thay vì resource.
- **Tự kiểm tra:** Designer không báo lỗi khi cập nhật database; register xuất hiện trong tab Posting của các document ở bước sau.

### Bài tập 2 — Ba document ghi movements vào GoodsInWarehouses
- **Đề bài (tóm tắt):** PurchaseInvoice tăng số dư; SalesInvoice giảm số dư; InventoryTransfer giảm ở kho gửi và tăng ở kho nhận (Amount để trống). Services không được vào register (Note 2.1); tạm thời ghi giá vốn bằng amount trong document (Note 2.2).
- **Gợi ý 1 — Hướng đi:** Mỗi document là **recorder** của register, movements được ghi trong handler **Posting** qua collection **RegisterRecords** (mục Document posting). Tăng = **Receipt**, giảm = **Expense**.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Tab Posting của từng document → chọn `GoodsInWarehouses` làm register; mở **Record wizard** để sinh khung (chọn tabular section `Products` trước, bấm Fill Expressions, sửa cột Expression).
  - Object module, `Procedure Posting(Cancel, Mode)`; `RegisterRecords.GoodsInWarehouses.Write = True`; mỗi dòng Products → `Add()`, đặt `RecordType`, `Period = Date`, dimensions, resources.
  - InventoryTransfer: mỗi dòng sinh **hai** records (Expense ở `WarehouseSender`, Receipt ở `WarehouseRecipient`).
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure Posting(Cancel, Mode)
	// bật tự ghi record set: RegisterRecords.___.Write = ___
	For Each CurRow In Products Do
		// Record = RegisterRecords.GoodsInWarehouses.Add();
		// RecordType = ___ (Receipt / Expense tùy document)
		// Period, Product, Warehouse, Quantity, Amount = ___
	EndDo;
	// InventoryTransfer: trong vòng lặp thêm record thứ hai cho kho ___
EndProcedure
```
- **Lỗi hay gặp:**
  - Chọn sai Receipt/Expense (lỗi phổ biến nhất). [ghi chú ngoài nguồn] Code demo của bài Theory (nhánh lesson/11-theory) ghi `Receipt` cho Sales invoice — đây là lỗi của demo, bán hàng phải là `Expense`; đừng chép theo.
  - Duyệt cả tabular section Services → services lọt vào register kho.
  - Quên `Write = True` → record set không được ghi, register rỗng.
  - Chạy lại Record wizard sau khi sửa tay → Posting bị thay toàn bộ.
- **Tự kiểm tra:** Post một Purchase invoice, mở document → chuyển tới register records (hoặc mở list của register) thấy records Receipt; post Sales invoice thấy Expense; Inventory transfer có 2 records mỗi dòng với 2 kho khác nhau.

### Bài tập 3 — Viết lại "Fill in by the remaining goods" bằng dữ liệu register
- **Đề bài (tóm tắt):** InventoryTransfer lấy số dư từ register (không còn tính từ documents); thêm cột Amount vào tabular section Products (không đặt lên form) và điền bằng số dư amount.
- **Gợi ý 1 — Hướng đi:** Đọc virtual table **Balance** của register với tham số Period = ngày document và Condition lọc theo kho gửi (mục Lấy dữ liệu từ virtual tables — đặt điều kiện trong parameters, không ở WHERE).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Thêm attribute `Amount` vào tabular section `Products` của InventoryTransfer; không kéo lên form.
  - Sửa `FillInByTheRemainingGoodsAtServer` (`&AtServer`): query tới `AccumulationRegister.GoodsInWarehouses.Balance(&Date, <condition theo Warehouse>)`; các trường số dư có hậu tố `Balance` (`QuantityBalance`, `AmountBalance`) → đặt alias trùng tên cột tabular section.
  - Phần client (ShowQueryBox, callback) giữ nguyên.
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtServer
Procedure FillInByTheRemainingGoodsAtServer()
	// SELECT Product, ___Balance AS Quantity, ___Balance AS Amount
	// FROM AccumulationRegister.GoodsInWarehouses.Balance(&Date, Warehouse = ___)
	// SetParameter: Date = ___, Warehouse = ___ (kho gửi)
	// nạp vào Object.Products
EndProcedure
```
- **Lỗi hay gặp:**
  - Lọc kho ở WHERE thay vì trong tham số virtual table → đọc thừa dữ liệu.
  - Alias không trùng tên cột → `Load` không điền Quantity/Amount.
  - Period kiểu Date lấy dữ liệu **trước** giây chỉ định — document khác cùng giây không được tính.
- **Tự kiểm tra:** Sau khi post vài Purchase/Sales invoice vào một kho, bấm nút trên Inventory transfer có kho gửi đó → Quantity khớp với report/list của register; xem cột Amount trong debugger (vì không có trên form).

### Bài tập 4 — Document ReturnOfGoodsFromCustomer (Generation từ SalesInvoice)
- **Đề bài (tóm tắt):** Document trả hàng, thuộc Sales, có mọi attributes và tabular sections của Sales invoice, phải **liên kết** với sales document và tạo được dựa trên Sales invoice với mọi field/bảng được điền; tạo object form, list form, synonym.
- **Gợi ý 1 — Hướng đi:** Cơ chế **Generation** (mục Generation): tab Generation → Generated based on, thuật toán điền trong handler **Filling**; nên có attribute liên kết tới document nguồn.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Có thể copy document SalesInvoice rồi đổi tên/synonym (giữ đủ attributes và tabular sections).
  - Thêm attribute `SalesDocument` kiểu `DocumentRef.SalesInvoice`; trên form hiển thị dạng **Label Field** với property **hyperlink**, không cho sửa.
  - Tab Generation → Generated based on: `Document.SalesInvoice`; dùng **Generation settings wizard** để sinh `Filling(FillingData, StandardProcessing)` rồi bổ sung `SalesDocument`.
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure Filling(FillingData, StandardProcessing)
	If TypeOf(FillingData) = Type("___") Then
		// header: Customer, Contract, Warehouse, Discount ... = FillingData.___
		// SalesDocument = ___
		// For Each ... In FillingData.Products: thêm dòng, chép các cột
		// For Each ... In FillingData.Services: thêm dòng, chép các cột
	EndIf;
EndProcedure
```
- **Lỗi hay gặp:**
  - Quên attribute liên kết (đề in đậm "must be linked") → không truy ngược được sales document.
  - Thêm cột/attribute mới vào Sales invoice sau này nhưng không bổ sung vào Filling.
  - Chạy lại wizard → mất phần sửa tay (service comments `//{{__CREATE_BASED_ON_WIZARD`).
- **Tự kiểm tra:** Mở một Sales invoice → Generate → Return of goods from customer: header và hai bảng được điền, field SalesDocument là hyperlink mở đúng invoice gốc.

### Bài tập 5 — Form ReturnOfGoodsFromCustomer: tính amount, khóa Price/Amount, tổng document
- **Đề bài (tóm tắt):** Khi đổi Quantity → tính lại Amount của dòng (cả Products và Services); không cho sửa Price và Amount; tính lại tổng document như ở SalesInvoice.
- **Gợi ý 1 — Hướng đi:** Dùng lại đúng các handler đã viết cho SalesInvoice form (Bài 8–9): event **OnChange** của cột Quantity, event OnChange của bảng để tính tổng; khóa cột bằng property **ReadOnly** của form item.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form module của document; `ProductsQuantityOnChange` / `ServicesQuantityOnChange` (`&AtClient`) gọi procedure tính amount dòng (có thể `&AtClientAtServerNoContext` để dùng được cả trên server); `ProductsOnChange` / `ServicesOnChange` gọi procedure tính tổng (`&AtServer`); trong Form editor đặt ReadOnly cho các cột Price, Amount.
- **Gợi ý 3 — Khung bài làm:**
  1. Đặt ReadOnly = True cho `ProductsPrice`, `ProductsAmount`, `ServicesPrice`, `ServicesAmount`.
  2. Tạo handler OnChange cho cột Quantity của cả hai bảng → gọi procedure tính amount của dòng hiện tại (`Items.<Bảng>.CurrentData`), có tính Discount.
  3. Tạo handler OnChange của hai bảng → gọi procedure server tính tổng vào `DocumentTotal`.
- **Lỗi hay gặp:**
  - Chỉ làm cho Products, quên Services.
  - Gán ReadOnly trong metadata attribute thay vì trên form item (khi đó Filling vẫn chạy được, nhưng hãy kiểm tra lại hành vi bạn muốn).
- **Tự kiểm tra:** Trên document trả hàng, đổi Quantity → Amount và tổng cập nhật; không gõ được vào Price/Amount.

### Bài tập 6 — ReturnOfGoodsFromCustomer ghi vào GoodsInWarehouses
- **Đề bài (tóm tắt):** Document trả hàng làm tăng quantity và amount ở kho của document.
- **Gợi ý 1 — Hướng đi:** Giống Bài tập 2: document là recorder, Posting ghi movements; trả hàng làm **tăng** số dư.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Tab Posting → register `GoodsInWarehouses`; object module `Posting`; chỉ duyệt tabular section `Products` (không Services); kho = attribute `Warehouse`.
- **Gợi ý 3 — Khung bài làm:**
  1. Đánh dấu register trong tab Posting.
  2. Viết vòng lặp Products trong Posting, mỗi dòng một record tăng số dư.
  3. Bật Write cho record set.
- **Lỗi hay gặp:**
  - Chọn Expense thay vì Receipt.
  - [ghi chú ngoài nguồn] Cấu hình mẫu cuối khóa (sau khi có batch ở các bài sau) có nhánh ghi trả hàng bằng `Expense` với số âm — đó là cách riêng của bản cuối; ở Bài 11 cứ làm theo cách hiểu trực tiếp: trả hàng = Receipt dương.
- **Tự kiểm tra:** Post một return → số dư hàng ở kho tăng đúng số lượng trả.

### Bài tập 7 — Accumulation register Sales (bán − trả, theo customer và contract)
- **Đề bài (tóm tắt):** Register lưu quantity và amount bán hàng (cả goods và services) theo customer và contract; recorders: SalesInvoice và ReturnOfGoodsFromCustomer; bán ghi dương, trả ghi âm; tự xác định Register kind.
- **Gợi ý 1 — Hướng đi:** Chỉ cần **doanh số trong kỳ**, không cần số dư → **Register kind = Turnovers** (mục Register kind, Bảng của register kiểu Turnovers). Với kiểu này record không có RecordType → trả hàng ghi bằng số âm.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Register `Sales`: Dimensions `Product`, `Customer`, `Contract`; Resources `Quantity`, `Amount`.
  - Tab Posting của SalesInvoice và ReturnOfGoodsFromCustomer: thêm `Sales`.
  - Posting duyệt **cả** Products **và** Services (Record wizard chỉ chọn được một tabular section → phần Services phải tự viết). Có thể ghi hai register trong cùng một vòng Products (xem demo "Posting ghi hai register từ một vòng lặp" — nhớ sửa RecordType của GoodsInWarehouses thành Expense).
- **Gợi ý 3 — Khung bài làm:**
```bsl
	// RegisterRecords.Sales.Write = ___
	For Each CurRow In Products Do
		// ... record GoodsInWarehouses (Bài tập 2/6)
		// Record = RegisterRecords.Sales.Add(); Period, Product, Customer, Contract = ___
		// Quantity, Amount = ___ (dấu dương với sales invoice, ___ với return)
	EndDo;
	For Each CurRow In Services Do
		// chỉ ghi Sales, không ghi GoodsInWarehouses
	EndDo;
```
- **Lỗi hay gặp:**
  - Chọn kiểu Balances → vẫn chạy nhưng virtual table Turnovers luôn đọc movement table (chậm khi dữ liệu lớn).
  - Gán `RecordType` cho record của register Turnovers → lỗi.
  - Quên dấu âm ở return → doanh số cộng thay vì trừ.
  - Quên Services.
- **Tự kiểm tra:** Bán 10 sản phẩm cho một customer, trả 2 trong cùng tháng → query/report Sales.Turnovers theo tháng cho customer đó ra Quantity = 8.

### Bài tập 8 — RequiredSalesAmount và discount theo doanh số tháng trước
- **Đề bài (tóm tắt):** Thêm `RequiredSalesAmount` vào CounterpartyContracts; trong SalesInvoice: nếu không điền → luôn được discount; nếu có → chỉ được discount khi doanh số của customer tháng trước vượt RequiredSalesAmount, ngược lại discount = 0. Gợi ý của đề: AddMonth, BegOfMonth, EndOfMonth.
- **Gợi ý 1 — Hướng đi:** Đọc virtual table **Turnovers** của register Sales cho kỳ = tháng trước, Periodicity Month, Condition theo Customer; chỉ cần biết "có/không" có dòng vượt ngưỡng (mục Lấy dữ liệu từ virtual tables).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Attribute `RequiredSalesAmount` (Number) trong catalog `CounterpartyContracts`, đặt lên item form.
  - Sửa function/procedure tính discount đã có trong object module của SalesInvoice (export, được form gọi khi đổi Contract).
  - Query: `AccumulationRegister.Sales.Turnovers(&BeginOfPeriod, &EndOfPeriod, Month, <condition>)`; resource có hậu tố `Turnover` (`AmountTurnover`); kiểm tra kết quả bằng `QueryResult.IsEmpty()`.
  - Tháng trước: lùi một tháng từ `Date` bằng `AddMonth`, rồi lấy đầu/cuối tháng.
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure ___() Export
	// DiscountPercent = Contract.___ ; Required = Contract.___
	If ___ Then
		// query Turnovers tháng trước, Customer = &Customer, AmountTurnover >= &Required
		// PreviousMonth = AddMonth(___, ___)
		// rỗng -> Discount = ___ ; có dòng -> Discount = ___
	Else
		// Discount = ___
	EndIf;
EndProcedure
```
- **Lỗi hay gặp:**
  - Đặt Customer vào WHERE thay vì Condition của virtual table.
  - Lấy tháng hiện tại thay vì tháng trước.
  - Đề nói "exceeds"; [ghi chú ngoài nguồn] lời giải tham khảo của khóa dùng `>=` — quyết định và ghi rõ biên của bạn.
  - Tên tham số query gõ sai giữa Text và SetParameter → lỗi "parameter not set" (lỗi chính tả kiểu này có trong một bản lời giải của khóa).
- **Tự kiểm tra:** Contract có RequiredSalesAmount = 1000; tháng trước bán cho customer 1500 → Sales invoice tháng này nhận discount; đổi sang customer chỉ mua 500 → discount = 0; contract không điền RequiredSalesAmount → luôn có discount.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/11-theory)

> So với lesson/10-theory, nhánh lesson/11-theory thêm hai accumulation register (`GoodsInWarehouses` kiểu Balance, `Sales` kiểu Turnovers), Posting của SalesInvoice và PurchaseInvoice, document ReturnOfGoodsFromCustomer (Generation) và lệnh Copy and Post ở list form của SalesInvoice.

### Posting ghi hai register từ một vòng lặp (SalesInvoice)
Nguồn: nhánh lesson/11-theory — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, PostingMode)

	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Warehouse = Warehouse;
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount = CurRowProducts.Amount;

		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Customer = Customer;
		Record.Amount = CurRowProducts.Amount;
	EndDo;

	For Each CurRowServices In Services Do
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowServices.Service;
		Record.Customer = Customer;
		Record.Amount = CurRowServices.Amount;
	EndDo;
	
EndProcedure
```
- Bản Posting viết tay: `Write = True` cho cả hai record sets, duyệt Products **một lần** cho cả hai register (khắc phục điểm Record wizard duyệt lặp tabular section cho từng register) và thêm vòng Services chỉ cho `Sales`.
- Register `Sales` kiểu Turnovers → record không có `RecordType`; register `GoodsInWarehouses` kiểu Balance → phải chọn `RecordType`.
- [ghi chú ngoài nguồn] Demo ghi `AccumulationRecordType.Receipt` cho sales invoice; về nghiệp vụ, bán hàng giảm số dư kho nên phải là `Expense` (xem Thẻ gợi ý bài thực hành, Bài tập 2).

### Posting đã tối ưu + BeforeWrite/AdditionalProperties với IsNew() (PurchaseInvoice)
Nguồn: nhánh lesson/11-theory — cf/Documents/PurchaseInvoice/Ext/ObjectModule.bsl
```bsl
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	AdditionalProperties.Insert("IsNew", IsNew());
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If AdditionalProperties.IsNew Then
	
		// Some code execution	
	
	EndIf;
	
	GoodsInWarehouses = RegisterRecords.GoodsInWarehouses;
	GoodsInWarehouses.Write = True;
	
	For Each ProductsRow In Products Do
	
		NewRecord = GoodsInWarehouses.AddReceipt();
		NewRecord.Period 	= Date;
		NewRecord.Warehouse = Warehouse;
		NewRecord.Product 	= ProductsRow.Product;
		NewRecord.Quantity 	= ProductsRow.Quantity;
		NewRecord.Amount 	= ProductsRow.Amount;
	
	EndDo;
	
EndProcedure
```
- Đúng ví dụ lý thuyết: `IsNew()` không kiểm tra được trong Posting (object đã được ghi) nên được kiểm tra trong `BeforeWrite` và truyền sang qua `AdditionalProperties`.
- Bản tối ưu của code Record wizard: gán record set vào biến `GoodsInWarehouses`, dùng `AddReceipt()` thay cho `Add()` + `RecordType = AccumulationRecordType.Receipt`.
- `Write = True` → record set được tự ghi khi thoát Posting.

### Filling do Generation settings wizard tạo (ReturnOfGoodsFromCustomer dựa trên SalesInvoice)
Nguồn: nhánh lesson/11-theory — cf/Documents/ReturnOfGoodsFromCustomer/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, StandardProcessing)
	//{{__CREATE_BASED_ON_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.
	If TypeOf(FillingData) = Type("DocumentRef.SalesInvoice") Then
		// Filling the headline
		SalesDocument 	= FillingData;
		Company 		= FillingData.Company;
		Contract 		= FillingData.Contract;
		Customer 		= FillingData.Customer;
		Warehouse 		= FillingData.Warehouse;
		For Each CurRowProducts In FillingData.Products Do
			NewRow = Products.Add();
			NewRow.Amount = CurRowProducts.Amount;
			NewRow.Price = CurRowProducts.Price;
			NewRow.Product = CurRowProducts.Product;
			NewRow.Quantity = CurRowProducts.Quantity;
		EndDo;
		For Each CurRowServices In FillingData.Services Do
			NewRow = Services.Add();
			NewRow.Amount = CurRowServices.Amount;
			NewRow.Price = CurRowServices.Price;
			NewRow.Quantity = CurRowServices.Quantity;
			NewRow.Service = CurRowServices.Service;
		EndDo;
	EndIf;
	//}}__CREATE_BASED_ON_WIZARD
EndProcedure
```
- Bản nguyên gốc do wizard tạo, còn service comments `//{{__CREATE_BASED_ON_WIZARD` … `//}}__CREATE_BASED_ON_WIZARD`: chạy lại wizard thì đoạn này bị thay toàn bộ, mất sửa tay.
- Trong ReturnOfGoodsFromCustomer.xml, `BasedOn` = `Document.SalesInvoice`; `TypeOf(FillingData) = Type("DocumentRef.SalesInvoice")` kiểm tra kiểu object nguồn.
- Bản wizard chưa có `Products.Clear()` và chưa chép `Discount`, `DocumentTotal` — khi làm Practice cần tự bổ sung (xem Thẻ gợi ý bài thực hành, Bài tập 4).

### Lệnh "Copy and Post" ở list form (Copy() + Write + Refresh())
Nguồn: nhánh lesson/11-theory — cf/Documents/SalesInvoice/Forms/ListForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure CopyAndPostAtServer()
	
	DocumentRef = Items.List.CurrentRow;
	If ValueIsFilled(DocumentRef) Then
		NewDocument = DocumentRef.Copy();
		// NewDocument variable contains a value of type DocumentObject
		NewDocument.Write(DocumentWriteMode.Posting, DocumentPostingMode.RealTime);
		
		Items.List.Refresh();
	Else
		Message("No document selected for copying");
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyAndPost(Command)
	CopyAndPostAtServer();
EndProcedure
```
- Command `CopyAndPost` (nút `FormCopyAndPost` trên command bar của list form) có Action tạo theo kiểu "Create on client and a procedure on server": client handler chỉ gọi `CopyAndPostAtServer()`.
- `Items.List.CurrentRow` của dynamic list là reference document đang chọn; `Copy()` trả về DocumentObject mới, chưa ghi.
- Phải gọi `Write(DocumentWriteMode.Posting, DocumentPostingMode.RealTime)`, nếu không bản copy bị mất; sau đó `Items.List.Refresh()` để list hiện document mới.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Chứng từ và biểu ghi tích lũy](https://www.youtube.com/watch?v=dQt7_Ln8zVI&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=6) (4:50) — Bài 3 — Document; Bài 11 — Accumulation register, posting _(mã nội bộ JC-7)_
- [Kết chuyển chứng từ](https://www.youtube.com/watch?v=fsu3Wqn9wz8&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=21) (8:01) — Bài 11 — Document posting, event Posting, RegisterRecords, posting mode _(mã nội bộ JC-22)_
- [Biểu ghi tích lũy](https://www.youtube.com/watch?v=wbF-aWunEdc&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=22) (13:46) — Bài 11 — Accumulation register Balances/Turnovers, dimensions, resources, virtual tables _(mã nội bộ JC-23)_
- [Truy vấn SQL và cấu trúc truy vấn](https://www.youtube.com/watch?v=E3EJ6WRG8Sk&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=40) (4:32) — Bài 10 — cấu trúc query; Bài 11 — virtual tables _(mã nội bộ JC-41)_
- [FROM và WHERE](https://www.youtube.com/watch?v=PtCdTq0a1nM&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=42) (5:58) — Bài 10 — FROM, WHERE; Bài 11 — lọc trong tham số virtual table _(mã nội bộ JC-43)_
