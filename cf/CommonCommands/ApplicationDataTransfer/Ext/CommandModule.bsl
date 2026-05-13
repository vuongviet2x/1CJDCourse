///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Form = ApplicationParameters[ApplicationsMigrationClient.NameOfTransitionForm()];
	If Form = Undefined Then
		OpenForm("DataProcessor.WizardOfTransitionToCloud.Form.WizardOfTransitionToCloud", , 
			CommandExecuteParameters.Source, 
			CommandExecuteParameters.Uniqueness, 
			CommandExecuteParameters.Window);
	ElsIf Not Form.IsOpen() Then
		Form.Open();
	Else
		Form.Activate();
	EndIf;
	
EndProcedure

#EndRegion

