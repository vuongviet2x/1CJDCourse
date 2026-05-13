////////////////////////////////////////////////////////////////////////////////
// 
//  Support of security profiles.
//
////////////////////////////////////////////////////////////////////////////////
// 
//@strict-types

#Region Public

// Returns external module execution mode in SaaS.
//
// Parameters:
//  ExternalModule - AnyRef - ref
//
// Returns:
//	String - external module execution mode.
//
Function ExternalModuleExecutionMode(Val ExternalModule) Export
	
	If Common.DataSeparationEnabled() Then
		
		Var_Key = SafeModeManagerInternalSaaS.RegisterKeyByReference(ExternalModule);
		
		If Common.SeparatedDataUsageAvailable() Then
			
			Mode = InformationRegisters.DataAreaExternalModulesAttachmentModes.ExternalModuleExecutionMode(
				Var_Key.Type, Var_Key.Id);
			
			If Mode = Undefined Then
				
				Mode = InformationRegisters.ExternalModulesConnectionOptionsSaaS.ExternalModuleExecutionMode(
					Var_Key.Type, Var_Key.Id);
				
				Return Mode;
				
			Else
				
				Return Mode;
				
			EndIf;
			
		Else
			
			Mode = InformationRegisters.ExternalModulesConnectionOptionsSaaS.ExternalModuleExecutionMode(
				Var_Key.Type, Var_Key.Id);
			
			Return Mode;
			
		EndIf;
		
	Else
		Raise NStr("ru = 'Функция не предназначена для вызова в информационной базе, в которой выключено разделение по областям данных';
								|en = 'The function cannot be called in the Infobase with disabled separation by data areas';");
	EndIf;
	
EndFunction

#EndRegion