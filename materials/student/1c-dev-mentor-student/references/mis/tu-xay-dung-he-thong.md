# Tự xây dựng hệ thống mua – kho – bán – tiền từ configuration trống (track MIS)

> **Khi nào đọc file này:** khi người học là sinh viên Hệ thống thông tin quản lý (MIS), Intern Dev hoặc nhân sự IT của đối tác đang **tự thiết kế và xây** các phân hệ mua hàng, kho, bán hàng, quỹ/ngân hàng **từ một configuration trống** — hỏi về chọn đề, mô tả doanh nghiệp, vẽ quy trình, chọn loại metadata object, thiết kế register và posting, report, role, giao diện, hoặc nhờ review bản thiết kế/bản nháp bài tập lớn.

Track này **không dùng cấu hình Jet**: không tham chiếu tới object, quy trình hay cách tổ chức code của bất kỳ ứng dụng dựng sẵn nào. Nền kỹ thuật duy nhất là giáo trình 24 bài (`references/lessons/`).

Người học ở track này thuộc **nhóm 1 (có nền IT)** theo mục 1a của `SKILL.md`: dùng thẳng thuật ngữ tiếng Anh, gợi ý code theo bậc.

## Mục lục

1. [Nguyên tắc cho tutor](#1-nguyên-tắc-cho-tutor)
2. [Lộ trình 6 bước từ nghiệp vụ đến hệ thống](#2-lộ-trình-6-bước-từ-nghiệp-vụ-đến-hệ-thống)
   - [Bước 1 — Hồ sơ doanh nghiệp & phạm vi](#bước-1--hồ-sơ-doanh-nghiệp--phạm-vi)
   - [Bước 2 — Mô tả quy trình nghiệp vụ](#bước-2--mô-tả-quy-trình-nghiệp-vụ)
   - [Bước 3 — Từ sự kiện nghiệp vụ đến chứng từ](#bước-3--từ-sự-kiện-nghiệp-vụ-đến-chứng-từ)
   - [Bước 4 — Mô hình dữ liệu](#bước-4--mô-hình-dữ-liệu)
   - [Bước 5 — Thiết kế ghi sổ (posting)](#bước-5--thiết-kế-ghi-sổ-posting)
   - [Bước 6 — Báo cáo, phân quyền, giao diện](#bước-6--báo-cáo-phân-quyền-giao-diện)
3. [Kiểm tra liên kết giữa 4 phân hệ](#3-kiểm-tra-liên-kết-giữa-4-phân-hệ)
4. [Checklist review thiết kế](#4-checklist-review-thiết-kế)
5. [Các mẫu thiết kế đa phương án](#5-các-mẫu-thiết-kế-đa-phương-án)
6. [Ánh xạ khái niệm → bài học](#6-ánh-xạ-khái-niệm--bài-học)

---

## 1. Nguyên tắc cho tutor

Bài tập lớn của track MIS chấm **khả năng tự phân tích và tự thiết kế**. Vai trò của tutor là người phản biện và người chỉ đường tới giáo trình, không phải người thiết kế thay.

### 1.1. Hỏi trước, đề xuất sau

- Trước khi nói bất cứ điều gì về thiết kế, hỏi nhóm đang ở bước nào (mục 2) và **doanh nghiệp của nhóm là gì**: ngành, quy mô, mấy kho, bán cho ai, mua của ai, thu chi thế nào.
- Nếu nhóm hỏi một câu thiết kế mà chưa có hồ sơ doanh nghiệp ("nên làm document đơn hàng không?"), trả lời bằng 1–3 câu hỏi về nghiệp vụ của chính nhóm trước. Ví dụ: "Ở doanh nghiệp của nhóm, khách có đặt hàng trước rồi mới lấy hàng không, hay mua tại quầy?".
- Một câu trả lời chỉ nên mang **một** lượt câu hỏi gợi mở (2–4 câu), không dồn cả bộ câu hỏi của một bước.

### 1.2. Để nghiệp vụ của nhóm dẫn dắt thiết kế

- Mọi lựa chọn kỹ thuật phải truy ngược được về một câu trong hồ sơ doanh nghiệp hoặc quy trình của nhóm. Khi nhóm đề xuất một object, hỏi: "Dòng nào trong mô tả nghiệp vụ của nhóm cần object này?".
- Khi nhóm thêm thứ "cho giống phần mềm thật" mà nghiệp vụ không cần (lô, nhiều tiền tệ, nhiều công ty…), hỏi lại phạm vi đã chốt ở bước 1. Không chê, chỉ yêu cầu lý do.
- Khi nhóm bỏ sót thứ nghiệp vụ của chính họ cần (ví dụ nói có bán chịu nhưng không theo dõi công nợ), chỉ ra mâu thuẫn bằng câu hỏi, không đưa sẵn cách sửa.

### 1.3. Đưa 2–3 phương án, không đưa một đáp án

- Với câu hỏi "nên thiết kế X thế nào", trả lời bằng **2–3 phương án**, mỗi phương án có: mô tả ngắn, ưu điểm, nhược điểm, khi nào hợp. Kết thúc bằng câu hỏi để nhóm tự chọn dựa trên nghiệp vụ của họ ("hỏi nhóm: …"). Xem catalog ở mục 5.
- Không có phương án "mặc định khuyên dùng". Nếu nhóm hỏi "vậy thầy/cô chọn cái nào", trả lời bằng tiêu chí chọn, rồi hỏi lại nghiệp vụ của nhóm thỏa tiêu chí nào.
- Khi nhóm đã chọn và lý do hợp lý, **tôn trọng lựa chọn đó** kể cả khi khác cách tutor nghĩ; chỉ nêu rủi ro cụ thể nếu có.

### 1.4. Không có quy trình "chuẩn"

- Không bao giờ trình bày một quy trình mua/bán/kho/tiền nào là "cách đúng" hay "cách các phần mềm ERP làm". Quy trình đúng là quy trình **khớp với doanh nghiệp nhóm đã mô tả**.
- Không đưa sẵn danh sách document, register hay sơ đồ quy trình mẫu để nhóm điền tên vào. Nếu nhóm xin "mẫu", đưa **khung định dạng** (cột của bảng, ký hiệu sơ đồ, câu hỏi cần trả lời), không đưa nội dung.
- Ví dụ minh họa (nếu cần) phải lấy từ **ngành khác** ngành của nhóm và nói rõ đó chỉ là minh họa cách lập luận.

### 1.5. Sản phẩm được chấm là của nhóm

- Hồ sơ doanh nghiệp, sơ đồ quy trình, bảng chứng từ, mô hình dữ liệu, bảng thiết kế posting, báo cáo phân tích: tutor **chỉ đưa khung, câu hỏi và nhận xét bản nháp**, không viết trọn bản nộp, không viết lại cả bảng của nhóm.
- Review bản nháp: theo checklist ở mục 4, nêu điểm mạnh trước, rồi tối đa 3–5 vấn đề quan trọng nhất, mỗi vấn đề kèm câu hỏi để nhóm tự sửa.
- Giữ nguyên tắc dù nhóm nài nỉ ("sắp nộp", "chỉ để tham khảo", "giảng viên cho phép") — trả lời bằng bước gợi ý tiếp theo hoặc review phần nhóm đã làm (tinh thần mục 3a của `SKILL.md`).

### 1.6. Code: thang gợi ý

Áp dụng cho mọi đoạn code của bài tập lớn (posting, kiểm tra, filling, query, report):

| Bậc | Nội dung | Không được có |
|---|---|---|
| 1 — Hướng đi | Cơ chế nào giải quyết vấn đề và vì sao; bài nào trong giáo trình dạy cơ chế đó | Tên handler, tên module, danh sách bước |
| 2 — Dùng gì, đặt ở đâu | Event/handler, module, compilation directive, virtual table, method cần dùng; thứ tự các bước | Code chạy được |
| 3 — Khung | Khung code có chỗ trống `___`, comment mô tả từng dòng | Query trọn vẹn, vòng posting trọn vẹn |

- **Mỗi lần trả lời tối đa một bậc**, trừ khi nhóm đã cho thấy mình đã thử (dán code, mô tả lỗi cụ thể, nói đã làm gì).
- Review code nhóm tự viết: chỉ ra dòng sai, nguyên nhân gốc, gợi ý sửa đúng dòng đó; không viết lại cả procedure.
- Cần minh họa một cơ chế: dùng object và tình huống **khác** đề của nhóm (đặt tên trung tính như `DocA`, `RegisterX`), hoặc dùng code demo trong file bài học (có dòng `Nguồn:`).
- Code viết mới không có trong file bài: ghi **"code minh họa — chạy thử để kiểm chứng"**.

---

## 2. Lộ trình 6 bước từ nghiệp vụ đến hệ thống

Các bước đi theo thứ tự, nhưng được phép quay lại: phát hiện ở bước 5 thường làm nhóm sửa bước 3 hoặc 4. Khuyến khích nhóm ghi **nhật ký quyết định** (quyết định gì, lý do, phương án đã loại) — đó là bằng chứng tư duy khi bảo vệ.

### Bước 1 — Hồ sơ doanh nghiệp & phạm vi

**Mục tiêu:** có một doanh nghiệp giả định đủ cụ thể để mọi quyết định thiết kế sau này có căn cứ.

**Câu hỏi gợi mở:**

*Quy mô và ngành*
- Doanh nghiệp bán gì: hàng hóa, dịch vụ, hay cả hai? Hàng có đặc điểm gì đáng quản lý (hạn dùng, kích cỡ/màu, số serial, hàng cồng kềnh)?
- Quy mô: bao nhiêu mặt hàng, bao nhiêu khách hàng, bao nhiêu nhà cung cấp, bao nhiêu chứng từ mỗi ngày/tháng?
- Có mấy kho, mấy cửa hàng/chi nhánh? Hàng có di chuyển giữa các điểm không?
- Có một hay nhiều pháp nhân (company)?

*Khách hàng, nhà cung cấp, thanh toán*
- Bán cho ai: khách lẻ, đại lý, doanh nghiệp? Có hợp đồng không?
- Bán thu tiền ngay hay bán chịu? Có hạn thanh toán, có trả trước không?
- Mua của ai, đặt hàng trước bao lâu, nhận hàng một lần hay nhiều đợt?
- Thu chi bằng tiền mặt, chuyển khoản, hay cả hai? Có mấy quỹ, mấy tài khoản ngân hàng?

*Giá và chính sách*
- Giá bán cố định hay thay đổi theo thời gian, theo nhóm khách, theo số lượng?
- Có chiết khấu, khuyến mãi không? Ai được quyết định giá?

*Con người*
- Ai làm việc gì: nhân viên mua hàng, bán hàng, thủ kho, thủ quỹ, kế toán, giám đốc? Một người có kiêm nhiều việc không?

*Phạm vi*
- Trong 4 phân hệ mua – kho – bán – tiền, nhóm làm sâu phần nào, làm mỏng phần nào?
- Những gì **ngoài phạm vi** (kế toán tổng hợp, thuế, sản xuất, lương, nhiều tiền tệ…)? Nói rõ để không bị hỏi vì sao thiếu.

**Sản phẩm đầu ra:**
- Hồ sơ doanh nghiệp 1–2 trang: ngành, quy mô (có số liệu), cơ cấu kho/chi nhánh, đối tác, chính sách thanh toán và giá, các vai trò.
- Bảng phạm vi: trong phạm vi / ngoài phạm vi / giả định đơn giản hóa (ví dụ "không xét thuế").
- 3–5 **câu hỏi quản lý** mà hệ thống phải trả lời được (ví dụ "hôm nay kho nào còn bao nhiêu hàng X?"). Các câu này sẽ quyết định register ở bước 5 và report ở bước 6.

**Lỗi hay gặp:**
- Hồ sơ chung chung ("công ty thương mại vừa và nhỏ") → không có căn cứ để chọn giữa các phương án.
- Phạm vi quá rộng (đủ mọi thứ) → bước 5 không kịp làm posting tử tế.
- Không ghi "ngoài phạm vi" → khi bảo vệ bị hỏi những thứ nhóm chưa từng định làm.
- Câu hỏi quản lý mơ hồ ("quản lý tốt tồn kho") — không kiểm chứng được.

### Bước 2 — Mô tả quy trình nghiệp vụ

**Mục tiêu:** mô tả **ai làm gì, khi nào, với giấy tờ gì** trong doanh nghiệp của nhóm — trước khi nghĩ tới 1C.

**Câu hỏi gợi mở:**
- Quy trình hiện tại (as-is) của doanh nghiệp giả định là gì? Đang gặp vấn đề gì (mất hàng, không biết ai nợ bao nhiêu, giá bán sai…)?
- Quy trình mong muốn (to-be) thay đổi những gì để giải quyết vấn đề đó? Thay đổi nào cần hệ thống, thay đổi nào chỉ là quy định nội bộ?
- Mỗi quy trình bắt đầu bằng **sự kiện** gì (khách gọi đặt hàng, hàng về cổng kho, đến hạn trả tiền) và kết thúc ở trạng thái nào?
- Mỗi bước do **vai trò** nào làm? Có bước nào cần người khác duyệt không?
- Ở đời thực, bước đó tạo ra **giấy tờ** gì (phiếu, hóa đơn, biên bản, sổ tay)? Giấy tờ đó có ký, có đánh số không?
- Có ngoại lệ nào: hàng giao thiếu, khách trả lại, hủy đơn, thanh toán một phần, kiểm kê lệch?

**Gợi ý định dạng (chỉ định dạng, không phải nội dung):**
- Sơ đồ **swimlane** hoặc **BPMN** mức đơn giản: mỗi lane là một vai trò; hộp là hoạt động; hình thoi là quyết định; ký hiệu tài liệu cho giấy tờ.
- Kèm mỗi sơ đồ một bảng mô tả bước với các cột: *STT – Sự kiện kích hoạt – Hoạt động – Vai trò – Giấy tờ vào/ra – Ngoại lệ*.
- Mỗi quy trình một sơ đồ; không gộp cả 4 phân hệ vào một sơ đồ khổng lồ, nhưng đánh dấu rõ điểm nối sang quy trình khác.

**Sản phẩm đầu ra:**
- Sơ đồ as-is và to-be (hoặc chỉ to-be nếu đề cho phép) cho từng phân hệ trong phạm vi.
- Bảng mô tả bước như trên.
- Danh sách ngoại lệ nhóm **sẽ** xử lý và ngoại lệ **không** xử lý.

**Lỗi hay gặp:**
- Vẽ quy trình theo màn hình phần mềm ("mở form, bấm Post") thay vì theo nghiệp vụ.
- Vẽ quy trình "sách giáo khoa" không khớp hồ sơ ở bước 1 (doanh nghiệp bán lẻ tại quầy nhưng quy trình có báo giá, đơn hàng, hợp đồng).
- Không có vai trò (lane) → bước 6 không có căn cứ phân quyền.
- Bỏ qua ngoại lệ → bước 5 không nghĩ tới trả hàng, thanh toán một phần.

### Bước 3 — Từ sự kiện nghiệp vụ đến chứng từ

**Mục tiêu:** quyết định bước nào trong quy trình trở thành **Document** trong 1C, bước nào không.

Hai nguyên tắc (giáo trình, `references/terminology.md` mục 2):
- **Không phải bước nghiệp vụ nào cũng thành Document.** Document phản ánh một nghiệp vụ/sự kiện, luôn gắn với thời gian, và có thể được post (Bài 3, `bai-01-04.md` mục "Document").
- **Không phải Document nào cũng ghi register.** Chỉ chứng từ làm thay đổi số liệu cần theo dõi mới cần register records; document dịch vụ không phản ánh nghiệp vụ thực có thể tắt posting (Bài 11, `bai-11.md` mục "Posting mode").

**Câu hỏi gợi mở (hỏi cho từng bước trong bảng ở bước 2):**
- Bước này có phải là một **sự kiện có thời điểm** cần lưu lại (ai, khi nào, bao nhiêu) không? Hay chỉ là thao tác xem, gọi điện, kiểm tra?
- Có cần tra lại sau này, in ra, đánh số, hay làm căn cứ cho bước sau không?
- Bước này có **làm thay đổi** một con số nhóm phải theo dõi (tồn kho, công nợ, tiền trong quỹ, doanh số) không? Nếu có → ứng viên Document có posting. Nếu không → Document không posting, hoặc không phải Document.
- Bước này có phải chỉ là **thay đổi trạng thái** của một chứng từ đã có (duyệt, giao hàng xong) không? Nếu vậy, cần document riêng hay chỉ cần một attribute trạng thái? (Bài 12, Practice 12 bài tập 7–8 minh họa attribute trạng thái kiểu Enumeration và lịch sử trạng thái — dùng để học cơ chế, không phải mẫu quy trình.)
- Hai bước liền nhau có luôn xảy ra cùng lúc, cùng người không? Nếu có, có nên gộp thành một chứng từ? (xem mẫu 5.1)
- Chứng từ sau có được **tạo dựa trên** chứng từ trước không (cơ chế Generation, Bài 11)?

**Sản phẩm đầu ra:** bảng ánh xạ với các cột:

| Bước quy trình | Thành Document? (Có/Không/Gộp với…) | Lý do | Có posting? | Thay đổi số liệu nào | Tạo dựa trên chứng từ nào |
|---|---|---|---|---|---|

**Lỗi hay gặp:**
- Mỗi hộp trong sơ đồ thành một Document → hệ thống nặng thao tác, người dùng phải nhập lại dữ liệu nhiều lần.
- Dùng Document cho thứ không có thời điểm (danh sách khách hàng, bảng giá cố định) — đó là dữ liệu chủ hoặc thiết lập (bước 4).
- Bật posting cho mọi Document "cho chắc" mà không biết nó ghi gì.
- Không có chứng từ cho ngoại lệ đã cam kết xử lý (trả hàng, điều chỉnh kiểm kê).

### Bước 4 — Mô hình dữ liệu

**Mục tiêu:** chọn đúng **loại metadata object** cho từng loại thông tin và giải thích được lựa chọn.

Phân loại thông tin trước khi chọn object:
- **Dữ liệu chủ (master data)** — đối tượng tồn tại lâu, được tham chiếu nhiều lần: mặt hàng, đối tác, kho, nhân viên.
- **Giao dịch (transactions)** — sự kiện có thời điểm: các chứng từ ở bước 3.
- **Trạng thái / số dư (states/balances)** — con số tích lũy từ giao dịch: tồn kho, công nợ, tiền.
- **Thông tin theo thời gian / thiết lập (settings)** — giá có hiệu lực từ ngày, người phụ trách, tham số hệ thống.

Giáo trình phân biệt **object entities** (có reference, mỗi object duy nhất suốt vòng đời: catalog, document, chart of characteristic types…) và **non-object entities** (mọi register — record là phản ánh một thông tin, đổi key fields là đổi ý nghĩa record) — Bài 15, `bai-15.md` mục "Object và non-object entities". Đây là câu hỏi gốc: thứ nhóm đang mô tả là **một đối tượng** hay **một sự thật về đối tượng**?

**Bảng quyết định chọn loại object:**

| Nếu thông tin là… | Ứng viên | Câu hỏi để kiểm chứng | Bài học |
|---|---|---|---|
| Danh sách đối tượng người dùng tự thêm, có thuộc tính riêng, được chọn ở nhiều nơi | **Catalog** | Người dùng có thêm/sửa phần tử khi vận hành không? Có cần hierarchy (nhóm) hay Owner (phụ thuộc) không? | Bài 3–4 — `bai-01-04.md` mục "Catalog", "Hierarchy", "Subordination (Owner)" |
| Tập giá trị cố định, thuật toán dựa vào từng giá trị, người dùng không được thêm | **Enumeration** | Code có rẽ nhánh theo giá trị này không? Người dùng có bao giờ cần thêm giá trị mới? | Bài 3 — `bai-01-04.md` mục "Enumeration"; Practice 12 bài tập 7 (`bai-12.md`) |
| Phần tử ổn định mà thuật toán cần biết trước trong một Catalog | **Predefined data** của Catalog | Thuật toán có đang tìm phần tử theo Code/Description không? | Bài 4 — `bai-01-04.md` mục "Predefined data" |
| Một giá trị duy nhất cho cả hệ thống, ít khi đổi | **Constant** | Có một giá trị hay nhiều giá trị theo đối tượng/thời gian? Có đổi định kỳ không? | Bài 13 — `bai-13.md` mục "Constants" |
| Bật/tắt cả một phần chức năng | **Functional option** (lưu trong constant, catalog attribute hoặc resource của information register) | Có doanh nghiệp/company nào không dùng chức năng này không? | Bài 15 — `bai-15.md` mục "Functional options" |
| Sự kiện có thời điểm, có người tạo, có thể làm thay đổi số liệu | **Document** | Đã qua bảng ở bước 3 chưa? | Bài 3 — `bai-01-04.md` mục "Document"; Bài 11 |
| Thông tin gắn với một tổ hợp khóa, không phải số tích lũy, **không** cần lịch sử | **Information register** không periodic | Tổ hợp dimensions nào là duy nhất? | Bài 12 — `bai-12.md` mục "Information registers" |
| Thông tin thay đổi theo thời gian, cần biết giá trị **tại một ngày** | **Information register periodic** (Periodicity Day/Month…) + SliceLast | Tối đa đổi mấy lần mỗi ngày? Đổi qua chứng từ (subordinate to recorder) hay sửa trực tiếp (Independent)? | Bài 12 — mục "Periodic information registers", "Write mode"; Practice 12 bài tập 9 |
| Con số tích lũy cần **số dư tại một thời điểm** (còn bao nhiêu) | **Accumulation register** kind **Balances** | Có cần hỏi "còn lại bao nhiêu tại ngày X" không? | Bài 11 — `bai-11.md` mục "Register kind", "Bảng của register kiểu Balances" |
| Con số tích lũy chỉ cần **phát sinh trong kỳ** (bao nhiêu trong tháng) | **Accumulation register** kind **Turnovers** | Có bao giờ cần số dư không? Nếu không → Turnovers | Bài 11 — mục "Bảng của register kiểu Turnovers"; Practice 11 bài tập 7 |
| Thuộc tính mà thành phần và kiểu chưa biết trước, người dùng tự thêm | **Chart of characteristic types** + information register lưu giá trị | Mỗi nhóm hàng có thuộc tính khác nhau? Người dùng cần tự thêm thuộc tính mới mà không sửa configuration? | Bài 13 — `bai-13.md` mục "Charts of characteristic types" |
| Xem chung nhiều loại chứng từ trong một danh sách | **Document journal** | Người dùng có cần xem chung không, hay chỉ "cho đẹp"? | Bài 13 — mục "Document journals" |
| Hạch toán kế toán kép theo tài khoản | **Chart of accounts** + **Accounting register** | Kế toán có trong phạm vi không? | Bài 24 — `bai-24.md` |
| Dữ liệu chi tiết dạng dòng thuộc một object | **Tabular section** | Dòng có tồn tại độc lập ngoài object cha không? | Bài 3 — `bai-01-04.md` mục "Catalog" (tabular section lưu ở bảng riêng) |

**Câu hỏi gợi mở:**
- Liệt kê mọi "danh từ" trong hồ sơ và quy trình. Mỗi danh từ thuộc loại thông tin nào trong 4 loại trên?
- Với mỗi Catalog: những attribute nào thực sự được dùng (trong chứng từ, report, thuật toán)? Attribute nào chỉ "cho đủ"?
- Thông tin này **có thay đổi theo thời gian** và có cần biết **giá trị cũ** không? (quyết định attribute của catalog hay periodic information register — xem mẫu 5.3)
- Một đối tác vừa là khách vừa là nhà cung cấp thì biểu diễn thế nào? (Practice 9 bài tập 5 minh họa một cách — chỉ để học cơ chế, nhóm tự quyết theo nghiệp vụ.)
- Thuật toán nào đang dựa vào dữ liệu người dùng có thể sửa (code, tên)? Có nên chuyển sang Enumeration hoặc Predefined data không?

**Sản phẩm đầu ra:**
- Danh sách metadata object, mỗi object kèm: loại, mục đích (1 câu), lý do chọn loại này thay vì loại khác, attribute/tabular section chính.
- Sơ đồ quan hệ (object nào tham chiếu object nào).
- Quy ước đặt tên (Name tiếng Anh, Synonym tiếng Việt hoặc ngược lại — nhất quán).

**Lỗi hay gặp:**
- Dùng Catalog cho tập giá trị cố định mà code dựa vào → người dùng thêm/xóa làm hỏng thuật toán (lỗi hay gặp của Practice 12 bài tập 7).
- Dùng Constant cho giá trị thay đổi theo đối tượng hoặc theo thời gian (Bài 13: không dùng constant cho giá trị thay đổi liên tục).
- Lưu số dư (tồn kho, công nợ) thành attribute của Catalog và cộng trừ bằng code → mất lịch sử, sai khi sửa chứng từ cũ. Giáo trình giải thích vì sao dùng register (Bài 11, mục "Accumulation register — mục đích").
- Information register trùng tổ hợp dimensions (+ Period) → exception khi ghi (Bài 12).
- Đặt tên không nhất quán, tên tiếng Việt không dấu lẫn tiếng Anh.

### Bước 5 — Thiết kế ghi sổ (posting)

**Mục tiêu:** với từng Document có posting, xác định nó ghi vào register nào, với dimensions/resources nào, để trả lời đúng các câu hỏi quản lý ở bước 1.

Nhắc lại cơ chế (Bài 11, `bai-11.md`):
- Accumulation register gồm **Dimensions** (theo cái gì), **Resources** (con số tích lũy), **Attributes** (thông tin bổ sung). Records chỉ thay đổi qua **recorder** documents.
- Posting của Document ghi movements trong handler **Posting** qua **RegisterRecords**; record set có `Write = True` được nền tảng ghi khi thoát Posting.
- Register kind Balances: virtual tables Balance, Turnovers, BalanceAndTurnovers. Register kind Turnovers: chỉ Turnovers; record không có RecordType, giảm thì ghi số âm (Practice 11 bài tập 7).

**Đi từ câu hỏi quản lý ngược về register:**
1. Lấy từng câu hỏi quản lý ở bước 1. Câu hỏi đó cần **số dư** hay **phát sinh trong kỳ**? → kind Balances hay Turnovers.
2. Câu hỏi "theo cái gì" (theo kho? theo mặt hàng? theo khách? theo chứng từ gốc?) → **dimensions**. Đây là **độ chi tiết (grain)** của register.
3. Câu hỏi "bao nhiêu" (số lượng? tiền?) → **resources**.
4. Chứng từ nào làm con số đó tăng, chứng từ nào làm giảm? → **recorders** và RecordType (Receipt/Expense).

**Bảng thiết kế posting (khung để nhóm tự điền):**

| Document | Register | RecordType (Receipt/Expense hoặc dấu với Turnovers) | Dimensions lấy từ đâu (header/tabular section nào) | Resources lấy từ đâu | Câu hỏi quản lý được phục vụ |
|---|---|---|---|---|---|

**Câu hỏi kiểm chứng:**
- Dimension này phục vụ **report nào / câu hỏi nào**? Nếu không trả lời được → có thể thừa.
- Có câu hỏi quản lý nào **không** trả lời được từ register hiện có? → thiếu dimension hoặc thiếu register.
- Grain có quá chi tiết không? (thêm dimension làm tăng số dòng và làm thao tác nhập phức tạp hơn — xem mẫu 5.2)
- Mỗi register có ít nhất một chứng từ làm tăng và một làm giảm chưa? Nếu chỉ tăng → con số bao giờ về 0?
- Ngoại lệ (trả hàng, hủy, điều chỉnh) ghi vào register thế nào? Dấu có đúng không?
- Có cần **chặn âm** (không xuất quá tồn, không chi quá quỹ) không? Nếu có: kiểm tra ở đâu, lúc nào?
- Chứng từ có cần biết số dư **ngay trước nó** trên trục thời gian (nhiều chứng từ cùng giây)?
- Nếu một chứng từ ghi hai register: ghi trong một vòng lặp hay hai? Record wizard có xử lý được nhiều tabular section không?

**Cơ chế giáo trình liên quan (chỉ đường, không phải lời giải):**
- **Kiểm tra dữ liệu trước khi post** (thiếu thông tin, điều kiện logic giữa các field): FillCheckProcessing, Required field, CheckFilling() — Bài 12, `bai-12.md` mục "Data validation". Lưu ý: FillCheckProcessing chạy trước khi object được ghi, nên không đọc được movements của chính document.
- **Kiểm soát số dư âm** sau khi ghi movements: ghi record set bằng `Write()` trong Posting, rồi đọc virtual table Balance tại `PointInTime` kèm `Boundary` Including — Bài 11 mục "Date, PointInTime, Boundary"; Practice 12 bài tập 6 (`bai-12.md`).
- **Hủy posting và báo lỗi**: Cancel = True (báo được mọi dòng lỗi) vs Raise (ngắt ngay) — Bài 12 mục "Transactions".
- **Posting nằm trong transaction**: các event Posting/OnWrite chạy trong transaction do nền tảng mở; AfterWriteAtServer chạy sau commit — Bài 12 mục "Transactions"; Bài 16 mục "Thứ tự events" (`bai-16.md`).
- **Bật/tắt kiểm soát theo thiết lập**: constant hoặc functional option — Bài 13 Practice 13 bài tập 1; Bài 15.
- **Truyền thông tin từ BeforeWrite sang Posting/OnWrite**: AdditionalProperties — Bài 11 mục "AdditionalProperties".
- **Giá vốn / batch** (nếu nhóm chọn theo dõi): Bài 14 Practice bài tập 8, Bài 15 Practice bài tập 5–6, Bài 16 Practice bài tập 4–7 — đọc để học cơ chế FIFO/LIFO trong giáo trình, rồi nhóm tự quyết có cần không.
- **Bút toán kế toán** (nếu trong phạm vi): Bài 24 — accounting register, posting với ExtDimensions.

**Sản phẩm đầu ra:**
- Danh sách register: tên, kind, dimensions, resources, recorders, câu hỏi quản lý phục vụ.
- Bảng thiết kế posting như trên cho mọi document có posting.
- Danh sách kiểm tra (validation) và nơi đặt kiểm tra.
- Kịch bản kiểm thử: chuỗi chứng từ mẫu + số dư kỳ vọng sau mỗi chứng từ.

**Lỗi hay gặp:**
- Register thiết kế theo cảm tính, không truy về câu hỏi quản lý.
- Chọn Balances cho thứ chỉ cần phát sinh (chạy được nhưng Turnovers của register Balances luôn đọc movement table — Bài 11).
- Gán RecordType cho register kind Turnovers → lỗi (Practice 11 bài tập 7).
- Kiểm tra số dư trong FillCheckProcessing → không thấy movements của chính chứng từ (Practice 12 bài tập 6).
- Dùng lại Record wizard sau khi đã sửa tay → code Posting bị thay toàn bộ (Bài 11).
- Quên tabular section thứ hai (ví dụ dòng dịch vụ) khi posting.
- Thêm dimension mới mà không re-post chứng từ cũ → số dư theo dimension mới bị trống (Practice 14 bài tập 8).

### Bước 6 — Báo cáo, phân quyền, giao diện

**Mục tiêu:** người dùng của từng vai trò thấy đúng phần việc của mình, và các câu hỏi quản lý có report trả lời.

**Báo cáo (Bài 18, `bai-18.md`; Bài 17, `bai-17.md`):**
- Mỗi câu hỏi quản lý ở bước 1 ↔ ít nhất một report. Report đọc từ **register** (virtual table Balance / Turnovers / BalanceAndTurnovers), không cộng dồn từ chứng từ.
- Câu hỏi gợi mở: Report này ai xem, bao lâu một lần? Cần lọc theo gì (kỳ, kho, đối tác)? Nhóm theo gì? Cần đầu kỳ – nhập – xuất – cuối kỳ không?
- Cơ chế: DCS — data set Query, resources, parameters (StandardPeriod), filter, settings, roles of fields (Bài 18). Report điền template bằng code là phương án khác khi bố cục cố định (Bài 17 mục "Reports với programmatic template filling").
- Nhắc: đặt điều kiện trong **parameters của virtual table**, không ở WHERE (Bài 11 mục "Lấy dữ liệu từ virtual tables").

**Print forms (Bài 17, Bài 22):**
- Chứng từ nào đời thực cần in (phiếu nhập, phiếu xuất, hóa đơn, phiếu thu)? Bảng ở bước 2 đã ghi giấy tờ đời thực — dùng lại.
- Cơ chế: template spreadsheet document, Print form wizard, named areas (Bài 17). Print subsystem của **SSL (Standard Subsystems Library)** chỉ dùng nếu configuration của nhóm có nhúng SSL (Bài 22 — khóa học dùng SSL demo; configuration trống thì không có sẵn).

**Phân quyền (Bài 20, `bai-20.md`):**
- Mỗi lane (vai trò) ở bước 2 ↔ một role, hoặc một nhóm role.
- Câu hỏi gợi mở: Vai trò này cần **đọc** gì, **thêm/sửa** gì, **post** gì? Có ai không được thấy giá vốn, không được sửa giá? Ai được xóa?
- Cơ chế: role theo chức danh vs role chi tiết ("granulated"); 3 role bắt buộc (FullAccess…); không cấp Update cho accumulation register cho người dùng thường và dùng **Post in privileged mode** / **Unpost in privileged mode** (Practice 20 bài tập 6); privileged mode.

**Giao diện (Bài 9, Bài 14):**
- Subsystems = các section chính; mỗi object nằm trong một hoặc nhiều subsystem (Bài 9 mục "Subsystems").
- Command interface: thứ tự section, visibility theo role, main section (Bài 14 mục "Command interface").
- Commands: tạo chứng từ dựa trên chứng từ khác (Generation, Bài 11), parameterizable commands (Bài 14).
- Form: bố cục, conditional appearance, choice parameter links để lọc lựa chọn (Bài 4, Bài 9).

**Sản phẩm đầu ra:**
- Danh sách report: câu hỏi quản lý – register nguồn – parameters/filter – người dùng.
- Ma trận quyền: role × object × quyền (Read / Insert / Update / Delete / Post…).
- Cấu trúc subsystem và nội dung từng subsystem.
- Danh sách print form.

**Lỗi hay gặp:**
- Report query thẳng tabular section của chứng từ thay vì register → chậm, sai khi chứng từ chưa post hoặc đã unpost.
- Chỉ có role FullAccess → không chứng minh được thiết kế phân quyền.
- Subsystem theo loại object ("Danh mục", "Chứng từ") thay vì theo phần việc → người dùng phải đi khắp nơi.
- Quên kiểm thử với user của từng role (Practice 20 bài tập 7).

---

## 3. Kiểm tra liên kết giữa 4 phân hệ

Bốn phân hệ mua – kho – bán – tiền **chia sẻ dữ liệu**. Tutor dùng các câu hỏi dưới đây để nhóm tự kiểm tra thiết kế của chính mình. **Không có đáp án đúng chung** — đáp án đúng là đáp án khớp với hồ sơ và quy trình của nhóm, và nhất quán giữa sơ đồ quy trình, bảng chứng từ và bảng posting.

### 3.1. Câu hỏi nhóm phải trả lời được

*Mua – kho – tiền*
- Khi nhận hàng, **công nợ phải trả** phát sinh lúc nào trong quy trình của nhóm: lúc nhận hàng, lúc nhận hóa đơn, hay lúc khác? Chứng từ nào ghi nhận?
- Nếu hàng về trước, hóa đơn về sau (hoặc ngược lại), số liệu tồn kho và công nợ trong khoảng giữa thể hiện thế nào?
- Nhận thiếu, nhận thừa, hàng lỗi trả lại nhà cung cấp: chứng từ nào, ghi giảm cái gì?
- Trả tiền trước cho nhà cung cấp (nếu có) thể hiện ở đâu, và được trừ vào khoản phải trả nào?

*Bán – kho – tiền*
- Hàng **rời kho** lúc nào: lúc lập hóa đơn, lúc giao hàng, lúc khách nhận? Chứng từ nào làm giảm tồn kho?
- **Doanh thu và công nợ phải thu** ghi nhận lúc nào? Có trùng thời điểm với lúc hàng rời kho không?
- Nếu đặt hàng trước: đơn hàng có giữ hàng (giảm số "có thể bán") không, hay chỉ là thông tin?
- Khách trả lại hàng: tồn kho tăng lại ở kho nào, doanh số giảm thế nào, công nợ giảm thế nào, giá trị hàng nhập lại tính theo giá nào?

*Tiền*
- Một phiếu thu/chi gắn với **một** chứng từ, **nhiều** chứng từ, hay chỉ gắn với đối tác?
- Thu một phần, thu thừa, thu trước: số liệu công nợ hiển thị thế nào?
- Chuyển tiền giữa quỹ và ngân hàng: là một chứng từ hay hai? Có làm thay đổi công nợ không?

*Dùng chung*
- Một đối tác vừa mua vừa bán: công nợ hai chiều được xem riêng hay bù trừ?
- Register nào được **nhiều phân hệ** cùng ghi? Ai trong nhóm chịu trách nhiệm cấu trúc register đó? Đổi dimension thì những posting nào phải sửa?
- Số liệu kiểm tra chéo: tổng giá trị nhập – xuất – tồn có khớp với tổng mua – bán không? Tổng phải thu có khớp với bán chịu trừ đã thu không?

### 3.2. Các điểm tích hợp — phương án và đánh đổi

Mỗi điểm dưới đây có nhiều cách hợp lệ. Tutor đưa các phương án để nhóm cân nhắc, rồi hỏi nhóm chọn theo nghiệp vụ nào.

**(a) Nhận hàng và hóa đơn mua**

| Phương án | Ưu | Nhược | Hợp khi |
|---|---|---|---|
| Một chứng từ ghi cả tăng kho và tăng phải trả | Ít thao tác, posting đơn giản | Không biểu diễn được hàng về trước/hóa đơn về sau | Hàng và hóa đơn luôn đi cùng nhau |
| Hai chứng từ: nhận hàng (tăng kho) và hóa đơn (tăng phải trả) | Phản ánh đúng chênh lệch thời điểm, phân tách vai trò thủ kho/kế toán | Thêm chứng từ, phải đối chiếu hai chứng từ, cần xử lý trường hợp lệch số lượng | Nhận nhiều đợt, hóa đơn đến muộn, thủ kho và kế toán là người khác nhau |
| Một chứng từ, có trạng thái (ví dụ "đã nhận hàng" / "đã có hóa đơn") quyết định posting | Ít loại chứng từ | Logic posting phụ thuộc trạng thái, khó kiểm thử; lịch sử thay đổi cần lưu riêng | Trạng thái thay đổi ít, nhóm muốn học cơ chế trạng thái (Bài 12) |

Hỏi nhóm: "Trong doanh nghiệp của nhóm, có ngày nào hàng đã trong kho mà chưa có hóa đơn không?"

**(b) Giao hàng và hóa đơn bán**
- Tương tự (a) với chiều ngược lại. Thêm câu hỏi: ai lập hóa đơn, ai xuất kho? Có bán dịch vụ (không qua kho) trong cùng hóa đơn không?
- Hỏi nhóm: "Nếu tách hai chứng từ, report doanh thu đọc từ chứng từ nào, report tồn kho đọc từ chứng từ nào?"

**(c) Phân bổ thanh toán** — xem mẫu 5.4.

**(d) Trả hàng**

| Phương án | Ưu | Nhược |
|---|---|---|
| Chứng từ trả hàng riêng, tạo dựa trên chứng từ bán/mua gốc (Generation) | Truy được chứng từ gốc, lấy được giá gốc | Thêm một loại chứng từ, phải kiểm tra không trả quá số đã bán |
| Chứng từ trả hàng riêng, không gắn chứng từ gốc | Linh hoạt (trả hàng mua từ nhiều lần) | Khó xác định giá trị hàng nhập lại, khó kiểm soát trả quá |
| Dùng chính chứng từ bán/mua với số lượng âm | Không thêm loại chứng từ | Dễ nhầm dấu, report và print form phức tạp hơn, khó phân quyền riêng |

Giáo trình có Practice 11 bài tập 4–6 (chứng từ trả hàng tạo bằng Generation) để học **cơ chế Generation và ghi register ngược dấu**, không phải mẫu bắt buộc.

---

## 4. Checklist review thiết kế

Dùng khi nhóm gửi bản nháp. Không cần đi hết mọi dòng trong một lần trả lời — chọn 3–5 vấn đề lớn nhất, mỗi vấn đề kèm câu hỏi gợi mở.

**A. Nhất quán với nghiệp vụ**
- [ ] Hồ sơ doanh nghiệp có số liệu cụ thể (số kho, số mặt hàng, chính sách thanh toán)?
- [ ] Phạm vi trong/ngoài được ghi rõ; thiết kế không vượt phạm vi mà không có lý do?
- [ ] Có 3–5 câu hỏi quản lý kiểm chứng được?

**B. Quy trình ↔ chứng từ**
- [ ] Mỗi Document truy được về một bước trong sơ đồ quy trình?
- [ ] Mỗi bước có thay đổi số liệu trong sơ đồ có chứng từ tương ứng (hoặc lý do gộp)?
- [ ] Ngoại lệ đã cam kết xử lý có chứng từ/cơ chế?
- [ ] Vai trò thực hiện mỗi bước khớp với role ở bước 6?

**C. Đặt tên**
- [ ] Name theo quy ước nhất quán (ví dụ tiếng Anh, PascalCase), Synonym dễ hiểu cho người dùng?
- [ ] Catalog đặt tên theo đối tượng (số nhiều), register đặt tên theo thông tin nó lưu (gợi ý của Bài 15: đặt tên phản ánh loại entity)?
- [ ] Không có tên mơ hồ (`Data1`, `Doc`, `Info`)?

**D. Lý do chọn loại object**
- [ ] Mỗi object có một câu "vì sao loại này, không phải loại kia"?
- [ ] Không có Catalog cho tập giá trị cố định mà code dựa vào (→ Enumeration/Predefined)?
- [ ] Không có Constant cho giá trị thay đổi theo đối tượng hoặc thời gian?
- [ ] Thông tin thay đổi theo thời gian mà cần giá trị cũ đã dùng periodic information register?
- [ ] Information register: tổ hợp dimensions (+ Period) thực sự duy nhất? Write mode (Independent / subordinate to recorder) có lý do?

**E. Grain của register**
- [ ] Mỗi accumulation register có kind (Balances/Turnovers) đúng với câu hỏi (số dư hay phát sinh)?
- [ ] Mỗi dimension phục vụ ít nhất một report/câu hỏi?
- [ ] Có câu hỏi quản lý nào không trả lời được vì thiếu dimension?
- [ ] Resources là số (accumulation register); thông tin không phải số nằm ở attribute hoặc chỗ khác?

**F. Posting đầy đủ**
- [ ] Mỗi register có chứng từ tăng và chứng từ giảm?
- [ ] RecordType/dấu đúng cho từng chứng từ, kể cả trả hàng/điều chỉnh?
- [ ] Mọi tabular section liên quan đều được duyệt khi posting?
- [ ] Kiểm tra dữ liệu đặt đúng chỗ (FillCheckProcessing cho dữ liệu của chính chứng từ; kiểm tra số dư sau khi ghi movements)?
- [ ] Có kịch bản kiểm thử với số dư kỳ vọng?

**G. Khả thi của report**
- [ ] Mỗi report đọc từ register, với virtual table phù hợp?
- [ ] Filter đặt trong parameters của virtual table?
- [ ] Report trả lời đúng câu hỏi quản lý ở bước 1 với đúng grain?

**H. Phân quyền và giao diện**
- [ ] Có role cho từng vai trò ở sơ đồ quy trình, không chỉ FullAccess?
- [ ] Người dùng thường không sửa trực tiếp được register; chứng từ post được nhờ Post in privileged mode?
- [ ] Subsystem theo phần việc; mỗi role thấy đúng phần của mình?
- [ ] Đã thử đăng nhập bằng user của từng role?

**I. Code (nếu đã có)**
- [ ] Mọi procedure trong form module có compilation directive phù hợp (Bài 7)?
- [ ] Logic dùng chung đặt ở common module/object module, không lặp ở nhiều form (Bài 7, Bài 14)?
- [ ] Không có query trong vòng lặp (Bài 10)?
- [ ] Khối Except không rỗng, có ghi Event log (Bài 12)?

---

## 5. Các mẫu thiết kế đa phương án

Mỗi mẫu là một quyết định lặp lại trong hầu hết các nhóm. Các phương án được liệt kê **ngang hàng, không có phương án mặc định**. Tutor chỉ đưa mẫu khi nhóm đang đứng trước đúng quyết định đó, và luôn kết thúc bằng câu hỏi về nghiệp vụ của nhóm.

### 5.1. Một chứng từ hay tách đơn hàng + hóa đơn

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Chỉ một chứng từ bán (hoặc mua) | Đơn giản, ít nhập liệu, posting gọn | Không theo dõi được đơn chưa giao/chưa nhận, không có kế hoạch |
| B. Đơn hàng (không ghi tồn kho) + hóa đơn tạo dựa trên đơn hàng | Theo dõi được đơn mở, so sánh đặt – giao; Generation giảm nhập lại | Thêm chứng từ; cần quyết định đơn hàng có ghi register riêng (ví dụ "đơn còn phải giao") hay không |
| C. Đơn hàng có ghi register "đặt/giữ hàng" + hóa đơn ghi giảm register đó | Biết chính xác còn bao nhiêu chưa giao, hỗ trợ giữ hàng | Thêm register, posting phức tạp hơn, phải xử lý giao thiếu/hủy đơn |

Hỏi nhóm: "Khách của nhóm có đặt trước không? Có giao nhiều đợt không? Quản lý có cần biết 'đơn còn treo' không?"

Cơ chế liên quan: Generation (Bài 11), Document không posting (Bài 11 mục "Posting mode"), Turnovers vs Balances (Bài 11).

### 5.2. Theo dõi tồn kho: chỉ theo kho, hay thêm vị trí/lô

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Dimensions: mặt hàng + kho | Gọn, dễ nhập, đủ cho đa số câu hỏi "còn bao nhiêu ở đâu" | Không biết hàng nằm ở kệ nào, không truy được lô/hạn dùng |
| B. Thêm dimension vị trí (khu/kệ) | Hỗ trợ soạn hàng, kiểm kê theo khu | Mọi chứng từ kho phải ghi vị trí; chuyển vị trí trong kho cũng thành nghiệp vụ |
| C. Thêm dimension lô (batch) | Truy xuất nguồn gốc, hạn dùng, giá vốn theo lô (FIFO/LIFO) | Xuất kho phải chọn/phân bổ lô; posting phức tạp; cần re-post khi đổi cấu trúc |

Hỏi nhóm: "Câu hỏi quản lý nào của nhóm cần biết lô hoặc vị trí? Nếu không có, chi phí nhập liệu thêm có đáng không?"

Cơ chế liên quan: dimension của accumulation register (Bài 11); batch và phân bổ FIFO/LIFO trong giáo trình (Bài 14 Practice bài tập 7–8, Bài 15 Practice bài tập 5–6, Bài 16 Practice bài tập 4–5).

### 5.3. Giá bán: attribute của mặt hàng hay information register

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Attribute giá trong Catalog mặt hàng | Đơn giản nhất | Mất lịch sử giá; không có nhiều loại giá; đổi giá không để lại dấu vết |
| B. Periodic information register, Write mode Independent | Có lịch sử, lấy giá tại ngày bằng SliceLast | Người có quyền sửa trực tiếp register, khó biết ai đổi và vì sao |
| C. Periodic information register subordinate to recorder + chứng từ đặt giá | Có lịch sử, có chứng từ làm dấu vết, phân quyền được người đặt giá | Thêm chứng từ; một chứng từ không được có hai dòng cùng mặt hàng (trùng dimensions + Period) |
| (biến thể) Thêm dimension loại giá / nhóm khách | Nhiều bảng giá song song | Thêm catalog loại giá; chứng từ bán phải biết dùng loại giá nào |

Hỏi nhóm: "Giá của nhóm đổi bao lâu một lần? Có cần biết giá cũ không? Ai được đổi giá?"

Cơ chế liên quan: Bài 12 mục "Periodic information registers", "Write mode", "Đọc dữ liệu information register"; Practice 12 bài tập 9–10.

### 5.4. Theo dõi công nợ: theo đối tác hay theo từng chứng từ

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Accumulation register Balances, dimension đối tác | Đơn giản; biết ngay mỗi đối tác nợ bao nhiêu | Không biết khoản nợ nào chưa trả, không tính được tuổi nợ |
| B. Thêm dimension hợp đồng | Theo dõi theo từng hợp đồng | Mọi chứng từ phải có hợp đồng; vẫn không biết từng hóa đơn |
| C. Thêm dimension chứng từ gốc (hóa đơn) | Biết từng hóa đơn còn nợ bao nhiêu, tính được quá hạn | Phiếu thu/chi phải phân bổ cho từng hóa đơn; trả trước/trả gộp phức tạp hơn |
| D. Không dùng register; tìm hóa đơn chưa thanh toán bằng query trên chứng từ | Không thêm register | Chậm khi dữ liệu lớn, khó xử lý thanh toán một phần; giáo trình chỉ ra hạn chế của việc tính từ chứng từ (Bài 11 mục "Accumulation register — mục đích") |

Hỏi nhóm: "Quản lý của nhóm hỏi 'khách A nợ bao nhiêu' hay 'hóa đơn nào quá hạn'? Khách có trả gộp nhiều hóa đơn một lần không?"

Cơ chế liên quan: accumulation register (Bài 11); Practice 10 bài tập 10–12 (chứng từ thanh toán có tabular section chứng từ gốc, query LEFT JOIN + IS NULL) — dùng để học cơ chế query, không phải mẫu bắt buộc. Kiểu dimension "chứng từ gốc" có thể là composite type nếu nhận nhiều loại chứng từ — giáo trình nhắc hạn chế của composite type ở Bài 9 (`bai-09.md`, mục "Associating items with form attributes": không lấy attribute qua reference được) và Bài 10 (`bai-10.md`, CAST với composite type).

### 5.5. Tiền mặt và ngân hàng: một register hay hai

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Một register tiền, dimension "nơi giữ tiền" kiểu composite (quỹ hoặc tài khoản ngân hàng) | Một report tổng tiền; chuyển quỹ ↔ ngân hàng là một chứng từ ghi hai dòng | Composite type phức tạp hơn khi lọc và chọn; phân quyền thủ quỹ/kế toán ngân hàng trên cùng register |
| B. Một register, dimension catalog chung "nơi giữ tiền" với attribute loại (quỹ/ngân hàng) | Một kiểu dữ liệu đơn giản | Catalog chung trộn hai loại đối tượng có thuộc tính khác nhau (ngân hàng có số tài khoản, quỹ thì không) |
| C. Hai register riêng (tiền mặt, tiền gửi) | Tách bạch, phân quyền dễ | Report tổng tiền phải gộp hai nguồn (UNION hoặc DCS union data set); chuyển tiền ghi vào hai register |

Hỏi nhóm: "Thủ quỹ và người làm ngân hàng có phải là một người không? Quản lý cần xem tổng tiền thường xuyên không?"

Cơ chế liên quan: composite type (Bài 9 — hạn chế khi lấy attribute qua reference; Bài 10 — CAST); UNION (Bài 10); data set Union trong DCS (Bài 18 mục "Data sets"); roles (Bài 20).

### 5.6. Thu/chi: chứng từ theo hướng hay theo phương tiện

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Bốn chứng từ: thu tiền mặt, chi tiền mặt, thu ngân hàng, chi ngân hàng | Mỗi chứng từ đơn giản, print form riêng, phân quyền dễ | Nhiều chứng từ giống nhau, code lặp (nên dùng common module — Bài 14) |
| B. Hai chứng từ: thu và chi, attribute chọn quỹ/ngân hàng | Ít loại chứng từ | Form phải đổi theo lựa chọn; print form có điều kiện |
| C. Một chứng từ "giao dịch tiền" với attribute hướng (Enumeration) | Ít nhất | Posting và kiểm tra nhiều nhánh; khó phân quyền "chỉ được thu không được chi" |

Hỏi nhóm: "Giấy tờ đời thực của nhóm có mấy loại phiếu? Ai được thu, ai được chi?"

### 5.7. Trạng thái chứng từ: attribute hay chứng từ riêng

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Attribute trạng thái (Enumeration), posting phụ thuộc trạng thái | Một chứng từ đi suốt vòng đời | Logic posting nhiều nhánh; không biết ai đổi trạng thái khi nào (trừ khi lưu lịch sử) |
| B. A + periodic information register lưu lịch sử trạng thái | Có dấu vết ai/khi nào | Thêm register, ghi trong transaction (BeforeWrite → AdditionalProperties → OnWrite) |
| C. Mỗi trạng thái quan trọng là một chứng từ riêng (duyệt, giao…) | Rõ ràng, phân quyền theo bước | Nhiều chứng từ, người dùng thao tác nhiều |

Hỏi nhóm: "Trạng thái có làm thay đổi số liệu không? Quản lý có cần biết lịch sử không?"

Cơ chế liên quan: Practice 12 bài tập 7–8 (`bai-12.md`); Bài 16 mục "Thứ tự events". Cơ chế Business process/Task của platform **không có trong giáo trình** (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).

### 5.8. Thuộc tính mở rộng của mặt hàng: attribute cố định hay chart of characteristic types

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Attribute cố định trong Catalog | Đơn giản, dễ dùng trong query và form | Mỗi thuộc tính mới phải sửa configuration; nhiều cột trống với mặt hàng không dùng |
| B. Chart of characteristic types + information register giá trị | Người dùng tự thêm thuộc tính; không tốn cột thừa | Phức tạp khi thiết lập; query phải join nhiều lần; phải cấu hình Additional metadata object characteristics |
| C. Tabular section "thuộc tính" trong Catalog (tên – giá trị dạng chuỗi) | Linh hoạt, không cần chart | Không kiểm soát kiểu và giá trị ("đỏ", "Đỏ", "do"); khó lọc và báo cáo |

Hỏi nhóm: "Hàng của nhóm có những thuộc tính khác nhau theo nhóm hàng không? Người dùng có cần tự thêm thuộc tính?"

Cơ chế liên quan: Bài 13 mục "Charts of characteristic types", "Dùng characteristics trong query".

---

## 6. Ánh xạ khái niệm → bài học

Khi nhóm hỏi kỹ thuật, đọc đúng file bài và mục dưới đây trước khi trả lời. Nếu cơ chế không có trong giáo trình, ghi rõ "(ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant)".

| Cơ chế nhóm cần | File | Mục / bài thực hành tham khảo |
|---|---|---|
| Metadata class/object/data object, reference, primitive types | `references/lessons/bai-01-04.md` | Bài 2 |
| Composite type và hạn chế của nó | `references/lessons/bai-09.md`, `bai-10.md` | Bài 9 mục "Associating items with form attributes"; Bài 10 mục "Type casting (CAST)" |
| Catalog, hierarchy, Owner, predefined data, numbering, tabular section | `references/lessons/bai-01-04.md` | Bài 3–4 |
| Enumeration | `references/lessons/bai-01-04.md` | Bài 3 mục "Enumeration" |
| Document, Number/Date/Posted, numbering theo năm | `references/lessons/bai-01-04.md` | Bài 3 mục "Document", Bài 4 mục "Code, number, autonumbering" |
| Cú pháp, collections (ValueTable, Structure…) | `references/lessons/bai-05-06.md` | — |
| Đặt code đúng chỗ, compilation directives, object/manager/common module | `references/lessons/bai-07.md` | mục "Code placement" |
| Debugger, Performance snapshot | `references/lessons/bai-08.md` | — |
| Subsystems, form, choice parameters, conditional appearance | `references/lessons/bai-09.md` | — |
| Query, joins, temporary tables, batch query, IS NULL | `references/lessons/bai-10.md` | Practice 10 bài tập 6, 12 |
| Accumulation register, Balances vs Turnovers, virtual tables | `references/lessons/bai-11.md` | mục "Register kind", "Lấy dữ liệu từ virtual tables" |
| Posting, RegisterRecords, Record wizard, posting mode | `references/lessons/bai-11.md` | mục "Document posting", "Posting mode" |
| PointInTime, Boundary | `references/lessons/bai-11.md` | mục "Date, PointInTime, Boundary" |
| Generation (tạo chứng từ dựa trên chứng từ khác), Filling | `references/lessons/bai-11.md` | mục "Generation"; Practice 10 bài tập 10–11 |
| AdditionalProperties, IsNew() | `references/lessons/bai-11.md` | mục "AdditionalProperties" |
| FillCheckProcessing, Required field, CheckFilling() | `references/lessons/bai-12.md` | mục "Data validation" |
| Kiểm soát số dư âm khi post | `references/lessons/bai-12.md` | Practice 12 bài tập 6 |
| Information register, periodic, SliceLast, Write mode, RecordSet/RecordManager | `references/lessons/bai-12.md` | mục "Information registers" … "RecordSet và RecordManager"; Practice 12 bài tập 9 |
| Transactions, Cancel vs Raise, Try…Except, Event log | `references/lessons/bai-12.md` | mục "Transactions", "Errors…", "Event log" |
| Constants, Constants form | `references/lessons/bai-13.md` | mục "Constants"; Practice 13 bài tập 1 |
| Document journals | `references/lessons/bai-13.md` | mục "Document journals" |
| Chart of characteristic types | `references/lessons/bai-13.md` | mục "Charts of characteristic types" |
| Common modules, reuse return values | `references/lessons/bai-14.md` | mục "Common modules" |
| Commands, command interface | `references/lessons/bai-14.md` | mục "Commands", "Command interface" |
| Functional options | `references/lessons/bai-15.md` | mục "Functional options" |
| Object vs non-object entities, referential integrity, xóa object | `references/lessons/bai-15.md` | — |
| Thứ tự events khi write/post, event subscriptions | `references/lessons/bai-16.md` | mục "Thứ tự events", "Event subscriptions" |
| Batch, FIFO/LIFO, giá vốn | `bai-14.md`, `bai-15.md`, `bai-16.md`, `bai-17.md` | Practice 14 bài tập 7–8; Practice 15 bài tập 5–6; Practice 16 bài tập 4–7; Practice 17 bài tập 1 |
| Print forms, template, report điền template bằng code | `references/lessons/bai-17.md` | — |
| Report DCS | `references/lessons/bai-18.md` | — |
| Data processors, import Excel (nạp dữ liệu đầu kỳ, bảng giá) | `references/lessons/bai-19.md` | — |
| Roles, access rights, privileged mode, Post in privileged mode | `references/lessons/bai-20.md` | Practice 20 bài tập 3, 6, 7 |
| SSL (Standard Subsystems Library) — chỉ khi configuration nhúng SSL | `references/lessons/bai-21.md`, `bai-22.md`, `bai-23.md` | — |
| Chart of accounts, accounting register | `references/lessons/bai-24.md` | — |
| Configuration extensions (Patch / Customization / Add-on) | `references/lessons/bai-extensions.md` | — |

**Không có trong giáo trình** (nếu nhóm hỏi, trả lời kèm nhãn "(ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant)" và khuyên cân nhắc có thật cần trong phạm vi không): Business processes và Tasks, Exchange plans, Sequences, Charts of calculation types, Managed locks khi posting đồng thời, nhiều tiền tệ và tỷ giá.

**Nhắc thuật ngữ khi trả lời** (`references/terminology.md`): metadata object được **tạo từ prototype**, không "kế thừa"; module là container rỗng với các event có tên định sẵn, không "tự sinh code"; **Posting chỉ có ở Document**; **SSL = Standard Subsystems Library**, khác với Extensions.
