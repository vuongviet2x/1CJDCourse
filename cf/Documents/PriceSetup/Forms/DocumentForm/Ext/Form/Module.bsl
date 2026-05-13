
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.LoadedFromFile Then
		Items.DocumentCreationOption.Title = "Created from the prices import data processor";
	EndIf;
	
EndProcedure
