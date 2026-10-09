# Phân tích nghiệp vụ ERP → cấu trúc phần mềm trên 1C:Enterprise

> **Khi nào đọc file này:** người học cần phân tích một bài toán doanh nghiệp rồi chuyển thành thiết kế trên nền tảng (chọn object, thiết kế register và posting, báo cáo, phân quyền), hoặc nhờ nhận xét bản phân tích / thiết kế. Khung trống: `mau-phan-tich.md`. Ví dụ đã làm sẵn ở ngành khác: `vi-du-phan-tich.md`.
>
> - Lộ trình **M**: file chính vẫn là `mis/tu-xay-dung-he-thong.md` (6 bước, câu hỏi gợi mở, catalog phương án). File này bổ sung nguyên tắc thiết kế (mục 3), ma trận posting, kịch bản kiểm thử và truy vết.
> - Lộ trình **J**: phân tích theo kiểu "đối chiếu với chuẩn" trên Jet (mục 2b), theo đề `btl/de-bai-btl.md`.
> - Lộ trình **D**: phân tích một yêu cầu thay đổi trên cấu hình có sẵn (mục 2c).

> Công cụ thu thập thông tin (bảng câu hỏi "7 + 2", ma trận fit-gap) và case doanh nghiệp thật đã ẩn danh theo ngành: `erp-cases/khung-khao-sat.md`, `erp-cases/case-doanh-nghiep.md`.

## 1. Tám bước — khung chung

Thứ tự từ nghiệp vụ tới phần mềm. Được quay lại bước trước khi phát hiện mâu thuẫn; ghi lại quyết định và lý do vào **nhật ký quyết định**.

| Bước | Câu hỏi trọng tâm | Sản phẩm (khung trong `mau-phan-tich.md`) | Liên hệ 1C |
|---|---|---|---|
| 1. Hồ sơ doanh nghiệp & phạm vi | Bán gì, cho ai, quy mô, mấy kho, chính sách giá và thanh toán; cái gì ngoài phạm vi | Hồ sơ + bảng phạm vi | Constants, Functional options (ví dụ "dùng nhiều kho") |
| 2. Danh sách quy trình | Quy trình nào trong phạm vi; mỗi quy trình bắt đầu bằng sự kiện gì, kết thúc ở đâu, ai tham gia | Bảng SIPOC rút gọn | Mỗi nhóm quy trình → một Subsystem |
| 3. Mô tả quy trình | Ai làm gì, khi nào, với giấy tờ gì; ngoại lệ | Swimlane / sơ đồ luồng chứng từ + bảng bước | Chuỗi chứng từ → **Generation** (tạo dựa trên) |
| 4. Phân loại dữ liệu | Đâu là dữ liệu chủ, đâu là sự kiện, đâu là số liệu cần theo dõi, đâu là thiết lập | Danh sách dữ liệu + ma trận ai tạo / ai xem / ai sửa | Dữ liệu chủ → Catalog / Enumeration; sự kiện → Document; số liệu → Register; thiết lập → Constant / Information register |
| 5. Quy tắc nghiệp vụ & kiểm soát | Quy tắc nào bắt buộc (không xuất âm, hạn mức công nợ, giá theo ngày, bắt buộc nhập) | Bảng quy tắc, mỗi quy tắc ghi **nơi kiểm tra** | Form / `FillCheckProcessing` / `Posting` (mục 3.6) |
| 6. Câu hỏi quản lý | Người quản lý cần biết gì, theo chiều nào (kho, hàng, khách), tại một thời điểm hay trong một kỳ | Danh sách câu hỏi → báo cáo | **Câu hỏi quyết định register** (mục 3.3) |
| 7. Thiết kế object & posting | Object nào, loại gì, attribute / tabular section gì, vì sao; chứng từ nào ghi register nào, chiều nào | Bảng thiết kế object, ma trận posting, ma trận phân quyền | Bài 3–4, 11–13, 20 |
| 8. Kiểm thử & truy vết | Nhập kịch bản nào thì số dư / báo cáo phải ra bao nhiêu; yêu cầu nào chưa có object hay báo cáo đáp ứng | Kịch bản kiểm thử + bảng truy vết | Register records, Query console, báo cáo DCS |

Bước 1–3 nói ngôn ngữ nghiệp vụ, **chưa nhắc tới 1C** — với người trái ngành đây là phần dễ bắt đầu nhất ("nghiệp vụ trước, thuật ngữ sau").

## 2. Biến thể theo lộ trình

### 2a. Lộ trình M — tự xây từ cấu hình trống

Theo `mis/tu-xay-dung-he-thong.md`: bước 1–3 ở đây ứng với bước 1–2 của file MIS; bước 4 ↔ bước 3–4; bước 5–7 ↔ bước 5–6; bước 8 là phần bổ sung (kiểm thử, truy vết). Với mọi quyết định lớn, đưa 2–3 phương án kèm đánh đổi (mục 5 của file MIS) và để nhóm chọn. Không dùng Jet làm mẫu.

### 2b. Lộ trình J — đối chiếu với chuẩn trên Jet

Cách các dự án ERP thật làm với phần mềm đóng gói: chạy quy trình chuẩn của phần mềm trên dữ liệu thật, rồi đánh dấu chỗ khớp và chỗ thiếu, thay vì thiết kế lại từ đầu.

1. Chạy quy trình của phân hệ nhóm phụ trách trên Jet với dữ liệu mẫu theo đề (phương pháp **khai báo → nhập liệu → quan sát**, `btl/jet-cho-nguoi-trai-nganh.md`).
2. Với từng yêu cầu của đề, ghi: **Khớp** / **Khớp một phần** / **Thiếu** — kèm bằng chứng quan sát (chứng từ nào, báo cáo nào).
3. Với chỗ thiếu: đề xuất cách bổ sung theo mức M1 (đặc tả) → M2 (khai báo trong Designer) → M3 (code).
4. Xếp mức ưu tiên: bắt buộc / nên có / bỏ qua — không phải thiếu sót nào cũng cần làm.

Phần phân tích khoảng trống là phần được chấm: coach, không viết thay (`chinh-sach-code.md` mục 5).

### 2c. Lộ trình D — yêu cầu thay đổi trên cấu hình có sẵn

1. Viết lại yêu cầu bằng một câu nghiệp vụ và một câu kiểm thử ("khi … thì hệ thống phải …").
2. Tìm object, register, form, báo cáo bị ảnh hưởng.
3. Chọn cách làm và nói đánh đổi: sửa trực tiếp cấu hình / Extension (Patch, Customization, Add-on) / Event subscription / external report hoặc data processor. Tiêu chí: mức độ cần thay đổi, khả năng cập nhật cấu hình gốc, bảo trì (Bài 16, bài Extensions; khóa tùy biến AccountingSuite trong `tai-nguyen.md`).
4. Thiết kế → code → kịch bản kiểm thử.

## 3. Nguyên tắc thiết kế 1C

### 3.1. Không phải bước nghiệp vụ nào cũng thành Document
Chỉ sự kiện có thời điểm, cần lưu lại, cần tra cứu / in / làm căn cứ, hoặc làm thay đổi số liệu cần theo dõi mới thành Document. "Duyệt đơn" thường chỉ là một attribute trạng thái (hoặc information register lưu lịch sử trạng thái).

### 3.2. Không phải Document nào cũng post
Đơn đặt hàng có thể không post; hoặc chỉ post vào một register "đơn còn mở" nếu có câu hỏi quản lý cần nó.

### 3.3. Câu hỏi quản lý quyết định register
- "Bây giờ / tại ngày X còn bao nhiêu?" (tồn kho, công nợ, tiền trong quỹ) → Accumulation register **Balances**, đọc virtual table `.Balance`.
- "Trong kỳ phát sinh bao nhiêu?" (doanh số tháng, lượng mua theo nhà cung cấp) → **Turnovers**, đọc `.Turnovers`.
- Cần cả đầu kỳ, phát sinh, cuối kỳ → Balances với `.BalanceAndTurnovers`.
- Một con số không ai hỏi tới → chưa cần register.

### 3.4. Chọn dimension
Dimension là chiều mà **cả hai chiều tăng và giảm đều điền được** và người quản lý cần cắt số liệu theo nó (kho, mặt hàng, khách). Thông tin chỉ có ở một chiều (nhà cung cấp chỉ có khi nhập) → để làm attribute của register hoặc lấy từ chứng từ, không làm dimension (Practical Developer's Guide, Lesson 12).

### 3.5. Information register hay attribute của Catalog
- Giá trị thay đổi theo thời gian và cần biết giá trị tại một ngày (giá bán, tỷ giá, hạn mức) → Information register **periodic**, đọc bằng `SliceLast` (Bài 12).
- Giá trị gần như cố định (đơn vị tính chính) → attribute của Catalog.
- Giá do một chứng từ thiết lập (phiếu điều chỉnh giá) → Information register **subordinate to recorder**.

### 3.6. Kiểm soát đặt ở đâu
| Loại quy tắc | Nơi kiểm tra | Bài |
|---|---|---|
| Bắt buộc nhập, giá trị hợp lệ chỉ dựa vào chính chứng từ | Property Fill checking hoặc `FillCheckProcessing` | 12 |
| Phụ thuộc số dư thật (tồn âm, vượt hạn mức công nợ) | `Posting`, sau khi ghi movements, có khóa dữ liệu | 11 |
| Tiện ích nhập liệu (tự điền giá, tự tính tiền) | Form | 9 |

Không bao giờ chỉ kiểm tra ở form: dữ liệu còn có thể vào bằng xử lý hàng loạt, import, hay form khác.

### 3.7. Các object khác
- Catalog: hierarchy cho nhóm hàng; Owner cho dữ liệu phụ thuộc (hợp đồng thuộc đối tác, lô thuộc mặt hàng); Predefined cho phần tử code cần gọi tới (Bài 4).
- Chart of characteristic types khi người dùng tự định nghĩa thuộc tính (màu, cỡ) (Bài 13).
- Chart of accounts + Accounting register chỉ khi đề tài có hạch toán kép (Bài 24).
- Business process / Task: chỉ khi thật sự cần luồng phê duyệt nhiều người — thường ngoài phạm vi bài tập lớn.
- Roles và Functional options thiết kế từ ma trận ai tạo / ai xem / ai sửa ở bước 4, không để tới cuối (Bài 15, 20).

### 3.8. Ma trận posting là cầu nối giữa phân tích và code
Mỗi ô của ma trận (chứng từ × register) ghi: chiều (tăng / giảm hoặc phát sinh), các dimension lấy từ đâu (header hay tabular section), resource tính thế nào, điều kiện ghi. Khi ma trận đầy đủ, code posting gần như viết theo ma trận — đó là lúc chuyển sang `chinh-sach-code.md` và `code-patterns.md`.

## 4. Cách tutor dẫn dắt

- Hỏi bước nhóm đang làm; mỗi lượt trả lời chỉ một lượt câu hỏi gợi mở (2–4 câu) cho bước đó.
- Nhận xét bản nháp theo thứ tự: **đầy đủ** (thiếu quy trình, ngoại lệ, vai trò?) → **nhất quán** (thiết kế có khớp hồ sơ doanh nghiệp không?) → **truy vết được** (mỗi object trả lời được "dòng nào trong nghiệp vụ cần tôi?", mỗi câu hỏi quản lý có register + báo cáo đáp ứng?). Nêu điểm mạnh trước, tối đa 3–5 vấn đề, mỗi vấn đề kèm câu hỏi.
- Minh họa bằng ví dụ ở **ngành khác** ngành của nhóm (`vi-du-phan-tich.md`), nói rõ là minh họa cách lập luận.
- Lộ trình J trái ngành: dùng từ đời thường ("sổ theo dõi tồn kho" trước, "Accumulation register" trong ngoặc sau).
- Khi thiết kế đã chốt và nhóm cần code: theo `chinh-sach-code.md`.
