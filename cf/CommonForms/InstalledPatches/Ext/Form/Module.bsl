///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var CurrentContext;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	If DataSeparationEnabled Then
		Items.InformationDetails.Title = NStr("ru = 'Состав исправлений настраивается администратором приложения.';
													|en = 'Patches are configured by the application administrator.';");
	ElsIf Parameters.OnUpdate Then
		Items.InformationDetails.Title = NStr("ru = 'Установленные исправления вступят в силу после перезапуска приложения.';
													|en = 'Installed patches will be applied after the application restart.';");
	ElsIf Not Common.IsWindowsClient() Then
		Items.InformationPages.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.Corrections) Then
		If TypeOf(Parameters.Corrections) = Type("ValueList") Then
			Filter = Parameters.Corrections;
		ElsIf TypeOf(Parameters.Corrections) = Type("Array") Then
			Filter.LoadValues(Parameters.Corrections);
		EndIf;
	EndIf;
	
	OnUpdate = Parameters.OnUpdate;
	Items.InstalledPatchesClose.Visible = OnUpdate;
	
	If DataSeparationEnabled
		Or Not Common.IsWindowsClient()
		Or Parameters.OnUpdate Then
		Items.FormInstallPatch.Visible = False;
		Items.FormDeletePatch.Visible    = False;
		Items.InstalledPatchesExportAttachedPatches.Visible = False;
		Items.InstalledPatchesContextMenuAdd.Visible = False;
		Items.InstalledPatchesContextMenuDelete.Visible  = False;
		Items.InstalledPatchesAttach.Visible = False;
	EndIf;
	
	RefreshPatchesList();
	
	Items.InstalledPatchesApplicableTo.Visible = False;
	
	IsWebClient = Common.IsWebClient() Or Common.ClientConnectedOverWebServer();
	Items.FindAndInstallUpdates.Visible = Not IsWebClient
		And Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationEventLogClick(Item)
	EventsArray = New Array;
	EventsArray.Add(NStr("ru = 'Исправления.Установка';
								|en = 'Patch.Install';"));
	EventsArray.Add(NStr("ru = 'Исправления.Изменение';
								|en = 'Patch.Modify';"));
	EventsArray.Add(NStr("ru = 'Исправления.Удаление';
								|en = 'Patch.Delete';"));
	SelectionOfLogEvents = New Structure("EventLogEvent", EventsArray);
	EventLogClient.OpenEventLog(SelectionOfLogEvents);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInstalledPatches

&AtClient
Procedure InstalledPatchesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	If Not DataSeparationEnabled Then
		DeleteExtensions(Item.SelectedRows);
	EndIf;
EndProcedure

&AtClient
Procedure InstalledPatchesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	If Not DataSeparationEnabled Then
		Notification = New NotifyDescription("AfterInstallUpdates", ThisObject);
		OpenForm("DataProcessor.InstallUpdates.Form",,,,,, Notification);
	EndIf;
EndProcedure

&AtClient
Procedure InstalledPatchesAttachOnChange(Item)
	CurrentData = Items.InstalledPatches.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("RowID", CurrentData.GetID());
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("InstalledPatchesAttachOnChangeCompletion", 0.1, True);
EndProcedure

&AtClient
Procedure InstalledPatchesAttachOnChangeCompletion()
	
	Try
		AttachInstalledPatchesOnChangeAtServer(Context.RowID);
	Except
		ErrorInfo = ErrorInfo();
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	HideTimeConsumingOperation();
	
EndProcedure

&AtServer
Procedure AttachInstalledPatchesOnChangeAtServer(RowID)
	
	ListLine = InstalledPatches.FindByID(RowID);
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	CurrentUsage = ListLine.Attach;
	Try
		Catalogs.ExtensionsVersions.ToggleExtensionUsage(ListLine.ExtensionID, CurrentUsage);
	Except
		ListLine.Attach = Not ListLine.Attach;
		RefreshPatchesList();
		
		Raise;
	EndTry;
	
	RefreshPatchesList();
	
EndProcedure

&AtClient
Procedure ShowTimeConsumingOperation()
	
	Items.InformationPages.CurrentPage= Items.TimeConsumingOperationPage;
	ReadOnly = True;
	
EndProcedure

&AtClient
Procedure HideTimeConsumingOperation()
	
	Items.InformationPages.CurrentPage = Items.InformationPage;
	ReadOnly = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveAs(Command)
	SavePatches();
EndProcedure

&AtClient
Procedure ExportAttachedPatches(Command)
	SavePatches(True);
EndProcedure

&AtClient
Procedure FindAndInstallUpdates(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.UpdateProgram();
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RefreshPatchesList()
	
	InstalledPatches.Clear();
	Items.InstalledPatchesPathToFile.Visible = False;
	
	SetPrivilegedMode(True);
	Extensions = ConfigurationExtensions.Get();
	SetPrivilegedMode(False);
	
	PatchesDetails = DescriptionOfInstalledFixes();
	
	For Each Extension In Extensions Do
		
		If Not ConfigurationUpdate.IsPatch(Extension) Then
			Continue;
		EndIf;
		
		If Filter.Count() <> 0 And Filter.FindByValue(Extension.Name) = Undefined Then
			Continue;
		EndIf;
		
		PatchProperties = ConfigurationUpdate.PatchProperties(Extension.Name);
		
		Patch = InstalledPatches.Add();
		Patch.Name = Extension.Name;
		Patch.Checksum = Base64String(Extension.HashSum);
		Patch.ExtensionID = Extension.UUID;
		Patch.Attach = Extension.Active;
		Patch.Version = Extension.Version;
		If PatchProperties = "ReadingError" Then
			Patch.Status = 0;
		ElsIf PatchProperties <> Undefined Then
			Patch.Status = 0;
			Patch.LongDesc = PatchProperties.Description;
			Patch.ApplicableTo = ApplicabilityForConfigurations(PatchProperties);
		Else
			LongDesc = PatchesDetails[Extension.Name];
			Patch.Status = 1;
			Patch.LongDesc = LongDesc;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function DescriptionOfInstalledFixes()
	
	If Not OnUpdate Then
		Return New Map;
	EndIf;
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	MethodParameters = New Array;
	MethodParameters.Add(StorageAddress);
	MethodParameters.Add(Filter.UnloadValues());
	MethodParameters.Add(True);
	BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
		"ConfigurationUpdate.NewPatchesDetails1",
		MethodParameters);
	BackgroundJob.WaitForExecutionCompletion(Undefined);
	
	NewPatchesDetails = GetFromTempStorage(StorageAddress);
	If TypeOf(NewPatchesDetails) <> Type("Map") Then
		NewPatchesDetails = New Map;
	EndIf;
	
	Return NewPatchesDetails;
	
EndFunction

&AtServer
Function ApplicabilityForConfigurations(PatchProperties)
	
	ConfigurationsNames = New Array;
	For Each ConfigurationName In PatchProperties.AppliedFor Do
		ConfigurationsNames.Add(ConfigurationName.ConfigurationName);
	EndDo;
	
	Return StrConcat(ConfigurationsNames, Chars.LF);
	
EndFunction

&AtClient
Procedure DeleteExtensions(SelectedRows)
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ExtensionsIDs = New Array;
	For Each RowID In SelectedRows Do
		PatchString = InstalledPatches.FindByID(RowID);
		ExtensionsIDs.Add(PatchString.ExtensionID);
	EndDo;
	
	Context = New Structure;
	Context.Insert("ExtensionsIDs", ExtensionsIDs);
	
	Notification = New NotifyDescription("DeleteExtensionAfterConfirmation", ThisObject, Context);
	If ExtensionsIDs.Count() > 1 Then
		QueryText = NStr("ru = 'Удалить выделенные исправления?';
							|en = 'Do you want to delete the selected patches?';");
	Else
		QueryText = NStr("ru = 'Удалить исправление?';
							|en = 'Do you want to delete the patch?';");
	EndIf;
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteExtensionAfterConfirmation(Result, Context) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Handler = New NotifyDescription("DeleteExtensionFollowUp", ThisObject, Context);
		
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Queries = RequestsToRevokeExternalModuleUsagePermissions(Context.ExtensionsIDs);
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, Handler);
		Else
			ExecuteNotifyProcessing(Handler, DialogReturnCode.OK);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionFollowUp(Result, Context) Export
	
	If Result = DialogReturnCode.OK Then
		CurrentContext = Context;
		AttachIdleHandler("DeleteExtensionCompletion", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionCompletion()
	
	Context = CurrentContext;
	
	Try
		DeleteExtensionsAtServer(Context.ExtensionsIDs);
	Except
		ErrorInfo = ErrorInfo();
		StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	EndTry;
	
EndProcedure

&AtServer
Procedure DeleteExtensionsAtServer(ExtensionsIDs)
	
	ErrorText = "";
	Catalogs.ExtensionsVersions.DeleteExtensions(ExtensionsIDs, ErrorText);
	
	RefreshPatchesList();
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

&AtServer
Function RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs)
	
	Return Catalogs.ExtensionsVersions.RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs);
	
EndFunction

&AtClient
Procedure AfterInstallUpdates(Result, AdditionalParameters) Export
	RefreshPatchesList();
EndProcedure

&AtClient
Procedure SaveAsCompletion(PathToDirectory, SelectedRows) Export
	
	FilesToSave = SaveAtServer(SelectedRows, PathToDirectory);
	
	If FilesToSave.Count() = 0 Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Interactively     = False;
	
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);
	
EndProcedure

&AtClient
Procedure SavePatches(OnlyAttachedOnes = False)
	
	If OnlyAttachedOnes Then
		SelectedRows = AttachedPatchesIDs();
	Else
		SelectedRows = Items.InstalledPatches.SelectedRows;
	EndIf;
	
	NotifyDescription = New NotifyDescription("SaveAsCompletion", ThisObject, SelectedRows);
	
	If SelectedRows.Count() = 0 Then
		If OnlyAttachedOnes Then
			ShowMessageBox(, NStr("ru = 'Нет подключенных исправлений.';
											|en = 'No attached patches.';"));
		EndIf;
		Return;
	ElsIf Not OnlyAttachedOnes And SelectedRows.Count() = 1 Then
		FilesToSave = SaveAtServer(SelectedRows);
	Else
		Title = NStr("ru = 'Выберите каталог для сохранения исправлений конфигурации';
						|en = 'Choose a directory to save the patch';");
		FileSystemClient.SelectDirectory(NotifyDescription, Title);
		Return;
	EndIf;
	
	If FilesToSave.Count() = 0 Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения исправления конфигурации';
												|en = 'Choose a file to save the patch';");
	SavingParameters.Dialog.Filter    = NStr("ru = 'Файлы исправлений конфигурации (*.cfe)|*.cfe';
												|en = '1C:Enterprise patch files (*.cfe)|*.cfe';") + "|" 
		+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Все файлы (%1)|%1';
																		|en = 'All files (%1)|%1';"), GetAllFilesMask());
	
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);
	
EndProcedure 

&AtClient
Function AttachedPatchesIDs()
	
	ConnectedNow = New Array;
	For Each Patch In InstalledPatches Do
		If Not Patch.Attach Then
			Continue;
		EndIf;
		
		ConnectedNow.Add(Patch.GetID());
	EndDo;
	
	Return ConnectedNow;
EndFunction

&AtServer
Function SaveAtServer(RowsIDs, PathToDirectory = "")
	
	FilesToSave = New Array;
	For Each RowID In RowsIDs Do
		ListLine = InstalledPatches.FindByID(RowID);
		ExtensionID = ListLine.ExtensionID;
		Extension = FindExtension(ExtensionID);
	
		If Extension <> Undefined Then
			If ValueIsFilled(PathToDirectory) Then
				Prefix = PathToDirectory + GetPathSeparator();
			Else
				Prefix = "";
			EndIf;
			Name = Prefix + Extension.Name + "_" + Extension.Version + ".cfe";
			Location = PutToTempStorage(Extension.GetData(), UUID);
			TransferableFileDescription = New TransferableFileDescription(Name, Location);
			FilesToSave.Add(TransferableFileDescription);
		EndIf;
	EndDo;
	
	Return FilesToSave;
	
EndFunction

&AtServerNoContext
Function FindExtension(ExtensionID)
	
	Return Catalogs.ExtensionsVersions.FindExtension(ExtensionID);
	
EndFunction

#EndRegion