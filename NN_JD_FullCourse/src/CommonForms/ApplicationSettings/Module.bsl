
&AtClient
Procedure UseCharacteristicsOnChange(Item)
	
	RefreshInterface = True;
	
EndProcedure


&AtClient
Procedure AfterWrite(WriteParameters)
	
	If RefreshInterface Then
	
		RefreshInterface();
	
	EndIf;
	
EndProcedure

