#Region EventHandlers

// GET /version method handler.
//
Function VersionGet(Query)
	
	Response = New HTTPServiceResponse(200);
	Data = New Structure;
	Data.Insert("version", ServicePayment.InterfaceVersion());
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(Data));
	
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;
	
EndFunction

// POST /setup method handler.
//
Function InstallSettingsAdd(Query)
	
	Try
		
		Data = ServicePayment.JSONData(Query.GetBodyAsString());
		JobState = TaskStateTemplate();
		
		RequiredProperties_ = StrSplit("version,url,login,password,subscriber",",");
		ErrorText = "";
		If Not CheckFilling(Data, RequiredProperties_, ErrorText) Then
			Response = ErrorResponse(10400, ErrorText);
			Return Response;
		EndIf;
					
		Constants.UseServicePayment.Set(True);
		Constants.Fresh1CServiceAddress.Set(Data.url);
		Constants.AccountSystemUserName.Set(Data.login);
		Common.WriteDataToSecureStorage(ServicePayment.OwnerOfAuthorizationPasswordInAccountSystem(), Data.password);
		CurrentUser = Users.CurrentUser();
		InformationRegisters.AuthorizationIn1cFresh.AddRecord(
			CurrentUser, Data.login, Data.password, Data.subscriber);
			
		Parameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
		Parameters.BackgroundJobDescription = NStr("ru = 'Установка настроек оплаты сервиса';
													|en = 'Configure service payment settings';");
		Parameters.WaitCompletion = 1;
		ExecutionParameters = TimeConsumingOperations.ExecuteProcedure(
			Parameters, "ServicePayment.SetServicePaymentSettings", Data.subscriber);
		JobState = TaskToRespondState(ExecutionParameters);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StrTemplate(NStr("ru = 'Не удалось установить настройки по причине: %1';
									|en = 'Cannot set the settings due to: %1';"), 
			CloudTechnology.ShortErrorText(ErrorInfo));
		Response = ErrorResponse(10400,  ErrorText);
		ServicePayment.LogHTTPRequest(Query, Response);
		
		WriteLogEvent(ServicePayment.EventLogEvent(NStr("ru = 'Ошибка данных';
																				|en = 'Data error';")), 
			EventLogLevel.Error, Metadata.HTTPServices.Billing, , 
			CloudTechnology.DetailedErrorText(ErrorInfo)); 
		
		Return Response;
		
	EndTry;
		
	Response = New HTTPServiceResponse(200);
	ResponseData = ServicePayment.ResponseDataTemplate();
	ResponseData.Insert("tariff_loading_supported", ServicePayment.TariffLoadingIsSupported());
	ResponseData.Insert("tariff_loading_job", JobState); // Backward compatibility.
	ResponseData.Insert("setup_job", JobState); 
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;
	
EndFunction

// POST /uninstall method handler.
//
Function DeleteSettingsAdd(Query)
	
	Try
		
		Data = ServicePayment.JSONData(Query.GetBodyAsString());
		JobState = TaskStateTemplate();
		
		RequiredProperties_ = StrSplit("version,subscriber",",");
		ErrorText = "";
		If Not CheckFilling(Data, RequiredProperties_, ErrorText) Then
			Response = ErrorResponse(10400, ErrorText);
			Return Response;
		EndIf;

		Constants.UseServicePayment.Set(False);
		Constants.Fresh1CServiceAddress.Set("");
		Constants.AccountSystemUserName.Set("");
		Common.DeleteDataFromSecureStorage(ServicePayment.OwnerOfAuthorizationPasswordInAccountSystem());
		CurrentUser = Users.CurrentUser();
		InformationRegisters.AuthorizationIn1cFresh.DeleteRecord(CurrentUser);
		
		Parameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
		Parameters.BackgroundJobDescription = NStr("ru = 'Удаление настроек оплаты сервиса';
													|en = 'Delete service payment settings';");
		Parameters.WaitCompletion = 1;
		ExecutionParameters = TimeConsumingOperations.ExecuteProcedure(
			Parameters, "ServicePayment.DeleteServicePaymentSettings", Data.subscriber);
		
		JobState = TaskToRespondState(ExecutionParameters);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StrTemplate(NStr("ru = 'Не удалось удалить настройки по причине: %1';
									|en = 'Cannot delete the settings due to: %1';"), 
			CloudTechnology.ShortErrorText(ErrorInfo));
		Response = ErrorResponse(10400,  ErrorText);
		ServicePayment.LogHTTPRequest(Query, Response);
		
		WriteLogEvent(ServicePayment.EventLogEvent(NStr("ru = 'Ошибка данных';
																				|en = 'Data error';")), 
			EventLogLevel.Error, Metadata.HTTPServices.Billing, , 
			CloudTechnology.DetailedErrorText(ErrorInfo)); 
		
		Return Response;
		
	EndTry;
		
	Response = New HTTPServiceResponse(200);
	ResponseData = ServicePayment.ResponseDataTemplate();
	ResponseData.Insert("setup_job", JobState);
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;

EndFunction

// GET /setup_result/{JobID} method handler.
//
// URL parameters:
//  JobID - String - ID of the setup job.
//
Function SetDeleteSettingsStateGet(Query)
	
	JobID = New UUID(Query.URLParameters["JobID"]);
	ExecutionParameters = TimeConsumingOperations.ActionCompleted(JobID);
	ExecutionParameters.Insert("JobID", JobID);
	Response = New HTTPServiceResponse(200);
	ServicePayment.AddDataHeaders(Response);
	ResponseData = TaskToRespondState(ExecutionParameters);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	
	Return Response;
	
EndFunction

// POST /bill/{Version}/* method handler.
//
// URL parameters:
//  Version - String - API version.
//
Function InvoicePaymentAdd(Query)
	
	Return ResponseToInvoiceRequest(Query);
	
EndFunction

// PUT /bill/{Version}/* method handler.
//
// URL parameters:
//  Version - API version.
//
Function InvoicePaymentChange(Query)
	
	Return ResponseToInvoiceRequest(Query);
	
EndFunction
	
#EndRegion

#Region Private

Function CheckFilling(Data, RequiredProperties_, ErrorText = "")
	
	MissingProperties = New Array;
	For Each Property In RequiredProperties_ Do
		If Not Data.Property(Property) Then
			MissingProperties.Add(Property);
		EndIf;
	EndDo;
	
	If MissingProperties.Count() > 0 Then
		ErrorText = StrTemplate(
			NStr("ru = 'Отсутствуют обязательные свойства: %1';
				|en = 'Required properties are missing: %1';"), 
			StrConcat(MissingProperties, ", "));
		Return False;
	EndIf;
	
	InterfaceVersion = Data.version;
	
	If InterfaceVersion > ServicePayment.InterfaceVersion() Then
		ErrorText = StrTemplate(
			NStr("ru = 'Версия интерфейса оплат %1 менеджера сервиса не поддерживается приложением.';
				|en = 'The application does not support the %1 payment interface version of Service Manager.';"),
			InterfaceVersion);
		Return False;
	EndIf; 
	
	Return True;
	
EndFunction

Function TaskStateTemplate()
	
	TaskDataTemplate = New Structure;
	TaskDataTemplate.Insert("id", "");
	TaskDataTemplate.Insert("status", "");
	TaskDataTemplate.Insert("error", False);
	TaskDataTemplate.Insert("brief_message", "");
	TaskDataTemplate.Insert("detail_message", "");
	
	Return TaskDataTemplate;
	
EndFunction

Function TaskToRespondState(ExecutionParameters)
	
	JobState = TaskStateTemplate();
	JobState.id = String(ExecutionParameters.JobID);
	If ExecutionParameters.Status = "Running" Then
		JobState.status = "Running";
	ElsIf ExecutionParameters.Status = "Completed2" Then
		JobState.status = "Completed";
	ElsIf ExecutionParameters.Status = "Error" Then
		JobState.status = "Error";
		JobState.error = True;
		JobState.brief_message = ExecutionParameters.BriefErrorDescription;
		JobState.detail_message = ExecutionParameters.DetailErrorDescription;
	ElsIf ExecutionParameters.Status = "Canceled" Then
		JobState.status = "Canceled";
	EndIf;
	
	Return JobState;
	
EndFunction

Function ResponseToInvoiceRequest(Query)
	
	Try
		QueryData = ServicePayment.InvoiceRequestData(Query);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StrTemplate(NStr("ru = 'Не удалось прочитать данные по причине: %1';
									|en = 'Cannot read the data. Reason: %1';"), 
			CloudTechnology.ShortErrorText(ErrorInfo));
		Response = ErrorResponse(ServicePayment.ReturnCodeDataError(),  ErrorText);
		ServicePayment.LogHTTPRequest(Query, Response);
		
		WriteLogEvent(ServicePayment.EventLogEvent(NStr("ru = 'Ошибка данных';
																				|en = 'Data error';")), 
			EventLogLevel.Error, Metadata.HTTPServices.Billing, , 
			CloudTechnology.DetailedErrorText(ErrorInfo)); 
		
		Return Response;
		
	EndTry;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(QueryData.InvoiceId);
	ExecutionParameters.BackgroundJobDescription = StrTemplate(
		NStr("ru = 'Подготовка счета на оплату по запросу %1.';
			|en = 'Prepare a proforma invoice for request %1.';"), QueryData.InvoiceId);
	ExecutionParameters.WaitCompletion = 0;
	TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "ServicePayment.PrepareInvoiceForPayment", QueryData);
	
	Response = New HTTPServiceResponse(200);
	ResponseData = ServicePayment.ResponseDataTemplate();
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;

EndFunction

Function ErrorResponse(ErrorCode, ErrorText)
	
	Response = New HTTPServiceResponse(400);
	Data = ServicePayment.ResponseDataTemplate(ErrorCode, ErrorText);
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(Data));
	Return Response;
	
EndFunction
  
#EndRegion 

