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

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	ImportURL = "http://cbrates.rbc.ru/tsv/cb/840.tsv";
	WhereToSave = 0;
	
	HeaderValueIfModifiedSince = CurrentSessionDate() - 24 * 60 * 60;
	Timeout = 7;
	
	VisibleEnabled(ThisObject);
	
	Items.PathAtClient.ChoiceButton = Not Common.IsWebClient();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	VisibleEnabled(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ImportURLOnChange(Item)
	
	ImportURL = TrimAll(ImportURL);
	
EndProcedure

&AtClient
Procedure WhereToSaveOnChange(Item)
	
	VisibleEnabled(ThisObject);
	
EndProcedure

&AtClient
Procedure PathAtClientStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectDirectory(New NotifyDescription("PathAtClientStartChoiceCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PathAtClientStartChoiceCompletion(Result, AdditionalParameters) Export
	
	FileName = Result;
	
	If FileName <> Undefined Then
		PathAtClient = FileName;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddressInTempStorageOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If IsBlankString(AddressInTempStorage) Then
		Return;
	EndIf;
	
	FileSystemClient.SaveFile(Undefined, AddressInTempStorage, "demo.txt");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ProxySettingsAccessFromClient(Command)
	
	OpenForm("CommonForm.ProxyServerParameters", New Structure("ProxySettingAtClient", True));
	
EndProcedure

&AtClient
Procedure ProxySettingsAccessFromServer(Command)
	
	OpenForm("CommonForm.ProxyServerParameters", New Structure("ProxySettingAtClient", False));
	
EndProcedure

&AtClient
Procedure ImportFile_(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Headers = New Map;
	
	If SendHeaderIfModifiedSince Then 
		Headers.Insert("If-Modified-Since", CommonClientServer.HTTPDate(HeaderValueIfModifiedSince));
	EndIf;
	
	ReceivingParameters = GetFilesFromInternetClientServer.FileGettingParameters();
	ReceivingParameters.Headers = Headers;
	ReceivingParameters.Timeout = Timeout;
	
	If WhereToSave = 0 Then
		
		If Not IsBlankString(PathAtClient) Then 
			ReceivingParameters.PathForSaving = PathAtClient;
		EndIf;
		
		Result = GetFilesFromInternetClient.DownloadFileAtClient(ImportURL, ReceivingParameters);
		
		If Result.Status Then
			PathAtClient = Result.Path;
			ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'На клиенте сохранен файл ""%1""';
					|en = '%1 file is saved on the client';"), 
				Result.Path ));
		Else
			CommonClient.MessageToUser(Result.ErrorMessage);
		EndIf;
	ElsIf WhereToSave = 1 Then
		
		If Not IsBlankString(PathAtServer) Then 
			ReceivingParameters.PathForSaving = PathAtServer;
		EndIf;
		
		Result = DownloadFileAtServer(ImportURL, ReceivingParameters);
		
		If Result.Status Then
			PathAtServer = Result.Path;
			ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'На сервере сохранен файл ""%1""';
					|en = '%1 file is saved on the server';"), 
				Result.Path));
		Else
			CommonClient.MessageToUser(Result.ErrorMessage);
		EndIf;
	ElsIf WhereToSave = 2 Then
		Result = DownloadFileToTempStorage(ImportURL);
		
		If Result.Status Then
			AddressInTempStorage = Result.Path;
			ShowMessageBox(,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл сохранен во временное хранилище ""%1""';
						|en = 'File is saved to the %1 temporary storage';"), 
					AddressInTempStorage));
		Else
			CommonClient.MessageToUser(Result.ErrorMessage);
		EndIf;
	Else
		CommonClient.MessageToUser(
			NStr("ru = 'Поле ""Куда сохранять"" не заполнено';
				|en = 'The ""Where to save"" field is blank';"), , "WhereToSave");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WhereToSave.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsFileIB");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibleEnabled(Form)
	
	Items = Form.Items;
	Items.PathAtClient.Enabled = (Form.WhereToSave = 0);
	Items.PathAtServer.Enabled = (Form.WhereToSave = 1);
	Items.AddressInTempStorage.Enabled    = (Form.WhereToSave = 2);
	Items.AddressInTempStorage.ReadOnly = (Form.WhereToSave = 2);
	Items.HeaderValueIfModifiedSince.ReadOnly = Not Form.SendHeaderIfModifiedSince;
	
EndProcedure

&AtClient
Procedure SelectDirectory(Val Notification)
	
#If WebClient Then
	ExecuteNotifyProcessing(Notification, Undefined);
	Return;
#Else
	
	If Not ValueIsFilled(ImportURL) Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("ru = 'Поле ""Что загружать"" не заполнено.';
														|en = 'The ""What to import"" field is blank';"),, "ImportURL");
		ExecuteNotifyProcessing(Notification, Undefined);
		Return;
	EndIf;
	
	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Multiselect = False;
	Dialog.Title = NStr("ru = 'Выберите файл для сохранения';
							|en = 'Select file to download';");
	Dialog.FullFileName = ?(ValueIsFilled(PathAtClient), PathAtClient, SelectFileName());
	
	Context = New Structure("Dialog, Notification", Dialog, Notification);
	
	ChoiceDialogNotification = New NotifyDescription("SelectDirectoryCompletion", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotification, Dialog);
	
#EndIf

EndProcedure

&AtClient
Procedure SelectDirectoryCompletion(SelectedFiles, Context) Export
	
	Dialog     = Context.Dialog;
	Notification = Context.Notification;
	
	If Not (SelectedFiles <> Undefined) Then
		ExecuteNotifyProcessing(Notification, Undefined);
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Notification, Dialog.SelectedFiles[0]);
	
EndProcedure

&AtClient
Function SelectFileName()
	
	Result = "";
	
	AddressLength = StrLen(ImportURL);
	For Number = 1 To AddressLength Do
		CharacterNumber = AddressLength - Number + 1;
		Char = Mid(ImportURL, CharacterNumber, 1);
		If Char = "\" Or Char = "/" Then
			Break;
		EndIf;
		Result = Char + Result;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function DownloadFileAtServer(ImportURL, ReceivingParameters)
	
	Return GetFilesFromInternet.DownloadFileAtServer(ImportURL, ReceivingParameters);
	
EndFunction

&AtServerNoContext
Function DownloadFileToTempStorage(ImportURL)
	
	Return GetFilesFromInternet.DownloadFileToTempStorage(ImportURL);
	
EndFunction

&AtClient
Procedure SendHeaderIfModifiedSinceOnChange(Item)
	VisibleEnabled(ThisObject);
EndProcedure

#EndRegion