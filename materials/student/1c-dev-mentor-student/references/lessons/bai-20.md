# Bài 20 — Roles and access rights (Vai trò và quyền truy cập)

## Khái niệm chính

### Access rights
- Nguyên tắc của 1C:Enterprise: theo mặc định, **mọi thứ không được cho phép đều bị cấm**.
- Chỉ có một thực thể chịu trách nhiệm cho việc user truy cập chức năng/dữ liệu: **Access right**. Đây là phần tử duy nhất điều khiển truy cập tới một chế độ làm việc, dữ liệu catalog, attribute, v.v.
- Số loại access right do platform định sẵn. Có 2 nhóm chính:
  - **General system-wide access rights** (quyền toàn hệ thống tới cơ chế platform): truy cập các chế độ làm việc của platform (Administration, Exclusive Mode, Thin Client, Interactive opening of external reports...).
  - **Object access rights**: làm việc với các configuration object. Số lượng phụ thuộc loại object — ví dụ catalog có 16 loại quyền (Read, Add, Change, Delete...), information register chỉ có 5 loại. Các quyền này đặt ở mức toàn bộ catalog. Có thể giới hạn ở mức attribute, nhưng khi đó chỉ một phần loại quyền khả dụng (với catalog là **View** và **Edit**).
- Object access rights chia 2 loại:
  - **Basic (non-interactive)**: luôn được kiểm tra bất kể cách truy cập object.
  - **Interactive**: chỉ kiểm tra khi thực hiện thao tác tương tác (ví dụ "Set deletion mark", "Post", "Clear posting").
- Kiểm tra interactive rights **có thể bị vượt qua** (ví dụ tự tạo form và thay standard commands bằng command riêng); kiểm tra non-interactive rights **không thể bị vượt qua** trong bất kỳ trường hợp nào.
- Các basic access rights bảo vệ chức năng nền tảng của object: **"Insert", "Read", "Update", "Delete"**. Để xây dựng giải pháp an toàn, chỉ cần quản lý 4 quyền này.
- Có thể kiểm tra quyền từ built-in language. Khi thêm command vào form, developer phải tự lo kiểm tra interactive rights tương ứng.
- Một infobase user có thể có interactive và non-interactive rights khác nhau trên cùng object (ví dụ "Posting" được phép nhưng "Interactive posting" bị cấm).
- Khi thực hiện thao tác không được phép: hiện thông báo lỗi **"Access violation!"** và mọi transaction đã bắt đầu bị hủy.
- Việc kiểm tra basic và interactive rights được dùng bởi form extension, table field extension, input field extension (form extension xác định bởi main attribute; table field/input field extension xác định bởi kiểu dữ liệu được sửa). Do đó nếu không có quyền **"View"**, list form hay object form sẽ không mở và hiện thông báo vi phạm quyền.

### Ví dụ kiểm tra quyền bởi extension (với document)
- Mở document form: kiểm tra "View"; nếu là form object mới → kiểm tra "Interactive insert", nếu không → "Edit". Khi write có posting → kiểm tra "Interactive posting", "Interactive undo posting" hoặc "Interactive posting regular" tùy chế độ write.
- Table field extension của document journal (khi journal là main attribute của form): kiểm tra có "View" cho ít nhất một document trong journal. Khi post từ journal → "Interactive posting"/"Interactive undo posting"/"Interactive posting regular". Khi xóa → "Interactive delete". Khi đặt/bỏ deletion mark → "Interactive mark for deletion"/"Interactive unmark for deletion". Khi thêm document mới (sau khi chọn loại) → "Interactive insert".
- Document input field chỉ kiểm tra quyền **"String input"**.

### Related rights (quyền liên quan)
- Một số quyền phụ thuộc nhau. Ví dụ: không thể cho phép "Update" mà không cấp "Read".
- Interactive rights phụ thuộc trực tiếp vào non-interactive tương ứng ("Interactive delete" phụ thuộc "Delete"). Khi cấu hình: bật interactive right → non-interactive tương ứng tự bật; bỏ non-interactive → interactive tương ứng tự bị reset. Chỉ có thể đặt non-interactive và bỏ interactive, không thể ngược lại.
- Chuỗi phụ thuộc phức tạp: với "Document", "Interactive undo posting" phụ thuộc đồng thời "Undo posting" và "Edit"; "Undo posting" phụ thuộc "Update"; "Update" phụ thuộc "Read".
- Quyền then chốt là **"Read"** — nếu thiếu, mọi quyền khác trên object tự động mất.

### Bảng access rights

| Access right | Mô tả |
| --- | --- |
| ActiveUsers | Xem danh sách active users. Có thể dùng khi tổ chức "guest login". |
| Administration | Thao tác quản trị như duy trì danh sách user hay mở configuration. |
| Automation | Dùng 1C:Enterprise ở automation mode. |
| Delete | Cho phép xóa |
| Edit | Cho phép sửa object (interactive) |
| EventLog | Xem event log và work protocols |
| ExclusiveMode | Chuyển sang exclusive mode khi làm việc ở 1C:Enterprise mode. |
| ExternalConnection | Dùng 1C:Enterprise qua COM connection. |
| Insert | Thêm object loại này. Kiểm tra ở mức object và mức DB. |
| InteractiveDelete | Xóa trực tiếp (interactive) |
| InteractiveDeleteMarked | Xóa interactive các object đã đánh dấu |
| InteractiveInsert | Thêm interactive object loại này |
| InteractiveMarkForDeletion | Đặt deletion mark interactive |
| InteractiveOpenExtDataProcessors | Mở external data processors bằng standard menu commands |
| InteractiveOpenExtReports | Mở external reports bằng standard menu commands |
| InteractivePosting | Post interactive document loại này |
| InteractivePostingRegular | Post interactive (bằng standard form commands) document ở regular (non-operational) mode |
| InteractiveUndoPosting | Hủy posting interactive |
| InteractiveUnmarkForDeletion | Bỏ deletion mark interactive |
| Posting | Post document |
| Read | Đọc dữ liệu từ infobase |
| StringInput | Cho phép dùng line input mode cho các object. |
| TotalsControl | Quản lý totals của accounting registers và accumulation registers — đặt kỳ tính totals và recalculation totals |
| UndoPosting | Hủy posting document |
| Update | Sửa object loại này. Kiểm tra ở mức object và mức DB. |
| Use | Dùng data processor, report, subsystem |
| View | Xem object (ví dụ trong list) |

### Access rights khi làm việc với form
- Quyền được cấu hình cho application objects. **Quyền mở form không được cấu hình, ngoại trừ common forms.**
- Khi mở form, kiểm tra quyền trên object là **main attribute** của form. Quyền trên object mà form trực thuộc trong cây metadata **không** được tính.
- Hệ quả: form của data processor không có main attribute → quyền trên data processor không ảnh hưởng việc mở form. Form trực thuộc catalog A nhưng main attribute là object catalog B → tính quyền trên catalog B.

### Roles
- **Role** là lớp trung gian giữa infobase users và access rights; mỗi role gom một tập quyền mà việc cấp chỉ có ý nghĩa khi đi cùng nhau (ví dụ role "Setting product prices": quyền cho register ProductPrices, catalog Products, document PriceSetup nếu register có recorder...).
- Cách đơn giản nhất: mở IB user card trong Designer mode và tick các role cần thiết. Cách này phổ quát, dùng tốt cho configuration đơn giản/ít user; role thường tương ứng chức danh (CEO, Purchasing Manager, Sales Manager, Storekeeper...).
- Khi configuration phức tạp, nhiều user, thay đổi nhân sự thường xuyên: role theo chức danh không phù hợp (cấp nhiều role lớn → thừa quyền).
- **"Granulated" roles**: role cấp quyền cho từng chức năng nhỏ (ví dụ ReadingSalesInvoice, AddChangePriceSetup, ReadCounterparties, SalesSubsystem). Nhưng với hệ thống lớn, mỗi user cần hàng chục/hàng trăm role → tốn nhiều thời gian quản lý.
- Vì vậy các standard configuration dựa trên **SSL (Standard Subsystems Library)** có thêm một lớp giữa IB user và roles: subsystem **"AccessManagement"**, gom roles thành **"Profiles"**.
  - Có thể tạo profile (ví dụ Accountant có quyền đặt giá) bằng cách gộp roles thay vì tạo role mới trong configuration (vốn cần exclusive access để cập nhật DB configuration).
  - Profiles tạo/sửa được trong Enterprise mode.
  - Sơ đồ: thực thể **"Access profile"** và **"Access group"**. Mỗi access profile gồm nhiều roles; mỗi user được gán một hoặc nhiều access groups; mỗi access group gắn với một access profile.

### Mandatory roles (role bắt buộc)
Configuration phải định nghĩa 3 role bắt buộc:
- **FullAccess** (synonym "Full access"): truy cập không giới hạn tới mọi dữ liệu "applied", nhưng **không** cấp quyền quản trị infobase nói chung (update configuration, làm việc trong designer...). Role này phải:
  - dùng độc lập được (gán cho user);
  - truy cập không giới hạn mọi dữ liệu, trừ quyền interactive deletion;
  - cho phép mọi thao tác quản trị dữ liệu (quản trị user, thiết lập chương trình, xóa object đã đánh dấu...);
  - gồm các quyền: Data administration, Active users, Event log, Exclusive mode, Thin client, Web client, Save user data, Output.
- **SystemAdministrator** (synonym "System administrator"): quyền bổ sung để quản trị infobase nói chung. Role này phải:
  - chỉ gán cho user **cùng với** FullAccess;
  - truy cập không giới hạn mọi dữ liệu (cho configuration phức tạp hoặc cloud infobase);
  - chứa mọi access rights tới objects (trừ quyền interactive delete);
  - gồm mọi quyền tới configuration root (đặc biệt Administration và Data Administration), trừ "Interactive opening of external reports" và "Interactive opening of external data processors".
- **InteractiveOpenExtReportsAndDataProcessors** (synonym "Open external reports and data processors interactively"): quyền mở external reports/data processors qua menu File - Open. Gồm quyền tới configuration root "Interactive opening of external reports" và "Interactive opening of external data processors".
- Ví dụ trong configuration Trade Management: quyền "update configuration" bị tắt cho SystemAdministrator vì có role riêng cho quyền này.
- Ba role trên phải được đặt làm **default roles** của configuration (property **DefaultRoles**). Default roles là role gán cho mỗi user khởi động infobase khi infobase chưa có user nào.
- Nếu cần thiết lập general rights (như "Thin client", "Thick client", "Interactive opening of external data processors"...), configuration phải định nghĩa role riêng để cấp; các role này không dùng độc lập mà gán cùng role khác.
- Configuration phải hoạt động được cả khi user có và không có các role này.
- Các quyền sau **không được đặt trong bất kỳ role nào**, kể cả FullAccess và SystemAdministrator (trừ trường hợp có lý do chính đáng):
  - Interactive delete
  - Interactive deletion of predefined objects
  - Interactive deletion mark on predefined objects
  - Interactive removal of deletion mark from predefined objects
  - Interactive deletion of marked predefined objects
- Khuyến nghị chỉ để quyền delete trong FullAccess và SystemAdministrator. Nếu cần cho user không có full rights xóa object → thêm role riêng **DeleteMarkedObjects** (không dùng độc lập, gán cùng role khác).

### Thiết lập quyền cho object mới và attribute
- Phải tuân thủ cách đặt quyền sao cho không xuất hiện role cấp quyền tới field của object mà không cấp quyền tới chính object (tránh việc user vô tình có quyền tới mọi attribute khi được gán role đó).
- Checkbox **"Set rights for new objects"** chỉ tick cho role **FullAccess**.
- Khi thêm role mới: tick **"Set rights for attributes and tabular sections by default"**, bỏ tick **"General rights for subordinate objects"**.
- Nếu cần role chỉ cấp quyền cho field của metadata object (View/Edit cho attributes, tabular sections, dimensions, commands... mà không có quyền trên object): trước đó trong role phải tick "General rights for subordinate objects", bỏ tick "Set rights for attributes and tabular sections by default" và xóa quyền trên mọi attributes và tabular sections.
- Khi thêm object mới hoặc field mới vào configuration → phải cấu hình quyền cho chúng trong các role tương ứng.

### Kiểm tra user có role
- Có thể dùng role "flag": role không cấp quyền nào, chỉ là marker cho biết user có quyền nào đó (ví dụ duyệt hợp đồng).
- Dùng method **IsInRole()**.

### Thực hành tạo role (theo bài)
- Role theo chức danh: "CEO", "PurchaseManager", "SalesManager", "Storekeeper", "HRM".
- Tạo role bắt buộc trước: SystemAdministrator (cấp quyền configuration root), FullAccess. Vì luôn dùng cùng nhau, chỉ để quyền tới objects cho FullAccess; SystemAdministrator chỉ có quyền tới platform mechanisms.
- FullAccess: mọi quyền tới mọi object trừ "Interactive delete" và các quyền liệt kê ở mục Mandatory roles.
- InteractiveOpenExtReportsAndDataProcessors: chỉ 2 quyền tới platform mechanisms.
- Khi tạo role mới, đã có sẵn các quyền: "Thin client", "Web client", "Mobile client", mọi loại main window modes, "Analytics system client" (sản phẩm BI riêng của 1C), "Save user data", "Output". Khuyến nghị giữ nguyên cho role theo chức danh.
- Với atomic roles (role nhỏ cho từng chức năng): bỏ tick mọi quyền tới platform mechanisms, trừ khi role đó chính là để cấp các quyền này (ví dụ role "ThinClient").
- Role SalesManager:
  - Documents "Sales invoice", "Return of goods from customer": mọi quyền trừ deletion và quyền data history.
  - Document "Purchase invoice": chỉ "Read", "View", "String input".
  - Accumulation registers liên quan bán hàng/di chuyển hàng: "Read", "View" (nếu không user không lập được report).
  - Reports và data processors chỉ có 2 quyền: "Use" và "View".
  - Price register: "Read" và "Update" (vì data processor ghi giá), cộng "View" và "Edit" (vì sales manager được đổi giá ngoài data processor).
  - **Bắt buộc** cấp "View" cho subsystems user cần truy cập — nếu không, user có quyền tới catalog/document nhưng không thấy trong interface.
  - Commands và common forms chỉ có một quyền: "View".
  - Constants: cần đọc giá trị → "Read"; cần thấy giá trị trên form → thêm "View".
- Khuyến nghị test truy cập dưới từng role (hoặc access profile).
- Tạo user Administrator (3 role chính) và User_Sales (role "SalesManager"). Khi infobase có ít nhất một user, platform yêu cầu authentication khi khởi động.
- Với user full access: menu "More" của form object tham chiếu không còn nút "Delete" (xóa trực tiếp record trong DB, không kiểm tra referential integrity) vì đã tắt "Interactive delete" trong FullAccess.

### Điều tra lỗi Access violation
- Tìm sự kiện lỗi truy cập trong **event log** (user có quyền quản trị xem được ở cả Designer và Enterprise).
- Record loại "Error" có record vi phạm quyền đứng trước; cột **Metadata** chỉ metadata object (ví dụ information register "Companies responsible persons"), cột **Data** chỉ quyền còn thiếu (ví dụ "Read"); dòng lỗi cho biết code gọi từ đâu (form catalog Companies).
- Lỗi khó điều tra khi xảy ra trong khối Try mà exception không được xử lý đủ chi tiết.
- Hai cách sửa:
  1. Cấp quyền còn thiếu cho role ("Read" là đủ nếu chỉ đọc bằng code).
  2. Tạm tắt giới hạn quyền — chạy code ở **privileged mode**.

### Privileged mode
- Flag **"Privileged"** của common module: mọi code trong module chạy không giới hạn quyền; module chỉ có thể là server-side.
- Method **SetPrivilegedMode(Boolean)**: bật (True) / tắt (False) privileged mode cho một đoạn code.
- Nếu không tắt tường minh, privileged mode tự tắt khi procedure/function bật nó kết thúc.
- Khuyến nghị **luôn tắt tường minh** (khi làm việc nhóm, người khác có thể thêm code vào procedure và code đó chạy không giới hạn quyền).
- Sai: bật privileged mode trước khi gọi một function (bên trong function có thể có code cần kiểm tra quyền). Đúng: chỉ bật ngay trước đoạn code cần bỏ kiểm tra quyền.
- Nếu bật privileged mode để chạy code sau toán tử Return thì không cần tắt tường minh sau đó (code sau Return không chạy).
- Ở client-server mode, privileged mode chỉ bật được trên server; gọi trên client không có tác dụng.
- Privileged mode không hiệu quả khi hiển thị cho user dữ liệu về object mà user không có quyền "View" — user sẽ thấy link tới object không tồn tại ("Object not found").
- Trong bài: cuối cùng vẫn cấp quyền "Read" (và "View") register responsible persons cho SalesManager và các role khác, xóa code privileged mode. Quyền ghi vào register này cấp cho role có quyền sửa companies (vì form module company ghi vào register khi write).

### User authentication
- Debug dưới user khác (user không có password): Tools - Options → tab **1C:Enterprise startup** → vùng "User" chọn setting "Name".
  - Để trống: mỗi lần khởi động platform hỏi chọn user.
  - Chọn user cụ thể: không có password → khởi động ngay; có password → mở cửa sổ authentication với tên đã chọn sẵn.
- Ẩn user khỏi danh sách chọn: bỏ tick **"Show in the selection list"** trong cửa sổ user.
- **OS authentication**: gán OS user cho 1C user; khi OS user đó đăng nhập, platform đăng nhập dưới 1C user tương ứng mà không hiện cửa sổ authentication.
- Nếu user không có cả 1C:Enterprise authentication lẫn OS authentication → biểu tượng dấu hỏi trong danh sách user. Platform còn có các phương thức authentication khác: OpenID, OpenID Connect, access token.

### Unsafe operation protection
- Cơ chế cảnh báo khi thực hiện thao tác tiềm ẩn nguy hiểm. Các thao tác này gồm:
  - Chạy external data processor (report) hoặc configuration extension.
  - Chạy hoặc cập nhật configuration/extension.
  - Truy cập từ external data processor (report) hoặc extension tới: load external data processor (report) khác; thực thi lệnh hệ điều hành; quản lý user; load external component.
- Flag **"Unsafe operation protection"** trong user properties, bật mặc định khi tạo user. Khuyến nghị không bỏ tick.

## Cú pháp & ví dụ code

Kiểm tra quyền từ built-in language:
```bsl
&AtServer

Procedure OnCreateAtServer(Cancel, StandardProcessing)

    If AccessRight("InteractiveDelete", Metadata.Documents.Document1) Then

        Items.ButtonDeleteDocument1.Enabled = True;

    Else

        Items.ButtonDeleteDocument1.Enabled = False;

    EndIf;

EndProcedure
```

Kiểm tra user có role:
```bsl
If IsInRole("DocumentApproval") Then
```

Method bật/tắt privileged mode:
```bsl
SetPrivilegedMode(Boolean)
```

[ghi chú ngoài nguồn] Các ví dụ privileged mode (tắt ngầm định, tắt tường minh, dùng sai/đúng trước lời gọi function) trong tài liệu gốc là ảnh chụp màn hình, không có code dạng văn bản để chép nguyên văn. Nhánh lesson/20-theory cũng không có lời gọi `SetPrivilegedMode` (đã ở trạng thái cuối bài: cấp quyền Read thay cho privileged mode; common module `CommonServerPrivileged` có flag Privileged nhưng trống) nên các ví dụ này vẫn chưa có code; phần điều tra Access violation, role bắt buộc và thiết lập quyền → đã bổ sung (nhánh lesson/20-theory).

## Thuộc tính/thiết lập quan trọng trong Designer
- **DefaultRoles** (property của configuration) — đặt FullAccess, SystemAdministrator, InteractiveOpenExtReportsAndDataProcessors.
- Role checkboxes: **"Set rights for new objects"** (chỉ FullAccess), **"Set rights for attributes and tabular sections by default"** (tick khi tạo role mới), **"General rights for subordinate objects"** (bỏ tick khi tạo role mới).
- Common module flag **"Privileged"**.
- User properties: **"Show in the selection list"**, **"Unsafe operation protection"**, OS authentication / 1C:Enterprise authentication.
- Tools - Options → tab **1C:Enterprise startup** → "User" → "Name".
- Event log: cột **Metadata**, **Data**.

## Lỗi thường gặp / lưu ý
- Thiếu quyền "View" → list form/object form không mở, hiện thông báo vi phạm quyền.
- Thao tác không được phép → "Access violation!", mọi transaction bị hủy.
- Kiểm tra interactive rights có thể bị vượt qua; non-interactive thì không. Khi thêm command vào form phải tự kiểm tra interactive rights.
- Không thể cho phép interactive right khi cấm non-interactive tương ứng (ví dụ không thể cho "Interactive delete" mà cấm "Delete").
- Thiếu "Read" → mất mọi quyền khác trên object.
- Quên cấp "View" cho subsystem → user không thấy object trong interface dù có quyền.
- Form không có main attribute → quyền trên data processor không ngăn mở form; quyền được xác định bởi main attribute, không phải vị trí form trong cây metadata.
- Lỗi đọc register trong OnCreateAtServer khi role thiếu "Read" → access violation khi mở form (ví dụ register "Companies responsible persons").
- Bật privileged mode trước khi gọi function là sai; quên tắt privileged mode tường minh là rủi ro khi làm việc nhóm.
- Privileged mode trên client không có tác dụng.
- Hiển thị dữ liệu đọc ở privileged mode cho user không có "View" → "Object not found".
- Không đặt "Interactive delete" và các quyền xóa predefined trong bất kỳ role nào.

## Điểm cần nhớ
- 1C: mọi thứ không được cho phép đều bị cấm; access right là cơ chế duy nhất kiểm soát truy cập.
- 4 basic rights Insert / Read / Update / Delete là đủ để xây dựng giải pháp an toàn; "Read" là quyền then chốt.
- Interactive rights phụ thuộc non-interactive; non-interactive không thể bị vượt qua.
- Quyền mở form xác định bởi main attribute (trừ common forms).
- 3 mandatory roles: FullAccess, SystemAdministrator, InteractiveOpenExtReportsAndDataProcessors — đặt làm DefaultRoles.
- Không cấp "Interactive delete" cho role nào; dùng role DeleteMarkedObjects nếu cần cho user thường.
- SSL có subsystem AccessManagement với Access profile / Access group, cấu hình được ở Enterprise mode.
- SetPrivilegedMode(True/False): chỉ bao quanh đúng đoạn code cần, luôn tắt tường minh, chỉ có tác dụng trên server.

## Thẻ gợi ý bài thực hành (Practice 20)

Các thẻ dưới đây đi theo thứ tự đề trong 20. Practice. Bài này chủ yếu là thiết lập role và user trong Designer, gần như không phải viết code. Mỗi thẻ chỉ có gợi ý, không có lời giải: bạn tự làm rồi kiểm tra trong Enterprise mode dưới từng user.

### Bài tập 1 — Ba role bắt buộc và user Administrator

- **Đề bài (tóm tắt):** Tạo 3 role bắt buộc (full rights, quản trị, mở external reports/data processors), đưa cả 3 vào default roles của configuration, tạo user Administrator có cả 3 role.
- **Gợi ý 1 — Hướng đi:** Xem mục "Mandatory roles" và "Thực hành tạo role". Ba role này luôn dùng cùng nhau, nên quyền tới objects chỉ đặt trong role full access; role quản trị chỉ chứa quyền tới configuration root; role thứ ba chỉ có 2 quyền mở external reports/data processors.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Roles: FullAccess (đề gọi là FullRights), SystemAdministrator (đề gọi là Administrator), InteractiveOpenExtReportsAndDataProcessors.
  - Checkbox của role: "Set rights for new objects" chỉ tick ở FullAccess; "Set rights for attributes and tabular sections by default" tick; "General rights for subordinate objects" bỏ tick.
  - Property **DefaultRoles** của configuration root.
  - Administration → Users (Designer) để tạo user.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo role full access: tick mọi quyền tới mọi object, rồi bỏ "Interactive delete" và các quyền xóa/đánh dấu xóa predefined.
  2. Ở configuration root của role full access: bỏ Administration, cập nhật DB configuration và 2 quyền mở external reports/data processors.
  3. Tạo role quản trị: chỉ tick quyền ở configuration root (Administration, Data administration...), trừ 2 quyền mở external.
  4. Tạo role thứ ba với đúng 2 quyền `InteractiveOpenExtDataProcessors`, `InteractiveOpenExtReports`.
  5. Đưa cả 3 vào DefaultRoles, tạo user Administrator và tick 3 role.
  - Mẹo của đề: tick quyền "từ cuối lên đầu". Ví dụ tick "String input" thì "Read" và "View" tự bật.
- **Lỗi hay gặp:**
  - Quên DefaultRoles. [ghi chú ngoài nguồn] Trong dump cấu hình của khóa (cả nhánh theory) property DefaultRoles đang trống, đừng lấy đó làm mẫu.
  - Để "Set rights for new objects" bật ở role khác ngoài full access.
  - Khi infobase đã có ít nhất một user, platform bắt đăng nhập. Hãy tạo user Administrator **trước** khi thử các user khác, kẻo không còn ai có quyền quản trị.
- **Tự kiểm tra:** Khởi động Enterprise dưới Administrator: mọi section hiện đủ, menu "More" của form catalog **không** còn nút "Delete" (xóa trực tiếp), File - Open mở được external data processor.

### Bài tập 2 — Đổi tên configuration

- **Đề bài (tóm tắt):** Đổi property Name của configuration root thành tên phù hợp với giải pháp của bạn.
- **Gợi ý 1 — Hướng đi:** Name của root là tên metadata, khác synonym. Role lưu quyền tới root theo object `Configuration.<Name>`, nên hãy làm bước này rồi mới mở lại các role để kiểm tra quyền ở root.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Properties palette của root configuration → Name (và Synonym hiển thị cho user).
- **Gợi ý 3 — Khung bài làm:**
  1. Mở properties của root, đổi Name (không dấu cách) và Synonym.
  2. Update DB configuration.
  3. Mở lại một role, kiểm tra cây quyền ở root đã mang tên mới.
- **Lỗi hay gặp:**
  - Chỉ đổi Synonym mà quên Name (đề yêu cầu Name).
  - Dùng dấu cách hoặc ký tự không hợp lệ trong Name.
- **Tự kiểm tra:** Tiêu đề cửa sổ Enterprise hiện synonym mới. Trong role, nút cấu hình quyền ở root hiển thị đúng tên mới.

### Bài tập 3 — Role theo chức danh: CEO, PurchaseManager, SalesManager, Storekeeper, MasterDataSpecialist

- **Đề bài (tóm tắt):** Tạo 5 role theo chức danh, mỗi role làm việc với subsystem phù hợp. CEO có quyền tới objects như FullAccess (trừ "Totals control") nhưng không có quyền quản trị ở root. MasterDataSpecialist tạo/sửa mọi master data. Các role khác được sửa master data theo nghiệp vụ.
- **Gợi ý 1 — Hướng đi:** Xem "Thực hành tạo role" (ví dụ SalesManager của bài lý thuyết) và "Access rights khi làm việc với form". Quyền "View" trên subsystem là bắt buộc thì user mới thấy object trong interface. Report/data processor chỉ cần "Use" + "View".
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - 5 role mới, checkbox như khi tạo role mới (xem bài 1).
  - Với CEO: quyền "Advanced tools"/chế độ technician ở root được phép (đề gợi ý), nhưng không có Administration.
  - Register giá: role nào ghi giá (qua data processor) cần "Read" + "Update"; role được sửa giá trên form cần thêm "View" + "Edit".
  - Mẹo của đề: làm xong một role "khung" có các quyền Read/View chung, rồi **copy** nó thành các role khác và chỉ sửa phần Insert/Update.
- **Gợi ý 3 — Khung bài làm:**
  1. Lập bảng giấy: hàng là object (catalog, document, register, report, data processor, subsystem), cột là 5 role, ô ghi R/V hay I/U/E.
  2. Tạo role khung với quyền đọc chung (Read, View, String input cho catalog/document, Read/View cho register, Use/View cho report).
  3. Copy thành 5 role, thêm Insert/Update/Interactive insert/Edit theo bảng (PurchaseManager tạo được product, SalesManager tạo được counterparty và contract...).
  4. Cấp "View" cho subsystem tương ứng của từng role.
- **Lỗi hay gặp:**
  - Quên "View" cho subsystem: user có quyền nhưng không thấy gì trong interface.
  - Cấp quyền sửa catalog mà quên các information register mà form của catalog đó ghi vào khi write (ví dụ register responsible persons của Companies trong bài lý thuyết).
  - Cho CEO "Totals control" hoặc quyền quản trị ở root.
- **Tự kiểm tra:** Đăng nhập lần lượt từng user: section hiển thị đúng chức danh, tạo được đúng loại master data cho phép, không tạo được loại không cho phép.

### Bài tập 4 — Characteristics cho mọi user, quyền xóa chỉ cho CEO, constants chỉ CEO/FullAccess

- **Đề bài (tóm tắt):** Mọi role được tạo characteristic mới (chart of characteristic types "Additional attributes and properties") và giá trị characteristic (catalog "ObjectsPropertiesValues"). Chỉ CEO có quyền xóa object. Chỉ CEO và FullAccess được sửa constants.
- **Gợi ý 1 — Hướng đi:** Quyền "Delete" là non-interactive (xóa bằng code, ví dụ khi xóa object đã đánh dấu), khác "Interactive delete". Constant: "Read" để đọc, "View" để thấy, "Update"/"Edit" để sửa.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - `ChartOfCharacteristicTypes.AdditionalAttributesAndProperties`, `Catalog.ObjectsPropertiesValues`: Insert/Update/Interactive insert/Edit cho mọi role.
  - Quyền "Delete" (không phải Interactive delete) chỉ ở CEO (ngoài FullAccess).
  - Constants: các role thường chỉ Read (+View nếu cần thấy trên form).
- **Gợi ý 3 — Khung bài làm:**
  1. Ở role khung (nếu chưa copy) hoặc lần lượt 5 role, mở 2 object characteristics và cấp quyền tạo/sửa.
  2. Đi qua mọi object trong CEO, tick "Delete" nhưng **không** tick "Interactive delete".
  3. Rà các role còn lại: không có "Delete" ở object nào.
  4. Rà constants ở 4 role không phải CEO: bỏ Update/Edit.
- **Lỗi hay gặp:**
  - Nhầm "Delete" với "Interactive delete" (đề cấm cái thứ hai ở mọi role, xem bài 5).
  - Functional option dựa trên constant bị ẩn sai với user không có "Read" trên constant. Xem bài 7.
- **Tự kiểm tra:** User không phải CEO: tạo được characteristic mới, field constant trên form chỉ đọc. User CEO: dùng được "Delete marked objects".

### Bài tập 5 — Không role nào có Interactive delete và quyền xóa predefined

- **Đề bài (tóm tắt):** Không role nào được có "Interactive delete" và các quyền interactive liên quan tới xóa predefined objects.
- **Gợi ý 1 — Hướng đi:** Đúng danh sách 5 quyền trong mục "Mandatory roles" (kể cả FullAccess và SystemAdministrator).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Trong mỗi role, các quyền Interactive delete, Interactive deletion of predefined objects, Interactive deletion mark / removal of deletion mark / deletion of marked predefined objects (chỉ xuất hiện ở object có predefined data, ví dụ catalog Users).
- **Gợi ý 3 — Khung bài làm:**
  1. Với từng role, lọc theo từng loại object (catalog, document, chart...).
  2. Bỏ tick 5 quyền trên ở mọi object.
  3. Ghi chú lại để khi thêm object mới vào configuration thì nhớ bỏ tick (đặc biệt ở FullAccess vì "Set rights for new objects" bật).
- **Lỗi hay gặp:**
  - Bỏ ở object thường nhưng quên object có predefined data.
  - Bỏ nhầm quyền "Interactive set deletion mark" thường: đánh dấu xóa vẫn phải được phép.
- **Tự kiểm tra:** Dưới mọi user, menu "More" của form object không có nút "Delete". Đặt deletion mark vẫn làm được.

### Bài tập 6 — Không cấp Update/Edit cho accumulation register, post ở privileged mode

- **Đề bài (tóm tắt):** Không cấp quyền update/edit accumulation registers. Thay vào đó document phải post và unpost ở privileged mode (bật ở tab "Rights" của document nếu chưa bật).
- **Gợi ý 1 — Hướng đi:** Xem "Privileged mode". Posting handler ghi `RegisterRecords`; nếu post ở privileged mode thì platform không kiểm tra quyền của user trên register khi ghi. User chỉ cần Read/View trên register để xem report và số dư.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Tab **Rights** của mỗi document có posting: "Post in privileged mode", "Unpost in privileged mode".
  - Trong role: accumulation registers chỉ "Read" + "View".
- **Gợi ý 3 — Khung bài làm:**
  1. Liệt kê mọi document có posting trong configuration (mua, bán, trả hàng, chuyển kho, đặt giá...).
  2. Mở tab Rights từng document, kiểm tra 2 checkbox privileged mode.
  3. Trong mọi role nghiệp vụ, để accumulation register chỉ Read/View.
- **Lỗi hay gặp:**
  - Sót một document (ví dụ document chuyển kho hoặc đặt giá): user post sẽ bị "Access violation!".
  - Đọc số dư trong posting (kiểm tra tồn) cũng chạy trong privileged mode, nhưng code đọc register **ở form** thì không, nên role vẫn cần "Read".
  - [ghi chú ngoài nguồn] Đề nói CEO "same rights as FullAccess", nên khi chấm có thể chấp nhận CEO có Update/Edit trên register. Hãy tự quyết định và ghi rõ lý do. Mặc định nên theo yêu cầu "không cấp update/edit".
- **Tự kiểm tra:** Đăng nhập Storekeeper/SalesManager, post và unpost document thành công. Mở trực tiếp list của accumulation register: không sửa được record.

### Bài tập 7 — Tạo user cho từng role và test toàn bộ ứng dụng

- **Đề bài (tóm tắt):** Tạo ít nhất một user cho mỗi role chức danh, test mọi chức năng (kể cả report và data processor). Thiếu quyền thì sửa role hoặc dùng privileged mode để lấy dữ liệu.
- **Gợi ý 1 — Hướng đi:** Xem "Điều tra lỗi Access violation" và "Privileged mode". Event log cho biết metadata object và quyền thiếu. Chọn: cấp quyền thiếu (thường chỉ "Read") hoặc bọc đúng đoạn đọc dữ liệu bằng privileged mode ở server.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Tools - Options → tab 1C:Enterprise startup → "User" để debug dưới user khác.
  - Event log (cột Metadata, Data).
  - Server-side: `SetPrivilegedMode(True/False)` hoặc common module có flag Privileged.
  - Functional option có property "Privileged get mode": user không cần quyền đọc constant mà interface vẫn ẩn/hiện đúng.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo user cho từng role (không password cho dễ test), bỏ "Show in the selection list" nếu muốn ẩn user.
  2. Với mỗi user: mở mọi section, tạo/post document, chạy từng report và data processor.
  3. Gặp lỗi → mở event log bằng Administrator, đọc Metadata + Data.
  4. Quyết định: thêm quyền vào role, hoặc dùng khung privileged mode dưới đây cho đoạn chỉ đọc dữ liệu.
  ```bsl
  &AtServer
  Function ___(___)
  	// bật privileged mode NGAY trước đoạn đọc dữ liệu, không bật trước lời gọi function khác
  	___
  	// đoạn đọc dữ liệu user không có quyền
  	___
  	// tắt privileged mode tường minh
  	___
  	Return ___;
  EndFunction
  ```
- **Lỗi hay gặp:**
  - Bật privileged mode ở client: không có tác dụng.
  - Hiển thị dữ liệu đọc bằng privileged mode cho user không có "View" trên object đó → "Object not found".
  - Quên test report (thiếu Read trên register) và data processor (thiếu Use).
- **Tự kiểm tra:** Mỗi user đi hết kịch bản nghiệp vụ của mình mà không có "Access violation!". Event log không còn record lỗi quyền.

### Bài tập 8 — Flag "Modifies saved data" cho nút "Fill by sales document"

- **Đề bài (tóm tắt):** Nút "Fill by sales document" của document "Return of goods from customer" vẫn bấm được khi user không có quyền sửa. Sửa bằng cách bật flag "Modifies saved data" cho form command.
- **Gợi ý 1 — Hướng đi:** Xem "Kiểm tra interactive rights có thể bị vượt qua": khi tự thêm command vào form, developer phải lo quyền. Flag này cho platform biết command sửa dữ liệu, nên platform tự khóa nút khi user không có quyền Edit.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form của document ReturnOfGoodsFromCustomer → tab Commands → command `FillBySalesDocument` → property **Modifies saved data**. Rà thêm các form command khác có sửa dữ liệu (ví dụ command điền hàng theo số dư ở form chuyển kho).
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo/dùng user chỉ có quyền đọc document trả hàng.
  2. Mở document dưới user đó, xác nhận nút vẫn bấm được (lỗi).
  3. Bật flag cho command, update DB configuration.
  4. Rà mọi form command khác có thay đổi dữ liệu và bật flag tương tự.
- **Lỗi hay gặp:**
  - Bật flag ở **button** thay vì ở **command**.
  - [ghi chú ngoài nguồn] Trong dump cấu hình của khóa, command `FillBySalesDocument` vẫn chưa có flag này (trạng thái trước khi sửa mà đề mô tả), nên đừng lấy dump làm bằng chứng là đã đúng.
- **Tự kiểm tra:** Dưới user chỉ đọc, nút "Fill by sales document" bị mờ. Dưới SalesManager, nút vẫn hoạt động.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/20-theory)

### Điều tra Access violation: code đọc register CompaniesResponsiblePersons và quyền Read/View cấp cho SalesManager

Nguồn: nhánh lesson/20-theory — cf/Catalogs/Companies/Forms/ItemForm/Ext/Form/Module.bsl; cf/Roles/SalesManager/Ext/Rights.xml

Form module của catalog Companies (chỗ gây lỗi "Read" trên information register khi mở company dưới User_Sales):

```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ResponsiblePersons = ResponsiblePersons(CurrentSessionDate(), Object.Ref);
	
	FillPropertyValues(ThisObject, ResponsiblePersons);
	
EndProcedure
// ...
&AtServerNoContext
Function ResponsiblePersons(Period, Company)

	Filter = New Structure("Company", Company);
	
	Return InformationRegisters.CompaniesResponsiblePersons.GetLast(
		Period,
		Filter
	);
	
EndFunction
```

Quyền được cấp trong role SalesManager (cách sửa 1 của bài):

```xml
	<object>
		<name>InformationRegister.CompaniesResponsiblePersons</name>
		<right>
			<name>Read</name>
			<value>true</value>
		</right>
		<right>
			<name>View</name>
			<value>true</value>
		</right>
	</object>
```

- Đúng ví dụ trong bài: event log chỉ metadata object "Companies responsible persons", quyền thiếu "Read", lời gọi xuất phát từ form catalog Companies (`OnCreateAtServer` → `GetLast()` của register).
- Nhánh ở trạng thái **cuối** của bài: đã cấp "Read" + "View" cho SalesManager và không còn code privileged mode trong form.
- Quyền ghi register (`RecordManager.Write(True)` trong `UpdateResponsiblePersons`, gọi từ `OnWriteAtServer`) chỉ cần cho role được sửa companies — SalesManager không có Update trên catalog Companies nên không cần.

### Common module có flag "Privileged"

Nguồn: nhánh lesson/20-theory — cf/CommonModules/CommonServerPrivileged.xml

```xml
			<Global>false</Global>
			<ClientManagedApplication>false</ClientManagedApplication>
			<Server>true</Server>
			<ExternalConnection>false</ExternalConnection>
			<ClientOrdinaryApplication>false</ClientOrdinaryApplication>
			<ServerCall>false</ServerCall>
			<Privileged>true</Privileged>
			<ReturnValuesReuse>DontUse</ReturnValuesReuse>
```

- Flag `Privileged` = true: mọi code trong module chạy không kiểm tra quyền; module chỉ có thể là server-side (`Server` = true, client flags = false).
- Trong nhánh module này còn trống — không có lời gọi `SetPrivilegedMode()` nào trong code, nên các ví dụ privileged mode bằng code của bài vẫn chỉ có trong ảnh.

### "Post in privileged mode" / "Unpost in privileged mode" cho document PersonnelChange

Nguồn: nhánh lesson/20-theory — cf/Documents/PersonnelChange.xml

```xml
			<Posting>Allow</Posting>
			<RealTimePosting>Allow</RealTimePosting>
			<RegisterRecordsDeletion>AutoDeleteOnUnpost</RegisterRecordsDeletion>
			<RegisterRecordsWritingOnPost>WriteSelected</RegisterRecordsWritingOnPost>
			<SequenceFilling>AutoFill</SequenceFilling>
			<RegisterRecords>
				<xr:Item xsi:type="xr:MDObjectRef">InformationRegister.Employees</xr:Item>
			</RegisterRecords>
			<PostInPrivilegedMode>true</PostInPrivilegedMode>
			<UnpostInPrivilegedMode>true</UnpostInPrivilegedMode>
```

- Cả 5 document của nhánh (SalesInvoice, ReturnOfGoodsFromCustomer, PurchaseInvoice, PersonnelChange, BonusesFinesOfEmployeesRegistration) bật hai property này.
- Nhờ vậy role SalesManager chỉ cần "Read"/"View" trên accumulation register mà vẫn post được document.

### Role FullAccess: "Set rights for new objects", không có Interactive delete và quyền quản trị configuration

Nguồn: nhánh lesson/20-theory — cf/Roles/FullAccess/Ext/Rights.xml

```xml
<Rights xmlns="http://v8.1c.ru/8.2/roles" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Rights" version="2.19">
	<setForNewObjects>true</setForNewObjects>
	<setForAttributesByDefault>true</setForAttributesByDefault>
	<independentRightsOfChildObjects>false</independentRightsOfChildObjects>
	<object>
		<name>Catalog.Companies</name>
		<right>
			<name>InteractiveDelete</name>
			<value>false</value>
		</right>
		<right>
<!-- ... -->
	<object>
		<name>Configuration.Configuration</name>
		<right>
			<name>Administration</name>
			<value>false</value>
		</right>
		<right>
			<name>UpdateDataBaseConfiguration</name>
			<value>false</value>
		</right>
		<right>
			<name>ConfigurationExtensionsAdministration</name>
			<value>false</value>
		</right>
		<right>
			<name>InteractiveOpenExtDataProcessors</name>
			<value>false</value>
		</right>
		<right>
			<name>InteractiveOpenExtReports</name>
			<value>false</value>
		</right>
	</object>
```

- `setForNewObjects` = true chỉ ở FullAccess (role SalesManager và các role khác = false), `setForAttributesByDefault` = true, `independentRightsOfChildObjects` = false — đúng khuyến nghị "Thiết lập quyền cho object mới và attribute".
- `InteractiveDelete` = false cho từng object (ví dụ Catalog.Companies); với catalog có predefined data (Users) role còn tắt thêm các quyền interactive trên predefined data (cùng file, dòng 423-445) — đúng danh sách "không được đặt trong bất kỳ role nào".
- Ở configuration root, FullAccess tắt Administration, UpdateDataBaseConfiguration, ConfigurationExtensionsAdministration và hai quyền mở external reports/data processors — những quyền này nằm ở role Administration và InteractiveOpenExtReportsAndDataProcessors.

### Role bắt buộc InteractiveOpenExtReportsAndDataProcessors

Nguồn: nhánh lesson/20-theory — cf/Roles/InteractiveOpenExtReportsAndDataProcessors/Ext/Rights.xml

```xml
	<setForNewObjects>false</setForNewObjects>
	<setForAttributesByDefault>true</setForAttributesByDefault>
	<independentRightsOfChildObjects>false</independentRightsOfChildObjects>
	<object>
		<name>Configuration.Configuration</name>
		<right>
			<name>InteractiveOpenExtDataProcessors</name>
			<value>true</value>
		</right>
		<right>
			<name>InteractiveOpenExtReports</name>
			<value>true</value>
		</right>
	</object>
```

- Chỉ hai quyền tới configuration root: `InteractiveOpenExtDataProcessors`, `InteractiveOpenExtReports` — đúng mô tả role bắt buộc thứ ba.
- [ghi chú ngoài nguồn] Trong nhánh, role quản trị tên `Administration` (không phải `SystemAdministrator`) và property DefaultRoles của configuration đang trống.

### Role SalesManager: Purchase invoice chỉ đọc, register giá Read/Update/View/Edit, data processor Use/View

Nguồn: nhánh lesson/20-theory — cf/Roles/SalesManager/Ext/Rights.xml

```xml
	<object>
		<name>Document.PurchaseInvoice</name>
		<right>
			<name>Read</name>
			<value>true</value>
		</right>
		<right>
			<name>View</name>
			<value>true</value>
		</right>
		<right>
			<name>InputByString</name>
			<value>true</value>
		</right>
	</object>
<!-- ... -->
		<name>InformationRegister.ProductPrices</name>
		<right>
			<name>Read</name>
			<value>true</value>
		</right>
		<right>
			<name>Update</name>
			<value>true</value>
		</right>
		<right>
			<name>View</name>
			<value>true</value>
		</right>
		<right>
			<name>Edit</name>
			<value>true</value>
		</right>
	</object>
	<object>
```

- Document "Purchase invoice": chỉ "Read", "View", "String input" (`InputByString`) như bài yêu cầu.
- Register giá `ProductPrices`: "Read" + "Update" (data processor ghi giá) và "View" + "Edit" (sales manager được đổi giá ngoài data processor).
- Data processor `ImportPricesFromExcel` chỉ có "Use" và "View" (cùng file, cuối danh sách); role cũng có "View" cho `Subsystem.Sales` và `Subsystem.Sales.Subsystem.Prices` (bắt buộc để thấy object trong interface).

## Video tham khảo

Video bài giảng trên YouTube có phạm vi trùng với bài này. Khi dẫn cho người học, nói "Bạn có thể tham khảo thêm về <chủ đề> của khóa tại đây: [<tên video>](link)" — không nói "khóa cũ/Junior", không dùng mã JC (mã JC trong danh sách chỉ để tra nội bộ). Quy ước đầy đủ: `references/video-junior-course.md`.

Không có video tương ứng — chỉ dẫn tài liệu Theory/Practice của bài.
