# Review và tư vấn code 1C — bộ quy tắc rút từ mã nguồn thật

> **Khi nào đọc file này:** người dùng dán code nhờ xem / sửa / tối ưu, hỏi "code này viết vậy được chưa", "có cách nào tốt hơn", hoặc nhờ tư vấn cách viết một kỹ thuật. Đọc cùng `chinh-sach-code.md` (được đưa code tới mức nào) và `code-patterns.md` (mẫu cấu trúc đầy đủ). Lỗi đã biết trong code mẫu của khóa và ERP_Practice: `code-review/loi-da-biet.md`. Chuẩn chính thức của 1C để dẫn chứng (#stdNNN): `code-review/chuan-phat-trien.md`. Code cú pháp tiếng Nga: `code-review/thuat-ngu-ru-en.md`. Tên API SSL tiếng Anh: `code-review/ssl-api-en.md`.
>
> Các quy tắc dưới đây rút từ việc đọc toàn bộ mã nguồn các repo của khóa (45 nhánh `1CJDCourse`, `ERP_Practice`, các bài làm thật của thực tập sinh) — mỗi quy tắc là một lỗi **đã thực sự xuất hiện** ở đó. Ví dụ viết trên đề trung tính "cấp phát vật tư cho công trình" của `code-patterns.md` mục 3, **không** phải lời giải bài thực hành. Mọi đoạn sửa là **code minh họa — chạy thử để kiểm chứng**.

## 1. Quy trình review

1. **Phân loại** theo `chinh-sach-code.md` mục 2. Nếu code là bài THỰC HÀNH (24 bài, Extensions, Intern Task, Partner Exam): chỉ nêu **vùng** và **mã quy tắc** (ví dụ "dòng 40–55 vi phạm P3 — đọc lại mục đó"), không đưa dòng sửa.
2. **Hỏi thiếu gì thì hỏi một lần:** tên module (object / manager / form / common), metadata liên quan (dimension, resource, thuộc tính `Delete records`, `Write register records on posting`), chế độ khóa của cấu hình (Managed / Automatic), có SSL không. Nhiều lỗi ở mục 2 chỉ kết luận được khi biết metadata.
3. **Đọc theo thứ tự** (giống `code-patterns.md` mục 2): đúng / sai về nghiệp vụ và dữ liệu → đặt đúng chỗ (module, handler, directive) → đồng thời và khóa → hiệu năng → chuẩn và trình bày.
4. **Trả lời theo bảng** `Vị trí | Mã quy tắc | Vấn đề | Vì sao | Sửa`, lỗi nặng trước. Tối đa 5–7 dòng; phần nhỏ gộp thành một câu "dọn dẹp".
5. **Kết thúc bằng cách tự kiểm**: kịch bản nhập liệu ngắn, xem Register records / Query console / Event log (`debug/giao-thuc-debug.md`).

Mức độ: **Nặng** = sai số liệu kho, tiền, sổ sách hoặc lỗi runtime trên luồng chính · **Vừa** = sai trong tình huống biên, hiệu năng đáng kể, đồng thời · **Nhẹ** = chuẩn, đặt tên, dọn dẹp.

## 2. Bộ quy tắc

### P — Posting và register (Bài 11, 12, 15, 16, 24)

**P1 · Nặng · Dấu và RecordType.** Xuất kho là `Expense` (hoặc `AddExpense()`), nhập là `Receipt`. Chứng từ đảo / trả lại: chọn **một** quy ước và dùng nhất quán — hoặc RecordType ngược lại với số dương, hoặc cùng RecordType với số âm (storno). Register Turnovers (doanh thu) của chứng từ trả lại phải mang số **âm**. Lỗi thật đã gặp: bán hàng ghi `Receipt` (tồn tăng khi bán); trả hàng cộng thêm doanh thu; hai nhánh của cùng một procedure dùng hai quy ước dấu khác nhau.

**P2 · Nặng · Movement cũ khi post lại.** Kiểm tra thuộc tính `Delete records` của document. Với `Delete automatically on unposting` và `Write selected`, procedure `Posting` nào có nhánh `Return` sớm (ví dụ "trạng thái Kế hoạch thì không ghi") sẽ để lại movement cũ khi post lại.
```bsl
// Cách 1: Designer → document → Delete records = Delete automatically (xóa mỗi lần post lại)
// Cách 2: luôn bật Write = True trước khi Return — record set rỗng sẽ được ghi, tức là xóa movement cũ
RegisterRecords.MaterialsInStock.Write = True;
RegisterRecords.MaterialsAtSites.Write = True;
If Not MustPost Then
	Return;
EndIf;
```

**P3 · Nặng · Biên thời điểm khi đọc số dư.**
- **Phân bổ** (FIFO / LIFO / bình quân) — đọc **trước** khi ghi: `Balance(&PointInTime, ...)` với `PointInTime()` hoặc `New Boundary(PointInTime(), BoundaryType.Excluding)`, và movement cũ của chính chứng từ phải đã bị xóa (P2, hoặc ghi record set rỗng trước khi đọc).
- **Kiểm tra âm** — ghi **trước** rồi đọc: `RegisterRecords.X.Write()` → `Balance(New Boundary(PointInTime(), BoundaryType.Including), ...) WHERE QuantityBalance < 0`.
- Không truyền ngày (`Balance(, ...)`) = số dư **hiện tại**: post lại chứng từ quá khứ sẽ tính trên số dư hôm nay (lỗi thật trong ERP_Practice).
- Procedure kiểm tra viết xong phải **được gọi** (lỗi thật: procedure kiểm tra tồn có sẵn nhưng `Posting` không gọi).

**P4 · Nặng · Phân bổ theo lô: chỉ lấy lô còn dương, xử lý dòng không có tồn.**
```bsl
|	LEFT JOIN AccumulationRegister.MaterialsInStock.Balance(&PointInTime,
|			Material IN (SELECT T.Material FROM Lines AS T) AND Warehouse = &Warehouse) AS Stock
|	ON Lines.Material = Stock.Material
|		AND Stock.QuantityBalance > 0          // lô âm / bằng 0 không được phân bổ
...
Take = Min(Left, Selection.QuantityBalance);
If Take <= 0 Then
	Continue;                                   // không ghi record số lượng 0, lô rỗng
EndIf;
```
Sắp xếp lô theo `Batch.PointInTime` (không chỉ `Batch.Date` — hai chứng từ cùng giây cho thứ tự không xác định). Còn thiếu sau vòng lặp (`Left > 0`) → báo lỗi + `Cancel = True`.

**P5 · Vừa · Lấy hết lô thì lấy hết tiền.** Giá vốn = `AmountBalance / QuantityBalance` rồi nhân lại sẽ để dư tiền lẻ ở lô đã hết hàng.
```bsl
If Take = Selection.QuantityBalance Then
	Record.Amount = Selection.AmountBalance;
Else
	Record.Amount = Round(Selection.AmountBalance * Take / Selection.QuantityBalance, 2);
EndIf;
```
Chia trong query phải chặn 0: `CASE WHEN QuantityBalance = 0 THEN 0 ELSE AmountBalance / QuantityBalance END`.

**P6 · Vừa · Khóa dữ liệu (Managed lock mode).** Đọc số dư để phân bổ hoặc kiểm tra mà không khóa → hai phiên post cùng lúc đọc cùng một số dư. `LockForUpdate` trên record set rỗng chỉ chắc chắn khóa theo Recorder của chính chứng từ; chuẩn là `DataLock` tường minh **trước** query đọc số dư:
```bsl
Lock = New DataLock;
Item = Lock.Add("AccumulationRegister.MaterialsInStock");
Item.Mode = DataLockMode.Exclusive;
Item.SetValue("Warehouse", Warehouse);
Item.DataSource = Lines;                       // tabular section hoặc ValueTable
Item.UseFromDataSource("Material", "Material");
Lock.Lock();
```

**P7 · Vừa · Đủ dimension, đúng resource.** Mỗi record ghi đủ mọi dimension (thiếu một dimension = số dư lệch sang "giá trị rỗng"). Resource của register **Balances** là thứ cộng dồn được (số lượng, **giá trị**) — không ghi đơn giá, số km, trạng thái vào đó. Ghi một thuộc tính (Company, Site…) cho **mọi** nhánh / mọi tabular section, không chỉ một bảng.

**P8 · Vừa · Lọc trong tham số virtual table, không trong WHERE.** `Balance(&Date, Material IN (&List) AND Warehouse = &Warehouse)` thay vì đọc cả register rồi `WHERE` hoặc lặp tìm bằng code. `SliceLast(&Date, Material = &Material)` — luôn truyền ngày chứng từ (không truyền = giá hiện tại cho chứng từ quá khứ). `Turnovers(&Begin, &End, , ...)`: để trống periodicity khi cần **tổng** — periodicity `Period` / `Recorder` trả **nhiều dòng** mỗi mặt hàng, gán vào một ô thì chỉ giữ dòng cuối (lỗi thật).

**P9 · Vừa · Đọc movement của một chứng từ cụ thể:** đọc **bảng vật lý** của register theo `Recorder = &Doc` (có index), không dùng `Turnovers(...)` cả ngày rồi lọc Recorder. Kiểm tra chứng từ gốc đã điền trước khi dereference `Doc.Date`.

**P10 · Nhẹ · Sửa tay trong khối wizard.** Code đã sửa tay nằm giữa `//{{__REGISTER_REGISTERRECORDS_WIZARD` … `//}}` sẽ mất khi chạy lại wizard. Sửa tay thì xóa marker.

### Q — Query và hiệu năng (Bài 10, 11, 19)

**Q1 · Vừa · Không query trong vòng lặp** — kể cả query ẩn: `Catalogs.X.FindByDescription`, `FindByCode`, dereference `Row.Material.Group.Description` (mỗi lần đọc cả object), `Ref.Attribute` để lấy giá trị cũ trong `BeforeWrite`. Gom về một query `IN (&List)` rồi tra bằng `Map`:
```bsl
Query = New Query("SELECT M.Description AS Description, M.Ref AS Ref
	|FROM Catalog.Materials AS M WHERE M.Description IN (&Names) AND NOT M.DeletionMark");
Query.SetParameter("Names", Names);
RefsByName = New Map;
Selection = Query.Execute().Select();
While Selection.Next() Do
	RefsByName.Insert(Selection.Description, Selection.Ref);
EndDo;
```
Ngoại lệ hợp lý: `GetObject()` trong vòng lặp khi **phải** sửa và ghi từng object — khi đó bọc transaction và xử lý lỗi từng object (T1).

**Q2 · Vừa · Tabular section làm nguồn bảng của query:** truyền `.Unload(, "Cột1, Cột2")` (ValueTable), ép kiểu trong query: `CAST(T.Material AS Catalog.Materials)`. Dùng temp table khi một tập dòng được dùng nhiều lần.

**Q3 · Vừa · Duyệt theo nhóm cần `TOTALS ... BY`** và `Select(QueryResultIteration.ByGroups)`; không có TOTALS thì `Select()` của cấp con rỗng.

**Q4 · Nhẹ · `ExecuteBatch()` + `FindNext(Filter)` / `Reset()`** để tra nhiều lần trên cùng một kết quả thay vì chạy lại query.

**Q5 · Vừa · Trong in ấn / báo cáo:** lấy mọi thứ cần in (kể cả logo, thông tin công ty) trong **query chính** hoặc cache `Map` theo khóa; `Template.GetArea(...)` đặt **ngoài** vòng lặp chứng từ; `ORDER BY` để in đúng thứ tự.

### F — Form và client/server (Bài 7, 9, 10, 16)

**F1 · Vừa · Tính ở client, lấy dữ liệu ở server một lần.** Thành tiền, tổng chứng từ (`Object.Lines.Total("Amount")`) tính ở client. Đổi một dòng cần giá + giá sàn → **một** hàm `&AtServerNoContext` trả `Structure`, không hai lần gọi. Không gọi `&AtServer` (kèm cả form) chỉ để đọc một thuộc tính.

**F2 · Nặng · `BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)`: ghi vào `CurrentObject`**, không vào `Object` — giá trị gán vào `Object` lúc này không được lưu (lỗi thật: địa chỉ giao hàng không bao giờ được ghi).

**F3 · Vừa · Thêm dòng bằng code không gọi `OnChange` của bảng** → tự gọi lại tính dòng và tính tổng sau `Add()` trong `ChoiceProcessing` / nút Fill.

**F4 · Vừa · Tên tham số `OpenForm` là chuỗi** — viết sai (`CloseOnChoise`) không có lỗi biên dịch, chỉ bị bỏ qua lặng lẽ. Chọn **một** kênh trả kết quả: owner + `ChoiceProcessing`, **hoặc** `CallbackDescription`. Tham số `Filter` của form chọn chỉ áp lên **trường** của danh sách; giá trị dùng làm tham số query của dynamic list thì truyền qua `Parameters` của form rồi `List.Parameters.SetParameterValue(...)`.

**F5 · Nặng · Handler mồ côi.** Xóa procedure trong module nhưng event vẫn gán trong form (Properties → Events) → lỗi khi event xảy ra, và mất luôn logic đáng lẽ chạy (ví dụ kiểm tra giá sàn khi sửa giá tay). Ngược lại: viết handler nhưng quên gán event → code không bao giờ chạy. Kiểm bằng *Configuration → Check* hoặc rà tab Events.

**F6 · Nặng · Không gọi modal khi cấu hình đặt `Modality use mode = Do not use`:** `DoMessageBox`, `DoQueryBox`, `OpenFormModal`, `InputValue`, `Предупреждение`, `Вопрос`… → dùng `ShowMessageBox`, `ShowQueryBox`, `ShowInputValue` + `CallbackDescription`. Có nhánh không cần hỏi thì `RunCallback(Callback, DialogReturnCode.Yes)` để chỉ còn một luồng xử lý.

**F7 · Vừa · Không gọi server trong `OnOpen`** — tính trong `OnCreateAtServer` / `OnReadAtServer`. Trên client không có `CurrentSessionDate()`; truyền ngày từ server hoặc dùng `CommonClient.SessionDate()` (SSL).

**F8 · Nhẹ · `OnActivateRow` đổi tham số danh sách con:** dùng `AttachIdleHandler("UpdateDetails", 0.2, True)` để không query mỗi lần nhấn mũi tên; kiểm `CurrentData = Undefined`.

**F9 · Nhẹ · Ghi giá trị trước khi xóa:** lưu giá trị cần báo vào biến **trước** khi `CurrentData.X = Undefined`, nếu không thông báo luôn rỗng.

### V — Kiểm tra dữ liệu và thông báo (Bài 12, 15, 16)

**V1 · Nặng · `FillCheckProcessing`: báo lỗi phải kèm `Cancel = True`;** không gọi `CheckFilling()` bên trong (đệ quy). Bỏ kiểm tra có điều kiện bằng cách xóa khỏi `CheckedAttributes` (`DeleteAttributeFromChecking` của SSL, hoặc `CheckedAttributes.Delete(...)`).

**V2 · Vừa · Thông báo gắn ô:** `New UserMessage` + `Field` (`"Lines[" + Format(Index, "NZ=0; NG=0") + "].Quantity"`) + `SetData(ThisObject)`; với SSL dùng `Common.MessageToUser` / `CommonClient.MessageToUser`. `Message()` chỉ chấp nhận trong demo, debug.

**V3 · Vừa · Kiểm tra cặp trường:** chỉ so khi cả hai đã điền (`If ValueIsFilled(A) And A = B`), nếu không người dùng nhận thông báo "trùng" khi thực ra là "chưa điền".

**V4 · Vừa · `Filling` / event subscription không ghi đè:** `If Not ValueIsFilled(Source.Company) Then ... EndIf` — giá trị từ `FillingValues` hoặc chứng từ cơ sở phải được giữ. Chữ ký chuẩn: `Filling(FillingData, FillingText, StandardProcessing)`; `FillingData` của Generation đã là Ref (không `.Ref`).

**V5 · Vừa · `BeforeWrite` / `OnWrite`:** kiểm `DataExchange.Load` ở đầu (`If DataExchange.Load Then Return; EndIf;`); truyền trạng thái "mới" / giá trị cũ sang `OnWrite` / `Posting` bằng `AdditionalProperties` (lúc đó `IsNew()` đã là False). Giá trị cũ đọc bằng một query một trường, không `Ref.Attribute`.

### T — Transaction, lỗi, log (Bài 8, 12)

**T1 · Nặng · Mẫu transaction chuẩn:**
```bsl
BeginTransaction();
Try
	// khóa (DataLock) → đọc → ghi các object
	CommitTransaction();
Except
	RollbackTransaction();
	WriteLogEvent("MyApp.Import", EventLogLevel.Error, , ,
		ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	Raise;                                   // ném lại lỗi GỐC, không Raise "chuỗi mới"
EndTry;
```
Lỗi thật đã gặp: thiếu `RollbackTransaction` trên một nhánh; `Raise "Có lỗi"` làm mất lỗi gốc; commit khi object chính chưa `Write()`; tạo nhiều chứng từ / record set không transaction → chạy giữa chừng lỗi để lại dữ liệu nửa vời; chạy lại tạo trùng (cần tìm và dùng lại kết quả cũ).

**T2 · Vừa · `Except` không được im lặng:** log + báo người dùng (hoặc `Raise`). Trong `Posting` / `FillCheckProcessing` dùng `Cancel = True` + thông báo thay vì `Raise`.

**T3 · Vừa · Hàm "không được ném exception"** (theo đề / hợp đồng hàm) phải `Return` ngay khi tham số sai, và trả đúng kiểu đã hứa (chuỗi lỗi, không Structure).

### X — File, Excel, external (Bài 19, 21–23)

**X1 · Vừa · Địa chỉ ô bằng số:** `Spreadsheet.Area(Row, Col, Row, Col)` hoặc `"R" + Format(Row, "NG=0") + "C" + Format(Col, "NG=0")`. `"R" + Row` sai từ dòng 1000 (thành `R1 000C2` / `R1,000C2` tùy locale).

**X2 · Vừa · Đọc giá trị số bằng `.Value`** (đọc file ở chế độ `SpreadsheetDocumentValuesReadingMode.Value`), không `.Text` (chuỗi đã định dạng); kiểm `TypeOf(Value) = Type("Number")` trước khi ghi vào trường số. So tiêu đề cột không phân biệt hoa thường: `Upper(TrimAll(...))`.

**X3 · Vừa · File từ máy người dùng:** `BeginPutFileToServer` / `PutFileToServerAsync` → temp storage → server đọc từ `GetFromTempStorage`. Không đọc đường dẫn client ở server; `New BinaryData(FileName)` ở client không chạy trên web client. Xóa file tạm trong `Try`.

**X4 · Vừa · In SSL:** `PrintCommand.ID` khớp tên trong `Print()`; `PrintManagement.PrintFormTemplate("Document.X.PF_MXL_Name")` / `"CommonTemplate.Name"`; `PutHorizontalPageBreak` từ chứng từ thứ 2; `PrintManagement.SetDocumentPrintArea` sau mỗi chứng từ; lọc query theo `ObjectsArray` (lỗi thật: in mọi chứng từ). Kiểm chữ ký `OutputSpreadsheetDocumentToCollection` theo đúng phiên bản SSL đang dùng.

**X5 · Nhẹ · Nội dung SSL:** sửa trong module `...Overridable` / khối `// StandardSubsystems.*`, không sửa module lõi; module có `Common.SubsystemExists(...)` ở một chỗ thì mọi chỗ gọi subsystem đó cũng phải kiểm.

### E — Extension (Bài Extensions)

**E1 · Vừa · `&Around` không gọi `ProceedWithCall()` = thay thế toàn bộ** procedure gốc; khi nhà cung cấp cập nhật, extension vẫn chạy bản cũ mà không báo. Chỉ thêm / bớt vài dòng → `&ChangeAndValidate` + `#Insert` / `#Delete` (platform báo khi gốc thay đổi).

**E2 · Nhẹ · Prefix** cho mọi procedure, attribute, form item thêm mới (`ext1_...`); tên field tham chiếu trong code phải tồn tại thật trên object (lỗi thật: điều kiện dùng cột `Count` không tồn tại → patch "sửa lỗi" gây lỗi runtime).

### M — Common module và cấu trúc (Bài 14, 23)

**M1 · Vừa · Cờ đúng ngữ cảnh:** Server (gọi từ posting / server) · Server call (client gọi được — chỉ export những gì client cần) · Client · Client+Server (thuần tính toán, không DB). Module scheduled job chỉ cần Server. Không dồn mọi hàm vào một module Server call.

**M2 · Nhẹ · Dọn dẹp:** handler rỗng còn gán event, stub `a = 1` trong `PresentationGetProcessing` (chạy mỗi lần hiển thị), `Message("On change")` debug, code chết, biến trùng tên hàm có sẵn (`Date`, `RefreshInterface`), magic number, typo trong tên metadata (đổi tên về sau rất tốn — sửa sớm). Chia `#Region Public / EventHandlers / Private`.

## 2b. Kiểm tra tự động — đối chiếu với công cụ phân tích tĩnh

Quy tắc ở mục 2 trùng phần lớn với chẩn đoán của **BSL Language Server** (`1c-syntax/bsl-language-server`, có tài liệu tiếng Anh cho ~190 chẩn đoán; dùng qua extension "Language 1C (BSL)" của VS Code, hoặc SonarQube) và các kiểm tra **1C:Code style V8** trong 1C:EDT (`1C-Company/v8-code-style`). Khi người dùng muốn tự kiểm tra hàng loạt, gợi ý chạy công cụ rồi mang kết quả lại để giải thích. Tên chẩn đoán dưới đây giúp tra nhanh:

| Quy tắc | BSL Language Server | 1C:Code style V8 (EDT) |
|---|---|---|
| P8 | `VirtualTableCallWithoutParameters`, `JoinWithVirtualTable` | — |
| Q1 | `CreateQueryInCycle`, `UsingFindElementByString`, `UnsafeFindByCode` | — |
| Q2–Q5 | `FieldsFromJoinsWithoutIsNull`, `SelectTopWithoutOrderBy`, `LogicalOrInJoinQuerySection`, `QueryParseError` | `ql-*` |
| F1 | `ServerCallsInFormEvents`, `TransferringParametersBetweenClientAndServer` | `form-module-pragma` |
| F5 | `WrongDataPathForFormElements`, `MissingEventSubscriptionHandler` | — |
| F6 | `UsingModalWindows`, `UsingSynchronousCalls` | — |
| V1 | `UsingCancelParameter` | — |
| V2 | `DeprecatedMessage` | — |
| V5 | `DataExchangeLoading` | `data-exchange-load` |
| T1 | `BeginTransactionBeforeTryCatch`, `CommitTransactionOutsideTryCatch`, `PairingBrokenTransaction`, `WrongUseOfRollbackTransactionMethod` | `begin-transaction`, `commit-transaction`, `lock-out-of-try` |
| T2 | `MissingCodeTryCatchEx`, `UsageWriteLogEvent` | `empty-except-statement` |
| X3 | `MissingTemporaryFileDeletion`, `MissingTempStorageDeletion`, `FileSystemAccess` | `missing-temporary-file-deletion` |
| E1–E2 | `WrongUseFunctionProceedWithCall`, `SuspiciousChangeAndValidate` | `change-and-validate-instead-of-around`, `extension-method-prefix` |
| M1 | `CompilationDirectiveLost`, `CompilationDirectiveNeedLess`, `CommonModuleNameServerCall`… | `form-module-missing-pragma` |
| M2 | `EmptyCodeBlock`, `CommentedCode`, `UnusedLocalMethod`, `MagicNumber`, `DeprecatedCurrentDate`, `UsingThisForm` | `module-empty-method` |

Công cụ **không** bắt được các lỗi nghiệp vụ nặng nhất ở mục 2 (dấu Receipt/Expense — P1, movement cũ khi post lại — P2, biên thời điểm — P3, lô âm — P4, ghi vào `Object` thay vì `CurrentObject` — F2): vẫn phải đọc code. Phần lớn chẩn đoán viết cho code cú pháp tiếng Nga nhưng chạy được cả với cú pháp tiếng Anh.

## 2c. Dấu hiệu code lỗi thời — nhắc người dùng khi gặp

Code chép từ diễn đàn, sách cũ hay repo cộng đồng thường mang các dấu hiệu dưới. Gặp thì nói rõ là cách cũ và chỉ cách hiện hành (chuẩn 1C ở `chuan-phat-trien.md`, đối chiếu cú pháp Nga ↔ Anh ở `thuat-ngu-ru-en.md`):

| Dấu hiệu | Vấn đề | Thay bằng |
|---|---|---|
| `DoMessageBox`, `DoQueryBox`, `OpenFormModal`, `.DoModal()`, `InputValue(...)`, `Предупреждение`, `Вопрос`, `ОткрытьФормуМодально` | Modal — lỗi khi *Modality use mode = Do not use*, không chạy ổn trên web client (#std703) | `ShowMessageBox`, `ShowQueryBox`, `OpenForm` + `CallbackDescription`, hoặc `Async` / `Await` |
| Form thường (ordinary form), `ЭтаФорма` / `ThisForm`, `ПолучитьФорму` / `GetForm` + `Open()` | Kiểu ứng dụng thường (8.1–8.2) | Managed form, `ThisObject`, `OpenForm` (#std404) |
| `Сообщить` / `Message` cho thông báo nghiệp vụ | Không gắn được ô, không chuẩn (#std418) | `UserMessage` / `Common.MessageToUser` |
| `ТекущаяДата()` / `CurrentDate()` | Giờ máy chủ / máy khách, không theo múi giờ phiên | `CurrentSessionDate()` |
| `FOR UPDATE` / `ДЛЯ ИЗМЕНЕНИЯ` trong query khi cấu hình dùng khóa managed | Không có tác dụng (#std460) | `DataLock` |
| Thư viện / công cụ cũ: xUnitFor1C, SSL 2.x (`ОбщегоНазначенияКлиентСервер.СообщитьПользователю` của bản cũ), lệnh `vrunner xunit` (vanessa-runner 2.x) | Dừng phát triển / đổi API | YAxUnit; SSL 3.x (`ssl-api-en.md`); vanessa-runner 3.x |
| `NotifyDescription` | Tên cũ, vẫn chạy | Bản platform mới dùng `CallbackDescription` — giữ đúng tên mà platform của người dùng có |

## 3. Mẫu trả lời review

```
**Tóm tắt:** 2 lỗi nặng (P1, F2), 1 lỗi vừa (Q1), vài điểm dọn dẹp.

| Vị trí | Quy tắc | Vấn đề | Vì sao | Sửa |
|---|---|---|---|---|
| Posting, dòng 18 | P1 | Ghi Receipt khi xuất | Tồn tăng khi bán | AddExpense() |
| ... | | | | |

**Bản sửa** (code minh họa — chạy thử để kiểm chứng): ...
**Tự kiểm:** post chứng từ → mở Register records → số lượng mang dấu ... ; post lại sau khi đổi ngày → ...
```
Với code bài THỰC HÀNH: giữ cột Vị trí, Quy tắc, Vấn đề, Vì sao; bỏ cột Sửa và phần Bản sửa.
