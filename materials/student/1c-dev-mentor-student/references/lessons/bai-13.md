# Bài 13 — Constants, Document journals, Charts of characteristic types

## Khái niệm chính

### Constants
- **Constants** dùng để lưu thông tin ít hoặc không bao giờ thay đổi. Ví dụ: "pickup warehouse" — khi delivery method là "pickup", tự điền kho bán hàng bằng giá trị mặc định; khi cần đổi (ví dụ đổi kho thuê sang kho mua), chỉ cần đổi giá trị constant.
- Nền tảng tự sinh form để làm việc với giá trị constant.
- Developer có thể tạo common form (nhánh **Common** → **Common forms**) loại **"Constants form"** để làm việc với một nhóm constants — gom constants theo mục đích (ví dụ "Default company" và "Default bank account" trên common form "Default values", thêm vào subsystem Sales).
- Property **"Include in the command interface"**: cho phép user làm việc với giá trị constant từ giao diện mà không cần common form. Khi đã có Constants form chung, có thể tắt property này để bỏ form riêng của từng constant khỏi giao diện.
- Property **"Default form"**: form được dùng thay cho form tự sinh khi mở constant để sửa.
- Từ code: **Set()** (procedure) để đặt giá trị, **Get()** (function) của constant manager để lấy giá trị.
- Ví dụ: tự điền company và bank account cho Sales invoice trong handler **Filling** của document object module.
- **Note**: không khuyến khích dùng constants cho giá trị thay đổi liên tục: temporary resource access tokens; giá trị số tính toán được tính lại định kỳ; các giá trị biết trước sẽ thay đổi theo chu kỳ.

### Document journals
- **Document journals** chủ yếu để nhóm trực quan các document khác loại khi xem. Có thể tạo nhiều metadata object "Document journal" trong configuration.
- Metadata của journal chỉ định loại document nào được đưa vào. Mỗi document có thể thuộc một hoặc nhiều journal, hoặc không thuộc journal nào.
- Có thể mô tả nhiều cột (columns) cho journal. Journal column = danh sách details của các document khác loại, có giá trị hiển thị trong cùng một cột (ví dụ journal "Purchases and Sales" gồm "Purchase invoice" và "Sales invoice": gộp attribute Vendor và Customer thành cột "Counterparty").
- **Note**: không thể chọn nhiều attributes của cùng một document vào một journal column.
- Journal có các cột mặc định: date, number, document type; có thể thêm số cột bổ sung bất kỳ.
- Nếu không chọn detail của một document cho cột → cột đó trống với mọi document loại đó. Không trộn các khái niệm hoàn toàn khác nhau vào một cột (ví dụ counterparty và tổng tiền).
- Nếu journal có hơn 1 loại document, nút tạo document mới thành submenu chọn loại document.
- Với mỗi journal, hệ thống tạo bảng trong database lưu link tới documents thuộc journal, và nhân bản nội dung các details đưa vào cột, số document, dấu posting... Khi document được ghi, hệ thống ghi/cập nhật records trong các bảng journal mà document thuộc về.

### Charts of characteristic types
- Dùng khi cần lưu thuộc tính của applied objects mà thành phần và kiểu chưa biết trước lúc phát triển (ví dụ product: màu, size, kích thước, vật liệu đóng gói; counterparty: "foreign company", "settlement in foreign currency"; warehouse: "requires an order for a pass to the territory").
- Characteristics có thể khác nhau theo nhóm object; user có thể tự nhập characteristics khi vận hành.
- 2 cách:
  1. Tạo attribute riêng cho mỗi characteristic → nhược điểm: mỗi characteristic là một trường trong bảng database, chiếm chỗ dù không dùng; nhiều characteristic → nhiều trường "thừa", bất tiện cho cả developer và user; thêm characteristic mới phải sửa ứng dụng.
  2. Dùng object đặc biệt mô tả tên, kiểu characteristic... → không có các nhược điểm trên; thêm characteristic không cần sửa ứng dụng, không tốn chỗ thừa, user tự thêm được. Đối tượng này là **chart of characteristic types**. Nhược điểm: logic tổ chức và sử dụng phức tạp hơn, nhưng chi phí chỉ phát sinh một lần lúc phát triển.
- Property **"Characteristic value type"**: định nghĩa composite data type gồm mọi kiểu có thể cần khi chỉ định kiểu giá trị characteristic.
- Ngoài primitive types, thường cần reference tới objects trong database (ví dụ "Main supplier" là link tới counterparty). Để giữ toàn vẹn dữ liệu (tránh "red", "Red", "Redd" khi nhập màu dạng string) và giới hạn lựa chọn (ví dụ chỉ các size thực có của mẫu giày) → lưu additional characteristic values trong object riêng: tạo catalog subordinate tới chart of characteristic types và chỉ định nó trong property **"Additional characteristic values"**.
  - **Note**: để chọn catalog làm giá trị "Additional characteristic values", catalog đó cũng phải được chọn trong "Characteristic value type".
- Lưu giá trị characteristic gắn với owner (product, counterparty...) → dùng **information register**. Ví dụ register "ObjectsCharacteristicValues":
  - Dimensions: "Object" (owner — liệt kê mọi object muốn gắn vào cơ chế), "Characteristic type" (link tới chart of characteristic types).
  - Resource: "Characteristic value".
  - Bật flags **"Master"** và **"No empty values"** cho cả hai dimensions.
  - Kiểu của resource "Characteristic value": sau khi thêm chart of characteristic types, danh sách kiểu có nhóm **"Characteristic"** — chọn characteristics của chart vừa tạo.
  - **Note**: không thể chỉ định cho resource này composite type gồm nhiều Characteristic types → giá trị của một chart of characteristic types lưu trong một register (chart thứ hai → register thứ hai...).
- Property **"Select type automatically"** của resource CharacteristicValue: đặt giá trị "Characteristic type" để kiểu của field phụ thuộc vào field khác (dimension CharacteristicType). Khi đó không còn nút chọn kiểu (ba chấm), mà là nút chọn từ danh sách và nút mở.
- Lọc additional values theo characteristic type đã chọn: đặt tham số chọn giá trị (choice parameters) cho resource của information register.
- Phân loại characteristic types theo object sở hữu:
  - Tạo enumeration **CharacteristicsObjectTypes** (Companies, Counterparties, Employees, Products, Warehouses; gán synonym chi tiết hơn).
  - Thêm attribute **CharacteristicsObjectType** (kiểu enumeration trên) vào chart of characteristic types, bắt buộc điền.
  - Sửa record form của register "Objects characteristic values":
    - Ẩn field Object nếu đã được điền (form mở từ một object cụ thể hoặc tạo bằng copy) — trong handler **OnCreateAtServer**; nếu chưa điền thì hiển thị để user điền.
    - Đặt choice parameters cho field "CharacteristicType" theo CharacteristicsObjectType: nếu Object khác Undefined → lọc theo loại object; nếu không → choice parameters rỗng (không lọc).
    - Gọi lại procedure này trong event **OnChange** của field Object: nếu loại object thay đổi (so với biến **PreviousObjectType**) → xóa CharacteristicType và CharacteristicValue, cập nhật choice parameters, rồi cập nhật biến.
- Cửa sổ **Additional metadata object characteristics** (mở từ context menu của metadata object — dòng Characteristics — hoặc nút **Characteristics** trên tab data của object editor): **phải làm cho mỗi object có characteristics**, chỉ định:
  - Object chứa danh sách characteristics (field **Characteristic types**, ví dụ chart AdditionalAttributesAndProperties).
  - Key field để lấy characteristic cụ thể, xác định kiểu giá trị và presentation (property **Key Field** — ví dụ standard attribute Ref).
  - Attribute characteristic nào (với giá trị filter nào) xác định danh sách characteristics của metadata object.
  - Phần trái: object cung cấp characteristic types; phần phải: nơi lưu giá trị characteristic.
  - Nhờ thiết lập này, user truy cập characteristics như attributes trong mọi report và dynamic list (ví dụ filter theo Color, Size trong list form của Products).
- Các phương án khác dùng chart of characteristic types:
  - Một chart cho một metadata object.
  - Một chart cho một (hoặc nhiều) metadata object, nhưng tính khả dụng của characteristics cấu hình riêng cho elements/groups (ví dụ "Shoe Size" chỉ cho nhóm "Shoes").
  - Một chart cho nhiều metadata objects, nhưng characteristics thuộc object qua entity trung gian (ví dụ catalog CharacteristicSet "aluminum can, 330 ml" dùng cho nhiều product) → lợi thế: ghi sổ theo characteristics (registers lưu nomenclature + set of characteristics); với cách demo (mỗi characteristic là một giá trị riêng) thì phải áp hai selection rồi gộp.

### Dùng characteristics trong query
- Ví dụ: chọn items thuộc nhóm "Clothes and shoes", hiển thị color và size ở cột riêng → join tới bảng register lưu giá trị characteristics **hai lần**; điều kiện join chỉ định characteristic type cụ thể và Object của register = reference của product.
- Trong WHERE: kiểm tra product thuộc hierarchy của group, và loại bỏ groups (folders) khỏi kết quả.

## Cú pháp & ví dụ code

Set / Get constant:
```bsl
// Setting the value
Constants.MainSignatory.Set("John Doe");

// Getting the value
DefaultCompany = Constants.DefaultCompany.Get();
```

Tự điền từ constants trong Filling:
```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
    
    Company     = Constants.DefaultCompany.Get();
    BankAccount = Constants.DefaultBankAccount.Get();
    
EndProcedure
```

[ghi chú ngoài nguồn] Code OnCreateAtServer/OnChange của record form register và query hiển thị Color/Size trong tài liệu gốc chỉ có dạng ảnh chụp màn hình, không có văn bản code nên không được chép lại. → code record form: xem mục Code demo của bài Theory (nhánh lesson/13-theory). Riêng query hiển thị Color/Size không có trong nhánh lesson/13-theory nên vẫn chưa có code.

## Thuộc tính/thiết lập quan trọng trong Designer
- Constant: **Include in the command interface**, **Default form**; constant manager **Set()** / **Get()**.
- Common form: loại **Constants form** (Common → Common forms).
- Document journal: danh sách documents đưa vào; **columns** (mỗi cột chọn details của các document khác loại); cột mặc định date, number, document type.
- Chart of characteristic types: **Characteristic value type**, **Additional characteristic values**; attribute **CharacteristicsObjectType** (bắt buộc).
- Information register lưu giá trị: dimensions **Object**, **CharacteristicType**; resource **CharacteristicValue**; flags **Master**, **No empty values**; nhóm kiểu **Characteristic**; resource property **Select type automatically** = "Characteristic type"; choice parameters.
- Cửa sổ **Additional metadata object characteristics**: **Characteristic types**, **Key Field**, phần lưu trữ giá trị.

## Lỗi thường gặp / lưu ý
- Không dùng constants cho giá trị thay đổi liên tục (access tokens, giá trị tính lại định kỳ...).
- Không chọn được nhiều attributes của cùng một document vào một journal column.
- Không trộn khái niệm khác nhau vào một journal column.
- Catalog dùng làm "Additional characteristic values" phải có trong "Characteristic value type".
- Resource CharacteristicValue không nhận composite type gồm nhiều Characteristic types → mỗi chart một register.
- Nếu không đặt "Select type automatically", field giá trị mở form chọn kiểu dù characteristic type chỉ có một kiểu.
- Nếu không đặt choice parameters, danh sách hiển thị mọi additional values (ví dụ "48-50" của Size khi chọn Color).
- Không phân loại theo CharacteristicsObjectType → user có thể chỉ định màu cho counterparty.
- Thiết lập Additional metadata object characteristics phải làm cho **từng** object có characteristics.

## Điểm cần nhớ
- Constants: dữ liệu ít thay đổi; `Constants.<Name>.Set()` / `.Get()`; gom nhiều constants vào common form loại Constants form.
- Document journal: nhóm document khác loại để xem; columns gộp details khác tên; có bảng riêng trong database được cập nhật khi ghi document.
- Chart of characteristic types: lưu characteristics chưa biết trước; Characteristic value type (composite) + Additional characteristic values (catalog subordinate).
- Giá trị characteristics lưu trong information register (Object + CharacteristicType → CharacteristicValue), bật Master & No empty values.
- "Select type automatically" + choice parameters để field giá trị đúng kiểu và lọc đúng danh sách.
- Phân loại characteristic types theo owner bằng enumeration CharacteristicsObjectTypes.
- Cấu hình Additional metadata object characteristics cho từng object để dùng characteristics trong report/dynamic list.
- Query lấy nhiều characteristics thành nhiều cột: join register nhiều lần, mỗi lần một characteristic type.

## Thẻ gợi ý bài thực hành (Practice 13)

> Thẻ gợi ý dẫn hướng cho từng yêu cầu của 13. Practice.docx; không có lời giải hoàn chỉnh. Phần lớn bài này là thiết lập metadata trong Designer, rất ít code.

### Bài tập 1 — Constant "Control balances of goods" và form "Goods turnover settings"
- **Đề bài (tóm tắt):** Tạo constant bật/tắt kiểm tra số dư hàng; code kiểm tra số dư (Bài 12) chỉ chạy khi constant = True; tạo form "Goods turnover settings" để sửa constant và đưa vào subsystem Master data.
- **Gợi ý 1 — Hướng đi:** Giá trị cấu hình ít thay đổi → **Constant** (kiểu Boolean); đọc bằng `Get()` (mục Constants). Form gom constants → common form loại **Constants form**.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Constant (ví dụ `ControlBalanceOfGoods`, Boolean).
  - Trong procedure kiểm tra số dư của SalesInvoice và InventoryTransfer (object module, gọi từ Posting): ở đầu procedure đọc `Constants.<Tên>.Get()`, nếu False thì thoát.
  - Common form loại Constants form (main attribute kiểu `ConstantsSet`), kéo constant từ cây attribute lên form; đưa form vào subsystem Master data. Có thể tắt **Include in the command interface** của constant để chỉ sửa qua form chung.
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure ___(Cancel)
	If Not Constants.___.Get() Then
		// không kiểm tra -> ___
	EndIf;
	// ... phần query số dư âm của Bài 12 giữ nguyên
EndProcedure
```
- **Lỗi hay gặp:**
  - Đọc constant trên client (form `&AtClient`) → không được; đọc trong object module (server).
  - Chỉ sửa một trong hai document.
  - [ghi chú ngoài nguồn] Constant trong cấu hình của khóa tên `ContolBalanceOfGoods` (thiếu chữ "r"); khi đặt tên của bạn, kiểm tra chính tả trước khi viết code vì đổi tên sau sẽ phải sửa mọi nơi gọi.
- **Tự kiểm tra:** Tắt constant trên form settings → sales invoice bán quá số dư vẫn post được; bật lại → bị chặn như Bài 12.

### Bài tập 2 — Document journal "Sales documents"
- **Đề bài (tóm tắt):** Journal gồm SalesInvoice và ReturnOfGoodsFromCustomer, các cột Company, Customer, Contract, Warehouse, BankAccount, DocumentTotal; đưa vào subsystem Sales, nhóm Important.
- **Gợi ý 1 — Hướng đi:** **Document journal** nhóm document khác loại để xem; mỗi **column** gộp một attribute của từng document (mục Document journals).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Journal `SalesDocuments`: tab Data → Registered documents chọn 2 documents; Columns: thêm 6 cột, mỗi cột chọn attribute cùng nghĩa của cả hai documents. Command interface của subsystem Sales: kéo command mở journal vào nhóm **Navigation panel.Important**.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo journal, chọn documents.
  2. Thêm từng column, mỗi column chọn 2 attributes (một của mỗi document).
  3. Đưa journal vào subsystem Sales.
  4. Mở Command interface của subsystem Sales, đặt command OpenList của journal vào Important.
- **Lỗi hay gặp:**
  - Chọn hai attributes của cùng một document vào một column (không được phép).
  - Return thiếu attribute tương ứng (ví dụ BankAccount) → column trống với return.
- **Tự kiểm tra:** Section Sales hiển thị journal in đậm; mở journal thấy cả invoice và return, 6 cột có giá trị; nút tạo mới là submenu chọn loại document.

### Bài tập 3 — Chart of characteristic types AdditionalAttributesAndProperties
- **Đề bài (tóm tắt):** Cho phép user thêm attributes/properties bổ sung cho Companies, Counterparties, CounterpartyContracts, Products, Warehouses, SalesInvoice, ReturnOfGoodsFromCustomer; giá trị có thể là primitive types, Counterparties, hoặc giá trị bổ sung trong object riêng; tạo được characteristic và giá trị ngay từ các object đó; mỗi object chỉ thấy characteristics của loại mình.
- **Gợi ý 1 — Hướng đi:** Đây chính là mô hình của lý thuyết: **chart of characteristic types** + catalog subordinate lưu additional values + **information register** lưu giá trị theo (Object, CharacteristicType) + enumeration phân loại theo object owner (mục Charts of characteristic types).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Chart `AdditionalAttributesAndProperties`: **Characteristic value type** = composite (Boolean, String, Date, Number, `CatalogRef.Counterparties`, catalog additional values); **Additional characteristic values** = catalog subordinate (ví dụ `ObjectsPropertiesValues`, Owners = chart).
  - Enumeration `CharacteristicsObjectTypes` (một giá trị cho mỗi object trong danh sách của đề) + attribute `CharacteristicsObjectType` bắt buộc trong chart.
  - Information register `ObjectsCharacteristicValues`: dimensions `Object` (composite: 5 catalogs + 2 documents) và `CharacteristicType` (ref tới chart), cả hai bật **Master** và **No empty values**; resource `CharacteristicValue` kiểu nhóm **Characteristic** của chart, **Select type automatically** = CharacteristicType, choice parameter link `Filter.Owner` theo CharacteristicType.
  - Record form của register (form module):
    - `OnCreateAtServer` (`&AtServer`): nếu `Record.Object` đã điền → ẩn `Items.Object` và gọi procedure đặt choice parameters.
    - Procedure đặt choice parameters (`&AtServer`): tạo mảng, nếu Object khác Undefined thì thêm một `New ChoiceParameter("Filter.CharacteristicsObjectType", <giá trị enum>)`, gán vào `Items.CharacteristicType.ChoiceParameters` dưới dạng `FixedArray` (mảng rỗng = không lọc).
    - `ObjectOnChange` (`&AtClient`): so loại object mới với biến form `PreviousObjectType` (khai báo `Var` đầu module); nếu khác → xóa CharacteristicType và CharacteristicValue, gọi lại procedure đặt choice parameters, cập nhật biến.
    - Function ánh xạ `TypeOf(Record.Object)` → giá trị enum: xem mẫu ở mục Code demo của bài Theory (bản demo chỉ có catalogs của lý thuyết; bạn thêm nhánh cho các object của đề).
  - Bật Master giúp mở danh sách giá trị từ form của từng object (Go to).
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtServer
Function CharacteristicsObjectType()
	// TypeOfObject = TypeOf(Record.Object)
	// If TypeOfObject = Type("CatalogRef.___") Then Result = Enums.CharacteristicsObjectTypes.___
	// ElsIf ... (mỗi object của đề, kể cả 2 documents: Type("DocumentRef.___"))
	// Else Raise ___
	// Return Result
EndFunction
```
- **Lỗi hay gặp:**
  - Catalog additional values không có trong Characteristic value type → không chọn được làm "Additional characteristic values".
  - Không đặt Select type automatically → field giá trị luôn hỏi chọn kiểu.
  - Không có choice parameter link → chọn Color mà vẫn thấy giá trị của Size.
  - Hàm ánh xạ loại object chỉ có 5 catalogs → mở record form từ SalesInvoice/return rơi vào nhánh `Raise`. [ghi chú ngoài nguồn] Lời giải tham khảo của khóa cũng chỉ xử lý 5 catalogs — bạn cần bổ sung hai documents (và giá trị enumeration tương ứng).
  - Quên đưa chart, catalog values, register vào subsystem.
- **Tự kiểm tra:** Từ form của một product mở danh sách giá trị characteristics → tạo record: chỉ thấy characteristic types có CharacteristicsObjectType = Products; chọn type kiểu catalog values → chỉ thấy giá trị của type đó; thử tương tự từ một Sales invoice.

### Bài tập 4 — Characteristics như attributes thường; "Primary supplier" và filter trên list form Products
- **Đề bài (tóm tắt):** Thiết lập characteristics cho mọi object để dùng như attributes thường; với Products thêm additional attribute "Primary supplier" kiểu CatalogRef.Counterparties và hiển thị filter theo nó trên list form.
- **Gợi ý 1 — Hướng đi:** Cửa sổ **Additional metadata object characteristics** (mục cuối phần Charts of characteristic types) — phải làm cho **từng** object; sau đó characteristic xuất hiện như field trong dynamic list và report.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Mỗi object (5 catalogs + 2 documents): nút **Characteristics** → nguồn characteristic types = chart, **Key Field** = Ref, filter field = `CharacteristicsObjectType`, filter value = giá trị enumeration của object đó; nguồn giá trị = register `ObjectsCharacteristicValues` (Object / CharacteristicType / CharacteristicValue).
  - "Primary supplier": là **dữ liệu** — tạo ở Enterprise mode một characteristic type mới (loại Products, kiểu Counterparties), không phải attribute trong Designer.
  - List form Products: tạo list form (nếu chưa có), thêm field của characteristic vào khu vực filter/quick settings của dynamic list (hoặc user tự thêm qua Settings), hoặc thêm field filter trên form.
- **Gợi ý 3 — Khung bài làm:**
  1. Lặp thiết lập Characteristics cho từng object, đổi filter value tương ứng.
  2. Cập nhật database, vào Enterprise mode tạo characteristic "Primary supplier".
  3. Gán Primary supplier cho vài products.
  4. Mở list form Products → thêm filter theo Primary supplier.
- **Lỗi hay gặp:**
  - Chỉ thiết lập cho Products → các object khác không dùng được characteristics như attributes.
  - Sai filter value (copy từ object khác) → object thấy characteristics của loại khác.
  - Tạo "Primary supplier" thành attribute metadata của Products → đi ngược mục đích của chart.
- **Tự kiểm tra:** Trên list form Products lọc theo một supplier → chỉ còn products có Primary supplier đó; thêm cột Primary supplier vào danh sách qua More → Change form/Settings.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/13-theory)

So với nhánh lesson/12-theory, nhánh lesson/13-theory thêm: constants `DefaultCompany`, `DefaultBankAccount` và common form `DefaultValues`, handler `Filling` của SalesInvoice (đã có nguyên văn ở mục "Cú pháp & ví dụ code"), document journal `PurchasesAndSales`, chart of characteristic types `AdditionalAttributesAndProperties` và information register `ObjectsCharacteristicValues` với record form. Dưới đây là các phần chính của nhánh.

### Constants form "Default values": hai constants trên một common form
Nguồn: nhánh lesson/13-theory — cf/CommonForms/DefaultValues/Ext/Form.xml
```xml
	<ChildItems>
		<InputField name="DefaultCompany" id="1">
			<DataPath>ConstantsSet.DefaultCompany</DataPath>
			<EditMode>EnterOnInput</EditMode>
			<ContextMenu name="DefaultCompanyContextMenu" id="2"/>
			<ExtendedTooltip name="DefaultCompanyExtendedTooltip" id="3"/>
		</InputField>
		<InputField name="DefaultBankAccount" id="4">
			<DataPath>ConstantsSet.DefaultBankAccount</DataPath>
			<ContextMenu name="DefaultBankAccountContextMenu" id="5"/>
			<ExtendedTooltip name="DefaultBankAccountExtendedTooltip" id="6"/>
		</InputField>
	</ChildItems>
	<Attributes>
		<Attribute name="ConstantsSet" id="1">
			<Type>
				<v8:Type>cfg:ConstantsSet</v8:Type>
			</Type>
			<MainAttribute>true</MainAttribute>
			<SavedData>true</SavedData>
		</Attribute>
```
- Đúng ví dụ lý thuyết: gom "Default company" và "Default bank account" vào common form `DefaultValues` (main attribute kiểu `ConstantsSet`).
- Trong `DefaultCompany.xml` / `DefaultBankAccount.xml` của nhánh này, `UseStandardCommands` = false → form riêng của từng constant không hiện trong giao diện, user chỉ sửa qua form chung.

### Journal "Purchases and Sales": column Counterparty gộp Vendor và Customer
Nguồn: nhánh lesson/13-theory — cf/DocumentJournals/PurchasesAndSales.xml
```xml
			<Column uuid="9e21df68-5159-44ae-af51-4b0ea57516fe">
				<Properties>
					<Name>Counterparty</Name>
					<Synonym>
						<v8:item>
							<v8:lang>en</v8:lang>
							<v8:content>Counterparty</v8:content>
						</v8:item>
					</Synonym>
					<Comment/>
					<Indexing>DontIndex</Indexing>
					<References>
						<xr:Item xsi:type="xr:MDObjectRef">Document.PurchaseInvoice.Attribute.Vendor</xr:Item>
						<xr:Item xsi:type="xr:MDObjectRef">Document.SalesInvoice.Attribute.Customer</xr:Item>
						<xr:Item xsi:type="xr:MDObjectRef">Document.ReturnOfGoodsFromCustomer.Attribute.Customer</xr:Item>
					</References>
				</Properties>
			</Column>
```
- Đây chính là ví dụ trong lý thuyết: attribute `Vendor` của Purchase invoice và `Customer` của Sales invoice (và Return of goods from customer) hiển thị trong cùng một column "Counterparty".
- Mỗi document góp đúng một attribute vào column; các cột date, number, document type là mặc định, không cần khai báo.

### Resource CharacteristicValue: Select type automatically + choice parameter link
Nguồn: nhánh lesson/13-theory — cf/InformationRegisters/ObjectsCharacteristicValues.xml
```xml
					<ChoiceParameterLinks>
						<xr:Link>
							<xr:Name>Filter.Owner</xr:Name>
							<xr:DataPath xsi:type="xs:string">InformationRegister.ObjectsCharacteristicValues.Dimension.CharacteristicType</xr:DataPath>
							<xr:ValueChange>Clear</xr:ValueChange>
						</xr:Link>
					</ChoiceParameterLinks>
					<ChoiceParameters/>
					<QuickChoice>Auto</QuickChoice>
					<CreateOnInput>Auto</CreateOnInput>
					<ChoiceForm/>
					<LinkByType>
						<xr:DataPath>InformationRegister.ObjectsCharacteristicValues.Dimension.CharacteristicType</xr:DataPath>
						<xr:LinkItem>0</xr:LinkItem>
					</LinkByType>
```
- `LinkByType` → DataPath tới dimension `CharacteristicType` = property **Select type automatically** = "Characteristic type": kiểu của field giá trị đi theo characteristic type đã chọn, không còn nút chọn kiểu.
- `ChoiceParameterLinks` với `Filter.Owner` = `CharacteristicType` → danh sách additional values chỉ gồm các giá trị thuộc characteristic type đó (không hiện "48-50" của Size khi chọn Color); `ValueChange` = `Clear` xóa giá trị khi đổi type.
- Hai dimensions `Object` và `CharacteristicType` trong cùng file đều có `Master` = true và `DenyIncompleteValues` = true (flag **No empty values**).

### Ánh xạ loại object sang CharacteristicsObjectTypes (bản demo của lý thuyết)
Nguồn: nhánh lesson/13-theory — cf/InformationRegisters/ObjectsCharacteristicValues/Forms/RecordForm/Ext/Form/Module.bsl
```bsl
&AtServer
Function CharacteristicsObjectType()

	TypeOfObject = TypeOf(Record.Object);
	
	If TypeOfObject = Type("CatalogRef.Companies") Then
		Result = Enums.CharacteristicsObjectTypes.Companies;
	ElsIf TypeOfObject = Type("CatalogRef.Counterparties") Then
		Result = Enums.CharacteristicsObjectTypes.Counterparties;
	ElsIf TypeOfObject = Type("CatalogRef.Employees") Then
		Result = Enums.CharacteristicsObjectTypes.Employees;
	ElsIf TypeOfObject = Type("CatalogRef.Products") Then
		Result = Enums.CharacteristicsObjectTypes.Products;
	ElsIf TypeOfObject = Type("CatalogRef.Warehouses") Then
		Result = Enums.CharacteristicsObjectTypes.Warehouses;
	Else
		Raise "Unexpected type of object: " + TypeOfObject;
	EndIf;

	Return Result;
	
EndFunction
```
- Function này nằm trong record form của register; cùng module còn có `OnCreateAtServer` (ẩn field Object khi đã điền), `ObjectOnChange` (so với biến `PreviousObjectType`, xóa CharacteristicType/CharacteristicValue khi loại object đổi) và `SetChoiceParametersForCharacteristicType` (đặt choice parameter `Filter.CharacteristicsObjectType`) — đúng các bước mô tả ở mục Charts of characteristic types; tự viết các procedure đó theo Thẻ gợi ý bài thực hành, Bài tập 3.
- Bản demo xử lý đúng 5 giá trị enumeration của lý thuyết (Companies, Counterparties, **Employees**, Products, Warehouses). [ghi chú ngoài nguồn] Danh sách object của 13. Practice khác (có CounterpartyContracts và hai documents, không có Employees) → phải sửa cả enumeration lẫn function này.

## Video tham khảo (khóa Junior cũ)

Video trong playlist "Junior Developer Course" (1C Vietnam Academy, khóa cũ) có phạm vi trùng với bài này. Gọi là "video JC-<số>" (số bài của khóa cũ, khác số bài giáo trình); quy ước dẫn và độ tin cậy: `references/video-junior-course.md`.

- [JC-16 «Hằng số (Constant)»](https://www.youtube.com/watch?v=0Ru2FzltA4k&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=15) (7:28) — Bài 13 — Constants
- [JC-21 «Dữ liệu xác định trước»](https://www.youtube.com/watch?v=EQLuZq69Nmw&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=20) (8:02) — Bài 4 — Predefined data; Bài 13 / 24 — predefined của Chart of characteristic types, Chart of accounts
