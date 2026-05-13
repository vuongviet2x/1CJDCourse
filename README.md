# `lesson/university-summary`

Snapshot riêng (không thuộc chain bài 02-24), dump từ infobase `FullProgram_University_Study_Program`.

## Tại sao là binary `.cf` thay vì XML?

Configuration trong base này có một Language object tên là:

```
1C:Enterprise - File Workshop Russian interface
```

Dấu `:` (colon) không hợp lệ trong tên thư mục Windows. Khi 1C:Designer cố `DumpConfigToFiles` vào `Languages/1C:Enterprise - File Workshop Russian interface.xml`, nó báo lỗi `Invalid file path 'Languages/'. The schema is not registered` và dừng.

Workaround: dump ra `Configuration.cf` (binary, không bị giới hạn tên file).

## Nội dung

Base này thực ra **rất nhỏ** — chỉ có 3 đối tượng:
- `Catalog.Products`
- `Document.Purchases`
- `Document.Sales`

Tổng cộng 78KB. **Không phải** "trạng thái tổng kết 24 bài" như tên folder gốc gợi ý. Trạng thái thực sự hoàn chỉnh của toàn khóa là branch [`master`](../../tree/master) (≈ lesson/24-practice).

## Cách load CF này vào 1C

1. Tạo infobase trống (`File-based`).
2. Mở trong 1C:Designer.
3. `Configuration → Load configuration from file…` → chọn `cf/Configuration.cf`.
4. Đồng ý ghi đè, sau đó `F7` cập nhật DB.

## Cách convert sang XML hierarchy

Sau khi load CF vào infobase, mở Designer, vào danh sách Languages, đổi tên language `1C:Enterprise - File Workshop Russian interface` → `RussianInterface` (hoặc tên hợp lệ khác). Sau đó dump:

```powershell
& "C:\Program Files\1cv8\8.3.26.1656\bin\1cv8.exe" DESIGNER `
    /F "<path-to-new-infobase>" /WA+ `
    /DumpConfigToFiles "<out-dir>"
```
