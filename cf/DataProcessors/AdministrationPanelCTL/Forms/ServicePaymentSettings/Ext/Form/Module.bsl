#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//@skip-warning
	AccountSystemUserPassword = Common.ReadDataFromSecureStorage(
		ServicePayment.OwnerOfAuthorizationPasswordInAccountSystem());
		
	Items.GroupLoadingRates.Visible = ServicePayment.TariffLoadingIsSupported();
		
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure AccountSystemUserNameOnChange(Item)
	
	OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure UserPasswordOfAccountingSystemOnChange(Item)
	
	PasswordOfUserOfAccountingSystemWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DownloadServiceRates(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf; 
	
	TimeConsumingOperation = StartLoadingServiceRates();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	Notification = New NotifyDescription("WhenLoadingTariffsIsComplete", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification, IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function StartLoadingServiceRates()
	
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "ServicePayment.DownloadServiceRates");
	
EndFunction

&AtClient
Procedure WhenLoadingTariffsIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then // The user has canceled the task.
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Загрузка выполнена';
										|en = 'Import completed';"), , 
		NStr("ru = 'Загрузка тарифов сервиса выполнена.';
			|en = 'Service plans are imported.';"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item)
	
	ConstantsNames = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	For Each ConstantName In ConstantsNames Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	ConstantsNames = New Array;
	DataPathAttribute = Items[TagName].DataPath;
	
	BeginTransaction();
	Try
		
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNames.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	Return ConstantsNames;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue  = ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure PasswordOfUserOfAccountingSystemWhenChangingOnServer()
	
	Common.WriteDataToSecureStorage(
		ServicePayment.OwnerOfAuthorizationPasswordInAccountSystem(), AccountSystemUserPassword);
	
EndProcedure

#EndRegion
