# Khóa học JD - 24 bài (1C:Enterprise)

Repository chứa source dump của infobase 1C cho từng bài học, được build bằng `1cv8.exe DESIGNER /DumpConfigToFiles` (Configuration Files Hierarchy / XML).

Mỗi branch là **trạng thái tích lũy** sau khi hoàn thành bài học đó: kế thừa toàn bộ nội dung của bài trước cộng với phần mới của bài hiện tại. Diff giữa hai branch liền kề chính là phần code thêm/sửa trong một bài.

## Cấu trúc thư mục

- `cf/` — toàn bộ cấu hình 1C dump dạng XML hierarchy (`Configuration.xml`, `Catalogs/`, `Documents/`, `CommonModules/`, ...). Đây là format chuẩn để source-control 1C config.
- `LESSONS.md` — file này.
- `.gitignore` — loại trừ thư mục worktree, project EDT cũ.

## Bản đồ branch → bài học

Mỗi bài có hai branch: `theory` (lý thuyết) và `practice` (thực hành). Bài 2 chỉ có lý thuyết (không có infobase thực hành). Bài 6 được gộp vào bài 5. Bài 21, 22, 23 dùng chung một infobase nên gộp thành `lesson/21-23-*`.

| Bài | Lý thuyết | Thực hành |
|----:|---|---|
|  2  | [`lesson/02-theory`](../../tree/lesson/02-theory) | _(không có)_ |
|  3  | [`lesson/03-theory`](../../tree/lesson/03-theory) | [`lesson/03-practice`](../../tree/lesson/03-practice) |
|  4  | [`lesson/04-theory`](../../tree/lesson/04-theory) | [`lesson/04-practice`](../../tree/lesson/04-practice) |
|  5+6 | [`lesson/05-theory`](../../tree/lesson/05-theory) | [`lesson/05-practice`](../../tree/lesson/05-practice) |
|  7  | [`lesson/07-theory`](../../tree/lesson/07-theory) | [`lesson/07-practice`](../../tree/lesson/07-practice) |
|  8  | [`lesson/08-theory`](../../tree/lesson/08-theory) | [`lesson/08-practice`](../../tree/lesson/08-practice) |
|  9  | [`lesson/09-theory`](../../tree/lesson/09-theory) | [`lesson/09-practice`](../../tree/lesson/09-practice) |
| 10  | [`lesson/10-theory`](../../tree/lesson/10-theory) | [`lesson/10-practice`](../../tree/lesson/10-practice) |
| 11  | [`lesson/11-theory`](../../tree/lesson/11-theory) | [`lesson/11-practice`](../../tree/lesson/11-practice) |
| 12  | [`lesson/12-theory`](../../tree/lesson/12-theory) | [`lesson/12-practice`](../../tree/lesson/12-practice) |
| 13  | [`lesson/13-theory`](../../tree/lesson/13-theory) | [`lesson/13-practice`](../../tree/lesson/13-practice) |
| 14  | [`lesson/14-theory`](../../tree/lesson/14-theory) | [`lesson/14-practice`](../../tree/lesson/14-practice) |
| 15  | [`lesson/15-theory`](../../tree/lesson/15-theory) | [`lesson/15-practice`](../../tree/lesson/15-practice) |
| 16  | [`lesson/16-theory`](../../tree/lesson/16-theory) | [`lesson/16-practice`](../../tree/lesson/16-practice) |
| 17  | [`lesson/17-theory`](../../tree/lesson/17-theory) | [`lesson/17-practice`](../../tree/lesson/17-practice) |
| 18  | [`lesson/18-theory`](../../tree/lesson/18-theory) | [`lesson/18-practice`](../../tree/lesson/18-practice) |
| 19  | [`lesson/19-theory`](../../tree/lesson/19-theory) | [`lesson/19-practice`](../../tree/lesson/19-practice) |
| 20  | [`lesson/20-theory`](../../tree/lesson/20-theory) | [`lesson/20-practice`](../../tree/lesson/20-practice) |
| 21+22+23 | [`lesson/21-23-theory`](../../tree/lesson/21-23-theory) | [`lesson/21-23-practice`](../../tree/lesson/21-23-practice) |
| 24  | [`lesson/24-theory`](../../tree/lesson/24-theory) | [`lesson/24-practice`](../../tree/lesson/24-practice) |

**`master`** = nội dung cuối cùng của `lesson/24-practice` (trạng thái tổng kết toàn khóa).

**`master-edt-archive`** = commit gốc trước khi chuyển format (chứa snapshot EDT của configuration `NN_JD_FullCourse`).

**[`lesson/university-summary`](../../tree/lesson/university-summary)** = snapshot riêng từ `FullProgram_University_Study_Program`. Base này có Language với tên chứa `:` (không hợp lệ trong tên file Windows) nên không dump được XML — được lưu dạng `.cf` binary. Thực ra chỉ có 3 đối tượng (Catalog.Products, Document.Purchases, Document.Sales), không phải "tổng kết toàn khóa".

## Cách sử dụng

### Xem code một bài cụ thể
```bash
git checkout lesson/09-practice    # ví dụ: trạng thái sau khi xong phần thực hành bài 9
```

### Xem điểm khác biệt giữa lý thuyết và thực hành của một bài
```bash
git diff lesson/09-theory..lesson/09-practice
```

### Xem những gì bài mới thêm so với bài trước
```bash
git diff lesson/09-practice..lesson/10-theory   # những thay đổi khi sang bài 10
```

### Import vào 1C
1. Tạo infobase trống (`Create new infobase` trong 1C launcher).
2. Mở 1C:Designer, mở infobase vừa tạo.
3. `Configuration → Load configuration from files` → chọn thư mục `cf/` của branch tương ứng.
4. Đồng ý ghi đè configuration, sau đó `F7` để cập nhật cấu hình cơ sở dữ liệu.

## Tag

Mỗi branch có tag tương ứng `v-<branch-name>` (vd: `v-lesson-09-practice`) để tham chiếu cố định.

## Build lại từ infobase

Source infobase nằm tại `D:\TaiLieuDaoTao\SGK_NongNghiep\Key_Mikhail\Bases\`.

Script build: `D:\jd-dumps\build-lessons.ps1`, `D:\jd-dumps\build-resume.ps1`.
