///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AdditionalReportsAndDataProcessors

// ACC:78-off additional data processor.

// Assignable client command handler.
//
// Parameters:
//   CommandID - String - Command name as it is given in function ExternalDataProcessorInfo of the object module.
//   RelatedObjects - Array - References the command runs for.
//
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjects) Export
	
	Parameters.CommandID = CommandID;
	CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
	CommandParameters.RelatedObjects = RelatedObjects;
	ExecuteCommandDirectly(CommandParameters);
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure
// ACC:78-on.

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.AdditionalDataProcessorRef) Then
		Settings = AdditionalReportsAndDataProcessors.LoadSettings(Parameters.AdditionalDataProcessorRef);
		
		If TypeOf(Settings) = Type("Structure") Then
			FileAddress = CommonClientServer.StructureProperty(Settings, "FileAddress");
		EndIf;
	Else
		Parameters.CommandID = "FormSettings";
	EndIf;
	
	If Not ValueIsFilled(FileAddress) Then
		FileAddress = "https://www.1c.ru/ftp/pub/pricelst/price_1c.zip";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FileAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Title = NStr("ru = 'Укажите путь к файлу прайс-листа';
										|en = 'Specify a path to the price list file';");
	OpenFileDialog.Filter = NStr("ru = 'Файл Microsoft Office Excel (*.xls)|*.xls|Архив (*.zip)|*.zip';
										|en = 'Microsoft Office Excel File (*.xls)|*.xls|Archive(*.zip)|*.zip';");
	OpenFileDialog.Multiselect = False;
	
	Context = New Structure("OpenFileDialog", OpenFileDialog);
	
	Notification = New NotifyDescription("SelectingFileCompletion", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(Notification, OpenFileDialog);
	
EndProcedure

&AtClient
Procedure SelectingFileCompletion(SelectedFiles, Context) Export
	
	OpenFileDialog = Context.OpenFileDialog;
	
	If (SelectedFiles <> Undefined) Then
		FileAddress = OpenFileDialog.FullFileName;
		If ValueIsFilled(Parameters.AdditionalDataProcessorRef) Then
			SaveFormSettings(Parameters.AdditionalDataProcessorRef, FileAddress);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FileAddressClearing(Item, StandardProcessing)
	FileAddress = "https://www.1c.ru/ftp/pub/pricelst/price_1c.zip";
	If ValueIsFilled(Parameters.AdditionalDataProcessorRef) Then
		SaveFormSettings(Parameters.AdditionalDataProcessorRef, FileAddress);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	SaveFormSettings(Parameters.AdditionalDataProcessorRef, FileAddress);
	Close();
	
EndProcedure

&AtClient
Procedure SaveAndImport(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	Permissions = InteractivePermissionsRequest();
	Handler = New NotifyDescription("SaveAndImportCompletion", ThisObject);
	SafeModeManagerClient.ApplyExternalResourceRequests(Permissions, ThisObject, Handler);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveAndImportCompletion(Result, AdditionalParameters) Export
	
	AccompanyingText1 = NStr("ru = 'Загрузка номенклатуры';
								|en = 'Import products';");
	
	CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
	CommandParameters.Insert("FileAddress", FileAddress);
	CommandParameters.AccompanyingText1 = AccompanyingText1 + "...";
	
	ShowUserNotification(CommandParameters.AccompanyingText1);
	
	Handler = New NotifyDescription("AfterFinishTimeConsumingOperation", ThisObject, AccompanyingText1);
	
	Operation = ExecuteCommandDirectly(CommandParameters);
	ExecuteNotifyProcessing(Handler, Operation);
	
EndProcedure

&AtClient
Procedure AfterFinishTimeConsumingOperation(Operation, AccompanyingText1) Export
	
	If Operation.Status = "Completed2" Then
		ShowUserNotification(NStr("ru = 'Успешное завершение';
											|en = 'Successful completion';"), , AccompanyingText1, PictureLib.Success32);
	Else
		ShowMessageBox(, Operation.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettings(AdditionalDataProcessorRef, FileAddress)
	
	ValueToSave = New Structure("FileAddress", FileAddress);
	AdditionalReportsAndDataProcessors.ShouldSaveSettings(AdditionalDataProcessorRef, ValueToSave);
	
EndProcedure

&AtServer
Function ExecuteCommandDirectly(CommandParameters)
	
	Operation = New Structure("Status, BriefErrorDescription, DetailErrorDescription");
	Try
		AdditionalReportsAndDataProcessors.ExecuteCommandFromExternalObjectForm(
			Parameters.CommandID,
			CommandParameters,
			ThisObject);
		Operation.Status = "Completed2";
	Except
		Operation.BriefErrorDescription   = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Operation.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	Return Operation;
	
EndFunction

&AtServer
Function InteractivePermissionsRequest()
	
	Permissions = New Array();
	
	IsInternetAddress = False;
	For Each Prefix In InternetProtocolsPrefixes() Do
		If Left(Lower(FileAddress), StrLen(Prefix)) = Lower(Prefix) Then
			IsInternetAddress = True;
			Break;
		EndIf;
	EndDo;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If IsInternetAddress Then
		
		URIStructure = CommonClientServer.URIStructure(FileAddress);
		
		Permissions.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				Lower(URIStructure.Schema),
				Lower(URIStructure.Host),
				URIStructure.Port));
		
	Else
		
		AddressInFileSystem = StrReplace(FileAddress, "\", "/");
		AddressStructure1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AddressInFileSystem, "/", True, False);
		AddressStructure1.Delete(AddressStructure1.UBound());
		Directory = StrConcat(AddressStructure1, ",");
		
		Permissions.Add(
			ModuleSafeModeManager.PermissionToUseFileSystemDirectory(Directory, True, False));
		
	EndIf;
	
	IDs = New Array();
	IDs.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(
			Parameters.AdditionalDataProcessorRef,
			Permissions,
			True));
	
	Return IDs;
	
EndFunction

&AtServerNoContext
Function InternetProtocolsPrefixes()
	
	Result = New Array();
	
	Result.Add("http");
	Result.Add("https");
	Result.Add("ftp");
	Result.Add("ftps");
	
	Return Result;
	
EndFunction

#EndRegion
