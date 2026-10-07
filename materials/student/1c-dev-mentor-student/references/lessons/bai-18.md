# Bài 18 — Reports: Data composition system (DCS)

## Khái niệm chính

### Basics of DCS
- **Data composition system (DCS)**: công cụ bao trùm mọi chức năng chính của report, từ lấy dữ liệu từ nhiều nguồn tới hiển thị thân thiện. Nguồn thường là database, mô tả bằng 1C:Enterprise query language.
- Developer định nghĩa **default report settings** để user chạy ngay; user có thể đổi settings → DCS sinh query khác và trình bày theo settings của user.
- DCS là tập các elements, mỗi element ứng với một giai đoạn thực thi report; mỗi element có declarative description, truy cập bằng code và serialization to/from XML.
- Hai thành phần chính ảnh hưởng kết quả: **composition schema** và **composition settings**.
- **Composition schema** — element cơ bản, mô tả mọi quy tắc lấy và xử lý dữ liệu:
  - Data sets
  - Composition fields
  - Calculated fields
  - Resources
  - Parameters
  - Element bổ sung (cho report phức tạp): Data set links, Templates, Nested schemas.
- **Data composition settings** — mô tả cách trình bày dữ liệu (developer hoặc user cấu hình): filter, ordering, conditional appearance, report structure, data retrieval parameters, data output parameters...
- **Data composition template** — kết quả áp dụng settings cụ thể lên schema; là "task" sẵn sàng cho composition processor. Gồm:
  - Data sets with resulting queries
  - Data set relationships
  - Parameter values
  - Layouts of various report areas
  - Body of the layout với correspondence settings giữa report structure và layouts
- **Composition template query** có thể khác nhiều so với query trong schema: chỉ chứa field và filter được chọn trong settings; field không dùng bị **tự động loại** khỏi query cuối (ngoại lệ: composition fields có role đặc biệt **"Balances"**). Query trong schema còn có thể chứa query language extensions cho DCS.
- Quá trình generate tự động; cũng có thể làm bằng code.

### Data sets
- Ba loại:
  1. **Query** — mô tả bằng query language.
  2. **Object** — tên external data set (value table, selection từ query result, range ô của spreadsheet document, register record set...). Phổ biến nhất: **value table**.
  3. **Union** — không phải data set thực, gộp nhiều data set thành một (giống UNION trong query), nhưng các data set con **không cần cùng số field**. Ví dụ gộp sales và purchases theo product.
- Thuộc tính chung: **Name** (duy nhất trong schema), **Fields**.
- Data set kéo-thả được. Rename bằng double-click tên.
- Union: field cùng **Path** (ví dụ Product) lấy dữ liệu từ cả hai data set con; record **chưa group** trước output (record có balance, record có sales riêng) — grouping làm ở bước sau. Muốn tách → đổi **Path** trong một data set (ví dụ `Product` → `ProductBalance`).

### Simple report (ví dụ Sales)
- Đổi tên report cũ thành **SalesTemplate** (synonym "Sales (template)"), tạo report **Sales** mới trong subsystem Sales. Tạo template kiểu **Data composition schema** bằng nút kính lúp ở field **"Main data composition schema"** hoặc nút **"Open data composition schema"**; loại template cố định, chỉ đổi tên → "Finish".
- Data set Query tên **Sales** — virtual table turnovers của register Sales. **Không cần totals trong query** (hierarchy làm bằng DCS).
- **Resources** tab: field được tính theo groupings (group / overall totals):
  - **Expression** — công thức, ví dụ `Sum(Balance)`; có aggregate functions, custom functions trong expression language của DCS, và cả **export function của common modules**.
  - **Calculate by…** — danh sách groupings tính resource. Trống → mọi grouping. Có giá trị → chỉ có ở grouping đó.
  - Nút **">>"** thêm mọi resource có thể tính totals. Amount → `Sum()`.
- **Settings** tab có 3 phần:
  - Trái: danh sách **report options** (một report nhiều option, ví dụ theo customer hoặc theo product).
  - Phải trên: cấu trúc groupings, tables, diagrams.
  - Phải dưới: parameters, selected fields, filter, sorting, conditional appearance, custom fields, other settings.
- **Settings wizard**:
  - Loại report: **list**, **table**, **diagram**. **Table** = chỉ tiêu tại giao điểm dòng × cột (ví dụ tồn kho: dòng là product, cột là warehouse); không hợp khi số chiều lớn (ví dụ 20+ warehouse).
  - Chọn fields: resources phải chỉ định theo thứ tự hiển thị; groupings có thể bỏ (sẽ tự thêm ở bước sau).
  - Groupings: Customer rồi Product. Với object có hierarchy chọn grouping type: **elements**, **hierarchy**, **hierarchy only** (hierarchy → hiện cả đường dẫn nhóm, tính totals theo hierarchy).
  - Sorting: nếu không chỉ định → DCS sắp tăng dần theo quy tắc kiểu primitive (date, number, string, boolean) và theo **presentation** với reference types (ví dụ description nếu main presentation là description); nhiều field trong một grouping → áp dụng lần lượt.
- Không cần tạo report form — platform tạo **default form**. Đổi tên report option thành **SalesByCustomers**.
- Favorites lưu theo **full name** → report mới mang tên cũ tự hiện trong Favorites, report cũ bị loại khỏi Favorites sau khi đổi tên.
- Form mặc định: nút **"Select option…"** (danh sách report options), **"Settings…"** (settings dành cho user).

### Parameters
- Tab **Parameters** tự có **BeginOfPeriod** và **EndOfPeriod** vì: (1) query dùng virtual table Turnovers có các parameter đó; (2) flag **Autofill** dưới query text trên tab Data sets được bật (tự lấy mọi field dùng trong query làm resource/grouping/filter...). Tắt Autofill → phải tự khai báo field, selection fields, virtual table parameters...
- Đặt tên parameter riêng trong virtual table → tab Parameters có 4 parameter (2 của DCS + 2 tự đặt).
- Đưa setting cho user: Settings → tab Parameters (cũng như Filter, Sorting, Conditional appearance) có flag **"Include in custom settings"**. **"Edit mode"**: **"Quick access"** → hiện ngay trên report form; **"Normal"** → chỉ trong cửa sổ settings.
- Bỏ giờ khỏi ngày: cột **"Type"** → **"Date format"** = "Date".
- Luôn bật parameter (không có checkbox): cột **"Usage"** = **"Always"** thay cho "Auto".
- Virtual table turnovers: empty date ở start/end → không giới hạn.
- Cột **"Expression"** (ngôn ngữ DCS, giao một phần với built-in language): `EndOfPeriod(<Period>, <PeriodType>)`, tham số viết sau ký hiệu **`&`**, PeriodType là chuỗi ("Day", "Month"...).
  - Vấn đề: ngày trống → thành cuối ngày 1.1.0001 (23:59:59) → report không có dữ liệu. Cách xử lý: biểu thức CASE kiểm tra empty date, hoặc dùng **standard period** (tự đưa end date về cuối ngày nếu không trống) — bài chọn cách này.
- Parameter **Period** kiểu **StandardPeriod**, always use. Với BeginOfPeriod/EndOfPeriod: bật **"Availability restriction"**, tắt **"Include in available fields"**, **"Usage"** về Auto; Expression: `&Period.StartDate`, `&Period.EndDate`. Bật "Include in custom settings" cho Period.

### Filter
- Thêm filter trên tab Filter rồi đưa vào custom settings với "Quick access".
- User tự cấu hình: submenu **"More actions"** → **"Change option..."** → cửa sổ gần giống tab Settings trong Designer. Ví dụ filter Product, comparison type **"In the list"**, bỏ use flag (tắt mặc định), include in custom settings + quick access → "finish editing".
- Filter user tạo chỉ user đó thấy; có thể lưu report option. Không đi sâu vào lưu report variant vì cấu hình hiện đại dùng report variants nâng cao trong subsystem **Reports** của **Standard Subsystems Library**.
- Để mọi user có filter → thêm ở mức configuration (Designer).
- Cột **Presentation** trên tab Filter → filter **"fixed"**: user chỉ bật/tắt, không đổi comparison type hay giá trị (ví dụ "Amount >= 1000" với presentation "Only for the amount from 1000"). Trong Enterprise mode: right-click → **"Set presentation"**, hoặc bật flag **"Detailed"** trong "More actions".
- User đổi được cấu trúc report (groupings, tables, diagrams) nhưng **không** đổi được data sets, parameters, resources → developer đôi khi chọn sẵn field bổ sung.

### Complex report (ví dụ PlannedSalary)
- Bối cảnh: hệ thống HRM bên ngoài trả bảng *Employee - Company - NumberOfHours - CurrentSalary*; cần report: employee, số giờ, lương tính, bonus/fine (có thể âm), số tiền trả = lương tính + bonus/fine (âm → hiển thị 0). Chỉ nhân viên đang làm việc tại ngày hiện tại (resource **"Works"** của information register **"Employees"**).
- Tạo subsystem **Salary** (con của HRM); accumulation register **BonusesFinesOfEmployees** kiểu **"Turnover"** (Dimensions: Employee, Company; Resources: Bonus, Fine); document **BonusesFinesOfEmployeesRegistration** (accumulation register không thể độc lập).
- Report **PlannedSalary**: data set **"object"** tên **"CurrentSalaryAccruals"**, field **"Data object name"** = **"PayrollAccrualsFromHRM"** (tên để truyền từ code); tự khai báo fields và value type.
- Data set "query" chọn nhân viên + bonus/fine từ information register "Employees" và accumulation register "BonusesFinesOfEmployees".
- **Data set links**: **mọi link là left join**. **"Link source"** = bảng chính, **"Link target"** = bảng nối; **"Source expression"**, **"Target expression"** = field hoặc biểu thức DCS.
  - Ưu điểm chính: dù mỗi set có nhiều dòng cùng giá trị field nối, khi tính totals chỉ dùng một record mỗi set, **không nhân đôi**; totals theo grouping đúng (khác với join nhiều bảng trong một query).
  - Truyền field của data set chính làm **query parameter** của data set nối: field **"Parameter"** (ví dụ `&Product`) → mỗi product một query. Parameter phải khai báo trong query; nếu chỉ dùng để link → khai báo trên tab **"Data composition"** của query (mọi parameter/field/condition ở tab này là tuỳ chọn).
  - Đơn giản nhưng có thể chậm: 1000 record → 1000 query. Tối ưu: flag **"Parameter list"** → query theo lô **1000 record** (1500 record → 2 query); điều kiện phải đổi sang **IN**: `Product IN (&Product)`.
  - Ví dụ: BonusesFinesOfEmployees làm data set chính, link qua 2 field Employee và Company.
- **Calculated fields**: field bổ sung tính bằng công thức (expression language của DCS); hiện trong settings theo tên ở path. **Hạn chế**: không dùng calculated field khác trong biểu thức. Được dùng data set fields, mọi cú pháp expression language, function **Export** của common modules. Có title, availability restriction, presentation expression, ordering expressions, value type, available values, formatting. Có thể làm resource (thêm vào Resources + expression tính total).
  - Khi chỉ cần tính giá trị cho resource → dùng expression ở Resources, không cần calculated field. Cần field mới không có trong data sets, hoặc field không phải resource → dùng calculated field.
  - Ví dụ: **AmountToPay** = `CurrentSalary + BonusFine`, value type **Number(10, 0)**. Platform cảnh báo khi dùng field không tồn tại.
- Parameters: Period và EndOfPeriod = `CurrentSessionDate()`; BeginOfPeriod = `BeginOfPeriod(CurrentSessionDate(), "Month")`; bật **"Restrict availability"**.
- Settings: option **"PlannedSalaryByCompanies"**; grouping Company → Employee (thêm field Position, Department qua edit grouping: double-click / nút pencil / **F2**). Gom field: chọn → right-click **"group fields"** → group tiêu đề **"Salary"**. Filter company và employee: include in user settings nhưng tắt mặc định.
- Không truyền object data set → user nhận lỗi khi generate.
- **Report object module**, handler **OnComposeResult** (kích hoạt khi generate qua method **`ComposeResult()`** — method then chốt khởi động toàn bộ quá trình):
  1. `StandardProcessing = False`.
  2. Lấy settings của **settings composer**.
  3. Tạo **DataCompositionTemplateComposer**, gọi **`Execute()`** truyền schema, settings và **details data** (từ tham số OnComposeResult) → nhận **DataCompositionTemplate**.
  4. Tạo **Structure** external data sets: key = **data object name** của object data set, value = giá trị hợp lệ (ở đây **ValueTable**).
  5. Tạo **DataCompositionProcessor**, khởi tạo với template + external data sets.
  6. Tạo **DataCompositionResultSpreadsheetDocumentOutputProcessor**, set spreadsheet document (**ResultDocument**), output kết quả. Muốn ra collection (ValueTable/ValueTree) → **DataCompositionResultValueCollectionOutputProcessor**.
  - **DetailsData**: khi DCS tạo spreadsheet document, ô chứa **DetailsIdentifier**, không chứa giá trị field; giá trị lấy từ object DetailsData được điền khi output.
  - Function giả lập HRM: chọn nhân viên đang làm, số giờ/lương random; max = số ngày tới hôm nay × 8 (ví dụ ngày 20 → 160).

### Characteristics in the report
- Characteristics đã khai báo cho object trong **characteristics window** (bài chart of characteristic types) → tự có trong report như attribute của object đó; characteristics của object khác không thấy.
- Chỉ có ở **Enterprise mode**, không có trong Designer. Nếu chưa khai báo cho object → thêm trên tab **Characteristics** của query (query console) — chỉ dùng được trong report đó. Khuyến nghị khai báo trực tiếp trong object.
- Ví dụ report kiểu **Table**: dòng = product, cột = characteristic "Color"; cột tiêu đề trống = sản phẩm chưa có Color. Hai resource → mỗi cột màu hiện cả hai.

### Report design
- Tab **Other/Additional settings**: **"Appearance template"** mặc định **"Main"**; không có metadata object **"Style"** → không có màu (như "Without appearance"). Ví dụ chọn **"Antique"**.
- **Conditional appearance** (developer và user đều dùng được), 4 thiết lập:
  - **Format** — background color, text color, font, cell format, text thay giá trị...
  - **Condition** — ví dụ `Balance < 0`.
  - **Formatted fields**.
  - **Usage area** — groupings, hierarchical groupings, totals, field headers, resource field headers, totals headers, totals resource field headers, header, parameters, filter…
- Ví dụ "Goods movement": màu chữ đỏ dùng predefined color **"Negative number"**. Một điều kiện cho một cột → cần 8 dòng; thay bằng auxiliary formatting **"Mark negatives"** trong Format window — chỉ cần chọn fields, platform tự kiểm tra giá trị âm → 1 dòng là đủ.
- Áp dụng chỉ cho một số grouping: chọn grouping trong report structure → settings riêng của grouping → thêm conditional appearance ở đó (ví dụ Product và Recorder, không cho Warehouse), xoá dòng trong report settings chung.

### Roles of fields
- Đặt trên tab Data sets, nút chọn ở cột **Role**. Platform tự đặt một số.
- Thuộc tính:
  - **Without role**.
  - **Period** — số thứ tự period; 0 = không phải period; period nhỏ nhất = 1, cha = 2... Ví dụ query Balances and Turnovers: Period = 3, Recorder = 2, LineNumber = 1; không dùng LineNumber → Recorder = 1, PeriodSecond = 2... Platform dùng để tính totals cho balance fields.
  - **Additional** — period field tuỳ chọn: không bắt buộc dùng nếu period con được dùng. Nếu không đặt → dùng period con thì field này cũng phải có trong grouping.
  - **Dimension** — dùng khi tính totals cho resources.
  - **Ignore NULL values** — không đưa group record cho field có giá trị NULL.
  - **Required** — thêm field vào data set của composition template nếu có ít nhất 1 field của data set được dùng trong settings (vì DCS loại field không dùng khỏi query → có thể gây lỗi).
  - (Không học: roles "Account" và "Balances".)
- **Periodicity** trong virtual table Turnovers / BalanceAndTurnovers: muốn chọn Recorder phải đặt **Recorder**, **Record** hoặc **Auto**.
  - **Important**: periodicity quyết định cách group resources: Recorder → theo dimensions + recorder; Record → thêm tới record number (nếu chọn LineNumber); Auto → chọn được Second, Hour, Day, Month..., group tới period chi tiết nhất được chọn.
- Gom field thành nhóm bằng **Path** dạng `GroupName.FieldName` (ví dụ `Receipt.Quantity`, `Expense.Quantity`).
- Report Goods movement: groupings Warehouse - Product - Recorder; field groups "Beginning of period", "Receipt", "Expense", "End of period"; đặt tiêu đề "Quantity"/"Amount" bằng nút **"Set title"** (không đặt title trùng nhau trong data set vì user không phân biệt được field trong Enterprise mode).
- Vấn đề: totals opening/closing trong grouping bị ngược (DCS không có dữ liệu theo giây). Giải pháp: chọn field **PeriodSecond** trong query → platform tự gán role **"Period, 2"** (Recorder là "Period, 1"); "additional" bỏ chọn → totals tính theo field này kể cả khi không chọn trong report. Chọn thêm PeriodDay → platform đặt "Additional" cho nó (đã có period chi tiết hơn). Xoá PeriodDay vì không cần.

## Cú pháp & ví dụ code

Ví dụ expression của resource:
```bsl
Sum(Balance)
```
```bsl
1
```
```bsl
Balance / Total * 100
```
```bsl
CASE WHEN FieldValue > 1 THEN True ELSE False END
```
```bsl
ServerCommonModule.Function(Parameter1, Parameter2)
```

Expression của parameter:
```bsl
EndOfPeriod(<Period>, <PeriodType>)
```
```bsl
CASE WHEN &EndOfPeriod = DateTime(1, 1, 1) THEN DateTime(1, 1, 1) ELSE EndOfPeriod(&EndOfPeriod, "Day") END
```
```bsl
&Period.StartDate
```
```bsl
&Period.EndDate
```

Điều kiện khi bật "Parameter list" trong data set links:
```bsl
Product IN (&Product)
```

Calculated field:
```bsl
CurrentSalary + BonusFine
```

Parameters của report PlannedSalary:
```bsl
CurrentSessionDate()
```
```bsl
BeginOfPeriod(CurrentSessionDate(), "Month")
```

Path nhóm field:
```bsl
Receipt.Quantity
Expense.Quantity
```

Các object/method dùng trong OnComposeResult: `ComposeResult()`, `DataCompositionTemplateComposer`, `Execute()`, `DataCompositionTemplate`, `DataCompositionProcessor`, `DataCompositionResultSpreadsheetDocumentOutputProcessor`, `DataCompositionResultValueCollectionOutputProcessor`, `DetailsData`, `DetailsIdentifier`.

[ghi chú ngoài nguồn] Code đầy đủ của OnComposeResult, function giả lập HRM và query text chỉ có dạng ảnh trong tài liệu nên không chép lại. Function giả lập HRM `PayrollAccrualsFromHRM`, OnComposeResult của PlannedSalary và query text của report Sales/PlannedSalary/GoodsMovement → xem mục Code demo của bài Theory (nhánh lesson/18-theory).

## Thuộc tính/thiết lập quan trọng trong Designer
- Report: **Main data composition schema**, nút **Open data composition schema**.
- Data set: **Name**, **Fields**, **Path**, **Role**, flag **Autofill**; object data set: **Data object name**; query tab **Data composition**, **Characteristics**.
- Resources: **Expression**, **Calculate by…**, nút **">>"**.
- Parameters: **Type** (Date format), **Usage** (Auto/Always), **Expression**, **Availability restriction / Restrict availability**, **Include in available fields**.
- Settings: **Include in custom settings**, **Edit mode** (Quick access / Normal), Filter **Presentation**, comparison type **In the list**, grouping type (elements / hierarchy / hierarchy only), **group fields**, **Set title**.
- Data set links: **Link source**, **Link target**, **Source expression**, **Target expression**, **Parameter**, **Parameter list**.
- Calculated field: path, expression, value type (ví dụ Number(10, 0)), title, availability restriction, presentation expression, ordering expressions, available values, formatting.
- Other/Additional settings: **Appearance template** (Main / Without appearance / Antique).
- Conditional appearance: **Format** (bao gồm **Mark negatives**, màu **Negative number**), **Condition**, **Formatted fields**, **Usage area**.
- Field roles: **Period**, **Additional**, **Dimension**, **Ignore NULL values**, **Required**.
- Virtual table parameter **Periodicity**: Recorder / Record / Auto.
- Enterprise mode: **More actions → Change option...**, **Set presentation**, flag **Detailed**.

## Lỗi thường gặp / lưu ý
- Field không dùng trong settings bị loại khỏi query cuối → có thể gây lỗi; dùng role **Required** khi cần.
- Parameter mặc định có checkbox và giờ trong ngày → đặt Date format và Usage = Always.
- Dùng `EndOfPeriod(&EndOfPeriod, "Day")` khi ngày trống → thành 1.1.0001 23:59:59 → report rỗng; dùng CASE hoặc StandardPeriod.
- Không truyền external data set cho object data set → lỗi khi generate.
- Data set links với parameter: mỗi dòng một query → chậm; bật "Parameter list" và dùng IN.
- Calculated field không được tham chiếu calculated field khác.
- Appearance template "Main" không có màu nếu configuration không có metadata object "Style".
- Đặt title trùng nhau trong data set → user không phân biệt được field; dùng "Set title" trong settings.
- Totals opening/closing balance sai khi không có dữ liệu theo giây → thêm PeriodSecond (role Period).
- Union data set: record chưa group trước output.
- Characteristics trong report chỉ có ở Enterprise mode.
- Favorites lưu theo full name → đổi tên report ảnh hưởng Favorites.

## Điểm cần nhớ
- DCS = **composition schema** (data sets, fields, calculated fields, resources, parameters) + **settings** → **composition template** → composition processor → output.
- Data sets: Query / Object (thường là value table, truyền từ code) / Union (không cần cùng số field).
- Resources = totals theo grouping (Expression + Calculate by); không cần TOTALS trong query.
- Đưa parameter/filter cho user: **Include in custom settings** + **Quick access**; dùng **StandardPeriod** với Expression `&Period.StartDate` / `&Period.EndDate`.
- Data set links luôn là **left join**, totals không bị nhân đôi; "Parameter list" xử lý theo lô 1000.
- Generate bằng code trong **OnComposeResult**: TemplateComposer → Processor (kèm external data sets) → OutputProcessor.
- Conditional appearance: Format/Condition/Formatted fields/Usage area; "Mark negatives" tiện cho số âm; có thể đặt theo từng grouping.
- Field role **Period** (và PeriodSecond) cần để totals của balance tính đúng; periodicity Recorder/Record/Auto mới chọn được Recorder.

## Thẻ gợi ý bài thực hành (Practice 18)

Các thẻ đi theo thứ tự đề trong 18. Practice. Cả hai report đều làm bằng DCS (data composition system).

### Bài tập 1 — Report "Sales with price deviation"

- **Đề bài (tóm tắt):** Report DCS gồm quantity đã bán, giá thực tế (Amount / Quantity), giá kế hoạch (export function lấy giá tại **ngày bán**) và chênh lệch (thực tế − kế hoạch), tính trung bình theo product. Có 2 variant (Company → Customer → Product và Customer → Product). Loại hàng trả. Có period kiểu StandardPeriod, filter company/customer/product ngay trên form. Giá chỉ hiện ở grouping Product và tổng chung; giá thực tế hiển thị dạng số nguyên. Đưa report vào subsystem Sales.
- **Gợi ý 1 — Hướng đi:**
  - Data set query trên **Turnovers** của register Sales, periodicity cho phép lấy ngày của record (SecondPeriod hoặc Recorder), rồi lọc quantity turnover **dương** để loại hàng trả.
  - Giá kế hoạch là **calculated field** có expression gọi export function của common module (DCS cho phép gọi function server trong expression).
  - Trung bình và chênh lệch là **resources** (mục "Resources = totals theo grouping"), với **Calculate by** = Product.
  - Lưu ý trong lý thuyết: expression của calculated field **không được** tham chiếu calculated field khác, nhưng expression của resource thì được.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Main data composition schema của report; query có field giá thực tế, dùng `CASE` chống chia 0.
  - Calculated field `PricePlan`: expression gọi function lấy giá đã làm ở bài information registers, qua common module có flag **Server call**, truyền product và **ngày bán**.
  - Calculated field `Deviation` (có thể để trống expression) và các resources: Quantity (Sum), PriceFact/PricePlan (Avg), Deviation (chênh lệch hai trung bình), Calculate by Product.
  - Format của field giá thực tế: `NFD=0` (chỉ đổi hiển thị, giữ nguyên dữ liệu).
  - Parameter `Period` kiểu StandardPeriod; `BeginOfPeriod`/`EndOfPeriod` có Expression `&Period.StartDate`/`&Period.EndDate`, đặt Availability restriction.
  - Settings: 2 variant; filter + period **Include in custom settings**, Edit mode **Quick access**; Appearance template.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo report, mở schema, viết query (ngày bán, company, customer, product, quantity, giá thực tế) với điều kiện quantity > 0.
  2. Đặt role Period cho field ngày.
  3. Thêm calculated field PricePlan, Deviation và các resources với Calculate by = Product.
  4. Khai báo parameters cho period.
  5. Tạo variant 1 (Company → Customer → Product) và variant 2 (Customer → Product, không có Company); thêm filter quick access, format, appearance.
  6. Đưa vào subsystem Sales.
  ```
  // Calculated field PricePlan (expression):  ___(Product, ___)   <- function export + ngày bán
  // Resource PriceFact:  ___(PriceFact)      Calculate by: Product
  // Resource Deviation:  ___                 <- hiệu của hai resource trung bình
  ```
- **Lỗi hay gặp:**
  - Lấy giá kế hoạch tại ngày hiện tại thay vì **ngày bán**.
  - Tính Deviation trong calculated field bằng cách tham chiếu PricePlan là không được. Phải đặt trong resource.
  - Không đặt Calculate by, khiến giá trung bình hiện cả ở Company/Customer.
  - Làm tròn ngay trong query thay vì chỉ format hiển thị, làm phép tính sai.
  - [ghi chú ngoài nguồn] Function giá được gọi cho **từng record** chi tiết (mỗi lần một query), nên dữ liệu lớn sẽ chậm. Có thể tối ưu bằng virtual table SliceLast trong query hoặc data set link.
- **Tự kiểm tra:** Post vài Sales invoice có discount (theo contract) ở những ngày có giá khác nhau. Chạy variant 1: cấp Product có Price fact/Price plan/Deviation trung bình, cấp Company/Customer chỉ có Quantity. Đổi variant 2: không còn Company. Tạo Return of goods: số liệu report không đổi. Đối chiếu một product với bảng ví dụ trong đề (142/151/−9).

### Bài tập 2 — Report "Goods movement" và tồn tối thiểu từ hệ thống ngoài

- **Đề bài (tóm tắt):** Report DCS gồm tồn đầu, nhập, xuất, tồn cuối (quantity và amount) theo kho → product, đúng ở mọi cấp grouping. Variant 2 thêm cột "Required minimum" lấy từ server common module `IntegrationWithWarehouseManagementSystem`: export function trả value table (Warehouse, Product, MinimumBalance) cho mọi kho × mọi product loại "Product", số ngẫu nhiên 1–20. Chỉ có period kiểu StandardPeriod, filter Warehouse (bằng) và Product (in list); tô màu ô tồn cuối khi thấp hơn mức tối thiểu ở cấp Product. Đưa report vào subsystem Warehouse.
- **Gợi ý 1 — Hướng đi:**
  - Query data set trên virtual table **BalanceAndTurnovers** của GoodsInWarehouses. Để balance đúng ở mọi grouping cần field có **role Period** (Recorder là Period 1, SecondPeriod là Period 2), tức là periodicity phải cho phép chọn Recorder (mục "Roles of fields").
  - Dữ liệu ngoài đi vào **object data set**, nối với query data set bằng **data set link** (luôn là left join).
  - Object data set yêu cầu tự generate report trong **OnComposeResult** và truyền external data sets (mục "Generate bằng code").
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Common module `IntegrationWithWarehouseManagementSystem` (Server): export function trả ValueTable. Lấy kho × product (product type "Product") rồi điền số bằng `New RandomNumberGenerator` / `RandomNumber(1, 20)`.
  - Schema: query data set + object data set (**Data object name** phải trùng key của external data sets), data set link theo Warehouse và Product.
  - Path nhóm field: `OpeningBalance.Quantity`, `Receipt.Amount`… và đặt title phân biệt rõ.
  - Resource MinimumBalance chỉ tính ở grouping Product.
  - Object module của report: `OnComposeResult(ResultDocument, DetailsData, StandardProcessing)`.
  - Conditional appearance ở grouping Product của variant 2: điều kiện tồn cuối quantity < MinimumBalance, BackColor sáng.
  - Parameters: chỉ để lại StandardPeriod cho user; `BeginOfPeriod`/`EndOfPeriod` lấy qua Expression và đặt Availability restriction.
- **Gợi ý 3 — Khung bài làm:**
  1. Viết function giả lập (kiểm tra số dòng = số kho × số product loại hàng hoá).
  2. Tạo report và query data set BalanceAndTurnovers, chọn thêm Recorder/SecondPeriod, gom field bằng Path.
  3. Thêm object data set, link, resource MinimumBalance.
  4. Viết OnComposeResult: tắt StandardProcessing, lấy settings, compose template, khởi tạo processor kèm external data sets, output ra ResultDocument.
  5. Tạo 2 variant, filter quick access, appearance, conditional appearance; đưa report vào subsystem Warehouse.
  ```bsl
  Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
  	___ // tắt xử lý chuẩn
  	___ // settings hiện tại -> TemplateComposer.Execute(schema, settings, DetailsData)
  	___ // Structure external data sets: key = Data object name, value = function giả lập
  	___ // DataCompositionProcessor.Initialize(...) -> output processor -> Output
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Không truyền external data set cho object data set sẽ lỗi khi generate. Key phải **trùng** Data object name.
  - Không có field role Period (Recorder/SecondPeriod), khiến tồn đầu/cuối ở cấp grouping bị sai.
  - Tám field Quantity/Amount trùng title làm user không phân biệt được trong settings. Đặt title riêng hoặc dùng "Set title".
  - Tô màu ở cả cấp Warehouse. Đặt conditional appearance trong grouping Product.
  - [ghi chú ngoài nguồn] Cấu hình mẫu của khóa đặt tên cột là `RequiredBalance` thay vì `MinimumBalance` như đề. Tên nào cũng được, miễn thống nhất giữa function, object data set và resource.
- **Tự kiểm tra:** So tồn cuối kỳ trước với tồn đầu kỳ sau; tổng theo kho bằng tổng các product. Variant 2 có cột Required minimum chỉ ở dòng product, ô tồn cuối được tô khi thấp hơn. Generate nhiều lần thì số tối thiểu đổi (do ngẫu nhiên) nhưng số dòng của value table không đổi.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/18-theory)

### Function giả lập HRM PayrollAccrualsFromHRM và OnComposeResult của report PlannedSalary

Nguồn: nhánh lesson/18-theory — cf/Reports/PlannedSalary/Ext/ObjectModule.bsl

```bsl
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("PayrollAccrualsFromHRM", PayrollAccrualsFromHRM());
// ...
Function PayrollAccrualsFromHRM()

	Result = New ValueTable;
	Result.Columns.Add("Employee", New TypeDescription("CatalogRef.Employees"));
	Result.Columns.Add("Company", New TypeDescription("CatalogRef.Companies"));
	
	NumberQualifier = New NumberQualifiers(10, 0, AllowedSign.Nonnegative);
	Result.Columns.Add("NumberOfHours", New TypeDescription("Number", NumberQualifier));
	Result.Columns.Add("CurrentSalary", New TypeDescription("Number", NumberQualifier));
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	EmployeesSliceLast.Employee AS Employee,
	|	EmployeesSliceLast.Company AS Company
	|FROM
	|	InformationRegister.Employees.SliceLast(&CurrentDate, ) AS EmployeesSliceLast
	|WHERE
	|	EmployeesSliceLast.Works";

	CurrentDate = CurrentSessionDate();

	Query.SetParameter("CurrentDate", CurrentDate);
	Selection = Query.Execute().Select();

	// Number of days during this month up to the current date multiple 8 hours per day
	NumberOfHoursCurrentMonth = Day(CurrentDate) * 8;
	
	RandomNumberGenerator = New RandomNumberGenerator;
	While Selection.Next() Do
		
		NewRow = Result.Add();
		
		FillPropertyValues(NewRow, Selection);
		NewRow.NumberOfHours = RandomNumberGenerator.RandomNumber(1, NumberOfHoursCurrentMonth);
		NewRow.CurrentSalary = NewRow.NumberOfHours * 500;
		
	EndDo;
	
	Return Result;

EndFunction
```

- Đúng function giả lập HRM của bài: chỉ lấy nhân viên đang làm (`SliceLast` của information register Employees, điều kiện `Works`), số giờ random tối đa = số ngày tới hôm nay × 8 (`Day(CurrentDate) * 8`), lương = số giờ × 500.
- Value table được khai báo cột có kiểu (`TypeDescription`, `NumberQualifiers(10, 0, AllowedSign.Nonnegative)`) khớp với các field tự khai báo trong object data set.
- Key `"PayrollAccrualsFromHRM"` trong `ExternalDataSets` trùng **Data object name** của object data set; phần còn lại của `OnComposeResult` theo đúng chuỗi của lý thuyết (StandardProcessing = False → TemplateComposer → DataCompositionProcessor → output processor).
- `FillPropertyValues(NewRow, Selection)` chép Employee, Company từ selection sang dòng mới theo tên cột.

### Data set query của PlannedSalary, data set links và calculated field AmountToPay

Nguồn: nhánh lesson/18-theory — cf/Reports/PlannedSalary/Templates/MainDataCompositionSchema/Ext/Template.xml

Query text của data set `BonusesFinesOfEmployees`:

```bsl
SELECT
	EmployeesSliceLast.Employee AS Employee,
	EmployeesSliceLast.Company AS Company,
	EmployeesSliceLast.Position AS Position,
	EmployeesSliceLast.Department AS Department,
	ISNULL(BonusesFinesOfEmployeesTurnovers.BonusTurnover, 0) 
		- ISNULL(BonusesFinesOfEmployeesTurnovers.FineTurnover, 0) AS BonusFine
FROM
	InformationRegister.Employees.SliceLast AS EmployeesSliceLast
		LEFT JOIN AccumulationRegister.BonusesFinesOfEmployees.Turnovers AS BonusesFinesOfEmployeesTurnovers
		ON EmployeesSliceLast.Employee = BonusesFinesOfEmployeesTurnovers.Employee
			AND EmployeesSliceLast.Company = BonusesFinesOfEmployeesTurnovers.Company
WHERE
	EmployeesSliceLast.Works
```

Object data set, hai data set links và calculated field (XML của schema):

```xml
	<dataSet xsi:type="DataSetObject">
		<name>CurrentPayrollAccruals</name>
<!-- ... -->
		<dataSource>DataSource1</dataSource>
		<objectName>PayrollAccrualsFromHRM</objectName>
	</dataSet>
	<dataSetLink>
		<sourceDataSet>BonusesFinesOfEmployees</sourceDataSet>
		<destinationDataSet>CurrentPayrollAccruals</destinationDataSet>
		<sourceExpression>Employee</sourceExpression>
		<destinationExpression>Employee</destinationExpression>
	</dataSetLink>
	<dataSetLink>
		<sourceDataSet>BonusesFinesOfEmployees</sourceDataSet>
		<destinationDataSet>CurrentPayrollAccruals</destinationDataSet>
		<sourceExpression>Company</sourceExpression>
		<destinationExpression>Company</destinationExpression>
	</dataSetLink>
	<calculatedField>
		<dataPath>AmountToPay</dataPath>
		<expression>CurrentSalary + BonusFine</expression>
		<title xsi:type="v8:LocalStringType">
```

- Query chọn nhân viên đang làm từ `Employees.SliceLast` và LEFT JOIN turnovers của register `BonusesFinesOfEmployees`; `ISNULL(...)` để nhân viên không có bonus/fine vẫn có `BonusFine = 0`.
- Virtual table viết không tham số — parameters `Period`, `BeginOfPeriod`, `EndOfPeriod` do DCS tự thêm (Autofill) và có expression `CurrentSessionDate()` / `BeginOfPeriod(CurrentSessionDate(), "Month")`.
- Hai `dataSetLink` (Employee, Company): link source là data set query, link target là object data set `CurrentPayrollAccruals` (`objectName` = `PayrollAccrualsFromHRM`) — mọi link là left join.
- Calculated field `AmountToPay` = `CurrentSalary + BonusFine` (value type Number(10, 0) trong schema) dùng field của cả hai data set.

### Query của report Sales (DCS) và parameters lấy từ StandardPeriod

Nguồn: nhánh lesson/18-theory — cf/Reports/Sales/Templates/MainDataCompositionSchema/Ext/Template.xml

```bsl
SELECT
	SalesTurnovers.Product AS Product,
	SalesTurnovers.Customer AS Customer,
	SalesTurnovers.AmountTurnover AS Amount
FROM
	AccumulationRegister.Sales.Turnovers(, , Auto, ) AS SalesTurnovers
```

```xml
	<parameter>
		<name>BeginOfPeriod</name>
<!-- ... -->
		<useRestriction>true</useRestriction>
		<expression>&amp;Period.StartDate</expression>
		<availableAsField>false</availableAsField>
	</parameter>
	<parameter>
		<name>EndOfPeriod</name>
<!-- ... -->
		<useRestriction>true</useRestriction>
		<expression>&amp;Period.EndDate</expression>
		<availableAsField>false</availableAsField>
	</parameter>
	<parameter>
		<name>Period</name>
<!-- ... -->
		<valueType>
			<v8:Type>v8:StandardPeriod</v8:Type>
		</valueType>
<!-- ... -->
		<useRestriction>false</useRestriction>
		<use>Always</use>
	</parameter>
```

- Query không có TOTALS — hierarchy Customer → Product do settings của DCS tạo; periodicity `Auto` của virtual table Turnovers.
- `BeginOfPeriod`/`EndOfPeriod`: `useRestriction` = true ("Availability restriction"), expression `&Period.StartDate` / `&Period.EndDate`, `availableAsField` = false — đúng cách bài xử lý vấn đề empty date.
- Parameter `Period` kiểu `StandardPeriod`, `use` = `Always` (không có checkbox).

### Query BalanceAndTurnovers của report GoodsMovement (có SecondPeriod)

Nguồn: nhánh lesson/18-theory — cf/Reports/GoodsMovement/Templates/MainDataCompositionSchema/Ext/Template.xml

```bsl
SELECT
	GoodsInWarehousesBalanceAndTurnovers.Recorder AS Recorder,
	GoodsInWarehousesBalanceAndTurnovers.Product AS Product,
	GoodsInWarehousesBalanceAndTurnovers.Warehouse AS Warehouse,
	GoodsInWarehousesBalanceAndTurnovers.QuantityOpeningBalance AS QuantityOpeningBalance,
	GoodsInWarehousesBalanceAndTurnovers.AmountOpeningBalance AS AmountOpeningBalance,
	GoodsInWarehousesBalanceAndTurnovers.QuantityReceipt AS QuantityReceipt,
	GoodsInWarehousesBalanceAndTurnovers.AmountReceipt AS AmountReceipt,
	GoodsInWarehousesBalanceAndTurnovers.QuantityExpense AS QuantityExpense,
	GoodsInWarehousesBalanceAndTurnovers.AmountExpense AS AmountExpense,
	GoodsInWarehousesBalanceAndTurnovers.QuantityClosingBalance AS QuantityClosingBalance,
	GoodsInWarehousesBalanceAndTurnovers.AmountClosingBalance AS AmountClosingBalance,
	GoodsInWarehousesBalanceAndTurnovers.SecondPeriod AS SecondPeriod
FROM
	AccumulationRegister.GoodsInWarehouses.BalanceAndTurnovers(, , Auto, , ) AS GoodsInWarehousesBalanceAndTurnovers
```

- Periodicity `Auto` để chọn được `Recorder`; field `SecondPeriod` được chọn để platform gán role "Period, 2" (Recorder là "Period, 1") → opening/closing balance trong grouping tính đúng.
- Các field được gom bằng Path dạng `OpeningBalance.Quantity`, `Receipt.Amount`... trong schema (tab Data sets) — ví dụ "Path nhóm field" của bài.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Hiển thị có điều kiện](https://www.youtube.com/watch?v=a6kSspz-wo4&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=35) (10:29) — Bài 9 — conditional appearance trên form; Bài 18 — conditional appearance trong DCS _(mã nội bộ JC-36)_
- [Báo cáo dựa trên khuôn mẫu](https://www.youtube.com/watch?v=WVqrshBBH-E&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=46) (6:34) — Bài 18 — DCS (theo mô tả của bảng gốc); nếu video nói về report điền template bằng code thì là Bài 17. Lưu ý: Tên video "báo cáo dựa trên khuôn mẫu" trùng tên Bài 17 (template-based reports) nhưng mô tả của bảng gốc là giới thiệu DCS — cần xem video để chốt. _(mã nội bộ JC-47)_
- [Khuôn mẫu và trình soạn thảo dữ liệu](https://www.youtube.com/watch?v=It9J9M69Tl8&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=47) (8:13) — Bài 18 — data composition schema, data fields, resources _(mã nội bộ JC-48)_
- [Bộ dữ liệu (data set)](https://www.youtube.com/watch?v=HLvgcgPFRq0&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=48) (5:59) — Bài 18 — data sets: Query, Object, Union _(mã nội bộ JC-49)_
- [Thiết lập (setting)](https://www.youtube.com/watch?v=rq_qf0e3is8&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=49) (8:31) — Bài 18 — settings: grouping, selected fields, filters, sorting _(mã nội bộ JC-50)_
