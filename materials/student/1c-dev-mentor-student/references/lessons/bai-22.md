# Bài 22 — SSL: Print subsystem

## Khái niệm chính

### Print subsystem
- Tạo print form của object dựa trên table templates (định dạng **MXL**) và template văn bản Office Open XML (**docx**).
- Cung cấp: visual editor cho table templates và DOCX templates (user sửa template có sẵn, print form được dựng theo thay đổi); công cụ đặt print commands vào submenu **"Print"**; preview print forms; lưu ra file, gửi e-mail, tạo ảnh QR code; program interface tạo print form từ template trong configuration.
- Ở Enterprise mode: gộp print forms thành bộ (set), lưu một hoặc nhiều file, gửi mail; tự động tính hàm trên các ô số được chọn (ví dụ tổng).
- Khi có nhiều print form (hơn chục), nên hiển thị trong submenu Print; hiển thị có thể phụ thuộc functional option hoặc giá trị attribute của document.
- Với Print subsystem, nhiệm vụ của developer: kết nối object vào subsystem (một lần), thêm print commands **bằng code** (không tạo metadata object loại Command) và thêm handler cho các command.

### Task trong bài
- Document "Demo: Goods receipt" (_DemoGoodsReceipt) trong SSL demo chưa có print command. Kết nối vào Print subsystem, tạo 2 command: "Goods receipt" và "Receipt at warehouse" (chỉ hiện với một số warehouse).

### Các bước kết nối
1. Chỉ định metadata object trong procedure **PrintManagementOverridable.OnDefinePrintSettings()**: bật khả năng thay đổi cho common module **PrintManagementOverridable**, thêm metadata object vào array **PrintObjects** của property **Settings**.
2. Thêm export procedure **AddPrintCommands(PrintCommands)** vào **manager module** của object, thêm dòng vào value table PrintCommands. Khuyến nghị đặt code trong service comments (xem phần code). Phải bật khả năng thay đổi manager module trong support settings.
3. Nếu thiếu, khi mở list form sẽ lỗi thiếu method **OnDefiningPrintSettings(Settings)** — method này cũng đặt trong manager module, điền property của structure Settings. Mô tả parameter Settings ở function **PrintManagement.ObjectPrintingSettings**. Để thêm print commands phải gán **OnAddPrintCommands = True**.
- Khuyến nghị theo tài liệu SSL; nếu không có tài liệu, tham khảo object đã có print form (ví dụ manager module document "Demo: Sales proforma invoice").
- Một command → nút trên command bar; từ hai command trở lên → submenu "Print".

### Các cột của bảng print commands
- **Order** (Number): ưu tiên thứ tự từ 1 đến 100, mặc định 50. Sắp xếp theo Order + presentation (thứ tự thêm dòng không ảnh hưởng). Command có order 10 lên trên command không chỉ định order.
- **FunctionalOptions** (String): danh sách functional option, phân cách bằng dấu phẩy, ảnh hưởng hiển thị command.
- **VisibilityConditions** (Array): thêm điều kiện bằng method **PrintManagement.AddCommandVisibilityCondition**. Điều kiện gồm 3 phần: tên attribute của object, giá trị so sánh, điều kiện so sánh.
- **Handler**, **PrintManager**, **Id**, **FixedSet** — xem dưới.
- Note của tác giả: tìm warehouse theo description không phải giải pháp tốt (có thể đổi tên, DB khác có thể không có) — chỉ để minh họa.

### AttachableCommands
- Để nút print hoạt động đúng, object phải kết nối với subsystem SSL khác: **AttachableCommands** (đọc tài liệu SSL, khuyến nghị khác nhau theo version).
- Trong form module của object có print command phải thêm lời gọi procedure kết nối form vào subsystem trong các event handler của form, và các attachable procedure xử lý command, đặt trong comment `// StandardSubsystems.AttachableCommands` … `// End StandardSubsystems.AttachableCommands` (tham khảo form "Demo: Sales proforma invoice").
- Gọi print command từ list form → cũng phải kết nối list form module vào AttachableCommands.
- Bài dùng Print wizard tạo template; wizard tạo command và procedure trong manager module — xóa command (không cần), giữ procedure cho "Receipt at warehouse".

### Các cách xử lý print command
1. **Không chỉ định handler và print manager**: manager module của object phải có export procedure **Print(ObjectArray, PrintParameters, PrintFormCollection, PrintObjects, OutputParameters)**.
2. **Property Handler**: client command handler thay cho handler Print chuẩn (ví dụ khi print form tạo trên client).
   - Format `<CommonModuleName>.<FunctionName>` khi đặt trong common module.
   - Format `<FunctionName>` khi đặt trong module main form của report/data processor chỉ định ở PrintManager.
   - Handler được gọi bằng **Eval()** nên chỉ **function** mới làm handler được; giá trị trả về không được dùng. Function có một parameter bắt buộc **PrintParameters** (Structure):
     - PrintObjects — Array — mảng link tới object được chọn.
     - Form — ClientApplicationForm — form gọi print command.
     - AdditionalParameters — Structure — tham số in bổ sung.
3. **Property PrintManager**: tên object có manager module chứa procedure Print tạo spreadsheet document.
   - Có thể chỉ định common module **"PrintManagement"** làm print manager → tự điền template không cần viết method; xử lý trong procedure Print của common module này. Hai điều kiện:
     1. Property ID của print command phải là đường dẫn đầy đủ tới template.
     2. Trong template mọi parameter cần điền phải đặt trong **ngoặc vuông** (vì vậy không thể nằm trong ô có filling property "Parameter").
4. **Phương pháp kết hợp**: property ID chứa nhiều print form (cùng hoặc khác nhau) cho bộ in, phân cách bằng dấu phẩy; có thể chỉ định print manager thay thế thay cho print manager chính trong PrintManager. Print form không có print manager riêng được tạo trong object ở PrintManager, nếu PrintManager trống thì trong manager module của chính object.
- **Important**: nếu PrintManager là common module PrintManagement thì không dùng được print manager khác; ID chỉ chứa đường dẫn đầy đủ tới template, không chứa tên print manager thay thế.

### Procedure Print trong manager module
- Nên đổi procedure điền spreadsheet document do print wizard tạo thành **function**, tối thiểu nhận 2 parameter:
  - **ObjectsArray** — array references tới object cần in.
  - **PrintObjects** — value list, mỗi giá trị là tên area của spreadsheet document nơi object được in.
- Function: tạo spreadsheet document, cuối cùng trả về nó; chọn dữ liệu cho array references; với mỗi document chỉ định area nó chiếm trong PrintObjects.

### Template cho print manager PrintManagement
- Ô chỉ có date và number trong title được điền vì các parameter khác chưa trong ngoặc vuông.
- Chọn mọi ô parameter, đổi property **"FillType"** từ "Parameter" sang **"Template"** (cũng có thể "Text" vì print manager tìm parameter theo text từng ô, nhưng nên dùng Template phòng khi sau này tự điền), rồi đặt parameter trong ngoặc vuông.
- Parameter của tabular section: `[TabularSectionName.ParameterName]`, ví dụ `[Goods.Price]`.

### Document set (bộ chứng từ)
- Phương pháp kết hợp dùng để in bộ chứng từ (ví dụ "Certificate of work completion" + "Invoice"). Không kết hợp được PrintManagement với print manager khác.
- Ví dụ: 3 template mới, 2 data processor (data processor 1 điền form 1, data processor 2 điền form 2 và 3). Command có 4 print form: một tạo trong manager module object, một trong data processor 1, hai trong data processor 2.
  - Cách 1: PrintManager = data processor PringGoodsReceipt2 (quản nhiều form nhất), khi đó form "WarehouseReceipt" phải ghi đường dẫn đầy đủ tới document manager.
  - Cách 2: chỉ để ID form đó, chỉ định print manager cho mọi form khác, PrintManager để trống.
- Muốn nhiều bản của một print form trong bộ → ghi nó trong ID bấy nhiêu lần.
- Property **FixedSet**: mặc định False — user thay đổi số bản từng form, thêm/bớt form khỏi bộ. True → user không đổi được thành phần bộ in.

### Tạo và sửa template
- Từ print form: sửa template và lưu vào infobase ("Edit template"), hoặc đi tới danh sách mọi template ("Go to print form templates").
- Danh sách template: icon bút chì xanh trên nền tờ giấy = template đã sửa đang dùng; nút "Use edited template" / "Use standard template". Template đã sửa nhưng dùng template chuẩn → icon đen trắng. Template đã sửa có thể xóa từ context menu hoặc submenu "More" → không còn icon.
- Để template được đánh dấu chính trong infobase được dùng khi dựng print form, phải lấy template trong code bằng **PrintManagement.PrintFormTemplate**, không dùng method có sẵn của platform **GetTemplate**.
- Danh sách template cũng mở từ "Administration - Print forms, reports and data processors" → hyperlink "Print form templates".
- User có thể tự tạo template/print command mới, tạo bởi print manager PrintManagement (không cần developer). Sau khi tạo phải bật flag hiển thị trong submenu Print; điều kiện hiển thị đặt qua biểu tượng bánh răng.
- Form print forms, reports and data processors có settings submenu Print: tắt bớt command; với external print forms có cột "External print form" với hyperlink tới additional data processor cung cấp command.

### Roles
- **EditPrintFormTemplates** — thêm và sửa print form templates.
- **OutputToPrinterFileClipboard** (thuộc subsystem "Core") — cho phép xuất print form ra máy in và gửi e-mail.
- **PrintFormsEdit** — sửa print form đã tạo trước khi gửi ra máy in hoặc e-mail, lưu ra file.

## Cú pháp & ví dụ code

Service comments cho Print subsystem:
```bsl
// StandardSubsystems.Print

…

// End StandardSubsystems.Print
```

Service comments cho AttachableCommands:
```bsl
// StandardSubsystems.AttachableCommands

…

// End StandardSubsystems.AttachableCommands
```

Chữ ký procedure trong manager module:
```bsl
AddPrintCommands(PrintCommands)

OnDefiningPrintSettings(Settings)

Print(ObjectArray, PrintParameters, PrintFormCollection, PrintObjects, OutputParameters)
```

Functional option cho command:
```bsl
PrintCommand.FunctionalOptions = "UseMultipleWarehouses"
```

PrintManager là data processor:
```bsl
PrintCommand.PrintManager = "DataProcessor.PrintPaymentInvoice";
```

ID là đường dẫn đầy đủ tới template (dùng với PrintManagement):
```bsl
PrintCommand.Id = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt";
```

Phương pháp kết hợp:
```bsl
PrintCommand.Id = "SalesInvoice,DataProcessor.PrintPaymentInvoice.PaymentInvoice"
```

Sai (PrintManagement kết hợp print manager khác):
```bsl
PrintCommand.Id = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt,DataProcessor.PrintInvoicesFromSupplier.InvoiceFromSupplier";

PrintCommand.PrintManager = "PrintManagement";
```

Đúng:
```bsl
PrintCommand.Id = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt,Document._GoodsReceipt.PF_MXL_InvoiceFromSupplier";

PrintCommand.PrintManager = "PrintManagement";
```

Parameter của tabular section trong template:
```bsl
[TabularSectionName.ParameterName]
[Goods.Price]
```

[ghi chú ngoài nguồn] Code đầy đủ của OnDefinePrintSettings, AddPrintCommands, AddCommandVisibilityCondition, procedure Print và function điền spreadsheet trong tài liệu gốc là ảnh chụp màn hình, không có văn bản để chép nguyên văn. → đã bổ sung (nhánh lesson/21-23-theory).

## Thuộc tính/thiết lập quan trọng trong Designer
- Common module **PrintManagementOverridable** → **OnDefinePrintSettings()** → `Settings.PrintObjects`.
- Structure Settings: **OnAddPrintCommands** = True.
- Cột bảng print commands: **Order**, **FunctionalOptions**, **VisibilityConditions**, **Handler**, **PrintManager**, **Id**, **FixedSet**.
- Ô template: property **FillType** ("Parameter" / "Template" / "Text").
- Roles: **EditPrintFormTemplates**, **OutputToPrinterFileClipboard**, **PrintFormsEdit**.

## Lỗi thường gặp / lưu ý
- Thiếu method OnDefiningPrintSettings(Settings) trong manager module → lỗi khi mở list form.
- Không đặt OnAddPrintCommands = True → command không hiện.
- Nút print không chạy đúng nếu object chưa kết nối AttachableCommands (cả object form lẫn list form).
- Handler chỉ có thể là function (gọi qua Eval()).
- PrintManagement: parameter không trong ngoặc vuông → không được điền; ô phải đổi FillType từ "Parameter".
- PrintManagement không kết hợp được với print manager khác trong ID.
- Template đã sửa không được dùng nếu code lấy template bằng GetTemplate thay vì PrintManagement.PrintFormTemplate.
- Tìm dữ liệu (warehouse) theo description để làm visibility condition không phải giải pháp tốt.

## Điểm cần nhớ
- Print subsystem: template MXL và DOCX, submenu Print, preview, lưu file, e-mail, QR code, user tự sửa template.
- Kết nối: PrintManagementOverridable.OnDefinePrintSettings() + AddPrintCommands(PrintCommands) + OnDefiningPrintSettings(Settings) với OnAddPrintCommands = True.
- Print commands thêm bằng code, không tạo metadata Command.
- Order (1–100, mặc định 50), FunctionalOptions, VisibilityConditions điều khiển vị trí và hiển thị.
- 4 cách xử lý: procedure Print trong manager module; Handler (function, Eval()); PrintManager; kết hợp qua Id phân cách dấu phẩy.
- PrintManagement làm print manager: Id = đường dẫn đầy đủ template, parameter trong [ngoặc vuông], không kết hợp print manager khác.
- Dùng PrintManagement.PrintFormTemplate thay GetTemplate để hỗ trợ template do user sửa.
- FixedSet = True khóa thành phần bộ in.

## Thẻ gợi ý bài thực hành (Practice 22)

Các thẻ dưới đây đi theo thứ tự đề trong 22. Practice (document "Demo: Sales order", `_DemoSalesOrder`, trong SSL demo). Mỗi thẻ chỉ có gợi ý, không có lời giải. Yêu cầu chung cho mọi print form: user phải sửa được template, nên template đặt tên với prefix `PF_MXL_` và trong code lấy template bằng `PrintManagement.PrintFormTemplate` (không dùng `GetTemplate`).

### Chuẩn bị — Kết nối _DemoSalesOrder vào Print subsystem (bước chung cho bài 1–3)

- **Đề bài (tóm tắt):** Bước chuẩn bị cho mọi print form của bài: object phải được Print subsystem nhận ra.
- **Gợi ý 1 — Hướng đi:** Xem "Các bước kết nối" và "AttachableCommands". Print command được thêm bằng code, không tạo metadata Command.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - `PrintManagementOverridable.OnDefinePrintSettings(Settings)`: thêm document vào `Settings.PrintObjects` (bật support cho common module).
  - Manager module của `_DemoSalesOrder` (bật support): `OnDefinePrintSettings(Settings) Export` với `OnAddPrintCommands = True`; `AddPrintCommands(PrintCommands) Export`; `Print(...) Export`. Đặt tất cả trong service comments `// StandardSubsystems.Print`.
  - Form document và list form: kiểm tra đã có khối `// StandardSubsystems.AttachableCommands` chưa (SSL demo thường có sẵn).
- **Gợi ý 3 — Khung bài làm:**
  1. Bật khả năng sửa cho `PrintManagementOverridable` và manager module của document.
  2. Thêm một dòng `PrintObjects` cho document.
  3. Tạo 2 procedure export trong manager module như khung dưới, phần command sẽ điền ở các bài sau.
  ```bsl
  // StandardSubsystems.Print
  Procedure OnDefinePrintSettings(Settings) Export
  	// bật cờ để SSL gọi AddPrintCommands
  	___
  EndProcedure

  Procedure AddPrintCommands(PrintCommands) Export
  	// mỗi print form: PrintCommands.Add(), điền Id, Presentation, (PrintManager), (Order)
  	___
  EndProcedure
  // End StandardSubsystems.Print
  ```
- **Lỗi hay gặp:**
  - Thiếu `OnDefinePrintSettings` trong manager module → lỗi khi mở list form.
  - Quên cờ `OnAddPrintCommands` → không có command nào.
- **Tự kiểm tra:** Mở list "Demo: Sales order" không lỗi. Sau khi thêm command ở bài 1, nút/submenu Print xuất hiện.

### Bài tập 1 — Print form "Sales order" (trong data processor PrintSalesOrder) và "Delivery order" (trong document)

- **Đề bài (tóm tắt):** Hai print form với handler tự viết (không dùng PrintManagement làm print manager): "Delivery order" xử lý trong chính document, "Sales order" xử lý trong data processor tự tạo `PrintSalesOrder`. "Sales order" phải đứng đầu submenu Print.
- **Gợi ý 1 — Hướng đi:** Xem "Các cách xử lý print command" (cách 1 và cách 3) và "Procedure Print trong manager module".
  - Command không có PrintManager → SSL gọi `Print` trong manager module của document.
  - Command có `PrintManager = "DataProcessor.PrintSalesOrder"` → SSL gọi `Print` trong manager module của data processor.
  - Thứ tự hiển thị do cột **Order** quyết định, không phải thứ tự thêm dòng.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Templates trong document: `PF_MXL_SalesOrder`, `PF_MXL_DeliveryOrder` (tạo bằng Print wizard hoặc vẽ tay, đặt area như Caption/Header...). Data processor chỉ chứa code, template vẫn có thể nằm ở document.
  - Data processor `PrintSalesOrder`: manager module có `Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export` và function điền spreadsheet.
  - SSL API: `PrintManagement.PrintFormInfo(PrintFormsCollection, "<Id>")`, `PrintManagement.PrintFormTemplate("Document._DemoSalesOrder.PF_MXL_...")`, `PrintManagement.SetDocumentPrintArea(...)`; set `TemplateSynonym`, `FullTemplatePath` để user mở "Edit template".
  - Order: giá trị nhỏ (ví dụ 1) cho "Sales order".
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo 2 template có prefix `PF_MXL_`, đặt parameter cho các field cần in (số, ngày, counterparty, địa chỉ giao hàng...).
  2. Trong `AddPrintCommands`: 2 dòng command, dòng "Sales order" có PrintManager và Order.
  3. Trong document: `Print` + function điền "Delivery order". Trong data processor: `Print` + function điền "Sales order".
  4. Function điền: query theo `Ref IN (&...)`, duyệt selection, Put từng area, ngắt trang giữa các document, gọi `SetDocumentPrintArea`.
  ```bsl
  Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
  	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "___");
  	If PrintForm <> Undefined Then
  		// gán SpreadsheetDocument = function điền của bạn; TemplateSynonym; FullTemplatePath
  		___
  	EndIf;
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Id trong `AddPrintCommands` khác Id dùng trong `PrintFormInfo` → print form trống.
  - Lấy template bằng `GetTemplate` → template user sửa không được dùng.
  - Không gọi `SetDocumentPrintArea` → in nhiều document thì chức năng gửi mail/lưu theo từng document không đúng.
  - Quên `PutHorizontalPageBreak()` giữa các document.
- **Tự kiểm tra:** Chọn 2 sales order trong list → Print → "Sales order": 2 trang, mỗi trang một document. "Sales order" đứng trên "Delivery order" trong submenu. "Edit template" mở đúng template `PF_MXL_...`.

### Bài tập 2 — "Sales order details" bằng PrintManagement, chỉ hiện với document từ 01.01.2025

- **Đề bài (tóm tắt):** Print form in mọi attribute và tabular section (trừ ContactInformation), điền hoàn toàn bởi common module PrintManagement, không viết code điền. Chỉ hiện cho document có ngày ≥ 01.01.2025. Tạo document trước và sau mốc này để kiểm tra.
- **Gợi ý 1 — Hướng đi:** Xem "Template cho print manager PrintManagement" và cột VisibilityConditions. PrintManagement tự điền khi Id là **đường dẫn đầy đủ tới template** và mọi parameter trong template viết trong **ngoặc vuông**. Điều kiện hiện thêm bằng `PrintManagement.AddCommandVisibilityCondition` (tên attribute, giá trị, `ComparisonType`).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Template `PF_MXL_SalesOrderDetails` trong document. Ô parameter: FillType = "Template", text dạng `[AttributeName]`. Cột tabular section dạng `[TabularSectionName.AttributeName]`.
  - Command: `Id = "Document._DemoSalesOrder.PF_MXL_SalesOrderDetails"`, `PrintManager = "PrintManagement"`.
  - Điều kiện: attribute `"Date"`, giá trị `Date(2025, 1, 1)`, phép so sánh "lớn hơn hoặc bằng".
- **Gợi ý 3 — Khung bài làm:**
  1. Xem danh sách attribute và tabular section của document trong Designer (bỏ ContactInformation).
  2. Vẽ template: header là các attribute, mỗi tabular section một area hàng tiêu đề và một area dòng.
  3. Đổi FillType của mọi ô parameter sang Template và bọc tên trong `[...]`.
  4. Thêm command và gắn điều kiện hiện vào **chính command này** (biến command vừa Add).
- **Lỗi hay gặp:**
  - Ô vẫn để FillType = "Parameter" → PrintManagement không điền.
  - Gắn visibility condition nhầm command. [ghi chú ngoài nguồn] Trong bản lời giải mẫu của khóa, điều kiện ngày lại gắn vào command "Delivery order" thay vì "Sales order details". Đề yêu cầu điều kiện cho "Sales order details", đừng lặp lại lỗi này.
  - Trộn PrintManagement với print manager khác trong cùng Id → không chạy (xem mục "Important").
- **Tự kiểm tra:** Document ngày 2024: submenu Print không có "Sales order details". Document ngày 2025: có, và in ra đủ attribute cùng các dòng tabular section.

### Bài tập 3 — "Document set": 2 bản "Sales order" + 1 bản "Delivery order"

- **Đề bài (tóm tắt):** Print form bộ gồm 2 bản "Sales order" và 1 bản "Delivery order".
- **Gợi ý 1 — Hướng đi:** Xem "Document set" và "Phương pháp kết hợp". Id chứa nhiều print form phân cách bằng dấu phẩy. Muốn in 2 bản thì ghi Id đó 2 lần. Form có print manager khác ghi dạng `<PrintManager>.<Id>`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Một dòng command mới trong `AddPrintCommands`. Id ghép từ: Id "Sales order" kèm tên data processor (2 lần) và Id "Delivery order" (form của chính document, không cần tiền tố nếu PrintManager để trống).
  - Có thể dựng Id bằng array + `StrConcat(..., ",")` cho dễ đọc.
  - Tùy chọn: `FixedSet` (khóa thành phần bộ), `Order` lớn để đứng cuối.
- **Gợi ý 3 — Khung bài làm:**
  1. Xác định 2 phần tử Id: một cho form trong data processor, một cho form trong document.
  2. Ghép thành chuỗi theo thứ tự: Sales order, Sales order, Delivery order.
  3. Thêm command "Document set", để PrintManager trống.
- **Lỗi hay gặp:**
  - Đặt `PrintManager = "PrintManagement"` cho bộ này → không kết hợp được với handler tự viết.
  - Thiếu tiền tố `DataProcessor.PrintSalesOrder.` cho form "Sales order" → SSL tìm form trong document và không thấy.
- **Tự kiểm tra:** In "Document set": preview có 2 trang Sales order và 1 trang Delivery order. Nếu không bật FixedSet, thử đổi số bản trong form preview.

### Bài tập 4 (bổ sung) — External print form "Sales order (external)"

- **Đề bài (tóm tắt):** External print form lặp lại print form "Sales order" (dùng lại template và handler), chỉ khác tiêu đề có thêm "(External)". Đăng ký vào hệ thống, gắn với "Demo: Sales order", kiểm tra.
- **Gợi ý 1 — Hướng đi:** Kết hợp bài 21 (đăng ký additional data processor) với bài này: Kind = PrintForm, Purpose = document. Gợi ý của đề: khi dùng server command, external print form phải có export procedure `Print()` trong **object module**, cùng bộ parameter như `ExecuteCommand` của data processor loại "FillingObject".
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Object module của .epf: `ExternalDataProcessorInfo() Export` với Kind = `DataProcessorKindPrintForm()`, Purpose có `"Document._DemoSalesOrder"`, command Use = `CommandTypeServerMethodCall()`, Modifier = `"PrintMXL"`.
  - Procedure `Print` export trong object module. Bộ parameter lấy đúng theo gợi ý của đề, đối chiếu với mô tả của `AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall()` và tài liệu SSL của version bạn dùng. Dùng lại logic điền và template "Sales order" (copy template vào data processor ngoài).
  - Tiêu đề: thêm "(External)" vào area/parameter tiêu đề.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo external data processor, copy template Sales order vào và sửa tiêu đề.
  2. Viết function đăng ký (Kind, Purpose, Version, command với Modifier PrintMXL).
  3. Viết `Print` export trong object module, gọi function điền tương tự bài 1.
  4. Đăng ký trong Administration → Print forms, reports and data processors, kiểm tra Sections/Purpose.
- **Lỗi hay gặp:**
  - Đặt `Print` ở manager module: đề yêu cầu object module.
  - Quên Modifier `"PrintMXL"` cho print form dựa trên table template.
  - Vẫn lấy template theo đường dẫn của document: khi đó bạn không dùng template trong file ngoài, và tiêu đề "(External)" không xuất hiện.
- **Tự kiểm tra:** Sau khi đăng ký, submenu Print của sales order có "Sales order (external)", tiêu đề in ra có "(External)". Danh sách print form trong Administration hiện hyperlink "External print form".

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/21-23-theory)

Trong nhánh lesson/21-23-theory, phần code của khóa học cho bài 22 nằm ở: manager module của document `_DemoGoodsReceipt` (thêm khối `// StandardSubsystems.Print`), một dòng trong `PrintManagementOverridable`, và hai data processor mới `PrintGoodsReceipt1`, `PrintGoodsReceipt2` cho document set. Các lời gọi `PrintManagement.*` là module của SSL (Standard Subsystems Library).

### Kết nối object vào Print subsystem (PrintManagementOverridable.OnDefinePrintSettings)
Nguồn: nhánh lesson/21-23-theory — cf/CommonModules/PrintManagementOverridable/Ext/Module.bsl
```bsl
Procedure OnDefinePrintSettings(Settings) Export
// ...
	// _Demo Example End
	
	Settings.PrintObjects.Add(Documents._DemoGoodsReceipt);

EndProcedure
```
- Code của khóa học: chỉ dòng `Settings.PrintObjects.Add(Documents._DemoGoodsReceipt);`, đặt sau khối `// _Demo Example` có sẵn.
- Module của SSL: `PrintManagementOverridable` là module overridable phải bật khả năng thay đổi trong support settings trước khi sửa.

### OnDefinePrintSettings và AddPrintCommands trong manager module
Nguồn: nhánh lesson/21-23-theory — cf/Documents/_DemoGoodsReceipt/Ext/ManagerModule.bsl
```bsl
// StandardSubsystems.Print

// Overrides object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure
// ...
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt";
	PrintCommand.Presentation = NStr("en = 'Goods receipt';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.PrintManager = "PrintManagement";

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "WarehouseReceipt";
	PrintCommand.Presentation = NStr("en = 'Receipt at warehouse';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 10;

	Warehouse = Catalogs._DemoStorageLocations.FindByDescription("Storage #1", True);
	If ValueIsFilled(Warehouse) Then
		PrintManagement.AddCommandVisibilityCondition(
			PrintCommand,
			"StorageLocation",
			Warehouse,
			ComparisonType.Equal
		);
	EndIf;
	
	// Document set.
	CommandsID = New Array;
	CommandsID.Add("WarehouseReceipt");
	CommandsID.Add("WarehouseReceipt");
	CommandsID.Add("DataProcessor.PrintGoodsReceipt1.GoodsReceipt1");
	CommandsID.Add("DataProcessor.PrintGoodsReceipt2.GoodsReceipt2");
	CommandsID.Add("DataProcessor.PrintGoodsReceipt2.GoodsReceipt3");
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = StrConcat(CommandsID, ",");
	PrintCommand.Presentation = NStr("en = 'Document set';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.FixedSet = True;
	PrintCommand.Order = 75;
// ...
EndProcedure
```
- Code của khóa học: toàn bộ hai procedure, đặt trong service comments `// StandardSubsystems.Print`; `Settings.OnAddPrintCommands = True` là điều kiện để SSL gọi `AddPrintCommands`.
- Command 1 dùng print manager `"PrintManagement"` nên `Id` là đường dẫn đầy đủ tới template; command "WarehouseReceipt" không có PrintManager → SSL gọi procedure `Print` của chính manager module này.
- `PrintManagement.AddCommandVisibilityCondition(PrintCommand, "StorageLocation", Warehouse, ComparisonType.Equal)` là API của SSL; tìm warehouse theo description chỉ để minh họa (như note của tác giả).
- "Document set": `Id` ghép nhiều print form bằng `StrConcat(CommandsID, ",")`, "WarehouseReceipt" lặp hai lần → in hai bản; `FixedSet = True`. (Trong file còn command "Document set 2" dùng PrintManagement, Id chỉ chứa đường dẫn template, không trộn print manager khác — đã lược.)

### Procedure Print và function điền spreadsheet
Nguồn: nhánh lesson/21-23-theory — cf/Documents/_DemoGoodsReceipt/Ext/ManagerModule.bsl
```bsl
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// Print a warehouse receipt
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "WarehouseReceipt");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = PrintWarehouseReceipt(ObjectsArray, PrintObjects);
		PrintForm.TemplateSynonym = NStr("en = 'Warehouse receipt'");
		PrintForm.FullTemplatePath = "Document._DemoGoodsReceipt.PF_MXL_WarehouseReceipt";
	EndIf;
	
EndProcedure

Function PrintWarehouseReceipt(RefsToObjects, PrintObjects)

	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintParameters_DemoGoodsReceiptWarehouseReceipt";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoGoodsReceipt.PF_MXL_WarehouseReceipt");
	
	Query = New Query;
	Query.Text =
// ...
	|	_DemoGoodsReceipt.Ref IN (&Refs)";
	
	Query.Parameters.Insert("Refs", RefsToObjects);
	
	Selection = Query.Execute().Select();

	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	AreaGoodsHeader = Template.GetArea("GoodsHeader");
	AreaGoods = Template.GetArea("Goods");
	Footer = Template.GetArea("Footer");

	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		RowNumberStart = Spreadsheet.TableHeight + 1;

		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());

		Spreadsheet.Put(AreaGoodsHeader);
		SelectionGoods = Selection.Goods.Select();
		While SelectionGoods.Next() Do
			AreaGoods.Parameters.Fill(SelectionGoods);
			Spreadsheet.Put(AreaGoods, SelectionGoods.Level());
		EndDo;

		Footer.Parameters.Fill(Selection);
		Spreadsheet.Put(Footer);

		InsertPageBreak = True;
		
		PrintManagement.SetDocumentPrintArea(Spreadsheet, RowNumberStart, PrintObjects, Selection.Ref);
	EndDo;

	Return Spreadsheet;
	
EndFunction
```
- Code của khóa học: procedure `Print` và function `PrintWarehouseReceipt(RefsToObjects, PrintObjects)` (procedure do print wizard tạo được đổi thành function nhận hai parameter rồi trả về spreadsheet).
- Module của SSL được gọi tới: `PrintManagement.PrintFormInfo` lấy dòng print form theo ID; `PrintManagement.PrintFormTemplate` lấy template (dùng template đã sửa trong infobase nếu có, khác `GetTemplate`); `PrintManagement.SetDocumentPrintArea` ghi area của từng document vào `PrintObjects`.
- `FullTemplatePath` cho phép user mở "Edit template" từ print form.

### Print manager là data processor (document set)
Nguồn: nhánh lesson/21-23-theory — cf/DataProcessors/PrintGoodsReceipt2/Ext/ManagerModule.bsl
```bsl
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "GoodsReceipt2");
	If PrintForm <> Undefined Then
		TemplateSynonym = "Goods receipt 2";
		PrintForm.SpreadsheetDocument = PrintGoodsReceipt(
			ObjectsArray,
			PrintObjects,
			"PF_MXL_GoodsReceipt2", 
			TemplateSynonym
		);
		PrintForm.TemplateSynonym = TemplateSynonym;
		PrintForm.FullTemplatePath = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt2";
	EndIf;

// ...
EndProcedure
```
- Code của khóa học: data processor `PrintGoodsReceipt2` quản hai print form "GoodsReceipt2" và "GoodsReceipt3" (khối "GoodsReceipt3" lặp y hệt, đã lược) (cùng function `PrintGoodsReceipt` trong module, khác template; function này giống phần điền Caption + `SetDocumentPrintArea` ở trên nên đã lược); `PrintGoodsReceipt1` có cấu trúc giống hệt cho "GoodsReceipt1".
- Trong `AddPrintCommands` các form này được gọi dạng `DataProcessor.PrintGoodsReceipt2.GoodsReceipt2` — tên print manager thay thế + ID print form.
- Template vẫn nằm trong document `_DemoGoodsReceipt` (`PF_MXL_GoodsReceipt1..3`), data processor chỉ chứa code điền.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

Không có video tương ứng — chỉ dẫn tài liệu Theory/Practice của bài.
