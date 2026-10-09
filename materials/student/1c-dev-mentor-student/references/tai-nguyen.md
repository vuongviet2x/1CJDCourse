# Tài nguyên: cài đặt nền tảng, Query console, file Jet, khóa học

> **Khi nào đọc file này:** chỉ khi người học **hỏi** về cài đặt platform, tải Query console, lấy file Jet, tài liệu giới thiệu công nghệ 1C:Enterprise, hoặc khóa học có chứng chỉ — hoặc khi họ bị kẹt vì thiếu công cụ (ví dụ cần chạy thử query mà chưa có Query console). Không chèn link vào mọi câu trả lời.
>
> Cập nhật: 08/10/2026. Nếu link không mở được, người học liên hệ giảng viên (quypv@1c.com.vn).

## 1. Thư mục cài đặt của khóa

**Link:** https://drive.google.com/drive/folders/1OV7Lq2TYbfqMMKFSu0hYDXK69kcXRIe6?usp=drive_link

Trong thư mục có:
- **Bộ cài nền tảng 1C:Enterprise** cho Windows và macOS.
- `queryconsole.epf` — Query console (external data processor).
- `jet.dt` — bản dump infobase Jet (cấu hình và dữ liệu có trong bản đó).
- `jet.cf` — file cấu hình Jet (chỉ cấu hình, không có dữ liệu).

**Phiên bản khuyến nghị: 8.3.25.1445** — cấu hình Jet của khóa chạy trên bản này. Trên macOS, nếu không cài được bản 8.3.25.1445 thì mới thử bản khác, và báo giảng viên bản đã cài.

Nhiều phiên bản platform cài song song được trên cùng máy — cần khi một khóa học yêu cầu bản mới hơn (mục 4).

## 2. Hướng dẫn nhanh

**Tạo infobase từ `jet.dt` (có sẵn cấu hình và dữ liệu):**
1. Mở 1C:Enterprise → **Add** → tạo infobase mới **không có cấu hình** (Create an infobase without a configuration…), chọn thư mục lưu.
2. Mở infobase đó bằng **Designer** → **Administration / Tools → Restore infobase** → chọn `jet.dt`.
3. Restore **ghi đè toàn bộ** infobase đích — chỉ restore vào infobase trống hoặc bản thử.

**Nạp `jet.cf` (chỉ cấu hình):**
1. Tạo infobase trống như trên → Designer → **Configuration → Open configuration**.
2. **Configuration → Load configuration from file** → chọn `jet.cf` → đồng ý **Update database configuration** (F7).
3. Lần đầu vào Enterprise mode: tạo user Administrator và làm các bước thiết lập ban đầu (`jet/jet-overview.md` mục 2, chỉ lộ trình J).

Chọn file nào: muốn có ngay dữ liệu để học, quan sát → `jet.dt`. Muốn một cấu hình sạch để tự nhập liệu → `jet.cf`. Sao lưu bài làm luôn dùng **Dump infobase** ra `.dt`; `.cf` không chứa dữ liệu (Bài 1).

**Query console:**
1. Chạy infobase ở chế độ **1C:Enterprise** → **File → Open** → chọn `queryconsole.epf`.
2. Viết hoặc dán query (có thể mở Query wizard), đặt giá trị tham số, bấm chạy để xem kết quả.
3. Dùng để: thử query trước khi đưa vào code, xem số dư / số phát sinh của register (`.Balance`, `.Turnovers`), kiểm tra posting đã ghi đúng chưa.
4. Mở được file `.epf` từ ổ đĩa cần quyền tương ứng; dùng user Administrator khi học.

## 3. Giới thiệu công nghệ nền tảng

**https://1c-dn.com/1c_enterprise/** — trang giới thiệu công nghệ 1C:Enterprise của 1C Developer Network. Gợi ý khi người học (hoặc đối tác) hỏi "1C:Enterprise là gì, kiến trúc ra sao, khác gì phần mềm đóng gói": platform và applied solution tách rời, phát triển dựa trên metadata, các loại client, chế độ file và client-server, công cụ phát triển, tích hợp. Khi trích một nhận định cụ thể từ trang này, dẫn đúng trang con, không tự diễn giải thêm.

## 4. Khóa học trực tuyến có chứng chỉ — 1C Skills Hub

**https://skillshub.1c-dn.com/login?next=/dashboard** — đăng ký tài khoản miễn phí; các khóa miễn phí và có chứng chỉ hoàn thành.

| Khóa | Nội dung | Yêu cầu | Gợi ý cho |
|---|---|---|---|
| **1C:Enterprise Development Basics. Junior Course** | Khóa nền: dùng các object có sẵn của platform để xây ứng dụng nghiệp vụ vừa phải; học trước mọi khóa phát triển khác | Biết khái niệm lập trình cơ bản, cơ sở dữ liệu quan hệ | D; M; thành viên có nền IT của nhóm J. Song song hoặc thay cho phần nền của giáo trình 24 bài |
| **Operational business processes in 1C:Company Management** | Ví dụ trọn vẹn tự động hóa chu trình thương mại trong 1C:Company Management | — | J và M — **hiểu quy trình nghiệp vụ trước khi thiết kế** |
| **1C Standard Subsystems Library Overview** | SSL từ đầu, làm trên cấu hình trống, tự dựng từng thành phần | Platform 8.3.24 trở lên; nền Junior Course (hoặc tự học 24 bài lý thuyết + series video lý thuyết trên YouTube) | D; J có nền IT (Jet xây trên SSL); sau Bài 21–23 |
| **1C:Enterprise. Modification of AccountingSuite Solution** | Tùy biến giải pháp có sẵn: phân tích yêu cầu tùy biến, chọn cách làm (sửa trực tiếp, event subscription, extension, external report / data processor), đánh đổi về bảo trì và cập nhật | Biết phát triển 1C cơ bản, quen Designer; nên học trước First Step và Development Basics. Beginners Course; **platform 8.3.27 trở lên** + cấu hình AccountingSuite của khóa | D (đối tác, thực tập sinh); J có nền IT muốn hiểu cách tùy biến an toàn; sau bài Extensions |
| **Data exchange in 1C** | Trao đổi dữ liệu, tích hợp, làm trên cấu hình trống | Junior Course; platform 8.3.24 trở lên | D; M muốn làm phần tích hợp |
| **IT Software for business WorldSkills training course** | Khóa thực hành cho lập trình viên 1C chuẩn bị thi WorldSkills | — | Sinh viên khá muốn thi đấu |
| **1C:Enterprise Mobile Developer** (có bản tiếng Việt) | Phát triển ứng dụng di động trên 1C | — | Tùy chọn, ngoài giáo trình |

Lưu ý khi giới thiệu:
- Khóa AccountingSuite cần platform 8.3.27 trở lên, khác bản 8.3.25.1445 dùng cho Jet — cài thêm bản mới cho khóa đó, giữ bản 8.3.25.1445 cho bài tập lớn.
- Lộ trình M: giới thiệu khóa để học kỹ thuật và hiểu quy trình; không coi quy trình trong khóa là thiết kế "chuẩn" cho doanh nghiệp của nhóm.
- Mẫu câu: "Nếu muốn học thêm có chứng chỉ, với hướng của bạn mình gợi ý khóa **<tên khóa>** trên 1C Skills Hub — đăng ký tài khoản miễn phí tại đây: <link>."
