#Region FormCommandsEventHandlers

#Region ExportCertificate

&AtClient
Procedure ExportCertificate(Command)
	
	CurrentRecord = Items.List.CurrentRow;
	If CurrentRecord <> Undefined Then
		CurrentData = Items.List.CurrentData;
		If CurrentData <> Undefined Then
			CertificateFileName = CurrentData.Description + ".cer";
		Else
			CertificateFileName = "Certificate.cer";
		EndIf;
		Notification = New NotifyDescription("UploadCertificateAfterSearch", 
			ThisObject, New Structure("FileName", CertificateFileName));
		CertificatesStorageClient.FindCertificate(Notification, New Structure("Thumbprint", CurrentData.Thumbprint));
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadCertificateAfterSearch(Result, IncomingContext) Export
	
	If Result.Completed2 And ValueIsFilled(Result.Certificate) Then
		GetFile(PutToTempStorage(Result.Certificate.Certificate), 
			IncomingContext.FileName, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportCertificate

&AtClient
Procedure ImportCertificate(Command)
	
	ToolTipText = NStr("ru = 'Укажите тип хранилища';
							|en = 'Specify store type';");
	NotifyDescription = New NotifyDescription("DownloadCertificateAfterSelectingStorageType", ThisObject);
	ShowInputValue(NotifyDescription, , ToolTipText, Type("EnumRef.CertificatesStorageType"));
	
EndProcedure

&AtClient
Procedure DownloadCertificateAfterSelectingStorageType(StoreType, AdditionalParameters) Export
	
	If StoreType <> Undefined Then
		NotifyDescription = New NotifyDescription("DownloadCertificateAfterPlacingFile", ThisObject, StoreType);
		BeginPutFile(NotifyDescription,,, True, UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadCertificateAfterPlacingFile(Result, CertificateAddress, SelectedFileName, StoreType) Export
	
	If Result Then
		Notification = New NotifyDescription("DownloadCertificateAfterAddingItToRepository", ThisObject);
		CertificatesStorageClient.Add(Notification, CertificateAddress, StoreType);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadCertificateAfterAddingItToRepository(Result, IncomingContext) Export

	If Result.Completed2 Then
		Items.List.Refresh();
	ElsIf Result.Property("ErrorInfo") Then 
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(Result.ErrorInfo));		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion