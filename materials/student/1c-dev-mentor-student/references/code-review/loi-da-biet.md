# Lỗi đã biết trong code mẫu của khóa và ERP_Practice

> **Khi nào đọc file này:** người học chép code demo của khóa (nhánh `lesson/NN-theory`, nhánh `master` / `master-edt-archive`) hoặc của ERP_Practice rồi gặp kết quả lạ; người học hỏi "code mẫu sao lại làm thế này"; trước khi trích một đoạn code có dòng `Nguồn:` từ các nhánh dưới đây. Mã quy tắc (P1, F2…) trỏ về `code-review/review-code.md`.
>
> Bản sửa các lỗi nặng của nhánh `master` (1CJDCourse) và ERP_Practice: đã đưa vào nhánh `master` của mỗi repo (10/2026, từ nhánh `fix/code-review-2026-10`) — các bảng dưới mô tả lỗi của bản trước khi sửa; các nhánh `lesson/NN-*` giữ nguyên để khớp video nên lỗi ở mục 1 vẫn còn trên các nhánh đó.
>
> Rút từ đợt đọc toàn bộ mã nguồn (10/2026), **chưa chạy lại trên platform**; dòng nào ghi *cần kiểm chứng* thì nói rõ như vậy với người học. Nguyên tắc khi gặp: nói thẳng đây là chỗ code mẫu đơn giản hóa hoặc có lỗi, chỉ cách đúng, **không lặng lẽ chép lại lỗi**.

## 1. Code demo lý thuyết (nhánh `lesson/NN-theory`)

Lưu ý chung: nhánh `lesson/09-theory` trùng gần như nguyên vẹn với `master-edt-archive` — là ảnh chụp **cả khóa** (đã có lô hàng, FIFO/LIFO, nạp Excel, DCS), không phải trạng thái tích lũy của riêng Bài 9. Đừng nói với người học rằng "đến Bài 9 cấu hình đã có FIFO".

| Bài | Ở đâu | Vấn đề | Đúng là | Quy tắc |
|---|---|---|---|---|
| 11–14 | `SalesInvoice` object module, `Posting` | Bán hàng ghi `Receipt` → tồn **tăng** khi bán; Bài 15 mới sửa thành `Expense` | `AddExpense()` | P1 |
| 14, 24 | `ReturnOfGoodsFromCustomer`, `Posting` | Trả hàng ghi doanh số **dương** vào `Sales` → doanh số cộng gấp đôi; nhập lại kho theo giá bán (bản đơn giản hóa) | Amount âm; giá vốn lấy từ movement của hóa đơn gốc | P1, P9 |
| 15, 16, 24 | `SalesInvoice`, `CheckGoodsInWarehouseBalance` | Procedure kiểm tra tồn viết xong nhưng `Posting` **không gọi** → không chặn bán quá tồn | Ghi movement → gọi kiểm tra với biên `Including` | P3 |
| 16–24 | Form `SalesInvoice`, `FillDeliveryAddress` | Ghi vào `Object` trong `BeforeWriteAtServer` → địa chỉ không được lưu (trái với chính comment của bài) | Ghi vào `CurrentObject` | F2 |
| 16–24 | Form `SalesInvoice`, `FillInSoldThisMonth` | `Turnovers` periodicity `Period` → chỉ giữ dòng cuối, không phải tổng tháng; chỉ tính sau khi ghi | Bỏ periodicity; gọi thêm ở `OnReadAtServer` | P8 |
| 10, 13, 16 | Form `SalesInvoice`, Pick | Typo `CloseOnChoise` → form chọn đóng sau lần chọn đầu; `ServicesChoiceProcessing` không được gán event và dùng cột `Product` (bảng Services có cột `Service`) | `CloseOnChoice`; gán event; cột `Service` | F4, F5 |
| 07–24 | Form `PersonnelChange`; form `SalesInvoice` (16–24: `ProductsBeforeDeleteRow`, `ProductsAfterDeleteRow`) | Event gán trong form nhưng module không có handler *(mức lỗi runtime cần kiểm chứng)* | Bỏ gán hoặc viết handler | F5 |
| 07, 10, 16 | Form `PersonnelChange` | Thông báo dùng tên nhân viên **sau khi** đã xóa → luôn rỗng | Lưu vào biến trước | F9 |
| 08, 10, 13, 16 | Form `SalesInvoice`, `CalculateWeightAtServer` | Dereference `Product.Weight` từng dòng; kết quả gán vào biến cục bộ (không phải form attribute) nên bị bỏ | Một query `SUM`; `TotalWeight` là form attribute | Q1 |
| 10, 14 | `CommonServer.ContractSumsByCounterparties` | Duyệt "2 cấp" nhưng query không có `TOTALS` → cấp con rỗng; function không `Return` | `TOTALS ... BY Product`, `ByGroups`, `Return` | Q3 |
| 12–24 | `SalesInvoice` / common module `Sales` | Truyền tabular section thẳng vào `FROM &Products` *(cần kiểm chứng theo phiên bản)* | `.Unload(, "...")` + `CAST` | Q2 |
| 13–16 | `Filling` / event subscription `DocumentsCommonFilling` | Ghi đè `Company` vô điều kiện | Chỉ điền khi rỗng | V4 |
| 09*, 19 | `ImportPricesFromExcel` | `"R" + i` sai từ dòng 1000; `FindByDescription` mỗi dòng; Bài 19 đọc giá bằng `.Text`; ghi từng `RecordManager` không transaction; 09* nuốt lỗi ghi chứng từ (chỉ log); so ngày đầu ngày với ngày có giờ → tạo trùng chứng từ | Địa chỉ số; một query + `Map`; `.Value`; record set / transaction; báo người dùng; `BegOfDay` | X1, X2, Q1, T1 |
| 09* | `SalesInvoice`, `InventoryTransfer` `Posting` | Đọc số dư không `DataLock` (cấu hình Managed); `InventoryTransfer` xóa movement khi hủy post → post lại sau khi **dời ngày về sau** có thể trừ trùng *(cần kiểm chứng)* | `DataLock`; ghi record set rỗng trước khi đọc | P6, P2 |
| 09* | `ReturnOfGoodsFromCustomer` | Không kiểm `SalesDocument` rỗng; trả vượt số đã bán bị bỏ qua lặng lẽ | Kiểm tra + báo lỗi | P9, V1 |
| 17 | `SalesInvoice` manager module, in | Query logo công ty cho **mỗi** chứng từ; `Products` manager có stub `a = 1` trong `PresentationGetProcessing` | Lấy trong query chính; xóa stub | Q5, M2 |
| 17, 20 | Form `Companies` (logo) | `New BinaryData(FileName)` ở client — không chạy web client | `BeginPutFileToServer` | X3 |
| 24 | `SalesInvoice` bút toán | `Dr Phải thu / Cr Hàng hóa` theo **giá bán**, dịch vụ không có bút toán — đơn giản hóa để minh họa `ExtDimensions` | Hai bút toán: doanh thu theo giá bán, giá vốn theo giá vốn | — |
| Ext | `Bugfix123` | Điều kiện dùng cột `Count` không tồn tại (bảng chỉ có `Quantity`) → bản patch gây lỗi runtime; `CRMImprovemnet` thiếu handler `crm_GoodsAmountOnChangeAfter`, thiếu prefix | Sửa tên cột; thêm handler, prefix | E2 |
| master-edt | `FormForDebugTest` | Chứng từ không `Write()`; `Raise "chuỗi"` mất lỗi gốc *(có thể cố ý cho bài debug)* | Mẫu T1 | T1 |
| Nhiều bài | — | `Message()` cho thông báo nghiệp vụ; handler rỗng; marker wizard; typo tên metadata (`ContolBalanceOfGoods`, `FunctionalOptionParatemets`) | `UserMessage` + `Field`; dọn dẹp | V2, M2 |

Các đoạn **nên dạy** trong nhánh theory (code tốt): kiểm tồn sau ghi bằng `New Boundary(PointInTime, BoundaryType.Including)` (`ProductsInDocuments`, 09*); FIFO/LIFO một query + `Min()` (09*); `SELECT TOP 2` + `Count() = 1` lấy giá trị mặc định duy nhất; `SliceLast` lọc trong tham số; tách common module Server / ServerCall / ClientServer; DCS external data set có kiểu cột (09*, 18); upload file async (09*, 19); `ShowQueryBox` / `RunCallback` một luồng (09*); `AdditionalProperties.Insert("IsNew", IsNew())` (11, 24); `DeleteAttributeFromChecking` + functional option có tham số (12–24); ghi register liên quan trong `OnWriteAtServer` cùng transaction (12, 17); vòng đời ghi của managed form (16); logo bằng `ValueStorage` + temp storage + `LockFormDataForEdit` (17); in với tabular section lồng và `PrintParametersKey` (17); storno trong bút toán đảo, `PresentationGetProcessing` của chart of accounts, `#Region` (24); tích hợp SSL Print (21–23).

## 2. ERP_Practice (`vuongviet2x/ERP_Practice`)

Thiết kế: cấu hình dịch vụ sửa chữa có vật tư theo sách *Practical Developer's Guide* (bản PDF: https://drive.google.com/file/d/1X0uW1nnb8PXg-RwCLLlt5H_e2DzkdsnT/view?usp=sharing) (compat 8.3.24, Managed lock, không modal). `GoodsReceipt` / `Services` ghi `BalanceOfMaterials`, `CostOfMaterials` (giá vốn bình quân, **không** theo kho), `Sales`, accounting register `Primary`; exchange plan `Branches` + prefix số theo node; 9 báo cáo DCS. Luồng posting `Services` là mẫu tốt: temp table dòng chứng từ → ghi record set rỗng → đọc số dư → tính giá vốn bình quân → ghi → (RealTime) kiểm tồn âm.

| Ở đâu | Vấn đề | Đúng là | Quy tắc |
|---|---|---|---|
| `ExchangePlans/Branches/Forms/ListForm` | Gọi `WriteChangesAtServer()` thiếu tham số bắt buộc → lỗi biên dịch | Truyền `Items.List.CurrentRow`, bỏ qua node này | — |
| `DataProcessors/DataExchange` | Gọi `ReadMessageWithChanges` / `WriteMessageWithChanges` — không phải method của platform; trong sách là procedure tự viết trong **object module của exchange plan**, repo thiếu file đó | Thêm `ExchangePlans/Branches/ObjectModule.bsl` theo sách (`CreateMessageWriter`, `SelectChanges`, `CreateMessageReader`, `ReadXML`, `DeleteChangeRecords`) | — |
| `Documents/Services`, `Posting` | Bút toán doanh thu (Nợ Phải thu / Có Doanh thu) nằm **trong** nhánh vật tư → doanh thu dịch vụ không vào sổ | Đưa bút toán doanh thu ra ngoài `If` | P1 |
| `Documents/Services`, `Posting` | Số dư đọc không truyền thời điểm → post lại chứng từ quá khứ tính giá vốn trên số dư hôm nay | `New Boundary(PointInTime(), BoundaryType.Excluding)` | P3 |
| `Documents/Services`, `Posting` | `LockForUpdate` trên record set rỗng không khóa các vật tư được đọc *(cần kiểm chứng)* | `DataLock` tường minh | P6 |
| Exchange plan `Branches` | Content thiếu `Primary`, `ChartOfAccounts`, `InputOpeningMaterialBalances` | Bổ sung content | — |
| `InputOpeningMaterialBalances` | `BeforeWrite` không kiểm `DataExchange.Load` | Thêm ở đầu | V5 |

