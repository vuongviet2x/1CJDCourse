# Nguồn mã mở bên ngoài — danh mục, cho ai, khi nào

> **Khi nào đọc file này:** người dùng hỏi "có thư viện / ví dụ / công cụ nào cho…", cần kỹ thuật **ngoài 24 bài** (HTTP/REST, di động, mã vạch, kiểm thử tự động, phân tích code tĩnh, CI/CD, AI agent với 1C), muốn đọc một ứng dụng lớn hơn, hoặc dán code cộng đồng (thường cú pháp tiếng Nga).
>
> Khảo sát 10/2026 (đọc trực tiếp repo, kiểm giấy phép trong file LICENSE). Số sao, trạng thái thay đổi nhanh — nói "tại thời điểm khảo sát", rà lại mỗi quý.
>
> **Nguyên tắc:** (1) không phải tài liệu của khóa — nói rõ nguồn và giấy phép; (2) phần lớn code cộng đồng là **cú pháp tiếng Nga** — với người mới chỉ giới thiệu nguồn tiếng Anh hoặc dùng như công cụ; chuyển cú pháp theo `code-review/thuat-ngu-ru-en.md`; (3) không chép khối code lớn vào câu trả lời — tóm tắt kỹ thuật, trỏ link; repo **không giấy phép** chỉ được trỏ link; (4) không thay bài thực hành, không dùng để lách `chinh-sach-code.md`.
>
> Ký hiệu đối tượng: **(a)** sinh viên mới, chỉ dùng chat · **(b)** intern / đối tác mức Junior · **(c)** giảng viên, sản xuất khóa học.

## 1. Đã tích hợp vào skill

| Nguồn | Giấy phép · cú pháp | Đã dùng ở đâu |
|---|---|---|
| [1Ci-Company/Jet](https://github.com/1Ci-Company/Jet) (nhánh `community`) — ứng dụng mã mở cho người học, SSL 3.1.10 | MIT · **EN** | `jet/`, `btl/` (lộ trình J) |
| [zeegin/v8std](https://github.com/zeegin/v8std) → v8std.ru — bộ chuẩn phát triển của 1C (~320 chuẩn) + bản đồ chuẩn ↔ chẩn đoán | CC0 · RU (bản EN gốc trên kb.1ci.com) | `code-review/chuan-phat-trien.md` |
| [1c-syntax/ssl_3_1_eng](https://github.com/1c-syntax/ssl_3_1_eng) — SSL 3.1 World edition (bản tiếng Anh) | CC-BY-4.0 (mirror; SSL là sản phẩm của 1C) · **EN** | `code-review/ssl-api-en.md` (chỉ tên + chữ ký) |
| [1c-syntax/bsl-language-server](https://github.com/1c-syntax/bsl-language-server) — ~190 chẩn đoán, tài liệu EN | LGPL-3.0 | `review-code.md` mục 2b (tên chẩn đoán) |
| [1C-Company/v8-code-style](https://github.com/1C-Company/v8-code-style) — kiểm tra chuẩn chính thức trong 1C:EDT | EPL-2.0 | `review-code.md` mục 2b, `chuan-phat-trien.md` |

## 2. Ứng dụng / thư viện mẫu để đọc

| Nguồn | Là gì | Giấy phép · cú pháp | Cho ai, khi nào |
|---|---|---|---|
| [1C-Developer-Network/MobileScanner](https://github.com/1C-Developer-Network/MobileScanner/tree/master/MobScanner) | App **di động** kiểm kê kho (compat 8.3.14): quét mã vạch bằng camera (`MultimediaTools.ShowBarcodeScanning`), tìm hàng theo SKU, thêm hàng mới, nhập tên bằng giọng nói, xuất PDF đẩy lên Dropbox qua `HTTPConnection`. Kèm bài blog trên 1c-dn.com | không ghi giấy phép → chỉ link · **EN** | (a)(b): ý tưởng BTL Logistics (kiểm kê bằng điện thoại), minh họa nền tảng di động |
| [vbondarevsky/Connector](https://github.com/vbondarevsky/Connector) (`src/en`) | HTTP client kiểu "Requests": `HTTPConnector.GetJson / PostJson`, session, cookie, Basic/Digest/AWS4, gzip, retry, redirect; 1 common module ~3 100 dòng + test | Apache-2.0 · **EN** + RU | (b): tích hợp REST/JSON; mẫu tổ chức common module lớn |
| [alexkmbk/1CI](https://github.com/alexkmbk/1CI) | Cấu hình CI server viết trên 1C: HTTP service `RunTask`, COM connector, RLS, giao diện Taxi | MIT · **EN** (SSL 2.2.4 — cũ) | (b): ví dụ HTTP service, RLS bằng cú pháp tiếng Anh; cảnh báo SSL đời cũ |
| [Bayselonarrend/OpenIntegrations](https://github.com/Bayselonarrend/OpenIntegrations) | Tích hợp sẵn Telegram, Google, Bitrix24… cho 1C / OneScript / CLI | MIT · chủ yếu RU | (b): dự án cần kết nối dịch vụ phổ biến |
| [infaton/MCP35](https://github.com/infaton/MCP35) | MCP server viết bằng BSL (JSON-RPC 2.0 qua HTTP service) | MIT · RU | (c)(b nâng cao): ví dụ HTTP service hiện đại |
| [zeegin/OpenSubsystemsLibrary](https://github.com/zeegin/OpenSubsystemsLibrary) | Thư viện nhỏ, sạch, có test và Gherkin | MIT · RU | (c): mẫu thiết kế thư viện |
| [BlizD/Tasks](https://github.com/BlizD/Tasks) | Cấu hình hoàn chỉnh quản lý công việc (kanban, phát hành) | Apache-2.0 · RU | (b) đọc được RU: đọc một cấu hình thật cỡ vừa |
| [1C-Company/dt-demo-configuration](https://github.com/1C-Company/dt-demo-configuration) | Demo EDT của 1C: thiết bị thương mại, máy quét mã vạch, định vị | **không giấy phép** → chỉ link · RU | (c) |
| [FoxyLinkIO/FoxyLink](https://github.com/FoxyLinkIO/FoxyLink), [astrizhachuk/mockserver-client-1c](https://github.com/astrizhachuk/mockserver-client-1c) | Tích hợp JSON / RabbitMQ dựa trên DCS (giấy phép cần đọc kỹ); mock HTTP để test tích hợp (GPL-3.0) | — · RU | (c) |

Lưu ý khi dùng **MobileScanner** làm mẫu: có `DoModal()` (lỗi khi *Modality use mode = Do not use* — thay `OpenForm` + callback), địa chỉ ô `"R" + String(n)` (quy tắc X1), `Message()`, ghi chứng từ ở client sau mỗi lần quét, token Dropbox để trần trong constant (#std740), HTTP không timeout (#std748), không `Try`.

## 3. Công cụ giới thiệu cho người học

| Công cụ | Dùng để | Giấy phép | Cho ai |
|---|---|---|---|
| VS Code + [Language 1C (BSL)](https://github.com/1c-syntax/vsc-language-1c-bsl) + [BSL Language Server](https://github.com/1c-syntax/bsl-language-server) | Tô màu BSL + query, gợi ý, chẩn đoán tĩnh (đặt ngôn ngữ thông báo `en`); đối chiếu `review-code.md` mục 2b | MIT / LGPL-3.0 | (b), (a) khá |
| 1C:EDT + [1C:Code style V8](https://github.com/1C-Company/v8-code-style) | Kiểm tra chuẩn trong EDT | EPL-2.0 | (b) làm trên EDT |
| [EvilBeaver/OneScript](https://github.com/EvilBeaver/OneScript) (2.0, .NET) | Chạy ngôn ngữ 1C **không cần platform** — luyện cú pháp, vòng lặp, collection, viết script tự động hóa | MPL-2.0 | (a) có máy, (b) |
| [cpr1c/tools_ui_1c](https://github.com/cpr1c/tools_ui_1c) | Query console, code console… cho managed form | GPL-3.0 | (b) — ưu tiên `queryconsole.epf` của khóa (`tai-nguyen.md`) |
| [bia-technologies/yaxunit](https://github.com/bia-technologies/yaxunit), [Pr-Mex/vanessa-automation](https://github.com/Pr-Mex/vanessa-automation) | Unit test (extension, EDT); kiểm thử hành vi / UI (BDD, Gherkin) | Apache-2.0 / BSD-3-Clause | (b) |
| [vanessa-opensource/vanessa-runner](https://github.com/vanessa-opensource/vanessa-runner) 3.x | CLI build / test / deploy. **Bản 3.0 đổi cú pháp lệnh** (`vrunner test xunit`, file `autumn-properties.json`, cần OneScript 2.0) — hướng dẫn cũ dùng 2.x | MPL-2.0 | (b) nâng cao, (c) |
| [1C-Company/GitConverter](https://github.com/1C-Company/GitConverter) | Chuyển kho cấu hình (repository) sang Git / EDT | CC-BY-SA-4.0 | (b), (c) |
| [1c-syntax/sonar-bsl-plugin-community](https://github.com/1c-syntax/sonar-bsl-plugin-community) | SonarQube cho đội / đối tác | LGPL-3.0 | (b) đối tác, (c) |
| [Diversus23/onec-docker](https://github.com/Diversus23/onec-docker) | Image Docker cho server, client, EDT, vanessa-runner | MIT | (c) |

## 4. AI agent làm việc với 1C (cho người có platform trên máy)

| Nguồn | Là gì | Giấy phép | Ghi chú |
|---|---|---|---|
| [Nikolay-Shirokov/cc-1c-skills](https://github.com/Nikolay-Shirokov/cc-1c-skills) | ~80 skill cho Claude Code / Cursor / Codex: tạo / sửa / kiểm tra metadata, form, DCS, role, MXL, extension trên bản dump XML; build `.epf`; infobase; web publish; **kiểm thử qua web client, quay video có phụ đề + TTS** | MIT · RU | Bản Python chạy được Linux; `form-validate`, `skd-validate` không cần platform (đã thử trên repo khóa — không bắt được handler mồ côi) |
| [Desko77/claude-code-skills-1c](https://github.com/Desko77/claude-code-skills-1c) | Bộ skill phái sinh từ cc-1c-skills: ~120 skill, ~40 rule, validator, tham chiếu SSL | MIT · RU | Tham khảo cách đóng gói rule |
| [Roman-repo/1c-dev-rules](https://github.com/Roman-repo/1c-dev-rules) | Đóng gói chuẩn v8std thành rule "tóm tắt + checklist + ví dụ sai / đúng" | MIT · RU | Mô hình đã áp dụng cho `chuan-phat-trien.md` |
| [feenlace/mcp-1c](https://github.com/feenlace/mcp-1c) | MCP server (Go): tra cứu metadata, trợ giúp cú pháp ~180 hàm có **đồng nghĩa RU ↔ EN**, gợi ý tối ưu query | MIT · RU | (b) dùng AI agent, (c) |
| [itrous/bsl-analyzer](https://github.com/itrous/bsl-analyzer) | Bộ phân tích BSL mới (LSP + MCP), ~180 chẩn đoán, tài liệu RU/EN | MIT / Apache-2.0 (một phần EPL-2.0) · beta | (c) thử nghiệm |
| [DitriXNew/EDT-MCP](https://github.com/DitriXNew/EDT-MCP), [Untru/1c-mcp](https://github.com/Untru/1c-mcp) | MCP cho 1C:EDT (GPL-3.0); danh mục cập nhật các MCP / skill cho 1C (không giấy phép → chỉ link) | — | (c) theo dõi hệ sinh thái |
| [comol/ai_rules_1c](https://github.com/comol/ai_rules_1c) | Bộ rule / subagent cho Cursor | **không giấy phép** → chỉ link | (c) |

**Phù hợp:** người dùng agent trên máy có cài platform, làm dự án thật. **Không phù hợp:** sinh viên mới chỉ dùng chat — người học nên tự thao tác Designer để học. Skill này là **gia sư** (giải thích, gợi ý, review, chính sách đưa code); các bộ trên là "tay chân" thao tác file — dùng song song được.

## 5. Không nên dùng / hạ ưu tiên

| Nguồn | Lý do |
|---|---|
| xDrivenDevelopment/xUnitFor1C | Dừng từ 2018, ordinary forms → dùng YAxUnit |
| EvilBeaver/oscript-library | Đã archive 2021 → dùng thư viện mới của tổ chức `oscript-library` |
| 1c-syntax/ssl_int | Dừng 2021 → dùng `ssl_3_1_eng` |
| vanessa-opensource/add | Còn dùng được nhưng hướng mới là YAxUnit + Vanessa Automation |
| tormozit/RDT1C, infostart-hub/snegopat | Công cụ mạnh nhưng tiếng Nga, giấy phép không rõ / chỉ Configurator 32-bit — không đưa vào bài giảng |
| Công cụ đặt lại / dò mật khẩu 1C | Không phù hợp giảng dạy (rủi ro bảo mật) |
| Repo "learn 1C" nội dung rỗng, code sinh EPF bằng AI giấy phép GPL | Không có giá trị học / không trích được |

Không tìm thấy repo chính thức của 1C cho **1C:Enterprise.Element** (chỉ có công cụ cộng đồng chưa chính thức) — nếu người dùng hỏi, nói rõ điều này.

