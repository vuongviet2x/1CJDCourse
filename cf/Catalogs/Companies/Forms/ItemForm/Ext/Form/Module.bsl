
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ResponsiblePersons = ResponsiblePersons(CurrentSessionDate(), Object.Ref);
	
	FillPropertyValues(ThisObject, ResponsiblePersons);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	BinaryData = CurrentObject.LogoPicture.Get();
	If TypeOf(BinaryData) = Type("BinaryData") Then
		LogoPictureAddress = PutToTempStorage(BinaryData, UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If LogoChanged Then
		BinaryData = GetFromTempStorage(LogoPictureAddress);
		CurrentObject.LogoPicture = New ValueStorage(BinaryData, New Deflation(9));
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Try
	
		UpdateResponsiblePersons(CurrentObject.Ref);
	
	Except
		
		Cancel = True;
		ErrorText = StrTemplate(
			"Failed to update responsible persons with the error: %1",
			ErrorProcessing.BriefErrorDescription(ErrorInfo())
		);
		Message(ErrorText);

	EndTry;
	
EndProcedure

&AtServer
Procedure UpdateResponsiblePersons(Company)
	
	Period = CurrentSessionDate();
	
	ResponsiblePersons = ResponsiblePersons(Period, Company);
	
	If ResponsiblePersons.CEO <> CEO
		Or ResponsiblePersons.ChiefAccountant <> ChiefAccountant
		Or ResponsiblePersons.CTO <> CTO Then
				
		RecordManager = InformationRegisters.CompaniesResponsiblePersons.CreateRecordManager();
		
		RecordManager.Company = Company;
		RecordManager.Period = Period;
		
		RecordManager.CEO = CEO;
		RecordManager.ChiefAccountant = ChiefAccountant;
		RecordManager.CTO = CTO;
		
		RecordManager.Write(True);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ResponsiblePersons(Period, Company)

	Filter = New Structure("Company", Company);
	
	Return InformationRegisters.CompaniesResponsiblePersons.GetLast(
		Period,
		Filter
	);
	
EndFunction

&AtClient
Procedure LogoPictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	AddLogoOnClientStartChoosing();
	
EndProcedure

&AtClient
Procedure AddLogoOnClientStartChoosing()
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Filter 		= "All images (*.bmp;*.png;*.jpeg;*.jpg)|*.bmp;*.png;*.jpeg;*.jpg";
	FileDialog.Multiselect 	= False;
	FileDialog.Title 		= "Select a logo image file";
	
	FileDialog.Show(New CallbackDescription("AddLogoOnClientFinishChoosing", ThisObject));

EndProcedure

&AtClient
Procedure AddLogoOnClientFinishChoosing(SelectedFiles, AdditionalParameters) Export

	If SelectedFiles = Undefined Then
		Return;
	EndIf;

	FileName = SelectedFiles[0];
	
	LogoFile = New File(FileName);
	
	CallbackDescription = New CallbackDescription(
		"AddLogoOnClientCompletion",
		ThisObject,
		New Structure("FileName", FileName)
	);
	LogoFile.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddLogoOnClientCompletion(Exist, AdditionalParameters) Export

	If Not Exist Then
		MessageText = StrTemplate(
			"File by the path '%1' doesn't exist, try to select a file once again",
			AdditionalParameters.FileName
		);
		Message(MessageText);
		Return;
	EndIf;
	
	BinaryData = New BinaryData(AdditionalParameters.FileName);
	
	LogoPictureAddress = PutToTempStorage(BinaryData, UUID);

	LogoChanged = True;
	Modified = True;
	
EndProcedure

