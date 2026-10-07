# Jet cho người trái ngành — hướng dẫn bài tập lớn cho nhóm 2

Khi nào đọc file này: người hỏi thuộc **nhóm 2 — trái ngành** (ví dụ sinh viên Logistics, kế toán, quản trị) đang làm bài tập lớn trên 1C:Jet: cần hiểu Jet từ góc nghiệp vụ, chuẩn bị dữ liệu và lập **nhật ký chứng từ / phiếu quan sát**, tùy biến mức **M2** trong Designer, hoặc cần một đoạn code đơn giản (M3 nhẹ) kèm giải thích bằng lời thường. Đề bài gốc: `references/btl/de-bai-btl.md`. Nhóm có nền IT (nhóm 1) thì không dùng mục 5 của file này mà theo cách gợi ý-trước trong SKILL.md.

Phiên bản Jet được mô tả: repo `1Ci-Company/Jet`, nhánh `community`, commit `80884de`, configuration 1.0.2.1. Code trích từ Jet ghi nguồn `Nguồn: Jet — cf/...` — bản quyền **1C:Jet (MIT)**. Thao tác Designer lấy từ ghi chú bài giảng `references/lessons/`; chỗ nào ghi chú không có tên nút thì ghi "(tên nút/menu có thể khác theo phiên bản — kiểm tra trên máy)".

Triết lý của file: **nghiệp vụ trước, thuật ngữ sau** — mỗi khái niệm được giải thích bằng chuyện thật ở công ty trước, thuật ngữ 1C để trong ngoặc. Phương pháp: **khai báo → nhập liệu → quan sát hệ quả**.

## Mục lục

1. [Jet nhìn từ góc nghiệp vụ](#1-jet-nhìn-từ-góc-nghiệp-vụ)
2. [Phương pháp "khai báo → nhập liệu → quan sát hệ quả"](#2-phương-pháp-khai-báo--nhập-liệu--quan-sát-hệ-quả)
3. [Quy tắc an toàn trước khi tùy biến](#3-quy-tắc-an-toàn-trước-khi-tùy-biến)
4. [Hướng dẫn M2 từng bước](#4-hướng-dẫn-m2-từng-bước)
5. [Code đơn giản kèm giải thích (M3 nhẹ)](#5-code-đơn-giản-kèm-giải-thích-m3-nhẹ)
6. [Khi nào cần gọi tutor](#6-khi-nào-cần-gọi-tutor)

---

## 1. Jet nhìn từ góc nghiệp vụ

### 1.1. Bốn phân hệ là bốn khâu của một vòng tiền – hàng

Một công ty thương mại nhỏ chạy theo vòng: **mua hàng → hàng nằm trong kho → bán hàng → thu tiền / trả tiền**. Jet chia đúng bốn khâu đó thành bốn phân hệ (subsystem — mỗi phân hệ là một mục trên thanh menu bên trái):

```
  Nhà cung cấp                                                   Khách hàng
       │  hàng về                                                    ▲ giao hàng
       ▼                                                             │
 [Purchases — Mua hàng] ──► [Warehouses — Kho] ──► [Sales — Bán hàng]
   SupplierInvoice          InventoryIncrease        SalesInvoice
       │ nợ NCC tăng        InventoryTransfer             │ khách nợ tăng
       │                    InventoryWriteOff             │
       ▼                                                  ▼
 [CashManagement — Tiền]: trả NCC bằng CashVoucher / BankPayment,
                          thu khách bằng CashReceipt / BankReceipt
```

Ngoài ra có phân hệ **Company** (thông tin công ty, thuế suất VAT) và **Administration** (người dùng, quyền — phần lớn thuộc SSL, thư viện chuẩn Standard Subsystems Library). Nguồn: Jet — cf/Subsystems/*.xml (xem bảng mục 4 của `references/jet/jet-overview.md`).

### 1.2. Ba loại "đồ vật" trong Jet

| Đời thực | Tên trong 1C | Ví dụ trong Jet | Đặc điểm |
|---|---|---|---|
| Sổ danh bạ, danh sách mặt hàng, danh sách kho | **Danh mục** (Catalog) | `Products`, `Counterparties`, `Warehouses`, `PriceTypes`, `CashAccounts`, `BankAccounts` | Người dùng tự thêm/sửa; chứng từ chọn từ đây thay vì gõ tay |
| Danh sách cố định, luật định sẵn | **Liệt kê** (Enumeration) | `ProductTypes` (Inventory = hàng hóa / Service = dịch vụ), `LiabilityTypes` (Liability = nợ / Advance = ứng trước) | Người dùng **không** thêm được giá trị; code dựa vào các giá trị này |
| Tờ phiếu, hóa đơn có ngày, có số | **Chứng từ** (Document) | `SupplierInvoice`, `SalesInvoice`… | Có thể **ghi sổ** (Posting — "post") thì mới làm thay đổi số liệu |
| Sổ cái ghi số liệu tích lũy | **Sổ tích lũy** (Accumulation register) | `InventoryInWarehouses`, `CustomerBalance`… | Chỉ chứng từ được ghi vào; người dùng không sửa tay |
| Bảng tra cứu theo thời gian | **Sổ thông tin** (Information register) | `Prices` (bảng giá) | Lưu "giá trị hiện hành" theo ngày, ví dụ giá bán |

Chưa ghi sổ thì chứng từ chỉ như **bản nháp** — báo cáo không đổi. Đây là điều quan trọng nhất khi lập phiếu quan sát.

### 1.3. Chín chứng từ nghiệp vụ — nghĩa ngoài đời

| Chứng từ (Synonym hiển thị) | Ngoài đời là | Những ô chính | Lưu ý khi dùng |
|---|---|---|---|
| `SupplierInvoice` (Supplier invoice) | Hóa đơn mua / phiếu nhập hàng mua | Supplier (nhà cung cấp), Warehouse (kho nhận), Currency, bảng `Inventory` (mặt hàng, số lượng, giá, VAT), bảng `AdvanceClearing` (trừ tiền đã ứng trước) | Chỉ dòng hàng loại **Inventory** mới vào kho; dòng **Service** chỉ ghi mua và công nợ |
| `SalesInvoice` (Sales invoice) | Hóa đơn bán hàng / phiếu xuất bán | Customer, Warehouse (kho xuất), PriceType (loại giá), bảng `Inventory`, `AdvanceClearing` | Chọn khách → loại giá của khách tự điền → giá tự điền lại |
| `InventoryIncrease` (Inventory increase) | Phiếu nhập kho không qua mua (nhập tồn đầu kỳ, nhập thừa) | Warehouse, bảng `Inventory` (Product, Quantity, Price, Amount) | Wiki của Jet dùng nó để nhập **tồn đầu kỳ**; Price ở đây là **giá vốn** |
| `InventoryWriteOff` (Inventory write-off) | Phiếu xuất hủy / xuất dùng nội bộ | Warehouse, bảng `Inventory` (Product, Quantity) | **Không có đơn giá, không có lý do** — giá trị tính theo giá vốn bình quân |
| `InventoryTransfer` (Inventory transfer) | Phiếu điều chuyển kho | Warehouse (kho xuất), WarehouseReceiver (kho nhận), bảng `Inventory` | Một phiếu = giảm ở kho này, tăng ở kho kia |
| `CashReceipt` (Cash receipt) | Phiếu thu tiền mặt | Operation (Customer = thu khách / Other = thu khác), CashAccount, Counterparty, bảng `PaymentDetails` (thu theo hóa đơn nào) | Để trống cột hóa đơn = khách **ứng trước** |
| `BankReceipt` (Bank receipt) | Giấy báo có ngân hàng | như trên, BankAccount thay CashAccount | |
| `CashVoucher` (Cash voucher) | Phiếu chi tiền mặt | Operation (Supplier = trả NCC / Other = chi khác) | Mọi khoản chi không trả NCC đều rơi vào "Other" |
| `BankPayment` (Bank payment) | Ủy nhiệm chi | như CashVoucher + Paid (đã chi), PaymentDate | **Chỉ ghi sổ khi tick Paid** — chưa tick thì post xong vẫn không có số liệu |

Nguồn: Jet — cf/Documents/<Tên>.xml (Synonym, attributes); điều kiện `Paid` ở cf/Documents/BankPayment/Ext/ManagerModule.bsl; điều kiện `ProductType = Inventory` ở cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl và SalesInvoice tương tự; thông tin tồn đầu kỳ và tạm ứng ở wiki *1C:Jet Initial Setup Guide*, mục 11.

### 1.4. "Sổ" là gì: mỗi sổ trả lời một câu hỏi kinh doanh

Hãy hình dung mỗi sổ tích lũy (accumulation register) là một **cuốn sổ cái có kẻ cột**:

- **Cột "phân tích theo"** (Dimension — chiều): ghi theo kho nào, mặt hàng nào, khách nào…
- **Cột "con số"** (Resource — chỉ tiêu): số lượng, số tiền.
- Mỗi dòng là **ghi tăng** (Receipt) hoặc **ghi giảm** (Expense), do một chứng từ ghi vào.

Có hai loại sổ:

- **Sổ số dư** (kind **Balances**) trả lời **"hiện có bao nhiêu?"** — cộng tăng trừ giảm ra số còn lại tại một thời điểm.
- **Sổ phát sinh** (kind **Turnovers**) trả lời **"trong kỳ đã phát sinh bao nhiêu?"** — chỉ cộng dồn, không có khái niệm "còn lại".

| Sổ | Loại | Câu hỏi kinh doanh nó trả lời | Phân tích theo | Con số |
|---|---|---|---|---|
| `InventoryInWarehouses` | Balances | Kho X hiện còn bao nhiêu cái mặt hàng Y? | Product, Warehouse | Quantity |
| `InventoryCost` | Balances | Lượng hàng tồn đó trị giá bao nhiêu theo giá vốn? | Product, Warehouse | Quantity, Amount |
| `Purchases` | Turnovers | Tháng này đã mua của NCC A bao nhiêu, bao nhiêu tiền? | Counterparty, Product, PurchaseDocument | Quantity, Amount, VATAmount |
| `Sales` | Turnovers | Tháng này đã bán cho khách B bao nhiêu? | Counterparty, Product, SalesDocument | Quantity, Amount, VATAmount |
| `SupplierBalance` | Balances | Còn nợ NCC A bao nhiêu, theo hóa đơn nào; đã ứng trước bao nhiêu? | LiabilityType, Counterparty, Document | Amount |
| `CustomerBalance` | Balances | Khách B còn nợ bao nhiêu, theo hóa đơn nào; khách đã ứng trước bao nhiêu? | LiabilityType, Counterparty, Document | Amount |
| `CashBalance` | Balances | Quỹ tiền mặt / tài khoản ngân hàng hiện còn bao nhiêu? | BankCashAccount, CashType | AmountCur |

Và một **sổ thông tin** (information register) quan trọng: `Prices` — "Giá bán loại giá X của mặt hàng Y **tại ngày Z** là bao nhiêu?". Sổ này ghi theo ngày (Periodicity = Day), không cần chứng từ (Write mode = Independent), được ghi bởi công cụ `PricesSetup` (Prices setup). Nguồn: Jet — cf/AccumulationRegisters/*.xml, cf/InformationRegisters/Prices.xml.

Mẹo đọc `CustomerBalance` (ghép từ code posting, xem mục 9.1 của `references/jet/jet-cash.md`): số dư dòng **Liability** dương = khách đang nợ theo hóa đơn đó; số dư dòng **Advance** âm = khách đã trả trước.

### 1.5. Chứng từ nào ghi sổ nào — nói bằng lời thường

| Khi ghi sổ chứng từ… | Sổ thay đổi thế nào |
|---|---|
| `SupplierInvoice` | Kho nhận **tăng** hàng và giá trị (chỉ hàng loại Inventory) · sổ mua **cộng thêm** · nợ NCC **tăng** (nếu có trừ ứng trước: ứng trước giảm, nợ hóa đơn giảm tương ứng) |
| `SalesInvoice` | Kho xuất **giảm** hàng, giá trị giảm theo giá vốn bình quân · sổ bán **cộng thêm** · khách nợ **tăng** |
| `InventoryIncrease` | Kho **tăng** hàng và giá trị (giá trị = Price nhập trên phiếu) |
| `InventoryTransfer` | Kho xuất **giảm**, kho nhận **tăng** — cả số lượng và giá trị |
| `InventoryWriteOff` | Kho **giảm** hàng, giá trị giảm theo giá vốn bình quân |
| `CashReceipt` / `BankReceipt` | Quỹ / tài khoản **tăng** · khách nợ **giảm** (nếu Operation = Customer) |
| `CashVoucher` / `BankPayment` | Quỹ / tài khoản **giảm** · nợ NCC **giảm** (nếu Operation = Supplier; BankPayment chỉ khi Paid) |

Ba chứng từ kho, SupplierInvoice và SalesInvoice còn **kiểm tra tồn âm**: nếu sau khi ghi mà số dư hiện tại của một mặt hàng ở kho bị âm, chứng từ bị từ chối với thông báo "Insufficient quantity on …". Nguồn: Jet — cf/AccumulationRegisters/InventoryInWarehouses/Ext/ManagerModule.bsl (procedure `NegativeBalanceControl`), lời gọi ở object module của 5 chứng từ này. Lưu ý quan sát: kiểm tra dựa trên số dư **hiện tại**, không theo ngày của chứng từ (mục 13 của `references/jet/jet-warehouse.md`) — đây là một điểm đáng đưa vào phân tích khoảng trống.

---

## 2. Phương pháp "khai báo → nhập liệu → quan sát hệ quả"

### 2.1. Khai báo dữ liệu nền theo đúng thứ tự

Thứ tự dưới đây bám wiki *1C:Jet Initial Setup Guide* (mục 4–11): danh mục nào được danh mục khác tham chiếu thì nhập trước.

| Bước | Ở đâu (Enterprise mode) | Nhập gì cho doanh nghiệp giả định | Vì sao trước |
|---|---|---|---|
| 1 | Company → Companies | Tên công ty, presentation currency (đồng tiền hạch toán) | Jet lấy đồng tiền hạch toán từ `Companies.MainCompany` |
| 2 | Company → VATRates; Warehouses → Units | Thuế suất, đơn vị tính (thùng, cái, kg) | Products tham chiếu tới hai danh mục này |
| 3 | Warehouses → Products | Nhóm hàng (folder), mặt hàng; chọn **ProductType** đúng (hàng hóa hay dịch vụ) | Chọn sai thành Service → hàng không vào kho |
| 4 | Sales → PriceTypes, rồi Prices setup | Loại giá (bán buôn, bán lẻ), bảng giá theo ngày hiệu lực | SalesInvoice lấy giá từ đây |
| 5 | Purchases/Sales → Counterparties | Khách, NCC; tick **Customer** / **Supplier**; gán PriceType cho khách | Một danh mục chung cho cả hai |
| 6 | Warehouses → Warehouses | Các kho / cửa hàng | |
| 7 | Cash management → CashAccounts, BankAccounts | Quỹ, tài khoản ngân hàng (chọn tiền tệ) | Tiền tệ của tài khoản bị khóa sau khi ghi |
| 8 | Chọn **ngày bắt đầu** | Ví dụ 01/03 của tháng giả định | Mọi chứng từ từ ngày này phải nhập đủ |
| 9 | Số dư đầu kỳ | Tồn kho: `InventoryIncrease` (mỗi kho một phiếu); tiền: `CashReceipt` / `BankReceipt` với Operation = **Other**; công nợ: `SalesInvoice` / `SupplierInvoice` với một mặt hàng dịch vụ giả "Opening balances input", ngày **trước** ngày bắt đầu | Không có số dư đầu thì chứng từ bán đầu tiên bị chặn vì tồn âm |

(tên mục menu có thể khác theo phiên bản — kiểm tra trên máy). Hệ quả cần ghi vào phân tích: số dư tiền đầu kỳ nhập bằng "thu khác" sẽ hiện như **một khoản thu trong kỳ** trên báo cáo CashStatement (mục 10 của `references/jet/jet-cash.md`).

### 2.2. Nhập chứng từ và lập nhật ký chứng từ

Đề yêu cầu tối thiểu **15 chứng từ** của phân hệ được giao trong một tháng giả định. "Nhật ký chứng từ" là **bảng nhóm tự lập** (không phải object Document journal trong 1C). Mẫu cột gợi ý:

| STT | Ngày | Loại chứng từ | Số | Đối tượng (khách/NCC/kho) | Nội dung nghiệp vụ | Số lượng / số tiền | Đã post? | Sổ bị ảnh hưởng | Ghi chú (lỗi gặp, cách xử lý) |
|---|---|---|---|---|---|---|---|---|---|

Mẹo để bộ 15 chứng từ "có chuyện để phân tích":
- Trộn tình huống bình thường với tình huống biên: bán vượt tồn (xem Jet chặn thế nào), bán chịu rồi thu một phần, khách ứng trước, chuyển kho, hủy hàng.
- Nhập ít nhất một chứng từ **lùi ngày** so với chứng từ khác để quan sát cách Jet xử lý thứ tự thời gian.
- Ghi lại mọi thông báo lỗi Jet đưa ra — đó là bằng chứng tốt cho phần khoảng trống.

### 2.3. Quan sát trước/sau: báo cáo nào xem sổ nào

| Muốn quan sát sổ | Mở báo cáo (Synonym) | Phân hệ | Báo cáo đọc từ |
|---|---|---|---|
| InventoryInWarehouses | Available stock | Warehouses | `InventoryInWarehouses.Balance` |
| InventoryCost | Stock statement (đầu kỳ – nhập – xuất – cuối kỳ có giá trị) | Warehouses | `InventoryCost.BalanceAndTurnovers` |
| Purchases | Purchases | Purchases | `Purchases.Turnovers` |
| SupplierBalance | Supplier balance | Purchases | `SupplierBalance.Balance` |
| Sales | Sales | Sales | `Sales.Turnovers` |
| CustomerBalance | Customer balance | Sales | `CustomerBalance.Balance` |
| Sales + InventoryCost | Profit on sales (lãi gộp) | Sales | `Sales.Turnovers` + `InventoryCost.Turnovers` |
| Prices | Price list | Sales | `Prices.SliceLast` |
| CashBalance | Cash statement | Cash management | `CashBalance.BalanceAndTurnovers` |

Nguồn: Jet — cf/Reports/<Tên>/Templates/MainDataCompositionSchema/Ext/Template.xml. Chú ý báo cáo **Customer balance nằm ở phân hệ Sales**, kể cả khi nhóm làm đề Tiền (Đề 7).

Ngoài ra trên form chứng từ có lệnh xem **toàn bộ dòng sổ do chứng từ đó ghi**: báo cáo SSL "Document register records" (lệnh nằm trong nhóm "See also" của form; code SSL khai báo phím tắt Ctrl+Shift+A — ngoài giáo trình, hãy kiểm tra lại trên máy). Nguồn: Jet — cf/Reports/DocumentRegisterRecords/Ext/ManagerModule.bsl (`Command.Presentation = "Document register records"`, `New Shortcut(Key.A, False, True, True)`). (tên nút/menu có thể khác theo phiên bản — kiểm tra trên máy). Đây là cách nhanh nhất để chụp phần "SAU" của phiếu quan sát.

### 2.4. Phiếu quan sát (ít nhất 5 chứng từ)

Quy trình cho mỗi chứng từ:

1. **Dự đoán**: nhìn bảng 1.5, ghi ra sổ nào sẽ đổi, tăng hay giảm, bao nhiêu.
2. **Chụp TRƯỚC**: mở các báo cáo ở 2.3 với kỳ bao trùm ngày chứng từ, lọc đúng mặt hàng / khách / kho.
3. **Ghi sổ** chứng từ (Post).
4. **Chụp SAU**: mở lại các báo cáo (bấm tạo lại báo cáo), và mở "Document register records" của chứng từ.
5. **Đối chiếu** dự đoán với thực tế; nếu lệch, giải thích vì sao.

Mẫu bảng:

| Chứng từ | Báo cáo / sổ | Chỉ tiêu | Trước | Sau | Chênh lệch | Đúng dự đoán? | Giải thích |
|---|---|---|---|---|---|---|---|
| SalesInvoice số 0003, 12/03 | Available stock | Mì gói, Kho HN | 120 | 100 | −20 | Có | Bán 20 thùng |
| | Customer balance | Đại lý A, Liability | 0 | 5.500.000 | +5.500.000 | Có | Tổng gồm VAT |
| | Profit on sales | Mì gói | … | … | … | | Giá vốn bình quân |

Những "bất ngờ" hay gặp — đáng ghi vào cột giải thích:
- Mặt hàng dịch vụ không làm đổi Available stock (ProductType = Service).
- BankPayment post rồi mà Cash statement không đổi → chưa tick Paid.
- Customer balance tăng theo **tổng có VAT**, còn Sales ghi Amount và VATAmount riêng. Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl (`SUM(DocumentInventory.Total) AS Amount` cho CustomerBalance).
- Giá vốn trên Profit on sales là bình quân, không phải giá của lần mua gần nhất.

---

## 3. Quy tắc an toàn trước khi tùy biến

### 3.1. Sao lưu trước mỗi buổi sửa

- **Dump infobase** (sao lưu cả cấu hình lẫn dữ liệu ra file `.dt`): Designer → Administration/Tools → **Dump infobase**; khôi phục bằng **Restore infobase** (Bài 1). Đặt tên file có ngày giờ, ví dụ `Nhom05_2026-10-07_truoc-them-Lo.dt`.
- `.cf` chỉ chứa cấu hình, **không có dữ liệu** — đừng dùng `.cf` để "sao lưu" 15 chứng từ của nhóm (Bài 1, thẻ Practice 1).
- **Restore ghi đè toàn bộ** infobase đích — chỉ restore vào infobase trống hoặc bản thử.
- File `.dt` cũng là một sản phẩm phải nộp của bài tập lớn — giữ bản cuối cùng sạch sẽ.

### 3.2. Đổi tên hiển thị bằng Synonym — không bao giờ đổi Name

Mỗi object, attribute, giá trị liệt kê trong Designer có hai tên:

- **Name** — tên "kỹ thuật" mà **code và query của Jet gọi tới**. Đổi Name là làm gãy mọi chỗ code đang gọi tên cũ.
- **Synonym** — tên **người dùng nhìn thấy** trên menu, form, tiêu đề cột. Đổi tự do.

Ví dụ thật trong Jet: attribute `ProductType` của danh mục Products được query ghi sổ của SupplierInvoice gọi đích danh:

Nguồn: Jet — cf/Documents/SupplierInvoice/Ext/ManagerModule.bsl
```bsl
	|		INNER JOIN Catalog.Products AS Products
	|		ON DocumentInventory.Product = Products.Ref
	|			AND (Products.ProductType = VALUE(Enum.ProductTypes.Inventory))
```

Dòng này nghĩa là: "chỉ dòng hàng nào có loại = Inventory mới được đưa vào kho". Nếu ai đổi Name `ProductType` thành `LoaiHang`, hoặc đổi Name giá trị liệt kê `Inventory`, thì query trên (và query tương tự trong SalesInvoice) không chạy được nữa — mọi hóa đơn mua và bán sẽ **không post được**. Vì câu query là một chuỗi chữ, lỗi thường chỉ hiện ra khi chạy tới đó (khi bấm Post), không hiện lúc lưu cấu hình (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).

Ví dụ thứ hai — attribute `Customer` của SalesInvoice có mặt ở ít nhất ba chỗ: query ghi sổ, form và mẫu in:

Nguồn: Jet — cf/Documents/SalesInvoice/Ext/ManagerModule.bsl
```bsl
	|	SalesInvoice.Customer AS Customer,
```

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
	PriceType = GetCustomerPriceType(Object.Customer);
```

Trong khi đó ô Customer trên form **không đặt Title riêng**, nên tiêu đề ô lấy từ Synonym (Bài 9: "tiêu đề = synonym của attribute gắn item, trừ khi item có Title"). Nghĩa là: đổi Synonym `Customer` thành "Khách hàng" → form hiện "Khách hàng", mà code vẫn chạy bình thường. Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form.xml (InputField `Customer` không có Title).

Synonym là **đa ngôn ngữ**: Jet khai báo bốn ngôn ngữ — English (`en`), Colombian (`es_CO`), Indonesian (`id`), Turkish (`tr`) (cf/Languages) — và mỗi Synonym có một dòng riêng cho từng ngôn ngữ (Synonym của `Customer` trên SalesInvoice hiện chỉ có dòng `en`). Sửa đúng dòng của ngôn ngữ giao diện đang chạy; sửa dòng khác thì nhãn trên màn hình không đổi.

Cũng **không đổi Name của form item** (ô trên form): code của Jet bật/tắt ô theo tên, ví dụ:

Nguồn: Jet — cf/Documents/CashVoucher/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
	If Object.Operation = PredefinedValue("Enum.CashVoucherOperations.Other") Then
		Items.Counterparty.Visible = False;
		Items.PaymentDetailsDocument.Visible = False;
```

Chọn đúng property khi Việt hóa (Bài 3, Bài 4):

| Muốn đổi | Sửa property |
|---|---|
| Tên mục menu / tên danh sách / nhãn ô | **Synonym** |
| Tên trên nút "Tạo" và tiêu đề form một phần tử | **Object presentation** (Bài 3: ghi vào Synonym thay vì Object presentation → tên danh sách cũng bị đổi) |
| Tiêu đề form danh sách | **List presentation** |
| Tên ô "nhóm cha" / "chủ sở hữu" | Synonym của standard attribute **Parent** / **Owner** (tab Data → Standard attributes) |

Nếu Designer hiện biểu tượng khóa không cho sửa một object thuộc SSL, đừng tự mở khóa — xem mục 6.

### 3.3. Mỗi lần một thay đổi, rồi cập nhật và thử ngay

1. Làm **một** thay đổi nhỏ (một attribute, một danh mục…).
2. **Update database configuration** (F7) — chưa F7 thì Enterprise mode chưa thấy gì mới (Bài 1).
3. Mở Enterprise mode (F5), **thử bằng một chứng từ thật**: tạo, ghi, post, rồi mở báo cáo liên quan xem số liệu cũ có còn đúng không.
4. Ổn → ghi lại vào nhật ký thay đổi của nhóm (ngày, ai sửa, sửa gì) → làm thay đổi tiếp theo.
5. Không ổn → sửa ngay khi còn nhớ mình vừa đổi gì; quá 2 lần không được → gọi tutor (mục 6), hoặc restore file `.dt` vừa dump.

Nếu form mở ra không thấy ô **mới thêm** (hoặc ô bị thiếu) dù đã F7, thử Enterprise mode → Menu → Window → **Restore window position** (Bài 1, thẻ Practice 1 Task 3) — form có thể đang dùng kích thước cũ đã lưu. Cách này không dành cho việc đổi nhãn (Synonym): nhãn chưa đổi thì kiểm tra lại dòng ngôn ngữ của Synonym và item có Title riêng không.

---

## 4. Hướng dẫn M2 từng bước

Mức **M2 = khai báo trực quan, không viết code** (đề, mục 2.3). Bảng dưới ghép hạng mục M2 của 9 đề với mục hướng dẫn:

| Hạng mục | Đề dùng | Mục |
|---|---|---|
| Thêm attribute vào danh mục / chứng từ | 2, 3, 4, 6, 7, 8, 9 | 4.1 |
| Thêm cột vào phần bảng (tabular section) | 1, 5, 9 | 4.2 |
| Tạo liệt kê và dùng nó | 2, 3, 4, 9 | 4.3 |
| Tạo danh mục (phân cấp, cấp dưới) | 1, 6, 8 | 4.4 |
| Tạo sổ thông tin nhập tay | 2, 4, 5, 7, 8 | 4.5 |
| Tạo chứng từ không ghi sổ | 3, 9 | 4.6 |
| Đặt ô mới lên form | tất cả | 4.7 |
| Đưa object vào phân hệ | tất cả | 4.8 |
| Cấp quyền trong role của Jet | tất cả | 4.9 |
| Báo cáo DCS trên dữ liệu có sẵn | 1, 2, 4, 6, 8, 9 | 4.10 |

Quy ước đặt tên gợi ý: Name viết tiếng Anh không dấu, viết hoa đầu từ (PascalCase) giống Jet (`Products`, `SalesInvoice`), Synonym tiếng Việt có dấu. [suy luận] Nếu nhiều nhóm sửa chung một cấu hình, nên thống nhất một tiền tố cho object mới của mỗi nhóm để khỏi trùng tên.

### 4.1. Thêm attribute vào danh mục hoặc chứng từ

Mẫu để bắt chước trong Jet: attribute `PriceType` của `Counterparties` (tham chiếu tới danh mục PriceTypes) và attribute `ProductType` của `Products` (tham chiếu tới liệt kê, có giá trị mặc định và bắt buộc nhập).

Ví dụ: Đề 6 — "Nhân viên kinh doanh" trên SalesInvoice; Đề 2 — "Loại kho" trên Warehouses; Đề 7 — "Hạn thanh toán" trên SalesInvoice.

1. Designer → cây cấu hình → mở object (ví dụ Documents → SalesInvoice).
2. Tab **Data** → danh sách **Attributes** → **Add** (tên nút có thể khác theo phiên bản — kiểm tra trên máy).
3. Điền **Name** (ví dụ `SalesRepresentative`), **Synonym** ("Nhân viên kinh doanh").
4. Chọn **Type**: kiểu tham chiếu `CatalogRef.<Danh mục>` nếu chọn từ danh sách; `Date` (Date format = Date) cho ngày; `Number` (Length, Precision, Nonnegative) cho số (Bài 2).
5. Nếu bắt buộc: **Fill checking** = Show error ("Display error"). Nếu cần giá trị mặc định: **Fill value** (Bài 3, thẻ Practice 3 Bài 4).
6. Nếu chỉ được chọn trong phạm vi một ô khác (ví dụ chỉ chọn tài khoản của đúng khách): **Choice parameter links**, Name `Filter.Owner`, data path tới ô kia (Bài 4).
7. F7 → đặt ô lên form (mục 4.7) → thử trong Enterprise mode.

Lưu ý: mọi chứng từ và danh mục nghiệp vụ của Jet đều có **form tự làm** (DocumentForm, ItemForm…), nên attribute mới **không tự hiện** trên form — phải kéo lên (Bài 10, thẻ Practice 10 Bài 1: "Thêm attribute vào metadata nhưng quên đặt field lên form → user không nhập được").

Jet còn có sẵn công cụ **Additional attributes** (thuộc tính bổ sung của SSL) thêm ô mới ngay trong Enterprise mode, không cần Designer — wiki *Initial Setup Guide* (mục 5, 7, 8) khuyên dùng nó để "adapt Jet… without development". Có thể nêu trong phân tích như một phương án; còn hạng mục M2 của đề yêu cầu làm trong Designer — hỏi tutor nếu muốn thay bằng công cụ này.

### 4.2. Thêm cột vào phần bảng

Mẫu: phần bảng `Inventory` của `SupplierInvoice` / `SalesInvoice` (cột Product, Quantity, Price, Amount, VATRate, VATAmount, Total) và của `InventoryWriteOff` (Product, Quantity).

Ví dụ: Đề 1 — cột "Lô hàng"; Đề 5 — cột "% chiết khấu"; Đề 9 — cột "Lý do".

1. Mở chứng từ → tab **Data** → **Tabular sections** → chọn `Inventory`.
2. Thêm attribute **vào trong** `Inventory` (không phải vào chứng từ) → Name, Synonym, Type (Bài 3, thẻ Practice 3 Bài 7: đặt nhầm ở chứng từ thì chỉ nhập được một giá trị cho cả phiếu).
3. Làm lại cho **từng** chứng từ đề yêu cầu (Đề 1 yêu cầu 4 chứng từ).
4. Nếu cột Lô chỉ được chọn lô của đúng mặt hàng trên dòng: Choice parameter links `Filter.Owner` trỏ tới cột Product của cùng dòng (Bài 4; tên hiển thị của đường dẫn có thể khác theo phiên bản — kiểm tra trên máy).
5. F7 → mở form, kéo cột mới vào bảng `Inventory` (mục 4.7).

Thêm cột vào phần bảng **không** làm đổi việc ghi sổ — query ghi sổ của Jet chỉ đọc các cột nó gọi tên. Đó là lý do hạng mục này là M2. Muốn cột mới đi vào sổ thì là M3 (mục 6).

### 4.3. Tạo liệt kê và dùng nó

Mẫu: liệt kê `ProductTypes` (Inventory, Service) dùng cho attribute `Products.ProductType` có **Fill value** = Inventory và **Fill checking** = Show error. Nguồn: Jet — cf/Catalogs/Products.xml.

Ví dụ: Đề 3 — Trạng thái đơn; Đề 4 — Xếp hạng A/B/C; Đề 2 — Loại kho; Đề 9 — Lý do chênh lệch.

1. Designer → **Enumerations** → **Add** → Name (ví dụ `DiscrepancyReasons`), Synonym.
2. Tab **Enum values**: thêm từng giá trị — Name tiếng Anh (`NaturalLoss`), Synonym tiếng Việt ("Hao hụt tự nhiên") (Bài 3, thẻ Practice 3 Bài 4).
3. Ở object dùng nó: thêm attribute kiểu `EnumRef.<Tên>`; đặt Fill value và Fill checking nếu cần.
4. F7; kéo ô lên form.

Liệt kê không cần cấp quyền trong role (trong Jet không role nào liệt kê Enum — đối chiếu cf/Roles/*/Ext/Rights.xml). Khi phân vân **liệt kê hay danh mục** (câu hỏi bắt buộc của Đề 4, Đề 8), các góc cần cân nhắc: ai được thêm giá trị mới (người dùng hay lập trình viên), code có rẽ nhánh theo từng giá trị không, giá trị có cần thêm thông tin đi kèm (mô tả, tỷ lệ, người phụ trách) không. Bài 3 và Bài 4: "dựa thuật toán vào predefined data hoặc Enumeration, không dựa vào code/description người dùng nhập".

### 4.4. Tạo danh mục — phẳng, phân cấp, cấp dưới

Mẫu trong Jet:
- Danh mục phẳng: `Warehouses` (Hierarchical = false).
- Danh mục phân cấp nhóm–phần tử: `Products`, `Counterparties` (Hierarchical = true, HierarchyType = Folders and items).
- Danh mục **cấp dưới** (có Owner): Jet **không có** danh mục nghiệp vụ nào có Owner (BankAccounts cũng để Owners trống) — làm theo bài thực hành `CounterpartyContracts` của Bài 4.

Nguồn: Jet — cf/Catalogs/Products.xml, Counterparties.xml, Warehouses.xml, BankAccounts.xml.

Ví dụ: Đề 1 — Lô hàng (cấp dưới của Products); Đề 6 — Khu vực (phân cấp Miền → Tỉnh); Đề 8 — Khoản mục chi phí (phân cấp).

1. Designer → **Catalogs** → **Add** → Name (ví dụ `Batches`), Synonym ("Lô hàng"); Object presentation ("Lô hàng"), List presentation (Bài 3).
2. Kiểm tra **Description length** đủ dài; **Code length** = 0 nếu không cần mã (Bài 4).
3. Attributes: ví dụ `ProductionDate`, `ExpiryDate` kiểu Date (Date format = Date).
4. **Phân cấp** (tab Hierarchy): bật Hierarchical, chọn **Hierarchy type**:
   - *Folder and item hierarchy* — nhóm chỉ để phân loại, chỉ phần tử mới được chọn vào chứng từ.
   - *Item hierarchy* — phần tử nằm dưới phần tử, **cả hai đều chọn được**.
   - Có thể giới hạn số cấp (Limit level count) (Bài 4).
   Câu hỏi cho nhóm: "Miền" có cần được chọn làm giá trị (ví dụ gán một nhân viên phụ trách cả miền) không? Câu trả lời quyết định chọn kiểu nào — ghi lý do vào bảng thiết kế đối tượng.
5. **Cấp dưới** (tab **Owners**): thêm `Catalog.Products`; đổi Synonym của standard attribute **Owner** thành "Mặt hàng". Nếu mã lô chỉ cần duy nhất trong một mặt hàng: **Code series** = Within subordination to owner (Bài 4, thẻ Practice 4 Bài 3).
6. Đưa vào phân hệ (4.8), cấp quyền (4.9), F7.
7. Form: với M2 có thể để platform tự sinh form (Bài 3: "Nếu không gán default form, platform tự sinh form động"). [suy luận] Form tự sinh sẽ không có các tiện ích SSL như thuộc tính bổ sung, file đính kèm mà form Warehouses có — chấp nhận được cho M2; muốn đủ như Jet thì làm theo checklist mục 6 của `references/jet/jet-extending.md` cùng tutor.

### 4.5. Tạo sổ thông tin để nhập tay

Mẫu: `Prices` — Periodicity = **Day**, Write mode = **Independent**, dimensions `PriceType`, `Product`, resource `Price`. Nguồn: Jet — cf/InformationRegisters/Prices.xml.

Ví dụ: Đề 2 — Định mức tồn kho; Đề 4 — Cam kết cung ứng; Đề 5 — Bậc chiết khấu; Đề 7 — Điều khoản thanh toán; Đề 8 — Ngân sách.

1. Designer → **Information registers** → **Add** (tên nút có thể khác theo phiên bản — kiểm tra trên máy) → Name (ví dụ `StockNorms`), Synonym.
2. **Write mode** = Independent (mặc định khi tạo) — nhập tay được, không cần chứng từ (Bài 12).
3. **Periodicity**: None (không lưu lịch sử) hoặc Day / Month… (lưu lịch sử thay đổi) (Bài 12).
4. **Dimensions** (phân tích theo): ví dụ `Warehouse`, `Product`. **Resources** (giá trị cần tra): ví dụ `MinimumQuantity`, `MaximumQuantity`.
5. Muốn từ form của kho mở nhanh danh sách định mức của kho đó: bật property **Master** của dimension tương ứng (Bài 12).
6. Đưa vào phân hệ, cấp quyền, F7. Người dùng nhập bằng cách mở sổ trong menu và thêm dòng.

Hai quy tắc của platform cần nhớ (Bài 12):
- **Không thể có hai dòng trùng toàn bộ dimensions** (cộng thêm Period nếu sổ định kỳ) — ghi dòng trùng sẽ báo lỗi. Vì vậy chọn cái gì làm dimension chính là chọn "mỗi tổ hợp nào chỉ có một giá trị".
- Chỉ sổ **định kỳ** mới tra được "giá trị hiện hành tại ngày X" (bảng ảo **SliceLast**). Sổ không định kỳ chỉ có giá trị hiện tại, mất lịch sử khi sửa.

Định kỳ hay không là câu hỏi phân tích bắt buộc của Đề 2 và Đề 8 — góc nhìn: doanh nghiệp có cần biết "tháng trước định mức là bao nhiêu" để giải thích một quyết định cũ không; giá trị thay đổi bao lâu một lần; báo cáo so sánh có phải dùng giá trị **tại ngày phát sinh** không. Quan sát cách Jet làm với `Prices`: giá đổi theo ngày, hóa đơn cũ vẫn giữ giá đã điền lúc lập.

### 4.6. Tạo chứng từ không ghi sổ

Mẫu trong Jet: `PricesSetupAuxiliary` là chứng từ **Posting = Deny** (không ghi sổ, chỉ có phần bảng `ProductPrices`). Về cấu trúc header + phần bảng hàng hóa, nhìn `InventoryWriteOff` (Warehouse + bảng `Inventory`). Nguồn: Jet — cf/Documents/PricesSetupAuxiliary.xml, cf/Documents/InventoryWriteOff.xml.

Ví dụ: Đề 3 — Đơn đặt hàng nhà cung cấp; Đề 9 — Phiếu kiểm kê.

1. Designer → **Documents** → **Add** → Name (ví dụ `InventoryCount`), Synonym ("Phiếu kiểm kê"), Object/List presentation.
2. Header attributes: ví dụ `Warehouse` (`CatalogRef.Warehouses`, bắt buộc), `CountedBy` (người kiểm), `Comment`.
3. Tab Data → **Tabular sections** → Add `Inventory` với các cột: `Product` (`CatalogRef.Products`), `BookQuantity`, `ActualQuantity`, `Difference` (Number, có Precision nếu hàng cân đo), `Reason` (`EnumRef.DiscrepancyReasons`). Đặt tên phần bảng là `Inventory` giống Jet cho dễ nhận ra.
4. Tab **Posting**: để **Posting** = Deny / không cho phép (tên giá trị có thể khác theo phiên bản — kiểm tra trên máy). Bài 16: khi tắt Posting, kiểm tra bắt buộc nhập chạy lúc **ghi** (write), và chứng từ không có lệnh Post/Undo posting.
5. Tab **Numbering**: giữ Autonumbering, Check uniqueness (Bài 4).
6. Forms: tạo **Document form** và **List form** bằng Form wizard (Bài 10, thẻ Practice 10 Bài 3), hoặc để platform tự sinh. Lưu ý: code M3 trên form (5.1–5.5) cần một Document form tạo rõ ràng; nếu đang dùng form tự sinh thì tạo form bằng Form wizard trước.
7. Đưa vào phân hệ con chứa chứng từ của nhóm (4.8), cấp quyền (4.9), F7.

**Đừng copy chứng từ Jet có ghi sổ** (InventoryWriteOff, SupplierInvoice…) để làm chứng từ không ghi sổ: bản copy mang theo object module gọi `Documents.<TênCũ>.InitializeDocumentData` và đăng ký register records — chính là lỗi "copy document mẫu nhưng post ra số liệu của document mẫu" ở mục 8 của `references/jet/jet-extending.md`. Tạo mới sạch hơn cho nhóm 2.

### 4.7. Đặt ô mới lên form

1. Mở object → tab **Forms** → double-click form (ví dụ `DocumentForm`) để mở Form editor (tên tab có thể khác theo phiên bản — kiểm tra trên máy).
2. Ở cửa sổ attributes của form, mở cây **Object**, tìm attribute mới.
3. **Kéo** attribute vào cây form items, thả vào đúng nhóm (Bài 10, thẻ Practice 10 Bài 1: "trên document form kéo attribute từ cây Object vào nhóm header"). Form SalesInvoice có các nhóm `GroupHeader`, `GroupLeft`, `GroupRight`, `GroupInfo`; form InventoryWriteOff có `GroupHeader`, `GroupLeft`, `GroupRight`, `GroupInfo`. Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form.xml, cf/Documents/InventoryWriteOff/Forms/DocumentForm/Ext/Form.xml.
4. Cột mới của phần bảng: mở `Object` → `Inventory` → kéo cột vào bảng `Inventory` trên form.
5. Muốn ô chỉ xem không sửa: property **ReadOnly** của item (Bài 9).
6. Muốn sắp hai ô nằm ngang: thêm Group – Regular group, Group = horizontal, kéo hai ô vào (Bài 9).
7. F7, mở Enterprise mode kiểm tra.

Không xóa hay đổi Name các item sẵn có của form Jet (mục 3.2), và không xóa nhóm `GroupAdditionalAttributes` (nơi SSL đặt thuộc tính bổ sung — mục 10.8 của `references/jet/jet-overview.md`).

### 4.8. Đưa object vào phân hệ

Mỗi phân hệ nghiệp vụ của Jet có phân hệ con. Đặt object mới theo cùng chỗ Jet đặt object cùng loại. Nguồn: Jet — cf/Subsystems/<Tên>.xml và cf/Subsystems/<Tên>/Subsystems/*.xml.

| Phân hệ | Danh mục mới vào | Chứng từ mới vào | Báo cáo, sổ mới vào |
|---|---|---|---|
| Warehouses | `Warehouses.Catalogs` | `Warehouses.Warehouse` | `Warehouses` (cha) |
| Purchases | `Purchases.Catalogs` | `Purchases.Purchases` | `Purchases` (cha) |
| Sales | `Sales.Catalogs` | `Sales.Sales` | `Sales` (cha); sổ giá nằm ở `Sales.Pricing` |
| CashManagement | `CashManagement.Catalogs` | `CashManagement.Bank` hoặc `CashManagement.CashInHand` | `CashManagement` (cha) |

Cách làm: mở object → tab **Subsystems** → tick phân hệ; hoặc mở phân hệ → tab **Content** → tick object (Bài 3, Bài 9). Một object có thể nằm trong nhiều phân hệ.

### 4.9. Cấp quyền trong role của Jet

Mỗi phân hệ nghiệp vụ có một role riêng: **`UseWarehouses`**, **`UsePurchases`**, **`UseSales`**, **`UseCashManagement`** (và `UseCompany`). Các role này có **"Set rights for new objects" = tắt**, nên object mới **không tự có quyền** — quên bước này là người dùng thường gặp "Access violation!". Role `FullAccess` thì bật, nên object mới tự nhận **đủ quyền kể cả xóa trực tiếp** — phải tắt `InteractiveDelete`. Nguồn: Jet — cf/Roles/UseWarehouses/Ext/Rights.xml (`<setForNewObjects>false</setForNewObjects>`), cf/Roles/FullAccess/Ext/Rights.xml (`<setForNewObjects>true</setForNewObjects>`).

Mẫu quyền lấy từ Jet:

| Object mới | Quyền cần tick trong role nhóm | Mẫu Jet |
|---|---|---|
| Danh mục | Read, Insert, Update, View, InteractiveInsert, Edit, InteractiveSetDeletionMark, InteractiveClearDeletionMark, InputByString | `Catalog.Warehouses` trong `UseWarehouses` |
| Chứng từ không ghi sổ | như danh mục [suy luận: bỏ các quyền Posting/UndoPosting của mẫu chứng từ có ghi sổ] | `Document.InventoryTransfer` trong `UseWarehouses` (bỏ phần posting) |
| Sổ thông tin nhập tay | Read, Update, View, Edit | `InformationRegister.Prices` trong `UseSales` (có thêm TotalsControl) |
| Báo cáo | Use, View | `Report.AvailableStock` trong `UseWarehouses` |
| Phân hệ con mới (nếu tạo) | View | `Subsystem.Warehouses.Subsystem.Catalogs` |
| Liệt kê | không cần | — |

Thao tác (Bài 20): Designer → **Roles** → mở role nhóm → tìm object trong cây → tick quyền. Mẹo của bài: tick "từ dưới lên" — tick InputByString thì Read và View tự bật. Sau đó mở `FullAccess` → object mới → **bỏ tick InteractiveDelete** (danh mục: bỏ thêm các quyền xóa/đánh dấu xóa predefined).

Hai lỗi đã gặp trong cấu trúc quyền của Jet:
- Báo cáo đọc sổ thì role phải có **Read** trên sổ đó. Ví dụ `UseCashManagement` **không có** quyền trên `AccumulationRegister.CustomerBalance` (chỉ có `CashBalance`) — báo cáo tuổi nợ của Đề 7 chạy dưới user chỉ có role này sẽ bị từ chối. Nguồn: Jet — cf/Roles/UseCashManagement/Ext/Rights.xml.
- Form đọc sổ thông tin (ví dụ code mục 5.4) cũng cần Read trên sổ đó trong role.

Thử quyền: đăng nhập bằng một user **không** có FullAccess. Trong Jet, user được tạo ở Enterprise mode (Administration → Users, theo wiki mục 12) và nhận role qua nhóm truy cập của SSL; Jet không cung cấp sẵn hồ sơ quyền nào (`AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles` để trống). Nếu không tự lập được hồ sơ quyền để thử, nhờ tutor (mục 6).

### 4.10. Báo cáo DCS trên dữ liệu có sẵn

Mẫu: báo cáo `Purchases` — một data set Query đọc `AccumulationRegister.Purchases.Turnovers`, resources `Sum(Amount)`, `Sum(Quantity)`… Nguồn: Jet — cf/Reports/Purchases/Templates/MainDataCompositionSchema/Ext/Template.xml. Mọi báo cáo của Jet đều là DCS, không có module, dùng form chung.

Ví dụ: Đề 4 — giá mua bình quân NCC × mặt hàng; Đề 6 — doanh số theo nhân viên/khu vực đọc từ SalesInvoice; Đề 8 — chi phí thực tế theo khoản mục đọc từ CashVoucher/BankPayment; Đề 1 — lô sắp hết hạn từ danh mục Lô.

Các bước (Bài 18):
1. Designer → **Reports** → **Add** → Name, Synonym; đưa vào phân hệ cha của nhóm.
2. Field **Main data composition schema** → nút kính lúp → chọn kiểu Data composition schema → Finish.
3. Tab **Data sets** → thêm data set **Query** → mở Query wizard, chọn bảng:
   - số liệu đã ghi sổ: bảng ảo của sổ (`Purchases.Turnovers`, `InventoryInWarehouses.Balance`);
   - số liệu trên chứng từ: `Document.SalesInvoice.Inventory` (dòng hàng) nối với header qua `Ref`;
   - số liệu danh mục: `Catalog.Batches`;
   - giá trị hiện hành của sổ thông tin: `InformationRegister.<Tên>.SliceLast`.
   Không cần TOTALS trong query — DCS tự tính tổng.
4. Tab **Resources**: thêm các cột số (nút ">>"), biểu thức `Sum(...)`. Chỉ tiêu tỷ lệ như giá bình quân viết ở cột Expression của resource, ví dụ `Sum(Amount) / Sum(Quantity)` — chia cho 0 khi Quantity = 0, nên bọc bằng biểu thức CASE (Bài 18 nhắc dùng CASE trong expression của DCS).
5. Tab **Settings** → **Settings wizard**: chọn kiểu List hoặc Table, chọn field, grouping (ví dụ NCC → mặt hàng).
6. Đưa Period / bộ lọc ra cho người dùng: tab Parameters / Filter → "Include in custom settings", Edit mode "Quick access" (Bài 18).
7. Conditional appearance để tô màu dòng cần chú ý (ví dụ tồn dưới định mức) (Bài 18).
8. Cấp quyền Use + View cho báo cáo và Read cho bảng nguồn (4.9), F7, chạy thử.

Báo cáo đọc từ chứng từ khác báo cáo đọc từ sổ thế nào là câu hỏi bắt buộc của Đề 6 — gợi ý quan sát: chứng từ chưa post hoặc đã đánh dấu xóa có lọt vào báo cáo không; muốn số dư "còn lại" thì đọc từ chứng từ có làm được không.

Jet còn đăng ký mỗi báo cáo trong `ReportsOptionsOverridable` để có mô tả trong danh sách báo cáo (mục 7.2 của `references/jet/jet-extending.md`) — đó là module SSL, nhờ tutor nếu muốn thêm.

---

## 5. Code đơn giản kèm giải thích (M3 nhẹ)

Với nhóm 2, phần này **được đưa code hoàn chỉnh** để dán vào, kèm giải thích từng dòng bằng lời nghiệp vụ; tutor vẫn duyệt trước khi nộp. Mọi đoạn dưới đây là **code minh họa — chạy thử để kiểm chứng**: tên object mới (`DiscountTiers`, `InventoryCount`, `PaymentTerms`…) là tên giả định, đổi cho khớp tên nhóm đã tạo ở mục 4. Code viết theo khuôn của Jet: handler phía client gom dữ liệu rồi gọi một hàm phía server (`&AtServerNoContext`), đặt trong đúng `#Region`.

### 5.0. Dán code vào đâu, mở thế nào

| Loại code | Đặt ở | Mở trong Designer |
|---|---|---|
| Phản ứng khi người dùng đổi một ô, bấm nút | **Form module** của form | Mở form (4.7) → phần **Form module** của Form editor (Bài 9) |
| Kiểm tra trước khi ghi, áp dụng cả khi ghi từ code | **Object module** của chứng từ | Context menu của chứng từ → mở object module (tên lệnh có thể khác theo phiên bản — kiểm tra trên máy) |

Code M3 trên form (5.1–5.5) cần một Document form tạo rõ ràng; nếu đang dùng form tự sinh (4.6 bước 6) thì tạo form bằng Form wizard trước — form tự sinh không có form module để dán code.

Gắn handler cho sự kiện của **form** (Bài 16): chọn ô trên form → **Properties palette** → mục sự kiện (ví dụ OnChange) → nút tạo handler; platform tạo procedure tên `<TênÔ><TênSựKiện>`. Handler của **object module** thì chỉ cần đúng tên chuẩn (`FillCheckProcessing`, `BeforeWrite`).

Quan trọng với form của Jet: nhiều sự kiện **đã có handler** (ví dụ `CustomerOnChange`, `InventoryQuantityOnChange` của SalesInvoice). Khi đó **thêm một dòng gọi vào trong procedure có sẵn**, đừng tạo procedure thứ hai — ô sự kiện trên Properties palette chỉ trỏ tới một procedure (Bài 16). Nguồn danh sách handler: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl.

Đánh dấu chỗ nhóm sửa bằng một dòng chú thích, ví dụ `// Nhóm 05 — Đề 5: chiết khấu`, để tutor và nhóm khác tìm được.

### 5.1. Tự điền giá trị khi người dùng nhập (Đề 5 — tự áp % chiết khấu)

Khuôn của Jet: khi đổi mặt hàng trên dòng, form gom dữ liệu vào một `Structure` rồi gọi server lấy giá:

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure InventoryQuantityOnChange(Item)
	
	InventoryTabularSectionClientServer.CalculateAmount(Items.Inventory.CurrentData);
	
EndProcedure
```

Giả định nhóm đã có: sổ thông tin **không định kỳ** `DiscountTiers` (dimensions `PriceType`, `Product`, `MinQuantity`; resource `DiscountPercent`) và cột `DiscountPercent` trong `SalesInvoice.Inventory` (mục 4.2, 4.5).

Code minh họa — chạy thử để kiểm chứng (form module của SalesInvoice):
```bsl
// Trong procedure CÓ SẴN InventoryQuantityOnChange, thêm dòng thứ hai:
&AtClient
Procedure InventoryQuantityOnChange(Item)
	
	InventoryTabularSectionClientServer.CalculateAmount(Items.Inventory.CurrentData);
	FillDiscountPercent(); // Nhóm 05 — Đề 5
	
EndProcedure

// Thêm mới, đặt trong #Region Private:
&AtClient
Procedure FillDiscountPercent()
	
	CurrentData = Items.Inventory.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataStructure = New Structure;
	DataStructure.Insert("PriceType", Object.PriceType);
	DataStructure.Insert("Product", CurrentData.Product);
	DataStructure.Insert("Quantity", CurrentData.Quantity);
	
	CurrentData.DiscountPercent = GetDiscountPercent(DataStructure);
	
EndProcedure

&AtServerNoContext
Function GetDiscountPercent(DataStructure)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	DiscountTiers.DiscountPercent AS DiscountPercent
	|FROM
	|	InformationRegister.DiscountTiers AS DiscountTiers
	|WHERE
	|	DiscountTiers.PriceType = &PriceType
	|	AND DiscountTiers.Product = &Product
	|	AND DiscountTiers.MinQuantity <= &Quantity
	|
	|ORDER BY
	|	DiscountTiers.MinQuantity DESC";
	
	Query.SetParameter("PriceType", DataStructure.PriceType);
	Query.SetParameter("Product", DataStructure.Product);
	Query.SetParameter("Quantity", DataStructure.Quantity);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DiscountPercent;
	EndIf;
	
	Return 0;
	
EndFunction
```

Dòng này nghĩa là:
- `FillDiscountPercent();` — "mỗi khi người bán sửa số lượng, tra lại mức chiết khấu".
- `CurrentData = Items.Inventory.CurrentData` — "dòng hàng người dùng đang đứng". Nếu không đứng ở dòng nào (`Undefined`) thì thôi.
- `DataStructure.Insert(...)` — "ghi ra một tờ giấy ba thông tin: loại giá của hóa đơn, mặt hàng, số lượng" để gửi lên máy chủ một lần (Jet làm y hệt trong `InventoryProductOnChange`).
- `&AtServerNoContext Function GetDiscountPercent` — "nhờ máy chủ tra bảng bậc chiết khấu"; dữ liệu sổ chỉ đọc được trên máy chủ (Bài 12).
- Câu query: "trong các bậc của đúng loại giá và mặt hàng này, lấy những bậc có số lượng tối thiểu **không vượt** số lượng đang mua, xếp bậc cao nhất lên đầu, lấy **1** dòng" — tức là bậc cao nhất mà khách đạt được.
- `Return 0` — "không đạt bậc nào thì chiết khấu 0%".

Code này chỉ **điền cột %**; nó không đổi Amount và không đổi số liệu ghi vào sổ Sales. Có trừ chiết khấu vào Amount hay không sẽ làm đổi doanh thu, công nợ khách — đó là thay đổi ghi sổ, bàn với tutor (mục 6). Muốn tra lại cả khi đổi mặt hàng, thêm cùng dòng `FillDiscountPercent();` vào cuối `InventoryProductOnChange`.

### 5.2. Tính một cột từ các cột khác (Đề 9 — Chênh lệch = Thực tế − Sổ sách)

Khuôn của Jet — InventoryIncrease tính Amount trên client mỗi khi đổi số lượng hoặc giá:

Nguồn: Jet — cf/Documents/InventoryIncrease/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure CalculateAmount()
	
	TabSectionRow = Items.Inventory.CurrentData;
	
	If TabSectionRow <> Undefined Then
		TabSectionRow.Amount = TabSectionRow.Quantity * TabSectionRow.Price;
	EndIf;
	
EndProcedure
```

Code minh họa — chạy thử để kiểm chứng (form module của `InventoryCount`; tạo handler OnChange cho hai cột `InventoryActualQuantity` và `InventoryBookQuantity` qua Properties palette):
```bsl
#Region FormTableItemsEventHandlersInventory

&AtClient
Procedure InventoryActualQuantityOnChange(Item)
	
	CalculateDifference();
	
EndProcedure

&AtClient
Procedure InventoryBookQuantityOnChange(Item)
	
	CalculateDifference();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CalculateDifference()
	
	TabSectionRow = Items.Inventory.CurrentData;
	
	If TabSectionRow <> Undefined Then
		TabSectionRow.Difference = TabSectionRow.ActualQuantity - TabSectionRow.BookQuantity;
	EndIf;
	
EndProcedure

#EndRegion
```

Dòng này nghĩa là:
- Hai handler `...OnChange` — "khi người kiểm sửa số thực tế, hoặc khi số sổ sách thay đổi, tính lại chênh lệch". Cả hai gọi chung một thủ tục để công thức chỉ viết một lần (Bài 4, thẻ Practice 4 Bài 6).
- `Difference = ActualQuantity - BookQuantity` — "chênh lệch dương là **thừa**, âm là **thiếu**".
- Đặt cột `Difference` trên form là **ReadOnly** (4.7) để không ai sửa tay rồi bị ghi đè.

Lưu ý: code form chỉ chạy khi người dùng sửa trên form. Nếu sau này dòng được điền bằng code (5.5), phải gọi tính lại cho từng dòng — 5.5 đã làm việc đó.

### 5.3. Hiện cảnh báo, chặn ghi khi dữ liệu sai (Đề 3 — ngày giao dự kiến)

Khuôn của Jet — chặn bằng `Common.MessageToUser(..., Cancel)` (thủ tục SSL) trong kiểm tra trước khi ghi:

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
	If Object.Inventory.Total("Total") < Object.AdvanceClearing.Total("AmountCur") Then
		MessageText = NStr("en = 'The invoice amount is less than the clearing amount.'");
		Common.MessageToUser(MessageText,,,, Cancel);
	EndIf;
```

Và Jet kiểm tra ở object module, ví dụ BankPayment bỏ yêu cầu nhập Counterparty khi Operation = Other:

Nguồn: Jet — cf/Documents/BankPayment/Ext/ObjectModule.bsl
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Operation = Enums.BankPaymentOperations.Other Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Counterparty"));
	EndIf;
	
EndProcedure
```

Code minh họa — chạy thử để kiểm chứng. Giả định chứng từ không ghi sổ `SupplierOrder` có attribute `ExpectedDeliveryDate`. Đặt trong **object module** của `SupplierOrder`, `#Region EventHandlers`, bên trong `#If Server Or ExternalConnection Then … #EndIf` giống object module của Jet:
```bsl
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(ExpectedDeliveryDate) And ExpectedDeliveryDate < BegOfDay(Date) Then
		MessageText = NStr("en = 'Ngày giao dự kiến không được sớm hơn ngày đặt hàng.'");
		Common.MessageToUser(MessageText, ThisObject, "ExpectedDeliveryDate", , Cancel);
	EndIf;
	
EndProcedure
```

Dòng này nghĩa là:
- `FillCheckProcessing` — "bước soát lỗi trước khi lưu phiếu". Chứng từ không ghi sổ thì bước này chạy khi bấm **Write** (Bài 16). Đây cũng là ví dụ của Bài 12: "Sales order có Shipment date không được sớm hơn ngày document".
- `ValueIsFilled(ExpectedDeliveryDate)` — "chỉ soát khi đã nhập ngày giao" (chưa nhập thì để tùy chọn bắt buộc nhập lo).
- `< BegOfDay(Date)` — "ngày giao trước ngày đặt hàng là vô lý".
- `Common.MessageToUser(…, ThisObject, "ExpectedDeliveryDate", , Cancel)` — "hiện thông báo cạnh ô Ngày giao và **không cho lưu**" (`Cancel` thành True). Dùng Cancel thay vì dừng hẳn để nếu có nhiều lỗi, người dùng thấy hết một lần (Bài 12).

Chỉ muốn **nhắc** mà vẫn cho lưu: bỏ tham số `Cancel` ở cuối. Muốn nhắc ngay lúc chọn ngày (trước khi lưu): tạo handler OnChange của ô trên form và gọi `ShowMessageBox(, "…")` — Jet dùng đúng lệnh này khi chưa chọn khách mà bấm "Select advances". Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl (`ShowMessageBox(, NStr("en = 'Please specify the customer.'"));`). [suy luận] Chuỗi tiếng Việt đặt trong `NStr("en = '…'")` vẫn hiển thị khi giao diện chạy tiếng Anh — kiểm tra trên máy.

### 5.4. Đọc giá trị hiện hành từ sổ thông tin bằng SliceLast (Đề 7 — hạn thanh toán)

Khuôn của Jet — tra giá bán bằng `SliceLast` tại ngày chứng từ:

Nguồn: Jet — cf/CommonModules/PriceManagementServerCall/Ext/Module.bsl
```bsl
	"SELECT ALLOWED
	|	PricesSliceLast.Price * &DocumentRepetition / &DocumentRate AS Price
	|FROM
	|	InformationRegister.Prices.SliceLast(
	|			&PriceDate,
	|			PriceType = &PriceType
	|				AND Product = &Product) AS PricesSliceLast";
```

Và khuôn đọc thuộc tính của khách khi chọn khách:

Nguồn: Jet — cf/Documents/SalesInvoice/Forms/DocumentForm/Ext/Form/Module.bsl
```bsl
&AtClient
Procedure CustomerOnChange(Item)
	
	PriceType = GetCustomerPriceType(Object.Customer);
	If ValueIsFilled(PriceType) Then
		Object.PriceType = PriceType;
		PriceManagementClient.RefillTabularSectionPricesByPriceType(ThisObject);
	EndIf;
	
EndProcedure
```

Giả định: sổ thông tin **định kỳ theo ngày** `PaymentTerms` (dimension `Counterparty`; resources `PaymentDays`, `CreditLimit`) và attribute `DueDate` trên SalesInvoice.

Code minh họa — chạy thử để kiểm chứng (form module của SalesInvoice):
```bsl
// Trong procedure CÓ SẴN CustomerOnChange, thêm một dòng cuối:
	FillDueDate(); // Nhóm 07 — Đề 7

// Thêm mới, đặt trong #Region Private:
&AtClient
Procedure FillDueDate()
	
	PaymentDays = GetPaymentDays(Object.Customer, Object.Date);
	Object.DueDate = BegOfDay(Object.Date) + PaymentDays * 86400;
	
EndProcedure

&AtServerNoContext
Function GetPaymentDays(Customer, DocumentDate)
	
	If Not ValueIsFilled(Customer) Then
		Return 0;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	PaymentTermsSliceLast.PaymentDays AS PaymentDays
	|FROM
	|	InformationRegister.PaymentTerms.SliceLast(
	|			&DocumentDate,
	|			Counterparty = &Customer) AS PaymentTermsSliceLast";
	
	Query.SetParameter("DocumentDate", DocumentDate);
	Query.SetParameter("Customer", Customer);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.PaymentDays;
	EndIf;
	
	Return 0;
	
EndFunction
```

Dòng này nghĩa là:
- `FillDueDate();` trong `CustomerOnChange` — "chọn khách xong thì, cùng lúc với việc Jet điền loại giá, điền luôn hạn thanh toán".
- `SliceLast(&DocumentDate, Counterparty = &Customer)` — "lấy điều khoản thanh toán **đang hiệu lực vào ngày lập hóa đơn** của đúng khách này". Nếu tháng 3 khách được nợ 30 ngày, tháng 5 đổi thành 45 ngày, hóa đơn ngày 10/4 vẫn lấy 30 (Bài 12, ví dụ SliceLast).
- `Return 0` — "khách chưa có điều khoản → coi như trả ngay".
- `BegOfDay(Object.Date) + PaymentDays * 86400` — "ngày hóa đơn cộng số ngày được nợ"; trong 1C, cộng một số vào ngày là cộng **giây**, nên một ngày = 86400 giây (Bài 5–6: "Date + Number cộng giây").

Lưu ý:
- Đổi **ngày** hóa đơn thì hạn không tự tính lại — muốn vậy, tạo handler OnChange của ô Date và gọi `FillDueDate();`.
- Role của người bán (`UseSales`) phải có **Read** trên sổ `PaymentTerms` (mục 4.9), vì hàm này chạy với quyền của người dùng.

### 5.5. Điền phần bảng từ số dư của sổ (Đề 9 — điền SL sổ sách)

Khuôn của Jet — đọc bảng ảo `Balance` của sổ:

Nguồn: Jet — cf/AccumulationRegisters/InventoryInWarehouses/Ext/ManagerModule.bsl
```bsl
		|		INNER JOIN AccumulationRegister.InventoryInWarehouses.Balance(, ) AS InventoryInWarehousesBalance
```

Và khuôn nạp kết quả query vào một bảng trên form bằng `Load(… .Unload())`:

Nguồn: Jet — cf/CommonForms/SelectAdvances/Ext/Form/Module.bsl
```bsl
	QueryResult = Query.Execute();
	
	AdvanceBalance.Load(QueryResult.Unload());
```

Code minh họa — chạy thử để kiểm chứng. Trên form `InventoryCount`: tạo form command `FillBookQuantity` (Bài 9, Form commands), kéo lên thanh lệnh của bảng `Inventory` thành nút "Điền SL sổ sách"; code trong form module:
```bsl
#Region FormCommandsEventHandlers

&AtClient
Procedure FillBookQuantity(Command)
	
	If Not ValueIsFilled(Object.Warehouse) Then
		ShowMessageBox(, NStr("en = 'Hãy chọn kho trước.'"));
		Return;
	EndIf;
	
	FillBookQuantityAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillBookQuantityAtServer()
	
	// Thời điểm lấy số sổ sách — câu hỏi phân tích bắt buộc số 3 của Đề 9.
	// Phương án A (đang dùng): cuối ngày của phiếu kiểm kê.
	// Phương án B: để trống (Undefined) = số dư hiện tại.
	// Nhóm tự chọn và lập luận trong báo cáo.
	BalanceDate = EndOfDay(Object.Date);
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	InventoryBalance.Product AS Product,
	|	InventoryBalance.QuantityBalance AS BookQuantity
	|FROM
	|	AccumulationRegister.InventoryInWarehouses.Balance(
	|			&BalanceDate,
	|			Warehouse = &Warehouse) AS InventoryBalance
	|
	|ORDER BY
	|	Product";
	
	Query.SetParameter("BalanceDate", BalanceDate);
	Query.SetParameter("Warehouse", Object.Warehouse);
	
	Object.Inventory.Load(Query.Execute().Unload());
	
	For Each TabSectionRow In Object.Inventory Do
		TabSectionRow.ActualQuantity = TabSectionRow.BookQuantity;
		TabSectionRow.Difference = 0;
	EndDo;
	
	Modified = True;
	
EndProcedure

#EndRegion
```

Dòng này nghĩa là:
- `If Not ValueIsFilled(Object.Warehouse)` — "chưa chọn kho thì không biết kiểm kho nào — nhắc và dừng".
- `FillBookQuantityAtServer()` là `&AtServer` (không phải `NoContext`) vì nó phải **sửa chính phiếu đang mở** (`Object`) và đọc sổ (Bài 7, Bài 10).
- `InventoryInWarehouses.Balance(&BalanceDate, Warehouse = &Warehouse)` — "sổ tồn kho cho biết: tại thời điểm đó, kho này còn bao nhiêu từng mặt hàng". Mặt hàng tồn bằng 0 thường không có dòng (ngoài giáo trình — hãy kiểm tra lại trong Syntax assistant).
- `QuantityBalance AS BookQuantity` — đổi tên cột cho **trùng tên cột** của phần bảng, vì `Load` ghép theo tên (Bài 10, thẻ Practice 10 Bài 6).
- `Object.Inventory.Load(...)` — "xóa các dòng cũ, chép danh sách tồn vào phiếu".
- Vòng `For Each` — "điền sẵn số thực tế bằng số sổ sách, chênh lệch 0; người kiểm chỉ sửa dòng nào đếm ra khác". Đây là một lựa chọn trình bày; nhóm có thể để trống số thực tế nếu muốn buộc người kiểm nhập từng dòng.
- `Modified = True` — "đánh dấu phiếu đã thay đổi, nhắc lưu khi đóng".
- Thời điểm `BalanceDate` cố ý để thành chú thích lựa chọn: chọn thời điểm nào, và có cần khóa nhập xuất trong lúc kiểm không, là câu hỏi phân tích được chấm điểm. Liên hệ khái niệm PointInTime / Boundary của Bài 11 nếu nhóm muốn số dư "đúng tại thời điểm phiếu".
- Role nhóm (`UseWarehouses`) đã có Read trên `InventoryInWarehouses` nên không cần cấp thêm. Nguồn: Jet — cf/Roles/UseWarehouses/Ext/Rights.xml.

Bước tự động tạo `InventoryIncrease` / `InventoryWriteOff` từ phiếu kiểm kê (phần còn lại của hạng mục M3 Đề 9) là tạo **chứng từ có ghi sổ** bằng code — làm cùng tutor (mục 6).

---

## 6. Khi nào cần gọi tutor

Gọi tutor **trước khi làm** (không phải sau khi hỏng) khi:

1. **Chạm vào việc ghi sổ**: sửa object module / manager module của chứng từ có posting (`Posting`, `InitializeDocumentData`), sửa `PostingManagement`, thêm sổ tích lũy mới, thêm sổ vào register records của chứng từ. Câu query ghi sổ của Jet là một batch đánh số `QueryResult[n]` — thêm bớt một query là lệch hết (mục 10.1 của `references/jet/jet-overview.md`).
2. **Thêm chiều (dimension) vào sổ dùng chung**: `InventoryInWarehouses` và `InventoryCost` được 5 chứng từ ghi (SupplierInvoice, SalesInvoice thuộc nhóm Mua và Bán; 3 chứng từ kho), `Sales` và `CustomerBalance` dính SalesInvoice và chứng từ thu tiền. Thêm chiều Lô (Đề 1) hay Nhân viên/Khu vực (Đề 6) là phải sửa ghi sổ của mọi chứng từ đó và ảnh hưởng nhóm khác — phải thống nhất với tutor và các nhóm liên quan.
3. **Muốn đổi số liệu đi vào sổ** dù chỉ gián tiếp: trừ chiết khấu vào Amount (Đề 5), chặn bán khi vượt hạn mức (Đề 7, "mã ghi sổ"), tự tạo chứng từ có ghi sổ từ phiếu kiểm kê (Đề 9) hoặc từ báo cáo (Đề 2).
4. **Lỗi lặp lại sau 2 lần thử**: cùng một thông báo lỗi khi F7, khi mở form hoặc khi post. Mang theo: ảnh chụp thông báo, bước vừa làm, file `.dt` gần nhất.
5. **Lỗi quyền không tự sửa được**: "Access violation!" dù đã tick quyền theo 4.9; user thử không thấy phân hệ; không biết lập hồ sơ quyền (access group) của SSL để thử user thường.
6. **Bất cứ thứ gì thuộc SSL**: module có tên kết thúc `Overridable`, defined types, event subscriptions, object có biểu tượng khóa, `Configuration - Support - Support options` (Bài 21). SSL là thư viện chung — sửa sai ở đây có thể hỏng chức năng của cả cấu hình.
7. **Đổi Name** của bất cứ thứ gì đã có trong Jet, xóa attribute / object của Jet, hoặc đổi kiểu dữ liệu của attribute đã có dữ liệu.
8. **Muốn dùng Extension** (phần mở rộng cấu hình) thay vì sửa trực tiếp — có giới hạn riêng (safe mode, xóa extension là mất dữ liệu attribute đã thêm) (mục 4.3 của `references/jet/jet-extending.md`).
9. **Restore `.dt`** khi không chắc infobase nào là đích — restore ghi đè toàn bộ.

Không cần gọi tutor cho: đổi Synonym / Object presentation, thêm attribute hay cột mới, tạo danh mục / liệt kê / sổ thông tin / chứng từ không ghi sổ mới, kéo ô lên form, đưa object vào phân hệ, tick quyền cho object **mới** của nhóm, làm báo cáo DCS chỉ đọc dữ liệu — miễn là đã dump `.dt` trước và thử bằng một chứng từ sau mỗi thay đổi (mục 3).
