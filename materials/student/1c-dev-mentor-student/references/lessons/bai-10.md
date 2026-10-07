# Bài 10 — Query language (Ngôn ngữ truy vấn)

## Khái niệm chính

### Query object và query text
- Nền tảng 1C dùng đối tượng đặc biệt **Query** để tạo và thực thi truy vấn tới các bảng cơ sở dữ liệu. Query tiện dùng khi cần lấy tập dữ liệu phức tạp, được nhóm và/hoặc sắp xếp; ví dụ kinh điển: tổng hợp trạng thái của register tại một thời điểm, lấy thông tin theo các lát cắt thời gian khác nhau.
- 1C dùng ngôn ngữ truy vấn giống SQL (SQL-like). Khi thực thi, nền tảng tự động chuyển query text sang văn bản truy vấn phù hợp với SQL server đang dùng.
- Nguồn dữ liệu (data sources) của query: bảng cơ sở dữ liệu, value table truyền vào query parameters, và temporary tables.
- Bảng cơ sở dữ liệu chia làm 2 lớp:
  - **Real tables**: được lưu trong database; có thể có các trường tính toán (calculable fields) được tính từ nhiều trường thật.
  - **Virtual tables**: không lưu trong database; khi truy cập, hệ thống tự thu thập thông tin từ các real tables. Virtual table có thể được tham số hóa (parameterized) — nội dung thực tế phụ thuộc giá trị tham số chỉ định trong query text. Mỗi virtual table có tên riêng để dùng trong query. (Chi tiết ở các bài về information register và accumulation register.)

### Các phần (section) của query
- Query text luôn bắt đầu bằng từ khóa bắt buộc **SELECT** — đây là từ khóa bắt buộc duy nhất, các từ khóa khác là tùy chọn.
- **Selection fields**: liệt kê sau SELECT, cách nhau bằng dấu phẩy. Dùng `*` để chọn tất cả trường.
- **AS**: đặt alias cho trường (hoặc cho nguồn dữ liệu). Có thể dùng biểu thức làm selection field (ví dụ `Quantity * Price AS Amount`). Nếu không đặt alias cho biểu thức, nền tảng tự gán (ví dụ `Field1`).
- **FROM**: chỉ định một hoặc nhiều nguồn dữ liệu.
- **WHERE**: điều kiện lọc; có thể dùng cả các trường không được chọn trong query. Điều kiện luôn là biểu thức logic (True/False). Có thể dùng thao tác trên selection fields, predefined values, giá trị kiểu nguyên thủy, query parameters, virtual fields.
- **Comment** trong query không ảnh hưởng gì; viết bằng 2 cách: (1) xuống dòng trong query text; (2) không xuống dòng — sau hai ký tự `//`.
- **GROUP BY**: các bản ghi có cùng giá trị ở các trường nhóm sẽ được "gộp" thành một bản ghi; các trường còn lại dùng aggregate functions: `SUM`, `COUNT(DISTINCT <field>)`, `COUNT`, `MAX`, `MIN`, `AVG`.
- **ORDER BY**: sắp xếp theo trường/biểu thức; `DESC` = giảm dần, mặc định tăng dần. Trường dùng để sắp xếp không bắt buộc phải có trong kết quả query.
- **HIERARCHY** (sắp xếp theo phân cấp, cho đối tượng phân cấp như catalog): trước tiên sắp xếp các parent từ cấp cao nhất, rồi cấp tiếp theo của mỗi parent, v.v. Giảm dần: `<field name> HIERARCHY DESC` (HIERARCHY đứng trước).
- **ALLOWED**: query chỉ chọn các bản ghi mà user hiện tại có quyền. Nếu không có, query báo lỗi khi gặp bản ghi user không có quyền. Chỉ ghi ở mệnh đề SELECT cấp cao nhất và áp dụng cho toàn bộ query (kể cả nested queries). Chỉ có tác dụng nếu bảng có data access restrictions. Quyền truy cập bảng không được xét: nếu bảng không có quyền READ, query vẫn lỗi dù có ALLOWED.
- **DISTINCT**: loại bỏ các dòng trùng lặp khỏi kết quả.
- **TOP <Count>**: giới hạn số dòng của kết quả (lấy các dòng đầu tiên theo quy tắc sắp xếp); số lượng là số nguyên. Có thể ORDER trong nested queries nếu nested query có TOP.
- **HAVING <Filter condition>**: đặt điều kiện cho giá trị aggregate function (WHERE không cho phép dùng aggregate function). Thứ tự: nhóm (GROUP BY) trước, rồi áp điều kiện HAVING.
- **Nested table trong selection field list**: nếu chọn tabular section của nguồn, trường kết quả có kiểu **QueryResult** (kết quả nested query). Khi Unload sang value table, kết quả lồng cũng được unload thành value table lồng. Mặc định nested result gồm mọi trường của nested table; có thể chỉ định trường trong ngoặc, hoặc `*` để chọn tất cả. Lấy dữ liệu từ trường này bằng `Select()` hoặc `Unload()`.

### Thực thi query và lấy kết quả
- `Text` property: gán query text cho Query object.
- `SetParameter()`: đặt giá trị tham số; đối số 1 = tên tham số, đối số 2 = giá trị. Tham số trong query text viết `&ParameterName`.
- `Execute()`: hàm trả về đối tượng kiểu **QueryResult**.
- Lấy dữ liệu từ QueryResult theo 2 cách:
  - `Select()` → đối tượng kiểu **Selection**: duyệt từng dòng; chỉ lưu dữ liệu một bản ghi tại một thời điểm → ít tốn bộ nhớ.
  - `Unload()` → đối tượng kiểu **ValueTable**: lấy toàn bộ một lần; Value table lưu trong RAM nên dữ liệu càng nhiều càng tốn bộ nhớ.
  - Chọn cách nào tùy vào nhiệm vụ.

### Query wizard
- Công cụ tạo query text bằng giao diện; mở từ context menu của module hoặc mục "Text" trên main menu.
- 2 biến thể: **query wizard** (chỉ tạo query text) và **query wizard with result processing** (có thêm tab result processing ở vị trí đầu; sinh sẵn code tạo Query object, gán text, thực thi, tạo selection và duyệt selection).
- Code đặt tham số KHÔNG được wizard sinh ra — phải tự viết.
- Nếu mở wizard ngoài khối code chứa kết quả query trước đó, nền tảng báo không tìm thấy query text, hỏi có tiếp tục không.
- Tab "Tables and fields": 3 danh sách — tất cả bảng của infobase, bảng đã chọn, selection fields.
- Tab "Order": ban đầu chỉ thấy các trường đã chọn; để sắp xếp theo trường khác, mở node "All fields". Cột Sort chọn thứ tự (ví dụ "Hierarchy, descending").
- Tab "Links": cấu hình join; flag **All** = chọn tất cả bản ghi từ bảng đó; tắt flag thì chỉ chọn bản ghi thỏa điều kiện nối.
- Có thể thêm nested query và đổi tên bảng nested query (tăng tính dễ đọc).
- Query batch trong wizard: query đưa dữ liệu vào temporary table hiển thị bằng tên temporary table; query hủy temporary table hiển thị bằng dấu trừ + tên (ví dụ "- Purchases"); query thường hiển thị là "Query Batch N" (N bắt đầu từ 1).
- Wizard báo lỗi khi mở query có UNION với số trường khác nhau.

### Joins
- Khi chọn từ nhiều nguồn mà không nối, kết quả là mọi tổ hợp của tất cả bản ghi (ví dụ 3 × 3 = 9 dòng).
- 4 loại join:
  - `[INNER] JOIN <Source description> BY <Filter condition>`
  - `LEFT JOIN <Source description> BY <Filter condition>`
  - `RIGHT JOIN <Source description> BY <Filter condition>`
  - `FULL JOIN <Source description> BY <Filter condition>`
- Trong 1C thực tế chỉ dùng 3 loại vì RIGHT join có thể biểu diễn bằng LEFT join — query wizard tự đổi RIGHT join thành LEFT join khi kết thúc.
- Danh sách join có thể mô tả nhiều join của nhiều nguồn cùng lúc.
- Từ khóa INNER có thể bỏ qua (chỉ tăng tính dễ đọc).
- Các nguồn nối không tương đương: kết quả có thể phụ thuộc bảng nào đứng trước (bên trái JOIN) và bảng nào đứng sau (bên phải).
- **INNER**: chỉ lấy các tổ hợp bản ghi thỏa điều kiện từ cả hai bảng.
- **LEFT**: lấy tất cả bản ghi của nguồn thứ nhất; bản ghi nguồn thứ hai chỉ lấy khi thỏa điều kiện; nếu không có bản ghi phù hợp, trường từ nguồn thứ hai = **NULL**.
- **FULL**: lấy tất cả bản ghi của cả hai nguồn; nối khi thỏa điều kiện; phía không tìm thấy bản ghi phù hợp chứa NULL.

### Nested tables và nested queries
- Danh sách nguồn có thể chứa nested tables — tabular sections của catalog và document. Tabular section có trường **Ref** lưu link tới owner (catalog, document); dùng trường này để nối các tabular section với nhau hoặc với owner.
- Nested query có thể dùng làm nguồn; mô tả giống query thường.
- Join bảng với nested query có thể làm giảm hiệu năng (DBMS optimizer có thể lập query plan sai).
- Ví dụ lỗi: nối document với cả hai tabular section Products (3 dòng) và Services (1 dòng, 1000) qua Ref → mỗi dòng Products nhận giá trị Services 1000 → tổng Services = 3000 (sai). Cách đúng: tính tổng Products và Services riêng (nested queries) rồi mới nối.

### Merging queries (UNION)
- Mỗi query trong union thu dữ liệu độc lập; ordering và tính totals thực hiện trên kết quả đã merge.
- Tên trường kết quả lấy theo danh sách selection fields của query đầu tiên; các trường của query còn lại khớp theo thứ tự xuất hiện.
- Các query merge phải có cùng số trường.
- Nếu các trường tương ứng có kiểu khác nhau → trường kết quả có kiểu composite.
- `UNION`: loại bỏ bản ghi trùng hoàn toàn giữa các query (chỉ giữ bản ghi đầu tiên). `UNION ALL`: giữ tất cả bản ghi.
- Grouping áp dụng riêng cho từng query trong union → muốn gộp kết quả union, đặt union vào nested query rồi GROUP BY từ nested query đó.

### Calculating query totals (TOTALS)
- Mệnh đề **TOTALS** xác định totals cần tính; giá trị aggregate được tính theo các tập dữ liệu có cùng giá trị checkpoint fields; totals được thêm vào kết quả như các totals rows.
- Bắt đầu bằng từ khóa bắt buộc TOTALS; danh sách aggregate functions: SUM, AVG, MIN, MAX, COUNT, COUNT (DISTINCT).
- **OVERALL**: tạo totals row cho toàn bộ kết quả.
- Totals theo checkpoints: sau từ khóa bắt buộc **BY**, liệt kê các grouping fields làm checkpoints.
- Nếu trường nhóm totals là reference tới catalog, có thể tính totals theo hierarchy: thêm từ khóa **HIERARCHY** sau reference đó.

### Expressions — Built-in functions
- Dùng được trong selection fields, filter conditions của join, và điều kiện WHERE. Danh sách xem trong cửa sổ custom expression; trợ giúp: tìm "Functions of query language".
- **DATEDIFF(<Date1>, <Date2>, <Type>)**: lấy Date2 trừ Date1, trả về số đơn vị theo Type (SECOND, MINUTE, HOUR, DAY, MONTH, QUARTER, YEAR); chỉ tính chênh lệch của đơn vị chỉ định, không xét các đơn vị còn lại (cả hai ví dụ trong tài liệu đều trả về 1).
- **VALUETYPE(<Expression>)**: trả về giá trị kiểu Type; nếu tham số là Undefined thì trả về Undefined.

### Selection operations (CASE)
- Các WHEN ... THEN được xử lý tuần tự; khi biểu thức logic là True thì kết thúc, kết quả là biểu thức sau THEN. Nếu mọi điều kiện đều False → dùng giá trị sau ELSE.

### Type casting (CAST)
- Dùng trong selection fields và WHERE. Ép biểu thức về kiểu nguyên thủy hoặc reference type (khi đó dùng tên bảng infobase tương ứng).
- Nếu kiểu composite có chứa kiểu cần ép → giá trị đúng kiểu giữ nguyên, giá trị kiểu khác → NULL.
- Nếu kiểu composite KHÔNG chứa kiểu cần ép → query thất bại với lỗi.

### Constants và parameters
- Literal: TRUE, FALSE, Number, String, Date (`DATETIME(...)`), Type (`TYPE(<Type name>)`), parameter (`&ParameterName`), UNDEFINED, NULL.
- Boolean, Number, String đặt giống như trong 1C:Enterprise language.
- Date: `DATETIME(năm, tháng, ngày[, giờ, phút, giây])` — 3 giá trị cuối là tùy chọn.
- Ngày tối đa với DATETIME: **31.12.3999 23:59:59**.
- `TYPE(<Type name>)`: Type name là tên kiểu nguyên thủy hoặc tên bảng có reference type cần lấy; kết quả là giá trị kiểu **Type**.

### Conditions và logical expressions
- Toán tử logic: **Not** (ưu tiên cao nhất) → **And** → **Or** (thấp nhất). Biểu thức logic đơn được tính trước, rồi Not, And, Or. Dùng ngoặc tròn () để đổi thứ tự.
- Các dạng logical expression:
  - `<Expression>`
  - `(<Expression> | <Logical expression>) <Comparison operation> (<Expression> | <Logical expression>)`
  - `<Expression> [Not] IN [HIERARCHY] (<Value list>)`
  - `<Expression> [Not] IN [HIERARCHY](<Query description>)`
  - `<Expression> [Not] BETWEEN <Expression> AND <Expression>`
  - `<Expression> IS [Not] NULL`
  - `<Expression> REFS <Table name>`
  - `<Expression> [Not] LIKE <STRING type literal> [Special character <STRING type literal>]`
- Comparison operations: `>`, `<`, `=`, `>=`, `<=`, `<>`.

### Value comparison rules
- Áp dụng cho: comparison operators; MIN/MAX; sắp xếp ORDER BY.
- Ưu tiên kiểu khi kiểu khác nhau (thấp → cao): NULL → Undefined → Boolean → Number → Date → String → Reference types. Giữa các reference types: theo internal table reference numbers.
- Cùng kiểu:
  - Boolean: True > False.
  - Number: quy tắc so sánh số thông thường.
  - Date: ngày sớm hơn nhỏ hơn.
  - String: theo đặc tính quốc gia của database và thứ tự sắp xếp; **không phân biệt hoa thường**; **không xét khoảng trắng cuối** (khác với 1C:Enterprise language: "bb" và "bb " → False trong ngôn ngữ, True trong query). Không đảm bảo sắp xếp giống nhau trên các DBMS khác nhau.
  - Reference types và UUID: so sánh theo giá trị; chỉ đảm bảo lặp lại trong cùng một database.
  - Không hỗ trợ so sánh UUID với kiểu khác.
  - Không cho phép so sánh trường có độ dài không giới hạn (string không giới hạn, ValueStorage, trường ValueType của chart of characteristic types).
- So sánh có ít nhất một NULL → kết quả NULL. Điều kiện (WHERE, BY, WHEN) có kết quả NULL → không thỏa.

### Các toán tử
- **IN**: kiểm tra giá trị có khớp một trong các giá trị liệt kê hoặc trong kết quả của query khác; **Not** đảo ngược.
- **IN HIERARCHY**: True nếu giá trị bên trái là reference tới phần tử catalog và nằm trong tập bên phải hoặc thuộc phân cấp của một group trong tập đó.
- IN cho nhiều trường: với nested query, với value table (truyền value table làm tham số, dùng N cột đầu), hoặc danh sách trực tiếp.
- **BETWEEN**: kiểm tra giá trị bên trái có nằm trong khoảng bên phải; NOT đảo ngược.
- **IS NULL**: không dùng `=` để kiểm tra NULL vì `NULL = NULL` luôn trả về False. Thường dùng với LEFT JOIN để lấy các dòng bảng chính không có dòng phù hợp ở bảng nối.
- **REFS**: kiểm tra giá trị bên trái có phải reference tới bảng chỉ định bên phải.
- **LIKE**: so khớp chuỗi với template; không phân biệt hoa thường trên mọi DBMS; giá trị phải kiểu String. Ký tự đặc biệt:
  - `%`: chuỗi bất kỳ số ký tự.
  - `_`: một ký tự bất kỳ.
  - `[...]`: một ký tự bất kỳ trong ngoặc; có thể dùng khoảng như a–z (gồm cả biên).
  - `[^...]`: bất kỳ ký tự nào trừ các ký tự sau dấu phủ định.
  - Muốn dùng ký tự đặc biệt như ký tự thường: đặt special character trước nó; special character được định nghĩa sau từ khóa **ESCAPE**.
  - Ví dụ template `"A_[0-9][a-z]\_e%"`: chữ A/a, một ký tự bất kỳ, một chữ số, một chữ cái, ký tự gạch dưới, chữ E/e; phía trước có thể có chuỗi ký tự bất kỳ.

### Query result iteration methods
- `Select()` và `Unload()` đều có tham số tùy chọn **TabOrderType** (kiểu duyệt) với 3 giá trị: `Linear` (mặc định), `ByGroupsWithHierarchy`, `ByGroups`.
- Nếu query có TOTALS, kết quả là cây → dùng `QueryResultIteration.ByGroupsWithHierarchy`: `Unload()` trả về **ValueTree**; `Select()` trả về Selection chỉ duyệt được cấp đầu — để duyệt cấp tiếp theo, gọi `Select()` trên từng Selection.
- Selection có phương thức `Level()` trả về cấp hiện tại, bắt đầu từ 0.

### Temporary tables
- Dùng temporary tables giúp tăng hiệu năng và đơn giản hóa việc đọc query text.
- 2 thành phần: đối tượng **TempTablesManager** (lưu dữ liệu temporary tables) và cú pháp query language để tạo/dùng temporary tables.
- Có thể tạo nhiều instance TempTablesManager, mỗi instance có tập temporary tables riêng; trong một manager, tên mỗi temporary table phải duy nhất (cũng là ID). Tên phải đáp ứng yêu cầu đặt tên biến của 1C:Enterprise language.
- Tạo bằng constructor `New`. Temporary table tồn tại chừng nào manager còn tồn tại; xóa manager → xóa mọi temporary table trong đó. Đóng cưỡng bức bằng `Close()` → xóa mọi bảng, không dùng tiếp manager được nữa.
- Query liên kết với manager qua property **TempTablesManager** của query.
- Tạo từ dữ liệu database: dùng từ khóa **INTO** + tên temporary table, đặt sau selection list. Kết quả (QueryResult) của query đó có selection gồm một dòng một cột **Count** = số bản ghi đã đưa vào temporary table.
- Lỗi nếu: manager chưa được đặt, hoặc đã đóng, hoặc đã có bảng cùng tên trong manager.
- Hàm **RECORDAUTONUMBER()**: thêm cột chứa số duy nhất vào temporary table.
- Tạo từ external source: chỉ định tên tham số chứa external source trong danh sách nguồn. External sources: Value table, Tabular section, Query result. Nếu cột trong value table không chỉ định kiểu → lỗi; dùng cột không có kiểu trong biểu thức (ví dụ CASE, ISNULL) → cũng lỗi.
- **Important**: temporary table tạo từ external source → query đó không được dùng UNION, JOIN, và không được dùng trường là attributes của trường bảng nguồn (ví dụ chọn ref tới company từ external source thì không chọn được attribute Address của catalog Companies trong cùng query).
- Dùng temporary table có sẵn: đặt manager cho Query qua property TempTablesManager, rồi truy cập temporary table theo tên như bảng thường.
- **DROP** + tên bảng: hủy temporary table khi không còn cần (temporary tables tốn tài nguyên máy chạy DBMS, hoặc máy hiện tại nếu infobase dạng file). Bảng không tồn tại → lỗi.
- Debug query có temporary tables:
  - `Query.ExecuteBatchWithIntermediateData()`.
  - Lấy dữ liệu từ manager: sau khi thực thi, manager lưu mọi bảng đã thêm và chưa bị drop; truy cập theo index hoặc tên qua `TempTablesManager.Tables`; `GetData()` trả về query result, rồi dùng `Select()`/`Unload()`.

### Batch queries
- Các query text trong batch cách nhau bằng dấu `;`. Thực thi tuần tự; temporary table tạo ra tồn tại đến hết batch hoặc đến khi bị hủy trong batch.
- Nếu Query có TempTablesManager, các temporary tables chưa bị drop trong batch sẽ được lưu vào manager. Có thể dùng và drop trong batch các temporary tables đã có sẵn trong manager.
- `Execute()`: thực thi tất cả, trả về kết quả của query cuối cùng.
- `ExecuteBatch()`: thực thi tất cả, trả về mảng kết quả theo thứ tự query; query drop temporary table có kết quả là **Undefined** (cũng nằm trong mảng).
- Batch dùng để lấy nhiều tập dữ liệu (có thể không liên quan nhau) trong một lần gọi database — không chỉ để tạo temporary tables.

## Cú pháp & ví dụ code

Chọn tất cả trường:
```bsl
"SELECT
|   *
|FROM
…
```

Biểu thức làm selection field:
```bsl
"SELECT
|   Products.Product AS Product,
|   Products.Quantity AS Quantity,
|   Products.Price,
|   Products.Quantity * Products.Price AS Amount
```

Cú pháp tổng quát:
```bsl
SELECT [ALLOWED] [DISTINCT] [TOP <Count>]
<Selection field list>
[FROM <Source list>]
[WHERE <Filter condition>]
[GROUP BY <Grouping fields>]
[HAVING <Filter condition>]
[ORDER BY <Sorting fields>]
```

UNION ALL trong nested query rồi GROUP BY:
```bsl
"SELECT
|   ProductsAndServices.Ref AS Ref,
|   SUM(ProductsAndServices.ProductsAmount) AS ProductsAmount,
|   SUM(ProductsAndServices.ServicesAmount) AS ServicesAmount
|FROM
|   (SELECT
|       SalesInvoiceProducts.Ref AS Ref,
|       SalesInvoiceProducts.Amount AS ProductsAmount,
|       0 AS ServicesAmount
|   FROM
|       Document.SalesInvoice.Products AS SalesInvoiceProducts
|    
|   UNION ALL
|    
|   SELECT
|       SalesInvoiceServices.Ref,
|       0,
|       SalesInvoiceServices.Amount
|   FROM
|       Document.SalesInvoice.Services AS SalesInvoiceServices) AS ProductsAndServices
|        
|GROUP BY
|   ProductsAndServices.Ref"
```

DATEDIFF:
```bsl
DATEDIFF(<Date1>, <Date2>, <Type>)

DATEDIFF(Date1, Date2, Year), where Date1 = 31.12.2021 15:00:00 and Date2 = 01.01.2022 13:00:00
DATEDIFF(Date1, Date2, Year), where Date1 = 01.01.2021 14:00:00 and Date2 = 31.12.2022 18:00:00
```

VALUETYPE:
```bsl
VALUETYPE(<Expression>)
```

Selection operation (CASE):
```bsl
CASE
<Selection alternatives>
[ELSE <Expression>]
END

WHEN <Logical expression>
THEN <Expression>
```

Type casting:
```bsl
CAST(<Expression> AS <Value type>)
```

Literals:
```bsl
TRUE
FALSE
<NUMBER type literal> (<Integer>[.<Integer>])
<STRING type literal> (<Character sequence>)
<DATE type literal> (DATETIME(<Integer>, <Integer>, <Integer>[, <Integer>, <Integer>, <Integer>])
<TYPE type literal> (TYPE(<Type name>))
<Parameter name> (&ParameterName)
UNDEFINED
NULL
```

Number:
```bsl
"SELECT
|	10 AS Integer,
|	12.45 AS Float"
```

String:
```bsl
"SELECT
|	""123abc"" AS FirstString,
|	""abcdefghijklmnop"" AS SecondString"
```

Date:
```bsl
"SELECT
|	DATETIME(2023, 12, 31) AS NewYearEve,
|	DATETIME(2024, 1, 1, 8, 30, 0) AS NewYearMorning"
```

Parameter:
```bsl
"SELECT
|	Products.Description AS Description,
|	Products.Type AS Type,
|	Products.Weight AS Weight
|FROM
|	Catalog.Products AS Products
|WHERE
|	Products.Ref = &Product"
```

Type:
```bsl
TYPE(String)
TYPE(Catalog.Products)

"SELECT
|	Counterparties.Description AS Description,
|	Counterparties.Contact AS Contact
|FROM
|	Catalog.Counterparties AS Counterparties
|WHERE
|	VALUETYPE(Counterparties.Contact) = TYPE(Catalog.Contacts)"
```

IN với danh sách giá trị:
```bsl
"SELECT
|	SalesInvoice.Ref AS Ref
|FROM
|	Document.SalesInvoice AS SalesInvoice
|WHERE
|	SalesInvoice.State IN (VALUE(Enum.SalesInvoiceStates.InDelivery), 
|					VALUE(Enum.SalesInvoiceStates.Finished))"
```

IN HIERARCHY:
```bsl
"SELECT
|	Products.Description
|FROM
|	Catalog.Products AS Products
|WHERE
|	Products.Ref IN HIERARCHY(&Group)"
```

IN HIERARCHY với query description:
```bsl
"SELECT
|	Products.Description
|FROM
|	Catalog.Products AS Products
|WHERE
|	Products.Ref IN HIERARCHY
|	(SELECT
|		Products.Ref
|	FROM
|		Catalog.Products AS Products
|	WHERE
|		Products.Description = ""Tools"")"
```

IN với kết quả query:
```bsl
// Select names of the products that were present in sales invoice documents
"SELECT
|	Products.Description AS Description
|FROM
|	Catalog.Products AS Products
|WHERE
|	Products.Ref IN
|		(SELECT
|			SalesInvoiceProducts.Product
|		FROM
|			Document.SalesInvoice.Products AS SalesInvoiceProducts)"
```

NOT IN:
```bsl
// Select names of the products that were present in sales invoices
"SELECT
|	Products.Description AS Description
|FROM
|	Catalog.Products AS Products
|WHERE
|	NOT Products.Ref IN
|		(SELECT
|			SalesInvoiceProducts.Product
|		FROM
|			Document.SalesInvoice.Products AS SalesInvoiceProducts)"
```
[ghi chú ngoài nguồn] Comment của ví dụ NOT IN trong tài liệu gốc giữ nguyên như ví dụ IN; về ý nghĩa, query này chọn các product KHÔNG có trong sales invoices.

IN cho nhiều trường — nested query:
```bsl
(expression1, expression2, …, expressionN) IN (SELECT expression1, expression2, …, expressionN FROM <DataSource>)

// Select PurchaseInvoice documents with company and vendor information, but only those in which the Company + Responsible coincides with the Company + Responsible of SalesInvoice documents
"SELECT
|	PurchaseInvoice.Ref AS Ref,
|	PurchaseInvoice.Company AS Company,
|	PurchaseInvoice.Vendor AS Vendor
|FROM
|	Document.PurchaseInvoice AS PurchaseInvoice
|WHERE
|	(PurchaseInvoice.Company, PurchaseInvoice.Responsible) IN
|			(SELECT
|				SalesInvoice.Company,
|				SalesInvoice.Responsible
|			FROM
|				Document.SalesInvoice AS SalesInvoice)"
```

IN — value table:
```bsl
(expression1, expression2, …, expressionN) IN (&Parameter)
```

IN — danh sách trực tiếp trong điều kiện:
```bsl
(expression1) IN ("Some string", 123, DATETIME(2023, 12, 31), True, VALUE(<MetadataClassName.MetadataObjectName.PredefinedValue>))

// Select sales documents in which the status is equal to one of several enumeration values
"SELECT
|	SalesInvoice.Ref AS Ref,
|	SalesInvoice.State AS State
|FROM
|	Document.SalesInvoice AS SalesInvoice
|WHERE
|	SalesInvoice.State IN (
|		VALUE(Enum.SalesInvoiceStates.Planned), 
|		VALUE(Enum.SalesInvoiceStates.InDelivery)
|	)"
```

BETWEEN:
```bsl
"SELECT
|	SalesInvoice.Ref AS SalesInvoice
|FROM
|	Document.SalesInvoice AS SalesInvoice
|WHERE
|	SalesInvoice.Date BETWEEN DATETIME(2023, 1, 1) AND &EndPeriod"
```

IS NULL:
```bsl
"SELECT
|	NULL IS NULL AS CorrectChecking,
|	NULL = NULL AS IncorrectChecking"
```

LEFT JOIN + IS NULL (bank accounts không dùng trong contract nào):
```bsl
"SELECT
|	BankAccounts.Ref AS Ref,
|	BankAccounts.Owner AS Owner
|FROM
|	Catalog.BankAccounts AS BankAccounts
|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
|		ON BankAccounts.Ref = CounterpartyContracts.BankAccount
|WHERE
|	CounterpartyContracts.Ref IS NULL"
```

REFS:
```bsl
"SELECT
|	Counterparties.Description AS Description,
|	Counterparties.Contact AS Contact
|FROM
|	Catalog.Counterparties AS Counterparties
|WHERE
|	Counterparties.Contact REFS Catalog.Contacts"
```

LIKE:
```bsl
"SELECT
|	Counterparties.Ref AS Ref,
|	Counterparties.Contact AS Contact
|FROM
|	Catalog.Counterparties AS Counterparties
|WHERE
|	Counterparties.Contact LIKE ""M[rs][.]%[#][0-9]%"""
```

Unload kết quả có TOTALS vào Value tree:
```bsl
ValueTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
```

TempTablesManager:
```bsl
TempTablesManager = New TempTablesManager;
```

```bsl
Query = New Query;

// Creating a manager into a separate variable
TempTablesManager = New TempTablesManager;
Query.TempTablesManager = TempTablesManager;

// Creating a manager directly into the query property
Query.TempTablesManager = New TempTablesManager;
```

INTO:
```bsl
"SELECT
|   SalesInvoiceProducts.Product AS Product,
|   SalesInvoiceProducts.Ref AS SalesInvoice
|INTO ProductsByDocuments
|FROM
|   Document.SalesInvoice.Products AS SalesInvoiceProducts"
```

RECORDAUTONUMBER():
```bsl
"SELECT
|   SalesInvoiceProducts.Ref AS SalesInvoice,
|   SalesInvoiceProducts.Product AS Product,
|   RECORDAUTONUMBER() AS RecordNumber
|INTO TempTableProducts
|FROM
|   Document.SalesInvoice.Products AS SalesInvoiceProducts"
```

DROP:
```bsl
DROP TempTableProducts
```

Debug — lấy dữ liệu temporary table từ manager:
```bsl
TempTablesManager = New TempTablesManager;
Query = New Query;
Query.TempTablesManager = TempTablesManager;
Query.Text = 
    "SELECT
    |   SalesInvoiceProducts.Product AS Product,
    |   SalesInvoiceProducts.Ref AS SalesInvoice,
    |   SalesInvoiceProducts.Quantity AS Quantity,
    |   SalesInvoiceProducts.Amount AS Amount
    |INTO TempTableProducts
    |FROM
    |   Document.SalesInvoice.Products AS SalesInvoiceProducts";
QueryResult = Query.Execute();

// Get data from temp table of temp tables manager and then unload the query result to a ValueTable
SalesInvoicesProducts = TempTablesManager.Tables["TempTableProducts"].GetData().Unload(); // Option 1
SalesInvoicesProducts = TempTablesManager.Tables[0].GetData().Unload(); // Option 2
```

Batch query với temporary tables:
```bsl
Query = New Query;
Query.Text = 
"SELECT
|   PurchaseInvoiceProducts.Product AS Product,
|   MAX(PurchaseInvoiceProducts.Price) AS PriceOfPurchase
|INTO TempTablePurchasedProducts
|FROM
|   Document.PurchaseInvoice.Products AS PurchaseInvoiceProducts
|WHERE
|   PurchaseInvoiceProducts.Ref.Posted
|
|GROUP BY
|   PurchaseInvoiceProducts.Product
|;
|
|////////////////////////////////////////////////////////////////////////////////
|SELECT
|   SalesInvoiceProducts.Product AS Product,
|   MAX(SalesInvoiceProducts.Price) AS PriceOfSale
|INTO TempTableSoldProducts
|FROM
|   Document.SalesInvoice.Products AS SalesInvoiceProducts
|WHERE
|   SalesInvoiceProducts.Ref.Posted
|
|GROUP BY
|   SalesInvoiceProducts.Product
|;
|
|////////////////////////////////////////////////////////////////////////////////
|SELECT
|   TempTableSoldProducts.Product AS Product,
|   TempTableSoldProducts.PriceOfSale AS PriceOfSale,
|   TempTablePurchasedProducts.PriceOfPurchase AS PriceOfPurchase
|FROM
|   TempTablePurchasedProducts AS TempTablePurchasedProducts
|       INNER JOIN TempTableSoldProducts AS TempTableSoldProducts
|       ON TempTablePurchasedProducts.Product = TempTableSoldProducts.Product"; 
QueryResult = Query.Execute();
```

ExecuteBatch():
```bsl
Query = New Query;
Query.Text = 
"SELECT
|   PurchaseInvoiceProducts.Product AS Product,
|   SUM(PurchaseInvoiceProducts.Quantity) AS Quantity
|FROM
|   Document.PurchaseInvoice.Products AS PurchaseInvoiceProducts
|WHERE
|   PurchaseInvoiceProducts.Ref.Posted
|
|GROUP BY
|   PurchaseInvoiceProducts.Product
|;
|
|////////////////////////////////////////////////////////////////////////////////
|SELECT
|   SalesInvoiceProducts.Product AS Product,
|   SUM(SalesInvoiceProducts.Quantity) AS Quantity
|FROM
|   Document.SalesInvoice.Products AS SalesInvoiceProducts
|WHERE
|   SalesInvoiceProducts.Ref.Posted
|
|GROUP BY
|   SalesInvoiceProducts.Product";
QueryBatch = Query.ExecuteBatch(); // array with 2 query results
Purchases   = QueryBatch[0].Select();
Sales       = QueryBatch[1].Select();
```

[ghi chú ngoài nguồn] Một số ví dụ trong tài liệu gốc (query hợp đồng còn hiệu lực theo counterparty, HAVING, nested table trong selection, các ví dụ join, CASE, CAST, TOTALS, temporary table từ external source, dùng temporary table ở query 2) chỉ có dạng ảnh chụp màn hình, không có văn bản code nên không được chép lại. → ví dụ dùng temporary table ở query 2 → xem mục Code demo của bài Theory (nhánh lesson/10-theory); nested table, join, CASE, TOTALS → luyện qua Thẻ gợi ý bài thực hành; HAVING, CAST, query hợp đồng theo counterparty, temporary table từ external source vẫn chưa có.

## Thuộc tính/thiết lập quan trọng trong Designer
- Query object: property **Text**, **TempTablesManager**; methods **SetParameter()**, **Execute()**, **ExecuteBatch()**, **ExecuteBatchWithIntermediateData()**.
- QueryResult: **Select()**, **Unload()** (tham số TabOrderType: **Linear**, **ByGroupsWithHierarchy**, **ByGroups**).
- Selection: **Level()**.
- TempTablesManager: **Close()**, **Tables** (truy cập theo tên hoặc index), **GetData()**.
- Query wizard: tab **Tables and fields**, **Order** (node **All fields**, cột **Sort**), **Links** (flag **All**); biến thể **query wizard with result processing** có thêm tab **result processing**.
- Hàm hỗ trợ được dùng trong ví dụ: **BegOfDay()** (đưa ngày hiện tại về đầu ngày khi đặt tham số &StartDate, &EndDate).

## Lỗi thường gặp / lưu ý
- Dùng **query wizard with result processing** sau khi đã sửa code xung quanh → code tự viết bị thay bằng code chuẩn. Chỉ dùng biến thể này trước khi sửa code; sau đó chỉ dùng **query wizard** để sửa query text.
- Không dùng **DISTINCT** khi không cần (ví dụ chắc chắn không có bản ghi trùng) — tạo tải thêm, ảnh hưởng hiệu năng với dữ liệu lớn.
- Không dùng aggregate function trong WHERE — dùng HAVING. Đặt điều kiện tổng vào WHERE sẽ áp cho từng bản ghi riêng → kết quả sai.
- Không dùng subqueries trong filter conditions của join — làm chậm query đáng kể, có thể gây lỗi trên một số DBMS.
- Chỉ dùng nested queries khi không có join với bảng khác hoặc chắc chắn các bảng nối có rất ít bản ghi.
- Nối document với nhiều tabular section cùng lúc qua Ref → nhân dòng, tổng sai.
- UNION với số trường khác nhau → lỗi (query wizard không mở được).
- Grouping áp riêng cho từng query trong union — phải group lại kết quả union qua nested query.
- CAST sang kiểu không có trong composite type → query lỗi.
- Không dùng `=` để kiểm tra NULL (`NULL = NULL` → False); dùng IS NULL.
- So sánh string trong query bỏ qua khoảng trắng cuối và không phân biệt hoa thường — khác 1C:Enterprise language.
- LIKE ở chế độ client/server có thể không thực thi nếu template quá dài (giới hạn phụ thuộc DBMS).
- Value table dùng làm nguồn temporary table phải có kiểu cột; cột không có kiểu dùng trong CASE/ISNULL → lỗi.
- Temporary table từ external source: không dùng UNION, JOIN, attributes của trường nguồn trong cùng query.
- Tạo temporary table khi manager chưa đặt / đã đóng / trùng tên → lỗi. DROP bảng không tồn tại → lỗi.
- Tạo temporary table cẩn thận khi dữ liệu lớn; drop khi không còn cần.
- Value table nằm trong RAM — dữ liệu lớn tốn bộ nhớ.

## Điểm cần nhớ
- SELECT là từ khóa bắt buộc duy nhất; thứ tự: SELECT [ALLOWED] [DISTINCT] [TOP] → FROM → WHERE → GROUP BY → HAVING → ORDER BY (TOTALS ở cuối).
- `Execute()` → QueryResult → `Select()` (Selection, từng dòng) hoặc `Unload()` (ValueTable, toàn bộ trong RAM).
- Join: INNER (chỉ khớp), LEFT (tất cả bên trái, NULL nếu không khớp), FULL (tất cả hai bên); RIGHT được wizard đổi thành LEFT.
- UNION loại trùng, UNION ALL giữ tất cả; số trường phải bằng nhau; tên trường theo query đầu.
- HAVING lọc trên aggregate; WHERE lọc trên từng bản ghi.
- NULL: kiểm tra bằng IS NULL; mọi so sánh có NULL → NULL → điều kiện không thỏa.
- Temporary tables: TempTablesManager + INTO; DROP để giải phóng; batch cách nhau bằng `;`; ExecuteBatch() trả mảng kết quả.
- Query có TOTALS → duyệt bằng QueryResultIteration.ByGroupsWithHierarchy (Unload → ValueTree).

## Thẻ gợi ý bài thực hành (Practice 10)

> Thẻ gợi ý dẫn hướng cho từng yêu cầu của 10. Practice.docx; không có lời giải hoàn chỉnh. Làm theo thứ tự Gợi ý 1 → 2 → 3, chỉ mở gợi ý sau khi đã thử tự làm.

### Bài tập 1 — Object Warehouses và attribute Warehouse trong PurchaseInvoice / SalesInvoice
- **Đề bài (tóm tắt):** Chọn loại metadata object phù hợp để lưu danh sách kho (Warehouses), thêm attribute **Warehouse** vào PurchaseInvoice và SalesInvoice và đặt field lên form của hai document.
- **Gợi ý 1 — Hướng đi:** Danh sách kho là dữ liệu tham chiếu (master data) được nhiều document dùng lại → là **Catalog**, không phải document hay register.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Catalog `Warehouses` (Code, Description là đủ cho bài này); attribute `Warehouse` kiểu `CatalogRef.Warehouses` trong cả hai document; trên document form kéo attribute từ cây `Object` vào nhóm header.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo catalog `Warehouses`, đặt synonym số ít/số nhiều.
  2. Mở PurchaseInvoice → tab Data → thêm attribute `Warehouse`, chọn kiểu.
  3. Làm tương tự cho SalesInvoice.
  4. Mở document form của từng document, kéo field `Warehouse` lên header.
- **Lỗi hay gặp:**
  - Thêm attribute vào metadata nhưng quên đặt field lên form → user không nhập được.
  - Chọn kiểu String cho Warehouse thay vì reference → không chọn được từ danh sách, dễ gõ sai tên kho.
- **Tự kiểm tra:** Ở Enterprise mode tạo 2 kho, mở Purchase invoice và Sales invoice, chọn được kho từ danh sách và lưu được document.

### Bài tập 2 — Subsystem Warehouse
- **Đề bài (tóm tắt):** Thêm subsystem mới **Warehouse** và đưa catalog Warehouses vào đó.
- **Gợi ý 1 — Hướng đi:** Subsystem quyết định object xuất hiện ở section nào của command interface.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Nhánh Common → Subsystems → thêm `Warehouse`; trên tab Content của subsystem chọn `Catalog.Warehouses` (hoặc từ catalog: tab Subsystems → đánh dấu `Warehouse`).
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo subsystem, đặt synonym.
  2. Đưa `Warehouses` vào content.
  3. Cập nhật database configuration và mở Enterprise mode.
- **Lỗi hay gặp:**
  - Subsystem rỗng hoặc tắt "Include in command interface" → không thấy section mới.
- **Tự kiểm tra:** Section "Warehouse" xuất hiện trên sections panel và mở được list form của Warehouses.

### Bài tập 3 — Document InventoryTransfer
- **Đề bài (tóm tắt):** Tạo document chuyển hàng giữa hai kho: attributes **WarehouseSender**, **WarehouseRecipient**, tabular section **Products** (Product, Quantity); đưa vào subsystem Warehouse.
- **Gợi ý 1 — Hướng đi:** Mỗi lần chuyển hàng là một nghiệp vụ có ngày, số → **Document**; danh sách hàng chuyển là **tabular section**.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Document `InventoryTransfer`; hai attributes kiểu `CatalogRef.Warehouses`; tabular section `Products` với `Product` (`CatalogRef.Products`) và `Quantity` (Number); tab Subsystems → `Warehouse`.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo document, đặt synonym, numbering mặc định.
  2. Thêm 2 attributes kho và tabular section Products với 2 cột.
  3. Đưa document vào subsystem Warehouse.
  4. Tạo document form và list form (Form wizard).
- **Lỗi hay gặp:**
  - Đặt Quantity không có độ chính xác phù hợp (Length/Precision) → nhập số lẻ bị cắt.
  - Quên đưa vào subsystem → không mở được từ giao diện.
- **Tự kiểm tra:** Tạo và lưu được một Inventory transfer có 2 dòng hàng trong section Warehouse.

### Bài tập 4 — Bố cục form InventoryTransfer (2 cột header)
- **Đề bài (tóm tắt):** Header gồm 2 cột: trái có dòng 1 Number + Date, dòng 2 WarehouseSender; phải có WarehouseRecipient nằm ngang hàng với WarehouseSender.
- **Gợi ý 1 — Hướng đi:** Bố cục form điều khiển bằng **group** lồng nhau: group ngang chứa hai group dọc; khoảng trống được tạo bằng label decoration không có title (đúng gợi ý của đề).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form editor → tab Elements: một `UsualGroup` có Group = **AlwaysHorizontal** (header), bên trong hai `UsualGroup` Group = **Vertical** (trái, phải); trong group trái thêm group ngang cho Number + Date; ở group phải đặt `LabelDecoration` rỗng phía trên WarehouseRecipient, chỉnh property **Font** (cỡ chữ) để decoration cao bằng dòng Number/Date. Tắt hiển thị title/viền của group nếu cần (ShowTitle, Representation).
- **Gợi ý 3 — Khung bài làm:**
  1. Thêm group header ngang, kéo các field hiện có vào.
  2. Tạo group trái (dọc) và group phải (dọc).
  3. Trong group trái: group ngang Number/Date, rồi WarehouseSender.
  4. Trong group phải: decoration rỗng, rồi WarehouseRecipient.
  5. Xem trước bằng Enterprise mode, chỉnh Font của decoration tới khi thẳng hàng.
- **Lỗi hay gặp:**
  - Dùng Group = Horizontal (không phải AlwaysHorizontal) → khi form hẹp, nền tảng có thể xếp lại thành dọc.
  - Decoration có title → hiện chữ thừa.
- **Tự kiểm tra:** Mở document form ở Enterprise mode, WarehouseRecipient nằm đúng ngang hàng WarehouseSender khi thay đổi kích thước cửa sổ.

### Bài tập 5 — Nút "Pick" trên InventoryTransfer
- **Đề bài (tóm tắt):** Thêm nút "Pick" chọn hàng vào tabular section, hoạt động giống ở Purchase invoice / Sales invoice.
- **Gợi ý 1 — Hướng đi:** Mở choice form của Products ở chế độ chọn nhiều lần (không đóng sau mỗi lần chọn), kết quả trả về form owner là bảng Products, xử lý trong event **ChoiceProcessing** của bảng — đúng như đã làm ở hai document kia (Bài 9).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Form command `Pick` (handler `&AtClient`), nút trên command bar của bảng Products; `OpenForm("Catalog.Products.ChoiceForm", ...)` với tham số structure `CloseOnChoice` = False và Filter theo loại product là hàng hóa (InventoryItem); event `ProductsChoiceProcessing` của item bảng: tìm dòng đã có bằng `FindRows`, nếu chưa có thì thêm dòng, Quantity = 1.
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtClient
Procedure ___(Command)
	// mở choice form của Products: owner = ___, CloseOnChoice = ___,
	// Filter chỉ lấy hàng hóa (không lấy service)
EndProcedure

&AtClient
Procedure ___(Item, SelectedValue, StandardProcessing)
	// tìm SelectedValue trong Object.Products bằng ___
	// nếu chưa có: thêm dòng, gán Product = ___, Quantity = ___
EndProcedure
```
- **Lỗi hay gặp:**
  - Không truyền owner (item bảng) cho `OpenForm` → event ChoiceProcessing không được gọi.
  - Không kiểm tra dòng trùng → cùng một product xuất hiện nhiều dòng.
  - So sánh enumeration trên client mà không dùng `PredefinedValue(...)`.
- **Tự kiểm tra:** Bấm Pick, chọn liên tiếp 3 product (có một product chọn 2 lần) → bảng có 3 dòng, không trùng, Quantity = 1; service không xuất hiện trong danh sách chọn.

### Bài tập 6 — Nút "Fill in by the remaining goods" (batch query với temporary tables)
- **Đề bài (tóm tắt):** Trên command bar của bảng Products: kiểm tra đã điền kho gửi; nếu bảng có dòng thì hỏi xác nhận (ShowQueryBox); nếu đồng ý thì xóa và điền số dư hàng tại ngày document = tổng mua đã post − tổng bán đã post, bằng **query batch** gồm temporary table Purchases, temporary table Sales và query cuối lấy hiệu.
- **Gợi ý 1 — Hướng đi:** Phần client (kiểm tra kho, hỏi user, callback) dùng đúng đoạn mẫu `CallbackDescription` / `ShowQueryBox` / `RunCallback` có sẵn trong đề. Phần server dùng **Temporary tables** + **Batch queries** (xem mục Temporary tables, Batch queries, Joins và IS NULL ở phần lý thuyết): query 1 gom số lượng mua theo product INTO Purchases, query 2 gom số lượng bán INTO Sales, query 3 nối hai bảng tạm và lấy hiệu.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form command `FillInByTheRemainingGoods` (`&AtClient`), callback export `FillInByTheRemainingGoodsAnswer`, server procedure `FillInByTheRemainingGoodsAtServer` (`&AtServer`, vì cần chạy query và sửa `Object`).
  - Nguồn: tabular section `Document.PurchaseInvoice.Products` và `Document.SalesInvoice.Products`; điều kiện qua dấu chấm `...Ref.Posted` và `...Ref.Date < &Date`; `SUM(...)` + `GROUP BY Product`.
  - Query cuối: `Purchases` **LEFT JOIN** `Sales` theo Product; phần bán bọc bằng `ISNULL(..., 0)` vì product chưa bán sẽ ra NULL.
  - Nạp kết quả: `Object.Products.Load(<QueryResult>.Unload())` — tên cột kết quả phải trùng tên cột tabular section (Product, Quantity).
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtServer
Procedure FillInByTheRemainingGoodsAtServer()
	// Query.Text gồm 3 phần, cách nhau bằng ";"
	//  1) SELECT Product, SUM(Quantity) ... INTO ___ FROM tabular section mua, WHERE ___
	//  2) SELECT Product, SUM(Quantity) ... INTO ___ FROM tabular section bán, WHERE ___
	//  3) SELECT ... FROM Purchases LEFT JOIN Sales ON ___ (Quantity = mua - ISNULL(___))
	// SetParameter("Date", ___)
	// nạp kết quả query cuối vào Object.Products bằng ___
EndProcedure
```
- **Lỗi hay gặp:**
  - Quên điều kiện Posted → document chưa post (bản nháp) cũng bị tính.
  - Dùng `Sales.Quantity` trực tiếp, không `ISNULL` → dòng của product chưa bán có Quantity = NULL.
  - Đặt cả Purchases và Sales vào cùng một query bằng join tabular sections → nhân dòng, tổng sai (xem "Lỗi thường gặp" của bài).
  - Tham số `&Date` lấy theo ngày document: Purchases/Sales cùng giây với document không được tính khi dùng `<`; đây là chấp nhận được ở Bài 10.
  - [ghi chú ngoài nguồn] Đề bắt kiểm tra kho gửi nhưng công thức số dư trong đề không nhắc tới kho; lời giải tham khảo của khóa ở Bài 10 cũng không lọc theo kho (số dư chung mọi kho). Nếu muốn chính xác hơn, có thể thêm điều kiện theo attribute `Warehouse` của document mua/bán. Bài 11 sẽ viết lại thủ tục này để đọc từ accumulation register theo `WarehouseSender`.
- **Tự kiểm tra:** Tạo 2 Purchase invoice (post 1, để nháp 1) và 1 Sales invoice đã post → bấm nút, số lượng mỗi product = mua đã post − bán đã post; bấm lại khi bảng có dòng → hiện câu hỏi, chọn "No" thì bảng giữ nguyên. Đặt breakpoint trong procedure server để xem `Query.ExecuteBatch()` nếu muốn quan sát từng temporary table.

### Bài tập 7 — Catalog Banks
- **Đề bài (tóm tắt):** Catalog lưu danh sách ngân hàng, attributes **NationalCode**, Country, City, Address, CorrAccount.
- **Gợi ý 1 — Hướng đi:** Danh sách ngân hàng là master data → Catalog; Country có thể tham chiếu catalog Countries đã có.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Catalog `Banks`; NationalCode, City, Address, CorrAccount kiểu String; Country kiểu `CatalogRef.Countries`. NationalCode in đậm trong đề → nên đặt **Required field** = Display error.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo catalog, thêm 5 attributes.
  2. Đặt Required field cho NationalCode.
  3. Tạo item form, sắp xếp field hợp lý.
- **Lỗi hay gặp:**
  - Độ dài String quá ngắn cho Address/CorrAccount.
- **Tự kiểm tra:** Tạo một bank để trống NationalCode → không lưu được; điền đủ → lưu được.

### Bài tập 8 — Catalog BankAccounts (phụ thuộc Banks)
- **Đề bài (tóm tắt):** Danh sách tài khoản ngân hàng, không tồn tại nếu không gắn với một bank; attributes **AccountNumber**, OpeningDate, CloseDate.
- **Gợi ý 1 — Hướng đi:** "Không tồn tại nếu thiếu bank" → hoặc catalog **subordinate** (property Owners = Banks, standard attribute **Owner** bắt buộc), hoặc attribute Bank bắt buộc. [ghi chú ngoài nguồn] Ở 12. Practice, BankAccounts phải subordinate tới Companies/Counterparties, còn Bank là attribute bắt buộc — nếu chọn cách attribute ngay từ đầu thì Bài 12 sửa ít hơn.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Catalog `BankAccounts`; AccountNumber (String), OpeningDate, CloseDate (Date, phần Date only); Bank: `CatalogRef.Banks` với Required field.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo catalog, thêm các attributes.
  2. Quyết định cách liên kết với Banks và đặt kiểm tra bắt buộc.
  3. Tạo item form.
- **Lỗi hay gặp:**
  - Dùng kiểu Date có cả giờ cho OpeningDate/CloseDate.
  - Không đặt bắt buộc → lưu được tài khoản không có bank.
- **Tự kiểm tra:** Không lưu được bank account khi chưa chọn bank.

### Bài tập 9 — Subsystem Funds
- **Đề bài (tóm tắt):** Subsystem Funds chứa Banks và BankAccounts, có picture.
- **Gợi ý 1 — Hướng đi:** Giống Bài tập 2, thêm property **Picture** của subsystem.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Subsystem `Funds` → Content: Banks, BankAccounts (sau này thêm PaymentExpense, PaymentReceipt); property Picture: chọn từ thư viện picture hoặc common picture.
- **Gợi ý 3 — Khung bài làm:**
  1. Tạo subsystem, đặt synonym và Picture.
  2. Đưa hai catalog vào content.
- **Lỗi hay gặp:**
  - Quên picture → section hiện icon mặc định (đề yêu cầu có picture).
- **Tự kiểm tra:** Section Funds hiện với icon riêng, mở được hai list form.

### Bài tập 10 — Document PaymentExpense (tạo dựa trên PurchaseInvoice)
- **Đề bài (tóm tắt):** Document chi tiền: **BankAccount**, **Counterparty**, DocumentAmount, tabular section **PaymentDetails** (**Document** kiểu DocumentRef.PurchaseInvoice, **Amount**); thuộc Funds; tạo được dựa trên Purchase invoice: Counterparty = Vendor, thêm một dòng Document = invoice, Amount = Amount của invoice.
- **Gợi ý 1 — Hướng đi:** Phần "tạo dựa trên" là cơ chế **Generation** (tab Generation → Generated based on + event **Filling**) — được trình bày chi tiết ở Bài 11 (mục Generation); có thể đọc trước mục đó.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Document `PaymentExpense`, attributes và tabular section như đề; subsystem Funds.
  - Tab Generation → Generated based on: `Document.PurchaseInvoice`.
  - Object module, handler `Filling(FillingData, StandardProcessing)`: kiểm tra `TypeOf(FillingData)` là `DocumentRef.PurchaseInvoice`, gán header, thêm dòng vào `PaymentDetails`. Có thể dùng Generation settings wizard để sinh khung rồi sửa.
  - Tổng tiền của invoice: dùng attribute tổng tiền mà Purchase invoice của bạn đang có (ví dụ DocumentTotal) — đề gọi là "Purchase invoice Amount".
- **Gợi ý 3 — Khung bài làm:**
```bsl
Procedure Filling(FillingData, StandardProcessing)
	If TypeOf(FillingData) = Type("___") Then
		// header: Counterparty = ___ (Vendor của invoice)
		// PaymentDetails: thêm 1 dòng, Document = ___, Amount = ___
		// DocumentAmount = ___
	EndIf;
EndProcedure
```
- **Lỗi hay gặp:**
  - Không kiểm tra kiểu FillingData → lỗi khi tạo document mới bình thường (FillingData = Undefined).
  - Chạy lại Generation settings wizard sau khi đã sửa tay → code Filling bị thay toàn bộ.
  - [ghi chú ngoài nguồn] Cấu hình mẫu của khóa không có PaymentExpense/PaymentReceipt nên không có bản đối chiếu; tự kiểm tra kỹ bằng Enterprise mode.
- **Tự kiểm tra:** Mở một Purchase invoice → submenu Generate → Payment expense: Counterparty và dòng PaymentDetails được điền đúng.

### Bài tập 11 — Document PaymentReceipt (tạo dựa trên SalesInvoice)
- **Đề bài (tóm tắt):** Giống PaymentExpense nhưng cột Document kiểu DocumentRef.SalesInvoice; tạo dựa trên Sales invoice: Counterparty = Customer, một dòng với Document = invoice, Amount = tổng của invoice.
- **Gợi ý 1 — Hướng đi:** Cùng cơ chế Generation như Bài tập 10; có thể copy document PaymentExpense rồi đổi kiểu cột và nguồn Generation.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Document `PaymentReceipt`; Generated based on: `Document.SalesInvoice`; handler `Filling` kiểm tra kiểu `DocumentRef.SalesInvoice`, lấy `Customer`.
- **Gợi ý 3 — Khung bài làm:**
  1. Copy PaymentExpense → đổi tên, synonym.
  2. Đổi kiểu cột `PaymentDetails.Document`.
  3. Đổi Generated based on và điều kiện kiểu trong Filling, lấy Customer thay cho Vendor.
- **Lỗi hay gặp:**
  - Copy xong quên đổi kiểu trong `Type("...")` của Filling → không bao giờ điền.
- **Tự kiểm tra:** Từ Sales invoice → Generate → Payment receipt được điền Customer và một dòng đúng số tiền.

### Bài tập 12 — Nút "Fill in by balance" trên PaymentExpense / PaymentReceipt
- **Đề bài (tóm tắt):** Nếu chưa có counterparty → báo và dừng; nếu bảng có dòng → cảnh báo sẽ xóa và hỏi tiếp tục; nếu đồng ý → tìm mọi invoice đã post của counterparty chưa có trong payment document đã post nào, thêm vào bảng cùng số tiền.
- **Gợi ý 1 — Hướng đi:** Phần client giống hệt Bài tập 6 (ValueIsFilled → ShowQueryBox / RunCallback → callback). Phần server: query lấy invoices **không có** trong tabular section PaymentDetails của payment documents đã post — dùng **LEFT JOIN + IS NULL** (mục IS NULL của lý thuyết) hoặc `NOT IN (nested query)`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:**
  - Form command + callback export `&AtClient`; procedure điền `&AtServer`.
  - Query: bảng chính `Document.PurchaseInvoice` (hoặc SalesInvoice) lọc `Posted` và `Vendor`/`Customer = &Counterparty`; bảng nối `Document.PaymentExpense.PaymentDetails` với điều kiện nối gồm `...Ref.Posted`; WHERE phần bên phải `IS NULL`.
  - Đặt tên trường kết quả trùng tên cột tabular section (Document, Amount) để nạp bằng `Load(...Unload())`.
- **Gợi ý 3 — Khung bài làm:**
```bsl
&AtServer
Procedure ___()
	// SELECT invoice AS Document, tổng tiền AS Amount
	// FROM Document.___ AS Invoices
	//   LEFT JOIN tabular section PaymentDetails của payment AS Paid
	//   ON Paid.Document = ___ AND Paid.Ref.Posted
	// WHERE Invoices.Posted AND counterparty = &Counterparty AND Paid.___ IS NULL
	// nạp kết quả vào Object.PaymentDetails
EndProcedure
```
- **Lỗi hay gặp:**
  - Đặt điều kiện `Paid.Ref.Posted` vào WHERE thay vì điều kiện nối → LEFT JOIN thành INNER, mất đúng các dòng cần tìm.
  - Dùng `= NULL` thay cho `IS NULL`.
  - Không loại chính document đang sửa: nếu nó đã post, các invoice của nó bị coi là "đã thanh toán" — cân nhắc thêm điều kiện `Paid.Ref <> &Ref`.
- **Tự kiểm tra:** Có 3 invoice đã post của một counterparty, 1 invoice đã nằm trong payment đã post → nút điền đúng 2 dòng; đổi counterparty rỗng → hiện thông báo và không làm gì.

### Bài tập T1 — Sales order có tổng services không quá 1000
- **Đề bài (tóm tắt):** Query chọn các Sales order có tổng tiền services ≤ 1000.
- **Gợi ý 1 — Hướng đi:** Điều kiện trên **tổng** → aggregate + **HAVING**, không phải WHERE (mục "Lỗi thường gặp": không dùng aggregate trong WHERE).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Nguồn là tabular section services của document Sales order trong cấu hình của bạn (nếu chưa có document Sales order, áp dụng cho Sales invoice); `SUM(Amount)`, `GROUP BY Ref`, `HAVING SUM(...) <= 1000`. Viết trong query console hoặc query wizard.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// SELECT Services.Ref AS Document, SUM(___) AS AmountOfServices
// FROM Document.___.Services AS Services
// GROUP BY ___
// HAVING ___ <= 1000
```
- **Lỗi hay gặp:**
  - Document không có dòng service nào sẽ không xuất hiện (không có dòng để gom) — nếu muốn tính cả document "0 service" thì phải đi từ bảng document và LEFT JOIN.
- **Tự kiểm tra:** Đối chiếu kết quả với tổng tính tay của 2–3 document.

### Bài tập T2 — Sales order: services > 5000 và goods = 0
- **Đề bài (tóm tắt):** Chọn Sales order có tổng services > 5000 và tổng goods bằng 0.
- **Gợi ý 1 — Hướng đi:** Không join hai tabular sections trực tiếp qua Ref (nhân dòng, tổng sai). Gom từng tabular section riêng (nested query hoặc temporary table), rồi LEFT JOIN từ bảng document; "goods = 0" gồm cả trường hợp không có dòng goods → `ISNULL(..., 0) = 0`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Hai temporary tables (`INTO`) hoặc hai nested queries; `ISNULL`; điều kiện ở WHERE của query cuối.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// 1) SELECT Ref, SUM(Amount) AS ServicesAmount INTO ___ FROM ...Services GROUP BY Ref;
// 2) SELECT Ref, SUM(Amount) AS GoodsAmount INTO ___ FROM ...Products GROUP BY Ref;
// 3) SELECT Docs.Ref FROM Document.___ AS Docs
//      LEFT JOIN ___ ON ___   LEFT JOIN ___ ON ___
//    WHERE ISNULL(___, 0) > 5000 AND ISNULL(___, 0) = 0
```
- **Lỗi hay gặp:**
  - Join cả hai tabular sections cùng lúc → SUM bị nhân theo số dòng của bảng kia.
  - Dùng INNER JOIN cho phần goods → mất các document không có dòng goods (chính là các document cần tìm).
- **Tự kiểm tra:** Tạo một document chỉ có services 6000 và một document có services 6000 + 1 dòng goods → chỉ document đầu được chọn.

### Bài tập T3 — Products có tổng mua và tổng bán > 0 (TempTablesManager, chỉ document đã post)
- **Đề bài (tóm tắt):** Viết nhiều query riêng dùng chung một temporary table manager; query cuối chọn products có tổng mua > 0 và tổng bán > 0, chỉ tính Purchase Order và Sales Order đã post.
- **Gợi ý 1 — Hướng đi:** Đúng mẫu "TempTablesManager: tạo temporary table ở query 1, dùng ở query 2" của mục Code demo của bài Theory: nhiều object Query (hoặc nhiều lần Execute) dùng chung property `TempTablesManager`.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** `New TempTablesManager`; query 1 INTO bảng mua (lọc `Ref.Posted`), query 2 INTO bảng bán, query 3 **INNER JOIN** hai bảng tạm và điều kiện > 0. Code đặt trong server procedure (ví dụ common module server hoặc form `&AtServer`).
- **Gợi ý 3 — Khung bài làm:**
```bsl
// Manager = New ___;
// Query1.TempTablesManager = ___;  Query1.Text = "... INTO PurchasesTotals ..."; Execute
// Query2.TempTablesManager = ___;  Query2.Text = "... INTO SalesTotals ...";     Execute
// Query3: SELECT ... FROM PurchasesTotals INNER JOIN SalesTotals ON ___
//         WHERE ___ > 0 AND ___ > 0
```
- **Lỗi hay gặp:**
  - Query sau không gán cùng manager → lỗi "table not found".
  - Tạo temporary table trùng tên lần hai trên cùng manager → lỗi (DROP hoặc đóng manager trước).
- **Tự kiểm tra:** Trong debugger xem `Manager.Tables[0].GetData().Unload()` để kiểm tra từng bảng tạm trước khi chạy query cuối.

### Bài tập T4 — Products: từ lần mua cuối tới lần bán cuối không quá một tuần
- **Đề bài (tóm tắt):** Chọn products mà khoảng cách giữa lần mua cuối và lần bán cuối ≤ 7 ngày.
- **Gợi ý 1 — Hướng đi:** "Lần cuối" = `MAX(Ref.Date)` theo product; sau đó so sánh hai ngày bằng **DATEDIFF** (mục Expressions — Built-in functions).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Hai nhóm dữ liệu (mua, bán) gom theo product bằng `MAX`; INNER JOIN theo product; `DATEDIFF(<ngày mua cuối>, <ngày bán cuối>, DAY)` trong WHERE.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// LastPurchase: SELECT Product, MAX(___) AS PurchaseDate ... GROUP BY Product
// LastSale:     SELECT Product, MAX(___) AS SaleDate ... GROUP BY Product
// SELECT ... FROM LastPurchase INNER JOIN LastSale ON ___
// WHERE DATEDIFF(___, ___, DAY) ___ 7
```
- **Lỗi hay gặp:**
  - Đảo thứ tự tham số DATEDIFF → số âm; cân nhắc trường hợp bán trước mua (giá trị âm) có tính hay không.
  - DATEDIFF chỉ tính chênh lệch theo đơn vị chỉ định — đọc lại ví dụ trong lý thuyết.
- **Tự kiểm tra:** Tạo một product mua ngày 1, bán ngày 5 và một product mua ngày 1, bán ngày 20 → chỉ product đầu được chọn.

### Bài tập T5 — Mua và bán theo document trong kỳ, kết quả hai cấp (TOTALS)
- **Đề bài (tóm tắt):** Query 4 trường Product, Document, Quantity, Amount (tổng theo document) cho mua và bán trong khoảng StartDate–EndDate; kết quả hai cấp: cấp 1 là tổng theo product; sắp xếp theo tên product.
- **Gợi ý 1 — Hướng đi:** Gộp mua và bán bằng **UNION ALL** (số trường phải bằng nhau), group lại kết quả union qua nested query hoặc temporary table, rồi thêm **TOTALS ... BY Product**; duyệt bằng `QueryResultIteration.ByGroups` / `ByGroupsWithHierarchy` (mục Query result iteration methods).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Trường Document có composite type (PurchaseInvoice hoặc SalesInvoice); điều kiện `Ref.Date BETWEEN &StartDate AND &EndDate`; `ORDER BY Product.Description`; `TOTALS SUM(Quantity), SUM(Amount) BY Product`.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// SELECT Product, Ref AS Document, SUM(Quantity), SUM(Amount) FROM ...mua WHERE ___ GROUP BY ___
// UNION ALL
// SELECT Product, Ref, SUM(Quantity), SUM(Amount) FROM ...bán WHERE ___ GROUP BY ___
// ORDER BY ___
// TOTALS SUM(___), SUM(___) BY ___
```
- **Lỗi hay gặp:**
  - Đặt ORDER BY/TOTALS vào từng phần của union thay vì cuối toàn bộ query.
  - Sắp xếp theo Product (reference) thay vì `Product.Description` → thứ tự không theo tên.
  - Ngày kết thúc kiểu Date lúc 00:00:00 làm mất document trong ngày cuối — dùng `EndOfDay`.
- **Tự kiểm tra:** Chạy trong query console, xem kết quả dạng cây: dòng product có tổng bằng tổng các dòng document bên dưới.

### Bài tập T6 — Products: Description + Details "This is a group" / "This is not a group"
- **Đề bài (tóm tắt):** Hai trường; Details hiển thị chuỗi tùy theo product là group hay item.
- **Gợi ý 1 — Hướng đi:** Selection operation **CASE WHEN ... THEN ... ELSE ... END** trên standard attribute **IsFolder** của catalog phân cấp.
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** `Catalog.Products` (Hierarchical, kiểu phân cấp folders and items); field `IsFolder`; chuỗi trong query đặt trong ngoặc kép (trong code 1C phải nhân đôi ngoặc kép).
- **Gợi ý 3 — Khung bài làm:**
```bsl
// SELECT Products.Description,
//   CASE WHEN ___ THEN ___ ELSE ___ END AS Details
// FROM Catalog.Products AS Products
```
- **Lỗi hay gặp:**
  - Viết chuỗi trong Query.Text mà quên nhân đôi ngoặc kép → lỗi cú pháp code 1C.
- **Tự kiểm tra:** Group và item đều xuất hiện với Details đúng.

### Bài tập T7 — Products KHÔNG nằm trong group có tên chứa "water"
- **Đề bài (tóm tắt):** Chọn products không thuộc (ở bất kỳ cấp nào) các group có description chứa từ "water".
- **Gợi ý 1 — Hướng đi:** **NOT IN HIERARCHY (nested query)** — nested query chọn các group có `Description LIKE "%water%"` (mục Các toán tử: IN HIERARCHY, LIKE).
- **Gợi ý 2 — Dùng gì, đặt ở đâu:** Nested query trên `Catalog.Products` với `IsFolder` và `LIKE`; query ngoài có `NOT ... IN HIERARCHY (...)`; cân nhắc loại group khỏi kết quả (`NOT IsFolder`) nếu chỉ muốn item.
- **Gợi ý 3 — Khung bài làm:**
```bsl
// SELECT Products.Ref FROM Catalog.Products AS Products
// WHERE NOT Products.Ref IN HIERARCHY (
//     SELECT Groups.Ref FROM Catalog.Products AS Groups
//     WHERE ___ AND Groups.Description LIKE ___ )
```
- **Lỗi hay gặp:**
  - Dùng `IN` thay cho `IN HIERARCHY` → chỉ loại item trực tiếp trong group, không loại item ở group con.
  - Template LIKE thiếu `%` ở hai đầu → chỉ khớp tên đúng bằng "water".
  - LIKE không phân biệt hoa thường — "Water" cũng khớp (đúng yêu cầu).
- **Tự kiểm tra:** Tạo group "Mineral water" có group con "Sparkling" chứa một item → item đó không có trong kết quả.

## Code demo của bài Theory (repo 1CJDCourse, nhánh lesson/10-theory)

> Phần query của Theory Bài 10 trong nhánh lesson/10-theory nằm ở common module `CommonServer` (Server). Function thứ hai `Qu()` của module trùng nguyên văn ví dụ `ExecuteBatch()` đã có ở mục "Cú pháp & ví dụ code" nên không chép lại.

### TempTablesManager: tạo temporary table ở query 1, dùng ở query 2
Nguồn: nhánh lesson/10-theory — cf/CommonModules/CommonServer/Ext/Module.bsl
```bsl
Function ContractSumsByCounterparties() Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
		"SELECT
		|	SalesInvoiceProducts.Product AS Product,
		|	SalesInvoiceProducts.Ref AS SalesInvoice,
		|	SalesInvoiceProducts.Quantity AS Quantity,
		|	SalesInvoiceProducts.Amount AS Amount
		|INTO TempTableProducts
		|FROM
		|	Document.SalesInvoice.Products AS SalesInvoiceProducts";

	QueryResult = Query.Execute();
	
	SecondQuery = New Query;
	SecondQuery.TempTablesManager = TempTablesManager;
	
	SecondQuery.Text = 
		"SELECT
		|	Products.Ref AS Product,
		|	SalesInvoiceProducts.SalesInvoice AS SalesInvoice,
		|	SalesInvoiceProducts.Quantity AS Quantity,
		|	SalesInvoiceProducts.Amount AS Amount
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN TempTableProducts AS SalesInvoiceProducts
		|		ON Products.Ref = SalesInvoiceProducts.Product";
	
	QueryResult = SecondQuery.Execute();
```
- Đúng ví dụ "dùng temporary table ở query 2" (trước đây chỉ có ảnh): hai object `Query` khác nhau dùng chung một `TempTablesManager` qua property `TempTablesManager`.
- Query 1 tạo bảng bằng `INTO TempTableProducts`; kết quả của nó chỉ có cột `Count`. Query 2 đọc `TempTableProducts` như bảng thường.
- `LEFT JOIN` từ `Catalog.Products`: product chưa bán vẫn có dòng, các trường từ temporary table là NULL.

### Đọc dữ liệu temporary table để debug, duyệt selection hai cấp, Level()
Nguồn: nhánh lesson/10-theory — cf/CommonModules/CommonServer/Ext/Module.bsl
```bsl
	// Get data from temp table and then unload the query result to a ValueTable
	ProductsFromSalesInvoices = TempTablesManager.Tables[0].GetData().Unload();
	
	SelectionProducts = QueryResult.Select();
	// First level selection
	While SelectionProducts.Next() Do
		SelectionDetailRecords = SelectionProducts.Select();
		
		Message("Total amount of product " + SelectionProducts.Product 
				+ " is " + SelectionProducts.Amount);
		
		// Second level selection
		While SelectionDetailRecords.Next() Do
			
			Message("Amount of product " + SelectionDetailRecords.Product 
					+ " at document " + SelectionDetailRecords.SalesInvoice 
					+ " is " + SelectionDetailRecords.Amount);
					
			// Current level of selection can be retrieved using the Level() method
			CurrentLevel = SelectionDetailRecords.Level();
		EndDo;
	
	EndDo;
	
	ValueTable = QueryResult.Unload();
	
EndFunction
```
- `TempTablesManager.Tables[0].GetData().Unload()` — cách xem dữ liệu temporary table khi debug: lấy bảng theo index, `GetData()` trả về query result, rồi `Unload()`.
- Selection lồng nhau: `SelectionProducts.Select()` lấy selection cấp con; `Level()` trả về cấp hiện tại.
- `QueryResult.Unload()` ở cuối đưa toàn bộ kết quả vào value table.
- [ghi chú ngoài nguồn] Query 2 không có `TOTALS`, nên selection không thực sự có nhóm (muốn có nhóm thật phải thêm `TOTALS` và duyệt bằng `QueryResultIteration.ByGroups` — xem mục Query result iteration methods và Bài tập T5 trong Thẻ gợi ý bài thực hành); function cũng không có `Return` — đây là code demo để quan sát trong debugger.
- [ghi chú ngoài nguồn] Nhánh lesson/10-theory không có code cho HAVING, CAST, query hợp đồng còn hiệu lực theo counterparty và temporary table từ external source.

## Video tham khảo (khóa Junior cũ)

Video trong playlist "Junior Developer Course" (1C Vietnam Academy, khóa cũ) có phạm vi trùng với bài này. Gọi là "video JC-<số>" (số bài của khóa cũ, khác số bài giáo trình); quy ước dẫn và độ tin cậy: `references/video-junior-course.md`.

- [JC-14 «Cơ bản về ngôn ngữ Query 1»](https://www.youtube.com/watch?v=wgEsimf_2ks&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=13) (11:42) — Bài 10 — SELECT, FROM, Query wizard
- [JC-37 «Danh sách động (Dynamic list)»](https://www.youtube.com/watch?v=rr_ohZ13H6k&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=36) (4:53) — Bài 9 — Dynamic list (bảng hoặc query tùy ý); Bài 10 — query language
- [JC-40 «Cơ bản về ngôn ngữ truy vấn 2»](https://www.youtube.com/watch?v=HJ2nTpet2yo&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=39) (5:33) — Bài 10 — parameters, Query wizard
- [JC-41 «Truy vấn SQL và cấu trúc truy vấn»](https://www.youtube.com/watch?v=E3EJ6WRG8Sk&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=40) (4:32) — Bài 10 — cấu trúc query; Bài 11 — virtual tables
- [JC-42 «Mệnh đề SELECT»](https://www.youtube.com/watch?v=gcvHm8ER72o&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=41) (6:34) — Bài 10 — SELECT, ISNULL, CASE, DISTINCT
- [JC-43 «FROM và WHERE»](https://www.youtube.com/watch?v=PtCdTq0a1nM&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=42) (5:58) — Bài 10 — FROM, WHERE; Bài 11 — lọc trong tham số virtual table
- [JC-44 «JOIN»](https://www.youtube.com/watch?v=Ukd1zPxIJqE&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=43) (7:23) — Bài 10 — LEFT / INNER / FULL JOIN
- [JC-45 «GROUP BY và HAVING»](https://www.youtube.com/watch?v=cCC-HVpGhJk&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=44) (5:10) — Bài 10 — GROUP BY, hàm tổng hợp, HAVING
- [JC-46 «Query trong ngôn ngữ 1C Script»](https://www.youtube.com/watch?v=Mws4QN1CdQY&list=PLp-gQ5Mgw0Zyp6VM4w9hZZQBtYrBpP5_P&index=45) (4:28) — Bài 10 — `New Query`, `.Text`, `SetParameter()`, `Execute()`, `Select()` / `Next()`, `Unload()`
