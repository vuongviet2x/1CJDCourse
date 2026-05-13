///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.LicensingClient.
//
// Server procedures and functions for setting up the licensing client.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a licensing client name.
//
Function LicensingClientName() Export
	
	SetPrivilegedMode(True);
	Return GetLicensingClientName();
	
EndFunction

#EndRegion

#Region Private

// Defines a configuration ID.
//
// Returns:
//  String - configuration ID.
//
Function ConfigurationID() Export
	
	SetPrivilegedMode(True);
	Return GetConfigurationID();
	
EndFunction

#Region LicensingClientSettings

// Checks if licensing client settings match authentication credentials of
// online support.
// f the settings do not match, the OUS username and password are written to
// licensing client settings.
// Not used in SaaS mode.
//
// Returns:
//  Boolean - True if the user needs to enter a username and a password,
//           otherwise, False.
//
Function CheckLicensingClientSettings() Export
	
	SetPrivilegedMode(True);
	
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	If AuthenticationData = Undefined
		And InfobaseUpdate.InfobaseUpdateInProgress() Then
		// If the infobase is not yet updated, Online Support settings
		// might not be moved to the secure storage.
		// 
		AuthenticationData = OnlineSupportUserAuthenticationDataFromObsoleteData();
	EndIf;
	
	If AuthenticationData = Undefined Then
		Return False;
	EndIf;
	
	// Writing licensing client settings to the infobase
	If LicensingClientName() = AuthenticationData.Login Then
		// Valid login and invalid password. Ask the user to re-enter credentials.
		// 
		Return False;
	Else
		
		WriteAuthenticationDataToLicensingClientSettings(AuthenticationData.Login, AuthenticationData.Password);
		Return True;
		
	EndIf;
	
EndFunction

// Writes licensing client settings.
//
// Parameters:
//  Login - String - Username of an online support user.
//  Password - String - Password of an online support user.
//
Procedure WriteAuthenticationDataToLicensingClientSettings(Login, Password)
	
	ConnectionSettings = OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	
	SetLicensingClientParameters(
		Login,
		Password,
		AdditionalParameterValue(
			ConnectionSettings.OUSServersDomain));
	
EndProcedure

// Defines a value of an additional parameter
// of licensing client settings.
//
// Parameters:
//  DomainZone - Number - Domain zone ID.
//
// Returns:
//  String - An additional parameter.
//
Function AdditionalParameterValue(DomainZone)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		"domain=%1;",
		?(DomainZone = 0, "ru", "eu"));
	
EndFunction

#EndRegion

#Region LibEventsProcessing

// It is called upon changing data of OSL authentication.
//
// Parameters:
//  Login - String - Username of an online support user.
//  Password - String - Password of an online support user.
//
Procedure OnChangeAuthenticationData(Login, Password) Export
	
	WriteAuthenticationDataToLicensingClientSettings(Login, Password);
	
EndProcedure

// See CommonOverridable.BeforeStartApplication.
//
Procedure BeforeStartApplication() Export
	
	// If the call comes from a scheduled job, don't run this method.
	If CurrentRunMode() = Undefined Then
		Return;
	EndIf;
	
	// Update licensing client parameters.
	Try
		
		// Cannot get licensing client parameters in the separated mode.
		// 
		If Common.DataSeparationEnabled()
			And Common.SeparatedDataUsageAvailable() Then
			Return;
		EndIf;
		
		If Users.IsFullUser(, True, False) Then
			SetPrivilegedMode(True);
			DomainZone = OnlineUserSupportInternalCached.OUSServersConnectionSettings().OUSServersDomain;
			NewValueOfAddlParameter = AdditionalParameterValue(DomainZone);
			If GetLicensingClientAdditionalParameter() <> NewValueOfAddlParameter Then
				SetLicensingClientParameters(
					,
					,
					NewValueOfAddlParameter);
			EndIf;
			SetPrivilegedMode(False);
		EndIf;
		
	Except
		
		OnlineUserSupport.WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обновить значение дополнительного параметра в настройках клиента лицензирования.
					|%1';
					|en = 'Cannot update an additional parameter value in licensing client settings.
					|%1';"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		
	EndTry;
	
EndProcedure

#EndRegion

#Region GetDataFromObsoleteMetadataObjects

// Defines authentication data from the DeleteOnlineUserSupportParameters information register.
//
// Returns:
//  Structure - Authentication data:
//    *Login - String - Username of an online support user.
//    *Password - String - Password of an online support user.
//
Function OnlineSupportUserAuthenticationDataFromObsoleteData()
	
	RequestingParameters = New Query(
	"SELECT
	|	UserOnlineSupportParameters.Name AS ParameterName,
	|	UserOnlineSupportParameters.Value AS ParameterValue
	|FROM
	|	InformationRegister.DeleteOnlineUserSupportParameters AS UserOnlineSupportParameters
	|WHERE
	|	UserOnlineSupportParameters.Name IN (""login"", ""password"")
	|	AND UserOnlineSupportParameters.User = &BlankID");
	
	RequestingParameters.SetParameter("BlankID",
		New UUID("00000000-0000-0000-0000-000000000000"));
	
	Username3  = Undefined;
	UserPassword = Undefined;
	
	SetPrivilegedMode(True);
	SelectingParameters = RequestingParameters.Execute().Select();
	While SelectingParameters.Next() Do
		
		// Query is not case sensitive
		ParameterNameLower = Lower(SelectingParameters.ParameterName);
		If ParameterNameLower = "login" Then
			Username3 = SelectingParameters.ParameterValue;
			
		ElsIf ParameterNameLower = "password" Then
			UserPassword = SelectingParameters.ParameterValue;
			
		EndIf;
		
	EndDo;
	
	If Username3 <> Undefined And UserPassword <> Undefined Then
		Return New Structure("Login, Password", Username3, UserPassword);
	Else
		// Data is not found in the obsolete information register.
		// Look up in the obsolete secure storage.
		Return AuthenticationDataInObsoleteSafeStorage();
	EndIf;
	
EndFunction

// Defines authentication data from the secure storage.
//
// Returns:
//  Structure - Authentication data:
//    *Login - String - Username of an online support user.
//    *Password - String - Password of an online support user.
//
Function AuthenticationDataInObsoleteSafeStorage()
	
	Try
		OSLSubsystemIDObsolete =
			Common.MetadataObjectID(
				"Subsystem.OnlineUserSupport.Subsystem.CoreISL");
	Except
		// A rare case. When the function is being called, the IDs
		// of metadata objects in the SSL core are not yet updated.
		OnlineUserSupport.WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении данных аутентификации из устаревшего безопасного хранилища данных.
					|%1';
					|en = 'An error occurred while receiving authentication data from the obsolete secure data storage.
					|%1';"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Return Undefined;
	EndTry;
	
	DataInSafeStorageObsolete =
		Common.ReadDataFromSecureStorage(
			OSLSubsystemIDObsolete,
			"login,password");
	If DataInSafeStorageObsolete.login <> Undefined
		And DataInSafeStorageObsolete.password <> Undefined Then
		Return New Structure(
			"Login, Password",
			DataInSafeStorageObsolete.login,
			DataInSafeStorageObsolete.password);
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
