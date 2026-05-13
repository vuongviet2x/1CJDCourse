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
	
	If Not AccessRight("SaveUserData", Metadata)
		Or Not AccessRight("DataAdministration", Metadata) Then
		ReadOnly = True;
		Items.FormDetails.Title = NStr("ru = 'Для переноса вариантов отчетов требуются права ""Сохранение данных пользователя"" и ""Администрирование данных"".';
												|en = 'To transfer report options, the Save user data and Data administration rights are required.';");
		Return;
	EndIf;
	
	Store = Metadata.ReportsVariantsStorage; // MetadataObjectSettingsStorage
	If Store <> Undefined And Store.Name = "ReportsVariantsStorage" Then
		Items.SaveReportOptions.Enabled = False;
		Items.LoadReportOptions.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
		Items.FormDetails.Title = Items.FormDetails.Title + Chars.LF + Chars.LF
			+ NStr("ru = 'Чтение вариантов отчетов из стандартного хранилища невозможно, поскольку хранилище подсистемы ""Варианты отчетов"" уже установлено в свойстве конфигурации ""Хранилище вариантов отчетов"".';
					|en = 'Cannot read report options from a standard storage as the Report options subsystem storage is already set in the Report options storage property.';");
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveReportOptions(Command)
	Result = SaveReportsOptionsAtServer();
	ShowMessageBox(, Result);
EndProcedure

&AtClient
Procedure LoadReportOptions(Command)
	QueryText = 
	NStr("ru = 'Загрузку вариантов отчетов следует выполнять только в том случае,
	|если сохранение не было выполнено до обновления конфигурации.
	|
	|В этом случае команду ""Загрузить варианты отчетов"" следует выполнять
	|после очистки свойства конфигурации ""Хранилище вариантов отчетов""
	|(в конфигураторе) и выполнения команды ""Сохранить варианты отчетов"".';
	|en = 'Import report options only
	|if they were not saved before configuration update.
	|
	|In this case, execute the ""Load report options"" command
	|after the ""Report option storage"" configuration property
	|(in Designer) is cleared and the ""Save report options"" command is executed.';");
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Загрузить варианты отчетов';
												|en = 'Load report options';"));
	Buttons.Add(DialogReturnCode.Cancel);
	Handler = New NotifyDescription("LoadReportOptionsCompletion", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons, , DialogReturnCode.Cancel);
EndProcedure

&AtClient
Procedure LoadReportOptionsCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Result = ImportReportsOptionsAtServer();
		ShowMessageBox(, Result);
	EndIf;
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Server call, Server.

&AtServer
Function SaveReportsOptionsAtServer()
	OptionsSaved = False;
	Try
		OptionsSaved = StartReportsOptionsConversion();
	Except
		ErrorPresentation = NStr("ru = 'Не удалось сохранить варианты отчетов по причине:
			|%1';
			|en = 'Cannot save the report options due to:
			|%1';");
		LogReportOptionError(Undefined, 
			StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, 
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, 
			ErrorProcessing.BriefErrorDescription(ErrorInfo())));
	EndTry;
	
	If OptionsSaved Then
		Result = NStr("ru = 'Настройки вариантов отчетов успешно сохранены.';
						|en = 'Report option settings are successfully saved.';");
	Else
		Result = NStr("ru = 'Не удалось сохранить настройки вариантов отчетов.
		|Подробности см. в окне сообщений и в журнале регистрации.';
		|en = 'Couldn''t save the report option settings.
		|See the Event log for details.';");
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function ImportReportsOptionsAtServer()
	Result = "";
	Try
		// Cannot call "Common.CalculateInSafeMode" as 
		// the data processor must be run as an external one.
		CommonModuleReportsOptions = Eval("ReportsOptions");
		If CommonModuleReportsOptions = Undefined Then
			Result = NStr("ru = 'Не удалось загрузить настройки вариантов отчетов:
				|Подсистема ""Варианты отчетов"" не существует в конфигурации.';
				|en = 'Cannot import the report option settings:
				|The ""Report options"" subsystem does not exist in the configuration.';");
		Else
			CommonModuleReportsOptions.CompleteConversionOfReportVariants();
			Result = NStr("ru = 'Настройки вариантов отчетов успешно загружены.
				|Если ранее свойство конфигурации ""Хранилище вариантов отчетов"" было очищено,
				|то теперь его снова можно заполнить, выбрав одноименное хранилище настроек.';
				|en = 'Report option settings were successfully imported.
				|If earlier the ""Report option storage"" configuration property was cleared,
				|you can fill it in again selecting the similarly named setting storage.';");
		EndIf;
	Except
		ErrorPresentation = NStr("ru = 'Не удалось загрузить варианты отчетов по причине:
			|%1';
			|en = 'Cannot import the report options due to:
			|%1';");
		LogReportOptionError(Undefined, StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, 
			ErrorProcessing.BriefErrorDescription(ErrorInfo())));
		Result = NStr("ru = 'Не удалось загрузить настройки вариантов отчетов.
			|Подробности см. в окне сообщений или в журнале регистрации.';
			|en = 'Cannot import the report option settings.
			|See the Event log for details.';");
	EndTry;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server.

&AtServer
Function StartReportsOptionsConversion()
	// The result that will be saved to the storage.
	VariantsTable = CommonSettingsStorageLoad("TransferReportOptions", "VariantsTable", , , "");
	If TypeOf(VariantsTable) <> Type("ValueTable") Or VariantsTable.Count() = 0 Then
		VariantsTable = New ValueTable;
		VariantsTable.Columns.Add("Report",     TypesDetailsString());
		VariantsTable.Columns.Add("Variant",   TypesDetailsString());
		VariantsTable.Columns.Add("Author",     TypesDetailsString());
		VariantsTable.Columns.Add("Setting", New TypeDescription("ValueStorage"));
		VariantsTable.Columns.Add("ReportPresentation",   TypesDetailsString());
		VariantsTable.Columns.Add("VariantPresentation", TypesDetailsString());
		VariantsTable.Columns.Add("AuthorID",   New TypeDescription("UUID"));
	EndIf;
	
	RemoveAll = True;
	ArrayOfObjectsKeysToDelete = New Array;
	
	StorageSelection = ReportsVariantsStorage.Select();
	SuccessiveReadingErrors = 0;
	While True Do
		Try
			GotSelectionItem = StorageSelection.Next();
			SuccessiveReadingErrors = 0;
		Except
			GotSelectionItem = Undefined;
			SuccessiveReadingErrors = SuccessiveReadingErrors + 1;
			ErrorPresentation = NStr("ru = 'Не удалось получить варианты отчетов из стандартного хранилища по причине:';
										|en = 'Cannot receive the report options from the standard storage due to:';")
				+ Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
			LogReportOptionError(Undefined, ErrorPresentation);
		EndTry;
		
		If GotSelectionItem = False Then
			Break;
		ElsIf GotSelectionItem = Undefined Then
			If SuccessiveReadingErrors > 100 Then
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		// Skip internal reports that are not attached.
		ReportMetadata = Common.MetadataObjectByFullName(StorageSelection.ObjectKey);
		If ReportMetadata <> Undefined Then
			StorageMetadata1 = ReportMetadata.VariantsStorage; // MetadataObjectSettingsStorage
			If StorageMetadata1 = Undefined Or StorageMetadata1.Name <> "ReportsVariantsStorage" Then
				RemoveAll = False;
				Continue;
			EndIf;
		EndIf;
		
		// All external report options are moved as it's impossible to determine
		// whether they are connected to the subsystem's storage.
		ArrayOfObjectsKeysToDelete.Add(StorageSelection.ObjectKey);
		
		IBUser = InfoBaseUsers.FindByName(StorageSelection.User);
		If IBUser = Undefined Then
			User = Catalogs.Users.FindByDescription(StorageSelection.User, True);
			If Not ValueIsFilled(User) Then
				Continue;
			EndIf;
			UserIdentificator = User.IBUserID;
		Else
			UserIdentificator = IBUser.UUID;
		EndIf;
		
		TableRow = VariantsTable.Add();
		TableRow.Report     = StorageSelection.ObjectKey;
		TableRow.Variant   = StorageSelection.SettingsKey;
		TableRow.Author     = StorageSelection.User;
		TableRow.Setting = New ValueStorage(StorageSelection.Settings, New Deflation(9));
		TableRow.VariantPresentation = StorageSelection.Presentation;
		TableRow.AuthorID   = UserIdentificator;
		If ReportMetadata = Undefined Then
			TableRow.ReportPresentation = StorageSelection.ObjectKey;
		Else
			TableRow.ReportPresentation = ReportMetadata.Presentation();
		EndIf;
	EndDo;
	
	// Save the result to the storage.
	CommonSettingsStorageSave(
		"TransferReportOptions", 
		"VariantsTable", 
		VariantsTable,
		,
		"");
	
	// Clear the standard storage.
	If RemoveAll Then
		ReportsVariantsStorage.Delete(Undefined, Undefined, Undefined);
	Else
		For Each ObjectKey In ArrayOfObjectsKeysToDelete Do
			ReportsVariantsStorage.Delete(ObjectKey, Undefined, Undefined);
		EndDo;
	EndIf;
	
	// Result.
	Return True;
EndFunction

&AtServer
Function ThisObject()
	Return FormAttributeToValue("Object");
EndFunction

&AtServer
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey, Value = Undefined,
	SettingsDescription = Undefined, UserName = Undefined)
	CommonSettingsStorage.Save(ObjectKey, SettingsKey, Value, SettingsDescription, UserName);
EndProcedure

&AtServer
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined)
	
	Result = CommonSettingsStorage.Load(ObjectKey, SettingsKey, SettingsDescription, UserName);
	
	If (Result = Undefined) And (DefaultValue <> Undefined) Then
		Result = DefaultValue;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function TypesDetailsString(StringLength = 1000)
	Return New TypeDescription("String", , New StringQualifiers(StringLength));
EndFunction

&AtServer
Procedure LogReportOptionError(Variant, Message, Attribute1 = Undefined, Attribute2 = Undefined, Attribute3 = Undefined)
	Level = EventLogLevel.Error;
	WriteLog(Level, Variant, Message, Attribute1, Attribute2, Attribute3);
EndProcedure

&AtServer
Procedure WriteLog(Level, Ref, Text, Parameter1 = Undefined, Parameter2 = Undefined, Parameter3 = Undefined)
	Text = StrReplace(Text, "%1", Parameter1); // Cannot navigate to StrTemplate.
	Text = StrReplace(Text, "%2", Parameter2);
	Text = StrReplace(Text, "%3", Parameter3);
	WriteLogEvent(NStr("ru = 'Перенос вариантов отчетов';
									|en = 'Transfer report options';", Common.DefaultLanguageCode()),
		Level, ThisObject().Metadata(), Ref, Text);
EndProcedure

#EndRegion
