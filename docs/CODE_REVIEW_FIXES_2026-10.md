# Sửa lỗi sau review mã nguồn (10/2026) — nhánh `fix/code-review-2026-10`

Áp dụng trên cấu hình hoàn chỉnh (`master`). Các nhánh `lesson/NN-*` **không đổi** để khớp với video. Chưa chạy thử trên platform — kiểm tra theo kịch bản cuối file rồi mới merge.

| File | Lỗi | Sửa |
|---|---|---|
| `CommonModules/ProductsInDocuments` | Không có khóa dữ liệu khi đọc số dư (cấu hình Managed lock) | Thêm `LockGoodsInWarehouses(Products, Warehouse)` — `DataLock` Exclusive theo Warehouse + Product |
| `Documents/SalesInvoice` `Posting` | FIFO/LIFO: không khóa; lô có số dư ≤ 0 vẫn được phân bổ (record âm / record 0 với lô rỗng); tiền lẻ còn lại ở lô đã xuất hết; thứ tự lô chỉ theo `Batch.Date` | Gọi khóa; `ON ... AND QuantityBalance > 0`; bỏ qua `Quantity <= 0`; lấy hết lô thì lấy `AmountBalance`; `ORDER BY Batch.PointInTime` |
| `Documents/InventoryTransfer` `Posting` | Như trên; `Delete records = on unposting` → post lại sau khi dời ngày về sau có thể trừ trùng movement cũ | Như trên; đổi `RegisterRecordsDeletion` thành `AutoDelete` |
| `Documents/InventoryTransfer` `FillCheckProcessing` | Cả hai kho rỗng vẫn báo "trùng kho"; thông báo không gắn ô | Chỉ so khi đã điền; `UserMessage` gắn `WarehouseRecipient` |
| `Documents/ReturnOfGoodsFromCustomer` | Không kiểm tra `SalesDocument` rỗng; trả vượt số đã bán bị bỏ qua lặng lẽ; ghi record số lượng 0; gán `Warehouse` hai lần; chữ ký `Filling` cũ; `FillingData.Ref` thừa | Kiểm tra + `Cancel`; `ReportExcessReturn`; bỏ qua `Quantity <= 0`; dọn dẹp |
| `Documents/SalesInvoice` form (Form.xml) | Event `ChoiceProcessing` của cột Batch gán handler `ProductsBatchChoiceProcessing` không tồn tại | Bỏ gán event (chọn lô dùng lệnh `PickBatch`) |
| `DataProcessors/ImportPricesFromExcel` | Địa chỉ ô `"R" + i` sai từ dòng 1000; `FindByDescription` mỗi dòng; ngày có giờ không khớp chứng từ đã có → tạo trùng; lỗi ghi chỉ vào Event log | `Area(Row, Col, Row, Col)`; một query + `Map`; `BegOfDay` ở cả hai phía; báo người dùng; kiểm tra kiểu ngày / giá |

**Chưa sửa (giữ cho bài giảng / cần anh quyết):** `Message()` → `UserMessage` toàn cấu hình; form debug `FormForDebugTest` (cố ý cho bài 8); 2 server call khi đổi Product trên form SalesInvoice; typo metadata `ContolBalanceOfGoods`.

## Kịch bản kiểm tra
1. FIFO, kho A: nhập lô 1 (10 × 10), lô 2 (10 × 12). Bán 15 → movement: lô 1 −10 / −100, lô 2 −5 / −60. Mở báo cáo tồn: lô 1 = 0 / 0.
2. Bán 30 (tồn 20) → thông báo thiếu 10, không post. Không có record số lượng 0.
3. Chuyển kho đã post: đổi ngày về sau, post lại → không báo thiếu sai.
4. Trả hàng không chọn hóa đơn → báo lỗi ô SalesDocument. Trả nhiều hơn đã bán → báo vượt, không post.
5. Excel 1 200 dòng, ngày có giờ → không lỗi địa chỉ ô; chạy lại cùng file → cập nhật chứ không tạo chứng từ mới.
6. Hai phiên post hai hóa đơn cùng sản phẩm, cùng kho, đồng thời → phiên sau chờ khóa, không cùng lấy một lô.
