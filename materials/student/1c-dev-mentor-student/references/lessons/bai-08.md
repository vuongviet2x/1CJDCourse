# Bài 8 — Debugging: debugger, breakpoints, step-by-step, Expression, Local variables, Call stack, Performance snapshot

## Khái niệm chính

### Debugger
- Công cụ chính để tìm và sửa lỗi; hỗ trợ phát triển và debug program modules. Khả năng:
  - debug module ở cả file và client-server version, kể cả **background jobs**
  - chạy từng bước (step by step)
  - đặt **breakpoints**
  - ngắt và tiếp tục chạy module
  - evaluate expressions để phân tích trạng thái biến
  - thay đổi giá trị biến khi debug
  - xem **call stack** của procedures/functions
  - dừng khi xảy ra lỗi
- Debug được qua **TCP/IP** và **HTTP**. Bài học chỉ dùng TCP/IP (HTTP cần cấu hình debug server). Điều kiện: giao thức mạng TCP/IP phải được bật trên hệ thống.

### Start debugging
- Từ Designer: nút **Start debugging** trên toolbar hoặc menu **Debug**, hotkey **F5**. Platform chạy client phù hợp nhất (thường là thin client).
- Chạy loại client khác: **Debug - Start debugging with -**.
- Trong khi debug đang kết nối, icon start debug đổi hình dạng. Bấm lại → cảnh báo debug đang chạy; nếu tiếp tục, session hiện tại bị kết thúc và session mới được khởi động.
- **Attach** vào session có sẵn: session phải bật debug connection. Kiểm tra trong Enterprise mode (user full rights): **Service and settings - Settings - Options**, property **Debug in current session** = **Allowed (TCP/IP)**.
- Trong Designer: **Debug - Attach for debugging…** → chọn session ở danh sách trên → **Attach**; chọn ở danh sách dưới → **Detach** để ngắt.
- Debug external connections, HTTP services, background jobs: bấm **Autoattach…**, đánh dấu loại kết nối cần, bấm **OK**.

### Breakpoints
- Breakpoint: vị trí trong module nơi việc thực thi dừng và quyền điều khiển chuyển cho debugger. Hiển thị bằng ký hiệu ở cột trái của module (ký hiệu khác nhau cho enabled/disabled).
- Đặt được ở bất kỳ dòng nào, bất kỳ lúc nào khi debug. Nếu dòng không có operator (dòng trống), chứa text không thực thi (header procedure/function, khai báo biến), hoặc là phần tiếp nối của operator dòng trên → vị trí breakpoint **tự động điều chỉnh**.
- Đặt/xóa bằng chuột: **double-click vùng xám** của dòng.
- Breakpoints được **lưu khi đóng configuration**. Xem danh sách: **Debug - Breakpoint list** (cột On/Off, module name, row).

| Command | Mô tả |
| --- | --- |
| Breakpoint | Đặt hoặc xóa breakpoint tại dòng con trỏ |
| Breakpoint with the condition | Đặt breakpoint và mở hộp thoại nhập điều kiện (logical expression); chỉ dừng khi điều kiện thỏa |
| Disable breakpoint | Bật/tắt breakpoint (khi dòng hiện tại có breakpoint) |
| Remove all breakpoints | Xóa mọi breakpoint ở mọi module |
| Disable all breakpoints | Tắt mọi breakpoint ở mọi module, không xóa |
| Breakpoint list | Xem và quản lý breakpoints |
| Stop on Error | Khi có lỗi, debugger dừng và chuyển tới dòng gây lỗi |

### Step-by-step execution
- Khi debug item đầu tiên được attach, hệ thống thêm các lệnh quản lý debug vào menu Debug.

| Command | Mô tả |
| --- | --- |
| Step In | Nếu operator kế tiếp là lời gọi procedure/function → đi vào từng bước bên trong; nếu không → sang operator kế |
| Step Over | Nếu là lời gọi → chạy trọn (không từng bước), sang operator kế |
| Step Out | Ngắt chạy từng bước của procedure/function hiện tại, dừng ở operator đầu tiên sau lời gọi |
| Go to Cursor | Chạy mọi lệnh tới dòng có con trỏ |
| Continue | Thoát chế độ từng bước, chạy tự do (tới breakpoint kế tiếp) |

- **Debug - Continue Debugging**: chạy tự do cho các debug item đã attach; client application được attach sẽ tự kích hoạt.
- Ngắt toàn bộ quá trình debug (trừ background jobs): xóa mọi breakpoint rồi chạy **Debug - Continue Debugging** (nếu breakpoint đã kích hoạt).
- Ngắt debug và kết thúc các debug item: **Debug - Finish** → khi đó `BeforeExit()` và `OnExit()` **không được chạy**.
- Có thể sửa và lưu configuration khi debug, nhưng debugger **không compile code đã sửa** — vẫn debug theo database configuration lúc bắt đầu/attach. Muốn debug thay đổi → phải **update database configuration**.
- Bảng phím tắt debugger có trong Help.

### Debug management (các lệnh còn lại trong menu Debug)
- **Restart**: dừng và khởi động lại ở 1C:Enterprise mode; nếu configuration đã sửa → nhắc update database configuration.
- **Break**: dừng module và kết thúc debug item hiện tại.
- **Stop**: dừng tại operator hiện tại; dùng để bắt đầu debug từ dòng thực thi kế tiếp; hữu ích để phân tích module bị "cycling" (lặp vô hạn).
- **Stop on errors**: mở hộp thoại thiết lập "stop on error".
  - Checkbox **Stop on error**: có dừng khi lỗi hay không. Khi dừng → cảnh báo *Runtime error* kèm vị trí và nguyên nhân.
  - Checkbox **Stop on errors that include specific text**: chỉ dừng nếu thông báo lỗi chứa substring trong bảng (substring chỉ được xét khi đánh dấu checkbox cạnh nó). Không chọn → dừng với mọi lỗi.
  - Tại chỗ lỗi, execution point được đặt và debug item gây lỗi thành item hiện tại.

### "Expression" window
- Mở bằng **Debug - Evaluate expression**, hoặc **Evaluate expression** trong context menu (right click), hoặc hotkey **Shift+F9**.
- Nhập biểu thức 1C:Enterprise language vào field **Expression** (tay hoặc chọn từ danh sách đã dùng). Nếu con trỏ đặt trên/đã chọn biểu thức → tự điền.
- Bấm **Evaluate** → kết quả ở field **Value**.
- Biểu thức được tính trong **hệ thống thật** → có thể có side effect (ví dụ biểu thức tạo item trong infobase nếu chưa có sẽ chỉ tạo một lần, vì lần sau item đã tồn tại thật).
- Nút **Add to immediate …**: đưa biểu thức vào immediate window (dòng mới) để theo dõi thay đổi; tự mở immediate window nếu chưa có.
- Với String, array hoặc collection → nút **Show value in a new window** khả dụng (hoặc context menu, phím **F2**):
  - String: cửa sổ multiline, copy được ra clipboard.
  - Collection/array: bảng, cột = tên attribute, row = giá trị; hiện số phần tử, cột đầu là index.
- Nút **Output list**: xuất bảng kết quả ra text hoặc spreadsheet document; với cây chỉ xuất các nhánh đang mở.
- Rê chuột lên biểu thức → tooltip giá trị hiện tại (nếu có textual representation); dùng được cho property.
- Có thể evaluate cả **code đã comment**; có thể chọn một phần biểu thức để tính riêng (ví dụ `Products[0]`).

### "Local variables" window
- Mở: **Debug - Local Variables** (khi đang debug).
- Chứa parameters của method đang debug và mọi local variable ở mức call stack hiện tại (mặc định đỉnh stack). Ban đầu biến ở trạng thái uninitialized; giá trị hiện khi được gán.
- Không sửa được cột Variable; không sửa được thành phần các rows.
- Tự cập nhật sau mỗi thao tác debug (đổi call stack, đổi debug item...).
- Context menu cột Value: **Copy result**. Một số kiểu xem được ở cửa sổ riêng.
- Immediate window có thể xuất ra spreadsheet hoặc text document.
- Cửa sổ tự đóng khi kết thúc debug.

### Variable value change
- Khi dừng ở breakpoint, có thể đổi giá trị biến và property object có quyền ghi — từ expressions window, immediate window, local variables window.
- Trong expressions window: rê chuột lên biến, bấm nút **Set expression as a value** (hình "f(x)") → cửa sổ nhập biểu thức (header là tên biến). Có thể nhập hằng số các kiểu hoặc biểu thức hợp lệ; có context help theo context method hiện tại.
- Bấm **Set** → kết quả hiện ở dưới: "The value is changed." hoặc thông báo lỗi.
- Trong immediate/local variables window: context menu → **Set expression as a value**. "Variable" bao gồm cả property của collection (lồng nhau tùy ý).

### Call stack
- Hiển thị chuỗi lời gọi procedure/function dẫn tới dòng đang debug. Cột: **Name** (method), **Line** (số dòng), **Item** (debug item chứa module).
- Icon cột đầu:
  - **Mũi tên vàng**: đỉnh call stack.
  - **Mũi tên xanh lá**: method mà context đó dùng để tính biến trong Expression window và Immediate window. Không hiện nếu đỉnh stack trùng context hiện tại.
- Double-click một row để đổi context và đặt con trỏ tới dòng tương ứng. Biến chỉ có giá trị trong context method khai báo nó (ví dụ TotalWeight trong CalculateWeightAtServer()).
- Row màu **xám**: chuyển tới dòng được nhưng **không evaluate** được biểu thức trong context đó — đó là các item "nằm" trên client khi đỉnh stack "nằm" trên server.

### Performance snapshot
- Đánh giá hiệu năng toàn configuration hoặc một phần, trong debug item bất kỳ: tần suất dùng và tốc độ từng đoạn code; code chạy ở server hay client; dòng nào gây server call. Có thể hiện thực nhiều cách giải rồi chọn cách nhanh nhất.
- So sánh phải trong **cùng điều kiện** (CPU bận việc khác ảnh hưởng kết quả); khi hai cách có hiệu năng gần nhau → chụp nhiều snapshot cho mỗi cách và lấy trung bình.
- Dùng **Performance meter** (menu Debug hoặc command bar). Chọn lại lần nữa → dừng đo và mở cửa sổ kết quả. Bật/tắt ảnh hưởng mọi debug item đang attach.
- Các phương án:
  1. Đo cả phần khởi động: chạy **Debug - Performance Snapshot** trước, rồi mới khởi động 1C:Enterprise (thời gian từ lúc bắt đầu đo tới lúc hệ thống chạy không tính).
  2. Không đo phần khởi động: khởi động 1C:Enterprise, chuẩn bị tới đoạn cần đo, sang Designer bật snapshot.
  - Đo cả phần shutdown: tắt chương trình rồi sang Designer — không cần dừng đo thủ công, kết quả tự hiện.
  - Không đo shutdown: dừng snapshot thủ công để xem kết quả. Ví dụ phân tích posting document: mở chương trình, mở và điền document, sang Designer bật snapshot, sang Enterprise post document, sang Designer kết thúc snapshot.

### Measurement results
- Bảng các cột:
  - **Module** — tên module
  - **Row number** — số dòng
  - **Line** — text của dòng
  - **Col.** — số lần gọi dòng này
  - **Time (net)** — tổng thời gian (giây) của dòng
  - **%(Time) (net)** — phần trăm trên tổng thời gian snapshot (100% là thực thi code trên client)
  - **Client** — icon đánh dấu dòng chạy trên client
  - **Server** — icon đánh dấu dòng chạy trên server
  - **Server proc.** (server processing) — icon dòng khởi tạo server call: **Direct server call** (gọi server ở mức platform hoặc gọi trực tiếp method server) và **Nested server call** (gọi local method client mà bên trong có server call).
- Checkbox **Track execution for procedures and functions**: chọn → thời gian = full time (call time + net time); bỏ chọn → chỉ thời gian của chính dòng ("net time"), không gồm thời gian procedure/function được gọi. Mặc định được chọn, trạng thái lưu giữa các session; đổi trạng thái thì header các cột thời gian đổi theo.
- Checkbox **Client** / **Server** (góc dưới phải) để hiển thị kết quả đo ở client, server hoặc cả hai — chỉ hiện khi debug server infobase / server debug item.
- Nhiều cửa sổ kết quả: rê chuột lên cột kết quả → tooltip URL file dữ liệu.
- Khi cửa sổ snapshot mở, module window có thêm cột số lần gọi và % thời gian (kèm icon client/server/server call); mở nhiều kết quả → nhiều cột; đóng cửa sổ kết quả → cột biến mất.
- Double-click dòng trong kết quả → nhảy tới dòng trong module (và ngược lại từ cột kết quả trong module editor).
- Sort theo cột bằng click header: Module/Row number → theo số dòng; Col. → theo số lần gọi; Time/%(Time) → theo thời gian; nếu đo cả client và server thì sort được theo các cột đó.

## Cú pháp & ví dụ code
- Tài liệu bài 8 không có ví dụ code 1C dạng text (các ví dụ chỉ ở dạng ảnh chụp màn hình). → đã bổ sung ở mục Code demo của bài Theory (nhánh lesson/08-theory).
- Các procedure được nhắc tên: `BeforeExit()`, `OnExit()` (không chạy khi dùng Debug - Finish); method ví dụ trong call stack: `Document.SalesInvoice.Form.DocumentForm.CalculateWeightAtServer()`; biểu thức ví dụ: `Products[0]`.

## Thuộc tính/thiết lập quan trọng trong Designer
- Menu **Debug**: Start debugging (**F5**), Start debugging with, Attach for debugging…, Autoattach…, Breakpoint, Breakpoint with the condition, Disable breakpoint, Remove all breakpoints, Disable all breakpoints, Breakpoint list, Stop on Error, Step In, Step Over, Step Out, Go to Cursor, Continue / Continue Debugging, Finish, Restart, Break, Stop, Stop on errors, Evaluate expression (**Shift+F9**), Local Variables, Performance meter / Performance Snapshot.
- Enterprise mode: **Service and settings - Settings - Options** → **Debug in current session** = **Allowed (TCP/IP)**.
- Hộp thoại Stop on errors: **Stop on error**, **Stop on errors that include specific text**.
- Expression window: field **Expression**, **Value**, nút **Evaluate**, **Add to immediate …**, **Show value in a new window** (F2), **Output list**, **Set expression as a value** (f(x)), **Set**.
- Local variables: **Copy result**.
- Performance snapshot: **Track execution for procedures and functions**, checkbox **Client** / **Server**.

## Lỗi thường gặp / lưu ý
- Sửa code khi đang debug nhưng không update database configuration → debugger vẫn chạy code cũ.
- **Debug - Finish** bỏ qua `BeforeExit()` và `OnExit()`.
- Bấm Start debugging khi đang debug → session hiện tại bị kết thúc.
- Attach không được nếu session chưa bật **Debug in current session = Allowed (TCP/IP)**.
- Evaluate expression chạy trên hệ thống thật → có side effect (ví dụ tạo dữ liệu trong infobase).
- Row xám trong Call stack: không evaluate được biểu thức (context client khi đỉnh stack ở server).
- Biến chỉ evaluate được trong context method chứa nó (đổi context → "not defined").
- Bỏ chọn **Track execution for procedures and functions** → Time không phản ánh thời gian thực của dòng có gọi method.
- So sánh hiệu năng phải cùng điều kiện; chạy nhiều snapshot và lấy trung bình.
- Debug qua TCP/IP yêu cầu TCP/IP bật trên hệ thống.

## Điểm cần nhớ
- F5 = Start debugging; Shift+F9 = Evaluate expression; F2 = Show value in a new window; double-click vùng xám = đặt/xóa breakpoint.
- Attach vào session cần **Debug in current session = Allowed (TCP/IP)**; dùng Autoattach cho background jobs, HTTP services, external connections.
- Breakpoint with the condition chỉ dừng khi điều kiện đúng; Stop on Error dừng tại dòng gây lỗi (có thể lọc theo text lỗi).
- Step In (vào trong), Step Over (chạy trọn), Step Out (ra ngoài), Go to Cursor, Continue.
- Thay đổi code khi debug cần update database configuration mới có hiệu lực.
- Có thể đổi giá trị biến khi dừng bằng **Set expression as a value**.
- Call stack: mũi tên vàng = đỉnh stack, xanh lá = context đang evaluate; row xám = không evaluate được.
- Performance snapshot cho biết số lần gọi, thời gian, client/server và dòng gây server call (Direct / Nested).

## Thẻ gợi ý bài thực hành (Practice 8)

> Thẻ bám theo đề "8. Practice.docx". Bài này chủ yếu là thao tác với debugger; phần code của form FormForDebugTest được **đề bài cho sẵn** (bạn chép từ file đề), nhiệm vụ là dùng debugger để tìm lỗi và quan sát.

### Bài tập 1 — Breakpoint cơ bản
- **Đề bài (tóm tắt):** Đặt breakpoint, start debugging và kiểm tra code dừng tại đó.
- **Gợi ý 1 — Hướng đi:** Mục "Breakpoints" và "Start debugging" của bài.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Double-click vùng xám bên trái dòng code (hoặc Debug → Breakpoint); **F5** = Start debugging.
- **Gợi ý 3 — Khung bài làm:**
  1. Chọn một handler client đã có (ví dụ OnChange của cột Quantity trong SalesInvoice).
  2. Đặt breakpoint ở dòng có operator.
  3. F5, thao tác ở Enterprise mode để handler chạy.
- **Lỗi hay gặp:**
  - Đặt breakpoint trên dòng trống/dòng `Procedure` → platform dời sang dòng có operator gần nhất.
  - Sửa code mà chưa update database configuration → debugger chạy code cũ.
- **Tự kiểm tra:** Designer bật lên, mũi tên vàng nằm ở dòng có breakpoint.

### Bài tập 2 — Breakpoint bị disable
- **Đề bài (tóm tắt):** Đặt breakpoint thứ hai sau breakpoint đầu và disable nó; tiếp tục debug (Continue / F5) từ breakpoint đầu và kiểm tra code không dừng ở breakpoint đã disable.
- **Gợi ý 1 — Hướng đi:** Breakpoint disable vẫn được giữ trong danh sách nhưng không dừng.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Debug → **Disable breakpoint**; **Breakpoint list** để xem trạng thái; Continue debugging (F5).
- **Gợi ý 3 — Khung bài làm:**
  1. Đặt breakpoint thứ hai cùng procedure, phía dưới.
  2. Disable nó.
  3. Chạy tới breakpoint đầu, bấm F5.
- **Lỗi hay gặp:**
  - Xóa breakpoint thay vì disable — đề muốn quan sát trạng thái disable.
  - Bấm Start debugging thay vì Continue khi đang debug → kết thúc session hiện tại.
- **Tự kiểm tra:** Code chạy hết procedure, không dừng ở breakpoint thứ hai; Breakpoint list hiện nó ở trạng thái tắt.

### Bài tập 3 — Conditional breakpoint
- **Đề bài (tóm tắt):** Đặt breakpoint có điều kiện, nên thử trong vòng lặp qua collection để điều kiện chỉ đúng ở một số dòng.
- **Gợi ý 1 — Hướng đi:** **Breakpoint with the condition** chỉ dừng khi biểu thức điều kiện đúng.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Debug → Breakpoint with the condition; nơi phù hợp: vòng `While` trong procedure FillProducts (code đề cho), điều kiện dựa trên biến đếm dòng; hoặc vòng duyệt tabular section ở server trong SalesInvoice.
- **Gợi ý 3 — Khung bài làm:**
  1. Chọn dòng bên trong thân vòng lặp.
  2. Đặt breakpoint có điều kiện dùng một biến thay đổi theo từng vòng.
  3. Chạy và kiểm tra giá trị biến khi dừng.
- **Lỗi hay gặp:**
  - Điều kiện dùng biến chưa tồn tại ở dòng đó → không bao giờ dừng.
  - Đặt breakpoint ngoài vòng lặp → chỉ dừng một lần, không thấy tác dụng của điều kiện.
- **Tự kiểm tra:** Debugger dừng đúng ở vòng có điều kiện đúng; Local variables cho thấy biến đếm đúng giá trị điều kiện.

### Bài tập 4 — Step In / Step Out / Step Over
- **Đề bài (tóm tắt):** Tự dùng ba lệnh step với các lời gọi lồng nhau.
- **Gợi ý 1 — Hướng đi:** Mục "Step-by-step execution": Step In vào trong method được gọi, Step Over chạy trọn method, Step Out chạy nốt method hiện tại rồi quay về nơi gọi.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Menu Debug (hoặc phím tắt); chuỗi gọi phù hợp: handler client CreateSalesInvoice → CreateSalesInvoiceAtServer → NewCustomer / NewContract / FillProducts. Mở **Call stack** để thấy các tầng.
- **Gợi ý 3 — Khung bài làm:**
  1. Breakpoint ở handler client CreateSalesInvoice.
  2. Step In vào procedure server, Step In tiếp vào NewCustomer.
  3. Step Out để quay lại; ở dòng NewContract dùng Step Over.
- **Lỗi hay gặp:**
  - Step In tại dòng không gọi method → chỉ đi tiếp một dòng như Step Over.
  - Muốn evaluate biến client khi đỉnh stack ở server → row client màu xám, không evaluate được.
- **Tự kiểm tra:** Call stack lúc ở trong NewContract có 3 tầng (NewContract ← CreateSalesInvoiceAtServer ← CreateSalesInvoice).

### Bài tập 5 — Đổi giá trị biến khi debug (SendMessage)
- **Đề bài (tóm tắt):** Tạo common form FormForDebugTest (thuộc MasterData), command SendMessage có handler client với đoạn code đề cho; khi debug, đổi biến để điều kiện đúng, sau đó đổi lần nữa để message là "Number is two, not one!".
- **Gợi ý 1 — Hướng đi:** Mục "Variable value change": dùng **Set expression as a value** trong Expression window hoặc Local variables. Biến 1C có kiểu động, nên có thể gán cả giá trị kiểu khác.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Common form + form command `SendMessage` (Action `&AtClient`), kéo lên form thành button; chép đoạn code của đề vào handler. Evaluate expression (Shift+F9), nút f(x) Set.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo form, command, button, chép code đề cho.
  2. Breakpoint ở dòng `If`; khi dừng, gán giá trị khiến điều kiện đúng.
  3. Step Over vào nhánh trong; khi đứng ở dòng `Message`, gán lại biến thành chuỗi phù hợp để message ra đúng câu của đề.
- **Lỗi hay gặp:**
  - Đổi giá trị **sau** khi dòng `If` đã chạy → không vào nhánh được nữa.
  - Gán số 2 lần thứ hai → message vẫn là "Number is 2".
  - Gán chuỗi không có khoảng trắng/dấu phẩy đúng → message lệch câu yêu cầu.
- **Tự kiểm tra:** Enterprise mode hiện đúng "Number is two, not one!".

### Bài tập 6 — Tìm lỗi trong CreateSalesInvoiceAtServer (Try/Except, ErrorInfo)
- **Đề bài (tóm tắt):** Thêm command CreateSalesInvoice (handler client gọi CreateSalesInvoiceAtServer), chép code đề cho vào form module, bấm nút → gặp lỗi chung chung; dùng debugger và Local variables để tìm nguyên nhân; thử evaluate `DetailErrorDescription(ErrorInfo())` trong khối Except.
- **Gợi ý 1 — Hướng đi:** Khối `Try ... Except` "nuốt" lỗi thật và `Raise` một thông báo chung, nên message trên màn hình không giúp gì. Dùng **Stop on Error** (dừng ngay tại dòng gây lỗi trước khi nhảy sang Except) hoặc Step Over từng dòng trong `Try`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Debug → Stop on errors; Expression window; Local variables; dòng comment gán `ErrorText` trong khối Except của code đề cho.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo command + handler client gọi procedure server; chép 4 method của đề.
  2. Bật Stop on Error, bấm nút → ghi lại dòng debugger dừng và nội dung lỗi.
  3. Đối chiếu với object module của SalesInvoice: method được gọi ở dòng đó có tồn tại không?
  4. Thử evaluate biểu thức lỗi trực tiếp trong Except, rồi bỏ comment dòng gán vào biến và xem lại.
  5. Sửa lỗi theo cách hợp lý (bỏ lời gọi không hợp lệ hoặc tự viết method còn thiếu).
- **Lỗi hay gặp:**
  - Chỉ đọc message "An error occurred while creating the document" và đoán mò.
  - Evaluate `DetailErrorDescription(ErrorInfo())` trực tiếp → rỗng; theo đề, `ErrorInfo()` chỉ cho kết quả khi gán vào biến.
  - Evaluate expression chạy trên hệ thống thật → có thể tạo thêm dữ liệu (ví dụ Counterparty) ngoài ý muốn.
  - [ghi chú ngoài nguồn] Ngay cả khi hết lỗi, procedure của đề không gọi ghi document, nên chứng từ không xuất hiện trong danh sách; chỉ Customer và Contract mới được ghi. Đề không yêu cầu ghi chứng từ, nhưng hãy nhận ra điều này khi debug.
- **Tự kiểm tra:** Sau khi sửa, bấm nút không còn lỗi; trong Local variables của CreateSalesInvoiceAtServer thấy `Document` có 3 dòng Products; danh sách Counterparties có thêm item mới (không tên).

### Bài tập 7 — Performance snapshot
- **Đề bài (tóm tắt):** Sau khi sửa lỗi, đo hiệu năng từ handler command client; sort theo các cột; chuyển qua lại giữa cửa sổ kết quả và module bằng double-click.
- **Gợi ý 1 — Hướng đi:** Mục "Performance snapshot" và "Measurement results": số lần gọi, thời gian, client/server, dòng gây server call.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Debug → Performance meter / Performance Snapshot; bật **Track execution for procedures and functions**; checkbox Client/Server; click header để sort.
- **Gợi ý 3 — Khung bài làm:**
  1. Bật đo, bấm nút CreateSalesInvoice, tắt đo.
  2. Sort theo Col. (số lần gọi) và theo Time.
  3. Double-click một dòng kết quả → nhảy vào module; double-click cột kết quả trong module → quay lại.
- **Lỗi hay gặp:**
  - Tắt Track execution → thời gian dòng có gọi method không phản ánh thực tế.
  - So sánh hai lần đo trong điều kiện khác nhau; nên đo vài lần và lấy trung bình.
- **Tự kiểm tra:** Dòng trong vòng `While` của FillProducts có số lần gọi bằng số product được thêm; dòng handler client gọi procedure server được đánh dấu là server call.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/08-theory)

> So với lesson/07-theory, nhánh lesson/08-theory chỉ thêm một đoạn code vào form module của SalesInvoice: tính Amount của dòng ở client và tính tổng trọng lượng ở server. Đây chính là code được debug trong các ảnh chụp của Bài 8 (call stack `Document.SalesInvoice.Form.DocumentForm.CalculateWeightAtServer()`, biến `TotalWeight`).

### Client: tính Amount của dòng hiện tại
Nguồn: nhánh lesson/08-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	FillAmountInProductsRow();
	OnProductOrQuantityChange();
	
EndProcedure

&AtClient
Procedure ProductsPriceOnChange(Item)
	FillAmountInProductsRow();
EndProcedure

&AtClient
Procedure FillAmountInProductsRow()

	CurrentData = Items.Products.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Amount = CurrentData.Price * CurrentData.Quantity;
	
EndProcedure
```
- Đặt breakpoint ở dòng `CurrentData.Amount = ...`, mở **Evaluate expression** (Shift+F9) để xem `CurrentData.Price`, `CurrentData.Quantity`; có thể dùng **Set expression as a value** để đổi giá trị trước khi dòng chạy.
- `ProductsQuantityOnChange` gọi hai procedure liên tiếp → chỗ luyện **Step In** (vào `FillAmountInProductsRow`) và **Step Over** (chạy trọn).
- Toàn bộ đoạn này chạy ở client (`&AtClient`) — trong kết quả Performance snapshot các dòng này được đánh dấu cột **Client**.

### Client → server: CalculateWeightAtServer và WeightOfProduct (call stack, Local variables)
Nguồn: nhánh lesson/08-theory — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure ProductsProductOnChange(Item)
	OnProductOrQuantityChange();
EndProcedure

&AtClient
Procedure OnProductOrQuantityChange()

	CalculateWeightAtServer();

EndProcedure

&AtServer
Procedure CalculateWeightAtServer()

	TotalWeight = 0;
	For Each ProductsRow In Object.Products Do
	
		TotalWeight = TotalWeight + WeightOfProduct(ProductsRow.Product) * ProductsRow.Quantity;
	
	EndDo;

EndProcedure

&AtServerNoContext
Function WeightOfProduct(Product)

	Return Product.Weight;

EndFunction
```
- Dừng trong `WeightOfProduct` rồi mở **Call stack**: đỉnh stack là `WeightOfProduct`, bên dưới là `CalculateWeightAtServer` (server), rồi `OnProductOrQuantityChange` và `ProductsProductOnChange`/`ProductsQuantityOnChange` (client) — các row client hiện màu **xám**, chuyển tới dòng được nhưng không evaluate được biểu thức.
- `TotalWeight` là biến local của `CalculateWeightAtServer`: double-click row đó trong Call stack mới evaluate được; ở context `WeightOfProduct` biến này "not defined" — đúng ví dụ trong bài.
- **Local variables** của `CalculateWeightAtServer` hiển thị `TotalWeight` và `ProductsRow`; đặt **Breakpoint with the condition** trong vòng `For Each` (ví dụ `ProductsRow.Quantity > 10`) để chỉ dừng ở dòng cần xem.
- Performance snapshot: dòng `CalculateWeightAtServer();` trong `OnProductOrQuantityChange` là **Direct server call**; dòng gọi `OnProductOrQuantityChange()` trong handler là **Nested server call**. `WeightOfProduct` được gọi từ server nên không tạo thêm server call.
- [ghi chú ngoài nguồn] `TotalWeight` chỉ là biến local, không được ghi vào attribute nào — code demo phục vụ debug, không phải nghiệp vụ hoàn chỉnh.

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

Không có video bài giảng tương ứng — chỉ dẫn tài liệu Theory/Practice của bài.

<!-- video-qa-thuchanh:start -->

Video giải đáp tình huống thực chiến và video thực hành từng bước liên quan tới bài này (thẻ chi tiết, triệu chứng, lưu ý khi giới thiệu: `references/video-qa-thuc-chien.md`, `references/video-thuc-hanh.md`; cùng mẫu câu dẫn ở trên):

- [Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng](https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1) (4:24) — cách tìm lỗi sự kiện OnChange không chạy (giải đáp tình huống; Bài 8 liên quan) _(mã nội bộ QA-1)_

<!-- video-qa-thuchanh:end -->
