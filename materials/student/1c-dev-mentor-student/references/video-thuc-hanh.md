# Chuỗi video thực hành case study (xây từ cấu hình rỗng) ↔ bài giáo trình ↔ lộ trình người học

> Cập nhật 07/10/2026. Nguồn: Phần 1 — playlist "Tuyển tập các bài tập thực hành 1C:Enterprise" (https://www.youtube.com/playlist?list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2; 6 bài + 1 đoạn mở đầu 5 giây); Phần 2 — playlist "(TEMP) Tuyển tập các bài tập thực hành 1C:Enterprise" (https://www.youtube.com/playlist?list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM; 14 video). Mỗi video dựng một bài toán nghiệp vụ từ cấu hình rỗng, làm từng bước trong Designer. Nội dung đã kiểm chứng bằng transcript.

**Về đánh số:** tiêu đề video đánh "Bài 1 … Bài 20" theo thứ tự riêng của chuỗi, **không** trùng số bài giáo trình. Phần 2 bắt đầu từ "Bài 7", không có "Bài 9", "Bài 19" có hai bản (Full/Short), và hiện dừng ở "Bài 20". Khi nói với người học, dùng tên video; khi nói thứ tự trong lộ trình, nói "video thứ k của lộ trình".

## Cách dùng

- Người học hỏi "nên học/xem gì", "mới bắt đầu, không biết gì", "muốn làm theo từng bước", hoặc hỏi lộ trình → Mục A chọn đúng nhóm.
- Lộ trình J đang làm một đề cụ thể → Mục B (kết hợp cả video giải đáp).
- Người học gặp một tình huống cụ thể → `references/video-qa-thuc-chien.md` Mục A (có cả tình huống lấy từ chuỗi này).
- Câu dẫn cho người học (giống quy ước video bài giảng): "🎬 Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](<link>)" — với tình huống lỗi có thể nói "tham khảo cách xử lý <tình huống> của khóa tại đây". Dùng **tên hiển thị** trong bảng (đã bỏ "Bài N:" và hậu tố tên kênh). Không nêu số "Bài N" của video (khác số bài giáo trình), không dùng mã QA-/P1-/P2- (chỉ để tra nội bộ), không gọi là "khóa cũ".
- Video dựng **ví dụ minh họa**. Với lộ trình M, nói rõ đây là ví dụ kỹ thuật, không phải thiết kế mẫu cho hệ thống của nhóm (nhóm vẫn tự chọn object theo doanh nghiệp của mình).
- Mỗi thẻ có "Lưu ý khi giới thiệu": chỗ video đơn giản hóa hoặc chưa chặt. Với D/M, có thể biến các lưu ý này thành bài tập nâng cấp ("thử sửa để chặn một sinh viên thuê hai xe").

## A. Lộ trình theo nhóm người học

### A1. Bắt đầu từ con số 0 hoặc sinh viên trái ngành — nắm vững thao tác Designer mà không bị ngợp

Giảng viên khuyến nghị: học theo chuỗi từ video "Ghi nhận luân chuyển dòng tiền" (cuối Phần 1) qua hết Phần 2. Chưa cài nền tảng thì xem trước [Cài đặt 1C:Enterprise phiên bản đào tạo](https://www.youtube.com/watch?v=sJqX17GGRt0&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=3) (2:19).

1. [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) — quỹ tiền mặt: thu/chi, posting, số dư trên form và đánh số chứng từ _(mã nội bộ P1-6)_
2. [Ghi nhận thay đổi tỷ giá hối đoái](https://www.youtube.com/watch?v=9_m7XqHPZlA&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=1) (9:04) — information register theo ngày và biểu đồ _(mã nội bộ P2-1)_
3. [Ghi nhận thay đổi giá mua tiền tệ](https://www.youtube.com/watch?v=lYPmr3Rxi3g&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=2) (8:11) — information register nhiều dimension _(trùng nhiều với video trước — có thể bỏ qua)_ _(mã nội bộ P2-2)_
4. [Lưu trữ và báo cáo kết quả học tập của sinh viên](https://www.youtube.com/watch?v=NhFE1uwi7Hw&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=3) (14:56) — chấm điểm qua chứng từ và báo cáo trung bình có tô màu _(mã nội bộ P2-3)_
5. [Hệ thống cho thuê xe điện](https://www.youtube.com/watch?v=wWGXT2KSul8&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=4) (10:40) — một chứng từ ghi vào hai register _(mã nội bộ P2-4)_
6. [Tạo lập hệ thống thông tin thư viện](https://www.youtube.com/watch?v=3DMFgUjg2Js&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=5) (24:38) — mượn – trả và tạo phiếu trả từ phiếu mượn _(mã nội bộ P2-5)_
7. [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28) — xử lý nhiều đơn hàng bằng một lệnh _(nâng cao (code client-server, command) — có thể để cuối)_ _(mã nội bộ P2-6)_
8. [Hạch toán sản phẩm dịch vụ](https://www.youtube.com/watch?v=GFsS9x1bOTQ&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=7) (15:54) — tách hàng hóa/dịch vụ và bật tắt tính năng bằng Functional option _(mã nội bộ P2-7)_
9. [Hạch toán thu nhập theo doanh số](https://www.youtube.com/watch?v=QRAzQKBCtds&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=8) (20:00) — quy đổi tỷ giá khi posting bằng SliceLast _(mã nội bộ P2-8)_
10. [Bắt lần khởi động đầu tiên](https://www.youtube.com/watch?v=Q9op8HgLMtM&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=9) (9:05) — xử lý lần chạy đầu tiên của ứng dụng _(mã nội bộ P2-9)_
11. [Hạch toán hàng hóa - Bài toán đơn giản nhất](https://www.youtube.com/watch?v=SwgfC-uA6Eg&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=10) (16:55) — nhập – xuất – tồn và chặn âm kho _(mã nội bộ P2-10)_
12. [Hạch toán hàng hóa - Hạch toán một kho](https://www.youtube.com/watch?v=BD370AtszHI&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=11) (20:57) — tồn kho theo từng kho (kho trên đầu chứng từ) _(mã nội bộ P2-11)_
13. [Hạch toán hàng hóa nhiều kho (Full)](https://www.youtube.com/watch?v=HIAYMOepPw4&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=12) (18:40) — kho trên từng dòng hàng và chặn âm theo từng kho _(chọn bản này hoặc bản Short ngay sau)_ _(mã nội bộ P2-12)_
14. [Hạch toán hàng hóa nhiều kho (Short)](https://www.youtube.com/watch?v=sHl70mbjk4c&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=13) (14:51) — sửa cấu trúc chứng từ đang có dữ liệu _(chỉ xem nếu đã làm "Hạch toán một kho"; nếu không thì xem bản Full)_ _(mã nội bộ P2-13)_
15. [Hạch toán hàng hóa - Theo hạn sử dụng](https://www.youtube.com/watch?v=TBgeOMXYp0w&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=14) (13:24) — tồn kho theo hạn sử dụng và xuất dần theo lô _(nâng cao — query batch, xuất dần theo lô)_ _(mã nội bộ P2-14)_

Gợi ý khi hướng dẫn: mỗi video, người học tự làm lại trên infobase của mình rồi trả lời một câu "vì sao" (vì sao dùng register này, vì sao đặt code ở module này). Nếu video đầu tiên (dòng tiền) quá dày với người hoàn toàn mới, có thể xem trước ba video Catalog/chứng từ đơn giản của Phần 1 (sinh viên – môn học, nhân viên, du lịch) — đây là đề xuất bổ sung, không thuộc khuyến nghị gốc.

### A2. Làm bài tập lớn / đồ án trên 1C:Jet

Giảng viên khuyến nghị: tham khảo chuỗi Phần 1, đặc biệt video "du lịch" và "dòng tiền" vì đây là các mô hình nghiệp vụ cốt lõi thường gặp trong đồ án.

1. [Giới thiệu nền tảng 1C:Enterprise](https://www.youtube.com/watch?v=Dahr2ACNN74&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=2) (13:59) — tổng quan nền tảng 1C:Enterprise _(mã nội bộ P1-1)_
2. [Cài đặt 1C:Enterprise phiên bản đào tạo](https://www.youtube.com/watch?v=sJqX17GGRt0&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=3) (2:19) — cài đặt bản 1C:Enterprise đào tạo _(mã nội bộ P1-2)_
3. [Lưu trữ thông tin sinh viên và môn học](https://www.youtube.com/watch?v=UGXVLOKRaGw&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=4) (12:19) — Catalog, phân cấp và tabular section _(mã nội bộ P1-3)_
4. [Lưu trữ thông tin nhân viên](https://www.youtube.com/watch?v=WF19J3tct0I&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=5) (9:37) — catalog cấp dưới và lịch sử lương theo tháng _(mã nội bộ P1-4)_
5. [Lưu trữ thông tin các chuyến du lịch](https://www.youtube.com/watch?v=PwqP4GODNrY&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=6) (13:15) — tạo chứng từ trên cơ sở chứng từ khác (Input on basis) _(★ mô hình "đặt trước → chứng từ thực hiện tạo trên cơ sở" (Create based on); trong Jet, phiếu thu/chi được tạo trên cơ sở hóa đơn SalesInvoice/SupplierInvoice theo đúng cơ chế này (`references/jet/jet-cash.md` mục 6))_ _(mã nội bộ P1-5)_
6. [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) — quỹ tiền mặt: thu/chi, posting, số dư trên form và đánh số chứng từ _(★ posting, accumulation register số dư, hiển thị số dư lên form, Document journal, Document numerator — đúng mô hình phân hệ CashManagement của Jet)_ _(mã nội bộ P1-6)_

Sau đó chọn video theo đề ở Mục B; khi gặp lỗi tra `references/video-qa-thuc-chien.md`.

**Lộ trình J (sinh viên Logistics, ít thời gian):** không xem cả chuỗi. Tối thiểu: video "dòng tiền" (hiểu posting và số dư) + video "du lịch" (hiểu tạo chứng từ trên cơ sở) + 1–2 video theo đề của nhóm (Mục B). Mỗi video xem xong, yêu cầu sinh viên chỉ ra chỗ tương ứng trong Jet (ví dụ register số dư quỹ ↔ register CashBalance của phân hệ CashManagement).

### A3. Sinh viên MIS tự xây hệ thống từ cấu hình trống (lộ trình M)

Chuỗi này sát nhất với việc nhóm M làm. Chọn theo khối chức năng nhóm đang xây:

- Tiền: [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29)
- Kho (tăng dần độ khó): [Hạch toán hàng hóa - Bài toán đơn giản nhất](https://www.youtube.com/watch?v=SwgfC-uA6Eg&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=10) (16:55) → [Hạch toán hàng hóa - Hạch toán một kho](https://www.youtube.com/watch?v=BD370AtszHI&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=11) (20:57) → [Hạch toán hàng hóa nhiều kho (Full)](https://www.youtube.com/watch?v=HIAYMOepPw4&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=12) (18:40) → [Hạch toán hàng hóa - Theo hạn sử dụng](https://www.youtube.com/watch?v=TBgeOMXYp0w&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=14) (13:24)
- Bán hàng, giá, tỷ giá: [Hạch toán sản phẩm dịch vụ](https://www.youtube.com/watch?v=GFsS9x1bOTQ&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=7) (15:54) · [Hạch toán thu nhập theo doanh số](https://www.youtube.com/watch?v=QRAzQKBCtds&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=8) (20:00) · [Ghi nhận thay đổi tỷ giá hối đoái](https://www.youtube.com/watch?v=9_m7XqHPZlA&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=1) (9:04)
- Đặt hàng / mua: [Lưu trữ thông tin các chuyến du lịch](https://www.youtube.com/watch?v=PwqP4GODNrY&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=6) (13:15) · [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28)
- Báo cáo có biểu đồ và tô màu: [Lưu trữ và báo cáo kết quả học tập của sinh viên](https://www.youtube.com/watch?v=NhFE1uwi7Hw&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=3) (14:56)

Nhắc nhóm: video là ví dụ kỹ thuật; quy trình và bộ object là do nhóm tự thiết kế theo doanh nghiệp của mình.

### A4. Intern Dev, nhân sự IT đối tác (lộ trình D)

Lướt nhanh Phần 1 để quen nghiệp vụ; tập trung các video có nhiều code và kỹ thuật:

- Thực hành: [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) · [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28) · [Hạch toán thu nhập theo doanh số](https://www.youtube.com/watch?v=QRAzQKBCtds&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=8) (20:00) · [Bắt lần khởi động đầu tiên](https://www.youtube.com/watch?v=Q9op8HgLMtM&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=9) (9:05) · [Hạch toán hàng hóa nhiều kho (Full)](https://www.youtube.com/watch?v=HIAYMOepPw4&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=12) (18:40) · [Hạch toán hàng hóa - Theo hạn sử dụng](https://www.youtube.com/watch?v=TBgeOMXYp0w&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=14) (13:24)
- Giải đáp thực chiến: [Tạo chức năng sửa password với vai trò người dùng](https://www.youtube.com/watch?v=taKIdmcCmIQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=9) (26:39) · [Kết nhập file excel vào danh mục sản phẩm](https://www.youtube.com/watch?v=DlXBXRzBJGw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=13) (38:42) · [Extension (Phần mở rộng) trong 1C:Enterprise](https://www.youtube.com/watch?v=T_DEaA1p_bA&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=22) (6:33) · [Chặn kết chuyển khi phát hiện tồn kho âm](https://www.youtube.com/watch?v=k2uht5J1f3c&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=25) (10:03) · [Hướng dẫn publish Infobase 1C:Enterprise lên web server](https://www.youtube.com/watch?v=P_bwSfxAV8I&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=28) (7:21)

Bài tập nâng cấp phù hợp nhóm D: sửa các điểm trong "Lưu ý khi giới thiệu" — kiểm tra theo PointInTime, lọc tồn theo cặp hàng – kho, gom query tỷ giá ra khỏi vòng lặp, chặn ghi ở object module thay vì form.

## B. Chọn video theo đề bài tập lớn trên Jet (cả hai playlist)

| Đề | Xem trước | Lấy gì từ video |
|---|---|---|
| Đề 1 — Lô hàng và hạn sử dụng | [Hạch toán hàng hóa - Theo hạn sử dụng](https://www.youtube.com/watch?v=TBgeOMXYp0w&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=14) (13:24) · [Hạch toán hàng hóa - Bài toán đơn giản nhất](https://www.youtube.com/watch?v=SwgfC-uA6Eg&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=10) (16:55) · [Chặn kết chuyển khi phát hiện tồn kho âm](https://www.youtube.com/watch?v=k2uht5J1f3c&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=25) (10:03) · [Lọc dữ liệu chọn sản phẩm theo hãng](https://www.youtube.com/watch?v=EfF2acfP2Y8&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=19) (6:30) · [Tự động lấy đơn vị tính của sản phẩm](https://www.youtube.com/watch?v=RKAGi62Vy5E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=12) (8:16) | tồn kho thêm chiều hạn dùng, xuất dần theo lô, chặn bán quá tồn; lọc lô theo sản phẩm khi chọn |
| Đề 2 — Định mức tồn kho chuỗi cửa hàng | [Báo động tồn kho thấp với màu chữ hiển thị](https://www.youtube.com/watch?v=0JbOMl80lnY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=18) (13:09) · [Truy vấn tồn kho trong chứng từ bán hàng](https://www.youtube.com/watch?v=13817kAvhwQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=17) (9:53) · [Hạch toán hàng hóa - Hạch toán một kho](https://www.youtube.com/watch?v=BD370AtszHI&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=11) (20:57) · [Xây dựng các trường tự động điền](https://www.youtube.com/watch?v=8klMmoJXBCk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=10) (2:02) · [Lưu trữ thông tin nhân viên](https://www.youtube.com/watch?v=WF19J3tct0I&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=5) (9:37) | tô màu khi dưới định mức, xem tồn khi chọn hàng, tồn theo kho/cửa hàng; ý tưởng lưu định mức theo kỳ bằng information register |
| Đề 3 — Đơn đặt hàng nhà cung cấp | [Lưu trữ thông tin các chuyến du lịch](https://www.youtube.com/watch?v=PwqP4GODNrY&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=6) (13:15) · [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28) · [Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng](https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1) (4:24) · [Lọc dữ liệu chọn sản phẩm theo hãng](https://www.youtube.com/watch?v=EfF2acfP2Y8&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=19) (6:30) · [Tạo chức năng in hóa đơn chứng từ](https://www.youtube.com/watch?v=uwEBQJZG6t4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=7) (5:31) | tạo chứng từ trên cơ sở đơn đặt, xử lý nhiều đơn, tính thành tiền khi đổi số lượng, lọc hàng theo NCC, in đơn |
| Đề 4 — Đánh giá nhà cung cấp | [Lưu trữ và báo cáo kết quả học tập của sinh viên](https://www.youtube.com/watch?v=NhFE1uwi7Hw&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=3) (14:56) · [Kiểm tra dữ liệu trùng lặp](https://www.youtube.com/watch?v=603j21ItABk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=11) (8:55) · [Hủy sự kiện đang thực thi](https://www.youtube.com/watch?v=rW40s85Gtc4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=16) (3:18) · [Báo cáo lợi nhuận theo kỳ](https://www.youtube.com/watch?v=98gDiVV8jx0&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=8) (9:16) | chấm điểm qua chứng từ → register → báo cáo trung bình có tô màu; chống trùng NCC; báo cáo theo kỳ |
| Đề 5 — Chiết khấu theo số lượng | [Lấy giá tự động](https://www.youtube.com/watch?v=oMowT1e019k&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=5) (8:32) · [Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng](https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1) (4:24) · [Hạch toán sản phẩm dịch vụ](https://www.youtube.com/watch?v=GFsS9x1bOTQ&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=7) (15:54) · [Xây dựng cơ chế tích điểm thưởng](https://www.youtube.com/watch?v=0aAaQQP9fXI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=14) (23:35) | tự điền giá, tính lại khi đổi số lượng, tính tổng tiền, điều chỉnh tiền phải trả |
| Đề 6 — Nhân viên kinh doanh và khu vực | [Lưu trữ thông tin nhân viên](https://www.youtube.com/watch?v=WF19J3tct0I&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=5) (9:37) · [Lọc dữ liệu chọn sản phẩm theo hãng](https://www.youtube.com/watch?v=EfF2acfP2Y8&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=19) (6:30) · [Lưu trữ thông tin sinh viên và môn học](https://www.youtube.com/watch?v=UGXVLOKRaGw&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=4) (12:19) · [Hướng dẫn thiết lập vai trò người dùng](https://www.youtube.com/watch?v=senxXwfjFxU&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=3) (3:38) | thông tin nhân viên và lịch sử theo kỳ, lọc lựa chọn theo khu vực, danh mục phân cấp, role |
| Đề 7 — Hạn thanh toán và tuổi nợ | [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) · [Báo cáo lợi nhuận theo kỳ](https://www.youtube.com/watch?v=98gDiVV8jx0&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=8) (9:16) · [Hủy sự kiện đang thực thi](https://www.youtube.com/watch?v=rW40s85Gtc4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=16) (3:18) | thu/chi và số dư theo đối tác, báo cáo theo kỳ, chặn ghi dữ liệu không hợp lệ |
| Đề 8 — Khoản mục chi phí và ngân sách | [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) · [Thực hiện tính toán đơn giản với SQL trong 1C](https://www.youtube.com/watch?v=dP21dfHxkCo&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=23) (2:59) · [Báo cáo lợi nhuận theo kỳ](https://www.youtube.com/watch?v=98gDiVV8jx0&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=8) (9:16) · [Hạch toán thu nhập theo doanh số](https://www.youtube.com/watch?v=QRAzQKBCtds&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=8) (20:00) | chi tiền ghi register, tính chênh lệch ngân sách – thực chi trong query, báo cáo theo kỳ, giá trị theo kỳ bằng information register |
| Đề 9 — Kiểm kê kho và xử lý chênh lệch | [Hạch toán hàng hóa - Bài toán đơn giản nhất](https://www.youtube.com/watch?v=SwgfC-uA6Eg&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=10) (16:55) · [Hạch toán hàng hóa - Hạch toán một kho](https://www.youtube.com/watch?v=BD370AtszHI&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=11) (20:57) · [Truy vấn tồn kho trong chứng từ bán hàng](https://www.youtube.com/watch?v=13817kAvhwQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=17) (9:53) · [Chặn kết chuyển khi phát hiện tồn kho âm](https://www.youtube.com/watch?v=k2uht5J1f3c&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=25) (10:03) · [Thực hiện tính toán đơn giản với SQL trong 1C](https://www.youtube.com/watch?v=dP21dfHxkCo&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=23) (2:59) | tồn theo kho, tồn sổ sách khi chọn hàng, chặn âm kho, tính chênh lệch trong query |
| Mọi đề — khi thêm object mới vào Jet | [Hiển thị đối tượng Siêu dữ liệu lên Quick menu](https://www.youtube.com/watch?v=rPSNKvFEQ8E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=21) (2:23) · [Cách hiển thị biểu ghi tích lũy lên phân hệ](https://www.youtube.com/watch?v=DBJeS7LfUpY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=4) (1:53) · [Extension (Phần mở rộng) trong 1C:Enterprise](https://www.youtube.com/watch?v=T_DEaA1p_bA&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=22) (6:33) · [Tạo chức năng in hóa đơn chứng từ](https://www.youtube.com/watch?v=uwEBQJZG6t4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=7) (5:31) | đưa object mới lên phân hệ, xem register khi kiểm tra posting, làm báo cáo bằng extension, bản in (trên Jet đăng ký qua SSL Print — Bài 22) |

Video quay trên cấu hình ví dụ, tên object khác Jet: dùng video để hiểu cơ chế, rồi tìm object tương ứng trong Jet (`references/jet/`).

## C. Thẻ video

### Phần 1

### Giới thiệu nền tảng 1C:Enterprise — 13:59

- Link: https://www.youtube.com/watch?v=Dahr2ACNN74&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=2
- Chủ đề để dẫn: tổng quan nền tảng 1C:Enterprise
- Video làm gì: Thuyết trình bằng slide: 1C Company, nền tảng = platform + applied solutions, low-code/RAD, DBMS hỗ trợ, kiến trúc 3 lớp, định hướng nghề nghiệp. Không thao tác Designer.
- Mốc xem nhanh: 0:31 Giới thiệu 3 nội dung: 1C Company, nền tảng, cơ hội nghề nghiệp/đối tác · 2:03 Số liệu quy mô 1C toàn cầu và tại Việt Nam · 4:39 Triết lý RAD/low-code: so sánh quy trình phát triển truyền thống với 1C · 6:13 Ngôn ngữ 1C: domain-specific, OOP, event-driven, script · 6:45 Hệ sinh thái: DBMS hỗ trợ, Designer, on-premise/cloud, đa nền tảng · 9:52 Tích hợp bên thứ ba (web service/API); ảnh Designer: Catalog, Attributes, Tabular section, Document, module · 11:57 Cơ hội đối tác (30/40/50% hoa hồng), cuộc thi, cộng đồng, khóa học
- Bài giáo trình: Bài 1 (chính); Bài 7
- Đề BTL Jet: —
- Nhóm phù hợp: J M D — mức nhập môn
- Lưu ý khi giới thiệu: Các con số (khách hàng, lập trình viên…) là tại thời điểm quay.
- _(mã nội bộ P1-1)_

### Cài đặt 1C:Enterprise phiên bản đào tạo — 2:19

- Link: https://www.youtube.com/watch?v=sJqX17GGRt0&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=3
- Chủ đề để dẫn: cài đặt bản 1C:Enterprise đào tạo
- Video làm gì: Tải và cài Training Version (chọn thành phần, ngôn ngữ giao diện), mở launcher, giới thiệu hai chế độ 1C:Enterprise và Designer.
- Mốc xem nhanh: 0:00 Vào trang cộng đồng 1C để tải bản Training Version · 0:30 Mở thư mục đã tải/giải nén, chạy bộ cài · 1:02 Chọn component (web server extension, additional interface languages EN/VI/RU), chọn ngôn ngữ English, Install, Finish · 1:33 Mở 1C từ Start menu; giới thiệu danh sách infobase · 1:33 Phân biệt chế độ 1C:Enterprise và Designer; hẹn các bài sau
- Bài giáo trình: Bài 1 (chính)
- Đề BTL Jet: —
- Nhóm phù hợp: J M D — mức nhập môn
- Lưu ý khi giới thiệu: Trang tải và giao diện bộ cài có thể đã đổi.
- _(mã nội bộ P1-2)_

### Lưu trữ thông tin sinh viên và môn học — 12:19

- Link: https://www.youtube.com/watch?v=UGXVLOKRaGw&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=4
- Chủ đề để dẫn: Catalog, phân cấp và tabular section
- Dựng từ cấu hình rỗng: Catalog Subjects, Catalog Students (hierarchy, tabular section), Report DCS
- Video làm gì: Từ cấu hình rỗng: Catalog Subjects; Catalog Students phân cấp (folder = lớp), số điện thoại có Mask, tabular section danh sách môn học; báo cáo DCS lọc sinh viên theo môn.
- Mốc xem nhanh: 0:30 Tạo infobase mới không cấu hình, chọn thư mục lưu trữ · 2:04 Tạo Catalog Students, bật Hierarchy (folders and items) — folder là lớp · 2:36 Tạo folder lớp VH1, VH2 và các sinh viên · 3:43 Tab Data: chỉnh độ dài/nhãn (Parent → Class) · 6:56 Thêm Tabular section danh sách môn học, Attribute Subject → CatalogRef.Subjects · 9:38 Settings wizard: List, group by Subject, order by Student · 11:04 Thêm Filter Subject vào user settings; chạy báo cáo, chọn môn Triết học
- Bài giáo trình: Bài 3 (chính); Bài 4, Bài 18, Bài 10
- Đề BTL Jet: Đề 6, Đề 2
- Nhóm phù hợp: M J D — mức cơ bản
- Lưu ý khi giới thiệu: Lưu môn học trong tabular section của sinh viên là thiết kế đơn giản hóa cho bài tập.
- _(mã nội bộ P1-3)_

### Lưu trữ thông tin nhân viên — 9:37

- Link: https://www.youtube.com/watch?v=WF19J3tct0I&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=5
- Chủ đề để dẫn: catalog cấp dưới và lịch sử lương theo tháng
- Dựng từ cấu hình rỗng: Catalog nhân viên (tabular section), Catalog con cái (Owner), Information register lương (periodic)
- Video làm gì: Từ cấu hình rỗng: Catalog nhân viên với tabular section quá trình công tác; catalog con cái là Subordinate catalog (Owner = nhân viên); information register lương Periodicity = Month (dimension nhân viên, Master) để mở từ form nhân viên.
- Mốc xem nhanh: 0:00 Tạo infobase mới cho bài nhân viên · 1:05 Tạo Catalog nhân viên, chạy thử nhập vài nhân viên · 2:38 Tạo Tabular section quá trình làm việc: nơi làm việc, chức vụ, ngày bắt đầu, ngày kết thúc (Date) · 4:12 Nhập thử; lưu ý chưa có kiểm tra ngày bắt đầu/kết thúc hợp lệ · 5:16 Tạo Catalog con cái, Owner = nhân viên, Attribute năm sinh Number(4) · 7:25 Tạo Information register lương: Periodic theo tháng, Independent, Resource lương, Dimension nhân viên (Master) · 8:28 Nhập lương từ form nhân viên, kiểm tra trong register
- Bài giáo trình: Bài 4 (chính); Bài 3, Bài 12, Bài 9
- Đề BTL Jet: Đề 6
- Nhóm phù hợp: M J D — mức cơ bản – trung bình
- Lưu ý khi giới thiệu: Chưa kiểm tra ngày kết thúc > ngày bắt đầu (bổ sung bằng FillCheckProcessing — Bài 12).
- _(mã nội bộ P1-4)_

### Lưu trữ thông tin các chuyến du lịch — 13:15

- Link: https://www.youtube.com/watch?v=PwqP4GODNrY&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=6
- Chủ đề để dẫn: tạo chứng từ trên cơ sở chứng từ khác (Input on basis)
- Dựng từ cấu hình rỗng: Catalog Customers, Visits; Enumeration; Document Booking, VisitExecution (Input on basis); Report DCS
- Video làm gì: Từ cấu hình rỗng: Catalog Customers, Visits; Document Booking; Enumeration phương thức thanh toán; Document VisitExecution tạo "Based on" Booking (Filling wizard tự sinh code); báo cáo DCS doanh thu theo phương thức thanh toán, chỉ lấy chứng từ đã post.
- Mốc xem nhanh: 0:32 Tạo Catalog Customers và Catalog Visits, nhập dữ liệu mẫu · 2:10 Tạo Document Booking với Customer, Visit · 4:18 Tạo Document VisitExecution: Booking, Customer, Visit, Total, PaymentMethod · 6:27 Tab Input on basis: VisitExecution dựa trên Booking, Filling wizard tự sinh code · 8:03 Thử tạo VisitExecution từ Booking (Create based on), nhập tổng tiền, Post · 10:43 Resources: SUM Total; Settings wizard List, group by PaymentMethod, order Total desc · 12:17 Chạy báo cáo, thêm chứng từ và chạy lại
- Bài giáo trình: Bài 3 (chính); Bài 16, Bài 18, Bài 10
- Đề BTL Jet: Đề 3, Đề 7
- Nhóm phù hợp: J M D — mức cơ bản
- Lưu ý khi giới thiệu: Không có tabular section và không ghi register; doanh thu lấy thẳng từ chứng từ — chuẩn giáo trình là ghi qua register (Bài 11).
- _(mã nội bộ P1-5)_

### Ghi nhận luân chuyển dòng tiền — 18:29

- Link: https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7
- Chủ đề để dẫn: quỹ tiền mặt: thu/chi, posting, số dư trên form và đánh số chứng từ
- Dựng từ cấu hình rỗng: Catalog Counterparties, 2 Document thu/chi, Document journal, Accumulation register (Balances), Document numerator
- Video làm gì: Từ cấu hình rỗng: Catalog Counterparties; chứng từ thu và chi tiền; Document journal gom hai chứng từ (lọc theo đối tác); accumulation register số dư quỹ ghi bằng Register records wizard; hiển thị số dư quỹ lên form bằng OnCreateAtServer + query bảng ảo Balance; Document numerator để hai loại phiếu đánh số liên tục.
- Mốc xem nhanh: 1:03 Tạo infobase mới, mở Designer · 2:39 Tạo Document CashReceipt: Counterparty, TotalAmount Number(14,2) không âm · 4:42 Copy CashReceipt thành Document chi tiền · 7:21 Lọc journal theo đối tác (More actions) · 8:52 Register records wizard: thu Receipt, chi Expense; Post lại các chứng từ, kiểm tra register · 11:01 Tạo form, form Attribute Balance; OnCreateAtServer + hàm lấy số dư bằng Query (Balances) · 15:19 Tạo Document numerator (Year) dùng chung cho 2 document; Mark for deletion, Delete marked objects; tạo lại chứng từ kiểm tra số liên tục
- Bài giáo trình: Bài 11 (chính); Bài 13, Bài 4, Bài 10, Bài 9, Bài 7
- Đề BTL Jet: Đề 7, Đề 8
- Nhóm phù hợp: J M D — mức trung bình
- Lưu ý khi giới thiệu: Register chỉ có resource, không có dimension (không tách theo quỹ/đối tác). Số dư tính khi mở form, không tự cập nhật; query không truyền Period.
- _(mã nội bộ P1-6)_

### Phần 2

### Ghi nhận thay đổi tỷ giá hối đoái — 9:04

- Link: https://www.youtube.com/watch?v=9_m7XqHPZlA&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=1
- Chủ đề để dẫn: information register theo ngày và biểu đồ
- Dựng từ cấu hình rỗng: Catalog Currencies (predefined), Information register (periodic Day), Report DCS Chart
- Video làm gì: Từ cấu hình rỗng: Catalog Currencies có Predefined (Dollar); information register tỷ giá Periodicity = Day; báo cáo DCS dạng Chart (đường) theo ngày và loại tiền.
- Mốc xem nhanh: 0:00 Tạo infobase mới · 0:31 Tạo Catalog Currencies, thêm Predefined items (Dollar…) · 1:33 Tạo Information register tỷ giá, Periodicity Day · 2:03 Resource ExchangeRate (Number), Dimension Currency · 3:05 Nhập tỷ giá cho các ngày cách quãng (dùng Copy để nhập nhanh) · 6:44 Settings wizard: Chart, Series Currency, Points Period, Line chart · 7:46 Phân tích điểm không có dữ liệu; chỉnh bổ sung kỳ (period addition)
- Bài giáo trình: Bài 12 (chính); Bài 4, Bài 18
- Đề BTL Jet: Đề 5, Đề 4
- Nhóm phù hợp: M J — mức cơ bản
- Lưu ý khi giới thiệu: Không dùng SliceLast; lấy tỷ giá hiện hành vẫn phải học Bài 12.
- _(mã nội bộ P2-1)_

### Ghi nhận thay đổi giá mua tiền tệ — 8:11

- Link: https://www.youtube.com/watch?v=lYPmr3Rxi3g&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=2
- Chủ đề để dẫn: information register nhiều dimension
- Dựng từ cấu hình rỗng: Catalog Currencies, Enumeration loại giao dịch, Information register 2 dimension, Report DCS Chart
- Video làm gì: Biến thể của video trước: thêm Enumeration Mua/Bán, information register giá theo ngày với hai dimension (loại tiền, loại giao dịch), biểu đồ có filter chọn giá mua hay giá bán.
- Mốc xem nhanh: 0:00 Tạo infobase mới · 1:34 Enumeration loại giao dịch: Mua, Bán · 1:34 Information register periodic Day, Resource Rate Number(10,2) · 2:06 Dimension Currency và loại giao dịch, bật không cho rỗng · 4:46 Tạo Report DCS, Query từ register, khai báo Resource · 6:21 Filter loại giao dịch vào user settings; chạy báo cáo · 6:51 Thử xóa Resource → biểu đồ không chạy; thêm lại
- Bài giáo trình: Bài 12 (chính); Bài 3, Bài 4, Bài 18
- Đề BTL Jet: Đề 5, Đề 3
- Nhóm phù hợp: M — mức cơ bản
- Lưu ý khi giới thiệu: Trùng nhiều với video tỷ giá; có thể chỉ xem một trong hai.
- _(mã nội bộ P2-2)_

### Lưu trữ và báo cáo kết quả học tập của sinh viên — 14:56

- Link: https://www.youtube.com/watch?v=NhFE1uwi7Hw&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=3
- Chủ đề để dẫn: chấm điểm qua chứng từ và báo cáo trung bình có tô màu
- Dựng từ cấu hình rỗng: Catalog Students, Subjects; Document buổi học (tabular section); Accumulation register; Report DCS (Average, Chart, Conditional appearance)
- Video làm gì: Từ cấu hình rỗng: Catalog Students, Subjects; Document buổi học với tabular section điểm; accumulation register điểm; báo cáo DCS điểm trung bình theo môn (parameter), biểu đồ và Conditional appearance 4 mức màu.
- Mốc xem nhanh: 0:32 Tạo infobase mới · 2:40 Tạo Document buổi học: Subject + Tabular section Student, Grade (0–10) · 3:43 Nhập vài buổi học (Hệ điều hành, Toán cao cấp) · 4:46 Tạo Accumulation register: Dimensions Student, Subject; Resource Grade · 6:49 Report DCS: Query từ register, điều kiện Subject = parameter · 8:56 Settings wizard: Chart, Student làm Points, order Grade tăng dần · 10:00 Conditional appearance 4 màu theo ngưỡng 8 / 6.5 / 5; chạy báo cáo theo môn
- Bài giáo trình: Bài 18 (chính); Bài 11, Bài 3, Bài 9
- Đề BTL Jet: Đề 4, Đề 2
- Nhóm phù hợp: J M — mức trung bình
- Lưu ý khi giới thiệu: Dùng accumulation register cho điểm là lựa chọn minh họa; điểm không phải đại lượng tích lũy thật.
- _(mã nội bộ P2-3)_

### Hệ thống cho thuê xe điện — 10:40

- Link: https://www.youtube.com/watch?v=wWGXT2KSul8&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=4
- Chủ đề để dẫn: một chứng từ ghi vào hai register
- Dựng từ cấu hình rỗng: Catalog Students; Document Purchase, Rental, Return; 2 Accumulation register (Balances); Report DCS
- Video làm gì: Từ cấu hình rỗng: Catalog Students; Document nhập xe, cho thuê, trả xe; hai accumulation register (xe trong kho, xe đang cho thuê theo sinh viên); báo cáo ai đang thuê xe.
- Mốc xem nhanh: 0:32 Tạo infobase "cho thuê xe điện" · 1:37 Document Purchase (Quantity), nhập 10 xe, Post · 2:43 Document Rental (Student) · 3:15 Copy Rental → Document Return · 4:21 Accumulation register xe đang thuê: Dimension Student (Copy register) · 8:30 Chạy thử: 3 sinh viên thuê, 1 trả; kiểm tra register · 9:00 Report DCS từ Balances register đang thuê, List Student
- Bài giáo trình: Bài 11 (chính); Bài 3, Bài 18, Bài 10
- Đề BTL Jet: Đề 9, Đề 1
- Nhóm phù hợp: M J — mức cơ bản – trung bình
- Lưu ý khi giới thiệu: Không chặn cho thuê khi hết xe và không chặn một sinh viên thuê 2 xe — bài tập tốt để tự bổ sung kiểm tra số dư khi posting.
- _(mã nội bộ P2-4)_

### Tạo lập hệ thống thông tin thư viện — 24:38

- Link: https://www.youtube.com/watch?v=3DMFgUjg2Js&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=5
- Chủ đề để dẫn: mượn – trả và tạo phiếu trả từ phiếu mượn
- Dựng từ cấu hình rỗng: Catalog Readers, Books; Document mượn, trả (Input on basis); Accumulation register; Report DCS
- Video làm gì: Từ cấu hình rỗng, giải thích kỹ: Catalog Readers (Mask điện thoại), Books (Format NG= cho năm); Document mượn sách với tabular section, Document trả sách tạo "Based on" phiếu mượn; register sách đang mượn theo độc giả; báo cáo DCS có filter.
- Mốc xem nhanh: 0:00 Tạo infobase "library" · 2:05 Attribute Phone String + Mask; hiển thị form Tabs · 5:11 Nhập dữ liệu mẫu (cập nhật cấu hình infobase) · 9:25 Document cho mượn sách: Reader + Tabular section ListOfBooks (Book) · 13:01 Input on basis: trả sách dựa trên mượn sách, Filling wizard · 15:41 Accumulation register BorrowedBooks: Dimensions Book, Reader; Resource Quantity · 20:53 Report DCS từ Balances; List, group Reader, order; Filter Reader/Book trong user settings
- Bài giáo trình: Bài 11 (chính); Bài 3, Bài 9, Bài 16, Bài 18
- Đề BTL Jet: Đề 3, Đề 9
- Nhóm phù hợp: J M — mức cơ bản – trung bình
- Lưu ý khi giới thiệu: Không kiểm tra trả sách chưa mượn và không quản lý số bản sách.
- _(mã nội bộ P2-5)_

### Hệ thống thông tin cửa hàng nhỏ — 12:28

- Link: https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6
- Chủ đề để dẫn: xử lý nhiều đơn hàng bằng một lệnh
- Dựng từ cấu hình rỗng: Catalog Customers, Products; Document Order, OrderProcess; Command có parameter; Filter criteria; Report
- Video làm gì: Từ cấu hình rỗng: Document Order; Document xử lý đơn có tabular section danh sách đơn; Command có parameter mở form xử lý và truyền các đơn đã chọn (OnCreateAtServer đọc Parameters); tìm chứng từ theo sản phẩm bằng Filter criteria.
- Mốc xem nhanh: 0:30 Tạo infobase mới · 2:01 Document Order: Customer + Tabular section Products (Product, Quantity) · 3:39 Document OrderProcess: Tabular section Orders (DocumentRef.Order) · 4:09 Tạo form document, handler OnCreateAtServer đọc Parameters điền Orders; Syntax check · 8:52 Chạy thử: chọn đơn hàng, bấm lệnh → mở OrderProcess đã điền đơn · 10:28 Report DCS Query từ filter criterion, parameter Product · 11:32 Settings List, order; parameter type CatalogRef.Products; chạy với "kem ốc quế"
- Bài giáo trình: Bài 14 (chính); Bài 9, Bài 16, Bài 7, Bài 18
- Đề BTL Jet: Đề 3
- Nhóm phù hợp: M D — mức nâng cao
- Lưu ý khi giới thiệu: Đoạn code transcript nghe không rõ, cần xem trực tiếp. Filter criteria (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant); cách thường dùng hơn là query vào tabular section.
- _(mã nội bộ P2-6)_

### Hạch toán sản phẩm dịch vụ — 15:54

- Link: https://www.youtube.com/watch?v=GFsS9x1bOTQ&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=7
- Chủ đề để dẫn: tách hàng hóa/dịch vụ và bật tắt tính năng bằng Functional option
- Dựng từ cấu hình rỗng: Catalog ProductsAndServices, Counterparties, Currencies; Document Sale; Constant; Functional option; Report DCS
- Video làm gì: Từ cấu hình rỗng: Catalog ProductsAndServices (IsService); Document Sale có hai tabular section Products/Services lọc bằng Choice parameters; tổng tiền tính ở BeforeWrite; Constant + Functional option ẩn/hiện đa tiền tệ; báo cáo DCS.
- Mốc xem nhanh: 0:30 Tạo infobase mới "Bài 14 hạch toán sản phẩm dịch vụ" từ cấu hình rỗng · 2:37 Nhập dữ liệu mẫu ở chế độ 1C:Enterprise (công ty, USD, sản phẩm Vinamilk, dịch vụ giao hàng) · 3:39 Document Sale: Buyer, Currency, Total Number(14,2); tabular section Products với Choice parameters IsService = False · 6:18 Copy tabular section thành Services, Choice parameters IsService = True · 8:24 Chạy thử: tạo Sale, Post and close → Total tự điền · 12:00 Report Sales (DCS): query Document.Sale, condition Currency = &Currency, Posted = True; resource Total; settings list, sort Buyer · 14:38 Parameter Currency mặc định VND; chạy báo cáo ở chế độ đơn/đa tiền tệ, thử giao dịch USD
- Bài giáo trình: Bài 15 (chính); Bài 3, Bài 4, Bài 13, Bài 16, Bài 18
- Đề BTL Jet: Đề 5
- Nhóm phù hợp: M D — mức cơ bản – trung bình
- Lưu ý khi giới thiệu: Không có register hay posting xuất kho. Tổng tiền chỉ thấy sau khi ghi (nên tính thêm trên form khi đổi dòng).
- _(mã nội bộ P2-7)_

### Hạch toán thu nhập theo doanh số — 20:00

- Link: https://www.youtube.com/watch?v=QRAzQKBCtds&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=8
- Chủ đề để dẫn: quy đổi tỷ giá khi posting bằng SliceLast
- Dựng từ cấu hình rỗng: Như video trước + Information register tỷ giá, Accumulation register thu nhập
- Video làm gì: Dựng lại bài sản phẩm/dịch vụ rồi thêm information register tỷ giá (periodic, Master) và accumulation register thu nhập; khi posting lấy tỷ giá bằng SliceLast để quy đổi sang VND.
- Mốc xem nhanh: 0:31 Tạo infobase "Bài 15", dựng lại Catalog ProductsAndServices (IsService), Counterparties, Currencies (predefined VND) · 4:12 Bật Master và Deny incomplete values cho dimension Currency; mở tỷ giá trực tiếp từ phần tử USD, nhập 23.200 · 5:15 Document Sale (Buyer, Currency, Total Number(14,2)), tabular section Products/Services với Choice parameters · 7:20 Object module, BeforeWrite tính Total; Currency Fill value = VND; chạy thử (620.000) · 11:05 Accumulation register thu nhập: dimension ProductOrService, resource Sum Number(14,2); Sale đặt Posting = Allow, Register records wizard cho Products và Services · 14:17 Query Builder trên virtual table SliceLast của register tỷ giá, SetParameter Currency/Date, Selection.Next() lấy Rate · 18:08 Report SalesIncome (DCS) từ register, resource Sum, settings list, sort tăng dần; chạy báo cáo
- Bài giáo trình: Bài 12 (chính); Bài 11, Bài 10, Bài 15, Bài 18
- Đề BTL Jet: Đề 5, Đề 2, Đề 4
- Nhóm phù hợp: M D — mức trung bình
- Lưu ý khi giới thiệu: Chạy một query tỷ giá cho mỗi dòng trong vòng lặp posting (nên gom một query). Ngày tỷ giá có thể là ngày hiện tại thay vì ngày chứng từ — kiểm tra khi xem.
- _(mã nội bộ P2-8)_

### Bắt lần khởi động đầu tiên — 9:05

- Link: https://www.youtube.com/watch?v=Q9op8HgLMtM&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=9
- Chủ đề để dẫn: xử lý lần chạy đầu tiên của ứng dụng
- Dựng từ cấu hình rỗng: Constant, Common form, Common module, Application module (OnStart)
- Video làm gì: Constant cờ khởi động, Common form thông báo, Common module server call; trong Application module, OnStart gọi server kiểm tra cờ và mở form; sau đó đặt cờ.
- Mốc xem nhanh: 0:00 Đặt bài toán: phát hiện lần khởi động đầu để mở form tham số ban đầu · 1:04 Tạo Constant kiểu Boolean · 3:12 Mở Application module, chọn event OnStart · 3:46 Tạo Common module server (Server, Server call); function Export trả Not Constants...Get() · 5:51 OnStart: If <Module>.IsFirstLaunch() Then OpenForm(...) · 7:24 Trong form tạo handler client + server, gán Constants...Set(True) · 8:26 Khởi động lại: form không còn xuất hiện
- Bài giáo trình: Bài 14 (chính); Bài 13, Bài 7, Bài 9
- Đề BTL Jet: —
- Nhóm phù hợp: M D — mức cơ bản
- Lưu ý khi giới thiệu: Cờ là theo cả infobase, không theo người dùng; nên đặt cờ sau khi người dùng hoàn tất thiết lập.
- _(mã nội bộ P2-9)_

### Hạch toán hàng hóa - Bài toán đơn giản nhất — 16:55

- Link: https://www.youtube.com/watch?v=SwgfC-uA6Eg&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=10
- Chủ đề để dẫn: nhập – xuất – tồn và chặn âm kho
- Dựng từ cấu hình rỗng: Catalog Products; Document PurchaseInvoice, Sale; Accumulation register Inventory; Report DCS
- Video làm gì: Từ cấu hình rỗng: Catalog Products; Document nhập hàng và bán hàng; accumulation register Inventory (Balances) ghi Receipt/Expense; báo cáo tồn theo ngày; chặn âm kho trong Posting (ghi trước, query số dư < 0, Cancel).
- Mốc xem nhanh: 0:31 Tạo infobase "Bài 17 hạch toán hàng hóa đơn giản" · 2:06 Copy thành Document Sale; tạo Accumulation register Inventory (Balances), resource Quantity, dimension Product · 3:10 Register records: PurchaseInvoice → Receipt, Sale → Expense qua Register records wizard · 4:14 Report Inventory (DCS) từ Inventory.Balance; parameter ReportDate (Date, format), EndOfPeriod · 7:57 Sale Posting: RegisterRecords.Write() rồi query Balance với Boundary(PointInTime, Including) · 12:08 Nếu không rỗng: Cancel = True, vòng lặp Selection.Next() → Message thiếu hàng · 15:49 Test: bán 2 khi tồn 1 → chặn post, báo thiếu 1; báo cáo vẫn tồn 1
- Bài giáo trình: Bài 11 (chính); Bài 10, Bài 18, Bài 3
- Đề BTL Jet: Đề 9, Đề 2, Đề 1
- Nhóm phù hợp: J M D — mức cơ bản – trung bình
- Lưu ý khi giới thiệu: Chưa khóa dữ liệu khi nhiều người post (managed lock (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant)). Đề bài nói "nhiều kho" nhưng phần làm chỉ theo sản phẩm.
- _(mã nội bộ P2-10)_

### Hạch toán hàng hóa - Hạch toán một kho — 20:57

- Link: https://www.youtube.com/watch?v=BD370AtszHI&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=11
- Chủ đề để dẫn: tồn kho theo từng kho (kho trên đầu chứng từ)
- Dựng từ cấu hình rỗng: Catalog Products, Warehouses; Document PurchaseInvoice, Sale; Accumulation register Inventory (Product, Warehouse); Report DCS Table
- Video làm gì: Thêm Catalog Warehouses và dimension Warehouse; mỗi chứng từ thuộc một kho (attribute ở header, Fill checking bắt buộc); chặn âm kho theo hàng + kho; báo cáo tồn Product × Warehouse.
- Mốc xem nhanh: 0:32 Catalog Products, Warehouses; nhập dữ liệu mẫu · 3:42 Thử bỏ trống Warehouse → báo lỗi; copy thành Document Sale · 4:44 Accumulation register Inventory (Balances): dimensions Product, Warehouse; resource Quantity · 5:50 Register records wizard: PurchaseInvoice Receipt, Sale Expense · 7:58 Sale Posting: Write, query Balance < 0 lọc Warehouse = &Warehouse, Product IN &Products · 14:19 Test: bán 33 sữa tươi kho Đống Đa → bị chặn · 15:21 Report cân đối hàng hóa (DCS): Table rows Product / columns Warehouse, parameter ngày báo cáo
- Bài giáo trình: Bài 11 (chính); Bài 12, Bài 10, Bài 18
- Đề BTL Jet: Đề 2, Đề 9
- Nhóm phù hợp: M D J — mức trung bình
- Lưu ý khi giới thiệu: Không khóa dữ liệu trước khi đọc số dư.
- _(mã nội bộ P2-11)_

### Hạch toán hàng hóa nhiều kho (Full) — 18:40

- Link: https://www.youtube.com/watch?v=HIAYMOepPw4&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=12
- Chủ đề để dẫn: kho trên từng dòng hàng và chặn âm theo từng kho
- Dựng từ cấu hình rỗng: Như video trước, Warehouse chuyển xuống tabular section của Sale
- Video làm gì: Dựng lại từ đầu; chứng từ bán chuyển Warehouse xuống tabular section (mỗi dòng một kho); posting và chặn âm kho theo cặp hàng – kho.
- Mốc xem nhanh: 0:00 Giới thiệu: tương tự Bài 18, dựng lại từ đầu để tham khảo đầy đủ · 1:37 Document PurchaseInvoice: tabular section Products, header Warehouse (Fill checking) · 3:09 Nhập hàng 50 đơn vị/mặt hàng vào ba kho · 4:14 Copy thành Document Sale, chuyển Warehouse xuống tabular section · 7:32 Repost chứng từ cũ, kiểm tra register · 11:52 Cancel = True + Message cho từng dòng; test bán 60 khi tồn 50 → chặn · 14:32 Report tồn kho DCS: Table Product × Warehouse, parameter ngày báo cáo
- Bài giáo trình: Bài 11 (chính); Bài 10, Bài 12, Bài 18
- Đề BTL Jet: Đề 9, Đề 2, Đề 1
- Nhóm phù hợp: M D — mức trung bình
- Lưu ý khi giới thiệu: Điều kiện Product IN … AND Warehouse IN … tách rời có thể báo thiếu nhầm cho cặp (hàng, kho) không có trong chứng từ; chuẩn hơn là lọc theo cặp (temporary table/join).
- _(mã nội bộ P2-12)_

### Hạch toán hàng hóa nhiều kho (Short) — 14:51

- Link: https://www.youtube.com/watch?v=sHl70mbjk4c&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=13
- Chủ đề để dẫn: sửa cấu trúc chứng từ đang có dữ liệu
- Dựng từ cấu hình rỗng: Load .dt từ video trước, chỉ sửa phần khác biệt
- Video làm gì: Không dựng lại: load file .dt của video "Hạch toán một kho" rồi chỉ làm phần khác: chuyển Warehouse xuống dòng, chạy lại Register records wizard, điền kho cho chứng từ cũ, repost.
- Mốc xem nhanh: 0:00 Giới thiệu: giống ví dụ 18, đổi từ bán một kho sang bán nhiều kho · 0:32 Dump infobase Bài 18 ra .dt, tạo infobase Bài 19 và load cấu hình · 3:07 Chạy lại Register records wizard cho Sale (Expense, Warehouse của dòng) · 4:10 Điền kho cho chứng từ cũ, repost; kiểm tra register qua All functions · 5:45 Sửa Posting: Write, query Balance < 0, Product IN &Products, Warehouse IN &Warehouses · 12:21 Bổ sung tồn kho để số dư dương, chạy báo cáo có sẵn · 13:54 Test bán 12 sữa chua kho Linh Đàm → chặn, báo thiếu
- Bài giáo trình: Bài 11 (chính); Bài 10
- Đề BTL Jet: Đề 9, Đề 2
- Nhóm phù hợp: M D — mức trung bình
- Lưu ý khi giới thiệu: Bắt buộc đã làm video "Hạch toán một kho"; chưa làm thì xem bản Full. Đây không phải bản tóm tắt.
- _(mã nội bộ P2-13)_

### Hạch toán hàng hóa - Theo hạn sử dụng — 13:24

- Link: https://www.youtube.com/watch?v=TBgeOMXYp0w&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=14
- Chủ đề để dẫn: tồn kho theo hạn sử dụng và xuất dần theo lô
- Dựng từ cấu hình rỗng: Catalog Products; Document PurchaseInvoice (ExpirationDate), Sale; Accumulation register Inventory (Product, ExpirationDate)
- Video làm gì: Register Inventory có thêm dimension ExpirationDate (lô = hạn dùng, không có Catalog Batch); khi bán, query batch (temporary table + join bảng ảo Balance) kiểm tra tồn còn hạn, ghi Expense lần lượt từng lô, thiếu thì Cancel.
- Mốc xem nhanh: 0:00 Bài toán: nhập/bán theo hàng + hạn dùng; bỏ lô quá hạn khi bán · 0:31 Catalog Products; Document PurchaseInvoice, tabular section Product, Quantity, ExpirationDate (Date) · 2:40 Register records wizard cho PurchaseInvoice (Receipt) · 3:13 Form có attribute SpreadsheetDocument + command client/server · 4:19 Query batch: temporary table từ tabular section, Index Product; join Inventory.Balance · 9:37 Vòng lặp xuất dần: Expense, Quantity = Min(còn phải xuất, tồn dòng), giảm biến còn lại · 12:19 RegisterRecords.Inventory.Write = True; chạy báo cáo kiểm tra: lô hết hạn còn lại trong tồn
- Bài giáo trình: Bài 11 (chính); Bài 10
- Đề BTL Jet: Đề 1
- Nhóm phù hợp: M D J — mức nâng cao
- Lưu ý khi giới thiệu: Cách "kiểm tra trước, ghi sau" khác các video trước ("ghi trước, tìm số dư âm sau"). Kiểm tra thứ tự lô (FEFO) và mốc so hạn khi xem; không khóa dữ liệu.
- _(mã nội bộ P2-14)_
