# Bài 14 — Common modules, Application/Session modules, Commands & Command interface

## Khái niệm chính

### Common modules
- **Common modules** chứa procedures và functions có thể gọi từ bất kỳ module nào khác của configuration; các procedures/functions đó phải có từ khóa **Export** trong tiêu đề.
- Có thể tạo procedures/functions thường (không Export) — chỉ gọi được trong chính module đó; thường mang mục đích phục vụ (service) cho các export methods.
- Properties của common module chỉ xem được trong **Properties palette** (common module không có object editor).
- Theo execution context, có 4 loại:
  - **client**: chỉ gọi từ client, chỉ chạy trên client.
  - **server**: chỉ gọi từ server, chỉ chạy trên server.
  - **client-server**: gọi được từ cả client và server; chạy trong cùng context nơi gọi.
  - **server call** (server with the ability to call the server): gọi được từ client và server, nhưng chỉ chạy trên server.
- Flag **"External connection"**: module có khả dụng trong session không khởi động interactive (kết nối database từ bên ngoài, ví dụ truy cập HTTP service hoặc Web-service khởi động session ở external connection). Nên bật cho server và client-server modules.
- Property **Global**: export methods của module thuộc global context → gọi trực tiếp như built-in methods, không cần tên module.
  - Global = False → global context có property cùng tên với common module (read-only), giá trị là object **CommonModule**; gọi dạng `XXXXX.YYYYY` (tên module.tên export method). Object common module có thể gán vào biến rồi gọi qua biến.
- Quy tắc cho client-server và server call modules:
  - Client-server module phải làm mọi việc trong một context duy nhất — không chấp nhận khi gọi từ client mà thực thi chuyển sang server từ module này hoặc module khác.
  - **Incorrect 1**: Form module -> Client-server module -> Module with the "Call server" flag
  - **Incorrect 2**: Form module -> Client-server module -> Client module -> Module with the "Call server" flag
  - **Correct**: Form module -> Client module -> Module with the "Call server" flag
- Khi gọi module "Server call" từ client: không phải object nào cũng truyền được giữa client và server (tra syntax assistant). Thường không truyền được: objects không tồn tại trên client hoặc server như **CatalogObject**, **DocumentObject**, collections **ValueTable**, **ValueTree**; form data collections (**FormDataStructure**, **FormDataCollection**, **FormDataTree**, **FormDataStructureAndCollection** — sửa trên server sau khi truyền từ client sẽ lỗi khi quay về client); một số objects không tồn tại trong thin client context. Ví dụ: **FileDialog** không tồn tại ở server; **ValueTable** không tồn tại ở client.
- Mỗi client-server module khi biên dịch tạo thành 2 bản: client và server; có thể khác nhau nhờ **preprocessor directives** — đặt code trong điều kiện để code chỉ vào bản có context hỗ trợ (ví dụ ghi event log không thực hiện được trong thin client).
- **Note**: preprocessor directives có thể tổng quát hoặc chi tiết: `#If Server` bao gồm kiểm tra `#If MobileAppServer Or MobileStandaloneServer`; `#If Client` bao gồm mọi client (thick client, web client, mobile client...).
- Danh sách đầy đủ preprocessor directives cho điều kiện: Client, Server, ThinClient, WebClient, MobileStandaloneServer, MobileAppClient, MobileAppServer, MobileClient, ThickClientOrdinaryApplication, ThickClientManagedApplication, ExternalConnection.
- Property **Privileged**: tắt kiểm soát quyền truy cập khi thực thi methods của module — mọi code chạy với full rights, không áp access restrictions.
  - **Note**: bật Privileged → property **Server** tự bật, các properties còn lại (**Client (ordinary application)**, **Client (managed application)**, **External connection**) bị reset. Privileged module chỉ chạy được trên server.

### Reuse return values
- Chỉ khả dụng nếu common module không phải Global. Property **"Reuse return values"**:
  - **Do not use**: không tái sử dụng.
  - **During call** / **During session**: sau lần gọi đầu, hệ thống nhớ tham số và kết quả; gọi lại với cùng tham số → trả giá trị đã lưu mà không thực thi function. Nếu function thay đổi giá trị tham số khi chạy, lần gọi lại sẽ không làm việc đó.
- Nơi lưu:
  - Function chạy trên server, gọi từ code server → nhớ cho session hiện tại ở server.
  - Function chạy trên thick/thin client → nhớ ở client.
  - Function chạy trên server, gọi từ client → nhớ ở cả client và server (session hiện tại).
- Xóa giá trị đã lưu:
  - **During call**: server — khi trả quyền điều khiển từ server; client — khi procedure/function built-in language cấp cao nhất kết thúc (do hệ thống gọi từ giao diện, không phải từ procedure khác).
  - **During session**: server — cuối session (hoặc sau thời gian nhất định); client — khi đóng client application (hoặc sau thời gian nhất định).
  - Theo thời gian: trên server, thick client, external connection, thin client và web client với tốc độ kết nối bình thường — **20 phút** sau khi tính giá trị hoặc **6 phút** sau lần dùng cuối (ví dụ gọi mỗi 5,5 phút: ba lần trả giá trị cũ, lần thứ tư thực thi lại vì đã 22 phút). Thin client và web client với kết nối chậm — **20 phút** sau khi tính.
  - Theo infobase settings: thiếu RAM trong working process của server; restart working process; client chuyển sang working process khác.
  - Sau khi xóa, lần gọi kế tiếp được thực thi như lần đầu.
- **Note**: không ảnh hưởng procedures — procedures luôn được thực thi.
- Kiểu tham số của export function khi bật reuse chỉ được là: primitive types (Undefined, NULL, Boolean, Number, String, Date); references tới database objects; Structures có property thuộc các kiểu trên (so sánh "theo nội dung").
- Nếu function trả về object → thực ra trả reference tới object trong cache; thay đổi trạng thái object sau đó thì lần gọi sau trả reference tới object đã bị thay đổi mà không thực thi function — cho tới khi giá trị bị xóa.
- Cache không quan tâm trạng thái privileged mode lúc gọi: lần gọi thật đầu tiên ở privileged mode có thể trả object không lấy được khi tắt privileged mode; các lần gọi sau không privileged vẫn nhận object "không được phép" cho tới khi cache bị xóa. Ngược lại cũng đúng.
- "During session": giá trị trả về không được chứa **TemporaryTableManager**, **Query** và application objects (ví dụ **DataProcessorObject**, **DocumentObject**), trực tiếp hay trong collection. Ngoại lệ: reference types (DocumentRef, CatalogRef...).
- Gọi function của module có reuse từ chính module đó: gọi bằng tên ngắn (`MyFunction()`) → luôn thực thi; muốn dùng giá trị lưu phải gọi bằng tên đầy đủ (`Pricing.MyFunction()`).
- **RefreshReusableValues()** (global context): xóa mọi giá trị lưu ở cả server và client, bất kể gọi ở đâu; có thể chạy lâu → chỉ dùng khi thực sự cần.

### Purpose and use
- Khuyến nghị đặt vào common modules code liên quan tới subsystem thay vì object cụ thể. Ví dụ: kiểm tra cột "Amount" (sản phẩm Promotional được giá 0) dùng cho cả Sales invoice và Return of goods from customer → đưa vào export procedure của common module Sales (server module) và gọi từ object module của các document.

### Application module
- Tự động thực thi khi configuration được nạp lúc 1C:Enterprise khởi động ở các chế độ: thin client, web client, thick client ở managed application mode (thick client regular application chỉ dùng trong configuration cũ, mặc định tắt trong infobase mới).
- Dùng xử lý hành động liên quan session của user (chủ yếu bắt đầu/kết thúc session). **Không khả dụng cho procedures chạy trên server.** Khuyến nghị chỉ viết handlers cho các event tương ứng.
- Unhandled exception trong bất kỳ event handler nào của managed application module (**BeforeStart()**, **OnStart()**, **BeforeExit()**, **OnExit()**) → toàn bộ hệ thống crash. Bắt exception trong khối Except thì không crash.
- Procedures, functions, variables có Export trong application module khả dụng trong: non-global client common modules; client procedures/functions của command module; client procedures/functions của form module.
- Trong context của application module khả dụng: phần global context chạy được ở client; export methods của mọi client common modules; export methods của server non-global common modules có property "Server call".

### External connection module
- Nằm ở root của configuration (như application module). Chứa event handlers khởi tạo khi hệ thống bắt đầu và kết thúc ở external connection mode (ví dụ HTTP-service).
- Có thể khai báo variables, procedures, functions khả dụng cho ứng dụng bên ngoài.
- Objects truy cập được từ bên ngoài qua external connection: export methods của external connection module; export methods của common modules (bao gồm/loại trừ module hoàn toàn bằng properties của common modules; bao gồm/loại trừ đoạn code bằng preprocessor instructions); global context của 1C:Enterprise script language.
- Module chỉ có trong external connection session; chế độ này hoàn toàn không có user interface.

### Session module
- Tự động thực thi khi 1C:Enterprise khởi động và configuration được nạp.
- Dùng khởi tạo **session parameters** và hành động liên quan session. Luôn chạy ở **privileged mode** của 1C:Enterprise server. Đặt session parameters trong handler **SessionParametersSetting()**.
- Chỉ chứa định nghĩa procedures/functions, có thể dùng procedures của common modules, **không chứa export** procedures/functions.
- SessionParametersSetting() được gọi **trước** BeforeStart() (hoặc OnStart() với external connection module).
- Xác định loại session (background job hay khác): **GetCurrentInfoBaseSession()** trả về object InformationBase Session; gọi **GetBackgroundJob()** trên object đó để biết có phải background task session. [ghi chú ngoài nguồn] Tài liệu gốc ghi cả "GetBackgroundTask()" và "GetBackgroundJob()" cho cùng phương thức. → xem mục Code demo của bài Theory (nhánh lesson/14-theory): code demo dùng `GetBackgroundJob()`.

### Commands
- **Command**: configuration object để mô tả hành động user thực hiện.
- Loại command:
  - **Standard**: platform tự sinh dựa trên configuration (ví dụ command mở list form của catalog Products trong subsystem "Master data"; nút "Create" trên list form). Platform cũng tạo command tạo object mới trong subsystems chứa object, nhưng mặc định tắt — developer có thể bật.
  - **Object commands**: catalog, register... có commands riêng (ví dụ tạo object mới theo quy tắc điền nhất định, mở form object trung gian).
  - **Common commands**: không gắn với object cụ thể hoặc thao tác với objects không dùng standard commands (ví dụ đổi password user hiện tại, gửi email, mở exchange settings).
- Phân loại ảnh hưởng vị trí trong command interface:
  - Theo dữ liệu: **independent** và **parameterizable**.
  - Theo mục đích: **navigation** và **action**.
- **Independent commands**: không cần dữ liệu bổ sung; kết quả như nhau bất kể gọi từ đâu (mở form list/form tạo document mới, chạy quy trình như tính giá vốn).
- **Parameterizable commands**: cần **command parameter** quyết định kết quả (mở list subordinate catalog — tham số là reference tới owner; tạo document dựa trên object; xử lý với reference tới object, ví dụ tải tỷ giá một loại tiền). Ví dụ standard: commands chuyển tới register records của document.
- Ví dụ tự tạo parameterizable command: object command của document Sales invoice gọi từ catalog Products:
  - **Group**: command panel of the form. General
  - **Command parameter type**: CatalogRef.Products
  - **Parameter usage mode**: Multiple
  - Trong command module, handler được tạo mặc định. Mode **Single** → tham số là một reference; mode **Multiple** → tham số là mảng references. Truyền mảng vào property **Products** của structure **FillingValues**, mở form document với parameter structure chứa FillingValues.
  - Trong handler **Filling**: kiểm tra kiểu FillingData; nếu là structure và có property Products → gọi procedure điền tabular sections Products và Services (quantity = 1). Tabular sections không thể tự điền bởi event này.
  - Kết quả: nút trong submenu **Generate** của item form và list form của Products; chọn nhiều item (product và service) → điền cả hai tabular sections.
- **Navigation commands**: điều hướng user trong chức năng ứng dụng; thường mở list form mới trong cửa sổ nơi gọi, thay form đang hiển thị trong work area. Có thể là independent hoặc parameterizable global commands (đi tới catalog list form — independent; đi tới list form của subordinate catalog — parameterizable).
  - Mỗi reference object có parameterizable navigation command **"Show in list"**: mở list form với dòng của object được highlight. Nếu document thuộc document journal, "Show in list" là submenu (list form document + journal).
- **Action command** (parameterizable): khi nhập chuỗi vào field kiểu reference rồi bấm "Create" → mở form tạo object mới, field gắn với attribute default presentation chứa chuỗi đã nhập (trừ documents — không có property "Default presentation").
  - **Note**: cần property **"Create on input"** = **"Use"** cho object (hoặc attributes tham chiếu tới object đó).
- **Command groups**: gom commands để dễ đặt vào command interface. Chọn một trong 4 categories (**Navigation panel**, **form navigation panel**, **action panel**, **form command bar**), rồi với các command đặt property **Group** = command group. Ví dụ group "Sales Calculations" (Navigation Panel, subsystem Sales) với common commands "Calculate cost" và "Calculate financial result".
  - Trên current section functions panel, commands không được gộp thành submenu; trên sections panel, commands được gộp thành subgroup như subordinate subsystem.

### Command interface
- Root configuration object có các mục command interface (chuột phải hoặc properties palette).
- **Configuration command interface**: lưu thứ tự sections và visibility của sections (kể cả theo user roles). Đổi thứ tự bằng mũi tên lên/xuống; reset bằng cách chọn root **Sections** trong cửa sổ "Command interface" và bấm **"Restore automatic order"**.
- **Main section command interface**: lưu thiết lập main section — service subsystem **Quick menu**, đứng trước mọi subsystems ở Enterprise mode; thường chứa objects dùng nhiều nhất.
  - Nút **"Open main section command interface"**: trái — objects có thể đặt vào main section; phải — vị trí trên các panel. Thêm/bớt bằng **"add command"** / **"remove command"** (mũi tên phải/trái). Mặc định vào nhóm **Navigation panel.Normal**; kéo thả sang **Navigation panel.Important** → command hiển thị in đậm.
- **"All subsystems" editor**: quản lý subsystems và command interfaces; mở từ context menu của root configuration node hoặc của node Subsystems (nhánh Common). Là phiên bản mở rộng của cửa sổ command interface một subsystem: thêm/sửa/xóa subsystems, đổi thứ tự trong configuration tree (không phải trong interface), nội dung, bật/tắt visibility objects cho mọi roles hoặc từng role.

## Cú pháp & ví dụ code

Export procedures/functions:
```bsl
Procedure RecalculateTotalOfDocument(Document) Export
    
Function DiscountPercentage(Product, Date) Export
```

Gọi methods của common module:
```bsl
// Calling a Global module method
FillPricesInTabularSection(TabularSection, Date);

// Calling a non-global module method
Pricing.FillPricesInTabularSection(TabularSection, Date);

// Writing a common module object to a variable 
// and calling a method of this common module via that variable
MyVariable = CommonModuleWithAVeryLongName;
MyVariable.ProcedureOfTheCommonModule();
```

Preprocessor directives (dạng điều kiện được nêu trong tài liệu):
```bsl
#If Server
#If MobileAppServer Or MobileStandaloneServer
#If Client
```

Gọi function có reuse từ chính module:
```bsl
MyFunction()          // executed on each call
Pricing.MyFunction()  // stored values are used
```

Xóa mọi giá trị lưu:
```bsl
RefreshReusableValues()
```

[ghi chú ngoài nguồn] Các ví dụ khác (bảng flag của 4 loại module, procedure ghi event log với preprocessor directive và hai bản client/server, common module Sales và lời gọi từ document, application module crash/không crash, command handler với FillingValues, Filling điền Products/Services) chỉ có dạng ảnh chụp màn hình, không có văn bản code nên không được chép lại. → bảng flag, common module Sales và lời gọi từ document, command handler với FillingValues, Filling điền Products/Services → xem mục Code demo của bài Theory (nhánh lesson/14-theory). Riêng procedure ghi event log với preprocessor directive và ví dụ application module crash/không crash không có trong nhánh lesson/14-theory (managed application module của nhánh là file rỗng) nên vẫn chưa có code.

## Thuộc tính/thiết lập quan trọng trong Designer
- Common module (Properties palette): **Client (ordinary application)**, **Client (managed application)**, **Server**, **Server call**, **External connection**, **Global**, **Privileged**, **Reuse return values** (**Do not use** / **During call** / **During session**).
- Session module: handler **SessionParametersSetting()**.
- Application module handlers: **BeforeStart()**, **OnStart()**, **BeforeExit()**, **OnExit()**.
- Command: **Group**, **Command parameter type**, **Parameter usage mode** (**Single** / **Multiple**).
- Command group: category **Navigation panel** / **form navigation panel** / **action panel** / **form command bar**.
- Object / attribute: **Create on input** = **Use**; **Default presentation**.
- Root configuration: **Configuration command interface** (**Restore automatic order**), **Main section command interface** (**Navigation panel.Normal**, **Navigation panel.Important**), **All subsystems** editor.

## Lỗi thường gặp / lưu ý
- Client-server module gọi tiếp sang module "Server call" (trực tiếp hoặc qua client module) → sai; phải đi Form module -> Client module -> Server call module.
- Truyền CatalogObject, DocumentObject, ValueTable, ValueTree, form data collections giữa client và server → lỗi (FileDialog không có ở server, ValueTable không có ở client; trả form data structure đã sửa từ server về client → lỗi).
- Code không khả dụng trong một context (ví dụ ghi event log trong thin client) → bọc bằng preprocessor directive.
- Privileged module chỉ chạy trên server; bật Privileged sẽ reset các flags khác.
- Reuse return values: không áp dụng cho procedures; tham số chỉ primitive/reference/Structure; object trả về là reference trong cache (thay đổi sẽ bị "nhớ"); cache bỏ qua privileged mode; "During session" không trả TemporaryTableManager, Query, application objects.
- Gọi function reuse bằng tên ngắn trong cùng module → không dùng cache.
- RefreshReusableValues() có thể chạy lâu — chỉ dùng khi thật cần.
- Unhandled exception trong BeforeStart/OnStart/BeforeExit/OnExit của application module → crash toàn hệ thống.
- Application module không khả dụng cho code server.
- Session module không chứa export methods.
- Muốn tạo object mới khi nhập reference → phải đặt "Create on input" = "Use".

## Điểm cần nhớ
- Common module: chỉ methods có Export mới gọi được từ ngoài; 4 loại context: client, server, client-server, server call.
- Global = gọi trực tiếp; non-global = `ModuleName.Method()`.
- Client-server module phải chạy trong một context; dùng preprocessor directives để tách code client/server.
- Privileged = full rights, chỉ server.
- Reuse return values (non-global): During call / During session; 20 phút / 6 phút; chỉ áp cho functions; RefreshReusableValues() để xóa.
- Application module: session phía client, handlers BeforeStart/OnStart/BeforeExit/OnExit — luôn bắt exception.
- Session module: SessionParametersSetting() chạy ở privileged mode, trước BeforeStart/OnStart; không có export.
- Commands: standard / object / common; independent vs parameterizable; navigation vs action; Command parameter type + Parameter usage mode (Single → reference, Multiple → mảng).

## Thẻ gợi ý bài thực hành (Practice 14)

> Thẻ gợi ý dẫn hướng cho từng yêu cầu của 14. Practice.docx; không có lời giải hoàn chỉnh. Với mỗi common module, đề nhắc phải đặt đúng flags trong Properties palette.

### Bài tập 1 — Server common module ProductsInDocuments: kiểm tra số dư dùng chung
- **Đề bài (tóm tắt):** Tạo server common module ProductsInDocuments (thêm hậu tố nếu cần) và chuyển phần kiểm tra số dư hàng của InventoryTransfer và SalesInvoice vào đó.
- **Gợi ý 1 — Hướng đi:** Code giống nhau ở nhiều document → đưa vào **export procedure** của **server** common module (mục Common modules, Purpose and use); document chỉ còn lời gọi `ModuleName.Method(...)` vì module không Global.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Common module `ProductsInDocuments`: flags **Server** = true, **External connection** = true (khuyến nghị cho server module), Client = false, **Server call** = false, Global = false.
  - Procedure export nhận đủ dữ liệu qua tham số vì không còn truy cập trực tiếp attributes của document: danh sách products (mảng), kho, thời điểm (PointInTime của document), `Cancel`.
  - Giữ đoạn đọc constant "Control balances of goods" (Bài 13) bên trong procedure chung.
  - Trong `Posting` của hai documents: thay lời gọi procedure cục bộ bằng lời gọi module; InventoryTransfer truyền `WarehouseSender`.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// Common module ProductsInDocuments (Server)
Procedure ___(Products, Warehouse, Date, Cancel) Export
	// kiểm tra constant -> nếu tắt thì ___
	// query số dư âm như Bài 12, nhưng dùng tham số thay cho attributes của document
	// Period = New Boundary(___, ___)
EndProcedure

// Object module của document, trong Posting, sau Write():
// ProductsInDocuments.___(___, ___, PointInTime(), Cancel);
```
- **Lỗi hay gặp:**
  - Bật Server call → module gọi được từ client, không cần thiết và lộ code server ra client.
  - Bật Global rồi vẫn gọi `ProductsInDocuments.Method` (hoặc ngược lại).
  - Quên `Export` → document không gọi được.
  - Trong module vẫn viết `PointInTime()` / `Products` như trong object module → lỗi, vì common module không có context của document.
- **Tự kiểm tra:** Xóa procedure kiểm tra cũ trong hai object modules, post sales invoice và inventory transfer vượt số dư → vẫn bị chặn với đúng thông báo; đặt breakpoint trong common module để thấy cả hai document đi qua cùng một chỗ.

### Bài tập 2 — Server call common module: function lấy giá
- **Đề bài (tóm tắt):** Tạo server call common module ProductsInDocuments (có hậu tố) chứa function trả giá của product tại ngày bất kỳ (tham số Product, Date); dùng nó trong form modules khi gọi từ client.
- **Gợi ý 1 — Hướng đi:** Client cần dữ liệu server mà không có form context → module có flag **Server call** (mục Common modules — loại server call); tham số chỉ là reference và Date (truyền được giữa client và server).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Common module `ProductsInDocumentsServerCall`: Server = true, **Server call** = true.
  - Export function `(Product, Date)`: đọc giá từ register ProductPrices (SliceLast, như Bài 12). Có thể đặt logic đọc giá trong manager module của register và để function server call chỉ gọi tiếp.
  - Trong form SalesInvoice: procedure client "khi đổi product" gọi `ProductsInDocumentsServerCall.<Function>(...)`, bỏ function `&AtServerNoContext` cục bộ cũ.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// Common module ProductsInDocumentsServerCall (Server, Server call)
Function ___(Product, Date) Export
	// trả về giá mới nhất của Product tại Date: ___
EndFunction

// Form module (&AtClient):
// CurrentData.Price = ___.___(CurrentData.Product, Object.Date);
```
- **Lỗi hay gặp:**
  - Tạo module server thường (không Server call) rồi gọi từ client → lỗi "procedure not found"/không khả dụng.
  - Truyền form data (`CurrentData`, `Object`) sang server call → nên truyền giá trị đơn (Product, Date).
- **Tự kiểm tra:** Chọn product trên sales invoice → giá được điền như trước khi refactor; trong debugger bước vào thấy code chạy ở server.

### Bài tập 3 — Client-server common module: tính amount của dòng, discount tùy chọn
- **Đề bài (tóm tắt):** Module client-server ProductsInDocuments (có hậu tố) chứa procedure tính lại amount của dòng tabular section; discount là tham số **tùy chọn**; thay mọi procedure cục bộ tính amount ở các form.
- **Gợi ý 1 — Hướng đi:** Một procedure dùng được cả trong `&AtClient` (OnChange) và `&AtServer` (tính tổng) → **client-server** module (mục Common modules); tham số tùy chọn khai báo bằng giá trị mặc định trong tiêu đề.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Common module `ProductsInDocumentsClientServer`: **Client (managed application)** = true, **Server** = true, External connection = true, Server call = false.
  - Export procedure `(Row, Discount = 0)`: tính Amount từ Quantity, Price, Discount.
  - Thay lời gọi ở form SalesInvoice, ReturnOfGoodsFromCustomer (và PurchaseInvoice nếu có tính amount — gọi không truyền discount); xóa procedure cục bộ `&AtClientAtServerNoContext`.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// Common module ProductsInDocumentsClientServer (Client + Server)
Procedure ___(ProductsRow, Discount = ___) Export
	// ProductsRow.Amount = ___
EndProcedure
```
- **Lỗi hay gặp:**
  - Gọi sang module Server call từ bên trong client-server module → sai quy tắc "một context" (Incorrect 1 của lý thuyết).
  - Không đặt giá trị mặc định → mọi lời gọi phải truyền discount (trái đề).
  - Quên sửa một form → vẫn còn procedure cục bộ trùng logic.
- **Tự kiểm tra:** Đổi Quantity ở sales invoice, return, purchase invoice → Amount đúng; Find in modules không còn procedure tính amount cục bộ.

### Bài tập 4 — Parameterizable command "Set price"
- **Đề bài (tóm tắt):** Command mở form PriceSetup với các product được chọn đã chèn sẵn vào tabular section; gọi được cho một hoặc nhiều products; có trên command bar của item form và list form Products; tự chọn object command hay common command.
- **Gợi ý 1 — Hướng đi:** Command cần dữ liệu (products được chọn) → **parameterizable command**; vì kết quả là tạo document PriceSetup → **object command** của PriceSetup với **Command parameter type** = CatalogRef.Products (mục Commands — đúng ví dụ tạo Sales invoice từ Products của lý thuyết). Dữ liệu chuyển sang document qua **FillingValues** và event **Filling**.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Document PriceSetup → tab Commands → command `SetPrice`: Group = command bar của form (ví dụ Important), Command parameter type = `CatalogRef.Products`, **Parameter usage mode = Multiple** (→ tham số là mảng).
  - Command module, handler `CommandProcessing(CommandParameter, CommandExecuteParameters)` (`&AtClient`): tạo structure FillingValues có property Products, mở `"Document.PriceSetup.ObjectForm"` với parameter `FillingValues`.
  - Object module PriceSetup, `Filling(FillingData, FillingText, StandardProcessing)`: nếu FillingData là Structure và có property Products → thêm dòng vào tabular section cho từng product (Filling không tự điền tabular section).
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	// FillingValues = New Structure("___", CommandParameter)
	// mở form object của PriceSetup với New Structure("FillingValues", ___)
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	// If TypeOf(FillingData) = Type("___") And FillingData.Property("___") Then
	//   For Each ... thêm dòng, Product = ___
EndProcedure
```
- **Lỗi hay gặp:**
  - Parameter usage mode = Single → chọn nhiều products chỉ nhận một (hoặc lệnh không khả dụng).
  - Dùng common command không có parameter type → không xuất hiện trên form Products.
  - Không kiểm tra `TypeOf(FillingData)` → lỗi khi PriceSetup được tạo bình thường hoặc dựa trên object khác.
  - Chọn Group trong submenu Generate trong khi đề yêu cầu trên command bar.
- **Tự kiểm tra:** Trên list form Products chọn 3 dòng → bấm Set price → form PriceSetup mở với 3 dòng, chỉ cần nhập Price và lưu; thử từ item form của một product.

### Bài tập 5 — Main section command interface
- **Đề bài (tóm tắt):** Main section hiển thị commands mở list purchase documents, journal Sales documents, catalogs Products, Counterparties, CounterpartyContracts, Warehouses; Products và journal Sales documents ở panel Important.
- **Gợi ý 1 — Hướng đi:** Thiết lập trong **Main section command interface** của root configuration (mục Command interface) — không cần code.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Chuột phải root configuration → Open main section command interface; bên trái chọn command OpenList của từng object, "add command"; kéo Products và journal SalesDocuments sang **Navigation panel.Important**, các command còn lại ở **Navigation panel.Normal**.
- **Gợi ý 3 — Khung bài làm:**
  1. Mở editor main section command interface.
  2. Thêm 6 commands.
  3. Kéo 2 commands vào Important, sắp xếp thứ tự.
- **Lỗi hay gặp:**
  - Thêm vào command interface của subsystem thay vì main section.
  - Object chưa có quyền/không thuộc subsystem nào nên không hiện trong danh sách bên trái — kiểm tra lại.
- **Tự kiểm tra:** Ở Enterprise mode, section đầu tiên (main) có 6 lệnh, 2 lệnh in đậm.

### Bài tập 6 — Lệnh tạo mới trong command interface của subsystems
- **Đề bài (tóm tắt):** Thêm command tạo Products vào subsystem Master data; command tạo Counterparty và CounterpartyContract vào subsystem Sales.
- **Gợi ý 1 — Hướng đi:** Platform đã sinh **standard command** "Create" cho object trong subsystem nhưng mặc định tắt (mục Commands — Standard) → bật trong command interface của subsystem.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Subsystem Master data → Command interface → nhóm action panel (Create) → bật Visible cho `Catalog.Products.StandardCommand.Create`; tương tự ở Sales cho Counterparties và CounterpartyContracts (object phải thuộc subsystem đó).
- **Gợi ý 3 — Khung bài làm:**
  1. Mở command interface của Master data, bật command Create của Products.
  2. Kiểm tra Counterparties, CounterpartyContracts đã thuộc subsystem Sales; bật command Create.
- **Lỗi hay gặp:**
  - Object không thuộc subsystem → command không có trong danh sách của subsystem đó.
- **Tự kiểm tra:** Ở section Master data có nút "Product" trong action panel (Create); ở Sales có "Counterparty" và "Counterparty contract".

### Bài tập 7 — Enumeration WriteOffMethods và constant WriteOffOrder
- **Đề bài (tóm tắt):** Enumeration "Write-Off methods" (FIFO, LIFO, Manually); constant WriteOffOrder kiểu EnumRef.WriteOffMethods; thêm field sửa constant vào constants form đã tạo (Bài 13).
- **Gợi ý 1 — Hướng đi:** Tập giá trị cố định → Enumeration; giá trị thiết lập chung → Constant; constants form có main attribute ConstantsSet nên chỉ cần kéo constant mới lên.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Enumeration `WriteOffMethods`; constant `WriteOffOrder`; mở common form "Goods turnover settings" → kéo `ConstantsSet.WriteOffOrder` lên form.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo enumeration với 3 values, đặt synonym dễ hiểu.
  2. Tạo constant, chọn kiểu.
  3. Thêm field vào constants form.
- **Lỗi hay gặp:**
  - Tạo form riêng mới thay vì thêm vào form có sẵn (đề yêu cầu form đã tạo trước đó).
- **Tự kiểm tra:** Mở form settings, chọn FIFO, lưu, mở lại vẫn là FIFO.

### Bài tập 8 — Dimension Batch trong GoodsInWarehouses
- **Đề bài (tóm tắt):** Register GoodsInWarehouses lưu movements và số dư không chỉ theo Product, Warehouse mà cả theo Batch (batch là document PurchaseInvoice); các thay đổi khác làm ở bài sau.
- **Gợi ý 1 — Hướng đi:** Thêm phân tích mới cho số dư → thêm **dimension** (mục Accumulation register của Bài 11).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Register `GoodsInWarehouses` → dimension `Batch` kiểu `DocumentRef.PurchaseInvoice`. Ở Posting của PurchaseInvoice, batch tự nhiên chính là reference của document đang post — có thể bắt đầu gán ngay từ bài này.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm dimension Batch.
  2. Cập nhật database configuration.
  3. (Tùy chọn) PurchaseInvoice: thêm phép gán Batch cho record trong Posting.
- **Lỗi hay gặp:**
  - Chọn kiểu Batch là composite hoặc catalog → không khớp đề ("batch document is the PurchaseInvoice").
  - Sau khi thêm dimension, số dư của các document cũ có Batch rỗng — cần re-post nếu muốn dữ liệu nhất quán.
- **Tự kiểm tra:** Re-post một Purchase invoice, mở records của register → cột Batch có giá trị là chính invoice đó.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/14-theory)

So với nhánh lesson/13-theory, nhánh lesson/14-theory thêm: các common modules `Sales`, `CommonClientServer`, `CommonServerCall`, `CommonServerPrivileged`, session module, managed application module (file rỗng), object command `CreateFromProducts` của SalesInvoice, command group `SalesCalculations` với hai common commands.

Flags của các common modules demo (đọc từ file .xml của từng module trong nhánh) — tương ứng bảng 4 loại module của lý thuyết:

| Common module | Loại | Client (managed application) | Server | External connection | Server call | Privileged | Global | Reuse return values |
|---|---|---|---|---|---|---|---|---|
| Sales | server | false | true | true | false | false | false | DontUse |
| CommonServer | server | false | true | false | false | false | false | DontUse |
| CommonClientServer | client-server | true | true | true | false | false | false | DontUse |
| CommonServerCall | server call | false | true | false | true | false | false | DontUse |
| CommonServerPrivileged | privileged | false | true | false | false | true | false | DontUse |

- `CommonServerPrivileged`: Privileged = true kéo theo Server = true, các flag client và External connection bị reset — đúng **Note** của lý thuyết.
- Trong nhánh, các module `CommonClientServer`, `CommonServerCall`, `CommonServerPrivileged` chỉ được tạo để minh họa flags (module rỗng, chưa có code).

### Common module Sales: kiểm tra Amount dùng chung cho hai document
Nguồn: nhánh lesson/14-theory — cf/CommonModules/Sales/Ext/Module.bsl
```bsl
Procedure CheckAmountOfProducts(Products, Cancel) Export
	
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
```
- Đúng ví dụ "Purpose and use": query kiểm tra cột Amount (bỏ qua sản phẩm `Promotional`) được chuyển nguyên từ FillCheckProcessing của Sales invoice (Bài 12) sang export procedure của server common module `Sales`.
- `Export` trong tiêu đề → gọi được từ object module của các document; `Cancel` truyền vào và được đổi bên trong procedure.

### Gọi Sales.CheckAmountOfProducts từ FillCheckProcessing
Nguồn: nhánh lesson/14-theory — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If Products.Count() > 0 Then
		DeleteAttributeFromChecking(CheckedAttributes, "Services");
	ElsIf Services.Count() > 0 Then	
		DeleteAttributeFromChecking(CheckedAttributes, "Products");
	EndIf;

	// Turn off checking by the platform
	DeleteAttributeFromChecking(CheckedAttributes, "Products.Amount");
	
	Sales.CheckAmountOfProducts(Products, Cancel);
	
EndProcedure
```
- Module có Global = false → gọi dạng `Sales.CheckAmountOfProducts(...)` (tên module.tên method).
- `ReturnOfGoodsFromCustomer/Ext/ObjectModule.bsl` trong cùng nhánh có FillCheckProcessing giống hệt, cùng gọi `Sales.CheckAmountOfProducts(Products, Cancel);` — một chỗ sửa cho cả hai document.

### Session module: phân biệt session của background job
Nguồn: nhánh lesson/14-theory — cf/Ext/SessionModule.bsl
```bsl
Procedure SessionParametersSetting(RequiredParameters)
	
	CurrentSession = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentSession.GetBackgroundJob();
	If BackgroundJob <> Undefined Then
		// This session is started in a background job
	Else
		// This session is started not in a backgroung job
	EndIf;
	
EndProcedure
```
- Handler `SessionParametersSetting()` chạy ở privileged mode, trước `BeforeStart()`; module không có export.
- `GetCurrentInfoBaseSession()` trả về object session; `GetBackgroundJob()` trả `Undefined` nếu session không phải background job — xác nhận tên method đúng là `GetBackgroundJob()` (không phải "GetBackgroundTask()").

### Object command CreateFromProducts: tạo Sales invoice từ danh sách Products
Nguồn: nhánh lesson/14-theory — cf/Documents/SalesInvoice/Commands/CreateFromProducts/Ext/CommandModule.bsl
```bsl
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FillingValues = New Structure("Products", CommandParameter);
	
	FormParameters = New Structure("FillingValues", FillingValues);
	OpenForm(
		"Document.SalesInvoice.ObjectForm",
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL
	);

EndProcedure
```
- Thiết lập trong `SalesInvoice.xml`: Group = `FormCommandBarCreateBasedOn`, Command parameter type = `CatalogRef.Products`, Parameter usage mode = `Multiple` → `CommandParameter` là mảng references; nút hiện trong submenu tạo dựa trên (Generate) của form Products.
- Mảng được đặt vào property `Products` của structure `FillingValues`, rồi truyền qua parameter `FillingValues` của `OpenForm`.

### Filling điền cả Products và Services bằng batch query
Nguồn: nhánh lesson/14-theory — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	Company 	= Constants.DefaultCompany.Get();
	BankAccount = Constants.DefaultBankAccount.Get();
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Products") Then
			
			FillProductAndServices(FillingData.Products);
			
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure FillProductAndServices(ProductsAndServices)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Products.Ref AS Product,
	|	1 AS Quantity
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ProductsAndServices)
	|	AND Products.Type = &Product
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.Ref AS Service,
	|	1 AS Quantity
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ProductsAndServices)
	|	AND Products.Type = &Service";
	
	Query.SetParameter("ProductsAndServices", 	ProductsAndServices);
	Query.SetParameter("Product", 				Enums.ProductTypes.Product);
	Query.SetParameter("Service", 				Enums.ProductTypes.Service);
	
	Results = Query.ExecuteBatch();
	Products.Load(Results[0].Unload());
	Services.Load(Results[1].Unload());
	
EndProcedure
```
- Đúng ví dụ lý thuyết: kiểm tra `TypeOf(FillingData) = Type("Structure")` và `Property("Products")`, rồi tự điền tabular sections (event Filling không tự điền tabular section).
- Batch query tách mảng references theo `Products.Type`: kết quả 0 → Products, kết quả 1 → Services, mỗi dòng `Quantity` = 1; nạp bằng `Load(Results[i].Unload())`.
- Hai dòng đầu vẫn điền Company/BankAccount từ constants (Bài 13).

### Command group SalesCalculations (Navigation panel)
Nguồn: nhánh lesson/14-theory — cf/CommandGroups/SalesCalculations.xml và cf/CommonCommands/CalculateCost.xml
```xml
			<Category>NavigationPanel</Category>
```
```xml
			<Group>CommandGroup.SalesCalculations</Group>
```
- Command group category `NavigationPanel`; common commands `CalculateCost` và `CalculateFinancialResult` đặt property Group = `CommandGroup.SalesCalculations` — đúng ví dụ "Sales Calculations" của lý thuyết.
- Command module của hai common commands chỉ là template mặc định (handler `CommandProcessing` với nội dung bị comment) — demo tập trung vào vị trí trong command interface.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Homepage, form và command](https://www.youtube.com/watch?v=DDk5kS4BRow&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=8) (5:11) — Bài 9 — Home page, form; Bài 14 — Commands, Command interface _(mã nội bộ JC-9)_
- [Làm việc với bối cảnh toàn cục (Global Context)](https://www.youtube.com/watch?v=cqwM140spEs&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=25) (5:16) — Bài 5-6 — Syntax assistant nhánh Global context, `Message()`; Bài 14 — common module Global _(mã nội bộ JC-26)_
- [Giao diện lệnh (command) trên biểu mẫu (form)](https://www.youtube.com/watch?v=4sYHynvvbls&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=34) (6:29) — Bài 9 — form commands, command bar; Bài 14 — commands. Ngoài giáo trình: gán phím tắt cho command không có trong giáo trình _(mã nội bộ JC-35)_
