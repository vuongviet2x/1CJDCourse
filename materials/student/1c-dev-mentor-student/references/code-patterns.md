# Chuẩn code và mẫu cấu trúc thường dùng

> **Khi nào đọc file này:** khi viết code cho DỰ ÁN hoặc HỌC KỸ THUẬT (xem `chinh-sach-code.md`), và khi review code của người học. Không dùng các mẫu ở đây để trả lời bài thực hành của giáo trình.

## 1. Thứ tự ưu tiên nguồn code

1. **Code thật có dòng `Nguồn:`** trong file bài (`lessons/`), `erp-practice/erp-practice.md`, và — chỉ lộ trình J — các file `jet/`. Dùng trước, nói rõ lấy từ đâu.
2. **Các mẫu ở mục 4 dưới đây** — viết trên ví dụ trung tính "công ty xây dựng cấp phát vật tư cho công trình", để người học thấy cấu trúc rồi áp vào object của mình. Đây là **code minh họa — chạy thử để kiểm chứng**.
3. Code viết mới cho object của người học: theo chuẩn ở mục 2, gắn nhãn "code minh họa — chạy thử để kiểm chứng".

Khi áp mẫu vào dự án: đổi tên object theo đúng tên trong cấu hình của người học, và nhắc họ kiểm tra tên thật trong Designer (sai một chữ là lỗi "Object field not found").

## 2. Chuẩn code tối thiểu

| Chủ đề | Quy tắc | Bài liên quan |
|---|---|---|
| Directive | Mọi procedure trong form module có `&AtClient` / `&AtServer` / `&AtServerNoContext`; nói lý do chọn | Bài 7 |
| Ít server call | Gom việc cần server vào **một** lần gọi. Tính toán thuần (thành tiền = số lượng × đơn giá) làm ở client. Không cần dữ liệu form thì dùng `&AtServerNoContext` | Bài 7 |
| Đọc dữ liệu | Đọc bằng **query**, không duyệt object hay đi qua nhiều tầng reference (`Row.Product.Group.Owner…`) khi xử lý hàng loạt, nhất là khi posting | Bài 10, 11 |
| Query trong vòng lặp | **Không.** Gom điều kiện bằng `IN (&List)`, temp table, batch query | Bài 10 |
| Posting | Chỉ trong **object module** của Document, handler `Posting`; bật `RegisterRecords.<Tên>.Write = True` cho mỗi register được ghi | Bài 11 |
| Kiểm tra số dư | "Ghi rồi kiểm tra" hoặc "đọc rồi ghi" với `LockForUpdate`, đọc virtual table `.Balance` — xem mẫu 4.1 và `erp-practice.md` | Bài 11 |
| Kiểm tra nhập liệu | Thuộc tính Fill checking hoặc handler `FillCheckProcessing` (Bài 12). Không chỉ kiểm tra ở form | Bài 12 |
| Transaction | Mỗi `BeginTransaction()` có `CommitTransaction()` hoặc `RollbackTransaction()` tương ứng trên mọi nhánh | Bài 12 |
| Exception | Không bắt lỗi chỉ để im lặng. Bắt thì ghi `WriteLogEvent(..., ErrorProcessing.DetailErrorDescription(ErrorInfo()))` rồi báo người dùng hoặc `Raise`. Trong `Posting` / `FillCheckProcessing` dùng `Cancel = True` + thông báo | Bài 12 |
| Thông báo | `New UserMessage` (có `Field` khi chỉ vào ô cụ thể); không dùng `Message()` cho thông báo nghiệp vụ trong code mới | Bài 12 |
| Module dùng chung | Đặt cờ common module đúng (Server / Client / Server call / Privileged) và chỉ `Export` hàm cần gọi từ ngoài | Bài 14 |
| Bố cục module | Chia `#Region` (Public, Private, EventHandlers…); tên tiếng Anh PascalCase giống metadata | Bài 23 |
| Sửa cấu hình có sẵn (Jet, giải pháp nhà cung cấp) | Cân nhắc Extension trước khi sửa trực tiếp; nói rủi ro khi cập nhật | Bài Extensions, `jet/jet-extending.md` |

Review code của người học theo đúng thứ tự: logic đúng/sai → đặt đúng chỗ (module, directive) → hiệu năng (query trong vòng lặp, server call) → đặt tên và trình bày. Bộ quy tắc review chi tiết có mã (P1…M2), ví dụ sai/đúng và mẫu trả lời: `code-review/review-code.md`.

## 3. Ví dụ trung tính dùng cho các mẫu

Công ty xây dựng cấp phát vật tư từ kho cho các công trình, công trình trả lại vật tư thừa; giá trị vật tư tính theo đơn giá kế hoạch có hiệu lực tại ngày cấp.

| Object | Loại | Cấu trúc chính |
|---|---|---|
| `Materials` | Catalog | — |
| `Warehouses`, `ConstructionSites` | Catalog | — |
| `PlannedCosts` | Information register, periodic (Day) | Dimension `Material` · Resource `UnitCost` |
| `MaterialIssue` | Document | `Warehouse`, `Site`, `RequiredDate`; tabular section `Lines` (`Material`, `Quantity`, `UnitCost`, `Amount`) |
| `MaterialsInStock` | Accumulation register, Balances | Dimension `Warehouse`, `Material` · Resource `Quantity` |
| `MaterialsAtSites` | Accumulation register, Balances | Dimension `Site`, `Material` · Resource `Quantity` |

## 4. Mẫu cấu trúc

### 4.1. Posting ghi hai register + chặn cấp quá tồn

Đặt ở: Document `MaterialIssue` → Object module → handler `Posting` (Designer: tab Register records tick hai register, hoặc dùng Register records wizard rồi sửa).

```bsl
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Posting(Cancel, PostingMode)

	RegisterRecords.MaterialsInStock.Write = True;
	RegisterRecords.MaterialsAtSites.Write = True;

	For Each Row In Lines Do
		// Kho giảm
		Record = RegisterRecords.MaterialsInStock.AddExpense();
		Record.Period = Date;
		Record.Warehouse = Warehouse;
		Record.Material = Row.Material;
		Record.Quantity = Row.Quantity;
		// Vật tư đang ở công trình tăng
		Record = RegisterRecords.MaterialsAtSites.AddReceipt();
		Record.Period = Date;
		Record.Site = Site;
		Record.Material = Row.Material;
		Record.Quantity = Row.Quantity;
	EndDo;

	// Chỉ kiểm tra tồn khi post theo thời gian thực (không kiểm tra khi post lùi ngày)
	If PostingMode = DocumentPostingMode.RealTime Then
		RegisterRecords.MaterialsInStock.LockForUpdate = True;
		RegisterRecords.MaterialsInStock.Write(); // ghi trước, rồi kiểm tra số dư sau khi ghi
		CheckStockShortage(Cancel);
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure CheckStockShortage(Cancel)

	Query = New Query;
	Query.Text =
	"SELECT
	|	Stock.Material AS Material,
	|	Stock.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.MaterialsInStock.Balance(
	|			,
	|			Warehouse = &Warehouse
	|				AND Material IN (&MaterialList)) AS Stock
	|WHERE
	|	Stock.QuantityBalance < 0";
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("MaterialList", Lines.UnloadColumn("Material"));

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Message = New UserMessage;
		Message.Text = StrTemplate("Không đủ %1 trong kho, thiếu %2", Selection.Material, -Selection.QuantityBalance);
		Message.Message();
		Cancel = True;
	EndDo;

EndProcedure

#EndRegion

#EndIf
```

Ý cần giải thích: `AddExpense` / `AddReceipt` là chiều tăng giảm; `Write = True` để platform ghi khi kết thúc posting; `LockForUpdate` + `Write()` để hai người không cùng xuất vượt tồn; một query cho cả danh sách (không query trong vòng lặp); `Cancel = True` hủy toàn bộ posting. So sánh với cách "đọc số dư trước rồi ghi" có giá vốn trong `erp-practice.md`. Kiểm tra: nhập tồn 10 → cấp 12 phải bị chặn và báo thiếu 2; cấp 8 → Register records của chứng từ có hai dòng, báo cáo tồn còn 2.

### 4.2. Form: tính ở client, lấy giá ở server một lần

Đặt ở: form của document `MaterialIssue`, form module. Bảng `Lines` trên form; handler tạo từ hai cột Material và Quantity của bảng (Properties → Events → OnChange).

```bsl
&AtClient
Procedure LinesMaterialOnChange(Item)
	Row = Items.Lines.CurrentData;
	Row.UnitCost = GetUnitCost(Row.Material, Object.Date); // một server call
	CalculateRowAmount(Row);
EndProcedure

&AtClient
Procedure LinesQuantityOnChange(Item)
	CalculateRowAmount(Items.Lines.CurrentData); // không cần server
EndProcedure

&AtClient
Procedure CalculateRowAmount(Row)
	Row.Amount = Row.Quantity * Row.UnitCost;
EndProcedure

&AtServerNoContext
Function GetUnitCost(Material, OnDate)
	Query = New Query;
	Query.Text =
	"SELECT
	|	Rates.UnitCost AS UnitCost
	|FROM
	|	InformationRegister.PlannedCosts.SliceLast(&OnDate, Material = &Material) AS Rates";
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("Material", Material);
	Selection = Query.Execute().Select();
	Return ?(Selection.Next(), Selection.UnitCost, 0);
EndFunction
```

Ý cần giải thích: tên handler do Designer sinh theo tên bảng + tên cột; `Items` trong form module là tập phần tử của form (không phải tabular section) — đặt tên tabular section là `Items` sẽ rất dễ nhầm; `&AtServerNoContext` vì chỉ cần hai tham số, không cần dữ liệu form; `SliceLast` lấy đơn giá có hiệu lực tại ngày chứng từ (Bài 12).

### 4.3. Kiểm tra dữ liệu khi ghi

Đặt ở: object module, handler `FillCheckProcessing`.

```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If ValueIsFilled(RequiredDate) And RequiredDate < BegOfDay(Date) Then
		Message = New UserMessage;
		Message.Text = "Ngày cần vật tư không được trước ngày cấp";
		Message.Field = "RequiredDate";
		Message.SetData(ThisObject);
		Message.Message();
		Cancel = True;
	EndIf;
EndProcedure
```

Quy tắc chọn chỗ: ràng buộc chỉ cần dữ liệu của chính chứng từ → `FillCheckProcessing`; ràng buộc phụ thuộc số dư thật (tồn, công nợ, hạn mức) → `Posting`; tiện ích nhập liệu (tự điền giá) → form.

### 4.4. Tạo chứng từ dựa trên chứng từ khác (Generation)

Đặt ở: document `MaterialReturn` → property **Based on** chọn `MaterialIssue` (và `MaterialIssue` → Generation) → object module handler `Filling` (có thể sinh khung bằng Filling wizard, Bài 11).

```bsl
Procedure Filling(FillingData, FillingText, StandardProcessing)
	If TypeOf(FillingData) <> Type("DocumentRef.MaterialIssue") Then
		Return;
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT
	|	Issue.Warehouse AS Warehouse,
	|	Issue.Site AS Site
	|FROM
	|	Document.MaterialIssue AS Issue
	|WHERE
	|	Issue.Ref = &Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IssueItems.Material AS Material,
	|	IssueItems.Quantity AS Quantity
	|FROM
	|	Document.MaterialIssue.Lines AS IssueItems
	|WHERE
	|	IssueItems.Ref = &Ref";
	Query.SetParameter("Ref", FillingData);
	Results = Query.ExecuteBatch();
	Header = Results[0].Select();
	If Header.Next() Then
		FillPropertyValues(ThisObject, Header);
	EndIf;
	BaseIssue = FillingData;
	Lines.Load(Results[1].Unload());
EndProcedure
```

Ý cần giải thích: batch query (hai query một lần gọi); `FillPropertyValues` chép các cột cùng tên; `BaseIssue` là attribute giả định để giữ liên kết với chứng từ gốc; `Lines.Load` nạp bảng giá trị vào tabular section có cột cùng tên.

### 4.5. Common module

Module `MaterialsServer`, cờ: **Server** + **Server call** (để form gọi được từ client). Không bật Client.

```bsl
#Region Public

// Đơn giá kế hoạch có hiệu lực tại OnDate. Gọi được từ client vì module bật Server call.
Function PlannedUnitCost(Material, OnDate) Export
	Query = New Query;
	Query.Text =
	"SELECT
	|	Rates.UnitCost AS UnitCost
	|FROM
	|	InformationRegister.PlannedCosts.SliceLast(&OnDate, Material = &Material) AS Rates";
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("Material", Material);
	Selection = Query.Execute().Select();
	Return ?(Selection.Next(), Selection.UnitCost, 0);
EndFunction

#EndRegion
```

Khi nào tách ra common module: logic dùng ở nhiều form / nhiều chứng từ. Cân nhắc **Reuse return values** cho dữ liệu ít đổi trong phiên (Bài 14).

### 4.6. Báo cáo, in ấn, data processor

Phần lớn là khai báo, ít code — dẫn về bài học thay vì viết mẫu mới:
- Báo cáo DCS: data set kiểu Query đọc virtual table (`.Balance`, `.Turnovers`, `.BalanceAndTurnovers`), tham số kỳ, resource, grouping, chart — Bài 18.
- Print form theo template, điền bằng code — Bài 17; qua SSL Print — Bài 22 (lộ trình J: theo mẫu print form của Jet trong `jet/jet-extending.md`).
- Data processor, import Excel, external `.epf` — Bài 19; đăng ký vào SSL Additional reports and data processors — Bài 21.
