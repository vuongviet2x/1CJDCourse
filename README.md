# Bài Extensions — Lý thuyết (configuration extensions)

Branch này **không** kế thừa `cf/` của khóa JD. Các extension của bài Extensions được làm trên cấu hình
**Standard Subsystems Library (SSL) – bản Demo**, nên branch chỉ chứa file extension:

- `cfe/` — file extension gốc (`.cfe`), load bằng *Configuration → Configuration extensions → Load from file*
  hoặc từ chế độ Enterprise (*All functions → Standard → Manage configuration extensions*).
- `src/` — code module trích từ `.cfe` để đọc / so sánh trên GitHub (chỉ để đọc, không load được).

| Extension | Purpose | Prefix | Adopted objects | Nội dung |
|---|---|---|---|---|
| `Bugfix123` | Patch | `bf123_` | Document `PurchaseInvoice` + `DocumentForm` | `&Around("CalculatePriceAtRow")` sửa lỗi chia cho 0 khi Quantity = 0 |
| `CRMImprovemnet` | Customization | `crm_` | `PurchaseInvoice` (TS `Goods`: thêm `crm_Discount`, `crm_AmountAfterDiscount`), DefinedType `MonetaryAmountNonNegative`, `DocumentForm` | Cột Discount / Amount after discount; handler OnChange kiểu **After** |
| `TestExtension` | Patch | `Test_` | `PurchaseInvoice`, `DocumentForm` | Form gán handler `Test_GoodsAmountOnChangeAround` (call type Instead) cho cột Amount — **module form rỗng** (extension thử nghiệm) |

Ghi chú khi đối chiếu tài liệu `Extensions theory`:

- Tài liệu viết document **PurchaseOrder** / tabular section **Products**; extension thực tế dùng document
  **PurchaseInvoice** / tabular section **Goods**.
- Tài liệu viết tên patch "BigFix123" và extension "CRMImprovement"; file thực tế là `Bugfix123` và `CRMImprovemnet`.
- `Bugfix123`: điều kiện `If GoodsRow.Count <> 0` nhưng phép chia dùng `GoodsRow.Quantity`; tabular section `Goods`
  của PurchaseInvoice (theo phần adopted trong extension) có `Quantity`, không có `Count` — cần kiểm tra lại.
- `CRMImprovemnet`: form có gán handler `crm_GoodsAmountOnChangeAfter` cho cột Amount nhưng module không có
  procedure này (chỉ có handler của cột Discount).
- Các ví dụ `&ChangeAndValidate` (print form), `&Around` cho function + `ProceedWithCall()`, tạo form element /
  attribute / command bằng code trên `_DemoGoodsSales` chỉ có trong ảnh chụp tài liệu, không có trong các file `.cfe` này.

Code trong `src/` được trích tự động từ container `.cfe` (module của form nằm trong mô tả form).
