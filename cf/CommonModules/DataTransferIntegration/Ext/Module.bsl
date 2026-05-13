#Region Internal

Procedure LogicalStorageManagers(AllLogicalStorageManagers) Export
		
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		AllLogicalStorageManagers.Insert("migration", ApplicationMigrationModule);
	EndIf;
	
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
Procedure PhysicalStorageManagers(AllPhysicalStorageManagers) Export
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
Procedure ValidityPeriodOfTemporaryID(ValidityPeriodOfTemporaryID) Export
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
Procedure DataBlockSize(DataBlockSize) Export
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
Procedure BlockSizeForSendingData(BlockSizeForSendingData) Export
EndProcedure

Procedure ErrorReceivingData(Response) Export
	
	CommonCTL.TechnologyLogEntry("GetData.Error", New Structure("StatusCode, LongDesc", Response.StatusCode, Response.GetBodyAsString()));
	
	WriteLogEvent(
		NStr("ru = 'Передача данных.Получение';
			|en = 'Data transfer.Receiving';", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		StrTemplate(
			NStr("ru = 'Код состояния: %1 %2';
				|en = 'Status code: %1 %2';", Common.DefaultLanguageCode()),
			Response.StatusCode,
			Chars.LF + Response.GetBodyAsString()));
	
EndProcedure

Procedure AnErrorOccurredWhileSendingData(Response) Export
	
	CommonCTL.TechnologyLogEntry("DataSending.Error", New Structure("StatusCode, LongDesc", Response.StatusCode, Response.GetBodyAsString()));
	
	WriteLogEvent(
		NStr("ru = 'Передача данных.Отправка';
			|en = 'Data transfer.Sending';", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		StrTemplate(
			NStr("ru = 'Код состояния: %1 %2';
				|en = 'Status code: %1 %2';", Common.DefaultLanguageCode()),
			Response.StatusCode,
			Chars.LF + Response.GetBodyAsString()));
	
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
Procedure OnGetTemporaryFileName(TempFileName, Extension) Export
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
Procedure OnExtendTemporaryIDValidity(Id, Date, Query) Export
EndProcedure

#EndRegion