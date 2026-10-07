# Bài Extensions — Configuration extensions (Mở rộng cấu hình)

## Khái niệm chính

### Giới thiệu
- **Configuration extension mechanism**: cơ chế mở rộng configuration **mà không thay đổi nó** (và không cần gỡ khỏi support). Extension là "add-on" kết nối vào main configuration và chạy bên trên nó.
- Đơn giản hóa:
  - **Configuration updates**: configuration không bị gỡ khỏi vendor support → cập nhật tự động, không phải so sánh object đã sửa với version mới.
  - **Bug fixes**: sửa lỗi trong extension và bật trong infobase, không cần phát hành full release và cập nhật tốn thời gian.
  - Tạo chức năng/subsystem mới phân phối cho nhiều infobase hoặc nhiều khách hàng.
- Configuration được áp extension gọi là **extended configuration**. Extension cho phép:
  - Tạo object mới.
  - Sửa object có sẵn: thêm subordinate objects (attributes, tabular sections, commands, templates); thay đổi object forms.
  - Sửa (thêm/thay thế) procedures và functions, kể cả event handlers.
- Để sửa object có sẵn phải thêm nó vào extension — gọi là **adopted** objects.

### Làm việc với extension
- Mở danh sách: menu **Configuration - Configuration extensions**. Có thể thêm, sửa, xóa, đặt active/inactive.
- Extension **inactive** vẫn có thể ảnh hưởng cấu trúc bảng DB nhưng đang bị tắt (không ảnh hưởng hành vi của configuration).
- Khi tạo extension phải chỉ định **name, synonym, prefix, purpose**.
- **Prefix** tự thêm vào metadata object mới tạo trong extension và event handler tạo trong adopted forms. Ví dụ prefix "crm_" → catalog mới tên **crm_Catalog1**.
- Double-click extension trong danh sách → mở cây configuration của extension; object duy nhất ban đầu là role tự tạo, dùng làm default role của extension.
- Prefix đổi được trong quá trình làm việc, nhưng object đã tạo giữ prefix cũ — trừ role tự tạo được gán vào property **"Default roles"** của extension. Tên role mặc định theo quy tắc **<prefix>+"DefaultRole"**; khi đổi prefix platform gợi ý đổi tên theo quy tắc với prefix mới.
- Số extension trên một infobase không giới hạn. **Thứ tự thực thi** phụ thuộc **purpose** và **thứ tự thêm vào infobase** (xem trong danh sách extension). Ví dụ: extension "Patch" đứng đầu; extension "AddOn" đứng cuối; extension "Customization" thêm sau "CRMImprovement" (cùng purpose) đứng sau nó.

### Property Purpose
- **Patch**: sửa lỗi ứng dụng. Được dự kiến dùng các tính năng "nguy hiểm" tiềm ẩn (ví dụ method extension với annotation **Around**). Dành cho một version ứng dụng cụ thể; khi có version mới tác giả phải phân tích khả năng áp dụng. Cho phép nhiều extension Patch nhưng phải đảm bảo không xung đột (ví dụ nhiều extension không được mở rộng cùng một method với mục đích khác nhau). Không cần xét extension có purpose khác.
- **Customization**: điều chỉnh ứng dụng theo yêu cầu khách hàng cụ thể. Khuyến nghị không dùng tính năng "nguy hiểm" (có thể gây xung đột khi chạy cùng nhau hoặc phụ thuộc thứ tự kết nối). Được dùng cẩn thận nếu tác giả chịu hoàn toàn trách nhiệm về hoạt động đúng trong version mới, có xét các extension Patch. Giả định mỗi thời điểm có số lượng tối thiểu extension loại này; nếu không gộp được vào một extension thì chia thành các khối lớn nhất của ứng dụng.
- **Add-on**: tính năng mới ít gắn với version ứng dụng (ví dụ bộ report mới). Phải chạy đúng khi ứng dụng được cập nhật; không được xét sự hiện diện của extension purpose khác. Số lượng tùy ý.

### Extension "Patch" — ví dụ
- Document PurchaseOrder mới trong SSL demo, tabular section Products (Product, Quantity, Price, Amount). Handler OnChange của cột Amount tính lại Price = Amount/Quantity, cố ý không kiểm tra Quantity = 0 → lỗi chia cho 0.
- Tạo extension purpose "Patch". Đặt tên patch theo số task trong hệ thống quản lý task (ví dụ "Bigfix123") thay vì tên dài như "OrderToSupplierDivideByZeroFix"; nói chung nên đặt tên theo chức năng.
- Mở rộng procedure **CalculatePriceAtRow**: đặt con trỏ trong procedure/khai báo → chuột phải → **"Add to Extension"**. Nhiều extension → platform hỏi chọn extension. Sau đó chọn **call type**:
  - Call before...
  - Call after...
  - Call instead of...
  - Call instead (with control)...
- **"Before"**: method extension chạy trước, rồi đến method configuration.
- **"After"**: method configuration chạy trước, rồi đến method extension.
- **"Instead of"**: method configuration không chạy, bị thay hoàn toàn. Thường dùng trong extension "Patch". Vẫn có thể gọi thuật toán chuẩn bằng method đặc biệt **ProceedWithCall()**; method "Instead" tạo ra đã chứa lời gọi ProceedWithCall() (có thể xóa).
- **"Instead (with control)"**: sửa có mục tiêu một hoặc vài phần của method, phần còn lại chạy theo thuật toán chuẩn.

### &Around annotation
- Chọn "Instead of" → document form và document tự động được thêm vào extension. **Note**: không thêm subordinate metadata objects (attributes, tabular sections...).
- Xóa ProceedWithCall() và viết thuật toán tính giá mới xét Quantity = 0.
- Procedure được khai báo với annotation **"Around"** và tên có prefix tự thêm.

### Extension "Customization" — ví dụ
- Yêu cầu: cột Discount (%) và AmountAfterDiscount = `Amount - Amount * Discount / 100` (ví dụ 150 - 150 * 10 / 100 = 135); tính lại khi Amount hoặc Discount thay đổi.
- Tạo extension "Customization" tên CRMImprovement. Thêm form PurchaseOrder → hiện cửa sổ chọn extension (vì có 2 extension).
- **Information**: để khỏi chọn extension mỗi lần, đóng mọi cửa sổ cây configuration của các extension trừ extension đang cần.
- Thêm tabular section Products vào extension → chỉ tabular section được thêm, attributes của nó không. Tạo 2 attribute riêng.
- Đặt synonym có ý nghĩa (ví dụ "Discount", không để user thấy prefix).
- crm_AmountAfterDiscount cần kiểu như Amount — **DefinedType.MonetaryAmountNonNegative** — chưa có trong extension. Có thể thêm trực tiếp, hoặc thêm attribute dùng kiểu đó (ví dụ attribute Amount) → defined type tự được adopt **by reference**. Không nên thêm object không cần.
- Adopted form: mặc định làm việc được với form **elements**, nhưng không làm việc được với form **attributes, commands, form parameters** (chữ xám, flag tắt, properties không sửa được). Attribute adopted có icon **mảnh ghép (puzzle)**, chưa adopted có icon **hình tròn**. Để truy cập attribute mới của tabular section → thêm main form attribute **Object** vào extension.
- Khi adopt main form attribute, mọi object được tham chiếu cũng được adopt (có ngoại lệ hiếm — xem tài liệu platform).
- Tạo event handler cho field gắn với property tạo trong extension, platform vẫn hỏi chọn "Before", "After", "Instead" — trường hợp này không quan trọng, có thể luôn chọn mặc định "After".
- Handler OnChange của Amount đã được mở rộng trong extension Patch → **không nên** dùng "Instead" ("Around") trong extension mới; không cần chạy trước → chọn **"After"**.
- Khi mở rộng handler từ main configuration, platform hỏi mở rộng **event handler** (khuyến nghị) hay **method**. Nếu chỉ mở rộng procedure mà không mở rộng event handler, khi event handler trong main configuration bị xóa thì procedure mở rộng không được gọi nữa. Mở rộng event handler tương đương tạo handler từ form của extension và hoạt động bất kể main configuration có handler cho event đó hay không.
- Kết quả: khi OnChange của Amount xảy ra, handler của extension "Patch" chạy trước (thay handler lỗi), sau đó handler của extension "Customization".

### &ChangeAndValidate annotation
- Thuộc call type "Instead (with control)". Dùng khi cần sửa một phần thuật toán chuẩn mà không dùng được "Before"/"After" (ví dụ sửa giữa method), còn "Around" không mong muốn vì nếu code method thay đổi khi cập nhật configuration thì thuật toán mới sẽ không chạy (Around ghi đè hoàn toàn).
- Method với "ChangeAndValidate" cho phép xóa/thêm dòng có chọn lọc; nếu phát hiện khác biệt giữa code đã lưu trong extension và code trong main configuration, method sẽ **ngừng mở rộng** method gốc (extension ngừng áp dụng cho method đó nhưng vẫn hoạt động ở các phần khác).
- Ví dụ: print form "Purchase order" hiển thị AmountAfterDiscount thay Amount, giữ nguyên header cột.
- **Lưu ý**: annotation "Before" và "After" **không khả dụng cho functions**.
- Method mở rộng với ChangeAndValidate được adopt **toàn bộ code**.
- Preprocessor directives: **#Delete / #EndDelete** để xóa dòng; **#Insert / #EndInsert** để chèn code. Thứ tự không quan trọng, miễn mọi code ngoài các directive giữ nguyên như method adopted.
- **Information**: query có text sửa bằng các preprocessor directive không mở được bằng query builder.
- Lỗi khi mở list PurchaseOrder: extension chạy ở **safe mode**, mặc định chỉ cho phép mở rộng client-side và server-side form handlers. Mở rộng method trong object manager module → extension không qua security check. Giải pháp: tắt flag **safe mode** và khởi động lại ứng dụng.

### &Around annotation cho functions
- Dùng "Around" và ProceedWithCall() thay cho "Before"/"After" (không khả dụng cho functions).
- Ví dụ: function trả turnover counterparty theo kỳ; nếu không truyền begin/end date thì chỉ lấy dữ liệu năm gần nhất (function đã điền EndDate rỗng bằng ngày hiện tại nhưng không kiểm tra BeginDate → lấy toàn bộ kỳ, chạy lâu).
- **Giá trị mặc định của parameter không được chuyển sang extension.**
- ProceedWithCall() gọi function gốc và trả kết quả. Code sau ProceedWithCall() và trước khi trả Result (có thể thay bằng giá trị riêng) ≈ "After". Code trước khi gọi function gốc (có thể không gọi nếu không cần) ≈ "Before".
- Đổi BeginDate, EndDate không ảnh hưởng code bên ngoài vì parameter khai báo với từ khóa **"Val"**.
- Emulate "After": biến Result chứa giá trị function gốc trả về; sửa rồi mới return (ví dụ thêm/bớt phần tử array).

### Lưu và load extension từ file
- Làm việc với extension như với configuration: lưu ra file, load từ file, so sánh và merge, syntax check...
- Không cần vào Designer để kết nối/cập nhật extension — làm được từ **Enterprise mode**: user có quyền quản trị phía client có thể tự load extension, thêm/cập nhật từ file, xóa, lưu ra file, quản lý properties như **Activity (Active)**.

### Lưu dữ liệu thêm trong extension vào bảng DB
- Adopt một catalog (ví dụ "Counterparties") **không** ảnh hưởng cấu trúc DB.
- **Note**: khi chưa có extension nào ảnh hưởng cấu trúc lưu trữ của metadata object, dữ liệu lưu trong bảng ban đầu.
- Thêm attribute mới (ví dụ "IsCustomer" Boolean) → lần cập nhật sau platform cảnh báo cần **restructure DB**: tạo bảng mới cho catalog có cột mới, chuyển mọi dữ liệu từ bảng gốc sang. Bảng gốc vẫn còn nhưng không còn record.
- Dù bao nhiêu extension khác sửa cấu trúc catalog, dữ liệu vẫn lưu trong cùng bảng mới miễn còn ít nhất một extension sửa cấu trúc object (thêm/sửa attribute hoặc tabular section).
- Nếu không còn extension nào ảnh hưởng cấu trúc (bị xóa, hoặc attributes/tabular sections bị xóa khỏi extension) → sau lần restructure tiếp, dữ liệu chuyển về bảng gốc; dữ liệu của attributes/tabular sections chỉ có trong extension **mất vĩnh viễn**.
- Extension **inactive** vẫn ảnh hưởng cấu trúc bảng nhưng metadata objects và code không được dùng; tắt activity không ảnh hưởng dữ liệu đã lưu, chỉ không đọc từ bảng tương ứng — field của extension bị tắt không truy cập được trong query.

### Forms extension
- Adopt form = adopt version hiện tại. Form trong main configuration thay đổi → extension hiện cảnh báo đề nghị cập nhật form từ configuration.
- Không bắt buộc cập nhật mỗi lần, nhưng có thể ảnh hưởng usability. Thêm/xóa/di chuyển element trong extension rồi trong main configuration có thể làm vị trí element khác thay đổi dù không ai sửa trực tiếp (ví dụ form _DemoGoodsSales: di chuyển "Storage location" sang tab "Additional" trong extension, rồi trong main configuration sang tab "Proforma invoices" → sau cập nhật field "Currency" bị chuyển sang tab "Proforma invoices").
- Cập nhật bằng nút nền vàng tốn thời gian khi nhiều form/nhiều DB, và còn phải kiểm tra sau cập nhật.
- **Khuyến nghị: thay đổi thành phần form attributes, commands và giao diện (elements) bằng code**. Hai lý do: sửa song song element ở main configuration và extension; sửa đồng thời form trong nhiều extension.

### Tạo form element bằng code
- Ví dụ attribute crm_Amount trong tabular section Products của _DemoGoodsSales; handler **OnCreateOnServer** với call type "After".
- Method **Add()** của object **Items** trả về item tạo ra. Property chính: **"DataPath"** (form/object attribute liên kết) và **"Type"** (loại field/element).
- Đường dẫn attribute tabular section: `<TabularSectionName.AttributeName>`; nếu là tabular section của object (không phải bảng form attribute) thêm "Object": `<Object.TabularSectionName.AttributeName>`.
- **Insert()**: thêm parameter là element mà item mới chèn **trước** nó (ví dụ để field đứng sau cột Price).
- Gán event bằng code: method **SetAction()** của form item — chỉ định tên action và tên handler procedure; áp dụng cho cả item tạo bằng code lẫn tạo trong form designer. Phải giữ đúng tập và thứ tự parameter của handler (có thể tạo handler cho field có sẵn để xem parameter, rồi xóa handler thừa).

### Tạo form attribute và command bằng code
- Ví dụ: field "Percentage" (form attribute, không lưu DB) và nút "Change prices by percentage" tăng giá mọi dòng theo phần trăm.
- Form attribute: method **ChangeAttributes()** của form, 2 parameter tùy chọn **AttributesToBeAdded** và **AttributesToBeDeleted** (Array of **FormAttribute**, phải tạo trước). Đây là thao tác tốn tài nguyên → gọi càng ít càng tốt, thực hiện mọi thay đổi một lần.
- Kiểu form attribute: object **TypeDescription** với qualifiers cho number (total length, độ dài phần thập phân, allowed sign — any hoặc non-negative). Thêm FormAttribute vào array mới, truyền vào ChangeAttributes().
- Gọi procedure (AddOwnAttributesAndCommands()) trong OnCreateAtServer, rồi tạo field Percentage. Đặt field trong group mới → phải tạo group trước.
- DataPath của field gắn form attribute: ghi trực tiếp tên attribute, **không** có "Object".
- Tắt title group bằng property **"ShowTitle"** để tránh indent thừa.
- Command thêm từ manager **"Commands"** của form. Property chính:
  - **"Action"** — tên handler procedure (procedure có một parameter, Command).
  - **"ModifiesStoredData"** — flag nhấn nút làm thay đổi stored data → form được đánh dấu modified để platform hỏi xác nhận khi đóng form.
- Handler: kiểm tra Percentage đã điền; nếu có, duyệt mọi dòng tabular section và tăng Price; nếu không, thông báo user.
- Truy cập trực tiếp attribute tạo bằng code theo tên → lỗi **"Variable not defined"**. Giải pháp: truy cập qua property của **ThisObject** — `ThisObject.MyProperty` hoặc `ThisObject["MyProperty"]`.
- **Information**: attributes và tabular sections tạo bằng code không có trong context help (khi tham chiếu bằng dấu chấm). Khuyến nghị tham chiếu theo tên trong ngoặc vuông để cho người khác biết attribute có thể được tạo bằng code.
- Nút gắn command: chỉ định tên command ở property **CommandName**; title lấy từ command.

### Operations with adopted objects
- Adopted object chỉ chứa properties có thể đặt **controlled**, **checked** hoặc **modifiable**:
  - **Controlled property**: không khớp giữa extension và extended configuration → **không thể áp dụng** extension. Ví dụ với catalog _DemoCounterparties: "Extended configuration object", "Hierarchical", "Code Type", "Allowed code length".
  - **Property to check**: không khớp → **cảnh báo**, không ngăn áp dụng. Ví dụ: "Code length", "Description length".
  - **Property to modify**: ví dụ "Object module".
- Property modifiable trong object kết quả: lấy từ extension (với property chỉ một giá trị, như "Main form") hoặc kết hợp main configuration và extensions (property bổ sung được, như "Object module"). Nhiều extension → lấy giá trị từ extension **đứng cuối** danh sách.
- Property modifiable không chỉ định giá trị → hành vi như configuration thường với giá trị trống (ví dụ Main report form modifiable mà không chỉ form → form tự sinh).
- Property **Name** luôn là controlled. Đổi tên object trong extended configuration (ví dụ _DemoCounterparties → Counterparties) → extension ngừng hoạt động cho đến khi đặt cùng tên cho adopted object.
- Property extension **"Support mapping to extended configuration objects by internal IDs"**: theo dõi tương ứng theo internal ID của loại object; tự bật cho extension mới. Khi bật, property **Extended configuration object** (controlled) được điền cho mỗi adopted object (kể cả subordinate).
- Trong Designer có thể **check extension applicability**; hệ thống đưa phương án (áp dụng cho nhiều dòng):
  - **Rename and save match** — đặt tên object theo object trong extended configuration có internal ID đã lưu (nếu tồn tại và cùng metadata type).
  - **Save name and change match** — đặt internal ID của object cùng tên vào Extended configuration object.
  - **Select match** — đặt internal ID của object chọn thủ công.
  - **Disable check** — tắt property Extended configuration object.
  - **Clear match** — đặt giá trị nội bộ; property không được cập nhật khi lưu extension.
  - **Set value from configuration object** — đặt giá trị property từ extended object.
  - **Delete object** — xóa object khỏi extension.
- Nên đọc tài liệu đúng version platform vì cơ chế extension thay đổi thường xuyên: [Configuration_extensions](https://kb.1ci.com/1C_Enterprise_Platform/Guides/Developer_Guides/1C_Enterprise_8.3.25_Developer_Guide/Chapter_30._Configuration_extension/)

### Tóm tắt annotations / call types (theo tài liệu)
| Call type (Designer) | Annotation trong tài liệu | Ghi chú |
| --- | --- | --- |
| Call before... | "Before" | Extension chạy trước; không có cho functions |
| Call after... | "After" | Configuration chạy trước; không có cho functions |
| Call instead of... | &Around | Thay hoàn toàn; ProceedWithCall() để gọi gốc |
| Call instead (with control)... | &ChangeAndValidate | #Delete/#EndDelete, #Insert/#EndInsert |

[ghi chú ngoài nguồn] Tài liệu chỉ viết dạng "&Around" và "&ChangeAndValidate" trong tiêu đề; "Before"/"After" được nhắc như tên annotation trong ngoặc kép, không có dạng "&Before"/"&After"/"&Instead" trong văn bản tài liệu.

## Cú pháp & ví dụ code

Công thức amount after discount:
```bsl
Amount - Amount * Discount / 100

150 - 150 * 10 / 100 = 150 - 15 = 135
```

Gọi thuật toán gốc từ method extension:
```bsl
ProceedWithCall()
```

Preprocessor directives cho &ChangeAndValidate:
```bsl
#Delete

#EndDelete

#Insert

#EndInsert
```

Đường dẫn DataPath:
```bsl
<TabularSectionName.AttributeName>
<Object.TabularSectionName.AttributeName>
```

Truy cập attribute tạo bằng code:
```bsl
ThisObject.MyProperty
ThisObject["MyProperty"]
```

[ghi chú ngoài nguồn] Trong tài liệu gốc, code là ảnh chụp màn hình. Code thật của CalculatePriceAtRow (&Around) và handler Discount (After) có ở mục "Code demo của bài Theory" cuối file (lấy từ file .cfe); function print form với #Delete/#Insert, function turnover với ProceedWithCall() và các ví dụ Items.Insert()/SetAction()/ChangeAttributes()/Commands vẫn chưa có code dạng văn bản.

## Thuộc tính/thiết lập quan trọng trong Designer
- Menu **Configuration - Configuration extensions**; thuộc tính extension: **Name, Synonym, Prefix, Purpose** (Patch / Customization / Add-on), **Default roles**, **Safe mode**, **Active**, **Support mapping to extended configuration objects by internal IDs**.
- Context menu **"Add to Extension"**; call type: Call before / Call after / Call instead of / Call instead (with control).
- Adopted object properties: Controlled / Property to check / Property to modify; **Extended configuration object**; **Name** (luôn controlled).
- Form item: **DataPath**, **Type**, **ShowTitle**, **CommandName**; command: **Action**, **ModifiesStoredData**.
- Methods: **Items.Add()**, **Items.Insert()**, **SetAction()**, **ChangeAttributes()** (AttributesToBeAdded, AttributesToBeDeleted), **FormAttribute**, **TypeDescription**.

## Lỗi thường gặp / lưu ý
- Lỗi chia cho 0 khi không kiểm tra Quantity = 0 (ví dụ minh họa cho Patch).
- Nhiều extension Patch không được mở rộng cùng method với mục đích khác nhau.
- Không dùng "Around" trong Customization khi method đã được Patch mở rộng → dùng "After".
- Chỉ mở rộng method mà không mở rộng event handler → có thể ngừng được gọi khi handler gốc bị xóa.
- Adopt tabular section không adopt attributes của nó; adopt form không cho làm việc với attributes/commands/parameters cho đến khi adopt (ví dụ main attribute Object).
- "Before"/"After" không có cho functions → dùng "Around" + ProceedWithCall().
- Giá trị mặc định của parameter không chuyển sang extension.
- ChangeAndValidate: code gốc thay đổi → method ngừng được mở rộng. Query sửa bằng directive không mở được bằng query builder.
- Safe mode chỉ cho phép mở rộng form handlers; mở rộng manager module → phải tắt safe mode.
- Xóa mọi extension sửa cấu trúc object → dữ liệu attributes chỉ có trong extension mất vĩnh viễn sau restructure.
- Sửa form element trực quan trong extension → có thể sai vị trí sau khi cập nhật form; nên sửa bằng code.
- Truy cập trực tiếp attribute tạo bằng code → "Variable not defined"; dùng ThisObject["..."].
- ChangeAttributes() tốn tài nguyên → gọi một lần.
- Đổi tên object trong configuration (Name là controlled) → extension ngừng hoạt động; dùng applicability check.

## Điểm cần nhớ
- Extension mở rộng configuration mà không sửa và không gỡ khỏi support; object cần sửa phải được adopt.
- Ba purpose: **Patch** (sửa lỗi, cho phép tính năng "nguy hiểm"), **Customization** (theo khách hàng, hạn chế tính năng nguy hiểm), **Add-on** (tính năng mới độc lập version); thứ tự thực thi theo purpose rồi thứ tự thêm.
- Call types: Before, After, Instead of (**&Around** + ProceedWithCall()), Instead with control (**&ChangeAndValidate** + #Delete/#Insert).
- Before/After không có cho functions; emulate bằng &Around.
- Safe mode của extension chỉ cho phép mở rộng form handlers.
- Thêm attribute trong extension → restructure DB sang bảng mới; extension inactive vẫn ảnh hưởng cấu trúc.
- Sửa form trong extension nên làm bằng code: Items.Add()/Insert(), SetAction(), ChangeAttributes(), Commands.
- Adopted properties: Controlled (chặn áp dụng), Check (cảnh báo), Modify; Name luôn controlled; dùng mapping theo internal IDs.

## Code demo của bài Theory (file .cfe của giảng viên)

Đây là code thật của các demo **lý thuyết** (không phải lời giải bài thực hành), dùng để minh họa khi giải thích.

Ba extension dưới đây là file thật khi quay demo Theory, làm trên document **`PurchaseInvoice`** (tabular section **`Goods`**: Product, Quantity, Price, Amount) trong infobase SSL (Demo).

> [ghi chú ngoài nguồn] Văn bản Theory gọi document là **PurchaseOrder**, tabular section **Products**, tên patch "BigFix123" và extension "CRMImprovement"; file thực tế là `PurchaseInvoice`/`Goods`, `Bugfix123`, `CRMImprovemnet` (sai chính tả trong tên extension). Khi trích dẫn cho người học, dùng tên trong file và nói rõ sự khác biệt này.

| Extension | Purpose | Prefix | Adopted objects |
|---|---|---|---|
| `Bugfix123` | Patch | `bf123_` | `PurchaseInvoice`, form `DocumentForm` |
| `CRMImprovemnet` | Customization | `crm_` | `PurchaseInvoice` (tabular section `Goods` + attribute mới `crm_Discount` synonym "Discount", `crm_AmountAfterDiscount` synonym "Amount after discount", kiểu DefinedType `MonetaryAmountNonNegative`), form `DocumentForm`, `_DemoCounterparties`, `_DemoCounterpartiesContracts`, `_DemoProducts` |
| `TestExtension` | Patch | `Test_` | `PurchaseInvoice`, form `DocumentForm` |

#### Extension "Patch" — &Around cho CalculatePriceAtRow (Bugfix123)
Nguồn: `Bugfix123.cfe` — Documents/PurchaseInvoice/Forms/DocumentForm (form module)
```bsl
&AtClient
&Around("CalculatePriceAtRow")
Procedure bf123_CalculatePriceAtRow(GoodsRow)
	
	If GoodsRow.Count <> 0 Then 
		GoodsRow.Price = GoodsRow.Amount / GoodsRow.Quantity;
	Else
		 GoodsRow.Price = 0; 	
	EndIf;
	
EndProcedure
```

- [ghi chú ngoài nguồn] Điều kiện kiểm tra `GoodsRow.Count` nhưng phép chia dùng `GoodsRow.Quantity`. Tabular section `Goods` của PurchaseInvoice (phần adopted trong các extension) có `Quantity`, không có `Count` → điều kiện phải là `GoodsRow.Quantity <> 0` như Theory mô tả ("tính đến trường hợp số lượng bằng 0"). Nói rõ với người học, đừng chép lại lỗi.
- Không gọi `ProceedWithCall()` — thuật toán gốc bị thay hoàn toàn (đúng ý Theory: lỗi nằm trong method gốc).

#### Extension "Customization" — cột Discount (CRMImprovemnet)
Nguồn: `CRMImprovemnet.cfe` — Documents/PurchaseInvoice/Forms/DocumentForm (form module)
```bsl
&AtClient
Procedure crm_Goodscrm_DiscountOnChangeAfter(Item)
	
	CalculateAmountWithDiscount(Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure CalculateAmountWithDiscount(GoodsRow)
	
    GoodsRow.crm_AmountAfterDiscount = GoodsRow.Amount - GoodsRow.Amount * GoodsRow.Discount / 100;
	
EndProcedure
```

- Handler OnChange của cột Discount (field `Goodscrm_Discount`) có call type **After** → tên `crm_Goodscrm_DiscountOnChangeAfter`. Procedure tính toán `CalculateAmountWithDiscount` là procedure mới của extension (không có prefix vì người làm tự đặt tên).
- [ghi chú ngoài nguồn] Form của extension có gán handler `crm_GoodsAmountOnChangeAfter` (After) cho cột **Amount** như Theory mô tả, nhưng module **không có** procedure này — trong file chỉ có handler của cột Discount. Muốn số tiền sau chiết khấu cập nhật khi Amount đổi thì cần thêm procedure đó (gọi `CalculateAmountWithDiscount(Items.Goods.CurrentData)`).
- [ghi chú ngoài nguồn] Công thức đọc `GoodsRow.Discount`, nhưng attribute mới tên `crm_Discount` (synonym "Discount") → cần kiểm tra lại trên infobase; theo tên attribute trong extension, đúng phải là `GoodsRow.crm_Discount`.

#### TestExtension
Nguồn: `TestExtension.cfe` — Documents/PurchaseInvoice/Forms/DocumentForm
- Purpose Patch; form gán handler `Test_GoodsAmountOnChangeAround` (call type **Instead**) cho cột Amount nhưng **module form rỗng** — extension thử nghiệm, không xuất hiện trong văn bản Theory. Dùng làm ví dụ "handler đã gán mà chưa viết procedure" khi giải thích lỗi.

#### Phần Theory chưa có code dạng văn bản
- `&ChangeAndValidate` cho print form "Purchase order", `&Around` cho function turnover + `ProceedWithCall()`, ví dụ `crm_Amount` trên `_DemoGoodsSales` với `Items.Insert()`/`SetAction()`/`ChangeAttributes()`/`Commands`: chỉ có trong ảnh chụp tài liệu, không có trong 3 file `.cfe`.

## Thẻ gợi ý bài thực hành (Extensions practice)

Các thẻ dưới đây đi theo thứ tự đề trong Extensions practice, làm trên infobase SSL (Demo). Mỗi thẻ chỉ có gợi ý, không có lời giải. Nguyên tắc chung: không sửa main configuration (trừ bước cố ý tạo lỗi ở bài 1). Mọi thay đổi nằm trong extension.

### Bài tập 1 — Extension "Patch" sửa lỗi lời gọi SetMainProject

- **Đề bài (tóm tắt):** Gỡ support cho command MakeDefault của catalog `_DemoProjects`. Trong procedure `SetMainProject` của command module, xóa tham số Project khỏi lời gọi `Catalogs._DemoProjects.SetMainProject(...)` để tạo lỗi. Thử command trên list form (chọn dòng, trả lời "Yes") để thấy lỗi. Sau đó sửa lỗi bằng extension mới với purpose "Patch".
- **Gợi ý 1 — Hướng đi:** Xem "Extension Patch — ví dụ" và "&Around annotation". Muốn thay hoàn toàn một procedure bị lỗi thì dùng "Call instead of..." (annotation Around): method gốc không chạy nữa, method trong extension chạy thay.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Main configuration: Support options của command module `Catalog._DemoProjects.Command.MakeDefault` (cho phép sửa), sửa lời gọi trong procedure `&AtServer SetMainProject(Project)`.
  - Extension mới: Purpose = Patch, đặt prefix và tên ngắn theo số task (ví dụ kiểu "Bugfix…").
  - Trong command module: chuột phải trong procedure `SetMainProject` → "Add to Extension" → "Call instead of...". Procedure mới có annotation Around và tên có prefix.
  - Giữ đúng directive `&AtServer` như procedure gốc.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo lỗi trong main configuration, update DB, tái hiện lỗi trong Enterprise.
  2. Tạo extension Patch, mở cây extension.
  3. Add to Extension procedure `SetMainProject` với call type "Instead of".
  4. Trong method mới: bỏ lời gọi `ProceedWithCall()` (gọi lại code lỗi), viết lời gọi đúng tới manager module.
  5. Update extension, test lại.
  ```bsl
  &AtServer
  &Around("SetMainProject")
  Procedure ___SetMainProject(Project)
  	// không gọi ProceedWithCall() — thay bằng lời gọi đúng tới manager module, truyền đủ tham số
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Giữ `ProceedWithCall()` → code lỗi gốc vẫn chạy.
  - Mở rộng nhầm procedure trong **manager module** của catalog thay vì procedure trong **command module** (lỗi nằm ở lời gọi).
  - Extension chưa active hoặc chưa update DB configuration của extension.
- **Tự kiểm tra:** Trên list `_DemoProjects`, chọn project, bấm MakeDefault, trả lời Yes: không lỗi, project in đậm và tên hiện trên tiêu đề ứng dụng. Tắt extension (Active = False) thì lỗi quay lại.

### Bài tập 2 — Extension "Customization": ReleasedBy/ReceivedBy cho _DemoInventoryTransfer

- **Đề bài (tóm tắt):** Thêm 2 attribute `ReleasedBy`, `ReceivedBy` kiểu `CatalogRef._DemoIndividuals` vào `_DemoInventoryTransfer`, hiển thị field trên form **chỉ bằng code**. Đổi `StorageSource` → điền `ReleasedBy` bằng người phụ trách của kho đó. Tương tự `StorageLocationDestination` → `ReceivedBy`. User vẫn sửa tay được.
- **Gợi ý 1 — Hướng đi:**
  - Attribute mới của object: adopt document vào extension rồi thêm attribute (xem "Lưu dữ liệu thêm trong extension vào bảng DB": sẽ có restructure DB).
  - Field trên form: xem "Tạo form element bằng code" (`Items.Add()`, `Insert()`, `DataPath`, `SetAction()`).
  - Điền tự động: handler OnChange cho 2 field kho. Field có sẵn nên gán handler bằng `SetAction()` hoặc mở rộng event handler của field với call type "After".
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Extension mới, Purpose = Customization. Adopt `Document._DemoInventoryTransfer`, thêm 2 attribute (synonym không lộ prefix).
  - Catalog `_DemoStorageLocations` có attribute `FinanciallyLiablePerson` (synonym "Financially liable person", kiểu `CatalogRef._DemoIndividuals`). Đây là "Person responsible" của đề.
  - Adopt form `DocumentForm`. Mở rộng `OnCreateAtServer` (call type "After") để tạo 2 input field. DataPath dạng `Object.<tên attribute có prefix>`. Đặt cạnh `StorageSource`/`StorageLocationDestination` (group `StorageLocationsGroup`).
  - Lấy attribute của kho ở server: dùng hàm của SSL `Common.ObjectAttributeValue(...)` hoặc đọc qua ref trong procedure `&AtServerNoContext`.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo extension, adopt document, thêm 2 attribute.
  2. Adopt form, mở rộng `OnCreateAtServer` với "After": tạo 2 field, gán handler OnChange cho 2 field kho.
  3. Viết 2 handler client và một function server lấy người phụ trách của kho.
  4. Kiểm tra lại safe mode của extension nếu bạn mở rộng gì khác ngoài form handler.
  ```bsl
  &AtServer
  Procedure ___OnCreateAtServerAfter(Cancel, StandardProcessing)
  	// Items.Insert/Add cho 2 field + DataPath; SetAction("OnChange", ...) cho 2 field kho
  	___
  EndProcedure

  &AtServerNoContext
  Function ___(StorageLocation)
  	// trả về người phụ trách của kho
  	___
  EndFunction
  ```
- **Lỗi hay gặp:**
  - Vẽ field bằng form designer trong extension: đề cấm, phải tạo bằng code.
  - DataPath thiếu `Object.` → field không gắn được với attribute của document.
  - Ghi đè handler OnChange có sẵn của field bằng "Around": hãy dùng "After" hoặc thêm hành động riêng, không phá logic gốc.
  - Handler gán qua `SetAction()` sai tập/thứ tự parameter (OnChange nhận `Item`).
  - Ghi đè giá trị user đã sửa tay mỗi lần mở form: chỉ điền trong OnChange của field kho.
- **Tự kiểm tra:** Mở document chuyển kho: 2 field mới hiện cạnh field kho. Chọn kho gửi → "Released by" tự điền đúng người phụ trách. Sửa tay rồi Save, mở lại → giá trị giữ nguyên.

### Bài tập 3 — Print form "Transfer Note" in Released/Received by từ attribute mới

- **Đề bài (tóm tắt):** Dùng extension của bài 2 để sửa print form "Transfer Note" của `_DemoInventoryTransfer`, sao cho ô "Released by" và "Received by" lấy từ 2 attribute mới.
- **Gợi ý 1 — Hướng đi:** Cần sửa **một phần** function dựng print form trong manager module (thêm field vào query, thêm dữ liệu cho template) mà vẫn giữ phần còn lại → "Call instead (with control)..." (`&ChangeAndValidate`) với `#Insert/#EndInsert` (và `#Delete/#EndDelete` nếu cần). Template cũng phải có parameter cho 2 ô này. Cách khác cũng được chấp nhận: "Call instead of..." (`&Around`) viết lại cả function — đơn giản hơn nhưng sẽ không nhận thay đổi của function gốc khi cấu hình được cập nhật; nếu chọn cách này, hãy giải thích được vì sao.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Manager module của `_DemoInventoryTransfer`, function `GoodsTransferPrintForm(ObjectsArray, PrintObjects)` (dựng "Transfer Note" từ template `PF_MXL_TransferNote`).
  - Trong function: query lấy header document, rồi structure dữ liệu in được điền vào parameters của các area. Area "Signatures" có nhãn "Released by"/"Received by".
  - Adopt template `PF_MXL_TransferNote` vào extension và thêm parameter vào ô cạnh nhãn (hoặc kiểm tra template đã có parameter chưa).
  - Mở rộng method trong manager module → tắt **Safe mode** của extension và khởi động lại (xem "&ChangeAndValidate annotation").
- **Gợi ý 3 — Khung bài làm:**
  1. Đọc function gốc, tìm chỗ query chọn field header và chỗ điền structure dữ liệu in.
  2. Add to Extension function đó với "Call instead (with control)".
  3. Dùng `#Insert` để thêm 2 field vào text query và thêm 2 phần tử vào dữ liệu in.
  4. Thêm parameter trong area chữ ký của template (tên trùng key bạn thêm).
  5. Tắt safe mode, update extension.
- **Lỗi hay gặp:**
  - Sửa dòng ngoài `#Insert/#Delete` → extension phát hiện khác biệt và ngừng mở rộng method.
  - Query đã sửa bằng directive không mở được bằng query builder. Sửa bằng tay cẩn thận dấu `|` và dấu phẩy.
  - Lỗi khi mở list/print vì safe mode chặn mở rộng manager module.
  - Tên parameter trong template không khớp key trong dữ liệu in → ô trống.
- **Tự kiểm tra:** Print → "Transfer note": ô Released by / Received by hiện đúng tên từ document. Đổi người trên document, Save, in lại → thay đổi theo.

### Bài tập 4 — Thử thứ tự gọi khi nhiều extension cùng mở rộng một method

- **Đề bài (tóm tắt):** Đọc tài liệu về thứ tự gọi method được mở rộng. Tạo nhiều extension mỗi loại purpose (ví dụ 2 Patch, 3 Customization, 2 Add-on), cùng mở rộng một method với cùng các annotation (Before, After, Instead), mỗi method hiện message là tên extension để quan sát thứ tự.
- **Gợi ý 1 — Hướng đi:** Xem "Làm việc với extension" (thứ tự thực thi theo purpose rồi theo thứ tự thêm vào infobase) và bảng "Tóm tắt annotations / call types". Before chạy trước method gốc, After chạy sau. Instead (Around) thay method gốc và chỉ gọi tiếp chuỗi khi có `ProceedWithCall()`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Chọn một **procedure** dễ kích hoạt, ví dụ một form event handler client của một form demo (Before/After không có cho functions).
  - Mỗi extension: "Add to Extension" cùng method, chọn call type cần thử. Trong thân chỉ hiện message chứa tên extension và call type.
  - Danh sách Configuration extensions để xem và đổi thứ tự thêm.
- **Gợi ý 3 — Khung bài làm:**
  1. Ghi trước dự đoán thứ tự (Patch → Customization → Add-on, trong cùng purpose theo thứ tự thêm).
  2. Tạo lần lượt các extension, mỗi extension mở rộng cùng method với Before và After. Một vài extension dùng Instead.
  3. Kích hoạt method, chép lại thứ tự message.
  4. Thử bỏ `ProceedWithCall()` trong một method Instead và quan sát extension nào bị "cắt" khỏi chuỗi.
  ```bsl
  &AtClient
  &___("<TênMethodGốc>")   // Before / After / Around tùy thử nghiệm
  Procedure ___<TênMethodGốc>(___)
  	// message: tên extension + call type
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Dùng function để thử Before/After: không có call type này cho functions.
  - Nhiều extension Patch cùng mở rộng một method với mục đích khác nhau: tài liệu khuyến cáo tránh trong thực tế. Ở đây chỉ để thí nghiệm.
  - Quên đặt extension về Active, hoặc quên update extension → message không hiện.
- **Tự kiểm tra:** Bảng thứ tự message khớp quy tắc purpose + thứ tự thêm. Đổi thứ tự (xóa rồi thêm lại một extension) thì message đổi theo dự đoán.

## Video tham khảo (khóa Junior cũ)

Video trong playlist "Junior Developer Course" (1C Vietnam Academy, khóa cũ) có phạm vi trùng với bài này. Gọi là "video JC-<số>" (số bài của khóa cũ, khác số bài giáo trình); quy ước dẫn và độ tin cậy: `references/video-junior-course.md`.

Không có video tương ứng trong playlist khóa cũ — chỉ dẫn tài liệu Theory/Practice của bài.
