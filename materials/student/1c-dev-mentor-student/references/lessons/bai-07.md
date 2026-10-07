# Bài 7 — Client-server: compilation directives, loại module, context/non-context call, đặt code đúng chỗ

## Khái niệm chính

### Phân chia client – server
- Mọi thao tác với application objects, đọc/ghi dữ liệu database chỉ thực hiện trên **server**. Chức năng form và command interface cũng được tạo ở server (chuẩn bị form data, sắp xếp elements, ghi form data sau khi thay đổi).
- Form chuẩn bị ở server được hiển thị ở **client**; client nhập liệu, gọi server để ghi dữ liệu. Command interface tạo ở server, hiển thị ở client. Report được tạo hoàn toàn ở server, hiển thị ở client.
- Platform tối thiểu hóa dữ liệu truyền về client: dữ liệu list, tabular sections, reports được truyền **dần theo phần người dùng đang xem**, không truyền hết ngay.
- **Server chạy**: database queries; ghi dữ liệu; posting documents; các phép tính; data processing; tạo reports; chuẩn bị form để hiển thị.
- **Client chạy**: lấy và mở form; hiển thị form; "giao tiếp" với người dùng (warnings, questions…); phép tính nhỏ cần phản hồi nhanh trong form (ví dụ price × quantity trên một dòng); làm việc với local files; làm việc với commercial equipment.

### Compilation directives trong form module
- **&AtClient**: chạy trong context client application. Có toàn bộ context form: attributes, elements, form parameters. Dùng cho mọi client event handler của form và procedure mô tả local form commands.
- **&AtServer**: chạy trong context server, có context form. Dùng cho mọi server event handler của form; developer cũng dùng để chuyển code lên server ("form's server procedures"). Gọi procedure này từ client = **context server call**.
- **&AtServerNoContext**: chạy ở server nhưng **không có form context** (attributes, elements, parameters). Dùng để chạy code chỉ chạy được ở server mà không phải truyền context giữa client và server (việc truyền context có thể tốn kém — phụ thuộc lượng form data, tốc độ client-server, sức mạnh máy client...). Gọi = **non-context server call**.
- **&AtClientAtServerNoContext**: chạy được cả ở client và server context. Ít dùng; dùng khi cần cùng một hành động cả lúc tạo form (server) và trong vòng đời form ở client → thay vì hai procedure giống nhau, viết một.
- Nếu **không ghi directive** trong form module → platform mặc định **&AtServer**.

### Quy tắc gọi
- Client procedure có thể gọi server procedure; chạy xong quay về client.
- **Không thể** gọi theo chiều ngược lại: server procedure không gọi được client procedure.
- Context server method **không thể** được gọi từ non-context client-server method hoặc non-context server method.

### Module chỉ chạy trên server
- Object module (catalog, document, chart of characteristic types và các reference objects khác).
- Object manager module.
- Record set module (registers).
- Một số common module — context phụ thuộc vào properties của module.

### Mục đích các module
- **Object module**: hiện thực hành vi của một instance riêng lẻ (CatalogObject, DocumentObject...). Chứa procedure/function làm việc với dữ liệu object (`ThisObject` và biến module), kể cả khi object chưa được ghi vào infobase. Ví dụ: object event handlers; procedure điền dữ liệu cho instance.
- **Manager module**: chứa chức năng "tĩnh" gắn logic với metadata object nhưng **không phụ thuộc trạng thái một instance cụ thể**:
  - liên quan tới tập hợp object (in danh sách, thông tin chung cho mọi instance, cập nhật infobase gắn với metadata object...);
  - làm việc với object đã ghi vào infobase, input parameter là **reference** (lấy printed form theo reference, tạo movements theo reference...).
  - Không cần data object instance (CatalogObject, DocumentObject...) để chạy.
- **Common module**: chức năng không gắn với một metadata object cụ thể, dùng chung cho nhiều object.

### 4 loại common module thường dùng
- **Client** — code luôn chạy chỉ trên client.
- **Client-server** — chạy trong context nơi gọi (gọi từ client → chạy ở client). Chỉ áp dụng cho code chạy được ở cả hai phía.
- **Server call** — chạy ở server, **có thể gọi từ client**.
- **Server** — chạy ở server, **chỉ gọi được từ server**.

### Preprocessor commands
- Dùng để tách code theo context chi tiết hơn: client method thực tế có thể chạy trên thin client, thick client, web client, mobile client. Một số code không chạy được trên web/mobile client hoặc cần điều kiện → tách bằng preprocessor commands.
- Ví dụ: method `Choose()` của object `FileDialog` (mở hộp thoại chọn file) yêu cầu file extension được kết nối khi chạy trên web client → cần tách logic.
- Method `AttachAddIn()` (gắn external component) không cần bước bổ sung, nhưng giới hạn: chỉ dùng được component dạng archive lưu trong infobase.

### Context và non-context call
- Mỗi context server call tạo thêm tải vì **toàn bộ form (elements + attribute data) được đóng gói gửi lên server**. Nếu không cần form data ở server → nên dùng non-context server call.
- Method &AtServerNoContext không biết `Object`, `ThisObject` (form hiện tại), `Items` (elements form hiện tại), và cả server variables của module → chỉ làm việc với dữ liệu được **truyền trực tiếp qua parameters**.
- Khi thêm parameter cho hàm, phải sửa lời gọi tương ứng, nếu không platform báo thiếu actual parameters.
- &AtClientAtServerNoContext: ngoài không có context, chỉ chạy code khả dụng ở cả client và server → **cấm truy cập database và tương tác người dùng**. Thường dùng cho tính toán đơn giản: tính tổng, điền title/text...
- Ví dụ tình huống: document có bảng products và attribute Total; Total tính lại ở client khi sửa số liệu; nhưng có server method thêm product rồi tính discount (discount ở server vì lưu trong database và phụ thuộc date + amount). Thay vì copy method tính Total thành bản server (trùng lặp code), tạo một method **client-server non-context** gọi được từ cả hai context. Cách nhân bản chỉ dùng trong tình huống khẩn cấp khi cần cùng hành động ở cả hai phía nhưng vẫn cần context.
- `AddMonth` cộng số tháng vào ngày truyền vào.

### Code placement (đặt code đúng module)
- Lỗi phổ biến: đặt business logic (ví dụ lấy giá hiện tại của product) trong **form module**.
- Form module dùng cho: làm việc với form, attributes, elements; tương tác người dùng (xử lý dữ liệu nhập, hiển thị kết quả, thông báo).
- Ví dụ SalesInvoice: attributes Customer (catalog Counterparties) và Contract (catalog CounterpartyContracts); Counterparties có attribute MainContract. Khi Customer đổi → Contract = MainContract của customer (handler sự kiện **OnChange** của field Customer).
- Gán **Undefined** cho attribute để xóa giá trị → kết quả là giá trị mặc định của kiểu: Number → 0; String → "" ; Date → 01.01.0001 00:00:00; Boolean → False; reference type → empty reference.
- Lý do không đặt logic này trong form module: document có thể được tạo từ code, hoặc từ giao diện với một số attribute đã điền sẵn (generation mechanism — tạo document dựa trên object khác); lúc đó không làm việc với form mà chỉ với object.
- Giải pháp: chuyển thuật toán vào **object module**, làm thành **export procedure** (FillMainContract), gọi lại từ form module.
  - Trong object module không có `Object` → bỏ tiền tố `Object.` (viết `MainContract` thay vì `Object.MainContract`).
  - Từ form module: lấy instance document object từ form attribute `Object`, gọi export method, rồi **đồng bộ lại** instance với form attribute `Object` để chuyển thay đổi lên form.
  - FillMainContractAtServer **không thể** là non-context, vì nó làm việc với form attribute (lấy instance và đồng bộ lại).
- Main attribute của form là **Object**, kết nối với một instance của object.

### Processing tabular sections
- Nên duyệt rows của tabular section **trên server**: ở client tabular section chỉ chứa phần rows đang hiển thị, phần còn lại được tải theo từng phần khi duyệt → bảng hàng trăm dòng có thể gây nhiều server calls, ảnh hưởng hiệu năng.

## Cú pháp & ví dụ code

### Danh sách compilation directives
```bsl
&AtClient
&AtServer
&AtServerNoContext
&AtClientAtServerNoContext
```

### Context server call — kiểm tra nhân viên trên 16 tuổi (document PersonnelChange)
```bsl
&AtClient

Procedure ChangesEmployeeOnChange(Item)

    CurrentData = Items.Changes.CurrentData;

    If ValueIsFilled(CurrentData.Employee) And Not EmployeeIsOldEnough(CurrentData.Employee) Then

        CurrentData.Employee = Undefined;

        MessageText = StrTemplate(

            "Employee %1 is under 16 years old on a document's date. You can't hire him",

            CurrentData.Employee

        );

        Message(MessageText);

    EndIf;

EndProcedure

&AtServer

Function EmployeeIsOldEnough(Employee)

    DateOfBirth = Employee.DateOfBirth;

    //If DateOfBirth <= AddMonth(Object.Date, -16 * 12) Then

    //  Return True;

    //Else

    //  Return False;

    //EndIf;

    // We can simplify the code above to return the result of comparison as Boolean

    Return DateOfBirth <= AddMonth(Object.Date, -16 * 12);

EndFunction
```
- Đổi `&AtServer` → `&AtServerNoContext` thì lỗi vì `Object` thành biến chưa khai báo. Cách sửa (tài liệu mô tả bằng hình): thêm parameter `Date` vào function và truyền thêm đối số ở lời gọi. [ghi chú ngoài nguồn: code sau khi sửa chỉ có trong ảnh chụp, không có dạng text trong tài liệu.] → đã bổ sung ở mục Code demo của bài Theory (nhánh lesson/07-theory).

### Ví dụ khác
- Code cho FillMainContractAtServer / FillMainContract, preprocessor commands và FileDialog chỉ xuất hiện dưới dạng ảnh trong tài liệu, không có text để trích nguyên văn. → FillMainContractAtServer / FillMainContract đã bổ sung ở mục Code demo của bài Theory (nhánh lesson/07-theory); preprocessor commands và FileDialog không có trong nhánh.

## Thuộc tính/thiết lập quan trọng trong Designer
- Thuộc tính của **common module** quyết định context thực thi (4 loại: Client, Client-server, Server call, Server).
- Event **OnChange** của form field (ví dụ field Customer) để gán handler.
- Form main attribute: **Object**.
- Các loại module: Object module, Object manager module, Record set module, Common module, Form module.

## Lỗi thường gặp / lưu ý
- Truy cập `Object`, `ThisObject`, `Items` hoặc server variables của module trong method &AtServerNoContext → lỗi biến chưa khai báo.
- Thêm parameter cho function nhưng không sửa lời gọi → platform báo không đủ actual parameters.
- Gọi client procedure từ server → không thể.
- Gọi context server method từ non-context client-server / non-context server method → không thể.
- Dùng context server call khi không cần form data → tải thêm không cần thiết.
- Đặt business logic trong form module → không chạy được khi document tạo từ code hoặc qua generation mechanism.
- Nhân bản cùng một method cho client và server → trùng lặp code; ưu tiên &AtClientAtServerNoContext.
- Trong &AtClientAtServerNoContext: không truy cập database, không tương tác người dùng.
- Duyệt tabular section lớn ở client → nhiều server calls, giảm hiệu năng.
- Khi copy code từ form module sang object module phải bỏ tham chiếu `Object.`.

## Điểm cần nhớ
- Đọc/ghi database, posting, queries, reports, chuẩn bị form: **server**. Hiển thị, tương tác người dùng, phép tính nhanh, local files, thiết bị: **client**.
- Bốn directive: &AtClient, &AtServer (mặc định khi không ghi), &AtServerNoContext, &AtClientAtServerNoContext.
- Chỉ gọi được client → server, không có chiều ngược lại.
- Ưu tiên non-context server call khi không cần form data, vì context call đóng gói toàn bộ form gửi lên server.
- Object module / manager module / record set module chạy trên server; manager module không cần instance, thường nhận reference.
- Common module: Client, Client-server, Server call (gọi được từ client), Server (chỉ từ server).
- Business logic đặt trong object module (export procedure), form module chỉ gọi lại và đồng bộ với attribute `Object`.
- Gán Undefined cho attribute = trả về giá trị mặc định của kiểu; duyệt tabular section trên server.

## Thẻ gợi ý bài thực hành (Practice 7)

> Thẻ bám theo đề "7. Practice.docx". Toàn bộ bài xoay quanh câu hỏi "code này đặt ở module nào, chạy ở client hay server" (mục Code placement và Compilation directives).

### Bài tập 1 — Attribute Discount (hợp đồng và SalesInvoice)
- **Đề bài (tóm tắt):** Thêm Discount (Number(4, 2)) vào CounterpartyContracts và vào SalesInvoice; trên form SalesInvoice field Discount phải read-only.
- **Gợi ý 1 — Hướng đi:** Discount trên chứng từ là giá trị được **điền tự động** từ hợp đồng, không cho sửa tay — chuẩn bị cho Bài tập 2.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Attribute `Discount` ở cả catalog và document (Length 4, Precision 2); trên form document đặt field và bật property **ReadOnly**.
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm attribute vào catalog, nhập discount cho vài hợp đồng.
  2. Thêm attribute vào document, đặt field lên form, bật ReadOnly.
- **Lỗi hay gặp:**
  - Đặt ReadOnly ở attribute metadata thay vì ở form item, hoặc quên hẳn.
  - Length 4, Precision 2 nghĩa là tối đa 99.99 — đủ cho phần trăm, đừng đặt Precision 4.
- **Tự kiểm tra:** Form SalesInvoice có field Discount mờ, không gõ được.

### Bài tập 2 — FillDiscount trong object module
- **Đề bài (tóm tắt):** Khi đổi Contract trên SalesInvoice, điền Discount từ hợp đồng bằng procedure FillDiscount đặt trong **object module** của document (vì Contract có thể đổi từ code, không chỉ từ form).
- **Gợi ý 1 — Hướng đi:** Mẫu "business logic trong object module, form chỉ gọi lại" giống hệt FillMainContract trong phần Code demo của bài Theory: export procedure trong object module + context server call ở form dùng `FormAttributeToValue` / `ValueToFormAttribute`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Object module của SalesInvoice: `Procedure FillDiscount() Export` — trong object module viết thẳng tên attribute (không có `Object.`). Form module: handler `&AtClient` cho event **OnChange** của field Contract → gọi một procedure `&AtServer` để chuyển `Object` thành applied object, gọi FillDiscount, rồi chuyển ngược lại.
- **Gợi ý 3 — Khung bài làm:**
  1. Viết export procedure trong object module: đọc discount từ hợp đồng, gán cho attribute Discount.
  2. Tạo handler OnChange của Contract trên form.
  3. Viết procedure server của form theo mẫu FillMainContractAtServer.
  ```bsl
  &AtServer
  Procedure OnChangeContractAtServer()
  	DocumentObject = ___;   // chuyển form attribute "Object" thành applied object
  	// gọi export procedure của object module
  	// chuyển applied object ngược về form attribute "Object"
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Viết `Object.Contract` trong object module → biến không xác định; ở đó dùng thẳng `Contract`.
  - Thiếu `Export` → form không gọi được method.
  - Đặt procedure gọi `FormAttributeToValue` là `&AtServerNoContext` → không có `Object`.
  - Quên `ValueToFormAttribute` → giá trị Discount không hiện lại trên form.
- **Tự kiểm tra:** Chọn hợp đồng có Discount 5 → field Discount trên chứng từ thành 5 ngay; đặt breakpoint trong FillDiscount để thấy nó chạy ở server.

### Bài tập 3 — Tính Amount có discount, dùng được ở client và server
- **Đề bài (tóm tắt):** Sửa procedure tính Amount của một dòng để tính cả discount của document và gọi được từ client lẫn server; tự lập công thức theo ví dụ Price 15, Quantity 10, Discount 5 → Amount 142.5; tạo method tính lại Amount cả bảng và gọi khi đổi discount.
- **Gợi ý 1 — Hướng đi:** Directive **&AtClientAtServerNoContext** (hoặc common module loại **Client-server**) cho code chạy được ở cả hai phía, với điều kiện không truy cập database, không tương tác người dùng. Discount phải truyền qua parameter vì method non-context không thấy `Object`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form module SalesInvoice: đổi directive của `CalculateAmountAtRow`, thêm parameter Discount; handler OnChange của Quantity/Price truyền thêm `Object.Discount`. Procedure tính lại cả bảng `&AtServer` duyệt `Object.Products`, gọi lại `CalculateAmountAtRow` cho từng dòng; gọi nó sau khi FillDiscount chạy (Bài tập 2).
- **Gợi ý 3 — Khung bài làm:**
  1. Từ ví dụ của đề suy ra công thức: 15 × 10 = 150, giảm 5% còn 142.5.
  2. Đổi directive và chữ ký procedure tính một dòng.
  3. Sửa mọi lời gọi cũ cho đủ parameter.
  4. Viết procedure server duyệt bảng và gọi lại procedure tính một dòng.
  ```bsl
  ___                                          // directive cho phép gọi từ client và server
  Procedure CalculateAmountAtRow(ProductsRow, ___)
  	ProductsRow.Amount = ___;                // Quantity × Price, trừ đi phần trăm discount
  EndProcedure
  ```
- **Lỗi hay gặp:**
  - Viết `Object.Discount` bên trong procedure `&AtClientAtServerNoContext` → lỗi biến chưa khai báo (giống ví dụ EmployeeIsOldEnough của bài).
  - Thêm parameter nhưng không sửa lời gọi cũ → "không đủ actual parameters".
  - Nhân trực tiếp với Discount (5) thay vì chia 100 → Amount sai.
  - Nhân bản hai procedure riêng cho client và server → trùng code.
- **Tự kiểm tra:** Nhập Price 15, Quantity 10 với hợp đồng Discount 5 → Amount = 142.5; đổi hợp đồng sang discount khác → mọi dòng tính lại.

### Bài tập 4 — DocumentTotal tính trên server
- **Đề bài (tóm tắt):** Chuyển việc tính DocumentTotal từ handler client ProductsOnChange sang một procedure server (hoặc gộp vào procedure tính lại Amount cả bảng, vì nó đã duyệt bảng); gọi sau khi tính lại Amount.
- **Gợi ý 1 — Hướng đi:** "Processing tabular sections": duyệt tabular section nên làm ở server để tránh nhiều server call. Gộp tính tổng vào cùng vòng lặp tính lại Amount là cách gọn nhất.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Procedure `&AtServer` (cần `Object` → context call) trong form module; handler `ProductsOnChange` (`&AtClient`) chỉ gọi procedure đó; procedure server của Bài tập 2 cũng gọi nó.
- **Gợi ý 3 — Khung bài làm:**
  1. Trong vòng lặp duyệt dòng ở server: tính Amount của dòng rồi cộng vào biến tổng.
  2. Sau vòng lặp gán tổng vào attribute của document.
  3. Thay nội dung handler ProductsOnChange bằng một lời gọi.
- **Lỗi hay gặp:**
  - Đặt procedure là `&AtServerNoContext` → không duyệt được `Object.Products`.
  - Quên gọi lại sau khi đổi hợp đồng → tổng không cập nhật theo discount mới.
  - Giữ vòng lặp cũ ở client song song → tính hai lần.
- **Tự kiểm tra:** Thêm/xóa dòng và đổi hợp đồng → DocumentTotal luôn bằng tổng các Amount; Performance snapshot (Bài 8) cho thấy chỉ một server call mỗi lần thay đổi.

### Bài tập 5 — Cảnh báo hợp đồng hết hiệu lực
- **Đề bài (tóm tắt):** Khi đổi ngày hoặc đổi hợp đồng, nếu ValidUntil của hợp đồng đã điền và nhỏ hơn ngày chứng từ thì báo "This contract is invalid on <ngày chứng từ không kèm giờ>"; ngày kết thúc lấy bằng function server không context; chỉ cảnh báo, không chặn.
- **Gợi ý 1 — Hướng đi:** **Non-context server call** (mục "Context và non-context call"): server chỉ cần reference hợp đồng để đọc ValidUntil, không cần cả form. So sánh và `Message()` ở client. Hợp đồng còn hiệu lực đến **hết** ngày ValidUntil, nên đưa ngày chứng từ về đầu ngày (hoặc ValidUntil về cuối ngày) trước khi so sánh.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form module: procedure kiểm tra `&AtClient`; function `&AtServerNoContext` nhận hợp đồng làm parameter, trả về ngày kết thúc. Handler OnChange của field Date và field Contract cùng gọi procedure kiểm tra. Dùng `ValueIsFilled()`, `BegOfDay()` / `EndOfDay()`, `Format()` (tra format chuỗi chỉ hiện ngày trong Syntax assistant).
- **Gợi ý 3 — Khung bài làm:**
  1. Viết function server không context: input là hợp đồng, output là ValidUntil.
  2. Viết procedure client: gọi function, kiểm tra đã điền, so sánh với ngày chứng từ đã đưa về đầu ngày, báo message.
  3. Gọi procedure từ OnChange của Date và (sau phần FillDiscount) từ OnChange của Contract.
  ```bsl
  &AtServerNoContext
  Function ContractValidUntil(___)
  	Return ___;      // ngày kết thúc của hợp đồng nhận qua parameter
  EndFunction
  ```
- **Lỗi hay gặp:**
  - Dùng `Object.Contract` bên trong function `&AtServerNoContext` → phải truyền qua parameter.
  - So sánh trực tiếp hai Date có giờ → chứng từ lập trong ngày ValidUntil (sau 00:00) bị báo nhầm là hết hạn.
  - Không kiểm tra ValidUntil trống → hợp đồng vô thời hạn (date rỗng) bị báo hết hạn.
  - Message in kèm giờ vì nối thẳng Date vào chuỗi thay vì dùng `Format()`.
- **Tự kiểm tra:** Hợp đồng ValidUntil = hôm qua, chứng từ hôm nay → có cảnh báo; ValidUntil = hôm nay → không cảnh báo; ValidUntil trống → không cảnh báo; đổi ngày chứng từ cũng kích hoạt kiểm tra.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/07-theory)

> Nhánh lesson/07-theory là trạng thái cấu hình khi quay demo Theory Bài 7 (so với lesson/05-theory: thêm form module của PersonnelChange, FillMainContract của SalesInvoice và 4 common module rỗng). Các đoạn dưới đây là code thật đứng sau những ảnh chụp màn hình của tài liệu.

### EmployeeIsOldEnough sau khi đổi sang &AtServerNoContext (truyền thêm parameter Date)
Nguồn: nhánh lesson/07-theory — cf/Documents/PersonnelChange/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure ChangesEmployeeOnChange(Item)
	
	CurrentData = Items.Changes.CurrentData;
	
	If ValueIsFilled(CurrentData.Employee) And Not EmployeeIsOldEnough(CurrentData.Employee, Object.Date) Then
		CurrentData.Employee = Undefined;
		MessageText = StrTemplate(
			"Employee %1 is under 16 years old on a document's date. You can't hire him",
			CurrentData.Employee
		);
		Message(MessageText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EmployeeIsOldEnough(Employee, Date)

	DateOfBirth = Employee.DateOfBirth;
	
	Return DateOfBirth <= AddMonth(Date, -16 * 12);
	
EndFunction
```
- Đây đúng là bản "sau khi sửa" mà tài liệu chỉ có ảnh: function thêm parameter `Date`, lời gọi ở client truyền thêm `Object.Date`.
- Trong hàm `&AtServerNoContext` không còn `Object.Date` — dùng parameter `Date`; nếu vẫn viết `Object.Date` sẽ lỗi biến chưa khai báo như bài mô tả.
- Server chỉ cần reference `Employee` (đọc `Employee.DateOfBirth`) và một ngày → non-context call, không đóng gói cả form gửi lên server.
- So với bản trong mục "Cú pháp & ví dụ code": phần comment `If ... Then Return True ...` đã được rút gọn thành `Return DateOfBirth <= AddMonth(Date, -16 * 12);`.

### FillMainContractAtServer (form module) gọi export procedure FillMainContract (object module)
Nguồn: nhánh lesson/07-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl và cf/Documents/SalesInvoice/Ext/ObjectModule.bsl
```bsl
&AtClient
Procedure CustomerOnChange(Item)
	
	FillMainContractAtServer();
	
EndProcedure

&AtServer
Procedure FillMainContractAtServer()

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillMainContract();
	
	ValueToFormAttribute(DocumentObject, "Object");

EndProcedure
```
```bsl
Procedure FillMainContract() Export

	If ValueIsFilled(Customer) Then
		Contract = Customer.MainContract;
	Else	
		Contract = Undefined;
	EndIf;
	
EndProcedure
```
- Đây là ví dụ Code placement của bài (trước đây chỉ có ảnh): business logic "điền hợp đồng chính của customer" nằm trong **object module** (`Export`), form module chỉ gọi lại.
- `FillMainContractAtServer` phải là `&AtServer` (context call) vì dùng `FormAttributeToValue("Object")` / `ValueToFormAttribute(DocumentObject, "Object")`.
- Trong object module viết thẳng `Customer`, `Contract` (attribute của chính object), không có `Object.`; gán `Undefined` khi chưa chọn customer → attribute trở về giá trị rỗng của kiểu.
- Handler `CustomerOnChange` gắn vào event **OnChange** của field Customer — đúng chiều gọi client → server.

### Bốn common module theo context thực thi
- Nhánh có 4 common module rỗng minh họa 4 loại trong bài, phân biệt chỉ bằng properties (cf/CommonModules/*.xml), không có code BSL:
  - `CommonClient`: Client (managed application) = true, Server = false.
  - `CommonClientServer`: Client (managed application) = true, Server = true, Server call = false.
  - `CommonServerCall`: Server = true, Server call = true (gọi được từ client).
  - `CommonServer`: Server = true, Server call = false (chỉ gọi từ server).
- [ghi chú ngoài nguồn] Nhánh lesson/07-theory không có ví dụ preprocessor commands (`#If ... #EndIf`) và không có ví dụ FileDialog.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

- [Các module và tương tác Client-Server](https://www.youtube.com/watch?v=oD8pK7RvuYw&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=29) (6:16) — Bài 7 — compilation directives, loại module, context / non-context call _(mã nội bộ JC-30)_
- [Trò chuyện với người dùng](https://www.youtube.com/watch?v=s0MHq7d_nVc&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=38) (9:26) — Bài 9 — ShowQueryBox + CallbackDescription (code mẫu); Bài 7 — dialog không chặn (CallbackDescription); Bài 21 — ShowUserNotification _(mã nội bộ JC-39)_
