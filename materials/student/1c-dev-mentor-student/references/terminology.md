# Thuật ngữ và cách diễn đạt chuẩn

Đọc file này khi giải thích khái niệm nền tảng, khi sinh viên dùng thuật ngữ sai, hoặc khi viết nội dung sẽ được trình bày lại (báo cáo, slide, bài thuyết trình).

## 1. Quy tắc bắt buộc

| Không nói | Nói đúng | Lý do |
|---|---|---|
| "Catalog *kế thừa* (inherit) từ class Catalogs" | Metadata object được **tạo từ prototype** (metadata class) có **basic implementation** sẵn | "Kế thừa" mang nghĩa OOP, không đúng với cơ chế 1C. Developer không tạo được metadata class mới. |
| "Module *tự sinh code*" | Module là **container rỗng** với **các event có tên định sẵn**; developer viết handler vào đó | Platform không sinh code cho module. (Wizard như Record wizard có thể *đề xuất* code, nhưng đó là công cụ, không phải module tự sinh.) |
| "Catalog/Register có event Posting" | **Posting chỉ có ở Document** — luôn nói rõ "Posting của Document" | Posting là đặc trưng phân biệt Document với các metadata object khác. |
| "SSL — giao thức bảo mật" | **SSL = Standard Subsystems Library** (thư viện các subsystem chuẩn) | Trong ngữ cảnh 1C, SSL không phải Secure Sockets Layer. |
| "SSL là một loại extension" / ngược lại | SSL và Extensions là **hai cơ chế khác nhau**, có thể dùng chồng lên nhau | SSL được nhúng vào configuration; Extension là lớp mở rộng tách rời configuration. |
| "Privileged mode on posting" | **Post in privileged mode** / **Unpost in privileged mode** | Tên property đúng của Document (giao diện tiếng Anh, platform 8.5). |
| "Extension giúp sửa code dễ" | Extension = **tùy biến an toàn khi cập nhật (upgrade-safe customization)** | Giá trị cốt lõi là không sửa trực tiếp configuration gốc. |
| "Extension loại sửa lỗi / loại bổ sung…" | Ba **Purpose** chính thức: **Patch / Customization / Add-on** | Giữ đúng tên tiếng Anh, không thay bằng từ chung chung. |

## 2. Nguyên tắc thiết kế cần nhắc sinh viên

- **Không phải bước nghiệp vụ nào cũng thành Document.** Chỉ những sự kiện cần ghi nhận, có ngày giờ và (thường) làm thay đổi số liệu mới nên là Document.
- **Không phải Document nào cũng post vào register.** Khi thiết kế, hỏi: chứng từ này có làm thay đổi số liệu cần theo dõi (tồn kho, công nợ…) không? Nếu không thì không cần register records.
- Thuật toán nên dựa vào **Predefined data** hoặc **Enumeration**, không dựa vào Code/Description người dùng có thể sửa.
- **Không thể sửa data object qua reference** — muốn sửa phải lấy object, sửa, rồi ghi lại (ví dụ `Ref.GetObject()` → sửa → `Write()` — ngoài giáo trình, kiểm tra trong Syntax assistant).

## 3. Bảng thuật ngữ Anh – Việt

Luôn giữ thuật ngữ tiếng Anh (đúng như trong Designer) và có thể kèm giải thích tiếng Việt ở lần đầu.

| Thuật ngữ | Giải thích ngắn |
|---|---|
| Platform | Nền tảng thực thi và phát triển (1C:Enterprise 8) |
| Applied solution / Configuration | Ứng dụng nghiệp vụ chạy trên platform, mô tả bằng metadata |
| Infobase | Cơ sở thông tin = configuration + dữ liệu |
| Designer | Chế độ phát triển (cấu hình) |
| Enterprise mode | Chế độ người dùng chạy ứng dụng |
| Metadata class | Loại đối tượng do platform định sẵn (Catalogs, Documents…) |
| Metadata object | Đối tượng developer tạo trong một metadata class (Catalog Products) |
| Data object | Bản ghi cụ thể người dùng tạo (một sản phẩm cụ thể) |
| Standard attributes | Thuộc tính có sẵn theo class (Code, Description, Date, Number…) |
| Attribute | Thuộc tính developer thêm |
| Tabular section | Bảng con của object, lưu ở bảng DB riêng |
| Reference (Ref) | Tham chiếu tới data object |
| Catalog | Danh mục |
| Enumeration (Enum) | Liệt kê — tập giá trị cố định |
| Document | Chứng từ — phản ánh nghiệp vụ, có thể post |
| Posting | Ghi sổ chứng từ — chỉ Document |
| Register records | Các bản ghi register do Document tạo ra khi post |
| Accumulation register | Sổ tích lũy (kind Balances / Turnovers) |
| Information register | Sổ thông tin (có thể periodic) |
| Virtual table | Bảng ảo của register (Balance, Turnovers, SliceLast…) |
| Chart of characteristic types | Kế hoạch loại đặc tính |
| Chart of accounts / Accounting register | Hệ thống tài khoản / Sổ kế toán |
| Constant | Hằng số lưu một giá trị duy nhất |
| Document journal | Nhật ký chứng từ |
| Subsystem | Nhóm chức năng hiển thị trên giao diện |
| Role | Vai trò — tập quyền truy cập |
| Common module | Module dùng chung |
| Object module / Manager module / Form module | Module của object / manager / form |
| Compilation directive | &AtClient, &AtServer, &AtServerNoContext, &AtClientAtServerNoContext |
| Query language | Ngôn ngữ truy vấn của 1C |
| Data composition system (DCS) | Hệ thống bố cục dữ liệu dùng làm report |
| Data processor | Xử lý dữ liệu (built-in hoặc external .epf) |
| Event subscription | Đăng ký event chung cho nhiều object |
| Functional option | Tùy chọn chức năng bật/tắt phần giao diện/chức năng |
| Configuration extension | Mở rộng cấu hình (Patch / Customization / Add-on) |
| SSL | Standard Subsystems Library |
