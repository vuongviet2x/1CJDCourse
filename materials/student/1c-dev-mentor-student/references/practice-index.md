# Danh mục bài thực hành của giáo trình (để nhận diện, không có lời giải)

> **Khi nào đọc file này:** trước khi viết code cho một yêu cầu, để kiểm tra yêu cầu có trùng một bài thực hành của 24 bài hoặc bài Extensions không (bước 2 trong `chinh-sach-code.md`). File chỉ liệt kê tên bài tập (thẻ gợi ý của 24 bài + Extensions, và các đề đánh giá Intern / Partner); đề tóm tắt và gợi ý nằm trong file bài tương ứng.

Cách đối chiếu: so **cơ chế + object + chức năng**, không so tên. Đổi tên object (ví dụ `GoodsInWarehouses` → `TonKho`), đổi ngành, hay tách đề thành nhiều câu hỏi nhỏ không làm yêu cầu thôi là bài thực hành.

## `bai-01-04.md` — Thẻ gợi ý bài thực hành (Practice 1–4)
- Practice 1 — Bài tập Task 1 (tạo infobase, load configuration, dump/restore)
- Practice 1 — Bài tập Task 2 (danh sách infobase, web client, server infobase)
- Practice 1 — Bài tập Task 3 (Compare and merge, cache form)
- Practice 2 — Bài tập Task 1 (reference và primitive types)
- Practice 2 — Bài tập Task 2 (Standard attributes)
- Practice 3 — Bài tập 1 (infobase mang tên bạn)
- Practice 3 — Bài tập 2 (Countries)
- Practice 3 — Bài tập 3 (Products với presentation khác nhau)
- Practice 3 — Bài tập 4 (ProductsTypes và attribute bắt buộc có giá trị mặc định)
- Practice 3 — Bài tập 5 (subsystem Master data)
- Practice 3 — Bài tập 6 (Counterparties)
- Practice 3 — Bài tập 7 (SalesInvoice với tabular section Products)
- Practice 3 — Bài tập 8 (subsystem Sales)
- Practice 3 — Bài tập 9 (cập nhật và nhập dữ liệu)
- Practice 4 — Bài tập 1 (Products có group, tối đa 4 cấp group)
- Practice 4 — Bài tập 2 (predefined "Vietnam" làm giá trị mặc định)
- Practice 4 — Bài tập 3 (CounterpartyContracts: owner, hierarchy hợp đồng/phụ lục, code)
- Practice 4 — Bài tập 4 (Contract trong SalesInvoice lọc theo Customer)
- Practice 4 — Bài tập 5 (số SalesInvoice duy nhất trong năm)
- Practice 4 — Bài tập 6 (Amount tự tính khi đổi Quantity/Price, procedure CalculateAmountAtRow)

## `bai-05-06.md` — Thẻ gợi ý bài thực hành (Practice 5-6)
- Bài tập 1 — DocumentTotal tự tính từ tabular section Products
- Bài tập 2 — Giá bán tối thiểu (MinimumSalePrice)
- Bài tập 3 — ValidUntil và "Days left" trên form hợp đồng
- Bài tập 4 — Common form TestCollections và SortArray
- Bài tập 5 — ShowSelectionFromValueList (ShowChooseItem + CallbackDescription)
- Bài tập 6 — CopyAndSearchValueTable (Copy theo filter + Total)
- Bài tập 7 — CalculateTotalAtValueTree (cây 3 cấp + function đệ quy)
- Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/05-theory)

## `bai-07.md` — Thẻ gợi ý bài thực hành (Practice 7)
- Bài tập 1 — Attribute Discount (hợp đồng và SalesInvoice)
- Bài tập 2 — FillDiscount trong object module
- Bài tập 3 — Tính Amount có discount, dùng được ở client và server
- Bài tập 4 — DocumentTotal tính trên server
- Bài tập 5 — Cảnh báo hợp đồng hết hiệu lực

## `bai-08.md` — Thẻ gợi ý bài thực hành (Practice 8)
- Bài tập 1 — Breakpoint cơ bản
- Bài tập 2 — Breakpoint bị disable
- Bài tập 3 — Conditional breakpoint
- Bài tập 4 — Step In / Step Out / Step Over
- Bài tập 5 — Đổi giá trị biến khi debug (SendMessage)
- Bài tập 6 — Tìm lỗi trong CreateSalesInvoiceAtServer (Try/Except, ErrorInfo)
- Bài tập 7 — Performance snapshot

## `bai-09.md` — Thẻ gợi ý bài thực hành (Practice 9)
- Bài tập 1 — Subsystem Purchases, picture và explanation
- Bài tập 2 — Document PurchaseInvoice
- Bài tập 3 — Number và Date trên cùng một dòng
- Bài tập 4 — Mặc định chỉ hai panel
- Bài tập 5 — Quan hệ của Counterparty (vendor / customer / other)
- Bài tập 6 — Chỉ chọn Vendor / Customer phù hợp
- Bài tập 7 — Tabular section Services trên page riêng
- Bài tập 8 — Dùng chung thuật toán cho Services
- Bài tập 9 — DocumentTotal = goods + services
- Bài tập 10 — Số dòng trên tiêu đề page "Products (2)"
- Bài tập 11 — Lọc Product theo loại trong Products / Services
- Bài tập 12 — Nút Pick cho Products và Services
- Bài tập 13 — Footer tổng Amount
- Bài tập 14 — List form trên Home page

## `bai-10.md` — Thẻ gợi ý bài thực hành (Practice 10)
- Bài tập 1 — Object Warehouses và attribute Warehouse trong PurchaseInvoice / SalesInvoice
- Bài tập 2 — Subsystem Warehouse
- Bài tập 3 — Document InventoryTransfer
- Bài tập 4 — Bố cục form InventoryTransfer (2 cột header)
- Bài tập 5 — Nút "Pick" trên InventoryTransfer
- Bài tập 6 — Nút "Fill in by the remaining goods" (batch query với temporary tables)
- Bài tập 7 — Catalog Banks
- Bài tập 8 — Catalog BankAccounts (phụ thuộc Banks)
- Bài tập 9 — Subsystem Funds
- Bài tập 10 — Document PaymentExpense (tạo dựa trên PurchaseInvoice)
- Bài tập 11 — Document PaymentReceipt (tạo dựa trên SalesInvoice)
- Bài tập 12 — Nút "Fill in by balance" trên PaymentExpense / PaymentReceipt
- Bài tập T1 — Sales order có tổng services không quá 1000
- Bài tập T2 — Sales order: services > 5000 và goods = 0
- Bài tập T3 — Products có tổng mua và tổng bán > 0 (TempTablesManager, chỉ document đã post)
- Bài tập T4 — Products: từ lần mua cuối tới lần bán cuối không quá một tuần
- Bài tập T5 — Mua và bán theo document trong kỳ, kết quả hai cấp (TOTALS)
- Bài tập T6 — Products: Description + Details "This is a group" / "This is not a group"
- Bài tập T7 — Products KHÔNG nằm trong group có tên chứa "water"

## `bai-11.md` — Thẻ gợi ý bài thực hành (Practice 11)
- Bài tập 1 — Accumulation register GoodsInWarehouses
- Bài tập 2 — Ba document ghi movements vào GoodsInWarehouses
- Bài tập 3 — Viết lại "Fill in by the remaining goods" bằng dữ liệu register
- Bài tập 4 — Document ReturnOfGoodsFromCustomer (Generation từ SalesInvoice)
- Bài tập 5 — Form ReturnOfGoodsFromCustomer: tính amount, khóa Price/Amount, tổng document
- Bài tập 6 — ReturnOfGoodsFromCustomer ghi vào GoodsInWarehouses
- Bài tập 7 — Accumulation register Sales (bán − trả, theo customer và contract)
- Bài tập 8 — RequiredSalesAmount và discount theo doanh số tháng trước

## `bai-12.md` — Thẻ gợi ý bài thực hành (Practice 12)
- Bài tập 1 — InventoryTransfer: chặn posting khi kho gửi = kho nhận
- Bài tập 2 — Catalog Companies và attribute Company trong documents
- Bài tập 3 — Dimension Company trong register Sales
- Bài tập 4 — Banks, BankAccounts (subordinate tới Companies/Counterparties), subsystem Funds
- Bài tập 5 — Attribute "Bank account" với giới hạn lựa chọn
- Bài tập 6 — Kiểm tra đủ hàng trong kho khi post SalesInvoice và InventoryTransfer
- Bài tập 7 — Attribute State của SalesInvoice (Planned, InDelivery, Completed)
- Bài tập 8 — Lịch sử state của SalesInvoice
- Bài tập 9 — Giá theo ngày: document PriceSetup và register ProductPrices
- Bài tập 10 — SalesInvoice tự điền giá theo register, khóa Price/Amount

## `bai-13.md` — Thẻ gợi ý bài thực hành (Practice 13)
- Bài tập 1 — Constant "Control balances of goods" và form "Goods turnover settings"
- Bài tập 2 — Document journal "Sales documents"
- Bài tập 3 — Chart of characteristic types AdditionalAttributesAndProperties
- Bài tập 4 — Characteristics như attributes thường; "Primary supplier" và filter trên list form Products

## `bai-14.md` — Thẻ gợi ý bài thực hành (Practice 14)
- Bài tập 1 — Server common module ProductsInDocuments: kiểm tra số dư dùng chung
- Bài tập 2 — Server call common module: function lấy giá
- Bài tập 3 — Client-server common module: tính amount của dòng, discount tùy chọn
- Bài tập 4 — Parameterizable command "Set price"
- Bài tập 5 — Main section command interface
- Bài tập 6 — Lệnh tạo mới trong command interface của subsystems
- Bài tập 7 — Enumeration WriteOffMethods và constant WriteOffOrder
- Bài tập 8 — Dimension Batch trong GoodsInWarehouses

## `bai-15.md` — Thẻ gợi ý bài thực hành (Practice 15)
- Bài tập 1 — Functional option UseCharacteristics và form cài đặt
- Bài tập 2 — FO có parameter ControlBalanceOfGoods theo từng company
- Bài tập 3 — Prefix số document theo company (CompanyPrefix + OnSetNewNumber)
- Bài tập 4 — Thử xoá object với và không có referential integrity control
- Bài tập 5 — Purchase invoice ghi chính nó vào dimension Batch
- Bài tập 6 — Cột Batch trong Sales invoice và lệnh "Pick batch"

## `bai-16.md` — Thẻ gợi ý bài thực hành (Practice 16)
- Bài tập 1 — Bảng products của document đang chọn trên home page
- Bài tập 2 — Mở item Products khi chọn dòng trong bảng mới
- Bài tập 3 — Event subscription điền Company mặc định cho mọi document
- Bài tập 4 — Posting Sales invoice: phân bổ batch FIFO/LIFO/Manually
- Bài tập 5 — Return of goods from customer: dòng chỉ theo Sales document, trả batch theo thứ tự ngược
- Bài tập 6 — Nút "Fill by sales document" gọi event Filling chuẩn
- Bài tập 7 — Amount trong GoodsInWarehouses theo giá vốn

## `bai-17.md` — Thẻ gợi ý bài thực hành (Practice 17)
- Bài tập 1 — Batch FIFO/LIFO/Manually cho document Inventory transfer
- Bài tập 2 — Print form "List of goods movement" cho Inventory transfer
- Bài tập 3 — Print form cho 2 documents
- Bài tập 4 — Report "Sales by customers" 3 cấp (programmatic template)

## `bai-18.md` — Thẻ gợi ý bài thực hành (Practice 18)
- Bài tập 1 — Report "Sales with price deviation"
- Bài tập 2 — Report "Goods movement" và tồn tối thiểu từ hệ thống ngoài

## `bai-19.md` — Thẻ gợi ý bài thực hành (Practice 19)
- Bài tập 1 — Data processor nạp giá từ Excel vào document PriceSetup

## `bai-20.md` — Thẻ gợi ý bài thực hành (Practice 20)
- Bài tập 1 — Ba role bắt buộc và user Administrator
- Bài tập 2 — Đổi tên configuration
- Bài tập 3 — Role theo chức danh: CEO, PurchaseManager, SalesManager, Storekeeper, MasterDataSpecialist
- Bài tập 4 — Characteristics cho mọi user, quyền xóa chỉ cho CEO, constants chỉ CEO/FullAccess
- Bài tập 5 — Không role nào có Interactive delete và quyền xóa predefined
- Bài tập 6 — Không cấp Update/Edit cho accumulation register, post ở privileged mode
- Bài tập 7 — Tạo user cho từng role và test toàn bộ ứng dụng
- Bài tập 8 — Flag "Modifies saved data" cho nút "Fill by sales document"

## `bai-21.md` — Thẻ gợi ý bài thực hành (Practice 21)
- Bài tập 1 — Global data processor "Revaluation" trong subsystem mới "My projects"
- Bài tập 2 — Đổi giá theo số cho _DemoCustomerProformaInvoice (ObjectFilling)
- Bài tập 3 — Điền giá hiện hành từ register cho _DemoGoodsSales và _DemoCustomerProformaInvoice, có cảnh báo
- Bài tập 4 — Giống bài 3 nhưng FormFilling: không ghi DB, chỉ một object, không hỏi

## `bai-22.md` — Thẻ gợi ý bài thực hành (Practice 22)
- Chuẩn bị — Kết nối _DemoSalesOrder vào Print subsystem (bước chung cho bài 1–3)
- Bài tập 1 — Print form "Sales order" (trong data processor PrintSalesOrder) và "Delivery order" (trong document)
- Bài tập 2 — "Sales order details" bằng PrintManagement, chỉ hiện với document từ 01.01.2025
- Bài tập 3 — "Document set": 2 bản "Sales order" + 1 bản "Delivery order"
- Bài tập 4 (bổ sung) — External print form "Sales order (external)"

## `bai-23.md` — Thẻ gợi ý bài thực hành (Practice 23)
- Bài tập — Phần 1: Kết nối catalog _DemoStorageLocations vào FilesOperations (catalog file riêng)
- Bài tập — Phần 2: Item form có submenu file và hyperlink "Attachments"
- Bài tập — Phần 3: Cột "Paperclip" trên list form
- Bài tập — Phần 4: Ảnh chính trên item form (như _DemoProducts)

## `bai-24.md` — Thẻ gợi ý bài thực hành (Practice 24)
- Bài tập 1 — Cơ chế kế toán: chart of accounts, extra dimensions, accounting register
- Bài tập 2 — Cho user bật/tắt kế toán
- Bài tập 3 — Tài khoản 01 Goods, 02 Trade payables, 03 Trade receivables
- Bài tập 4 — Bút toán khi mua, bán, trả hàng, chuyển kho
- Bài tập 5 — Report Trial Balance
- Bài tập 6 — Document nhập bút toán tay, không posting, xử lý deletion mark

## `bai-extensions.md` — Thẻ gợi ý bài thực hành (Extensions practice)
- Bài tập 1 — Extension "Patch" sửa lỗi lời gọi SetMainProject
- Bài tập 2 — Extension "Customization": ReleasedBy/ReceivedBy cho _DemoInventoryTransfer
- Bài tập 3 — Print form "Transfer Note" in Released/Received by từ attribute mới
- Bài tập 4 — Thử thứ tự gọi khi nhiều extension cùng mở rộng một method

## Đề đánh giá Intern và đề thi Partner (không phải bài thực hành 24 bài, nhưng xử lý như bài thực hành)

Đề gốc nằm trong project của giảng viên. Người học hỏi các đề này → chỉ gợi ý theo bậc, minh họa cơ chế bằng ví dụ khác đề.

- Intern Task 0 — FIFO / LIFO / chọn lô thủ công: register tồn theo lô, xuất theo thứ tự lô, giá bán lẻ periodic do chứng từ ghi
- Intern Task 1.1 — Personal Financial Management (PocketMoney) Module 1: Accounts, ExpenseTypes, Income, Expense, sổ Ledger, kiểm tra số dư, subsystem, panel, common form Balances
- Intern Task 1.2 — PocketMoney Module 2: DefaultAccount, hierarchy, tiền tố số chứng từ, predefined Other, ngân sách Budget / BudgetExecution, StrictBudgetCheck, kiểm tra chỉ khi post real-time
- Intern Task 1.3 — PocketMoney Module 3: tabular section Details cho Income, common module ServiceSrv.ProcessIncomeDocs, ghi log
- Intern Task 4 — Bike rental company: văn phòng, khách, xe, biểu giá Tỉnh × Hạng, nhập xe, cho thuê, trả xe, quỹ, công nợ
- Intern Task 5 — Nạp giá từ Excel vào ProductsPrices (1C:Company Management)
- Intern Task 6 — Mẫu in ngoài cho SalesOrder (1C:Company Management)
- Intern Task 7 — Additional data processor chạy như nhiệm vụ thường kỳ, tạo / đánh dấu xóa Notes (SSL)
- Intern Task 8 — Chart of accounts + accounting register riêng, data processor MonthlyOperations, báo cáo Accounts status (AccountingSuite)
- Intern Task 9 — Chứng từ nhập hàng mới tích hợp vào AccountingSuite (posting, lệnh, role, mẫu in, nạp Excel, báo cáo)
- Partner Exam Stage 1, Đề 1 — điểm thưởng: sơ đồ tích điểm theo ngưỡng doanh số có ngày hiệu lực, thẻ thưởng, báo cáo số dư điểm
- Partner Exam Stage 1, Đề 2 — đa tiền tệ (tỷ giá tới giây), giá nhiều loại tiền tối đa một lần mỗi ngày, chiết khấu theo hợp đồng, báo cáo giá và doanh số
- Partner Exam Stage 1, Đề 3 — PurchaseInvoice, báo cáo tồn kho theo ngày, mẫu in phiếu xuất kho với người phụ trách kho theo ngày
