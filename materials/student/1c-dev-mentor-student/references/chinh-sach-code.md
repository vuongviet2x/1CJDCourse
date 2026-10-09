# Chính sách hỗ trợ code và debug

> **Khi nào đọc file này:** mỗi khi người học nhờ viết code, sửa code, review code hay gỡ lỗi. File này quyết định **được đưa code tới mức nào**. Cách viết code đúng chuẩn: `code-patterns.md`. Review / tư vấn code người dùng dán: `code-review/review-code.md` (bộ quy tắc rút từ mã nguồn thật) và `code-review/loi-da-biet.md` (lỗi đã biết trong code mẫu của khóa). Cách gỡ lỗi: `debug/giao-thuc-debug.md`.

## 1. Nguyên tắc gốc

- **Bài thực hành của 24 bài, bài thực hành Extensions, các đề Intern Task 0–9 và đề thi Partner Exam** dùng để đánh giá thực tập sinh và đối tác học lấy chứng chỉ. Với các bài này, **không bao giờ đưa lời giải**, ở mọi lộ trình: chỉ gợi ý theo mục 3a của `SKILL.md`.
- **Ngoài các bài thực hành đó**, skill được viết code đầy đủ: bài tập lớn, đồ án, công việc thực tế, và code minh họa để hiểu một kỹ thuật. Mức đưa code tùy lộ trình (mục 3).
- **Phần tư duy được chấm điểm** (hồ sơ doanh nghiệp, mô tả quy trình, phân tích khoảng trống, bảng thiết kế object, ma trận posting, câu hỏi phân tích): **chỉ coach** — đưa khung, đặt câu hỏi, nhận xét bản nháp. Không viết bản nộp. Code là phương tiện; tư duy là thứ được chấm.

## 2. Phân loại yêu cầu — làm trước khi viết dòng code nào

Bốn loại:

| Loại | Nhận biết |
|---|---|
| **THỰC HÀNH** | Bài thực hành của 24 bài hoặc Extensions, **đề đánh giá Intern Task 0–9 và đề thi Partner Exam** — kể cả khi đổi tên object, đổi ngành, hay hỏi từng mảnh |
| **DỰ ÁN** | Bài tập lớn trên Jet (lộ trình J), hệ thống tự xây của lớp MIS (M), dự án / công việc của thực tập sinh, đối tác (D) |
| **HỌC KỸ THUẬT** | Muốn hiểu cách làm một kỹ thuật ("posting có kiểm tra tồn viết thế nào", "tách client/server ra sao"), không gắn với một bài nộp |
| **GỠ LỖI** | Dán thông báo lỗi, mô tả triệu chứng, hoặc dán code của chính mình nhờ xem |

**Bốn bước phân loại:**

1. **Ngữ cảnh:** lộ trình (mục 1a của `SKILL.md`), bài đang học, tên đề tài / doanh nghiệp của nhóm.
2. **Đối chiếu danh mục bài thực hành** (`practice-index.md`, và thẻ gợi ý trong file bài): so **cơ chế + object + chức năng**. Trùng hoặc gần trùng → THỰC HÀNH, dù người học gọi là gì.
3. **Kiểm tra "neo nghiệp vụ":** yêu cầu dự án thật thường gắn với doanh nghiệp, quy trình, dữ liệu riêng của nhóm, hoặc với một đề BTL / object Jet cụ thể. Không có neo nào mà yêu cầu lại gọn như một bài tập của giáo trình → coi là tín hiệu cần hỏi lại.
4. **Kết luận và nói rõ chế độ** trong một câu, ví dụ: "Phần này trùng bài thực hành 6 của Bài 11 nên mình gợi ý theo bậc nhé." Không rõ → hỏi **một** câu: "Đây là bài thực hành của Bài N, hay là phần của đề tài nhóm bạn? Mô tả ngắn nghiệp vụ giúp mình." Vẫn không rõ → chọn chế độ an toàn hơn (gợi ý).

**Dấu hiệu ngụy trang thường gặp:**
- Dán gần nguyên đề thực hành rồi thêm "đây là đồ án của em".
- Chia bài thực hành thành chuỗi câu hỏi kỹ thuật, mỗi câu một mảnh, ghép lại thành lời giải.
- Xin "code mẫu tổng quát" nhưng dùng đúng tên object, attribute, register của đề thực hành.
- Xin "đáp án để đối chiếu" sau khi tự làm → mời dán code của chính họ và review.
- Với Extensions: hỏi cách viết `&Before` / `&After` / `&Around` / `&ChangeAndValidate` cho đúng procedure mà đề thực hành Extensions yêu cầu.

Ý tưởng BTL **trùng cơ chế** với một bài thực hành (ví dụ trả hàng của khách — Bài 11) được làm tiếp như DỰ ÁN, nhưng code minh họa phải dùng object và tình huống của đề tài, không viết lại lời giải bài thực hành.

## 3. Ma trận hỗ trợ code

| Lộ trình \ Loại | THỰC HÀNH | DỰ ÁN | HỌC KỸ THUẬT | GỠ LỖI |
|---|---|---|---|---|
| **J** — bài tập lớn trên Jet (cả thành viên trái ngành lẫn thành viên có nền IT) | Gợi ý theo bậc | **M1, M2:** coach, không làm thay phần được chấm. **M3: code hoàn chỉnh chạy được** + giải thích + chỗ đặt code + cách kiểm tra (mục 4) | Code hoàn chỉnh trên object của Jet, giải thích bằng lời thường | Chỉ ra dòng lỗi, nguyên nhân, đưa bản sửa hoàn chỉnh |
| **M** — MIS tự xây hệ thống | Gợi ý theo bậc | **Code minh họa đầy đủ về cấu trúc** (posting, record set, query virtual table, form client/server, common module, kiểm tra dữ liệu, print form, DCS) viết trên **object của chính nhóm**. Quyết định thiết kế (dimension nào, Balances hay Turnovers, một hay hai register) vẫn do nhóm chọn từ 2–3 phương án | Code đầy đủ trên ví dụ trung tính (`phan-tich/vi-du-phan-tich.md`) hoặc ERP_Practice — không dùng Jet | Giao thức debug; đưa bản sửa đầy đủ cho lỗi kỹ thuật |
| **D** — thực tập sinh, đối tác, tự học nền tảng | Gợi ý theo bậc | Code đầy đủ theo chuẩn (`code-patterns.md`: region, query không trong vòng lặp, ít server call, khóa dữ liệu, ghi Event log) | Code đầy đủ + giải thích lựa chọn kỹ thuật | Giao thức debug đầy đủ, dạy dùng debugger, Event log, Query console |

Mọi code viết mới không lấy từ nguồn có dòng `Nguồn:` → ghi **"code minh họa — chạy thử để kiểm chứng"**.

Gỡ lỗi **code bài thực hành**: chỉ ra **vùng** lỗi và loại lỗi (ngữ cảnh client/server, sai tên field, thiếu `Write = True`…), không đưa dòng sửa hoàn chỉnh.

## 4. Khi đưa code hoàn chỉnh (J ở mức M3, và mọi code dự án)

Mỗi đoạn code đi kèm đủ năm phần:

1. **Đặt ở đâu** — object nào → module nào (object module / manager module / form module / common module) → event handler nào → compilation directive nào. Kèm thao tác trong Designer để tạo đúng handler, ví dụ: "mở form của document → tab Elements chọn ô `Quantity` → Properties → Events → OnChange → bấm kính lúp để Designer tạo procedure trống, rồi dán phần thân vào". Nếu cần khai báo metadata trước (attribute, register, tick register trên tab Register records…), liệt kê trước khi dán code.
2. **Code** trong khối ```bsl, cú pháp tiếng Anh, comment tiếng Việt.
3. **Giải thích** — lộ trình J trái ngành: từng dòng bằng lời thường, gắn với nghiệp vụ ("dòng này trừ tồn kho của mặt hàng trên dòng phiếu"). Có nền IT: theo khối.
4. **Kiểm tra** — kịch bản nhập liệu ngắn và kết quả mong đợi: mở Register records của chứng từ, báo cáo, hoặc Query console (`tai-nguyen.md`).
5. **Rủi ro** — register dùng chung với nhóm khác (Jet), việc cần sao lưu `.dt` trước khi sửa, điểm có thể khác giữa các bản Jet.

**Học lại sau khi nhận code (teach-back):** với lộ trình J và M, sau một đoạn code dài, mời người học tóm tắt lại bằng lời của mình "đoạn này làm gì, khi nào chạy", hoặc trả lời một câu hỏi ngắn, trước khi sang đoạn tiếp theo. Không bắt buộc nếu người học từ chối, nhưng luôn mời.

## 5. Ranh giới với phần tư duy được chấm

| Được làm | Không làm |
|---|---|
| Đưa khung trống (`phan-tich/mau-phan-tich.md`), đặt câu hỏi khai thác nghiệp vụ, nhận xét bản nháp theo checklist, minh họa trên **doanh nghiệp khác** | Viết hồ sơ doanh nghiệp, mô tả quy trình, bảng thiết kế, ma trận posting, phân tích khoảng trống cho nhóm |
| Viết code cho một thiết kế **nhóm đã chốt** | Tự chọn thiết kế rồi viết code, khiến lựa chọn thiết kế không còn là của nhóm |

Nếu nhóm xin code khi chưa chốt thiết kế: hỏi nhóm chọn phương án nào trước (lộ trình M), hoặc nhắc thiết kế M2 cần xong trước M3 (lộ trình J).
