#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Returns a version.
// 
// Returns:
//  Number
Function Version() Export
	
	Return 1.2;
	
EndFunction
 
// Returns HTTPConnection.
// 
// Parameters: 
//  Address - String
//  Login - String
//  Password - String
//  Timeout - Number
// 
// Returns:
//  HTTPConnection
Function Join(Address, Login = Undefined, Password = Undefined, Timeout = 30) Export

	AddressParts = CommonClientServer.URIStructure(Address);
	Join = New HTTPConnection(AddressParts.Host, 443, Login, Password,
		GetFilesFromInternet.GetProxy(AddressParts.Schema), Timeout,
		New OpenSSLSecureConnection(,New OSCertificationAuthorityCertificates));
	
	Return Join;
	
EndFunction

// Get data.
// 
// Parameters:
//  Parameters - Structure:
// * Address - String
// * Method - String
//  ResultAddress - String - Address to save the result to.
// 
// Returns: 
//  See QueryResult
Function GetData(Parameters, ResultAddress) Export
	
	Address = Parameters.Address;
	Method = Parameters.Method;
	
	Join = Join(Address);
	Query = New HTTPRequest(StrTemplate("/info/hs/migration/%1", Method));
	
	Try
		Response = Join.CallHTTPMethod("GET", Query);
		Result = QueryResult(Response);
	Except
		ErrorInfo = ErrorInfo();
		Result = RequestExecutionError(ErrorInfo);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
	Return Result;
	
EndFunction

Procedure SendData(Parameters, ResultAddress) Export
	
	Address = Parameters.Address;
	Method = Parameters.Method;
	Data = Parameters.Data;
	
	Join = Join(Address);
	Query = New HTTPRequest(StrTemplate("/info/hs/migration/%1", Method));
	Query.SetBodyFromString(SaaSOperationsCTL.StringFromJSONStructure(Data));
	Try
		Response = Join.CallHTTPMethod("POST", Query);
		PutToTempStorage(QueryResult(Response), ResultAddress);
	Except
		ErrorInfo = ErrorInfo();
		PutToTempStorage(RequestExecutionError(ErrorInfo), ResultAddress);
	EndTry;
	
EndProcedure

Function ExecuteExternalInterfaceMethod(Parameters, ResultAddress) Export
	
	APIAddress = Parameters.APIAddress;
	Method = Parameters.Method;
	MethodComposition = StrSplit(Method,"/");
	RequestType_ = MethodComposition[0];
	MethodComposition.Delete(0);
	Method = StrConcat(MethodComposition, "/");
	
	SoftwareInterfaceVersion = 0;
	Parameters.Property("SoftwareInterfaceVersion", SoftwareInterfaceVersion);
	MethodInAddressIsSupported = (SoftwareInterfaceVersion <> Undefined And SoftwareInterfaceVersion >=19);
	
	Authorization = Parameters.Authorization;
	Data = Parameters.Data;
	If Parameters.Property("Timeout") Then
		Timeout = Parameters.Timeout;
	Else
		Timeout = 30;
	EndIf;
	
	URLStructure1 = CommonClientServer.URIStructure(APIAddress);
	Join = Join(URLStructure1.Host, Authorization.Login, Authorization.Password, Timeout);
	
	ResourceAddress = StrTemplate("%1/execute", URLStructure1.PathAtServer);
	If MethodInAddressIsSupported Then
		ResourceAddress = ResourceAddress + "/" + RequestType_ + "/" + Method;
	EndIf;
	Query = New HTTPRequest(ResourceAddress);
	
	If Data <> Undefined Then
		QueryData = Common.CopyRecursive(Data);
	Else
		QueryData = New Structure;
	EndIf; 
	
	If Not MethodInAddressIsSupported Then
		MainSection_ = New Structure;
		MainSection_.Insert("type", RequestType_);
		MainSection_.Insert("method", Method);
		If TypeOf(QueryData) = Type("Structure") Then
			QueryData.Insert("general", MainSection_);
		EndIf;
	EndIf;
	
	If Authorization.Property("SubscriberCode") Then
		AuthorizationSection = New Structure;
		AuthorizationSection.Insert("account", Authorization.SubscriberCode);
		If TypeOf(QueryData) = Type("Structure") Then
			QueryData.Insert("auth", AuthorizationSection);
		EndIf;
	EndIf;
	
	Query.SetBodyFromString(SaaSOperationsCTL.StringFromJSONStructure(QueryData));
	
	Try
		Response = Join.CallHTTPMethod("POST", Query);
		Result = QueryResult(Response);
	Except
		ErrorInfo = ErrorInfo();
		Result = RequestExecutionError(ErrorInfo);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
	Return Result;
	
EndFunction

// Transfers the file to the cloud service server.
// 
// Parameters:
//  Parameters - Structure:
//   * APIAddress - String
//   * SoftwareInterfaceVersion - Number
//   * Login - String
//   * Password - String
//   * SubscriberCode - Number
//   * FileName - String
//   * FileSize - Number
//   * TemporaryStorageFileName - String
//  ResultAddress - String - Address where the result is saved in the temporary storage.
//
Procedure TransferFile_(Parameters, ResultAddress) Export
	
	MethodParameters = New Structure;
	MethodParameters.Insert("APIAddress", Parameters.APIAddress);
	MethodParameters.Insert("SoftwareInterfaceVersion", Parameters.SoftwareInterfaceVersion);
	MethodParameters.Insert("Authorization", AuthorizationParameters(Parameters.Login, Parameters.Password));
	MethodParameters.Insert("Method", "srv/files/new_multipart");
	
	Data = New Structure;
	Data.Insert("name", Parameters.FileName);
	Data.Insert("size", Parameters.FileSize);
	Data.Insert("type", "new_data_dump");
	Data.Insert("owner", Parameters.SubscriberCode);
	
	MethodParameters.Insert("Data", Data);
	
	Result = ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
	
	If Result.Error Then
		Return;
	EndIf;
	
	FileID = Result.Data.file_id;
	FileLocation1 = FilesCTL.FullTemporaryStorageFileName(Parameters.TemporaryStorageFileName);
	Location = Result.Data.url;
	
	If Result.Data.type = "s3" Then
		
		BlockSize = 1024 * 1024 * 100; // 100 MB.
		URIStructure = CommonClientServer.URIStructure(Location);
		Join = Join(Location);
		DataStream = FileStreams.Open(FileLocation1, FileOpenMode.Open, FileAccess.Read);
		SendingRange = New Structure;
		SendingRange.Insert("Begin", 0);
		SendingRange.Insert("End", Min(BlockSize - 1, Parameters.FileSize - 1));
		Parts = New Array;
		While True Do
			Buffer = New BinaryDataBuffer(SendingRange.End - SendingRange.Begin + 1);
			DataStream.Read(Buffer, 0, Buffer.Size);
			DataRequest = New HTTPRequest(URIStructure.PathAtServer);
			DataRequest.SetBodyFromBinaryData(GetBinaryDataFromBinaryDataBuffer(Buffer));
			For Each Title In Result.Data.headers Do
				KeyValue = StrSplit(Title, ":");
				DataRequest.Headers.Insert(KeyValue[0], KeyValue[1]);
			EndDo; 
			Response = Join.CallHTTPMethod("PUT", DataRequest);
			If Response.StatusCode <> 200 Then
				DataStream.Close();
				MethodParameters.Method = "srv/files/abort_multipart";
				MethodParameters.Data = New Structure("file_id", FileID);
				ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
				Result = ResultTemplate();
				Result.Error = True;
				Result.ErrorMessage = StrTemplate(
					NStr("ru = 'Не удалось отправить часть файла, код ответа: %1%2%3';
						|en = 'Cannot send the file part. Response code: %1%2%3';"), 
					Response.StatusCode, Chars.LF, Response.GetBodyAsString());
				PutToTempStorage(Result, ResultAddress);
				Return;
			EndIf;
			Parts.Add(StrReplace(CommonCTL.HTTPHeader(Response, "ETag"),"""",""));
			SendingRange.Begin = SendingRange.End + 1;
			SendingRange.End = Min(SendingRange.End + BlockSize, Parameters.FileSize - 1);
			If SendingRange.Begin > SendingRange.End Then // All data has been sent.
				Break;
			EndIf;
			MethodParameters.Method = "srv/files/new_part";
			MethodParameters.Data = New Structure("file_id, part_number", FileID, Parts.Count() + 1);
			Result = ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
			If Result.Error Then
				DataStream.Close();
				Return;
			EndIf;
			URIStructure = CommonClientServer.URIStructure(Result.Data.url);
		EndDo;
		DataStream.Close();
		
		MethodParameters.Method = "srv/files/complete_multipart";
		MethodParameters.Data = New Structure("file_id, parts", FileID, Parts);
		ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
		If Result.Error Then
			Return;
		EndIf;
			
	Else
		
		AccessParameters = New Structure;
		AccessParameters.Insert("URL", Parameters.APIAddress);
		AccessParameters.Insert("UserName", Parameters.Login);
		AccessParameters.Insert("Password", Parameters.Password);
		
		SendOptions = New Structure;
		SendOptions.Insert("Location", Location);
		SendOptions.Insert("SetCookie", Undefined);
		
		Result = DataTransferServer.SendPartOfFileToLogicalStorage(
			AccessParameters, SendOptions, FileLocation1);
			
		If Result = Undefined Then
			Result = ResultTemplate();
			Result.Error = True;
			Result.ErrorMessage = StrTemplate(
				NStr("ru = 'Не удалось отправить файл по адресу: %1';
					|en = 'Cannot send the file to: %1';"), Location);
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
		
	EndIf;
	
	Result = ResultTemplate();
	Result.Insert("FileID", FileID);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Returns authorization parameters.
// 
// Parameters: 
//  Login - String
//  Password - String
//  SubscriberCode - Number
// 
// Returns: 
//  Structure - Authorization parameters:
// * Login - String
// * Password - String
// * SubscriberCode - Number - If the value is passed in the parameters.
Function AuthorizationParameters(Login, Password, SubscriberCode = Undefined) Export
	
	AuthorizationParameters = New Structure;
	AuthorizationParameters.Insert("Login", Login);
	AuthorizationParameters.Insert("Password", Password);
	If Not SubscriberCode = Undefined Then
		AuthorizationParameters.Insert("SubscriberCode", SubscriberCode);
	EndIf; 
	
	Return AuthorizationParameters;
	
EndFunction

Procedure GetInformationAboutTransitionOptions(Parameters, ResultAddress) Export

	QueryOptions = New Structure;
	QueryOptions.Insert("Address", Parameters.Address);
	QueryOptions.Insert("Method", Parameters.MethodInformation);
	
	Result = New Structure;
	Result.Insert("Information", GetData(QueryOptions, ResultAddress));
	
	QueryOptions.Insert("Method", Parameters.LoadingOptionsMethod);
	Result.Insert("ImportOptions", GetData(QueryOptions, ResultAddress));
	Result.Insert("VersionOfProcessingOnServer", 0);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure
 
#EndRegion 
 
#Region Private

// Parameters:
//  Response - HTTPResponse
//  IncludeHeadings - Boolean
// 
// Returns:
//  Structure:
//   * Headers - Array of String
//   * Data - Arbitrary
//   * ErrorMessage - String
//   * Error - Boolean
//   * ResponseBody - String
//   * StatusCode - Number
Function QueryResult(Response, IncludeHeadings = False)
	
	ResponseString = Response.GetBodyAsString();
	
	Result = ResultTemplate();
	
	If IncludeHeadings Then
		Headers = New Array;
		For Each Title In Response.Headers Do
			Headers.Add(StrTemplate("%1:%2", Title.Key, Title.Value));
		EndDo; 	
		Result.Insert("Headers", Headers);
	EndIf; 
	
	Result.StatusCode = Response.StatusCode;
	Result.ResponseBody = ResponseString;
	Result.Error = (Response.StatusCode > 204);
	
	If Response.StatusCode = 401 Then
		Result.ErrorMessage = NStr("ru = 'Ошибка авторизации. Неправильно задан логин или пароль.';
											|en = 'Authorization error. Username or password is incorrect.';"); 
	ElsIf Response.StatusCode = 403 Then
		Result.ErrorMessage = NStr("ru = 'Ошибка авторизации. У пользователя нет доступа к программному интерфейсу.';
											|en = 'Authorization error. User does not have access to API.';");
	ElsIf Response.StatusCode = 404 Then
		Result.ErrorMessage = NStr("ru = 'Не найдено. Адрес сервиса указан неверно или сервис не найден.';
											|en = 'Not found. Service address is incorrect or service is not found.';");
	ElsIf Response.StatusCode >= 500 Then
		Result.ErrorMessage = NStr("ru = 'Внутренняя ошибка. Подробности в журнале регистрации.';
											|en = 'Internal error. For more information, see the event log.';");
	EndIf;
	
	If Result.Error Then
		WriteLogEvent(
			NStr("ru = 'Переход в облако';
				|en = 'Cloud migration';"), 
			EventLogLevel.Error,,,
			ResponseString);
		If Not IsBlankString(ResponseString) Then
			//@skip-check empty-except-statement - If failed to receive data, don't make an attempt to return it.
			Try
				Result.Data = SaaSOperationsCTL.StructureFromJSONString(ResponseString);	
				If Result.Data.Property("message") Then
					Result.ErrorMessage = Result.Data.message;
				ElsIf Result.Data.Property("description") Then
					Result.ErrorMessage = Result.Data.description;
				EndIf; 
			Except
			EndTry;
		EndIf; 
			
		Return Result;
	ElsIf Not IsBlankString(ResponseString) Then
		Result.Data = SaaSOperationsCTL.StructureFromJSONString(ResponseString);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function RequestExecutionError(ErrorInfo)
	
	WriteLogEvent(
		NStr("ru = 'Переход в облако';
			|en = 'Cloud migration';"), 
		EventLogLevel.Error,,,
		CloudTechnology.DetailedErrorText(ErrorInfo));
		
	Result = ResultTemplate();
	Result.Error = True;
	Result.ErrorMessage = CloudTechnology.DetailedErrorText(ErrorInfo);
	
	Return Result;
	
EndFunction

Function ResultTemplate()
	
	Result = New Structure;
	Result.Insert("StatusCode", 0);
	Result.Insert("ResponseBody", "");
	Result.Insert("Error", False);
	Result.Insert("ErrorMessage", "");
	Result.Insert("Data", Undefined);
	
	Return Result;
	
EndFunction
 
#EndRegion 

#EndIf