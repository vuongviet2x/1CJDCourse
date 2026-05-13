///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsClient.
//
// Client procedures and functions for importing classifiers:
//  - Handle the "Online support and services" panel events
//  - Switch to interactive classifier update
//  - Set up classifier autoupdate
//  - Notify on classifier data updates
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens a classifier update wizard.
//
Procedure RunClassifierUpdate() Export
	
	OpenForm("DataProcessor.UpdateClassifiers.Form.Form");
	
EndProcedure

// Defines a name of the event that will contain a notification
// about completing classifier import.
//
// Returns:
//  String - An event name. It can be used for forms to identify
//           messages they accept.
//
Function ImportNotificationEventName() Export
	
	Return "ClassifiersOperations.ClassifiersImported";
	
EndFunction

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ApplicationSettings.

// The URL event handler of the
// OSLClassifiersUpdateNotStartedDecorationURLProcessing form
// in the "Online support and services"
// SSL administration panel.
//
// Parameters:
//  Form - ClientApplicationForm - an administration panel form.
//  Item - ЭлементФормы - an information input field.
//  FormattedStringURL - String - URL.
//  StandardProcessing - Boolean - Flag of standard reference processing.
//
Procedure OnlineSupportAndServicesOSLDecorationClassifiersNotUpdatedURLProcessing(
		Form,
		Item,
		FormattedStringURL,
		StandardProcessing) Export
	
	StandardProcessing = False;
	
	If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
		ShowMessageBox(,
			NStr("ru = 'Для автоматического обновления классификаторов необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update classifiers automatically, 
				|enable online support.';"));
		Return;
	EndIf;
	
	OnlineUserSupportClient.EnableInternetUserSupport(
		Undefined,
		Form);
	
EndProcedure

// End StandardSubsystems.ApplicationSettings

#EndRegion

#EndRegion

#Region Internal

// Called upon the application start from
// OnlineUserSupportClient.OnStart().
//
Procedure OnStart() Export
	
	ClientParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientParametersOnStart.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	OUSParameters = ClientParametersOnStart.OnlineUserSupport;
	If OUSParameters.ClassifiersUpdateNotification Then
		
		AttachIdleHandler(
			"NotificationOnClassifiersUpdateEnabled",
			1,
			True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Defines IDs and numbers of versions that contain files with updates.
//
// Parameters:
//  FileName - String - a location of classifier archive.
//
// Returns:
//  Array - contains classifier IDs and version number.
//
Function ClassifiersVersionsInFile(FileName) Export
	
	#If Not WebClient Then
	
	ClassifiersVersions = New Array;
	
	If CommonClientServer.GetFileNameExtension(FileName) <> "zip" Then
		Return ClassifiersVersions;
	EndIf;
	
	// ACC:574-off Mobile client doesn't use this code.
	
	ZipFileReader = New ZipFileReader(FileName);
	For Each Item In ZipFileReader.Items Do
		
		// Encrypted archive items are not processed.
		If Item.Encrypted Then
			Continue;
		EndIf;
		
		SeparatorPosition = StrFind(Item.BaseName, "_", SearchDirection.FromEnd);
		
		// If the filename format is not [ID]_[Version], the subsystem must skip it.
		// 
		If SeparatorPosition = 0 Then
			Continue;
		EndIf;
		
		Try
			Version        = Number(StrReplace(Mid(Item.BaseName, SeparatorPosition + 1), Chars.NBSp, ""));
			Id = Left(Item.BaseName, SeparatorPosition - 1);
		Except
			Version = Undefined;
			Id = Undefined;
		EndTry;
		
		// If the filename contains invalid data, the subsystem must skip it.
		// 
		If Not ValueIsFilled(Id) Or Not ValueIsFilled(Version) Then
			Continue;
		EndIf;
		
		VersionDetails = New Structure;
		VersionDetails.Insert("Id", Id);
		VersionDetails.Insert("Version",        Version);
		VersionDetails.Insert("Name",           Item.Name);
		ClassifiersVersions.Add(VersionDetails);
		
	EndDo;
	
	ZipFileReader.Close();
	
	// ACC:574-on
	
	Return ClassifiersVersions;
	
	#Else
	
	Raise NStr("ru = 'Интерактивная загрузка архива с классификаторами при работе в веб-клиенте запрещена.';
							|en = 'Interactive import of archive with classifiers while working in the web client is prohibited.';");
	
	#EndIf
	
EndFunction

// Returns an event name for the event log
//
// Returns:
//  String - Event name.
//
Function EventLogEventName() Export
	
	Return NStr("ru = 'Работа с классификаторами';
				|en = 'Classifiers';",
		CommonClient.DefaultLanguageCode());
	
EndFunction

#EndRegion
