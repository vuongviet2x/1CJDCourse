#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SupportRequestID = Parameters.SupportRequestID;
	If Parameters.Property("UserCode") 
		And ValueIsFilled(Parameters.UserCode) Then
		UserCode = Parameters.UserCode;
	Else
		UserCode = InformationCenterServer.UserCodeForAccess();
	EndIf;
	FillInUnseenInteractions();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UnreadInteractionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	InformationCenterClient.OpenInteractionWithSupport(
		SupportRequestID, CurrentData.Id, CurrentData.Type, CurrentData.Incoming, False, UserCode);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInUnseenInteractions()
	
	For Each ListItem In Parameters.ListOfUnseenInteractions Do
		 
		UnsolicitedInteraction = ListItem.Value;
		NewLineOfVT = UnreadInteractions.Add();
		FillPropertyValues(NewLineOfVT, UnsolicitedInteraction);
		NewLineOfVT.PictureNumber = 
			InformationCenterServer.InteractionImageNumber(NewLineOfVT.Type, NewLineOfVT.Incoming);
		NewLineOfVT.ImageExplanation = ?(NewLineOfVT.Incoming, NStr("ru = 'Вх.';
																			|en = 'Incoming';"), NStr("ru = 'Исх.';
																								|en = 'Outgoing';"));
		
	EndDo;
	
EndProcedure

#EndRegion

