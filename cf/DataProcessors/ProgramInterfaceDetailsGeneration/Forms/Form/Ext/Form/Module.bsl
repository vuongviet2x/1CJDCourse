///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Or MobileClient Then
	ShowMessageBox(, NStr("ru = 'Запуск в веб-клиенте или в мобильном клиенте невозможен.
		|Запустите тонкий клиент.';
		|en = 'Cannot start in web client or mobile client.
		|Start thin client.';"));
	Cancel = True;
	Return;
#EndIf
	
	DefineVersionLanguage();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SavingDialog = New FileDialog(FileDialogMode.Save);
	SavingDialog.Multiselect = False;
	SavingDialog.Filter = NStr("ru = 'Описание программного интерфейса';
									|en = 'Application interface details';") + "(*.html)|*.html";
	NotifyDescription = New NotifyDescription("PathToFileStartChoiceCompletion", ThisObject);
	FileSystemClient.ShowSelectionDialog(NotifyDescription, SavingDialog);
	
EndProcedure

&AtClient
Procedure DumpDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	DirectorySelectionDialogBox = New FileDialog(FileDialogMode.ChooseDirectory);
	DirectorySelectionDialogBox.Multiselect = False;
	NotifyDescription = New NotifyDescription("DumpDirectoryStartChoiceCompletion", ThisObject);
	FileSystemClient.ShowSelectionDialog(NotifyDescription, DirectorySelectionDialogBox);
	
EndProcedure

&AtClient
Procedure PathToFileOpening(Item, StandardProcessing)
	StandardProcessing = False;
	FileSystemClient.OpenFile(Object.PathToFile);
EndProcedure

&AtClient
Procedure SubsystemsBeingAnalyzedStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	FilterByRefMetadata = New ValueList;
	FilterByRefMetadata.Add("Subsystems");
	
	ChoiceParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	ChoiceParameters.MetadataObjectsToSelectCollection = FilterByRefMetadata;
	ChoiceParameters.SelectedMetadataObjects = Object.SubsystemsBeingAnalyzed;
	
	Notification = New NotifyDescription("SubsystemsToAnalyzeCompleteSelection", ThisObject);
	StandardSubsystemsClient.ChooseMetadataObjects(ChoiceParameters, Notification);
EndProcedure

&AtClient
Procedure SubsystemsToAnalyzeCompleteSelection(Result, AdditionalParameters) Export
	If TypeOf(Result) <> Type("ValueList") Then
		Return;
	EndIf;
	
	Object.SubsystemsBeingAnalyzed = Result;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Prepare(Command)
	If Not ValueIsFilled(Object.PathToFile) Then
		ShowMessageBox(, NStr("ru = 'Укажите путь к файлу, в который будет сохранен результат.';
										|en = 'Specify a file path to save the result.';"));
		Return;
	EndIf;
	PrepareAtServer();
	
	Text = NStr("ru = 'Описание программного интерфейса подготовлено.';
				|en = 'Application interface details are prepared.';");
	ShowMessageBox(, Text);
	
EndProcedure

&AtClient
Procedure OpenWarningsList(Command)
	If Object.DetailsGenerationLog = Undefined Then
		ShowMessageBox(, NStr("ru = 'Сначала подготовьте описание программного интерфейса.';
										|en = 'First, you need to prepare application interface details.';"));
		Return;
	EndIf;
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DetailsGenerationLog", Object.DetailsGenerationLog);
	OpenForm(FullFormName("DescriptionCreationWarnings"), OpeningParameters);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PrepareAtServer()
	ObjectModule = FormAttributeToValue("Object");
	ObjectModule.GenerateAPI();
	ValueToFormAttribute(ObjectModule, "Object");
EndProcedure

&AtClient
Procedure PathToFileStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.PathToFile = Result[0];
	// For compatibility with Linux.
	Object.PathToFile = StrReplace(Object.PathToFile, "\", "/");
	
EndProcedure

&AtClient
Procedure DumpDirectoryStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.DumpDirectory = Result[0];
	// For compatibility with Linux.
	Object.DumpDirectory = StrReplace(Object.DumpDirectory, "\", "/");
	
	DefineVersionLanguage();
	
EndProcedure

&AtClient
Function FullFormName(Name)
	NameParts = StrSplit(FormName, ".");
	NameParts[3] = Name;
	Return StrConcat(NameParts, ".");
EndFunction

&AtServer
Procedure DefineVersionLanguage()
	
	DataProcessorObject2 = FormAttributeToValue("Object");
	DataProcessorObject2.DefineVersionLanguage();
	
	Object.VersionLanguage = DataProcessorObject2.VersionLanguage;
	
EndProcedure

#EndRegion