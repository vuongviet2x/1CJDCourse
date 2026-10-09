# Chuẩn phát triển của 1C (1C:Enterprise Development Standards) — bản rút gọn cho Junior

> **Khi nào đọc file này:** khi review code và muốn dẫn **chuẩn chính thức** của 1C cho một nhận xét; khi người dùng hỏi "chuẩn của 1C nói gì về…", "viết thế này có đúng chuẩn không"; khi intern / đối tác chuẩn bị code cho dự án thật. Quy tắc thực hành có mã (P1, Q1, F2…) và mẫu trả lời: `code-review/review-code.md`.
>
> **Nguồn:** bộ chuẩn phát triển của 1C (its.1c.ru/db/v8std, bản tiếng Anh trên **kb.1ci.com** → 1C:Enterprise Development Standards), qua bản biên tập mở **v8std.ru** (repo `zeegin/v8std`, giấy phép **CC0**). Bảng dưới là **tóm tắt tiếng Việt của người soạn** cho khoảng 50 chuẩn cốt lõi trên tổng số khoảng 320; mã `#stdNNN` dùng để tra bản đầy đủ: `https://v8std.ru/std/NNN/` (tiếng Nga) hoặc tìm theo tên trên kb.1ci.com (tiếng Anh). Khảo sát 10/2026. Ví dụ code trong các chuẩn gốc viết bằng cú pháp tiếng Nga — khi giải thích, chuyển sang cú pháp tiếng Anh (`code-review/thuat-ngu-ru-en.md`).
>
> Cách dùng khi trả lời: nêu nhận xét bằng lời của mình + "(chuẩn 1C #stdNNN)"; không chép nguyên văn chuẩn. Với người mới (lộ trình J), chỉ dẫn chuẩn khi thật cần — ưu tiên giải thích bằng hậu quả nghiệp vụ.

## 1. Posting, register, khóa, transaction

| Chuẩn | Nội dung chính (tóm tắt) | Quy tắc review | Công cụ bắt được |
|---|---|---|---|
| #std603 | Phần lớn document phải **được post**; chưa post = bản nháp, không kiểm tra nghiệp vụ, không vào sổ. Giai đoạn của chứng từ đã post thể hiện bằng **trạng thái**, kiểm tra theo trạng thái | P2 | — |
| #std450 | **Không** gọi `RecordSet.Write()` tường minh trong `Posting` — để platform ghi khi kết thúc posting (tránh deadlock). **Ngoại lệ:** khi dữ liệu register cần cho thuật toán ngay sau đó trong posting (ví dụ kiểm tra số dư âm sau khi ghi) | P3 | — |
| #std661 | Kiểm soát tồn khi post phải là **đọc có khóa**. Cách khuyến nghị: ghi các register không cần kiểm soát trước; cuối transaction ghi register cần kiểm soát với `LockForUpdate = True`, rồi query số dư âm theo đúng tập dimension; có âm → hủy | P3, P6 | — |
| #std460 | Dùng **chế độ khóa managed**; đặt khóa tường minh (`DataLock`) **trước khi đọc** dữ liệu sẽ dùng để ghi; khóa đúng phạm vi cần thiết; trong chế độ managed, `FOR UPDATE` trong query không có tác dụng | P6 | v8cs `configuration-data-lock-mode`, `ql-using-for-update` |
| #std783 | Transaction: mỗi `BeginTransaction` có cặp `CommitTransaction` / `RollbackTransaction`; bắt đầu và kết thúc **trong cùng một method**; exception trong transaction không tự hủy transaction — phải `RollbackTransaction` trong `Except` | T1 | BSL LS `BeginTransactionBeforeTryCatch`, `CommitTransactionOutsideTryCatch`, `PairingBrokenTransaction`, `WrongUseOfRollbackTransactionMethod` |
| #std792 | Không ghi record set của information / accumulation register **trong vòng lặp** từng bản ghi — gom thành một set (lô khoảng 1 000 bản ghi); nếu chỉ đổi dưới 30 % thì ghi phần thay đổi | Q1, T1 | — |
| #std477 | Register phải **tự đủ nghĩa**: logic và báo cáo trên register không lấy trường của recorder (chứng từ) qua dấu chấm — dữ liệu cần thì đưa vào dimension / attribute của register | P7 | — |
| #std633 | Nếu cấu hình có cơ chế bật / tắt `Active` của movement thì **mọi** query và báo cáo phải lọc movement đang active | — | — |
| #std664 / #std663 | Số dư theo một bộ dimension bị khóa khi ghi → chọn dimension theo đúng "độ mịn" nghiệp vụ và dùng chế độ tách tổng (totals splitting) để nhiều người post song song | P6 | — |

## 2. Sự kiện của object và kiểm tra dữ liệu

| Chuẩn | Nội dung chính | Quy tắc review | Công cụ |
|---|---|---|---|
| #std463 | `FillCheckProcessing`: kiểm tra mà Fill checking thường không làm được (theo điều kiện, theo tabular section, liên quan nhiều trường); bỏ kiểm tra có điều kiện bằng cách xóa khỏi `CheckedAttributes` | V1 | — |
| #std464 | `BeforeWrite`: điền thuộc tính, kiểm tra, làm việc với giá trị **cũ** đã lưu trong DB | V5 | BSL LS `DataExchangeLoading` |
| #std465 | `OnWrite`: ghi dữ liệu liên quan sang object khác; **không** sửa chính object đang ghi (đã ghi xong) | V5 | `DataExchangeLoading` |
| #std773 | Mọi handler `BeforeWrite` / `OnWrite` / `BeforeDelete`… kiểm tra `DataExchange.Load` ở **đầu** handler và thoát (dữ liệu nhận qua trao đổi ghi nguyên trạng) | V5 | `DataExchangeLoading`, v8cs `data-exchange-load` |
| #std686 | Không gán `Cancel = False` (kể cả gián tiếp `Cancel = HasErrors()`) — có thể xóa `True` đã đặt trước đó. Viết `If … Then Cancel = True; EndIf;` hoặc `Cancel = Cancel Or …` | V1 | `UsingCancelParameter`, v8cs `event-handler-boolean-param` |
| #std396 | `Filling`: chặn "Tạo dựa trên" không hợp lệ (dựa trên nhóm, dựa trên chứng từ chưa post) — được phép `Raise` để báo lý do | V4 | — |
| #std466 / #std752 | `OnCopy` xóa dữ liệu không được sao chép; `BeforeDelete` kiểm tra / dọn dữ liệu liên quan | — | — |
| #std451 | Tạo object bằng code qua method của manager (`Documents.X.CreateDocument()`, `Catalogs.X.CreateItem()`), không dùng `New`; gọi `Fill()` tường minh để chạy logic điền mặc định | T1 | — |

## 3. Query

| Chuẩn | Nội dung chính | Quy tắc review | Công cụ |
|---|---|---|---|
| #std436 | Dữ liệu cùng loại lấy bằng **một** query (`IN`, `UNION ALL`, batch query), không query trong vòng lặp | Q1 | v8cs `query-in-loop`; BSL LS `CreateQueryInCycle` |
| #std657 | Mọi điều kiện thuộc về virtual table đặt **trong tham số** virtual table, dạng đơn giản `Dimension = &Value` / `IN (&List)`; subquery trong tham số chỉ dùng một bảng, không join | P8 | `VirtualTableCallWithoutParameters`, v8cs `ql-virtual-table-filters` |
| #std733 | Đọc `.Balance` nhanh nhất khi **không truyền ngày** (bảng tổng hiện hành) — chỉ dùng khi thực sự cần số dư hiện tại (post thời gian thực); post lùi ngày phải truyền thời điểm | P3, P8 | — |
| #std654 | Lấy trường qua dấu chấm (`Ref.Attribute`) tạo join ngầm; với trường **kiểu hỗn hợp** thì đặc biệt tránh — dùng `CAST(... AS ...)` | Q1 | `QueryNestedFieldsByDot`, `RefOveruse` |
| #std655 | Không join với subquery — đưa subquery thành **temp table** | Q2 | `JoinWithSubQuery`, `JoinWithVirtualTable` |
| #std658 / #std652 | Điều kiện chính trong `WHERE` / `ON` / tham số virtual table phải dùng được **index**; không nối điều kiện chính bằng `OR` | Q2 | `LogicalOrInJoinQuerySection`, `LogicalOrInTheWhereSectionOfQuery` |
| #std777 | Temp table để tăng hiệu năng / chia query; chỉ chọn cột và dòng cần thiết; không đổ hàng trăm nghìn dòng | Q2 | v8cs `ql-temp-table-index` |
| #std412 | Thuật toán phụ thuộc thứ tự dòng (FIFO, sinh movement, hiển thị) → luôn `ORDER BY`; `TOP` không có `ORDER BY` là kết quả không xác định | P4, Q5 | `SelectTopWithoutOrderBy` |
| #std438 | Kiểm tra kết quả rỗng bằng `QueryResult.IsEmpty()` chỉ khi **không** đọc dữ liệu sau đó | — | — |
| #std434 / #std435 | Ưu tiên `UNION ALL` thay `UNION` khi không cần loại trùng; hạn chế `FULL OUTER JOIN` | Q2 | `UnionAll`, `FullOuterJoinQuery` |
| #std726 | `LIKE` chỉ dùng với literal hằng (`Attribute LIKE "123%"`) hoặc tham số đã xử lý ký tự đặc biệt | — | `UsingLikeInQuery`, `IncorrectUseLikeInQuery` |
| #std415 | **Không** dùng `ALLOWED` trong query phục vụ tính toán / posting — dữ liệu bị ẩn làm sai kết quả | — | — |
| #std496 | Đọc vài thuộc tính của một ref: dùng query (hoặc `Common.ObjectAttributesValues` của SSL), không `GetObject()` / dereference đọc cả object | Q1, V5 | v8cs `reading-attribute-from-database` |

## 4. Client / server, form

| Chuẩn | Nội dung chính | Quy tắc review | Công cụ |
|---|---|---|---|
| #std487 | Kiểm soát số **server call**: một thao tác người dùng thường không quá một lần gọi thêm; kiểm soát lượng dữ liệu truyền đi | F1 | `MissingTempStorageDeletion` |
| #std636 | `&AtServerNoContext` chỉ truyền tham số; `&AtServer` truyền cả dữ liệu form đã đổi + khởi tạo context → chậm hơn. Không cần dữ liệu form thì dùng NoContext | F1 | — |
| #std629 | Giảm code chạy ở client, nhưng tính toán nhẹ (thành tiền, tổng) vẫn làm ở client để khỏi gọi server | F1 | — |
| #std439 | Mọi method của form module có compilation directive; dùng preprocessor đúng chỗ | M1 | `CompilationDirectiveLost`, v8cs `form-module-missing-pragma` |
| #std703 | Cấu hình đặt *Modality use mode = Do not use*; dùng `ShowMessageBox`, `ShowQueryBox`, `OpenForm` + callback (hoặc `Async`/`Await`) thay method modal | F6 | `UsingModalWindows`, `UsingSynchronousCalls`, v8cs `dont-use-modality-mode` |
| #std404 / #std741 | Mở form bằng `OpenForm` (không `GetForm` + `Open`); form có tham số khai báo trong **Parameters** của form | F4 | `GetFormMethod` |
| #std411 | Giới hạn giá trị chọn bằng **Choice parameters / Choice parameter links** của field hoặc attribute | F4 | — |
| #std409 | Trong form module ưu tiên `FormAttributeToValue` (gọn, ít lỗi) thay cho `FormDataToValue`; chỉ chuyển sang object khi cần method của object | F1 | `FormDataToValue` |
| #std400 / #std418 / #std585 | Thông báo người dùng bằng `UserMessage` (SSL: `Common.MessageToUser` / `CommonClient.MessageToUser`); **không** dùng `Message()` | V2 | `DeprecatedMessage` |
| #std522 / #std523 | Giảm truy cập DB trong handler chạy thường xuyên (OnActivateRow…); không dùng `CurrentRow` để lấy giá trị trường của dòng — dùng `CurrentData` (và kiểm `Undefined`) | F8 | `CurrentRowAccess` |

## 5. Module, đặt tên, lỗi

| Chuẩn | Nội dung chính | Quy tắc review | Công cụ |
|---|---|---|---|
| #std455 | Cấu trúc module theo **region**: phần mô tả biến, `Public` (giao diện lập trình), `EventHandlers`, `Internal`, `Private`… | M2 | `CodeOutOfRegion`, `NonStandardRegion` |
| #std469 | Common module gom theo một chủ đề; chọn 1 trong 4 ngữ cảnh (Server, Client, Server call, Client+Server) và đặt **hậu tố tên** theo ngữ cảnh (`…Client`, `…ServerCall`, `…ClientServer`) | M1 | `CommonModuleName*`, `CommonModuleInvalidType` |
| #std679 | Không bật cờ **Server call** mặc định cho mọi module server — chỉ module chứa API thực sự gọi từ client, và API đó không lộ dữ liệu / không cho làm điều người dùng không được phép | M1 | v8cs `common-module-server-call` |
| #std544 | Không đặt method `Export` trong command module / common command; form module chỉ export khi thật cần (handler gắn từ code, callback) | M1 | `CommandModuleExportMethods` |
| #std454 / #std647 / #std640 | Tên biến, method có nghĩa, PascalCase; tham số từ chung đến riêng, tham số tùy chọn sau tham số bắt buộc | M2 | `FunctionNameStartsWithGet`, `NumberOfOptionalParams` |
| #std453 | Doc-comment cho method `Export` (mô tả, Parameters, Returns) | M2 | `MissingParameterDescription` |
| #std499 | Không bắt exception khi không cần (platform đã hiện lỗi và ghi Event log); khi bắt thì ghi `WriteLogEvent` với `DetailErrorDescription` và báo người dùng | T2 | `MissingCodeTryCatchEx`, `UsageWriteLogEvent`, v8cs `empty-except-statement` |
| #std790 | `Raise` bằng code chỉ khi cần (lỗi nghiệp vụ hiển thị cho người dùng); với lỗi kỹ thuật nên có **category** lỗi | T2, T3 | — |
| #std498 | Ghi Event log có tên sự kiện, mức độ, metadata, dữ liệu liên quan | T2 | — |
| #std693 | `Structure` không nhồi quá nhiều key qua constructor; không dùng làm "bảng" — dùng ValueTable | — | `NumberOfValuesInStructureConstructor` |
| #std782 | Nối chuỗi số lượng lớn (≥ 1 000 lần) bằng `StrConcat` / mảng, không `+` trong vòng lặp | — | — |

## 6. File, tích hợp, bảo mật, quyền

| Chuẩn | Nội dung chính | Quy tắc review | Công cụ |
|---|---|---|---|
| #std542 | File tạm lấy tên bằng `GetTempFileName()`, xóa sau khi dùng; không ghi vào thư mục cố định | X3 | `FileSystemAccess`, `MissingTemporaryFileDeletion`, `TempFilesDir` |
| #std748 | Mọi `HTTPConnection`, `WSProxy`, `FTPConnection`… phải đặt **timeout** | X (tích hợp) | `TimeoutsInExternalResources` |
| #std740 | Không lưu mật khẩu / token dạng rõ trong code hay constant — dùng kho dữ liệu an toàn (`Common.WriteDataToSecureStorage` của SSL) | — | `UsingHardcodeSecretInformation`, v8cs `secure-password-storage` |
| #std669 / #std770 | Hạn chế `Execute` / `Eval` (thực thi code động), đặc biệt trên server | — | `ExecuteExternalCode` |
| #std485 | Privileged mode chỉ cho đoạn ngắn, có lý do; không mở rộng quyền người dùng ngoài mục đích | — | `SetPrivilegedMode` |
| #std689 / #std488 | Thiết kế role theo chức năng, có các role chuẩn (toàn quyền, quản trị…); hạn chế kiểm tra quyền bằng tên role (`IsInRole`) rải rác trong code | — | `IsInRoleMethod` |
| #std548 / #std789 | Lệnh in: người dùng chỉ cần quyền đọc dữ liệu + quyền chạy lệnh; người dùng có thể sửa template (SSL Print) nên code in phải chịu được khi vùng / tham số template bị đổi hoặc xóa | X4 | — |
| #std540 / #std539 | Chỉ dùng scheduled job khi thật cần; luôn cho người dùng cách chạy tay việc tương ứng | — | `ScheduledJobHandler` |

## 7. Ghi chú khi đối chiếu với code của khóa

- Code của khóa (bài 11–16) gọi `RegisterRecords.X.Write()` trong `Posting` rồi kiểm tra số dư âm — đây là **ngoại lệ hợp lệ** của #std450 (cần dữ liệu ngay sau đó) và đúng tinh thần #std661; khi dạy, nói rõ đây là ngoại lệ, không phải cách ghi mặc định.
- Bản đồ đầy đủ chuẩn ↔ chẩn đoán BSL LS / 1C:Code style V8 có trên v8std.ru (mỗi chuẩn liệt kê các check bắt được nó); tên chẩn đoán dùng được với `review-code.md` mục 2b.
