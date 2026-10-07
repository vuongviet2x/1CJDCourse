# Bài 15 — Functional options, Object/non-object entities, Referential integrity

## Khái niệm chính

### Functional options (FO)
- **Functional options** là metadata class cho phép người dùng tự bật/tắt một phần chức năng của chương trình. Giúp developer làm **một** applied solution duy nhất thay vì nhiều giải pháp cho từng trường hợp sử dụng (ví dụ: DB này dùng nhiều currency, DB kia không).
- **Functional option parameters**: metadata class dùng để chia chức năng **theo vùng dữ liệu** (ví dụ theo Company) thay vì theo toàn bộ database.
- FO có tác động tới:
  - **User interface** — khi tắt FO, hệ thống ẩn mọi phần tử liên quan:
    - global command interface;
    - form details (kể cả các cột của form details kiểu Value Table hoặc Value Tree);
    - form commands;
    - reports được làm bằng data composition system.
  - **Thuật toán viết bằng built-in language** — có thể lấy giá trị FO từ code để dùng trong điều kiện (ví dụ giảm khối lượng tính toán).
- FO và parameters **không ảnh hưởng nội dung database**: mọi bảng và field đều tồn tại trong DB bất kể trạng thái FO.
- **Global command interface**: hệ thống ẩn commands của mọi object thuộc FO bị tắt. Ví dụ `UseProduction` = False → ẩn command mở section Production, tạo document ProductRelease, mở list ProductRelease...
  - FO `UseProduction` có thể tính theo giá trị functional option parameter (ví dụ Company): bật cho company này, tắt cho company khác. Đổi giá trị parameter bằng built-in language → đổi trạng thái FO → đổi visibility.
  - Một command bị loại khỏi command interface nếu **attribute là command parameter** bị FO tắt.
  - Một parameterizable command bị loại nếu **command parameter type** bị FO tắt. Nếu parameter type là composite → command chỉ unavailable khi **tất cả** các type đều bị tắt.
- **Nơi lưu giá trị FO** (property **Data path**) có thể là:
  - constants,
  - catalog attributes,
  - resources of information registers.
  - Không giới hạn kiểu giá trị, nhưng **chỉ FO lưu giá trị kiểu Boolean** mới dùng được để quản lý interface. FO kiểu khác chỉ dùng được khi đọc trong built-in language.
- **Gán object vào FO** — 2 cách:
  1. Từ object, tab **"Functional options"** (chỉ hiện các FO lưu giá trị kiểu Boolean).
  2. Từ tab **Content** của FO — chi tiết hơn: chọn được không chỉ catalogs, documents..., mà cả attributes, tabular sections, attributes of tabular sections.
- **Quy tắc visibility (toán tử "OR")**: object không được gán FO nào → luôn visible. Nếu có gán → visible khi **ít nhất một** FO được gán đang bật. Quy tắc giống hệt cho form attributes / form commands.
- Constant mới có default value **False** → FO bị tắt ngay sau khi update.
- Trong "functions for technician", objects luôn hiện bất kể FO; list form khi đó cho thấy object thuộc chức năng bị tắt và không dùng được.
- **Commands của global command interface và form đang mở KHÔNG tự cập nhật** khi giá trị FO thay đổi → dùng global context method **`RefreshInterface()`**.
  - `RefreshInterface()` tốn nhiều tài nguyên → dùng có chủ đích, không gọi mỗi lần FO đổi.
  - Pattern của standard solutions: một form chứa nhiều FO nhóm theo khối chức năng (Purchases, Sales, Production...). Nếu user đổi ít nhất 1 FO → ghi vào một biến cờ rằng sau khi lưu cần refresh interface.
  - Ví dụ trong bài: common form DefaultValues đổi tên thành **ApplicationSettings**, thêm form attribute kiểu Boolean làm cờ "cần update interface"; khi đổi constant liên quan FO → set cờ = True; handler **AfterWrite** của form kiểm tra cờ và gọi `RefreshInterface()` (method này là **client-side**, dù dẫn tới server call).
- **Hệ quả khi set FO parameters (và khi chạy `RefreshInterface()`)**:
  - với mỗi form, gọi đóng tất cả auxiliary forms (kèm các handler tương ứng);
  - form từ chối đóng thì không bị đóng;
  - thành phần elements của main form được cập nhật;
  - nếu main form đang active → hiển thị theo thành phần mới;
  - nếu auxiliary form đang active: command mở auxiliary form được chạy lại nếu còn available sau refresh; nếu không → cập nhật và hiển thị main form;
  - nếu active form là auxiliary form mở bằng command không thuộc form navigation panel → thay bằng main form đã cập nhật.
- **Form attributes và form commands** có property **"Functional options"** (chọn 1 hoặc nhiều FO) — cùng quy tắc OR như configuration objects.
- FO không chỉ để đổi command interface: còn là công cụ tiện để **lấy một giá trị mà không phải xét user rights**, và **cache** giá trị để tối ưu việc đọc thường xuyên từ code.

### Privileged mode & caching
- Property **"Use privileged mode for getting data"**:
  - **Bật**: giá trị FO lấy trong privileged mode; kết quả được cache cho **tất cả sessions** của infobase.
  - **Tắt**: lấy ở normal mode; cache cho **session hiện tại**. Cache cả giá trị (nếu lấy được) lẫn dấu hiệu không lấy được giá trị.
  - Cache bị reset khi giá trị **session parameters** thay đổi.

### Functional option parameters
- Dùng khi giá trị FO cần lấy kèm "làm rõ", ví dụ: company 1 có hạch toán theo contracts không → tạo FO `UseContracts` (hoặc `AccountingByContracts`) + functional option parameter `Company`.
- Kiểu giá trị property **Use** của parameter:
  - FO lưu trong **catalog attribute** → `CatalogRef.Companies`.
  - FO lưu trong **information register resource** → một **dimension** của chính register đó có kiểu `CatalogRef.Company`.
- Một parameter dùng được cho nhiều FO. Danh sách trong **Use** gồm catalog references và information register dimensions; với mỗi parameter chọn được **một catalog** và **một dimension của mỗi information register**.
- **Không được** dùng cùng một metadata object trong nhiều functional option parameters.
- Ví dụ trong bài:
  - FO `CompanyPrefix` — lưu trong attribute của catalog Companies; **không gán objects** vì không phải separator, chỉ để lấy prefix của company (đánh số document riêng theo company, ví dụ AB0001, CH0001).
  - FO `UseContracts` — lưu trong resource của information register `CompanyAccountingSettings` (có thể thêm resource khác như dùng tax accounting). Content: catalog `CounterpartyContracts` và attribute `Contract` của các documents.
  - Parameter `Company`: chọn reference tới catalog Companies (cho `CompanyPrefix`) và dimension kiểu `CatalogRef.Companies` của register `CompanyAccountingSettings`.
  - Record form của register cũng cần làm cơ chế gọi `RefreshInterface()` như common form của constants.
- **Global interface với parameterized FO**: nếu flag True ở **ít nhất một** register record → FO = True → catalog `CounterpartyContracts` hiện trong global interface.
- **Trong form**: platform **không tự xác định** dùng parameter nào để tính FO chứa attribute `Contract` → tính như global interface (True nếu có 1 record True). Phải dùng global method dành cho form: **`SetParametersFormFunctionalOptions(<ParametersStructure>)`** — structure gồm tên parameter và giá trị (ở đây: `Company` = Company của document).
  - Gọi từ form event **OnCreateAtServer** và từ handler **OnChange** của form field Company (vì company khác có thể có giá trị FO khác).
- **Đọc giá trị FO từ code**: function **`GetFunctionalOption`**, có tham số tuỳ chọn `Parameters` kiểu **Structure** (key = tên functional option parameter, value = giá trị làm rõ).

### Object và non-object entities
- **Object entities**: mọi object có reference — catalogs, documents, charts of characteristic types, charts of accounts, charts of calculation types, exchange plans, business processes, tasks.
  - Mỗi object là duy nhất (kể cả khi điền giống hệt object khác) nhờ **unique identifier** không đổi suốt vòng đời object, dù mọi attribute/tabular section thay đổi.
  - Ví dụ: 2 item "Scissors" giống hệt trong Products → 2 reference khác nhau, hạch toán riêng. Đổi tên thành Small Scissors / Large Scissors → nhờ referential integrity, presentation đổi ở mọi nơi dùng.
  - Ví dụ chuẩn hơn: catalog **Individuals** — một người có thể đổi chức vụ, tình trạng hôn nhân, họ, thậm chí giới tính nhưng vẫn là cùng một người → phải là object entity.
- **Non-object entities**: **tất cả registers**. Record là phản ánh của một thông tin (số odometer ngày bảo dưỡng, đã bán bao nhiêu hàng với số tiền nào...). Đổi key fields → đổi ý nghĩa record (đổi John thành Michael trong lịch sử chức vụ → dữ liệu hoàn toàn khác).
  - Ví dụ: information register **Employee Positions** (Period – Individual – Position).
- Chọn object để lưu thông tin dựa trên **loại entity** mà object phản ánh; chú ý cách đặt tên object (catalog `Individuals` vs information register `Employee Positions`).

### Referential integrity
- Khi presentation của object đổi → mọi reference tới nó đổi presentation ở mọi nơi dùng.
- Dimension có flag **Master**: register records phụ thuộc object được tham chiếu; xoá object thì records tự động bị xoá.
- **2 cách xoá object entities**:
  1. **Direct deletion** — không an toàn: reference vẫn còn trong DB nhưng trỏ tới object không tồn tại → có thể gây lỗi trong thuật toán, và hiển thị không thân thiện (chỉ là identifier). Mặc định không có trong context menu, chỉ có trong submenu **"More actions"** của item/object form hoặc list form.
  2. **Mark for deletion** rồi xoá với kiểm soát referential integrity — cách được khuyến nghị: user có thể đổi ý (bỏ deletion mark); khi xoá qua service processing **"Delete marked objects"**, hệ thống phân tích reference còn lại tới object, nếu có thì **cấm xoá** cho tới khi các reference đó được xử lý (thay/xoá giá trị attribute, hoặc xoá object chứa reference).
- **"Delete marked objects"** nằm trong section **"Standard"** của menu **"functions for technician"**, có 2 lựa chọn:
  - **"Full deletion"** — xoá tất cả object đã đánh dấu.
  - **"Selective deletion"** — chỉ xoá object user chọn (**khuyến nghị**, tránh xoá nhầm object user định bỏ đánh dấu nhưng chưa làm).
  - Có lệnh "set all" / "clear all", và bật/tắt flag theo metadata object trong cây.
  - Khi object còn bị tham chiếu → thông báo và xem được danh sách object tham chiếu (ví dụ bank bị đánh dấu xoá nhưng còn bank account có owner là bank đó).
- **Access rights** (trong objects kiểu Role): **Delete** — cho phép direct deletion; **"Interactive mark for deletion"** — cho phép đánh dấu xoá trong interactive mode (từ form).

## Cú pháp & ví dụ code

```bsl
FunctionalOptionParameters = New Structure("Company", CompanyValue);

Prefix = GetFunctionalOption("CompanyPrefix", FunctionalOptionParameters);
```

Các method được nêu trong tài liệu (chỉ có chữ ký, không có đoạn code đầy đủ dạng văn bản):

```bsl
RefreshInterface()
SetParametersFormFunctionalOptions(<ParametersStructure>)
GetFunctionalOption
```

[ghi chú ngoài nguồn] Các đoạn code khác trong bài (handler AfterWrite gọi RefreshInterface, procedure gọi SetParametersFormFunctionalOptions) chỉ có ở dạng ảnh chụp màn hình, không có văn bản trong tài liệu nên không chép lại. → xem mục Code demo của bài Theory (nhánh lesson/15-theory): handler AfterWrite gọi `RefreshInterface()` ở record form của `CompanyAccountingSettings`, và ví dụ đặt FO parameters ở form Sales invoice (tên method thật là `SetFormFunctionalOptionParameters`). Phần áp dụng cho common form cài đặt → xem Thẻ gợi ý bài thực hành.

## Thuộc tính/thiết lập quan trọng trong Designer
- Functional option: **Data path** (constant / catalog attribute / information register resource).
- Functional option: **Use privileged mode for getting data**.
- Functional option: tab **Content**.
- Configuration object: tab **Functional options**.
- Form attribute / form command: property **Functional options**.
- Functional option parameter: property **Use** (catalog reference / information register dimension).
- Information register dimension: flag **Master**.
- Catalog: property **Check uniqueness** (uniqueness control — ví dụ không được có 2 object cùng code).
- Attribute: property **Required field** = "Display error".
- Role access rights: **Delete**, **Interactive mark for deletion**.

## Lỗi thường gặp / lưu ý
- Client làm việc với **file version** của infobase **qua web server**: đổi FO chỉ đổi interface sau khi **restart web server** (restart client application không có tác dụng).
- Sau khi bật FO, subsystem vẫn chưa hiện trong global command interface → do interface và form đang mở không tự refresh; cần `RefreshInterface()` (hoặc restart infobase — bất tiện).
- Không gọi `RefreshInterface()` mỗi lần FO thay đổi vì tốn tài nguyên.
- Field `Contract` vẫn hiện trên form dù FO tắt cho company đó → vì platform không biết dùng parameter nào; phải gọi `SetParametersFormFunctionalOptions`.
- **Required field = "Display error"**: nếu attribute bị tắt bởi FO **thường** → không kiểm tra; nếu bị tắt bởi FO **có parameter** → **vẫn kiểm tra** dù field bị ẩn khỏi form → phải tự loại attribute khỏi danh sách checked attributes trong event handler của object (hoặc form).
- Không dùng cùng một metadata object trong nhiều functional option parameters.
- Direct deletion để lại "broken reference" (reference trỏ tới object không tồn tại).
- Uniqueness control bật → attribute xác định uniqueness không được trùng giá trị.

## Điểm cần nhớ
- FO ẩn/hiện UI (global command interface, form details, form commands, DCS reports) nhưng **không đổi cấu trúc database**.
- Chỉ FO lưu giá trị **Boolean** mới điều khiển được interface; nơi lưu: constant, catalog attribute, information register resource.
- Visibility theo quy tắc **OR**: không gán FO → luôn hiện; có gán → hiện nếu ít nhất 1 FO bật.
- Đổi FO xong phải gọi **`RefreshInterface()`** (client-side, tốn tài nguyên) để cập nhật interface và form đang mở.
- FO có parameter: dùng **`SetParametersFormFunctionalOptions`** trong form (OnCreateAtServer + OnChange của field làm parameter), và **`GetFunctionalOption(Name, Structure)`** trong code.
- Bật **Use privileged mode for getting data** khi giá trị FO không nhạy cảm (cache cho mọi session).
- Object entities có reference/unique identifier; registers là non-object entities — đổi key field là đổi ý nghĩa record.
- Xoá an toàn = **mark for deletion** + **"Delete marked objects"** (ưu tiên **Selective deletion**); direct deletion không an toàn.

## Thẻ gợi ý bài thực hành (Practice 15)

Các thẻ dưới đây đi theo thứ tự đề trong 15. Practice. Mỗi thẻ chỉ có gợi ý, không có lời giải: bạn tự viết code rồi kiểm tra lại trong Enterprise mode.

### Bài tập 1 — Functional option UseCharacteristics và form cài đặt

- **Đề bài (tóm tắt):** Tạo FO `UseCharacteristics` để bật/tắt toàn bộ chức năng characteristics; làm một form riêng để user sửa giá trị FO; khi lưu form phải cập nhật global command interface và các form đang mở.
- **Gợi ý 1 — Hướng đi:** FO kiểu Boolean điều khiển visibility của các object liên quan đến characteristics (mục "Functional options (FO)"). Interface và form đang mở **không tự refresh** khi FO đổi, nên phải gọi `RefreshInterface()`, nhưng chỉ gọi một lần sau khi ghi, vì method này tốn tài nguyên.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Constant Boolean `UseCharacteristics` làm **Data path** của FO.
  - Tab **Content** của FO: chart of characteristic types, information register và catalog phục vụ characteristics (các object bạn đã tạo ở bài trước).
  - Common form (bài lý thuyết đổi `DefaultValues` thành `ApplicationSettings`) có attribute kiểu ConstantsSet và một form attribute Boolean làm cờ "cần refresh".
  - Handler client `OnChange` của field constant (chỉ bật cờ) và form event `AfterWrite` (`&AtClient`).
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo constant, rồi tạo FO, đặt Data path và Content.
  2. Đưa constant lên common form cài đặt, thêm attribute cờ, tốt nhất đặt tên khác tên method (ví dụ `InterfaceRefreshRequired`).
  3. Gán handler OnChange cho field và AfterWrite cho form qua Properties palette.
  4. Đưa form vào command interface của subsystem phù hợp.
  ```bsl
  &AtClient
  Procedure ___OnChange(Item)
  	// chỉ đánh dấu cờ "cần refresh", KHÔNG refresh ở đây
  	___
  EndProcedure

  &AtClient
  Procedure AfterWrite(WriteParameters)
  	// nếu cờ bật -> gọi method refresh interface (client-side)
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Gọi `RefreshInterface()` ngay trong OnChange: giá trị chưa được ghi, lại tốn tài nguyên.
  - Constant mới có giá trị mặc định False, nên sau khi update configuration các object trong Content bị ẩn ngay. Đây là hành vi đúng, không phải lỗi.
  - Đặt tên attribute trùng tên method `RefreshInterface`: vẫn chạy được nhưng khó đọc.
  - Nếu chạy file infobase qua web server, interface chỉ đổi sau khi restart web server.
- **Tự kiểm tra:** Trong Enterprise mode, tắt FO rồi Save: các command của characteristics biến khỏi sections mà không cần khởi động lại. Bật lại thì chúng xuất hiện. Đặt breakpoint ở AfterWrite để thấy cờ chỉ True khi field thật sự bị đổi.

### Bài tập 2 — FO có parameter ControlBalanceOfGoods theo từng company

- **Đề bài (tóm tắt):** Thay constant kiểm soát tồn kho bằng FO có parameter `Company` (lưu trong information register `CompanyAccountingSettings`). Document có Company thì kiểm tra theo company, document không có Company thì giữ logic cũ (đọc constant).
- **Gợi ý 1 — Hướng đi:** Mục "Functional option parameters": FO lưu trong **resource** của information register, còn parameter trỏ tới **dimension** Company của register đó. Đọc giá trị từ code bằng `GetFunctionalOption(Name, Structure)`, trong đó key của structure là tên parameter. Procedure kiểm tra tồn kho dùng chung (nằm trong server common module) nhận thêm tham số tuỳ chọn `Company = Undefined`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Information register `CompanyAccountingSettings`: nonperiodical, dimension `Company` (CatalogRef.Companies), resource Boolean `ControlBalanceOfGoods`.
  - FO `ControlBalanceOfGoods`: Data path là resource trên, Content để trống (chỉ đọc từ code), nên bật **Use privileged mode for getting data**.
  - Functional option parameter `Company`: trong **Use** chọn dimension `Company` của register.
  - Procedure Export trong common module (Server), gọi từ handler `Posting` của các document đang kiểm tra tồn kho.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo register, FO và parameter như trên.
  2. Thêm tham số tuỳ chọn Company vào procedure kiểm tra chung.
  3. Đầu procedure: chọn nguồn giá trị (FO có parameter hay constant), nếu không cần kiểm tra thì `Return`.
  4. Document có attribute Company truyền thêm Company; document không có thì không truyền.
  ```bsl
  Procedure ___(Products, Warehouse, Date, Cancel, Company = Undefined) Export
  	If ___ Then  // Company có được truyền vào không?
  		// đọc FO có parameter: tên FO + Structure("Company", ...)
  		___
  	Else
  		// giữ cách cũ: đọc constant
  		___
  	EndIf;
  	// nếu không cần kiểm tra -> thoát; ngược lại query Balance và báo dòng âm
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Truyền structure sai key: key phải đúng **tên functional option parameter** (`Company`), không phải tên dimension hay tên attribute.
  - Quên truyền Company từ document có Company, khi đó FO không được tính theo company.
  - [ghi chú ngoài nguồn] Trong cấu hình mẫu của khóa, tên FO/constant bị gõ thiếu chữ "r" (`ContolBalanceOfGoods`). Khi tự làm, đặt đúng `ControlBalanceOfGoods` như đề bài và dùng thống nhất một tên.
  - Kiểm tra tồn kho phải lấy balance tại thời điểm **bao gồm** chính document (dùng `New Boundary(..., BoundaryType.Including)` hoặc `PointInTime()`), sau khi đã ghi movements.
- **Tự kiểm tra:** Tạo 2 record trong `CompanyAccountingSettings`: company A bật, company B tắt. Post Sales invoice bán vượt tồn: với A thì bị chặn kèm thông báo, với B thì post được. Inventory transfer vẫn theo constant như cũ.

### Bài tập 3 — Prefix số document theo company (CompanyPrefix + OnSetNewNumber)

- **Đề bài (tóm tắt):** Thêm attribute `Prefix` cho catalog Companies, tạo FO có parameter `CompanyPrefix` lưu giá trị trong attribute này, rồi tự động gắn prefix vào số của mọi document có Company qua `OnSetNewNumber`, gọi chung một server common module `DocumentNumbering`.
- **Gợi ý 1 — Hướng đi:** FO không kiểu Boolean không điều khiển interface, nhưng vẫn đọc được bằng `GetFunctionalOption` (mục "Functional option parameters", ví dụ `CompanyPrefix`). Event `OnSetNewNumber` của object module có tham số `Prefix`: gán giá trị cho nó thì platform dùng làm phần đầu của số tự động.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Catalog Companies: attribute `Prefix` (String, ngắn).
  - FO `CompanyPrefix`: Data path = attribute `Prefix`, Content trống.
  - Parameter `Company`: **Use** phải có thêm **reference của catalog Companies** (ngoài dimension của register ở bài 2).
  - Common module `DocumentNumbering` (Server): một export procedure nhận `StandardProcessing`, `Prefix`, `Company`.
  - Object module của **từng** document có Company: handler `OnSetNewNumber(StandardProcessing, Prefix)`.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo attribute, FO và bổ sung Use của parameter.
  2. Viết procedure chung trong `DocumentNumbering`: gán `Prefix` bằng giá trị FO tính theo company truyền vào.
  3. Thêm handler `OnSetNewNumber` vào mọi document có Company, mỗi handler chỉ một dòng gọi module chung.
  ```bsl
  // CommonModule DocumentNumbering (Server)
  Procedure ___(StandardProcessing, Prefix, Company) Export
  	// Prefix = giá trị FO "CompanyPrefix" với parameter Company
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Use của parameter `Company` thiếu catalog Companies, khi đó FO `CompanyPrefix` không tính được theo company.
  - Prefix chỉ áp dụng khi **số mới được cấp**; document đã có số giữ nguyên số cũ.
  - [ghi chú ngoài nguồn] Cấu hình mẫu của khóa chỉ có handler này ở Sales invoice, trong khi đề bài yêu cầu **mọi** document có Company. Hãy thêm cho đủ.
  - Quên chọn Company trước khi ghi (Company trống) thì prefix rỗng.
- **Tự kiểm tra:** Đặt Prefix "AB" cho company 1 và "CH" cho company 2. Tạo mới document cho từng company, Save: số bắt đầu bằng AB… hoặc CH…. Đặt breakpoint trong `OnSetNewNumber` để xem giá trị `Prefix`.

### Bài tập 4 — Thử xoá object với và không có referential integrity control

- **Đề bài (tóm tắt):** Tạo 3 company, dùng 2 company trong vài document. Xoá trực tiếp một company và quan sát các field tham chiếu; đánh dấu xoá 2 company còn lại rồi chạy "Delete marked objects", đọc thông báo lỗi và danh sách object còn tham chiếu.
- **Gợi ý 1 — Hướng đi:** Mục "Referential integrity": direct deletion để lại broken reference; mark for deletion + "Delete marked objects" kiểm tra reference trước khi xoá.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Lệnh **More actions → Delete** trên list/item form (direct deletion); lệnh đánh dấu xoá; service processing **"Delete marked objects"** trong section **Standard** của "functions for technician"; nên dùng **Selective deletion**. User cần quyền **Delete** / **Interactive mark for deletion** trong role.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo company X, Y, Z; dùng X và Y trong 1–2 document mỗi company.
  2. Xoá trực tiếp X, mở lại document có X và xem field Company hiển thị gì.
  3. Đánh dấu xoá Y và Z, chạy "Delete marked objects" (Selective), chọn cả hai.
  4. Đọc kết quả: Z bị xoá, Y bị giữ lại; mở danh sách object đang tham chiếu tới Y.
  (Bài này thao tác trong Enterprise mode, không cần viết code.)
- **Lỗi hay gặp:**
  - Không thấy lệnh Delete trong context menu: lệnh chỉ có trong **More actions**.
  - Dùng "Full deletion" làm xoá luôn object khác đang đánh dấu nhầm.
  - Quên rằng record của register có dimension **Master** trỏ tới object sẽ bị xoá theo.
- **Tự kiểm tra:** Field tham chiếu X hiển thị dạng identifier (object không tồn tại); Y vẫn còn với deletion mark kèm báo cáo "có reference"; Z biến khỏi danh sách.

### Bài tập 5 — Purchase invoice ghi chính nó vào dimension Batch

- **Đề bài (tóm tắt):** Sửa movements của Purchase invoice để dimension mới `Batch` của register GoodsInWarehouses nhận reference tới chính document đang post.
- **Gợi ý 1 — Hướng đi:** Mỗi phiếu nhập là một batch. Trong object module, `Ref` là reference của document đang post.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Dimension `Batch` của accumulation register GoodsInWarehouses có kiểu `DocumentRef.PurchaseInvoice`; handler `Posting` trong object module của Purchase invoice; chỉ cần thêm một phép gán vào vòng lặp tạo record đã có.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm dimension Batch vào register (nếu chưa có).
  2. Trong vòng lặp tạo record Receipt của Purchase invoice, gán thêm field Batch.
  3. Re-post các Purchase invoice cũ để movements có Batch.
- **Lỗi hay gặp:**
  - Code được sinh bằng register records wizard có cảnh báo trong marker: chạy lại wizard sẽ **ghi đè** phần bạn sửa tay.
  - Quên re-post document cũ, nên balance theo batch trống.
- **Tự kiểm tra:** Post một Purchase invoice, mở **Register records** (Go to → GoodsInWarehouses) và thấy cột Batch chứa chính document đó.

### Bài tập 6 — Cột Batch trong Sales invoice và lệnh "Pick batch"

- **Đề bài (tóm tắt):** Thêm cột `Batch` vào tabular section Products của Sales invoice, chỉ hiện khi Write-off order = Manually. Cột là bắt buộc nhưng phải bỏ khỏi danh sách kiểm tra khi không ở Manually. Thêm lệnh "Pick batch": kiểm tra dòng hiện tại, Product và Warehouse; mở form `PickBatch` (của Purchase invoice) liệt kê các batch còn tồn và số lượng; batch được chọn ghi vào dòng hiện tại qua callback `PickBatchAfterSelection`.
- **Gợi ý 1 — Hướng đi:**
  - Ẩn/hiện cột: đọc constant WriteOffOrder trong form event phía server.
  - Bỏ kiểm tra bắt buộc: cùng kỹ thuật lý thuyết nêu cho attribute bị ẩn bởi FO có parameter, tức là xoá path khỏi `CheckedAttributes` trong `FillCheckProcessing`.
  - Form chọn: dynamic list với custom query trên virtual table **Balance** của GoodsInWarehouses, tham số đặt qua `Parameters.SetParameterValue` (gợi ý trong đề).
  - Mở form non-modal kèm owner và `CallbackDescription`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Column `Batch` (kiểu giống dimension Batch), Required field = "Display error".
  - Form Sales invoice: `OnCreateAtServer` (`&AtServer`) đặt `Visible` cho cột và nút; command `PickBatch` với handler `&AtClient`; callback Export `PickBatchAfterSelection(Result, AdditionalParameters)`.
  - Object module: `FillCheckProcessing(Cancel, CheckedAttributes)`, path cần xoá là `"Products.Batch"`.
  - Purchase invoice: form generic `PickBatch`, các form parameters Date, Product, Warehouse, đọc trong `OnCreateAtServer`.
  - `OpenForm`: owner là **form field** Batch của table, callback qua tham số CallbackDescriptionOnClose (theo đề bài).
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm column, đặt Required field, đưa lên form; thêm command và nút vào command bar của table Products.
  2. `OnCreateAtServer`: tính một biến Boolean "đang Manually", gán cho Visible của cột và nút.
  3. `FillCheckProcessing`: nếu không Manually thì tìm index của path, khác Undefined thì xoá.
  4. Tạo form `PickBatch`: attribute DynamicList với custom query trên Balance (lọc theo &Product, &Warehouse, ngày &Date); `OnCreateAtServer` đặt 3 tham số từ `Parameters`.
  5. Handler `PickBatch`: kiểm tra rồi mở form.
  6. Callback: bỏ qua khi Result là Undefined, ngược lại ghi vào dòng hiện tại.
  ```bsl
  &AtClient
  Procedure PickBatch(Command)
  	// 1) dòng hiện tại có tồn tại? Product đã điền? -> nếu không: báo user, Return
  	// 2) Warehouse đã điền? -> nếu không: báo lỗi, Return
  	___
  	// 3) Structure tham số (Date, Product, Warehouse) + OpenForm(..., owner = field Batch, ..., callback)
  	___
  EndProcedure

  &AtClient
  Procedure PickBatchAfterSelection(Result, AdditionalParameters) Export
  	___ // kiểm tra Result và dòng hiện tại, rồi gán Batch
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Quên `Export` ở callback thì platform không gọi được.
  - Không kiểm tra `Items.Products.CurrentData = Undefined`: lỗi khi table trống hoặc không có dòng nào được chọn.
  - [ghi chú ngoài nguồn] Code mẫu của khóa chỉ kiểm tra Product; đề bài yêu cầu báo lỗi cả khi **Warehouse** trống. Đừng bỏ bước này. Tên callback trong cấu hình mẫu là `PickBatchOnSelection`; tên theo đề là `PickBatchAfterSelection`, chỉ khác tên.
  - `CheckedAttributes.Find()` trả Undefined nếu không có path, nên phải kiểm tra trước khi `Delete()`.
- **Tự kiểm tra:** Đặt Write-off order = FIFO: cột Batch và nút ẩn, document post được khi Batch trống. Đặt Manually: cột hiện; bấm "Pick batch" khi chưa chọn product hoặc warehouse thì nhận thông báo; khi đủ dữ liệu, form chỉ liệt kê batch còn tồn của đúng product và kho, chọn một dòng thì Batch được điền.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/15-theory)

So với nhánh lesson/14-theory, nhánh lesson/15-theory thêm: functional options `UseCharacteristics`, `UseContracts`, `CompanyPrefix` (và `UseCounterparties`), functional option parameter `Company`, information register `CompanyAccountingSettings` (Nonperiodical, Write mode `Independent`, dimension `Company`, resources `UseContracts`, `UseTaxes`) với record form, common form `DefaultValues` đổi tên thành `ApplicationSettings`, và code đặt FO parameters trong form Sales invoice.

### Form Sales invoice: đặt functional option parameters theo Company
Nguồn: nhánh lesson/15-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetFunctionalOptionParameters();
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	OnCompanyChangeAtServer();
	
EndProcedure

&AtServer
Procedure OnCompanyChangeAtServer()

	SetFunctionalOptionParameters();

EndProcedure
// ...
&AtServer
Procedure SetFunctionalOptionParameters()
	
	FunctionalOptionParatemets = New Structure("Company", Object.Company);
	
	SetFormFunctionalOptionParameters(FunctionalOptionParatemets);
	
EndProcedure
```
- Đây là ví dụ còn thiếu của lý thuyết: gọi từ `OnCreateAtServer` và từ `CompanyOnChange` (qua `OnCompanyChangeAtServer`, vì method chỉ chạy trên server) — company khác có thể có giá trị FO `UseContracts` khác → field `Contract` ẩn/hiện theo company của document.
- Structure gồm tên functional option parameter (`Company`) và giá trị (`Object.Company`).
- Tên method thật của platform là **`SetFormFunctionalOptionParameters`**; tài liệu lý thuyết ghi `SetParametersFormFunctionalOptions` — khi viết code phải dùng tên `SetFormFunctionalOptionParameters`. (Tên biến `FunctionalOptionParatemets` bị gõ sai trong demo nhưng không ảnh hưởng.)

### Record form của CompanyAccountingSettings: cờ RefreshInterface khi đổi UseContracts
Nguồn: nhánh lesson/15-theory — cf/InformationRegisters/CompanyAccountingSettings/Forms/RecordForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure UseContractsOnChange(Item)
	RefreshInterface = True;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If RefreshInterface Then
		RefreshInterface();
	EndIf;
	
EndProcedure
```
- Đúng ghi chú lý thuyết "Record form của register cũng cần làm cơ chế gọi `RefreshInterface()` như common form của constants": form attribute Boolean `RefreshInterface`, field `Record.UseContracts` gắn handler OnChange `UseContractsOnChange`.
- Common form `ApplicationSettings` trong nhánh này có cùng cơ chế (handler OnChange bật cờ + `AfterWrite`) như record form ở trên.

### FO UseContracts: Data path là resource của information register, Content gồm catalog và attributes
Nguồn: nhánh lesson/15-theory — cf/FunctionalOptions/UseContracts.xml
```xml
			<Location>InformationRegister.CompanyAccountingSettings.Resource.UseContracts</Location>
			<PrivilegedGetMode>true</PrivilegedGetMode>
			<Content>
				<xr:Object>Catalog.CounterpartyContracts</xr:Object>
				<xr:Object>Document.PurchaseInvoice.Attribute.Contract</xr:Object>
				<xr:Object>Document.ReturnOfGoodsFromCustomer.Attribute.Contract</xr:Object>
				<xr:Object>Document.SalesInvoice.Attribute.Contract</xr:Object>
			</Content>
		</Properties>
```
- `Location` (Data path) = resource `UseContracts` của register `CompanyAccountingSettings`; `PrivilegedGetMode` = **Use privileged mode for getting data** bật.
- Tab Content chọn chi tiết tới mức attribute: catalog `CounterpartyContracts` và attribute `Contract` của ba documents.

### FO CompanyPrefix (không gán objects) và parameter Company
Nguồn: nhánh lesson/15-theory — cf/FunctionalOptions/CompanyPrefix.xml và cf/FunctionalOptionsParameters/Company.xml
```xml
			<Location>Catalog.Companies.Attribute.Prefix</Location>
			<PrivilegedGetMode>true</PrivilegedGetMode>
			<Content/>
```
```xml
			<Use>
				<xr:Item xsi:type="xr:MDObjectRef">InformationRegister.CompanyAccountingSettings.Dimension.Company</xr:Item>
			</Use>
```
- `CompanyPrefix` lưu ở catalog attribute `Companies.Prefix`, `Content` rỗng — chỉ để đọc bằng `GetFunctionalOption("CompanyPrefix", ...)`, không điều khiển interface.
- Property **Use** của parameter `Company` trỏ tới dimension `Company` của `CompanyAccountingSettings`.
- [ghi chú ngoài nguồn] Lý thuyết nói parameter `Company` chọn cả reference catalog Companies (cho `CompanyPrefix`); trong nhánh lesson/15-theory, **Use** chỉ có dimension của register.

## Video tham khảo (khóa Junior cũ)

Video trong playlist "Junior Developer Course" (1C Vietnam Academy, khóa cũ) có phạm vi trùng với bài này. Gọi là "video JC-<số>" (số bài của khóa cũ, khác số bài giáo trình); quy ước dẫn và độ tin cậy: `references/video-junior-course.md`.

- [JC-17 «Đối tượng và tập hợp bản ghi»](https://www.youtube.com/watch?v=L4OkNedrIeQ&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=16) (5:26) — Bài 15 — object vs non-object entities; Bài 12 — RecordSet / RecordManager
- [JC-18 «Tính toàn vẹn tham chiếu»](https://www.youtube.com/watch?v=e-C_yERp2sE&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=17) (7:49) — Bài 15 — referential integrity, deletion mark, xóa object
- [JC-38 «Tùy chọn chức năng»](https://www.youtube.com/watch?v=RF55RDNLgks&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=37) (7:02) — Bài 15 — Functional options
