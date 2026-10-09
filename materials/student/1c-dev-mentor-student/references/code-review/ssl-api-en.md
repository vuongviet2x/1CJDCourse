# SSL (Standard Subsystems Library) — tên API tiếng Anh hay dùng

> **Khi nào đọc file này:** người dùng làm trên cấu hình có SSL (Jet, SSL Demo của Bài 21–23, 1C:Company Management, AccountingSuite…) và cần đúng **tên tiếng Anh** của module / hàm SSL; khi đọc code hay tài liệu tiếng Nga có `ОбщегоНазначения…`, `УправлениеПечатью…` và cần tên tương ứng. Bài liên quan: B21–B23, Extensions; Jet: `jet/jet-overview.md` (Jet nhúng SSL 3.1.10).
>
> Nguồn kiểm chứng: SSL **World edition 3.1.12.175** (bản tiếng Anh, mirror `1c-syntax/ssl_3_1_eng`, tháng 4/2026). Chữ ký dưới đây chép từ bản đó — **phiên bản SSL khác có thể khác tham số** (SSL 2.x trong cấu hình cũ như AccountingSuite, Company Management đời cũ): luôn mở module trong cấu hình thật của người dùng (Designer → Common modules → tìm tên hàm, đọc doc-comment) trước khi khẳng định. Chỉ trích tên và chữ ký hàm, không chép nguyên module.

## 1. Module ↔ tên tiếng Nga

| English | Русский | Ngữ cảnh |
|---|---|---|
| `Common` | ОбщегоНазначения | Server |
| `CommonClient` | ОбщегоНазначенияКлиент | Client |
| `CommonClientServer` | ОбщегоНазначенияКлиентСервер | Client + Server |
| `CommonServerCall` | ОбщегоНазначенияВызовСервера | Server call |
| `StandardSubsystemsClient` / `StandardSubsystemsServer` | СтандартныеПодсистемыКлиент / …Сервер | |
| `PrintManagement` / `PrintManagementClient` / `PrintManagementOverridable` | УправлениеПечатью / …Клиент / …Переопределяемый | B22 |
| `AdditionalReportsAndDataProcessors` | ДополнительныеОтчетыИОбработки | B21, Intern Task 6–7 |
| `TimeConsumingOperations` / `TimeConsumingOperationsClient` | ДлительныеОперации / …Клиент | |
| `FilesOperations` / `FilesOperationsClient` | РаботаСФайлами / …Клиент | B23 |
| `AccessManagement` | УправлениеДоступом | B20 |
| `Users` / `UsersClient` | Пользователи / …Клиент | |
| `ReportsOptions` | ВариантыОтчетов | |
| `ObjectAttributesLock` | ЗапретРедактированияРеквизитовОбъектов | |
| `InfobaseUpdate` | ОбновлениеИнформационнойБазы | |
| `ObjectsPrefixesEvents` | ПрефиксацияОбъектовСобытия | |
| `PropertyManager` | УправлениеСвойствами | Additional attributes (Jet dùng) |
| `ContactsManager` | УправлениеКонтактнойИнформацией | |
| `AttachableCommands` | ПодключаемыеКоманды | |
| `BatchEditObjects` | ГрупповоеИзменениеОбъектов | |
| `CurrencyRateOperations` | РаботаСКурсамиВалют | |
| `…Overridable` (`CommonOverridable`, `AccessManagementOverridable`…) | …Переопределяемый | Nơi **được phép** viết code tích hợp — không sửa module lõi |

## 2. Hàm hay dùng (chữ ký theo SSL 3.1.12 World edition)

| Việc cần làm | API |
|---|---|
| Thông báo gắn ô (server) | `Common.MessageToUser(MessageToUserText, DataKey = Undefined, Field = "", DataPath = "", Cancel = False)` |
| Thông báo gắn ô (client) | `CommonClient.MessageToUser(MessageToUserText, DataKey = Undefined, …)` |
| Đọc một thuộc tính của ref (không đọc cả object) | `Common.ObjectAttributeValue(Ref, AttributeName, SelectAllowedItems = False, LanguageCode = Undefined)` |
| Đọc nhiều thuộc tính | `Common.ObjectAttributesValues(Ref, Attributes, …)` — `Attributes` là chuỗi "A, B" hoặc Array → Structure |
| Một thuộc tính của nhiều ref | `Common.ObjectsAttributeValue(ReferencesArray, AttributeName, …)` → Map |
| Kiểm tra subsystem có trong cấu hình | `Common.SubsystemExists(FullSubsystemName)` / `CommonClient.SubsystemExists(…)`; gọi module có thể không tồn tại qua `Common.CommonModule(Name)` |
| Ref có tồn tại trong DB | `Common.RefExists(Ref)` |
| Kiểm tra chứng từ đã post | `Common.CheckDocumentsPosting(Documents)` |
| Ngày phiên ở client | `CommonClient.SessionDate()` |
| Hỏi người dùng (không modal) | `StandardSubsystemsClient.ShowQuestionToUser(CallbackDescriptionOnCompletion, QueryText, Buttons, AdditionalParameters = Undefined)` |
| Mở URL | `CommonClient.OpenURL(URL, Notification = Undefined)` |
| Lưu mật khẩu / token an toàn | `Common.WriteDataToSecureStorage(Owner, Data, Key = "Password")`, `Common.ReadDataFromSecureStorage(…)` |
| Người dùng hiện tại | `Users.CurrentUser()`, `Users.AuthorizedUser()` |
| Kiểm tra role | `AccessManagement.HasRole(Role, ObjectReference = Undefined, User = Undefined)` |
| Dynamic list | `CommonClientServer.SetDynamicListParameter(List, ParameterName, Value, Use = True)`, `CommonClientServer.SetDynamicListFilterItem(DynamicList, FieldName, …)` |
| Thuộc tính form item | `CommonClientServer.SetFormItemProperty(FormItems, TagName, PropertyName, Value)` |
| Mảng, Structure | `CommonClientServer.SupplementArray(Destination, Source, UniqueValuesOnly = False)`, `DeleteValueFromArray(Array, Value)`, `ArraysDifference(Array, SubtractionArray)`, `SupplementStructure(Receiver, Source, Replace = Undefined)`; `Common.ValueTableToArray(ValueTable)`, `Common.CopyRecursive(Source)` |
| In (server, trong `Print()` của manager module) | `PrintManagement.MustPrintTemplate(PrintFormsCollection, TemplateName)`; `PrintManagement.PrintFormTemplate(TemplatePath, LanguageCode = Undefined)` — `TemplatePath` dạng `"Document.X.PF_MXL_Name"` hoặc `"CommonTemplate.Name"`; `PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, TemplateName, TemplateSynonym, SpreadsheetDocument, Picture = Undefined, FullTemplatePath = "", PrintFormFileName = Undefined)`; `PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Ref)` |
| Đăng ký object có lệnh in | `PrintManagementOverridable.OnDefinePrintSettings(Settings)` |
| Gọi lệnh in từ client | `PrintManagementClient.ExecutePrintCommand(PrintManagerName, TemplatesNames, ObjectsArray, FormOwner, PrintParameters = Undefined)` |
| Đăng ký external data processor / report | `AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo(SSLVersion = "")` trong `ExternalDataProcessorInfo()` của object module |
| Chạy nền | `TimeConsumingOperations.ExecuteFunction(ExecutionParameters, FunctionName, …)` / `ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters)`; tham số: `FunctionExecutionParameters(FormIdentifier)` / `BackgroundExecutionParameters(…)`; client chờ: `TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion = Undefined, …)` |
| File đính kèm | `FilesOperations.FileBinaryData(AttachedFile, RaiseException = True)`, `FilesOperations.AppendFile(FileParameters, FileAddressInTempStorage, …)` |

## 3. Khối tích hợp chuẩn trong object của cấu hình

SSL nhúng vào object của cấu hình bằng các khối có chú thích `// StandardSubsystems.<Subsystem>` … `// End StandardSubsystems.<Subsystem>` (tiếng Nga: `// СтандартныеПодсистемы.…`). Khi thêm object mới (chứng từ, catalog) vào cấu hình SSL: chép khối tương ứng từ một object có sẵn (ví dụ form có Print, Attachable commands, Additional attributes), sửa tên object; đăng ký object ở module `…Overridable` của subsystem. Không xóa khối của object có sẵn khi tùy biến — ưu tiên extension (`bai-extensions.md`).
