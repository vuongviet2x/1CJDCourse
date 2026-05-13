
#Region Public

// Returns the billing API version. A version is a prime number.
// 
// Returns:
//  Number - an interface version.
//
Function InterfaceVersion() Export
	
	Return 3;
	
EndFunction

// Returns a presentation of the service payment currency.
// 
// Returns:
//  String - Payment currency presentation. 
//
Function PresentationOfPaymentCurrency() Export
	
	PresentationOfPaymentCurrency = NStr("ru = 'руб.';
									|en = 'euros';"); 
	ServicePaymentOverridable.OnSetPaymentCurrencyPresentation(PresentationOfPaymentCurrency);
	
	Return PresentationOfPaymentCurrency;
	
EndFunction

// See CommonOverridable.OnAddClientParametersOnStart
// Method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
Procedure OnAddClientParametersOnStart(Parameters) Export
EndProcedure

// Returns the expiration states of service plan subscriptions submitted by the service manager.
// Data is returned only for users with the "Subscriber owner" role.
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
// 
// Returns:
//  Structure:
//   * TestResultsAreCompleted - Number
//   * CompletedFree - Number
//   * EndingPaid - Number
//   * TotalCompleted - Number
//   * NotTestResultsAreCompleted - Number
//   * NotCompletedFree - Number
//   * NotEndingPaid - Number
//   * NotTotalCompleted - Number
Function StatesOfCompletionOfTariffSubscriptions() Export
EndFunction

// Returns the flag that indicates whether the infobase supports the import of service plans.
// 
// Returns:
//  Boolean - If True, it supports the import.
//
Function TariffLoadingIsSupported() Export
	
	Result = False;
	ServicePaymentOverridable.OnDefineServicePlansImportSupport(Result);
	
	Return Result;
	
EndFunction

// Import servicer plans from the Service Manager to the infobase catalogs.
// 
Procedure DownloadServiceRates() Export
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		AuthorizationData = ServiceProgrammingInterfaceInternal.AuthorizationDataInService();
		SubscriberCode = AuthorizationData.SubscriberCode;
	Else
		SubscriberCode = ServiceProgrammingInterface.SubscriberOfThisApplication().Code;
	EndIf; 
	
	Filter = ServiceProgrammingInterface.NewSelectionOfSupportCompanyTariffsList();
	Filter.ServiceProviderCode = SubscriberCode;
	Filter.ReceivingParameters.Add(ServiceProgrammingInterface.ParameterForGettingValidityPeriods());

	RawData = New Structure;
	RawData.Insert("ServiceOrganizationRates", 
		ServiceProgrammingInterface.ServiceOrganizationRates(Filter));
		
	Filter = ServiceProgrammingInterface.NewTariffsListFilter();
	Filter.ReceivingParameters.Add(ServiceProgrammingInterface.ParameterForGettingPaidOnly());
	Filter.ReceivingParameters.Add(ServiceProgrammingInterface.ParameterForGettingValidityPeriods());
	RawData.Insert("ProviderRates", ServiceProgrammingInterface.ServiceRates(Filter));
	
	ProcessingResult = NewProcessingResult();
	
	Try
		ServicePaymentOverridable.OnImportServicePlans(RawData, ProcessingResult);
		If ProcessingResult.Error Then
			Raise ProcessingResult.Message;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("ru = 'Загрузка тарифов сервиса';
													|en = 'Import service plans';", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise StrTemplate(
			NStr("ru = 'Ошибка при загрузке тарифов сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
						|en = 'An error occurred when importing the service plans. Reason:
						|%1
						|For more information, see the event log of the billing application.';"),
			CloudTechnology.ShortErrorText(ErrorInfo));
	EndTry;
	
EndProcedure

// Sends a respond to the billing management system to the proforma invoice address.
//
// Parameters:
//  InvoiceId - UUID - Proforma invoice ID.
//  Data - See ServicePayment.ResponseDataTemplate
//
// Returns:
//  HTTPResponse - Service manager response.
//
// Example:
//  ...
//  Data = ServicePayment.AnswerDataTemplate();
//  Data.Insert("paid", True); // Proforma invoice payment flag.
//  ServicePayment.SendRequestToBillingAccountSystem(ProformaInvoiceID, Data); // Send.
//
Function SendResponseToBillingSystem(InvoiceId, Data) Export
	
	SetPrivilegedMode(True);
	If SaaSOperations.DataSeparationEnabled() Then
		ServiceAddress = SaaSOperations.InternalServiceManagerURL();
	Else
		ServiceAddress = ServiceProgrammingInterfaceInternal.ServiceAddressFromLocalDatabase();
	EndIf;
	
	AccountAddress = StrTemplate("%1/%2/%3", ServiceAddress, AddressOfInvoicesForPaymentOfBillingSystem(), InvoiceId);
	ServerData = CommonClientServer.URIStructure(AccountAddress);
	AccountSystemUserName = Constants.AccountSystemUserName.Get();
	AccountSystemUserPassword = Common.ReadDataFromSecureStorage(
		OwnerOfAuthorizationPasswordInAccountSystem());
		
	If Not ValueIsFilled(AccountSystemUserName) Then
		ErrorText = NStr("ru = 'Не настроены параметры подключения к учетной системе биллинга. 
								 |Нужно установить настройки по ссылке: 
								 |%1';
								|en = 'Parameters for connecting to the billing accounting system are not configured. 
								|Configure settings by reference:
								|%1';");
		LinkToSettings = "e1cib/data/DataProcessor.AdministrationPanelCTL.Form.ServicePaymentSettings";
		Raise StrTemplate(ErrorText, LinkToSettings); 
	EndIf;
	
	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  New OpenSSLSecureConnection(, New OSCertificationAuthorityCertificates);
	Else
		SecureConnection = Undefined;
	EndIf;
	
	Join = New HTTPConnection(ServerData.Host, ServerData.Port,
		AccountSystemUserName, AccountSystemUserPassword,
		GetFilesFromInternet.GetProxy(ServerData.Schema), 5, SecureConnection);
	
	Method_HTTP = "PUT";
	HTTPRequest = New HTTPRequest;
	HTTPRequest.ResourceAddress = ServerData.PathAtServer;
	HTTPRequest.SetBodyFromString(JSONString(Data));
	Response = Join.CallHTTPMethod(Method_HTTP, HTTPRequest);
	LogHTTPRequest(HTTPRequest, Response);
	
	// Object transaction might not be committed on time.
	If Response.StatusCode = 404 Then
		For Counter = 1 To 3 Do
			CommonCTL.Pause(1);
			Response = Join.CallHTTPMethod(Method_HTTP, HTTPRequest);
			If Not Response.StatusCode = 404 Then
				Break;
			EndIf; 
		EndDo;
		If Response.StatusCode = 404 Then
			Raise StrTemplate(NStr("ru = 'Ошибка 404 при отправке ответа по счету %1 на адрес %2. 
				|Возможно во внутренней публикации Менеджера сервиса не опубликован HTTP-сервис %3.';
				|en = 'Error 404 occurred when sending a response on the %1invoice to the %2 address.
				|The %3 HTTP service is not published in the internal Service Manager publication.';"),
				InvoiceId, AccountAddress, "UniversalIntegration");
		EndIf; 
	EndIf;
	
	ErrorTextTemplate = NStr("ru = 'Ошибка %1 при отправке ответа по счету %2 на адрес %3 по причине: %4';
								|en = 'Error %1 occurred when sending the response on proforma invoice %2 to %3. Reason: %4';");
	If Response.StatusCode = 401 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			StrTemplate(NStr("ru = 'Пользователь %1 не авторизован.';
							|en = 'User %1 is not authorized.';"), AccountSystemUserName));
	ElsIf Response.StatusCode = 403 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			StrTemplate(NStr("ru = 'Запрос %1 не разрешен пользователю %2.';
							|en = 'The %1 request is restricted for user %2.';"), Method_HTTP, AccountSystemUserName)); 
	ElsIf Response.StatusCode = 405 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			StrTemplate(NStr("ru = 'Метод %1 не поддерживается.';
							|en = 'The %1 method is not supported.';"), Method_HTTP));
	ElsIf Response.StatusCode = 400 Or Response.StatusCode >= 500 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			Response.GetBodyAsString());
	EndIf;
	
	Return Response;
	
EndFunction

// Returns a data template upon exporting the proforma invoice data.
//
// Parameters:
//  ResponseCode - Number - Response code. If the parameter is not passed, it is set to 10200.
//              To set a value, use the following methods::
//               ReturnCodeDataError() - Same as code 10400 - Used for handling known errors.
//              ReturnCodeInternalError() - Same as code 10500 - Used for handling unknown errors.
//  Message - String - Error message. Contains the text that will be returned to the user.
// 
// Returns:
//  Structure:
//   * response - Number - Response code.
//   * error - Boolean - Error flag. Set if the response code is not 102xx.
//   * message - String - error message.
//
Function ResponseDataTemplate(ResponseCode = 10200, Message = "") Export
	
	ResponseData = New Structure;
	ResponseData.Insert("response", ResponseCode);
	ResponseData.Insert("error", ?(ResponseCode >= 10200 And ResponseCode <= 10299, False, True));
	ResponseData.Insert("message", Message);
	
	Return ResponseData;
	
EndFunction

// Returns the data error code.
// 
// Returns:
//   Number - Data error return code: 10400.
//
Function ReturnCodeDataError() Export
	
	Return 10400;
	
EndFunction

// Returns the internal error code.
// 
// Returns:
//   Number - Internal error return code: 10500.
//
Function ReturnCodeInternalError() Export
	
	Return 10500;
	
EndFunction

#EndRegion 

#Region Internal

// Configure service payment settings.
// 
// Parameters:
//  SubscriberCode - Number - Code of the subscriber who is an accounting system owner.
// 
Procedure SetServicePaymentSettings(SubscriberCode) Export
	
	ProcessingResult = NewProcessingResult();
	
	Try
		ServicePaymentOverridable.AtSettingServicePaymentSettings(SubscriberCode, ProcessingResult);
		If ProcessingResult.Error Then
			Raise ProcessingResult.Message;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("ru = 'Установка настроек оплаты сервиса';
													|en = 'Configure service payment settings';", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise StrTemplate(
			NStr("ru = 'Ошибка при установке настроек оплаты сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
						|en = 'An error occurred when configuring service payment settings. Reason:
						|%1
						|For more information, see the event log of the billing application.';"),
			CloudTechnology.ShortErrorText(ErrorInfo));
	EndTry;
		
	If TariffLoadingIsSupported() Then
		DownloadServiceRates()
	EndIf;
	
EndProcedure

// Delete service payments settings.
//
// Parameters:
//  SubscriberCode - Number - Code of the subscriber who is an accounting system owner.
//
Procedure DeleteServicePaymentSettings(SubscriberCode) Export
	
	ProcessingResult = NewProcessingResult();
	
	Try
		ServicePaymentOverridable.AtDeletingServicePaymentSettings(SubscriberCode, ProcessingResult);
		If ProcessingResult.Error Then
			Raise ProcessingResult.Message;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("ru = 'Удаление настроек оплаты сервиса';
													|en = 'Delete service payment settings';", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise StrTemplate(
			NStr("ru = 'Ошибка при удалении настроек оплаты сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
						|en = 'An error occurred when deleting service payment settings. Reason:
						|%1
						|For more information, see the event log of the billing application.';"),
			CloudTechnology.ShortErrorText(ErrorInfo));
	EndTry;
	
EndProcedure

// Proforma invoice background job handler.
//
// Parameters:
//  QueryData - See InvoiceRequestData
//
Procedure PrepareInvoiceForPayment(QueryData) Export
	
	Try	
		InvoiceId = New UUID(QueryData.InvoiceId);
		
		// Generate a proforma invoice from the request data.
		ProcessingResult = NewProcessingResult();
		ProformaInvoice = CreatePaymentInvoice(QueryData, ProcessingResult);
		If ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf; 
		
		// Get proforma invoice print form.
		ProcessingResult = NewProcessingResult();
		PrintForm = PrintedInvoiceForm(QueryData, ProformaInvoice, ProcessingResult);
		If Not PrintForm = Undefined Then
			Stream = New MemoryStream;
			PrintForm.Write(Stream, SpreadsheetDocumentFileType.MXL);
			BinaryData = Stream.CloseAndGetBinaryData();
			PlaceFileInInvoice(InvoiceId, BinaryData, "bill.mxl");
		ElsIf ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf;
		
		// Get proforma invoice binary data.
		ProcessingResult = NewProcessingResult();
		InvoiceData = CustomerInvoiceDetails(QueryData, ProformaInvoice, ProcessingResult);
		If Not InvoiceData = Undefined Then
			PlaceFileInInvoice(InvoiceId, InvoiceData, "bill.zip");
		ElsIf ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf;
		
		If PrintForm = Undefined And InvoiceData = Undefined Then
			Raise StrTemplate(
				NStr("ru = 'Не заданы или не возвращают данных переопределяемые методы %1 и %2.';
					|en = 'The overridable %1 and %2 methods are not set or return no data.';"),
				"ServicePaymentOverridable.OnGetProformaInvoicePrintForm",
				"ServicePaymentOverridable.OnGetProformaInvoiceDetails");
		EndIf;
			
		ProcessingResult = NewProcessingResult();
		PaymentURL = PaymentInvoiceLink(QueryData, ProformaInvoice, ProcessingResult);
		If ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf;
		
		Data = ResponseDataTemplate();
		Data.Insert("payment_link", PaymentURL);
		
		SendResponseToBillingSystem(InvoiceId, Data);
		
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("ru = 'Подготовка счета на оплату';
													|en = 'Prepare a proforma invoice';", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Data = ResponseDataTemplate(ReturnCodeInternalError(), CloudTechnology.ShortErrorText(ErrorInfo));
		SendResponseToBillingSystem(InvoiceId, Data);
		
	EndTry;
	
EndProcedure

// Returns the data of the proforma invoice request in a structured form.
// 
// Parameters:
//  Query - HTTPServiceRequest - Proforma invoice request from the Service Manager.
//
// Returns:
//  Structure - Request data.:
//   * InvoiceId - UUID - Proforma invoice ID.
//   * SellerCode - Number - Seller's subscriber code.
//   * NameOfSeller - String - Seller subscriber name.
//   * SellerPublicId - String - Customer's public TIN.
//   * SellerSMail - String - Seller's email.
//   * BuyerSCode - Number - Customer's subscriber code.
//   * BuyerSName - String - Customer's subscriber name.
//   * PublicBuyerID - String - Customer's public TIN.
//   * BuyerSMail - String - Customer's email.
//   * BuyerSPhoneNumber - String - Customer's phone.
//   * AdditionalInformation - String - Additional proforma invoice information.
//   * Renewal - Boolean - Recurrent subscription flag. 
//   * PaymentURL - String - Link to the proforma invoice payment.
//   * Sum - Number - Proforma invoice amount. Digit capacity is 31.2.
//   * ServicePlans - ValueTable:
//     ** ProviderServicePlanCode - String - Provider service plan code.
//     ** ServiceProviderPlanCode - String - Code of the intermediary's service plan. Overrides the provider's service plan code.
//     ** ValidityPeriodCode - String - Support plan validity code.
//     ** Count - Number - Support plan count. Digit capacity is 10.0.
//     ** Sum - Number - Price of a certain plan validity period (digit capacity is 31.2).
//     ** NumberOfBaseDocument - String - Number of subscription that requests a proforma invoice.
//   * Services - ValueTable:
//     ** OperationService - String - Service description.
//     ** Sum - Number - Service price. Digit capacity is 31.2.
//
Function InvoiceRequestData(Query) Export
	
	Data = JSONData(Query.GetBodyAsString());
		
	IsInternal = ServiceProgrammingInterfaceInternal;
	Result = IsInternal.RenameProperties(Data, RenamingRequestFields());
	Result.ServicePlans = IsInternal.StructuresArrayIntoValueTable(Result.ServicePlans, IsInternal.RenamingInvoice());
	Result.Services = IsInternal.StructuresArrayIntoValueTable(Result.Services, IsInternal.RenamingServiceAccount());
		
	Return Result; // @skip-check constructor-function-return-section

EndFunction

// Converts the passed value into a JSON string.
//
// Parameters:
//  Data - Structure - Data.
// 
// Returns:
//  String - a string in the JSON format.
//
Function JSONString(Data) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data,, "ConvertingJSONData", ServicePayment);
	
	Return JSONWriter.Close();
	
EndFunction

// Converts a JSON string into Structure.
//
// Parameters:
//	String - String - JSON string.
//	PropertiesWithDateValuesNames - Array of String - Property names to convert into Data values.
// 
// Returns:
//	Structure - Data from the passed string.
Function JSONData(String, PropertiesWithDateValuesNames = Undefined) Export
	
	If IsBlankString(String) Then
		Return New Structure;
	EndIf; 
	
	If PropertiesWithDateValuesNames = Undefined Then
		PropertiesWithDateValuesNames = New Array;
	EndIf; 
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	
	If PropertiesWithDateValuesNames.Count() = 0 Then
		Response = ReadJSON(JSONReader); 
	Else
		Response = ReadJSON(JSONReader, , , , 
			"RestoringDateValue", ServicePayment, ,
			PropertiesWithDateValuesNames);
	EndIf;
	
	Return Response; // @skip-check constructor-function-return-section
	
EndFunction

// See the WriteJSON global context method, the ConversionFunctionName parameter.
// 
// Parameters:
//  Property - String
//  Value - Arbitrary
//  AdditionalParameters - Arbitrary
//  Cancel - Boolean
// 
// Returns:
//  String - JSON data conversion.
Function ConvertingJSONData(Property, Value, AdditionalParameters, Cancel) Export
	
	If TypeOf(Value) = Type("Null") Then
		Cancel = True;
	ElsIf Common.IsReference(TypeOf(Value)) Then
		Return String(Value.UUID());
	ElsIf TypeOf(Value) = Type("UUID") Then
		Return String(Value);
	EndIf;
	
EndFunction

// Handler for restoring Date values when reading a JSON string.
// 
// Parameters:
//  Property - String - Object property name.
//  Value - String, Number - Value retrieved from a JSON string.
//  AdditionalParameters - Arbitrary - Data processor's additional parameters.
// 
// Returns:
//  Date - Restored date value.
Function RestoringDateValue(Property, Value, AdditionalParameters) Export
	
	// Check the standard values: 2018-01-01T00:00:00, 2018-01-01T00:00:00Z, 2018-01-01T00:00:00+0000
	If StrLen(Value) <= 24 And Mid(Value, 5, 1) = "-" And Mid(Value, 8, 1) = "-" And Mid(Value, 11, 1) = "T" Then
		Return XMLValue(Type("Date"), Value);
	EndIf; 
	
	// Restore the data in the format dd.MM.yyyy.
	PartsOfDateValue = StrSplit(Value, ".");
	If PartsOfDateValue.Count() >= 3 Then
		Return Date(Number(PartsOfDateValue[2]), Number(PartsOfDateValue[1]), Number(PartsOfDateValue[0]));
	EndIf;
	
	// Restore the data in the format MM/dd/yyyy.
	PartsOfDateValue = StrSplit(Value, "/");
	If PartsOfDateValue.Count() >= 3 Then
		Return Date(Number(PartsOfDateValue[2]), Number(PartsOfDateValue[0]), Number(PartsOfDateValue[1]));
	EndIf;
	
	Return Value;
	
EndFunction

// Query field renaming.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ServiceProgrammingInterfaceInternal.ColumnDetails
Function RenamingRequestFields() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("InvoiceId", New TypeDescription("UUID")));
	Renamings.Insert("seller_id", IsInternal.ColumnDetails("SellerCode", Common.StringTypeDetails(12)));
	Renamings.Insert("seller_name", IsInternal.ColumnDetails("NameOfSeller", Common.StringTypeDetails(64)));
	Renamings.Insert("seller_public_id", IsInternal.ColumnDetails("SellerPublicId", Common.StringTypeDetails(36)));
	Renamings.Insert("seller_email", IsInternal.ColumnDetails("SellerSMail", New TypeDescription("String")));
	Renamings.Insert("client_id", IsInternal.ColumnDetails("BuyerSCode", Common.StringTypeDetails(12)));
	Renamings.Insert("client_name", IsInternal.ColumnDetails("BuyerSName", Common.StringTypeDetails(64)));
	Renamings.Insert("client_public_id", IsInternal.ColumnDetails("PublicBuyerID", Common.StringTypeDetails(36)));
	Renamings.Insert("client_email", IsInternal.ColumnDetails("BuyerSMail", Common.StringTypeDetails(500)));
	Renamings.Insert("client_phone", IsInternal.ColumnDetails("BuyerSPhoneNumber", Common.StringTypeDetails(500)));
	Renamings.Insert("client_info", IsInternal.ColumnDetails("AdditionalInformation", New TypeDescription("String")));
	Renamings.Insert("renewal", IsInternal.ColumnDetails("Renewal", New TypeDescription("Boolean")));
	Renamings.Insert("payment_link",  IsInternal.ColumnDetails("PaymentURL", Common.StringTypeDetails(1024)));
	Renamings.Insert("total_cost",  IsInternal.ColumnDetails("Sum", Common.TypeDescriptionNumber(31, 2, AllowedSign.Nonnegative)));
	Renamings.Insert("tariffs", "ServicePlans");
	Renamings.Insert("services", "Services");
	
	Return Renamings;
	
EndFunction

Procedure LogHTTPRequest(Query, Response, BinaryData = False) Export
	
	LongDesc = QueryDetails(Query, BinaryData) + Chars.LF + "---" + Chars.LF + ResponseDescription(Response, BinaryData);
	WriteLogEvent(EventLogEvent(NStr("ru = 'HTTP-запрос';
															|en = 'HTTP request';")), EventLogLevel.Information,
		Metadata.HTTPServices.Billing, , LongDesc);
	
EndProcedure

// Add data headers.
// 
// Parameters:
//  Response - HTTPServiceResponse
Procedure AddDataHeaders(Response) Export
	
	Headers = Response.Headers;
	
	Headers.Insert("Accept", "application/json");
	Headers.Insert("Accept-Charset", "utf-8");
	Headers.Insert("Content-Type", "application/json; charset=utf-8");
	Headers.Insert("Cache-Control", "no-cache");
	
EndProcedure

// Authorization password owner in the service.
// 
// Parameters:
//  User - CatalogRef.Users
// 
// Returns:
//  String
Function OwnerOfAuthorizationPasswordInService(User) Export
	
	Return InformationRegisters.AuthorizationIn1cFresh.OwnerOfSecureStorage(User);
	
EndFunction

// Authorization password owner in the accounting system.
// 
// Returns:
//  String
Function OwnerOfAuthorizationPasswordInAccountSystem() Export
	
	Return Metadata.Constants.AccountSystemUserName.FullName();
	
EndFunction

#EndRegion

#Region Private

Function NewProcessingResult()
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("Error", False);
	ProcessingResult.Insert("Message", "");
	
	Return ProcessingResult;
	
EndFunction

Function AddressOfInvoicesForPaymentOfBillingSystem()
	
	Return "hs/ui/bills";
	
EndFunction

Function CreatePaymentInvoice(QueryData, ProcessingResult)

	ProformaInvoice = Undefined;
	
	ServicePaymentOverridable.OnCreateProformaInvoice(
		QueryData, ProformaInvoice, ProcessingResult);
		
	Return ProformaInvoice;

EndFunction

Function PrintedInvoiceForm(QueryData, ProformaInvoice, ProcessingResult)
	
	PrintForm = Undefined; // SpreadsheetDocument
	
	ServicePaymentOverridable.OnGetProformaInvoicePrintForm(
		QueryData, ProformaInvoice, PrintForm, ProcessingResult);
		
	Return PrintForm;
	
EndFunction

Function CustomerInvoiceDetails(QueryData, ProformaInvoice, ProcessingResult)
	
	Data = Undefined;
	
	ServicePaymentOverridable.OnGetProformaInvoiceDetails(
		QueryData, ProformaInvoice, Data, ProcessingResult);
		
	Return Data;
	
EndFunction

Function PaymentInvoiceLink(QueryData, ProformaInvoice, ProcessingResult)
	
	PaymentURL = "";
	
	ServicePaymentOverridable.OnGetPaymentURL(
			QueryData, ProformaInvoice, PaymentURL, ProcessingResult);	
	
	Return PaymentURL;
	
EndFunction
 
Function PlaceFileInInvoice(InvoiceId, BinaryData, FileName)
	
	TokenParameters = ServiceProgrammingInterface.NewOptionsForGettingFileUploadCoupon();
	TokenParameters.InvoiceId = InvoiceId;
	TokenParameters.Size = BinaryData.Size();
	TokenParameters.FileName = FileName;
	TokenData = ServiceProgrammingInterface.InvoiceForPaymentAndDownloadCoupon(TokenParameters);
	Address = StrTemplate("hs/dt/upload/%1", TokenData.FileImportCoupon);
	SetPrivilegedMode(True);
	If SaaSOperations.DataSeparationEnabled() Then
		ServiceAddress = SaaSOperations.InternalServiceManagerURL();
	Else
		ServiceAddress = ServiceProgrammingInterfaceInternal.ServiceAddressFromLocalDatabase();
	EndIf;
	
	FullAddress = StrTemplate("%1/%2", ServiceAddress, Address);
	ServerData = CommonClientServer.URIStructure(FullAddress);
	
	If SaaSOperations.DataSeparationEnabled() Then
		Join = SaaSOperationsCTL.ConnectingToServiceManager(ServerData);
	Else
		Join = ServiceProgrammingInterfaceInternal.ConnectingToServiceManagerFromLocalDatabase(ServerData);
	EndIf; 
	
	HTTPRequest = New HTTPRequest;
	HTTPRequest.ResourceAddress = ServerData.PathAtServer;
	HTTPRequest.SetBodyFromBinaryData(BinaryData);
	HTTPRequest.Headers.Insert("IBSession", "start");
	HTTPRequest.Headers.Insert("Content-Range", 
		StrTemplate("bytes 0-%1/%2", Format(TokenParameters.Size - 1, "NG=0"), 
		Format(TokenParameters.Size, "NG=0")));
	
	Response = Join.CallHTTPMethod("PUT", HTTPRequest);
	
	If Response.StatusCode = 500 Then
		For Counter = 1 To 3 Do
			CommonCTL.Pause(Counter * 3);
			Response = Join.CallHTTPMethod("PUT", HTTPRequest);
			If Not Response.StatusCode = 201 Then
				Break;
			EndIf; 
		EndDo;
	EndIf;
	
	If Not Response.StatusCode = 201 Then
		LogHTTPRequest(HTTPRequest, Response, True);
		If Response.StatusCode = 500 Then
			ErrorText = StrTemplate(
				NStr("ru = 'Ошибка 500 при помещении файла в счет на оплату %1 по причине: %2';
					|en = 'Error 500 occurred when placing a file to the %1 proforma invoice due to: %2';"),
				InvoiceId, Response.GetBodyAsString());
			Raise ErrorText;
		EndIf; 
	EndIf;
	
	Return Response;
	
EndFunction

#Region Logging

Function EventLogEvent(Refinement) Export

	Return StrTemplate("%1.%2", NStr("ru = 'Оплата сервиса';
									|en = 'Service payments';", Common.DefaultLanguageCode()), Refinement);

EndFunction

Function BaseURL(HTTPServiceRequest)
	
	BaseURL = HTTPServiceRequest.Headers.Get("X-Forwarded-Path");
	If BaseURL = Undefined Then
		Return NormalizeAddress(HTTPServiceRequest.BaseURL);
	Else
		AddressParts = StrSplit(NormalizeAddress(HTTPServiceRequest.BaseURL), "/", False);
		Return AddressParts[0] + "//" + AddressParts[1] + BaseURL;
	EndIf;
	
EndFunction

Function NormalizeAddress(Address)
	
	AddressParts = StrSplit(Address, "/", False);
	
	Protocol = TrimAll(AddressParts[0]) + "//";
	AddressParts.Delete(0);
	
	NameParts = StrSplit(TrimAll(AddressParts[0]), ":");
	AddressParts.Delete(0);
	ServerName = NameParts[0];
	ServerPort = ?(NameParts.Count() = 1, "", TrimAll(NameParts[1]));
	If Protocol = "http://" Then
		ServerPort = ?(IsBlankString(ServerPort) Or ServerPort = "80", "", ":" + ServerPort);
	ElsIf Protocol = "https://" Then
		ServerPort = ?(IsBlankString(ServerPort) Or ServerPort = "443", "", ":" + ServerPort);
	Else
		Raise StrTemplate(NStr("ru = 'Неизвестный протокол: %1';
										|en = 'Unknown protocol: %1';", 
			Common.DefaultLanguageCode()), Protocol);
	EndIf;
	
	Path = "/" + StrConcat(AddressParts, "/");
	
	Return Protocol + ServerName + ServerPort + Path;
	
EndFunction

Function QueryDetails(Query, BinaryData = False)
	
	QueryOptions = Undefined;
	If TypeOf(Query) = Type("HTTPServiceRequest") Then
		If Query.QueryOptions.Count() Then
			QueryOptions = New Array;
			For Each KeyAndValue In Query.QueryOptions Do
				QueryOptions.Add(KeyAndValue.Key + "=" + EncodeString(
					KeyAndValue.Value, StringEncodingMethod.URLEncoding));
			EndDo;
			QueryOptions = "?" + StrConcat(QueryOptions, "&");
		EndIf;
		Address = Query.HTTPMethod + " " + BaseURL(Query) + Query.RelativeURL + QueryOptions;
	Else
		Address = Query.ResourceAddress;
	EndIf;
	
	Headers = New Array;
	Asterisks = "***";
	For Each Title  In Query.Headers Do
		HeaderKey = Title.Key;
		HeaderValue = Title.Value;
		// For the Authorization header, hide the password value.
		If Lower(HeaderKey) = "authorization" And Not IsBlankString(HeaderValue) Then
			PartsOfTheValue = StrSplit(HeaderValue, " ");
			If PartsOfTheValue.Count() = 1 Then
				PartsOfTheValue[0] = Asterisks;
			ElsIf Lower(PartsOfTheValue[0]) = "basic" Then
				Try
					UsernamePassword = GetStringFromBinaryData(Base64Value(PartsOfTheValue[1]));
					LoginPasswordParts = StrSplit(UsernamePassword, ":");
					If LoginPasswordParts.Count() >= 2 Then
						LoginPasswordParts[1] = Asterisks;
						PartsOfTheValue[1] = StrConcat(LoginPasswordParts, ":");
					Else
						PartsOfTheValue[1] = Asterisks;
					EndIf;
				Except
					PartsOfTheValue[1] = Asterisks;
				EndTry;
			Else
				PartsOfTheValue[1] = Asterisks;
			EndIf;
			HeaderValue = StrConcat(PartsOfTheValue, " ");
		EndIf;
		Headers.Add(StrTemplate("%1: %2", HeaderKey, HeaderValue));
	EndDo;
	
	If BinaryData Then
		RequestBody = GetBase64StringFromBinaryData(Query.GetBodyAsBinaryData());
	Else
		RequestBody = Query.GetBodyAsString();
	EndIf; 
	
	If StrLen(RequestBody) > 1000 Then
		RequestBody = StrTemplate(NStr("ru = '%1...';
									|en = '%1...';"), Left(RequestBody, 1000));
	EndIf; 
	
	Return StrTemplate(
		"%1
		|%2
		|
		|%3", Address, 
		StrConcat(Headers, Chars.LF), RequestBody);
	
EndFunction

Function ResponseDescription(Response, BinaryData = False)
	
	Headers = New Array;
	For Each Title  In Response.Headers Do
		Headers.Add(StrTemplate("%1: %2", Title.Key, Title.Value));
	EndDo; 
	
	If TypeOf(Response) = Type("HTTPServiceResponse") Then
		StatusCode = StrTemplate("%1 %2", Response.StatusCode, Response.Reason);
	Else
		StatusCode = Response.StatusCode
	EndIf; 
	
	If BinaryData Then
		ResponseBody = GetBase64StringFromBinaryData(Response.GetBodyAsBinaryData());
	Else
		ResponseBody = Response.GetBodyAsString();
	EndIf; 

	If StrLen(ResponseBody) > 1000 Then
		ResponseBody = StrTemplate(NStr("ru = '%1...';
									|en = '%1...';"), Left(ResponseBody, 1000));
	EndIf; 
	
	
	Return StrTemplate(
		"%1
		|%2
		|
		|%3", 
		StatusCode,
		StrConcat(Headers, Chars.LF), Response.GetBodyAsString());
	
EndFunction

#EndRegion

#EndRegion
