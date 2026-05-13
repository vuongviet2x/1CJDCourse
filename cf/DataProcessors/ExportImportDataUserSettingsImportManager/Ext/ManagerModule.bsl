#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Imports settings of infobase users.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data export.
//		For details, see comments to the API of ExportImportDataContainerManager handler.
//		
//	Handlers - DataProcessorObjectDataProcessorName
//	LinkReplacementFlow - DataProcessorObject.ExportImportDataReferenceReplacementStream
//  ReplaceUserInSettings - Map - Mapping between the old and new usernames.
//
Procedure DownloadInformationDatabaseUserSettings(Container, Handlers, LinkReplacementFlow, 
	ReplaceUserInSettings = Undefined) Export
	
	StorageTypes = ExportImportDataInternal.TypesOfStandardSettingsRepositories();
	
	For Each StoreType In StorageTypes Do
		
		DownloadManager = Create();
		DownloadManager.Initialize(Container, StoreType, Handlers, LinkReplacementFlow);
		DownloadManager.ImportData(ReplaceUserInSettings);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
