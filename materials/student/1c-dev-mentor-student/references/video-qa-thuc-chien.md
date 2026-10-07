# Video giải đáp tình huống thực chiến ↔ triệu chứng ↔ bài giáo trình

> Cập nhật 07/10/2026. Nguồn: playlist "Giải đáp câu hỏi của sinh viên và cộng đồng lập trình viên 1C:Enterprise" (https://www.youtube.com/playlist?list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r, 28 video, kênh Trung tâm đào tạo lập trình 1C Việt Nam). Nội dung từng video đã được kiểm chứng bằng transcript: phần "Video làm gì" là những gì video **thực sự** làm, có thể khác mô tả trong file Excel đối chiếu ban đầu.

## Cách dùng

1. Người học báo lỗi, mô tả triệu chứng hoặc hỏi "làm sao để…": **giải thích nguyên nhân và cách làm theo giáo trình trước**. Sau đó tra Mục A; nếu khớp, thêm một câu dẫn video (tối đa 2 video).
2. Câu dẫn cho người học (giống quy ước video bài giảng): "🎬 Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](<link>)" — với tình huống lỗi có thể nói "tham khảo cách xử lý <tình huống> của khóa tại đây". Dùng **tên hiển thị** trong bảng (đã bỏ "Bài N:" và hậu tố tên kênh). Không nêu số "Bài N" của video (khác số bài giáo trình), không dùng mã QA-/P1-/P2- (chỉ để tra nội bộ), không gọi là "khóa cũ".
3. Nếu thẻ video (Mục B) có "Lưu ý khi giới thiệu" liên quan tới điều người học sắp làm, nói thêm một câu ngắn (ví dụ: "video kiểm tra theo tồn hiện tại; với chứng từ ghi lùi ngày hãy dùng PointInTime như Bài 11"). Video là cách làm minh họa; nếu khác giáo trình thì theo giáo trình.
4. Có thể gợi ý tua tới mốc thời gian trong dòng "Mốc xem nhanh" ("tua tới khoảng 1:38 để xem cách đặt breakpoint").
5. Lộ trình J (BTL trên Jet): ưu tiên video có cột "Đề BTL Jet" trùng đề của nhóm; bảng theo đề ở `references/video-thuc-hanh.md` Mục B. Lộ trình M, D: không cần nhắc Jet.
6. Bản dành cho sinh viên: video là tài liệu công khai, được dẫn bình thường; vẫn giữ nguyên tắc gợi ý trước với bài thực hành của giáo trình.

## A. Tra theo triệu chứng / câu hỏi

### Form, sự kiện, điền tự động

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| đổi số lượng mà thành tiền không tự tính, phải sửa giá mới tính; viết procedure ...OnChange rồi mà không chạy; đặt breakpoint trong handler mà debugger không dừng | [Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng](https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1) (4:24) | Bài 16 |
| muốn chứng từ mới tự điền sẵn kho/điểm bán mặc định; mỗi lần tạo phiếu phải chọn lại kho | [Xây dựng các trường tự động điền](https://www.youtube.com/watch?v=8klMmoJXBCk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=10) (2:02) | Bài 4 |
| chọn sản phẩm mà đơn vị tính không tự hiện; lấy thuộc tính của sản phẩm điền vào dòng hàng; lỗi khi đọc Product.UOM ở client | [Tự động lấy đơn vị tính của sản phẩm](https://www.youtube.com/watch?v=RKAGi62Vy5E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=12) (8:16) | Bài 7 |
| muốn chặn nhập trùng số điện thoại / mã số thuế; báo lỗi khi tạo khách hàng đã tồn tại | [Kiểm tra dữ liệu trùng lặp](https://www.youtube.com/watch?v=603j21ItABk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=11) (8:55) | Bài 16 |
| đã báo lỗi rồi mà vẫn lưu được dữ liệu sai; làm sao chặn không cho ghi khi dữ liệu không hợp lệ | [Hủy sự kiện đang thực thi](https://www.youtube.com/watch?v=rW40s85Gtc4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=16) (3:18) | Bài 16 |
| chọn hãng/nhà cung cấp rồi mà danh sách sản phẩm vẫn hiện tất cả; tạo catalog mới chạy lên không sửa được, báo không đủ quyền | [Lọc dữ liệu chọn sản phẩm theo hãng](https://www.youtube.com/watch?v=EfF2acfP2Y8&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=19) (6:30) | Bài 9 |
| làm sao thêm ảnh cho sản phẩm/nhân viên; chọn ảnh xong ghi lại mở ra thì mất ảnh; bấm vào trường ảnh không có gì xảy ra | [Thêm ảnh cho các đối tượng](https://www.youtube.com/watch?v=TQNa4cveOdc&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=6) (10:04) | Bài 17 |

### Tồn kho, posting, register

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| bán vượt tồn mà chứng từ vẫn post được, tồn kho bị âm; làm sao không cho kết chuyển khi không đủ hàng | [Chặn kết chuyển khi phát hiện tồn kho âm](https://www.youtube.com/watch?v=k2uht5J1f3c&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=25) (10:03) | Bài 11 |
| muốn xem tồn kho ngay khi chọn hàng trên phiếu bán; query tồn kho trả về rỗng khi sản phẩm chưa nhập; ô số lượng bằng 0 bị trống | [Truy vấn tồn kho trong chứng từ bán hàng](https://www.youtube.com/watch?v=13817kAvhwQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=17) (9:53) | Bài 10 |
| tồn kho dưới mức tối thiểu thì hiện màu đỏ; conditional appearance so sánh hai cột; đặt định mức tồn kho tối thiểu | [Báo động tồn kho thấp với màu chữ hiển thị](https://www.youtube.com/watch?v=0JbOMl80lnY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=18) (13:09) | Bài 9 |
| tích điểm cho khách khi bán hàng; trừ điểm thưởng đã dùng; khách dùng quá số điểm đang có | [Xây dựng cơ chế tích điểm thưởng](https://www.youtube.com/watch?v=0aAaQQP9fXI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=14) (23:35) | Bài 11 |
| đã tích register vào phân hệ mà chạy không thấy; muốn mở register lên để kiểm tra posting | [Cách hiển thị biểu ghi tích lũy lên phân hệ](https://www.youtube.com/watch?v=DBJeS7LfUpY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=4) (1:53) | Bài 9 |

### Giá và information register

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| chọn sản phẩm trên chứng từ bán mà giá không tự điền; lấy giá mới nhất theo ngày từ bảng giá thế nào | [Lấy giá tự động](https://www.youtube.com/watch?v=oMowT1e019k&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=5) (8:32) | Bài 12 |

### Báo cáo, truy vấn, bản in

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| báo cáo doanh thu – chi phí theo tháng làm thế nào; báo cáo DCS lọc từ ngày đến ngày | [Báo cáo lợi nhuận theo kỳ](https://www.youtube.com/watch?v=98gDiVV8jx0&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=8) (9:16) | Bài 18 |
| muốn báo cáo có cột chênh lệch mà không lưu vào register; tính toán cột trong query 1C thế nào | [Thực hiện tính toán đơn giản với SQL trong 1C](https://www.youtube.com/watch?v=dP21dfHxkCo&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=23) (2:59) | Bài 10 |
| chứng từ không có nút in; làm sao tạo mẫu in hóa đơn; sửa chữ trên mẫu in | [Tạo chức năng in hóa đơn chứng từ](https://www.youtube.com/watch?v=uwEBQJZG6t4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=7) (5:31) | Bài 17 |

### Giao diện, phân hệ, màu sắc

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| tạo phân hệ/đối tượng mới mà vào không thấy gì; muốn hiện nút Tạo mới ngay trên phân hệ | [Hiển thị đối tượng Siêu dữ liệu lên Quick menu](https://www.youtube.com/watch?v=rPSNKvFEQ8E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=21) (2:23) | Bài 14 |
| đã tích register vào phân hệ mà chạy không thấy; muốn mở register lên để kiểm tra posting | [Cách hiển thị biểu ghi tích lũy lên phân hệ](https://www.youtube.com/watch?v=DBJeS7LfUpY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=4) (1:53) | Bài 9 |
| muốn đổi màu vàng của giao diện 1C theo màu công ty | [Thay đổi Style (màu sắc) của chương trình](https://www.youtube.com/watch?v=cgmDdh6bHMg&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=24) (2:47) | Bài 9 |

### Người dùng, phân quyền, ngôn ngữ

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| tạo user mà không thấy role nào để chọn; làm sao bắt đăng nhập khi mở 1C; tạo xong user thì Designer bắt đăng nhập | [Hướng dẫn thiết lập vai trò người dùng](https://www.youtube.com/watch?v=senxXwfjFxU&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=3) (3:38) | Bài 20 |
| làm sao cho người dùng tự đổi mật khẩu; chạy data processor mới tạo báo không đủ quyền | [Tạo chức năng sửa password với vai trò người dùng](https://www.youtube.com/watch?v=taKIdmcCmIQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=9) (26:39) | Bài 20 |
| muốn user Việt thấy tiếng Việt, user nước ngoài thấy tiếng Anh; đã thêm ngôn ngữ mà vẫn hiện tiếng Anh | [Tùy chỉnh ngôn ngữ theo người dùng](https://www.youtube.com/watch?v=wo7G7jSPtBE&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=26) (4:30) | Bài 20 |
| làm sao đổi giao diện 1C sang tiếng Việt; cài 1C xong không thấy tiếng Việt | [Chuyển đổi ngôn ngữ trên cấu hình 1C:Enterprise](https://www.youtube.com/watch?v=lqhWahjse2I&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=2) (1:37) | Bài 1 |

### Dữ liệu ngoài, extension, cài đặt và triển khai

| Người học nói… | Video | Bài giáo trình |
|---|---|---|
| nhập danh sách sản phẩm từ file Excel vào 1C; sau khi import file Excel bị khóa không mở được | [Kết nhập file excel vào danh mục sản phẩm](https://www.youtube.com/watch?v=DlXBXRzBJGw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=13) (38:42) | Bài 19 |
| mang data processor sang database khác mà không cập nhật cấu hình; mở file .epf bị cảnh báo bảo mật | [Lưu bộ xử lý ngoài](https://www.youtube.com/watch?v=DTRivJSbAoI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=15) (1:40) | Bài 19 |
| muốn thêm báo cáo vào cấu hình chuẩn mà không sửa cấu hình gốc; tạo extension xong không thấy báo cáo; mang extension sang database khác | [Extension (Phần mở rộng) trong 1C:Enterprise](https://www.youtube.com/watch?v=T_DEaA1p_bA&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=22) (6:33) | bài Extensions |
| gửi bài/infobase cho thầy cô hoặc bạn cùng nhóm thế nào; chép database sang máy khác | [Kết xuất kết nhập cấu hình bằng file *.1CD](https://www.youtube.com/watch?v=3X0EAToibUg&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=27) (3:29) | Bài 1 |
| publish xong mở trình duyệt báo lỗi; muốn truy cập 1C qua trình duyệt từ máy khác | [Hướng dẫn publish Infobase 1C:Enterprise lên web server](https://www.youtube.com/watch?v=P_bwSfxAV8I&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=28) (7:21) | Bài 1 |
| muốn xem thử phần mềm 1C mà không cài đặt | [Hướng dẫn truy cập bản dùng thử 1C:AccountingSuite](https://www.youtube.com/watch?v=8Vmkv3KP5ek&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=20) (1:16) | Bài 1 |

### Tình huống có cách làm trong chuỗi video thực hành (xây từ cấu hình rỗng)

| Người học cần… | Video | Bài giáo trình |
|---|---|---|
| một chứng từ phải ghi vào hai register | [Hệ thống cho thuê xe điện](https://www.youtube.com/watch?v=wWGXT2KSul8&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=4) (10:40) | Bài 11 |
| tạo phiếu trả/phiếu thực hiện từ phiếu mượn/phiếu đặt mà không nhập lại | [Lưu trữ thông tin các chuyến du lịch](https://www.youtube.com/watch?v=PwqP4GODNrY&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=6) (13:15) · [Tạo lập hệ thống thông tin thư viện](https://www.youtube.com/watch?v=3DMFgUjg2Js&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=5) (24:38) | Bài 11, Bài 3 |
| hiện số dư quỹ/tồn hiện tại lên form chứng từ | [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) | Bài 11 |
| phiếu thu và phiếu chi phải đánh số liên tục, mỗi năm đánh lại | [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) | Bài 11 |
| xem chung nhiều loại chứng từ trong một danh sách | [Ghi nhận luân chuyển dòng tiền](https://www.youtube.com/watch?v=YzhM76Wy9fk&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=7) (18:29) | Bài 11 |
| năm hiện "2 000" có dấu cách / định dạng số trên form | [Tạo lập hệ thống thông tin thư viện](https://www.youtube.com/watch?v=3DMFgUjg2Js&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=5) (24:38) | Bài 11 |
| nhập số điện thoại theo mẫu cố định (Mask) | [Lưu trữ thông tin sinh viên và môn học](https://www.youtube.com/watch?v=UGXVLOKRaGw&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=4) (12:19) · [Tạo lập hệ thống thông tin thư viện](https://www.youtube.com/watch?v=3DMFgUjg2Js&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=5) (24:38) | Bài 11, Bài 3 |
| danh mục con thuộc về một phần tử khác (Owner) | [Lưu trữ thông tin nhân viên](https://www.youtube.com/watch?v=WF19J3tct0I&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=5) (9:37) | Bài 4 |
| lưu lịch sử thay đổi theo tháng/ngày (lương, tỷ giá, giá) | [Lưu trữ thông tin nhân viên](https://www.youtube.com/watch?v=WF19J3tct0I&list=PLp-gQ5Mgw0ZybnANjTWo69eHYBDWgE-r2&index=5) (9:37) · [Ghi nhận thay đổi tỷ giá hối đoái](https://www.youtube.com/watch?v=9_m7XqHPZlA&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=1) (9:04) | Bài 12, Bài 4 |
| chặn âm kho theo từng kho, kho nằm trên từng dòng hàng | [Hạch toán hàng hóa - Hạch toán một kho](https://www.youtube.com/watch?v=BD370AtszHI&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=11) (20:57) · [Hạch toán hàng hóa nhiều kho (Full)](https://www.youtube.com/watch?v=HIAYMOepPw4&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=12) (18:40) | Bài 11 |
| xuất hàng theo hạn sử dụng, không bán lô quá hạn | [Hạch toán hàng hóa - Theo hạn sử dụng](https://www.youtube.com/watch?v=TBgeOMXYp0w&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=14) (13:24) | Bài 11 |
| ẩn/hiện một tính năng bằng tùy chọn (Functional option) | [Hạch toán sản phẩm dịch vụ](https://www.youtube.com/watch?v=GFsS9x1bOTQ&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=7) (15:54) | Bài 15 |
| quy đổi ngoại tệ theo tỷ giá ngày chứng từ khi posting | [Hạch toán thu nhập theo doanh số](https://www.youtube.com/watch?v=QRAzQKBCtds&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=8) (20:00) | Bài 12 |
| chọn nhiều đơn trong danh sách rồi bấm một nút xử lý | [Hệ thống thông tin cửa hàng nhỏ](https://www.youtube.com/watch?v=zXa4pQv0LHE&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=6) (12:28) | Bài 14 |
| làm gì đó khi ứng dụng chạy lần đầu | [Bắt lần khởi động đầu tiên](https://www.youtube.com/watch?v=Q9op8HgLMtM&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=9) (9:05) | Bài 14 |
| đổi cấu trúc chứng từ khi infobase đã có dữ liệu | [Hạch toán hàng hóa nhiều kho (Short)](https://www.youtube.com/watch?v=sHl70mbjk4c&list=PLp-gQ5Mgw0ZwiR39KPVCIVuUKhfEAD0KM&index=13) (14:51) | Bài 11 |

Thẻ chi tiết của các video thực hành: `references/video-thuc-hanh.md`.

## B. Thẻ video (theo thứ tự trong playlist)

### Fix lỗi không tính toán Thành tiền khi thay đổi Số lượng — 4:24

- Link: https://www.youtube.com/watch?v=LRRNf8MxoQw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=1
- Chủ đề để dẫn: cách tìm lỗi sự kiện OnChange không chạy
- Video làm gì: Tái hiện lỗi đổi Số lượng mà Thành tiền không tính, đặt Breakpoint để thấy handler của cột Quantity không bao giờ được gọi: procedure có trong form module nhưng chưa được gắn vào sự kiện OnChange của phần tử. Sửa bằng cách tạo handler qua bảng Events của phần tử.
- Mốc xem nhanh: 0:00 Mô tả lỗi: thêm sản phẩm, nhập số lượng nhưng Thành tiền không tính · 0:35 Tái hiện: chỉ khi sửa Giá mới tính ra Thành tiền · 1:07 Mở form module của chứng từ, rà các hàm PriceOnChange, hàm tính toán, CalculateTotal · 2:10 Breakpoint ở Quantity không dừng; thử breakpoint ở Price thì dừng, dùng Step into theo dõi luồng · 2:41 Suy luận: handler Quantity chưa được hệ thống "nhận" — xóa procedure cũ · 3:11 Tạo lại handler qua Events của phần tử (OnChange), dán lại code · 3:43 Chạy thử: đổi số lượng đã tự tính Thành tiền; kết luận phải tạo handler qua Events để hệ thống gắn đúng sự kiện
- Người học thường hỏi: "đổi số lượng mà thành tiền không tự tính, phải sửa giá mới tính"; "viết procedure ...OnChange rồi mà không chạy"; "đặt breakpoint trong handler mà debugger không dừng"
- Bài giáo trình: Bài 16 (chính); Bài 8, Bài 9
- Đề BTL Jet: Đề 3, Đề 5, Đề 9
- Nhóm phù hợp: J M D — mức cơ bản
- Lưu ý khi giới thiệu: Video xóa rồi tạo lại procedure; thật ra chỉ cần mở Properties → Events của phần tử và chọn đúng procedure. Tên procedure trùng tên chuẩn không tự gắn vào sự kiện.
- _(mã nội bộ QA-1)_

### Chuyển đổi ngôn ngữ trên cấu hình 1C:Enterprise — 1:37

- Link: https://www.youtube.com/watch?v=lqhWahjse2I&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=2
- Chủ đề để dẫn: cách đổi giao diện nền tảng sang tiếng Việt
- Video làm gì: Sửa bộ cài nền tảng (Change/Modify trong Windows), thêm Vietnamese vào ngôn ngữ giao diện rồi cài lại; Designer hiển thị tiếng Việt. Không thao tác object Languages của cấu hình.
- Mốc xem nhanh: 0:00 Giao diện ban đầu tiếng Anh trên bản training version · 0:31 Chuột phải vào 1C:Enterprise trong danh sách chương trình đã cài, chọn Change/Modify bộ cài; chọn đúng bản platform · 0:31 Trong bước chọn ngôn ngữ giao diện: thêm Vietnamese (ngoài English) · 1:03 Install, Finish · 1:03 Mở lại Designer: giao diện và cây cấu hình hiển thị tiếng Việt
- Người học thường hỏi: "làm sao đổi giao diện 1C sang tiếng Việt"; "cài 1C xong không thấy tiếng Việt"
- Bài giáo trình: Bài 1 (chính)
- Đề BTL Jet: —
- Nhóm phù hợp: J — mức cơ bản
- Lưu ý khi giới thiệu: Chỉ đổi giao diện của nền tảng; tên các object trong cấu hình không tự dịch (xem video "Tùy chỉnh ngôn ngữ theo người dùng"). Giáo trình dùng thuật ngữ Designer tiếng Anh, nên giữ giao diện tiếng Anh khi học theo tài liệu.
- _(mã nội bộ QA-2)_

### Hướng dẫn thiết lập vai trò người dùng — 3:38

- Link: https://www.youtube.com/watch?v=senxXwfjFxU&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=3
- Chủ đề để dẫn: tạo role và user đầu tiên
- Video làm gì: Tạo role Administrator bằng "Set all rights", Update database configuration, tạo user admin và gán role; giải thích các kiểu xác thực. Sau đó cả 1C:Enterprise và Designer đều yêu cầu đăng nhập.
- Mốc xem nhanh: 0:00 Mở infobase bằng Designer, chưa có user nên không cần đăng nhập · 0:00 Common > Roles: tạo role Administrator đầu tiên · 0:32 Mở Rights, chọn Set all rights; nhắc phải Update database configuration · 1:35 Administration > Users: tạo user admin, gán role Administrator · 1:35 Giải thích ô mật khẩu/xác thực bị mờ trên bản training version · 2:06 Chạy thử 1C:Enterprise mode: yêu cầu đăng nhập · 2:37 Mở lại Designer cũng yêu cầu đăng nhập; giải thích 1C:Enterprise / OS / OpenID authentication
- Người học thường hỏi: "tạo user mà không thấy role nào để chọn"; "làm sao bắt đăng nhập khi mở 1C"; "tạo xong user thì Designer bắt đăng nhập"
- Bài giáo trình: Bài 20 (chính)
- Đề BTL Jet: Đề 6
- Nhóm phù hợp: J M D — mức cơ bản
- Lưu ý khi giới thiệu: Video chỉ tạo role toàn quyền; phân quyền theo từng object (Read/Insert/Update…) xem Bài 20. User đầu tiên phải có role có quyền Administration. Phần OpenID được giải thích đơn giản hóa.
- _(mã nội bộ QA-3)_

### Cách hiển thị biểu ghi tích lũy lên phân hệ — 1:53

- Link: https://www.youtube.com/watch?v=DBJeS7LfUpY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=4
- Chủ đề để dẫn: cách hiện register lên phân hệ
- Video làm gì: Đưa accumulation register vào Content của subsystem nhưng chạy vẫn không thấy; mở Command interface của subsystem và bật Visibility cho lệnh danh sách của register thì register mới hiện.
- Mốc xem nhanh: 0:00 Mục tiêu: hiển thị accumulation register Revenues trong phân hệ · 0:31 Cách thông thường: thêm register vào Content của subsystem · 0:31 Chạy thử: register vẫn không xuất hiện · 1:03 Mở Command interface của subsystem, tìm lệnh của register, bật Visibility · 1:33 Chạy lại: Revenues hiện trong phân hệ; lưu ý thực tế không đưa register cho người dùng
- Người học thường hỏi: "đã tích register vào phân hệ mà chạy không thấy"; "muốn mở register lên để kiểm tra posting"
- Bài giáo trình: Bài 9 (chính); Bài 14, Bài 11
- Đề BTL Jet: Đề 1, Đề 2, Đề 7, Đề 9
- Nhóm phù hợp: J M — mức cơ bản
- Lưu ý khi giới thiệu: Lệnh của register ẩn mặc định là có chủ ý; người dùng cuối nên xem qua báo cáo. Nếu vẫn không thấy, kiểm tra role có quyền View trên register.
- _(mã nội bộ QA-4)_

### Lấy giá tự động — 8:32

- Link: https://www.youtube.com/watch?v=oMowT1e019k&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=5
- Chủ đề để dẫn: tự điền giá theo bảng giá
- Video làm gì: Tạo information register Price (Periodicity = Day, dimension Product, resource Price), nhập bảng giá; trong form chứng từ bán, khi chọn Product thì gọi hàm server dùng InformationRegisters.Price.GetLast(Object.Date, Filter) để điền giá và tính lại thành tiền.
- Mốc xem nhanh: 0:30 Tạo Information register Price: Periodicity Day, Write mode Independent · 1:01 Dimension Product (CatalogRef Products), resource Price (Number) · 2:02 Mở form module chứng từ Sales, tạo hàm chạy phía server GetPrice(Product) · 3:05 Tạo Structure Filter, key = tên dimension Product · 4:06 Gọi GetLast(Object.Date, Filter) lấy bản ghi gần nhất trước ngày chứng từ, Return Row.Price · 7:20 Gán giá vào dòng hiện tại, tính lại Amount và tổng hóa đơn · 7:50 Chạy thử: chọn sản phẩm, giá tự điền
- Người học thường hỏi: "chọn sản phẩm trên chứng từ bán mà giá không tự điền"; "lấy giá mới nhất theo ngày từ bảng giá thế nào"
- Bài giáo trình: Bài 12 (chính); Bài 16, Bài 7
- Đề BTL Jet: Đề 5, Đề 3
- Nhóm phù hợp: M J D — mức trung bình
- Lưu ý khi giới thiệu: Hàm dùng &AtServer; chỉ cần &AtServerNoContext và truyền Product, Date. Khi điền nhiều dòng nên dùng một query bảng ảo SliceLast (cách của Bài 12).
- _(mã nội bộ QA-5)_

### Thêm ảnh cho các đối tượng — 10:04

- Link: https://www.youtube.com/watch?v=TQNa4cveOdc&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=6
- Chủ đề để dẫn: lưu và hiển thị ảnh cho sản phẩm
- Video làm gì: Thêm form attribute địa chỉ ảnh hiển thị bằng Picture field, handler Click gọi BeginPutFile chọn ảnh vào temporary storage; catalog có attribute kiểu ValueStorage, ghi ảnh trong BeforeWriteAtServer và nạp lại khi mở form.
- Mốc xem nhanh: 0:00 Mục tiêu: thêm ảnh cho sản phẩm/nhân sự; tạo item form nếu chưa có · 1:04 Kiểu hiển thị Picture field; NonselectedPictureText; bật Hyperlink · 1:34 Tạo handler Click của picture field · 2:04 New NotifyDescription + BeginPutFile (Interactive True, UUID form), StandardProcessing = False · 5:41 Form events BeforeWriteAtServer và OnCreateAtServer · 8:18 OnCreateAtServer: GetURL(Object.Ref, "<attribute>") để hiển thị lại ảnh · 9:21 Chạy thử, chỉnh PictureSize = Proportionally
- Người học thường hỏi: "làm sao thêm ảnh cho sản phẩm/nhân viên"; "chọn ảnh xong ghi lại mở ra thì mất ảnh"; "bấm vào trường ảnh không có gì xảy ra"
- Bài giáo trình: Bài 17 (chính); Bài 9, Bài 16, Bài 7
- Đề BTL Jet: —
- Nhóm phù hợp: M D — mức trung bình
- Lưu ý khi giới thiệu: Đối chiếu thứ tự tham số BeginPutFile trong Syntax assistant. Ảnh lớn hoặc nhiều file nên dùng cơ chế file (Bài 23).
- _(mã nội bộ QA-6)_

### Tạo chức năng in hóa đơn chứng từ — 5:31

- Link: https://www.youtube.com/watch?v=uwEBQJZG6t4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=7
- Chủ đề để dẫn: tạo mẫu in chứng từ bằng Print wizard
- Video làm gì: Dùng Print wizard tạo command Print và template cho chứng từ bán (header, bảng hàng, footer), rồi sửa template SpreadsheetDocument: ô parameter và ô chữ cố định, in đậm, đổi màu.
- Mốc xem nhanh: 0:00 Vấn đề: cần in hóa đơn bán hàng gửi khách · 0:31 Mở Print wizard trên chứng từ Sales, đặt tên lệnh in · 1:02 Chọn trường header: Number, Date · 1:33 Chọn footer: Total (và một trường khác, transcript không rõ) · 2:05 Wizard tạo command Print và template; ghim lệnh in lên form chứng từ · 3:09 Chỉnh template: ô parameter vs ô text, sửa nhãn, in đậm, màu, thêm tên doanh nghiệp · 4:43 Chạy thử bản in đã sửa
- Người học thường hỏi: "chứng từ không có nút in"; "làm sao tạo mẫu in hóa đơn"; "sửa chữ trên mẫu in"
- Bài giáo trình: Bài 17 (chính); Bài 22, Bài 14
- Đề BTL Jet: Đề 3, Đề 9, Đề 7
- Nhóm phù hợp: J M D — mức cơ bản
- Lưu ý khi giới thiệu: Print wizard sinh code in kiểu cũ. Jet dùng SSL nên trên Jet hãy đăng ký lệnh in qua Print subsystem (Bài 22).
- _(mã nội bộ QA-7)_

### Báo cáo lợi nhuận theo kỳ — 9:16

- Link: https://www.youtube.com/watch?v=98gDiVV8jx0&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=8
- Chủ đề để dẫn: báo cáo DCS theo kỳ
- Video làm gì: Tạo accumulation register (loại Balances, một resource), chứng từ bán ghi Receipt, chứng từ mua ghi Expense; báo cáo DCS lấy số liệu từ bảng ảo của register với tham số từ ngày – đến ngày.
- Mốc xem nhanh: 0:33 Bối cảnh: chứng từ Sales ghi doanh thu, Purchase ghi chi phí · 1:35 Register records cho Sales: Receipt Profit = tổng hóa đơn · 2:39 Register records cho Purchase: Expense Profit (có nhầm lẫn rồi sửa lại [3:10]) · 3:41 Repost lại toàn bộ chứng từ, xem register · 5:43 Đặt tên trường Profit/Revenue/Cost; Settings: Selected fields · 7:19 Dùng tham số kỳ (BeginOfPeriod/EndOfPeriod) để báo cáo theo kỳ; tạo thêm chứng từ thử · 8:20 Kết quả theo kỳ: bán 6,8 triệu, mua 2 triệu, lợi nhuận 4,8 triệu
- Người học thường hỏi: "báo cáo doanh thu – chi phí theo tháng làm thế nào"; "báo cáo DCS lọc từ ngày đến ngày"
- Bài giáo trình: Bài 18 (chính); Bài 11, Bài 10
- Đề BTL Jet: Đề 8, Đề 7, Đề 4
- Nhóm phù hợp: M J — mức trung bình
- Lưu ý khi giới thiệu: "Lợi nhuận = tổng bán − tổng mua" chỉ để minh họa kỹ thuật, không đúng nghiệp vụ (cần giá vốn hàng bán). Số liệu phát sinh theo kỳ hợp với register loại Turnovers hơn.
- _(mã nội bộ QA-8)_

### Tạo chức năng sửa password với vai trò người dùng — 26:39

- Link: https://www.youtube.com/watch?v=taKIdmcCmIQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=9
- Chủ đề để dẫn: cho người dùng tự đổi mật khẩu
- Video làm gì: Tạo data processor có form đổi mật khẩu (PasswordMode), hàm &AtServerNoContext kiểm tra InfoBaseUsers.CurrentUser() rồi ghi mật khẩu mới; nhắc cấp quyền cho role trên data processor mới.
- Mốc xem nhanh: 0:00 Lưu ý: chức năng khó thực hành trên training version, cần bản có bản quyền (theo lời giảng viên) · 1:37 Tạo user admin: bỏ "cannot change password", 1C:Enterprise authentication, Show in list · 3:43 Tạo Data processor ChangePassword và form qua wizard · 4:15 Form attributes: cờ cho phép đổi, NewPassword, ConfirmNewPassword (String, password mode); command ChangePassword · 8:27 Hàm &AtServerNoContext kiểm tra user: InfoBaseUsers.CurrentUser(), CannotChangePassword, StandardAuthentication · 15:21 OnCreateAtServer, OnOpen (ShowMessageBox + Cancel), handler command (ClearMessages, so khớp, Message) · 24:56 Chạy thử: sai xác nhận báo lỗi; đúng thì đổi thành công; đăng nhập lại bằng mật khẩu mới
- Người học thường hỏi: "làm sao cho người dùng tự đổi mật khẩu"; "chạy data processor mới tạo báo không đủ quyền"
- Bài giáo trình: Bài 20 (chính); Bài 19, Bài 7, Bài 16
- Đề BTL Jet: —
- Nhóm phù hợp: D — mức nâng cao
- Lưu ý khi giới thiệu: Video chỉ thử với user toàn quyền; user thường không ghi được InfoBaseUser nếu không bật privileged mode (SetPrivilegedMode — Bài 20) và phải kiểm soát chặt. Nền tảng/SSL đã có sẵn chức năng đổi mật khẩu.
- _(mã nội bộ QA-9)_

### Xây dựng các trường tự động điền — 2:02

- Link: https://www.youtube.com/watch?v=8klMmoJXBCk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=10
- Chủ đề để dẫn: giá trị mặc định khi tạo chứng từ
- Video làm gì: Không viết code: tạo phần tử Predefined trong catalog điểm bán và đặt thuộc tính Fill value của attribute trên Document Sale trỏ tới phần tử đó; chứng từ mới tự điền sẵn điểm bán.
- Mốc xem nhanh: 0:00 Nêu yêu cầu: chứng từ bán hàng mới cần điểm bán mặc định (cơ sở 1 / trụ sở chính) · 0:31 Vào Catalog Điểm bán, mở Predefined để tạo phần tử xác định trước · 1:04 Nhập phần tử predefined (tên "...supermarket"); sang Document Sale, attribute POS, đặt thuộc tính Fill value · 1:35 Chạy thử: tạo chứng từ bán hàng mới, điểm bán tự hiển thị giá trị mặc định
- Người học thường hỏi: "muốn chứng từ mới tự điền sẵn kho/điểm bán mặc định"; "mỗi lần tạo phiếu phải chọn lại kho"
- Bài giáo trình: Bài 4 (chính); Bài 3, Bài 16
- Đề BTL Jet: Đề 2, Đề 9
- Nhóm phù hợp: J M — mức cơ bản
- Lưu ý khi giới thiệu: Fill value (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant) chỉ áp dụng khi tạo object mới. Mặc định khác nhau theo người dùng thì phải điền bằng code (OnCreateAtServer / Filling — Bài 16).
- _(mã nội bộ QA-10)_

### Kiểm tra dữ liệu trùng lặp — 8:55

- Link: https://www.youtube.com/watch?v=603j21ItABk&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=11
- Chủ đề để dẫn: cảnh báo dữ liệu trùng
- Video làm gì: Hàm CheckDuplicate dùng Catalogs.Customer.FindByAttribute("PhoneNumber", …) gọi trong OnChange, BeforeClose, BeforeWrite của form khách hàng; trùng thì hiện thông báo. Video nói rõ mới cảnh báo, chưa chặn ghi.
- Mốc xem nhanh: 0:00 Đặt bài toán: kiểm tra trùng số điện thoại khách hàng trong Catalog Customer · 1:03 Demo: chưa có kiểm tra thì vẫn tạo được khách hàng trùng số · 2:06 Function CheckDuplicate(PhoneNumber), dùng Catalogs.Customer.FindByAttribute với tên attribute dạng chuỗi · 3:40 Kiểm tra kết quả rỗng (IsEmpty) để trả về False (không trùng) / True (trùng) · 4:12 Gắn vào các sự kiện: OnChange của trường PhoneNumber, BeforeClose, BeforeWrite của form · 7:18 Chạy thử: đổi số điện thoại trùng thì hiện cảnh báo · 8:23 Kết luận: mới phát hiện trùng, chưa ngăn được việc ghi
- Người học thường hỏi: "muốn chặn nhập trùng số điện thoại / mã số thuế"; "báo lỗi khi tạo khách hàng đã tồn tại"
- Bài giáo trình: Bài 16 (chính); Bài 12, Bài 7
- Đề BTL Jet: Đề 4
- Nhóm phù hợp: M D — mức cơ bản
- Lưu ý khi giới thiệu: FindByAttribute không loại trừ chính khách hàng đang sửa, nên sửa và ghi lại khách hàng cũ sẽ bị báo trùng nhầm — cần so với Object.Ref. Muốn chặn ghi xem video "Hủy sự kiện đang thực thi"; nơi chuẩn để kiểm tra là FillCheckProcessing/BeforeWrite của object (Bài 12).
- _(mã nội bộ QA-11)_

### Tự động lấy đơn vị tính của sản phẩm — 8:16

- Link: https://www.youtube.com/watch?v=RKAGi62Vy5E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=12
- Chủ đề để dẫn: điền thuộc tính sản phẩm vào dòng chứng từ
- Video làm gì: Tạo catalog đơn vị tính, thêm attribute vào Products và cột vào bảng hàng của Document Sale; trong OnChange của cột Product gọi hàm server trả về Product.UOM rồi gán vào dòng hiện tại. Có xử lý lỗi gọi sai context.
- Mốc xem nhanh: 0:00 Nêu bài toán: đổi sản phẩm trên dòng chứng từ Sale thì đơn vị tính đổi theo · 0:31 Tạo Catalog đơn vị tính (UOM) · 2:05 Đưa catalog vào subsystem, cấp quyền cho role admin, nhập dữ liệu đơn vị tính · 3:07 Kéo trường UOM vào item form sản phẩm, nhập sản phẩm thử (bánh phở = kg, mì chính) · 4:11 Thêm cột UOM vào bảng hàng trên form Sale; viết function GetUOM(Product) chạy ở server · 6:47 Sửa lỗi directive (context/no context), kiểm tra cú pháp · 7:22 Chạy thử: chọn sản phẩm, đơn vị tính tự điền
- Người học thường hỏi: "chọn sản phẩm mà đơn vị tính không tự hiện"; "lấy thuộc tính của sản phẩm điền vào dòng hàng"; "lỗi khi đọc Product.UOM ở client"
- Bài giáo trình: Bài 7 (chính); Bài 3, Bài 16, Bài 9, Bài 20
- Đề BTL Jet: Đề 1, Đề 3, Đề 5
- Nhóm phù hợp: M D J — mức cơ bản
- Lưu ý khi giới thiệu: Chỉ đọc một thuộc tính thì dùng &AtServerNoContext; kiểm tra CurrentData <> Undefined trước khi gán.
- _(mã nội bộ QA-12)_

### Kết nhập file excel vào danh mục sản phẩm — 38:42

- Link: https://www.youtube.com/watch?v=DlXBXRzBJGw&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=13
- Chủ đề để dẫn: nhập dữ liệu từ Excel
- Video làm gì: Data processor trong cấu hình: chọn file bằng FileDialog, mở bằng COMObject("Excel.Application"), đọc từng dòng tạo phần tử Catalogs.Products, tự tạo đơn vị tính nếu chưa có, đóng Excel.
- Mốc xem nhanh: 0:00 Giới thiệu file Excel mẫu (STT, Description, UOM) và mục tiêu nhập vào danh mục sản phẩm · 2:05 Tạo form, attribute ExcelFile kiểu String, trường nhập có ChoiceButton · 3:11 Sự kiện StartChoice: New FileDialog(FileDialogMode.Open), Title, Filter cho xls/xlsx · 7:30 Nếu chọn được file thì gán FullFileName vào ExcelFile; chạy thử hộp thoại chọn file · 12:12 Mở Sheets(1), xác định phiên bản Excel để đếm số dòng/cột ([14:17]–[17:59]) · 23:46 Vòng lặp từ dòng 2: CreateItem sản phẩm, đọc từng ô, gán Description; tìm/tạo mới UOM ([27:37]–[32:22]) · 33:26 Write sản phẩm; DisplayAlerts = False, Excel.Quit(); [35:01] gắn vào command; [36:35]–[37:36] sửa lỗi sai tên, chạy thành công
- Người học thường hỏi: "nhập danh sách sản phẩm từ file Excel vào 1C"; "sau khi import file Excel bị khóa không mở được"
- Bài giáo trình: Bài 19 (chính); Bài 7, Bài 12, Bài 23
- Đề BTL Jet: Đề 2, Đề 9
- Nhóm phù hợp: D M — mức nâng cao
- Lưu ý khi giới thiệu: COM Excel chạy trên server: chỉ ổn ở file infobase trên máy có cài Excel; client-server phải chuyển file lên server. Không kiểm tra trùng nên chạy lại sẽ nhân đôi dữ liệu. Cách của giáo trình (Bài 19) là đọc file vào SpreadsheetDocument.
- _(mã nội bộ QA-13)_

### Xây dựng cơ chế tích điểm thưởng — 23:35

- Link: https://www.youtube.com/watch?v=0aAaQQP9fXI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=14
- Chủ đề để dẫn: tích và trừ điểm thưởng qua register
- Video làm gì: Accumulation register điểm thưởng (Balances, dimension Customer); chứng từ bán ghi Receipt điểm theo số tiền và Expense điểm đã dùng; báo cáo số dư điểm; trên form giới hạn số điểm được dùng bằng query số dư.
- Mốc xem nhanh: 0:30 Đặt bài toán: 1.000 đồng = 1 điểm, khách dùng điểm để trừ tiền · 1:32 Thêm register vào Register records của Document Sale, Register records wizard: điểm = tiền phải trả / 1000 · 2:35 Tạo báo cáo từ bảng ảo Balance (Customer, điểm Balance), đưa vào subsystem, cấp quyền admin · 4:09 Đăng lại các chứng từ Sale, kiểm tra báo cáo (64 + 21 = 85) · 7:50 Tính điểm nhận thêm trong procedure tính tiền phải trả · 14:38 Nếu dùng vượt điểm tối đa thì báo và đặt về 0; trừ điểm × 1000 vào tiền phải trả; sửa lỗi thiếu EndIf · 21:33 Thêm movement Expense (RecordType.Expense) trong Posting để trừ điểm đã dùng; [22:05] kiểm tra báo cáo 465
- Người học thường hỏi: "tích điểm cho khách khi bán hàng"; "trừ điểm thưởng đã dùng"; "khách dùng quá số điểm đang có"
- Bài giáo trình: Bài 11 (chính); Bài 10, Bài 18, Bài 16
- Đề BTL Jet: Đề 5, Đề 7
- Nhóm phù hợp: M D — mức trung bình – nâng cao
- Lưu ý khi giới thiệu: Giới hạn điểm chỉ kiểm tra trên form; posting chưa chặn số dư âm. Query số dư không truyền Period nên mở lại chứng từ đã post thì số dư đã gồm chính nó.
- _(mã nội bộ QA-14)_

### Lưu bộ xử lý ngoài — 1:40

- Link: https://www.youtube.com/watch?v=DTRivJSbAoI&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=15
- Chủ đề để dẫn: bộ xử lý ngoài (.epf)
- Video làm gì: Lưu một data processor của cấu hình thành file bộ xử lý ngoài, mở bằng File → Open trong 1C:Enterprise ở cấu hình khác (có cảnh báo bảo mật); mở file trong Designer để xem code.
- Mốc xem nhanh: 0:00 Mục tiêu: lưu data processor trong cấu hình ra file để dùng ở cấu hình khác · 0:00 Chọn data processor trong cây cấu hình, dùng chức năng lưu thành external data processor · 0:31 Lưu file ra Desktop · 1:03 Mở file trong 1C:Enterprise mode, chấp nhận cảnh báo bảo mật, chạy được · 1:03 Mở file trong Designer để xem form và module code
- Người học thường hỏi: "mang data processor sang database khác mà không cập nhật cấu hình"; "mở file .epf bị cảnh báo bảo mật"
- Bài giáo trình: Bài 19 (chính); Bài 21, Bài 20
- Đề BTL Jet: —
- Nhóm phù hợp: D M — mức cơ bản
- Lưu ý khi giới thiệu: Người dùng cần quyền mở external data processor. Trên cấu hình dùng SSL (như Jet) nên đăng ký qua Additional reports and data processors (Bài 21).
- _(mã nội bộ QA-15)_

### Hủy sự kiện đang thực thi — 3:18

- Link: https://www.youtube.com/watch?v=rW40s85Gtc4&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=16
- Chủ đề để dẫn: chặn ghi bằng Cancel = True
- Video làm gì: Tiếp video kiểm tra trùng: trong BeforeWrite của form khách hàng, khi trùng thì gán Cancel = True; giải thích handler có tham số Cancel thì hủy được hành động. Ghi khách hàng trùng bị chặn.
- Mốc xem nhanh: 0:00 Nhắc lại ví dụ kiểm tra trùng số điện thoại khách hàng · 0:31 Demo: hệ thống báo trùng nhưng vẫn ghi đối tượng · 1:03 Mục tiêu: chặn sự kiện ghi để không cho đối tượng sai vào database · 1:34 Mở module form Customer, xem CheckDuplicate, OnChange, BeforeClose, BeforeWrite · 2:04 Giải thích tham số Cancel; gán Cancel = True trong BeforeWrite khi trùng · 2:43 Chạy thử: Save and close bị chặn, khách hàng trùng không được ghi
- Người học thường hỏi: "đã báo lỗi rồi mà vẫn lưu được dữ liệu sai"; "làm sao chặn không cho ghi khi dữ liệu không hợp lệ"
- Bài giáo trình: Bài 16 (chính); Bài 12
- Đề BTL Jet: Đề 4, Đề 7
- Nhóm phù hợp: J M D — mức cơ bản
- Lưu ý khi giới thiệu: Cancel trong BeforeWrite của form chỉ chặn khi ghi từ form; muốn chặn mọi đường ghi (code, import) đặt kiểm tra ở object module hoặc FillCheckProcessing (Bài 12). Vẫn còn lỗi báo trùng nhầm của video trước.
- _(mã nội bộ QA-16)_

### Truy vấn tồn kho trong chứng từ bán hàng — 9:53

- Link: https://www.youtube.com/watch?v=13817kAvhwQ&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=17
- Chủ đề để dẫn: hiển thị tồn kho khi chọn hàng
- Video làm gì: Thêm cột tồn kho vào bảng hàng của chứng từ bán; khi chọn Product gọi hàm server chạy query trên bảng ảo Balance của register tồn kho theo sản phẩm và điểm bán; không có bản ghi thì trả 0; chỉnh Format để hiện số 0.
- Mốc xem nhanh: 0:00 Đặt bài toán: chứng từ bán hàng cần cột tồn kho khi chọn mặt hàng · 0:32 Thêm attribute tồn kho (Number) vào tabular section, đặt cạnh Quantity trên form · 3:11 Thêm tham số Location; dùng Query builder lấy bảng Balance của register tồn kho · 4:15 Điều kiện Product = &Product, điểm bán = &Location · 4:45 Selection.Next: trả về số dư; không có bản ghi thì trả về 0 · 6:55 Chạy thử: tồn kho âm vẫn hiện (chưa chặn), tồn 0 hiện trống · 7:56 Chỉnh Format và EditFormat: NZ=0 để hiện số 0; [9:31] kiểm tra lại
- Người học thường hỏi: "muốn xem tồn kho ngay khi chọn hàng trên phiếu bán"; "query tồn kho trả về rỗng khi sản phẩm chưa nhập"; "ô số lượng bằng 0 bị trống"
- Bài giáo trình: Bài 10 (chính); Bài 11, Bài 7, Bài 16, Bài 9
- Đề BTL Jet: Đề 2, Đề 9, Đề 1
- Nhóm phù hợp: J M D — mức trung bình
- Lưu ý khi giới thiệu: Query không truyền Period nên lấy số dư hiện tại, không theo ngày chứng từ. Nên đặt điều kiện trong tham số của virtual table Balance thay vì WHERE.
- _(mã nội bộ QA-17)_

### Báo động tồn kho thấp với màu chữ hiển thị — 13:09

- Link: https://www.youtube.com/watch?v=0JbOMl80lnY&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=18
- Chủ đề để dẫn: tô màu cảnh báo tồn kho thấp
- Video làm gì: Thêm định mức tối thiểu vào Products và cột định mức vào bảng hàng chứng từ bán; Conditional appearance của form tô đỏ ô tồn kho khi tồn < định mức (so sánh hai cột của dòng).
- Mốc xem nhanh: 0:00 Bài toán: cảnh báo tồn kho thấp; ngưỡng do người dùng đặt · 1:03 Thêm attribute MinInventory (Number) vào Catalog Products, đưa lên item form, nhập ngưỡng · 2:36 Thêm cột MinInventory vào tabular section Sale, cạnh cột tồn kho · 6:18 Gọi trong OnChange của Product, gán vào cột MinInventory · 7:20 Chạy thử: hiển thị tồn kho và tồn tối thiểu (tồn đang âm) · 8:26 Form > Conditional appearance: TextColor đỏ, điều kiện tồn kho < MinInventory, Formatted fields = cột tồn kho · 10:04 Chạy thử: tồn thấp hiện đỏ; [10:35] nhập hàng cho điểm bán khác, tồn đủ thì không đỏ
- Người học thường hỏi: "tồn kho dưới mức tối thiểu thì hiện màu đỏ"; "conditional appearance so sánh hai cột"; "đặt định mức tồn kho tối thiểu"
- Bài giáo trình: Bài 9 (chính); Bài 3, Bài 10, Bài 16
- Đề BTL Jet: Đề 2, Đề 9
- Nhóm phù hợp: J M — mức cơ bản – trung bình
- Lưu ý khi giới thiệu: Định mức chỉ theo sản phẩm; Đề 2 cần định mức theo từng cửa hàng/kho (thường dùng information register). Lưu tồn và định mức vào dòng chứng từ là dữ liệu thừa.
- _(mã nội bộ QA-18)_

### Lọc dữ liệu chọn sản phẩm theo hãng — 6:30

- Link: https://www.youtube.com/watch?v=EfF2acfP2Y8&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=19
- Chủ đề để dẫn: lọc danh sách chọn theo một trường khác
- Video làm gì: Tạo catalog Brand, thêm Brand vào Products và vào chứng từ bán; dùng Choice parameter links (Filter.Brand ↔ Object.Brand) trên cột sản phẩm để khi chọn hãng thì danh sách sản phẩm chỉ còn hàng của hãng đó; cấp quyền role cho catalog mới.
- Mốc xem nhanh: 0:30 Tạo Catalog Brand; thêm attribute Brand vào Catalog sản phẩm · 1:33 Đưa Brand lên form của sản phẩm · 2:04 Chạy thử: không sửa được Catalog Brand vì thiếu quyền, vào Role admin cấp quyền · 2:38 Nhập dữ liệu mẫu hãng và sản phẩm · 4:12 Giới thiệu Choice parameters (giá trị cố định) và Choice parameter links · 5:14 Chạy thử: chọn "Trang điểm Hoàng Anh" chỉ còn phấn má, son môi; gợi ý áp dụng cho bài hãng xe → xe · 5:46 Nói thêm về link theo cột trong tabular section
- Người học thường hỏi: "chọn hãng/nhà cung cấp rồi mà danh sách sản phẩm vẫn hiện tất cả"; "tạo catalog mới chạy lên không sửa được, báo không đủ quyền"
- Bài giáo trình: Bài 9 (chính); Bài 3, Bài 20
- Đề BTL Jet: Đề 3, Đề 6, Đề 1
- Nhóm phù hợp: J M — mức cơ bản
- Lưu ý khi giới thiệu: Giáo trình Bài 9 dạy Choice parameters (giá trị cố định); Choice parameter links (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant). Đổi hãng sau khi đã chọn hàng thì dòng cũ không bị kiểm tra lại.
- _(mã nội bộ QA-19)_

### Hướng dẫn truy cập bản dùng thử 1C:AccountingSuite — 1:16

- Link: https://www.youtube.com/watch?v=8Vmkv3KP5ek&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=20
- Chủ đề để dẫn: xem thử một ứng dụng 1C thực tế qua trình duyệt
- Video làm gì: Mở trang dùng thử, đăng nhập bằng tài khoản demo có sẵn (chọn tài khoản tiếng Việt) và xem giao diện phần mềm kế toán qua trình duyệt.
- Mốc xem nhanh: 0:00 Giới thiệu mục đích: bản dùng thử cho khách hàng/đối tác/trường học · 0:00 Mở địa chỉ web của bản dùng thử · 0:31 Chọn tài khoản dùng thử (bản tiếng Việt), nhập mật khẩu · 0:31 Vào xem giao diện phần mềm qua trình duyệt
- Người học thường hỏi: "muốn xem thử phần mềm 1C mà không cài đặt"
- Bài giáo trình: Bài 1 (chính)
- Đề BTL Jet: —
- Nhóm phù hợp: J — mức giới thiệu
- Lưu ý khi giới thiệu: Địa chỉ và tài khoản demo có thể đã thay đổi; kiểm tra trước khi gửi.
- _(mã nội bộ QA-20)_

### Hiển thị đối tượng Siêu dữ liệu lên Quick menu — 2:23

- Link: https://www.youtube.com/watch?v=rPSNKvFEQ8E&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=21
- Chủ đề để dẫn: bật lệnh cho phân hệ đang trống
- Video làm gì: Phân hệ đã hiện nhưng không có gì bên trong: mở Command interface và bật Visibility cho lệnh danh sách và lệnh "tạo mới" của Document Sale, rồi của catalog sản phẩm.
- Mốc xem nhanh: 0:00 Mô tả: Quick menu xuất hiện nhưng trống · 0:32 Mở Command interface trong Designer, tìm Document Sale và lệnh "Sale: create" · 1:03 Tích hiển thị (Visibility) cho cả hai lệnh · 1:33 Chạy thử: danh sách Sale và lệnh tạo Sale mới đã xuất hiện · 1:33 Thêm Catalog sản phẩm, chỉ tích lệnh danh sách · 2:06 Chạy lại: catalog sản phẩm hiện, lệnh tạo mới không hiện
- Người học thường hỏi: "tạo phân hệ/đối tượng mới mà vào không thấy gì"; "muốn hiện nút Tạo mới ngay trên phân hệ"
- Bài giáo trình: Bài 14 (chính); Bài 9
- Đề BTL Jet: mọi đề (khi thêm object mới vào Jet)
- Nhóm phù hợp: J M — mức cơ bản
- Lưu ý khi giới thiệu: "Quick menu" là tên phân hệ trong ví dụ, không phải khái niệm của nền tảng. Object phải nằm trong Content của subsystem và role phải có quyền thì lệnh mới hiện.
- _(mã nội bộ QA-21)_

### Extension (Phần mở rộng) trong 1C:Enterprise — 6:33

- Link: https://www.youtube.com/watch?v=T_DEaA1p_bA&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=22
- Chủ đề để dẫn: thêm báo cáo bằng extension mà không sửa cấu hình gốc
- Video làm gì: Tạo extension, adopt register tồn kho, tạo báo cáo DCS và subsystem trong extension; chạy thử rồi lưu file .cfe và nạp vào infobase khác.
- Mốc xem nhanh: 0:31 Định nghĩa extension, ví dụ báo cáo riêng cho cấu hình chuẩn · 1:02 Configuration > Configuration extensions > Add, đổi tên/prefix · 3:10 Tạo Report trong extension, mở Data composition schema, tạo data set query · 3:41 Settings: list, chọn trường hiển thị · 4:12 Tạo Subsystem trong extension, thêm report vào Content; chạy thử · 5:13 Mở infobase khác, thêm extension từ file · 5:45 Chạy report trên infobase mới, đọc dữ liệu register
- Người học thường hỏi: "muốn thêm báo cáo vào cấu hình chuẩn mà không sửa cấu hình gốc"; "tạo extension xong không thấy báo cáo"; "mang extension sang database khác"
- Bài giáo trình: bài Extensions (chính); Bài 18, Bài 9, Bài 11
- Đề BTL Jet: Đề 2, Đề 4, Đề 7, Đề 8, Đề 9
- Nhóm phù hợp: D M J — mức trung bình
- Lưu ý khi giới thiệu: Video không nói về Purpose (Patch/Customization/Add-on — xem bài Extensions). Extension chỉ nạp được vào cấu hình có đúng các object đã adopt; object mới cần quyền.
- _(mã nội bộ QA-22)_

### Thực hiện tính toán đơn giản với SQL trong 1C — 2:59

- Link: https://www.youtube.com/watch?v=dP21dfHxkCo&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=23
- Chủ đề để dẫn: tính toán ngay trong query
- Video làm gì: Trong query của DCS, bỏ trường lưu sẵn và thêm trường tính Revenue − Cost với alias tiếng Việt, rồi sửa Settings của báo cáo.
- Mốc xem nhanh: 0:00 Giới thiệu report có Revenue, Cost, Benefits; Benefits đang ghi sẵn vào register · 1:03 Mở DCS, sửa query: bỏ Benefits · 1:33 Thêm trường tính toán Revenue - Cost AS "Lợi nhuận" trong SELECT · 2:04 Sửa Settings: bỏ Benefits, thêm Lợi nhuận · 2:36 Chạy report: cột lợi nhuận hiển thị
- Người học thường hỏi: "muốn báo cáo có cột chênh lệch mà không lưu vào register"; "tính toán cột trong query 1C thế nào"
- Bài giáo trình: Bài 10 (chính); Bài 18
- Đề BTL Jet: Đề 8, Đề 9, Đề 5, Đề 4
- Nhóm phù hợp: J M — mức cơ bản
- Lưu ý khi giới thiệu: Đây là ngôn ngữ truy vấn 1C, không phải SQL. Với LEFT JOIN cần ISNULL; phép chia phải kiểm tra mẫu số 0 (CASE).
- _(mã nội bộ QA-23)_

### Thay đổi Style (màu sắc) của chương trình — 2:47

- Link: https://www.youtube.com/watch?v=cgmDdh6bHMg&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=24
- Chủ đề để dẫn: đổi màu giao diện bằng Style
- Video làm gì: Tạo Style trong nhánh Common, đổi màu một số style item, gán vào thuộc tính Style của cấu hình; giao diện đổi màu.
- Mốc xem nhanh: 0:00 Đặt vấn đề: đổi màu vàng mặc định của giao diện · 0:33 Common > Styles: tạo Style mới · 1:07 Đổi màu các style item (hồng, xanh) · 1:38 Kết quả trong editor: màu đã đổi · 2:09 Configuration root > properties > Style: chọn style mới · 2:09 Chạy chương trình, giao diện đổi màu
- Người học thường hỏi: "muốn đổi màu vàng của giao diện 1C theo màu công ty"
- Bài giáo trình: Bài 9 (chính)
- Đề BTL Jet: —
- Nhóm phù hợp: M D — mức cơ bản
- Lưu ý khi giới thiệu: Đối tượng Style (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant); không phải vùng nào trên giao diện cũng đổi được qua Style.
- _(mã nội bộ QA-24)_

### Chặn kết chuyển khi phát hiện tồn kho âm — 10:03

- Link: https://www.youtube.com/watch?v=k2uht5J1f3c&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=25
- Chủ đề để dẫn: kiểm soát âm kho khi posting
- Video làm gì: Trong Posting của chứng từ bán: ghi movements vào register trước, query bảng ảo Balance (sản phẩm IN danh sách, kho = kho chứng từ) lấy dòng có tồn < 0; nếu có thì báo thiếu bao nhiêu và Cancel = True.
- Mốc xem nhanh: 0:00 Tái hiện lỗi: bán son môi tồn 0 vẫn post được · 1:37 Mở module Document Sale, handler Posting · 2:10 Ghi movements vào register trước khi kiểm tra · 2:42 Query Builder: virtual table Balance, điều kiện sản phẩm IN (&list) và kho = &kho · 4:15 Tham số danh sách sản phẩm = UnloadColumn từ tabular section · 7:14 Sửa lỗi cú pháp (thiếu đóng ngoặc), chạy thử · 8:57 Post bị chặn: "Failed to post" + thông báo thiếu hàng
- Người học thường hỏi: "bán vượt tồn mà chứng từ vẫn post được, tồn kho bị âm"; "làm sao không cho kết chuyển khi không đủ hàng"
- Bài giáo trình: Bài 11 (chính); Bài 10, Bài 12
- Đề BTL Jet: Đề 1, Đề 9, Đề 2
- Nhóm phù hợp: J M D — mức trung bình
- Lưu ý khi giới thiệu: Không đặt Period cho Balance nên chứng từ ghi lùi ngày bị kiểm tra theo tồn hiện tại — giáo trình Bài 11 dùng PointInTime/Boundary. Không khóa dữ liệu khi nhiều người post cùng lúc (managed lock (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant)).
- _(mã nội bộ QA-25)_

### Tùy chỉnh ngôn ngữ theo người dùng — 4:30

- Link: https://www.youtube.com/watch?v=wo7G7jSPtBE&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=26
- Chủ đề để dẫn: hiển thị ngôn ngữ khác nhau cho từng người dùng
- Video làm gì: Tạo Language "vi" bên cạnh English, nhập synonym tiếng Việt cho Document Sale, đặt Language cho từng user trong Administration → Users; user tiếng Việt thấy "Bán hàng".
- Mốc xem nhanh: 0:00 Đặt vấn đề: giao diện theo ngôn ngữ của từng user · 1:01 Languages: có English (en), tạo Vietnamese (vi) · 1:31 Mở Synonym của Document Sale · 2:03 Administration > Users: user admin EN, Language = English · 2:34 Tạo user admin VN, Language = Vietnamese; update configuration · 3:05 Chạy bằng user EN: hiện "Sale" · 3:41 Chạy bằng user VN: hiện "Bán hàng"
- Người học thường hỏi: "muốn user Việt thấy tiếng Việt, user nước ngoài thấy tiếng Anh"; "đã thêm ngôn ngữ mà vẫn hiện tiếng Anh"
- Bài giáo trình: Bài 20 (chính); Bài 2
- Đề BTL Jet: —
- Nhóm phù hợp: D M — mức cơ bản
- Lưu ý khi giới thiệu: Chỉ synonym của metadata được dịch; chuỗi trong code cần NStr; dữ liệu (tên hàng…) không tự dịch. Trên cấu hình SSL quản lý user qua catalog Users.
- _(mã nội bộ QA-26)_

### Kết xuất kết nhập cấu hình bằng file *.1CD — 3:29

- Link: https://www.youtube.com/watch?v=3X0EAToibUg&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=27
- Chủ đề để dẫn: mang một file infobase sang máy hoặc thư mục khác
- Video làm gì: Tạo infobase mới rồi chép file 1Cv8.1CD của infobase khác đè vào thư mục; mở lên có đủ cấu hình và dữ liệu. So sánh nhanh với cách gửi file .cf và .dt.
- Mốc xem nhanh: 0:00 Mục tiêu: gửi file .1CD sang cấu hình khác; nhắc .cf (cấu hình) và .dt (cấu hình + dữ liệu) · 0:30 Tạo infobase mới, chọn thư mục lưu · 1:01 Mở infobase thư viện để xem các đối tượng · 1:32 Mở thư mục infobase, tìm file 1Cv8.1CD · 2:02 Chép và dán đè vào thư mục infobase mới (Replace) · 2:35 Mở lại: có đủ dữ liệu độc giả, mượn, trả; so sánh với .dt
- Người học thường hỏi: "gửi bài/infobase cho thầy cô hoặc bạn cùng nhóm thế nào"; "chép database sang máy khác"
- Bài giáo trình: Bài 1 (chính)
- Đề BTL Jet: —
- Nhóm phù hợp: J M D — mức cơ bản
- Lưu ý khi giới thiệu: Chỉ dùng với file infobase và phải đóng mọi phiên làm việc trước khi chép. Cách nên dùng để nộp bài là Dump infobase (.dt) hoặc lưu cấu hình (.cf) — Bài 1.
- _(mã nội bộ QA-27)_

### Hướng dẫn publish Infobase 1C:Enterprise lên web server — 7:21

- Link: https://www.youtube.com/watch?v=P_bwSfxAV8I&list=PLp-gQ5Mgw0ZyRJw4qEFKcUz4cCagjYG6r&index=28
- Chủ đề để dẫn: publish infobase lên web server (IIS)
- Video làm gì: Bật IIS và ISAPI Extensions trên Windows, kiểm tra thành phần web server extension của bộ cài, cấp quyền IIS_IUSRS, Publish to web server từ Designer, chỉnh handler và Application pool; mở localhost/<tên> để đăng nhập.
- Mốc xem nhanh: 0:00 Giới thiệu: publish infobase lên IIS · 1:03 Thêm ASP.NET 3.5, .NET Extensibility; cài và kiểm tra localhost · 2:06 Kiểm tra bản cài 1C có web server extension · 2:36 Thư mục cài 1C: Security, thêm IIS_IUSRS, Full control · 4:11 IIS Manager: trỏ tới module web server extension của 1C · 5:16 Mở localhost/<tên>: màn hình đăng nhập · 5:46 Tạo Role admin và user admin, đăng nhập web thành công
- Người học thường hỏi: "publish xong mở trình duyệt báo lỗi"; "muốn truy cập 1C qua trình duyệt từ máy khác"
- Bài giáo trình: Bài 1 (chính); Bài 7, Bài 20
- Đề BTL Jet: —
- Nhóm phù hợp: D — mức trung bình
- Lưu ý khi giới thiệu: Cấp Full control cho IIS_IUSRS trên cả thư mục cài 1C là quá rộng. "Enable 32-bit applications" chỉ đúng khi cài nền tảng 32-bit.
- _(mã nội bộ QA-28)_

## C. Ghi chú về playlist

- Tiêu đề video đánh số "Bài 13 … Bài 36" theo thứ tự riêng của playlist, **không** trùng số bài giáo trình (ví dụ video "Bài 22: Kiểm tra dữ liệu trùng lặp" không thuộc Bài 22 – SSL Print). Khi người học gọi video theo số đó, tra bảng trên theo tên.
- Vị trí 20 (bản dùng thử AccountingSuite) và 27 (chép file .1CD) không mang số "Bài N". Video vị trí 27 chưa có trong file Excel đối chiếu ban đầu.
- Nhiều video được quay trên cấu hình ví dụ bán mỹ phẩm (Sale, Products, POS/điểm bán) — tên object trong video không phải tên trong giáo trình hay trong Jet.
