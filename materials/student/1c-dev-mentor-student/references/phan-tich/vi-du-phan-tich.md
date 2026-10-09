# Ví dụ phân tích → thiết kế (ngành minh họa)

> **Khi nào đọc file này:** cần minh họa **cách lập luận** từ nghiệp vụ tới thiết kế 1C. Hai ví dụ dùng ngành ít gặp trong đề tài sinh viên và khác các đề đánh giá của khóa (cấp phát vật tư công trình, xưởng bánh). Luôn nói rõ: đây là minh họa cách suy nghĩ, không phải thiết kế mẫu để chép. Nếu đề tài của nhóm trùng ngành với một ví dụ, dùng ví dụ còn lại. Lộ trình J: ưu tiên minh họa trên chính Jet.

## Ví dụ A — Công ty xây dựng cấp phát vật tư cho công trình

**Hồ sơ (K1, rút gọn):** 400 loại vật tư (xi măng, thép, ống, dây điện), 2 kho trung tâm, 6 công trình đang thi công; chỉ huy trưởng công trình đề nghị vật tư, kho cấp, cuối giai đoạn công trình trả lại vật tư thừa. Giá trị vật tư theo đơn giá kế hoạch, cập nhật mỗi quý. Ngoài phạm vi: mua hàng, kế toán tổng hợp, giá thành công trình chi tiết.

**Quy trình (K3):**

```mermaid
flowchart LR
  R[Công trình đề nghị vật tư] --> I[Kho cấp vật tư]
  I --> U[Công trình sử dụng]
  U --> B[Trả lại vật tư thừa]
  I -. thiếu hàng .-> W[Báo phòng mua hàng]
```

**Câu hỏi quản lý (K6):**
1. Kho nào đang còn bao nhiêu vật tư X? → tại thời điểm, theo kho + vật tư.
2. Công trình nào đang giữ bao nhiêu vật tư gì (đã cấp mà chưa dùng hết / chưa trả)? → tại thời điểm, theo công trình + vật tư.
3. Giá trị vật tư đã cấp cho từng công trình theo tháng? → trong kỳ.

**Lập luận chọn object:**
- "Đề nghị vật tư" có cần là Document không? Nếu đề nghị qua điện thoại và kho cấp ngay → **không**, gộp vào phiếu cấp. Nếu đề nghị phải được duyệt trước và kho cần biết lượng đã hứa cấp → có, và cần thêm câu hỏi "vật tư đã được giữ cho công trình bao nhiêu". (Hai phương án — tùy hồ sơ.)
- Câu hỏi 1 và 2 hỏi "còn bao nhiêu" → hai register **Balances**. Vì sao hai register chứ không một register có dimension "Nơi ở" (kho hoặc công trình)? Một register gọn hơn nhưng dimension phải nhận hai kiểu dữ liệu (composite type) và báo cáo phải lọc theo kiểu; hai register rõ nghĩa, mỗi câu hỏi một register. Ví dụ này chọn hai register.
- Câu hỏi 3 hỏi "trong kỳ" → register **Turnovers** `IssuedToSites` (dimension Site, Material; resource Amount).
- Đơn giá kế hoạch đổi theo quý → Information register periodic `PlannedCosts`, không phải attribute của Catalog.

**Ma trận posting (K9):**

| Chứng từ | MaterialsInStock (Balances) | MaterialsAtSites (Balances) | IssuedToSites (Turnovers) |
|---|---|---|---|
| MaterialIssue | Giảm (Warehouse ← header, Material ← dòng) | Tăng (Site, Material) | Phát sinh: số lượng × đơn giá |
| MaterialReturn | Tăng | Giảm | Phát sinh âm (giảm giá trị đã cấp) |

**Quy tắc (K5):** không cấp quá tồn → kiểm tra trong `Posting` (code: `code-patterns.md` mẫu 4.1); không trả nhiều hơn lượng công trình đang giữ → `Posting`, đọc `MaterialsAtSites`; ngày cần vật tư không trước ngày cấp → `FillCheckProcessing` (mẫu 4.3); tự điền đơn giá → form (mẫu 4.2).

**Kiểm thử (K11, rút gọn):**

| # | Thao tác | Mong đợi |
|---|---|---|
| T1 | Nhập tồn 10 tấn thép vào Kho 1 | Tồn Kho 1 = 10 |
| T2 | Cấp 12 tấn cho công trình A | Bị chặn, báo thiếu 2 |
| T3 | Cấp 8 tấn cho công trình A, đơn giá 15.000.000/tấn | Kho 1 còn 2; công trình A giữ 8; giá trị cấp tháng = 120.000.000 |
| T4 | Công trình A trả 3 tấn | Kho 1 = 5; công trình A giữ 5; giá trị cấp tháng = 75.000.000 |

## Ví dụ B — Xưởng bánh nhỏ (sản xuất đơn giản)

**Hồ sơ:** 20 loại bánh, 60 nguyên liệu, 1 kho nguyên liệu, 1 kho thành phẩm; mỗi ngày làm theo kế hoạch rồi bán cho các quán cà phê. Ngoài phạm vi: tính giá thành chi tiết theo chi phí chung, kế hoạch nhu cầu nguyên liệu (MRP).

**Câu hỏi quản lý:**
1. Còn bao nhiêu nguyên liệu X, đủ làm bao nhiêu mẻ bánh Y?
2. Hôm nay sản xuất bao nhiêu, hao hụt nguyên liệu so với định mức bao nhiêu?
3. Tồn thành phẩm theo loại bánh.

**Lập luận:**
- **Định mức nguyên liệu** (một mẻ bánh Y cần bao nhiêu bột, đường…) là dữ liệu chủ phụ thuộc vào bánh → phương án 1: tabular section `Recipe` trong Catalog `Products`; phương án 2: Catalog `Recipes` có Owner là `Products` (cho phép nhiều công thức, có hiệu lực theo thời gian thì cần thêm information register). Xưởng chỉ có một công thức mỗi loại → phương án 1 đủ.
- **Một chứng từ hay hai** cho sản xuất? Phương án 1: `ProductionReport` một chứng từ vừa ghi giảm nguyên liệu vừa ghi tăng thành phẩm — đơn giản, hợp xưởng nhỏ. Phương án 2: tách `MaterialIssue` (xuất nguyên liệu) và `ProductionOutput` (nhập thành phẩm) — hợp khi xuất và nhập ở hai thời điểm, hai người khác nhau.
- Câu hỏi 2 cần so **thực tế với định mức** → chứng từ phải lưu cả lượng định mức (tính từ công thức × số mẻ) và lượng thực tế; báo cáo so sánh đọc từ chứng từ hoặc một register Turnovers `MaterialUsage` (dimension Material, Product; resource StandardQty, ActualQty).

**Ma trận posting (phương án một chứng từ):**

| Chứng từ | MaterialStock (Balances) | FinishedGoods (Balances) | MaterialUsage (Turnovers) |
|---|---|---|---|
| ProductionReport | Giảm theo lượng thực tế | Tăng số bánh làm được | StandardQty, ActualQty theo nguyên liệu |
| SalesInvoice | — | Giảm | — |

**Quy tắc:** không xuất nguyên liệu quá tồn → `Posting`; số mẻ > 0 → Fill checking; tự tính lượng định mức khi nhập số mẻ → form (gọi server một lần để đọc công thức).

**Điểm để nhóm tự quyết:** giá trị nguyên liệu xuất tính theo giá nào (bình quân, nhập trước xuất trước) — nếu đề tài cần, xem cách tính giá vốn bình quân trong `erp-practice/erp-practice.md`; nếu không, ghi vào "ngoài phạm vi".
