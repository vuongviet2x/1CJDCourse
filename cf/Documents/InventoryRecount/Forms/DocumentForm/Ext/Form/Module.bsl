
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.StoredFiles
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	// StandardSubsystems.StoredFiles
	FilesOperations.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	// End StandardSubsystems.StoredFiles
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportDataFromFile(Command)
	
	FileImportParameters = FileSystemClient.FileImportParameters();
	FileImportParameters.FormIdentifier = UUID;
	FileImportParameters.Dialog.Filter = 
		"Tables (*.xls,*.xlsx,*.xlsm)|*.xls;*.xlsx;*.xlsm;
		||Microsoft Excel 1997-2003 (*.xls)|*.xls
		||Microsoft Excel (*.xlsx,*.xlsm)|*.xlsx;*.xlsm";
	
	CallbackDescription = New CallbackDescription("ImportDataAfterSelection", ThisObject);
	
	FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters);
	
EndProcedure

&AtClient
Procedure ImportDataAfterSelection(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;

	// FileName = FileThatWasPut.Name
	// BinaryData = GetFromTempStorage(FileThatWasPut.Location)
	
EndProcedure

#EndRegion

