# Đề bài tập lớn ERP — Base 1C:Jet (tài liệu gốc của giảng viên)

> Nguồn: file "BTL ERP – Base 1C JET" do giảng viên Phạm Viết Quý soạn. Đây là đề chính thức; khi trả lời về yêu cầu, mức M1/M2/M3, thang điểm, bám đúng văn bản này.

# **Bản đồ cấu hình 1C:Jet**

Phần này mô tả những gì 1C:Jet đang có, đọc trực tiếp từ cấu hình. Sinh
viên cần nắm phần này trước khi chọn đề, vì mọi đề tài đều bắt đầu bằng
câu hỏi: **Jet gốc đã làm được gì, và còn thiếu gì cho doanh nghiệp của
nhóm?**

## **1.1. Các phân hệ nghiệp vụ**

+---------------+--------------------------+---------------------------+
| **Phân hệ**   | **Chứng từ và danh mục** | **Sổ và báo cáo**         |
+===============+==========================+===========================+
| **Purchases** | SupplierInvoice;         | Sổ Purchases,             |
|               | Counterparties,          | SupplierBalance; báo cáo  |
| Mua hàng      | Products, Units          | Purchases,                |
|               |                          | SupplierBalance           |
+---------------+--------------------------+---------------------------+
| **Sales**     | SalesInvoice;            | Sổ Sales,                 |
|               | Counterparties,          | CustomerBalance; báo cáo  |
| Bán hàng      | Products, Units; nhóm    | Sales, CustomerBalance,   |
|               | Pricing: PriceTypes, sổ  | ProfitOnSales, PriceList  |
|               | thông tin Prices         |                           |
+---------------+--------------------------+---------------------------+
| *             | InventoryIncrease,       | Sổ InventoryInWarehouses, |
| *Warehouses** | InventoryTransfer,       | InventoryCost; báo cáo    |
|               | InventoryWriteOff;       | AvailableStock,           |
| Kho           | Warehouses, Products,    | StockStatement            |
|               | Units                    |                           |
+---------------+--------------------------+---------------------------+
| **Cas         | CashReceipt, CashVoucher | Sổ CashBalance; báo cáo   |
| hManagement** | (tiền mặt); BankReceipt, | CashStatement             |
|               | BankPayment (ngân hàng); |                           |
| Tiền          | CashAccounts,            |                           |
|               | BankAccounts, Currencies |                           |
+---------------+--------------------------+---------------------------+
| **Company**   | Companies, Currencies,   | ---                       |
|               | VATRates                 |                           |
| Doanh nghiệp  |                          |                           |
+---------------+--------------------------+---------------------------+

## **1.2. Các sổ tích lũy**

Sổ tích lũy là nơi Jet ghi nhận "trạng thái" của doanh nghiệp. Sổ loại
Balances (số dư) trả lời câu hỏi "hiện có bao nhiêu"; sổ loại Turnovers
(doanh số) trả lời câu hỏi "trong kỳ đã phát sinh bao nhiêu".

  ----------------------------------------------------------------------------------
  **Sổ**                      **Loại**    **Chiều (phân tích      **Chỉ tiêu (đo
                                          theo)**                 lường)**
  --------------------------- ----------- ----------------------- ------------------
  **InventoryInWarehouses**   Balances    Product, Warehouse      Quantity

  **InventoryCost**           Balances    Product, Warehouse      Quantity, Amount

  **CustomerBalance**         Balances    LiabilityType,          Amount
                                          Counterparty, Document  

  **SupplierBalance**         Balances    LiabilityType,          Amount
                                          Counterparty, Document  

  **CashBalance**             Balances    BankCashAccount,        AmountCur
                                          CashType                

  **Purchases**               Turnovers   Counterparty, Product,  Quantity, Amount,
                                          PurchaseDocument        VATAmount

  **Sales**                   Turnovers   Counterparty, Product,  Quantity, Amount,
                                          SalesDocument           VATAmount
  ----------------------------------------------------------------------------------

## **1.3. Chứng từ nào ghi vào sổ nào**

Đây là bảng quan trọng nhất cho phương pháp "khai báo → nhập liệu → quan
sát hệ quả". Trước khi ghi sổ một chứng từ, cần nhìn vào hàng tương ứng
để dự đoán báo cáo nào sẽ thay đổi.

+--------------+--------+-------+-------+-----+------+-------+------+
| **Chứng từ** | **I    | **I   | **P   | **S | **Su | **    | **Ca |
|              | nvIn** | nvent | urcha | ale | ppli | Custo | sh** |
|              |        | ory** | ses** | s** | er** | mer** |      |
|              | **     |       |       |     |      |       | **B  |
|              | Wareho | **C   |       |     | **B  | *     | alan |
|              | uses** | ost** |       |     | alan | *Bala | ce** |
|              |        |       |       |     | ce** | nce** |      |
+==============+========+=======+=======+=====+======+=======+======+
| **Suppl      | ●      | ●     | ●     |     | ●    |       |      |
| ierInvoice** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **Sa         | ●      | ●     |       | ●   |      | ●     |      |
| lesInvoice** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **Invento    | ●      | ●     |       |     |      |       |      |
| ryIncrease** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **Invento    | ●      | ●     |       |     |      |       |      |
| ryTransfer** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **Invento    | ●      | ●     |       |     |      |       |      |
| ryWriteOff** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **C          |        |       |       |     |      | ●     | ●    |
| ashReceipt** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **B          |        |       |       |     |      | ●     | ●    |
| ankReceipt** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **C          |        |       |       |     | ●    |       | ●    |
| ashVoucher** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+
| **B          |        |       |       |     | ●    |       | ●    |
| ankPayment** |        |       |       |     |      |       |      |
+--------------+--------+-------+-------+-----+------+-------+------+

*Chứng từ PricesSetupAuxiliary ghi vào sổ thông tin Prices (bảng giá
theo loại giá và mặt hàng, định kỳ theo ngày). Giá vốn tính theo phương
pháp bình quân.*

## **1.4. Những gì cấu hình gốc của JET chưa có**

Danh sách này là "nguyên liệu" cho các đề tài. Mọi điểm dưới đây đã được
đối chiếu với cấu hình:

> • **Không có sản xuất** --- không có chứng từ hay sổ nào cho định mức
> nguyên vật liệu, lệnh sản xuất. Nhánh sản xuất trong sơ đồ quy trình
> chung của khóa học không thực hiện được trên Jet.
>
> • **Không có chứng từ đặt hàng** ở cả hai chiều --- không có đơn mua,
> không có đơn bán. Jet ghi nhận việc đã xảy ra, chưa quản lý cam kết.
>
> • **Không theo dõi lô, hạn sử dụng, số serial** --- tồn kho chỉ phân
> tích theo mặt hàng và kho.
>
> • **Không có chiều Company trong sổ nào** --- có danh mục Companies
> nhưng số liệu không tách theo pháp nhân.
>
> • **Không có nhân viên kinh doanh, khu vực, hạn thanh toán, hạn mức
> nợ, khoản mục chi phí, định mức tồn kho.**

# **2. Quy định chung cho các nhóm**

## **2.1. Cách chia đề**

  --------------------------------------------------------------------------
  **Phân hệ**          **Đề A**                   **Đề B**
  -------------------- -------------------------- --------------------------
  **Warehouses**       Đề 1 --- Lô hàng và hạn sử Đề 2 --- Định mức tồn kho
                       dụng                       chuỗi cửa hàng

  **Purchases**        Đề 3 --- Đơn đặt hàng nhà  Đề 4 --- Đánh giá nhà cung
                       cung cấp                   cấp

  **Sales**            Đề 5 --- Chiết khấu theo   Đề 6 --- Nhân viên kinh
                       số lượng                   doanh và khu vực

  **CashManagement**   Đề 7 --- Hạn thanh toán và Đề 8 --- Khoản mục chi phí
                       tuổi nợ                    và ngân sách
  --------------------------------------------------------------------------

## **2.2. Nội dung sản phẩm phải nộp**

> 1\. **Hồ sơ doanh nghiệp giả định** --- tên, ngành, quy mô, danh mục
> mặt hàng, số kho, khách hàng và nhà cung cấp tiêu biểu, đặc thù vận
> hành. Nhóm được tự do sáng tạo trong khung gợi ý của đề.
>
> 2\. **Vận hành trên Jet gốc** --- khai báo dữ liệu nền cho doanh
> nghiệp của nhóm, nhập tối thiểu 15 chứng từ thuộc phân hệ được giao
> trong một tháng giả định, nộp nhật ký chứng từ và phiếu quan sát
> trước/sau cho ít nhất 5 chứng từ.
>
> 3\. **Phân tích khoảng trống** --- Jet gốc đáp ứng được gì, chưa đáp
> ứng được gì cho doanh nghiệp này. Mỗi khoảng trống phải gắn với một
> hậu quả nghiệp vụ cụ thể (mất tiền, mất hàng, chậm giao, ra quyết định
> sai...).
>
> 4\. **Phát triển thêm** --- thiết kế và, tùy mức, hiện thực các đối
> tượng mới. Bắt buộc có bảng thiết kế đối tượng: tên, loại đối tượng
> 1C, các trường, lý do chọn loại đối tượng đó. Các bạn tham khảo tài
> liệu làm việc với nền tảng 1C:Enterprise ( các ví dụ mẫu trong [[link
> này]{.underline}](https://docs.google.com/document/d/1jAWDZpT1_rzmsXI_edEQnJvwxhLlac5L-ntAwElu4-Y/edit?tab=t.0):
> phần 3 và tập trung phần 3.d ), phần này không yêu cầu bắt buộc, mình
> sẽ hướng dẫn các nhóm thực hiện, các nhóm có thể xây dựng ý tưởng
> trước.
>
> ***Các nhóm cần chuẩn bị***
>
> 1\. Báo cáo chính (Word/PDF/Slide): nhật ký chứng từ + phiếu quan
> sát + phân tích gap (so sánh giữa hai thứ: Nghiệp vụ thực tế của doanh
> nghiệp giả định với Khả năng hiện có của phần mềm Jet ) + đề xuất mở
> rộng
>
> **Nhật ký chứng từ** khác đối tượng Document Journal trong phần mềm.
> Đây là bảng các nhóm tự tạo để liệt kê các chứng từ đã nhập ví dụ như
> hình ảnh dưới:
>
> *(hình minh họa trong tài liệu gốc)*
>
> Tương tự như **phiếu quan sát** cũng do các nhóm tự tạo, là bảng ghi
> lại trạng thái báo cáo/register TRƯỚC và SAU khi ghi sổ (post) một
> chứng từ. Ví dụ như ảnh:
>
> *(hình minh họa trong tài liệu gốc)*
>
> 2\. File .dt kèm theo (nộp qua Google Drive/link)
>
> 3\. Phần Demo trực tiếp trên máy ( cho buổi báo cáo hoặc quay hình lại
> nếu như không có buổi này)

## **2.3. Ba mức phát triển**

Trong 1C:Jet, việc ghi sổ của mọi chứng từ được viết bằng mã nguồn
(module chung PostingManagement). Mỗi yêu cầu trong các đề được gắn một
mức:

  ------------------------------------------------------------------------
  **Mức**   **Tên**             **Phạm vi**
  --------- ------------------- ------------------------------------------
  **M1**    Đặc tả              Mô tả bằng văn bản, sơ đồ và bảng thiết kế
                                đối tượng. Không thao tác trong Designer.
                                Bắt buộc với mọi nhóm.

  **M2**    Khai báo trực quan  Tạo trong Designer bằng thao tác trực
                                quan: danh mục, liệt kê, thuộc tính mới
                                trên chứng từ hoặc danh mục, sổ thông tin
                                nhập tay, chứng từ mới không ghi sổ, phân
                                hệ, báo cáo DCS trên dữ liệu có sẵn. Không
                                viết mã.

  **M3**    Cần lập trình       Thêm chiều hoặc sổ tích lũy mới, sửa logic
                                ghi sổ, tự động hóa trên biểu mẫu.
  ------------------------------------------------------------------------

## **2.4. Thang điểm gợi ý**

  -----------------------------------------------------------------------
  **Tiêu chí**                            **Trọng số** **Ghi chú**
  --------------------------------------- ------------ ------------------
  Hồ sơ doanh nghiệp rõ ràng, nhất quán   10%          
  với dữ liệu nhập                                     

  Vận hành Jet gốc: đủ chứng từ, phiếu    25%          Kiểm tra trong
  quan sát đúng                                        infobase của nhóm

  Phân tích khoảng trống: gắn với hậu quả 25%          Trọng tâm của lớp
  nghiệp vụ                                            Logistics

  Thiết kế đối tượng: đúng loại đối       25%          M1 + M2
  tượng, có lý do                                      

  Trình bày và trả lời câu hỏi phân tích  15%          
  của đề                                               

  Điểm cộng: hạng mục M3 hoạt động được   +10%         Tối đa
  -----------------------------------------------------------------------

# **3. Đề tài**

## **Đề 1 --- Lô hàng và hạn sử dụng**

  -----------------------------------------------------------------------
  **Phân hệ**        Warehouses
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Công ty phân phối thực phẩm khô (mì, đồ hộp, bánh
  ý**                kẹo) với 2 kho, khoảng 40 mặt hàng. Mỗi lần nhập
                     hàng là một lô có hạn sử dụng khác nhau; mỗi tháng
                     công ty hủy một lượng hàng hết hạn đáng kể.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Danh mục Warehouses, Products (có ProductType: Inventory/Service)
>
> • Chứng từ InventoryIncrease, InventoryTransfer, InventoryWriteOff;
> SupplierInvoice và SalesInvoice đều có trường Warehouse
>
> • Sổ InventoryInWarehouses và InventoryCost, cùng phân tích theo
> Product và Warehouse
>
> • Báo cáo AvailableStock, StockStatement

**Khoảng trống nghiệp vụ**

Tồn kho không phân biệt lô. Công ty không biết lô nào sắp hết hạn, không
áp dụng được nguyên tắc hết hạn trước --- xuất trước (FEFO).

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                            **Loại đối tượng**   **Mức**
  --------------------------------------- -------------------- -----------
  Danh mục Lô hàng, cấp dưới của          Catalog              **M2**
  Products, với thuộc tính Ngày sản xuất,                      
  Hạn sử dụng                                                  

  Cột Lô hàng trong phần bảng Inventory   Thuộc tính phần bảng **M2**
  của SupplierInvoice, InventoryIncrease,                      
  SalesInvoice, InventoryWriteOff                              

  Danh sách lô lọc theo hạn sử dụng còn   Báo cáo DCS trên     **M2**
  dưới N ngày                             danh mục             

  Thêm chiều Lô hàng vào                  Sửa sổ + ghi sổ      **M3**
  InventoryInWarehouses; xử lý                                 
  InventoryCost                                                

  Báo cáo tồn kho theo lô và hạn sử dụng  Báo cáo DCS trên sổ  **M3**
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Jet tính giá vốn bình quân theo mặt hàng và kho. Nếu theo dõi lô,
> có cần tính giá vốn theo lô không? Vì sao?
>
> 2\. Có nên thêm chiều Lô vào cả InventoryCost hay chỉ
> InventoryInWarehouses? Hệ quả của mỗi lựa chọn là gì?
>
> 3\. Khi hủy hàng hết hạn, nhóm dùng chứng từ nào của Jet? Chứng từ đó
> đang thiếu thông tin gì?

## **Đề 2 --- Định mức tồn kho chuỗi cửa hàng**

  -----------------------------------------------------------------------
  **Phân hệ**        Warehouses
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Chuỗi 5 cửa hàng tiện lợi và 1 kho tổng tại Hà Nội.
  ý**                Hàng được nhập về kho tổng rồi điều chuyển xuống cửa
                     hàng. Cửa hàng thường xuyên hết hàng bán chạy trong
                     khi kho tổng tồn nhiều.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Chứng từ InventoryTransfer với Warehouse (kho xuất) và
> WarehouseReceiver (kho nhận)
>
> • Sổ InventoryInWarehouses theo Product, Warehouse
>
> • Báo cáo AvailableStock, StockStatement
>
> • Danh mục Warehouses không có thuộc tính nghiệp vụ riêng (chỉ có
> thông tin liên hệ và thuộc tính bổ sung)

**Khoảng trống nghiệp vụ**

Không có định mức tồn tối thiểu và tối đa theo từng cửa hàng. Việc điều
chuyển dựa vào cảm tính của quản lý, không có cảnh báo.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**    **Mức**
  -------------------------------------- --------------------- -----------
  Sổ thông tin Định mức tồn kho: chiều   Information Register  **M2**
  Warehouse, Product; chỉ tiêu Tồn tối                         
  thiểu, Tồn tối đa                                            

  Thuộc tính Loại kho (Kho tổng / Cửa    Enumeration + thuộc   **M2**
  hàng) trên Warehouses, dùng liệt kê    tính                  

  Báo cáo so sánh tồn thực tế với định   Báo cáo DCS           **M2**
  mức, đánh dấu dưới mức tối thiểu                             

  Tự tạo InventoryTransfer đề xuất từ    Xử lý dữ liệu         **M3**
  báo cáo cảnh báo                                             
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Định mức nên cố định hay thay đổi theo mùa? Nếu thay đổi, sổ thông
> tin cần đặt định kỳ không?
>
> 2\. Tại sao định mức là sổ thông tin mà không phải thuộc tính của danh
> mục Products?
>
> 3\. Từ số liệu tháng giả định, cửa hàng nào điều chuyển nhiều nhất?
> Điều đó nói gì về việc đặt định mức?

## **Đề 3 --- Đơn đặt hàng nhà cung cấp**

  -----------------------------------------------------------------------
  **Phân hệ**        Purchases
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Doanh nghiệp nhập khẩu thiết bị điện gia dụng, đặt
  ý**                hàng trước 2--6 tuần, thường nhận hàng thành nhiều
                     đợt. Bộ phận mua hàng cần biết hàng nào đã đặt nhưng
                     chưa về để không đặt trùng.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Chứng từ SupplierInvoice (Supplier, Warehouse, Currency, phần bảng
> Inventory, AdvanceClearing)
>
> • SupplierInvoice ghi vào 4 sổ: InventoryInWarehouses, InventoryCost,
> Purchases, SupplierBalance
>
> • Không có chứng từ đặt hàng nhà cung cấp

**Khoảng trống nghiệp vụ**

Jet chỉ ghi nhận hàng đã về. Không phân biệt được hàng đã đặt, hàng đang
về, hàng đã nhận đủ.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**    **Mức**
  -------------------------------------- --------------------- -----------
  Chứng từ Đơn đặt hàng nhà cung cấp:    Document (không ghi   **M2**
  Supplier, Warehouse, Ngày giao dự      sổ)                   
  kiến, phần bảng hàng hóa                                     

  Liệt kê Trạng thái đơn: Mới / Đã xác   Enumeration           **M2**
  nhận / Nhận một phần / Nhận đủ / Hủy                         

  Thuộc tính "Theo đơn đặt hàng" trên    Thuộc tính            **M2**
  SupplierInvoice                                              

  Sổ Hàng đặt chưa về: đơn đặt hàng ghi  Accumulation Register **M3**
  tăng, SupplierInvoice ghi giảm                               

  Báo cáo đơn chưa hoàn thành theo nhà   Báo cáo DCS           **M3**
  cung cấp                                                     
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Sổ Hàng đặt chưa về nên là Balances hay Turnovers? Giải thích bằng
> câu hỏi nghiệp vụ mà sổ phải trả lời.
>
> 2\. Đơn đặt hàng có nên ghi vào InventoryInWarehouses không? Vì sao
> không?
>
> 3\. Nếu nhà cung cấp giao thiếu và không giao bù, trạng thái đơn và số
> liệu trong sổ phải xử lý thế nào?

## **Đề 4 --- Đánh giá nhà cung cấp**

  -----------------------------------------------------------------------
  **Phân hệ**        Purchases
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Công ty thương mại vật liệu xây dựng mua cùng một
  ý**                mặt hàng (xi măng, thép) từ 3 nhà cung cấp với giá
                     và độ tin cậy giao hàng khác nhau. Ban giám đốc muốn
                     có căn cứ chọn nguồn cung.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Danh mục Counterparties với cờ Supplier
>
> • Sổ Purchases (Turnovers): Counterparty, Product, PurchaseDocument;
> Quantity, Amount, VATAmount
>
> • Báo cáo Purchases
>
> • Lưu ý: thuộc tính PriceType trên Counterparties là loại giá **bán**
> cho khách hàng (SalesInvoice tự điền từ đây), không phải bảng giá mua

**Khoảng trống nghiệp vụ**

Sổ Purchases cho biết đã mua bao nhiêu và giá bao nhiêu, nhưng không có
tiêu chí thời gian giao hàng, cam kết cung ứng hay xếp hạng.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**    **Mức**
  -------------------------------------- --------------------- -----------
  Báo cáo giá mua bình quân theo nhà     Báo cáo DCS           **M2**
  cung cấp × mặt hàng (Amount /                                
  Quantity) từ sổ Purchases                                    

  Sổ thông tin Cam kết cung ứng:         Information Register  **M2**
  Counterparty, Product; Thời gian giao                        
  cam kết (ngày), Số lượng đặt tối thiểu                       

  Thuộc tính Ngày hẹn giao trên          Thuộc tính + Báo cáo  **M2**
  SupplierInvoice; báo cáo tỷ lệ giao    DCS                   
  đúng hẹn                                                     

  Liệt kê Xếp hạng nhà cung cấp (A/B/C)  Enumeration + thuộc   **M2**
  và thuộc tính trên Counterparties      tính                  
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Nhóm đề xuất trọng số nào giữa giá, thời gian giao và độ tin cậy?
> Kết quả xếp hạng thay đổi thế nào nếu đổi trọng số?
>
> 2\. Xếp hạng nên là liệt kê hay danh mục? Khi nào doanh nghiệp cần đổi
> sang danh mục?
>
> 3\. Đề này và Đề 3 bổ sung cho nhau thế nào? Nếu có đơn đặt hàng, Ngày
> hẹn giao nên nằm ở đâu?

## **Đề 5 --- Chiết khấu theo số lượng**

  -----------------------------------------------------------------------
  **Phân hệ**        Sales
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Nhà phân phối nước giải khát bán cho đại lý cấp 1,
  ý**                cấp 2 và cửa hàng lẻ. Đại lý mua càng nhiều thùng
                     thì được chiết khấu càng cao, theo bậc.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Danh mục PriceTypes; sổ thông tin Prices (PriceType, Product →
> Price), định kỳ theo ngày
>
> • Chứng từ PricesSetupAuxiliary để cập nhật giá hàng loạt
>
> • Counterparties có thuộc tính PriceType; khi chọn khách trên
> SalesInvoice, loại giá được tự điền và giá được điền lại
>
> • Báo cáo PriceList

**Khoảng trống nghiệp vụ**

Jet đã giải quyết tốt giá theo nhóm khách. Điều còn thiếu là chiết khấu
theo khối lượng mua trên từng đơn.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**    **Mức**
  -------------------------------------- --------------------- -----------
  Sổ thông tin Bậc chiết khấu:           Information Register  **M2**
  PriceType, Product, Số lượng tối                             
  thiểu; chỉ tiêu % chiết khấu                                 

  Cột % chiết khấu trên phần bảng        Thuộc tính phần bảng  **M2**
  Inventory của SalesInvoice (nhập tay)                        

  Tự áp chiết khấu khi nhập số lượng     Mã trên biểu mẫu      **M3**

  Báo cáo doanh thu trước và sau chiết   Sửa sổ Sales + báo    **M3**
  khấu                                   cáo                   
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Vì sao sổ Prices được đặt định kỳ theo ngày? Điều gì xảy ra với
> hóa đơn cũ khi giá thay đổi?
>
> 2\. Chiết khấu nên phụ thuộc vào loại giá, vào khách hàng cụ thể, hay
> cả hai?
>
> 3\. Nếu chiết khấu chỉ nhập tay, rủi ro kiểm soát nội bộ là gì?

## **Đề 6 --- Nhân viên kinh doanh và khu vực**

  -----------------------------------------------------------------------
  **Phân hệ**        Sales
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Công ty phân phối dược mỹ phẩm có 8 nhân viên kinh
  ý**                doanh phụ trách 3 miền. Hoa hồng được tính theo
                     doanh số của từng người, và ban giám đốc cần doanh
                     số theo vùng.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Chứng từ SalesInvoice: Customer, Warehouse, PriceType, Author,
> Total...
>
> • Sổ Sales: Counterparty, Product, SalesDocument; báo cáo Sales,
> ProfitOnSales
>
> • Lưu ý: Author là người tạo chứng từ, không phải người bán

**Khoảng trống nghiệp vụ**

Không gắn được đơn bán với nhân viên kinh doanh hay khu vực, nên không
tính được hoa hồng và không phân tích được theo vùng.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**    **Mức**
  -------------------------------------- --------------------- -----------
  Danh mục Khu vực, phân cấp Miền → Tỉnh Catalog               **M2**
                                         (hierarchical)        

  Danh mục Nhân viên kinh doanh: Khu vực Catalog               **M2**
  phụ trách, Tỷ lệ hoa hồng                                    

  Thuộc tính Khu vực trên                Thuộc tính            **M2**
  Counterparties; Nhân viên kinh doanh                         
  trên SalesInvoice                                            

  Báo cáo doanh số theo nhân viên và khu Báo cáo DCS           **M2**
  vực, đọc từ chứng từ SalesInvoice                            

  Thêm chiều Nhân viên, Khu vực vào sổ   Sửa sổ + ghi sổ       **M3**
  Sales                                                        
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Khu vực nên gắn vào khách hàng hay vào từng hóa đơn? Nếu khách
> chuyển sang vùng khác, doanh số cũ tính cho vùng nào?
>
> 2\. Báo cáo đọc từ chứng từ khác gì báo cáo đọc từ sổ? Khi nào cách
> thứ nhất không đủ?
>
> 3\. Tỷ lệ hoa hồng thay đổi theo thời gian thì nên lưu ở đâu?

## **Đề 7 --- Hạn thanh toán và tuổi nợ**

  -----------------------------------------------------------------------
  **Phân hệ**        CashManagement
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Công ty cung cấp văn phòng phẩm cho doanh nghiệp,
  ý**                bán chịu 30--60 ngày. Nợ quá hạn ngày càng tăng và
                     công ty không biết khách nào cần dừng bán.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Sổ CustomerBalance: LiabilityType (Liability = nợ phải thu / Advance
> = tiền ứng trước), Counterparty, Document; Amount
>
> • CashReceipt, BankReceipt có phần bảng PaymentDetails (Document,
> PaymentAmount, Amount) để thu tiền theo từng hóa đơn
>
> • SalesInvoice có phần bảng AdvanceClearing để cấn trừ tiền ứng trước
>
> • Báo cáo CustomerBalance (thuộc phân hệ Sales)

**Khoảng trống nghiệp vụ**

Sổ theo dõi được còn nợ bao nhiêu trên từng hóa đơn, nhưng không có hạn
thanh toán, nên không biết khoản nào quá hạn và quá hạn bao lâu. Không
có hạn mức nợ.

**Yêu cầu phát triển**

  -----------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**   **Mức**
  -------------------------------------- -------------------- -----------
  Sổ thông tin Điều khoản thanh toán:    Information Register **M2**
  Counterparty; Số ngày được nợ, Hạn mức                      
  nợ; định kỳ                                                 

  Thuộc tính Hạn thanh toán trên         Thuộc tính           **M2**
  SalesInvoice                                                

  Báo cáo tuổi nợ: số dư CustomerBalance Báo cáo DCS          **M3**
  theo hóa đơn, chia nhóm Chưa đến hạn /                      
  1--30 / 31--60 / trên 60 ngày                               

  Cảnh báo hoặc chặn bán khi khách vượt  Mã ghi sổ            **M3**
  hạn mức nợ                                                  
  -----------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Vì sao CustomerBalance cần chiều Document? Nếu bỏ chiều này thì
> mất khả năng phân tích gì?
>
> 2\. Tiền khách ứng trước (Advance) có tính vào tuổi nợ không?
>
> 3\. Chặn bán hay chỉ cảnh báo khi vượt hạn mức --- ai trong doanh
> nghiệp nên có quyền vượt?

## **Đề 8 --- Khoản mục chi phí và ngân sách**

  -----------------------------------------------------------------------
  **Phân hệ**        CashManagement
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Công ty dịch vụ vận tải nội địa có nhiều khoản chi
  ý**                vận hành: nhiên liệu, cầu đường, sửa chữa, lương tài
                     xế, thuê bãi. Kế toán không trả lời được tháng này
                     chi bao nhiêu cho nhiên liệu so với kế hoạch.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • CashVoucher, BankPayment có thuộc tính Operation, là liệt kê chỉ có
> 2 giá trị: Supplier và Other
>
> • Sổ CashBalance: BankCashAccount, CashType (Cash/NonCash); AmountCur
>
> • Báo cáo CashStatement

**Khoảng trống nghiệp vụ**

Mọi khoản chi không trả nhà cung cấp đều rơi vào "Other", không phân
loại được mục đích chi.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                           **Loại đối tượng**    **Mức**
  -------------------------------------- --------------------- -----------
  Danh mục Khoản mục chi phí, phân cấp   Catalog               **M2**
  (Vận hành → Nhiên liệu, Cầu đường...)  (hierarchical)        

  Thuộc tính Khoản mục trên CashVoucher, Thuộc tính            **M2**
  BankPayment, dùng khi Operation =                            
  Other                                                        

  Sổ thông tin Ngân sách: Khoản mục; Số  Information Register  **M2**
  tiền; định kỳ theo tháng                                     

  Báo cáo chi phí thực tế theo khoản     Báo cáo DCS           **M2**
  mục, đọc từ chứng từ chi                                     

  Sổ Chi phí (Turnovers) và báo cáo kế   Accumulation Register **M3**
  hoạch -- thực tế                                             
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Operation là liệt kê, còn Khoản mục chi phí nhóm chọn là danh mục.
> Tiêu chí nào để chọn giữa hai loại này?
>
> 2\. Một khoản chi trả nhà cung cấp (Operation = Supplier) có cần gắn
> khoản mục không?
>
> 3\. Nếu ngân sách thay đổi giữa năm, sổ thông tin định kỳ giúp giữ
> lịch sử thế nào?

##  **Đề 9 --- Kiểm kê kho và xử lý chênh lệch**

  -----------------------------------------------------------------------
  **Phân hệ**        Warehouses
  ------------------ ----------------------------------------------------
  **Doanh nghiệp gợi Nhà phân phối phụ tùng xe máy có 1 kho chính khoảng
  ý**                300 mã hàng, nhiều mã nhỏ, giá trị thấp, dễ thất
                     lạc. Cuối mỗi quý công ty kiểm kê toàn bộ kho; lần
                     gần nhất lệch hàng chục mã nhưng không ai giải thích
                     được nguyên nhân.

  -----------------------------------------------------------------------

**Jet gốc đang có**

> • Chứng từ InventoryIncrease (Warehouse; phần bảng Product, Quantity,
> Price, Amount) --- thiết kế ban đầu để nhập tồn đầu kỳ
>
> • Chứng từ InventoryWriteOff (Warehouse; phần bảng Product, Quantity)
> --- không có đơn giá, không có lý do xuất hủy
>
> • Cả hai ghi vào InventoryInWarehouses và InventoryCost; giá trị hàng
> giảm lấy theo giá vốn bình quân
>
> • Báo cáo StockStatement, AvailableStock cho số lượng sổ sách
>
> • Không có chứng từ kiểm kê

**Khoảng trống nghiệp vụ**

Jet điều chỉnh được tồn kho nhưng không lưu lại cuộc kiểm kê: không có
số sổ sách và số thực tế đặt cạnh nhau, không biết điều chỉnh nào xuất
phát từ lần kiểm kê nào, và không phân biệt được hao hụt tự nhiên, mất
mát hay nhập sai.

**Yêu cầu phát triển**

  ------------------------------------------------------------------------
  **Hạng mục**                            **Loại đối tượng**   **Mức**
  --------------------------------------- -------------------- -----------
  Chứng từ Phiếu kiểm kê: Warehouse,      Document (không ghi  **M2**
  Người kiểm, phần bảng Product, SL sổ    sổ)                  
  sách, SL thực tế, Chênh lệch                                 

  Liệt kê Lý do chênh lệch: Hao hụt tự    Enumeration + thuộc  **M2**
  nhiên / Mất mát / Hư hỏng / Nhập xuất   tính phần bảng       
  sai; cột Lý do trên Phiếu kiểm kê                            

  Thuộc tính "Theo phiếu kiểm kê" và Lý   Thuộc tính           **M2**
  do trên InventoryIncrease,                                   
  InventoryWriteOff                                            

  Báo cáo tổng hợp chênh lệch theo lý do  Báo cáo DCS          **M2**
  và mặt hàng qua các kỳ kiểm kê                               

  Tự điền SL sổ sách từ                   Mã trên chứng từ     **M3**
  InventoryInWarehouses; tự tạo                                
  InventoryIncrease/WriteOff từ phiếu                          
  ------------------------------------------------------------------------

**Câu hỏi phân tích bắt buộc**

> 1\. Phiếu kiểm kê có nên tự ghi sổ tồn kho không? Vì sao doanh nghiệp
> thường tách "ghi nhận kết quả kiểm" và "điều chỉnh sổ" thành hai bước?
>
> 2\. InventoryWriteOff không có đơn giá. Giá trị hàng thiếu được xác
> định từ đâu, và điều đó ảnh hưởng thế nào đến báo cáo lợi nhuận?
>
> 3\. Nếu kho vẫn nhập xuất trong lúc kiểm, SL sổ sách phải lấy tại thời
> điểm nào? Nhóm đề xuất quy trình gì để tránh sai lệch?
