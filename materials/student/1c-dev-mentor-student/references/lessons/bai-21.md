# Bài 21 — Standard Subsystems Library (SSL): giới thiệu, Core, Additional reports and data processors

## Khái niệm chính

### SSL
- **Standard Subsystems Library (SSL)**: tập các functional subsystem phổ quát dùng trong configuration 1C:Enterprise để triển khai chức năng chuẩn — một "constructor" giải pháp sẵn có giúp tăng tốc và thống nhất chức năng (authorization, reports, data exchange, files, integrations...).
- Subsystem dùng được cùng nhau hoặc riêng lẻ. Hai loại theo công nghệ triển khai:
  - Subsystem **"independent functionality"**: chỉ cần chuyển chức năng sang ("implemented and forgotten"), không cần thiết lập nhiều.
  - **Integrated subsystems** ("tight integration"): chức năng dùng trong các object cụ thể của consumer configuration; phải xác định object nào, rồi thiết lập thêm, sửa code và form của object đó.
- Theo thuật ngữ 1C, SSL cũng là một configuration, nhưng không tự động hóa nghiệp vụ cụ thể mà chứa các cơ chế để mượn vào giải pháp khác.
- Khuyến nghị chỉ đưa vào các subsystem cần thiết. "Subsystems" ở đây là tập metadata object thuộc subsystem (metadata type "Subsystem"): common modules, common commands, catalogs, constants, data processors, scheduled jobs...
- Bài học dùng configuration **"Standard Subsystems Library (demo)"**, phiên bản 3.1.

### Subsystem "Core"
- Gồm common modules "Common", "CommonClient", v.v. Cung cấp procedure/function phổ quát làm việc với configuration, metadata objects, value collections...
- Ví dụ: **CommonClientServer.ValueInArray(<Value>)** — tạo array mới, đặt giá trị truyền vào và trả về array.

### Additional reports and data processors
- Cho phép:
  - kết nối external reports và data processors vào ứng dụng, tùy chỉnh hiển thị trong interface và quyền user;
  - liên kết tới object cụ thể (ví dụ để điền object);
  - dùng làm print form mới hoặc thay print form có sẵn;
  - chạy data processor theo lịch (scheduled);
  - công cụ quản trị danh sách additional reports and data processors.
- Theo mục đích: **global** (dùng chung cho configuration) hoặc **assigned** (dùng với loại object cụ thể). Assignable data processors chia 4 loại: điền object; print forms; tạo object dựa trên object khác; reports.
- Phải **đăng ký** vào infobase: reports từ file **.erf**, các loại khác từ file **.epf**.

### Yêu cầu đăng ký
- Object module phải có export function **ExternalDataProcessorInfo()** (tên giống nhau cho report và data processor), trả về structure.
- Structure khởi tạo bằng cách gọi **AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo()** (có thể truyền SSL version, không bắt buộc). Mô tả các property nằm trong khối mô tả phía trên function trong common module.
- Theo development standards, export procedure/function phải có mô tả (mục đích, parameters, return value với function). Tạo bằng: viết comment ở các dòng trước; hoặc chuột phải dòng khai báo → submenu Refactor → "Document procedure"/"Document function".
- Trong mô tả, property của Structure liệt kê sau ký hiệu "*"; property/cột lồng nhau có thêm indent và thêm "*" ("**", "***"...).

### Các property của RegistrationParameters
- **Kind** (String): PrintForm, ObjectFilling, RelatedObjectsCreation, Report, MessageTemplate, AdditionalDataProcessor, AdditionalReport. Nên điền bằng function "DataProcessorKind<KindName>" của common module **AdditionalReportsAndDataProcessorsClientServer** (ví dụ DataProcessorKindAdditionalDataProcessor()).
- **Purpose**: array tên đầy đủ metadata object mà data processor áp dụng (ví dụ "Document.PurchaseOrder", "Catalog.Products"). Không bắt buộc, nhưng với PrintForm, ObjectFilling nên điền (không dùng độc lập).
- **Version**: phiên bản (1.0; thay đổi nhỏ tăng minor 1.1, 1.2...; thay đổi lớn tăng major 2.0, 2.1...).
- **Information**: mô tả ngắn cho administrator.
- **SafeMode**: bật/tắt safe mode khi chạy; mặc định True — chỉ điền khi cần tắt.
- **Commands**: value table các command (không bắt buộc với reports). Một data processor có thể có nhiều command (ví dụ scheduled: một command điền settings, một command chạy task; PrintForm: nhiều print form command như "Commercial invoice" và "Commercial invoice with discounts").
  - **ID** — tên nội bộ command.
  - **Presentation** — tên hiển thị cho user.
  - **Use** — loại command: "ClientMethodCall", "ServerMethodCall", "FillingForm", "OpeningForm", "DataImportFromFile". Nên lấy bằng các function AdditionalReportsAndDataProcessorsClientServer.CommandType<TypeName>; mô tả các function này có template procedure xử lý command.
  - **ShowNotification** — True → khi chạy hiện thông báo "The command is running...". Áp dụng mọi loại trừ mở form (Use = "OpeningForm").
  - **Modifier** — phân loại bổ sung. Với external print forms: "PrintMXL" cho print form dựa trên table layout. Với load dữ liệu từ file: bắt buộc, chứa tên đầy đủ metadata object (catalog) được load dữ liệu.
  - **Hide** — tùy chọn; True → service command, ẩn trong card của additional object.
- **Quan trọng**: phải trả về (Return) RegistrationParameters, nếu không data processor không kết nối được.

### Đăng ký trong Enterprise mode
- Administration - Print forms, reports and data processors → đảm bảo flag "Additional reports and data processors" bật → hyperlink "Additional reports and data processors" → "Add from file…" → chấp nhận cảnh báo → chọn file.
- Tab **Commands**: danh sách command; field **"Sections"** (hyperlink "Undefined") chọn subsystem hiển thị data processor trong submenu Tools - Additional data processors.
- Tab **"Additional information"**: hiện "Information", version, type, file name, object name.
- User có quyền xem additional reports/data processors và subsystem Administration có thể chạy trực tiếp bằng nút "Run" trong item form, nhưng nên đặt vào subsystem phù hợp.
- Danh sách subsystem hiển thị chỉ gồm các subsystem liệt kê trong một số method của subsystem AdditionalReportsAndDataProcessors và data processor SSLAdministrationPanel. Thêm subsystem khác: liệt kê trong procedure **GetSectionsWithAdditionalDataProcessors()** của common module **AdditionalReportsAndDataProcessorsOverridable**.
- Common module có postfix **Overridable**: dành cho developer khác thay đổi hành vi mà không đụng object quan trọng của subsystem, giúp cập nhật library dễ hơn; các thuật toán chính nằm ở module không có postfix này.
- Cập nhật data processor đã sửa: nút **"Update from file…"** trong list form hoặc item form của catalog "additional reports and data processors".

### Mở khóa sửa object SSL (support)
- "Configuration - Support - Support options" → "Enable the ability to change" → đồng ý rằng cập nhật tự động hoàn toàn sẽ không còn → trong cửa sổ support rules bấm OK.
- Tìm object trong cửa sổ "Support options", double-click cột tên configuration → chọn rule **"Changes are allowed w/o breaking support"** → OK.
- Thêm subsystem riêng (hoặc bất kỳ metadata object không trực thuộc nào) → phải bật thay đổi cho configuration root tương tự.

### Thêm section "Sales" cho additional data processors
1. Bật thay đổi configuration root, tạo subsystem Sales.
2. Trong AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalDataProcessors(): copy một dòng, đổi sang subsystem mới.
3. Tạo common command tên theo template **"AdditionalDataProcessors<SubsystemName>"** (có thể copy từ command AdditionalDataProcessorsAdministration), đặt vào subsystem Sales, đưa vào functional option **"UseAdditionalReportsAndDataProcessors"** (cũng phải bật thay đổi trong support settings).
4. Trong command module đổi giá trị tham số cuối của procedure được gọi từ "Administration" sang "Sales".
- Nếu functional option tắt → command ẩn → subsystem Sales trống nên cũng không hiển thị (platform phân tích khi khởi động và khi gọi **RefreshInterface()**).
- Visibility mặc định cấu hình cho user ở cột **"Quick access"**; với DB không có user: trong list additional data processors của section → hyperlink **"Customize list"** → tick data processor → OK.

### Data processor loại "ObjectFilling"
- Dùng để thêm command điền một hoặc nhiều object. Các loại command:
  - Client method call
  - Server method call
  - Opening a data processor form
  - Filling a form (một object, không ghi vào DB; các loại khác ghi object đã điền vào DB)
- Chỉ có thể là assigned, không thể global. Trên form object được gán xuất hiện nút hoặc submenu **"Fill"** trên command bar.
- Chọn loại command theo thứ tự câu hỏi:
  1. Cần mở form riêng? → "OpenForm".
  2. Cần tương tác với user (hỏi, nhập giá trị) mà không cần form riêng? → "ClientMethodCall".
  3. Cần ghi object sau khi điền? Có → "server method call"; không → "FormFilling".
- Một data processor có thể chứa command nhiều loại.
- Ví dụ bài: data processor "Fill goods with balances" điền tabular section Goods của document "Goods transfer" (_DemoInventoryTransfer) theo số dư từ accumulation register "Demo: Available stock in storage locations".
- Nên điền Purpose ngay khi phát triển để user không gắn data processor vào object không phù hợp (có thể gây exception).

#### Command "ClientMethodCall"
- Data processor phải có **main form** (phải được gán là main form), trong module có **export client procedure ExecuteCommand(CommandID, RelatedObjectsArray)**. Không cần command, attribute, element khác trên form.
- Danh sách object có thể gắn assigned data processor do configuration object **"Object with additional commands"** loại **"TypeCollection"** quản lý. Phải bật thay đổi object này và thêm document vào danh sách types; sau đó "Sections" được điền tự động khi đăng ký.
- Tìm document trong interface: search by functions có ở mỗi section.
- Presentation quá dài → nút chỉ hiển thị hình, text hiện ở tooltip.
- Nhấn nút điền trên document mới chưa ghi → hộp hỏi phải ghi object trước.
- Khuyến nghị kiểm tra command ID trong ExecuteCommand dù chỉ có một command.
- Chỉ có thể lấy, sửa, ghi object theo reference ở server → truyền references sang server procedure. Từ list form một lần gọi có thể chứa nhiều reference → truyền tất cả cùng lúc để giảm server call.
- Khi ghi document: nếu đã posted → ghi ở chế độ Posting, nếu không → Write. Khuyến nghị ghi trong khối Try.
- Ghi document bằng code khi form/list đang mở: dữ liệu không được đọc lại → dùng **NotifyChanged(ObjectRef)** hoặc **NotifyChanged(Type)** để dynamic list (main table thuộc type đó) được cập nhật. Form document đang mở không được đọc lại khi gọi method này; cập nhật bằng nút Reread trong submenu "More actions".
- Từ list form có thêm bước chọn command điền.

#### Command "OpenForm"
- Data processor phải có main form; form này mở khi gọi command. Với data processor "Object filling", form phải có parameter **RelatedObjects** kiểu **Arbitrary** (array references tới object).
- Thêm 2 parameter được truyền khi mở: **CommandID** (String(0)) và **AdditionalDataProcessorRef** (CatalogRef.AdditionalReportsAndDataProcessors).
- Để parameter khả dụng trong OnOpen phải bật flag **"Key parameter"** — nếu không chúng bị xóa khỏi structure Parameters khi kết thúc sự kiện tạo form. "Key parameter" làm parameter khả dụng suốt thời gian dùng form.
- Ví dụ thêm decoration "Label" height 3 để form không quá thấp (message panel che element).
- Property **ShouldShowUserNotification** = True cho command ClientMethodCall: client nhận thông báo tùy chỉnh ở góc chương trình khi gọi command.
- Form mở full screen → đổi **WindowOpeningMode** thành "Lock owner's window".
- Đóng form khi user từ chối: đặt code đóng form trong kiểm tra form đang mở (đóng form chưa mở gây exception). Cũng phải đóng form trong handler command "FillGoods".
- Truyền parameter từ client sang server: không có từ khóa **"Val"** (truyền "by reference") → giá trị đi client→server và server→client. Một số object không trả về client được (ví dụ Array lưu trong form parameters) → exception khi trả quyền điều khiển về client. Giải pháp: thêm **Val** trước parameter của server procedure.
- Trong thực tế nên tách code trùng giữa OnOpen và ExecuteCommand thành procedure riêng.

#### Command "FormFilling"
- Điền form của object đang mở mà không ghi DB; user thấy kết quả, sửa được hoặc đóng không lưu. Có thể gọi export method của form module hoặc method nhận form làm tham số. Hạn chế: không dùng từ list form, chỉ gắn vào object form.
- Tạo **export procedure ExecuteCommand** trong **object module** với 3 parameter: **CommandID, RelatedObjects, ExecutionParameters**.
- ExecutionParameters có property **ThisForm** chứa form object đang điền; truy cập main attribute (mặc định tên **Object**) để điền như application object.
- Lỗi: đăng ký external data processor không chỉ SSL version → server procedure ExecuteCommand gọi không có parameter thứ ba ExecutionParameters → lỗi nếu parameter bắt buộc. Giải pháp: truyền SSL version trong ExternalDataProcessorInfo bằng cách gọi method từ common library module (không ghi tay) để vẫn đúng sau khi cập nhật library.
- Tip: command "form filling" không tự đặt form modification; nên đặt modification thủ công.

#### Command "Server method call"
- Tạo export procedure **ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters)** trong data processor object module (giống FormFilling).
- Thông tin cần làm cho từng loại command có trong mô tả các service procedure/function, ví dụ mô tả của **AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall()**.

## Cú pháp & ví dụ code

Cách thông thường khởi tạo array:
```bsl
ObjectNames = New Array;

ObjectNames.Add("Catalog.Warehouses");

FillingParameters.ObjectNames = ObjectNames;
```

Dùng Core:
```bsl
FillingParameters.ObjectNames = CommonClientServer.ValueInArray("Catalog.Warehouses");
```

Khai báo function đăng ký:
```bsl
Function ExternalDataProcessorInfo() Export
```

Khởi tạo structure:
```bsl
RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo();
```

Kind:
```bsl
RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
```

Purpose (khởi tạo array trong function riêng):
```bsl
RegistrationParameters.Purpose = DataProcessorPurpose();

Function DataProcessorPurpose()

    Result = New Array;

    Result.Add("Document.PurchaseOrder");

    Return Result;

EndFunction
```

Version, Information:
```bsl
RegistrationParameters.Version = "1.0";

RegistrationParameters.Information = "Data processor for product prices import from Excel file";
```

Command loại OpenForm:
```bsl
NewCommand = RegistrationParameters.Commands.Add();

NewCommand.Presentation = "Import product prices from Excel";

NewCommand.ID           = "ImportData";

NewCommand.Use          = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
```

Purpose cho ObjectFilling:
```bsl
RegistrationParameters.Purpose.Add("Document._DemoInventoryTransfer");
```

Command loại ClientMethodCall:
```bsl
NewCommand = RegistrationParameters.Commands.Add();

NewCommand.Presentation = "Fill products with balances with warning";

NewCommand.ID           = "FillProductsWithBalancesClientCall";

NewCommand.Use          = AdditionalReportsAndDataProcessorsClientServer.CommandTypeClientMethodCall();
```

Cập nhật dynamic list sau khi ghi bằng code:
```bsl
NotifyChanged(ObjectRef)

NotifyChanged(Type)

NotifyChanged(Type("DocumentLink._DemoMovementOfProducts"))
```

Chữ ký procedure xử lý command:
```bsl
// Main form module — ClientMethodCall (export client procedure)
ExecuteCommand(CommandID, RelatedObjectsArray)

// Object module — FormFilling / ServerMethodCall (export procedure)
ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters)
```

[ghi chú ngoài nguồn] Code đầy đủ của ExecuteCommand, OnOpen, handler "FillGoods", phần truyền SSL version trong tài liệu gốc là ảnh chụp màn hình, không có văn bản để chép nguyên văn. → Code demo lý thuyết đã được bổ sung từ file .epf gốc (thư mục `external/21` của repo), xem mục "Code demo lý thuyết từ file .epf gốc" ở cuối file.

## Thuộc tính/thiết lập quan trọng trong Designer
- Support: "Configuration - Support - Support options", "Enable the ability to change", rule **"Changes are allowed w/o breaking support"**.
- Common module **AdditionalReportsAndDataProcessorsOverridable** → procedure **GetSectionsWithAdditionalDataProcessors()**.
- Common command tên **AdditionalDataProcessors<SubsystemName>**; functional option **UseAdditionalReportsAndDataProcessors**.
- **"Object with additional commands"** (TypeCollection) — danh sách object gắn assigned data processor.
- Data processor: main form; form parameters **RelatedObjects** (Arbitrary), **CommandID** (String(0)), **AdditionalDataProcessorRef** (CatalogRef.AdditionalReportsAndDataProcessors), flag **"Key parameter"**.
- Form property **WindowOpeningMode** = "Lock owner's window".
- Decoration "Label" (height 3).
- Refactor → "Document procedure"/"Document function".

## Lỗi thường gặp / lưu ý
- Quên `Return RegistrationParameters` → không kết nối được data processor.
- Subsystem không xuất hiện trong danh sách "Sections" → phải thêm vào GetSectionsWithAdditionalDataProcessors().
- Document không có trong danh sách "Sections" của ObjectFilling → thêm vào TypeCollection "Object with additional commands".
- Sửa object SSL → phải bật khả năng thay đổi trong support settings; cập nhật tự động hoàn toàn sẽ không còn.
- Data processor không hiện trong list khi DB không có user → dùng "Customize list".
- Ghi object bằng code khi form mở → dữ liệu không được đọc lại; dùng NotifyChanged (form document vẫn cần Reread).
- Parameters form bị xóa sau khi tạo form nếu không bật "Key parameter".
- Đóng form chưa mở → exception.
- Truyền Array từ form parameters sang server không có Val → exception khi trả về client.
- Không truyền SSL version → ExecuteCommand ở server không nhận ExecutionParameters → lỗi.
- FormFilling không dùng được từ list form; không tự đặt modification.

## Điểm cần nhớ
- SSL là configuration chứa cơ chế phổ quát; chỉ đưa vào subsystem cần thiết; có hai loại: independent và integrated.
- Core: Common/CommonClient/CommonClientServer, ví dụ CommonClientServer.ValueInArray().
- Đăng ký additional report/data processor cần export function ExternalDataProcessorInfo() trả về RegistrationParameters.
- Property quan trọng: Kind, Purpose, Version, Information, SafeMode, Commands (ID, Presentation, Use, ShowNotification, Modifier, Hide).
- Module Overridable là nơi được phép tùy biến hành vi SSL.
- ObjectFilling chỉ assigned; 4 loại command: ClientMethodCall, ServerMethodCall, OpenForm, FormFilling — chọn theo 3 câu hỏi.
- ClientMethodCall → ExecuteCommand(CommandID, RelatedObjectsArray) trong main form; FormFilling/ServerMethodCall → ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) trong object module.
- Dùng Val khi truyền Array từ client sang server mà không cần trả về.

## Thẻ gợi ý bài thực hành (Practice 21)

Các thẻ dưới đây đi theo thứ tự đề trong 21. Practice (làm trên infobase SSL demo). Mỗi thẻ chỉ có gợi ý, không có lời giải. Các data processor là file .epf bên ngoài configuration: bạn tự viết, đăng ký, rồi kiểm tra trong Enterprise mode.

Lưu ý chung của đề: một data processor có thể chứa nhiều command, nhưng tốt nhất chỉ chứa các command cùng loại. Mọi command phải chạy không lỗi với các object được gán và không xuất hiện ở object khác. Vì vậy Purpose phải điền đúng.

### Bài tập 1 — Global data processor "Revaluation" trong subsystem mới "My projects"

- **Đề bài (tóm tắt):** Additional data processor global (Kind = AdditionalDataProcessor) trong section mới "My projects". User nhập ngày và phần trăm (âm hoặc dương), bấm "Revaluate": với mỗi product có giá trong "Demo: Product prices" **trước** ngày đó, ghi một record mới vào ngày đó với giá cũ nhân theo phần trăm. Ngày và phần trăm bắt buộc nhập.
- **Gợi ý 1 — Hướng đi:**
  - Phần đăng ký: xem "Yêu cầu đăng ký" và "Các property của RegistrationParameters".
  - Phần section: xem "Thêm section Sales cho additional data processors" và làm y hệt với subsystem MyProjects.
  - Phần logic: lấy **giá cuối cùng trước ngày** của mỗi product (virtual table SliceLast của periodic information register), rồi ghi record mới.
  - Command cần form riêng để nhập ngày và phần trăm, nên chọn loại "OpenForm".
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Configuration (bật support cho root và các object SSL cần sửa): subsystem `MyProjects`; một dòng mới trong `AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalDataProcessors()`; common command `AdditionalDataProcessorsMyProjects` (copy từ `AdditionalDataProcessorsAdministration`, đổi tham số section) đặt vào subsystem MyProjects và vào Content của functional option `UseAdditionalReportsAndDataProcessors`.
  - External data processor: object module có `ExternalDataProcessorInfo() Export`. Kind lấy từ `AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor()`, command Use = `CommandTypeOpenForm()`.
  - Main form: 2 attribute (Date, Percentage) có "Fill check", command "Revaluate".
  - Register: `InformationRegister._DemoProductsPrices` (dimension `Products`, resource `Price`, periodicity Second).
- **Gợi ý 3 — Khung bài làm:**
  1. Làm phần configuration (subsystem, Overridable, common command, FO), update DB.
  2. Tạo external data processor, viết function đăng ký, điền Kind, Version, Information, Commands.
  3. Tạo main form, attribute, command; handler client kiểm tra điền đủ rồi gọi server.
  4. Server: query SliceLast tại thời điểm **ngay trước** ngày nhập, duyệt kết quả, tính giá mới, ghi record cho ngày nhập.
  5. Đăng ký file, chọn section "My projects" ở field Sections, thêm vào "Customize list" nếu DB không có user.
  ```bsl
  &AtClient
  Procedure Revaluate(Command)
  	// kiểm tra Date và Percentage (CheckFilling hoặc kiểm tra tay) -> dừng nếu thiếu
  	___
  	RevaluateAtServer();
  EndProcedure

  &AtServer
  Procedure RevaluateAtServer()
  	// query giá cuối trước ngày; với mỗi dòng: tạo record manager, điền Period/Products/Price, ghi
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Truyền đúng ngày nhập vào SliceLast: record cùng ngày (nếu có) cũng bị lấy. Đề nói "before the specified date", nên lùi 1 giây hoặc dùng boundary loại trừ.
  - Product không có giá trước ngày (như "Ruler 15cm" trong ví dụ của đề) không được ghi record giá 0.
  - Quên `Return` structure đăng ký → không đăng ký được.
  - Section "My projects" không có trong danh sách Sections vì quên dòng trong module Overridable, hoặc common command không nằm trong FO/subsystem.
- **Tự kiểm tra:** Dùng đúng bảng ví dụ của đề (ngày 23.10.2024, -10%): register phải có thêm đúng 3 record (135; 28.8; 45). Bấm Revaluate với Date trống phải báo lỗi và không ghi gì.

### Bài tập 2 — Đổi giá theo số cho _DemoCustomerProformaInvoice (ObjectFilling)

- **Đề bài (tóm tắt):** Data processor điền object cho `_DemoCustomerProformaInvoice`: đổi Price ở mỗi dòng tabular section Goods theo số user nhập, tính lại Sum và Total của dòng. Chạy được cho nhiều document cùng lúc.
- **Gợi ý 1 — Hướng đi:** Xem "Data processor loại ObjectFilling" và 3 câu hỏi chọn loại command. Cần user nhập một số, và document phải được ghi (vì chạy cho nhiều document, kể cả từ list). Vì vậy dùng "OpenForm" (form có field nhập số) hoặc "ClientMethodCall" (hỏi số bằng dialog nhập), rồi gọi server để sửa và ghi từng document.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Kind = `DataProcessorKindObjectFilling()`, Purpose có `"Document._DemoCustomerProformaInvoice"`.
  - Với OpenForm: form parameters `RelatedObjects` (Arbitrary), `CommandID`, `AdditionalDataProcessorRef`, bật "Key parameter".
  - Tabular section `Goods` có các cột `Count`, `Price`, `Sum`, `Total`.
  - Server: lấy object theo ref (`GetObject()`), sửa, ghi theo chế độ Posting nếu document đã posted, nếu không thì Write, đặt trong Try.
  - Sau khi ghi: `NotifyChanged(...)` để list được cập nhật.
- **Gợi ý 3 — Khung bài làm:**
  1. Đăng ký: Kind, Purpose, một command (OpenForm hoặc ClientMethodCall).
  2. Client: lấy số từ user. User hủy hoặc số = 0 thì dừng.
  3. Server (nhận `Val` array refs): duyệt document, duyệt dòng Goods, đổi Price, tính lại Sum/Total, ghi.
  4. Client: gọi NotifyChanged, đóng form nếu đang mở.
  ```bsl
  &AtServerNoContext
  Procedure ChangePricesAtServer(Val Refs, Val Delta)
  	For Each DocRef In Refs Do
  		// lấy object, duyệt Goods: đổi Price, tính lại Sum và Total
  		___
  		// ghi: Posting nếu đã posted, ngược lại Write (trong Try)
  		___
  	EndDo;
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Đổi Price mà quên tính lại Sum/Total (đề bắt buộc).
  - Không có `Val` khi truyền array lấy từ form parameters → exception khi trả quyền về client.
  - Quên đưa document vào TypeCollection "Object with additional commands" → nút Fill không hiện. Trong SSL demo document này đã có sẵn, hãy kiểm tra trước.
  - Form document đang mở không tự đọc lại sau khi ghi bằng code. Dùng Reread.
- **Tự kiểm tra:** Chọn 2–3 document trong list, chạy command, nhập 10: mở từng document, Price tăng 10, Sum = Count × Price mới. Document đã posted vẫn posted.

### Bài tập 3 — Điền giá hiện hành từ register cho _DemoGoodsSales và _DemoCustomerProformaInvoice, có cảnh báo

- **Đề bài (tóm tắt):** Data processor điền object cho 2 document: điền Price ở Goods bằng giá trong "Demo: Product prices" có hiệu lực tại ngày document. Trước khi điền phải cảnh báo mất dữ liệu, user được từ chối. Chạy được cho nhiều document.
- **Gợi ý 1 — Hướng đi:** Cần hỏi user (không cần form riêng) và phải ghi object → loại "ClientMethodCall": hỏi bằng `ShowQueryBox` (không chặn, có callback). Chỉ khi user trả lời Yes mới gọi server. Ở server, giá lấy bằng SliceLast tại **ngày của từng document**, không phải ngày hiện tại.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Purpose có 2 phần tử: `"Document._DemoGoodsSales"`, `"Document._DemoCustomerProformaInvoice"`.
  - Defined type `ObjectWithAdditionalCommands`: kiểm tra `_DemoGoodsSales` đã có chưa. Nếu chưa, bật support và thêm vào.
  - Main form module: `ExecuteCommand(CommandID, RelatedObjectsArray) Export` (client), `New CallbackDescription(...)`, `ShowQueryBox`, `DialogReturnCode.Yes`.
  - Hai document có Goods khác cột (`_DemoGoodsSales` không có Sum/Total). Nếu tính lại tổng thì phải xử lý theo loại document.
- **Gợi ý 3 — Khung bài làm:**
  1. Đăng ký command ClientMethodCall với Purpose 2 document.
  2. `ExecuteCommand`: kiểm tra CommandID, lưu array refs, hiện câu hỏi.
  3. Callback: nếu không phải Yes thì Return. Nếu Yes thì gọi server với array refs.
  4. Server: với mỗi document, lấy giá theo `Date` của nó, điền Price, tính lại cột phụ thuộc nếu có, ghi.
  ```bsl
  &AtClient
  Procedure ExecuteCommand(CommandID, RelatedObjectsArray) Export
  	// kiểm tra CommandID; tạo CallbackDescription, truyền RelatedObjectsArray qua AdditionalParameters
  	___
  EndProcedure

  &AtClient
  Procedure ___Finish(Result, AdditionalParameters) Export
  	// chỉ tiếp tục khi user chọn Yes -> gọi server, rồi NotifyChanged
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Dùng `CurrentSessionDate()` thay vì ngày document.
  - Product không có giá: quyết định rõ (giữ giá cũ hay đặt 0) và nhất quán. Đề không nói, nên giữ giá cũ an toàn hơn.
  - Data processor không có main form, hoặc `ExecuteCommand` không Export → command không chạy.
  - Purpose chỉ có một document → command không hiện ở document kia.
- **Tự kiểm tra:** Trên `_DemoGoodsSales` và proforma invoice: bấm Fill, chọn No thì không đổi gì; chọn Yes thì Price khớp giá trong register tại ngày document. Thử document có ngày trước lần đổi giá gần nhất để thấy lấy đúng giá cũ.

### Bài tập 4 — Giống bài 3 nhưng FormFilling: không ghi DB, chỉ một object, không hỏi

- **Đề bài (tóm tắt):** Command điền giá như bài 3 nhưng không ghi vào DB: form object chỉ trở thành modified. Chỉ chạy cho một object và không hỏi user.
- **Gợi ý 1 — Hướng đi:** Không ghi DB và chỉ từ form object → loại "FormFilling" (xem mục "Command FormFilling"). Code ở **object module** của data processor (server), nhận form qua `ExecutionParameters.ThisForm`, sửa main attribute `Object` của form.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Command Use = `CommandTypeFormFilling()`, Purpose như bài 3.
  - Object module: `ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export`.
  - `ExternalDataProcessorInfo`: truyền SSL version bằng hàm trả version của library (ví dụ `StandardSubsystemsServer.LibraryVersion()`), không ghi tay chuỗi version.
  - Form modification: đặt thủ công (property `Modified` của form), vì FormFilling không tự đặt.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm command FormFilling (có thể chung data processor với bài 3 nếu muốn, nhưng đề khuyên command cùng loại thì chung).
  2. Trong ExecuteCommand: kiểm tra CommandID, lấy form, lấy ngày document từ `Object` của form.
  3. Duyệt dòng Goods của `Object` của form, điền Price.
  4. Đánh dấu form modified.
  ```bsl
  Procedure ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export
  	// kiểm tra CommandID
  	___
  	Form = ExecutionParameters.___;
  	// duyệt Form.Object.Goods, điền Price theo giá tại ngày Form.Object.Date
  	___
  	// đặt cờ modified cho form
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Không truyền SSL version khi đăng ký → ExecuteCommand ở server không nhận parameter thứ ba → lỗi "too few parameters".
  - Gọi `Write()` trên object: sai yêu cầu (không được ghi DB).
  - Quên đặt modified → user đóng form mà không được hỏi lưu.
  - FormFilling không dùng được từ list form, đây là đúng yêu cầu "một object".
- **Tự kiểm tra:** Mở document, chạy command: Price đổi ngay, tiêu đề form có dấu "*". Đóng form → platform hỏi lưu. Chọn No rồi mở lại thì giá cũ vẫn còn. Command không xuất hiện ở list form.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/21-23-theory)

Nhánh lesson/21-23-theory là cấu hình demo SSL (Standard Subsystems Library) dùng chung cho bài 21-23. So với cấu hình của bài trước, phần lớn object là module của SSL; phần do khóa học tự thêm/sửa cho bài 21 chỉ gồm: common command `AdditionalDataProcessorsSales`, một dòng trong `AdditionalReportsAndDataProcessorsOverridable`, functional option `UseAdditionalReportsAndDataProcessors` và subsystem `Training`. Nhánh không chứa file external data processor (.epf) nào, cũng không có function `ExternalDataProcessorInfo` hay `ExecuteCommand` do khóa học viết — các data processor đăng ký trong bài được tạo bên ngoài configuration nên không nằm trong dump.

### Thêm section cho additional data processors (Overridable module)
Nguồn: nhánh lesson/21-23-theory — cf/CommonModules/AdditionalReportsAndDataProcessorsOverridable/Ext/Module.bsl
```bsl
Procedure GetSectionsWithAdditionalDataProcessors(Sections) Export
	
	// _Demo Example Start
	Sections.Add(AdditionalReportsAndDataProcessorsClientServer.StartPageName());
	Sections.Add(Metadata.Subsystems._DemoIntegratedSubsystemsPart);
	Sections.Add(Metadata.Subsystems.Sales);
	// _Demo Example End
	
EndProcedure
```
- Code của khóa học: chỉ dòng `Sections.Add(Metadata.Subsystems.Sales);` — copy dòng có sẵn rồi đổi sang subsystem của mình (bước 2 của mục "Thêm section Sales").
- Module của SSL: `AdditionalReportsAndDataProcessorsOverridable` là module "overridable" mà SSL gọi tới khi dựng danh sách section; `AdditionalReportsAndDataProcessorsClientServer.StartPageName()` là API của SSL cho trang chủ.
- Lưu ý khi đọc dump: subsystem trong nhánh tên `Training` (synonym "Training"), không có subsystem tên `Sales`; dòng trên chỉ chạy được khi tên subsystem trùng khớp.

### Common command AdditionalDataProcessorsSales
Nguồn: nhánh lesson/21-23-theory — cf/CommonCommands/AdditionalDataProcessorsSales/Ext/CommandModule.bsl
```bsl
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm(
		CommandParameter,
		CommandExecuteParameters,
		AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor(),
		"Sales");
	
EndProcedure

#EndRegion
```
- Code của khóa học: command được copy từ `AdditionalDataProcessorsAdministration` (giữ nguyên header copyright của SSL), chỉ đổi tham số cuối từ `"Administration"` sang `"Sales"`.
- Module của SSL được gọi tới: `AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm` mở danh sách additional data processors của section; `DataProcessorKindAdditionalDataProcessor()` chọn loại.
- Tên command theo template `AdditionalDataProcessors<SubsystemName>`.

### Đưa command vào functional option và subsystem
Nguồn: nhánh lesson/21-23-theory — cf/FunctionalOptions/UseAdditionalReportsAndDataProcessors.xml
```xml
			<Location>Constant.UseAdditionalReportsAndDataProcessors</Location>
// ...
				<xr:Object>CommonCommand.AdditionalDataProcessorsAdministration</xr:Object>
				<xr:Object>CommonCommand.AdditionalReportsAdministration</xr:Object>
				<xr:Object>CommonCommand.AdditionalDataProcessorsSales</xr:Object>
			</Content>
```
Nguồn: nhánh lesson/21-23-theory — cf/Subsystems/Training.xml
```xml
			<Content>
				<xr:Item xsi:type="xr:MDObjectRef">CommonCommand.AdditionalDataProcessorsSales</xr:Item>
				<xr:Item xsi:type="xr:MDObjectRef">Document.InventoryRecount</xr:Item>
			</Content>
```
- Command mới được thêm vào Content của functional option `UseAdditionalReportsAndDataProcessors` (object của SSL, phải bật thay đổi trong support settings): constant tắt thì command ẩn, section trống cũng ẩn theo.
- Subsystem của khóa học chứa command này (và document `InventoryRecount` của bài 23) để command hiện trên command panel của section.

### Code demo lý thuyết từ file .epf gốc (thư mục external/21)

Nguồn: các file .epf giảng viên dùng khi quay phần lý thuyết bài 21, lưu trong thư mục `external/21` của repo 1CJDCourse (mỗi thư mục có file .epf gốc, `ObjectModule.bsl` và `Forms/Form/Module.bsl`). Code dưới đây chép nguyên văn. Thư mục này còn có lời giải bài thực hành (`Practice_*`); bản sinh viên của skill **không** dùng các lời giải đó — với bài thực hành chỉ dùng thẻ gợi ý ở trên.

| Data processor | Kind | Purpose | Commands (ID → Use) |
|---|---|---|---|
| Theory_ImportPricesFromExcel | AdditionalDataProcessor (global) | — | `ImportData` → OpenForm |
| Theory_FillProductsWithBalances (bản đầu) | ObjectFilling | `Document._DemoInventoryTransfer` | `FillProductsWithBalancesClientCall` → ClientMethodCall · `FillProductsWithBalancesClientOpenForm` → OpenForm · `FillProductsWithBalancesServer` → FormFilling |
| Theory_FillGoodsWithBalances_New (bản sửa) | ObjectFilling | `Document._DemoInventoryTransfer` | `FillProductsWithBalancesClientCall` → ClientMethodCall · `FillProductsWithBalancesClientOpenForm` → OpenForm · `FillProductsWithBalancesServerFormFilling` → FormFilling |

Form attribute/parameter chính (đọc từ mô tả form trong .epf): Fill goods with balances — attribute `ProductGroup`, parameters `RelatedObjects`, `CommandID`, `AdditionalDataProcessorRef`, command `FillGoods`/`FillProducts`; ImportPricesFromExcel — `Period`, `PriceType`, `SpreadsheetDocument`, `PathToFile`, commands `ReadFile`, `LoadPrices`.

#### Demo "Fill goods with balances" — bản sửa (Theory_FillGoodsWithBalances_New)

Đây là bản nên dùng khi giảng: SSL version lấy bằng hàm thư viện và command ID khớp giữa object module và form.

Object module — đăng ký 3 command và xử lý FormFilling:

Nguồn: repo 1CJDCourse — external/21/Theory_FillGoodsWithBalances_New/ObjectModule.bsl

```bsl
Function ExternalDataProcessorInfo() Export 
	
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo(
		StandardSubsystemsServer.LibraryVersion()
	);
	
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling();
	RegistrationParameters.Version 		= "1.0";
	RegistrationParameters.Information 	= "Data processor for filling products tabular section of the _DemoInventoryTransfer document";
	RegistrationParameters.Purpose.Add("Document._DemoInventoryTransfer");

	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Fill products with balances with warning";
	NewCommand.ID	      	= "FillProductsWithBalancesClientCall";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeClientMethodCall();
	NewCommand.ShouldShowUserNotification = True;
	
	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Fill products with balances with warning using filter";
	NewCommand.ID	      	= "FillProductsWithBalancesClientOpenForm";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();

	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Fill products with balances without saving";
	NewCommand.ID	      	= "FillProductsWithBalancesServerFormFilling";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeFormFilling();
	
	Return RegistrationParameters;
	
EndFunction

Procedure ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export

	If CommandID <> "FillProductsWithBalancesServerFormFilling" Then
		Return;
	EndIf;
	
	Object = ExecutionParameters.ThisForm.Object;
	
	// Work with object (the attribute of the form)
	Object.Comment = StrTemplate(
		"Written from the filling data processor in %1",
		Format(CurrentSessionDate(), "DF=HH:mm:ss")
	);
	
EndProcedure
```

- `ExternalDataProcessorInfo(StandardSubsystemsServer.LibraryVersion())`: truyền SSL version bằng hàm thư viện (không ghi tay) → server `ExecuteCommand` nhận đủ tham số `ExecutionParameters`.
- `ShouldShowUserNotification = True` gắn cho command ClientMethodCall.
- FormFilling: `ExecutionParameters.ThisForm.Object` là main attribute của form document đang mở; demo chỉ ghi `Comment`, không ghi DB. Code này **không** đặt `ThisForm.Modified = True` (xem tip "FormFilling không tự đặt modification" ở trên).

Form module — ClientMethodCall, OpenForm, ghi document ở server:

Nguồn: repo 1CJDCourse — external/21/Theory_FillGoodsWithBalances_New/Forms/Form/Module.bsl

```bsl
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjectsArray) Export
	
	If CommandID = "FillProductsWithBalancesClientCall" Then
		AdditionalParameters = New Structure("RelatedObjects", RelatedObjectsArray);
		
		ShowQueryBox(
			New CallbackDescription("FillProductsAnswer", ThisObject, AdditionalParameters),
			"Tabular section will be cleared and then filled with the goods balances. Continue?",
			QuestionDialogMode.YesNo
		);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
		
	If Parameters.CommandID = "FillProductsWithBalancesClientOpenForm" Then
		AdditionalParameters = New Structure("RelatedObjects", Parameters.RelatedObjects);
		
		ShowQueryBox(
			New CallbackDescription("FillProductsAnswer", ThisObject, AdditionalParameters),
			"Tabular section will be cleared and then filled with the goods balances. Continue?",
			QuestionDialogMode.YesNo
		);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillGoods(Command)
		
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	// Call for the server procedure of filling products
	// ...
	FillProductsWithBalancesAtServer(Parameters.RelatedObjects);

	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillProductsAnswer(Result, AdditionalParameters) Export

	If Result <> DialogReturnCode.Yes Then
		If IsOpen() Then
			Close();
		EndIf;
		Return;
	EndIf;

	FillProductsWithBalancesAtServer(AdditionalParameters.RelatedObjects);
	
	NotifyChanged(Type("DocumentRef._DemoInventoryTransfer"));
	
EndProcedure

&AtServer
Procedure FillProductsWithBalancesAtServer(Val RelatedObjects)
	
	For Each RelatedObject In RelatedObjects Do
	
		DocumentObject = RelatedObject.GetObject();
		
		// For each document get goods balances on its date
		// and fill Products tabular section with these balances
		// ...
		
		DocumentObject.Comment = StrTemplate(
			"Written from the filling data processor in %1",
			Format(CurrentSessionDate(), "DF=HH:mm:ss")
		);
		
		If DocumentObject.Posted Then
			WriteMode = DocumentWriteMode.Posting;
		Else
			WriteMode = DocumentWriteMode.Write;
		EndIf;

		DocumentObject.Write(WriteMode);		
	
	EndDo;
	
EndProcedure
```

- ClientMethodCall: SSL gọi export procedure `ExecuteCommand(CommandID, RelatedObjectsArray)` của main form (form không mở ra); câu hỏi non-modal `ShowQueryBox` + `CallbackDescription`, mảng reference truyền qua `AdditionalParameters`.
- OpenForm: form mở với `Parameters.CommandID` và `Parameters.RelatedObjects` (cần flag "Key parameter" để còn đọc được trong `OnOpen`).
- Server: `RelatedObject.GetObject()` → sửa → ghi `Posting` nếu document đã post, ngược lại `Write`. Parameter có `Val` vì mảng nằm trong form parameters không trả về client được.
- `NotifyChanged(Type("DocumentRef._DemoInventoryTransfer"))` để dynamic list cập nhật.
- [ghi chú ngoài nguồn] Phần lấy số dư chỉ là chỗ trống `// ...`; tài liệu lý thuyết nói rõ chức năng không quan trọng, demo minh hoạ cơ chế command. Muốn điền thật thì query virtual table Balance của register số dư theo ngày document (Bài 11).
- [ghi chú ngoài nguồn] Nhánh OpenForm: `OnOpen` hỏi và khi chọn Yes thì điền **ngay**, không đợi người dùng chọn `ProductGroup` rồi bấm `FillGoods` — bộ lọc trên form chưa được dùng, và form vẫn mở sau khi điền. Bản đầu tránh điều này bằng `If ThisObject.IsOpen() Then Return` trong handler câu trả lời. Nếu giảng phần "mở form để lọc", nên chỉ ra điểm này.
- [ghi chú ngoài nguồn] Ghi document không đặt trong `Try` (khác khuyến nghị ở phần lý thuyết).

#### Demo "Fill goods with balances" — bản đầu (Theory_FillProductsWithBalances)

Nguồn: repo 1CJDCourse — external/21/Theory_FillProductsWithBalances/ObjectModule.bsl

```bsl
Function ExternalDataProcessorInfo() Export 
	
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("3.1.10.386");
	
	RegistrationParameters.Kind 		= AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling();
	RegistrationParameters.Version 		= "1.0";
	RegistrationParameters.Information 	= "Data processor for filling products tabular section of the _DemoInventoryTransfer document";
	RegistrationParameters.Purpose 		= CommonClientServer.ValueInArray("Document._DemoInventoryTransfer");
	
	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Fill products with balances with warning";
	NewCommand.ID	      	= "FillProductsWithBalancesClientCall";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeClientMethodCall();
	
	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Fill products with balances with warning using filter";
	NewCommand.ID	      	= "FillProductsWithBalancesClientOpenForm";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	NewCommand.ShouldShowUserNotification = True;

	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Fill products with balances without saving";
	NewCommand.ID	      	= "FillProductsWithBalancesServer";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeFormFilling();
	
	Return RegistrationParameters;
	
EndFunction

Procedure ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export

	If CommandID <> "FillProductsWithBalancesServer" Then
		Return;
	EndIf;
	
	Object = ExecutionParameters.ThisForm.Object;
	
	// Work with object (the attribute of the form)
	Object.Goods.Add();
	
EndProcedure
```

Nguồn: repo 1CJDCourse — external/21/Theory_FillProductsWithBalances/Forms/Form/Module.bsl

```bsl
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjectsArray) Export
	
	If CommandID = "FillProductsWithBalances" Then
	
		FillProductsAfterAsking(RelatedObjectsArray);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.CommandID = "FillProductsWithBalancesWithFilter" Then
		FormWasOpen = True;
		FillProductsAfterAsking(Parameters.RelatedObjects);
	Else
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillProducts(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FillAtServer(Parameters.RelatedObjects, True);
	
	// For an additional data processor command with the "Opening form" type
	// we should notify about changes so that dynamic lists update data
	For Each ChangedObject In Parameters.RelatedObjects Do
		NotifyChanged(Parameters.RelatedObjects[0]);
	EndDo;
	
	If ThisObject.IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillProductsAfterAsking(RelatedObjects)

	AdditionalParameters = New Structure("RelatedObjects", RelatedObjects);
	
	ShowQueryBox(
		New CallbackDescription("FillProductsAnswer", ThisObject, AdditionalParameters),
		"Tabular section will be cleared and then filled with the goods balances. Continue?",
		QuestionDialogMode.YesNo
	);

EndProcedure

&AtClient
Procedure FillProductsAnswer(Result, AdditionalParameters) Export

	If Result <> DialogReturnCode.Yes Then
		If ThisObject.IsOpen() Then
			Close();
		EndIf;
		Return;
	EndIf;

	If ThisObject.IsOpen() Then
		Return;
	EndIf;
	
	FillAtServer(AdditionalParameters.RelatedObjects, False);
	
EndProcedure

&AtServer
Procedure FillAtServer(Val RelatedObjects, FilterProducts) // Показать фокус с Знач (Val)
	
	For Each RelatedObject In RelatedObjects Do
	
		DocumentObject = RelatedObject.GetObject();
		
		// For each document get goods balances on its date
		// and fill Products tabular section with these balances
		// ...
		
		If DocumentObject.Posted Then
			WriteMode = DocumentWriteMode.Posting;
		Else
			WriteMode = DocumentWriteMode.Write;
		EndIf;

		DocumentObject.Write(WriteMode);		
	
	EndDo;
	
EndProcedure
```

- SSL version ghi tay `"3.1.10.386"` — đúng cái lý thuyết khuyên tránh (cập nhật library sẽ lệch).
- `Purpose = CommonClientServer.ValueInArray(...)` — ví dụ dùng subsystem Core.
- `FormWasOpen`, `Cancel = True` trong `OnOpen` khi không phải command OpenForm, và `If ThisObject.IsOpen() Then Return` trong handler câu trả lời: khi form mở, việc điền dời sang nút `FillProducts` (sau khi người dùng chọn bộ lọc).
- [ghi chú ngoài nguồn] **Command ID lệch**: object module đăng ký `FillProductsWithBalancesClientCall` / `FillProductsWithBalancesClientOpenForm`, nhưng form kiểm tra `"FillProductsWithBalances"` / `"FillProductsWithBalancesWithFilter"` → command ClientMethodCall không làm gì, command OpenForm luôn bị `Cancel`. Bản `_New` đã sửa — có thể dùng làm bài "tìm lỗi" cho sinh viên.
- [ghi chú ngoài nguồn] Vòng `For Each ChangedObject In Parameters.RelatedObjects Do NotifyChanged(Parameters.RelatedObjects[0])` dùng phần tử đầu thay vì `ChangedObject`.
- [ghi chú ngoài nguồn] Comment tiếng Nga `// Показать фокус с Знач (Val)` = "minh hoạ mẹo với Val" — ghi chú quay bài, không phải logic.

#### Demo ImportPricesFromExcel (Kind AdditionalDataProcessor, command OpenForm)

Nguồn: repo 1CJDCourse — external/21/Theory_ImportPricesFromExcel/ObjectModule.bsl

```bsl
Function ExternalDataProcessorInfo() Export 
	
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo();
	
	RegistrationParameters.Kind 		= AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
	RegistrationParameters.Version 		= "1.0";
	RegistrationParameters.Information 	= "Data processor for product prices import from Excel file";

	NewCommand = RegistrationParameters.Commands.Add();
	NewCommand.Presentation = "Import product prices from Excel";
	NewCommand.ID	      	= "ImportData";
	NewCommand.Use 			= AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	
	Return RegistrationParameters;
	
EndFunction
```

Nguồn: repo 1CJDCourse — external/21/Theory_ImportPricesFromExcel/Forms/Form/Module.bsl

```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Period = CurrentSessionDate();
EndProcedure

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

&AtClient
Procedure FileFinishChoice(SelectedFiles, AdditionalParameters) Export

	If SelectedFiles <> Undefined Then
		PathToFile = SelectedFiles[0];
				
		BeginPutFileToServer(
			New CallbackDescription("ReadFinishPuttingFile", ThisObject),,,,
			PathToFile,
			UUID
		);	
	EndIf;	

EndProcedure

&AtClient
Procedure ReadFinishPuttingFile(PlacedFileDescription, AdditionalParameters) Export

	If PlacedFileDescription = Undefined Then
		Return;
	EndIf;
	
	ReadOnServer(PlacedFileDescription.Address, PlacedFileDescription.FileRef.Extension);	

EndProcedure

&AtServer
Procedure ReadOnServer(AddressAtTempStorage, FileExtension)
	
	BinaryData = GetFromTempStorage(AddressAtTempStorage);
	
	// Temp file
	TempFileName = GetTempFileName(FileExtension);
	BinaryData.Write(TempFileName);
	
	SpreadsheetDocument.Read(TempFileName, SpreadsheetDocumentValuesReadingMode.Value);
	
	Try
		DeleteFiles(TempFileName);
	Except
		WriteLogEvent(
			"Files.Deletion",
			EventLogLevel.Error,
			Metadata.DataProcessors.ImportPricesFromExcel,,
			DetailErrorDescription(ErrorInfo())
		);
	EndTry;
	
EndProcedure

&AtClient
Procedure LoadPrices(Command)
	LoadPricesAtServer();
EndProcedure

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
	
	// Rx - row #x, Cx - column #x
	For i = 1 To ColumnsCount Do
		ColumnNameArea = SpreadsheetDocument.Area("R1C" + i);
		ColumnName = TrimAll(ColumnNameArea.Text);
		// Searching name of excel file column at structure with column numbers
		If ColumnNumbers.Property(ColumnName) Then
			ColumnNumbers[ColumnName] = i;
		Else
			Message(StrTemplate("Column %1 with number %2 will be skipped", ColumnName, i));
		EndIf;
	EndDo;
	
	ColumnsError = False;
	For Each KeyAndValue In ColumnNumbers Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			Message(StrTemplate("Can't find column %1 in Excel file", KeyAndValue.Key));
			ColumnsError = True;
		EndIf;
	EndDo;
	
	If ColumnsError Then
		Return;
	EndIf;
	
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

- Luồng file client → server (Bài 19): `FileDialog.Show` → `BeginPutFileToServer` (đặt vào temp storage, gắn với `UUID` của form) → server `GetFromTempStorage` → ghi temp file → `SpreadsheetDocument.Read(..., SpreadsheetDocumentValuesReadingMode.Value)` → xoá temp file trong `Try`, lỗi ghi Event log.
- Dòng 1 là tiêu đề cột; tìm số cột theo tên bằng Structure `ColumnNumbers` (Product, Price), thiếu cột thì báo và dừng.
- Ghi giá bằng `InformationRegisters.ProductPrices.CreateRecordManager()` + `Write(True)` (Bài 12).
- [ghi chú ngoài nguồn] `ExternalDataProcessorInfo()` gọi **không** truyền SSL version — chấp nhận được vì command OpenForm không cần `ExecutionParameters`. `WriteLogEvent` tham chiếu `Metadata.DataProcessors.ImportPricesFromExcel`, trong khi đây là data processor ngoài (không có trong metadata của configuration) → nhánh xoá file lỗi có thể phát sinh exception; nên kiểm chứng khi chạy. Information register `ProductPrices` và catalog `Products` không phải tên object của cấu hình SSL demo (`_DemoProductsPrices`, `_DemoProducts`) — demo này chạy trên cấu hình có các object đó.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Trò chuyện với người dùng](https://www.youtube.com/watch?v=s0MHq7d_nVc&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=38) (9:26) — Bài 9 — ShowQueryBox + CallbackDescription (code mẫu); Bài 7 — dialog không chặn (CallbackDescription); Bài 21 — ShowUserNotification _(mã nội bộ JC-39)_

<!-- video-qa-thuchanh:start -->

Video giải đáp tình huống thực chiến và video thực hành từng bước liên quan tới bài này (thẻ chi tiết, triệu chứng, lưu ý khi giới thiệu: `references/video-qa-thuc-chien.md`, `references/video-thuc-hanh.md`; cùng mẫu câu dẫn ở trên):

- [Lưu bộ xử lý ngoài](https://www.youtube.com/watch?v=DTRivJSbAoI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=15) (1:40) — bộ xử lý ngoài (.epf) (giải đáp tình huống; Bài 21 liên quan) _(mã nội bộ QA-15)_

<!-- video-qa-thuchanh:end -->
