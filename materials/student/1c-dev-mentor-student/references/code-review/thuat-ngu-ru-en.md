# Bảng đối chiếu cú pháp và thuật ngữ Nga ↔ Anh ↔ Việt

> **Khi nào đọc file này:** người dùng dán code **cú pháp tiếng Nga** (Процедура, Если…), đọc tài liệu / repo cộng đồng (phần lớn bằng tiếng Nga), hoặc cần chuyển một đoạn code sang cú pháp tiếng Anh của khóa. Thuật ngữ tiếng Việt dùng trong khóa: `terminology.md` (giữ nguyên tên tiếng Anh cho object, chỉ giải thích bằng tiếng Việt).
>
> Platform hiểu **cả hai** cú pháp trong cùng một cấu hình (thuộc tính *Script variant* của cấu hình chỉ quyết định cú pháp khi Designer sinh code mới). Khi chuyển code: đổi từ khóa và tên hàm theo bảng; **tên object metadata** (Справочники.Номенклатура) giữ theo cấu hình thật — đổi tên metadata là việc khác. Bảng dưới là đối chiếu phổ biến; hàm ít gặp hãy tra Syntax Assistant (hiện cả hai tên).

## 1. Từ khóa của ngôn ngữ

| Русский | English | | Русский | English |
|---|---|---|---|---|
| Процедура / КонецПроцедуры | Procedure / EndProcedure | | Функция / КонецФункции | Function / EndFunction |
| Экспорт | Export | | Знач | Val |
| Перем | Var | | Возврат | Return |
| Если / Тогда / ИначеЕсли / Иначе / КонецЕсли | If / Then / ElsIf / Else / EndIf | | Для / По / Цикл / КонецЦикла | For / To / Do / EndDo |
| Для Каждого … Из … Цикл | For Each … In … Do | | Пока … Цикл | While … Do |
| Продолжить / Прервать | Continue / Break | | Попытка / Исключение / КонецПопытки | Try / Except / EndTry |
| ВызватьИсключение | Raise | | Новый | New |
| И / Или / Не | And / Or / Not | | Истина / Ложь / Неопределено / NULL | True / False / Undefined / NULL |
| ЭтотОбъект | ThisObject | | ?(усл, a, b) | ?(cond, a, b) |
| #Область / #КонецОбласти | #Region / #EndRegion | | #Если Сервер Тогда … #КонецЕсли | #If Server Then … #EndIf |
| &НаКлиенте | &AtClient | | &НаСервере | &AtServer |
| &НаСервереБезКонтекста | &AtServerNoContext | | &НаКлиентеНаСервереБезКонтекста | &AtClientAtServerNoContext |
| &Перед / &После / &Вместо / &ИзменениеИКонтроль | &Before / &After / &Around / &ChangeAndValidate | | ПродолжитьВызов() | ProceedWithCall() |
| #Вставка / #КонецВставки / #Удаление / #КонецУдаления | #Insert / #EndInsert / #Delete / #EndDelete | | Асинх / Ждать | Async / Await |

## 2. Hàm và đối tượng hay gặp

| Русский | English | Ghi chú |
|---|---|---|
| Сообщить() | Message() | Code mới dùng `UserMessage` |
| СообщениеПользователю | UserMessage | |
| ЗначениеЗаполнено() | ValueIsFilled() | |
| ТипЗнч() / Тип() | TypeOf() / Type() | |
| СтрШаблон / СтрНайти / СтрРазделить / СтрСоединить | StrTemplate / StrFind / StrSplit / StrConcat | |
| СокрЛП / Лев / Прав / Сред / ВРег / НРег | TrimAll / Left / Right / Mid / Upper / Lower | |
| Формат() / Число() / Строка() / Дата() | Format() / Number() / String() / Date() | |
| ТекущаяДатаСеанса() / ТекущаяДата() | CurrentSessionDate() / CurrentDate() | Ưu tiên CurrentSessionDate |
| НачалоДня / КонецДня / НачалоМесяца / КонецМесяца / ДобавитьМесяц | BegOfDay / EndOfDay / BegOfMonth / EndOfMonth / AddMonth | |
| Мин() / Макс() / Окр() | Min() / Max() / Round() | |
| Запрос / РезультатЗапроса / Выборка | Query / QueryResult / Selection (QueryResultSelection) | |
| УстановитьПараметр / Выполнить / Выбрать / Следующий / Выгрузить | SetParameter / Execute / Select / Next / Unload | |
| ВыполнитьПакет() / МенеджерВременныхТаблиц | ExecuteBatch() / TempTablesManager | |
| ТаблицаЗначений / Массив / Структура / Соответствие / СписокЗначений / ДеревоЗначений | ValueTable / Array / Structure / Map / ValueList / ValueTree | |
| НайтиСтроки / Найти / Итог / Свернуть / ВыгрузитьКолонку | FindRows / Find / Total / GroupBy / UnloadColumn | |
| Движения / НаборЗаписей / Записывать / Записать() | RegisterRecords / RecordSet / Write (= True) / Write() | |
| ДобавитьПриход() / ДобавитьРасход() / ВидДвиженияНакопления.Приход / Расход | AddReceipt() / AddExpense() / AccumulationRecordType.Receipt / Expense | |
| МоментВремени() / Граница / ВидГраницы.Включая / Исключая | PointInTime() / Boundary / BoundaryType.Including / Excluding | |
| БлокировкаДанных / ЭлементБлокировкиДанных / РежимБлокировкиДанных.Исключительный / Заблокировать() | DataLock / DataLockItem / DataLockMode.Exclusive / Lock() | |
| ИсточникДанных / ИспользоватьИзИсточникаДанных | DataSource / UseFromDataSource | |
| НачатьТранзакцию / ЗафиксироватьТранзакцию / ОтменитьТранзакцию | BeginTransaction / CommitTransaction / RollbackTransaction | |
| ЗаписьЖурналаРегистрации / УровеньЖурналаРегистрации.Ошибка | WriteLogEvent / EventLogLevel.Error | |
| ИнформацияОбОшибке / ПодробноеПредставлениеОшибки / КраткоеПредставлениеОшибки | ErrorInfo / DetailErrorDescription / BriefErrorDescription | Bản mới: `ErrorProcessing.DetailErrorDescription` |
| ОбменДанными.Загрузка | DataExchange.Load | |
| ДополнительныеСвойства | AdditionalProperties | |
| ПолучитьОбъект() / Записать(РежимЗаписиДокумента.Проведение) | GetObject() / Write(DocumentWriteMode.Posting) | |
| ОткрытьФорму / ОписаниеОповещения / ВыполнитьОбработкуОповещения | OpenForm / NotifyDescription (CallbackDescription) / RunCallback | |
| ПоказатьПредупреждение / ПоказатьВопрос | ShowMessageBox / ShowQueryBox | Modal cũ: Предупреждение / Вопрос = DoMessageBox / DoQueryBox |
| Элементы / ТекущиеДанные / Объект / Параметры | Items / CurrentData / Object / Parameters | |
| РеквизитФормыВЗначение / ЗначениеВРеквизитФормы | FormAttributeToValue / ValueToFormAttribute | |
| ПоместитьВоВременноеХранилище / ПолучитьИзВременногоХранилища | PutToTempStorage / GetFromTempStorage | |
| ТабличныйДокумент / ПолучитьОбласть / Вывести | SpreadsheetDocument / GetArea / Put | |
| HTTPСоединение / HTTPЗапрос / ЗащищенноеСоединениеOpenSSL | HTTPConnection / HTTPRequest / OpenSSLSecureConnection | |
| ЧтениеJSON / ЗаписьJSON / ПрочитатьJSON / ЗаписатьJSON | JSONReader / JSONWriter / ReadJSON / WriteJSON | |

## 3. Metadata và handler

| Русский | English | Việt (giải thích) |
|---|---|---|
| Справочник / Документ / Перечисление / Константа | Catalog / Document / Enum / Constant | danh mục / chứng từ / liệt kê / hằng |
| РегистрНакопления (Остатки / Обороты) | AccumulationRegister (Balance / Turnovers) | register tích lũy (số dư / phát sinh) |
| РегистрСведений (периодический, подчинен регистратору) | InformationRegister (periodic, subordinate to recorder) | register thông tin |
| РегистрБухгалтерии / ПланСчетов / Субконто | AccountingRegister / ChartOfAccounts / ExtDimension | sổ kế toán / hệ thống tài khoản / chiều phân tích |
| ПланВидовХарактеристик | ChartOfCharacteristicTypes | |
| Обработка / Отчет / ОбщийМодуль / ОбщаяФорма / ОбщаяКоманда | DataProcessor / Report / CommonModule / CommonForm / CommonCommand | |
| Роль / ФункциональнаяОпция / Подсистема / ПодпискаНаСобытие / РегламентноеЗадание | Role / FunctionalOption / Subsystem / EventSubscription / ScheduledJob | |
| ПланОбмена / HTTP-сервис / Расширение конфигурации | ExchangePlan / HTTP service / Configuration extension | |
| Остатки() / Обороты() / ОстаткиИОбороты() / СрезПоследних() | .Balance() / .Turnovers() / .BalanceAndTurnovers() / .SliceLast() | virtual table |
| ОбработкаПроведения / ОбработкаПроверкиЗаполнения / ОбработкаЗаполнения | Posting / FillCheckProcessing / Filling | |
| ПередЗаписью / ПриЗаписи / ПриКопировании / ПередУдалением / ПриУстановкеНовогоНомера | BeforeWrite / OnWrite / OnCopy / BeforeDelete / OnSetNewNumber | |
| ПриСозданииНаСервере / ПриОткрытии / ПриЧтенииНаСервере / ПередЗаписьюНаСервере / ПослеЗаписи | OnCreateAtServer / OnOpen / OnReadAtServer / BeforeWriteAtServer / AfterWrite | |
| ПриИзменении / НачалоВыбора / ОбработкаВыбора / ПослеУдаления | OnChange / StartChoice / ChoiceProcessing / AfterDeleteRow | |
| СКД (система компоновки данных) / Макет / Печатная форма | DCS (Data composition system) / Template / Print form | |
| БСП (Библиотека стандартных подсистем) | SSL (Standard Subsystems Library) | xem `ssl-api-en.md` |
| Конфигуратор / Предприятие / Синтакс-помощник / Консоль запросов | Designer / 1C:Enterprise mode / Syntax Assistant / Query console | |
| ИТС / Стандарты разработки | ITS / Development Standards | `chuan-phat-trien.md` |

## 4. Query language

| Русский | English |
|---|---|
| ВЫБРАТЬ / РАЗЛИЧНЫЕ / ПЕРВЫЕ n / РАЗРЕШЕННЫЕ | SELECT / DISTINCT / TOP n / ALLOWED |
| ИЗ / ГДЕ / СГРУППИРОВАТЬ ПО / ИМЕЮЩИЕ / УПОРЯДОЧИТЬ ПО / ИТОГИ … ПО | FROM / WHERE / GROUP BY / HAVING / ORDER BY / TOTALS … BY |
| ПОМЕСТИТЬ / УНИЧТОЖИТЬ | INTO / DROP |
| ЛЕВОЕ / ВНУТРЕННЕЕ / ПОЛНОЕ СОЕДИНЕНИЕ … ПО | LEFT / INNER / FULL JOIN … ON |
| ОБЪЕДИНИТЬ ВСЕ | UNION ALL |
| ЕСТЬNULL / ВЫБОР КОГДА … ТОГДА … ИНАЧЕ … КОНЕЦ / ВЫРАЗИТЬ … КАК | ISNULL / CASE WHEN … THEN … ELSE … END / CAST … AS |
| В / В ИЕРАРХИИ / ПОДОБНО / МЕЖДУ | IN / IN HIERARCHY / LIKE / BETWEEN |
| СУММА / КОЛИЧЕСТВО / МАКСИМУМ / МИНИМУМ / СРЕДНЕЕ | SUM / COUNT / MAX / MIN / AVG |
| ЗНАЧЕНИЕ(Перечисление.X.Y) / НАЧАЛОПЕРИОДА(…, ДЕНЬ) / ДОБАВИТЬКДАТЕ | VALUE(Enum.X.Y) / BEGINOFPERIOD(…, DAY) / DATEADD |
| ДЛЯ ИЗМЕНЕНИЯ | FOR UPDATE |
