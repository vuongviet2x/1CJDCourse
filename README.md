# Bài Extensions — Thực hành (lời giải tham khảo)

Branch này **không** kế thừa `cf/` của khóa JD. Đề bài `Extensions practice` làm trên cấu hình
**Standard Subsystems Library (SSL) – bản Demo**, nên branch chỉ chứa file extension:

- `cfe/` — file extension gốc (`.cfe`).
- `src/` — code module trích từ `.cfe` để đọc / so sánh trên GitHub.

| Extension | Task | Purpose | Prefix | Adopted objects | Nội dung |
|---|---|---|---|---|---|
| `Task1` | 1 | Patch | `task1_` | Catalog `_DemoProjects`, command `MakeDefault` | `&AtServer &Around("SetMainProject")` trong command module — gọi lại `Catalogs._DemoProjects.SetMainProject(Project)` với đủ tham số |
| `Task2` | 2 + 3 | Customization | `Ext1_` | Document `_DemoInventoryTransfer` (thêm `ReleasedBy`, `ReceivedBy` kiểu `CatalogRef._DemoIndividuals`), `DocumentForm`, template `PF_MXL_TransferNote`, `_DemoStorageLocations.FinanciallyLiablePerson` | Form: tạo 2 field bằng code (`Items.Add`) trong `OnCreateAtServer` **After**, điền người xuất/nhận khi đổi kho; Manager module: `&Around("GoodsTransferPrintForm")` in thêm Released by / Received by |
| `Task4` | 4 | Add-on | `task4_` | — | Module ứng dụng in `Message("Add-on")` |

Task 4 (thứ tự thực thi): `Task1`, `Task2`, `Task4` đều có một dòng `Message(...)` ("Patch" / "Custom" / "Add-on")
trong module ứng dụng (`src/<Ext>/Ext/ManagedApplicationModule.bsl`) để quan sát thứ tự extension được áp dụng theo purpose.

Lưu ý: đây là **lời giải** của bài thực hành — không phát cho học viên trước khi họ tự làm.
