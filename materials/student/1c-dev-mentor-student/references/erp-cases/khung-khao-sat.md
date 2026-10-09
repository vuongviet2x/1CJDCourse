# Khung khảo sát doanh nghiệp "7 + 2" — từ mẫu khảo sát thực tế của 1C Việt Nam

> **Khi nào đọc file này:** nhóm làm M1 (phân tích nghiệp vụ) cần đi phỏng vấn / khảo sát một doanh nghiệp; người học hỏi "khảo sát hệ thống hỏi những gì", "fit-gap là gì"; intern / đối tác chuẩn bị presales. Quy trình phân tích 8 bước của skill: `phan-tich/quy-trinh-phan-tich.md` — khung này là **công cụ cho bước thu thập** của quy trình đó.
>
> Nguồn: rút từ ba loại mẫu khảo sát mà 1C Việt Nam dùng khi tư vấn 1C:Company Management (bảng câu hỏi theo phân hệ, ma trận theo phòng ban, bảng phản hồi yêu cầu) và các lỗi thường gặp khi khách điền — đã bỏ mọi thông tin khách hàng. Khung là **đề xuất của người soạn**, không phải biểu mẫu chính thức.

## 1. Ba loại tài liệu khảo sát trong một dự án thật

| Loại | Dùng khi | Nội dung |
|---|---|---|
| **T1 — Bảng câu hỏi** | Bắt đầu, khách tự điền trước buổi gặp | Thông tin doanh nghiệp (ngành, người dùng theo bộ phận, sơ đồ tổ chức, mong muốn, thời hạn) + 6 phần nghiệp vụ: danh mục, CRM, bán hàng, kho & mua hàng, tài chính, sản xuất; kèm **danh sách tài liệu khách cần gửi** (danh mục hàng, quy trình, định mức, mẫu báo cáo, quy định phê duyệt…) |
| **T2 — Ma trận theo phòng ban (fit-gap)** | Sau phỏng vấn, tư vấn điền | Quy trình / biểu mẫu của khách → **đối tượng 1C đề xuất** → báo cáo / mẫu in → **mức đáp ứng** → cấp phê duyệt → **câu hỏi mở** |
| **T3 — Bảng phản hồi yêu cầu** | Khách có sẵn bộ yêu cầu (URS, RFP — thường ở dược, FDI) | Từng yêu cầu → phản hồi (Đáp ứng / Cấu hình / Tùy chỉnh / Chưa có / Cần làm rõ / Ngoài phạm vi) → ghi chú trao đổi |

Ba loại nối thành một chuỗi: **T1 thu bối cảnh → T2 ánh xạ quy trình sang 1C → T3 trả lời từng yêu cầu**.

## 2. Khung "7 + 2"

Hai mức: **Lite** — sinh viên lộ trình J làm M1 trên Jet (mua, bán, kho, tiền): chỉ các câu **in đậm**; **Full** — lộ trình M, intern, đối tác.

| # | Khối | Câu hỏi cốt lõi | Bằng chứng cần thu |
|---|---|---|---|
| K1 | Hồ sơ doanh nghiệp | **Ngành, sản phẩm, số pháp nhân / kho / chi nhánh**, số nhân sự, **người dùng theo vai trò**, phần mềm đang dùng | Sơ đồ tổ chức |
| K2 | Mục tiêu và nỗi đau | **3 vấn đề lớn nhất (xếp hạng)**, **3 báo cáo lãnh đạo cần mà chưa có**, thời hạn, tiêu chí thành công đo được | Ghi chép phỏng vấn |
| K3 | Kiểm kê Excel và giấy tờ | **Danh sách file Excel đang dùng: tên — ai cập nhật — tần suất — lấy số từ đâu — ai đọc** | Bản sao file đã ẩn danh |
| K4 | Dữ liệu chủ | **Số mã hàng theo nhóm, đơn vị tính và quy đổi**, thuộc tính (màu, size, khổ, định lượng…), lô / hạn dùng, **số khách / NCC**, các kiểu giá | 20–50 dòng danh mục mẫu |
| K5 | Quy trình theo chuỗi | **Mua (đề nghị → báo giá → đơn → nhận → kiểm → nhập)**, **Bán (báo giá → đơn → giao → hóa đơn → thu)**, **Kho (nhập / xuất / chuyển / kiểm kê)**, **Tiền (thu / chi / công nợ)**; Full thêm: sản xuất (định mức, công đoạn, lệnh, sản lượng, gia công ngoài), QA/QC, nhân sự | Sơ đồ as-is (swimlane) |
| K6 | Phê duyệt và kiểm soát | Chứng từ nào cần duyệt, cấp duyệt, ngưỡng giá trị, trạng thái; ai được sửa gì; có cần lịch sử thay đổi | Ma trận duyệt |
| K7 | Khối lượng và KPI | **Số đơn / tháng, số dòng / đơn, số phiếu kho / ngày**, KPI đang đo (công thức, nguồn), kỳ báo cáo | Bảng số liệu |
| O1 | **Đầu ra 1 — ma trận fit-gap** | Quy trình → đối tượng 1C (Catalog / Document / Register / Report) → mức đáp ứng (Chuẩn / Cấu hình / Tùy chỉnh / Ngoài phạm vi) → câu hỏi mở | |
| O2 | **Đầu ra 2 — danh sách yêu cầu có trạng thái** | Mã — mô tả — nguồn — ưu tiên (Must / Should / Could / Won't) — phản hồi — cần làm rõ | |

**Quy tắc dùng:** (a) tách cột "ví dụ gợi ý" khỏi cột "trả lời" — khách hay để nguyên ví dụ; (b) chỉnh khối sản xuất / QA-QC đúng ngành trước khi gửi (mẫu chép từ ngành khác còn sót câu hỏi không liên quan là lỗi đã gặp thật); (c) **mỗi doanh nghiệp một file mẫu sạch** — không lấy file đã điền của doanh nghiệp A làm mẫu cho B (rò rỉ dữ liệu).

## 3. Những gì mẫu khảo sát thường thiếu — nên hỏi thêm

1. Câu hỏi **định lượng** (số mã hàng, số đơn, số dòng / đơn) — thiếu thì không ước lượng được quy mô.
2. **Xếp hạng nỗi đau** và "báo cáo nào đang tốn công nhất".
3. **Kiểm kê file Excel** — trong thực tế, các file Excel mới là "nguồn sự thật" của doanh nghiệp.
4. **Chuyển đổi dữ liệu**: số dư đầu kỳ, chất lượng danh mục (tên hàng nhồi thông số, trùng mã, sai đơn vị).

## 4. Gắn với bài tập lớn và lớp học

- **Lộ trình J (M1):** dùng mức Lite để phỏng vấn doanh nghiệp giả định / thật của nhóm; đầu ra O1 viết theo đối tượng **của Jet** (`jet/`), phần Jet không có → ghi "mở rộng M2 / M3".
- **Lộ trình M:** mức Full, đầu ra O1 là đầu vào cho bảng thiết kế metadata (`phan-tich/mau-phan-tich.md`).
- **Bài tập gợi ý:** "đọc 2–3 file Excel đã ẩn danh → vẽ quy trình → đề xuất metadata"; "săn lỗi Excel" (hằng số gõ tay trong công thức, liên kết ngoài, ngày bị đảo ngày / tháng, hai phòng giữ hai bản trùng); "tách tên hàng dài thành thuộc tính"; "viết phản hồi cho 20 yêu cầu".
- Phần tư duy được chấm (hồ sơ doanh nghiệp, bảng fit-gap) vẫn theo `chinh-sach-code.md` mục 5: đưa khung và câu hỏi, không điền thay.
