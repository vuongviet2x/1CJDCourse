#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer; // DataProcessorObject.ExportImportDataContainerManager
Var CurHandlers;
Var CurNameOfSettingsStore;
Var CurSettingsStore; // StandardSettingsStorageManager
Var CurSerializer;

#EndRegion

#Region Internal

Procedure Initialize(Container, NameOfSettingsStore, Handlers, Serializer) Export
	
	CurContainer = Container; // DataProcessorObject.ExportImportDataContainerManager
	CurNameOfSettingsStore = NameOfSettingsStore;
	CurHandlers = Handlers;
	CurSerializer = Undefined; // 
	
	CurSettingsStore = Common.CalculateInSafeMode(NameOfSettingsStore); // StandardSettingsStorageManager
	
EndProcedure

Procedure ExportData() Export
	
	If CurNameOfSettingsStore <> "SystemSettingsStorage" And Metadata[CurNameOfSettingsStore] <> Undefined Then
		// Exporting data from standard setting storages only.
		Return;
	EndIf;
	
	Cancel = False;
	CurHandlers.BeforeUnloadingSettingsStore(
		CurContainer,
		CurSerializer,
		CurNameOfSettingsStore,
		CurSettingsStore,
		Cancel);
	
	If Not Cancel Then
		
		UnloadStandardStorageSettings();
		
	EndIf;
	
	CurHandlers.AfterUnloadingSettingsStore(
		CurContainer,
		CurSerializer,
		CurNameOfSettingsStore,
		CurSettingsStore);
	
EndProcedure

Procedure Close() Export
	
	Return;
	
EndProcedure

#EndRegion

#Region Private

Procedure UnloadStandardStorageSettings()
	
	FileName = CurContainer.CreateFile(
		ExportImportDataInternal.UserSettings(),
		CurNameOfSettingsStore);
	
	WriteStream = DataProcessors.ExportImportDataInfobaseDataWritingStream.Create();
	WriteStream.OpenFile(FileName, CurSerializer);
	
	IBUsers = InfoBaseUsers.GetUsers();
	
	For Each IBUser In IBUsers Do // InfoBaseUser
		ExportOfUserSettings(IBUser.Name, WriteStream);
	EndDo;
	
	WriteStream.Close();
	
	ObjectCount = WriteStream.ObjectCount();
	If ObjectCount = 0 Then
		CurContainer.ExcludeFile(FileName);
	Else
		CurContainer.SetNumberOfObjects(FileName, ObjectCount);
	EndIf;
	
EndProcedure

Procedure ExportOfUserSettings(UserName, WriteStream)
	
	Filter = New Structure("User", UserName);
	Selection = CurSettingsStore.Select(Filter);
	
	Continue_ = True;
	
	While Continue_ Do
		
		SettingsRead = False;
		
		Try
			
			Continue_ = Selection.Next();
			SettingsRead = True;
			
			If Not Continue_ Then
				Break;
			EndIf;
			
			Settings = Selection.Settings;
			
			UnloadSettingsElement(
				WriteStream,
				Selection.SettingsKey,
				Selection.ObjectKey,
				Selection.User,
				Selection.Presentation,
				Settings);
			
		Except
			
			If SettingsRead Then
				
				ErrorText = NStr("ru = 'Выгрузка настройки пропущена, т.к. произошла ошибка:';
									|en = 'Setting export is skipped due to an error:';");
				ErrorDetailedText = Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
			Else
				
				ErrorText = NStr("ru = 'Выгрузка настройки пропущена, т.к. настройка не может быть прочитана:';
									|en = 'Setting export is skipped as the setting cannot be read:';");
				ErrorDetailedText = "";
				
			EndIf;
			
			LREvent = NStr(
				"ru = 'Выгрузка загрузка данных. Выгрузка настройки пропущена';
				|en = 'Data export and import. Setting export skipped';",
				Common.DefaultLanguageCode());
			Comment = StrTemplate("%1
				|SettingsKey=%2
				|ObjectKey=%3
				|User=%4
				|Presentation=%5
				|%6",
				ErrorText,
				Selection.SettingsKey,
				Selection.ObjectKey,
				Selection.User,
				Selection.Presentation,
				ErrorDetailedText);
			
			WriteLogEvent(LREvent, EventLogLevel.Warning, , , Comment);
			
			Continue_ = True;
			
		EndTry;
		
	EndDo;
			
EndProcedure

Procedure UnloadSettingsElement(WriteStream, Val SettingsKey, Val ObjectKey, Val User, Val Presentation, Val Settings)
	
	Cancel = False;
	
	If XMLStringProcessing.FindDisallowedXMLCharacters(SettingsKey) > 0
		Or XMLStringProcessing.FindDisallowedXMLCharacters(ObjectKey) > 0
		Or XMLStringProcessing.FindDisallowedXMLCharacters(User) > 0
		Or XMLStringProcessing.FindDisallowedXMLCharacters(Presentation) > 0 Then
		
		WriteLogEvent(
			NStr("ru = 'Выгрузка загрузка данных. Выгрузка настройки пропущена';
				|en = 'Data export and import. Setting export skipped';", Common.DefaultLanguageCode()),
			EventLogLevel.Warning,,,
			NStr("ru = 'Выгрузка настройки пропущена, т.к. в ключевых параметрах содержатся недопустимые символы.';
				|en = 'Setting export is skipped as key parameters contain invalid characters.';", Common.DefaultLanguageCode()));
		
		Cancel = True;
		
	EndIf;
	
	Artifacts = New Array();
	
	CurHandlers.BeforeUploadingSettings(
		CurContainer,
		CurSerializer,
		CurNameOfSettingsStore,
		SettingsKey,
		ObjectKey,
		Settings,
		User,
		Presentation,
		Artifacts,
		Cancel);
	
	SerializationViaValueStorage = False;
	If Not SettingsAreSerializedToXDTO(Settings) Then
		Settings = New ValueStorage(Settings);
		SerializationViaValueStorage = True;
	EndIf;
	
	If Not Cancel Then
		
		RecordingSettings = ExportImportDataInternal.NewSettingsEntry();
		RecordingSettings.SettingsKey = SettingsKey;
		RecordingSettings.ObjectKey = ObjectKey;
		RecordingSettings.User = User;
		RecordingSettings.Presentation = Presentation;
		RecordingSettings.SerializationViaValueStorage = SerializationViaValueStorage;
		RecordingSettings.Settings = Settings;
		
		WriteStream.WriteInformationDatabaseDataObject(RecordingSettings, Artifacts);
		
	EndIf;
	
	CurHandlers.AfterUnloadingSettings(
		CurContainer,
		CurSerializer,
		CurNameOfSettingsStore,
		SettingsKey,
		ObjectKey,
		Settings,
		User,
		Presentation);
	
EndProcedure

Function SettingsAreSerializedToXDTO(Val Settings)
	
	If TypeOf(Settings) = Type("ClientApplicationInterfaceSettings") 
		Or TypeOf(Settings) = Type("CommandInterfaceSettings") 
		Or TypeOf(Settings) = Type("ChoiceHistorySettings")
		Or TypeOf(Settings) = Type("FormSettings")
		Or TypeOf(Settings) = Type("TableSearchHistory")
		Or TypeOf(Settings) = Type("CommandInterfaceSettings")
		Then
		Return False;
	EndIf;
	
	Result = True;
	
	Try
		
		VerificationFlow = New XMLWriter();
		VerificationFlow.SetString();
		
		XDTOSerializer.WriteXML(VerificationFlow, Settings);
		
	Except
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
