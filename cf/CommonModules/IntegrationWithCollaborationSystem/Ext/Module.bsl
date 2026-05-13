#Region Public

// Data for managing the interaction system.
// 
// Returns: 
//  String
Function DataForInteractionSystemManagement() Export
	
	DataFromStorage = Common.ReadDataFromSecureStorage(
		"DataForInteractionSystemManagement", 
		"DataForInteractionSystemManagement");
	
	Return String(DataFromStorage);
	
EndFunction

// Connection to collaboration system in SaaS mode is available.
// 
// Returns:
//  Boolean - False.
Function CanConnectToCollaborationSystemSaaS() Export
	
	Return False;
	
EndFunction

// Returns the result of a request to the HTTP service to manage the collaboration system
//
// Parameters:
//  ManagementServicePublicationURL - String
//  ControlCode					 - String
//  MethodName						 - String
//  QueryOptions				 - Structure
// 
// Returns:
//  Structure - Result of a request to the service with the following fields:
//		* Success - Boolean
//		* MessageText - String
//		* ResultData - Structure
//
Function RequestToService(ManagementServicePublicationURL, ControlCode, MethodName, QueryOptions = Undefined)
	
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("MessageText", "");
	Result.Insert("ResultData", Undefined);
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ManagementServicePublicationURL);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		SecureConnection = 
			CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
		
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		
		QueryData = New Structure;
		QueryData.Insert("control_code", ControlCode);
		QueryData.Insert("method", MethodName);
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, QueryData);
		
		QueryString = JSONWriter.Close();
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
		
		Query = New HTTPRequest(PathAtServer, Headers);
		Query.SetBodyFromString(QueryString);
		
		Response = Join.Post(Query);
		
		If Response.StatusCode <> 200 Then
			ErrorText = StrTemplate(NStr("ru = 'Ошибка %1';
										|en = 'Error %1';", Common.DefaultLanguageCode()), String(Response.StatusCode));
			Raise ErrorText;
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			Raise ResponseBodyString;
		EndTry;
		
		If ResponseData.error Then
			Result.MessageText = ResponseData.message;
			Return Result;
		EndIf;
		
		If MethodName = NameOfDatabaseRegistrationMethod() Then
			
			BaseName = QueryOptions.BaseName;
			RegistrationParameters = New(TypeInformationSecurityRegistrationParameters()); // CollaborationSystemInfoBaseRegistrationParameters
			RegistrationParameters.ServerAddress = ResponseData.ServerAddress;
			RegistrationParameters.Email = ResponseData.SubscriberID;
			RegistrationParameters.InfoBaseName = BaseName;
			RegistrationParameters.ActivationCode = ResponseData.ActivationCode;
			
			RegistrationResult = 
				IntegrationWithCollaborationSystem.ObjectOfInteractionSystem().RegisterInfoBase(
					RegistrationParameters);
			
			If RegistrationResult.RegistrationCompleted Then
				Result.Success = True;
				Result.ResultData = New Structure;
				Result.ResultData.Insert("UserData_", ResponseData.Users);
			Else
				Result.MessageText = RegistrationResult.MessageText;
			EndIf;
			
		ElsIf MethodName = MethodNameListOfUsers() Then
			
			Result.Success = True;
			Result.ResultData = New Structure;
			Result.ResultData.Insert("UserData_", ResponseData.Users);
			
		EndIf;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate("%1.%2", EventLogEventName(), NStr("ru = 'Регистрация базы через сервис';
																	|en = 'Base registration via the service';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		
		Result.MessageText = CloudTechnology.ShortErrorText(ErrorInfo);
		
	EndTry;
	
	Return Result;
	
EndFunction

// Register the infobase via a service.
// 
// Parameters: 
//  ManagementServicePublicationURL - String
//  ControlCode - String
//  BaseName - String
// 
// Returns: See RequestToService
Function RegisterDatabaseThroughService(ManagementServicePublicationURL, ControlCode, BaseName) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("BaseName", BaseName);
	Return RequestToService(
		ManagementServicePublicationURL, 
		ControlCode, 
		NameOfDatabaseRegistrationMethod(), 
		QueryOptions);
	
EndFunction

// Collaboration System integration in SaaS is enabled.
// 
// Returns:
//  Boolean
Function IntegrationWithCollaborationSystemUsedSaaS() Export
	
	Return False;
	
EndFunction

// Interaction system object.
// 
// Returns: 
//  CollaborationSystemManager
Function ObjectOfInteractionSystem() Export
	
	Return CollaborationSystem;
	
EndFunction

// Collaboration system supports on-server registration.
// 
// Returns:
//  Boolean
Function CollaborationSystemRegistrationSupportedAtServer() Export
	
	Info = New SystemInfo;
	If CommonClientServer.CompareVersions(
		Info.AppVersion, 
		MinPlatformVersion1()) < 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Get information about service users.
// 
// Parameters: 
//  ManagementServicePublicationURL - String
//  ControlCode - String
// 
// Returns: See RequestToService
//
Function GetDataAboutServiceUsers(ManagementServicePublicationURL, ControlCode) Export
	
	Return RequestToService(
		ManagementServicePublicationURL, 
		ControlCode, 
		MethodNameListOfUsers());
	
EndFunction

// Returns the decrypted data for managing the collaboration system via the HTTP service.
//
// Parameters:
//  DataToManage - String - encrypted data
// 
// Returns:
//  Structure - Decryption result with the following fields:
//	* MessageText - String - a message generated when decrypting
//	* Deciphered - Boolean - indicates that the decryption is successfully completed
//	* Data - Structure - Decrypted data:
//	  ** ManagementServicePublicationURL - String
//	  ** ControlCode - String
//
Function DecryptDataForManagement(DataToManage) Export
	
	Result = New Structure;
	Result.Insert("MessageText", "");
	Result.Insert("Deciphered", False);
	Result.Insert("Data", Undefined);
	
	Try
	
		BinaryData = base64UrlDecode(DataToManage);
		
		DataReader = New DataReader(BinaryData);
		ReadingResult = "";
		While Not DataReader.ReadCompleted Do
			ReadLine_ = DataReader.ReadLine();
			ReadingResult = ReadingResult + ReadLine_ + Chars.LF;
		EndDo;
		DataReader.Close();
		
		StructureOfData = StructureFromJSONString(ReadingResult);
		
		Result.Data = StructureOfData;
		Result.Deciphered = True;
	
	Except
		
		ErrorInfo = ErrorInfo();
		Result.MessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Returns: 
//  Type - Type. 
Function TypeCollectionOfApplicationIds() Export
	
	Return Type("CollaborationSystemApplicationIDCollection");
	
EndFunction

// Returns: 
//  Type - Type. 
Function TypeInformationSecurityRegistrationParameters() Export
	
	Return Type("CollaborationSystemInfoBaseRegistrationParameters");
	
EndFunction

// Returns: 
//  Type - Type. 
Function TypeAppSharing() Export
	
	Return Type("CollaborationSystemApplicationLinks");
	
EndFunction

#EndRegion

#Region Private

Function base64UrlDecode(Val String)
	
	While StrLen(String) % 4 <> 0 Do
		String = String + "=";
	EndDo;
	
	String = StrReplace(String, "-", "+");
	String = StrReplace(String, "_", "/");
	
	Return Base64Value(String);
	
EndFunction

Function NameOfDatabaseRegistrationMethod()
	
	Return "register";
	
EndFunction

Function MethodNameListOfUsers()
	
	Return "users_list";
	
EndFunction

Function EventLogEventName()
	
	Return NStr("ru = 'Система взаимодействия';
				|en = 'Collaboration system';", Common.DefaultLanguageCode());
	
EndFunction

// Platform version. The server methods required to register the infobase in the collaboration system appeared in this 1C:Enterprise version.
// 
// Returns:
//  String - version
//
Function MinPlatformVersion1()
	
	Return "8.3.15.1000";
	
EndFunction

Function StructureFromJSONString(String, DateTypeProperties = Undefined)
    
	JSONReader = New JSONReader;
    JSONReader.SetString(String);
    Response = ReadJSON(JSONReader,, DateTypeProperties, JSONDateFormat.ISO); 
    Return Response
    
EndFunction

#EndRegion