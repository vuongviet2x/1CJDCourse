#Region Internal

// Returns a template of a request to the Service Manager's external API.
//
// Parameters:
//  Method - String - Name of the Service Manager's external API method.
//  InterfaceType - String, Undefined - Type of the Service Manager's external API.
//                                         If not specified, it is set to "usr".
// 
// Returns:
//  String
//
Function ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType = Undefined) Export
	
	Address = "hs/ext_api/execute";
	
	If ServiceProgrammingInterfaceCached.ServiceManagerSupportsMethodInAddress() Then
		
		Return Address + "/" + ?(InterfaceType = Undefined, "usr", InterfaceType) + "/" + Method;
		
	EndIf;
	
	Return Address;
	
EndFunction

// Version of the ExtAPI HTTP service retrieved via the SSL API version mechanism.
// 
// Returns:
//  Number, Undefined - ExtAPI version. If a connection to the Service Manager is not configured, it is set to Undefined.
Function ServiceManagerExtAPIVersion() Export
	
	SetPrivilegedMode(True);
	
	If SaaSOperations.DataSeparationEnabled() Then
		If Not SaaSOperations.ServiceManagerEndpointConfigured() Then
			Return Undefined;
		EndIf;
		Versions = Common.GetInterfaceVersions(
			SaaSOperations.InternalServiceManagerURL(),
			SaaSOperations.ServiceManagerInternalUserName(),
			SaaSOperations.ServiceManagerInternalUserPassword(),
			"ExtAPI");
		If Not ValueIsFilled(Versions) Then
			Return 1;
		EndIf;
			
		Return Versions[Versions.UBound()];
	Else
		Return ServiceProgrammingInterfaceCached.InterfaceVersionProperties().Version;
	EndIf; 
	
EndFunction

// The Service Manager supports specifying methods in ExtAPI HTTP addresses.
// 
// Returns:
//  Boolean
Function ServiceManagerSupportsMethodInAddress() Export
	
	EXTAPIVersion = ServiceManagerExtAPIVersion();
	
	Return EXTAPIVersion <> Undefined And EXTAPIVersion >= 19;

EndFunction

// Returns a template of a request to the external Service Manager API.
//
// Parameters:
//  Method - String - Name of the Service Manager's external API method.
//  InterfaceType - String, Undefined - Type of the Service Manager's external API.
//                                         If not specified, it is set to "usr".
// 
// Returns:
//  Structure - Query template.:
//  * general - Structure:
//     ** type - String
//     ** method - String
//
Function QueryTemplate(Method, InterfaceType = Undefined) Export

	If ServiceProgrammingInterfaceCached.ServiceManagerSupportsMethodInAddress() Then
		Return New Structure;
	EndIf;
	
	MainParametersOfMethod = New Structure;
	MainParametersOfMethod.Insert("type", ?(InterfaceType = Undefined, "usr", InterfaceType));
	MainParametersOfMethod.Insert("method", Method);

	QueryTemplate = New Structure;
	QueryTemplate.Insert("general", MainParametersOfMethod);

	Return QueryTemplate;

EndFunction

// Sends a request to a service of the external Service Manager API.
//
// Parameters:
//  QueryData - Structure - Request data in the given format without the "auth" section.
//                               
//  Method - String - Name of the Service Manager's external API method.
//  InterfaceType - String, Undefined - Type of the Service Manager's external API.
//                                         If not specified, it is set to "usr".
//  AuthorizeSubscriber - Boolean - Flag indicating whether to add authentication for the current area user.
//   Authentication data is added prior to the request.
//
// Returns:
//  HTTPResponse - a response of a HTTP service of the Service manager. 
//
Function SendDataToServiceManager(QueryData, Method, InterfaceType = Undefined, AuthorizeSubscriber = True) Export

	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();
	Address = ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	
	If AuthorizeSubscriber Then
		If DataSeparationEnabled Then
			Subscriber = ServiceProgrammingInterface.SubscriberOfThisApplication();
			AuthorizationProperties = AuthorizationProperties(Subscriber.Code);
		Else
			AuthorizationData = AuthorizationDataInService();
			AuthorizationProperties = AuthorizationProperties(AuthorizationData.SubscriberCode);
		EndIf; 
	Else
		AuthorizationProperties = AuthorizationProperties();
	EndIf;
	
	QueryData.Insert("auth", AuthorizationProperties);
	
	If DataSeparationEnabled Then
		Result =  SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	Else
		Result = SendRequestToServiceFromLocalDatabase("POST", Address, QueryData);
	EndIf; 
	
	Return Result;

EndFunction

// Renames the response data fields by the renaming field map.
// 
// Parameters:
// 	ResponseData - Structure - Response data.
// 	Renamings - Map of KeyAndValue:
// 	* Key - String - Original field name.
// 	* Value  - See ColumnDetails
// 				- String - a column name.
// Returns:
// 	See RenameProperties.ResponseData
Function RenameProperties(ResponseData, Val Renamings) Export

	For Each Item In Renamings Do
		RenamingValue = Item.Value; // See ColumnDetails
		If TypeOf(RenamingValue) = Type("String") Then 
			FieldName = RenamingValue;
			FieldType = Undefined;
		Else
			FieldName = RenamingValue.Name;
			FieldType = RenamingValue.Type;
		EndIf;
		If ResponseData.Property(Item.Key) Then
			Value = ResponseData[Item.Key];
			ResponseData.Delete(Item.Key);
		Else
			Value = Undefined;
		EndIf;
		If FieldType <> Undefined Then
			Value = ValueByType(FieldType, Value);
		EndIf; 
			
		ResponseData.Insert(FieldName, Value);
		
	EndDo;

	Return ResponseData;

EndFunction

// Returns API respond data.
//
// Parameters:
// 	Response - HTTPResponse - HTTP response to process.
// 	RaiseExceptionAtError - Boolean - Error flag. Set if the response code is not 102xx.
// 	StatusCode - Number - Return parameter. The status code of an HTTP service response.
// 	ResponseCode - Number - Return parameter. Takes the value from the "general.response" property.
// 	Message - String - Return parameter. Takes the value from the "general.message" property.
//  
// Returns:
// 	Undefined, Structure - Result data.:
//   * Fields - Arbitrary - Arbitrary result fields.
Function ExecutionResult(Response, RaiseExceptionAtError = True,
		StatusCode = 0, ResponseCode = 0, Message = "") Export

	StatusCode = Response.StatusCode;
	If StatusCode <> 200 Then
		If RaiseExceptionAtError Then
			Raise StrTemplate("%1 %2", StatusCode, Response.GetBodyAsString());
		Else
			Return Undefined;
		EndIf;
	EndIf;

	DataStream = Response.GetBodyAsStream();
	DateNames = StrSplit("start,completion,planned_date,created,modified,activated,blocked,expiration,timestamp", ",", False);
	Data = SaaSOperationsCTL.StructureFromJSONStream(DataStream, DateNames);

	ResponseCode = Data.general.response;
	Message = Data.general.message;

	If Not (ResponseCode = 10200 Or ResponseCode = 10201 Or ResponseCode = 10202 Or ResponseCode = 10240) Then
		If RaiseExceptionAtError Then
			If ResponseCode <> 10404 Then
				Message = StrTemplate("%1 %2", ResponseCode, Message);
			EndIf; 
			Raise Message;
		Else
			Return Undefined;
		EndIf;
	EndIf;

	Return Data;

EndFunction

// Returns authentication properties for a request to the Service Manager's external API.
// 
// Parameters:
// 	SubscriberCode - Number
// 	User - CatalogRef.Users
// 	Token - String
// 	
// Returns:
// 	Structure:
//   * account - Number - Area subscriber code (number).
//  For SaaS authentication, also pass the following data:
//   * key - String - Area key.
//   * tenant - Number - Area number.
//   * hash - String - Password hash.
//   * login - String - Username.
//   * host - String - Host of the showcase that contains the application.
//   * type - String - Response type. For CTL, always "smtl".
//
Function AuthorizationProperties(SubscriberCode = Undefined,
	Val User = Undefined, Val Token = Undefined) Export

	AuthorizationProperties = New Structure;
	If ValueIsFilled(SubscriberCode) Then
		AuthorizationProperties.Insert("account", SubscriberCode);
	EndIf;
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		Return AuthorizationProperties;
	EndIf;
	
	If User = Undefined Then
		UserIdentificator = InfoBaseUsers.CurrentUser().UUID;
	Else
		UserIdentificator = Common.ObjectAttributeValue(User, "IBUserID");
	EndIf;

	AreaNumber = SaaSOperations.SessionSeparatorValue();
	
	SetPrivilegedMode(True);
	
	AccessKey = Constants.DataAreaKey.Get();
	
	// Read the user from the infobase as, after a password change, CurrentUser() contains the old password.
	CurrentUser = InfoBaseUsers.FindByUUID(UserIdentificator);

	If CurrentUser = Undefined And Token = Undefined Then
		// Administrator sends a request after the user has logged in to a data area.
		Administrator = InfoBaseUsers.CurrentUser();
		ExceptionPattern = NStr("ru = 'Запрос не может быть выполнен, т.к. вызывается от администратора информационной базы - %1 (%2).
								 |Возможно выполнение только от имени пользователя области - %3.';
								|en = 'Cannot execute the query as it is called from the infobase administrator - %1 (%2).
								|It can be executed only on behalf of area user - %3.';");
		Raise StrTemplate(ExceptionPattern, Administrator.Name, Administrator.FullName, Format(AreaNumber, "NG=0")); 
	EndIf;
	
	If CurrentUser = Undefined Then
	
		StoredPasswordValue = Token;
		
		If UserIdentificator <> CommonClientServer.BlankUUID() Then
			UserName = InfoBaseUsers.CurrentUser().Name;
		Else
			UserName = StrTemplate("service user (%1)", Left(New UUID, 8));
		EndIf;
	
	Else
		StoredPasswordValue = CurrentUser.StoredPasswordValue;
		UserName = CurrentUser.Name;
	EndIf;
	
	SetPrivilegedMode(False);

	ApplicationLocation = CommonClientServer.URIStructure(GetInfoBaseURL());

	AuthorizationProperties.Insert("type", "smtl");
	AuthorizationProperties.Insert("host", ApplicationLocation.Host);
	AuthorizationProperties.Insert("login", UserName);
	AuthorizationProperties.Insert("hash", StoredPasswordValue);
	AuthorizationProperties.Insert("tenant", AreaNumber);
	AuthorizationProperties.Insert("key", AccessKey);
	
	Return AuthorizationProperties;

EndFunction

// Send a request to the service from the local infobase.
// 
// Parameters:
//  Method - String
//  Address - String
//  Data - Structure:
//   * auth - Structure:
//      ** account - Number
//  ConnectionCache - Boolean
//  Timeout - Number
// 
// Returns:
//  HTTPResponse
Function SendRequestToServiceFromLocalDatabase(Method, Address, Data = Undefined, ConnectionCache = True, Timeout = 60) Export
	
	ServiceAddress = ServiceAddressFromLocalDatabase();
	
	FullAddress = StrTemplate("%1/%2", ServiceAddress, Address);
	ServerData = CommonClientServer.URIStructure(FullAddress);
	
	If ConnectionCache Then
		Join = ServiceProgrammingInterfaceCached.ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout);
	Else
		Join = ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout);
	EndIf;
	
	Query = New HTTPRequest(ServerData.PathAtServer);
	Query.Headers.Insert("Content-Type", "application/json; charset=utf-8");

	If TypeOf(Data) = Type("Structure") Then
		Data = SaaSOperationsCTL.StringFromJSONStructure(Data);
		Query.SetBodyFromString(Data);
	ElsIf TypeOf(Data) = Type("BinaryData") Then
		Query.SetBodyFromBinaryData(Data);
	ElsIf TypeOf(Data) = Type("String") Then
		Query.SetBodyFromString(Data);
	EndIf;

	Return Join.CallHTTPMethod(Method, Query);
	
EndFunction

// Service address from the local infobase.
// 
// Returns:
//  String - Service address from the local infobase.
Function ServiceAddressFromLocalDatabase() Export
	
	SetPrivilegedMode(True);
	ServiceAddress = Constants.Fresh1CServiceAddress.Get();
	
	If Not ValueIsFilled(ServiceAddress) Then
		ErrorText = NStr("ru = 'Не установлен адрес сервиса. Нужно установить адрес в настройках по ссылке: 
		|%1';
		|en = 'Service address is not specified. Set the address in the settings by reference:
		|%1';");
		LinkToSettings = "e1cib/data/DataProcessor.AdministrationPanelCTL.Form.FreshServiceConnectionSettings";
		Raise StrTemplate(ErrorText, LinkToSettings); 
	EndIf;
	
	Return ServiceAddress;

EndFunction

// Connection with the service manager from the local infobase.
// 
// Parameters:
//  ServerData - See CommonClientServer.URIStructure
//  Timeout - Number
// 
// Returns:
//  HTTPConnection
Function ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout = 60) Export
	
	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  New OpenSSLSecureConnection(, New OSCertificationAuthorityCertificates);
	Else
		SecureConnection = Undefined;
	EndIf;
	
	AuthorizationData = AuthorizationDataInService();
	Join = New HTTPConnection(ServerData.Host, ServerData.Port,
		AuthorizationData.Login, AuthorizationData.Password,
		GetFilesFromInternet.GetProxy(ServerData.Schema), Timeout, SecureConnection);

	Return Join;
	
EndFunction

// Returns authentication data for the given user.
// If no user is specified, it is set to the active user.
//
// Parameters:
//  User - CatalogRef.Users - If not passed, the current user is used.
//  
// Returns:
//  Structure:
//   * Login - String
//   * Password - String
//   * SubscriberCode - Number
//
Function AuthorizationDataInService(User = Undefined) Export
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf; 
	AuthorizationData = InformationRegisters.AuthorizationIn1cFresh.Read(User);
	If Not ValueIsFilled(AuthorizationData.Login) Then
		ErrorText = NStr("ru = 'Не установлены данные авторизации в сервисе. Нужно установить данные авторизации по ссылке:
						         |%1.';
								|en = 'Authorization data in the service is not specified. Set authorization data by reference:
								|%1.';");
		LinkToAuthorizationData = "e1cib/data/InformationRegister.AuthorizationIn1cFresh";
		Raise StrTemplate(ErrorText, LinkToAuthorizationData);
	EndIf; 
	
	Return AuthorizationData;
	
EndFunction
 
// Array of structures to the value table.
// 
// Parameters:
//  StructuresArray - Array of Structure:
//   * Fields - Arbitrary - Fields correspond to the table columns.
//  RenamingColumns - Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
// 
// Returns:
//  ValueTable:
//   * Fields - Arbitrary - Column set. Corresponds to the fields of the array structures.
Function StructuresArrayIntoValueTable(StructuresArray, RenamingColumns) Export
	
	Prefix = StrTemplate("%1_","Column"); // To avoid duplicates upon renaming.
	PrefixLength = StrLen(Prefix);
	
	Result = New ValueTable;
	For Each String In StructuresArray Do
		For Each KeyValue In String Do
			ColumnType = Undefined;
			RenamingValue = RenamingColumns.Get(KeyValue.Key);
			If ValueIsFilled(RenamingValue) And TypeOf(RenamingValue) = Type("Structure") Then
				ColumnType = RenamingValue.Type;
			EndIf;
			If Result.Columns.Find(Prefix + KeyValue.Key) = Undefined Then
				Result.Columns.Add(Prefix + KeyValue.Key, ColumnType);
			EndIf;
			If ColumnType <> Undefined Then
				String[KeyValue.Key] = ValueByType(ColumnType, KeyValue.Value);
			EndIf;
		EndDo;
		NewRow = Result.Add();
		For Each KeyAndValue In String Do
			NewRow[Prefix + KeyAndValue.Key] = String[KeyAndValue.Key];
		EndDo;
	EndDo;

	For Each Item In RenamingColumns Do
		If TypeOf(Item.Value) = Type("String") Then
			ColumnName = Item.Value;
			ColumnType = Undefined;
		Else
			ColumnName = Item.Value.Name;
			ColumnType = Item.Value.Type;
		EndIf;
		If Result.Columns.Find(Prefix + Item.Key) <> Undefined Then
			Column = Result.Columns[Prefix + Item.Key]; // ValueTableColumn
			Column.Name = ColumnName;
		Else
			Result.Columns.Add(ColumnName, ColumnType);
		EndIf;
	EndDo;
	
	For Each Column In Result.Columns Do
		If Left(Column.Name, PrefixLength) = Prefix Then
			Column.Name = Mid(Column.Name, PrefixLength + 1);
		EndIf;
	EndDo;

	Return Result;

EndFunction

// Value table to the structure array.
// 
// Parameters:
//  ValueTable - ValueTable:
//   * Fields - Arbitrary - Arbitrary list of fields.
// RenamingProperties - Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
// 
// Returns:
//  Array of Structure:
//   * Fields - Arbitrary - Fields correspond to the table columns.
Function TableOfValuesInArrayOfStructures(ValueTable, RenamingProperties) Export
	
	Result = New Array;
	For Each String In ValueTable Do
		Item = New Structure;
		For Each KeyValue In RenamingProperties Do
			Value = String[KeyValue.Value.Name];
			If KeyValue.Value.Type.ContainsType(Type("UUID")) Then
				Value = String(Value);
			EndIf; 
			Item.Insert(KeyValue.Key, Value);
		EndDo; 
		Result.Add(Item);
	EndDo; 
	
	Return Result;
	
EndFunction
 
#Region Subscriber

// Returns subscriber renaming fields.
//
// Parameters:
//  KI - Boolean - Add contact information fields.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - API field name.
//   * Value - See ColumnDetails
//
Function RenamingSubscriber(KI = False) Export
	
	Renamings = New Map;
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(64)));
	Renamings.Insert("id", ColumnDetails(
		"Code", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("email", ColumnDetails("Mail", Common.StringTypeDetails(500)));
	Renamings.Insert("public_id", ColumnDetails("PublicId", Common.StringTypeDetails(36)));
	If KI Then // Add contact information fields.
		Renamings.Insert("site", ColumnDetails("Website1", Common.StringTypeDetails(500)));
		Renamings.Insert("city", ColumnDetails("City", Common.StringTypeDetails(500)));
		Renamings.Insert("phone", ColumnDetails("Phone", Common.StringTypeDetails(500)));
	EndIf; 
	                                            
	Return Renamings;

EndFunction

// Renaming the "Subscriber users" table.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingSubscriberUsers() Export
	
	Renamings = New Map;
	Renamings.Insert("login", ColumnDetails(
		"Login", Common.StringTypeDetails(250)));
	Renamings.Insert("name", ColumnDetails(
		"FullName", Common.StringTypeDetails(150)));
	Renamings.Insert("email", ColumnDetails(
		"Mail", Common.StringTypeDetails(254)));
	Renamings.Insert("role", ColumnDetails(
		"UserRole", New TypeDescription("EnumRef.SubscriberUsersRoles")));
	Renamings.Insert("session_restriction", ColumnDetails(
		"AllowedNumberOfSessions", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("is_temporary", ColumnDetails(
		"TemporaryAccess", New TypeDescription("Boolean")));
	
	Return Renamings;
	
EndFunction
 
#EndRegion

#Region AccountingSystem

// Renaming the "Accounting system" object.
// 
// Parameters:
//  Method - String - API method name.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountingSystem(Method) Export
	
	Renamings = New Map;
	
	Renamings.Insert("id", ColumnDetails(
		"Code", Common.TypeDescriptionNumber(9, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(100)));
	Renamings.Insert("owner_id", ColumnDetails(
		"OwnerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("import", ColumnDetails("ImportingData",New TypeDescription("Boolean")));
	Renamings.Insert("import_login", ColumnDetails(
		"ImportingUserLogin", Common.StringTypeDetails(250)));
	Renamings.Insert("export", ColumnDetails("ExportingData",New TypeDescription("Boolean")));
	Renamings.Insert("export_url", ColumnDetails(
		"ExportingURL", Common.StringTypeDetails(150)));
	Renamings.Insert("export_login", ColumnDetails(
		"ExportingUserLogin", Common.StringTypeDetails(250)));
	
	If Method = "accounting_system/info" Then
		Renamings.Insert("description", ColumnDetails("LongDesc", New TypeDescription("String")));
		Renamings.Insert("export_rules", "ExportingRules");
		Renamings.Insert("import_rules", "ImportingRules");
		Renamings.Insert("response_processing_rules", "ResponseProcessingRules");
	EndIf;
	
	Return Renamings;
	
EndFunction
 
// Renaming the "Export rules" table of the "Accounting system" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountingSystemUploadRules() Export
	
	Renamings = New Map;
	
	Renamings.Insert("rule_id",  ColumnDetails(
		"RuleCode", Common.StringTypeDetails(120)));
	Renamings.Insert("rule_line_id",  ColumnDetails(
		"RowID", New TypeDescription("UUID")));
	Renamings.Insert("condition_id",  ColumnDetails(
		"ConditionCode", Common.TypeDescriptionNumber(9, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("url",  ColumnDetails(
		"Address", Common.StringTypeDetails(150)));
	Renamings.Insert("fast_sending",  ColumnDetails(
		"FastSending", New TypeDescription("Boolean")));
	Renamings.Insert("scheduled_export",  ColumnDetails(
		"ScheduledExport", New TypeDescription("Boolean")));
	Renamings.Insert("provider_selection",  ColumnDetails(
		"SelectionBySupplier", New TypeDescription("Boolean")));
	
	Return Renamings;
	
EndFunction

// Renaming the "Import rules" table of the "Accounting system" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountSystemUploadRules() Export
	
	Renamings = New Map;
	
	Renamings.Insert("rule_id",  ColumnDetails(
		"RuleCode", Common.StringTypeDetails(120)));
	Renamings.Insert("url",  ColumnDetails(
		"Address", Common.StringTypeDetails(150)));
	
	Return Renamings;

EndFunction

// Renaming the "Response processing rules" table of the "Accounting system" object.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountSystemResponseProcessingRules() Export
	
	Renamings = New Map;
	
	Renamings.Insert("rule_line_id",  ColumnDetails(
		"ExportingRuleLineId", New TypeDescription("UUID")));
	Renamings.Insert("rule_id",  ColumnDetails(
		"RuleCode", Common.StringTypeDetails(120)));
	Renamings.Insert("response_codes",  ColumnDetails(
		"ResponseCodes", New TypeDescription("Array")));
	
	Return Renamings;
	
EndFunction

#EndRegion

#Region SubscriptionPlan

// Renaming the "Service plan subscription" object.
// 
// Parameters:
//  ForServiceOrganization - Boolean - Indicates whether a description for service providers is received.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingSubscriptionPlan(ForServiceOrganization) Export
	
	Renamings = New Map;
	
	Renamings.Insert("id",  ColumnDetails(
		"Number", Common.StringTypeDetails(9)));
	Renamings.Insert("created", ColumnDetails(
		"Date", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("start", ColumnDetails(
		"ConnectionDate", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("completion", ColumnDetails(
		"DateOfExpiration", Common.DateTypeDetails(DateFractions.DateTime)));
	If ForServiceOrganization Then
		Renamings.Insert("account", ColumnDetails(
			"ServicedSubscriberCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("servant", ColumnDetails(
			"MasterSubscriberCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("tariff", ColumnDetails(
			"ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Else
		Renamings.Insert("account", ColumnDetails(
			"SubscriberCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("servant", ColumnDetails(
			"ServiceProviderCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("tariff", ColumnDetails(
			"ServicePlanCode", Common.StringTypeDetails(9)));
	EndIf; 
	
	Renamings.Insert("servant_tariff", ColumnDetails(
		"ServiceProviderPlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("period", ColumnDetails(
		"ValidityPeriodCode", Common.StringTypeDetails(10)));
	Renamings.Insert("amount", ColumnDetails(
		"Count", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("parent", ColumnDetails(
		"PrimarySubscriptionNumber", Common.StringTypeDetails(9)));
	Renamings.Insert("type", ColumnDetails(
		"SubscriptionType", New TypeDescription("EnumRef.ServiceSubscriptionsTypes")));
	Renamings.Insert("bill", ColumnDetails(
		"InvoiceNum", Common.StringTypeDetails(9)));
	Renamings.Insert("bill_id", ColumnDetails(
		"PaymentInvoiceID", New TypeDescription("UUID")));
	
	Return Renamings;
	
EndFunction

// Renaming the creation response fields of service plan subscription.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAndCreatingSubscriptionToPricingPlan() Export
	
	Renamings = New Map;
	Renamings.Insert("id",  ColumnDetails(
		"Number", Common.StringTypeDetails(9)));
	Renamings.Insert("completion", ColumnDetails(
		"DateOfExpiration", Common.DateTypeDetails(DateFractions.DateTime)));
	
	Return Renamings;

EndFunction

// Names of subscription creation properties.
// 
// Parameters:
//  ExtensionProperties1 - Boolean - Indicates whether subscription extension properties are added.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - String
Function SubscriptionCreationPropertyNames(ExtensionProperties1 = False) Export
	
	PropertiesNames = New Map;
	PropertiesNames.Insert("MasterSubscriberCode", "servant");
	PropertiesNames.Insert("ServicedSubscriberCode", "account");
	PropertiesNames.Insert("ServiceProviderPlanCode", "servant_tariff");
	PropertiesNames.Insert("ProviderServicePlanCode", "tariff");
	PropertiesNames.Insert("ValidityPeriodCode", "period");
	PropertiesNames.Insert("ConnectionDate", "start");
	PropertiesNames.Insert("DateOfExpiration", "completion");
	If ExtensionProperties1 Then
		PropertiesNames.Insert("PrimarySubscriptionNumber", "parent");
		PropertiesNames.Insert("Count", "amount");
	EndIf; 
	
	Return PropertiesNames;

EndFunction

#EndRegion

#Region Tariff

// Renaming the "Service plan" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingRates() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(9)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(150)));
	Renamings.Insert("description", ColumnDetails("DescriptionForServiceOrganizations", New TypeDescription("String")));
	Renamings.Insert("description_for_subscribers", ColumnDetails("DescriptionForSubscribers", New TypeDescription("FormattedDocument")));
	Renamings.Insert("start", ColumnDetails("ValidityStartDate", Common.DateTypeDetails(DateFractions.Date)));
	Renamings.Insert("expiration", ColumnDetails("ValidityEndDate", Common.DateTypeDetails(DateFractions.Date)));
	Renamings.Insert("prolongation_validity", ColumnDetails(
		"ProlongationSubscriptionPeriod", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("extension_validity", ColumnDetails(
		"ExtensionSubscriptionPeriod", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("prolongation_during", ColumnDetails(
		"PeriodForAddingRenewingSubscription", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("is_extension", ColumnDetails("TariffExpansion", New TypeDescription("Boolean")));
	Renamings.Insert("is_payable", ColumnDetails("Paid", New TypeDescription("Boolean")));
	Renamings.Insert("is_trial", ColumnDetails("Test_", New TypeDescription("Boolean")));
	Renamings.Insert("has_condition", ColumnDetails("ThereIsCondition", New TypeDescription("Boolean")));
	Renamings.Insert("payment_by_periods", ColumnDetails("PeriodicPayment", New TypeDescription("Boolean")));
	Renamings.Insert("periods_frequency", ColumnDetails("FrequencyOfPayment", Common.StringTypeDetails(10)));
	Renamings.Insert("validity_periods", ColumnDetails("ActionPeriods", New TypeDescription("ValueTable")));
	
	Return Renamings;

EndFunction

// Renaming the "Validity periods" table of the "Service plan" object.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamesAndValidityPeriods() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(10)));
	Renamings.Insert("period", ColumnDetails("Periodicity", New TypeDescription("EnumRef.ValidityPeriodsFrequency")));
	Renamings.Insert("quantity", ColumnDetails("Count", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(50)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	Renamings.Insert("comment", ColumnDetails("Comment", New TypeDescription("String")));
	
	Return Renamings;

EndFunction

// Renaming the "Extensions" table.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function TariffExtensionsRenamings() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(9)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(150)));
	
	Return Renamings;

EndFunction

// Renaming the "Recommended service plans" list fields.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingRecommendedRates() Export
	
	Renamings = New Map;
	Renamings.Insert("provider_tariff_id", ColumnDetails(
		"ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("servant_tariff_id", ColumnDetails(
		"ServiceProviderPlanCode", Common.StringTypeDetails(9)));
	
	Return Renamings;
	
EndFunction

#EndRegion
 
#Region ServiceOrganizationTariff

// Renaming the "Service provider plan" object.
// 
// Parameters:
//  Method - String - API method name.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingServiceOrganizationRates(Method) Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(12)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(64)));
	Renamings.Insert("tariff_id", ColumnDetails("ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("brief_description", ColumnDetails("ShortDescription", Common.StringTypeDetails(1024)));
	If Method = "account/servant_tariffs/info" Then
		Renamings.Insert("description_for_subscribers", ColumnDetails(
			"DescriptionForSubscribers", New TypeDescription("FormattedDocument")));
	EndIf; 
	Renamings.Insert("validity_periods", ColumnDetails("ActionPeriods", New TypeDescription("ValueTable")));
	
	Return Renamings;

EndFunction

// Renaming the "Validity periods" table of the "Service provider plan" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingServiceOrganizationTariffValidityPeriods() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(10)));
	Renamings.Insert("period", ColumnDetails("Periodicity", New TypeDescription("EnumRef.ValidityPeriodsFrequency")));
	Renamings.Insert("quantity", ColumnDetails("Count", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(50)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	Renamings.Insert("recommended", ColumnDetails("Recommended_", New TypeDescription("Boolean")));
	Renamings.Insert("comment", ColumnDetails("Comment", New TypeDescription("String")));
	
	Return Renamings;

EndFunction

#EndRegion  

#Region ProformaInvoice

// Renaming the "Account" object.
// 
// Parameters:
//  Method - String
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function InvoiceRenamings(Method) Export
	
	Renamings = New Map;
	If Not (Method = "bill/update" Or Method = "bill/create") Then
		Renamings.Insert("id", ColumnDetails(
			"Number", Common.StringTypeDetails(9)));
		Renamings.Insert("created", ColumnDetails(
			"Date", Common.DateTypeDetails(DateFractions.DateTime)));
		Renamings.Insert("modified", ColumnDetails(
			"ChangeDate", Common.DateTypeDetails(DateFractions.DateTime)));
	EndIf; 
	Renamings.Insert("bill_id", ColumnDetails(
		"InvoiceId", New TypeDescription("UUID")));
	Renamings.Insert("seller_id", ColumnDetails(
		"SellerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("customer_id", ColumnDetails(
		"BuyerSCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("total_cost", ColumnDetails(
		"Sum", Common.TypeDescriptionNumber(31, 2, AllowedSign.Nonnegative)));
	Renamings.Insert("renewal", ColumnDetails(
		"Renewal", New TypeDescription("Boolean")));
	Renamings.Insert("payment_link", ColumnDetails(
		"PaymentURL", Common.StringTypeDetails(1024)));
	Renamings.Insert("paid", ColumnDetails(
		"Paid", New TypeDescription("Boolean")));
	Renamings.Insert("add_info", ColumnDetails(
		"AdditionalInformation", New TypeDescription("String")));
	Renamings.Insert("comment", ColumnDetails(
		"Comment", New TypeDescription("String")));
		
	Return Renamings;
	
EndFunction

// Renaming the "Service plans" table of the "Account" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingInvoice() Export
	
	Renamings = New Map;
	Renamings.Insert("tariff_id", ColumnDetails("ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("servant_tariff_id", ColumnDetails(
		"ServiceProviderPlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("period_id", ColumnDetails("ValidityPeriodCode", Common.StringTypeDetails(10)));
	Renamings.Insert("amount", ColumnDetails("Count", Common.TypeDescriptionNumber(10,0)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	Renamings.Insert("basis_id", ColumnDetails("NumberOfBaseDocument", Common.StringTypeDetails(9)));
	
	Return Renamings;

EndFunction

// Renaming the "Services" table of the "Account" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingServiceAccount() Export
	
	Renamings = New Map;
	Renamings.Insert("service", ColumnDetails("OperationService", Common.StringTypeDetails(1000)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	
	Return Renamings;
	
EndFunction

// Renaming the "Files" table of the "Account" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountFiles() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Id", New TypeDescription("UUID")));
	Renamings.Insert("name", ColumnDetails("LongDesc", Common.StringTypeDetails(150)));
	
	Return Renamings;

EndFunction

// Renaming account state data.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountState() Export
	
	Renamings = New Map;
	Renamings.Insert("name", ColumnDetails("Name", Common.StringTypeDetails(17)));
	Renamings.Insert("error", ColumnDetails("Error", New TypeDescription("Boolean")));
	Renamings.Insert("description", ColumnDetails("LongDesc", New TypeDescription("String")));
	
	Return Renamings;
	
EndFunction

// Renaming the result of creating \ changing the account.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountResultOfCreatingChange() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Number", Common.StringTypeDetails(9)));
	Renamings.Insert("bill_id", ColumnDetails("InvoiceId", New TypeDescription("UUID")));

	Return Renamings;
	
EndFunction

// Renaming the "Import token" object of the "Account" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingInvoiceDownloadCoupon() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Number", Common.StringTypeDetails(9)));
	Renamings.Insert("bill_id", ColumnDetails("InvoiceId", New TypeDescription("UUID")));
	Renamings.Insert("direction", ColumnDetails("DataTransferDirection", Common.StringTypeDetails(8)));
	Renamings.Insert("token", ColumnDetails("FileImportCoupon",  Common.StringTypeDetails(64)));
	Renamings.Insert("url", ColumnDetails("ImportURL", New TypeDescription("String")));
	
	Return Renamings;
	
EndFunction

// Renaming data of the account creation \ change request.
// Parameters:
//  InvoiceData - See ServiceProgrammingInterface.NewInvoiceTemplate
//  Method - String - Application interface method name.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails 
Function RequestDataForCreatingAndModifyingInvoiceForPayment(InvoiceData, Method) Export
	
	QueryData = QueryTemplate(Method);
	Renamings = InvoiceRenamings(Method);
	For Each KeyValue In Renamings Do
		If Not InvoiceData.Property(KeyValue.Value.Name) Then
			Continue;
		EndIf; 
		Simple = InvoiceData[KeyValue.Value.Name];
		If KeyValue.Value.Type.ContainsType(Type("UUID")) Then
			Simple = String(Simple);
		EndIf; 
		QueryData.Insert(KeyValue.Key, Simple);		
	EndDo;
	If InvoiceData.Property("ServicePlans") Then
		Renamings = RenamingInvoice();
		QueryData.Insert("tariffs", TableOfValuesInArrayOfStructures(InvoiceData.ServicePlans, Renamings));
	EndIf; 
	If InvoiceData.Property("Services") Then
		Renamings = RenamingServiceAccount();
		QueryData.Insert("services", TableOfValuesInArrayOfStructures(InvoiceData.Services, Renamings));
	EndIf; 
	If InvoiceData.Property("Files") Then
		Renamings = RenamingAccountFiles();
		QueryData.Insert("files", TableOfValuesInArrayOfStructures(InvoiceData.Files, Renamings));
	EndIf; 
	If InvoiceData.Property("AdditionalAttributes") Then
		Renamings = RenamingAdditionalInformation(False);
		QueryData.Insert("fields", TableOfValuesInArrayOfStructures(
			InvoiceData.AdditionalAttributes, Renamings));
	EndIf;
	
	Return QueryData;

EndFunction

#EndRegion

#Region Package

// Renaming the "Application" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingApp() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"Code", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	Renamings.Insert("owner", ColumnDetails(
		"SubscriberOwnerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("application", ColumnDetails(
		"ConfigurationCode", Common.StringTypeDetails(22)));
	Renamings.Insert("app_version", ColumnDetails(
		"ConfigurationVersion", Common.StringTypeDetails(18)));
	Renamings.Insert("app_name", ColumnDetails(
		"ConfigurationDescription", Common.StringTypeDetails(64)));
	Renamings.Insert("status", ColumnDetails(
		"ApplicationState", New TypeDescription("EnumRef.ApplicationsStates")));
	Renamings.Insert("url", ColumnDetails(
		"ApplicationURL", Common.StringTypeDetails(500)));
	Renamings.Insert("timezone", ColumnDetails(
		"TimeZone", Common.StringTypeDetails(100)));

	Return Renamings;
	
EndFunction

// Renaming the "ApplicationBackups" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingApplicationBackups() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"BackupIdentificator", Common.StringTypeDetails(36)));
	Renamings.Insert("timestamp", ColumnDetails(
		"BackupTimestamp", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("for_support", ColumnDetails(
		"ForTechSupport", New TypeDescription("Boolean")));
	
	Return Renamings;
	
EndFunction
 
#EndRegion

#Region UserTask

// Renaming the "User task" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingUserTask() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"Number", Common.StringTypeDetails(32)));
	Renamings.Insert("name", ColumnDetails(
		"TaskDescription", New TypeDescription("String")));
	Renamings.Insert("created", ColumnDetails(
		"Date", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("author", ColumnDetails(
		"AuthorAsString", New TypeDescription("String")));
	
	Return Renamings;
	
EndFunction

#Region AdditionalInfo

// Renaming the list of additional information records.
// 
// Parameters:
//  AddTitle_ - Boolean - Indicates whether the header of the additional information record is added to the renaming parameters.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAdditionalInformation(AddTitle_ = True) Export
	
	Renamings = New Map;
	Renamings.Insert("key", ColumnDetails("Key", Common.StringTypeDetails(100)));
	If AddTitle_ Then
		Renamings.Insert("name", ColumnDetails("Title", Common.StringTypeDetails(150)));
	EndIf;
	Renamings.Insert("type", ColumnDetails("Type", Common.StringTypeDetails(50)));
	Renamings.Insert("value", ColumnDetails("Value", DescriptionOfValueTypesForAdditionalInformation()));
	
	Return Renamings;
	
EndFunction

// Data constructor of additional information records.
// 
// Returns:
//  ValueTable - New additional information records.:
// * Key - String
// * Type - String
// * Value - See DescriptionOfValueTypesForAdditionalInformation
Function NewAdditionalInformation() Export
	
	AdditionalInfo = New ValueTable;
	AdditionalInfo.Columns.Add("Key", Common.StringTypeDetails(100));
	AdditionalInfo.Columns.Add("Type", Common.StringTypeDetails(50));
	AdditionalInfo.Columns.Add("Value", DescriptionOfValueTypesForAdditionalInformation());

	Return AdditionalInfo

EndFunction

// Presentation of value types of additional information records.
// 
// Returns:
//  ValueList of String
Function PresentationsOfValueTypesForAdditionalInformation() Export
	
	TypesPresentation1 = New ValueList;
    TypesPresentation1.Add("string", NStr("ru = 'Строка';
												|en = 'String';"));
    TypesPresentation1.Add("decimal", NStr("ru = 'Число';
												|en = 'Number';"));
    TypesPresentation1.Add("date", NStr("ru = 'Дата';
											|en = 'Date';"));
    TypesPresentation1.Add("boolean", NStr("ru = 'Булево';
												|en = 'Boolean';"));
    TypesPresentation1.Add("subscriber", NStr("ru = 'Справочник ""Абоненты""';
													|en = 'The ""Subscribers"" catalog';"));
    TypesPresentation1.Add("service", NStr("ru = 'Справочник ""Услуги""';
												|en = 'The ""Services"" catalog';"));
    TypesPresentation1.Add("additional_value", NStr("ru = 'Справочник ""Дополнительные значения""';
														|en = 'The ""Additional values"" catalog';"));
    TypesPresentation1.Add("additional_value_group", NStr("ru = 'Справочник ""Дополнительные значения (иерархия)""';
																|en = 'The ""Additional values (hierarchy)"" catalog';"));
    TypesPresentation1.Add("tariff", NStr("ru = 'Справочник ""Тарифы""';
												|en = 'The ""Service plans"" catalog';"));
    TypesPresentation1.Add("service_provider_tariff", NStr("ru = 'Справочник ""Тарифы поставщиков услуг""';
																|en = 'The ""Service plan of service providers"" catalog';"));
    TypesPresentation1.Add("user", NStr("ru = 'Справочник ""Пользователи""';
											|en = 'The ""Users"" catalog';"));
    TypesPresentation1.Add("tariff_period", NStr("ru = 'Справочник ""Периоды тарифов""';
														|en = 'The ""Periods of service plans"" catalog';"));
    TypesPresentation1.Add("subscription", NStr("ru = 'Документ ""Подписка""';
													|en = 'The ""Subscription"" document';"));
	
	Return TypesPresentation1;
	
EndFunction

// Description of value types of additional information records.
// 
// Returns:
//  TypeDescription
Function DescriptionOfValueTypesForAdditionalInformation() Export
	
	ValueTypes = New Array;
	ValueTypes.Add("Number");
	ValueTypes.Add("String");
	ValueTypes.Add("Date");
	ValueTypes.Add("Boolean");
	
	Return New TypeDescription(ValueTypes);

EndFunction

#EndRegion 

#EndRegion

#EndRegion

#Region Private

Function ValueByType(ValueType, Value)
	
	If ValueType.ContainsType(Type("UUID")) Then
		Return New UUID(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ServicesTypes")) Then
		Return Enums.ServicesTypes.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ValidityPeriodsFrequency")) Then
		Return Enums.ValidityPeriodsFrequency.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ApplicationsStates")) Then
		Return Enums.ApplicationsStates.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ServiceSubscriptionsTypes")) Then
		Return Enums.ServiceSubscriptionsTypes.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ApplicationUserRights")) Then
		Return Enums.ApplicationUserRights.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.SubscriberUsersRoles")) Then
		Return Enums.SubscriberUsersRoles.ValueByName(Value);
	Else
		Return Value;
	EndIf;
	
EndFunction
 
// Returns the details of a column of the field rename table.
// 
// Parameters:
//	Name - String - New name.
//	Type - TypeDescription - Value type.
//	
// Returns:
//	Structure:
//	 * Name - String - New name.
//	 * Type - TypeDescription - Value type.
Function ColumnDetails(Name, Type) Export

	Return New Structure("Name, Type", Name, Type);

EndFunction

#EndRegion
