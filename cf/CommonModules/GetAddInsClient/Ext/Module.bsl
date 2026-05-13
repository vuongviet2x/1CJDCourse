///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaS.GetAddIns" subsystem.
// CommonModule.GetAddInsClient.
//
// Client procedures and functions for importing add-ins:
//  - Handle the "Online support and services" panel events
//  - Switch to interactive add-in update
//  - Set up add-in autoupdate
//  - Notify on add-in data updates
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the add-in update wizard.
// Available only for full-access users.
//
// Parameters:
//  IDs - Array of String, Undefined - List of add-in UUIDs.
//                   
//  UpdateFile - String, Undefined - The path to an add-in file.
//
Procedure UpdateAddIns(
		IDs = Undefined,
		UpdateFile = Undefined) Export
	
	FormParameters = New Structure(
		"IDs, UpdateFile",
		IDs,
		UpdateFile);
	OpenForm(
		"DataProcessor.AddInsUpdate.Form.Form",
		FormParameters);
	
EndProcedure

// Determines the name of the event that will contain the notification
// on completing the add-ins upload.
//
// Returns:
//  String - An event name. It can be used for forms to identify
//           messages they accept.
//
Function ImportNotificationEventName() Export
	
	Return "GetAddIns.AddInsDownloaded";
	
EndFunction

// Determines the schedule of a add-in update job.
//
// Returns:
//  Structure - The settings of the add-in update schedule job.
//              See GetAddIns.AddInsUpdateSettings.
//
Function AddInsUpdateSettings() Export
	
	Return GetAddInsServerCall.AddInsUpdateSettings();
	
EndFunction

// Changes the add-in update settings.
//
// Parameters:
//  Settings - Structure - Add-in update scheduled job settings.
//    **UpdateOption - Number - Update option number.
//    Add-in update scheduled job settings.
//    **UpdateOption - Number - Update option number.
//
Procedure ChangeAddInsUpdateSettings(Settings) Export
	
	GetAddInsServerCall.ChangeAddInsUpdateSettings(Settings);
	
EndProcedure

#EndRegion

#Region Internal

#Region OnlineUserSupportSubsystemsIntegration

// Processes notifications in the "Online support and services"
// administration panel.
//
// Parameters:
//  Form - ClientApplicationForm - Form where notification is processed.
//  EventName - String - Event name.
//  Parameter - Arbitrary - A parameter.
//  Source - Arbitrary - Event source.
//
Procedure OnlineSupportAndServicesProcessNotification(
		Form,
		EventName,
		Parameter,
		Source) Export
	
	If EventName <> "OnlineSupportDisabled"
			And EventName <> "OnlineSupportEnabled" Then
		Return;
	EndIf;
	
	SettingsOfUpdate = GetAddInsServerCall.AddInsUpdateSettings();
	
	If EventName = "OnlineSupportDisabled" Then
		
		If SettingsOfUpdate.UpdateOption = OptionsOfUpdateFromService() Then
			Form.Items.DecorationAddInsUpdateNotRunning.Visible = True;
		EndIf;
		
	ElsIf EventName = "OnlineSupportEnabled" Then
		
		If SettingsOfUpdate.Schedule <> Undefined Then
			Form.Items.DecorationAddInsUpdateSchedule.Title =
				OnlineUserSupportClientServer.SchedulePresentation(
					SettingsOfUpdate.Schedule);
		EndIf;
		Form.AddInsUpdateOption = SettingsOfUpdate.UpdateOption;
		Form.Items.DecorationAddInsUpdateNotRunning.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Defines the IDs and numbers of versions stored in the update file.
//
// Parameters:
//  FileName - String - The location of the add-ins archive.
//
// Returns:
//  Array - Contains add-in IDs and versions.
//
Function AddInsVersionsInFile(FileName) Export
	
	#If Not WebClient Then
	
	VersionsOfExternalComponents = New Array;
	
	If CommonClientServer.GetFileNameExtension(FileName) <> "zip" Then
		Return VersionsOfExternalComponents;
	EndIf;
	
	ManifestFile = Undefined;
	
	// ACC:574-off Mobile client doesn't use this code.
	
	ZipFileReader = New ZipFileReader(FileName);
	For Each ArchiveItem In ZipFileReader.Items Do
		
		If Upper(ArchiveItem.Name) = "EXTERNAL-COMPONENTS.JSON" Then
			ManifestFile = ArchiveItem;
			Break;
		EndIf;
		
	EndDo;
	
	If ManifestFile <> Undefined Then
	
		DetailsDirectory = CommonClientServer.AddLastPathSeparator(
			GetTempFileName(ManifestFile.BaseName));
		ZipFileReader.Extract(
			ManifestFile,
			DetailsDirectory,
			ZIPRestoreFilePathsMode.DontRestore);
		DescriptionFileName = DetailsDirectory + ManifestFile.Name;
		
		OperationResult = AddInsVersionsInformation(DescriptionFileName);
		If Not ValueIsFilled(OperationResult.ErrorCode) Then
			VersionsOfExternalComponents = OperationResult.AddInsData;
		EndIf;
		DeleteFiles(DetailsDirectory);
		
	EndIf;
	
	ZipFileReader.Close();
	
	// ACC:574-on
	
	Return VersionsOfExternalComponents;
	
	#Else
	
	Raise NStr("ru = 'Интерактивная загрузка архива с внешними компонентами при работе в веб-клиенте запрещена.';
							|en = 'Manual import of the archive with add-ins is not allowed in the web client.';");
	
	#EndIf
	
EndFunction

// Returns an event name for the event log
//
// Returns:
//  String - Event name.
//
Function EventLogEventName() Export
	
	Return NStr("ru = 'Получение внешних компонент.';
				|en = 'Get add-ins.';", CommonClient.DefaultLanguageCode());
	
EndFunction

// Returns the add-in files details from the manifest file.
//
// Returns:
//   Structure - The result of uploading add-ins.:
//    *ErrorCode              - String - File processing error code.
//    *ErrorMessage      - String - File processing error details.
//    *AddInsData - Array of Structure - Add-ins data.:
//     **Id          - String - The add-in UUID.
//     **Description           - String - The name of the add-in.
//                                Specified by the user when the add-in is created.
//                                
//     **Version                 - String - The add-in version number.
//     **VersionDate             - Date - The add-in version release date.
//     **VersionDetails         - String - Add-in version details.
//     **FileName               - String - The add-in version file name.
//
Function AddInsVersionsInformation(FileName)
	
	#If Not WebClient Then
	
	OperationResult = New Structure;
	OperationResult.Insert("ErrorCode",              "");
	OperationResult.Insert("ErrorMessage",      "");
	
	AddInsData = New Array;
	
	Try
		
		JSONReader = New JSONReader;
		JSONReader.OpenFile(FileName);
		VersionsOfExternalComponents = ReadJSON(JSONReader, , "buildDate");
		
		// Filling in a table with updates.
		For Each AddInDetails In VersionsOfExternalComponents Do
			
			AddInData = New Structure;
			AddInData.Insert("Id",    AddInDetails.externalComponentNick);
			AddInData.Insert("Description",     AddInDetails.externalComponentName);
			AddInData.Insert("Version",           AddInDetails.version);
			AddInData.Insert("VersionDate",       AddInDetails.buildDate);
			AddInData.Insert("VersionDetails",   "");
			AddInData.Insert("FileName",         AddInDetails.fileName);
			
			AddInsData.Add(AddInData);
			
		EndDo;
	
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить описание внешних компонент из файла по причине:
				|%1';
				|en = 'Cannot get add-in details from the file due to:
				|%1';"),
			ErrorInfo);
		EventLogClient.AddMessageForEventLog(
			EventLogEventName(),
			"Warning",
			Comment);
		OperationResult.ErrorCode = "AddInsDetailsFileInvalid";
		OperationResult.ErrorMessage = Comment;
	EndTry;
	
	JSONReader.Close();
	
	OperationResult.Insert("AddInsData", AddInsData);
	
	Return OperationResult;
	
	#Else
	
	Raise NStr("ru = 'Получение информации о версиях внешних компонент при работе в веб-клиенте запрещена.';
							|en = 'Getting information about add-in versions is not allowed in the web client.';");
	
	#EndIf
	
EndFunction

// Returns the number of the update option from the service.
// 
// Returns:
//  Number - An update option value.
//
Function OptionsOfUpdateFromService()
	Return 1;
EndFunction

#EndRegion
