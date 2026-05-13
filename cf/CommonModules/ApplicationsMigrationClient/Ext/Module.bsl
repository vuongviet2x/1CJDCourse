
#Region Internal

Procedure OnStart(Parameters) Export
	
	If Parameters.Cancel Then
		Return;
	EndIf;
	
	StartupOptions = StandardSubsystemsClient.ClientParametersOnStart();
	
	If StartupOptions.SeparatedDataUsageAvailable 
		And StartupOptions.MigrationOfApplicationsOpenForm Then
		Form = GetForm("DataProcessor.WizardOfTransitionToCloud.Form.ApplicationMigration");
		Form.OnOpenForm(True);
	EndIf;
	
EndProcedure

// Returns: 
//  String - Name of the cloud migration form.
Function NameOfTransitionForm() Export

	Return "CloudTechnology.ApplicationsMigration.GoToServiceForm";
	
EndFunction

// Returns: 
//  ClientApplicationForm, Undefined - Cloud migration form.
Function GoToServiceForm() Export
	
	Return ApplicationParameters[NameOfTransitionForm()];
	
EndFunction

#EndRegion
