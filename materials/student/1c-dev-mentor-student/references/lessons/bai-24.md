# Bài 24 — Accounting (Kế toán trên nền tảng 1C)

## Khái niệm chính

### Các loại metadata then chốt
- Bài không giảng lý thuyết kế toán; giả định học viên đã biết khái niệm cơ bản.
- **Chart of accounts**: mô tả mọi tài khoản dùng ghi nhận hoạt động (ví dụ Materials, Cash).
- **Accounting register**: thông tin các nghiệp vụ theo tài khoản và totals của tài khoản.
- **Chart of characteristic types**: mô tả đối tượng phân tích (extra dimensions) mà kế toán theo dõi trên tài khoản (ví dụ theo từng material).

### Tạo Chart of accounts
- Tạo subsystem "Accounting", chart of accounts "ChartOfAccounts".
- Functional option **"UseAccounting"**, đưa các object đã tạo (và sẽ tạo) vào **Content**.
- Tab **Data**: code length 10, name length 100, bật **"Autoorder by code"** (sắp xếp mặc định theo code).
- Theo dõi cả số lượng: thêm giá trị vào nhánh **"accounting flags"** — flag **"Quantitative"**, kiểu Boolean mặc định.

### Extra dimension types / Extra dimension
- **"Extra dimension types"**: các phân đoạn phân tích; mỗi tài khoản có thể theo dõi theo nhiều extra dimension types.
- **"Extra dimension"**: đối tượng phân tích cụ thể.
- Ví dụ: tài khoản "Goods" theo dõi theo products và warehouses (extra dimension types); sản phẩm "Dark chocolate 100g" và kho "Main" trong một record là extra dimensions.
- Chart of characteristic types được dùng để mô tả extra dimension types và kiểu giá trị extra dimension có thể nhận.
- Tạo chart of characteristic types **"ExtraDimensionTypes"**, đưa vào subsystem "Accounting", characteristic value types = references tới catalogs và documents.
- Trong chart of accounts (tab **"Extra dimension"**): property **"Extra dimension types"** = ExtraDimensionTypes; **"Maximum extra dimensions"** = 3.
- Danh sách extra dimension cho configuration → tạo **predefined values** trong ExtraDimensionTypes. Tương tự tạo predefined accounts.

### Accounting register
- Tạo "GeneralJournal", đưa vào subsystem "Accounting". Property **"Chart of accounts"** = chart đã tạo; bật flag **"Correspondence"** để record chứa debit và credit. Không bật → không hỗ trợ "double entry", record giống accumulation register (một cho debit + một cho credit).
- Không có dimensions; resources: **Amount** và **Quantity**. Với Quantity chỉ định accounting flag **"Quantitative"** để chỉ điền được cho tài khoản có quantitative accounting.
- Flag **"Balance"** của resource (mặc định bật): platform kiểm tra resource value ở bên debit và credit bằng nhau khi ghi. Giữ cho Amount (không thể tạo record Dr 100 / Cr 80). Tắt cho Quantity (không phải mọi tài khoản đều theo dõi số lượng — ví dụ "Goods" có, "Settlements with suppliers" không).
- Recorders: documents "PurchaseInvoice", "SalesInvoice", "ReturnOfGoodsFromCustomer"; sửa handler posting.
- Resource có accounting flag phải ghi tên với postfix **Dr** (debit) hoặc **Cr** (credit). Extra dimensions ghi dạng `ExtDimensionsDr(/ExtDimensionsCr)[RefToExtraDimensionType] = ExtraDimensionValue`.
- Gán manager của chart of characteristic types ExtraDimensionTypes vào biến chỉ để dòng code ngắn hơn, không bắt buộc.
- Record: tài khoản hiển thị chỉ bằng số, extra dimensions được điền, quantity điền cho tài khoản quantitative.
- List form nhiều cột; standard solutions thường tự tổ chức nhóm giá trị debit/credit theo chiều dọc (AccountDr / Extra dimension 1 Dr / 2 Dr / 3 Dr).

### Presentation tài khoản
- Muốn hiển thị `<AccountCode + AccountDescription>`: handler **PresentationGetProcessing** trong **manager module** của Chart of accounts. Sự kiện xảy ra khi platform lấy presentation của object (hiển thị trong document form, register list form...).
- 3 parameter: **Data**, **Presentation**, **StandardProcessing** — phải tắt standard processing để thuật toán riêng chạy.
- **Data** chứa link tới object và field là default presentation field trên tab "Data" (ở đây Code).
- **Presentation** là presentation cuối cùng user thấy.
- Truy cập attribute khác: có thể đọc từ object theo reference, nhưng nếu không cần query phức tạp thì khuyến nghị dùng handler **PresentationFieldsGetProcessing** để chỉ định attributes sẽ được lấy và truyền vào parameter "Data" của PresentationGetProcessing (ví dụ thêm property "Description"), rồi nối code và description vào Presentation.

### Report "Trial balance"
- Report mới đưa vào subsystem "Accounting", tạo main data composition schema, data set loại "Query", mở query console, nhánh **"AccountingRegisters"**.
- Các bảng mới:
  - **ExtDimensions**: bảng **physical**, lưu giá trị extra dimension cho records (bảng chính không lưu extra dimension cho từng record).
  - **RecordsWithExtDimensions**: bảng **virtual**, kết hợp hai bảng thật (bảng chính + "ExtDimensions"): thông tin nghiệp vụ theo tài khoản kèm extra dimension.
  - **DrCrTurnovers**: bảng **virtual**, lấy turnover giữa các tài khoản đối ứng. Chỉ có trong register hỗ trợ correspondence (flag "correspondence" bật). Khác "Turnover": phân tích turnover giữa các tài khoản khi đã biết tài khoản nào ghi nợ, tài khoản nào ghi có.
- Cần cả balance và turnover → chọn từ virtual table **BalanceAndTurnovers**: có thêm field **<Resource>Dr** và **<Resource>Cr** cho mọi resource, cùng **<Resource>OpeningSplittedBalanceDr / <Resource>OpeningSplittedBalanceCr** (cho <Resource>OpeningBalance) và **<Resource>ClosingSplittedBalanceDr / <Resource>ClosingSplittedBalanceCr** (cho <Resource>ClosingBalance). Field splitted balance chỉ dùng cho query có totals.
- Chọn field: account, balance và turnover amount theo debit/credit; nhóm field thành OpeningBalance, Turnover, ClosingBalance; chỉ định resources; tạo parameter **Period** kiểu **StandardPeriod**; grouping "Account"; chọn mọi resource vào selected fields.
- Sửa lỗi hiển thị:
  - Header cột lặp (Opening Balance và Opening Balance.Dr): tab **"Other settings"** → property **"Field header type"** = **"Brief"**.
  - Totals closing balance bằng 0: trên tab **"Data sets"** các balance field tự nhận **accounting roles** → tính theo quy tắc kế toán, không phù hợp report này → xóa roles của resource field.

### Document "General journal entry" (nhập bút toán thủ công)
- User có quyền cao (ví dụ kế toán trưởng) thường được nhập bút toán trực tiếp vào general journal (accounting register).
- Document chỉ đóng vai trò recorder (accumulation và accounting registers không sửa trực tiếp được nếu không có recorder), không lưu dữ liệu trong document.
- Đưa vào subsystem "Accounting" và functional option "Use accounting". **Tắt posting** của document (không phản ánh nghiệp vụ thực, không cần sự kiện "Post").
- Chỉ định document làm recorder của accounting register, tạo document form, thêm bảng register records lên form, gộp cột thành group.
- Cho phép chọn period cho từng record (một document có thể có record nhiều kỳ). Muốn period = ngày document: ẩn cột Period, điền Period cho từng record của record set trước khi ghi document.
- Tắt posting → cũng tắt tự động xóa record trong register phụ thuộc (property **"Delete records"** trên tab **"Posting"**) → document có deletion mark vẫn còn record và ảnh hưởng totals.
- Xóa record set thì document trở nên vô dụng (user mở thấy bảng rỗng).
- **Activity**: record của mọi register có property Activity. Activity = False → record bị loại khi tính totals (vẫn lưu trong bảng physical).
- Deletion mark có thể đặt/bỏ từ document form, list form hoặc bằng code; khi đó record set lấy từ property **RegisterRecords** có thể rỗng (vì Posting tắt) → phải làm việc trực tiếp với register record set: tạo set mới, đặt filter theo recorder và đọc records.
- List form tự sinh của accounting register không hiện field Activity nhưng dùng hình đầu dòng: active → màu, inactive → đen trắng. Bài tạo list form riêng để user lọc theo active/inactive và gộp cột gọn hơn.

## Cú pháp & ví dụ code

Ví dụ record vi phạm "Balance" (credit nhỏ hơn debit):
```bsl
AccountDr    Amount    AccountCr                            Amount
"Goods"          100      "Settlements with suppliers"      80
```

Cú pháp extra dimensions trong record:
```bsl
ExtDimensionsDr(/ExtDimensionsCr)[RefToExtraDimensionType] = ExtraDimensionValue
```

Chữ ký handler (manager module của Chart of accounts):
```bsl
PresentationGetProcessing(Data, Presentation, StandardProcessing)
```

[ghi chú ngoài nguồn] Code posting các document, PresentationGetProcessing, PresentationFieldsGetProcessing, điền Period trước khi ghi và xử lý Activity khi đặt deletion mark trong tài liệu gốc là ảnh chụp màn hình, không có văn bản để chép nguyên văn. → đã bổ sung (nhánh lesson/24-theory).

## Thuộc tính/thiết lập quan trọng trong Designer
- Chart of accounts: tab **Data** (code length, name length, **Autoorder by code**, default presentation field); nhánh **accounting flags** (flag **Quantitative**); tab **Extra dimension** (**Extra dimension types**, **Maximum extra dimensions**); predefined accounts.
- Chart of characteristic types **ExtraDimensionTypes**: characteristic value types, predefined values.
- Accounting register: **Chart of accounts**, **Correspondence**; resources **Amount**, **Quantity** (accounting flag Quantitative); flag **Balance**; recorders.
- Functional option **UseAccounting** → **Content**.
- DCS: data set "Query"; parameter **Period** (StandardPeriod); tab **Other settings** → **Field header type** = "Brief"; tab **Data sets** → accounting roles.
- Document: posting (tắt), tab **Posting** → **Delete records**.
- Register record: **Activity**.

## Lỗi thường gặp / lưu ý
- Không bật "Correspondence" → register không có double entry.
- Để flag "Balance" bật cho Quantity → lỗi vì không mọi tài khoản theo dõi số lượng; tắt cho Quantity, giữ cho Amount.
- Quên postfix Dr/Cr cho resource có accounting flag.
- Header cột lặp trong report → Field header type = "Brief".
- Totals closing balance = 0 do accounting roles tự gán cho balance fields → xóa roles.
- Document tắt posting → không tự xóa record khi đặt deletion mark → dùng Activity.
- RegisterRecords có thể rỗng khi đặt deletion mark từ list form/code → tạo record set mới, filter theo recorder, đọc records.
- Tránh đọc lại object trong PresentationGetProcessing; dùng PresentationFieldsGetProcessing.

## Điểm cần nhớ
- Ba metadata kế toán: Chart of accounts, Accounting register, Chart of characteristic types.
- Extra dimension types (phân đoạn) vs Extra dimension (đối tượng cụ thể); ExtraDimensionTypes gắn vào chart of accounts, Maximum extra dimensions.
- Accounting flag "Quantitative" + resource Quantity; flag Balance chỉ giữ cho Amount.
- Correspondence = double entry; resource dùng postfix Dr/Cr; ExtDimensionsDr/ExtDimensionsCr[...].
- PresentationGetProcessing + PresentationFieldsGetProcessing để hiển thị "Code + Description".
- Bảng mới: ExtDimensions (physical), RecordsWithExtDimensions, DrCrTurnovers (virtual); report dùng BalanceAndTurnovers.
- Document nhập tay: tắt posting, làm recorder; dùng Activity = False để loại record khỏi totals khi đánh dấu xóa.

## Thẻ gợi ý bài thực hành (Practice 24)

Các thẻ dưới đây đi theo thứ tự đề trong 24. Practice, làm trên configuration của bạn (các document PurchaseInvoice, SalesInvoice, ReturnOfGoodsFromCustomer, InventoryTransfer). Mỗi thẻ chỉ có gợi ý, không có lời giải. Code demo trong mục theory demo bên dưới chỉ minh họa cú pháp. Bạn phải tự viết posting cho document của mình, kể cả document chuyển kho mà demo không có.

### Bài tập 1 — Cơ chế kế toán: chart of accounts, extra dimensions, accounting register

- **Đề bài (tóm tắt):** Kế toán theo bút toán kép Dr/Cr, có analytics (extra dimension) cho tài khoản.
- **Gợi ý 1 — Hướng đi:** Ba metadata trong mục "Các loại metadata then chốt": Chart of characteristic types mô tả loại extra dimension, Chart of accounts dùng nó, Accounting register có Correspondence để mỗi record có cả Dr lẫn Cr.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Chart of characteristic types `ExtraDimensionTypes`: value types là catalog refs (Products, Warehouses, Counterparties...).
  - Chart of accounts: tab Data (code length, Autoorder by code), accounting flag **Quantitative**, tab Extra dimension (`Extra dimension types` = ExtraDimensionTypes, `Maximum extra dimensions`).
  - Accounting register `GeneralJournal`: `Chart of accounts`, flag **Correspondence**, resources `Amount` (Balance bật) và `Quantity` (accounting flag Quantitative, Balance **tắt**).
  - Subsystem "Accounting" chứa các object này.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo ExtraDimensionTypes, khai báo type, tạo predefined values cho từng loại analytics cần dùng.
  2. Tạo chart of accounts, gắn ExtraDimensionTypes, thêm flag Quantitative.
  3. Tạo accounting register, bật Correspondence, tạo 2 resource như trên.
  4. Đưa tất cả vào subsystem Accounting.
- **Lỗi hay gặp:**
  - Quên Correspondence → register không có double entry (record tách Dr và Cr riêng).
  - Để Balance bật cho Quantity → lỗi khi ghi bút toán giữa tài khoản có và không có số lượng.
  - Maximum extra dimensions nhỏ hơn số analytics của tài khoản Goods (cần ít nhất 2).
- **Tự kiểm tra:** Mở chart of accounts trong Enterprise mode. Tab extra dimensions của một tài khoản cho chọn đúng các loại analytics.

### Bài tập 2 — Cho user bật/tắt kế toán

- **Đề bài (tóm tắt):** User bật/tắt được tính năng kế toán. Khi tắt thì không thấy object nào liên quan.
- **Gợi ý 1 — Hướng đi:** Functional option lưu trong Boolean constant (xem bài 15 và mục "Tạo Chart of accounts"). Object trong Content bị ẩn khỏi interface khi option tắt.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Constant Boolean (ví dụ `UseAccounting`), functional option `UseAccounting` với Location = constant đó. Content: chart of accounts, accounting register, ExtraDimensionTypes, subsystem Accounting, report Trial balance, document nhập bút toán tay. Đưa constant lên form cài đặt của ứng dụng.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo constant và functional option, đặt Location.
  2. Thêm mọi object kế toán (kể cả object tạo ở bài 5, 6) vào Content.
  3. Cho user sửa constant trên form settings (có refresh interface như bài 15).
- **Lỗi hay gặp:**
  - Tạo report/document mới ở bài sau mà quên thêm vào Content.
  - Role của user thường không có Read trên constant → interface sai. Có thể bật "Privileged get mode" cho option.
- **Tự kiểm tra:** Tắt option → section Accounting và mọi object kế toán biến mất. Bật lại → xuất hiện.

### Bài tập 3 — Tài khoản 01 Goods, 02 Trade payables, 03 Trade receivables

- **Đề bài (tóm tắt):** Goods theo dõi theo product + warehouse và có số lượng. Trade payables và Trade receivables theo dõi theo counterparty.
- **Gợi ý 1 — Hướng đi:** Tài khoản là **predefined** của chart of accounts. Analytics của từng tài khoản đặt ở tab extra dimensions của tài khoản. Số lượng bật bằng accounting flag Quantitative (cho tài khoản và cho từng extra dimension nếu cần).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Chart of accounts → Predefined: code `01`, `02`, `03`, Name tiếng Anh không dấu cách (dùng trong code dạng `ChartsOfAccounts.<Tên chart>.<Name>`). Mỗi tài khoản: flag Quantitative (chỉ 01), danh sách extra dimension types.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo 3 predefined accounts với code và description.
  2. 01: thêm extra dimensions Product, Warehouse, bật Quantitative.
  3. 02, 03: thêm extra dimension Counterparty.
  4. (Tùy chọn) handler presentation để tài khoản hiện "Code Description" (xem mục "Presentation tài khoản").
- **Lỗi hay gặp:**
  - Bật Quantitative cho 02/03 → phải ghi số lượng cho tài khoản công nợ.
  - Thứ tự extra dimension khác nhau giữa các tài khoản mà code lại truy cập theo chỉ số thay vì theo predefined type.
- **Tự kiểm tra:** Danh sách chart of accounts hiện 01, 02, 03 theo thứ tự code. Mở tài khoản 01 thấy 2 extra dimension và cờ số lượng.

### Bài tập 4 — Bút toán khi mua, bán, trả hàng, chuyển kho

- **Đề bài (tóm tắt):** Mua: Dr Goods – Cr Trade payables. Bán: Dr Trade receivables – Cr Goods. Trả hàng: như bán nhưng quantity và amount âm. Chuyển kho: Dr Goods – Cr Goods, chỉ khác extra dimension Warehouse.
- **Gợi ý 1 — Hướng đi:** Thêm accounting register vào **Register records** của 4 document, rồi trong `Posting` ghi thêm record vào `RegisterRecords.<AccountingRegister>` cạnh các record accumulation hiện có. Cú pháp: mục "Accounting register" (postfix Dr/Cr cho resource có accounting flag, `ExtDimensionsDr[...]`/`ExtDimensionsCr[...]`).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Object module của từng document, procedure `Posting(Cancel, PostingMode)` (server).
  - Record: `Period`, `AccountDr`, `AccountCr`, `Amount` (một property vì Balance bật), `QuantityDr` hoặc `QuantityCr` (bên nào là tài khoản Goods), extra dimensions theo predefined của ExtraDimensionTypes.
  - Counterparty: mua thì lấy nhà cung cấp, bán/trả thì lấy khách hàng của document.
  - Đặt `Write = True` cho record set kế toán.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm accounting register vào Register records của 4 document.
  2. Mua hàng: mỗi dòng Products → một bút toán, quantity bên Dr.
  3. Bán hàng: mỗi dòng Products → một bút toán, quantity bên Cr.
  4. Trả hàng: như bán, amount và quantity mang dấu âm (không đảo Dr/Cr).
  5. Chuyển kho: cả hai bên là Goods, quantity cả Dr và Cr, Warehouse Dr = kho nhận, Warehouse Cr = kho gửi. Amount lấy theo giá vốn đã tính cho accumulation register.
  ```bsl
  // trong Posting, bên trong vòng lặp dòng hàng
  NewRecord = RegisterRecords.___.Add();
  NewRecord.Period    = ___;
  NewRecord.AccountDr = ___;   // predefined account
  NewRecord.AccountCr = ___;
  // Amount, QuantityDr/QuantityCr, ExtDimensionsDr[...] / ExtDimensionsCr[...]
  ___
  ```
- **Lỗi hay gặp:**
  - Ghi `Quantity` không postfix → lỗi, vì resource có accounting flag.
  - Trả hàng mà đảo Dr/Cr thay vì dấu âm → turnover bị phồng cả hai bên (đề yêu cầu số âm).
  - Dòng Services: dịch vụ không phải hàng tồn kho. [ghi chú ngoài nguồn] Demo của bài không tạo bút toán Cr Goods cho Services. Đề không nói rõ, hãy quyết định và ghi lý do.
  - Quên thêm register vào Register records → record không được ghi khi post.
- **Tự kiểm tra:** Post từng loại document, mở list accounting register: đúng cặp tài khoản, extra dimension, số lượng chỉ ở bên Goods. Unpost thì record biến mất.

### Bài tập 5 — Report Trial Balance

- **Đề bài (tóm tắt):** Report hiện số dư đầu kỳ, phát sinh trong kỳ, số dư cuối kỳ theo tài khoản, tách riêng Dr và Cr.
- **Gợi ý 1 — Hướng đi:** Xem mục "Report Trial balance": DCS với data set Query trên virtual table **BalanceAndTurnovers** của accounting register, có sẵn field tách Dr/Cr.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Report mới, main data composition schema. Query console nhánh AccountingRegisters. Parameter `Period` kiểu StandardPeriod. Grouping theo Account. Resources. Tab Other settings → Field header type = "Brief". Tab Data sets → xóa accounting roles của resource field.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo report, schema, data set Query, chọn field Account và 6 field amount opening/turnover/closing Dr/Cr.
  2. Gom field thành nhóm OpeningBalance / Turnover / ClosingBalance, khai báo resources.
  3. Tạo parameter Period, truyền ngày đầu/cuối vào virtual table.
  4. Settings: grouping Account, selected fields là các resource.
  5. Sửa header lặp và totals cuối kỳ như lý thuyết.
- **Lỗi hay gặp:**
  - Totals closing balance bằng 0 vì accounting roles tự gán → xóa roles.
  - Header cột lặp "Opening Balance.Dr" → Field header type = Brief.
  - Dùng field splitted balance trong query không có totals.
- **Tự kiểm tra:** Sau khi post mua rồi bán: tổng phát sinh Dr = tổng phát sinh Cr. Số dư cuối kỳ của 01 khớp hàng còn lại theo giá trị.

### Bài tập 6 — Document nhập bút toán tay, không posting, xử lý deletion mark

- **Đề bài (tóm tắt):** Document cho phép nhập bút toán tùy ý vào accounting register, không có thuộc tính posting. Khi đánh dấu xóa, record không ảnh hưởng totals nhưng vẫn được giữ để user sửa tiếp hoặc bỏ đánh dấu.
- **Gợi ý 1 — Hướng đi:** Xem mục "Document General journal entry". Document chỉ là recorder, tắt Posting. Record nhập trực tiếp trên form qua bảng register records. Khi deletion mark đổi, đổi **Activity** của record (Activity = False → không tính vào totals) thay vì xóa.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Document mới: Posting = Deny, là recorder của accounting register, đưa vào subsystem và functional option.
  - Form: bảng register records của document, ẩn cột Period.
  - Object module, event **BeforeWrite** (server): gán Period = ngày document cho mọi record. Phát hiện deletion mark thay đổi so với giá trị trong DB.
  - Khi đổi Activity: **không** dựa vào `RegisterRecords` (có thể rỗng khi đánh dấu từ list form). Tạo record set mới qua manager của register, filter theo recorder, đọc, đổi Active, ghi.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo document, tắt posting, thêm làm recorder.
  2. Tạo form, thêm bảng register records, gộp cột, ẩn Period.
  3. BeforeWrite: gán Period cho các record; gọi procedure đổi activity.
  4. Procedure đổi activity: thoát nếu object mới hoặc deletion mark không đổi; ngược lại đọc record set theo recorder và đổi Active.
  ```bsl
  Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
  	// gán Period = Date cho từng record; rồi gọi procedure xử lý Activity
  	___
  EndProcedure

  Procedure ___()
  	// thoát sớm: object mới, hoặc DeletionMark không đổi so với giá trị trong DB
  	___
  	// record set mới -> filter theo recorder -> Read -> đổi Active -> ghi đè
  	___
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Tắt posting nhưng tưởng record tự xóa khi đánh dấu xóa (không xóa: "Delete records" phụ thuộc posting).
  - Xóa record set khi đánh dấu xóa → bỏ đánh dấu thì document trống, trái yêu cầu.
  - Dùng `RegisterRecords` để đổi Active → không chạy khi đánh dấu từ list form.
  - So sánh deletion mark với chính nó thay vì với giá trị đã lưu (`Ref.<...>`).
- **Tự kiểm tra:** Nhập bút toán, lưu, xem Trial balance. Đánh dấu xóa từ **list form** → report không còn số đó, record vẫn còn (hình đen trắng trong list register). Bỏ đánh dấu → số trở lại.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/24-theory)

Nhánh lesson/24-theory là trạng thái cấu hình khi quay demo bài 24: so với cấu hình của bài 20 có thêm ChartsOfAccounts/ChartOfAccounts, AccountingRegisters/GeneralJournal, ChartsOfCharacteristicTypes/ExtraDimensionTypes, Documents/GeneralJournalEntry, Reports/TrialBalance và functional option UseAccounting. Mọi mẫu dưới đây lấy từ nhánh theory.

### Hiển thị tài khoản dạng "Code Description" (PresentationFieldsGetProcessing + PresentationGetProcessing)
Nguồn: nhánh lesson/24-theory — cf/ChartsOfAccounts/ChartOfAccounts/Ext/ManagerModule.bsl
```bsl
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Code");
	Fields.Add("Description");
	Fields.Add("Ref");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = StrTemplate("%1 %2", Data.Code, Data.Description);
	
EndProcedure
```
- Cả hai handler đặt trong manager module của Chart of accounts, đều gán `StandardProcessing = False` để thuật toán riêng chạy.
- `PresentationFieldsGetProcessing` khai báo các field cần đọc ("Code", "Description", "Ref"); platform truyền đúng các field này vào parameter `Data` của `PresentationGetProcessing`, không phải đọc lại object theo reference.
- `StrTemplate("%1 %2", ...)` ghép code và description thành presentation user thấy trong document form và list form của register.

### Posting của PurchaseInvoice: bút toán Dr Products / Cr TradePayables
Nguồn: nhánh lesson/24-theory — cf/Documents/PurchaseInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, PostingMode)
// ...
	GoodsInWarehouses = RegisterRecords.GoodsInWarehouses;
	GoodsInWarehouses.Write = True;
	
	GeneralJournal = RegisterRecords.GeneralJournal;
	GeneralJournal.Write = True;
	
	ExtraDimensionTypes = ChartsOfCharacteristicTypes.ExtraDimensionTypes;
	
	For Each ProductsRow In Products Do
	
		NewRecord = GoodsInWarehouses.AddReceipt();
		NewRecord.Period 	= Date;
		NewRecord.Warehouse = Warehouse;
		NewRecord.Product 	= ProductsRow.Product;
		NewRecord.Quantity 	= ProductsRow.Quantity;
		NewRecord.Amount 	= ProductsRow.Amount;
		
		NewRecord = GeneralJournal.Add();
		NewRecord.Period 	 = Date;
		NewRecord.AccountDr  = ChartsOfAccounts.ChartOfAccounts.Products;
		NewRecord.AccountCr  = ChartsOfAccounts.ChartOfAccounts.TradePayables;
		NewRecord.Amount 	 = ProductsRow.Amount;
		NewRecord.QuantityDr = ProductsRow.Quantity;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Product]   	= ProductsRow.Product;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Warehouse] 	= Warehouse;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Counterparty] = Vendor;
		
	EndDo;
	
EndProcedure
```
- Cùng một vòng lặp ghi cả record của accumulation register GoodsInWarehouses và record của accounting register GeneralJournal; cả hai record set đều bật `Write = True`.
- Resource Quantity có accounting flag Quantitative nên ghi với postfix: `QuantityDr` (tài khoản Products bên debit có theo dõi số lượng). Amount có flag Balance nên chỉ một property `Amount` cho cả hai bên.
- Extra dimensions gán qua `ExtDimensionsDr[...]` / `ExtDimensionsCr[...]` với key là predefined value của chart of characteristic types ExtraDimensionTypes; biến `ExtraDimensionTypes` chỉ để dòng code ngắn hơn.
- Tài khoản lấy từ predefined accounts: `ChartsOfAccounts.ChartOfAccounts.Products`, `ChartsOfAccounts.ChartOfAccounts.TradePayables`.

### Posting của SalesInvoice: bút toán Dr TradeReceivables / Cr Products
Nguồn: nhánh lesson/24-theory — cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
Procedure Posting(Cancel, PostingMode)

	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	RegisterRecords.GeneralJournal.Write = True;

	ExtraDimensionTypes = ChartsOfCharacteristicTypes.ExtraDimensionTypes;
// ...
		NewRecord = RegisterRecords.GeneralJournal.Add();
		NewRecord.Period 	 = Date;
		NewRecord.AccountDr  = ChartsOfAccounts.ChartOfAccounts.TradeReceivables;
		NewRecord.AccountCr  = ChartsOfAccounts.ChartOfAccounts.Products;
		NewRecord.Amount 	 = CurRowProducts.Amount;
		NewRecord.QuantityCr = CurRowProducts.Quantity;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Counterparty] = Customer;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Product]   	= CurRowProducts.Product;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Warehouse] 	= Warehouse;
	EndDo;
// ...
EndProcedure
```
- Bên credit là tài khoản quantitative nên số lượng ghi vào `QuantityCr`; extra dimension Counterparty bên debit, Product và Warehouse bên credit.
- Trong demo, vòng lặp Services chỉ ghi register Sales, không tạo bút toán (dịch vụ không phải hàng tồn kho) — xem thêm thẻ gợi ý Bài tập 4.

### Posting của ReturnOfGoodsFromCustomer: bút toán đảo dấu
Nguồn: nhánh lesson/24-theory — cf/Documents/ReturnOfGoodsFromCustomer/Ext/ObjectModule.bsl
```bsl
		NewRecord = RegisterRecords.GeneralJournal.Add();
		NewRecord.Period 	 = Date;
		NewRecord.AccountDr  = ChartsOfAccounts.ChartOfAccounts.TradeReceivables;
		NewRecord.AccountCr  = ChartsOfAccounts.ChartOfAccounts.Products;
		NewRecord.Amount 	 = - CurRowProducts.Amount;
		NewRecord.QuantityCr = - CurRowProducts.Quantity;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Counterparty] = Customer;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Product]   	= CurRowProducts.Product;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Warehouse] 	= Warehouse;
	EndDo;
```
- Trả hàng dùng cùng cặp tài khoản với bán hàng nhưng Amount và QuantityCr âm (bút toán "đỏ"), thay vì đảo Dr/Cr.
- Nhờ vậy turnover của tài khoản trong report Trial balance giảm đúng chiều bán hàng, không làm phồng cả hai bên debit và credit.

### Document GeneralJournalEntry: điền Period và đổi Activity khi đặt deletion mark
Nguồn: nhánh lesson/24-theory — cf/Documents/GeneralJournalEntry/Ext/ObjectModule.bsl
```bsl
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	For Each Record In RegisterRecords.GeneralJournal Do
		Record.Period = Date;
	EndDo;
	
	ChangeRecordsActivity();
	
EndProcedure

Procedure ChangeRecordsActivity()

	If IsNew() Or DeletionMark = Ref.DeletionMark Then
		Return;
	EndIf;
	
	GeneralJournalRecords = AccountingRegisters.GeneralJournal.CreateRecordSet();
	
	GeneralJournalRecords.Filter.Recorder.Set(Ref);
	GeneralJournalRecords.Read();
	
	For Each Record In GeneralJournalRecords Do
		Record.Active = Not DeletionMark;
	EndDo;
	
	GeneralJournalRecords.Write(True);
	
EndProcedure
```
- Document tắt Posting nên dùng `BeforeWrite`: gán `Record.Period = Date` cho mọi record trong `RegisterRecords.GeneralJournal` (cột Period đã ẩn trên form).
- `ChangeRecordsActivity` thoát sớm nếu document mới hoặc deletion mark không đổi (`DeletionMark = Ref.DeletionMark` so giá trị trong object với giá trị đang lưu trong DB).
- Không dùng `RegisterRecords` vì khi đặt deletion mark từ list form record set này có thể rỗng: tạo record set mới bằng `AccountingRegisters.GeneralJournal.CreateRecordSet()`, đặt `Filter.Recorder` rồi `Read()`.
- `Record.Active = Not DeletionMark` loại record khỏi totals khi document bị đánh dấu xóa; `Write(True)` ghi đè record set.

### Query của report TrialBalance (virtual table BalanceAndTurnovers)
Nguồn: nhánh lesson/24-theory — cf/Reports/TrialBalance/Templates/MainDataCompositionSchema/Ext/Template.xml
```xml
		<query>SELECT
	GeneralJournalBalanceAndTurnovers.Account AS Account,
	GeneralJournalBalanceAndTurnovers.AmountOpeningBalanceDr AS AmountOpeningBalanceDr,
	GeneralJournalBalanceAndTurnovers.AmountOpeningBalanceCr AS AmountOpeningBalanceCr,
	GeneralJournalBalanceAndTurnovers.AmountTurnoverDr AS AmountTurnoverDr,
	GeneralJournalBalanceAndTurnovers.AmountTurnoverCr AS AmountTurnoverCr,
	GeneralJournalBalanceAndTurnovers.AmountClosingBalanceDr AS AmountClosingBalanceDr,
	GeneralJournalBalanceAndTurnovers.AmountClosingBalanceCr AS AmountClosingBalanceCr
FROM
	AccountingRegister.GeneralJournal.BalanceAndTurnovers AS GeneralJournalBalanceAndTurnovers</query>
```
- Text query nằm trong main data composition schema; chọn từ virtual table `AccountingRegister.GeneralJournal.BalanceAndTurnovers`, có sẵn các field tách Dr/Cr cho opening balance, turnover, closing balance.
- Schema còn khai báo parameter Period (cùng BeginOfPeriod/EndOfPeriod) để truyền khoảng thời gian vào virtual table.

### Functional option UseAccounting
Nguồn: nhánh lesson/24-theory — cf/FunctionalOptions/UseAccounting.xml
```xml
			<Content>
				<xr:Object>ChartOfAccounts.ChartOfAccounts</xr:Object>
				<xr:Object>AccountingRegister.GeneralJournal</xr:Object>
				<xr:Object>ChartOfCharacteristicTypes.ExtraDimensionTypes</xr:Object>
				<xr:Object>Subsystem.Accounting</xr:Object>
				<xr:Object>Document.GeneralJournalEntry</xr:Object>
			</Content>
```
- Content gồm chart of accounts, accounting register, ExtraDimensionTypes, subsystem Accounting và document GeneralJournalEntry — cùng cơ chế functional option lưu ở Boolean constant (xem thẻ gợi ý Bài tập 2).

## Video tham khảo (khóa Junior cũ)

Video trong playlist "Junior Developer Course" (1C Vietnam Academy, khóa cũ) có phạm vi trùng với bài này. Gọi là "video JC-<số>" (số bài của khóa cũ, khác số bài giáo trình); quy ước dẫn và độ tin cậy: `references/video-junior-course.md`.

- [JC-21 «Dữ liệu xác định trước»](https://www.youtube.com/watch?v=EQLuZq69Nmw&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=20) (8:02) — Bài 4 — Predefined data; Bài 13 / 24 — predefined của Chart of characteristic types, Chart of accounts
