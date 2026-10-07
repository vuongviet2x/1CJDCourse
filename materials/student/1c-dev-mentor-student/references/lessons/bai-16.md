# Bài 16 — Events (object/form/form element events) và Event subscriptions

## Khái niệm chính

### Tổng quan về events
- Khi làm việc với catalogs, documents, registers và form của chúng, nhiều event được kích hoạt. Ví dụ tạo document mới ở interactive mode: **Filling** (object module), **OnCreateAtServer** và **OnOpen** (form module).
- Một số event có hành vi chuẩn của platform, có thể override bằng cách đổi tham số **StandardProcessing** từ True sang False. Ví dụ field "Text box" có event **StartChoice**; tắt standard processing → bấm nút choice không xảy ra gì (thay vì mở choice form cho reference attribute, mở bảng nhập số cho attribute kiểu Number...). Có thể tắt rồi tự mở custom form.

### Cách tìm events và gán handler
- **Object / manager / record set modules / root modules** (application, session, external connection module):
  - Danh sách event nằm trong list procedures and functions của module; handler có thể gán được hiển thị trong **dấu ngoặc nhọn `< >`**. "Go to" hoặc double click → thêm handler vào module.
  - Handler **phải có tên chuẩn**. Procedure tên `BeforeWrite` tự động được coi là handler của event BeforeWrite, **kể cả khi tham số khác chuẩn**. (Ví dụ: đổi `BeforeWrite1` → `BeforeWrite` thì event BeforeWrite không còn trong danh sách để tạo.)
- **Form modules** (form và form elements):
  - Danh sách event ở **properties palette** và context menu của element.
  - Event phải được **gán tường minh** với handler; tên procedure tuỳ ý (khuyến nghị giữ mặc định). Mặc định: event của form → tên trùng tên event; event của element → `<FormElementName>` + `<EventName>` (ví dụ OnChange của field Carrier → `CarrierOnChange()`).
  - Từ properties palette có thể tạo mới **hoặc gán procedure có sẵn**.
  - Có thể tạo một handler chung cho nhiều field (ví dụ field Price trong 2 tabular sections Products và Services để tính lại amount) — đặt tên không gắn với element cụ thể.
  - Danh sách handler có thể chọn được lọc theo **số lượng tham số** của procedure.
  - Platform **không kiểm soát** liên kết event–handler khi rename/xoá procedure. Handler không tồn tại = như không có handler → event xử lý theo chuẩn. Phát hiện bằng cách thử "go to handler" từ palette/context menu.
  - Khuyến nghị thao tác từ **Properties palette**:
    - Rename: sửa tên trong ô event trên palette → platform đề nghị rename procedure. Nếu từ chối → tạo procedure mới, procedure cũ vẫn còn nhưng không còn là handler.
    - Xoá: clear ô event trên palette → platform đề nghị xoá procedure khỏi module.

### Thứ tự events (writing/posting)
- Sơ đồ ghi catalog item và sơ đồ post document chỉ khác nhau ở event **Posting** (chỉ có khi post, không có khi chỉ write).
- Thời điểm **FillCheckProcessingAtServer** (form) / **FillCheckProcessing** (object) khi làm interactive phụ thuộc property **Posting** của document: bật → check khi post; tắt → check khi write, và document không có lệnh post/undo posting.
- Thứ tự:
  1. **Form module. BeforeWrite(Cancel, WriteParameters)** — client, chạy đầu tiên khi write/post/undo posting. Dùng cho check client, chuẩn bị dữ liệu chỉ có ở client, tương tác user (cancel ghi tới khi có trả lời, rồi ghi lại từ code với một cờ báo không cần hỏi nữa).
     - **WriteParameters**: structure có kiểu định sẵn theo loại object; catalog → rỗng; document → 2 property:
       - **WriteMode** (kiểu `DocumentWriteMode`): Write, Posting, UndoPosting
       - **PostingMode** (kiểu `DocumentPostingMode`): RealTime, Regular
     - Có thể bổ sung property bất kỳ để truyền dữ liệu từ client sang BeforeWriteAtServer, OnWriteAtServer, AfterWriteAtServer.
  2. **Form module. FillCheckProcessingAtServer(Cancel, CheckedAttributes)** và **Object module. FillCheckProcessing(Cancel, CheckedAttributes)** — giống nhau, một cho form/attribute của form, một cho object/attribute/tabular sections. Attribute có **"Required field"** = "Display error" → path vào mảng **CheckedAttributes**. Form có property **"AutoFillCheck"** (mặc định bật); tắt → ghi interactive từ form không gọi cả 2 event.
     - Cả 2 chỉ chạy khi ghi **interactive**. Ghi bằng code không gọi → dùng method **`CheckFilling()`** của object để kích hoạt.
     - Ví dụ: form có attributes City, District, Street, Building, Apartment (bắt buộc khi bật cờ "delivery required"), BeforeWriteAtServer ghép thành attribute DeliveryAddress của document theo quy tắc.
  3. **Form module. BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)** — server. Form đã được "tách" thành form và applied object sẽ ghi vào DB.
     - **CurrentObject** có kiểu "object" class (CatalogObject, DocumentObject...) — instance đã tạo nhưng chưa ghi vào DB.
     - Mọi thay đổi phải làm qua **CurrentObject**; sửa qua form attribute **Object** không có tác dụng (chỉ nên read-only, tốt nhất không dùng). Sau khi write transaction xong, dữ liệu từ CurrentObject được ghi vào Object.
     - Ghi object bằng code → event này (và mọi event trong form module) **không được gọi**. Thuật toán phải chạy với mọi cách ghi → đặt trong handler của object (**BeforeWrite**).
  4. **— Start of transaction —**
  5. **Object module. BeforeWrite(Cancel, WriteMode, PostingMode)** — event đầu tiên sau khi bắt đầu transaction. Với document có thêm WriteMode và PostingMode (chính là các property trong WriteParameters ở form).
     - Dùng để hoàn thiện object (ví dụ TotalAmount = tổng các tabular sections Products, Services...), chuẩn bị dữ liệu cho bước sau (ví dụ so sánh status cũ lấy qua reference với status hiện tại, ghi vào **AdditionalProperties** việc status có đổi không để sau đó ghi vào register).
     - Huỷ ghi → tham số **Cancel**.
     - Tới cuối event, object **chưa** được ghi vào DB; đọc dữ liệu qua reference sẽ là dữ liệu cũ (không có thay đổi của user trên form và của BeforeWriteAtServer/BeforeWrite).
  6. **Object module. OnWrite(Cancel)** — event đầu tiên sau khi object ghi vào DB; object mới đã có reference. Dùng để ghi dữ liệu liên quan đến object (ví dụ lịch sử status: *Document ref - State - Date - Author*). Lỗi → huỷ transaction tường minh (raise exception hoặc Cancel) hoặc ngầm định (exception như chia cho 0). Không lỗi → document và status ghi trong **một transaction**.
  7. **Object module. Posting(Cancel, PostingMode)** — chỉ khi post (interactive hoặc bằng code). Posting tắt → không bao giờ chạy. Mục đích: tạo và ghi movements vào registers, kiểm tra liên quan (ví dụ không âm tồn kho). PostingMode: real-time hoặc backdated. Nếu bật tự động xoá movements trên tab **Posting** (mặc định cho document mới) → mọi register records của document bị xoá tự động trước event; nếu không phải xoá bằng code.
  8. **Form module. OnWriteAtServer(Cancel, CurrentObject, WriteParameters)** — sau khi ghi object vào DB nhưng trước khi kết thúc transaction; **event cuối cùng có thể huỷ ghi** trong transaction.
     - Mục đích: ghi thông tin bổ sung. Tương tự OnWrite của object module: dữ liệu nằm trong object → dùng OnWrite(); dữ liệu nằm trên form → dùng event này. Cũng dùng khi cần WriteParameters.
     - CurrentObject (DocumentObject) chứa dữ liệu đã ghi; gọi được export methods của object.
     - Object mới: `CurrentObject.Ref` có reference; `Object.Ref` vẫn là empty ref.
     - Kết luận: thao tác với object đã ghi → CurrentObject; cần ref của object mới → `CurrentObject.Ref`; form attribute Object chỉ để so sánh "trước" và "đã ghi"; cần ghi dữ liệu bổ sung dựa trên form data + object data → dùng handler này.
     - Ví dụ: lưu các giá trị City/District mới nhập (auto-completion "San" → San Francisco, San Diego; user nhập San Sebastian) vào object riêng trong transaction, tránh tạo record thừa nếu document không ghi được.
  9. **— Completing the transaction —**
  10. **Form module. AfterWriteAtServer(CurrentObject, WriteParameters)** — sau khi transaction xong, dữ liệu object được chuyển thành form data rồi gọi handler. **Không có Cancel** (quá muộn). Handler cuối cùng mà form data và object đã ghi còn tách biệt.
      - Dùng cho thao tác trên form chỉ làm khi object chắc chắn đã ghi (ví dụ hiển thị thông tin bổ sung).
      - Sửa CurrentObject **vô nghĩa** (dữ liệu đã nạp vào Object, CurrentObject bị huỷ khi thoát handler), nhưng dùng được để đọc property/gọi export methods.
      - WriteParameters vẫn còn.
      - Ví dụ: cột form attribute **SoldThisMonth** trong tabular section của Sales invoice, query sales turnovers từ đầu tháng tới cuối ngày của document date để điền cột.
  11. **Form module. AfterWrite(WriteParameters)** — client, event chính cuối cùng. Sau AfterWriteAtServer: form gửi về client, application object bị huỷ trong server memory, form object trên server bị huỷ. Dùng để hiển thị trên form, hội thoại với user (warning), thông báo cho user hoặc các form đang mở rằng object đã đổi.

### Events khi đóng form (client, cấm server call)
- **Form module. BeforeClose(Cancel, Exit, WarningText, StandardProcessing)** — quyết định form có được đóng không.
  - `Cancel = True` → form không đóng.
  - `StandardProcessing = False` → form đóng **không hỏi** dù dữ liệu đã bị sửa (bình thường platform hỏi write / đóng không lưu / huỷ đóng).
  - **Exit** = True khi user đóng main application window; đóng form riêng → False.
  - **WarningText** — text hiển thị khi đóng app hoặc khi từ chối đóng form (web client gộp mọi message vào một dialog). Không set → "The data is changed. All changes will be lost."
  - Hội thoại với user: question dialog là **non-modal** → chia 2 phần: (1) hỏi, set Cancel = True; (2) trong response handler, nếu đồng ý → set attribute (ví dụ `CloseWithoutChecking`, Boolean, mặc định False) = True rồi gọi `Close()`.
  - Item form/document form/record form đã được platform tự kiểm soát mất dữ liệu; common forms, data processor forms, list/choice forms thì platform hiếm khi kiểm tra → đôi khi phải tự làm.
- **Form module. OnClose(Exit)** — form đã đóng (user không thấy) nhưng program object vẫn còn. Dùng cho thao tác chỉ làm khi form chắc chắn đóng: đóng auxiliary form phụ thuộc, tắt trading equipment kết nối ở OnOpen. **Không thể** từ chối đóng ở đây. Sau event, form object bị xoá khỏi client memory.

### Form field events (input field)
- **StartChoice(Item, ChoiceData, StandardProcessing)**
  - **Item**: form element kích hoạt event (ví dụ field `ProductsProduct` của form table).
  - **ChoiceData**: danh sách cho user chọn, thường là Undefined; có thể set `StandardProcessing = False` và gán **ValueList** (khi danh sách nhỏ, tới khoảng 10 phần tử, không cần mở form riêng).
  - Có thể tắt standard processing và mở choice form với thuật toán riêng. Truyền field vào tham số **"Owner"** của `OpenForm` → giá trị chọn tự động điền vào ô, không cần xử lý choice event riêng.
  - Ví dụ: document PersonnelChange, operation "Dismissal" → chỉ chọn nhân viên đang làm việc. Tạo choice form mới cho catalog Employees (**không** đặt làm default choice form), dynamic list bật **CustomQuery**, query catalog Employees + information register Employees (catalog làm main table để platform trả về ref). OnCreateAtServer kiểm tra form parameters có property **Filter**, nếu không → raise exception; điền parameters Date và Company cho dynamic list từ Filter. StartChoice: nếu operation kind = Dismissal → StandardProcessing = False, mở form với filter date + company và Item làm owner.
  - Date field: nút chọn là calendar; number field: calculator — vẫn là cùng choice button, cùng event.
- **Clearing(Item, StandardProcessing)** — lệnh clear (nút clear bật bằng property **"ClearButton"** = Yes, hoặc hotkey **Shift + F4**). Dùng cho thao tác liên quan (xoá Customer thì xoá cả Contract). `StandardProcessing = False` → không xoá giá trị.
- **Tuning(Item, Direction, StandardProcessing)** — nút scroll (property **SpinButton** = Yes). **Direction** kiểu Number: 1 = up/increase, -1 = down/decrease. Không nhất thiết là số (ví dụ chuyển tháng <Month Year>).
- **Opening(Item, StandardProcessing)** — nút open (property **"OpenButton"** = Yes). Mặc định có cho field liên kết reference attribute; tắt bằng OpenButton = No. Bật cho kiểu primitive → standard mở cửa sổ hiển thị giá trị dạng string. Override bằng StandardProcessing = False.
- **ChoiceProcessing(Item, SelectedValue, StandardProcessing)** — sau khi user chọn giá trị nhưng **trước khi** đặt vào field. Có thể:
  - từ chối lựa chọn (`StandardProcessing = False`);
  - đặt giá trị khác (`SelectedValue`).
  - Lý do không giới hạn danh sách từ đầu: (1) usability — user không hiểu vì sao không chọn được supplier có thật → cho chọn rồi báo lỗi và huỷ; (2) kỹ thuật — kiểm tra từng phần tử tốn kém (ví dụ 49 phần tử), chỉ kiểm tra phần tử được chọn.
  - Đặt giá trị khác kiểu: field kiểu string, danh sách chọn là catalog elements → đặt presentation thay vì ref.

### Form table events
- Tập handler phụ thuộc kiểu dữ liệu liên kết (value table, value tree, tabular section, dynamic list, value list).
- **OnChange(Item)** — gọi khi có bất kỳ thay đổi nào trong một row (4 cột → điền 4 cột = 4 lần event). Không dùng cho mọi trường hợp (ví dụ không dùng để tính amount khi đổi quantity/price); chỉ dùng khi thuật toán phải chạy mỗi lần row đổi, hoặc cùng một thuật toán nhẹ cho nhiều event ở nhiều cột. Thêm/xoá row **không** kích hoạt event.
- **Selection(Item, SelectedRow, Field, StandardProcessing)** — double click ô, hoặc chọn row + Enter; hoặc bấm nút "Select" chuẩn khi form table liên kết main attribute bật **"Selection Mode"**.
  - **SelectedRow**: với tabular section/value table là **số identifier của row** (không phải line number) → lấy row bằng `FindByID(RowIdentifier)`.
  - **Field**: form element (cột) hiện tại → xử lý khác nhau theo cột. Hữu ích khi table **ReadOnly** (không có nút open/select trong ô).
  - `ShowValue()` hiển thị giá trị truyền ở tham số thứ hai trong dialog, không chờ đóng; loại dialog phụ thuộc kiểu giá trị.
- **OnActivateRow(Item)** — khi user chọn row: hiển thị thông tin bổ sung, filter table khác (country → cities), cập nhật property của element (availability nút).
  - **Important**: tránh **context server call** — khi về client form được cập nhật, current row bị kích hoạt lại → OnActivateRow gọi lại. Nếu cần → dùng client **Idle handler** (tham số 1: procedure; 2: khoảng thời gian; 3: một lần hay lặp).
  - Idle handler: client procedure gọi theo khoảng thời gian, bật bằng `AttachIdleHandler`; procedure phải **export** và **không có tham số**.
- **BeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)** — thêm row interactive (nút/hotkey). Kiểm tra có cấm thêm không → `Cancel = True`. **Clone** = True nếu thêm bằng copy. **Parent** và **Folder** chỉ có nghĩa với hierarchical catalogs và charts of characteristic types: Parent — phần tử/nhóm cha; Group (Folder) — True tạo group, False tạo element.
  - Không được dùng server method của form có directive **&AtServer** và không được đổi attribute dẫn tới server call.
- **BeforeRowChange(Item, Cancel)** — trước khi vào chế độ sửa row; override (mở form object liên quan) hoặc cấm sửa (`Cancel = True`).
- **OnStartEdit(Item, NewRow, Clone)** — sau khi vào chế độ sửa ô, trước khi thay đổi. Thường dùng cùng BeforeStartAdd: khi row thêm bằng copy → xoá một số cột (ví dụ **RowIdentifier** do developer thêm để định danh row không phụ thuộc line number); điền cột khi thêm row mới. **NewRow**: đang sửa row mới hay row cũ; **Clone**: row mới có phải copy không.
- **BeforeEditEnd(Item, NewRow, CancelEdit, Cancel)** — trước khi kết thúc sửa row (Enter, lệnh "Finish editing", click row khác); cũng xảy ra khi **Esc** → `CancelEdit = True`. Dùng để kiểm tra row ngay sau khi sửa (`Cancel = True` + thông báo). **Chỉ** gọi khi kết thúc sửa row, **không** gọi khi chuyển cột (Tab/chuột). Nên kiểm tra CancelEdit để không ép user điền khi họ bấm Esc.
- **OnEditEnd(Item, NewRow, CancelEdit)** — sau khi thoát chế độ sửa; không huỷ được. Dùng để tính dữ liệu bổ sung (tổng trọng lượng, phí giao hàng). Xảy ra **sau** OnChange của table; chọn thay OnChange khi cần NewRow và CancelEdit.

### Event subscriptions
- Cho phép đặt event handler ở module tách khỏi object, dùng một handler cho event của nhiều object (cả mọi object của một metadata class). Đặc biệt hữu ích khi customize standard configurations — thêm handler mà không đụng code chính.
- Configuration object kiểu **"Event Subscription"**, thiết lập:
  - **Source** — danh sách object types.
  - **Event** — event được xử lý.
  - **Handler** — path tới **export procedure** làm handler.
- Chọn type chung **DocumentObject / CatalogObject /...** → áp dụng cho mọi object của class, kể cả object tạo sau này.
- Chỉ chọn được **object events**, không chọn được form events.
- Danh sách event phụ thuộc Source: nhiều metadata class → chỉ còn event có ở tất cả.
- Handler: platform tìm export procedures khớp số tham số trong **common modules bật flag "Server"**; tạo mới cũng phải chọn common module có flag "Server". Platform cho chọn cả common module client-server (không phù hợp cho server events) → developer tự chọn đúng module.
- Ví dụ: subscription **FillDocumentCompany**, Source = DocumentObject, Event = **Filling**, điền company từ constant "Default Company" — thêm document mới không cần làm gì.
- Ba quy tắc (rule) điền:
  - "điền attribute trong mọi document có attribute đó" → Source = DocumentObject, code kiểm tra attribute tồn tại: lấy metadata object bằng `Metadata()`, tìm attribute theo tên trong property **Attributes**; Undefined → dừng procedure.
  - "điền từ constant cho mọi document, một số document điền khác" → Source = DocumentObject, kiểm tra type của Source để xử lý riêng.
  - "chỉ điền cho các document được chọn có attribute" → chỉ định từng document trong Source (chỉ chọn document có attribute).
- **Thứ tự thực thi event subscriptions**:
  1. Subscription chạy **ngay sau** event handler của object; chỉ chặn được event của object module, chạy trên server.
  2. Cùng source và action → chạy theo thứ tự vị trí trong cây metadata **từ trên xuống**.
  3. Subscription với source kiểu chung (DocumentObject, CatalogObject...) chạy **sau** subscription với source cụ thể (kể cả composite type).
  - Muốn subscription cho một document cụ thể chạy sau subscription chuẩn có Source = DocumentObject → cũng dùng Source DocumentObject, đặt thấp hơn trong danh sách, và kiểm tra type trong handler.

## Cú pháp & ví dụ code

```bsl
ProductRow = Object.Products.FindByID(SelectedRow);
```

```bsl
If TypeOf(Source) <> Type("DocumentObject.MyDocument") Then

    Return;

EndIf;
```

Chữ ký các handler (theo tài liệu):

```bsl
// Form module
BeforeWrite(Cancel, WriteParameters)
FillCheckProcessingAtServer(Cancel, CheckedAttributes)
BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
AfterWriteAtServer(CurrentObject, WriteParameters)
AfterWrite(WriteParameters)
BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
OnClose(Exit)

// Object module
FillCheckProcessing(Cancel, CheckedAttributes)
BeforeWrite(Cancel, WriteMode, PostingMode)
OnWrite(Cancel)
Posting(Cancel, PostingMode)

// Form field
StartChoice(Item, ChoiceData, StandardProcessing)
Clearing(Item, StandardProcessing)
Tuning(Item, Direction, StandardProcessing)
Opening(Item, StandardProcessing)
ChoiceProcessing(Item, SelectedValue, StandardProcessing)

// Form table
OnChange(Item)
Selection(Item, SelectedRow, Field, StandardProcessing)
OnActivateRow(Item)
BeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
BeforeRowChange(Item, Cancel)
OnStartEdit(Item, NewRow, Clone)
BeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
OnEditEnd(Item, NewRow, CancelEdit)
```

[ghi chú ngoài nguồn] Các đoạn code khác (handler Price chung, StartChoice cho Dismissal, BeforeClose với CloseWithoutChecking, handler FillDocumentCompany...) chỉ có dạng ảnh trong tài liệu nên không chép lại. (StartChoice cho operation Dismissal, handler Price chung và FillDocumentCompany → đã bổ sung (nhánh lesson/16-theory). BeforeClose với CloseWithoutChecking: nhánh chỉ có response handler `BeforeCloseAnswer` và attribute `CloseWithoutChecking` → đã bổ sung phần này (nhánh lesson/16-theory); procedure `BeforeClose` (hỏi user, `Cancel = True`) vẫn chưa có nguồn.) → xem mục Code demo của bài Theory bên dưới.

## Thuộc tính/thiết lập quan trọng trong Designer
- Document: property **Posting**; tab **Posting** (tự động xoá movements).
- Attribute: **Required field** = "Display error".
- Form: **AutoFillCheck** (mặc định bật).
- Input field: **ClearButton**, **SpinButton**, **OpenButton**.
- Form table: **Selection Mode**, **ReadOnly**.
- Dynamic list: **CustomQuery**; choice form không đặt làm default choice form.
- Event Subscription: **Source**, **Event**, **Handler**.
- Common module: flag **Server** (bắt buộc cho handler của event subscription).

## Lỗi thường gặp / lưu ý
- Trong object module, procedure trùng tên event **tự động thành handler** dù tham số sai.
- Rename/xoá procedure handler trong form module → platform không cập nhật liên kết; handler không tồn tại = event xử lý chuẩn. Nên thao tác từ Properties palette.
- FillCheckProcessing/FillCheckProcessingAtServer **không** chạy khi ghi bằng code → dùng `CheckFilling()`.
- Trong BeforeWriteAtServer / OnWriteAtServer: thay đổi qua form attribute **Object** không được ghi → dùng **CurrentObject**.
- Form events không chạy khi ghi bằng code → logic bắt buộc phải đặt trong object module (BeforeWrite...).
- Trong object BeforeWrite, đọc qua reference trả dữ liệu cũ.
- AfterWriteAtServer: sửa CurrentObject vô nghĩa; không có Cancel.
- BeforeClose / OnClose: client, **cấm server call**; OnClose không huỷ được việc đóng.
- Form table OnChange gọi cho mỗi thay đổi trong row — không dùng cho tính toán thông thường.
- OnActivateRow: tránh context server call (gây kích hoạt lại event) → dùng Idle handler.
- BeforeAddRow: không dùng method &AtServer, không đổi attribute gây server call.
- BeforeEditEnd: không gọi khi chuyển cột; kiểm tra CancelEdit trước khi ép user điền.
- Event subscription: platform cho chọn cả common module client-server — developer tự chọn module server phù hợp.

## Điểm cần nhớ
- Object module: handler theo **tên chuẩn**; form module: handler **gán tường minh** qua Properties palette.
- `StandardProcessing = False` để tắt hành vi chuẩn của platform.
- Thứ tự ghi: Form BeforeWrite → FillCheck (form + object) → BeforeWriteAtServer → [transaction] Object BeforeWrite → OnWrite → Posting → OnWriteAtServer → [hết transaction] AfterWriteAtServer → AfterWrite.
- **OnWriteAtServer** là nơi cuối cùng huỷ được việc ghi; ref của object mới lấy qua `CurrentObject.Ref`.
- Logic phải chạy với mọi cách ghi → đặt ở **object module**, không đặt ở form.
- StartChoice + `OpenForm` với Owner = Item → giá trị chọn tự điền vào field.
- ChoiceProcessing cho phép từ chối hoặc thay giá trị user chọn.
- Event subscription: Source/Event/Handler, handler là export procedure trong common module **Server**; chỉ object events; source cụ thể chạy trước source chung, cùng loại thì theo thứ tự trong cây metadata.

## Thẻ gợi ý bài thực hành (Practice 16)

Các thẻ đi theo thứ tự đề trong 16. Practice. Các thẻ 4, 5 và 7 cùng sửa Posting của Sales invoice và Return of goods from customer, nên đọc cả ba trước khi bắt đầu viết.

### Bài tập 1 — Bảng products của document đang chọn trên home page

- **Đề bài (tóm tắt):** Dưới list Purchase invoice và Sales invoice trên home page, thêm bảng read-only hiện các product (không gồm services) của document đang chọn. Chỉ áp dụng cho home page và phải xử lý trường hợp list không có dòng active.
- **Gợi ý 1 — Hướng đi:** Mục "Form table events": event **OnActivateRow** của list chạy mỗi khi dòng hiện tại đổi. Dùng một **dynamic list thứ hai** có custom query lọc theo tham số `&Ref`, rồi đổi tham số đó ngay ở client, không cần server call (theo cảnh báo trong lý thuyết, server call trong OnActivateRow dễ gây kích hoạt lại event).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Tạo **list form riêng** cho mỗi document (ví dụ `DetailedListForm`) và đặt form này lên home page; list form mặc định giữ nguyên.
  - Form attribute thứ hai kiểu DynamicList, **CustomQuery** trên tabular section `Products` của document, điều kiện `Ref = &Ref`.
  - Field `Ref` của list chính phải hiển thị hoặc bật **Use always** (tip trong đề).
  - Handler `&AtClient` cho event OnActivateRow của table List; method `Parameters.SetParameterValue` của dynamic list.
  - Bảng products: **ReadOnly**, tắt thêm/xoá/kéo dòng.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo list form mới, thêm dynamic list thứ hai cùng query, đặt nó dưới list chính.
  2. Đặt bảng read-only, bật Use always cho `Ref` của list chính.
  3. Viết OnActivateRow: lấy dòng hiện tại; có dòng thì truyền Ref, không có thì truyền giá trị rỗng.
  4. Đặt form mới lên home page thay cho list form cũ.
  ```bsl
  &AtClient
  Procedure ListOnActivateRow(Item)
  	// lấy CurrentData của table List
  	If ___ Then
  		___ // tham số Ref = Ref của dòng hiện tại
  	Else
  		___ // tham số Ref = Undefined -> bảng products rỗng
  	EndIf;
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Quên trường hợp `CurrentData = Undefined` (DB chưa có document hoặc filter không khớp) dẫn tới lỗi runtime.
  - `Ref` không hiển thị và không bật Use always, nên `CurrentData.Ref` không có giá trị.
  - Sửa list form mặc định làm thay đổi list ở mọi nơi khác trong chương trình.
  - Gọi `&AtServer` trong OnActivateRow gây nhấp nháy hoặc lặp event.
- **Tự kiểm tra:** Trên home page, chuyển giữa các document: bảng dưới đổi theo và chỉ có product. Đặt filter không khớp document nào thì bảng rỗng, không có lỗi. Mở list Sales invoice từ section Sales: list không có bảng phụ.

### Bài tập 2 — Mở item Products khi chọn dòng trong bảng mới

- **Đề bài (tóm tắt):** Double-click hoặc Enter trên dòng của bảng products vừa tạo thì mở item form của Products.
- **Gợi ý 1 — Hướng đi:** Event **Selection** của form table chạy khi user chọn dòng. `ShowValue()` mở form chuẩn của giá trị khi để trống tham số đầu (theo đề).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Handler `&AtClient` cho event Selection của bảng products, signature `(Item, SelectedRow, Field, StandardProcessing)`; đọc `Items.<Bảng>.CurrentData.Product`.
- **Gợi ý 3 — Khung bài làm:**
  1. Gán handler Selection cho bảng qua Properties palette.
  2. Lấy dòng hiện tại; nếu Product đã điền thì gọi `ShowValue` với tham số đầu để trống.
  ```bsl
  &AtClient
  Procedure ___Selection(Item, SelectedRow, Field, StandardProcessing)
  	// lấy CurrentData, kiểm tra Product đã điền
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Viết procedure trong form module nhưng không gán vào event thì không có tác dụng (form handler phải gán tường minh).
  - Không kiểm tra giá trị rỗng trước khi mở form.
- **Tự kiểm tra:** Double-click một dòng thì item form của product đó mở ra; Enter trên dòng cũng mở như vậy.

### Bài tập 3 — Event subscription điền Company mặc định cho mọi document

- **Đề bài (tóm tắt):** Tự động điền Company mặc định vào mọi document có attribute Company, kể cả document tạo sau này, mà developer không phải viết thêm code. Company mặc định chỉ tồn tại khi có **đúng một** company chưa đánh dấu xoá. Function lấy company mặc định đặt trong manager module của Companies, và chỉ điền khi Company còn trống.
- **Gợi ý 1 — Hướng đi:** Mục "Event subscriptions": **Source** = mọi document (type `DocumentObject`), **Event** = `Filling`, handler là export procedure trong common module **Server**. Subscription chạy **sau** handler Filling riêng của document, nên phải kiểm tra trống trước khi điền để tôn trọng thuật toán riêng.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Event Subscription: Source / Event / Handler.
  - Common module (flag Server): procedure Export `(Source, FillingData, FillingText, StandardProcessing)`.
  - Kiểm tra document có attribute Company bằng `Source.Metadata().Attributes.Find(...)`.
  - Manager module của Catalog Companies: function Export trả company mặc định. Query dùng `SELECT FIRST 2` / `TOP 2` + điều kiện không đánh dấu xoá; đếm bằng `Selection.Count()` (đề gọi là Quantity()).
- **Gợi ý 3 — Khung bài làm:**
  1. Viết function trong manager module: query tối đa 2 company hợp lệ; đúng 1 thì trả ref đó, ngược lại trả ref rỗng.
  2. Viết handler trong common module: không có attribute thì Return; đã điền thì bỏ qua; còn lại gọi function.
  3. Tạo Event Subscription trỏ tới handler.
  ```bsl
  Procedure ___Filling(Source, FillingData, FillingText, StandardProcessing) Export
  	// 1) document không có attribute "Company" -> Return
  	___
  	// 2) chỉ điền khi Company còn trống -> gọi function của manager module
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Ghi đè Company vô điều kiện. [ghi chú ngoài nguồn] Bản demo của bài Theory (mục "Code demo" bên dưới) gán thẳng và **không** kiểm tra trống, nên làm mất giá trị do Filling riêng của document điền trước. Bài Practice phải kiểm tra.
  - Query chọn tất cả company thay vì 2 bản ghi; hoặc quên điều kiện DeletionMark.
  - Common module không bật flag Server, hoặc procedure không Export.
  - Chọn Source là một vài document cụ thể thay vì `DocumentObject`, nên document mới tạo sau này không được điền.
- **Tự kiểm tra:** Khi có đúng 1 company hợp lệ: tạo mới bất kỳ document có Company thì field được điền sẵn. Thêm company thứ 2 (hoặc đánh dấu xoá company duy nhất) thì field trống. Tạo document "based on" có Company riêng thì giá trị riêng được giữ.

### Bài tập 4 — Posting Sales invoice: phân bổ batch FIFO/LIFO/Manually

- **Đề bài (tóm tắt):** Khi post Sales invoice, đọc constant WriteOffOrder. Với FIFO/LIFO, tính batch trong query theo balance và chia số lượng qua các batch (ví dụ 20 = 5 + 10 + 5). Với Manually, dùng batch user đã chọn. Mọi trường hợp đều kiểm tra tồn theo batch (nếu company bật kiểm soát).
- **Gợi ý 1 — Hướng đi:** Lấy balance theo product + batch từ virtual table **Balance** của GoodsInWarehouses, sắp xếp theo ngày của batch (tăng dần cho FIFO, giảm dần cho LIFO). Duyệt selection và giữ một biến "còn phải xuất"; mỗi batch xuất `Min(còn phải xuất, tồn của batch)` rồi trừ dần. Khi re-post, movements cũ của chính document không được tính vào balance.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Object module, handler `Posting(Cancel, Mode)`.
  - Constant `WriteOffOrder`, enum các cách xuất (FIFO / LIFO / Manually).
  - Query batch: temporary table chứa products của document (gộp theo product), LEFT JOIN `GoodsInWarehouses.Balance(&PointInTime, ...)`, ORDER BY product rồi ngày của batch.
  - Hàm `Min()`; `RegisterRecords.GoodsInWarehouses.Add()`, RecordType Expense.
  - Loại movements cũ: tab Posting của document đặt **Register records deletion = AutoDelete**, hoặc ghi một record set rỗng trước query (tip trong đề).
  - Kiểm tra tồn: procedure chung từ bài 15 (truyền Company).
- **Gợi ý 3 — Khung bài làm:**
  1. Đọc WriteOffOrder. Nếu khác Manually thì chọn chiều sắp xếp và chạy query balance theo batch.
  2. Duyệt selection: gặp product mới thì nạp lại biến "còn phải xuất"; đã đủ thì bỏ qua các batch còn lại.
  3. Mỗi batch: tính số xuất, thêm một record Expense có Batch, trừ biến.
  4. Còn thiếu hàng (khi chuyển product và sau vòng lặp) thì Cancel kèm thông báo.
  5. Manually: ghi theo Batch của từng dòng document.
  6. Ghi movements rồi gọi kiểm tra tồn theo batch.
  ```bsl
  While Selection.Next() Do
  	If ___ Then        // sang product mới
  		___            // báo thiếu của product trước (nếu còn), nạp lại "còn phải xuất"
  	ElsIf ___ Then     // đã xuất đủ cho product này
  		Continue;
  	EndIf;
  	___                // số xuất = min(...), thêm record Expense có Batch, trừ "còn phải xuất"
  EndDo;
  ```
- **Lỗi hay gặp:**
  - Re-post làm balance tính trùng với movements cũ của chính document. Đặt AutoDelete hoặc ghi set rỗng **trước** query.
  - Chỉ kiểm tra thiếu hàng sau vòng lặp, nên bỏ sót product ở giữa danh sách. Phải kiểm tra cả khi chuyển product.
  - Nối chiều sắp xếp vào query text nhưng quên khoảng trắng.
  - Quên ISNULL cho product không có balance, dẫn tới NULL trong phép tính.
- **Tự kiểm tra:** Dựng đúng ví dụ trong đề (Batch 1/2/3 = 5/10/15, bán 20). Post với FIFO, xem Register records: 5 + 10 + 5. Đổi sang LIFO, re-post: 15 + 5. Bán 40 thì bị chặn. Re-post nhiều lần, kết quả không đổi.

### Bài tập 5 — Return of goods from customer: dòng chỉ theo Sales document, trả batch theo thứ tự ngược

- **Đề bài (tóm tắt):** Tabular section chỉ được điền từ Sales document. User chỉ được xoá dòng hoặc giảm quantity, không thêm dòng; cột Batch chỉ hiện khi Manually. Movements: Manually thì ghi theo batch của dòng; FIFO/LIFO thì trả batch **muộn trước** (FIFO) hoặc **sớm trước** (LIFO), dựa trên records của sales document.
- **Gợi ý 1 — Hướng đi:**
  - Chặn thêm dòng bằng event **BeforeAddRow** của form table (mục "Form table events").
  - Ẩn cột Batch trong form event server, giống Sales invoice.
  - Batch để trả lấy từ records mà **chính Sales document** đã ghi: virtual table **Turnovers** với periodicity Recorder, lọc theo `Recorder = &SalesInvoice`, sắp xếp ngược với lúc bán. Thuật toán chia số lượng giống thẻ 4.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form module: `ProductsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)` (`&AtClient`), `OnCreateAtServer`; các column không cho sửa (Product, Batch, Price, Amount) đặt ReadOnly.
  - Object module: event `Filling` điền từ `DocumentRef.SalesInvoice` (gộp dòng như Sales document, kèm Batch).
  - `Posting`: với FIFO/LIFO dùng `GoodsInWarehouses.Turnovers(..., Recorder, ...)` lấy QuantityExpense/AmountExpense theo batch; Manually dùng batch của dòng.
  - Cách ghi movement trả hàng: Receipt, hoặc Expense với số **âm** (storno). Chọn một cách và dùng thống nhất.
- **Gợi ý 3 — Khung bài làm:**
  1. Form: chặn thêm dòng, ẩn Batch khi không Manually, khoá các cột không được sửa.
  2. Filling: điền header và dòng từ Sales invoice.
  3. Posting FIFO/LIFO: query turnovers của sales document theo batch, sắp xếp ngược; duyệt và chia như thẻ 4, mỗi batch tối đa bằng số đã xuất.
  4. Posting Manually: mỗi dòng một record theo batch của dòng.
  ```bsl
  &AtClient
  Procedure ProductsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
  	___ // từ chối thêm dòng (kể cả copy)
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Sắp xếp batch cùng chiều với lúc bán. Khi trả hàng phải **ngược lại**: FIFO trả batch muộn trước.
  - Lấy batch từ balance hiện tại thay vì records của sales document.
  - [ghi chú ngoài nguồn] Lời giải tham khảo của khóa không báo lỗi khi số trả **vượt** số đã bán. Nên tự thêm kiểm tra "còn dư sau vòng lặp".
  - Dùng event OnChange của table để chặn thêm dòng là quá muộn; phải dùng BeforeAddRow.
- **Tự kiểm tra:** Tạo Return "based on" Sales invoice ở ví dụ 20 hammers (FIFO 5/10/5), giảm quantity xuống 10 rồi post. Register records phải là 5 của Batch 3 và 5 của Batch 2. Thử thêm dòng: không được. Đổi sang Manually: cột Batch hiện ra.

### Bài tập 6 — Nút "Fill by sales document" gọi event Filling chuẩn

- **Đề bài (tóm tắt):** Thêm nút trên header của Return of goods from customer để điền lại document đúng như khi tạo "based on" Sales invoice.
- **Gợi ý 1 — Hướng đi:** Không viết lại thuật toán điền. Gọi method `Fill()` của **document object**: platform chạy event `Filling` của object module, giống khi tạo "based on". Trên form phải chuyển form data sang object rồi đưa kết quả về form.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form command + handler `&AtClient`; kiểm tra `Object.SalesDocument` đã điền.
  - Hỏi xác nhận non-modal: `ShowQueryBox` + `CallbackDescription`; callback Export kiểm tra `DialogReturnCode.Yes`.
  - Procedure `&AtServer`: `FormAttributeToValue("Object")` → `Fill(...)` → `ValueToFormAttribute(...)`.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo command, đặt nút vào header.
  2. Handler client: Sales document trống thì báo; có thì hỏi xác nhận.
  3. Callback: Yes thì gọi procedure server.
  4. Procedure server: chuyển sang object, gọi Fill với Sales document, đưa về form.
  ```bsl
  &AtServer
  Procedure ___AtServer()
  	___ // form data -> document object
  	___ // gọi Fill(...) với Sales document -> chạy event Filling
  	___ // document object -> form data
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Dùng câu hỏi modal (`DoQueryBox`) thay vì `ShowQueryBox` có callback.
  - Copy lại code điền vào form thay vì gọi `Fill()`, khi đó hai nơi lệch nhau.
  - Callback quên Export.
- **Tự kiểm tra:** Sửa vài dòng rồi bấm nút, trả lời Yes: document trở lại như mới tạo "based on". Trả lời No thì không có gì thay đổi.

### Bài tập 7 — Amount trong GoodsInWarehouses theo giá vốn

- **Đề bài (tóm tắt):** Sales invoice: Amount xuất kho = giá vốn theo balance của batch (ví dụ 1500/15 × 5 = 500). Return of goods: Amount = giá vốn tính từ records của sales document (Turnovers). Phải tránh chia cho 0.
- **Gợi ý 1 — Hướng đi:** Trong cùng query lấy batch ở thẻ 4 và 5, tính thêm "giá đơn vị" = AmountBalance / QuantityBalance (Sales invoice) hoặc AmountExpense / QuantityExpense của sales document (Return). Record ghi `Amount = số lượng × giá đơn vị`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Field tính trong query, dùng `CASE WHEN <mẫu số> = 0 THEN 0 ELSE ... END` (bọc ISNULL khi có LEFT JOIN). Với Manually: query balance (hoặc turnovers) theo product + batch, rồi tìm dòng tương ứng cho mỗi dòng document (ví dụ `FindNext` với Structure filter, hoặc JOIN trong query).
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm field giá đơn vị có CASE chống chia 0 vào query FIFO/LIFO.
  2. Trong vòng lặp, Amount = số xuất × giá đơn vị.
  3. Nhánh Manually: lấy thêm giá đơn vị theo product + batch.
  4. Return: dùng giá từ turnovers của sales document.
- **Lỗi hay gặp:**
  - Chia cho 0 khi batch hết tồn hoặc không có record dẫn tới exception. Luôn dùng CASE.
  - Vẫn ghi Amount theo giá bán của document, khiến balance amount âm dần (ví dụ pencil 50/70 trong đề).
  - Return dùng giá vốn hiện tại thay vì giá trong records của sales document.
- **Tự kiểm tra:** Theo ví dụ trong đề, xem Register records của Sales invoice: Amount của từng batch bằng số lượng × (amount tồn / quantity tồn). Sau khi bán hết một product, balance amount phải bằng 0, không âm. Return 7 pencils (5 Batch1 + 2 Batch2) thì Amount là 250 và 104.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/16-theory)

### StartChoice cho operation Dismissal: chỉ chọn nhân viên đang làm việc

Nguồn: nhánh lesson/16-theory — cf/Documents/PersonnelChange/Forms/DocumentForm/Ext/Form/Module.bsl; cf/Catalogs/Employees/Forms/WorkingEmployees/Ext/Form/Module.bsl; cf/Catalogs/Employees/Forms/WorkingEmployees/Ext/Form.xml (query của dynamic list)

Form module của document PersonnelChange (handler gán cho field `ChangesEmployee`):

```bsl
&AtClient
Procedure ChangesEmployeeStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsPersonnelChange.Dismissal") Then
		StandardProcessing = False;
		
		OpenParameters = New Structure("Filter", New Structure("Date, Company", Object.Date, Object.Company));
		
		OpenForm("Catalog.Employees.Form.WorkingEmployees", OpenParameters, Item);
	EndIf;

	//FillChoiceData(ChoiceData);

EndProcedure
```

Choice form `WorkingEmployees` của catalog Employees:

```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not Parameters.Property("Filter") Then
		Raise "Parameters should contain Filter property";
	EndIf;
	
	List.Parameters.SetParameterValue("Date", 		Parameters.Filter.Date);
	List.Parameters.SetParameterValue("Company", 	Parameters.Filter.Company);
		
EndProcedure
```

Query của dynamic list `List` (ManualQuery = true):

```bsl
SELECT
	Employees.Ref AS Employee,
	EmployeesSliceLast.Position AS Position,
	EmployeesSliceLast.Department AS Department,
	EmployeesSliceLast.Employee.DateOfBirth AS DateOfBirth
FROM
	InformationRegister.Employees.SliceLast(&Date, Company = &Company) AS EmployeesSliceLast
		INNER JOIN Catalog.Employees AS Employees
		ON EmployeesSliceLast.Employee = Employees.Ref
WHERE
	EmployeesSliceLast.Works
```

- Đúng ví dụ trong bài: operation kind = Dismissal → `StandardProcessing = False`, mở form `WorkingEmployees` với `Filter` (Date, Company) và truyền `Item` làm **Owner** → giá trị chọn tự điền vào ô, không cần ChoiceProcessing.
- Operation khác Dismissal → không đụng tới StandardProcessing, platform mở choice form mặc định.
- `OnCreateAtServer` của choice form `Raise` nếu thiếu property `Filter`, rồi đặt parameters `Date`/`Company` cho dynamic list; form này **không** đặt làm default choice form.
- Query: catalog Employees làm main table (INNER JOIN với `SliceLast` của information register Employees, điều kiện `Works`) để dynamic list trả về ref nhân viên. Procedure `FillChoiceData` (gán `ChoiceData` là ValueList) cũng có trong module nhưng lời gọi đang bị comment.

### Phần response handler của BeforeClose: attribute CloseWithoutChecking

Nguồn: nhánh lesson/16-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl; cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form.xml

```bsl
&AtClient
Procedure BeforeCloseAnswer(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		CloseWithoutChecking = True;
		Close();
	EndIf;

EndProcedure
```

```xml
		<Attribute name="CloseWithoutChecking" id="8">
			<Title>
				<v8:item>
					<v8:lang>en</v8:lang>
					<v8:content>Close without checking</v8:content>
				</v8:item>
			</Title>
			<Type>
				<v8:Type>xs:boolean</v8:Type>
			</Type>
		</Attribute>
```

- Đây là phần (2) của hội thoại non-modal trong bài: user trả lời Yes → đặt `CloseWithoutChecking = True` rồi gọi `Close()` lần nữa.
- Form attribute `CloseWithoutChecking` kiểu Boolean (mặc định False) đúng như mô tả lý thuyết.
- Nhánh **chưa có** procedure `BeforeClose` (phần (1): hỏi user, `Cancel = True`, kiểm tra `CloseWithoutChecking`) — form cũng chưa gán event BeforeClose, nên phần này vẫn chỉ có trong ảnh của tài liệu.

### Một handler Price dùng chung cho Products và Services (Item.Parent)

Nguồn: nhánh lesson/16-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl; cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form.xml

```bsl
&AtClient
Procedure FillAmountInCurrentData(CurrentData)
	
	CurrentData.Amount = CurrentData.Price * CurrentData.Quantity;
	
EndProcedure
// ...
&AtClient
Procedure ProductsServicesPriceOnChange(Item)
	
	CurrentData = Item.Parent.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillAmountInCurrentData(CurrentData);
	
EndProcedure
```

```xml
									<Events>
										<Event name="OnChange">ProductsServicesPriceOnChange</Event>
									</Events>
```

- Ví dụ "một handler cho nhiều field" của bài: field Price của cả Products và Services cùng gán `ProductsServicesPriceOnChange` (tên không gắn với một element cụ thể).
- `Item.Parent.CurrentData` lấy dòng hiện tại của chính form table chứa field vừa đổi → một procedure phục vụ cả hai tabular section.
- Đây là phiên bản demo trong form module: procedure client `FillAmountInCurrentData` không có discount.

### BeforeWriteAtServer: Object và CurrentObject, ghép DeliveryAddress

Nguồn: nhánh lesson/16-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl

```bsl
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//CurrentWorkplace = CommonClient.CurrentWorkplace();
	//WriteParameters.Insert("Workplace", CurrentWorkplace);
	WriteParameters.Insert("NewObject", Object.Ref.IsEmpty());
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// This code doesn't change the object of document,
	// because the object is already placed in the CurrentObject parameter
	Object.Date = EndOfDay(Object.Date);
	
	// That's why we should work with CurrentObject to change the object
	CurrentObject.Date = EndOfDay(CurrentObject.Date);
	
// ...
	FillDeliveryAddress();
	
EndProcedure
// ...
&AtServer
Procedure FillDeliveryAddress()
	
	AddressParts = New Array;
	AddressParts.Add(City);
	AddressParts.Add(District);
	AddressParts.Add(Street);
	AddressParts.Add(Building);
	AddressParts.Add(Apartment);

	// StrConcat function merges an array of strings passed (the first parameter) 
	// into a single string with the specified separator (the second parameter) 
	Object.DeliveryAddress = StrConcat(AddressParts, ", ");
	
EndProcedure
```

- Form `BeforeWrite` (client) thêm property `NewObject` vào `WriteParameters` để dùng ở các bước sau (AfterWrite).
- `BeforeWriteAtServer` minh hoạ trực tiếp quy tắc: gán `Object.Date` **không** có tác dụng, phải sửa qua `CurrentObject.Date`.
- Form còn có `FillCheckProcessingAtServer` xoá City/District/Street/Building/Apartment khỏi `CheckedAttributes` khi không bật `DeliveryIsRequired`, và `AfterWriteAtServer` → `FillInSoldThisMonth()` điền cột SoldThisMonth bằng query turnovers — đúng hai ví dụ của sơ đồ events (cùng file).
- [ghi chú ngoài nguồn] `FillDeliveryAddress()` vẫn gán vào `Object.DeliveryAddress` dù được gọi từ BeforeWriteAtServer — theo chính quy tắc trên, giá trị này sẽ không được ghi; nên gán `CurrentObject.DeliveryAddress`.

### Event subscription FillDocumentCompany (phiên bản demo của bài)

Nguồn: nhánh lesson/16-theory — cf/EventSubscriptions/FillDocumentCompany.xml; cf/CommonModules/DocumentsCommonFilling/Ext/Module.bsl

```xml
			<Source>
				<v8:TypeSet>cfg:DocumentObject</v8:TypeSet>
			</Source>
			<Event>Filling</Event>
			<Handler>CommonModule.DocumentsCommonFilling.FillDocumentCompanyFilling</Handler>
```

```bsl
Procedure FillDocumentCompanyFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	MetadataObject = Source.Metadata();
	If MetadataObject.Attributes.Find("Company") = Undefined Then
		Return;
	EndIf;
	
	Source.Company = Constants.DefaultCompany.Get();
	
EndProcedure
```

- Đúng tên subscription trong ảnh của bài: Source = `DocumentObject`, Event = `Filling`, Handler trỏ tới export procedure trong common module.
- Lưu ý: bản demo gán thẳng `Constants.DefaultCompany.Get()` và **không** kiểm tra `ValueIsFilled(Source.Company)`, nên ghi đè cả giá trị do Filling riêng của document điền trước đó (subscription chạy sau handler của object). Bài Practice 16 yêu cầu chỉ điền khi Company còn trống → xem Thẻ gợi ý bài tập 3.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Sự kiện và trình xử lý sự kiện](https://www.youtube.com/watch?v=FAkymD2Zqks&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=10) (9:29) — Bài 9 — form events; Bài 16 — form & form element events, thứ tự events _(mã nội bộ JC-11)_

<!-- video-qa-thuchanh:start -->

Video giải đáp tình huống thực chiến và video thực hành từng bước liên quan tới bài này (thẻ chi tiết, triệu chứng, lưu ý khi giới thiệu: `references/video-qa-thuc-chien.md`, `references/video-thuc-hanh.md`; cùng mẫu câu dẫn ở trên):

- [Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng](https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1) (4:24) — cách tìm lỗi sự kiện OnChange không chạy (giải đáp tình huống; Bài 16 chính) _(mã nội bộ QA-1)_
- [Kiểm tra dữ liệu trùng lặp](https://www.youtube.com/watch?v=603j21ItABk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=11) (8:55) — cảnh báo dữ liệu trùng (giải đáp tình huống; Bài 16 chính) _(mã nội bộ QA-11)_
- [Hủy sự kiện đang thực thi](https://www.youtube.com/watch?v=rW40s85Gtc4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=16) (3:18) — chặn ghi bằng Cancel = True (giải đáp tình huống; Bài 16 chính) _(mã nội bộ QA-16)_
- [Lấy giá tự động](https://www.youtube.com/watch?v=oMowT1e019k&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=5) (8:32) — tự điền giá theo bảng giá (giải đáp tình huống; Bài 16 liên quan) _(mã nội bộ QA-5)_
- [Thêm ảnh cho các đối tượng](https://www.youtube.com/watch?v=TQNa4cveOdc&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=6) (10:04) — lưu và hiển thị ảnh cho sản phẩm (giải đáp tình huống; Bài 16 liên quan) _(mã nội bộ QA-6)_
- [Xây dựng các trường tự động điền](https://www.youtube.com/watch?v=8klMmoJXBCk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=10) (2:02) — giá trị mặc định khi tạo chứng từ (giải đáp tình huống; Bài 16 liên quan) _(mã nội bộ QA-10)_
- [Tự động lấy đơn vị tính của sản phẩm](https://www.youtube.com/watch?v=RKAGi62Vy5E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=12) (8:16) — điền thuộc tính sản phẩm vào dòng chứng từ (giải đáp tình huống; Bài 16 liên quan) _(mã nội bộ QA-12)_
- [Lưu trữ thông tin các chuyến du lịch](https://www.youtube.com/watch?v=PwqP4GODNrY&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=6) (13:15) — tạo chứng từ trên cơ sở chứng từ khác (Input on basis) (thực hành case study; Bài 16 liên quan) _(mã nội bộ P1-5)_
- [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28) — xử lý nhiều đơn hàng bằng một lệnh (thực hành case study; Bài 16 liên quan) _(mã nội bộ P2-6)_

<!-- video-qa-thuchanh:end -->
