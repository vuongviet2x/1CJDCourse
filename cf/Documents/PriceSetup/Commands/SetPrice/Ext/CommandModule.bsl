
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FillingValues = New Structure("Products", CommandParameter);
	
	FormParameters = New Structure("FillingValues", FillingValues);
	OpenForm(
		"Document.PriceSetup.ObjectForm",
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL
	);
	
EndProcedure
