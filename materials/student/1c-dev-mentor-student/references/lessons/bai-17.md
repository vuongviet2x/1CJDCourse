# Bài 17 — Print forms, làm việc với hình ảnh, Reports với programmatic template filling

## Khái niệm chính

### Print forms — tổng quan
- Print form: công cụ hiển thị thông tin về một/nhiều object hoặc thông tin tổng hợp từ DB theo một mẫu đặc biệt. Vẫn cần trong thời đại electronic document management (phải tạo tài liệu điện tử theo format trước khi ký điện tử). Có form theo format bắt buộc (báo cáo cho cơ quan nhà nước), form tự do (nội bộ, ví dụ phiếu kiểm kê kho). Còn dùng để in phong bì, price tags, labels...
- Ngoài in ra máy in, print form có thể lưu ra file ở nhiều format.

### Spreadsheet document & Template
- Print form được xuất ra **spreadsheet document** — internal object của 1C platform, giống Excel/Google Sheet.
- Cấu trúc được định nghĩa bởi configuration object **Template**. Template thêm được vào gần như mọi configuration object: catalogs, documents, enumerations, mọi loại registers, mọi loại plans, reports, data processors, tasks, business processes.
- Loại template dùng cho print forms: **spreadsheet document** và **text document**. "Text document" ít dùng hơn — cho phiếu in trên cash register tape và form không cần cấu trúc phức tạp (bảng, ảnh, độ rộng cột, wrap text...).
- Template "spreadsheet document" chứa "khuôn" dữ liệu; một template có thể dùng cho nhiều biến thể in (có/không discount, có/không tax, có/không con dấu chữ ký...). Có **named areas** lấy được từ code.
- Quy trình điền spreadsheet document từ template:
  1. Lấy template vào biến.
  2. Lấy template area vào biến.
  3. (Nếu cần) điền dữ liệu vào area.
  4. Xuất area ra spreadsheet document.

### Print form wizard
- Nằm trong submenu **"Wizards"** của context menu object (hoặc submenu **"Actions"** trong object editor).
- Bước 1: tạo mới hoặc sửa print command. Đặt tên rõ ràng; dialog **không kiểm tra** space/ký tự cấm, nhưng yêu cầu giống tên metadata object (vì sẽ tạo command và template mới).
- Các bước: chọn field cho header → mỗi tabular section một bước (ví dụ Products, Services) → field cho footer → chọn panel hiển thị command (mặc định **Form command bar** kiểu **"Important"**) và thiết lập spreadsheet document: print without preview, **view-only table** (cấm sửa tay), **table protection** (ngoài cấm sửa còn tắt context menu và cấm copy dữ liệu).
- Wizard tạo các area: Caption, Header, ProductsHeader, Products, ServicesHeader, Services, Footer.
- Loại area: **row areas** (tên hiện bên trái số dòng, viền đỏ trên-dưới), ngoài ra có **column areas** và **cell areas**.

### FillType của cell
- **"Text"** — xuất nguyên văn.
- **"Parameter"** — text trong ngoặc nhọn (ví dụ `<Number>`, `<Responsible>`), toàn bộ ô được điền bằng code.
- **"Template"** — kết hợp: các chuỗi trong ngoặc vuông (`[DocumentNumber]`, `[DocumentDate]`) là parameter của area, phần text còn lại giữ nguyên. Ví dụ điền 12 và 15.08.2024 → "Sales invoice 12 from 15.08.2024" (format ngày phụ thuộc regional settings của infobase).

### Code do wizard sinh ra
- **Command module**: client procedure (command handler) tạo object `SpreadsheetDocument` mới → truyền vào server procedure → gọi procedure điền trong **document manager module** → về client set **ShowGrid**, **Protection**, **ReadOnly**, **ShowHeaders** (Protection và ReadOnly theo flag ở bước cuối wizard) → `SpreadsheetDocument.Show()` mở form chứa spreadsheet document (user sửa, in, preview, lưu file).
- **Manager module**: export procedure `SalesInvoice` với tham số `SpreadsheetDocument` và `Ref`.
  - `GetTemplate()` của document manager lấy template theo tên.
  - Query chỉ chọn các field đã chọn trong wizard; kết quả vào `Selection`.
  - **`GetArea()`**: theo tên, hoặc theo địa chỉ `"RmCn:RxCy"` (m/n = row/column ô đầu, x/y = row/column ô cuối). Ví dụ `GetArea("R2C2:R4C3")` → cột 2–3, dòng 2–4, tổng 6 ô. Cú pháp khác: truyền số — `GetArea(2, 2, 4, 3)`.
  - `SpreadsheetDocument.Clear()` — xoá nội dung phòng khi spreadsheet document truyền vào đã có dữ liệu.
  - Biến `InsertPageBreak` = False ban đầu để không chèn page break ở vòng lặp đầu; sau mỗi vòng = True → mỗi document bắt đầu trang mới, hỗ trợ in nhiều document (điều kiện `SalesInvoice.Ref In (&Ref)`, tham số Ref là array references user chọn).
  - **Page break**: điểm kết thúc trang này / bắt đầu trang sau ở mọi chế độ. Horizontal page break xuất bằng **`PutHorizontalPageBreak()`**; vertical page break hiếm dùng.
  - Khổ giấy đổi được từ code qua property **PageSize** (kiểu String) của spreadsheet document.
  - **`Put()`** — xuất area, luôn từ dòng mới. **`Join()`** — nối area vào dòng cuối sau cột cuối; hữu ích khi tập cột phụ thuộc điều kiện (ví dụ "Sales with discounts" vs "Sales", hoặc functional option "use discounts").
  - **`Parameters.Fill(...)`** — điền parameter của area theo các property trùng tên có trong source (selection, collection, object truy cập property qua dấu chấm). Tên không khớp (ví dụ parameter "Product" mà source chỉ có "Item") → **không được điền**.
  - Điền bằng gán trực tiếp khi cần chuẩn bị dữ liệu (presentation phức tạp của organization, số tiền bằng chữ — có method riêng trong common module).
  - Tham số thứ hai của `Put()` là **selection level** (method `Level()` của selection) làm level grouping dòng; chỉ có nghĩa khi dùng **`StartRowAutoGrouping()`** và **`EndRowAutoGroup()`**. Row autogrouping cho phép thu gọn/mở rộng nhóm dòng bằng "+"/"-".
  - Tabular sections được chọn trong query như **nested parts** → khi đọc kết quả, chúng là query result riêng → lấy bằng `Select()` hoặc `Unload()`. `Level()` của selection mới trả 0; khác 0 khi query có totals (**TOTALS BY**).
- Chọn nhiều document trong list form: Ctrl+click, Shift (từ–đến), Ctrl+A.
- Nhược điểm print form từ wizard: form mở bằng method của spreadsheet document có tiêu đề "Table"; attribute xếp dọc lãng phí chỗ; header bảng Services vẫn in khi không có dòng nào.

### Tạo print form từ đầu (không dùng wizard)
- Xoá template, command và procedure cũ; tạo export function **`PrintFormSalesInvoice`** trong manager module, tham số `PrintingObjects`, trả về spreadsheet document đã điền.
- Command **SalesInvoice**: group **"Form command bar.Important"**, command parameter type = reference tới chính document, **parameter usage mode = Multiple** (in nhiều document từ list).
- Gọi method của manager module chỉ được trên **server** (client context không biết Catalogs, Documents...) → tạo server function trong command module (một dòng return), client nhận spreadsheet document và gọi `Show()` — tham số đầu có thể là **tiêu đề cửa sổ**.
- Template **PF_SalesInvoice** kiểu "Spreadsheet document" — prefix **"PF_"** báo hiệu template dùng cho print form.
- Khuyến nghị: đặt độ rộng các cột bằng nhau, chuẩn A4 = **40 cột**; chọn cột 1–40 → "Column Width..." = **2.75**. Cột 1 và 40 thu hẹp (**0.9**) làm lề, không điền dữ liệu.
- Column width có bước tối thiểu **~0.125**; giá trị không chia hết bị làm tròn xuống (rồi làm tròn 2 chữ số thập phân). Ví dụ 0.9 → 0.88 (7×0.125 = 0.875); nhập 0.87 → 0.75.
- Sắp xếp areas theo thứ tự xuất ra print form để dễ đọc.
- **Title**: để dòng 1 trống; merge cells dòng 2 cột 2–39 (nút **"Merge cells"** trên toolbar **"Spreadsheet Document"**; mọi lệnh có trong menu **Table**); font Arial 12 bold, FillType "Template", căn giữa, text `Sales invoice No.[DocumentNumber] from [DocumentDate]`. Nếu sau khi thoát ô không thấy ngoặc nhọn → kiểm tra lại FillType.
- Đặt tên area: click số dòng → **Table - Names - Set name...**; xoá: **"Remove name"**; xem tất cả: **Table - Names - Names…**. Đổi tên: Table - Names hoặc double-click header area.
- Muốn có dòng trống giữa các area → để dòng trống trong area.
- Đổi số dòng của area bằng insert/delete rows, **trừ area 1 dòng**: dùng "split cell" (vertical) hoặc xoá area rồi tạo lại.
- **Header**: nhãn ("Company:", "Customer:") và parameter đặt ở **ô riêng**, vì font/màu áp dụng cho toàn ô → không dùng "Template" nếu muốn nhãn bold mà giá trị không bold. Parameter `<Contract>` đặt bên phải dòng customer.
- **HeaderProducts**: text tĩnh, bold, borders; thêm dòng trống trước bảng để có khoảng cách (bảng Products/Services chỉ in khi tabular section có dòng).
- **ProductsTableRow**: toàn parameters. Dùng `Fill()` → tên parameter phải trùng tên property; nên đặt trùng tên attribute của object.
- Copy area: chọn **cả dòng** (click số dòng, không phải range ô) rồi đổi tên/text.
- **Totals**: "Total:" + parameter **TotalAmount** (document đã có attribute lưu tổng → chỉ cần chọn trong query).
- **Footer**: người phụ trách, warehouse. Tránh gõ sai tên parameter: copy tên attribute từ metadata tree, hoặc kéo-thả attribute vào template (kéo-thả sẽ **phá merge** ô).
- Query đổi tên Date, Number thành **DocumentDate**, **DocumentNumber** để trùng parameter.
- Format ngày không có giờ: (1) global method **`Format()`**; (2) property **Format** của ô template. Format của ô không có tác dụng cho ô FillType "Template" (giá trị hỗn hợp).
- Format từ code **ưu tiên hơn** format của ô.
- **HorizontalAlign = "Auto"**: số căn phải, chuỗi căn trái. `Format()` trả về **String** → giá trị luôn là chuỗi → nếu căn lề quan trọng, tự đặt alignment.
- Vừa trang: margin, paper size, orientation, scale (page setup từ preview). Dùng property **FitToPage** = True của SpreadsheetDocument; form càng vượt trang thì scale càng giảm → không hợp cho form rất rộng (cân nhắc landscape).
- **PrintParametersKey** (string) lưu page parameters theo từng print form, riêng cho từng user; thường là `<tên object>_<tên print form>`. Đổi key → platform đọc thiết lập theo key mới, chưa có thì reset về mặc định.

### Working with images
- Spreadsheet document có drawings: shapes, drawing để điền text, drawing để thay ảnh, fixed picture, diagrams...
- Drawing để thay ảnh dùng cho logo, con dấu, chữ ký (phụ thuộc company, người phụ trách).
- Catalog Companies: attribute **LogoPicture** kiểu **ValueStorage**.
  - ValueStorage: lưu dữ liệu nhiều kiểu kể cả phức tạp (ảnh/binary data); không sửa trực tiếp được, chỉ ghi đè bằng value storage mới.
- Hiển thị ảnh trên form: **image field** liên kết form attribute kiểu **String** chứa địa chỉ binary data trong **temporary storage**.
  - Temporary storage: lưu bất kỳ giá trị serializable nào trong một session (ví dụ trả value table về client qua địa chỉ).
- Form attribute **LogoPictureAddress**, field type **"Image field"**, bật **"Hyperlink"**, **NonselectedPictureText** = "Add logo" (màu Light Gray), đặt trong group tiêu đề "Logo", **"TitlePosition"** tắt tiêu đề.
- **Important**: **PictureSize** = **"Proportional"** để ảnh co theo kích thước field.
- Handler event **Click** của field: tắt standard processing (nếu không sẽ mở cửa sổ hiện string của attribute), gọi **`LockFormDataForEdit()`** để khoá object company.
- **File dialog**: property **Filter** giới hạn loại file; tắt multiple selection; đặt title; mở bằng **`Show()`** với callback description. Đặt trong procedure riêng để sau chuyển sang common module được.
- Notification handler phải **Export**; tham số (xem Syntax Assistant cho `Show()` của FileDialog): **SelectedFiles** — array path nếu chọn ít nhất 1 file, **Undefined** nếu huỷ (Esc, Cancel, đóng cửa sổ); **AdditionalParameters** (Undefined nếu không truyền).
- Kiểm tra file tồn tại (file có thể bị move/rename/delete, hoặc user gõ tên): `New File(FileName)` rồi **`BeginCheckingExistence`** với callback; tham số đầu **Exist** (Boolean). FileName truyền qua AdditionalParameters của callback description.
- File tồn tại → `New BinaryData(FullFileName)` → **`PutToTemporaryStorage`** kèm **unique identifier của form** (để địa chỉ không bị xoá ở server call tiếp theo) → ghi địa chỉ vào LogoPictureAddress.
- Form attribute **LogoChanged** (Boolean) đánh dấu logo đã đổi; `Modified = True` để platform hỏi lưu khi đóng.
- Platform giới hạn truy cập attribute ValueStorage qua form data → làm việc với object thật trong form event handlers:
  - Đọc: **OnReadAtServer** — value storage chỉ có method **`Get()`**; nếu không có giá trị → Undefined; kiểm tra kiểu là **BinaryData** → đặt vào temporary storage, ghi địa chỉ.
  - Ghi: **BeforeWriteAtServer** — nếu LogoChanged → lấy binary data từ temporary storage → gán **new ValueStorage**. Tham số thứ hai của constructor là compression (compression level: **-1** mặc định, **0** không nén, **9** nén tối đa). Dữ liệu lớn nên nén tối đa để DB không phình.
- **Ảnh trong template**: tăng Title lên 4 dòng; chọn ô → **"Picture"** trên toolbar hoặc **Table - Pictures - Picture…**; không chọn ảnh, bấm OK → shape kích thước tối thiểu, kéo giãn/di chuyển. Đó là **spreadsheet document drawing**. SpreadsheetDocument có property **Drawings** (collection), dùng được cho template và cả template areas (mỗi area cũng là spreadsheet document). Đặt tên drawing **"Logo"**, "picture size" = **"Proportional"**.
- Function export trong **catalog manager module** trả binary data của logo; khi điền: kiểm tra kiểu BinaryData → `New Picture(BinaryData)` → gán vào property **Picture** của drawing.
- Bỏ khung quanh logo: property **"Line"** = "None" trong template, hoặc bằng code (xem bên dưới). Không có line thì drawing không thấy trong template tới khi chọn → đặt property **Pattern** = **"Solid"** (có thể đã active nhưng không hoạt động đúng, chọn lại) để drawing có nền trắng.

### Reports với programmatic template filling
- Nguyên tắc giống print form (spreadsheet document + template). Khác: report thường có **period** và **parameters/filters**.
  - **Parameters**: thường bắt buộc, có thể phức tạp hơn (ví dụ "show balances: only non-negative / only negative / all", "Product type: all / goods / services").
  - **Filters**: gắn trực tiếp với dữ liệu (product, counterparty, company, warehouse).
- Phải tự làm form (nút "Generate", period, parameters, filters) và thêm report vào command interface.
- Phần lớn report thực tế dùng template **"Data composition scheme"** (DCS) — bài sau.
- Ví dụ: report **SalesByCustomers** (subsystem Sales), template **Sales** kiểu SpreadsheetDocument, areas: Title, HeaderProducts, **RowCustomer**, **RowProduct** (multi-level bằng auto-grouping; dòng customer tô màu). Title dùng FillType Template.
- Form kiểu **"Report form"**: command bar có sẵn "Select option...", "Settings...", "More actions" (dùng cho DCS) → tắt **autofill** của command bar.
- Command **"Generate"** (handler client + server), nút bật **"DefaultButton"**.
- Form attribute **Result** kiểu **SpreadsheetDocument**, "TitlePosition" = "No", bật **ReadOnly**.
- Attribute **Period** kiểu **"StandardPeriod"**, **Products** kiểu **"ValueList"** với **"ValueType"** = `CatalogRef.Products`; đặt trong collapsible group "Parameters" (list items thêm như field, không phải table); bật **"ClearButton"** = "Yes".
- Khác print form: không cần `Show()` (form đã mở); filter tuỳ chọn — chỉ áp dụng khi user nhập.
- Procedure **GenerateAtServer**: `Result.Clear()` → lấy template và areas → query:
  - Tham số **FilterProducts** = `ValueIsFilled(Products)`: True → chỉ chọn record có product trong list; False → mọi record.
  - End date trống → truyền **Undefined** (virtual table trả record tới hiện tại); nếu truyền empty date thì chỉ chọn record tới 01.01.0001. Có end date → đưa về **cuối ngày**.
  - Multi-level: query **totals**, group theo customers, tính tổng field Amount.
- Điền: thực thi query → điền Title, xuất → xuất HeaderProducts → nếu không có record thì dừng → `StartRowAutoGrouping` → select theo groups (cấp 1: tổng theo customer, cấp 2: sản phẩm) → số thứ tự dạng **N.M** (biến khởi tạo trước vòng customers và trong vòng, trước vòng products) → `Put()` với level `Selection.Level()` → tăng biến số thứ tự → kết thúc autogrouping.
- Title theo period:
  - có cả start và end → "Sales by customers from []"
  - chỉ start → "Sales by customers from []"
  - chỉ end → "Sales by customers to []"
  - không có → "Sales by customers"
  - → header trở thành **parameter** điền hoàn toàn từ code.
- Loại report này **rất ít dùng**: user không đổi được cấu trúc, không tự thêm filter, không lưu report options. Chỉ dùng khi không thể dùng DCS.

## Cú pháp & ví dụ code

Ô FillType "Template":
```bsl
<Sales invoice [DocumentNumber] from [DocumentDate]>
```

```bsl
SpreadsheetDocument.Show()
```

Lấy area theo địa chỉ:
```bsl
GetArea("R2C2:R4C3")
GetArea(2, 2, 4, 3)
```

```bsl
SpreadsheetDocument.Clear()
```

```bsl
Header.Parameters.Fill(Selection)
```

```bsl
Header.Parameters.DocumentDate = Format(Selection.Date, "DLF=D")
```

Điều kiện trong query để in nhiều document:
```bsl
SalesInvoice.Ref In (&Ref)
```

```bsl
TotalAmount = TotalAmount + ProductsRow.Amount;
```

```bsl
AreaTitle.Parameters.DocumentDate = Format(Selection.DocumentDate, "DLF=DD");
```

```bsl
SpreadsheetDocument.PrintParametersKey = "SalesOfGoodsOfServices_SalesOfGoodsOfServicesWithDiscounts";
```

```bsl
BinaryData = New BinaryData(FullFileName)
```

```bsl
LogoChanged = True;

Modified = True;
```

```bsl
AreaTitle.Drawings.Logo.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
```

```bsl
Result.Clear();
```

Các method được nêu trong bài: `GetTemplate()`, `GetArea()`, `Put()`, `Join()`, `PutHorizontalPageBreak()`, `StartRowAutoGrouping()`, `EndRowAutoGroup()`, `Level()`, `Select()`, `Unload()`, `Format()`, `LockFormDataForEdit()`, `BeginCheckingExistence`, `PutToTemporaryStorage`, `Get()` (ValueStorage), `New Picture(BinaryData)`, `New File(FileName)`, `ValueIsFilled(Products)`.

[ghi chú ngoài nguồn] Code đầy đủ của command module, PrintFormSalesInvoice, file dialog, OnReadAtServer/BeforeWriteAtServer và GenerateAtServer chỉ có dạng ảnh trong tài liệu nên không chép lại. Code logo/file dialog/OnReadAtServer/BeforeWriteAtServer với ValueStorage, function CompanyLogo và command SalesInvoice/PrintFormSalesInvoice của bài → xem mục Code demo của bài Theory (nhánh lesson/17-theory). GenerateAtServer của report programmatic template → xem Thẻ gợi ý bài thực hành (bài tập 4).

## Thuộc tính/thiết lập quan trọng trong Designer
- Template type: **Spreadsheet document**, **Text document**; prefix tên **PF_**.
- Cell: **FillType** (Text / Parameter / Template), **Format**, **HorizontalAlign** (Auto).
- Column Width (2.75 cho 40 cột A4; 0.9 cho cột lề; bước 0.125).
- Command: group **Form command bar.Important**, parameter type, **parameter usage mode = Multiple**.
- SpreadsheetDocument (code): **ShowGrid**, **Protection**, **ReadOnly**, **ShowHeaders**, **PageSize**, **FitToPage**, **PrintParametersKey**, **Drawings**.
- Wizard options: print without preview, view-only table, table protection.
- Image field: **Hyperlink**, **NonselectedPictureText**, **PictureSize** = Proportional, **TitlePosition**.
- Drawing: name, picture size = **Proportional**, **Line** = None, **Pattern** = Solid.
- Catalog attribute: kiểu **ValueStorage**.
- Report form: command bar autofill (tắt), **DefaultButton**, field **ReadOnly**, **TitlePosition** = No, **ClearButton** = Yes; attribute **StandardPeriod**, **ValueList** + **ValueType**.

## Lỗi thường gặp / lưu ý
- Wizard không kiểm tra space/ký tự cấm trong tên command.
- Tên parameter của area không khớp tên property của source → `Fill()` không điền.
- Tham số level của `Put()` vô nghĩa nếu không có `StartRowAutoGrouping()`/`EndRowAutoGroup()`.
- Thoát ô mà không thấy ngoặc nhọn → FillType chưa đặt "Template".
- Area 1 dòng không thêm dòng bằng insert được → dùng split cell (vertical) hoặc tạo lại.
- Kéo-thả attribute vào template phá merge ô.
- Format của ô vô tác dụng với ô FillType "Template"; format từ code đè format của ô; `Format()` trả String → ảnh hưởng căn lề Auto.
- Column width bị làm tròn xuống theo bước 0.125.
- Print form trông vừa nhưng không vừa 1 trang khi preview → dùng FitToPage (không hợp form quá rộng).
- Đổi PrintParametersKey → page settings của user có thể reset về mặc định.
- Ảnh không lưu sau "Save and close" nếu chưa code ghi vào ValueStorage (BeforeWriteAtServer) và đọc ra (OnReadAtServer); không truy cập được ValueStorage qua form data.
- Không truyền form unique identifier khi PutToTemporaryStorage → địa chỉ có thể bị xoá ở server call kế tiếp.
- Report: truyền empty date làm end date → chỉ chọn tới 01.01.0001; dùng Undefined.
- Pattern "Solid" có thể hiển thị đã chọn nhưng không hoạt động → chọn lại.

## Điểm cần nhớ
- Print form = Template (spreadsheet document) + code: `GetTemplate` → `GetArea` → điền `Parameters` → `Put`/`Join` vào SpreadsheetDocument.
- FillType: Text / Parameter (`<...>`) / Template (`[...]` trong text).
- Hỗ trợ in nhiều document: `Ref In (&Ref)`, usage mode Multiple, page break trước mỗi document (trừ document đầu).
- Code của manager module chỉ gọi được trên server; client nhận spreadsheet document rồi `Show(title)`.
- `FitToPage` để vừa trang; `PrintParametersKey` để nhớ page settings theo user.
- Ảnh: ValueStorage trong object, temporary storage + image field trên form, đọc ở OnReadAtServer, ghi ở BeforeWriteAtServer; in bằng drawing + `New Picture(BinaryData)`.
- Report kiểu programmatic template: tự làm form, period/filter tuỳ chọn, multi-level bằng TOTALS + row autogrouping — ít dùng, ưu tiên DCS.

## Thẻ gợi ý bài thực hành (Practice 17)

Các thẻ đi theo thứ tự đề trong 17. Practice.

### Bài tập 1 — Batch FIFO/LIFO/Manually cho document Inventory transfer

- **Đề bài (tóm tắt):** Hoàn thiện batch accounting cho Inventory transfer. Thêm attribute và element còn thiếu; FIFO/LIFO tự phân bổ batch, Manually thì có nút "Pick a batch" như các document khác. Amount trong movements tính theo balance, giống Sales invoice.
- **Gợi ý 1 — Hướng đi:** Dùng lại đúng thuật toán của Sales invoice ở Practice 16 (query Balance theo batch, sắp xếp theo ngày batch, biến "còn phải xuất", `Min()`, giá đơn vị = AmountBalance / QuantityBalance). Điểm khác: mỗi lượng phân bổ là một lần **chuyển kho**, nên tạo **hai** records cùng batch và cùng giá vốn: Expense ở kho xuất, Receipt ở kho nhận.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Document InventoryTransfer: column `Batch` trong tabular section Products (Required field, bỏ khỏi `CheckedAttributes` khi không Manually, như bài 15).
  - Form: `OnCreateAtServer` ẩn/hiện cột Batch và nút; command "Pick a batch" mở lại form chọn batch của Purchase invoice, truyền **WarehouseSender** làm kho.
  - Object module, `Posting`: balance lấy theo `WarehouseSender`; 2 lần `RegisterRecords.GoodsInWarehouses.Add()` cho mỗi phần phân bổ.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm column Batch, đưa lên form, thêm command Pick batch và callback.
  2. Ẩn/hiện theo WriteOffOrder; xử lý CheckedAttributes.
  3. Posting FIFO/LIFO: copy cấu trúc vòng lặp từ Sales invoice, đổi kho, thêm record Receipt.
  4. Posting Manually: theo batch của từng dòng, giá lấy từ balance theo product + batch.
  5. Kiểm tra tồn ở kho xuất bằng procedure chung (document này không có Company, nên không truyền Company).
  ```bsl
  // trong vòng lặp phân bổ batch
  	___ // số chuyển = min(còn phải chuyển, tồn batch)
  	___ // record Expense: kho XUẤT, Batch, Quantity, Amount = số chuyển * giá đơn vị
  	___ // record Receipt: kho NHẬN, cùng Batch, cùng Quantity và Amount
  	___ // trừ "còn phải chuyển"
  ```
- **Lỗi hay gặp:**
  - Chỉ ghi Expense mà quên Receipt ở kho nhận, hoặc ngược lại.
  - Truyền nhầm kho nhận vào form chọn batch. Batch phải lấy theo tồn ở **kho xuất**.
  - Receipt ở kho nhận ghi Amount khác Expense, làm giá trị hàng thay đổi khi chỉ chuyển kho.
  - Quên AutoDelete hoặc record set rỗng, nên re-post tính trùng balance.
- **Tự kiểm tra:** Chuyển 20 hammers (tồn 5/10/15 theo batch) với FIFO: Register records có 3 cặp Expense/Receipt (5, 10, 5) cùng batch và cùng amount. Report hoặc query balance: tổng amount của hai kho không đổi so với trước khi chuyển.

### Bài tập 2 — Print form "List of goods movement" cho Inventory transfer

- **Đề bài (tóm tắt):** Tạo print form "List of goods movement" cho Inventory transfer (có thể dùng wizard), bố cục cuối cùng phải giống ảnh trong đề.
- **Gợi ý 1 — Hướng đi:** Mục "Print forms" và "Tạo print form từ đầu": template spreadsheet document với các area có tên; code `GetTemplate` → `GetArea` → điền `Parameters` → `Put` vào SpreadsheetDocument. Command ở client chỉ nhận spreadsheet document từ server rồi `Show()`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Template (prefix tên theo quy ước), các area ví dụ Title / Header / ProductsHeader / Products / Footer; cell FillType Parameter/Template.
  - Command của document: group **Form command bar.Important**, parameter type `DocumentRef.InventoryTransfer`, **parameter usage mode = Multiple**.
  - Command module: `CommandProcessing` (`&AtClient`) + function `&AtServer` một dòng gọi export function trong **manager module**.
  - Manager module: export function nhận mảng refs, trả `SpreadsheetDocument`; query lấy tabular section Products dạng nested (`Products.(...)`) hoặc query riêng.
- **Gợi ý 3 — Khung bài làm:**
  1. Chạy wizard hoặc tự tạo template; đặt tên area và parameter khớp tên field trong query.
  2. Viết function trong manager module: tạo spreadsheet, lấy template và area, query theo `Ref IN (&...)`.
  3. Vòng lặp document: page break trước mỗi document trừ document đầu; điền Title/Header; vòng lặp dòng products; Footer.
  4. Đặt `ShowGrid`/`ReadOnly`, trả kết quả.
  5. Command module gọi function và `Show("List of goods movement")`.
  ```bsl
  &AtClient
  Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
  	___ // gọi function server -> nhận spreadsheet document
  	___ // Show(<tiêu đề cửa sổ>)
  EndProcedure

  &AtServer
  Function ___(CommandParameter)
  	Return ___; // gọi export function trong manager module của document
  EndFunction
  ```
- **Lỗi hay gặp:**
  - Tên parameter của area không khớp tên field nên `Parameters.Fill()` không điền.
  - Gọi `Documents.<...>` từ client là không được, phải đi qua function `&AtServer`.
  - Quên page break hoặc dùng sai biến cờ, khiến các document dính vào nhau khi in nhiều cùng lúc.
  - Ngày in thô: dùng `Format(..., "DLF=D")`.
- **Tự kiểm tra:** Mở một Inventory transfer, bấm lệnh in: bố cục khớp ảnh trong đề (số, ngày, kho xuất/nhận, bảng dòng). Chọn 2 document trong list rồi in: mỗi document một trang.

### Bài tập 3 — Print form cho 2 documents

- **Đề bài (tóm tắt):** Trong file 17. Practice.docx, mục này chỉ có dòng tiêu đề "The print form for 2 documents:"; phần chi tiết (nhiều khả năng là ảnh mẫu) không có ở dạng văn bản. Hỏi giảng viên để biết chính xác bố cục được yêu cầu.
- **Gợi ý 1 — Hướng đi:** Dù bố cục là gì, print form phải xử lý được **nhiều document trong một lần in** (mục "Điểm cần nhớ": `Ref In (&Ref)`, usage mode Multiple, page break trước mỗi document trừ document đầu).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Như thẻ 2: command có parameter usage mode = **Multiple**; trong manager module có biến cờ page break và `PutHorizontalPageBreak()`; nếu cần vừa trang thì dùng `FitToPage`, nhớ page settings theo user bằng `PrintParametersKey`.
- **Gợi ý 3 — Khung bài làm:**
  1. Xác nhận bố cục với ảnh mẫu.
  2. Kiểm tra command cho phép chọn nhiều document.
  3. Kiểm tra vòng lặp document đặt page break đúng chỗ.
- **Lỗi hay gặp:**
  - Usage mode để Single nên chỉ in được một document.
  - Page break đặt **sau** mỗi document, làm thừa một trang trắng ở cuối.
- **Tự kiểm tra:** Chọn 2 document trong list và in: 2 trang, mỗi trang đúng một document, không có trang trắng.

### Bài tập 4 — Report "Sales by customers" 3 cấp (programmatic template)

- **Đề bài (tóm tắt):** Report 3 cấp Company → Customer → Product. Cấp 1 và 2 có tổng quantity và amount, mỗi cấp một màu, thu gọn/mở rộng được. Có period, filter nhiều giá trị theo companies, customers, products; các field có nút clear. Đưa report vào subsystem Sales.
- **Gợi ý 1 — Hướng đi:** Mục "Reports với programmatic template filling": tự làm report form với attribute `Result` (SpreadsheetDocument), period và các filter. Query trên virtual table **Turnovers** của register Sales, dùng **TOTALS BY** để có tổng theo 2 cấp. Duyệt selection theo groups và `Put(area, Level())` giữa `StartRowAutoGrouping()` và `EndRowAutoGrouping()` để thu gọn được.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Report form attributes: `Result` (SpreadsheetDocument), `Period` (StandardPeriod), 3 attribute **ValueList** có **ValueType** tương ứng; field có **ClearButton** = Yes, **TitlePosition**; command Generate làm **DefaultButton**.
  - Template của report: area tiêu đề, header cột, 3 area dòng (mỗi cấp một màu nền).
  - Procedure `&AtServer` generate. Filter tuỳ chọn trong điều kiện virtual table: list rỗng thì không lọc (ví dụ cờ Boolean `ValueIsFilled(list)` kết hợp `CASE`).
  - `QueryResultIteration.ByGroups` cho cấp tổng, `Select()` thường cho dòng chi tiết.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo report, form, template, đưa report vào subsystem Sales.
  2. Generate: `Result.Clear()`, lấy area, viết query Turnovers có filter tuỳ chọn, ORDER BY, TOTALS SUM theo Company, Customer.
  3. Đặt tham số kỳ: end date trống thì truyền **Undefined**, có giá trị thì cuối ngày.
  4. Put tiêu đề và header, bật auto grouping, 3 vòng lặp lồng, mỗi lần Put kèm Level, rồi kết thúc auto grouping.
  ```bsl
  ___ // bật row auto-grouping
  SelectionCompanies = QueryResult.Select(___);       // duyệt theo groups
  While SelectionCompanies.Next() Do
  	___ // điền area Company, Put(area, SelectionCompanies.Level())
  	// tương tự: Customer (ByGroups) -> Product (Select() thường)
  	___
  EndDo;
  ___ // kết thúc row auto-grouping
  ```
- **Lỗi hay gặp:**
  - Truyền empty date làm end date thì chỉ chọn tới 01.01.0001. Dùng Undefined.
  - Truyền tham số level cho `Put()` nhưng không bật auto grouping thì không thu gọn được.
  - [ghi chú ngoài nguồn] Tên method đúng trong platform là `EndRowAutoGrouping()`; tài liệu lý thuyết viết `EndRowAutoGroup()`.
  - Filter dùng `IN (&List)` với list rỗng sẽ không trả dòng nào. Phải có nhánh "không lọc".
- **Tự kiểm tra:** Generate không filter: 3 cấp với tổng đúng, nút +/- thu gọn được Company/Customer. Chọn 2 customer trong filter: chỉ còn các customer đó. Xoá filter bằng nút clear rồi generate lại. Đối chiếu tổng với report hoặc register Sales.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/17-theory)

### Logo của company: OnReadAtServer đọc ValueStorage, BeforeWriteAtServer ghi ValueStorage có nén

Nguồn: nhánh lesson/17-theory — cf/Catalogs/Companies/Forms/ItemForm/Ext/Form/Module.bsl

```bsl
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	BinaryData = CurrentObject.LogoPicture.Get();
	If TypeOf(BinaryData) = Type("BinaryData") Then
		LogoPictureAddress = PutToTempStorage(BinaryData, UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If LogoChanged Then
		BinaryData = GetFromTempStorage(LogoPictureAddress);
		CurrentObject.LogoPicture = New ValueStorage(BinaryData, New Deflation(9));
	EndIf;
	
EndProcedure
```

- Đọc: `CurrentObject.LogoPicture.Get()` (ValueStorage chỉ có `Get()`), kiểm tra kiểu `BinaryData` rồi `PutToTempStorage(BinaryData, UUID)` → địa chỉ gán vào form attribute `LogoPictureAddress` mà image field hiển thị.
- Ghi: chỉ khi `LogoChanged` → lấy binary data từ temporary storage, gán `New ValueStorage(BinaryData, New Deflation(9))` vào `CurrentObject` (nén tối đa, đúng khuyến nghị cho dữ liệu lớn).
- Làm việc qua `CurrentObject` trong hai form event này vì platform không cho truy cập attribute ValueStorage qua form data — đúng phần lý thuyết "Working with images".

### Chọn file logo: Click của image field → FileDialog → BeginCheckingExistence

Nguồn: nhánh lesson/17-theory — cf/Catalogs/Companies/Forms/ItemForm/Ext/Form/Module.bsl

```bsl
&AtClient
Procedure LogoPictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	AddLogoOnClientStartChoosing();
	
EndProcedure

&AtClient
Procedure AddLogoOnClientStartChoosing()
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Filter 		= "All images (*.bmp;*.png;*.jpeg;*.jpg)|*.bmp;*.png;*.jpeg;*.jpg";
	FileDialog.Multiselect 	= False;
	FileDialog.Title 		= "Select a logo image file";
	
	FileDialog.Show(New CallbackDescription("AddLogoOnClientFinishChoosing", ThisObject));

EndProcedure

&AtClient
Procedure AddLogoOnClientFinishChoosing(SelectedFiles, AdditionalParameters) Export

	If SelectedFiles = Undefined Then
		Return;
	EndIf;

	FileName = SelectedFiles[0];
	
	LogoFile = New File(FileName);
	
	CallbackDescription = New CallbackDescription(
		"AddLogoOnClientCompletion",
		ThisObject,
		New Structure("FileName", FileName)
	);
	LogoFile.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddLogoOnClientCompletion(Exist, AdditionalParameters) Export

	If Not Exist Then
		MessageText = StrTemplate(
			"File by the path '%1' doesn't exist, try to select a file once again",
			AdditionalParameters.FileName
		);
		Message(MessageText);
		Return;
	EndIf;
	
	BinaryData = New BinaryData(AdditionalParameters.FileName);
	
	LogoPictureAddress = PutToTempStorage(BinaryData, UUID);

	LogoChanged = True;
	Modified = True;
	
EndProcedure
```

- Handler `Click`: tắt standard processing (nếu không sẽ mở cửa sổ hiện string của attribute) và gọi `LockFormDataForEdit()` để khoá object company.
- File dialog đặt trong procedure riêng: `Filter` chỉ ảnh, `Multiselect = False`, `Title`, mở bằng `Show()` với `CallbackDescription`; callback `Export` nhận `SelectedFiles` (Undefined khi huỷ).
- Kiểm tra file tồn tại bằng `New File(FileName)` + `BeginCheckingExistence`, FileName truyền qua AdditionalParameters của callback description.
- Tồn tại → `New BinaryData(...)` → `PutToTempStorage(BinaryData, UUID)` (gắn unique identifier của form), rồi `LogoChanged = True` và `Modified = True` để platform hỏi lưu khi đóng.

### Logo trong print form: function trong catalog manager module + drawing "Logo"

Nguồn: nhánh lesson/17-theory — cf/Catalogs/Companies/Ext/ManagerModule.bsl; cf/Documents/SalesInvoice/Ext/ManagerModule.bsl

Catalog Companies, manager module:

```bsl
Function CompanyLogo(Company) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Companies.LogoPicture AS LogoPicture
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref = &Ref";
	
	Query.SetParameter("Ref", Company);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.LogoPicture.Get();
	Else
		Return Undefined;
	EndIf;
	
EndFunction
```

Đoạn điền area Title trong `PrintFormSalesInvoice` (document SalesInvoice, manager module):

```bsl
Function PrintFormSalesInvoice(PrintingObjects) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.ShowGrid = False;
	
	SpreadsheetDocument.PrintParametersKey = "SalesInvoice_SalesInvoice";
// ...
	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		AreaTitle.Parameters.Fill(Selection);
		AreaTitle.Parameters.DocumentDate = Format(Selection.DocumentDate, "DLF=DD");
		
		CompanyLogo = Catalogs.Companies.CompanyLogo(Selection.Company);
		If TypeOf(CompanyLogo) = Type("BinaryData") Then
			Picture = New Picture(CompanyLogo);
			AreaTitle.Drawings.Logo.Picture = Picture;
		EndIf;
		
		SpreadsheetDocument.Put(AreaTitle);
// ...
		InsertPageBreak = True;
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction
```

- `CompanyLogo()` là export function trả `LogoPicture.Get()` (binary data hoặc Undefined) — đúng gợi ý "function export trong catalog manager module" của bài.
- Kiểm tra `TypeOf(...) = Type("BinaryData")` → `New Picture(CompanyLogo)` → gán vào `AreaTitle.Drawings.Logo.Picture` (drawing đặt tên "Logo" trong template).
- Cùng function có các thiết lập của bài: `ShowGrid = False`, `PrintParametersKey = "SalesInvoice_SalesInvoice"` (dạng `<tên object>_<tên print form>`), page break trước mỗi document trừ document đầu, `FitToPage = True`.
- Dòng bỏ khung bằng code `AreaTitle.Drawings.Logo.Line = New Line(...)` không có trong nhánh (code của mục "Cú pháp & ví dụ code" vẫn là nguồn duy nhất).

### Command SalesInvoice: server function một dòng gọi PrintFormSalesInvoice

Nguồn: nhánh lesson/17-theory — cf/Documents/SalesInvoice/Commands/SalesInvoice/Ext/CommandModule.bsl

```bsl
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	SpreadsheetDocument = PrintFormSalesInvoice(CommandParameter);
	
	SpreadsheetDocument.Show("Sales invoice");
	
EndProcedure

&AtServer
Function PrintFormSalesInvoice(PrintingObjects)
	Return Documents.SalesInvoice.PrintFormSalesInvoice(PrintingObjects);
EndFunction
```

- Đúng phiên bản "tạo print form từ đầu" của bài (tên command và function trùng ảnh trong tài liệu): client gọi function `&AtServer` một dòng, nhận spreadsheet document rồi `Show("Sales invoice")` với tiêu đề cửa sổ.

## Video tham khảo (khóa Junior cũ)

Video trong playlist "Junior Developer Course" (1C Vietnam Academy, khóa cũ) có phạm vi trùng với bài này. Gọi là "video JC-<số>" (số bài của khóa cũ, khác số bài giáo trình); quy ước dẫn và độ tin cậy: `references/video-junior-course.md`.

- [JC-47 «Báo cáo dựa trên khuôn mẫu»](https://www.youtube.com/watch?v=WVqrshBBH-E&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=46) (6:34) — Bài 18 — DCS (theo mô tả của bảng gốc); nếu video nói về report điền template bằng code thì là Bài 17. Lưu ý: Tên video "báo cáo dựa trên khuôn mẫu" trùng tên Bài 17 (template-based reports) nhưng mô tả của bảng gốc là giới thiệu DCS — cần xem video để chốt.
