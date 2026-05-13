
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	Try
		FillInAlertsPossibleTypes();
	Except
		// No exception handling is required.
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillInAlertsPossibleTypes()
	
	HandlersModule = CommonClient.CommonModule("UsersNotificationCTLClient");
	Handlers = HandlersModule.NotificationsHandlers();
	
	For Each NotificationTypeData In Handlers Do
		Items.NotificationKind.ChoiceList.Add(NotificationTypeData.Key);
	EndDo;
	
EndProcedure

#EndRegion