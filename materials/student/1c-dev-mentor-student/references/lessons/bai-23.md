# Bài 23 — SSL: Làm việc với file (FileSystem, FilesOperations) và Module markup

## Khái niệm chính

### Các kịch bản làm việc với file
- Mở file từ file system, sửa, lưu.
- Lưu dữ liệu file trong hệ thống (hoặc storage riêng), gồm đính kèm file vào object (ví dụ ảnh hàng lỗi đính kèm document nhận hàng).
- Làm việc với file lưu trong hệ thống: xem, versioning, sửa tuần tự (một user sửa thì người khác không sửa được).
- Các cơ chế nằm ở các subsystem khác nhau:
  - Làm việc với file trong file system: common modules **FileSystem** thuộc subsystem **"Core"**.
  - File lưu trong hệ thống/storage riêng, đính kèm vào object: subsystem riêng **"FilesOperations"**.

### File system (FileSystemClient / FileSystem)
- Các method hữu ích: chọn file và đặt binary data vào temporary storage, mở thư mục trong Explorer, mở URL bằng ứng dụng mặc định, v.v.
- Ví dụ bài: document mới **"Inventory recount"** với attributes "Warehouse", "EmployeeResponsible", "Comment" và tabular section "Goods" (attributes "Product", "Quantity", "QuantityFact"); subsystem "Sales" đổi tên thành "Training".
- Command "Import data from file" (client handler) gọi procedure **ImportFile_()** của common module **FileSystemClient**: truyền object kiểu **CallbackDescription** chỉ procedure gọi khi chọn file xong; tùy chọn truyền tham số filter lấy bằng **FileSystemClient.FileImportParameters**.
- Ưu điểm method library: xử lý web client (một số browser cần extension làm việc với file) — kiểm tra loại client và kết nối/từ chối file extension; xử lý trường hợp file đang bận hoặc không tồn tại.
- Ví dụ attribute **FileFullName** (đường dẫn file) và **FileURL** (link Internet), form attribute **"FileType"** dạng radio buttons chuyển giữa các trang:
  - Nút open của FileFullName: kiểm tra đã điền rồi gọi **OpenFile** của FileSystemClient, nếu chưa điền thì báo lỗi. Command "Show in Explorer" cùng logic.
  - Nút open của FileURL: gọi **OpenURL**.
- Thông báo user: **CommonClient.MessageToUser()** (dùng object kiểu MessageToUser); có thể nhận parameter **Cancel** để đặt True khi gọi từ handler có parameter đó. Phía server: **Common.MessageToUser()**.
- **OpenURL** hoạt động với public link, link chat messenger, link gửi email, navigation link tới object 1C, link 1C help... — mở theo tương ứng ứng dụng/protocol của hệ thống.
- Kiểm tra link hợp lệ theo phần đầu chuỗi bằng function **IsAllowedRef()**; bỏ phần đầu → báo lỗi.
- Server common module **FileSystem** có ít public method, chủ yếu làm việc với temporary files/directories.

### Files operations (FilesOperations)
- Trong thực tế, file đính kèm object lưu dưới dạng **attached files**.
- 3 cách lưu:
  1. Mỗi object "owner" có catalog riêng **"<ObjectName>AttachedFiles"** (ví dụ "InventoryRecountAttachedFiles") — khi quyền truy cập các owner khác nhau. Thường phù hợp nhất.
  2. Một catalog chung cho nhiều owner — khi ít owner (không quá 10), quyền trùng hoàn toàn và không định thay đổi.
  3. Mọi file trong catalog **Files** có sẵn của FilesOperations — cho configuration đơn giản.
- **File versioning chỉ có với file trong catalog "Files"**; catalog "<OwnerName>AttachedFiles" chỉ luôn có một version (mới nhất). Đôi khi kết hợp các cách trong một configuration.

### Các bước kết nối document InventoryRecount vào FilesOperations
1. Tạo catalog lưu attached files (có thể copy **_DemoProjectsAttachedFiles** trong demo): tên "InventoryRecountAttachedFiles", synonym "Attached files (Inventory recount)". **Important**: nhớ bỏ quyền interactive deletion của object mới khỏi role FullAccess!
2. Đặt link tới document "InventoryRecount" làm kiểu attribute **"FileOwner"** của catalog.
3. Quyết định có tạo group (folder) không: bật **"Hierarchical catalog"**, hierarchy type **"Folder and item hierarchy"**; đổi property **Use** thành **"For folder and item"** cho attributes Author, FileOwner, UniversalModificationDate, CreationDate, ChangedBy, PictureIndex, LongDesc. Nếu không cần group mà catalog copy đã hierarchical → tắt property này.
4. Nếu catalog chứa file service cần ẩn với user → thêm attribute **"Service"** kiểu Boolean.
5. Đưa catalog vào defined types **"AttachedFile"** (links) và **"AttachedFileObject"** (objects) (phải bật khả năng thay đổi trong support options).
6. Đưa catalog vào exchange plan **InfobaseUpdate**.
7. Tạo event subscriptions: catalog file trong types của property **"Source"** của một subscription (ví dụ CatalogManager.InventoryRecountAttachedFiles), object owner trong subscription còn lại (ví dụ DocumentObject.InventoryRecount). Ví dụ trong demo: "_DemoDetermineAttachedFileForm" và "_DemoSetDeletionMarkForAttachedDocumentFiles". Nếu sửa giải pháp chuẩn, các subscription này có thể đã có sẵn.

| Subscription | Event | Handler |
| --- | --- | --- |
| DetermineAttachedFileForm | FormGetProcessing | FilesOperationsClientServer.DetermineAttachedFileForm |
| SetDeletionMarkForAttachedDocumentFiles | BeforeWrite | FilesOperations.SetDeletionMarkForAttachedDocumentFiles |

8. Đưa link tới object có attached files (DocumentRef.InventoryRecount) vào defined type **"AttachedFilesOwner"**.
9. Nếu object không phải document → thêm type (object, không phải link) vào defined type **"AttachedFilesOwnerObject"**.

### Làm việc với attached files trong Enterprise mode
- Document có hyperlink tới attachments. Form attachments: thêm file theo đường dẫn, từ template, từ scanner; nút view, edit, commit, print; thêm nút trong "More actions".
- "Add local file" → dòng file có icon phần mở rộng.
- Double-click/Enter → form "Open file" với "Read-only" (= nút "View") và "Editing" (= nút "Edit"), flag "Do not ask again".
- "Edit": thông báo file bị khóa để sửa, mở bằng ứng dụng liên kết, text trong list chuyển xanh. Chỉ một user sửa tại một thời điểm; người khác xem version mới nhất.
- "Finish": file không thay đổi → không tạo version mới, mở khóa. File có sửa → "Commit", ngày sửa cập nhật.
- File card: F2 hoặc "More actions" → "Open card".
- "Undo edits": hủy khóa; nếu file đã sửa thì khi mở xem sẽ cảnh báo bản local khác bản đã lưu, cho chọn mở từ local copy hoặc từ application.
- "Save changes": cập nhật version nhưng không mở khóa. Có nút khóa file mà không mở.

### Tích hợp vào form document
- **OnCreateAtServer**: gọi **FilesOperations.OnCreateAtServer** với dữ liệu chuẩn bị sẵn. Muốn hyperlink "Attachments" trên command bar: gọi **FilesOperations.FilesHyperlink()**, đặt property **"Location"** = tên group (ở đây command bar).
- Hyperlink hiển thị số file đính kèm.
- Tắt hyperlink "Attachments" ở phần "Go to": bỏ mọi flag trong command interface của form cho command **AttachedFiles**.
- **OnOpen**: gọi FilesOperationsClient.OnOpen — đổi visibility nút scan nếu scan không khả dụng (như Web-client).
- **OnWriteAtServer**: gọi FilesOperations.OnWriteAtServer.
- **NotificationProcessing**: gọi FilesOperationsClient.NotificationProcessing.
- Thêm attachable command handlers (copy từ document "_DemoSalesOrder").
- Nếu copy event handler procedure → phải liên kết event với handler trong properties palette hoặc danh sách procedure của form module; nếu không procedure không hoạt động như handler.

### Module Markup (Region)
- Dùng **module regions** để tách procedure/function theo loại và ý nghĩa (form handlers, form element handlers...).
- Region có thể collapse/expand. **Ctrl + Shift + Num-** / **Ctrl + Shift + Num+** thu gọn/mở rộng mọi "node" trong module; cũng hoạt động trong reports và mọi cấu trúc cây trong 1C (ví dụ list hierarchical catalog ở view mode "Tree").
- Danh sách region khuyến nghị cho từng loại module do 1C development standards quy định. Trong region cấp cao có thể tạo region riêng với tên bất kỳ; region có thể tạo bên trong procedure/function.
- Tên region viết không có dấu cách.

### Biểu tượng kẹp giấy trong list form
- 2 thay đổi:
  1. Trong query của dynamic list thêm field **HasFiles**: 0 nếu không có file, 1 nếu có.
  2. Thêm field vào form table, loại **"Image field"**, tắt title, property **"ValuesPicture"** = picture **"ClipCollection"** (gồm 2 hình: rỗng cho 0 và kẹp giấy cho 1); property **"HeaderPicture"** = picture **"Clip"**.
- Thực hiện: tạo list form, bật flag **"CustomQuery"** cho dynamic list "List", thêm join tới information register **"FilesExist"** trong query text.

### Các method hữu ích khác
- **FillFilesAttachedToObject()**: truyền reference owner và array để nhận references tới attached files.
- **FileData()** của common module FilesOperations: trả thông tin về file (link tới catalog file, không phải file trên đĩa) — dùng khắp nơi khi làm việc với file infobase.
- Client procedures **OpenFile()**, **OpenFileDirectory()**, **SaveFileAs()** của **FilesOperationsClient** (tương tự FileSystemClient) nhận structure **FileData** chứ không phải link.
- Server module cũng: lấy binary data, thêm electronic signature, lưu file kèm chữ ký, copy attached files giữa các owner...

## Cú pháp & ví dụ code

Hyperlink Attachments trên command bar:
```bsl
FilesHyperlink = FilesOperations.FilesHyperlink();

FilesHyperlink.Location = "CommandBar";
```

OnOpen:
```bsl
FilesOperationsClient.OnOpen(ThisObject, Cancel);
```

OnWriteAtServer:
```bsl
FilesOperations.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
```

NotificationProcessing:
```bsl
FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
```

Region:
```bsl
#Region <RegionName> (the region name is written without spaces)

// code inside the region

#EndRegion
```

[ghi chú ngoài nguồn] Code đầy đủ của ImportFile_, OpenFile/OpenURL handlers, OnCreateAtServer, query HasFiles và FillFilesAttachedToObject trong tài liệu gốc là ảnh chụp màn hình, không có văn bản để chép nguyên văn. → đã bổ sung ImportFile_, OnCreateAtServer, query HasFiles (nhánh lesson/21-23-theory); OpenFile/OpenURL handlers và FillFilesAttachedToObject vẫn chưa có nguồn (không có trong code của khóa ở cả hai nhánh 21-23).

## Thuộc tính/thiết lập quan trọng trong Designer
- Catalog attached files: attribute **FileOwner**; **Hierarchical catalog**, **"Folder and item hierarchy"**; property **Use** = **"For folder and item"** cho Author, FileOwner, UniversalModificationDate, CreationDate, ChangedBy, PictureIndex, LongDesc; attribute **Service** (Boolean).
- Defined types: **AttachedFile**, **AttachedFileObject**, **AttachedFilesOwner**, **AttachedFilesOwnerObject**.
- Exchange plan **InfobaseUpdate**.
- Event subscriptions: property **Source**; event **FormGetProcessing**, **BeforeWrite**.
- Form command interface: command **AttachedFiles**.
- Dynamic list: **CustomQuery**; information register **FilesExist**; field **HasFiles**.
- Form table field: **"Image field"**, **ValuesPicture** = "ClipCollection", **HeaderPicture** = "Clip".

## Lỗi thường gặp / lưu ý
- Quên bỏ quyền interactive deletion của catalog attached files mới khỏi FullAccess.
- Sửa defined types (và object SSL khác) cần bật khả năng thay đổi trong support options.
- File versioning chỉ có với catalog "Files"; catalog <OwnerName>AttachedFiles chỉ có version mới nhất.
- Copy event handler procedure mà không gán event trong form → không chạy.
- OpenURL kiểm tra link bằng IsAllowedRef(); link thiếu phần đầu → lỗi.
- "Undo edits" sau khi sửa → bản local khác bản lưu, cần chọn nguồn mở.

## Điểm cần nhớ
- FileSystem (Core) cho file trên đĩa; FilesOperations cho attached files trong infobase.
- FileSystemClient: ImportFile_ (CallbackDescription, FileImportParameters), OpenFile, OpenURL; xử lý web client và file bận/thiếu.
- CommonClient.MessageToUser() / Common.MessageToUser() để thông báo user.
- 3 cách lưu attached files; phổ biến nhất là catalog <ObjectName>AttachedFiles; versioning chỉ ở catalog Files.
- Kết nối: catalog + FileOwner, defined types, InfobaseUpdate, 2 event subscriptions, AttachedFilesOwner(Object).
- Form: FilesOperations.OnCreateAtServer + FilesHyperlink(), FilesOperationsClient.OnOpen, FilesOperations.OnWriteAtServer, FilesOperationsClient.NotificationProcessing.
- Icon kẹp giấy: field HasFiles qua join FilesExist + Image field với ClipCollection.
- Dùng #Region/#EndRegion để cấu trúc module theo development standards.

## Thẻ gợi ý bài thực hành (Practice 23)

23. Practice là một task tự nghiên cứu duy nhất. Để dễ theo dõi, thẻ dưới đây chia nó thành 4 phần theo đúng các yêu cầu của đề. Mỗi thẻ chỉ có gợi ý, không có lời giải. Mẫu tham khảo tốt nhất là chính SSL demo: document `InventoryRecount` của bài lý thuyết và item form của catalog `_DemoProducts` (có ảnh chính).

### Bài tập — Phần 1: Kết nối catalog _DemoStorageLocations vào FilesOperations (catalog file riêng)

- **Đề bài (tóm tắt):** Kết nối catalog `_DemoStorageLocations` vào FilesOperations. File của storage location phải lưu trong catalog riêng, không dùng catalog "Files" chung.
- **Gợi ý 1 — Hướng đi:** Làm lại đúng 9 bước của mục "Các bước kết nối document InventoryRecount vào FilesOperations", nhưng owner là **catalog** chứ không phải document. Vì vậy bước 9 (defined type cho object owner) là bắt buộc.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Catalog mới `_DemoStorageLocationsAttachedFiles` (copy từ `_DemoProjectsAttachedFiles`), attribute `FileOwner` kiểu `CatalogRef._DemoStorageLocations`. Quyết định có cần hierarchical hay không.
  - Defined types: `AttachedFile` (ref), `AttachedFileObject` (object), `AttachedFilesOwner` (CatalogRef owner), `AttachedFilesOwnerObject` (CatalogObject owner).
  - Exchange plan `InfobaseUpdate`: thêm catalog file.
  - Event subscriptions `_DemoDetermineAttachedFileForm` (Source thêm `CatalogManager` của catalog file) và `_DemoSetDeletionMarkForAttachedDocumentFiles` (xem có cần thêm owner không).
  - Role `FullAccess`: bỏ Interactive delete (và quyền xóa predefined) của catalog mới.
- **Gợi ý 3 — Khung bài làm:**
  1. Bật support cho các object SSL sẽ sửa (defined types, exchange plan, subscriptions, role).
  2. Copy catalog file, đổi tên/synonym, đổi kiểu FileOwner.
  3. Thêm vào 4 defined types, InfobaseUpdate, subscriptions.
  4. Sửa FullAccess cho catalog mới.
  5. Update DB configuration.
- **Lỗi hay gặp:**
  - Quên `AttachedFilesOwnerObject` vì bài lý thuyết là document (document không cần bước này).
  - Copy catalog đang hierarchical nhưng không cần group: phải tắt hoặc đổi Use của các attribute như mục 3 của lý thuyết.
  - Quên bỏ Interactive delete ở FullAccess (lý thuyết nhấn mạnh "Important").
- **Tự kiểm tra:** Trong Enterprise, mở một storage location, thêm file qua form attachments (khi đã làm Phần 2). File mới phải nằm trong list của catalog `_DemoStorageLocationsAttachedFiles`, không nằm trong "Files".

### Bài tập — Phần 2: Item form có submenu file và hyperlink "Attachments"

- **Đề bài (tóm tắt):** Item form của storage location có submenu làm việc với file và hyperlink "Attachments" như bài lý thuyết.
- **Gợi ý 1 — Hướng đi:** Xem "Tích hợp vào form document" và code demo của form `InventoryRecount` ở mục theory demo bên dưới. Có 4 event của form cần gọi tới SSL, cộng các attachable handler.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form module (item form của catalog): `OnCreateAtServer` (`&AtServer`), `OnOpen` (`&AtClient`), `OnWriteAtServer` (`&AtServer`), `NotificationProcessing` (`&AtClient`).
  - SSL: `FilesOperations.FilesHyperlink()` với `Location = "CommandBar"`, `FilesOperations.OnCreateAtServer`, `FilesOperationsClient.OnOpen`, `FilesOperations.OnWriteAtServer`, `FilesOperationsClient.NotificationProcessing`.
  - Attachable handlers `Attachable_*` (copy từ `_DemoSalesOrder` hoặc `_DemoProducts`).
  - Bọc mỗi lời gọi trong `// StandardSubsystems.StoredFiles` … `// End StandardSubsystems.StoredFiles`.
- **Gợi ý 3 — Khung bài làm:**
  1. Kiểm tra form đã có handler nào (OnCreateAtServer, OnOpen...). Nếu có thì chèn lời gọi vào, không tạo trùng.
  2. Thêm các handler còn thiếu **qua Properties palette** để chúng được gán với event.
  3. Copy các attachable handler, đặt vào region phù hợp.
- **Lỗi hay gặp:**
  - Copy procedure handler mà không gán event trong form → không chạy (lý thuyết đã cảnh báo).
  - Quên `OnWriteAtServer` → file thêm trên form object mới chưa ghi không được lưu đúng.
  - Hyperlink "Attachments" xuất hiện 2 lần (command bar và "Go to"): bỏ flag command AttachedFiles trong command interface của form.
- **Tự kiểm tra:** Hyperlink hiện số file đính kèm và tăng khi thêm file. Submenu file hoạt động.

### Bài tập — Phần 3: Cột "Paperclip" trên list form

- **Đề bài (tóm tắt):** List form có cột hình kẹp giấy cho storage location có file đính kèm.
- **Gợi ý 1 — Hướng đi:** Xem "Biểu tượng kẹp giấy trong list form" và query HasFiles của InventoryRecount trong theory demo: bật custom query cho dynamic list, join information register `FilesExist`, thêm Image field.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Dynamic list `List`: flag **CustomQuery**, LEFT JOIN `InformationRegister.FilesExist` theo `ObjectWithFiles`, field `HasFiles` (0/1).
  - Form table: field loại Image field, `ValuesPicture` = `ClipCollection`, `HeaderPicture` = `Clip`, tắt title.
- **Gợi ý 3 — Khung bài làm:**
  1. Mở list form của catalog (tạo nếu chưa có), bật CustomQuery.
  2. Sửa query: thêm join và field HasFiles. Chú ý trường hợp không có record trong `FilesExist` (giá trị NULL).
  3. Kéo field HasFiles vào table, đổi sang Image field, gán 2 picture.
- **Lỗi hay gặp:**
  - Chỉ xét `HasFiles = TRUE` mà không tính NULL → kết quả trống hoặc sai với item chưa từng có file.
  - Dùng INNER JOIN → mất các storage location không có file.
  - Để field dạng input field → hiện số 0/1 thay vì hình.
- **Tự kiểm tra:** Item có file hiện kẹp giấy, item không có file để trống. Xóa hết file của một item thì kẹp giấy biến mất sau khi refresh list.

### Bài tập — Phần 4: Ảnh chính trên item form (như _DemoProducts)

- **Đề bài (tóm tắt):** Gắn và hiển thị ảnh chính của storage location trên item form. Ảnh phải còn sau khi lưu, đóng và mở lại form. Các nút "View", "Clear", "Open the attachment card" và submenu ảnh phải chạy. Không cần nút "PDF image album". Nhớ chia module bằng region.
- **Gợi ý 1 — Hướng đi:** Ảnh chính là một **attribute** của catalog trỏ tới file đính kèm (vì thế ảnh còn sau khi mở lại). FilesOperations có sẵn "file field" vẽ khung ảnh và các nút, chỉ cần khai báo nó trong `OnCreateAtServer`. Hãy đọc item form của `_DemoProducts` để xem cách nó khai báo.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Catalog `_DemoStorageLocations`: attribute mới (ví dụ `PicturesFile`) kiểu `CatalogRef._DemoStorageLocationsAttachedFiles`.
  - Item form: một group trống để chứa ảnh (sắp xếp lại form thành 2 cột nếu muốn: ảnh bên trái, Code/Description bên phải).
  - SSL: `FilesOperations.FileField()` (các property chỉ chỗ đặt, data path tới attribute ảnh, form attribute chứa địa chỉ dữ liệu ảnh), `FilesOperations.SettingsOfFileManagementInForm()`. `FilesOperations.OnCreateAtServer` nhận được **array** nhiều item (hyperlink + file field).
  - Attachable handlers cho preview field: `Attachable_PreviewFieldClick`, `Attachable_PreviewFieldCheckDragging`, `Attachable_PreviewFieldDrag`, `Attachable_AttachedFilesPanelCommand`.
  - Region theo chuẩn: `FormEventHandlers`, `FormHeaderItemsEventHandlers`, `FormCommandsEventHandlers`...
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm attribute ảnh vào catalog, update DB.
  2. Thêm group chứa ảnh vào item form.
  3. Trong `OnCreateAtServer`: tạo tham số hyperlink (Phần 2) và tham số file field, gom vào array, gọi `OnCreateAtServer` của SSL.
  4. Copy các attachable handler cho preview field, đặt trong region.
  ```bsl
  &AtServer
  Procedure OnCreateAtServer(Cancel, StandardProcessing)
  	// StandardSubsystems.StoredFiles
  	// 1) tham số hyperlink (như Phần 2)
  	___
  	// 2) tham số file field: chỗ đặt = group ảnh, data path = attribute ảnh của Object, attribute địa chỉ ảnh
  	___
  	// 3) gom cả hai vào Array, (tùy chọn) settings, gọi FilesOperations.OnCreateAtServer
  	___
  	// End StandardSubsystems.StoredFiles
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Lưu ảnh vào form attribute thay vì attribute của catalog → mở lại form thì mất ảnh.
  - Kiểu attribute ảnh trỏ tới catalog "Files" chung hoặc catalog của object khác, trái yêu cầu "catalog riêng".
  - Quên các handler preview field hoặc không gán event → click/kéo thả ảnh không có tác dụng.
  - Thêm procedure mà không đặt trong `#Region` (đề nhắc rõ).
- **Tự kiểm tra:** Click khung ảnh → chọn file → ảnh hiện ngay. Save, đóng, mở lại → ảnh vẫn còn. Thử "View", "Clear", "Open the attachment card". File ảnh cũng xuất hiện trong danh sách Attachments và trong catalog file riêng.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/21-23-theory)

Trong nhánh lesson/21-23-theory, phần code của khóa học cho bài 23 là document `InventoryRecount` (form module + list form) và catalog `InventoryRecountAttachedFiles` (copy từ `_DemoProjectsAttachedFiles` của SSL demo, manager module giữ nguyên code của SSL). Các lời gọi `FilesOperations*`, `FileSystemClient.*` là module của SSL (Standard Subsystems Library).

### Kết nối form document vào FilesOperations (có #Region)
Nguồn: nhánh lesson/21-23-theory — cf/Documents/InventoryRecount/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.StoredFiles
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	// StandardSubsystems.StoredFiles
	FilesOperations.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	// End StandardSubsystems.StoredFiles
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion
```
- Code của khóa học: các event handler của form và attachable handler, mỗi lời gọi bọc trong service comments `// StandardSubsystems.StoredFiles`; module chia region `FormEventHandlers`, `FormHeaderItemsEventHandlers` (tên region không có dấu cách).
- Module của SSL được gọi tới: `FilesOperations.FilesHyperlink()` + `Location = "CommandBar"` → hyperlink "Attachments" trên command bar; `FilesOperations.OnCreateAtServer`, `FilesOperationsClient.OnOpen`, `FilesOperations.OnWriteAtServer`, `FilesOperationsClient.NotificationProcessing`.
- Các procedure `Attachable_*` (copy từ `_DemoSalesOrder`) phải được gán làm handler trong properties palette, nếu không sẽ không chạy.

### Chọn file bằng FileSystemClient.ImportFile_
Nguồn: nhánh lesson/21-23-theory — cf/Documents/InventoryRecount/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
#Region FormCommandsEventHandlers

&AtClient
Procedure ImportDataFromFile(Command)
	
	FileImportParameters = FileSystemClient.FileImportParameters();
	FileImportParameters.FormIdentifier = UUID;
	FileImportParameters.Dialog.Filter = 
		"Tables (*.xls,*.xlsx,*.xlsm)|*.xls;*.xlsx;*.xlsm;
		||Microsoft Excel 1997-2003 (*.xls)|*.xls
		||Microsoft Excel (*.xlsx,*.xlsm)|*.xlsx;*.xlsm";
	
	CallbackDescription = New CallbackDescription("ImportDataAfterSelection", ThisObject);
	
	FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters);
	
EndProcedure

&AtClient
Procedure ImportDataAfterSelection(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;

	// FileName = FileThatWasPut.Name
	// BinaryData = GetFromTempStorage(FileThatWasPut.Location)
	
EndProcedure

#EndRegion
```
- Code của khóa học: command `ImportDataFromFile` và callback `ImportDataAfterSelection` (export, nhận file đã đặt vào temporary storage).
- Module của SSL: `FileSystemClient.FileImportParameters()` trả structure tham số (`FormIdentifier`, `Dialog.Filter`...); `FileSystemClient.ImportFile_` mở dialog, đưa file lên server và gọi `CallbackDescription`.
- Trong demo phần xử lý chỉ để ở dạng comment: tên file ở `FileThatWasPut.Name`, binary data đọc bằng `GetFromTempStorage(FileThatWasPut.Location)` — `ImportFile_` đã lo phần chọn file và đưa file vào temporary storage (việc mà nếu dùng method của platform như `FileDialog`, `BeginPutFileToServer` thì developer phải tự viết).

### Biểu tượng kẹp giấy: query HasFiles của dynamic list
Nguồn: nhánh lesson/21-23-theory — cf/Documents/InventoryRecount/Forms/ListForm/Ext/Form.xml
```xml
				<QueryText>SELECT
	DocumentInventoryRecount.Ref,
	DocumentInventoryRecount.DeletionMark,
	DocumentInventoryRecount.Number,
	DocumentInventoryRecount.Date,
	DocumentInventoryRecount.Posted,
	DocumentInventoryRecount.StorageLocation,
	DocumentInventoryRecount.EmployeeResponsible,
	DocumentInventoryRecount.Comment,
	DocumentInventoryRecount.Goods,
	DocumentInventoryRecount.PointInTime,
	CASE
		WHEN FilesExist.HasFiles = TRUE THEN
			1
		ELSE
			0
	END AS HasFiles
FROM
	Document.InventoryRecount AS DocumentInventoryRecount
	LEFT JOIN InformationRegister.FilesExist AS FilesExist
		ON DocumentInventoryRecount.Ref = FilesExist.ObjectWithFiles</QueryText>
```
Nguồn: nhánh lesson/21-23-theory — cf/Documents/InventoryRecount/Forms/ListForm/Ext/Form.xml
```xml
					<HeaderPicture>
						<xr:Ref>CommonPicture.Clip</xr:Ref>
						<xr:LoadTransparent>true</xr:LoadTransparent>
					</HeaderPicture>
					<ValuesPicture>
						<xr:Ref>CommonPicture.ClipCollection</xr:Ref>
						<xr:LoadTransparent>true</xr:LoadTransparent>
					</ValuesPicture>
```
- Code của khóa học: bật CustomQuery cho dynamic list, LEFT JOIN information register `FilesExist` (của SSL) theo `ObjectWithFiles`, chuyển Boolean thành 0/1 bằng `CASE`.
- Picture field `HasFiles`: `HeaderPicture` = `CommonPicture.Clip`, `ValuesPicture` = `CommonPicture.ClipCollection` (hình rỗng cho 0, kẹp giấy cho 1).

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

Không có video tương ứng — chỉ dẫn tài liệu Theory/Practice của bài.
