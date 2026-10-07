# Bài 9 — Subsystems, Panels, Forms (attributes, parameters, commands, items, groups, conditional appearance), Home page

## Khái niệm chính

### Subsystems
- **Subsystem** là khối cơ bản để xây giao diện 1C:Enterprise → việc đầu tiên khi phát triển configuration là thiết kế thành phần các subsystem, rồi gắn configuration objects vào subsystem một cách chính xác, có ý nghĩa.
- Ứng dụng đơn giản có thể không dùng subsystem, nhưng khuyến nghị **luôn dùng**: ngoài xây giao diện, Subsystem còn mô tả các phần chức năng (logical parts) của applied solution.
- Hai cấp: **top-level** (là các section chính của giao diện) và **subordinate**.
- Subordinate subsystems **không hiển thị trong Current section functions panel**; chỉ thấy khi click lại vào section đang mở.
- Mỗi configuration object có thể nằm trong **một hoặc nhiều** subsystem (khả dụng ở mỗi subsystem được chọn).
- Subsystems kết hợp với visibility theo roles → giao diện gọn, người dùng chỉ thấy các section cần cho công việc (ví dụ thủ kho chỉ cần nhập/xuất hàng).
- Ngay cả ứng dụng nhỏ cũng cần nhiều subsystem (ví dụ Accounting, Sales, Purchases, Warehouses, và một subsystem chỉ cho administrator).

### Subsystem properties
- **Include in the command interface**: subsystem có hiển thị trong giao diện không. Một số subsystem chỉ dùng để phân nhóm chức năng metadata, không cần hiển thị.
- **Explanation**: hiển thị thông tin subsystem dạng tooltip khi rê chuột.
- **Picture**: ảnh subsystem trong giao diện; **chỉ hiển thị cho top-level subsystems**.
  - Nếu có ít nhất một ảnh cao hơn 48 pixel → mọi ảnh như vậy thu nhỏ tỷ lệ về 48 pixel chiều cao.
  - Nếu mọi ảnh trong sections panel thấp hơn 48 pixel → chiều cao panel tính theo ảnh cao nhất; ảnh nhỏ hơn được căn giữa.
  - Thêm ảnh: Picture → nút chọn → cửa sổ **Select picture**, tab **From configuration** → **Add** → platform tạo configuration object **Common picture** và mở editor → **Load from file** → chọn file → nhập **Name** → đóng editor → chọn ảnh trong Select picture → **OK**. Ảnh xuất hiện trong nhánh **Common pictures** của cây configuration.
  - Trong giao diện, **synonym** của subsystem là tên section, ảnh hiện cạnh tên. Không có ảnh → dùng ảnh mặc định.
- Tab **Content**: thêm/bớt objects khỏi subsystem.

### Panels
- Developer cấu hình bố cục panel mặc định cho mọi người dùng; mỗi người dùng có thể tự thay đổi thành phần và vị trí.
- Sửa thành phần panel: lệnh **Open client application interface** trong context menu của configuration. Mặc định configuration mới: **Sections panel** ở trên, dưới là **Current section functions panel**.
- Trong Enterprise mode, thêm/bớt panel bằng **kéo thả**.
- **Sections panel**: hiển thị các section chính (top-level subsystems). Section **Quick menu** tự tạo, chứa documents, reports... hay dùng.
- **Current section functions panel**: hiển thị objects và commands của subsystem đang chọn; chưa chọn thì trống. Thường bị tắt vì không chia theo subordinate subsystems và các section "reports", "service" (platform tự tạo khi subsystem có reports và data processors).
- **Open items panel**: danh sách mọi form đang mở (như tab trình duyệt).
- **Favorites bar**: các mục người dùng đánh dấu sao (ngôi sao cạnh header form). Có thể sửa danh sách (attach/detach, rename, đổi thứ tự bằng kéo, xóa).
- **History panel**: lịch sử form mở gần đây; click icon đồng hồ → danh sách chi tiết ngày giờ, mở lại form, quản lý favorites.
- Tìm kiếm: **Ctrl + F** để tới ô search.

### Forms — tổng quan
- Form: object để nhập, xem thông tin và quản lý các quy trình.
- Phần hiển thị mô tả bằng **cây form items**: input fields, check boxes, radio buttons, buttons...; item có thể là **group** (framed panel, panel có pages/tabs, page, command bar) hoặc **table** (chứa columns).
- Chức năng form mô tả bằng **attributes** (dữ liệu form xử lý) và **commands** (hành động form thực hiện).
- Hệ thống có thể tự tạo form cho applied object; developer cũng có thể tự tạo. Hệ thống tự sắp xếp giao diện theo mô tả logic (có xét kiểu dữ liệu); developer tinh chỉnh thứ tự, width, height.
- Form dùng được commands của chính nó và **global commands** của command interface; có thể tạo configurable commands mở form khác theo dữ liệu form hiện tại (ví dụ báo cáo tồn kho của warehouse đang chọn trong sales invoice).
- Có thể gắn user messages vào form data → hệ thống đánh dấu và kích hoạt control người dùng nhập sai.
- Form tự xét quyền theo role: attribute không được xem → control liên quan tự bị gỡ, form được dựng lại.
- Form editor (Designer) định nghĩa: **Form attributes**, **Form commands**, **Form parameters**, **Form module**, **Form items**, **Command interface**.
- **Lưu ý: form tồn tại đồng thời ở cả server và client.**

### Form attributes
- Tập attributes = **form data**: dữ liệu hiển thị, sửa, lưu trong form. Bản thân attribute không hiển thị/sửa dữ liệu — form controls gắn với attribute làm việc đó.
- **Mọi form data phải mô tả bằng form attributes**; không được dùng biến của form module làm nguồn dữ liệu cho form controls.
- Availability attribute có thể cấu hình bằng functional options (học sau).
- **Main attribute**: quyết định chức năng chuẩn của form (**form extension**). **Form chỉ có một main attribute.**
- Form extension = các properties, methods, form parameters bổ sung của object **ClientApplicationForm** đặc thù theo kiểu main attribute.
- Các nhóm kiểu dữ liệu form dùng:
  - Kiểu dùng trực tiếp (hỗ trợ cả thin client và web client): ví dụ Number, CatalogRef.Items, GraphicalSchema, SpreadsheetDocument.
  - Kiểu được chuyển sang form data types — hiển thị trong ngoặc, ví dụ `(CatalogObject.Items)`.
  - **Dynamic list**: kiểu đặc biệt hiển thị dữ liệu tùy ý từ bảng database (chỉ định bảng hoặc mô tả bằng query language); dựa trên data composition system; hỗ trợ sort, selection, search, grouping, conditional appearance.
- Một số applied types (CatalogObject...) không có ở thin/web client → platform có form data types riêng, phải chuyển đổi applied objects ↔ form data:
  - **FormDataStructure**: tập attributes kiểu tùy ý (có thể chứa structures, collections). Ví dụ đại diện CatalogObject trong form.
  - **FormDataCollection**: danh sách có kiểu giống array, truy cập theo index hoặc ID. Với collection từ register record sets hoặc object tables, field **LineNumber** không tương ứng index thật. Đôi khi không truy cập được theo ID. ID có thể là số nguyên bất kỳ. Đại diện table trong form.
  - **FormDataStructureAndCollection**: vừa là structure vừa là collection. Ví dụ đại diện record set.
  - **FormDataTree**: lưu dữ liệu phân cấp.
- **Important!** Không khuyến nghị dùng form data làm parameters của procedure/function chuyển quyền từ client sang server, hoặc làm giá trị trả về khi chuyển về client.
- **Important!** Khi gọi server và trả về client, **chỉ phần dữ liệu thay đổi** được truyền về form.
- Document có table → FormDataStructure (document) chứa FormDataCollection (table).
- **Lưu ý**: applied objects chỉ có ở server; form data objects dùng được ở cả server và client.
- Hạn chế khi tạo form attributes:
  - Cấm gán giá trị kiểu **Array** và **Map** cho form attributes.
  - Với attributes kiểu tùy ý của các object FormDataStructure, FormDataCollectionItem, FormDataTreeItem, FormDataStructureAndCollection: không được gán Array, Map.
  - Không khuyến nghị dùng Array, Map làm phần tử của Structure hoặc ValueList → dùng **FixedArray**, **FixedMap**.
  - Không khuyến nghị dùng Structure, ValueList trong attribute data (attributes của attributes).
  - Attribute kiểu Arbitrary hoặc chứa collection: không gán giá trị chứa các applied object: DocumentObject, CatalogObject, BusinessProcessObject, TaskObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, ExchangePlanObject, ChartOfAccountsObject, ExternalDataSourceCubeDimensionTableObject, ExternalDataSourceTableObject.
- Form data = biểu diễn thống nhất dữ liệu từ nhiều applied objects, có ở cả server và client. Nếu developer tự viết thuật toán xử lý thì phải **tự chuyển đổi** dữ liệu.
- Cột **Always use** (”Use always”) trong attribute editor — ảnh hưởng truyền dữ liệu server–client:
  - Attribute con của dynamic list (column): bật → luôn đọc từ database và đưa vào form data; tắt → chỉ đọc khi có form item **đang hiển thị** gắn với attribute (hoặc attribute con).
  - Attribute con của register record collection: bật → register records của document được đọc và có trong form data; tắt → không đọc (nếu không có form item tham chiếu).
  - Các attribute còn lại: bật → luôn có trong form data; tắt → chỉ có khi tồn tại form item gắn với attribute (khác dynamic list: **visibility của item không quan trọng**).
  - Property của attribute cha ảnh hưởng mọi attribute con (tắt ở document table → coi như tắt ở mọi attribute con).
- Kiểu trong ngoặc ở cột Type (ví dụ `(CatalogObject.Products)`) nghĩa là applied type sẽ được chuyển sang form data type; kiểu thật của attribute Object là **FormDataStructure**.
- Đặc điểm theo kiểu:
  - ValueTable, ValueTree: thêm columns bằng lệnh **Add attribute column** (định nghĩa cấu trúc).
  - FormDataCollection (object tables) và FormDataStructureAndCollection (record sets): thêm cột bổ sung (**Add attribute column**) không gắn dữ liệu infobase; được tạo khi sinh form data, truy cập được ở client và server.
  - ValueList: đặt **Value type** → giới hạn kiểu khi thêm tương tác; thêm bằng code không bị cấm nhưng sẽ cố ép sang kiểu giới hạn. Có thể gắn Value type với form item.
  - DynamicList: thiết lập list parameters: main table, settings...

### Chuyển đổi applied object ↔ form data
- Global methods: **ValueToFormData()** (applied object → form data), **FormDataToValue()** (form data → applied object), **CopyFormData()** (copy form data có cấu trúc tương thích; trả True nếu thành công, False nếu không tương thích).
- Method làm việc với applied objects chỉ có trong **server procedures**; CopyFormData() dùng được ở cả server và client.
- Khi chuyển đổi, object được cache và kiểm tra tính cập nhật của bản cache.
- Với standard actions (mở form, lệnh Write chuẩn...) trong form có main attribute → chuyển đổi **tự động**.
- Methods của ClientApplicationForm (server): **ValueToFormAttribute()** (applied object → form attribute chỉ định), **FormAttributeToValue()** (form attribute → applied object).
- Trong form module, nên dùng **FormAttributeToValue** thay vì FormDataToValue: nhất quán với các ứng dụng 1C khác, cú pháp đơn giản hơn (không cần chỉ định kiểu), ít lỗi hơn. FormDataToValue yêu cầu chỉ định kiểu tường minh.
- Khi chuyển ValueTable/ValueTree sang form data bằng ValueToFormData() hoặc ValueToFormAttribute(): object phải chứa **mọi cột** của form data.
- **Important!** Cột attribute không gắn dữ liệu không tham gia chuyển đổi; cột thiếu trong object data sẽ bị xóa khi chuyển sang form data.
- Tham số thứ nhất của FormAttributeToValue() và FormDataToValue() chỉ có thể là: FormDataStructure, FormDataCollection, FormDataStructureAndCollection, FormDataTree.

### Attribute properties
- **Title**: dùng làm tiêu đề form item gắn với attribute nếu item không có Title riêng.
- **Main attribute**: attribute này là main → quyết định form extension.
- **Saved data**: khi sửa tương tác attribute → cố lock form attribute liên quan; bật property **Modified** của form; nếu form ở chế độ **Read only** → mọi item gắn attribute này cũng Read only.
- **Required field**: kiểm tra điền dữ liệu (giá trị **Display error**). Chỉ áp dụng cho: primitive types (Number, String, Boolean, Date, mọi reference, standard period), Value list, Value tree, Value table. Kiểm tra tương tự hàm `ValueIsFilled()`; table được coi là đã điền khi có ít nhất một row.

### Form parameters
- Tab **Parameters**, hai mục đích:
  - Mô tả dữ liệu ảnh hưởng tới việc mở form (parameterization).
  - Xác định parameters tạo **form uniqueness key**: bật property **Key parameter**. Khi mở form, hệ thống tìm form có cùng uniqueness key; có → trả form đó; không → tạo form mới.
- Giá trị parameter truyền qua parameters structure cùng system parameters. Phân tích trong event **OnCreateAtServer()** (collection **Parameters** là property của ClientApplicationForm).
- **Important!** Sau handler OnCreateAtServer, mọi **non-key** parameter bị xóa khỏi collection Parameters. Key parameters hiển thị **in đậm** trong danh sách. Non-key parameter cần dùng tiếp → lưu vào form data.
- Parameter không được truyền khi mở form → platform vẫn thêm vào structure với giá trị **Undefined** (tương đương bỏ qua parameter khi gọi method); áp dụng cho cả parameter developer tạo và standard parameters.
- **Standard parameters** hỗ trợ tương tác tự động giữa forms (chọn giá trị từ choice form, mở object form, standard commands...); developer có thể truyền khi gọi **OpenForm()**.
- Danh sách standard parameters: Help - Interface (managed) - Client application form - Client application form extension for... Với list forms và choice forms xem "Client application form extension for dynamic lists" (main attribute là dynamic list).

### Form commands
- Command chỉ mô tả hành động; muốn chạy phải gắn với form item (ví dụ Button). Các nhóm:
  - **Commands created by developer**: phải tạo handler trong form module.
  - **Standard commands**: do extension của main attribute và của attributes dạng list (object table, dynamic list, information register record set...) cung cấp, nếu có form item gắn attribute đó.
  - **Global commands**: từ global command interface (tab **Global commands**); có thể non-parameterized hoặc parameterized. Parameterized chỉ được cung cấp nếu form có nguồn parameter đúng kiểu. Đặt được ở bất kỳ đâu trên form.
- Availability của standard commands do property **Command set** của form item quyết định (ví dụ tắt nút "Mark for deletion" và "Delete" trên command bar của Sales invoice).
- Property **Action**: handler thực hiện command. Không có handler → command không dùng được. Chỉ chọn được **client-side** procedure/function **có một parameter**.
- Property **Modifies saved data**: khi chạy command → cố lock main form attribute (thất bại → command thất bại); bật **Modified** của form. Nếu form Read-only → mọi item gắn command này cũng Read-only.
- Chạy parameterized global command mà parameter lấy từ attribute có ”Modifies data”, với object mới chưa ghi → hệ thống cố ghi object, hỏi người dùng; trả lời không → command thất bại.
- Khi tự điền command bars/context menus có command source: standard commands **không** được thêm nếu item đã có nút thêm thủ công cùng command (không áp dụng cho command từ fragment của global command interface).
- Command có property **Use** tắt → mọi nút liên quan biến khỏi command interface; người dùng không đổi được.

### Form items
- Các item của managed form tạo thành tập phân cấp, quyết định giao diện. Loại: **Form** (root, duy nhất), **Form field**, **Form decoration**, **Form table**, **Form button**, **Form group**, **Form item add-on**.
- Form field và form table **luôn gắn form data**. Nếu không chỉ định attribute, hoặc attribute không có ở client do hạn chế quyền, hoặc bị loại khỏi thành phần (properties View và Edit của form attribute) → field không hiển thị và tự bị xóa khi tạo form ở Enterprise mode.

### General properties of form items
- **TitleLocation**: cách hiển thị tiêu đề. Tiêu đề = synonym của attribute gắn item, trừ khi item có **Title**. Tiêu đề luôn kết thúc bằng ":" (hệ thống tự thêm).
- **Data**: tham chiếu tới form attribute gắn item; không gắn → item không hiển thị.
- **Command** (của button): command chạy khi bấm; không gắn → button không hiển thị.
- Item ở chế độ Read-only khi: có property **ReadOnly** (Designer hoặc code), hoặc group chứa nó có ReadOnly, hoặc attribute gắn có **SavedData** và form ở Read-only. (Field Read-only có khung màu nhạt hơn, không có nút select, chỉ có nút open.)
- Visibility: **Visible** (đổi được trong Designer và bằng code) và **User visibility** (chỉ cấu hình trong Designer, visibility ban đầu theo **roles**). Visibility cuối = Visible **AND** User visibility. Người dùng đổi visibility trong hộp thoại **Customize form** thực chất đổi User visibility.

### Associating items with form attributes
- **Connection to current data of tables**: item gắn với cột của table trên form → hiển thị dữ liệu dòng hiện tại. Áp dụng cho fields và tables; cột không cần hiển thị trong table; item có thể Read only hoặc edit. Ví dụ data path: `Elements.Products.CurrentData.Price` (Elements = property form chứa mọi items; Products = form table; CurrentData = dòng hiện tại; Price = attribute của table). Loại field: Label field hoặc Input field.
- **Connection to attributes through reference**: attribute kiểu reference (ví dụ CatalogRef) → item gắn với attribute lấy qua reference; dữ liệu tự lấy và cập nhật khi reference đổi; độ sâu tùy ý; luôn **View only**. Ví dụ: `Object.Products.Product.Weight`.
  - **Note**: attribute **composite type** (nhiều kiểu, gồm CatalogRef, DocumentRef...) **không** lấy attribute qua reference được.
- **Connection with collections totals**: gắn với tổng của collection (tables, record sets, value lists — value list chỉ có số rows): totals theo number fields; số rows; luôn View only. Ví dụ: `Object.Products.TotalAmount` (tổng cột Amount).
  - Hiển thị totals ở footer cột: bật property **Footer** của table, điền **FooterDataPath** của cột.
  - Hiển thị số rows ở tiêu đề tab: điền **TitleDataPath** của group kiểu Page.
- **Choice parameters**: giá trị parameters dùng khi chọn giá trị attribute (khi mở choice form, quick choice list, nhập theo dòng). Truyền vào form được mở qua structure **Parameters**: cột Name = key, cột Value = value. Nếu Name là ”Filter.Type” → tạo form parameter **Filter** (Structure) chứa key ”Type” với value ”Product”. Danh sách giá trị cho filter: chọn kiểu **Fixed array** khi sửa cột Value. Ví dụ: giới hạn products có Type = `Enumeration.ProductTypes.Product`.

### Form (root item)
- Mô tả thuộc tính hiển thị của form và form event handlers; luôn duy nhất, ở gốc cây.
- Ngắt mở form:
  - **OnCreateAtServer**: đặt `Cancel = True` → form không được tạo.
  - **OnOpen**: đặt `Cancel = True` → form không được mở.
- Property **WindowOpeningMode**:
  - **Independent**: mở trong vùng làm việc của cửa sổ chính.
  - **Lock parent window**: cửa sổ non-modal, khóa form đã khởi tạo việc mở. Cho form nhập ít thông tin, dùng nhanh (ví dụ catalog ít attribute). Trông giống modal nhưng khi mở từ code, module **không dừng**. Mở ở cửa sổ phụ. Mặc định cho: Catalog item and group; Exchange plan node; Item and group of a chart of characteristic types; Account; Calculation type; Task; Record of an independent information register.
  - **Lock the entire interface**: như trên nhưng khóa cả form cha và toàn bộ giao diện. Không là mặc định cho form nào.
- Thuật toán xác định cửa sổ bị khóa: nếu **FormOwner** là form chưa đóng → khóa form đó; nếu FormOwner là form item của form chưa đóng → khóa form chứa item; còn lại (FormOwner = Undefined hoặc owner đã đóng) → khóa cửa sổ hiện tại của client application lúc mở.
- WindowOpeningMode không ảnh hưởng khi mở form từ form đang khóa giao diện; khi đó parameter WindowOpeningMode của **OpenForm()** cũng bị bỏ qua → form mở ở cửa sổ riêng, non-blocking.
- **Command bar** của form: vị trí bằng property ”Command bar location”; tập standard commands bằng property ”Command set”.
- **Enable form change** tắt → người dùng không đổi được tập và vị trí items ở Enterprise mode.
- **ReadOnly** của form: chỉ đổi bằng code. True → không khả dụng: items gắn attributes có "Saved data"; buttons gắn commands có "Changes saved data"; buttons gắn hầu hết standard commands. Chỉ attribute tắt "Saved data" còn sửa được.

### Radio buttons và checkboxes
- Field kiểu **Radio button field**: property **ChoiceList** quyết định số lượng và giá trị radio buttons. Mặc định nằm ngang; xếp dọc bằng ”Column count”. Column count = 0 → hệ thống tự chia nhiều dòng theo chỗ trống (tính lúc tạo form, không động).
- Checkbox field và Radio button field có display kind: checkbox dùng property **Checkbox type** (segmented buttons, switches, checkboxes); radio button dùng property "radio button type".

### Group
- Kết hợp được fields, pages, commands, columns. Loại group:
  - **Regular group**: nhóm form items.
  - **Command bar**: chứa buttons và groups.
  - **Pages**: panel có tabs (dọc hoặc ngang); bên trong chỉ chứa group kiểu **Page**; Page chứa items khác.
  - **Column group**: nhóm cột trong table; đổi quy tắc nhóm (dọc/ngang).
- Group lồng nhau được; di chuyển items giữa groups — hệ thống tự kiểm tra hợp lệ, tự đổi properties cần thiết (ví dụ View); yêu cầu với item con đổi → tự sửa hoặc xóa.
- Thiết kế Regular group:
  - **No**: không đánh dấu.
  - **Slight highlight**: tiêu đề chữ lớn màu xanh lá.
  - **Standard highlight**: tiêu đề chữ lớn xanh lá + indent quanh items (mỗi phía).
  - **Strong highlight**: tiêu đề chữ lớn xanh lá + dải xanh bên trái suốt chiều cao + indent phía dưới.
- Property **Behavior**:
  - **Regular** (hoặc **Auto**) — standard group: không đổi hiển thị khi người dùng thao tác.
  - **Collapsible**: người dùng thu/mở ở Enterprise mode. Developer **không** xác định được trạng thái từ code, **không** ép thu/mở. Trạng thái ban đầu theo checkbox **Collapsed**. Không thu/mở được nếu tiêu đề rỗng hoặc không hiển thị (**ShowTitle** = False).
  - **Pop-up**: ban đầu như group thu gọn; click tiêu đề → "pop up" trên form ở cửa sổ đặc biệt. Mỗi lúc chỉ một pop-up group → không lồng được; pop-up lồng sẽ hiển thị như collapsible. Hiện/ẩn **không cần server call**. Phải có tiêu đề (tiêu đề là text hyperlink); không có tiêu đề → hoạt động như standard group.
- **ControlRepresentation**: điều khiển trạng thái collapsible bằng hình hoặc hyperlink. **CollapsedRepresentationTitle**: tiêu đề khi thu gọn; không điền → dùng tiêu đề thường.
- Command bar: property **”Command source”** chỉ định form item (Form, Form table, Spreadsheet document field, Graphical schema field) cung cấp "own" commands; tập commands hiển thị theo property Command set của item nguồn. Ví dụ: attribute SpreadsheetDocument → thêm group Command Bar với source là spreadsheet document. Form tables đã có command bar sẵn; chỉ thêm khi cần khác thường (đặt bên trái, nút dọc, tách vị trí).

### Conditional appearance
- Thiết lập từ properties panel của **root item** của form. Data composition system (reports, dynamic lists) cũng có conditional appearance.
- Không khuyến nghị dùng conditional appearance **của form** cho dynamic list nếu có thể dùng conditional appearance của chính list.
- Các kiểu:
  - **Background color** — form items: input field, text document field, table, standard button; table fields: label field, input field, radio button field, picture field.
  - **Text color** — form items: label field, input field, text document field, picture field, radio button field, table, regular button, hyperlink, text decoration, picture decoration; table fields: label field, input field, radio button field.
  - **Font** — form items: label field, input field, text document field, picture field, radio button field, calendar field, table, regular button, hyperlink, text decoration, picture decoration; table fields: label field, input field. Note: đổi font bằng conditional appearance không được tính khi xác định kích thước items.
  - **Mark negatives** — form items và table fields: label field, input field.
  - **Horizontal position** — form items: label field, input field, text decoration; table fields: label field, input field.
  - **Unfilled mark** — form items: input field, table; table fields: input field. Note: nếu điều khiển *MarkIncomplete* bằng conditional appearance → nên đặt *AutoMarkIncomplete* = “No” cho field.
  - **Text** — table fields: label field, input field.
  - **Format** — form items: Page group, Regular group; table fields: label field, input field.
  - **Visibility** — ẩn table fields: label field, input field, radio button field, picture field; ô ẩn được thay bằng ô kề (lớn hơn), thuật toán có thể khác giữa các client. Không khuyến nghị dùng để ẩn **cả dòng** (giảm hiệu năng, hiển thị sai).
  - **Accessibility** — tắt availability của table fields: label field, input field, radio button field, picture field.
  - **Read only** — View only cho các table fields trên.
  - **Show** — ẩn giá trị trong cột table (label field, input field, radio button field, picture field); dùng cho cột nằm trong column group kiểu **In cell**. Cột không nhóm hoặc vẫn hiển thị riêng → dùng **Visibility**.
- Note: conditional appearance dùng ngày giờ máy hiện tại điều chỉnh theo time zone của session.
- Cột form table được format có điều kiện chứa field của table đó → dùng current data của table đó; field không thuộc table → dùng current data của **table đầu tiên** (theo thứ tự trong form editor).
- Thiết kế động theo form data, không cần thao tác đặc biệt. Nếu dùng dynamic list fields trong điều kiện → bật *Always use* cho các field đó.
- Ví dụ: đổi màu chữ dòng trong table Products nếu amount > 1 triệu.

### Home page
- **Home page**: form active khi khởi động ứng dụng, chứa các chức năng hay dùng. Mặc định do developer cấu hình; chung cho mọi người hoặc theo roles. Mỗi người dùng có thể đổi thành phần home page ở Enterprise mode.

## Cú pháp & ví dụ code

### Chuyển đổi dữ liệu trong thuật toán tự viết
```bsl
&AtClient

Procedure WriteObject();

    WriteObjectAtServer();

EndProcedure

&AtServer

Procedure WriteObjectAtServer()

    ObjectItem = FormDataToValue(Form.Object, Type("CatalogObject.Items"));

    ObjectItem.Write();

EndProcedure
```
[ghi chú ngoài nguồn: dòng `Procedure WriteObject();` có dấu chấm phẩy — theo chính Bài 6, đặt chấm phẩy sau mô tả procedure gây compilation error; giữ nguyên như tài liệu.]

### FormDataToValue vs FormAttributeToValue
```bsl
Products = FormDataToValue(ProductsTable, Type("ValueTable"));
```
```bsl
Products = FormAttributeToValue("ProductsTable");
```

### FormAttributeToValue + ValueToFormAttribute
```bsl
&AtServer

Procedure CalculateTotalAtServer()

    // Convert the Object attribute to an applied object.

DocumentObject = FormAttributeToValue("Object");

// Perform recomputing by the method defined in the document module.

    DocumentObject.CalculateTotal();

    // Convert the applied object back to an attribute.

    ValueToFormAttribute(DocumentObject, "Object");

EndProcedure
```

### Form parameters — nơi gọi
```bsl
// Generate a form parameter.

Parameters = New Structure();

Parameters.Insert("PickMode", PredefinedValue("Enumeration.PickModes.Simple"));

// Open a form with specified parameters.

OpenForm("CommonForm.PickProducts", Parameters);
```

### Form parameters — trong form module
```bsl
&AtServer

Procedure OnCreateAtServer(Cancel, StandardProcessing)

    // Check if the form contains such a parameter

    If Parameters.Property("PickMode") Then

        If Parameters.PickMode= Enumerations.PickModes.Simple Then

            …

        EndIf;

    EndIf;

EndProcedure
```

### Data path ví dụ
```bsl
Elements.Products.CurrentData.Price
Object.Products.Product.Weight
Object.Products.TotalAmount
```

## Thuộc tính/thiết lập quan trọng trong Designer

**Subsystem**: Include in the command interface; Explanation; Picture (Select picture → From configuration → Add → Common picture → Load from file → Name → OK); Synonym (tên section); tab Content.

**Configuration**: context menu → Open client application interface (sửa panels).

**Form editor**: Form attributes, Form commands, Form parameters (tab Parameters), Form module, Form items, Command interface; tab Global commands.

**Form attribute**: Title; Main attribute; Saved data; Required field (Display error); cột Always use / Use always; cột Type; lệnh Add attribute column; Value type (ValueList); View, Edit.

**Form parameter**: Key parameter.

**Form command**: Action; Modifies saved data; Use; Command set (của form item).

**Form item (chung)**: TitleLocation; Title; Data; Command (button); ReadOnly; Visible; User visibility; Choice parameters (Name/Value, Fixed array).

**Table / Page group**: Footer; FooterDataPath (column); TitleDataPath (Page group).

**Form (root)**: WindowOpeningMode (Independent / Lock parent window / Lock the entire interface); FormOwner; Command bar location; Command set; Enable form change; ReadOnly (chỉ bằng code); event OnCreateAtServer, OnOpen; Conditional appearance.

**Radio button / Checkbox**: ChoiceList; Column count; Checkbox type; radio button type.

**Group**: loại Regular group / Command bar / Pages / Page / Column group; design No / Slight highlight / Standard highlight / Strong highlight; Behavior (Regular/Auto, Collapsible, Pop-up); Collapsed; ShowTitle; ControlRepresentation; CollapsedRepresentationTitle; Command source.

**Conditional appearance kinds**: Background color, Text color, Font, Mark negatives, Horizontal position, Unfilled mark (MarkIncomplete / AutoMarkIncomplete), Text, Format, Visibility, Accessibility, Read only, Show.

## Lỗi thường gặp / lưu ý
- Dùng biến form module làm nguồn dữ liệu cho form controls → không được phép; phải dùng form attributes.
- Form chỉ có **một** main attribute.
- Không dùng form data làm parameter khi gọi từ client sang server, hoặc làm giá trị trả về cho client.
- Gán Array/Map cho form attributes → cấm; dùng FixedArray/FixedMap trong Structure/ValueList.
- Không gán applied objects (DocumentObject, CatalogObject...) vào attribute Arbitrary hoặc collection.
- Applied objects chỉ có ở server; ValueToFormData/FormDataToValue/ValueToFormAttribute/FormAttributeToValue chỉ dùng trong server procedures.
- Chuyển ValueTable/ValueTree sang form data mà thiếu cột → cột thiếu bị xóa; cột không gắn dữ liệu không tham gia chuyển đổi.
- Non-key form parameters bị xóa sau OnCreateAtServer → lưu vào form data nếu cần.
- Composite type không lấy attribute qua reference được.
- Command không có Action → không dùng được; Action chỉ nhận client procedure/function có một parameter.
- Field không gắn attribute / button không gắn command → không hiển thị.
- Collapsible/Pop-up group cần tiêu đề hiển thị; pop-up không lồng nhau.
- Không dùng conditional appearance để ẩn cả dòng table; không dùng conditional appearance của form cho dynamic list nếu list tự làm được.
- Dùng dynamic list fields trong conditional appearance → bật Always use.
- Điều khiển MarkIncomplete bằng conditional appearance → đặt AutoMarkIncomplete = “No”.
- Subordinate subsystems không hiển thị trong Current section functions panel; Picture chỉ hiện với top-level subsystems.

## Điểm cần nhớ
- Thiết kế subsystems là bước đầu tiên; object có thể thuộc nhiều subsystem; kết hợp roles để giao diện gọn.
- Panels: Sections, Current section functions, Open items, Favorites, History; người dùng tự điều chỉnh được.
- Form có mặt ở cả server và client; mọi dữ liệu form phải là form attributes; một main attribute quyết định form extension.
- Form data types: FormDataStructure, FormDataCollection, FormDataStructureAndCollection, FormDataTree; kiểu trong ngoặc ở cột Type = sẽ được chuyển đổi.
- Trong form module ưu tiên FormAttributeToValue / ValueToFormAttribute (server); CopyFormData chạy cả client và server.
- Form parameters: Key parameter tạo uniqueness key; non-key bị xóa sau OnCreateAtServer; parameter không truyền = Undefined.
- Visibility cuối = Visible AND User visibility; ReadOnly được áp dụng theo group và từ Saved data khi form Read-only.
- WindowOpeningMode: Independent / Lock parent window (mặc định cho catalog item...) / Lock the entire interface; Cancel = True trong OnCreateAtServer hoặc OnOpen để ngắt mở form.

## Thẻ gợi ý bài thực hành (Practice 9)

> Thẻ bám theo đề "9. Practice.docx". Phần lớn yêu cầu làm bằng thiết lập trong Designer (subsystem, form editor, choice parameters, home page); chỉ một số bài cần code trong form module.

### Bài tập 1 — Subsystem Purchases, picture và explanation
- **Đề bài (tóm tắt):** Tạo subsystem Purchases; đặt picture và explanation cho mọi subsystem.
- **Gợi ý 1 — Hướng đi:** Mục "Subsystems" và "Subsystem properties"; Picture chỉ hiển thị với top-level subsystem.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Subsystem → property **Explanation**, **Picture** (Select picture → From configuration → Add → Common picture → Load from file).
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo subsystem Purchases, bật Include in the command interface.
  2. Tạo common picture cho từng subsystem, gán vào Picture.
  3. Điền Explanation.
- **Lỗi hay gặp:**
  - Gán picture cho subsystem con → không hiện.
  - Quên Include in the command interface → section không xuất hiện.
- **Tự kiểm tra:** Sections panel hiển thị icon cho từng section; rê chuột thấy explanation.

### Bài tập 2 — Document PurchaseInvoice
- **Đề bài (tóm tắt):** Tạo PurchaseInvoice có **Vendor**, **Contract**, DocumentTotal và tabular section **Products** (**Product**, **Quantity**, **Price**, **Amount**), thuộc Purchases, list presentation "Purchase Invoices".
- **Gợi ý 1 — Hướng đi:** Cấu trúc tương tự SalesInvoice (Bài 3–4); đề không yêu cầu thêm, nhưng nên cho Contract lọc theo Vendor giống Contract của SalesInvoice lọc theo Customer (Choice parameter links `Filter.Owner`, Bài 4).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Document mới; Vendor kiểu `CatalogRef.Counterparties`; Contract kiểu `CatalogRef.CounterpartyContracts`; Fill checking cho các attribute in đậm; List presentation; tab Subsystems chọn Purchases.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo document và attribute.
  2. Thêm tabular section với 4 attribute.
  3. Đặt presentation và subsystem.
- **Lỗi hay gặp:**
  - Không đặt Choice parameter links cho Contract → chọn được hợp đồng của đối tác khác.
  - Quên Fill checking cho các attribute in đậm.
- **Tự kiểm tra:** Section Purchases có lệnh "Purchase Invoices"; bỏ trống Vendor → không ghi được.

### Bài tập 3 — Number và Date trên cùng một dòng
- **Đề bài (tóm tắt):** Sửa form SalesInvoice và PurchaseInvoice để Number và Date nằm ngang trên một dòng.
- **Gợi ý 1 — Hướng đi:** Mục "Group": một **Regular group** với kiểu nhóm ngang chứa hai field.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form editor → Form items → Add → Group – Regular group; property Group (horizontal), ShowTitle = No, Representation None; kéo Number và Date vào group.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo document form (nếu chưa có) cho từng document.
  2. Thêm regular group ngang ở đầu form.
  3. Kéo Number và Date vào.
- **Lỗi hay gặp:**
  - Group để kiểu dọc → field vẫn xếp chồng.
  - Để hiện tiêu đề group → thêm một dòng tiêu đề thừa.
- **Tự kiểm tra:** Mở chứng từ ở Enterprise mode, Number và Date nằm cạnh nhau.

### Bài tập 4 — Mặc định chỉ hai panel
- **Đề bài (tóm tắt):** Cấu hình để mặc định hiển thị sections panel và open items panel.
- **Gợi ý 1 — Hướng đi:** Mục "Panels": developer chỉnh bố cục mặc định, người dùng có thể tự đổi sau.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Root Configuration → context menu → **Open client application interface**.
- **Gợi ý 3 — Khung bài làm:**
  1. Mở cửa sổ chỉnh panels.
  2. Chỉ giữ Sections panel và Open items panel ở vùng hiển thị.
- **Lỗi hay gặp:**
  - Infobase cũ đã lưu thiết lập giao diện của người dùng → không thấy thay đổi; thử với người dùng mới hoặc khôi phục thiết lập mặc định.
- **Tự kiểm tra:** Khởi động Enterprise mode chỉ thấy hai panel đó.

### Bài tập 5 — Quan hệ của Counterparty (vendor / customer / other)
- **Đề bài (tóm tắt):** Thêm số attribute cần thiết vào Counterparties để biểu diễn quan hệ: vendor, customer, other — một counterparty có thể có nhiều quan hệ cùng lúc; tạo item form, đổi TitleLocation của các checkbox sang "Right".
- **Gợi ý 1 — Hướng đi:** Vì các quan hệ **không loại trừ nhau**, một attribute Enumeration (chỉ chọn một giá trị) không đủ; mỗi quan hệ là một attribute Boolean riêng. Trên form, Boolean hiển thị dạng checkbox (mục "Radio buttons và checkboxes").
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Ba attribute Boolean trong catalog Counterparties; tạo Item form; từng checkbox → property **TitleLocation** = Right.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm attribute Boolean cho từng quan hệ.
  2. Tạo item form.
  3. Chỉnh TitleLocation cho các checkbox.
- **Lỗi hay gặp:**
  - Dùng một attribute Enumeration → không thể vừa vendor vừa customer.
  - Đổi TitleLocation của group thay vì của từng checkbox.
- **Tự kiểm tra:** Một counterparty tick được cả Vendor và Customer; nhãn nằm bên phải ô tick.

### Bài tập 6 — Chỉ chọn Vendor / Customer phù hợp
- **Đề bài (tóm tắt):** Trong PurchaseInvoice, field Vendor chỉ chọn counterparty có quan hệ Vendor; trong SalesInvoice, Customer chỉ chọn counterparty có quan hệ Customer.
- **Gợi ý 1 — Hướng đi:** Giá trị lọc **cố định** (luôn là True) → property **Choice parameters** của attribute (khác Choice parameter links, vốn lấy giá trị từ field khác).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Attribute Vendor của PurchaseInvoice / Customer của SalesInvoice → Choice parameters → Name `Filter.<tên attribute Boolean>`, Value = True.
- **Gợi ý 3 — Khung bài làm:**
  1. Mở Choice parameters của attribute.
  2. Thêm một dòng filter theo attribute Boolean tương ứng.
  3. F7 và thử chọn.
- **Lỗi hay gặp:**
  - Gõ sai tên sau `Filter.` → filter không có tác dụng.
  - Đặt filter trên form item của một form nhưng quên form khác; đặt ở attribute metadata thì áp dụng cho mọi form.
- **Tự kiểm tra:** Danh sách chọn Vendor chỉ hiện counterparty có tick Vendor; tương tự với Customer.

### Bài tập 7 — Tabular section Services trên page riêng
- **Đề bài (tóm tắt):** Thêm tabular section Services (cùng attribute như Products) cho PurchaseInvoice và SalesInvoice; đặt bảng Products và Services trên hai page khác nhau.
- **Gợi ý 1 — Hướng đi:** Mục "Group": group kiểu **Pages** chứa các group **Page**.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Document → Tabular sections → Add `Services` với Product, Quantity, Price, Amount; form editor → Add group Pages → hai Page → kéo table Products vào page 1, Services vào page 2.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm tabular section ở cả hai document.
  2. Kéo tabular section mới lên form.
  3. Tạo Pages + 2 Page, sắp lại hai table.
- **Lỗi hay gặp:**
  - Thêm Services chỉ ở một document.
  - Đặt Page trực tiếp dưới form mà không có group Pages cha.
  - Quên đặt ReadOnly cho cột Amount của Services như đã làm ở Products.
- **Tự kiểm tra:** Form chứng từ có hai tab "Products" và "Services", mỗi tab một bảng.

### Bài tập 8 — Dùng chung thuật toán cho Services
- **Đề bài (tóm tắt):** Tính Amount theo dòng và kiểm tra giá tối thiểu cho bảng Services giống bảng Products, không lặp code mà gọi cùng code từ event của cả hai bảng.
- **Gợi ý 1 — Hướng đi:** Thuật toán không được "đóng cứng" vào `Items.Products`; nhận **dòng hiện tại làm parameter**, rồi mỗi handler chỉ truyền dòng của bảng mình. Đây chính là áp dụng mục "Data path" (`Items.<Table>.CurrentData`) và quy tắc tránh duplication.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form module SalesInvoice: sửa procedure kiểm tra giá tối thiểu để nhận parameter dòng; thêm handler OnChange cho cột Quantity, Price, Product của Services (`&AtClient`), mỗi handler chỉ vài dòng gọi các procedure chung với `Items.Services.CurrentData`.
- **Gợi ý 3 — Khung bài làm:**
  1. Đổi chữ ký procedure kiểm tra giá: thêm parameter dòng, bỏ việc tự lấy `Items.Products.CurrentData` bên trong.
  2. Sửa các handler Products để truyền dòng.
  3. Tạo các handler Services tương ứng.
  ```bsl
  &AtClient
  Procedure ServicesPriceOnChange(Item)
  	ControlMinimumSalesPrice(___);          // dòng hiện tại của bảng Services
  	CalculateAmountAtRow(___, ___);         // cùng dòng đó và discount của document
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Copy nguyên procedure thành bản "...Services" → duplication.
  - Bên trong procedure chung vẫn còn tham chiếu `Items.Products` → bảng Services kiểm tra nhầm dòng.
  - Quên kiểm tra dòng = Undefined trước khi đọc field.
- **Tự kiểm tra:** Nhập giá thấp hơn tối thiểu ở bảng Services → giá tự sửa và có message; Amount của Services tính có discount.

### Bài tập 9 — DocumentTotal = goods + services
- **Đề bài (tóm tắt):** Sửa thuật toán DocumentTotal thành tổng Amount của cả Products và Services.
- **Gợi ý 1 — Hướng đi:** Mở rộng procedure server tính lại tổng (Bài 7) để duyệt thêm bảng thứ hai; gọi nó từ OnChange của cả hai form table.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Procedure `&AtServer` hiện có; handler OnChange của form table Services (`&AtClient`).
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm vòng lặp thứ hai cho `Object.Services` vào cùng biến tổng.
  2. Tạo handler OnChange của table Services gọi procedure đó.
- **Lỗi hay gặp:**
  - Reset biến tổng về 0 giữa hai vòng lặp → mất phần goods.
  - Quên handler OnChange của Services → tổng không cập nhật khi sửa dịch vụ.
- **Tự kiểm tra:** Goods 100 + services 50 → DocumentTotal = 150; xóa dòng dịch vụ → tổng giảm.

### Bài tập 10 — Số dòng trên tiêu đề page "Products (2)"
- **Đề bài (tóm tắt):** Tiêu đề page hiển thị số dòng của bảng trên page đó.
- **Gợi ý 1 — Hướng đi:** Không cần code: page có property **TitleDataPath** (mục "Thuộc tính/thiết lập": Table / Page group) — gắn tiêu đề với một data path có sẵn của tabular section là số dòng.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form editor → page chứa Products → property TitleDataPath → chọn trong cây `Object.Products` phần tử biểu diễn số dòng; làm tương tự cho Services, ở cả hai document.
- **Gợi ý 3 — Khung bài làm:**
  1. Chọn page, mở TitleDataPath.
  2. Mở rộng `Object` → tabular section → chọn mục số dòng.
- **Lỗi hay gặp:**
  - Viết code đếm dòng trong OnChange và gán Title → chạy được nhưng phức tạp và dễ quên cập nhật.
  - Chọn data path của bảng khác page.
- **Tự kiểm tra:** Thêm dòng → tiêu đề page tự đổi thành "Products (n)".

### Bài tập 11 — Lọc Product theo loại trong Products / Services
- **Đề bài (tóm tắt):** Bảng Products chỉ chọn product loại InventoryItem; bảng Services chỉ chọn loại Service.
- **Gợi ý 1 — Hướng đi:** Lọc theo giá trị cố định → **Choice parameters** của attribute Product trong từng tabular section.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Document → tabular section Products → attribute Product → Choice parameters: `Filter.<attribute loại của Products>` = giá trị enum tương ứng; làm tương tự cho Services, ở cả hai document.
- **Gợi ý 3 — Khung bài làm:**
  1. Mở Choice parameters của Product trong Products, chọn giá trị InventoryItem.
  2. Làm lại cho Services với giá trị Service.
- **Lỗi hay gặp:**
  - Tên attribute sau `Filter.` phải đúng tên attribute loại trong catalog Products của bạn (trong cấu hình mẫu là `ProductType`).
  - Đặt filter ở attribute Product của catalog thay vì ở attribute của tabular section.
- **Tự kiểm tra:** Danh sách chọn ở bảng Products không có dịch vụ và ngược lại.

### Bài tập 12 — Nút Pick cho Products và Services
- **Đề bài (tóm tắt):** Thêm nút Pick cho từng bảng của SalesInvoice; mở choice form của Products lọc theo loại; chọn không đóng form; nếu product đã có trong bảng thì bỏ qua, chưa có thì thêm dòng với Product và Quantity = 1.
- **Gợi ý 1 — Hướng đi:** Mục "Form parameters" và "Form commands": mở form bằng `OpenForm` với Structure tham số (MultipleChoice, CloseOnChoice, Filter); truyền **Owner** là form table để giá trị chọn quay về event **ChoiceProcessing** của table đó. Một procedure mở form dùng chung, nhận table và loại product làm parameter.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form commands `PickProducts`, `PickServices` (Action `&AtClient`), đặt thành button trong command bar của từng table. `PredefinedValue("Enum.<...>.<...>")` lấy giá trị enum trên client. Event ChoiceProcessing của từng form table (`&AtClient`). Kiểm tra trùng bằng `Object.<Tabular section>.FindRows(<Structure>)` — trả về Array.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo hai command + button.
  2. Viết procedure chung mở choice form với 3 key tham số và Owner.
  3. Tạo handler ChoiceProcessing cho từng bảng: tìm dòng có Product đã chọn, nếu không có thì thêm dòng.
  ```bsl
  &AtClient
  Procedure PickProductsToTable(TableItem, ProductType)
  	Parameters_ = New Structure("MultipleChoice, CloseOnChoice, Filter", ___, ___, ___);
  	OpenForm(___, Parameters_, ___);   // tên choice form, tham số, Owner
  EndProcedure

  &AtClient
  Procedure ProductsChoiceProcessing(Item, SelectedValue, StandardProcessing)
  	// tìm dòng có Product = SelectedValue; nếu Count() = 0 thì thêm dòng, điền 2 cột
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Không truyền Owner → ChoiceProcessing của table không được gọi.
  - Gõ sai tên key: [ghi chú ngoài nguồn] code demo/cấu hình của khóa có chỗ viết `CloseOnChoise` — platform không nhận key sai nên form vẫn đóng sau mỗi lần chọn; key đúng là `CloseOnChoice`.
  - Key bên trong Filter phải là tên attribute loại trong catalog Products của bạn (đề viết "Type", cấu hình mẫu dùng `ProductType`).
  - `FindRows()` trả về Array các dòng — kiểm tra "chưa có" bằng method `Count()` của Array.
- **Tự kiểm tra:** Bấm Pick ở Products → chỉ thấy InventoryItem; chọn liên tiếp nhiều product, form không đóng, mỗi product chỉ xuất hiện một lần với Quantity = 1; chọn lại product đã có → không thêm dòng.

### Bài tập 13 — Footer tổng Amount
- **Đề bài (tóm tắt):** Thêm footer cho bảng Products và Services của SalesInvoice và PurchaseInvoice, hiển thị tổng cột Amount.
- **Gợi ý 1 — Hướng đi:** Không cần code: table có property **Footer**, cột có **FooterDataPath** gắn với tổng của collection (mục "Associating items with form attributes", connection with collection totals).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form table → Footer = bật; cột Amount → FooterDataPath → chọn phần tổng của Amount trong `Object.<Tabular section>`.
- **Gợi ý 3 — Khung bài làm:**
  1. Bật Footer cho table.
  2. Đặt FooterDataPath cho cột Amount.
  3. Lặp lại cho 4 bảng (2 document × 2 tabular section).
- **Lỗi hay gặp:**
  - Bật Footer nhưng quên FooterDataPath → footer trống.
  - Đặt FooterDataPath ở cột khác (ví dụ Quantity) trong khi đề yêu cầu Amount.
  - [ghi chú ngoài nguồn] Trong cấu hình mẫu cuối khóa không tìm thấy footer tổng Amount; demo Theory chỉ có footer cho cột Quantity — đừng dựa vào cấu hình mẫu để đối chiếu bài này.
- **Tự kiểm tra:** Dưới mỗi bảng hiện tổng Amount, cập nhật ngay khi sửa dòng.

### Bài tập 14 — List form trên Home page
- **Đề bài (tóm tắt):** Hiển thị list form của SalesInvoice và PurchaseInvoice trên home page; tạo list form nếu chưa có.
- **Gợi ý 1 — Hướng đi:** Mục "Home page": developer cấu hình bố cục mặc định của home page.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Tạo **List form** cho từng document (Forms → Add → Document list form); root Configuration → context menu → mở cấu hình **Home page** → thêm hai list form vào cột.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo list form cho hai document.
  2. Mở cấu hình home page, thêm hai form.
  3. F7, khởi động lại Enterprise mode.
- **Lỗi hay gặp:**
  - Không tạo list form trước → không chọn được form để đưa lên home page.
  - Thiết lập home page của người dùng đã lưu ghi đè bố cục mặc định.
- **Tự kiểm tra:** Mở ứng dụng thấy ngay danh sách Sales invoices và Purchase Invoices trên trang chủ.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/10-theory)

> [ghi chú ngoài nguồn] Bản export nhánh lesson/09-theory trùng với master (chỉ khác ConfigDumpInfo, Rights và một file XML) — tức là chứa lời giải Practice, nên không trích vào bản học viên. Các demo form của Theory Bài 9 (Filter qua form parameters, conditional appearance "amount > 1 triệu", footer) xuất hiện trong nhánh lesson/10-theory khi so với lesson/08-theory, nên được trích từ nhánh đó.

### Standard parameter Filter khi mở choice form từ code (StartChoice)
Nguồn: nhánh lesson/10-theory — cf/Documents/PersonnelChange/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure ChangesEmployeeStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenParameters = New Structure("Filter", New Structure("Gender", PredefinedValue("Enum.Gender.Female")));
	
	OpenForm("Catalog.Employees.ChoiceForm", OpenParameters, Item);
	
EndProcedure
```
- Tắt xử lý chuẩn (`StandardProcessing = False`) rồi tự mở choice form với form parameter `Filter` (Structure lồng Structure) — dạng code của property **Choice parameters** `Filter.Gender`.
- Parameter thứ ba của `OpenForm` là `Item` → field `ChangesEmployee` thành **FormOwner**; giá trị chọn được trả về field đó.
- `PredefinedValue("Enum.Gender.Female")` lấy giá trị enum ở client (không truy cập database).

### Choice parameters "Filter.Type" bằng code và Pick với form parameters
Nguồn: nhánh lesson/10-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl và cf/Documents/PurchaseInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure PickProducts(Command)
	PickProductsToTable(Items.Products, PredefinedValue("Enum.ProductTypes.Product"));
EndProcedure

&AtClient
Procedure PickServices(Command)
	PickProductsToTable(Items.Services, PredefinedValue("Enum.ProductTypes.Service"));
EndProcedure

&AtClient
Procedure PickProductsToTable(TableItem, ProductType)

	OpenForm(
		"Catalog.Products.ChoiceForm",
		New Structure("MultipleChoice, CloseOnChoise, Filter", False, False, New Structure("Type", ProductType)),
		TableItem
	);

EndProcedure
```
```bsl
&AtClient
Procedure Pick(Command)
	OpenForm("Catalog.Products.ChoiceForm", New Structure("ChoiceMode, CloseOnChoice", True, False), Items.Products);
EndProcedure
```
- Đúng ví dụ của bài: giới hạn products có `Type = Enum.ProductTypes.Product` — `New Structure("Type", ProductType)` được truyền làm form parameter `Filter`.
- Ở PurchaseInvoice, standard parameters `ChoiceMode` và `CloseOnChoice` được truyền qua Structure; Owner là table `Items.Products` → giá trị chọn đi vào event `ProductsChoiceProcessing`.
- [ghi chú ngoài nguồn] Key `CloseOnChoise` trong SalesInvoice là lỗi chính tả của code demo (standard parameter đúng là `CloseOnChoice`, như trong PurchaseInvoice); platform không nhận key sai này nên `CloseOnChoice` giữ giá trị mặc định.

### Conditional appearance và footer (thiết lập trong Form.xml, không có code)
Nguồn: nhánh lesson/10-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form.xml
```xml
			<dcsset:item>
				<dcsset:selection>
					<dcsset:item>
						<dcsset:field>Products</dcsset:field>
					</dcsset:item>
				</dcsset:selection>
				<dcsset:filter>
					<dcsset:item xsi:type="dcsset:FilterItemComparison">
						<dcsset:left xsi:type="dcscor:Field">Object.Products.Amount</dcsset:left>
						<dcsset:comparisonType>GreaterOrEqual</dcsset:comparisonType>
						<dcsset:right xsi:type="xs:decimal">1000000</dcsset:right>
					</dcsset:item>
				</dcsset:filter>
				<dcsset:appearance>
					<dcscor:item xsi:type="dcsset:SettingsParameterValue">
						<dcscor:parameter>TextColor</dcscor:parameter>
						<dcscor:value xsi:type="v8ui:Color">#4BB859</dcscor:value>
					</dcscor:item>
				</dcsset:appearance>
			</dcsset:item>
```
- Đây là ví dụ "đổi màu chữ dòng trong table Products nếu amount > 1 triệu": điều kiện `Object.Products.Amount` **GreaterOrEqual** `1000000`, appearance **TextColor**, áp dụng cho field `Products`.
- Cùng Form.xml, cột `ProductsQuantity` có `FooterDataPath` = `Object.Products.TotalQuantity` (connection with collection totals); cột `ProductsWieght` có DataPath `Object.Products.Product.Weight` (connection through reference, luôn View only).

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Giao diện người dùng cơ bản](https://www.youtube.com/watch?v=rn0hEz5Xc08&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=7) (5:44) — Bài 3 — Subsystem (sơ lược); Bài 9 — Subsystems, Panels, command interface _(mã nội bộ JC-8)_
- [Homepage, form và command](https://www.youtube.com/watch?v=DDk5kS4BRow&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=8) (5:11) — Bài 9 — Home page, form; Bài 14 — Commands, Command interface _(mã nội bộ JC-9)_
- [Cơ bản về trình chỉnh sửa form](https://www.youtube.com/watch?v=FqrPnmv_QPA&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=9) (7:05) — Bài 9 — form attributes, form items, groups, DataPath _(mã nội bộ JC-10)_
- [Sự kiện và trình xử lý sự kiện](https://www.youtube.com/watch?v=FAkymD2Zqks&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=10) (9:29) — Bài 9 — form events; Bài 16 — form & form element events, thứ tự events _(mã nội bộ JC-11)_
- [Cơ bản về UX-UI](https://www.youtube.com/watch?v=Fsfbuzgyutk&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=30) (6:39) — Bài 9 — bố cục form, groups. Ngoài giáo trình: nguyên lý thiết kế giao diện (công thái học) không có trong giáo trình _(mã nội bộ JC-31)_
- [Phần tử trường](https://www.youtube.com/watch?v=KmiQm3DJ4AQ&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=31) (5:32) — Bài 9 — form items (field). Ngoài giáo trình: các loại field chi tiết, mặt nạ nhập liệu (mask), định dạng hiển thị không có mục riêng trong giáo trình _(mã nội bộ JC-32)_
- [Giao diện lệnh (command) trên biểu mẫu (form)](https://www.youtube.com/watch?v=4sYHynvvbls&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=34) (6:29) — Bài 9 — form commands, command bar; Bài 14 — commands. Ngoài giáo trình: gán phím tắt cho command không có trong giáo trình _(mã nội bộ JC-35)_
- [Hiển thị có điều kiện](https://www.youtube.com/watch?v=a6kSspz-wo4&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=35) (10:29) — Bài 9 — conditional appearance trên form; Bài 18 — conditional appearance trong DCS _(mã nội bộ JC-36)_
- [Danh sách động (Dynamic list)](https://www.youtube.com/watch?v=rr_ohZ13H6k&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=36) (4:53) — Bài 9 — Dynamic list (bảng hoặc query tùy ý); Bài 10 — query language _(mã nội bộ JC-37)_
- [Trò chuyện với người dùng](https://www.youtube.com/watch?v=s0MHq7d_nVc&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=38) (9:26) — Bài 9 — ShowQueryBox + CallbackDescription (code mẫu); Bài 7 — dialog không chặn (CallbackDescription); Bài 21 — ShowUserNotification _(mã nội bộ JC-39)_

<!-- video-qa-thuchanh:start -->

Video giải đáp tình huống thực chiến và video thực hành từng bước liên quan tới bài này (thẻ chi tiết, triệu chứng, lưu ý khi giới thiệu: `references/video-qa-thuc-chien.md`, `references/video-thuc-hanh.md`; cùng mẫu câu dẫn ở trên):

- [Cách hiển thị biểu ghi tích lũy lên phân hệ](https://www.youtube.com/watch?v=DBJeS7LfUpY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=4) (1:53) — cách hiện register lên phân hệ (giải đáp tình huống; Bài 9 chính) _(mã nội bộ QA-4)_
- [Báo động tồn kho thấp với màu chữ hiển thị](https://www.youtube.com/watch?v=0JbOMl80lnY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=18) (13:09) — tô màu cảnh báo tồn kho thấp (giải đáp tình huống; Bài 9 chính) _(mã nội bộ QA-18)_
- [Lọc dữ liệu chọn sản phẩm theo hãng](https://www.youtube.com/watch?v=EfF2acfP2Y8&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=19) (6:30) — lọc danh sách chọn theo một trường khác (giải đáp tình huống; Bài 9 chính) _(mã nội bộ QA-19)_
- [Thay đổi Style (màu sắc) của chương trình](https://www.youtube.com/watch?v=cgmDdh6bHMg&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=24) (2:47) — đổi màu giao diện bằng Style (giải đáp tình huống; Bài 9 chính) _(mã nội bộ QA-24)_
- [Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng](https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1) (4:24) — cách tìm lỗi sự kiện OnChange không chạy (giải đáp tình huống; Bài 9 liên quan) _(mã nội bộ QA-1)_
- [Thêm ảnh cho các đối tượng](https://www.youtube.com/watch?v=TQNa4cveOdc&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=6) (10:04) — lưu và hiển thị ảnh cho sản phẩm (giải đáp tình huống; Bài 9 liên quan) _(mã nội bộ QA-6)_
- [Hiển thị đối tượng Siêu dữ liệu lên Quick menu](https://www.youtube.com/watch?v=rPSNKvFEQ8E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=21) (2:23) — bật lệnh cho phân hệ đang trống (giải đáp tình huống; Bài 9 liên quan) _(mã nội bộ QA-21)_
- [Extension (Phần mở rộng) trong 1C:Enterprise](https://www.youtube.com/watch?v=T_DEaA1p_bA&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=22) (6:33) — thêm báo cáo bằng extension mà không sửa cấu hình gốc (giải đáp tình huống; Bài 9 liên quan) _(mã nội bộ QA-22)_
- [Tạo lập hệ thống thông tin thư viện](https://www.youtube.com/watch?v=3DMFgUjg2Js&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=5) (24:38) — mượn – trả và tạo phiếu trả từ phiếu mượn (thực hành case study; Bài 9 liên quan) _(mã nội bộ P2-5)_
- [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28) — xử lý nhiều đơn hàng bằng một lệnh (thực hành case study; Bài 9 liên quan) _(mã nội bộ P2-6)_

<!-- video-qa-thuchanh:end -->
