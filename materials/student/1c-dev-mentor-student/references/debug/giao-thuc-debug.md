# Giao thức gỡ lỗi

> **Khi nào đọc file này:** người học dán thông báo lỗi, mô tả triệu chứng ("post mà sổ không có gì", "đổi số lượng không tính tiền", "bị âm kho"), hoặc nhờ xem code chạy sai. Mức đưa bản sửa: `chinh-sach-code.md` mục 3. Công cụ debugger chi tiết: Bài 8; Event log: Bài 12.

## 1. Bảy bước

1. **Thu thập** — nguyên văn thông báo lỗi (nhiều máy hiện tiếng Nga), module và dòng (thông báo lỗi thường có `{Document.X.ObjectModule(25)}`), thao tác vừa làm, chế độ chạy (file / client-server; thin client / web client), phiên bản platform. Thiếu thông tin quan trọng thì hỏi một lượt, tối đa 3 câu.
2. **Dịch và xếp loại** theo bảng mục 2.
3. **Xác định ngữ cảnh chạy** — đoạn lỗi ở module nào, directive nào; common module bật cờ gì. Phần lớn lỗi của người mới nằm ở đây (Bài 7).
4. **Tái hiện tối thiểu** — một bộ dữ liệu nhỏ nhất làm lỗi xuất hiện (vài chứng từ, vài dòng).
5. **Dùng công cụ** (mục 4) — breakpoint, Evaluate expression, Event log, Query console.
6. **Sửa và giải thích** — nguyên nhân gốc trước, bản sửa sau (mức theo lộ trình), cách phòng lần sau.
7. **Xác nhận** — chạy lại kịch bản, xem Register records / báo cáo cho kết quả đúng.

Với code **bài thực hành của giáo trình**: chỉ chỉ ra vùng lỗi và loại lỗi, để người học tự sửa (`chinh-sach-code.md`).

## 2. Từ điển lỗi thường gặp

Câu chữ có thể khác đôi chút giữa các bản platform; tra theo cụm từ chính.

| Tiếng Anh | Tiếng Nga | Thường do | Kiểm tra |
|---|---|---|---|
| Object field not found (X) | Поле объекта не обнаружено (X) | Sai tên attribute / cột; dùng tên Synonym thay vì Name; truy cập dữ liệu không có ở client | So tên với Designer; xem directive của procedure |
| Method of object not found (X) | Метод объекта не обнаружен (X) | Sai tên method; procedure trong module khác thiếu `Export`; gọi method server từ client | `Export`, cờ common module, directive |
| Variable is not defined (X) | Переменная не определена (X) | Gõ sai tên biến; biến khai báo ở procedure khác | Phạm vi biến (Bài 5–6) |
| Procedure or function with the specified name is not defined (X) | Процедура или функция с указанным именем не определена (X) | Gọi procedure không có trong module hiện tại; quên tiền tố tên common module (`TenModule.TenHam()`); sai tên | Procedure nằm ở module nào, có `Export` không, cờ common module |
| Type is not defined (Query) | Тип не определен (Запрос) | Tạo `New Query` ở client (thin/web client không có Query) | Chuyển sang `&AtServer` / `&AtServerNoContext` (Bài 7) |
| Invalid argument type / Type mismatch | Неверный тип аргумента / Несоответствие типов | Truyền sai kiểu: chuỗi thay cho reference, ngày thay cho số | Kiểu của attribute; Evaluate expression |
| Insufficient rights … | Недостаточно прав … | Role thiếu quyền trên object / register; RLS | Roles của user (Bài 20) |
| Data is locked / lock conflict | Конфликт блокировок … | Hai phiên cùng ghi; transaction quá dài | Rút ngắn transaction; thứ tự khóa (Bài 12) |
| Failed to post / không thông báo nhưng chứng từ không post | — | `Cancel = True` ở đâu đó; FillCheckProcessing báo lỗi | Đọc hết thông báo dưới form; đặt breakpoint ở `Posting` |

## 3. Checklist theo triệu chứng

**Post xong mà register không có dòng nào**
- [ ] Tab **Register records** của document đã tick register chưa? Property **Posting** = Allow?
- [ ] Handler `Posting` nằm trong **object module** (không phải form module hay manager module)?
- [ ] Có `RegisterRecords.<Tên>.Write = True` (hoặc `RegisterRecords.Write()`)?
- [ ] Vòng lặp duyệt đúng tabular section? Tabular section có dòng không?
- [ ] Gán đủ `Period`, các dimension, resource? `RecordType` / `AddReceipt` / `AddExpense` đúng chiều?
- [ ] Mở chứng từ → lệnh xem Register records (hoặc report movements) để xem thật sự ghi gì.

**Bị âm kho / báo thiếu hàng sai**
- [ ] Số dư trước đó đúng chưa (đã post chứng từ nhập chưa)?
- [ ] Ngày chứng từ xuất có **trước** chứng từ nhập không? Chứng từ ghi lùi ngày cần PointInTime / Boundary (Bài 11).
- [ ] Query số dư có đọc lẫn movements cũ của chính chứng từ khi re-post không (xem cách ghi record set rỗng trong `erp-practice.md`)?
- [ ] Dimension của register có khớp điều kiện lọc (kho, mặt hàng, lô)?

**Đổi giá trị trên form mà không tính lại**
- [ ] Đã gắn handler `OnChange` cho đúng ô (Properties → Events) chưa, hay chỉ viết procedure mà không gắn?
- [ ] Handler của cột trong bảng hay của ô trên header?
- [ ] Procedure tính có đúng directive (`&AtClient` cho phép tính thuần)?

**Không thấy object mới trong giao diện**
- [ ] Object đã đưa vào subsystem? Đã F7 (Update database configuration)?
- [ ] Role của user có quyền xem? (Lộ trình J: các điểm đăng ký trong `jet/jet-extending.md`.)

**Chạy chậm**
- [ ] Query trong vòng lặp? Đi qua nhiều tầng reference?
- [ ] Nhiều server call trong một thao tác? Bật Performance measurement (Bài 8) để đếm.

## 4. Công cụ

| Công cụ | Dùng khi | Ở đâu |
|---|---|---|
| Breakpoint, Step over / Step into | Xem code chạy tới đâu, biến bằng bao nhiêu | Designer → Debug → Start debugging (Bài 8) |
| Evaluate expression | Xem giá trị một biểu thức, kết quả query tại điểm dừng | Khi đang dừng ở breakpoint (Bài 8) |
| Stop on error | Dừng đúng dòng phát sinh exception | Debug menu (Bài 8) |
| Event log | Lỗi phía server, lỗi của người khác, lịch sử ghi dữ liệu | Enterprise mode, mục Event log (qua All functions hoặc Administration, tùy cấu hình) (Bài 12) |
| Performance measurement | Đo thời gian, số server call | Bài 8 |
| Query console | Chạy thử query có tham số, xem virtual table | File `.epf` trong thư mục cài đặt (`tai-nguyen.md`) |
| Register records của chứng từ | Xem chứng từ thực sự ghi gì | Từ form chứng từ / danh sách |

## 5. Mẫu trả lời

```
🔎 Lỗi: <nguyên văn> → nghĩa là: <một câu>
📍 Ở đâu: <module, procedure, directive>
🧠 Nguyên nhân gốc: <...>
🛠 Cách sửa: <bản sửa hoặc gợi ý, theo mức của lộ trình>
✅ Kiểm tra lại: <thao tác + kết quả mong đợi>
🛡 Lần sau: <thói quen phòng lỗi>
```

Lộ trình J trái ngành: thay thuật ngữ bằng lời thường, giữ thuật ngữ tiếng Anh trong ngoặc. Lỗi vẫn còn sau hai lần sửa, hoặc liên quan register dùng chung với nhóm khác → khuyên gọi tutor (`btl/jet-cho-nguoi-trai-nganh.md`, mục cuối).
